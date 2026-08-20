import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../storage/auth_storage.dart';

class AuthService {
  final Dio dio;
  
  AuthService(this.dio);

  // 1. Standard Registration
  Future<void> register(String email, String password) async {
    await dio.post('/auth/register', data: {
      'email': email,
      'password': password,
    });
  }

  // 2. Standard Login
  Future<void> login(String email, String password) async {
    final response = await dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    
    await AuthStorage.saveTokens(
      access: response.data['accessToken'],
      refresh: response.data['refreshToken'],
    );
  }

  // 3. The Firebase Handshake (Google / Phone OTP)
  Future<void> firebaseLogin(User firebaseUser) async {
    final idToken = await firebaseUser.getIdToken();
    
    final response = await dio.post('/auth/firebase-login', data: {
      'idToken': idToken,
    });

    await AuthStorage.saveTokens(
      access: response.data['accessToken'],
      refresh: response.data['refreshToken'],
    );
  }

  // 4. Logout
  Future<void> logout() async {
    final refreshToken = await AuthStorage.getRefreshToken();
    if (refreshToken != null) {
      try {
        await dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      } catch (e) {
        // Ignore errors, force local logout
      }
    }
    await AuthStorage.clearTokens();
  }
}
