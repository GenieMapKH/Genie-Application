import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/device/microphone_permission.dart';
import 'package:genie/core/media/image_upload_policy.dart';
import 'package:genie/shared/utils/image_rejection_message.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/chat/e2ee/e2ee_setup_service.dart';
import 'package:genie/features/chat/e2ee/backup/pin_check.dart';
import 'package:genie/features/chat/presentation/screens/chat_pin_setup_page.dart';
import 'package:genie/features/chat/models/chat_composer_mode.dart';
import 'package:genie/features/chat/models/chat_send_problem.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_call_entry_tile.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_composer_banner.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_conversation_header.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_image_picker.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_input_bar.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_key_changed_banner.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_message_action_problem_text.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_message_tile.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_notice.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_send_problem_text.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_participant_sheet.dart';
import 'package:genie/features/chat/presentation/widgets/pin/pin_check_dialog.dart';
import 'package:genie/features/chat/presentation/widgets/voice/chat_voice_recorder_bar.dart';
import 'package:genie/features/chat/presentation/widgets/voice/voice_hold_panel.dart';
import 'package:genie/features/chat/presentation/widgets/voice/voice_recording_problem_text.dart';
import 'package:genie/features/chat/providers/active_chat_provider.dart';
import 'package:genie/features/chat/models/chat_timeline.dart';
import 'package:genie/features/chat/providers/chat_call_history_provider.dart';
import 'package:genie/features/chat/providers/chat_call_starter.dart';
import 'package:genie/features/chat/providers/chat_composer_provider.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/chat/providers/visible_conversation.dart';
import 'package:genie/features/chat/providers/voice_playback_provider.dart';
import 'package:genie/features/chat/providers/voice_recording_provider.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/features/safety/presentation/view_models/block_providers.dart';
import 'package:genie/features/safety/presentation/widgets/blocked_conversation_bar.dart';
import 'package:genie/features/safety/presentation/widgets/safety_menu_button.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/features/chat/models/chat_listing.dart';
import 'package:genie/features/chat/presentation/widgets/conversation/chat_listing_offer_bar.dart';

class ChatConversationPage extends ConsumerWidget {
  final String participantId;
  final String participantName;

  /// The listing the chat was opened from: offered above the message bar,
  /// to send so the owner knows which one is meant.
  final ChatListing? listingToOffer;

  const ChatConversationPage({
    super.key,
    required this.participantId,
    required this.participantName,
    this.listingToOffer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    // A conversation belongs to the signed-in user, so wait for them.
    final userId = profile.hasError ? null : profile.valueOrNull?.id;
    final chat = userId == null
        ? null
        : (userId: userId, participantId: participantId);
    final startCall = ref.watch(chatCallStarterProvider);
    final canCall =
        startCall != null && chat != null && userId != participantId;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          backgroundColor: context.colors.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: context.colors.textMuted),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: ChatConversationHeader(
            participantName: participantName,
            chat: chat,
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: context.l10n.callVoice,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.border),
                ),
                child: Icon(
                  Icons.phone_outlined,
                  color: context.colors.textMuted,
                  size: 18,
                ),
              ),
              onPressed: canCall
                  ? () => startCall(participantId, participantName)
                  : null,
            ),
            if (chat != null && userId != participantId)
              SafetyMenuButton(userId: participantId, userName: participantName)
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
      body: userId == participantId
          ? ChatNotice(message: context.l10n.chatThisIsYourOwnAccount)
          : chat != null
          ? _Conversation(
              chat: chat,
              participantName: participantName,
              listingToOffer: listingToOffer,
            )
          : profile.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ChatNotice(
              message: context.l10n.chatSignInToChatOrCheck,
              onAction: () => ref.invalidate(userProfileProvider),
            ),
    );
  }
}

class _Conversation extends ConsumerStatefulWidget {
  final ChatParticipants chat;
  final String participantName;
  final ChatListing? listingToOffer;

  const _Conversation({
    required this.chat,
    required this.participantName,
    this.listingToOffer,
  });

  @override
  ConsumerState<_Conversation> createState() => _ConversationState();
}

class _ConversationState extends ConsumerState<_Conversation> {
  late final VisibleConversation _visible;

  /// The microphone is held down: the message bar stays (the finger is on
  /// its button) and shows the recording in place of the field.
  bool _holdingVoice = false;

  /// Still offered above the message bar: not sent nor closed yet.
  late ChatListing? _offeredListing = widget.listingToOffer;

  void _sendOfferedListing() {
    final listing = _offeredListing;
    if (listing == null) return;
    setState(() => _offeredListing = null);
    ref.read(activeChatProvider(widget.chat).notifier).sendListing(listing);
  }

