import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:genie/core/config/app_config.dart';
import 'package:genie/core/device/device_description.dart';
import 'api_cache_manager.dart';
import 'auth_interceptor.dart';
import 'device_headers_interceptor.dart';
import 'network_status.dart';
import 'network_status_interceptor.dart';
import 'retry_interceptor.dart';
import 'safe_log_interceptor.dart';

/// [onSessionEnded] is called when the server stops accepting this device's
/// session (see [AuthInterceptor.onSessionEnded]).
Dio createApiClient({void Function()? onSessionEnded}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      // A phone that cannot connect in 15 s will not in 60: fail, and let
      // the retry or the kept answer take over, instead of a frozen screen.
      connectTimeout: const Duration(seconds: 15),
      // Both the wait for the first byte and any pause between later ones.
      // A slow but working connection keeps bytes coming, so this only
      // ends a stalled request. Slow endpoints set their own.
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  final status = NetworkStatus.instance;
  status.probe = () => dio.get<void>(
    '/health',
    options: Options(
      extra: {CacheInterceptor.skipCache: true, RetryInterceptor.noRetry: true},
    ),
  );

  // Order matters for failures, which pass through in this order: the
  // status sees every one, the cache answers what it kept, and only what
  // is left is retried.
  dio.interceptors.add(NetworkStatusInterceptor(status));
  dio.interceptors.add(CacheInterceptor());
  dio.interceptors.add(RetryInterceptor(dio));
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
