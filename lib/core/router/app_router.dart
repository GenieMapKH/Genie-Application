import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/welcome_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/create_account_page.dart';
import '../../features/home/presentation/main_layout.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
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
