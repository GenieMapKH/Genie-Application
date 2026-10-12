import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/profile/data/repositories/user_repository.dart';
import 'package:genie/features/profile/presentation/view_models/profile_edit_controller.dart';
import 'package:genie/features/profile/presentation/view_models/user_providers.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/utils/app_popup.dart';

/// Opens the dialog that edits one text [field] of the profile.
///
/// [invalidMessage] is shown when the value breaks the field's rules, and
/// [takenMessage] when another account already has it.
Future<void> showProfileFieldEditor(
  BuildContext context, {
  required ProfileField field,
  required String label,
  required String invalidMessage,
  String? takenMessage,
  String? help,
  String? initialValue,
  TextInputType? keyboardType,
}) {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _ProfileFieldEditor(
      field: field,
      label: label,
      help: help,
      initialValue: initialValue,
      keyboardType: keyboardType,
      invalidMessage: invalidMessage,
      takenMessage: takenMessage,
    ),
  );
}

class _ProfileFieldEditor extends ConsumerStatefulWidget {
  final ProfileField field;
  final String label;
  final String? help;
  final String? initialValue;
  final TextInputType? keyboardType;
  final String invalidMessage;
  final String? takenMessage;

  const _ProfileFieldEditor({
    required this.field,
    required this.label,
    required this.invalidMessage,
    this.takenMessage,
    this.help,
    this.initialValue,
    this.keyboardType,
  });

  @override
  ConsumerState<_ProfileFieldEditor> createState() =>
      _ProfileFieldEditorState();
}

class _ProfileFieldEditorState extends ConsumerState<_ProfileFieldEditor> {
  late final _controller = TextEditingController(text: widget.initialValue);
  String? _error;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final unchanged =
        ProfileEditController.normalize(widget.field, _controller.text) ==
        widget.initialValue;
    if (unchanged) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _error = null;
      _isSaving = true;
    });
    final result = await ref
        .read(profileEditControllerProvider)
        .save(widget.field, _controller.text);
    if (!mounted) return;

    if (result == ProfileSaveResult.saved) {
      Navigator.pop(context);
      AppPopup.showSuccess(context, context.l10n.commonSaved);
      return;
    }
    setState(() {
      _isSaving = false;
      _error = switch (result) {
        ProfileSaveResult.invalid => widget.invalidMessage,
        ProfileSaveResult.taken =>
          widget.takenMessage ?? context.l10n.commonSomethingWentWrong,
        _ => context.l10n.commonSomethingWentWrong,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final help = widget.help;

    return AlertDialog(
      title: Text(
        l10n.personalInfoEdit(widget.label),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (help != null) ...[
            Text(
              help,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !_isSaving,
            keyboardType: widget.keyboardType,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            style: TextStyle(fontSize: 16, color: colors.textPrimary),
            decoration: InputDecoration(
              labelText: widget.label,
              prefixText: widget.field == ProfileField.username ? '@' : null,
              errorText: _error,
              errorMaxLines: 3,
              filled: true,
              fillColor: colors.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.commonSave),
        ),
      ],
    );
  }
}
