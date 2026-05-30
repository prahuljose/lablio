import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_colors.dart';
import 'core/i18n/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/security/app_lock.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/biomarkers/providers/biomarker_notes_provider.dart';
import 'features/biomarkers/providers/biomarkers_provider.dart';
import 'features/biomarkers/providers/custom_biomarkers_provider.dart';
import 'features/profile/providers/medical_record_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/reports/providers/reports_provider.dart';
import 'l10n/app_localizations.dart';

class LablioApp extends ConsumerStatefulWidget {
  const LablioApp({super.key});

  @override
  ConsumerState<LablioApp> createState() => _LablioAppState();
}

class _LablioAppState extends ConsumerState<LablioApp> {
  StreamSubscription<AuthState>? _authSub;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _lastUserId = Supabase.instance.client.auth.currentUser?.id;
    // When the signed-in user changes (login as a different user, or sign out),
    // drop all cached user-scoped data so the next read fetches fresh.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      final newId = state.session?.user.id;
      if (newId != _lastUserId) {
        _lastUserId = newId;
        _resetUserScopedProviders();
      }
    });
  }

  void _resetUserScopedProviders() {
    ref.invalidate(profileProvider);
    ref.invalidate(biomarkerEntriesProvider);
    ref.invalidate(reportsProvider);
    ref.invalidate(customBiomarkersProvider);
    ref.invalidate(biomarkerNotesProvider);
    ref.invalidate(medicalRecordProvider);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Lablio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Keep the global semantic palette in sync with the active theme so
      // direct AppColors.* reads (in custom widgets) match light/dark.
      builder: (context, child) {
        AppColors.brightness = Theme.of(context).brightness;
        return AppLockGate(child: child ?? const SizedBox.shrink());
      },
      routerConfig: appRouter,
    );
  }
}
