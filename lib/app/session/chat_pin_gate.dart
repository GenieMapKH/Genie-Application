import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:genie/app/session/sign_out.dart';
import 'package:genie/features/chat/e2ee/e2ee_setup_service.dart';
import 'package:genie/features/chat/presentation/screens/chat_pin_setup_page.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';

/// Every account has a chat PIN. A signed-in account without one creates it
/// here before it can use the app: right after signing up or signing in
/// (with a password or with Google), and an account from before the PIN
/// was required at its next start. Guests pass straight through.
///
/// Lives in `app/` because it joins chat to the session: neither feature
/// knows the other.
class ChatPinGate extends ConsumerWidget {
  final Widget child;

  const ChatPinGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    // Until the server answered, the app shows as usual: a PIN still to
    // create replaces it then. A server that cannot be asked blocks nobody.
    final status = ref.watch(chatPinStatusProvider).valueOrNull;
    if (userId == null) return child;

    return switch (status) {
      ChatPinStatus.notSet ||
      ChatPinStatus.lockedWithPassword => ChatPinSetupPage(
        key: ValueKey(userId),
        userId: userId,
        fromPassword: status == ChatPinStatus.lockedWithPassword,
        onDone: () => ref.invalidate(chatPinStatusProvider),
        onSignOut: () async {
          await ref.read(signOutProvider)();
          if (context.mounted) context.go('/');
        },
      ),
      ChatPinStatus.set || ChatPinStatus.unknown || null => child,
    };
  }
}
