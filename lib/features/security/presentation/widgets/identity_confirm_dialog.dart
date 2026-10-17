import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/logging/app_logger.dart';
import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/auth/data/google_sign_in_service.dart';
import 'package:genie/features/security/data/repositories/account_repository.dart';
import 'package:genie/features/security/presentation/view_models/account_security_controller.dart';
import 'package:genie/l10n/l10n.dart';

/// Asks the user to show they own the account, then runs [action] with that
/// proof. The dialog stays open and says what went wrong until the action
/// succeeds (returns true) or the user cancels (returns false).
///
/// With [offerGoogle] an account linked to Google can confirm by signing in
/// with Google again instead of typing a password. [isDestructive] colours
/// the confirm button as a warning.
Future<bool> showIdentityConfirmDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required bool offerGoogle,
  required Future<AccountActionResult> Function(IdentityProof proof) action,
  bool isDestructive = true,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _IdentityConfirmDialog(
      title: title,
      confirmLabel: confirmLabel,
      offerGoogle: offerGoogle,
      isDestructive: isDestructive,
      action: action,
    ),
  );
  return confirmed == true;
}

class _IdentityConfirmDialog extends ConsumerStatefulWidget {
  final String title;
  final String confirmLabel;
  final bool offerGoogle;
  final bool isDestructive;
  final Future<AccountActionResult> Function(IdentityProof proof) action;

  const _IdentityConfirmDialog({
    required this.title,
    required this.confirmLabel,
    required this.offerGoogle,
    required this.isDestructive,
    required this.action,
  });

  @override
  ConsumerState<_IdentityConfirmDialog> createState() =>
      _IdentityConfirmDialogState();
}

class _IdentityConfirmDialogState
    extends ConsumerState<_IdentityConfirmDialog> {
  final _password = TextEditingController();
  String? _error;
  bool _isBusy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirmWithPassword() async {
    if (_password.text.isEmpty) {
      setState(() => _error = context.l10n.identityConfirmPasswordRequired);
      return;
    }
    await _run(
      IdentityProof.password(_password.text),
      rejected: context.l10n.identityConfirmPasswordWrong,
    );
  }

  Future<void> _confirmWithGoogle() async {
    final l10n = context.l10n;
    setState(() {
      _error = null;
      _isBusy = true;
    });

    String? idToken;
    try {
      idToken = await ref.read(googleSignInServiceProvider).freshIdToken();
    } catch (e) {
      AppLogger.error('Google confirmation failed', e);
    }
    if (!mounted) return;
    if (idToken == null) {
      // The account picker was closed, or Google could not be reached.
      setState(() => _isBusy = false);
      return;
    }
    await _run(
      IdentityProof.google(idToken),
      rejected: l10n.identityConfirmGoogleFailed,
    );
  }

  Future<void> _run(IdentityProof proof, {required String rejected}) async {
    final l10n = context.l10n;
    setState(() {
      _error = null;
      _isBusy = true;
    });

    final result = await widget.action(proof);
    if (!mounted) return;
    if (result == AccountActionResult.done) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _isBusy = false;
      _error = switch (result) {
        AccountActionResult.identityRejected => rejected,
        AccountActionResult.tooManyAttempts => l10n.commonTooManyAttempts,
        AccountActionResult.deviceTooNew => l10n.accountDeviceTooNew,
        _ => l10n.commonSomethingWentWrong,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.offerGoogle
                ? l10n.identityConfirmGoogleHelp
                : l10n.identityConfirmPasswordHelp,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.offerGoogle) ...[
            OutlinedButton(
              onPressed: _isBusy ? null : _confirmWithGoogle,
              child: Text(l10n.identityConfirmWithGoogle),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.identityConfirmOr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.textHint),
              ),
            ),
          ],
          TextField(
            controller: _password,
            obscureText: true,
            enabled: !_isBusy,
            onSubmitted: (_) => _confirmWithPassword(),
            decoration: InputDecoration(
              labelText: l10n.identityConfirmPassword,
              errorText: _error,
              errorMaxLines: 3,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isBusy ? null : () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: _isBusy ? null : _confirmWithPassword,
          style: widget.isDestructive
              ? TextButton.styleFrom(foregroundColor: colors.danger)
              : null,
          child: _isBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
