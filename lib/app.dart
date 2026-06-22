import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/auth/password_recovery.dart';
import 'core/constants/app_colors.dart';
import 'core/i18n/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/security/app_lock.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/appearance_provider.dart';
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
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _lastUserId = Supabase.instance.client.auth.currentUser?.id;
    // Surface invalid/expired reset-link errors as a SnackBar.
    passwordRecoveryError.addListener(_onRecoveryError);
    // When the signed-in user changes (login as a different user, or sign out),
    // drop all cached user-scoped data so the next read fetches fresh.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      // A reset-link deep link establishes a session and emits this event —
      // gate the app on setting a new password (router watches the notifier).
      if (state.event == AuthChangeEvent.passwordRecovery) {
        passwordRecoveryNotifier.value = true;
      }
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

  void _onRecoveryError() {
    final msg = passwordRecoveryError.value;
    if (msg == null) return;
    _messengerKey.currentState
      ?..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.high,
        behavior: SnackBarBehavior.floating,
      ));
    passwordRecoveryError.value = null;
  }

  @override
  void dispose() {
    passwordRecoveryError.removeListener(_onRecoveryError);
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    // Apply accent + AMOLED before themes are built so both recompute on change.
    AppColors.applyAccent(ref.watch(accentColorProvider));
    AppColors.amoled = ref.watch(amoledProvider);

    return MaterialApp.router(
      title: 'Lablio',
      scaffoldMessengerKey: _messengerKey,
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
        // Honor the OS text-size setting, but clamp the extremes so layouts
        // stay intact (very large scales would otherwise overflow tiles/rows).
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.3,
          // Tap anywhere outside a field to dismiss the keyboard.
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: AppLockGate(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
      routerConfig: appRouter,
    );
  }
}
