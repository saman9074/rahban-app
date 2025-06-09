import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rahban/api/auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(); // کنترلر ایمیل
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await context.read<AuthRepository>().register(
          name: _nameController.text,
          email: _emailController.text, // ارسال ایمیل
          phoneNumber: _phoneController.text,
          password: _passwordController.text,
          passwordConfirmation: _passwordConfirmationController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ثبت‌نام با موفقیت انجام شد. اکنون وارد شوید.')),
          );
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطا در ثبت‌نام: $e')),
          );
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
          title: const Text('ثبت‌نام'),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ایجاد حساب کاربری',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'نام و نام خانوادگی'),
                    validator: (value) => value!.isEmpty ? 'لطفا نام خود را وارد کنید' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController, // فیلد ایمیل
                    decoration: const InputDecoration(labelText: 'ایمیل'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'لطفا ایمیل را وارد کنید';
                      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) return 'فرمت ایمیل نامعتبر است';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'شماره تلفن'),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value!.isEmpty ? 'لطفا شماره تلفن را وارد کنید' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'رمز عبور'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'لطفا رمز عبور را وارد کنید';
                      if (value.length < 8) return 'رمز عبور باید حداقل ۸ کاراکتر باشد';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordConfirmationController,
                    decoration: const InputDecoration(labelText: 'تکرار رمز عبور'),
                    obscureText: true,
                    validator: (value) {
                      if (value != _passwordController.text) return 'رمزهای عبور یکسان نیستند';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _register,
                    child: const Text('ثبت‌نام'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('قبلا ثبت‌نام کرده‌اید؟ وارد شوید'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}