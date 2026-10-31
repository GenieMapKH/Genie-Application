import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/profile/data/repositories/user_repository.dart';
import 'package:tilomnov/features/profile/presentation/view_models/profile_edit_controller.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';

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
  /// Wait for a pause in typing before asking the server about a username.
  static const _checkDelay = Duration(milliseconds: 400);

  late final _controller = TextEditingController(text: widget.initialValue);
  Timer? _checkTimer;
  String? _error;
  bool _isSaving = false;

  /// What is known about the username as typed; null when there is nothing
  /// to say (not a username field, unchanged, or not asked yet).
  UsernameCheck? _usernameCheck;
  bool _isChecking = false;

  bool get _isUsername => widget.field == ProfileField.username;

  /// A username known to be taken or malformed is not worth sending.
  bool get _canSave =>
      !_isSaving &&
      !_isChecking &&
      _usernameCheck != UsernameCheck.taken &&
      _usernameCheck != UsernameCheck.invalid;

  @override
  void dispose() {
    _checkTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Checks the username while it is typed, so "already taken" appears
  /// before Save is pressed. Another person may take it in the meantime, so
  /// saving still handles that answer too.
  void _onChanged(String text) {
    if (!_isUsername) return;

    _checkTimer?.cancel();
    final username = ProfileEditController.normalize(widget.field, text);
    setState(() => _error = null);

    // Unchanged: it is this user's own, nothing to ask.
    if (username == widget.initialValue) {
      setState(() {
        _usernameCheck = null;
        _isChecking = false;
      });
      return;
    }
    // Malformed: said at once, without waiting or asking.
    if (!ProfileEditController.isValid(widget.field, username)) {
      setState(() {
        _usernameCheck = UsernameCheck.invalid;
        _isChecking = false;
      });
      return;
    }

    setState(() {
      _usernameCheck = null;
      _isChecking = true;
    });
    _checkTimer = Timer(_checkDelay, () => _checkUsername(text));
  }

  Future<void> _checkUsername(String text) async {
    final check = await ref
        .read(profileEditControllerProvider)
        .checkUsername(text);
    // The answer is for what was typed then: ignore it if the text moved on.
    if (!mounted || _controller.text != text) return;
    setState(() {
      _usernameCheck = check;
      _isChecking = false;
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
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
        _ => failureMessage(
          context.l10n,
          fallback: context.l10n.commonSomethingWentWrong,
        ),
      };
    });
  }

  /// The reason the typed username cannot be used, if it is known.
  String? _usernameProblem(BuildContext context) {
    return switch (_usernameCheck) {
      UsernameCheck.taken =>
        widget.takenMessage ?? context.l10n.commonSomethingWentWrong,
      UsernameCheck.invalid => widget.invalidMessage,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final help = widget.help;
    final problem = _error ?? _usernameProblem(context);
    final isAvailable = _usernameCheck == UsernameCheck.available;

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
            onChanged: _onChanged,
            onSubmitted: (_) => _save(),
            style: TextStyle(fontSize: 16, color: colors.textPrimary),
            decoration: InputDecoration(
              labelText: widget.label,
              prefixText: _isUsername ? '@' : null,
              errorText: problem,
              errorMaxLines: 3,
              helperText: _isChecking
                  ? l10n.personalInfoUsernameChecking
                  : isAvailable
                  ? l10n.personalInfoUsernameAvailable
                  : null,
              helperStyle: TextStyle(
                color: isAvailable ? colors.success : colors.textMuted,
              ),
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
          onPressed: _canSave ? _save : null,
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
