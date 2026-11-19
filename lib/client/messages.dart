import 'dart:convert';
import 'dart:typed_data';

import 'package:ecp/ecp.dart';
import 'package:http/http.dart' as http;

class MessageHandler {
  final EcpCore core;
  final http.Client client;
  final ActivitySender activitySender;
  final GroupManager groups;

  MessageHandler({
    required this.core,
    required this.client,
    required this.activitySender,
    required this.groups,
  });

  MessageStore get _messageStore => core.storage.messageStore;
  ProcessedObjectStore get _processedObjectStore =>
      core.storage.processedObjectStore;

  // activities being handled: a commit that lost its claim catches up on the
  // inbox from inside the activity that led to it, which is still in there
  final _inFlight = <Uri>{};

  Future<http.Response> fetchInbox() async {
    return client.get(core.identity.inbox);
  }

  Future<List<WireActivity>> parseInboxBody(dynamic json) async {
    if (json is String) {
      json = jsonDecode(json);
    }

    if (json is Map<String, dynamic> && json['type'] == 'OrderedCollection') {
      final collection = OrderedCollection.fromJson(json);
      return collection.orderedItems
          .whereType<Map<String, dynamic>>()
          .map(WireActivity.fromJson)
          .toList();
    }

    if (json is List) {
      return json
          .whereType<Map<String, dynamic>>()
          .map(WireActivity.fromJson)
          .toList();
    }

    if (json is Map<String, dynamic>) {
      return [WireActivity.fromJson(json)];
    }

    throw FormatException(
      'Expected OrderedCollection, List, or Map — got ${json.runtimeType}',
    );
  }

