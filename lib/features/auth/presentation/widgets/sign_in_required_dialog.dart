import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/widgets/dialogs/app_dialog.dart';

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
  return AppDialog.show<void>(
    context,
    builder: (dialogContext) {
      final l10n = dialogContext.l10n;
      return AppDialog(
        icon: Icons.person_rounded,
        title: l10n.loginRequiredTitle,
        message: l10n.loginRequiredMessage,
        primaryLabel: l10n.loginRequiredAction,
        onPrimary: () {
          Navigator.pop(dialogContext);
          router?.push('/');
        },
        secondaryLabel: l10n.commonCancel,
      );
    },
  );
}
