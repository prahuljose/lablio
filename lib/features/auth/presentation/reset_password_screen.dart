import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth/password_recovery.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_repository.dart';

/// Shown after the user opens a password-reset link. The recovery deep link has
/// already established a session, so here they simply choose a new password.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  // The recovery session may still be settling when this screen first appears
  // (the deep link's code exchange runs asynchronously). Gate submission on it.
  bool _ready = false;
  StreamSubscription<AuthState>? _authSub;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _ready = client.auth.currentSession != null;
    if (!_ready) {
      _authSub = client.auth.onAuthStateChange.listen((s) {
        if (s.session != null && mounted) {
          _timeout?.cancel();
          setState(() => _ready = true);
        }
      });
      // If the session never establishes (e.g. an expired link, or a PKCE link
      // opened on a different device than it was requested from), don't hang —
      // bail to login with a message.
      _timeout = Timer(const Duration(seconds: 12), _abortUnverified);
    }
  }

  Future<void> _abortUnverified() async {
    if (!mounted || _ready) return;
    await Supabase.instance.client.auth.signOut();
    passwordRecoveryNotifier.value = false;
    passwordRecoveryError.value =
        'We couldn’t verify your reset link. Please request a new one.';
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _timeout?.cancel();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AuthRepository(Supabase.instance.client)
          .updatePassword(_password.text);
      // Let the OS offer to save the new password.
      TextInput.finishAutofillContext();
      // Recovery is complete — release the router lock and proceed.
      passwordRecoveryNotifier.value = false;
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(t.authPasswordUpdated),
        behavior: SnackBarBehavior.floating,
      ));
      context.go(AppRoutes.home);
    } on AuthException catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.high),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text(t.authUpdatePasswordError(e.toString())),
          backgroundColor: AppColors.high,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    // The recovery session is active; leaving without setting a password should
    // sign out so a half-finished reset can't linger. Block the system back.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await Supabase.instance.client.auth.signOut();
        passwordRecoveryNotifier.value = false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Gradient hero ───────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryDark,
                        AppColors.primary,
                        AppColors.primaryLight,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.password_outlined,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        t.resetNewPasswordTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.resetNewPasswordSubtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: t.authNewPassword,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) => (v == null || v.length < 6)
                                ? t.authMin6Chars
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirm,
                            obscureText: _obscure,
                            autofillHints: const [AutofillHints.newPassword],
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: t.authConfirmPassword,
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                            validator: (v) => v != _password.text
                                ? t.authPasswordsDontMatch
                                : null,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: (_loading || !_ready) ? null : _submit,
                            icon: (_loading || !_ready)
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check, size: 18),
                            label: Text(
                                _ready ? t.resetUpdateButton : t.resetVerifying),
                          ),
                        ],
                      ),
                    ),
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