  Future<List<StoredMessage>> getInbox() async {
    final response = await fetchInbox();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EcpNetworkException(
        'Failed to fetch inbox (HTTP ${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    return handleInbox(response.body);
  }

  Future<List<StoredMessage>> handleInbox(dynamic json) {
    return parseInboxBody(json).then((v) => handleActivities(v));
  }

  Future<List<StoredMessage>> handleActivities(List<WireActivity> activities) {
    return core.exclusive(() async {
      final stored = await _restoreStashed();

      for (final activity in activities) {
        final message = await handleActivity(activity);
        if (message != null) {
          stored.add(message);
        }
      }

      return stored;
    });
  }

  Future<StoredMessage?> handleActivity(WireActivity activity) =>
      core.exclusive(() => _handleActivity(activity));

  Future<StoredMessage?> _handleActivity(WireActivity activity) async {
    return activity.map(
      wireCreate: (wireCreate) async {
        final objectId = wireCreate.object.id;
        if (objectId == null) {
          return null;
        }
        if (_inFlight.contains(objectId)) return null;
        // Still in the inbox after this device applied it, so the ack never
        // reached the server, e.g. the network dropped or the app was killed.
        // MLS deleted the key, so only the ack can be sent again.
        final stored = await _messageStore.hasMessage(objectId);
        if (stored || await _processedObjectStore.check(objectId)) {
          await _processedObjectStore.add(objectId);
          await _sendDeliveredAck(
            objectId,
            stored ? wireCreate.actor : core.identity.id,
          );
          return null;
        }
        // e.g. the iOS notification service decrypted it
        final stashed = await core.stashedMessage(objectId.toString());
        if (stashed != null) {
          final message = await _restore(stashed);
          await _sendDeliveredAck(objectId, wireCreate.actor);
          return message;
        }
        StoredMessage? result;
        var handled = false;
        _inFlight.add(objectId);
        try {
          result = await _handleWireObject(wireCreate);
          handled = true;
        } catch (e) {
          // Activities fanned out per user reach devices they can't apply to,
          // e.g. a welcome for another of our devices, a commit for a group
          // this device isn't in yet, or a message to a chat a contact hasn't
          // moved over since our devices were reset. Retrying can't help:
          // drop it rather than failing the whole batch.
          // ignore: avoid_print
          print('ECP dropping activity $objectId: $e');
        } finally {
          _inFlight.remove(objectId);
        }
        // recorded first, so a failed ack is sent again from the inbox entry
        // the server keeps
        await _processedObjectStore.add(objectId);
        // kept when storing it failed, the next inbox fetch tries again
        if (handled) await core.deleteStashed(objectId.toString());
        // only an activity this device could apply counts as delivered, a
        // dropped one only clears this device's inbox entry
        await _sendDeliveredAck(
          objectId,
          handled ? wireCreate.actor : core.identity.id,
        );
        return result;
      },
      wireDelivered: (wireDelivered) async {
        // Deduped by its own id: the object id is the message's, which our
        // other devices already recorded when they got the message.
        final id = wireDelivered.id;
        if (id != null && !await _processedObjectStore.markDelivered(id)) {
          return null;
        }
        await _messageStore.markMessageDelivered(wireDelivered.object);
        return null;
      },
    );
  }

  Future<StoredMessage?> _handleWireObject(WireCreate wireCreate) {
    final objectId = wireCreate.object.id!;
    return wireCreate.object.map(
      privateMessage: (message) async {
        final processed = await core.decryptPrivateMessage(
          ciphertext: message.content,
          stashId: objectId.toString(),
        );
        switch (processed) {
          case null:
            return null;
          case MergedCommit(:final groupId, :final committer, :final newLeaves):
            if (newLeaves.isNotEmpty) {
              await groups.verifyLeaves(groupId, newLeaves, addedBy: committer);
            }
            return null;
          case ReceivedActivity(:final groupId, :final activity):
            return await handleLocalActivity(
              activity,
              groupId,
              objectId,
              message.actor,
              // sent from another of our devices, it is delivered once a
              // recipient acknowledges it
              delivered: message.actor != core.identity.id,
            );
        }
      },
      approvalRequest: (request) async {
        await core.storage.approvalRequestStore.saveApprovalRequest(
          StoredApprovalRequest(did: request.did, publicKey: request.publicKey),
        );
        return null;
      },
      welcomeMessage: (message) async {
        final result = await core.joinFromWelcome(message.content);
        // hidden until its leaves check out, so a contact whose devices were
        // reset can't show messages before the user accepts the reset
        await core.storage.groupStore.saveGroup(
          groupIdBytes: result.groupId,
          isActive: false,
        );
        // every leaf is new to this device. The welcome's actor is only what
        // the server says, but it only decides who removes bad leaves.
        final unverified = await groups.verifyGroup(
          result.groupId,
          addedBy: message.actor,
        );
        if (unverified.isEmpty) {
          await core.storage.groupStore.setGroupActive(result.groupId, true);
          // e.g. a contact brought back into the DM after starting a new one
          await groups.mergeDms();
        }
        return null;
      },
    );
  }

  Future<StoredMessage?> handleLocalActivity(
    Activity activity,
    Uint8List groupId,
    Uri objectId,
    Uri actor, {
    bool delivered = false,
  }) async {
    // what is still sent in a DM that was merged belongs to the one kept
    groupId = await core.storage.groupStore.getMergedInto(groupId) ?? groupId;
    return activity.map(
      create: (create) {
        return create.object.map(
          note: (note) async {
            final stMessage = StoredMessage(
              groupId: groupId,
              serverActivityId: objectId,
              receivedAt: DateTime.now(),
              senderId: actor,
              id: activity.id,
              content: note.content,
              inReplyTo: note.inReplyTo,
              attachment: note.attachments ?? [],
              delivered: delivered,
            );

            await _messageStore.saveMessage(stMessage);
            return stMessage;
          },
          emojiReact: (_) async {
            return null;
          },
          document: (_) async {
            return null;
          },
          image: (image) async {
            final stMessage = StoredMessage(
              groupId: groupId,
              serverActivityId: objectId,
              receivedAt: DateTime.now(),
              senderId: actor,
              id: activity.id,
              inReplyTo: image.inReplyTo,
              attachment: [image],
              delivered: delivered,
            );

            await _messageStore.saveMessage(stMessage);
            return stMessage;
          },

          video: (_) async {
            return null;
          },

          audio: (_) async {
            return null;
          },
        );
      },
      update: (_) async {
        return null;
      },
      delivered: (_) async {
        return null;
      },
      typing: (_) async {
        return null;
      },
      delete: (_) async {
        return null;
      },
    );
  }

  /// Encrypts [activity] for [groupId] and sends it. Throws an
  /// [EcpDevicesChangedException] while the group has devices of a user
  /// whose reset was not accepted, see [GroupManager.ensureVerified].
  Future<void> sendMessage(Activity activity, Uint8List groupId) async {
    await groups.ensureVerified(groupId);
    final returned = await core.exclusive(() async {
      final wireActivity = await core.encryptActivity(activity, groupId);
      return activitySender.sendActivity(wireActivity);
    });
    await handleLocalActivity(
      activity,
      groupId,
      (returned as WireCreate).object.id ??
          returned.id!, // FIXME this doesnt feel right
      core.identity.id,
    );
  }

  /// Notify the user's other devices that this device is pending approval.
  Future<void> sendApprovalRequest({
    required Uint8List publicKey,
    required String did,
  }) async {
    final me = core.identity.id;
    await activitySender.sendActivity(
      WireActivity.wireCreate(
        actor: me,
        to: [me],
        object: WireObject.approvalRequest(
          actor: me,
          to: [me],
          publicKey: publicKey,
          did: did,
        ),
      ),
    );
  }

  /// Stores the messages that were decrypted but not stored, by the iOS
  /// notification service or by a process that ended in between. Their acks
  /// are sent from their inbox entries, when the server still has them.
  Future<List<StoredMessage>> _restoreStashed() async {
    final restored = <StoredMessage>[];
    for (final stashed in await core.stashedMessages()) {
      final message = await _restore(stashed);
      if (message != null) restored.add(message);
    }
    return restored;
  }

  Future<StoredMessage?> _restore(StashedMessage stashed) async {
    final objectId = Uri.parse(stashed.stashId);
    StoredMessage? message;
    if (!await _messageStore.hasMessage(objectId)) {
      final Activity activity;
      final Uri sender;
      try {
        activity = Activity.fromJson(
          jsonDecode(utf8.decode(stashed.plaintext)) as Map<String, dynamic>,
        );
        sender = credentialOwner(stashed.senderCredential);
      } catch (e) {
        // ignore: avoid_print
        print('ECP dropping stashed $objectId: $e');
        await core.deleteStashed(stashed.stashId);
        return null;
      }
      message = await handleLocalActivity(
        activity,
        stashed.groupId,
        objectId,
        sender,
        delivered: sender != core.identity.id,
      );
    }
    await _processedObjectStore.add(objectId);
    await core.deleteStashed(stashed.stashId);
    return message;
  }

  /// A failed ack must not fail the rest of the inbox, the entry stays on
  /// the server and the ack is sent again on the next fetch.
  Future<void> _sendDeliveredAck(Uri objectId, Uri senderId) async {
    final deliveredActivity = WireActivity.wireDelivered(
      actor: core.identity.id,
      to: [senderId],
      object: objectId,
    );
    try {
      await activitySender.sendActivity(deliveredActivity);
    } catch (e) {
      // ignore: avoid_print
      print('ECP delivered ack for $objectId failed: $e');
    }
  }
}
