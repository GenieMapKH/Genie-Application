import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/features/chat/models/chat_models.dart';
import 'package:genie/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:genie/features/chat/providers/chat_provider.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';

class ChatConversationPage extends ConsumerStatefulWidget {
  final String participantId;
  final String participantName;

  const ChatConversationPage({
    super.key,
    required this.participantId,
    required this.participantName,
  });

  @override
  ConsumerState<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends ConsumerState<ChatConversationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final profile = await ref.read(userProfileProvider.future);
        if (mounted) {
          final initService = ref.read(e2eeInitServiceProvider);
          await initService.initializeE2EE(context, profile.id);
        }
      } catch (e) {
        debugPrint('Failed to initialize E2EE in ChatConversation: $e');
      }

      if (mounted) {
        ref.read(activeChatProvider.notifier).setActiveChat(
              widget.participantId,
              widget.participantName,
            );
      }
    });
  }

  @override
  void dispose() {
    // We don't clear the active chat immediately here, otherwise it might flicker on pop.
    // However, it's good practice to manage it appropriately.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(activeChatProvider);

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
          title: Column(
            children: [
              Text(
                widget.participantName,
                style: GoogleFonts.inter(
                  color: const Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
                child: const Icon(Icons.phone_outlined, color: Color(0xFF6B7280), size: 18),
              ),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              itemCount: chatState?.messages.length ?? 0,
              itemBuilder: (context, index) {
                final message = chatState!.messages[index];
                final isMe = message.senderId == 'me';
                
                if (isMe) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildMyMessage(message.text),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildTheirMessage(message.text),
                  );
                }
              },
            ),
          ),
          ChatInputBar(
            onSend: (text) {
              ref.read(activeChatProvider.notifier).sendMessage(text);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMyMessage(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF111827),
          ),
        ),
      ),
    );
  }

  Widget _buildTheirMessage(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF111827),
          ),
        ),
      ),
    );
  }
}

