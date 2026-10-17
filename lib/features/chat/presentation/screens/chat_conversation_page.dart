import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/media/image_upload_policy.dart';
import 'package:genie/shared/utils/image_rejection_message.dart';
import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/features/chat/e2ee/e2ee_setup_service.dart';
import 'package:genie/features/chat/presentation/widgets/chat_conversation_header.dart';
import 'package:genie/features/chat/presentation/widgets/chat_image_picker.dart';
import 'package:genie/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:genie/features/chat/presentation/widgets/chat_key_changed_banner.dart';
import 'package:genie/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:genie/features/chat/presentation/widgets/chat_participant_sheet.dart';
import 'package:genie/features/chat/presentation/widgets/pin_prompt_dialog.dart';
import 'package:genie/features/chat/providers/active_chat_provider.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/l10n/l10n.dart';

class ChatConversationPage extends ConsumerWidget {
  final String participantId;
  final String participantName;

  const ChatConversationPage({
    super.key,
    required this.participantId,
    required this.participantName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    // A conversation belongs to the signed-in user, so wait for them.
    final userId = profile.hasError ? null : profile.valueOrNull?.id;
    final chat = userId == null
        ? null
        : (userId: userId, participantId: participantId);

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
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: userId == participantId
          ? _ChatNotice(message: context.l10n.chatThisIsYourOwnAccount)
          : chat != null
          ? _Conversation(chat: chat, participantName: participantName)
          : profile.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ChatNotice(
              message: context.l10n.chatSignInToChatOrCheck,
              onRetry: () => ref.invalidate(userProfileProvider),
            ),
    );
  }
}

class _Conversation extends ConsumerStatefulWidget {
  final ChatParticipants chat;
  final String participantName;

  const _Conversation({required this.chat, required this.participantName});

  @override
  ConsumerState<_Conversation> createState() => _ConversationState();
}

class _ConversationState extends ConsumerState<_Conversation> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  void _open({bool takeOver = false}) {
    if (!mounted) return;
    ref
        .read(activeChatProvider(widget.chat).notifier)
        .open(askPin: _askPin, takeOver: takeOver);
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

  /// Only for an account that chose a backup PIN, on a device without its
  /// keys. Anyone else is never asked.
  Future<String?> _askPin() async {
    if (!mounted) return null;
    return showPinPrompt(
      context,
      title: context.l10n.chatPinRestoreTitle,
      helper: context.l10n.chatPinRestoreHelp,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = activeChatProvider(widget.chat);
    final chatState = ref.watch(provider);

    ref.listen(provider.select((state) => state.sendError), (_, error) {
      if (error == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    });

    return switch (chatState.status) {
      ActiveChatStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      ActiveChatStatus.unavailable
          when chatState.setupResult == E2eeSetupResult.usedOnAnotherDevice =>
        _ChatNotice(
          message: context.l10n.chatUsedOnAnotherDevice,
          actionLabel: context.l10n.chatUseOnThisDevice,
          onRetry: () => _open(takeOver: true),
        ),
      ActiveChatStatus.unavailable => _ChatNotice(
        message: switch (chatState.setupResult) {
          E2eeSetupResult.wrongPin =>
            '${context.l10n.pinWrong}\n\n${context.l10n.pinForgotHint}',
          E2eeSetupResult.rateLimited =>
            '${context.l10n.pinLocked}\n\n${context.l10n.pinForgotHint}',
          E2eeSetupResult.cancelled =>
            '${context.l10n.chatPinNeeded}\n\n${context.l10n.pinForgotHint}',
          _ => context.l10n.chatOpenFailed,
        },
        onRetry: _open,
      ),
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
          else
            ChatInputBar(
              onSend: (text) => ref.read(provider.notifier).sendMessage(text),
              onAttach: _sendPicture,
            ),
        ],
      ),
    };
  }

  Widget _buildMessages(ActiveChatState chatState) {
    final messages = chatState.messages;
    if (messages.isEmpty) {
      return _ChatNotice(
        message: context.l10n.chatMessagesAreEndToEndEncrypted,
      );
    }

    // Reversed, so the list stays anchored to the newest message.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return Padding(
          key: ValueKey(message.id),
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ChatMessageBubble(
            message: message,
            isMine: message.senderId == widget.chat.userId,
            onRetry: () => ref
                .read(activeChatProvider(widget.chat).notifier)
                .retry(message.id),
          ),
        );
      },
    );
  }
}

/// A centred message, with a retry button when there is something to retry.
class _ChatNotice extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  /// The button's label; "Try again" when null.
  final String? actionLabel;

  const _ChatNotice({required this.message, this.onRetry, this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: context.colors.textMuted,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(actionLabel ?? context.l10n.chatTryAgain),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
