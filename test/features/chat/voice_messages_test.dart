import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genie/core/device/microphone_permission.dart';
import 'package:genie/features/chat/data/chat_socket_service.dart';
import 'package:genie/features/chat/models/chat_attachment.dart';
import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/models/chat_send_problem.dart';
import 'package:genie/features/chat/models/chat_voice.dart';
import 'package:genie/features/chat/presentation/screens/chat_conversation_page.dart';
import 'package:genie/features/chat/presentation/widgets/voice/chat_voice_message.dart';
import 'package:genie/features/chat/presentation/widgets/voice/chat_voice_recorder_bar.dart';
import 'package:genie/features/chat/presentation/widgets/voice/voice_hold_panel.dart';
import 'package:genie/features/chat/presentation/widgets/voice/voice_record_button.dart';
import 'package:genie/features/chat/providers/active_chat_provider.dart';
import 'package:genie/features/chat/providers/chat_provider.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/chat/providers/voice_playback_provider.dart';
import 'package:genie/features/chat/providers/voice_recording_provider.dart';
import 'package:genie/features/profile/data/models/user_profile.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';

import 'chat_fakes.dart';

import 'voice_fakes.dart';

void main() {
  group('voice details', () {
    test('travel inside the message and come back the same', () {
      final attachment = voiceAttachment(1);

      final back = ChatAttachment.tryParse(attachment.toJson())!;

      expect(back.isVoice, isTrue);
      expect(back.voice!.duration, const Duration(seconds: 3));
      expect(back.voice!.waveform, [0, 10, 31, 5]);
    });

    test('a picture claiming to be a voice message is still a picture', () {
      final json = fakeAttachment(1).toJson()
        ..['voice'] = threeSecondVoice.toJson();

      final attachment = ChatAttachment.tryParse(json)!;
      final message = voiceMessage('m1', attachment);

      expect(attachment.isVoice, isFalse);
      expect(message.voice, isNull);
    });

    test('implausible details are ignored, not trusted', () {
      expect(ChatVoiceDetails.tryParse({'ms': -5, 'wave': []}), isNull);
      expect(ChatVoiceDetails.tryParse({'ms': 3600000, 'wave': []}), isNull);
      expect(
        ChatVoiceDetails.tryParse({
          'ms': 1000,
          'wave': [99, -3],
        })!.waveform,
        [ChatVoiceDetails.maxLevel, 0],
      );
    });

    test('a waveform has a fixed number of bars, loudest kept', () {
      final samples = [for (var i = 0; i < 100; i++) i == 50 ? 1.0 : 0.1];

      final waveform = ChatVoiceDetails.waveformOf(samples);

      expect(waveform, hasLength(ChatVoiceDetails.bars));
      expect(
        waveform.reduce((a, b) => a > b ? a : b),
        ChatVoiceDetails.maxLevel,
      );
      expect(ChatVoiceDetails.waveformOf([]), everyElement(0));
    });
  });

  group('sending', () {
    late FakeChatRepository repository;
    late FakeChatSocket socket;
    late FakeCipher cipher;
    late FakeAttachmentService attachments;
    late ConversationsNotifier conversations;
    late ActiveChatNotifier chat;

    final note = RecordedVoiceNote(
      bytes: Uint8List.fromList([9, 9, 9]),
      mimeType: 'audio/mp4',
      fileName: 'voice-message.m4a',
      details: threeSecondVoice,
    );

    setUp(() async {
      repository = FakeChatRepository();
      socket = FakeChatSocket();
      cipher = FakeCipher();
      attachments = FakeAttachmentService();
      conversations = ConversationsNotifier(
        repository: repository,
        socketService: socket,
        cipher: cipher,
      );
      chat = ActiveChatNotifier(
        userId: me,
        participantId: peer,
        repository: repository,
        socketService: socket,
        setupService: FakeSetupService(),
        cipher: cipher,
        attachments: attachments,
        conversations: conversations,
      );
      await chat.open(askPin: neverAskPin);
    });

    tearDown(() {
      chat.dispose();
      conversations.dispose();
    });

    test('shows it at once, uploads it, and seals its details', () async {
      final sending = chat.sendVoice(note);

      final pending = chat.state.messages.single;
      expect(pending.voice, threeSecondVoice);
      expect(pending.status, ChatMessageStatus.sending);

      await sending;

      final sent = chat.state.messages.single;
      expect(sent.status, ChatMessageStatus.sent);
      expect(attachments.uploads.single, [9, 9, 9]);
      expect(cipher.sealedAttachments.single!.voice, threeSecondVoice);
      expect(cipher.sealedAttachments.single!.isVoice, isTrue);
    });

    test('a retry after a lost connection does not upload again', () async {
      socket.sendError = const ChatSendException(ChatSendProblem.noConnection);
      await chat.sendVoice(note);
      expect(chat.state.messages.single.status, ChatMessageStatus.failed);

      socket.sendError = null;
      await chat.retry(chat.state.messages.single.id);

      expect(attachments.uploads, hasLength(1));
      expect(chat.state.messages.single.status, ChatMessageStatus.sent);
    });

    test('the chat list shows a voice message as one', () async {
      cipher.incomingAttachments['last-$peer'] = voiceAttachment(1);
      repository.conversations = [
        ChatConversation.fromJson({
          'participantId': peer,
          'participantName': 'Dara',
          'lastMessage': {
            'id': 'last-$peer',
            'senderId': peer,
            'ciphertext': 'sealed:',
            'nonce': 'nonce',
            'createdAt': '2026-01-01T10:00:00.000Z',
          },
        }),
      ];

      await conversations.refresh();
      // Opening the chat already started a reload; this one follows it.
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(
        conversations.state.value!.single.lastMessage,
        ChatConversation.voicePreview,
      );
    });
  });

  group('in the conversation', () {
    late FakeChatRepository repository;
    late FakeChatSocket socket;
    late FakeCipher cipher;
    late FakeAttachmentService attachments;
    late FakeVoiceRecorder recorder;
    late FakeVoicePlayer player;
    late MicrophoneAccess access;
    late TestClock clock;

    setUp(() {
      clock = TestClock();
      repository = FakeChatRepository();
      socket = FakeChatSocket();
      cipher = FakeCipher();
      attachments = FakeAttachmentService();
      recorder = FakeVoiceRecorder();
      player = FakeVoicePlayer();
      access = MicrophoneAccess.granted;
    });

    Future<void> openChat(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider.overrideWith(
              (ref) async => UserProfile(
                id: me,
                role: 'user',
                createdAt: DateTime.utc(2026),
              ),
            ),
            chatRepositoryProvider.overrideWithValue(repository),
            chatSocketServiceProvider.overrideWithValue(socket),
            e2eeSetupServiceProvider.overrideWithValue(FakeSetupService()),
            messageCipherProvider.overrideWith((ref, userId) => cipher),
            chatAttachmentServiceProvider.overrideWithValue(attachments),
            voiceRecorderFactoryProvider.overrideWithValue(() => recorder),
            voicePlayerFactoryProvider.overrideWithValue(() => player),
            microphoneAccessProvider.overrideWithValue(() async => access),
            voiceRecordingClockProvider.overrideWithValue(clock.call),
          ],
          child: const MaterialApp(
            home: ChatConversationPage(
              participantId: peer,
              participantName: 'Dara',
            ),
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
    }

    testWidgets('records, shows the bar, and sends the voice message', (
      tester,
    ) async {
      await openChat(tester);

      await tester.tap(find.bySemanticsLabel('Record a voice message'));
      await tester.pump();
      await tester.pump();
      expect(find.byType(ChatVoiceRecorderBar), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      clock.now = clock.now.add(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byTooltip('Send voice message'));
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }

      expect(find.byType(ChatVoiceRecorderBar), findsNothing);
      expect(find.byType(ChatVoiceMessage), findsOneWidget);
      expect(attachments.uploads.single, [7, 7, 7]);
      expect(socket.sent, hasLength(1));
    });

    Future<TestGesture> holdMicrophone(WidgetTester tester) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.bySemanticsLabel('Record a voice message')),
      );
      await tester.pump(VoiceRecordButton.holdDelay);
      await tester.pump();
      await tester.pump();
      return gesture;
    }

    testWidgets('held down, the microphone records and sends on release', (
      tester,
    ) async {
      await openChat(tester);

      final gesture = await holdMicrophone(tester);
      expect(find.byType(VoiceHoldPanel), findsOneWidget);
      expect(find.text('Slide to cancel'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(ChatVoiceRecorderBar), findsNothing);

      clock.now = clock.now.add(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }

      expect(find.byType(VoiceHoldPanel), findsNothing);
      expect(find.byType(ChatVoiceMessage), findsOneWidget);
      expect(socket.sent, hasLength(1));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('sliding the held finger left throws the recording away', (
      tester,
    ) async {
      await openChat(tester);

      final gesture = await holdMicrophone(tester);
      clock.now = clock.now.add(const Duration(seconds: 2));
      await gesture.moveBy(
        const Offset(-(VoiceRecordButton.cancelDistance + 10), 0),
      );
      await tester.pump();
      expect(recorder.cancelled, isTrue);
      expect(find.byType(VoiceHoldPanel), findsNothing);

      await gesture.up();
      await tester.pump();
      expect(socket.sent, isEmpty);
      expect(find.byType(ChatVoiceMessage), findsNothing);
    });

    testWidgets('a quick press is a tap: it opens the recording bar', (
      tester,
    ) async {
      await openChat(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.bySemanticsLabel('Record a voice message')),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pump();
      await tester.pump();

      expect(find.byType(ChatVoiceRecorderBar), findsOneWidget);
      expect(find.byType(VoiceHoldPanel), findsNothing);
      await tester.tap(find.byTooltip('Delete recording'));
      await tester.pump();
    });

    testWidgets('a received voice message shows its length and plays', (
      tester,
    ) async {
      final attachment = voiceAttachment(1);
      attachments.files[attachment.path] = Uint8List.fromList([3, 3]);
      cipher.incomingAttachments['m1'] = attachment;
      repository.history = [encrypted('m1', '', from: peer)];

      await openChat(tester);

      expect(find.text('0:03'), findsOneWidget);
      await tester.tap(find.byTooltip('Play'));
      await tester.pump();
      await tester.pump();

      expect(player.loaded.single, [3, 3]);
      expect(find.byTooltip('Pause'), findsOneWidget);
      expect(find.text('1×'), findsOneWidget);
    });

    testWidgets('a microphone turned off in settings says so', (tester) async {
      access = MicrophoneAccess.blockedInSettings;
      await openChat(tester);

      await tester.tap(find.bySemanticsLabel('Record a voice message'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Microphone access is turned off. Turn it on in Settings.'),
        findsOneWidget,
      );
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byType(ChatVoiceRecorderBar), findsNothing);
    });
  });
}
