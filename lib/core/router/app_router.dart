import 'dart:async';

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

class _AppShellState extends State<_AppShell> with WidgetsBindingObserver {
  DateTime? _lastBackPress;
  String _path = AppRoutes.home;

  // ── WidgetsBindingObserver ────────────────────────────────────────────────
  // Called by Flutter BEFORE GoRouter's Router widget sees the back press.
  // We're added after the Router (child mounts after parent) so we appear
  // later in WidgetsBinding._observers and are therefore called FIRST (reverse
  // order iteration). Returning true consumes the event; false lets GoRouter
  // handle it (pop nested screens, etc.).
  @override
  Future<bool> didPopRoute() async {
    if (!mounted) return false;
    // If the root navigator has something above the shell (a nested screen),
    // don't intercept — let GoRouter pop it normally.
    if (Navigator.of(context, rootNavigator: true).canPop()) return false;
    // We're on a bare root tab — show snackbar / exit.
    _handleExit();
    return true; // consumed
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────

  int _selectedIndex() {
    if (_path.startsWith(AppRoutes.reports)) return 1;
    if (_path.startsWith(AppRoutes.biomarkers)) return 2;
    if (_path.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  void _handleExit() {
    if (!mounted) return;
    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _lastBackPress = now;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.textPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  }

  @override
  Widget build(BuildContext context) {
    _path = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex(),
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.home);
            case 1:
              context.go(AppRoutes.reports);
            case 2:
              context.go(AppRoutes.biomarkers);
            case 3:
              context.go(AppRoutes.profile);
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: AppLocalizations.of(context).navHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.folder_outlined),
            activeIcon: const Icon(Icons.folder),
            label: AppLocalizations.of(context).navReports,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.science_outlined),
            activeIcon: const Icon(Icons.science),
            label: AppLocalizations.of(context).navBiomarkers,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outlined),
            activeIcon: const Icon(Icons.person),
            label: AppLocalizations.of(context).navProfile,
          ),
        ],
      ),
    );
  }
}


