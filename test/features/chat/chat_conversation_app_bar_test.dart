import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/chat/presentation/widgets/conversation/chat_conversation_app_bar.dart';
import 'package:tilomnov/shared/widgets/glass/glass_icon_button.dart';
import 'package:tilomnov/shared/widgets/glass/glass_scope.dart';

import '../../support/test_app.dart';

Future<void> _pump(
  WidgetTester tester, {
  required bool glass,
  VoidCallback? onCall,
}) {
  return pumpTestApp(
    tester,
    GlassScope(
      enabled: glass,
      child: Scaffold(
        appBar: ChatConversationAppBar(
          participantId: 'u-2',
          participantName: 'Dara',
          chat: null,
          onCall: onCall,
          showMenu: false,
        ),
      ),
    ),
  );
}

void main() {
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