  @override
  void initState() {
    super.initState();
    // Its new-message notifications are not shown while it is open.
    _visible = ref.read(visibleConversationProvider)
      ..show(widget.chat.participantId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void dispose() {
    _visible.hide(widget.chat.participantId);
    super.dispose();
  }

  void _open() {
    if (!mounted) return;
    ref.read(activeChatProvider(widget.chat).notifier).open(askPin: _askPin);
  }

  /// Only on a device without the account's keys. The dialog stays open
  /// while each PIN is checked, and says what went wrong.
  Future<bool> _askPin(PinCheck check) async {
    if (!mounted) return false;
    return showPinCheckDialog(
      context,
      title: context.l10n.chatPinRestoreTitle,
      helper: context.l10n.chatPinRestoreHelp,
      check: check,
    );
  }

  /// The account still has to create its chat PIN (or move its chats from
  /// the account password to one): then chat opens.
  Future<void> _createPin({required bool fromPassword}) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ChatPinSetupPage(
          userId: widget.chat.userId,
          fromPassword: fromPassword,
          onDone: () => Navigator.of(context).pop(true),
        ),
      ),
    );
    if (created != true || !mounted) return;
    ref.invalidate(chatPinStatusProvider);
    _open();
  }

  Future<void> _sendPicture() async {
    final PickedChatImage? picture;
    try {
      picture = await pickChatImage(context);
    } on ImageRejectedException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(imageRejectionMessage(context.l10n, e.reason))),
      );
      return;
    } catch (e) {
      // The camera or gallery refused, e.g. permission was denied.
      AppLogger.error('Could not pick a picture', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.chatCouldNotOpenYourPhotos)),
      );
      return;
    }
    if (picture == null || !mounted) return;

    ref
        .read(activeChatProvider(widget.chat).notifier)
        .sendImage(
          picture.bytes,
          name: picture.name,
          mimeType: picture.mimeType,
        );
  }

  /// Sends a new message, a reply, or the new text of the message being
  /// edited, then goes back to writing new messages.
  Future<void> _send(String text) async {
    final composer = ref.read(chatComposerProvider(widget.chat).notifier);
    final mode = composer.state;
    composer.state = null;
    final chat = ref.read(activeChatProvider(widget.chat).notifier);

    switch (mode) {
      case EditingMessage(:final message):
        final problem = await chat.editMessage(message.id, text);
        if (problem == null || !mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                chatMessageActionProblemText(context.l10n, problem),
              ),
            ),
          );
      case ReplyingTo(:final message):
        await chat.sendMessage(text, replyTo: message);
      case null:
        await chat.sendMessage(text);
    }
  }

  /// "Replying to Dara" / "Editing message", with a button to stop.
  Widget? _composerBanner(ChatComposerMode? mode) {
    if (mode == null) return null;
    return ChatComposerBanner(
      mode: mode,
      authorName: mode.message.senderId == widget.chat.userId
          ? context.l10n.chatYou
          : widget.participantName,
      onCancel: () =>
          ref.read(chatComposerProvider(widget.chat).notifier).state = null,
    );
  }

  Future<void> _recordVoice() async {
    // A message playing aloud would be recorded too.
    await ref.read(voicePlaybackProvider.notifier).stop();
    await ref.read(voiceRecordingProvider(widget.chat).notifier).start();
  }

  /// Records while the microphone is held down.
  Future<void> _holdVoiceStart() async {
    setState(() => _holdingVoice = true);
    await _recordVoice();
    // Let go (or interrupted, as by the permission question) before the
    // microphone was ready: nothing worth sending was said.
    if (mounted && !_holdingVoice) {
      await ref.read(voiceRecordingProvider(widget.chat).notifier).discard();
    }
  }

  /// The microphone was let go: send, unless the finger slid away.
  void _holdVoiceEnd({required bool cancelled}) {
    setState(() => _holdingVoice = false);
    final recording = ref.read(voiceRecordingProvider(widget.chat).notifier);
    unawaited(cancelled ? recording.discard() : recording.finish());
  }

  void _showRecordingProblem(VoiceRecordingProblem problem) {
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(voiceRecordingProblemText(l10n, problem)),
          // Only the phone's settings can turn the microphone back on.
          action: problem == VoiceRecordingProblem.microphoneBlocked
              ? SnackBarAction(
                  label: l10n.openSystemSettings,
                  onPressed: MicrophonePermission.openSettings,
                )
              : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final provider = activeChatProvider(widget.chat);
    final chatState = ref.watch(provider);
    final recordingProvider = voiceRecordingProvider(widget.chat);
    // Only whether a recording is on: its level and time change many times
    // a second, and only the recording bar shows them.
    final isRecording = ref.watch(
      recordingProvider.select((recording) => recording.isActive),
    );
    final composerMode = ref.watch(chatComposerProvider(widget.chat));
    final blockStatus = ref
        .watch(blockStatusProvider(widget.chat.participantId))
        .valueOrNull;
    // Voice messages keep playing while their bubbles scroll out of view,
    // and stop when this screen closes.
    ref.watch(voicePlaybackProvider.notifier);

    ref.listen(provider.select((state) => state.sendError), (_, error) {
      if (error == null) return;
      // Blocked since the conversation opened: the bar below says so.
      if (error == ChatSendProblem.blocked) {
        ref
            .read(blockStatusProvider(widget.chat.participantId).notifier)
            .refresh();
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(chatSendProblemText(context.l10n, error))),
        );
    });
    // The message being replied to or edited was deleted meanwhile.
    ref.listen(provider.select((state) => state.messages), (_, messages) {
      final mode = ref.read(chatComposerProvider(widget.chat));
      if (mode != null && !messages.any((m) => m.id == mode.message.id)) {
        ref.read(chatComposerProvider(widget.chat).notifier).state = null;
      }
    });
    ref.listen(recordingProvider, (previous, next) {
      final problem = next.problem;
      if (problem != null && !identical(previous, next)) {
        _showRecordingProblem(problem);
      }
    });

    return switch (chatState.status) {
      ActiveChatStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      ActiveChatStatus.unavailable => _unavailableNotice(chatState.setupResult),
      ActiveChatStatus.ready => Column(
        children: [
          Expanded(child: _buildMessages(chatState)),
          if (chatState.peerKeyChanged)
            ChatKeyChangedBanner(
              participantName: widget.participantName,
              onAccept: () => ref.read(provider.notifier).acceptNewPeerKey(),
              onViewSecurityCode: () => showChatParticipantSheet(
                context,
                chat: widget.chat,
                participantName: widget.participantName,
              ),
            )
          else if (blockStatus != null && !blockStatus.canMessage)
            BlockedConversationBar(
              status: blockStatus,
              participantId: widget.chat.participantId,
              participantName: widget.participantName,
            )
          else if (isRecording && !_holdingVoice)
            Consumer(
              builder: (context, ref, _) => ChatVoiceRecorderBar(
                recording: ref.watch(recordingProvider),
                onDiscard: () => ref.read(recordingProvider.notifier).discard(),
                onSend: () => ref.read(recordingProvider.notifier).finish(),
              ),
            )
          else ...[
            if (_offeredListing case final listing?)
              ChatListingOfferBar(
                listing: listing,
                onSend: _sendOfferedListing,
                onDismiss: () => setState(() => _offeredListing = null),
              ),
            ChatInputBar(
              onSend: _send,
              mode: composerMode,
              banner: _composerBanner(composerMode),
              onAttach: _sendPicture,
              onRecordVoice: _recordVoice,
              onHoldVoiceStart: _holdVoiceStart,
              onHoldVoiceEnd: _holdVoiceEnd,
              recordingPanel: _holdingVoice
                  ? Consumer(
                      builder: (context, ref, _) => VoiceHoldPanel(
                        recording: ref.watch(recordingProvider),
                      ),
                    )
                  : null,
            ),
          ],
        ],
      ),
    };
  }

  /// Why chat cannot open here, and the one thing to do about it.
  Widget _unavailableNotice(E2eeSetupResult? result) {
    final l10n = context.l10n;
    return switch (result) {
      E2eeSetupResult.pinNotSet => ChatNotice(
        icon: Icons.shield_outlined,
        title: l10n.chatPinCreateTitle,
        message: l10n.chatPinRequiredMessage,
        actionLabel: l10n.chatPinCreateAction,
        onAction: () => _createPin(fromPassword: false),
      ),
      E2eeSetupResult.lockedWithPassword => ChatNotice(
        icon: Icons.shield_outlined,
        title: l10n.chatPinMoveTitle,
        message: l10n.chatPinMoveHelp,
        actionLabel: l10n.chatPinCreateAction,
        onAction: () => _createPin(fromPassword: true),
      ),
      E2eeSetupResult.cancelled => ChatNotice(
        icon: Icons.lock_outline,
        title: l10n.chatLockedTitle,
        message: l10n.chatPinNeeded,
        actionLabel: l10n.chatEnterPinAction,
        onAction: _open,
        footnote: l10n.pinForgotHint,
      ),
      E2eeSetupResult.rateLimited => ChatNotice(
        icon: Icons.lock_clock_outlined,
        isWarning: true,
        title: l10n.chatPinLockedTitle,
        message: l10n.chatPinLockedMessage,
        onAction: _open,
        footnote: l10n.pinForgotHint,
      ),
      _ => ChatNotice(
        icon: Icons.cloud_off_outlined,
        message: l10n.chatOpenFailed,
        onAction: _open,
      ),
    };
  }

  Widget _buildMessages(ActiveChatState chatState) {
    final calls = ref.watch(chatCallHistoryProvider(widget.chat));
    final items = mergeTimeline(chatState.messages, calls);
    if (items.isEmpty) {
      return ChatNotice(message: context.l10n.chatMessagesAreEndToEndEncrypted);
    }

    // Reversed, so the list stays anchored to the newest message.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[items.length - 1 - index];
        return Padding(
          key: ValueKey(item.key),
          padding: const EdgeInsets.only(bottom: 16.0),
          child: switch (item) {
            ChatMessageItem(:final message) => ChatMessageTile(
              chat: widget.chat,
              message: message,
              participantName: widget.participantName,
            ),
            ChatCallItem(:final call) => ChatCallEntryTile(
              call: call,
              userId: widget.chat.userId,
            ),
          },
        );
      },
    );
  }
}
