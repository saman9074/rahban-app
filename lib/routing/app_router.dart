import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rahban/features/auth/presentation/auth_controller.dart';
import 'package:rahban/features/auth/presentation/login_screen.dart';
import 'package:rahban/features/auth/presentation/register_screen.dart';
import 'package:rahban/features/guardian/presentation/guardian_screen.dart';
import 'package:rahban/features/history/presentation/history_screen.dart';
import 'package:rahban/features/home/presentation/home_screen.dart';
import 'package:rahban/features/profile/presentation/profile_screen.dart';
import 'package:rahban/features/splash/splash_screen.dart';
import 'package:rahban/features/trip/presentation/start_trip_screen.dart';

import '../main.dart';

class AppRouter {
  final AuthController authController;

  late final GoRouter router;

  AppRouter(this.authController);

  GoRouter createRouter(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: authController,
      redirect: (context, state) {
        final authState = authController.authState;
        final isSplash = state.matchedLocation == '/splash';
        final isAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';
        final isLoggedIn = authState == AuthState.authenticated;

        // اگر Splash هنوز نمایش داده نشده، اجازه ورود به صفحات دیگه نیست
        if (!appState.splashShown) {
          if (!isSplash) return '/splash';
          return null;
        }

        // بعد از نمایش Splash:
        if (isSplash && appState.splashShown) {
          return isLoggedIn ? '/home' : '/login';
        }

        if (!isLoggedIn && !isAuth) return '/login';
        if (isLoggedIn && isAuth) return '/home';

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) {
            // کنترل markSplashShown رو به SplashScreen منتقل میکنیم تا یکبار اجرا بشه
            return SplashScreen(
              onInitializationComplete: () {
                Provider.of<AppState>(context, listen: false).markSplashShown();
              },
            );
          },
        ),
        GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
        GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
        ShellRoute(
          builder: (context, state, child) => Scaffold(body: child),
          routes: [
            GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
            GoRoute(path: '/guardian', builder: (context, state) => const GuardianScreen()),
            GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
            GoRoute(path: '/trip', builder: (context, state) => const StartTripScreen()),
          ],
        ),
      ],
    );
  }
}
