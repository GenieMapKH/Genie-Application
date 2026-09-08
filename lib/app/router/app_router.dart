import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/auth/presentation/screens/welcome_page.dart';
import 'package:genie/features/auth/presentation/screens/login_page.dart';
import 'package:genie/features/auth/presentation/screens/create_account_page.dart';
import 'package:genie/features/home/presentation/screens/main_layout.dart';

import 'package:genie/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:genie/shared/transitions/app_transition_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      // Check if user is logged in
      final token = await AuthStorage.getAccessToken();
      final isLoggedIn = token != null && token.isNotEmpty;

      // Determine if they are on an authentication-related screen
      final isAuthScreen =
          state.matchedLocation == '/' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (isLoggedIn && isAuthScreen) {
        // Bypass welcome/login and go straight to home
        return '/home';
      }

      return null; // Continue normally
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            AppTransitionPage(child: const WelcomePage(), key: state.pageKey),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            AppTransitionPage(child: const LoginPage(), key: state.pageKey),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => AppTransitionPage(
          child: const CreateAccountPage(),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            AppTransitionPage(child: const MainLayout(), key: state.pageKey),
      ),
    ],
  );
});
