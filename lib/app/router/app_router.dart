import 'package:tilomnov/features/auth/presentation/view_models/login_form_provider.dart';
import 'package:tilomnov/features/auth/presentation/view_models/password_reset_flow.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tilomnov/features/auth/presentation/screens/welcome_page.dart';
import 'package:tilomnov/features/auth/presentation/screens/login_page.dart';
import 'package:tilomnov/features/auth/presentation/screens/create_account_page.dart';
import 'package:tilomnov/features/auth/presentation/screens/forgot_password_page.dart';
import 'package:tilomnov/features/auth/presentation/screens/otp_verification_page.dart';
import 'package:tilomnov/features/auth/presentation/screens/reset_password_page.dart';
import 'package:tilomnov/features/home/presentation/screens/main_layout.dart';
import 'package:tilomnov/app/session/chat_pin_gate.dart';

import 'package:tilomnov/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tilomnov/shared/transitions/app_transition_page.dart';

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
          child: ForgotPasswordPage(
            initialMethod: state.uri.queryParameters['method'] == 'phone'
                ? AuthMethod.phone
                : AuthMethod.email,
          ),
          key: state.pageKey,
        ),
      ),
      GoRoute(
        path: '/verify-otp',
        pageBuilder: (context, state) {
          // An SMS reset carries its Firebase session in `extra`; an email
          // one can also come as `?email=` (older links).
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
        path: '/home',
        pageBuilder: (context, state) => AppTransitionPage(
          child: const ChatPinGate(child: MainLayout()),
          key: state.pageKey,
        ),
      ),
    ],
  );
});
