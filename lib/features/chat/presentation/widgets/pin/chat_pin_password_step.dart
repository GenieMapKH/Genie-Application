import 'package:flutter/material.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/chat/presentation/widgets/pin/pin_status_line.dart';
import 'package:genie/features/chat/providers/chat_pin_setup_provider.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/widgets/buttons/app_button.dart';

/// The account password, typed once to move chats locked with it to a PIN.
/// After a refusal it offers to start over with new keys, for a password
/// that was reset since.
class ChatPinPasswordStep extends StatefulWidget {
  final ChatPinSetupState state;
  final String? errorText;
  final ValueChanged<String> onSubmit;
  final VoidCallback onStartOver;

  const ChatPinPasswordStep({
    super.key,
    required this.state,
    required this.errorText,
    required this.onSubmit,
    required this.onStartOver,
  });

  @override
  State<ChatPinPasswordStep> createState() => _ChatPinPasswordStepState();
}

class _ChatPinPasswordStepState extends State<ChatPinPasswordStep> {
  final _controller = TextEditingController();
  bool _hidden = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmStartOver() async {
    final l10n = context.l10n;
    final goAhead = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chatPinStartOverTitle),
        content: Text(l10n.chatPinStartOverMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: context.colors.danger),
            child: Text(l10n.chatPinStartOverAction),
          ),
        ],
      ),
    );
    if (goAhead == true) widget.onStartOver();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final busy = widget.state.busy;

    return Column(
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          enabled: !busy,
          obscureText: _hidden,
          autofillHints: const [AutofillHints.password],
          onSubmitted: widget.onSubmit,
          decoration: InputDecoration(
            labelText: l10n.chatPasswordLabel,
            errorText: widget.errorText == null ? null : '',
            errorStyle: const TextStyle(height: 0),
            suffixIcon: IconButton(
              icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _hidden = !_hidden),
            ),
          ),
        ),
        const SizedBox(height: 12),
        PinStatusLine(
          errorText: widget.errorText,
          checking: busy,
          checkingText: l10n.chatPasswordChecking,
        ),
        const SizedBox(height: 16),
        AppButton.primary(
          text: l10n.commonContinue,
          isLoading: busy,
          onPressed: busy ? null : () => widget.onSubmit(_controller.text),
        ),
        if (widget.state.canStartOver) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: busy ? null : _confirmStartOver,
            child: Text(l10n.chatPinStartOverLink),
          ),
        ],
      ],
    );
  }
}
