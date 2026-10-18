import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/security/presentation/view_models/account_security_controller.dart';
import 'package:genie/features/security/presentation/view_models/security_providers.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/utils/app_popup.dart';
import 'package:genie/shared/widgets/buttons/app_button.dart';
import 'package:genie/shared/widgets/layout/app_page_scaffold.dart';
import 'package:genie/shared/widgets/forms/app_text_field.dart';

/// Sets a new password after checking the current one. Every other device
/// is signed out by the server; this one stays signed in. An account that
/// has no password yet (Google sign-in) uses `CreatePasswordPage` instead.
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirmation = TextEditingController();

  PasswordProblem? _problem;

  /// A refusal from the server, shown under the current password.
  String? _serverError;
  bool _isSaving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final problem = AccountSecurityController.checkNewPassword(
      current: _current.text,
      next: _next.text,
      confirmation: _confirmation.text,
    );
    setState(() {
      _problem = problem;
      _serverError = null;
    });
    if (problem != null) return;

    setState(() => _isSaving = true);
    final result = await ref
        .read(accountSecurityControllerProvider)
        .changePassword(current: _current.text, next: _next.text);
    if (!mounted) return;

    if (result == AccountActionResult.done) {
      AppPopup.showSuccess(context, l10n.passwordChanged);
      Navigator.pop(context);
      return;
    }
    setState(() {
      _isSaving = false;
      _serverError = switch (result) {
        AccountActionResult.identityRejected => l10n.passwordIncorrect,
        AccountActionResult.tooManyAttempts => l10n.commonTooManyAttempts,
        AccountActionResult.deviceTooNew => l10n.accountDeviceTooNew,
        _ => l10n.commonSomethingWentWrong,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppPageScaffold(
      title: l10n.securityChangePassword,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Text(
            l10n.passwordIntro,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: context.colors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: l10n.passwordCurrent,
            controller: _current,
            obscureText: true,
            maxWidth: null,
            textInputAction: TextInputAction.next,
            errorText: _problem == PasswordProblem.currentMissing
                ? l10n.passwordCurrentRequired
                : _serverError,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: l10n.passwordNew,
            controller: _next,
            obscureText: true,
            maxWidth: null,
            textInputAction: TextInputAction.next,
            errorText: switch (_problem) {
              PasswordProblem.tooShort => l10n.passwordTooShort,
              PasswordProblem.sameAsCurrent => l10n.passwordSameAsCurrent,
              _ => null,
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: l10n.passwordConfirm,
            controller: _confirmation,
            obscureText: true,
            maxWidth: null,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            errorText: _problem == PasswordProblem.mismatch
                ? l10n.passwordMismatch
                : null,
          ),
          const SizedBox(height: 28),
          AppButton(
            text: l10n.securityChangePassword,
            onPressed: _submit,
            isLoading: _isSaving,
            maxWidth: null,
            backgroundColor: context.colors.primary,
            textColor: context.colors.onPrimary,
          ),
        ],
      ),
    );
  }
}
