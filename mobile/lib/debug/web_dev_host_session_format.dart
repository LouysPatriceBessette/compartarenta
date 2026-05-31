// Pure-Dart session format constants shared by the Flutter app and
// web_dev_session_server.dart (VM — must not import Flutter or Drift).

/// Bump when export/import Drift snapshot layout changes.
const int kWebDevHostSessionVersion = 3;

/// Session JSON `version` accepted on PUT by [web_dev_session_server.dart].
bool isAcceptedDevHostSessionVersion(Object? version) =>
    version is int && version >= 2;
