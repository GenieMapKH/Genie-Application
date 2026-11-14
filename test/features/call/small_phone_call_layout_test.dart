import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/core/device/microphone_permission.dart';
import 'package:tilomnov/features/call/application/call_controller.dart';
import 'package:tilomnov/features/call/presentation/call_screen.dart';
import 'package:tilomnov/features/call/providers/call_providers.dart';
import 'package:tilomnov/features/chat/presentation/widgets/conversation/chat_input_bar.dart';

import '../../support/test_app.dart';
import 'call_fakes.dart';

void main() {
  for (final width in [280.0, 320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final language in ['en', 'km']) {
        testWidgets(
          'call and composer fit ${width.toInt()}px $language text $scale',
          (tester) async {
            tester.view.physicalSize = Size(width, 568);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final controller = CallController(
              signaling: FakeCallSignaling(),
              newMedia: FakeCallMedia.new,
              requestMicrophone: () async => MicrophoneAccess.granted,
              newCallId: () => 'layout-call',
            );
            await controller.call('peer', 'A long contact display name');
            await pumpTestApp(
              tester,
              Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: const CallScreen(),
                ),
              ),
              savedSettings: {'settings.language': language},
              overrides: [
                callControllerProvider.overrideWith((_) => controller),
              ],
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await controller.hangUp();
            await tester.pumpWidget(const SizedBox());
            await pumpTestApp(
              tester,
              Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: const Scaffold(
                    body: Align(
                      alignment: Alignment.bottomCenter,
                      child: ChatInputBar(),
                    ),
                  ),
                ),
              ),
              savedSettings: {'settings.language': language},
            );
            await tester.pumpAndSettle();
            if (scale == 1) {
              expect(
                tester.getSize(find.byType(ChatInputBar)).height,
                lessThanOrEqualTo(64),
              );
            }
            expect(
              tester.getSize(find.byType(TextField)).width,
              greaterThanOrEqualTo(width - 180),
            );
            await tester.enterText(
              find.byType(TextField),
              'A long message on a narrow phone',
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
