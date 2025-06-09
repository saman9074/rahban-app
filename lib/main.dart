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
import 'package:rahban/features/trip/presentation/trip_controller.dart';
import 'package:rahban/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fa_IR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<TripRepository>(create: (_) => TripRepository()),
        Provider<UserRepository>(create: (_) => UserRepository()),
        Provider<GuardianRepository>(create: (_) => GuardianRepository()),

        ChangeNotifierProvider<AuthController>(
          create: (context) => AuthController(context.read<AuthRepository>())..checkAuthenticationStatus(),
        ),
        ChangeNotifierProvider<TripController>(
          create: (context) => TripController(context.read<TripRepository>()),
        ),
        ChangeNotifierProvider<ProfileController>(
          create: (context) => ProfileController(context.read<UserRepository>()),
        ),
        ChangeNotifierProvider<HistoryController>(
          create: (context) => HistoryController(context.read<TripRepository>()),
        ),
        ChangeNotifierProvider<GuardianController>(
          create: (context) => GuardianController(context.read<GuardianRepository>()),
        ),
      ],
      child: Builder(
        builder: (context) {
          final router = AppRouter(context.watch<AuthController>()).router;
          return MaterialApp.router(
            title: 'Rahban',
            debugShowCheckedModeBanner: false,
            theme: ThemeData( // Theme Data remains the same
              primarySwatch: Colors.teal,
              scaffoldBackgroundColor: Colors.grey[50],
              textTheme: GoogleFonts.vazirmatnTextTheme(Theme.of(context).textTheme).apply(bodyColor: Colors.grey[800], displayColor: Colors.black87),
              appBarTheme: AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.black87, titleTextStyle: GoogleFonts.vazirmatn(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87)),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Colors.teal, width: 2)),
                filled: true,
                fillColor: Colors.white,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), padding: const EdgeInsets.symmetric(vertical: 16.0), backgroundColor: Colors.teal[700], foregroundColor: Colors.white, textStyle: GoogleFonts.vazirmatn(fontSize: 16, fontWeight: FontWeight.bold))),
              textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: Colors.teal[800], textStyle: GoogleFonts.vazirmatn(fontWeight: FontWeight.w600,))),
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}