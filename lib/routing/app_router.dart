import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      initialLocation: '/splash', // **تغییر:** مسیر اولیه به اسپلش تغییر کرد
      routes: [
        GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()), // اضافه شد
        GoRoute(path: '/login',builder: (context, state) => const LoginScreen(),),
        GoRoute(path: '/register',builder: (context, state) => const RegisterScreen(),),
        GoRoute(path: '/home',builder: (context, state) => const HomeScreen(), ),
        GoRoute(path: '/start-trip',builder: (context, state) => const StartTripScreen(),),
        GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
        GoRoute(path: '/guardians', builder: (context, state) => const GuardianScreen()),
      ],
      redirect: (context, state) {
        // از ریدایرکت کردن در صفحه اسپلش جلوگیری می‌کنیم
        if (state.matchedLocation == '/splash') return null;

        final currentAuthState = authController.authState;
        final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

        if (currentAuthState == AuthState.unknown) {
          // اگر وضعیت احراز هویت نامشخص است، کاربر را به صفحه ورود می‌فرستیم
          // این اتفاق پس از پایان اسپلش اسکرین رخ می‌دهد
          return '/login';
        }

        if (currentAuthState == AuthState.authenticated) {
          return isAuthRoute ? '/home' : null;
        } else {
          return isAuthRoute ? null : '/login';
        }
      },
    );
  }
}