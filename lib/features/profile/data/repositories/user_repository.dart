import 'package:dio/dio.dart';

class UserProfile {
  final String id;
  final String? email;
  final String? phone;
  final String? username;
  final String role;
  final DateTime createdAt;
  final String? firebaseUid;

  UserProfile({
    required this.id,
    this.email,
    this.phone,
    this.username,
    required this.role,
    required this.createdAt,
    this.firebaseUid,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      phone: json['phone'],
      username: json['username'],
      role: json['role'] ?? 'user',
      createdAt: DateTime.parse(json['createdAt']),
      firebaseUid: json['firebaseUid'],
    );
  }

  /// Display name: username, phone, email prefix, fallback to 'User'
  String get displayName {
    if (username != null && username!.isNotEmpty) {
      return username!;
    }
    if (phone != null && phone!.isNotEmpty) {
      return phone!;
    }
    if (email != null && email!.isNotEmpty) {
      return email!.split('@').first;
    }
    return 'User';
  }
}

class UserRepository {
  final Dio dio;

  UserRepository(this.dio);

  Future<UserProfile> getProfile() async {
    int maxRetries = 3;
    int delayMs = 1500;

    for (int i = 0; i <= maxRetries; i++) {
      try {
        final response = await dio.get('/users/me');
        return UserProfile.fromJson(response.data);
      } on DioException catch (e) {
        // On initial Google Sign-in, the backend might have a slight delay
        // syncing the new user record between the Auth and User microservices (404).
        // Or the microservice might temporarily return 502/504 while routing.
        if (i < maxRetries &&
            (e.response?.statusCode == 404 ||
                e.response?.statusCode == 502 ||
                e.response?.statusCode == 504 ||
                e.type == DioExceptionType.connectionError)) {
          await Future.delayed(Duration(milliseconds: delayMs));
          delayMs = (delayMs * 1.5).toInt(); // Exponential backoff
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Failed to load profile after multiple retries.');
  }

  Future<UserProfile> updateProfile({String? username, String? phone}) async {
    final data = <String, dynamic>{};
    if (username != null) data['username'] = username;
    if (phone != null) data['phone'] = phone;

    final response = await dio.patch('/users/me', data: data);
    return UserProfile.fromJson(response.data);
  }
}
