import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:genie/features/call/data/call_notifications.dart';
import 'package:genie/features/notifications/models/push_message.dart';
import 'package:genie/features/settings/data/app_settings_storage.dart';
import 'package:genie/l10n/generated/app_localizations.dart';

/// Runs when a push arrives while the app is closed or in the background
/// (a separate isolate, without the app's state). Pushes with a visible
/// notification are shown by the system; only Android's silent call
/// pushes are handled here: ring, stop ringing, tell of a missed call.
@pragma('vm:entry-point')
Future<void> handleBackgroundPush(RemoteMessage message) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  final push = PushMessage.fromData(message.data);
  if (push is! IncomingCallPush && push is! CallEndedPush) return;

  WidgetsFlutterBinding.ensureInitialized();
  final l10n = await _appLanguage();
  final calls = CallNotifications();
  await calls.initialize();

  switch (push) {
    case IncomingCallPush(:final callId, :final callerName, :final sentAt):
      // A push held back while the phone was off is about a call long over.
      if (sentAt != null &&
          DateTime.now().difference(sentAt) > const Duration(seconds: 45)) {
        return;
      }
      await calls.showIncoming(
        callId: callId,
        title: l10n.callIncomingFrom(callerName),
        acceptLabel: l10n.callAccept,
        declineLabel: l10n.callDecline,
        data: message.data,
      );
    case CallEndedPush(:final callId, :final callerName, :final missed):
      await calls.cancel(callId);
      if (missed) {
        await calls.showMissed(
          callId: callId,
          title: l10n.callMissedFrom(callerName),
          data: message.data,
        );
      }
    default:
      break;
  }
}

/// The language the user picked in the app, else the phone's.
Future<AppLocalizations> _appLanguage() async {
  final saved = AppSettingsStorage(
    await SharedPreferences.getInstance(),
  ).readLocale();
  final code =
      saved?.languageCode ?? PlatformDispatcher.instance.locale.languageCode;
  return lookupAppLocalizations(Locale(code == 'km' ? 'km' : 'en'));
}
