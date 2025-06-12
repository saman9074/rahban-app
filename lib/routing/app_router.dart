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
import 'package:rahban/features/trip/presentation/e2ee_setup_screen.dart';
import 'package:rahban/features/trip/presentation/start_trip_screen.dart';

class AppRouter {
  // The AuthController is now passed via the constructor to handle auth state.
  final AuthController authController;

  AppRouter(this.authController);

  // The GoRouter instance is created once and exposed as a getter.
  late final GoRouter router = GoRouter(
    initialLocation: '/',
    // refreshListenable ensures the router re-evaluates redirects when auth state changes.
    refreshListenable: authController,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

      // A ShellRoute can be used for pages that share a common UI, like a bottom navigation bar.
      ShellRoute(
        builder: (context, state, child) => Scaffold(body: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          GoRoute(path: '/guardians', builder: (context, state) => const GuardianScreen()),
          GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
          // The new route for E2EE setup is included here.
          GoRoute(path: '/e2ee-setup', builder: (context, state) => const E2EESetupScreen()),
          GoRoute(path: '/start-trip', builder: (context, state) => const StartTripScreen()),
        ],
      ),
    ],
    // The redirect logic now correctly uses the injected AuthController.
    redirect: (BuildContext context, GoRouterState state) {
      final authState = authController.authState;
      final isAuthenticated = authState == AuthState.authenticated;
      final isGoingToAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final isGoingToSplash = state.matchedLocation == '/';

      // If not authenticated and not heading to a public route, redirect to login.
      if (!isAuthenticated && !isGoingToAuthRoute && !isGoingToSplash) {
        return '/login';
      }

      // If authenticated and trying to access login/register, redirect to home.
      if (isAuthenticated && isGoingToAuthRoute) {
        return '/home';
      }

      // In all other cases, no redirect is necessary.
      return null;
    },
  );
}
