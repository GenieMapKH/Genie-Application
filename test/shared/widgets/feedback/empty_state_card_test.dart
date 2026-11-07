import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tilomnov/features/chat/presentation/screens/chat_list_page.dart';
import 'package:tilomnov/features/chat/providers/chat_provider.dart';
import 'package:tilomnov/features/feed/presentation/screens/feed_page.dart';
import 'package:tilomnov/features/property/presentation/screens/my_properties_page.dart';
import 'package:tilomnov/features/property/presentation/screens/saved_properties_page.dart';
import 'package:tilomnov/features/property/presentation/view_models/own_listings.dart';
import 'package:tilomnov/features/property/presentation/view_models/own_listings_providers.dart';
import 'package:tilomnov/features/property/presentation/widgets/my_properties/property_tabs.dart';
import 'package:tilomnov/shared/widgets/feedback/empty_state_card.dart';

import '../../../features/chat/chat_fakes.dart';
import '../../../support/test_app.dart';

class _FilteredListings extends PropertiesNotifier {
  @override
  Future<OwnListings> build() async =>
      const OwnListings(countByStatus: {'Draft': 1});
}

void main() {
  for (final (language, theme) in const [
    ('en', 'light'),
    ('km', 'light'),
    ('en', 'dark'),
    ('km', 'dark'),
  ]) {
    testWidgets(
      'empty main tabs have identical card bounds: $language $theme',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Rect? expected;
        for (final page in const [
          FeedPage(isEmbedded: true),
          SavedPropertiesPage(isEmbedded: true),
          ChatListPage(isEmbedded: true),
          MyPropertiesPage(isEmbedded: true),
        ]) {
          await pumpTestApp(
            tester,
            page,
            savedSettings: {
              'settings.language': language,
              'settings.theme_mode': theme,
            },
            overrides: [
              signedInOverride(signedIn: false),
              conversationsProvider.overrideWith(
                (_) => ConversationsNotifier(
                  repository: FakeChatRepository(),
                  socketService: FakeChatSocket(),
                  cipher: null,
                ),
              ),
            ],
          );
          await tester.pumpAndSettle();
          final card = find
              .descendant(
                of: find.byType(EmptyStateCard),
                matching: find.byType(DecoratedBox),
              )
              .first;
          final bounds = tester.getRect(card);
          expected ??= bounds;
          expect(bounds, expected, reason: '${page.runtimeType}');
          expect(bounds.height, 320);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }
      },
    );
  }

  testWidgets('empty status filter keeps the other listing tabs', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const MyPropertiesPage(isEmbedded: true),
      overrides: [propertiesProvider.overrideWith(_FilteredListings.new)],
    );
    await tester.pumpAndSettle();
    expect(find.byType(PropertyTabs), findsOneWidget);
    expect(find.byType(EmptyStateCard), findsOneWidget);
    await tester.tap(find.text('Draft (1)'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text scrolls without clipping', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var pressed = false;
    await pumpTestApp(
      tester,
      Scaffold(
        body: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: ListView(
            children: [
              EmptyStateCard(
                icon: Icons.dynamic_feed_rounded,
                title: 'Your feed is empty',
                hint: 'Follow property owners to see their latest listings.',
                action: FilledButton(
                  onPressed: () => pressed = true,
                  child: const Text('Explore'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Explore'));
    await tester.tap(find.text('Explore'));
    expect(pressed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
