import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:genie/app/navigation/call_navigation.dart';
import 'package:genie/app/router/app_router.dart';
import 'package:genie/app/session/sign_out.dart';
import 'package:genie/core/theme/app_theme.dart';
import 'package:genie/core/theme/scroll_physics.dart';
import 'package:genie/features/auth/data/repositories/auth_repository.dart';
import 'package:genie/features/call/providers/call_providers.dart';
import 'package:genie/features/chat/providers/chat_service_providers.dart';
import 'package:genie/features/notifications/providers/notification_providers.dart';
import 'package:genie/features/settings/providers/app_settings_providers.dart';
import 'package:genie/l10n/l10n.dart';
import 'package:genie/shared/utils/app_popup.dart';

class AppScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const GlidingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // The server ended this device's session (signed out from another
    // device, for one): leave at once, whatever screen is open.
    ref.listen(sessionEndedProvider, (_, _) async {
      await ref.read(signOutProvider)();
      router.go('/');

      final context = router.routerDelegate.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        AppPopup.showInfo(context, context.l10n.sessionEnded);
      }
    });

    // Chat keys are made at sign-in, not first when a chat is opened.
    ref.listen(chatKeysQuietSetupProvider, (_, _) {});
    // Notifications: shown and opened from the start, and this device
    // registered for them while someone is signed in.
    ref.listen(pushNotificationsProvider, (_, _) {});
    ref.listen(pushRegistrationSyncProvider, (_, _) {});
    // A call, placed or received, shows its screen over everything.
    ref.listen(callControllerProvider, (_, call) {
      onCallChanged(ref, router, call);
    });

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Tilomnov',
      scrollBehavior: AppScrollBehavior(),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      // Null follows the phone's language; English when that is not offered.
      locale: ref.watch(localeProvider),
      supportedLocales: AppLanguages.all,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}
