import 'package:permission_handler/permission_handler.dart';

/// Opens this app's page in the phone's settings, where the user turns a
/// permission (microphone, notifications) back on.
Future<void> openAppSystemSettings() => openAppSettings();
