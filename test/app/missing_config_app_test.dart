import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/app/missing_config_app.dart';

void main() {
  testWidgets('says how to start the app instead of showing nothing', (
    tester,
  ) async {
    await tester.pumpWidget(const MissingConfigApp());

    expect(find.text('No API server is set'), findsOneWidget);
    expect(find.text(MissingConfigApp.debugCommand), findsOneWidget);
  });
}
