import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../onboarding/onboarding_state.dart';
import '../../l10n/app_localizations.dart';
import '../../features/auth/presentation/auth_gate.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/biomarkers/data/biomarker_model.dart';
import '../../features/biomarkers/presentation/add_custom_biomarker_screen.dart';
import '../../features/biomarkers/presentation/add_entry_screen.dart';
import '../../features/biomarkers/presentation/biomarker_detail_screen.dart';
import '../../features/biomarkers/presentation/biomarkers_screen.dart';
import '../../features/biomarkers/presentation/browse_biomarkers_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/medical_record_screen.dart';
import '../../features/scan/data/lab_report_parser.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/scan/presentation/review_extraction_screen.dart';
import '../../features/scan/presentation/scan_report_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/reports/data/report_model.dart';
import '../../features/reports/presentation/add_report_screen.dart';
import '../../features/reports/presentation/report_detail_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const reports = '/reports';
  static const addReport = '/reports/add';
  static const reportDetail = '/reports/detail';
  static const biomarkers = '/biomarkers';
  static const browseBiomarkers = '/biomarkers/browse';
  static const biomarkerDetail = '/biomarkers/detail';
  static const addEntry = '/biomarkers/add-entry';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const onboarding = '/onboarding';
  static const scanReport = '/scan';
  static const reviewExtraction = '/scan/review';
  static const settings = '/settings';
  static const addCustomBiomarker = '/biomarkers/custom/add';
  static const search = '/search';
  static const medicalRecord = '/profile/medical-record';
}

/// Notifies GoRouter whenever Supabase auth state changes (sign-in / sign-out),
/// so the `redirect` below re-runs and moves the user to the right place.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Routes reachable while signed out (excluding splash, which is transient).
const _authRoutes = {
  AppRoutes.login,
  AppRoutes.signup,
  AppRoutes.forgotPassword,
};

