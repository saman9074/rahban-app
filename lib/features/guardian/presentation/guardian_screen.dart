import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rahban/features/guardian/presentation/guardian_controller.dart';

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
                decoration: const InputDecoration(
                  labelText: 'نام',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'نام الزامی است' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'شماره تلفن',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'شماره تلفن الزامی است' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لغو'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await context.read<GuardianController>().addGuardian(
                  name: nameController.text,
                  phoneNumber: phoneController.text,
                );
                if (mounted && success) Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.person_add),
            label: const Text('افزودن'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
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
        appBar: AppBar(
          title: const Text('مدیریت نگهبانان'),
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
        body: Consumer<GuardianController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.errorMessage != null) {
              return Center(
                child: Text(
                  'خطا: ${controller.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (controller.guardians.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 90, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'هنوز نگهبانی اضافه نکرده‌اید.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: controller.guardians.length,
              itemBuilder: (context, index) {
                final guardian = controller.guardians[index];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    leading: const CircleAvatar(
                      radius: 24,
                      child: Icon(Icons.person),
                    ),
                    title: Text(
                      guardian.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(guardian.phoneNumber),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'تنظیم به عنوان پیش‌فرض',
                          child: IconButton(
                            icon: Icon(
                              guardian.isDefault ? Icons.star : Icons.star_border,
                              color: guardian.isDefault ? Colors.amber : Colors.grey,
                            ),
                            onPressed: () => controller.setDefault(guardian.id),
                          ),
                        ),
                        Tooltip(
                          message: 'حذف نگهبان',
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => controller.deleteGuardian(guardian.id),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddGuardianDialog,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('نگهبان جدید'),
        ),
      ),
    );
  }
}
