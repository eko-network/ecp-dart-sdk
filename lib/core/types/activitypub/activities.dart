import 'package:ecp/core/types/activitypub/internal_id.dart';
import 'package:ecp/core/utils/converters.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'objects.dart';

part '../../../generated/core/types/activitypub/activities.freezed.dart';
part '../../../generated/core/types/activitypub/activities.g.dart';

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.pascal)
sealed class Activity with _$Activity {
  const Activity._();

  const factory Activity.typing({
    @InternalIdConverter() required InternalId id,
  }) = Typing;

  const factory Activity.create({
    @InternalIdConverter() required InternalId id,
    required ActivityPubObject object,
  }) = Create;

  const factory Activity.update({
    @InternalIdConverter() required InternalId id,
    required ActivityPubObject object,
  }) = Update;

  const factory Activity.delete({
    @InternalIdConverter() required InternalId id,
    @InternalIdConverter() required object,
  }) = Delete;

  const factory Activity.delivered({
    @InternalIdConverter() required InternalId id,
    @UriConverter() required Uri object,
  }) = Delivered;

  factory Activity.newTyping({InternalId? id}) =>
      Activity.typing(id: id ?? InternalId.gen());

  factory Activity.newCreate({
    InternalId? id,
    required ActivityPubObject object,
  }) =>
      Activity.create(id: id ?? InternalId.gen(), object: object);

  factory Activity.newUpdate({
    InternalId? id,
    required ActivityPubObject object,
  }) =>
      Activity.update(id: id ?? InternalId.gen(), object: object);

  factory Activity.newDelete({
    InternalId? id,
    @InternalIdConverter() required dynamic object,
  }) =>
      Activity.delete(id: id ?? InternalId.gen(), object: object);

  factory Activity.newDelivered({
    InternalId? id,
    required Uri object,
  }) =>
      Activity.delivered(id: id ?? InternalId.gen(), object: object);

  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json);

  String get type => map(
    typing: (_) => 'Typing',
    create: (_) => 'Create',
    update: (_) => 'Update',
    delete: (_) => 'Delete',
    delivered: (_) => 'Delivered',
  );

  bool get isTransient => this is Typing;
  bool get isStable => !isTransient;

  InternalId get id => map(
    typing: (v) => v.id,
    create: (v) => v.id,
    update: (v) => v.id,
    delete: (v) => v.id,
    delivered: (v) => v.id,
  );
}
