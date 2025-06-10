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

class AppRouter {
  final AuthController authController;
  late final GoRouter router;

  AppRouter(this.authController) {
    router = GoRouter(
      refreshListenable: authController,
      initialLocation: '/splash', // همیشه با اسپلش شروع کن
      routes: [
        GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
        GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
        GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/start-trip', builder: (context, state) => const StartTripScreen()),
        GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
        GoRoute(path: '/guardians', builder: (context, state) => const GuardianScreen()),
      ],
      redirect: (BuildContext context, GoRouterState state) {
        final loggedIn = authController.authState == AuthState.authenticated;
        final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';
        final onSplash = state.matchedLocation == '/splash';

        // اگر وضعیت احراز هویت در حال بررسی است، در صفحه اسپلش بمان
        if (authController.authState == AuthState.unknown) {
          return onSplash ? null : '/splash';
        }

        // اگر کاربر لاگین کرده و در صفحات ورود یا اسپلش است، به خانه ببر
        if (loggedIn && (loggingIn || onSplash)) {
          return '/home';
        }

        // اگر کاربر لاگین نکرده و در صفحه‌ای غیر از ورود است، به صفحه ورود ببر
        if (!loggedIn && !loggingIn) {
          return '/login';
        }

        // در غیر این صورت، نیازی به تغییر مسیر نیست
        return null;
      },
    );
  }
}