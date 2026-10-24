import 'package:dio/dio.dart';

import 'package:genie/features/notifications/models/notification_preferences.dart';

/// Where a device registers for pushes, as the server names it.
enum PushPlatform { android, ios, web }

/// The notification service's API.
class NotificationRepository {
  final Dio dio;

  NotificationRepository({required this.dio});

  /// This device can be reached with [token], in [locale] ('en' or 'km').
  Future<void> registerDevice({
    required String token,
    required PushPlatform platform,
    required String locale,
  }) async {
    await dio.post(
      '/notifications/devices',
      data: {'token': token, 'platform': platform.name, 'locale': locale},
    );
  }

  /// Stops pushes to this device, e.g. before signing out.
  Future<void> removeDevice(String token) async {
    await dio.post('/notifications/devices/remove', data: {'token': token});
  }

  Future<NotificationPreferences> fetchPreferences() async {
    final response = await dio.get('/notifications/preferences');
    return NotificationPreferences.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  /// Saves only what is given, and returns what the server now holds.
  Future<NotificationPreferences> updatePreferences({
    bool? chatMessages,
    bool? promotions,
    bool? savedSearchAlerts,
    bool? followedListings,
    bool? savedListingUpdates,
  }) async {
    final response = await dio.patch(
      '/notifications/preferences',
      data: {
        'chatMessages': ?chatMessages,
        'promotions': ?promotions,
        'savedSearchAlerts': ?savedSearchAlerts,
        'followedListings': ?followedListings,
        'savedListingUpdates': ?savedListingUpdates,
      },
    );
    return NotificationPreferences.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
