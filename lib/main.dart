import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
import 'package:rahban/models/offline_packet.dart';
import 'package:rahban/routing/app_router.dart';
import 'package:rahban/services/background_service.dart'; // Import service

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- [NEW] Initialize Hive and Background Service ---
  await Hive.initFlutter();
  Hive.registerAdapter(OfflinePacketAdapter());
  await Hive.openBox<OfflinePacket>('offline_packets');
  await initializeBackgroundService();
  // ----------------------------------------------------

  final authRepository = AuthRepository();
  final userRepository = UserRepository();
  final guardianRepository = GuardianRepository();
  final tripRepository = TripRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController(authRepository)),
        ChangeNotifierProvider(create: (_) => E2EEController()),
        ChangeNotifierProvider(create: (_) => GuardianController(guardianRepository)),
        ChangeNotifierProvider(create: (_) => ProfileController(userRepository)),
        ChangeNotifierProvider(create: (context) => TripController(tripRepository, context.read<E2EEController>())),
        ChangeNotifierProvider(create: (_) => HistoryController(tripRepository)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = AppRouter(context.read<AuthController>()).router;

    return MaterialApp.router(
      title: 'Rahban',
      theme: ThemeData(
        // Theme data...
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa')],
    );
  }
}