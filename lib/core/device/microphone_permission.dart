import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:genie/core/device/system_settings.dart';

/// Whether the app may use the microphone.
enum MicrophoneAccess {
  granted,

  /// The user said no this time; asking again may work.
  denied,

  /// Only the system settings can turn it back on.
  blockedInSettings,
}

/// Asks for the microphone (voice messages, calls) where the app must ask
/// first. A browser asks on its own when recording starts, so on the web
/// and on desktop this reports [MicrophoneAccess.granted] and lets the
/// recorder fail if the user then refuses.
abstract final class MicrophonePermission {
  static bool get _asksFirst =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<MicrophoneAccess> request() async {
    if (!_asksFirst) return MicrophoneAccess.granted;

    final status = await Permission.microphone.request();
    if (status.isGranted || status.isLimited) return MicrophoneAccess.granted;
    return status.isPermanentlyDenied || status.isRestricted
        ? MicrophoneAccess.blockedInSettings
        : MicrophoneAccess.denied;
  }

  /// Opens this app's page in the system settings.
  static Future<void> openSettings() => openAppSystemSettings();
}

/// Asks for the microphone; replaced in tests.
final microphoneAccessProvider = Provider<Future<MicrophoneAccess> Function()>(
  (ref) => MicrophonePermission.request,
);
