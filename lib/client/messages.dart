import 'dart:convert';
import 'dart:typed_data';

import 'package:ecp/ecp.dart';
import 'package:http/http.dart' as http;

class MessageHandler {
  final EcpCore core;
  final http.Client client;
  final ActivitySender activitySender;

  MessageHandler({
    required this.core,
    required this.client,
    required this.activitySender,
  });

  MessageStore get _messageStore => core.storage.messageStore;
  ProcessedObjectStore get _processedObjectStore =>
      core.storage.processedObjectStore;

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

  Future<List<StoredMessage>> handleActivities(
    List<WireActivity> activities,
  ) async {
    final stored = <StoredMessage>[];

    for (final activity in activities) {
      final message = await handleActivity(activity);
      if (message != null) {
        stored.add(message);
      }
    }

    return stored;
  }

  Future<StoredMessage?> handleActivity(WireActivity activity) async {
    return activity.map(
      wireCreate: (wireCreate) async {
        final objectId = wireCreate.object.id;
        if (objectId == null) {
          return null;
        }
        if (await _processedObjectStore.check(objectId)) {
          return null;
        }
        await _sendDeliveredAck(objectId, wireCreate.actor);

        final result = await wireCreate.object.map(
          privateMessage: (message) async {
            final returned = await core.decryptPrivateMessage(
              ciphertext: message.content,
            );
            if (returned == null) {
              return null;
            }
            final (decrypted, groupId) = returned;

            return await handleLocalActivity(
              decrypted,
              groupId,
              objectId,
              message.actor,
              delivered: true,
            );
          },
          approvalRequest: (request) async {
            await core.storage.approvalRequestStore.saveApprovalRequest(
              StoredApprovalRequest(
                did: request.did,
                publicKey: request.publicKey,
              ),
            );
          },
          welcomeMessage: (message) async {
            final result = await core.joinFromWelcome(message.content);
            await core.storage.groupStore.saveGroup(
              groupIdBytes: result.groupId,
            );
            return null;
          },
        );
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
              attachment: [],
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
          image: (_) async {
            return null;
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
    final wireActivity = await core.encryptActivity(activity, groupId);
    final returned = await activitySender.sendActivity(wireActivity);
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
