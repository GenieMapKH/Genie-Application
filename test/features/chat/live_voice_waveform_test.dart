import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/features/chat/presentation/widgets/voice/live_voice_waveform.dart';

void main() {
  group('LiveVoiceWaveform.smoothed', () {
    test('a lone spike is softened by the bars before it', () {
      final bars = LiveVoiceWaveform.smoothed([0, 0, 1, 0, 0]);

      expect(bars, [0, 0, 0.5, 0.3, 0.2]);
    });

    test('a bar keeps its height when newer samples arrive', () {
      final before = LiveVoiceWaveform.smoothed([0.2, 0.8, 0.4]);
      final after = LiveVoiceWaveform.smoothed([0.2, 0.8, 0.4, 1, 0]);

      expect(after.sublist(0, 3), before);
    });

    test('stays between 0 and 1', () {
      expect(
        LiveVoiceWaveform.smoothed([2, -1, 0.5]),
        everyElement(inInclusiveRange(0, 1)),
      );
    });
  });

  testWidgets('keeps sliding between samples and stops when told', (
    tester,
  ) async {
    Widget waveform(List<double> levels, {bool moving = true}) => MaterialApp(
      home: SizedBox(
        width: 200,
        child: LiveVoiceWaveform(
          levels: levels,
          capacity: 31,
          sampleInterval: const Duration(milliseconds: 100),
          moving: moving,
          color: Colors.red,
        ),
      ),
    );

    await tester.pumpWidget(waveform(const [0.5]));
    await tester.pumpWidget(waveform(const [0.5, 0.9]));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(waveform(const [0.5, 0.9], moving: false));
    expect(tester.hasRunningAnimations, isFalse);
  });
}
