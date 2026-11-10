import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/admin/data/admin_record.dart';
import 'package:tilomnov/features/admin/presentation/admin_record_tile.dart';
import 'package:tilomnov/shared/widgets/media/user_avatar.dart';

import '../../support/test_app.dart';

void main() {
  testWidgets(
    'users have avatars, accurate badges and icons on account fields',
    (tester) async {
      await pumpTestApp(
        tester,
        Scaffold(
          body: ListView(
            children: const [
              AdminRecordTile(
                record: AdminRecord({
                  'id': 'u1',
                  'username': 'sokha',
                  'name': 'Sokha Chan',
                  'email': 'sokha@example.com',
                  'phone': '+85512345678',
                  'emailVerified': true,
                  'phoneVerified': false,
                  'deactivatedAt': null,
                }),
              ),
              AdminRecordTile(
                record: AdminRecord({
                  'id': 'u2',
                  'username': null,
                  'name': '',
                  'emailVerified': false,
                  'deactivatedAt': '2026-11-09T10:00:00Z',
                }),
              ),
            ],
          ),
        ),
        savedSettings: const {'settings.theme_mode': 'dark'},
      );
      await tester.pumpAndSettle();
      expect(find.byType(UserAvatar), findsNWidgets(2));
      expect(find.text('S'), findsOneWidget);
      expect(find.text('?'), findsOneWidget);
      expect(find.text('Active account'), findsOneWidget);
      expect(find.text('Deactivated'), findsOneWidget);
      expect(find.text('Email verified'), findsOneWidget);
      expect(find.text('Phone verified'), findsNothing);
      expect(find.byIcon(Icons.mark_email_read_outlined), findsOneWidget);
      await tester.tap(find.text('@sokha'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.mail_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
      expect(find.byIcon(Icons.alternate_email_rounded), findsOneWidget);
      expect(find.text('+85512345678'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
