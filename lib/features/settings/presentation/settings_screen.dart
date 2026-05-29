import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/locale_provider.dart';
import '../../../core/security/app_lock.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/units/unit_converter.dart';
import '../../../core/units/unit_system_provider.dart';
import '../../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(title: t.settingsAppearance, children: [
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Icon(Icons.brightness_6_outlined,
                        color: AppColors.textSecondary),
                    const SizedBox(width: 16),
                    Expanded(child: Text(t.settingsTheme)),
                    SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                      segments: const [
                        ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto, size: 18),
                            tooltip: 'System'),
                        ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode, size: 18),
                            tooltip: 'Light'),
                        ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode, size: 18),
                            tooltip: 'Dark'),
                      ],
                      selected: {ref.watch(themeModeProvider)},
                      onSelectionChanged: (s) => ref
                          .read(themeModeProvider.notifier)
                          .set(s.first),
                    ),
                  ],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _Section(title: t.settingsUnits, children: [
            Card(
              child: SwitchListTile(
                value: ref.watch(unitSystemProvider) == UnitSystem.si,
                onChanged: (v) => ref.read(unitSystemProvider.notifier).set(
                    v ? UnitSystem.si : UnitSystem.conventional),
                secondary: Icon(Icons.straighten,
                    color: AppColors.textSecondary),
                title: Text(t.settingsSIUnits),
                subtitle: Text(t.settingsSIUnitsSub),
                activeThumbColor: AppColors.primary,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _Section(title: t.settingsSecurity, children: [
            Card(
              child: SwitchListTile(
                value: ref.watch(appLockEnabledProvider),
                onChanged: (v) => _toggleAppLock(context, ref, v),
                secondary: Icon(Icons.fingerprint,
                    color: AppColors.textSecondary),
                title: Text(t.settingsBiometricLock),
                subtitle: Text(t.settingsBiometricLockSub),
                activeThumbColor: AppColors.primary,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _Section(title: t.settingsLanguage, children: [
            Card(
              child: Column(
                children: [
                  for (final entry in const [
                    (null, 'System default'),
                    (Locale('en'), 'English'),
                    (Locale('hi'), 'हिन्दी'),
                    (Locale('ml'), 'മലയാളം'),
                  ])
                    RadioListTile<Locale?>(
                      value: entry.$1,
                      groupValue: ref.watch(localeProvider),
                      onChanged: (v) =>
                          ref.read(localeProvider.notifier).set(v),
                      title: Text(entry.$2),
                      activeColor: AppColors.primary,
                    ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _toggleAppLock(
      BuildContext context, WidgetRef ref, bool enable) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!enable) {
      await ref.read(appLockEnabledProvider.notifier).set(false);
      return;
    }
    final service = ref.read(biometricServiceProvider);
    if (!await service.isAvailable()) {
      messenger.showSnackBar(const SnackBar(
        content: Text('No biometrics or device lock set up on this device.'),
        backgroundColor: AppColors.high,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final ok = await service.authenticate('Confirm to enable biometric lock');
    if (ok) {
      await ref.read(appLockEnabledProvider.notifier).set(true);
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ...children,
        ],
      );
}

