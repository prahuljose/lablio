import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/auth_gate.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/biomarkers/data/biomarker_model.dart';
import '../../features/biomarkers/presentation/add_entry_screen.dart';
import '../../features/biomarkers/presentation/biomarker_detail_screen.dart';
import '../../features/biomarkers/presentation/biomarkers_screen.dart';
import '../../features/biomarkers/presentation/browse_biomarkers_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
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
      return loggedIn ? AppRoutes.home : AppRoutes.login;
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
      builder: (_, state) {
        final report = state.extra as ReportModel;
        return ReportDetailScreen(report: report);
      },
    ),
    GoRoute(
      path: AppRoutes.editProfile,
      builder: (_, __) => const EditProfileScreen(),
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
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return BiomarkerDetailScreen(
          biomarkerId: extra['biomarkerId'] as String,
          biomarkerName: extra['biomarkerName'] as String,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.addEntry,
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return AddEntryScreen(
          biomarkerId: extra['biomarkerId'] as String,
          biomarkerName: extra['biomarkerName'] as String,
          biomarker: extra['biomarker'] as BiomarkerModel?,
          reportId: extra['reportId'] as String?,
        );
      },
    ),
  ],
);

class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRoutes.reports)) return 1;
    if (location.startsWith(AppRoutes.biomarkers)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex(context),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.science_outlined),
            activeIcon: Icon(Icons.science),
            label: 'Biomarkers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}