/// A subtle fade + rise transition for drill-in screens, giving a polished
/// "hero" feel instead of the default platform push.
CustomTransitionPage<void> _fadeRisePage(
    GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondary, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(0, 0.035), end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
    child: child,
  );
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  refreshListenable:
      _AuthChangeNotifier(Supabase.instance.client.auth.onAuthStateChange),
  redirect: (context, state) {
    final loggedIn = Supabase.instance.client.auth.currentSession != null;
    final loc = state.matchedLocation;

    // Splash is just a launch point — always resolve it to a real screen
    // based on session state (otherwise we get stuck on the spinner, e.g.
    // after a hot restart which resets the location to '/').
    if (loc == AppRoutes.splash) {
      if (!loggedIn) return AppRoutes.login;
      return gOnboardingSeen ? AppRoutes.home : AppRoutes.onboarding;
    }

    // Show first-run onboarding once, after the user is signed in.
    if (loggedIn && !gOnboardingSeen && loc != AppRoutes.onboarding) {
      return AppRoutes.onboarding;
    }

    final onAuthRoute = _authRoutes.contains(loc);

    // Not signed in and trying to reach a protected route → login.
    if (!loggedIn && !onAuthRoute) return AppRoutes.login;

    // Signed in but sitting on the login/signup screens → home.
    if (loggedIn &&
        (loc == AppRoutes.login || loc == AppRoutes.signup)) {
      return AppRoutes.home;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (_, __) => const AuthGate(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      builder: (_, __) => const SignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (_, __) => const ForgotPasswordScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => _AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.reports,
          builder: (_, __) => const ReportsScreen(),
        ),
        GoRoute(
          path: AppRoutes.biomarkers,
          builder: (_, __) => const BiomarkersScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, __) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.addReport,
      builder: (_, __) => const AddReportScreen(),
    ),
    GoRoute(
      path: AppRoutes.reportDetail,
      pageBuilder: (_, state) => _fadeRisePage(
        state,
        ReportDetailScreen(report: state.extra as ReportModel),
      ),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.editProfile,
      builder: (_, __) => const EditProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      pageBuilder: (_, state) =>
          _fadeRisePage(state, const SettingsScreen()),
    ),
    GoRoute(
      path: AppRoutes.addCustomBiomarker,
      pageBuilder: (_, state) =>
          _fadeRisePage(state, const AddCustomBiomarkerScreen()),
    ),
    GoRoute(
      path: AppRoutes.search,
      pageBuilder: (_, state) =>
          _fadeRisePage(state, const SearchScreen()),
    ),
    GoRoute(
      path: AppRoutes.medicalRecord,
      pageBuilder: (_, state) =>
          _fadeRisePage(state, const MedicalRecordScreen()),
    ),
    GoRoute(
      path: AppRoutes.scanReport,
      pageBuilder: (_, state) =>
          _fadeRisePage(state, const ScanReportScreen()),
    ),
    GoRoute(
      path: AppRoutes.reviewExtraction,
      pageBuilder: (_, state) {
        final result = state.extra as ExtractionResult;
        return _fadeRisePage(
          state,
          ReviewExtractionScreen(
            candidates: result.candidates,
            rawText: result.rawText,
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.browseBiomarkers,
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return BrowseBiomarkersScreen(
          reportId: extra?['reportId'] as String?,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.biomarkerDetail,
      pageBuilder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return _fadeRisePage(
          state,
          BiomarkerDetailScreen(
            biomarkerId: extra['biomarkerId'] as String,
            biomarkerName: extra['biomarkerName'] as String,
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.addEntry,
      pageBuilder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return _fadeRisePage(
          state,
          AddEntryScreen(
            biomarkerId: extra['biomarkerId'] as String,
            biomarkerName: extra['biomarkerName'] as String,
            biomarker: extra['biomarker'] as BiomarkerModel?,
            reportId: extra['reportId'] as String?,
          ),
        );
      },
    ),
  ],
);

class _AppShell extends StatefulWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  static const _navChannel = MethodChannel('com.lablio.app/nav');
  String _path = AppRoutes.home;

  @override
  void initState() {
    super.initState();
    // Receive every back press from the native Android OnBackPressedDispatcher.
    // canPop() on the ROOT navigator tells us if a nested screen is on top.
    // Kotlin owns the 2-second double-press timer and calls finishAffinity()
    // on the second press. Flutter only decides: pop a nested screen, or show
    // the "press again to exit" snackbar for root tabs (first press).
    _navChannel.setMethodCallHandler((call) async {
      if (call.method != 'back' || !mounted) return;
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        GoRouter.of(context).pop();
        return;
      }
      // Root tab — show snackbar (Kotlin will exit on the next press).
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        content: const Text(
          'Press back again to exit Lablio',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ));
    });
  }

  @override
  void dispose() {
    _navChannel.setMethodCallHandler(null);
    super.dispose();
  }

  int _selectedIndex() {
    if (_path.startsWith(AppRoutes.reports)) return 1;
    if (_path.startsWith(AppRoutes.biomarkers)) return 2;
    if (_path.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    _path = GoRouterState.of(context).uri.path;

    return Scaffold(
      extendBody: true, // body flows behind the floating nav bar
      body: widget.child,
      bottomNavigationBar: _LabNav(
        currentIndex: _selectedIndex(),
        onTap: (i) {
          switch (i) {
            case 0: context.go(AppRoutes.home);
            case 1: context.go(AppRoutes.reports);
            case 2: context.go(AppRoutes.biomarkers);
            case 3: context.go(AppRoutes.profile);
          }
        },
        labels: [
          AppLocalizations.of(context).navHome,
          AppLocalizations.of(context).navReports,
          AppLocalizations.of(context).navBiomarkers,
          AppLocalizations.of(context).navProfile,
        ],
      ),
    );
  }
}

// ── Floating frosted-glass pill nav bar ──────────────────────────────────────

class _LabNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<String> labels;

  const _LabNav({
    required this.currentIndex,
    required this.onTap,
    required this.labels,
  });

  static const _icons = [
    (Icons.home_rounded,    Icons.home_outlined),
    (Icons.folder_rounded,  Icons.folder_outlined),
    (Icons.science_rounded, Icons.science_outlined),
    (Icons.person_rounded,  Icons.person_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final pad  = MediaQuery.of(context).padding.bottom;
    final dark = Theme.of(context).brightness == Brightness.dark;

    // Outer padding makes the pill float above the system nav area.
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + pad),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: 62,
            decoration: BoxDecoration(
              // Translucent surface — white-ish in light, black-ish in dark.
              color: dark
                  ? Colors.black.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.10)
                    : const Color(0xFF0096C7).withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.35 : 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                for (int i = 0; i < _icons.length; i++)
                  Expanded(
                    child: _NavItem(
                      activeIcon: _icons[i].$1,
                      icon:       _icons[i].$2,
                      label: labels[i],
                      selected:  i == currentIndex,
                      onTap: () => onTap(i),
                      dark: dark,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dark;

  const _NavItem({
    required this.activeIcon,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.dark,
  });

  static const _gradA = Color(0xFF023E8A);
  static const _gradB = Color(0xFF0096C7);

  @override
  Widget build(BuildContext context) {
    // Inactive icon colour — brand blue in light, soft white in dark.
    final inactiveColor = dark
        ? Colors.white.withValues(alpha: 0.40)
        : const Color(0xFF0077B6).withValues(alpha: 0.50);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: selected
              // ── Active: gradient pill with icon + label side by side ──
              ? Container(
                  key: const ValueKey(true),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_gradA, _gradB],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    // "More rectangular rounded" — tighter radius than a full pill.
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _gradB.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                )
              // ── Inactive: centred icon only ───────────────────────────
              : SizedBox(
                  key: const ValueKey(false),
                  width: double.infinity,
                  child: Icon(icon, color: inactiveColor, size: 22),
                ),
        ),
      ),
    );
  }
}


