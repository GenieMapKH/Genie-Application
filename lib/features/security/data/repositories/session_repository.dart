import 'package:dio/dio.dart';

import 'package:tilomnov/features/security/data/models/device_session.dart';

/// API access for the devices signed in to the account. A sign-out takes
/// effect on the other device at once.
class SessionRepository {
  final Dio dio;

  SessionRepository(this.dio);

  Future<DeviceList> fetchSessions() async {
    final response = await dio.get('/auth/sessions');
    return DeviceList.fromJson(response.data as Map<String, dynamic>);
  }

  /// The server refuses (403) while this device is too new to sign others
  /// out, see [DeviceList.canSignOutOthers].
  Future<void> signOut(String sessionId) async {
    await dio.delete('/auth/sessions/$sessionId');
  }

  /// Signs every device out, this one included. Refused like [signOut].
  Future<void> signOutAll() async {
    await dio.post('/auth/logout-all');
  }
}
