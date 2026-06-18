import 'dart:io';

import 'package:openmls/openmls.dart';

/// Initializes openmls, resolving the native library path on desktop platforms
/// where Flutter and Dart CLI use layouts that openmls does not detect.
Future<void> initOpenmls() async {
  if (!_usesCustomLibraryResolution()) {
    await Openmls.init();
    return;
  }

  final libraryPath = resolveOpenmlsLibraryPath();
  if (libraryPath == null) {
    throw StateError(
      'Could not find the openmls native library. '
      'Build the app first so native assets are available '
      '(for example: flutter pub get, then flutter run or flutter build linux).',
    );
  }

  await Openmls.init(libraryPath: libraryPath);
}

bool _usesCustomLibraryResolution() {
  return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
}

/// Returns an absolute path to the openmls native library when it can be found.
String? resolveOpenmlsLibraryPath() {
  if (!_usesCustomLibraryResolution()) {
    return null;
  }
  final libraryName = _libraryNameForPlatform();
  if (libraryName == null) {
    return null;
  }

  for (final candidate in _libraryPathCandidates(libraryName)) {
    final file = File(candidate);
    if (file.existsSync()) {
      return file.absolute.path;
    }
  }

  return null;
}

String? _libraryNameForPlatform() {
  if (Platform.isMacOS || Platform.isIOS) {
    return 'libopenmls_frb.dylib';
  }
  if (Platform.isLinux || Platform.isAndroid) {
    return 'libopenmls_frb.so';
  }
  if (Platform.isWindows) {
    return 'openmls_frb.dll';
  }
  return null;
}

Iterable<String> _libraryPathCandidates(String libraryName) sync* {
  try {
    final executableDir = File(Platform.resolvedExecutable).parent.path;
    yield '$executableDir/lib/$libraryName';
    yield '$executableDir/../lib/$libraryName';
  } on Object {
    // Platform.resolvedExecutable is unavailable in some test environments.
  }

  yield '.dart_tool/lib/$libraryName';

  for (final nativeAssetsDir in _nativeAssetsDirectories()) {
    yield '$nativeAssetsDir/$libraryName';
  }

  for (final hooksDir in _openmlsHooksBuildDirectories()) {
    yield '$hooksDir/$libraryName';
  }
}

List<String> _nativeAssetsDirectories() {
  if (Platform.isLinux) {
    return ['build/native_assets/linux'];
  }
  if (Platform.isMacOS) {
    return ['build/native_assets/macos'];
  }
  if (Platform.isWindows) {
    return ['build/native_assets/windows'];
  }
  return const [];
}

List<String> _openmlsHooksBuildDirectories() {
  const sharedRoot = '.dart_tool/hooks_runner/shared/openmls/build';
  if (Platform.isLinux) {
    return ['$sharedRoot/linux-x64', '$sharedRoot/linux-arm64'];
  }
  if (Platform.isMacOS) {
    return ['$sharedRoot/macos-x64', '$sharedRoot/macos-arm64'];
  }
  if (Platform.isWindows) {
    return ['$sharedRoot/windows-x64'];
  }
  return const [];
}
