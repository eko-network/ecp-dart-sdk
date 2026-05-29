import 'package:ecp/core/default.dart';
import 'package:ecp/core/utils/converters.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part '../../../generated/core/types/activitypub/wire_activities.freezed.dart';
part '../../../generated/core/types/activitypub/wire_activities.g.dart';

abstract interface class HasWireActivity {
  Object? get context;
  Uri? get id;
  Uri get actor;
  List<Uri> get to;
}

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.pascal)
sealed class WireActivity with _$WireActivity implements HasWireActivity {
  const WireActivity._();

  @FreezedUnionValue('Take')
  const factory WireActivity.wireTake({
    @JsonKey(name: '@context') @Default(ecpJsonLdContext) Object? context,
    @UriConverter() Uri? id,
    @UriConverter() required List<Uri> to,
    @UriConverter() required Uri actor,
  }) = WireTake;

  @FreezedUnionValue('Create')
  const factory WireActivity.wireCreate({
    @JsonKey(name: '@context') @Default(ecpJsonLdContext) Object? context,
    @UriConverter() Uri? id,
    @UriConverter() required List<Uri> to,
    required WireObject object,
    @UriConverter() required Uri actor,
  }) = WireCreate;

  @FreezedUnionValue('Delivered')
  const factory WireActivity.wireDelivered({
    @JsonKey(name: '@context') @Default(ecpJsonLdContext) Object? context,
    @UriConverter() Uri? id,
    @UriConverter() required List<Uri> to,
    @UriConverter() required Uri object,
    @UriConverter() required Uri actor,
  }) = WireDelivered;

  factory WireActivity.fromJson(Map<String, dynamic> json) =>
      _$WireActivityFromJson(json);

  @override
  Object? get context => map(
        wireTake: (v) => v.context,
        wireCreate: (v) => v.context,
        wireDelivered: (v) => v.context,
      );

  @override
  Uri? get id => map(
        wireTake: (v) => v.id,
        wireCreate: (v) => v.id,
        wireDelivered: (v) => v.id,
      );

  @override
  List<Uri> get to => map(
        wireTake: (v) => v.to,
        wireCreate: (v) => v.to,
        wireDelivered: (v) => v.to,
      );

  @override
  Uri get actor => map(
        wireTake: (v) => v.actor,
        wireCreate: (v) => v.actor,
        wireDelivered: (v) => v.actor,
      );

  String get type => map(
        wireTake: (_) => 'Take',
        wireCreate: (_) => 'Create',
        wireDelivered: (_) => 'Delivered',
      );
}
