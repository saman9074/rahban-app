import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rahban/features/auth/presentation/auth_controller.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:rahban/features/trip/presentation/trip_controller.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  LatLng? _lastKnownPosition;
  VolumeController? _volumeController;
  final List<DateTime> _volumePressTimestamps = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripController>().initializeLocationService();
    });
    if (!kIsWeb) {
      _volumeController = VolumeController();
      _volumeController!.listener((volume) {
        _handleVolumePress();
      });
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _volumeController?.removeListener();
    }
    super.dispose();
  }

  void _handleVolumePress() {
    // منطق دکمه صدا بدون تغییر
    // مثلا شمارش فشارهای سریع پشت سر هم یا هر کاری که مد نظرته
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('رهبان'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) => context.go(value),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(value: '/profile', child: Text('پروفایل کاربری')),
                const PopupMenuItem<String>(value: '/history', child: Text('تاریخچه سفرها')),
                const PopupMenuItem<String>(value: '/guardians', child: Text('مدیریت نگهبانان')),
              ],
            ),
            IconButton(icon: const Icon(Icons.logout), tooltip: 'خروج از حساب',
              onPressed: () async {
                await context.read<TripController>().completeActiveTrip();
                if (mounted) context.read<AuthController>().logout();
              },
            ),
          ],
        ),
        body: Consumer<TripController>(
          builder: (context, tripController, child) {
            // وقتی موقعیت تغییر کرد، موقعیت نقشه رو بروزرسانی کن
            if (tripController.currentPosition != null && _lastKnownPosition != tripController.currentPosition) {
              _lastKnownPosition = tripController.currentPosition;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _mapController.move(_lastKnownPosition!, 15.0);
              });
            }

            return Stack(
              children: [
                _buildMap(tripController),
                Positioned(
                  top: 16, right: 16,
                  child: FloatingActionButton(
                    heroTag: 'myLocationFab', mini: true,
                    onPressed: () {
                      if (tripController.currentPosition != null) {
                        _mapController.move(tripController.currentPosition!, 15.0);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('موقعیت شما فعلاً مشخص نیست.')),
                        );
                      }
                    },
                    backgroundColor: Colors.white,
                    child: Icon(Icons.my_location, color: Colors.teal[700]),
                  ),
                ),

                // اگر در حالت سفر هستیم، کنترل‌های مربوطه
                if (tripController.isInTrip) _buildInTripControls(context)
                else _buildStartTripButton(context, tripController.currentPosition),

                // نمایش هشدار و درخواست روشن کردن GPS اگر خاموش باشد
                if (!tripController.locationServiceEnabled)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: Card(
                          margin: const EdgeInsets.all(32),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_off, size: 60, color: Colors.red),
                                const SizedBox(height: 16),
                                const Text(
                                  'GPS شما خاموش است!',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'برای استفاده از نقشه، لطفا موقعیت مکانی خود را روشن کنید.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () => Geolocator.openLocationSettings(),
                                  child: const Text('روشن کردن GPS'),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMap(TripController tripController) {
    if (tripController.isLocationLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (tripController.locationError.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'خطا: ${tripController.locationError}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red[700], fontSize: 16),
          ),
        ),
      );
    }

    return FlutterMap(
      key: ValueKey(tripController.currentPosition.toString()),
      mapController: _mapController,
      options: MapOptions(
        initialCenter: tripController.currentPosition ?? const LatLng(35.6892, 51.3890),
        initialZoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'ir.rahban.app',
        ),
        if (tripController.currentPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                width: 80.0,
                height: 80.0,
                point: tripController.currentPosition!,
                child: Icon(Icons.person_pin_circle, color: Colors.teal[700], size: 60.0),
              ),
            ],
          ),

      ],
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
          textStyle: const TextStyle(fontSize: 18),
        ),
        onPressed: currentPosition == null
            ? null
            : () => context.go('/start-trip', extra: currentPosition),
      ),
    );
  }

  Widget _buildInTripControls(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 24,
      right: 24,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('اتمام سفر'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(vertical: 20),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () async {
                await context.read<TripController>().completeActiveTrip();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('سفر با موفقیت به اتمام رسید.')),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.sos_outlined),
              label: const Text('SOS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                padding: const EdgeInsets.symmetric(vertical: 20),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () {
                context.read<TripController>().triggerSOS();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('پیام اضطراری برای نگهبانان ارسال شد!')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
