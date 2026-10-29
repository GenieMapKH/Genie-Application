import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/settings/data/app_settings_storage.dart';
import 'package:tilomnov/features/settings/providers/app_settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilomnov/features/notifications/models/notification_preferences.dart';
import 'package:tilomnov/features/notifications/presentation/notification_settings_page.dart';
import 'package:tilomnov/features/notifications/providers/notification_preferences_provider.dart';
import 'package:tilomnov/features/notifications/providers/notification_providers.dart';

import 'notification_fakes.dart';

void main() {
  late FakeNotificationRepository repository;
  late FakePushMessaging messaging;
  late AppSettingsStorage settings;

  setUp(() async {
    repository = FakeNotificationRepository();
    messaging = FakePushMessaging();
    SharedPreferences.setMockInitialValues({});
    settings = AppSettingsStorage(await SharedPreferences.getInstance());
  });

  group('the switches', () {
    test('change at once and stay as the server saved them', () async {
      final notifier = NotificationPreferencesNotifier(repository: repository);
      await Future<void>.delayed(Duration.zero);

      final saved = await notifier.change(promotions: false);

      expect(saved, isTrue);
      expect(notifier.state.value!.promotions, isFalse);
      expect(repository.preferences.promotions, isFalse);
      notifier.dispose();
    });

    test('go back when the change cannot be saved', () async {
      final notifier = NotificationPreferencesNotifier(repository: repository);
      await Future<void>.delayed(Duration.zero);
      repository.error = Exception('offline');

      final saved = await notifier.change(chatMessages: false);

      expect(saved, isFalse);
      expect(notifier.state.value!.chatMessages, isTrue);
      notifier.dispose();
    });
  });

  Future<void> openPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repository),
          pushMessagingProvider.overrideWithValue(messaging),
          appSettingsStorageProvider.overrideWithValue(settings),
        ],
        child: const MaterialApp(home: NotificationSettingsPage()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows both switches and saves a change', (tester) async {
    repository.preferences = const NotificationPreferences(
      chatMessages: true,
      promotions: true,
    );
    await openPage(tester);

    expect(find.text('Chat messages'), findsOneWidget);
    expect(find.text('Offers and news'), findsOneWidget);
    expect(
      find.textContaining('Security alerts and calls are always on'),
      findsOneWidget,
    );

    await tester.tap(find.text('Offers and news'));
    await tester.pump();

    expect(repository.preferences.promotions, isFalse);
  });

  testWidgets('message text in notifications is on, and can be turned off', (
    tester,
  ) async {
    await openPage(tester);
    expect(find.text('Show message text'), findsOneWidget);
    expect(settings.readShowNotificationText(), isTrue);

    await tester.tap(find.text('Show message text'));
    await tester.pump();

    expect(settings.readShowNotificationText(), isFalse);
  });

  testWidgets('says when the phone blocks notifications for the app', (
    tester,
  ) async {
    messaging.allow = false;
    await openPage(tester);

    expect(find.text('Notifications are off for this app'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('offers to try again when the settings cannot be loaded', (
    tester,
  ) async {
    repository.error = Exception('offline');
    await openPage(tester);

    expect(
      find.text('Could not load your notification settings.'),
      findsOneWidget,
    );

    repository.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Chat messages'), findsOneWidget);
  });
}
