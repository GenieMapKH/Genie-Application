import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/welcome_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/create_account_page.dart';
import '../../features/home/presentation/main_layout.dart';

import '../../core/storage/auth_storage.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      // Check if user is logged in
      final token = await AuthStorage.getAccessToken();
      final isLoggedIn = token != null && token.isNotEmpty;
      
      // Determine if they are on an authentication-related screen
      final isAuthScreen = state.matchedLocation == '/' || 
                           state.matchedLocation == '/login' || 
                           state.matchedLocation == '/register';
                           
      if (isLoggedIn && isAuthScreen) {
        // Bypass welcome/login and go straight to home
        return '/home';
      }
      
      return null; // Continue normally
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const WelcomePage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const CreateAccountPage(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const MainLayout()),
    ],
  );
});
