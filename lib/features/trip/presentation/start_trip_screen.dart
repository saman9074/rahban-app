import 'dart:io';
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
    if (_selectedGuardians.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفا حداقل یک نگهبان انتخاب کنید.')));
      return;
    }
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطا: موقعیت مکانی یافت نشد.')));
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final response = await context.read<TripRepository>().startTrip(
          guardians: _selectedGuardians,
          location: location,
          vehicleInfo: {
            'plate': _plateController.text,
            'type': _typeController.text,
            'color': _colorController.text,
          },
          platePhoto: _platePhoto,
        );
        final tripId = response.data['trip']['id'].toString();
        if(mounted) {
          await context.read<TripController>().startNewTrip(tripId);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سفر با موفقیت آغاز شد!')));
          context.go('/home');
        }
      } catch (e) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در شروع سفر: $e')));
        }
      } finally {
        if(mounted) {
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
        appBar: AppBar(title: const Text('شروع سفر جدید')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('اطلاعات خودرو (اختیاری)', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              if (_platePhoto != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kIsWeb
                      ? Image.network(_platePhoto!.path, height: 150, fit: BoxFit.cover)
                      : Image.file(File(_platePhoto!.path), height: 150, fit: BoxFit.cover),
                ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(_platePhoto == null ? 'گرفتن عکس از پلاک' : 'گرفتن عکس جدید'),
                onPressed: _takePlatePhoto,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black54,
                    side: BorderSide(color: Colors.grey.shade400)
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
              _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton.icon(
                onPressed: _startTrip,
                icon: const Icon(Icons.play_arrow),
                label: const Text('تایید و شروع سفر'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
              )
            ],
          ),
        ),
      ),
    );
  }
}
