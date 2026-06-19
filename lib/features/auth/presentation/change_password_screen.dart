import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_repository.dart';

/// Lets a signed-in user change their password. Re-authenticates with the
/// current password first (Supabase's updateUser doesn't require it, but
/// verifying proves it's really the account owner making the change).
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repo = AuthRepository(Supabase.instance.client);
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null) return;

    setState(() => _loading = true);
    try {
      // Verify the current password by re-authenticating.
      try {
        await repo.signIn(email: email, password: _current.text);
      } on AuthException {
        messenger.showSnackBar(SnackBar(
          content: Text(t.authCurrentPasswordWrong),
          backgroundColor: AppColors.high,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
      await repo.updatePassword(_password.text);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(t.authPasswordChanged),
        backgroundColor: AppColors.normal,
        behavior: SnackBarBehavior.floating,
      ));
      context.pop();
    } on AuthException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppColors.high,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(t.authChangePasswordError(e.toString())),
        backgroundColor: AppColors.high,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.settingsChangePassword),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _current,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: t.authCurrentPassword,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? t.authEnterCurrentPassword : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: t.authNewPassword,
                prefixIcon: const Icon(Icons.lock_reset_outlined),
              ),
              validator: (v) {
                if (v == null || v.length < 6) return t.authMin6Chars;
                if (v == _current.text) return t.authNewMustDiffer;
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirm,
              obscureText: _obscure,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: t.authConfirmPassword,
                prefixIcon: const Icon(Icons.lock_reset_outlined),
              ),
              validator: (v) =>
                  v != _password.text ? t.authPasswordsDontMatch : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(t.authChangeButton),
            ),
          ],
        ),
      ),
    );
  }
}
