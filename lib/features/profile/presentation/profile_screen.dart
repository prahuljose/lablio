import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/animated_lablio_logo.dart';
import '../../../core/widgets/lablio_refresh.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/auth_repository.dart';
import '../../biomarkers/providers/biomarkers_provider.dart';
import '../data/account_service.dart';
import '../data/medical_record_model.dart';
import '../data/profile_model.dart';
import '../providers/medical_record_provider.dart';
import '../providers/profile_provider.dart';
import 'export_selection_sheet.dart';

final _profileAuthRepoProvider = Provider(
  (ref) => AuthRepository(Supabase.instance.client),
);

String _sexLabel(AppLocalizations t, String? sex) => switch (sex) {
      'male' => t.formSexMale,
      'female' => t.formSexFemale,
      'other' => t.formSexOther,
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

    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 52,
        titleSpacing: 8,
        leading: const LablioAppBarLogo(),
        title: Text(t.profileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: t.profileEditTooltip,
            onPressed: () => context.push(AppRoutes.editProfile),
          ),
        ],
      ),
      body: LablioRefresh(
        onRefresh: () async {
          ref.invalidate(medicalRecordProvider);
          try {
            // refresh() keeps cached data on failure (offline) and rethrows.
            await ref.read(profileProvider.notifier).refresh();
          } catch (e) {
            if (context.mounted) showOfflineAwareSnackBar(context, e);
          }
        },
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildAvatar(context, fullName,
              profileAsync.valueOrNull?.avatarUrl, profileAsync.valueOrNull),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                _InfoTile(
                    icon: Icons.person_outlined,
                    label: t.formName,
                    value: fullName),
                const Divider(height: 1),
                _InfoTile(
                    icon: Icons.email_outlined,
                    label: t.formEmail,
                    value: email),
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
                  title: Text(t.profileMedicalRecord),
                  subtitle: Text(t.profileMedicalRecordSub),
                  trailing: Icon(Icons.chevron_right,
                      color: AppColors.textTertiary),
                  onTap: () => context.push(AppRoutes.medicalRecord),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.settings_outlined,
                      color: AppColors.textSecondary),
                  title: Text(t.profileSettings),
                  subtitle: Text(t.profileSettingsSub),
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
                  title: Text(t.profileShareWithDoctor),
                  subtitle: Text(t.profileShareWithDoctorSub),
                  trailing: Icon(Icons.chevron_right,
                      color: AppColors.textTertiary),
                  onTap: () => _shareWithDoctor(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.download_outlined,
                      color: AppColors.textSecondary),
                  title: Text(t.profileExportData),
                  subtitle: Text(t.profileExportDataSub),
                  trailing: Icon(Icons.chevron_right,
                      color: AppColors.textTertiary),
                  onTap: () => _exportData(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.info_outline,
                      color: AppColors.textSecondary),
                  title: Text(t.profileAboutApp),
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
            label: Text(t.profileSignOut,
                style: const TextStyle(color: AppColors.high)),
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
            label: Text(t.profileDeleteAccount,
                style: const TextStyle(color: AppColors.high)),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _shareWithDoctor(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final entries = ref.read(biomarkerEntriesProvider).valueOrNull ?? [];
    if (entries.isEmpty) {
      messenger.showSnackBar(SnackBar(
        content: Text(t.profileNoResultsToSummarize),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Load the medical record first so the sheet can offer an include toggle
    // (and so we honour that choice). valueOrNull returns [] before data loads.
    final medical = await ref
        .read(medicalRecordProvider.future)
        .catchError((_) => <MedicalRecordEntry>[]);
    if (!context.mounted) return;

    // Let the user pick which biomarkers go into the PDF (latest per marker)
    // and whether to include the medical-record section.
    final tracked = ref.read(trackedBiomarkersProvider).valueOrNull ?? entries;
    final selection = await showExportSelectionSheet(
      context,
      tracked,
      medicalCount: medical.length,
    );
    if (selection == null || selection.isEmpty) return; // dismissed / nothing

    // Keep only entries for the selected biomarkers; the PDF still computes the
    // latest reading per marker internally.
    final selectedEntries =
        entries.where((e) => selection.biomarkerIds.contains(e.biomarkerId)).toList();
    final medicalForPdf =
        selection.includeMedical ? medical : <MedicalRecordEntry>[];

    final profile = ref.read(profileProvider).valueOrNull;
    if (!context.mounted) return;
    // Show a preview of the PDF; share/print + export logging happen there.
    context.push(
      AppRoutes.pdfPreview,
      extra: {
        'profile': profile,
        'entries': selectedEntries,
        'medical': medicalForPdf,
        'biomarkerCount': selection.biomarkerIds.length,
        'includedMedical': selection.includeMedical,
      },
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final entries = ref.read(biomarkerEntriesProvider).valueOrNull ?? [];
    if (entries.isEmpty) {
      messenger.showSnackBar(SnackBar(
        content: Text(t.profileNoResultsToExport),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    try {
      await AccountService(Supabase.instance.client).exportEntries(entries);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(t.profileExportFailed(e.toString())),
        backgroundColor: AppColors.high,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        var canDelete = false;
        var deleting = false;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text(t.profileDeleteAccount),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.profileDeleteConfirmBody),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: t.profileDeleteTypeToConfirm,
                  ),
                  onChanged: (v) =>
                      setLocal(() => canDelete = v.trim().toUpperCase() == 'DELETE'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: deleting ? null : () => Navigator.pop(dialogContext),
                child: Text(t.commonCancel),
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
                            content:
                                Text(t.profileDeleteAccountError(e.toString())),
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
                    : Text(t.profileDeleteForever,
                        style: const TextStyle(color: AppColors.high)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(
      BuildContext context, String fullName, String? avatarUrl,
      [ProfileModel? profile]) {
    final initials = fullName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    final t = AppLocalizations.of(context);
    final age = profile?.age;
    final sex = switch (profile?.sex) {
      'male' => t.formSexShortMale,
      'female' => t.formSexShortFemale,
      'other' => t.formSexOther,
      _ => null,
    };
    final subtitleBits = <String>[
      if (age != null) t.profileAgeYears(age),
      if (sex != null) sex,
    ];

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
          if (subtitleBits.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subtitleBits.join('  ·  '),
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.profileSignOutTitle),
        content: Text(t.profileSignOutConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(t.commonCancel)),
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
            child: Text(AppLocalizations.of(context).profileSignOut,
                style: const TextStyle(color: AppColors.high)),
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
          child: LablioLoader(size: 44),
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
                    Text(AppLocalizations.of(context).profileHealthDetails,
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
                label: AppLocalizations.of(context).authSexLabel,
                value: _sexLabel(AppLocalizations.of(context), profile?.sex),
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
