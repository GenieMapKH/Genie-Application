import 'package:flutter/material.dart';
import 'package:genie/features/chat/e2ee/pin_rules.dart';
import 'package:genie/l10n/l10n.dart';

/// Asks for the 6-digit backup PIN. Returns null if the user cancels.
/// With [isNewPin] an easily guessed PIN is refused.
Future<String?> showPinPrompt(
  BuildContext context, {
  required String title,
  required String helper,
  bool allowCancel = true,
  bool isNewPin = false,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PinPromptDialog(
      title: title,
      helper: helper,
      allowCancel: allowCancel,
      isNewPin: isNewPin,
    ),
  );
}

class _PinPromptDialog extends StatefulWidget {
  final String title;
  final String helper;
  final bool allowCancel;
  final bool isNewPin;

  const _PinPromptDialog({
    required this.title,
    required this.helper,
    required this.allowCancel,
    required this.isNewPin,
  });

  @override
  State<_PinPromptDialog> createState() => _PinPromptDialogState();
}

class _PinPromptDialogState extends State<_PinPromptDialog> {
  static final _sixDigits = RegExp(r'^\d{6}$');

  final _controller = TextEditingController();
  String? _error;

  /// The PIN protects the chat keys, so a shorter one is never accepted.
  void _submit() {
    final pin = _controller.text;
    if (!_sixDigits.hasMatch(pin)) {
      setState(() => _error = context.l10n.pinIncomplete);
      return;
    }
    if (widget.isNewPin && isGuessablePin(pin)) {
      setState(() => _error = context.l10n.pinTooGuessable);
      return;
    }
    Navigator.pop(context, pin);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 6,
        decoration: InputDecoration(
          hintText: context.l10n.pinHint,
          helperText: widget.helper,
          helperMaxLines: 3,
          errorText: _error,
        ),
      ),
      actions: [
        if (widget.allowCancel)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
          ),
        TextButton(onPressed: _submit, child: Text(context.l10n.pinSubmit)),
      ],
    );
  }
}
