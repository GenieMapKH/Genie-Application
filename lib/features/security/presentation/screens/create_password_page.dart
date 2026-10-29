import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/logging/app_logger.dart';
import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/auth/data/google_sign_in_service.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/security/presentation/view_models/account_security_controller.dart';
import 'package:tilomnov/features/security/presentation/view_models/security_providers.dart';
import 'package:tilomnov/features/security/presentation/widgets/info_note.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/buttons/app_button.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';
import 'package:tilomnov/shared/widgets/forms/app_text_field.dart';

/// Gives an account that signs in with Google a password of its own.
///
/// Such an account has nothing to type where the app asks for a password
/// (recovering a forgotten chat PIN, for one). The owner confirms with
/// Google once more, then chooses a password. Pops with true once it is set.
class CreatePasswordPage extends ConsumerStatefulWidget {
  /// Said at the top when the user was sent here from something that needs
  /// a password; null when they came on their own.
  final String? reason;

  const CreatePasswordPage({super.key, this.reason});

  @override
  ConsumerState<CreatePasswordPage> createState() => _CreatePasswordPageState();
}

class _CreatePasswordPageState extends ConsumerState<CreatePasswordPage> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  PasswordProblem? _problem;
  String? _serverError;
  bool _isSaving = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final problem = AccountSecurityController.checkFirstPassword(
      next: _password.text,
      confirmation: _confirmation.text,
    );
    setState(() {
      _problem = problem;
      _serverError = null;
    });
    if (problem != null) return;

    setState(() => _isSaving = true);
    final idToken = await _confirmWithGoogle();
    if (!mounted) return;
    if (idToken == null) {
      // The account picker was closed, or Google could not be reached.
      setState(() => _isSaving = false);
      return;
    }

    final result = await ref
        .read(accountSecurityControllerProvider)
        .createPassword(googleIdToken: idToken, password: _password.text);
    if (!mounted) return;

    if (result == AccountActionResult.done) {
      // The profile now says the account has a password.
      ref.invalidate(userProfileProvider);
      AppPopup.showSuccess(context, l10n.createPasswordDone);
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _isSaving = false;
      _serverError = switch (result) {
        AccountActionResult.identityRejected =>
          l10n.identityConfirmGoogleFailed,
        AccountActionResult.tooManyAttempts => l10n.commonTooManyAttempts,
        AccountActionResult.deviceTooNew => l10n.accountDeviceTooNew,
        _ => l10n.commonSomethingWentWrong,
      };
    });
  }

  Future<String?> _confirmWithGoogle() async {
    try {
      return await ref.read(googleSignInServiceProvider).freshIdToken();
    } catch (e) {
      AppLogger.error('Google confirmation failed', e);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reason = widget.reason;

    return AppPageScaffold(
      title: l10n.securityCreatePassword,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          if (reason != null) ...[InfoNote(reason), const SizedBox(height: 16)],
          Text(
            l10n.createPasswordIntro,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: context.colors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: l10n.passwordNew,
            controller: _password,
            obscureText: true,
            maxWidth: null,
            textInputAction: TextInputAction.next,
            errorText: _problem == PasswordProblem.tooShort
                ? l10n.passwordTooShort
                : null,
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
                : _serverError,
          ),
          const SizedBox(height: 28),
          AppButton(
            text: l10n.createPasswordAction,
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
