import 'package:dio/dio.dart';

class UserProfile {
  final String id;
  final String? email;
  final String? phone;
  final String role;
  final DateTime createdAt;
  final String? firebaseUid;

  UserProfile({
    required this.id,
    this.email,
    this.phone,
    required this.role,
    required this.createdAt,
    this.firebaseUid,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'] ?? 'user',
      createdAt: DateTime.parse(json['createdAt']),
      firebaseUid: json['firebaseUid'],
    );
  }

  /// Display name: email username or phone, fallback to 'User'
  String get displayName {
    if (email != null && email!.isNotEmpty) {
      return email!.split('@').first;
    }
    if (phone != null && phone!.isNotEmpty) {
      return phone!;
    }
    return 'User';
  }
}

class UserRepository {
  final Dio dio;

  UserRepository(this.dio);

  Future<UserProfile> getProfile() async {
    final response = await dio.get('/users/me');
    return UserProfile.fromJson(response.data);
  }
}
