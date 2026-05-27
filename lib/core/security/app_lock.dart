import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import 'biometric_service.dart';

const _key = 'app_lock_enabled';

final biometricServiceProvider = Provider((ref) => BiometricService());

/// Persisted "require biometric unlock" preference.
class AppLockEnabledNotifier extends StateNotifier<bool> {
  AppLockEnabledNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> set(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
  }
}

final appLockEnabledProvider =
    StateNotifierProvider<AppLockEnabledNotifier, bool>(
  (ref) => AppLockEnabledNotifier(),
);

/// Wraps the app, presenting a lock screen when biometric lock is enabled
/// and the app has just launched or returned from the background.
class AppLockGate extends ConsumerStatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _authInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Lock on cold start if the preference is on.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(appLockEnabledProvider)) {
        setState(() => _locked = true);
        _authenticate();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!ref.read(appLockEnabledProvider)) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // Re-lock when leaving the foreground.
      if (!_locked) setState(() => _locked = true);
    } else if (state == AppLifecycleState.resumed) {
      if (_locked && !_authInProgress) _authenticate();
    }
  }

  Future<void> _authenticate() async {
    if (_authInProgress) return;
    _authInProgress = true;
    final ok = await ref
        .read(biometricServiceProvider)
        .authenticate('Unlock Lablio to view your health data');
    _authInProgress = false;
    if (ok && mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            child: _LockScreen(onUnlock: _authenticate),
          ),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  final VoidCallback onUnlock;
  const _LockScreen({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline,
                  size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text('Lablio is locked',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Authenticate to continue',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: ElevatedButton.icon(
                onPressed: onUnlock,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
