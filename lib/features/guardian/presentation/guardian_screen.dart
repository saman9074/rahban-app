import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rahban/features/guardian/presentation/guardian_controller.dart';
import 'package:rahban/features/guardian/models/guardian_model.dart';

class GuardianScreen extends StatefulWidget {
  const GuardianScreen({super.key});

  @override
  State<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends State<GuardianScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GuardianController>().fetchGuardians();
    });
  }

  void _showAddGuardianDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('افزودن نگهبان جدید'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'نام'),
                validator: (v) => v!.isEmpty ? 'نام الزامی است' : null,
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'شماره تلفن'),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'شماره تلفن الزامی است' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('لغو')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await context.read<GuardianController>().addGuardian(
                  name: nameController.text,
                  phoneNumber: phoneController.text,
                );
                if (mounted && success) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('افزودن'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مدیریت نگهبانان')),
        body: Consumer<GuardianController>(
          builder: (context, controller, child) {
            if (controller.isLoading) return const Center(child: CircularProgressIndicator());
            if (controller.errorMessage != null) return Center(child: Text('خطا: ${controller.errorMessage}'));
            if (controller.guardians.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('هنوز نگهبانی اضافه نکرده‌اید.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: controller.guardians.length,
              itemBuilder: (context, index) {
                final guardian = controller.guardians[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.person, size: 40),
                    title: Text(guardian.name),
                    subtitle: Text(guardian.phoneNumber),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            guardian.isDefault ? Icons.star : Icons.star_border,
                            color: guardian.isDefault ? Colors.amber : Colors.grey,
                          ),
                          tooltip: 'تنظیم به عنوان پیش‌فرض',
                          onPressed: () => controller.setDefault(guardian.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => controller.deleteGuardian(guardian.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddGuardianDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
