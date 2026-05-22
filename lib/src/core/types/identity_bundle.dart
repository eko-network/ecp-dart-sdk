import 'dart:typed_data';
import 'package:ecp/src/core/types/storage.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:openmls/openmls.dart';
import '../utils/b64.dart';
import 'mls_credential_record.dart';

part '../../../generated/src/core/types/identity_bundle.g.dart';

@JsonSerializable()
class IdentityBundle {
  @Uint8ListConverter()
  final Uint8List credentialIdentity;
  @Uint8ListConverter()
  final Uint8List credential;
  @Uint8ListConverter()
  final Uint8List signer;
  @Uint8ListConverter()
  final Uint8List signerPublicKey;
  @Uint8ListConverter()
  final List<Uint8List> keyPackages;

  const IdentityBundle({
    required this.credentialIdentity,
    required this.credential,
    required this.signer,
    required this.signerPublicKey,
    required this.keyPackages,
  });

  factory IdentityBundle.fromJson(Map<String, dynamic> json) =>
      _$IdentityBundleFromJson(json);

  Map<String, dynamic> toJson() => _$IdentityBundleToJson(this);
}
