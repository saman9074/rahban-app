import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:rahban/features/security/e2ee_controller.dart';
import 'package:rahban/utils/persian_words.dart';

class E2EESetupScreen extends StatefulWidget {
  const E2EESetupScreen({super.key});

  @override
  State<E2EESetupScreen> createState() => _E2EESetupScreenState();
}

class _E2EESetupScreenState extends State<E2EESetupScreen> {
  List<String> _secureWords = [];
  bool _hasConfirmed = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _generateWords();
  }

  void _generateWords() {
    final random = Random();
    final Set<String> words = {};
    while (words.length < 5) {
      words.add(persianWords[random.nextInt(persianWords.length)]);
    }
    setState(() {
      _secureWords = words.toList();
    });
  }

  Future<void> _saveKeyAndProceed() async {
    if (!_hasConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً ابتدا ذخیره کردن کلمات را تایید کنید.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Save the new key permanently, overwriting any existing one.
      final e2eeController = context.read<E2EEController>();
      await e2eeController.generateAndSaveKey(_secureWords);

      // Check if we are in the "start trip" flow or "reset key" flow.
      final extra = GoRouterState.of(context).extra;
      final location = (extra is LatLng) ? extra : null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('کلید امنیتی با موفقیت ذخیره شد!')),
        );
        if (location != null) {
          // Came from "start trip" flow, proceed to the next step.
          context.go('/start-trip', extra: location);
        } else {
          // Came from "reset key" flow, go back to the previous screen (home).
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ذخیره‌سازی کلید: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayWords = _secureWords.join(' - ');
    // Check if a key is already set to adjust the title and text.
    final bool isResetting = context.read<E2EEController>().isKeySet;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(isResetting ? 'بازنشانی کلید امنیتی' : 'تنظیم کلید امنیتی')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.shield_moon_outlined, color: Colors.teal, size: 80),
              const SizedBox(height: 24),
              Text(
                'کلمات بازیابی جدید شما',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                color: Colors.teal.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        displayWords,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      IconButton(
                        icon: const Icon(Icons.copy_all_outlined),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: displayWords));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('کلمات در کلیپ‌بورد کپی شد.')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isResetting
                    ? 'این ۵ کلمه جایگزین کلید قبلی شما می‌شود. آن را در جایی امن یادداشت کنید. کلید قبلی دیگر معتبر نخواهد بود.'
                    : 'این ۵ کلمه، کلید دائمی شماست. آن را در جایی امن یادداشت کنید. فقط با این کلمات می‌توان موقعیت شما را مشاهده کرد.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.6, color: Colors.red[700]),
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                title: const Text('کلمات را در جایی امن ذخیره کردم.'),
                value: _hasConfirmed,
                onChanged: (bool? value) {
                  setState(() {
                    _hasConfirmed = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.teal,
              ),
              const Spacer(),
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('ذخیره و ادامه'),
                onPressed: _hasConfirmed ? _saveKeyAndProceed : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
