import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/chat/presentation/widgets/conversation/chat_conversation_app_bar.dart';
import 'package:tilomnov/shared/widgets/glass/glass_icon_button.dart';
import 'package:tilomnov/shared/widgets/glass/glass_scope.dart';
import 'package:tilomnov/shared/widgets/media/user_avatar.dart';

import '../../support/test_app.dart';

Future<void> _pump(
  WidgetTester tester, {
  required bool glass,
  String participantName = 'Dara',
  VoidCallback? onCall,
}) {
  return pumpTestApp(
    tester,
    GlassScope(
      enabled: glass,
      child: Scaffold(
        appBar: ChatConversationAppBar(
          participantName: participantName,
          chat: null,
          onCall: onCall,
        ),
      ),
    ),
  );
}

void main() {
  for (final glass in [false, true]) {
    testWidgets('avatar and name are centered together with glass=$glass', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;

      for (final width in [360.0, 429.0]) {
        tester.view.physicalSize = Size(width, 800);
        for (final name in [
          'Dara',
          'chamnah david',
          'A very long participant name',
        ]) {
          await _pump(tester, glass: glass, participantName: name);
          final nameCenter = tester.getCenter(find.text(name));
          final avatar = tester.getRect(find.byType(UserAvatar));
          final label = tester.getRect(find.text(name));
          expect((avatar.left + label.right) / 2, closeTo(width / 2, 0.01));
          expect(avatar.right, lessThan(label.left));
          expect(
            tester.getCenter(find.byIcon(Icons.phone_outlined)).dx,
            greaterThan(nameCenter.dx),
          );
          expect(find.byIcon(Icons.more_vert), findsNothing);
          expect(tester.takeException(), isNull);
        }
      }
    });
  }

  testWidgets('with glass, back and call are round glass and call calls', (
    tester,
  ) async {
    var calls = 0;
    await _pump(tester, glass: true, onCall: () => calls++);

    expect(find.byType(GlassIconButton), findsNWidgets(2));
    expect(find.text('Dara'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.phone_outlined));
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('without glass, the bar keeps its plain buttons', (tester) async {
    await _pump(tester, glass: false, onCall: () {});

    expect(find.byType(GlassIconButton), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
  });
}
