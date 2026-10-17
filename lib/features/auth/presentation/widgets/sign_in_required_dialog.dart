import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:genie/core/theme/app_colors.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/l10n/l10n.dart';

/// Guards something only an account can do (chat, favourites, posting,
/// the tabs of one's own data). True when someone is signed in; otherwise
/// asks the guest to sign in or create an account, and returns false.
bool requireSignIn(BuildContext context, WidgetRef ref) {
  if (ref.read(isSignedInProvider)) return true;
  showSignInRequiredDialog(context);
  return false;
}

/// "Account required", with a way to the welcome screen (log in or sign up).
///
/// The welcome screen is opened through the router: signing in then goes to
/// the map with `go('/home')`, which closes it. A screen pushed outside the
/// router would stay on top of the map after signing in.
Future<void> showSignInRequiredDialog(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final colors = dialogContext.colors;
      final l10n = dialogContext.l10n;
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        title: Text(
          l10n.loginRequiredTitle,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          l10n.loginRequiredMessage,
          style: GoogleFonts.inter(fontSize: 14, color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              l10n.commonCancel,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              elevation: 4,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              router?.push('/');
            },
            child: Text(
              l10n.loginRequiredAction,
              style: GoogleFonts.inter(
                color: colors.onPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );
}
