import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/features/chat/models/chat_participant.dart';
import 'package:tilomnov/features/chat/presentation/widgets/conversation/chat_presence_label.dart';
import 'package:tilomnov/features/chat/providers/chat_participant_providers.dart';
import 'package:tilomnov/features/chat/providers/chat_service_providers.dart';

import 'chat_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  group('describePresence', () {
    final now = DateTime(2026, 5, 20, 15, 30);

    String seen(DateTime lastSeenAt) => describePresence(
      _en,
      ChatPresence(userId: peer, online: false, lastSeenAt: lastSeenAt),
      now: now,
    );

    test('online', () {
      expect(
        describePresence(_en, const ChatPresence(userId: peer, online: true)),
        'Online',
      );
    });

    test('says nothing about someone who was never seen', () {
      expect(
        describePresence(_en, const ChatPresence(userId: peer, online: false)),
        '',
      );
    });

    test('recent absences are relative', () {
      expect(
        seen(now.subtract(const Duration(seconds: 20))),
        'Last seen just now',
      );
      expect(
        seen(now.subtract(const Duration(minutes: 5))),
        'Last seen 5 min ago',
      );
      expect(
        seen(now.subtract(const Duration(minutes: 59))),
        'Last seen 59 min ago',
      );
    });

    test('older ones name the day', () {
      expect(seen(DateTime(2026, 5, 20, 9, 5)), 'Last seen today at 09:05');
      expect(
        seen(DateTime(2026, 5, 19, 23, 40)),
        'Last seen yesterday at 23:40',
      );
      expect(seen(DateTime(2026, 5, 1, 12)), 'Last seen 1/5/2026');
    });
  });

  group('chatPresenceProvider', () {
    late FakeChatSocket socket;
    late ProviderContainer container;
    late List<ChatPresence> seen;

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    setUp(() {
      socket = FakeChatSocket();
      container = ProviderContainer(
        overrides: [chatSocketServiceProvider.overrideWithValue(socket)],
      );
      seen = [];
      container.listen(chatPresenceProvider(peer), (_, next) {
        final presence = next.valueOrNull;
        if (presence != null) seen.add(presence);
      });
    });

    test('starts with the current status, then follows changes', () async {
      await settle();
      socket.presence.add(const ChatPresence(userId: peer, online: true));
      await settle();

      expect(seen.map((p) => p.online), [false, true]);
    });

    test("ignores other people's status", () async {
      await settle();
      socket.presence.add(const ChatPresence(userId: 'someone', online: true));
      await settle();

      expect(seen, hasLength(1));
    });

    test('asks again after reconnecting, since the server forgot', () async {
      await settle();
      socket.presenceOf = (userId) =>
          ChatPresence(userId: userId, online: true);

      socket.connections.add(null);
      await settle();

      expect(socket.watching, [peer, peer]);
      expect(seen.last.online, isTrue);
    });

    test('stops watching when nobody is looking', () async {
      await settle();

      container.dispose();

      expect(socket.watching, isEmpty);
    });
  });
}
