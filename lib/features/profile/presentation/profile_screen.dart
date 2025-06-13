import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rahban/features/profile/presentation/profile_controller.dart';
import 'package:rahban/features/profile/models/user_model.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileController>().fetchUser();
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isPasswordLoading = true);
      final message = await context.read<ProfileController>().changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        newPasswordConfirmation: _confirmPasswordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        _formKey.currentState?.reset();
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
      setState(() => _isPasswordLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('پروفایل کاربری'),
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
        body: Consumer<ProfileController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.errorMessage != null) {
              return Center(child: Text('❌ خطا: ${controller.errorMessage}'));
            }
            if (controller.user == null) {
              return const Center(child: Text('اطلاعات کاربری یافت نشد.'));
            }

            final user = controller.user!;
            return ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_outline, color: Colors.teal),
                          title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('نام'),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.email_outlined, color: Colors.teal),
                          title: Text(user.email),
                          subtitle: const Text('ایمیل'),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.phone_outlined, color: Colors.teal),
                          title: Text(user.phoneNumber),
                          subtitle: const Text('شماره تلفن'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text('تغییر رمز عبور',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _currentPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'رمز عبور فعلی',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                            validator: (v) => v!.isEmpty ? 'این فیلد الزامی است' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _newPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'رمز عبور جدید',
                              prefixIcon: Icon(Icons.lock),
                            ),
                            obscureText: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'این فیلد الزامی است';
                              if (v.length < 8) return 'رمز عبور باید حداقل ۸ کاراکتر باشد';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'تکرار رمز عبور جدید',
                              prefixIcon: Icon(Icons.lock_reset),
                            ),
                            obscureText: true,
                            validator: (v) {
                              if (v != _newPasswordController.text) return 'رمزهای عبور یکسان نیستند';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          _isPasswordLoading
                              ? const Center(child: CircularProgressIndicator())
                              : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text('ثبت تغییرات'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _changePassword,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
