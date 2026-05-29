import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../auth/data/auth_repository.dart';
import '../../biomarkers/providers/biomarkers_provider.dart';
import '../data/account_service.dart';
import '../data/doctor_report_service.dart';
import '../data/profile_model.dart';
import '../providers/profile_provider.dart';

final _profileAuthRepoProvider = Provider(
  (ref) => AuthRepository(Supabase.instance.client),
);

String _sexLabel(String? sex) => switch (sex) {
      'male' => 'Male',
      'female' => 'Female',
      'other' => 'Other',
      _ => '—',
    };

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final profileAsync = ref.watch(profileProvider);
    final fullName = profileAsync.valueOrNull?.fullName ??
        (user?.userMetadata?['full_name'] as String? ?? 'User');
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit profile',
            onPressed: () => context.push(AppRoutes.editProfile),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAvatar(context, fullName, profileAsync.valueOrNull?.avatarUrl),
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
          _HealthDetailsCard(profileAsync: profileAsync),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.medical_information_outlined,
                      color: AppColors.textSecondary),
                  title: const Text('Medical record'),
                  subtitle:
                      const Text('Vaccinations, allergies, conditions'),
                  trailing: Icon(Icons.chevron_right,
                      color: AppColors.textTertiary),
                  onTap: () => context.push(AppRoutes.medicalRecord),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.settings_outlined,
                      color: AppColors.textSecondary),
                  title: const Text('Settings'),
                  subtitle:
                      const Text('Theme, units, biometric lock, language'),
                  trailing: Icon(Icons.chevron_right,
                      color: AppColors.textTertiary),
                  onTap: () => context.push(AppRoutes.settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.medical_services_outlined,
                      color: AppColors.textSecondary),
                  title: const Text('Share with doctor'),
                  subtitle: const Text('PDF summary of your results'),
                  trailing: Icon(Icons.chevron_right,
                      color: AppColors.textTertiary),
                  onTap: () => _shareWithDoctor(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.download_outlined,
                      color: AppColors.textSecondary),
                  title: const Text('Export my data'),
                  subtitle: const Text('Download all results as CSV'),
                  trailing: Icon(Icons.chevron_right,
                      color: AppColors.textTertiary),
                  onTap: () => _exportData(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.info_outline,
                      color: AppColors.textSecondary),
                  title: const Text('About Lablio'),
                  trailing: Icon(Icons.chevron_right,
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
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _confirmDeleteAccount(context, ref),
            icon: const Icon(Icons.delete_forever_outlined,
                color: AppColors.high, size: 20),
            label: const Text('Delete account',
                style: TextStyle(color: AppColors.high)),
          ),
        ],
      ),
    );
  }

  Future<void> _shareWithDoctor(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final entries = ref.read(biomarkerEntriesProvider).valueOrNull ?? [];
    if (entries.isEmpty) {
      messenger.showSnackBar(const SnackBar(
        content: Text('No results to summarize yet.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final profile = ref.read(profileProvider).valueOrNull;
    try {
      await DoctorReportService().share(profile: profile, entries: entries);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Could not generate PDF: $e'),
        backgroundColor: AppColors.high,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final entries = ref.read(biomarkerEntriesProvider).valueOrNull ?? [];
    if (entries.isEmpty) {
      messenger.showSnackBar(const SnackBar(
        content: Text('No results to export yet.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    try {
      await AccountService(Supabase.instance.client).exportEntries(entries);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Export failed: $e'),
        backgroundColor: AppColors.high,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        var canDelete = false;
        var deleting = false;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('Delete account'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This permanently deletes your account, all reports, '
                  'biomarker results, and uploaded files. This cannot be undone.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Type DELETE to confirm',
                  ),
                  onChanged: (v) =>
                      setLocal(() => canDelete = v.trim().toUpperCase() == 'DELETE'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: deleting ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: (!canDelete || deleting)
                    ? null
                    : () async {
                        setLocal(() => deleting = true);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await AccountService(Supabase.instance.client)
                              .deleteAccount();
                          await ref
                              .read(_profileAuthRepoProvider)
                              .signOut();
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        } catch (e) {
                          setLocal(() => deleting = false);
                          messenger.showSnackBar(SnackBar(
                            content: Text('Could not delete account: $e'),
                            backgroundColor: AppColors.high,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      },
                child: deleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Delete forever',
                        style: TextStyle(color: AppColors.high)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(
      BuildContext context, String fullName, String? avatarUrl) {
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
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700))
                : null,
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out of Lablio?'),
        content: const Text('You can sign back in anytime.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              // Pop the dialog using its OWN context so we close the dialog
              // route on the root navigator — not the shell's nested navigator.
              Navigator.pop(dialogContext);
              // The router's auth-aware redirect navigates to /login the moment
              // the session clears. Do NOT navigate manually here.
              try {
                await ref.read(_profileAuthRepoProvider).signOut();
              } catch (_) {
                // Local session is cleared even if the server call fails;
                // the redirect still fires.
              }
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

class _HealthDetailsCard extends StatelessWidget {
  final AsyncValue<ProfileModel?> profileAsync;
  const _HealthDetailsCard({required this.profileAsync});

  @override
  Widget build(BuildContext context) {
    return profileAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (profile) {
        final dob = profile?.dateOfBirth;
        final age = profile?.age;
        final bmi = profile?.bmi;

        return Card(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  children: [
                    Text('Health Details',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              _InfoTile(
                icon: Icons.cake_outlined,
                label: 'Date of birth',
                value: dob == null
                    ? '—'
                    : '${DateFormat('MMMM d, yyyy').format(dob)}'
                        '${age != null ? '  ·  $age yrs' : ''}',
              ),
              const Divider(height: 1),
              _InfoTile(
                icon: Icons.wc_outlined,
                label: 'Sex',
                value: _sexLabel(profile?.sex),
              ),
              const Divider(height: 1),
              _InfoTile(
                icon: Icons.straighten_outlined,
                label: 'Height & Weight',
                value: [
                  if (profile?.heightCm != null)
                    '${profile!.heightCm!.toStringAsFixed(0)} cm',
                  if (profile?.weightKg != null)
                    '${profile!.weightKg!.toStringAsFixed(1)} kg',
                ].isEmpty
                    ? '—'
                    : [
                        if (profile?.heightCm != null)
                          '${profile!.heightCm!.toStringAsFixed(0)} cm',
                        if (profile?.weightKg != null)
                          '${profile!.weightKg!.toStringAsFixed(1)} kg',
                      ].join('  ·  ') +
                        (bmi != null
                            ? '  ·  BMI ${bmi.toStringAsFixed(1)}'
                            : ''),
              ),
              const Divider(height: 1),
              _InfoTile(
                icon: Icons.bloodtype_outlined,
                label: 'Blood type',
                value: profile?.bloodType ?? '—',
              ),
            ],
          ),
        );
      },
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
