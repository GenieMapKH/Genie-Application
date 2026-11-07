import 'package:tilomnov/features/call/presentation/mini_call_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tilomnov/app/navigation/call_navigation.dart';
import 'package:tilomnov/app/router/app_router.dart';
import 'package:tilomnov/app/session/sign_out.dart';
import 'package:tilomnov/app/update/update_required_page.dart';
import 'package:tilomnov/core/network/api_version_interceptor.dart';
import 'package:tilomnov/core/theme/app_theme.dart';
import 'package:tilomnov/core/theme/scroll_physics.dart';
import 'package:tilomnov/features/auth/data/repositories/auth_repository.dart';
import 'package:tilomnov/features/call/models/call_state.dart';
import 'package:tilomnov/features/call/providers/call_providers.dart';
import 'package:tilomnov/features/home/presentation/providers/glass_navigation_provider.dart';
import 'package:tilomnov/features/notifications/providers/notification_providers.dart';
import 'package:tilomnov/features/settings/providers/app_settings_providers.dart';
import 'package:tilomnov/l10n/l10n.dart';
import 'package:tilomnov/shared/utils/app_popup.dart';
import 'package:tilomnov/shared/widgets/feedback/connection_popups.dart';
import 'package:tilomnov/shared/widgets/glass/glass_scope.dart';

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
    // The server no longer serves this build's API: only an update helps.
    final updateRequired = ref.watch(apiVersionRetiredProvider);

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

    // Notifications: shown and opened from the start, and this device
    // registered for them while someone is signed in.
    ref.listen(pushNotificationsProvider, (_, _) {});
    ref.listen(pushRegistrationSyncProvider, (_, _) {});
    // A call, placed or received, shows its screen over everything.
    ref.listen(callControllerProvider, (previous, call) {
      onCallChanged(ref, router, previous ?? const CallState(), call);
      final callContext = router.routerDelegate.navigatorKey.currentContext;
      if (callContext != null) {
        ref
            .read(nativeCallIntegrationProvider)
            .update(
              previous ?? const CallState(),
              call,
              title: callContext.l10n.callInProgress,
              returnLabel: callContext.l10n.callReturn,
            );
      }
    });

    ref.listen(callMinimizedProvider, (_, minimized) {
      ref
          .read(callScreenPresenterProvider)
          .update(
            router,
            ref.read(callControllerProvider),
            minimized: minimized,
          );
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
      builder: (context, child) => updateRequired
          ? const UpdateRequiredPage()
          // Every page's floating buttons follow the glass navigation bar.
          : Consumer(
              builder: (context, ref, _) => GlassScope(
                enabled: watchGlassNavigation(ref, context),
                child: ConnectionPopups(
                  navigatorKey: router.routerDelegate.navigatorKey,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      child ?? const SizedBox.shrink(),
                      const MiniCallBar(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
