import 'package:flutter/material.dart';

Future<String?> confirmModeration(
  BuildContext context, {
  required String title,
  required String message,
  bool permanent = false,
}) async {
  return showDialog<String>(
    context: context,
    builder: (_) =>
        _ModerationDialog(title: title, message: message, permanent: permanent),
  );
}

class _ModerationDialog extends StatefulWidget {
  final String title;
  final String message;
  final bool permanent;
  const _ModerationDialog({
    required this.title,
    required this.message,
    required this.permanent,
  });
  @override
  State<_ModerationDialog> createState() => _ModerationDialogState();
}

class _ModerationDialogState extends State<_ModerationDialog> {
  final reason = TextEditingController();
  final confirmation = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    reason.dispose();
    confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SingleChildScrollView(
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.message),
            const SizedBox(height: 16),
            TextFormField(
              controller: reason,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Reason'),
              validator: (value) => (value?.trim().length ?? 0) < 3
                  ? 'Enter a reason (at least 3 characters)'
                  : null,
            ),
            if (widget.permanent)
              TextFormField(
                controller: confirmation,
                decoration: const InputDecoration(
                  labelText: 'Type DELETE to confirm',
                ),
                validator: (value) =>
                    value == 'DELETE' ? null : 'Type DELETE to continue',
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(context, reason.text.trim());
          }
        },
        child: Text(widget.title),
      ),
    ],
  );
}
