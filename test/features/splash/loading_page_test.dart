import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/splash/presentation/loading_page.dart';

void main() {
  testWidgets('LoadingPage renders core logo image', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoadingPage(
          displayDuration: Duration.zero,
        ),
      ),
    );

    // Locate the Image widget
    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);

    final imageWidget = tester.widget<Image>(imageFinder);
    expect(imageWidget.image, isA<AssetImage>());
    final assetImage = imageWidget.image as AssetImage;
    expect(assetImage.assetName, equals('assets/images/login/image.png'));
    expect(imageWidget.width, equals(114.0));
    expect(imageWidget.height, equals(159.0));
  });

  testWidgets('LoadingPage invokes onFinished when timer expires',
      (WidgetTester tester) async {
    var finished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: LoadingPage(
          displayDuration: const Duration(milliseconds: 500),
          onFinished: () => finished = true,
        ),
      ),
    );

    expect(finished, isFalse);

    await tester.pump(const Duration(milliseconds: 600));
    expect(finished, isTrue);
  });
}
