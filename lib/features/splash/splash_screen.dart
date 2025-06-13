import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rahban/features/auth/presentation/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onInitializationComplete;

  const SplashScreen({super.key, this.onInitializationComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    Timer(const Duration(milliseconds: 500), () {
      if (mounted) _animationController.forward();
    });

    Timer(const Duration(seconds: 5), () {
      if (!mounted) return;

      widget.onInitializationComplete?.call();

      final authState = context.read<AuthController>().authState;

      if (authState == AuthState.authenticated) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // لوگو یا آیکن جایگزین
                  Builder(
                    builder: (context) {
                      try {
                        return Image.asset(
                          'assets/images/rahban.png',
                          width: 150,
                          height: 150,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.shield_outlined,
                            size: 100,
                            color: theme.primaryColor,
                          ),
                        );
                      } catch (_) {
                        return Icon(
                          Icons.shield_outlined,
                          size: 100,
                          color: theme.primaryColor,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'رهبان',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.primaryColorDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '«سفر کن، ما مراقبیم.»',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
