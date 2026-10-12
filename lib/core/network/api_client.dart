import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:genie/core/config/app_config.dart';
import 'package:genie/core/device/device_description.dart';
import 'api_cache_manager.dart';
import 'auth_interceptor.dart';
import 'device_headers_interceptor.dart';
import 'safe_log_interceptor.dart';

/// [onSessionEnded] is called when the server stops accepting this device's
/// session (see [AuthInterceptor.onSessionEnded]).
Dio createApiClient({void Function()? onSessionEnded}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  dio.interceptors.add(CacheInterceptor());
  dio.interceptors.add(AuthInterceptor(dio, onSessionEnded: onSessionEnded));
  // Not on the web: a browser would need the server to allow these headers.
  if (!kIsWeb) {
    dio.interceptors.add(DeviceHeadersInterceptor(DeviceDescriptionReader()));
  }
  if (kDebugMode) {
    dio.interceptors.add(SafeLogInterceptor());
  }

  return dio;
}
