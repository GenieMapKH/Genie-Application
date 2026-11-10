import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tilomnov/features/call/data/call_notifications.dart';
import 'package:tilomnov/features/notifications/data/system_notifications.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('on Android a tagged notification takes the id Firebase shows a '
      'push with, so it replaces the one the system showed', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(LocalSystemNotifications.notificationIdOf('chat:alice'), 0);
    // An untagged one gets an id of its own, never Firebase's.
    expect(LocalSystemNotifications.notificationIdOf(null), isNonNegative);
  });

  test('on iOS each tag keeps its own id, so senders do not replace '
      'each other', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(
      LocalSystemNotifications.notificationIdOf('chat:alice'),
      isNot(LocalSystemNotifications.notificationIdOf('chat:bob')),
    );
    expect(
      LocalSystemNotifications.notificationIdOf('chat:alice'),
      LocalSystemNotifications.notificationIdOf('chat:alice'),
    );
  });

  test('a call uses the tag the server names it by', () {
    expect(CallNotifications.tagOf('c1'), 'call:c1');
    expect(CallNotifications.idOf('c1'), 3118);
    expect(CallNotifications.idOf('c2'), isNot(CallNotifications.idOf('c1')));
    expect(CallNotifications.idOf('c1'), isNot(0));
  });
}
