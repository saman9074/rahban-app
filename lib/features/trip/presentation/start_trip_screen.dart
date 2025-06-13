import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rahban/api/trip_repository.dart';
import 'package:latlong2/latlong.dart';
import 'package:rahban/features/guardian/models/guardian_model.dart';
import 'package:rahban/features/guardian/presentation/guardian_controller.dart';
import 'package:rahban/features/security/e2ee_controller.dart';
import 'package:rahban/features/trip/presentation/trip_controller.dart';
import 'package:rahban/utils/encryption_service.dart';

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
    final location = GoRouterState.of(context).extra as LatLng?;
    final e2eeController = context.read<E2EEController>();

    if (_selectedGuardians.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفا حداقل یک نگهبان انتخاب کنید.')));
      return;
    }
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطا: موقعیت مکانی یافت نشد.')));
      return;
    }
    if (!e2eeController.isKeySet) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطا: کلید امنیتی تنظیم نشده است.')));
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final keyBytes = await e2eeController.getKeyBytes();
        final locationJson = jsonEncode({'lat': location.latitude, 'lon': location.longitude});
        final encryptedLocation = EncryptionService.encrypt(locationJson, keyBytes);

        final response = await context.read<TripRepository>().startTrip(
          guardians: _selectedGuardians,
          encryptedInitialLocation: encryptedLocation,
          vehicleInfo: {
            'plate': _plateController.text,
            'type': _typeController.text,
            'color': _colorController.text,
          },
          platePhoto: _platePhoto,
        );

        final tripId = response.data['trip']['id'].toString();
        if (mounted) {
          await context.read<TripController>().startNewTrip(tripId);
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
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('شروع سفر جدید'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('اطلاعات خودرو (اختیاری)', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),

              if (_platePhoto != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(_platePhoto!.path, height: 160, fit: BoxFit.cover)
                        : Image.file(File(_platePhoto!.path), height: 160, fit: BoxFit.cover),
                  ),
                ),

              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(_platePhoto == null ? 'گرفتن عکس از پلاک' : 'گرفتن عکس جدید'),
                onPressed: _takePlatePhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[50],
                  foregroundColor: Colors.blue[900],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.w500),
                  side: BorderSide(color: Colors.blue.shade200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(labelText: 'شماره پلاک'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'نوع خودرو'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'رنگ'),
              ),

              const Divider(height: 40),
              Text('انتخاب نگهبانان', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),

              Consumer<GuardianController>(
                builder: (context, controller, child) {
                  if (controller.isLoading) return const Center(child: CircularProgressIndicator());
                  if (controller.guardians.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'لطفا ابتدا از بخش "مدیریت نگهبانان" یک نگهبان اضافه کنید.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: controller.guardians.map((guardian) {
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: CheckboxListTile(
                          title: Text(guardian.name),
                          subtitle: Text(guardian.phoneNumber),
                          value: _selectedGuardians.contains(guardian),
                          onChanged: (bool? selected) => _onGuardianSelected(selected, guardian),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startTrip,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('تایید و شروع سفر'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
