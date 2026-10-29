import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/splash/presentation/screens/loading_page.dart';
import 'package:tilomnov/shared/widgets/media/app_logo.dart';

void main() {
  testWidgets('LoadingPage renders core logo image', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoadingPage(displayDuration: Duration.zero)),
    );

    final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(picture.bytesLoader, isA<SvgAssetLoader>());
    final loader = picture.bytesLoader as SvgAssetLoader;
    expect(loader.assetName, equals(AppLogo.lightAssetPath));
    expect(picture.width, equals(220.0));
    expect(picture.height, equals(150.0));
  });

  testWidgets('LoadingPage shows the dark logo in the dark theme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: const LoadingPage(displayDuration: Duration.zero),
      ),
    );

    final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
    final loader = picture.bytesLoader as SvgAssetLoader;
    expect(loader.assetName, equals(AppLogo.darkAssetPath));
  });

  testWidgets('LoadingPage invokes onFinished when timer expires', (
    WidgetTester tester,
  ) async {
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
