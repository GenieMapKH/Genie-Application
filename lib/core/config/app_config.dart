/// Build-time configuration. The values are compiled into the app from an
/// env file that is NOT shipped with it:
///
///     flutter run --dart-define-from-file=.env
///     flutter build apk --release --dart-define-from-file=.env.production
///
/// See `.env.example` for the available keys. A compiled-in value can still be
/// dug out of the app by someone determined, so only public values belong
/// here, never a secret.
abstract final class AppConfig {
  /// Used by a build that was not given `API_BASE_URL`.
  static const _defaultApiBaseUrl =
      'https://gateway-production-c0c5.up.railway.app';

  /// From the env file, or `--dart-define=API_BASE_URL=...` for one run.
  /// Devices only reach each other in chat when they use the same server.
  static const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// False for a build that was started without an env file, which falls
  /// back to the production server.
  static const hasApiBaseUrl = _apiBaseUrl != '';

  /// Base URL of the API gateway, without a trailing slash.
  static const apiBaseUrl = hasApiBaseUrl ? _apiBaseUrl : _defaultApiBaseUrl;

  /// The public half of the Firebase "Web Push certificates" key pair
  /// (`FCM_WEB_VAPID_KEY`). Only a browser needs it to receive pushes; it is
  /// public by design, so it may be compiled in.
  static const webPushKey = String.fromEnvironment('FCM_WEB_VAPID_KEY');

  static const hasWebPushKey = webPushKey != '';
}
