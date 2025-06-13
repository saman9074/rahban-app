import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:rahban/api/auth_repository.dart';
import 'package:rahban/api/guardian_repository.dart';
import 'package:rahban/api/trip_repository.dart';
import 'package:rahban/api/user_repository.dart';
import 'package:rahban/features/auth/presentation/auth_controller.dart';
import 'package:rahban/features/guardian/presentation/guardian_controller.dart';
import 'package:rahban/features/history/presentation/history_controller.dart';
import 'package:rahban/features/profile/presentation/profile_controller.dart';
import 'package:rahban/features/security/e2ee_controller.dart';
import 'package:rahban/features/trip/presentation/trip_controller.dart';
import 'package:rahban/routing/app_router.dart';
import 'package:camera/camera.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fa_IR', null);
  if (!kIsWeb) {
    try {
      cameras = await availableCameras();
    } on CameraException catch (e) {
      print('Error in fetching the cameras: $e');
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<TripRepository>(create: (_) => TripRepository()),
        Provider<UserRepository>(create: (_) => UserRepository()),
        Provider<GuardianRepository>(create: (_) => GuardianRepository()),
        ChangeNotifierProvider<E2EEController>(create: (_) => E2EEController()),
        ChangeNotifierProvider<AuthController>(
          create: (context) => AuthController(context.read<AuthRepository>())
            ..checkAuthenticationStatus(),
        ),
        ChangeNotifierProvider<ProfileController>(
          create: (context) =>
              ProfileController(context.read<UserRepository>()),
        ),
        ChangeNotifierProvider<HistoryController>(
          create: (context) =>
              HistoryController(context.read<TripRepository>()),
        ),
        ChangeNotifierProvider<GuardianController>(
          create: (context) =>
              GuardianController(context.read<GuardianRepository>()),
        ),
        ChangeNotifierProvider<TripController>(
          create: (context) => TripController(
            context.read<TripRepository>(),
            context.read<E2EEController>(),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          final appRouter = AppRouter(context.watch<AuthController>());
          return MaterialApp.router(
            title: 'Rahban',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primaryColor: const Color(0xFF1E3A8A),
              scaffoldBackgroundColor: const Color(0xFFF9FAFB),
              fontFamily: GoogleFonts.vazirmatn().fontFamily,
              colorScheme: ColorScheme.light(
                primary: const Color(0xFF1E3A8A),
                secondary: const Color(0xFF10B981),
                background: const Color(0xFFF9FAFB),
                surface: Colors.white,
                onPrimary: Colors.white,
                onBackground: const Color(0xFF111827),
                onSurface: Colors.black87,
              ),
              textTheme: GoogleFonts.vazirmatnTextTheme().apply(
                bodyColor: const Color(0xFF111827),
                displayColor: const Color(0xFF111827),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: Color(0xFF111827),
                titleTextStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 12.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: Color(0xFF1E3A8A), width: 2),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: GoogleFonts.vazirmatn(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  textStyle: GoogleFonts.vazirmatn(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            routerConfig: appRouter.router,
          );
        },
      ),
    );
  }
}

class AppState extends ChangeNotifier {
  bool _splashShown = false;
  bool get splashShown => _splashShown;

  void markSplashShown() {
    _splashShown = true;
    notifyListeners();
  }
}
