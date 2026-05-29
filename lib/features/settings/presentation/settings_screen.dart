import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/locale_provider.dart';
import '../../../core/security/app_lock.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/units/unit_converter.dart';
import '../../../core/units/unit_system_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/data/profile_model.dart';
import '../../profile/providers/profile_provider.dart';

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
          const SizedBox(height: 12),
          _Section(title: 'Default tags', children: [
            _TagsEditor(),
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


// ── Tags editor ─────────────────────────────────────────────────────────────

class _TagsEditor extends ConsumerStatefulWidget {
  const _TagsEditor();

  @override
  ConsumerState<_TagsEditor> createState() => _TagsEditorState();
}

class _TagsEditorState extends ConsumerState<_TagsEditor> {
  final _ctrl = TextEditingController();
  List<String>? _tags;
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _hydrate(ProfileModel? p) {
    if (_tags != null) return;
    _tags = List<String>.from(p?.effectiveTags ?? kDefaultTags);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final current = ref.read(profileProvider).valueOrNull;
      if (current == null) return;
      await ref.read(profileProvider.notifier).save(
            current.copyWith(defaultTags: List<String>.from(_tags!)),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Default tags saved'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.normal,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not save: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.high,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addTag(String raw) {
    final t = raw.trim().toLowerCase();
    if (t.isEmpty || _tags!.contains(t)) { _ctrl.clear(); return; }
    setState(() { _tags!.add(t); _ctrl.clear(); });
  }

  void _remove(String t) => setState(() => _tags!.remove(t));

  void _reset() => setState(() => _tags = List<String>.from(kDefaultTags));

  @override
  Widget build(BuildContext context) {
    _hydrate(ref.watch(profileProvider).valueOrNull);
    final tags = _tags ?? kDefaultTags;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.label_outline, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              const Expanded(child: Text('Appear as quick suggestions when logging a result.',
                  style: TextStyle(fontSize: 13))),
            ]),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                for (final t in tags)
                  Chip(
                    label: Text(t),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _remove(t),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.30)),
                    labelStyle: const TextStyle(fontSize: 13, color: AppColors.primary),
                    deleteIconColor: AppColors.primary,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  textInputAction: TextInputAction.done,
                  onSubmitted: _addTag,
                  decoration: InputDecoration(
                    hintText: 'Add a tag…',
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.divider)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => _addTag(_ctrl.text),
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset to defaults'),
                style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size(80, 38)),
                child: _saving
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
