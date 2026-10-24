import 'package:flutter/material.dart';

import 'package:genie/l10n/l10n.dart';

/// The longest name the server keeps.
const _maxName = 60;

/// Asks for a saved search's name, starting from [initialName]. The trimmed
/// name, or null when cancelled.
Future<String?> showSavedSearchNameDialog(
  BuildContext context, {
  required String title,
  required String initialName,
  String? help,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) =>
        _NameDialog(title: title, initialName: initialName, help: help),
  );
}

class _NameDialog extends StatefulWidget {
  final String title;
  final String initialName;
  final String? help;

  const _NameDialog({
    required this.title,
    required this.initialName,
    this.help,
  });

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(
    text: widget.initialName.length > _maxName
        ? widget.initialName.substring(0, _maxName)
        : widget.initialName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _name => _controller.text.trim();

  void _done() {
    if (_name.isNotEmpty) Navigator.pop(context, _name);
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
          if (widget.help case final help?) ...[
            Text(help),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: _maxName,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _done(),
            decoration: InputDecoration(labelText: l10n.savedSearchName),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: _name.isEmpty ? null : _done,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
