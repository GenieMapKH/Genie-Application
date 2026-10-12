import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Build-time configuration, read from the `.env` / `.env.production` files.
/// See `.env.example` for the available keys.
abstract final class AppConfig {
  /// Used when the env file does not define `API_BASE_URL`.
  static const _defaultApiBaseUrl =
      'https://gateway-production-c0c5.up.railway.app';

  /// Set with `--dart-define=API_BASE_URL=...`. It wins over the env file,
  /// so one build can be pointed at another server without editing files.
  /// Devices only reach each other in chat when they use the same server.
  static const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// Base URL of the API gateway, without a trailing slash.
  static String get apiBaseUrl => _apiBaseUrlOverride.isNotEmpty
      ? _apiBaseUrlOverride
      : dotenv.env['API_BASE_URL'] ?? _defaultApiBaseUrl;
}
