import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/core/theme/app_colors.dart';
import 'package:tilomnov/features/profile/presentation/view_models/user_providers.dart';
import 'package:tilomnov/features/security/presentation/view_models/account_security_controller.dart';
import 'package:tilomnov/features/security/presentation/view_models/security_providers.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/feedback/failure_message.dart';
import 'package:tilomnov/shared/utils/email_address.dart';
import 'package:tilomnov/shared/widgets/buttons/app_button.dart';
import 'package:tilomnov/shared/widgets/forms/app_text_field.dart';
import 'package:tilomnov/shared/widgets/layout/app_page_scaffold.dart';

/// Adds an email to an account made with only a phone number, so a
/// forgotten password can be reset by email. Confirmed with the password.
class AddEmailPage extends ConsumerStatefulWidget {
  const AddEmailPage({super.key});

  @override
  ConsumerState<AddEmailPage> createState() => _AddEmailPageState();
}

class _AddEmailPageState extends ConsumerState<AddEmailPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  String? _emailError;
  String? _passwordError;
  bool _isSaving = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final email = _email.text.trim();
    setState(() {
      _emailError = isValidEmail(email) ? null : l10n.authErrEnterValidEmail;
      _passwordError = _password.text.isEmpty
          ? l10n.passwordCurrentRequired
          : null;
    });
    if (_emailError != null || _passwordError != null) return;

    setState(() => _isSaving = true);
    final result = await ref
        .read(accountSecurityControllerProvider)
        .addEmail(email: email, password: _password.text);
    if (!mounted) return;

    if (result == AccountActionResult.done) {
      ref.invalidate(userProfileProvider);
      AppPopup.showSuccess(context, l10n.addEmailDone);
      Navigator.pop(context);
      return;
    }
    setState(() {
      _isSaving = false;
      if (result == AccountActionResult.emailTaken) {
        _emailError = l10n.addEmailTaken;
      } else {
        _passwordError = switch (result) {
          AccountActionResult.identityRejected => l10n.passwordIncorrect,
          AccountActionResult.tooManyAttempts => l10n.commonTooManyAttempts,
          AccountActionResult.deviceTooNew => l10n.accountDeviceTooNew,
          _ => failureMessage(l10n, fallback: l10n.commonSomethingWentWrong),
        };
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppPageScaffold(
      title: l10n.addEmailTitle,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Text(
            l10n.addEmailIntro,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: context.colors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            key: const Key('add_email_field'),
            label: l10n.personalInfoEmail,
            hintText: l10n.authExampleGmailCom,
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            maxWidth: null,
            textInputAction: TextInputAction.next,
            errorText: _emailError,
          ),
          const SizedBox(height: 16),
          AppTextField(
            key: const Key('add_email_password_field'),
            label: l10n.passwordCurrent,
            controller: _password,
            obscureText: true,
            maxWidth: null,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            errorText: _passwordError,
          ),
          const SizedBox(height: 28),
          AppButton(
            text: l10n.addEmailTitle,
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
