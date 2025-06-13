import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:keybinder/keybinder.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:rahban/features/profile/presentation/profile_controller.dart';
import 'package:rahban/features/security/e2ee_controller.dart';
import 'package:rahban/features/trip/presentation/trip_controller.dart';
import 'package:rahban/widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();

  final _volumeUpBinding = Keybinding.from({LogicalKeyboardKey.audioVolumeUp});
  final _volumeDownBinding = Keybinding.from({LogicalKeyboardKey.audioVolumeDown});

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripController>().initializeLocationService();
      context.read<ProfileController>().fetchUser();
      if (!kIsWeb) {
        _setupSOSKeybinding();
      }
    });
  }

  void _setupSOSKeybinding() {
    Keybinder.bind(_volumeUpBinding, (bool pressed) {
      if (pressed && _volumeDownBinding.isPressed) {
        _handleSOSActivation();
      }
    });

    Keybinder.bind(_volumeDownBinding, (bool pressed) {
      if (pressed && _volumeUpBinding.isPressed) {
        _handleSOSActivation();
      }
    });
  }

  void _handleSOSActivation() {
    if (mounted && context.read<TripController>().isInTrip) {
      _triggerSOS();
    }
  }

  void _triggerSOS() {
    context.read<TripController>().triggerSOS();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('وضعیت اضطراری (SOS) فعال شد!'),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _recenterMap() {
    final currentPosition = context.read<TripController>().currentPosition;
    if (currentPosition != null) {
      _mapController.move(currentPosition, 16.0);
    }
  }

  void _handleStartTrip(LatLng? currentPosition) {
    if (currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('موقعیت مکانی شما هنوز مشخص نشده است.'),
          backgroundColor: Colors.grey.shade900,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final e2eeController = context.read<E2EEController>();

    if (e2eeController.isKeySet) {
      context.push('/start-trip', extra: currentPosition);
    } else {
      context.push('/e2ee-setup', extra: currentPosition);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      Keybinder.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          title: const Text('رهبان'),
          backgroundColor: theme.colorScheme.primary,
          elevation: 4,
          centerTitle: true,
        ),
        drawer: const AppDrawer(),
        body: Consumer2<TripController, E2EEController>(
          builder: (context, tripController, e2eeController, child) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final pos = tripController.currentPosition;
              if (pos != null) {
                _mapController.move(pos, 16.0);
              }
            });

            return Stack(
              children: [
                _buildMap(tripController, theme),
                if (tripController.isInTrip)
                  _buildInTripOverlay(tripController, theme),
                if (!tripController.isInTrip)
                  _buildStartTripButton(context, tripController.currentPosition, theme),
                if (tripController.isLocationLoading || e2eeController.isLoading)
                  _buildLoadingIndicator(theme),
                if (tripController.locationError.isNotEmpty)
                  _buildErrorDisplay(tripController.locationError),
                _buildRecenterButton(theme),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMap(TripController tripController, ThemeData theme) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: tripController.currentPosition ?? const LatLng(35.6892, 51.3890),
        initialZoom: 16.0,
      ),
      children: [
        TileLayer(
          urlTemplate: kIsWeb ? 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png' : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'ir.arcaneteam.rahban',
        ),
        if (tripController.currentPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: tripController.currentPosition!,
                width: 48,
                height: 48,
                child: Icon(Icons.my_location, color: theme.colorScheme.primary, size: 32),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRecenterButton(ThemeData theme) {
    return Positioned(
      bottom: 120,
      left: 24,
      child: FloatingActionButton(
        onPressed: _recenterMap,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        tooltip: 'بازگرداندن موقعیت',
        child: const Icon(Icons.gps_fixed),
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Center(
      child: Card(
        color: theme.colorScheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'در حال بارگذاری...',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorDisplay(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade900.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          error,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildInTripOverlay(TripController tripController, ThemeData theme) {
    return Positioned(
      bottom: 40,
      left: 24,
      right: 24,
      child: Card(
        color: theme.colorScheme.surface,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.sos),
                label: const Text('SOS'),
                onPressed: _triggerSOS,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              ElevatedButton(
                onPressed: () => tripController.completeActiveTrip(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'پایان سفر',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartTripButton(BuildContext context, LatLng? currentPosition, ThemeData theme) {
    return Positioned(
      bottom: 40,
      left: 24,
      right: 24,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.navigation_outlined),
        label: const Text('شروع سفر جدید'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 6,
        ),
        onPressed: () => _handleStartTrip(currentPosition),
      ),
    );
  }
}
