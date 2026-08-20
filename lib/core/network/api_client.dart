import 'package:dio/dio.dart';
import 'auth_interceptor.dart';

Dio createApiClient() {
  final dio = Dio(BaseOptions(
    // 10.0.2.2 is used to access localhost from an Android emulator
    baseUrl: 'https://genie-authentication.onrender.com', 
    connectTimeout: const Duration(seconds: 10),
  ));

  dio.interceptors.add(AuthInterceptor(dio));
  
  return dio;
}
