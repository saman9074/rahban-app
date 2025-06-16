import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rahban/features/auth/presentation/auth_controller.dart';
import 'package:rahban/features/auth/presentation/login_screen.dart';
import 'package:rahban/features/auth/presentation/register_screen.dart';
import 'package:rahban/features/guardian/presentation/guardian_screen.dart';
import 'package:rahban/features/history/presentation/history_screen.dart';
import 'package:rahban/features/home/presentation/home_screen.dart';
import 'package:rahban/features/profile/presentation/profile_screen.dart';
import 'package:rahban/features/security/presentation/e2ee_setup_screen.dart'; // NEW
import 'package:rahban/features/splash/splash_screen.dart';
import 'package:rahban/features/trip/presentation/start_trip_screen.dart';
import 'package:rahban/features/about/presentation/about_us_screen.dart';
import 'package:rahban/features/contact/presentation/contact_us_screen.dart';

class AppRouter {
  final AuthController authController;

  AppRouter(this.authController);

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: authController,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

      ShellRoute(
        builder: (context, state, child) => Scaffold(body: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          GoRoute(path: '/about', builder: (context, state) => const AboutUsScreen()),
          GoRoute(path: '/contact',builder: (context, state) => const ContactUsScreen()),
          GoRoute(path: '/guardians', builder: (context, state) => const GuardianScreen()),
          GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),

          // Route for the initial E2EE setup screen
          GoRoute(path: '/e2ee-setup', builder: (context, state) => const E2EESetupScreen()),

          GoRoute(path: '/start-trip', builder: (context, state) => const StartTripScreen()),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final authState = authController.authState;
      final isAuthenticated = authState == AuthState.authenticated;
      final isGoingToAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final isGoingToSplash = state.matchedLocation == '/';

      if (!isAuthenticated && !isGoingToAuthRoute && !isGoingToSplash) {
        return '/login';
      }
      if (isAuthenticated && isGoingToAuthRoute) {
        return '/home';
      }
      return null;
    },
  );
}
