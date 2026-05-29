import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/i18n/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/security/app_lock.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'l10n/app_localizations.dart';

class LabioApp extends ConsumerWidget {
  const LabioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
