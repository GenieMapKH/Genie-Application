import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/chat/e2ee/backup/pin_check.dart';
import 'package:tilomnov/features/chat/presentation/widgets/pin/chat_pin_password_step.dart';
import 'package:tilomnov/features/chat/presentation/widgets/pin/pin_code_field.dart';
import 'package:tilomnov/features/chat/presentation/widgets/pin/pin_status_line.dart';
import 'package:tilomnov/features/chat/providers/chat_pin_setup_provider.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';

/// Creates the account's chat PIN, which every account has: without it no
/// other phone could read the chats. [fromPassword] first asks the account
/// password, for chats still locked with it.
///
/// [onDone] runs once the PIN is saved. [onSignOut], when given, is the way
/// out for someone who does not want to go on as this account.
class ChatPinSetupPage extends ConsumerStatefulWidget {
  final String userId;
  final bool fromPassword;
  final VoidCallback onDone;
  final VoidCallback? onSignOut;

  const ChatPinSetupPage({
    super.key,
    required this.userId,
    required this.onDone,
    this.fromPassword = false,
    this.onSignOut,
  });

  @override
  ConsumerState<ChatPinSetupPage> createState() => _ChatPinSetupPageState();
}

class _ChatPinSetupPageState extends ConsumerState<ChatPinSetupPage> {
  final _pin = TextEditingController();

  ({String userId, bool fromPassword}) get _args =>
      (userId: widget.userId, fromPassword: widget.fromPassword);

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _onPinTyped(ChatPinSetupState state, String pin) {
    final controller = ref.read(chatPinSetupProvider(_args).notifier);
    if (state.step == ChatPinSetupStep.confirmPin) {
      controller.confirmPin(pin);
    } else {
      controller.choosePin(pin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = chatPinSetupProvider(_args);
    final state = ref.watch(provider);

    ref.listen(provider, (previous, next) {
      if (next.done && previous?.done != true) widget.onDone();
      // Each step, and each refused PIN, starts from an empty field.
      if (next.step != previous?.step || next.shakes != previous?.shakes) {
        _pin.clear();
      }
    });

    final colors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 408),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: colors.primarySoft,
                    child: Icon(
                      Icons.shield_outlined,
                      size: 36,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _title(l10n, state.step),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _explanation(l10n, state.step),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.5,
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (state.step == ChatPinSetupStep.password)
                    ChatPinPasswordStep(
                      state: state,
                      errorText: _passwordError(l10n, state.passwordResult),
                      onSubmit: ref.read(provider.notifier).submitPassword,
                      onStartOver: ref.read(provider.notifier).startOver,
                    )
                  else
                    _PinStep(
                      controller: _pin,
                      state: state,
                      errorText: _problemText(l10n, state.problem),
                      onTyped: (pin) => _onPinTyped(state, pin),
                      onBack: ref.read(provider.notifier).back,
                    ),
                  if (widget.onSignOut != null) ...[
                    const SizedBox(height: 32),
                    TextButton(
                      onPressed: state.busy ? null : widget.onSignOut,
                      child: Text(l10n.chatPinSetupSignOut),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _title(AppLocalizations l10n, ChatPinSetupStep step) => switch (step) {
    ChatPinSetupStep.password => l10n.chatPinMoveTitle,
    ChatPinSetupStep.choosePin => l10n.chatPinCreateTitle,
    ChatPinSetupStep.confirmPin => l10n.chatPinConfirmTitle,
  };

  String _explanation(AppLocalizations l10n, ChatPinSetupStep step) =>
      switch (step) {
        ChatPinSetupStep.password => l10n.chatPinMoveHelp,
        ChatPinSetupStep.choosePin => l10n.chatPinCreateHelp,
        ChatPinSetupStep.confirmPin => l10n.chatPinConfirmHelp,
      };

  String? _problemText(AppLocalizations l10n, ChatPinSetupProblem? problem) =>
      switch (problem) {
        ChatPinSetupProblem.tooGuessable => l10n.pinTooGuessable,
        ChatPinSetupProblem.mismatch => l10n.chatPinMismatch,
        ChatPinSetupProblem.saveFailed => failureMessage(
          l10n,
          fallback: l10n.chatPinSaveFailed,
        ),
        null => null,
      };

  String? _passwordError(AppLocalizations l10n, PinCheckResult? result) =>
      switch (result) {
        PinRejected() => l10n.chatPasswordWrong,
        PinLockedOut() => l10n.chatPasswordTooManyTries,
        PinCheckFailed() => failureMessage(l10n, fallback: l10n.pinCheckFailed),
        PinAccepted() || null => null,
      };
}

/// The six boxes for choosing or confirming the PIN.
class _PinStep extends StatelessWidget {
  final TextEditingController controller;
  final ChatPinSetupState state;
  final String? errorText;
  final ValueChanged<String> onTyped;
  final VoidCallback onBack;

  const _PinStep({
    required this.controller,
    required this.state,
    required this.errorText,
    required this.onTyped,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final confirming = state.step == ChatPinSetupStep.confirmPin;
    return Column(
      children: [
        PinCodeField(
          // A new field for each step, so focus and the keypad come back.
          key: ValueKey(state.step),
          controller: controller,
          enabled: !state.busy,
          hasError: errorText != null,
          shakeCount: state.shakes,
          onCompleted: onTyped,
        ),
        const SizedBox(height: 16),
        PinStatusLine(
          errorText: errorText,
          checking: state.busy,
          checkingText: context.l10n.chatPinSaving,
        ),
        if (confirming) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: state.busy ? null : onBack,
            child: Text(context.l10n.chatPinChooseAnother),
          ),
        ],
      ],
    );
  }
}
