import 'package:flutter/material.dart';

import 'package:genie/l10n/l10n.dart';

/// Asks for the account password that locks the chat keys. Returns null if
/// the user cancels. The password is only checked by what it opens.
Future<String?> showAccountPasswordPrompt(
  BuildContext context, {
  required String title,
  required String helper,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AccountPasswordDialog(title: title, helper: helper),
  );
}

class _AccountPasswordDialog extends StatefulWidget {
  final String title;
  final String helper;

  const _AccountPasswordDialog({required this.title, required this.helper});

  @override
  State<_AccountPasswordDialog> createState() => _AccountPasswordDialogState();
}

class _AccountPasswordDialogState extends State<_AccountPasswordDialog> {
  final _controller = TextEditingController();
  bool _hidden = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _controller.text;
    if (password.isEmpty) return;
    Navigator.pop(context, password);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.helper),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: _hidden,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.chatPasswordLabel,
              suffixIcon: IconButton(
                icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _hidden = !_hidden),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.commonContinue)),
      ],
    );
  }
}
