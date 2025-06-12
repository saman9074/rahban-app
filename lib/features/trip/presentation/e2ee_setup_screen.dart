import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:rahban/utils/encryption_service.dart';
import 'package:rahban/utils/persian_words.dart';

class E2EESetupScreen extends StatefulWidget {
  const E2EESetupScreen({super.key});

  @override
  State<E2EESetupScreen> createState() => _E2EESetupScreenState();
}

class _E2EESetupScreenState extends State<E2EESetupScreen> {
  List<String> _secureWords = [];
  bool _hasConfirmed = false;

  @override
  void initState() {
    super.initState();
    _generateWords();
  }

  void _generateWords() {
    final random = Random();
    // Ensure no duplicate words are selected
    final Set<String> words = {};
    while (words.length < 5) {
      words.add(persianWords[random.nextInt(persianWords.length)]);
    }
    setState(() {
      _secureWords = words.toList();
    });
  }

  void _continueToNextStep() {
    if (!_hasConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً ابتدا ذخیره کردن کلمات را تایید کنید.')),
      );
      return;
    }

    final location = GoRouterState.of(context).extra as LatLng?;
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطا: موقعیت مکانی یافت نشد.')));
      context.go('/home'); // Go back home if location is missing
      return;
    }

    // Generate the key from the words
    final String combinedWords = _secureWords.join('');
    final Uint8List keyBytes = EncryptionService.generateKeyFromWords(combinedWords);
    // Encode the key in Base64 to safely pass it as a string
    final String base64Key = base64.encode(keyBytes);

    // Navigate to start trip screen with all necessary data
    context.go(
      '/start-trip',
      extra: {
        'location': location,
        'e2eeKey': base64Key,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String displayWords = _secureWords.join(' - ');
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ایجاد کلید امنیتی سفر')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.shield_outlined, color: Colors.amber, size: 80),
              const SizedBox(height: 24),
              Text(
                'کلمات امنیتی سفر شما',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                color: Colors.amber.shade50,
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
              const Text(
                'این ۵ کلمه، کلید خصوصی شما برای این سفر است. آن را به صورت امن (مثلاً تلفنی) به نگهبانان خود اطلاع دهید. رهبان به این کلمات دسترسی ندارد و فقط با آن می‌توان موقعیت شما را مشاهده کرد.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.6),
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
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('ادامه و انتخاب نگهبان'),
                onPressed: _hasConfirmed ? _continueToNextStep : null,
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
