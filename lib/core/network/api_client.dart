import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_interceptor.dart';

Dio createApiClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl:
          dotenv.env['API_BASE_URL'] ??
          'https://geniebackend-production-ef56.up.railway.app',
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  dio.interceptors.add(AuthInterceptor(dio));
  dio.interceptors.add(
    LogInterceptor(
      responseBody: true,
      error: true,
      requestHeader: true,
      requestBody: true,
    ),
  );

  return dio;
}
