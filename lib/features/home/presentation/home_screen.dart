import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:rahban/features/auth/presentation/auth_controller.dart';
import 'package:rahban/features/profile/presentation/profile_controller.dart';
import 'package:rahban/features/trip/presentation/trip_controller.dart';
import 'package:volume_controller/volume_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize services when the screen is first built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripController>().initializeLocationService();
      // CORRECTED: The method to fetch the user profile is `loadUserProfile`.
      context.read<ProfileController>().fetchUser();
      _setupVolumeListener();
    });
  }

  void _setupVolumeListener() {
    VolumeController().listener((volume) {
      if (mounted && context.read<TripController>().isInTrip) {
        context.read<TripController>().triggerSOS();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('وضعیت اضطراری (SOS) فعال شد!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: Consumer<TripController>(
          builder: (context, tripController, child) {
            return Stack(
              children: [
                _buildMap(tripController),
                if (tripController.isInTrip) _buildInTripOverlay(tripController),
                if (!tripController.isInTrip)
                  _buildStartTripButton(context, tripController.currentPosition),
                if (tripController.isLocationLoading) _buildLoadingIndicator(),
                if (tripController.locationError.isNotEmpty) _buildErrorDisplay(tripController.locationError),
              ],
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final profileController = context.watch<ProfileController>();
    final user = profileController.user;

    return AppBar(
      title: Text('رهبان - ${user?.name ?? "کاربر"} خوش آمدید'),
      actions: [
        IconButton(
          icon: const Icon(Icons.shield_outlined),
          tooltip: 'مدیریت نگهبانان',
          onPressed: () => context.go('/guardians'),
        ),
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: 'تاریخچه سفرها',
          onPressed: () => context.go('/history'),
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          tooltip: 'پروفایل',
          onPressed: () => context.go('/profile'),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'خروج',
          onPressed: () => context.read<AuthController>().logout(),
        ),
      ],
    );
  }

  Widget _buildMap(TripController tripController) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: tripController.currentPosition ?? const LatLng(35.6892, 51.3890), // Default to Tehran
        initialZoom: 16.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'ir.arcaneteam.rahban',
        ),
        if (tripController.currentPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: tripController.currentPosition!,
                width: 80,
                height: 80,
                child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('در حال دریافت موقعیت...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorDisplay(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(24),
        color: Colors.black.withOpacity(0.7),
        child: Text(
          error,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildInTripOverlay(TripController tripController) {
    return Positioned(
      bottom: 40,
      left: 24,
      right: 24,
      child: Card(
        color: Colors.red[800],
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'سفر در جریان است',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: () => tripController.completeActiveTrip(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                child: Text(
                  'پایان سفر',
                  style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartTripButton(BuildContext context, LatLng? currentPosition) {
    return Positioned(
      bottom: 40,
      left: 24,
      right: 24,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.navigation_outlined),
        label: const Text('شروع سفر جدید'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onPressed: currentPosition == null
            ? null
            : () => context.go('/e2ee-setup', extra: currentPosition),
      ),
    );
  }
}
