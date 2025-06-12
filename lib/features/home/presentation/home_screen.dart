import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:rahban/features/auth/presentation/auth_controller.dart';
import 'package:rahban/features/profile/presentation/profile_controller.dart';
import 'package:rahban/features/security/e2ee_controller.dart';
import 'package:rahban/features/trip/presentation/trip_controller.dart';
import 'package:volume_controller/volume_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controller to programmatically move the map
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripController>().initializeLocationService();
      context.read<ProfileController>().fetchUser();

      // Setup the volume listener only on mobile platforms
      if (!kIsWeb) {
        _setupVolumeListener();
      }
    });
  }

  /// Sets up a listener for volume button presses to trigger SOS.
  void _setupVolumeListener() {
    VolumeController().listener((volume) {
      // Check if the widget is still in the tree and a trip is active
      if (mounted && context.read<TripController>().isInTrip) {
        _triggerSOS();
      }
    });
  }

  /// A helper function to trigger SOS and show a confirmation message.
  void _triggerSOS() {
    context.read<TripController>().triggerSOS();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('وضعیت اضطراری (SOS) فعال شد!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// A helper function to recenter the map on the user's current location.
  void _recenterMap() {
    final currentPosition = context.read<TripController>().currentPosition;
    if (currentPosition != null) {
      _mapController.move(currentPosition, 16.0);
    }
  }


  /// Checks if the E2EE key is set before starting a trip.
  void _handleStartTrip(LatLng? currentPosition) {
    if (currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('موقعیت مکانی شما هنوز مشخص نشده است.')),
      );
      return;
    }

    final e2eeController = context.read<E2EEController>();

    if (e2eeController.isKeySet) {
      context.go('/start-trip', extra: currentPosition);
    } else {
      context.go('/e2ee-setup', extra: currentPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: Consumer2<TripController, E2EEController>(
          builder: (context, tripController, e2eeController, child) {
            return Stack(
              children: [
                _buildMap(tripController),
                if (tripController.isInTrip) _buildInTripOverlay(tripController),
                if (!tripController.isInTrip)
                  _buildStartTripButton(context, tripController.currentPosition),
                if (tripController.isLocationLoading || e2eeController.isLoading) _buildLoadingIndicator(),
                if (tripController.locationError.isNotEmpty) _buildErrorDisplay(tripController.locationError),
                // Add the recenter button to the stack
                _buildRecenterButton(),
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
        // NEW: Button to reset the E2EE key
        IconButton(
          icon: const Icon(Icons.vpn_key_outlined),
          tooltip: 'بازنشانی کلید امنیتی',
          onPressed: () => context.go('/e2ee-setup'), // Navigates to the setup screen without a location
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
      mapController: _mapController, // Assign the controller to the map
      options: MapOptions(
        initialCenter: tripController.currentPosition ?? const LatLng(35.6892, 51.3890),
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

  Widget _buildRecenterButton() {
    return Positioned(
      bottom: 120, // Adjust position to not overlap with other buttons
      left: 24,
      child: FloatingActionButton(
        onPressed: _recenterMap,
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        child: const Icon(Icons.gps_fixed),
      ),
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
              Text('در حال بارگذاری...'),
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
        color: Colors.white,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // SOS Button
              ElevatedButton.icon(
                icon: const Icon(Icons.sos),
                label: const Text('SOS'),
                onPressed: _triggerSOS,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
                ),
              ),
              // End Trip Button
              ElevatedButton(
                onPressed: () => tripController.completeActiveTrip(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
                ),
                child: const Text('پایان سفر'),
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
        onPressed: () => _handleStartTrip(currentPosition),
      ),
    );
  }
}
