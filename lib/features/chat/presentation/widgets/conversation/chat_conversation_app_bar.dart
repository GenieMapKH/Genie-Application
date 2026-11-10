import 'package:flutter/material.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/chat/presentation/widgets/conversation/chat_conversation_header.dart';
import 'package:tilomnov/features/chat/providers/active_chat_state.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/glass/glass_icon_button.dart';
import 'package:tilomnov/shared/widgets/glass/glass_scope.dart';

/// The bar over a conversation: back, who it is with, and a call button.
/// With glass ([GlassScope]) the buttons are round glass, as in
/// iOS 26's Messages.
class ChatConversationAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String participantName;

  /// Null until it is known who is signed in.
  final ChatParticipants? chat;

  /// Null while a call cannot be started: the button is then disabled.
  final VoidCallback? onCall;

  const ChatConversationAppBar({
    super.key,
    required this.participantName,
    required this.chat,
    required this.onCall,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final glass = GlassScope.of(context);
    return AppBar(
      backgroundColor: context.colors.surface,
      elevation: 0,
      leadingWidth: 64,
      titleSpacing: 0,
      leading: glass ? Center(child: _glassBack(context)) : _back(context),
      title: ChatConversationHeader(
        participantName: participantName,
        chat: chat,
      ),
      centerTitle: true,
      actions: [
        SizedBox(
          width: 64,
          child: Center(
            child: glass
                ? GlassIconButton(
                    icon: Icons.phone_outlined,
                    iconSize: 20,
                    tooltip: context.l10n.callVoice,
                    onPressed: onCall,
                  )
                : _solidCall(context),
          ),
        ),
      ],
    );
  }

  Widget _glassBack(BuildContext context) =>
      GlassIconButton.back(onPressed: () => Navigator.of(context).pop());

  Widget _back(BuildContext context) => IconButton(
    icon: Icon(Icons.arrow_back, color: context.colors.textMuted),
    onPressed: () => Navigator.of(context).pop(),
  );

  Widget _solidCall(BuildContext context) => IconButton(
    tooltip: context.l10n.callVoice,
    // Larger than the circle it draws, so a tap beside it still calls.
    constraints: const BoxConstraints.tightFor(width: 56, height: 56),
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
    onPressed: onCall,
  );
}
