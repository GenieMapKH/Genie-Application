import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genie/features/auth/presentation/screens/welcome_page.dart';
import 'package:genie/features/auth/presentation/screens/login_page.dart';
import 'package:genie/features/auth/presentation/screens/create_account_page.dart';
import 'package:genie/features/auth/presentation/screens/forgot_password_page.dart';
import 'package:genie/features/auth/presentation/screens/otp_verification_page.dart';
import 'package:genie/features/auth/presentation/screens/reset_password_page.dart';
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
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/verify-otp' ||
          state.matchedLocation == '/reset-password';

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
        path: '/forgot-password',
        pageBuilder: (context, state) => AppTransitionPage(
          child: const ForgotPasswordPage(),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: '/verify-otp',
        pageBuilder: (context, state) {
          final email = Uri.decodeComponent(
            state.uri.queryParameters['email'] ?? '',
          );
          return AppTransitionPage(
            child: OtpVerificationPage(email: email),
            key: state.pageKey,
          );
        },
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) {
          final email = Uri.decodeComponent(
            state.uri.queryParameters['email'] ?? '',
          );
          final otp = Uri.decodeComponent(
            state.uri.queryParameters['otp'] ?? '',
          );
          return AppTransitionPage(
            child: ResetPasswordPage(email: email, otp: otp),
            key: state.pageKey,
          );
        },
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            AppTransitionPage(child: const MainLayout(), key: state.pageKey),
      ),
    ],
  );
});
