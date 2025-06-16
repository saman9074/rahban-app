import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('درباره رهبان'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(
                  Icons.shield_outlined,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'رهبان: همراه امن شما در سفر',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'هدف اصلی رهبان، ایجاد یک ابزار قابل اتکا برای افزایش امنیت شما در سفرهای روزمره و شرایط اضطراری است. ما معتقدیم که هر فردی حق دارد با آرامش خاطر سفر کند و در صورت بروز خطر، ابزاری قدرتمند برای کمک و ثبت شواهد در اختیار داشته باشد.',
                style: textTheme.bodyLarge?.copyWith(height: 1.8),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 20),
              _buildFeatureCard(
                context,
                icon: Icons.emergency_share,
                title: 'حالت اضطراری (SOS)',
                description: 'با فشردن دکمه SOS، برنامه به حالت اضطراری وارد شده و شروع به جمع‌آوری حداکثری داده‌های محیطی (موقعیت، صدای اطراف، اطلاعات شبکه) به عنوان مدرک دیجیتال می‌کند.',
              ),
              _buildFeatureCard(
                context,
                icon: Icons.storage_outlined,
                title: 'ذخیره‌سازی آفلاین',
                description: 'حتی در صورت قطع اینترنت، رهبان به کار خود ادامه می‌دهد و تمام اطلاعات را به صورت محلی ذخیره کرده و پس از اتصال مجدد، آن‌ها را به سرور ارسال می‌کند.',
              ),
              _buildFeatureCard(
                context,
                icon: Icons.lock_outline,
                title: 'رمزنگاری سرتاسری (E2EE)',
                description: 'حریم خصوصی شما اولویت اول ماست. تمام داده‌های شما قبل از ارسال، با کلید شخصی و منحصربه‌فردتان رمزنگاری می‌شوند و هیچ‌کس جز شما و نگهبانان مورد اعتمادتان به محتوای آن دسترسی ندارد.',
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'با رهبان، با اطمینان سفر کنید.',
                  style: textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, {required IconData icon, required String title, required String description}) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.secondary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(description, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}