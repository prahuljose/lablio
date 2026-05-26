import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../auth/data/auth_repository.dart';

final _profileAuthRepoProvider = Provider(
  (ref) => AuthRepository(Supabase.instance.client),
);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final fullName =
        user?.userMetadata?['full_name'] as String? ?? 'User';
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAvatar(context, fullName),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                _InfoTile(
                    icon: Icons.person_outlined, label: 'Name', value: fullName),
                const Divider(height: 1),
                _InfoTile(
                    icon: Icons.email_outlined, label: 'Email', value: email),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline,
                      color: AppColors.textSecondary),
                  title: const Text('About Lablio'),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textTertiary),
                  onTap: () => _showAbout(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context, ref),
            icon: const Icon(Icons.logout, color: AppColors.high),
            label: const Text('Sign Out',
                style: TextStyle(color: AppColors.high)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.high),
              foregroundColor: AppColors.high,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, String fullName) {
    final initials = fullName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary,
            child: Text(initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          Text(fullName, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(_profileAuthRepoProvider).signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
            child: const Text('Sign Out',
                style: TextStyle(color: AppColors.high)),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Lablio',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Track your lab results and monitor your health.',
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 12)),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
