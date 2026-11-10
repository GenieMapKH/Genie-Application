import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/shared/widgets/lists/settings_list.dart';

import '../../support/test_app.dart';

void main() {
  for (final (width, textScale) in [(390.0, 1.0), (280.0, 1.0), (280.0, 2.0)]) {
    testWidgets(
      'settings values keep arrows aligned at $width px, text $textScale',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await pumpTestApp(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SettingsSection(
                    children: [
                      for (final (title, value) in [
                        ('Appearance', 'Dark'),
                        ('Language', 'English'),
                        ('Subscription Plan', 'Free'),
                        ('Notifications', null),
                        ('Saved searches', null),
                      ])
                        SettingsRow(
                          icon: Icons.settings_outlined,
                          title: title,
                          value: value,
                          onTap: () {},
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        final arrows = find.byIcon(Icons.chevron_right);
        expect(arrows, findsNWidgets(5));
        final rightEdge = tester.getRect(arrows.first).right;
        for (var i = 1; i < 5; i++) {
          expect(tester.getRect(arrows.at(i)).right, rightEdge);
        }
        for (final (index, value) in ['Dark', 'English', 'Free'].indexed) {
          expect(
            tester.getRect(find.text(value)).right,
            tester.getRect(arrows.at(index)).left - 8,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
