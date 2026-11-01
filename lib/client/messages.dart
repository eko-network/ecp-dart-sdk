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
      final stored = <StoredMessage>[];

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
        if (_inFlight.contains(objectId) ||
            await _processedObjectStore.check(objectId)) {
          return null;
        }
        await _sendDeliveredAck(objectId, wireCreate.actor);

        StoredMessage? result;
        _inFlight.add(objectId);
        try {
          result = await _handleWireObject(wireCreate);
        } catch (e) {
          // Activities fanned out per user reach devices they can't apply to,
          // e.g. a welcome for another of our devices or a commit for a group
          // this device isn't in yet. The server entry was already acked, so
          // retrying can't help: drop it rather than failing the whole batch.
          // ignore: avoid_print
          print('ECP dropping activity $objectId: $e');
        } finally {
          _inFlight.remove(objectId);
        }
        await _processedObjectStore.add(objectId);
        return result;
      },
      wireDelivered: (wireDelivered) async {
        final objectId = wireDelivered.object;
        if (await _processedObjectStore.markDelivered(objectId)) {
          await _messageStore.markMessageDelivered(objectId);
        }
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
        await core.storage.groupStore.saveGroup(groupIdBytes: result.groupId);
        // every leaf is new to this device. The welcome's actor is only what
        // the server says, but it only decides who removes bad leaves.
        await groups.verifyGroup(result.groupId, addedBy: message.actor);
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
  }) {
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

  Future<void> sendMessage(Activity activity, Uint8List groupId) async {
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

  Future<void> _sendDeliveredAck(Uri objectId, Uri senderId) async {
    final deliveredActivity = WireActivity.wireDelivered(
      actor: core.identity.id,
      to: [senderId],
      object: objectId,
    );
    await activitySender.sendActivity(deliveredActivity);
  }
}
