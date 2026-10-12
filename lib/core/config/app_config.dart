import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Build-time configuration, read from the `.env` / `.env.production` files.
/// See `.env.example` for the available keys.
abstract final class AppConfig {
  /// Used when the env file does not define `API_BASE_URL`.
  static const _defaultApiBaseUrl =
      'https://gateway-production-c0c5.up.railway.app';

  /// Base URL of the API gateway, without a trailing slash.
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? _defaultApiBaseUrl;
}
