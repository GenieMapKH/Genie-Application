import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/notifications/application/push_notifications_controller.dart';
import 'package:genie/features/notifications/application/push_registration.dart';
import 'package:genie/features/notifications/data/notification_repository.dart';
import 'package:genie/features/notifications/data/system_notifications.dart';
import 'package:genie/features/notifications/models/push_message.dart';

import 'notification_fakes.dart';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('reading a push', () {
    test('a chat message names who sent it', () {
      final push = PushMessage.fromData({
        'type': 'chat_message',
        'senderId': 'alice',
        'senderName': 'Alice',
        'messageId': 'm1',
      });

      expect(push, isA<ChatMessagePush>());
      expect((push as ChatMessagePush).senderId, 'alice');
      expect(push.senderName, 'Alice');
    });

    test('a chat message can carry its sealed text, for Android', () {
      final sealed = PushMessage.fromData({
        'type': 'chat_message',
        'senderId': 'alice',
        'senderName': 'Alice',
        'messageId': 'm1',
        'recipientId': 'bob',
        'ciphertext': 'sealed',
        'nonce': 'n',
      });
      final generic = PushMessage.fromData({
        'type': 'chat_message',
        'senderId': 'alice',
        'senderName': 'Alice',
        'messageId': 'm1',
      });
      final half = PushMessage.fromData({
        'type': 'chat_message',
        'senderId': 'alice',
        'messageId': 'm1',
        'recipientId': 'bob',
        'ciphertext': 'sealed',
      });

      expect((sealed as ChatMessagePush).isSealed, isTrue);
      expect(sealed.ciphertext, 'sealed');
      expect((generic as ChatMessagePush).isSealed, isFalse);
      expect((half as ChatMessagePush).isSealed, isFalse);
      expect(
        ChatMessagePush.withoutSealedText({
          'senderId': 'alice',
          'ciphertext': 'sealed',
          'nonce': 'n',
        }),
        {'senderId': 'alice'},
      );
    });

    test('a promotion opens a listing, or a web page over HTTPS only', () {
      final listing = PushMessage.fromData({
        'type': 'promotion',
        'promotionId': 'p1',
        'propertyId': 'prop-1',
      });
      final unsafe = PushMessage.fromData({
        'type': 'promotion',
        'promotionId': 'p2',
        'url': 'http://example.com/deal',
      });
      final page = PushMessage.fromData({
        'type': 'promotion',
        'promotionId': 'p3',
        'url': 'https://example.com/deal',
      });

      expect((listing as PromotionPush).propertyId, 'prop-1');
      expect((unsafe as PromotionPush).url, isNull);
      expect(
        (page as PromotionPush).url,
        Uri.parse('https://example.com/deal'),
      );
    });

    test('calls carry who is calling and whether it was missed', () {
      final ringing = PushMessage.fromData({
        'type': 'call_incoming',
        'callId': 'c1',
        'callerId': 'alice',
        'callerName': 'Alice',
        'sentAt': '2026-10-19T10:00:00.000Z',
      });
      final ended = PushMessage.fromData({
        'type': 'call_ended',
        'callId': 'c1',
        'missed': 'true',
      });

      expect(
        (ringing as IncomingCallPush).sentAt,
        DateTime.utc(2026, 10, 19, 10),
      );
      expect((ended as CallEndedPush).missed, isTrue);
    });

    test('anything incomplete or unknown only opens the app', () {
      expect(PushMessage.fromData({}), isA<UnknownPush>());
      expect(
        PushMessage.fromData({'type': 'chat_message'}),
        isA<UnknownPush>(),
      );
      expect(PushMessage.fromData({'type': 'lottery'}), isA<UnknownPush>());
    });
  });

  group('registering this device', () {
    late FakePushMessaging messaging;
    late FakeNotificationRepository repository;

    PushRegistration registration({
      PushPlatform? platform = PushPlatform.android,
    }) => PushRegistration(
      messaging: messaging,
      repository: repository,
      platform: platform,
    );

    setUp(() {
      messaging = FakePushMessaging();
      repository = FakeNotificationRepository();
    });

    test('registers its token, kind and language once allowed', () async {
      final registered = await registration().start(locale: 'km');

      expect(registered, isTrue);
      expect(repository.registered.single, (
        token: 'token-1',
        platform: PushPlatform.android,
        locale: 'km',
      ));
    });

    test('registers nothing when the user says no', () async {
      messaging.allow = false;

      expect(await registration().start(locale: 'en'), isFalse);
      expect(repository.registered, isEmpty);
    });

    test('a device without pushes (desktop) is never asked', () async {
      expect(await registration(platform: null).start(locale: 'en'), isFalse);
      expect(repository.registered, isEmpty);
    });

    test('follows a token that Firebase replaced', () async {
      await registration().start(locale: 'en');

      messaging.refreshes.add('token-2');
      await _settle();

      expect(repository.registered.map((r) => r.token), ['token-1', 'token-2']);
    });

    test('signing out removes the device and forgets the token', () async {
      final device = registration();
      await device.start(locale: 'en');

      await device.stop();

      expect(repository.removed, ['token-1']);
      expect(messaging.deletedTokens, 1);
    });

    test(
      'signing out still forgets the token when the server is down',
      () async {
        final device = registration();
        await device.start(locale: 'en');
        repository.error = Exception('offline');

        await device.stop();

        expect(messaging.deletedTokens, 1);
      },
    );
  });

  group('a push reaching the app', () {
    late FakePushMessaging messaging;
    late FakeSystemNotifications system;
    late List<PushMessage> opened;
    late List<PushMessage> calls;
    late bool Function(PushMessage) filter;
    late PushNotificationsController controller;
    ChatPushText? chatText;
    late List<ChatMessagePush> written;

    setUp(() async {
      messaging = FakePushMessaging();
      system = FakeSystemNotifications();
      opened = [];
      calls = [];
      written = [];
      filter = (_) => true;
      chatText = (message) async {
        written.add(message);
        return (title: message.senderName, body: 'see you at 5');
      };
      controller = PushNotificationsController(
        messaging: messaging,
        system: system,
        open: (message) async => opened.add(message),
        shouldShow: (message) => filter(message),
        onCallPush: calls.add,
        chatText: (message) => chatText!(message),
      );
    });

    tearDown(() => controller.dispose());

    const chat = (
      data: {
        'type': 'chat_message',
        'senderId': 'alice',
        'senderName': 'Alice',
      },
      title: 'Alice',
      body: 'New message',
    );

    test('while open, a chat message is shown, one per sender', () async {
      await controller.start();

      messaging.foreground.add(chat);
      await _settle();

      expect(system.shown.single.title, 'Alice');
      expect(system.shown.single.channel, NotificationChannel.chatMessages);
      expect(system.shown.single.tag, 'chat:alice');
    });

    const sealedChat = (
      data: {
        'type': 'chat_message',
        'senderId': 'alice',
        'senderName': 'Alice',
        'messageId': 'm1',
        'recipientId': 'bob',
        'ciphertext': 'sealed',
        'nonce': 'n',
      },
      title: null,
      body: null,
    );

    test('a chat message with its sealed text is written by the app', () async {
      await controller.start();

      messaging.foreground.add(sealedChat);
      await _settle();
      await _settle();

      expect(written.single.ciphertext, 'sealed');
      expect(system.shown.single.title, 'Alice');
      expect(system.shown.single.body, 'see you at 5');
      expect(system.shown.single.channel, NotificationChannel.chatMessages);
      expect(system.shown.single.tag, 'chat:alice');
    });

    test('its sealed text is not kept in the notification', () async {
      await controller.start();

      messaging.foreground.add(sealedChat);
      await _settle();
      await _settle();

      expect(system.shownData.single.keys, isNot(contains('ciphertext')));
      expect(system.shownData.single['senderId'], 'alice');
    });

    test('and not shown when that conversation is on screen', () async {
      filter = (message) => message is! ChatMessagePush;
      await controller.start();

      messaging.foreground.add(sealedChat);
      await _settle();
      await _settle();

      expect(written, isEmpty);
      expect(system.shown, isEmpty);
    });

    test('a failure writing it shows nothing and does not crash', () async {
      chatText = (_) async => throw Exception('cannot open');
      await controller.start();

      messaging.foreground.add(sealedChat);
      await _settle();
      await _settle();

      expect(system.shown, isEmpty);
    });

    test('not when that conversation is already on screen', () async {
      filter = (message) => message is! ChatMessagePush;
      await controller.start();

      messaging.foreground.add(chat);
      await _settle();

      expect(system.shown, isEmpty);
    });

    test('a call push goes to the call screen, not the tray', () async {
      await controller.start();

      messaging.foreground.add((
        data: {'type': 'call_incoming', 'callId': 'c1', 'callerId': 'alice'},
        title: null,
        body: null,
      ));
      await _settle();

      expect(calls.single, isA<IncomingCallPush>());
      expect(system.shown, isEmpty);
    });

    test(
      'tapping one, in the tray or in the app, opens what it is about',
      () async {
        await controller.start();

        messaging.opened.add(chat);
        await _settle();
        system.tap!({'type': 'security_sign_in'});
        await _settle();

        expect(opened[0], isA<ChatMessagePush>());
        expect(opened[1], isA<SignInAlertPush>());
      },
    );

    test(
      'a notification that started the app is opened once it is up',
      () async {
        messaging.launch = chat;

        await controller.start();

        expect(opened.single, isA<ChatMessagePush>());
      },
    );
  });
}
