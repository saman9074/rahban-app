import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rahban/features/auth/presentation/auth_controller.dart';
import 'package:rahban/features/profile/presentation/profile_controller.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch for changes in the profile to update the drawer header
    final profileController = context.watch<ProfileController>();
    final user = profileController.user;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              user?.name ?? 'کاربر رهبان',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(user?.phoneNumber ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: Text(
                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'R',
                style: TextStyle(fontSize: 40.0, color: Theme.of(context).primaryColor),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('خروج از حساب کاربری'),
            onTap: () {
              // Close the drawer first
              Navigator.of(context).pop();
              // Then call logout
              context.read<AuthController>().logout();
            },
          ),
        ],
      ),
    );
  }

  // Helper method to create styled ListTiles for navigation
  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required String route,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      onTap: () {
        // Close the drawer
        Navigator.of(context).pop();
        // Navigate to the desired page
        context.go(route);
      },
    );
  }
}
