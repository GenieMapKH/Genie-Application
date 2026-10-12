import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/features/chat/e2ee/e2ee_setup_service.dart';
import 'package:genie/features/chat/presentation/widgets/chat_conversation_header.dart';
import 'package:genie/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:genie/features/chat/presentation/widgets/chat_key_changed_banner.dart';
import 'package:genie/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:genie/features/chat/presentation/widgets/chat_participant_sheet.dart';
import 'package:genie/features/chat/presentation/widgets/pin_prompt_dialog.dart';
import 'package:genie/features/chat/providers/active_chat_provider.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';

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
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF6B7280)),
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
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Icon(
                  Icons.phone_outlined,
                  color: Color(0xFF6B7280),
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
          ? const _ChatNotice(message: 'This is your own account.')
          : chat != null
          ? _Conversation(chat: chat, participantName: participantName)
          : profile.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ChatNotice(
              message: 'Sign in to chat, or check your connection.',
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

  void _open() {
    if (!mounted) return;
    ref.read(activeChatProvider(widget.chat).notifier).open(askPin: _askPin);
  }

  Future<String?> _askPin({required bool isNewPin}) async {
    if (!mounted) return null;
    return showPinPrompt(
      context,
      allowCancel: !isNewPin,
      title: isNewPin ? 'Create Backup PIN' : 'Enter Backup PIN',
      helper: isNewPin
          ? 'This PIN encrypts your chat keys. Do not forget it!'
          : 'Enter your PIN to restore your chats.',
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
      ActiveChatStatus.unavailable => _ChatNotice(
        message: switch (chatState.setupResult) {
          E2eeSetupResult.wrongPin =>
            'Failed to restore backup. Incorrect PIN?',
          E2eeSetupResult.rateLimited =>
            'Too many attempts. Try again in 15 minutes.',
          E2eeSetupResult.cancelled =>
            'Your backup PIN is needed to read and send messages.',
          _ => 'Could not open this chat. Check your connection.',
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
            ),
        ],
      ),
    };
  }

  Widget _buildMessages(ActiveChatState chatState) {
    final messages = chatState.messages;
    if (messages.isEmpty) {
      return const _ChatNotice(
        message: 'Messages are end-to-end encrypted. Say hello!',
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

  const _ChatNotice({required this.message, this.onRetry});

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
                color: const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
