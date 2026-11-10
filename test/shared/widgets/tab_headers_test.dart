import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/feed/presentation/screens/feed_page.dart';
import 'package:tilomnov/features/feed/presentation/widgets/feed_header.dart';
import 'package:tilomnov/features/property/presentation/screens/my_properties_page.dart';
import 'package:tilomnov/features/property/presentation/screens/saved_properties_page.dart';
import 'package:tilomnov/shared/widgets/glass/glass_icon_button.dart';
import 'package:tilomnov/shared/widgets/glass/glass_scope.dart';
import 'package:tilomnov/shared/widgets/layout/app_header_bar.dart';

import '../../support/test_app.dart';

void main() {
  for (final width in [320.0, 800.0]) {
    for (final glass in [false, true]) {
      testWidgets('tab headers align at $width wide, glass: $glass', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        Offset? backCenter;
        var backs = 0;
        void back() => backs++;

        for (final page in [
          FeedPage(isEmbedded: true, onBackPressed: back),
          SavedPropertiesPage(isEmbedded: true, onBackPressed: back),
          MyPropertiesPage(isEmbedded: true, onBackPressed: back),
        ]) {
          await pumpTestApp(
            tester,
            Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(padding: const EdgeInsets.only(top: 32)),
                child: GlassScope(enabled: glass, child: page),
              ),
            ),
            overrides: [signedInOverride(signedIn: false)],
            savedSettings: const {'settings.theme_mode': 'dark'},
          );
          final header = find.byType(AppHeaderBar);
          final loadingRect = tester.getRect(header);
          await tester.pumpAndSettle();
          expect(tester.getRect(header), loadingRect);
          expect(loadingRect.top, 32);
          expect(loadingRect.height, 56);

          final arrow = glass
              ? find.byType(GlassIconButton)
              : find.byIcon(Icons.arrow_back);
          backCenter ??= tester.getCenter(arrow);
          expect(tester.getCenter(arrow), backCenter);
          await tester.tap(arrow);

          if (page is FeedPage) {
            final banner = tester.widget<ColoredBox>(
              find
                  .descendant(
                    of: find.byType(FeedHeader),
                    matching: find.byType(ColoredBox),
                  )
                  .first,
            );
            expect(banner.color, tester.element(header).colors.background);
          }
          expect(tester.takeException(), isNull);
        }
        expect(backs, 3);
      });
    }
  }
}
