import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:rahban/api/trip_repository.dart';
import 'package:rahban/features/security/e2ee_controller.dart';
import 'package:rahban/features/trip/presentation/trip_controller.dart';
import 'package:rahban/models/offline_packet.dart';
import 'package:rahban/utils/encryption_service.dart';
import 'package:wifi_scan/wifi_scan.dart';

// کانال ارتباطی با کد نیتیو
const platform = MethodChannel('com.rahban/cellinfo');

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // --- SECTION 1: INITIALIZATION ---
  DartPluginRegistrant.ensureInitialized();
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(OfflinePacketAdapter().typeId)) {
    Hive.registerAdapter(OfflinePacketAdapter());
  }
  final offlineBox = await Hive.openBox<OfflinePacket>('offline_packets');

  // Instantiate all necessary services and controllers here
  final tripRepository = TripRepository();
  final e2eeController = E2EEController();
  // Load the key at the start to ensure it's available
  await e2eeController.loadKey();


  // --- SECTION 2: STATE VARIABLES ---
  Timer? periodicTimer;
  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;
  LatLng? currentPosition;
  String? tripId;
  TripStatus tripStatus = TripStatus.none;
  bool isOnline = true; // Assume online by default


  // --- SECTION 3: HELPER FUNCTIONS (DEFINED INSIDE onStart) ---

  // This function now has access to tripRepository and offlineBox from the parent scope
  Future<void> _sendQueuedData() async {
    if (offlineBox.isEmpty || !isOnline) return;
    print("BG Service: Found ${offlineBox.length} packets in queue. Sending...");

    final Map<dynamic, OfflinePacket> packets = Map.from(offlineBox.toMap());
    for (var entry in packets.entries) {
      final key = entry.key;
      final packet = entry.value;
      try {
        if (packet.tripStatus == TripStatus.active) {
          await tripRepository.updateLocation(tripId: packet.tripId, encryptedData: packet.encryptedData);
        } else {
          await tripRepository.sendSosData(tripId: packet.tripId, encryptedData: packet.encryptedData);
        }
        await offlineBox.delete(key);
        print("BG Service: Successfully sent and deleted queued packet with key $key");
      } catch (e) {
        print("BG Service: Failed to send queued packet. Will retry later. Error: $e");
        break;
      }
    }
  }

  Future<Map<String, dynamic>> _gatherData(TripStatus status, LatLng position) async {
    if (status == TripStatus.active) {
      return {'lat': position.latitude, 'lon': position.longitude};
    } else {
      // WiFi Data Gathering
      List<Map<String, dynamic>> wifiList = [];
      try {
        if (await WiFiScan.instance.canStartScan(askPermissions: false) == CanStartScan.yes) {
          await WiFiScan.instance.startScan();
          final wifis = await WiFiScan.instance.getScannedResults();
          wifiList = wifis.map((net) => {'bssid': net.bssid, 'rssi': net.level}).toList();
        }
      } catch (e) {
        print("BG Service: Could not get WiFi info: $e");
      }

      // Cell Tower Data Gathering
      Map<String, dynamic>? cellData;
      try {
        final Map<dynamic, dynamic>? result = await platform.invokeMethod('getCellInfo');
        cellData = result?.cast<String, dynamic>();
      } on PlatformException catch (e) {
        print("BG Service: Failed to get cell info via native channel: '${e.message}'.");
      }

      return {
        'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'gps': {'lat': position.latitude, 'lon': position.longitude, 'acc': 10},
        'cell': cellData,
        'wifi': wifiList,
      };
    }
  }

  // --- SECTION 4: SERVICE LIFECYCLE & LOGIC ---

  connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
    isOnline = !results.contains(ConnectivityResult.none);
    if (isOnline) {
      _sendQueuedData();
    }
  });

  service.on('updatePosition').listen((payload) {
    if (payload != null) {
      currentPosition = LatLng(payload['lat'], payload['lon']);
    }
  });

  service.on('configure').listen((payload) {
    tripId = payload!['tripId'];
    tripStatus = TripStatus.values[payload['tripStatusValue']];

    periodicTimer?.cancel();
    periodicTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (tripId == null || currentPosition == null) return;
      if (isOnline) await _sendQueuedData();

      final packetData = await _gatherData(tripStatus, currentPosition!);

      if (!e2eeController.isKeySet) {
        print("BG Service Error: E2EE Key not set. Cannot encrypt.");
        return;
      }
      final keyBytes = await e2eeController.getKeyBytes();
      final encryptedData = EncryptionService.encrypt(jsonEncode(packetData), keyBytes);

      try {
        if (!isOnline) throw 'Device is offline';

        if (tripStatus == TripStatus.active) {
          await tripRepository.updateLocation(tripId: tripId!, encryptedData: encryptedData);
          print('BG Service: Sent active location');
        } else if (tripStatus == TripStatus.emergency) {
          await tripRepository.sendSosData(tripId: tripId!, encryptedData: encryptedData);
          print('BG Service: Sent emergency data');
        }
      } catch (e) {
        print('BG Service: Failed to send data, queuing... Error: $e');
        final offlinePacket = OfflinePacket(
            tripId: tripId!,
            encryptedData: encryptedData,
            tripStatusValue: tripStatus.index,
            timestamp: DateTime.now().millisecondsSinceEpoch);
        await offlineBox.add(offlinePacket);
      }
    });
  });

  service.on('updateTripStatus').listen((payload) {
    if (payload != null) {
      tripStatus = TripStatus.values[payload['tripStatusValue']];
      print("BG Service: Trip status updated to $tripStatus");
    }
  });

  service.on('stop').listen((event) {
    periodicTimer?.cancel();
    connectivitySubscription?.cancel();
    service.stopSelf();
    offlineBox.clear();
  });
}

// This function remains outside onStart
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
      notificationChannelId: 'rahban_service',
      initialNotificationTitle: 'رهبان',
      initialNotificationContent: 'سرویس رهبان در حال آماده‌سازی است.',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
    ),
  );
}