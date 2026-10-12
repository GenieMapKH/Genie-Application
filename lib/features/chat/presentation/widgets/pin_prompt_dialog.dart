import 'package:flutter/material.dart';

/// Asks for the 6-digit backup PIN. Returns null if the user cancels.
Future<String?> showPinPrompt(
  BuildContext context, {
  required String title,
  required String helper,
  bool allowCancel = true,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PinPromptDialog(
      title: title,
      helper: helper,
      allowCancel: allowCancel,
    ),
  );
}

class _PinPromptDialog extends StatefulWidget {
  final String title;
  final String helper;
  final bool allowCancel;

  const _PinPromptDialog({
    required this.title,
    required this.helper,
    required this.allowCancel,
  });

  @override
  State<_PinPromptDialog> createState() => _PinPromptDialogState();
}

class _PinPromptDialogState extends State<_PinPromptDialog> {
  final _controller = TextEditingController();

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
          hintText: '6-digit PIN',
          helperText: widget.helper,
        ),
      ),
      actions: [
        if (widget.allowCancel)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
