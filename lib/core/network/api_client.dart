import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:genie/core/config/app_config.dart';
import 'api_cache_manager.dart';
import 'auth_interceptor.dart';
import 'safe_log_interceptor.dart';

Dio createApiClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  dio.interceptors.add(CacheInterceptor());
  dio.interceptors.add(AuthInterceptor(dio));
  if (kDebugMode) {
    dio.interceptors.add(SafeLogInterceptor());
  }

  return dio;
}
