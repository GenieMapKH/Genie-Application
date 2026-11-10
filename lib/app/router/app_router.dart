import 'package:tilomnov/features/auth/presentation/view_models/password_reset_flow.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart';
import 'package:tilomnov/features/auth/presentation/screens/admin_email_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/auth/presentation/screens/welcome_page.dart';
import 'package:tilomnov/features/auth/presentation/screens/login_page.dart';
import 'package:tilomnov/features/auth/presentation/screens/create_account_page.dart';
import 'package:tilomnov/features/auth/presentation/screens/forgot_password_page.dart';
import 'package:tilomnov/features/auth/presentation/screens/otp_verification_page.dart';
import 'package:tilomnov/features/auth/presentation/screens/reset_password_page.dart';
import 'package:tilomnov/features/home/presentation/screens/main_layout.dart';

import 'package:tilomnov/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tilomnov/shared/transitions/app_transition_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      // Check if user is logged in
      var token = await AuthStorage.getAccessToken();
      if (AuthStorage.needsAdminEmailVerification(token)) {
        await AuthStorage.clearTokens();
        token = null;
      }
      final isLoggedIn = token != null && token.isNotEmpty;
      final isAdmin = AuthStorage.isAdminAccessToken(token);
      final path = state.matchedLocation;

      if (path == '/admin-login') return null;

      if (isAdmin &&
          (path == '/' || path == '/login' || path == '/admin/dashboard')) {
        return '/home';
      }
      if (!isAdmin && path.startsWith('/admin')) {
        return isLoggedIn ? '/home' : '/login';
      }

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
          // Email recovery also accepts older links with `?email=`.
          final target = state.extra is PasswordResetTarget
              ? state.extra! as PasswordResetTarget
              : EmailResetTarget(
                  Uri.decodeComponent(state.uri.queryParameters['email'] ?? ''),
                );
          return AppTransitionPage(
            child: OtpVerificationPage(target: target),
            key: state.pageKey,
          );
        },
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) {
          final proof = state.extra is PasswordResetProof
              ? state.extra! as PasswordResetProof
              : EmailCodeProof(
                  Uri.decodeComponent(state.uri.queryParameters['email'] ?? ''),
                  Uri.decodeComponent(state.uri.queryParameters['otp'] ?? ''),
                );
          return AppTransitionPage(
            child: ResetPasswordPage(proof: proof),
            key: state.pageKey,
          );
        },
      ),
      GoRoute(
        path: '/admin-login',
        pageBuilder: (context, state) {
          final token = state.uri.queryParameters['token'];
          return AppTransitionPage(
            key: state.pageKey,
            child: AdminEmailPage(key: ValueKey(token), token: token),
          );
        },
      ),
      GoRoute(
        path: '/admin/dashboard',
        pageBuilder: (context, state) =>
            AppTransitionPage(child: const MainLayout(), key: state.pageKey),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            AppTransitionPage(child: const MainLayout(), key: state.pageKey),
      ),
    ],
  );
});
