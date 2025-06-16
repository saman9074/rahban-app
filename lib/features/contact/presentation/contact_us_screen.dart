import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  Future<void> _sendEmail() async {
    if (_formKey.currentState!.validate()) {
      final subject = Uri.encodeComponent(_subjectController.text);
      final body = Uri.encodeComponent(_messageController.text);
      final emailUri = Uri.parse('mailto:abdi9074@gmail.com?subject=$subject&body=$body');

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطا: هیچ اپلیکیشن ایمیلی یافت نشد.')),
          );
        }
      }
    }
  }

  Future<void> _launchTwitter() async {
    final twitterUri = Uri.parse('https://twitter.com/saman9074');
    if (await canLaunchUrl(twitterUri)) {
      await launchUrl(twitterUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ارتباط با ما'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'ارسال پیام به تیم توسعه',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _subjectController,
                          decoration: const InputDecoration(
                            labelText: 'موضوع',
                            prefixIcon: Icon(Icons.subject),
                          ),
                          validator: (value) =>
                          value!.isEmpty ? 'لطفا موضوع را وارد کنید' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            labelText: 'متن پیام',
                            prefixIcon: Icon(Icons.message_outlined),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 6,
                          validator: (value) =>
                          value!.isEmpty ? 'لطفا متن پیام را وارد کنید' : null,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _sendEmail,
                          icon: const Icon(Icons.send_outlined),
                          label: const Text('ارسال از طریق ایمیل'),
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16)
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Text('ما را در شبکه‌های اجتماعی دنبال کنید', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              InkWell(
                onTap: _launchTwitter,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link, color: Colors.blue), // Placeholder for Twitter icon
                      const SizedBox(width: 12),
                      Text(
                        '@saman9074 در توییتر',
                        style: theme.textTheme.bodyLarge?.copyWith(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ],
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