import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rahban/features/auth/presentation/auth_controller.dart';
import 'package:rahban/features/profile/presentation/profile_controller.dart';
import 'package:rahban/features/auth/presentation/auth_controller.dart';
import 'package:rahban/features/profile/presentation/profile_controller.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = context.watch<ProfileController>();
    final user = profileController.user;

    return Drawer(
      child: Container(
        color: const Color(0xFFF9FAFB), // پس‌زمینه روشن هماهنگ با تم
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(
                user?.name ?? 'کاربر رهبان',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              accountEmail: Text(
                user?.phoneNumber ?? '',
                style: const TextStyle(color: Colors.white70),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'R',
                  style: const TextStyle(
                    fontSize: 32.0,
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF164B75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            const SizedBox(height: 4),
            _buildDrawerItem(
              context: context,
              icon: Icons.shield_outlined,
              text: 'مدیریت نگهبانان',
              route: '/guardians',
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.history,
              text: 'تاریخچه سفرها',
              route: '/history',
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.vpn_key_outlined,
              text: 'بازنشانی کلید امنیتی',
              route: '/e2ee-setup',
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.person_outline,
              text: 'پروفایل',
              route: '/profile',
            ),
            const Divider(), // Divider to separate main items from others
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('درباره ما'),
              onTap: () {
                context.pop();
                context.push('/about');
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_support_outlined),
              title: const Text('ارتباط با ما'),
              onTap: () {
                context.pop();
                context.push('/contact');
              },
            ),
            const Divider(height: 32, thickness: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'خروج از حساب کاربری',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                context.read<AuthController>().logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required String route,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF1E3A8A),
      ),
      title: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: Color(0xFF111827),
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        context.go(route);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      hoverColor: Colors.blue.withOpacity(0.05),
    );
  }
}
