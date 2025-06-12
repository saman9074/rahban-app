import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rahban/api/trip_repository.dart';
import 'package:latlong2/latlong.dart';
import 'package:rahban/features/guardian/models/guardian_model.dart';
import 'package:rahban/features/guardian/presentation/guardian_controller.dart';
import 'package:rahban/features/trip/presentation/trip_controller.dart';
import 'package:rahban/utils/encryption_service.dart'; // NEW IMPORT

class StartTripScreen extends StatefulWidget {
  const StartTripScreen({super.key});
  @override
  State<StartTripScreen> createState() => _StartTripScreenState();
}

class _StartTripScreenState extends State<StartTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _typeController = TextEditingController();
  final _colorController = TextEditingController();

  final List<Guardian> _selectedGuardians = [];
  XFile? _platePhoto;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Fetch guardians as soon as the screen is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GuardianController>().fetchGuardians();
    });
  }

  void _onGuardianSelected(bool? selected, Guardian guardian) {
    setState(() {
      if (selected == true) {
        _selectedGuardians.add(guardian);
      } else {
        _selectedGuardians.remove(guardian);
      }
    });
  }

  Future<void> _takePlatePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    setState(() {
      _platePhoto = image;
    });
  }

  Future<void> _startTrip() async {
    // 1. Extract location and the E2EE key passed from the previous screen.
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final location = extra?['location'] as LatLng?;
    final base64Key = extra?['e2eeKey'] as String?;

    if (_selectedGuardians.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفا حداقل یک نگهبان انتخاب کنید.')));
      return;
    }
    if (location == null || base64Key == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطا: اطلاعات امنیتی یا موقعیت مکانی یافت نشد.')));
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // --- E2EE Encryption Step ---
        // Decode the Base64 key back to bytes.
        final Uint8List keyBytes = base64.decode(base64Key);
        // Create the JSON string for the location.
        final String locationJson = jsonEncode({'lat': location.latitude, 'lon': location.longitude});
        // Encrypt the JSON string using the key.
        final String encryptedLocation = EncryptionService.encrypt(locationJson, keyBytes);
        // --- End E2EE Step ---

        final response = await context.read<TripRepository>().startTrip(
          guardians: _selectedGuardians,
          encryptedInitialLocation: encryptedLocation, // Pass the encrypted data
          vehicleInfo: {
            'plate': _plateController.text,
            'type': _typeController.text,
            'color': _colorController.text,
          },
          platePhoto: _platePhoto,
        );

        final tripId = response.data['trip']['id'].toString();
        if (mounted) {
          // Pass the tripId and the key to the controller to be stored securely
          // for the duration of the trip.
          await context.read<TripController>().startNewTrip(tripId, base64Key);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سفر با موفقیت آغاز شد!')));
          context.go('/home');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در شروع سفر: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('شروع سفر جدید'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('اطلاعات خودرو (اختیاری)', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              if (_platePhoto != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(_platePhoto!.path, height: 150, fit: BoxFit.cover)
                        : Image.file(File(_platePhoto!.path), height: 150, fit: BoxFit.cover),
                  ),
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(_platePhoto == null ? 'گرفتن عکس از پلاک' : 'گرفتن عکس جدید'),
                onPressed: _takePlatePhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black54,
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _plateController, decoration: const InputDecoration(labelText: 'شماره پلاک (در صورت ناخوانا بودن عکس)')),
              const SizedBox(height: 12),
              TextFormField(controller: _typeController, decoration: const InputDecoration(labelText: 'نوع خودرو')),
              const SizedBox(height: 12),
              TextFormField(controller: _colorController, decoration: const InputDecoration(labelText: 'رنگ')),
              const Divider(height: 40),
              Text('انتخاب نگهبانان', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Consumer<GuardianController>(
                builder: (context, controller, child) {
                  if (controller.isLoading) return const Center(child: CircularProgressIndicator());
                  if (controller.guardians.isEmpty) {
                    return Center(child: Text('لطفا ابتدا از بخش "مدیریت نگهبانان" یک نگهبان اضافه کنید.', textAlign: TextAlign.center));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.guardians.length,
                    itemBuilder: (context, index) {
                      final guardian = controller.guardians[index];
                      return CheckboxListTile(
                        title: Text(guardian.name),
                        subtitle: Text(guardian.phoneNumber),
                        value: _selectedGuardians.contains(guardian),
                        onChanged: (bool? selected) => _onGuardianSelected(selected, guardian),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                onPressed: _startTrip,
                icon: const Icon(Icons.play_arrow),
                label: const Text('تایید و شروع سفر'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], padding: const EdgeInsets.symmetric(vertical: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
