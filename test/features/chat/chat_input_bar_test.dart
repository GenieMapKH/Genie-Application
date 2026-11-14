import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tilomnov/features/chat/presentation/widgets/conversation/chat_emoji_panel.dart';
import 'package:tilomnov/features/chat/presentation/widgets/conversation/chat_input_bar.dart';
import 'package:tilomnov/features/chat/presentation/widgets/voice/voice_record_button.dart';
import 'package:tilomnov/l10n/l10n.dart';

import '../../support/test_app.dart';

void main() {
  testWidgets(
    'compact composer keeps attachment, emoji, send and voice actions',
    (tester) async {
      var attachments = 0;
      var voiceTaps = 0;
      final sent = <String>[];
      final holdEnds = <bool>[];
      final recording = ValueNotifier(false);
      addTearDown(recording.dispose);

      await pumpTestApp(
        tester,
        Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ValueListenableBuilder(
              valueListenable: recording,
              builder: (context, isRecording, _) => ChatInputBar(
                onAttach: () => attachments++,
                onSend: sent.add,
                onRecordVoice: () => voiceTaps++,
                onHoldVoiceStart: () => recording.value = true,
                onHoldVoiceEnd: ({required cancelled}) {
                  holdEnds.add(cancelled);
                  recording.value = false;
                },
                recordingPanel: isRecording ? const Text('Recording') : null,
              ),
            ),
          ),
        ),
      );
      final l10n = tester.element(find.byType(ChatInputBar)).l10n;

      await tester.tap(find.bySemanticsLabel(l10n.chatAttachPicture));
      expect(attachments, 1);
      expect(
        tester.getSize(find.byType(VoiceRecordButton)),
        const Size(48, 48),
      );
      await tester.tap(find.byType(VoiceRecordButton));
      expect(voiceTaps, 1);

      await tester.tap(find.bySemanticsLabel(l10n.chatShowEmojis));
      await tester.pumpAndSettle();
      expect(find.byType(ChatEmojiPanel), findsOneWidget);
      final firstEmoji = find
          .descendant(
            of: find.byType(ChatEmojiPanel),
            matching: find.byType(Text),
          )
          .first;
      final emoji = tester.widget<Text>(firstEmoji).data!;
      await tester.tap(firstEmoji);
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(l10n.chatSendMessage));
      await tester.pump();
      expect(sent, [emoji]);

      await tester.tap(find.bySemanticsLabel(l10n.chatShowKeyboard));
      await tester.pump();
      await tester.enterText(find.byType(TextField), ' Hello ');
      await tester.tap(find.bySemanticsLabel(l10n.chatSendMessage));
      await tester.pump();
      expect(sent, [emoji, 'Hello']);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final microphone = tester.state(find.byType(VoiceRecordButton));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(VoiceRecordButton)),
      );
      await tester.pump(VoiceRecordButton.holdDelay);
      expect(find.text('Recording'), findsOneWidget);
      expect(tester.state(find.byType(VoiceRecordButton)), same(microphone));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(holdEnds, [false]);
      expect(tester.takeException(), isNull);
    },
  );
}
