import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/animated_lablio_logo.dart';

/// Splash shown at `/`. The Lablio mark draws itself full-page, then we
/// continue to Home. (Only logged-in + onboarded users reach this screen;
/// everyone else is redirected to login / onboarding before it builds.)
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _navigated = false;

  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    // A short beat after the draw finishes, then continue to Home.
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) context.go(AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    final logoSize =
        (MediaQuery.of(context).size.width * 0.5).clamp(160.0, 220.0);

    // Light background matches the app icon (#EAF4FB).
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FB),
      body: Center(
        child: AnimatedLablioLogo(
          size: logoSize,
          duration: const Duration(milliseconds: 1600),
          onComplete: _goHome,
        ),
      ),
    );
  }
}
