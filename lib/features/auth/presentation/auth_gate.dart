import 'package:flutter/material.dart';

/// Splash shown at `/`. The router's auth-aware `redirect` immediately sends
/// the user to `/home` or `/login` based on session state, so this just needs
/// to render a brief loading state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
