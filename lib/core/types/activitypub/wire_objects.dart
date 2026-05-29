import 'dart:typed_data';

import 'package:ecp/core/types/activitypub/context.dart';
import 'package:ecp/core/utils/converters.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part '../../../generated/core/types/activitypub/wire_objects.freezed.dart';
part '../../../generated/core/types/activitypub/wire_objects.g.dart';

abstract interface class HasWireObject {
  Object? get context;
  Uri? get id;
  Uri get actor;
  List<Uri> get to;
  Uint8List get content;
}

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.pascal)
sealed class WireObject with _$WireObject implements HasWireObject {
  const WireObject._();

  const factory WireObject.privateMessage({
    @JsonKey(name: '@context') @Default(ecpJsonLdContext) Object? context,
    @UriConverter() Uri? id,
    @UriConverter() required Uri actor,
    @UriConverter() required List<Uri> to,
    @Uint8ListConverter() required Uint8List content,
  }) = PrivateMessage;

  const factory WireObject.welcomeMessage({
    @JsonKey(name: '@context') @Default(ecpJsonLdContext) Object? context,
    @UriConverter() Uri? id,
    @UriConverter() required Uri actor,
    @UriConverter() required List<Uri> to,
    @Uint8ListConverter() required Uint8List content,
  }) = WelcomeMessage;

  factory WireObject.fromJson(Map<String, dynamic> json) =>
      _$WireObjectFromJson(json);

  @override
  Object? get context =>
      map(privateMessage: (v) => v.context, welcomeMessage: (v) => v.context);

  @override
  Uri? get id => map(privateMessage: (v) => v.id, welcomeMessage: (v) => v.id);

  @override
  Uri get actor =>
      map(privateMessage: (v) => v.actor, welcomeMessage: (v) => v.actor);

  @override
  List<Uri> get to =>
      map(privateMessage: (v) => v.to, welcomeMessage: (v) => v.to);

  String get type => map(
    privateMessage: (_) => 'PrivateMessage',
    welcomeMessage: (_) => 'WelcomeMessage',
  );

  @override
  Uint8List get content =>
      map(privateMessage: (v) => v.content, welcomeMessage: (v) => v.content);
}
