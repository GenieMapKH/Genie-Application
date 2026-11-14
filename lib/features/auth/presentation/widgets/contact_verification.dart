import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tilomnov/features/auth/data/phone_verification_service.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/auth/presentation/auth_error_message.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/dialogs/app_dialog.dart';
import 'package:tilomnov/shared/widgets/forms/app_text_field.dart';

Future<String?> verifyEmailOwnership(
  BuildContext context,
  WidgetRef ref,
  String email,
) {
  final auth = ref.read(authServiceProvider);
  return _verify(context, email, () async {
    await auth.requestEmailVerification(email);
    return null;
  }, (code) => auth.confirmEmailVerification(email, code));
}

Future<String?> verifyPhoneOwnership(
  BuildContext context,
  WidgetRef ref,
  String phone,
) async {
  final challenge = ref.read(phoneVerificationServiceProvider).challenge(phone);
  try {
    return await _verify(
      context,
      phone,
      challenge.send,
      challenge.confirm,
      automaticProof: challenge.automaticProof,
    );
  } finally {
    challenge.close();
  }
}

Future<String?> _verify(
  BuildContext context,
  String destination,
  Future<String?> Function() send,
  Future<String> Function(String) confirm, {
  Future<String?>? automaticProof,
}) async {
  final proof = await send();
  if (proof != null || !context.mounted) return proof;
  return AppDialog.show<String>(
    context,
    barrierDismissible: false,
    builder: (_) => _ContactCodeDialog(
      destination: destination,
      send: send,
      confirm: confirm,
      automaticProof: automaticProof,
    ),
  );
}

class _ContactCodeDialog extends StatefulWidget {
  final String destination;
  final Future<String?> Function() send;
  final Future<String> Function(String) confirm;
  final Future<String?>? automaticProof;
  const _ContactCodeDialog({
    required this.destination,
    required this.send,
    required this.confirm,
    this.automaticProof,
  });
  @override
  State<_ContactCodeDialog> createState() => _ContactCodeDialogState();
}

class _ContactCodeDialogState extends State<_ContactCodeDialog> {
  final code = TextEditingController();
  Timer? timer;
  int wait = 60;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    widget.automaticProof?.then((proof) {
      if (mounted && proof != null && !busy) Navigator.pop(context, proof);
    });
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && wait > 0) setState(() => wait--);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    code.dispose();
    super.dispose();
  }

  String message(Object error) => authErrorMessage(context.l10n, error);

  Future<void> confirm() async {
    if (busy) return;
    if (!RegExp(r'^\d{6}$').hasMatch(code.text.trim())) {
      setState(() => error = context.l10n.authPleaseEnterAll6Digits);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final proof = await widget.confirm(code.text.trim());
      if (mounted) Navigator.pop(context, proof);
    } catch (e) {
      if (mounted) setState(() => error = message(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resend() async {
    if (busy || wait > 0) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final proof = await widget.send();
      if (!mounted) return;
      if (proof != null) {
        Navigator.pop(context, proof);
        return;
      }
      setState(() {
        wait = 60;
        code.clear();
      });
    } catch (e) {
      if (mounted) setState(() => error = message(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppDialog(
      icon: LucideIcons.badgeCheck,
      title: l10n.authOtpVerification,
      message: widget.destination,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            key: const Key('contact_otp'),
            controller: code,
            label: l10n.authOtpVerification,
            keyboardType: TextInputType.number,
            errorText: error,
            enabled: !busy,
            onSubmitted: (_) => confirm(),
          ),
          TextButton(
            onPressed: busy || wait > 0 ? null : resend,
            child: Text(
              wait > 0 ? l10n.authResendOtpIn(wait) : l10n.authResendOtp,
            ),
          ),
        ],
      ),
      primaryLabel: l10n.authVerify,
      onPrimary: busy ? null : confirm,
      primaryBusy: busy,
      secondaryLabel: l10n.commonCancel,
      onSecondary: () {
        if (!busy) Navigator.pop(context);
      },
    );
  }
}
