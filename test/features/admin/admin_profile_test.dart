import 'package:flutter/material.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/profile/data/models/user_profile.dart';
import 'package:tilomnov/features/profile/presentation/screens/personal_info_page.dart';
import 'package:tilomnov/features/profile/presentation/screens/user_profile_page.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/security/presentation/screens/security_page.dart';
import 'package:tilomnov/features/subscription/presentation/view_models/subscription_providers.dart';
import 'package:tilomnov/features/chat/models/chat_models.dart';
import 'package:tilomnov/features/chat/models/chat_participant.dart';
import 'package:tilomnov/features/chat/presentation/widgets/conversation/chat_conversation_header.dart';
import 'package:tilomnov/features/chat/providers/chat_participant_providers.dart';
import 'package:tilomnov/features/home/presentation/widgets/layout/nav_tabs.dart';
import 'package:tilomnov/features/home/presentation/widgets/layout/classic_bottom_nav.dart';
import 'package:tilomnov/features/home/presentation/widgets/layout/glass_bottom_nav.dart';
import 'package:tilomnov/shared/widgets/media/admin_identity.dart';
import '../../support/test_app.dart';

void main() {
  testWidgets(
    'admin profile retains editing and security without customer settings',
    (tester) async {
      await pumpTestApp(
        tester,
        const UserProfilePage(),
        overrides: [
          userProfileProvider.overrideWith(
            (_) async => UserProfile(
              id: 'admin',
              name: 'Platform admin',
              role: 'admin',
              createdAt: DateTime(2026),
            ),
          ),
          accountSubscriptionProvider.overrideWith(
            (_) =>
                throw StateError('Admin must not load a customer subscription'),
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.byType(AdminAvatarFrame), findsOneWidget);
      expect(find.byType(AdminIdentityBadge), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      await tester.tap(find.text('Personal information'));
      await tester.pumpAndSettle();
      expect(find.byType(PersonalInfoPage), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Security'));
      await tester.pumpAndSettle();
      expect(find.byType(SecurityPage), findsOneWidget);
      expect(find.text('Change password'), findsOneWidget);
      expect(find.byIcon(Icons.devices_outlined), findsOneWidget);
      expect(find.byIcon(Icons.no_accounts_outlined), findsNothing);
      expect(find.byIcon(Icons.block), findsNothing);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byIcon(Icons.logout_outlined),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      for (final icon in [
        Icons.workspace_premium_outlined,
        Icons.privacy_tip_outlined,
        Icons.travel_explore,
        Icons.notifications_none_outlined,
      ]) {
        expect(find.byIcon(icon), findsNothing);
      }
      expect(tester.takeException(), isNull);
    },
  );

  for (final glass in [false, true]) {
    testWidgets(
      'six admin tabs fit a narrow screen with ${glass ? 'glass' : 'classic'} navigation',
      (tester) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await pumpTestApp(
          tester,
          Scaffold(
            bottomNavigationBar: glass
                ? const GlassBottomNav(isAdmin: true)
                : const ClassicBottomNav(isAdmin: true),
          ),
          overrides: [signedInOverride()],
        );
        for (final tab in navTabsFor(isAdmin: true)) {
          final label = tab.label(tester.element(find.byType(Scaffold)).l10n);
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
        }
        expect(find.text('Feed'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('other users see the admin frame and badge in a conversation', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      Scaffold(
        appBar: AppBar(
          title: const ChatConversationHeader(
            participantName: 'Support',
            chat: (userId: 'user', participantId: 'admin'),
          ),
        ),
      ),
      overrides: [
        signedInOverride(signedIn: false),
        chatParticipantProfileProvider.overrideWith(
          (_, id) async => ChatParticipantProfile.fromJson({
            'id': id,
            'name': 'Support',
            'role': 'admin',
            'createdAt': '2026-01-01T00:00:00Z',
          }),
        ),
        chatPresenceProvider.overrideWith((_, id) => const Stream.empty()),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byType(AdminAvatarFrame), findsOneWidget);
    await tester.tap(find.text('Support'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminIdentityBadge), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'admin identity survives conversation updates and defaults to ordinary user',
    () {
      final chat = ChatConversation.fromJson({
        'participantId': 'admin',
        'participantName': 'Support',
        'participantIsAdmin': true,
      });
      final message = EncryptedMessage(
        id: 'm',
        senderId: 'admin',
        recipientId: 'user',
        ciphertext: 'c',
        nonce: 'n',
        createdAt: DateTime(2026),
      );
      expect(chat.copyWith(unreadCount: 0).participantIsAdmin, isTrue);
      expect(chat.withNewMessage(message).participantIsAdmin, isTrue);
      expect(chat.withEditedLastMessage(message).participantIsAdmin, isTrue);
      expect(
        ChatConversation.fromJson({'participantId': 'user'}).participantIsAdmin,
        isFalse,
      );
      expect(
        ChatParticipantProfile.fromJson({
          'id': 'user',
          'createdAt': '2026-01-01T00:00:00Z',
        }).isAdmin,
        isFalse,
      );
    },
  );
}
