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
    try {
      final response = await dio.get('/users/me');
      return UserProfile.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // On initial Google Sign-in, the backend might have a slight delay
        // syncing the new user record between the Auth and User microservices.
        await Future.delayed(const Duration(milliseconds: 2000));
        final retryResponse = await dio.get('/users/me');
        return UserProfile.fromJson(retryResponse.data);
      }
      rethrow;
    }
  }

  Future<UserProfile> updateProfile({String? username, String? phone}) async {
    final data = <String, dynamic>{};
    if (username != null) data['username'] = username;
    if (phone != null) data['phone'] = phone;

    final response = await dio.patch('/users/me', data: data);
    return UserProfile.fromJson(response.data);
  }
}
