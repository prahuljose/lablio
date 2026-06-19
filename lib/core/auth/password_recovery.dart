import 'package:flutter/foundation.dart';

/// Deep link the password-reset email redirects back to. Must be registered as
/// a custom URL scheme on Android (intent-filter) and iOS (CFBundleURLTypes),
/// AND added to the Supabase dashboard's Auth → URL Configuration redirect
/// allow-list, or the link will be rejected.
const kPasswordResetRedirect = 'lablio://reset-callback';

/// Flipped to `true` when the user opens the app via a password-reset link.
/// The router watches this and forces the user to the "Set new password"
/// screen until it's cleared. It is driven by [RecoveryLinkObserver] (from the
/// deep-link URI, which is deterministic) and, as a backup, by the
/// `AuthChangeEvent.passwordRecovery` auth event.
final passwordRecoveryNotifier = ValueNotifier<bool>(false);

/// Set to a human-readable message when a reset link is invalid or expired, so
/// the app can surface it (e.g. a SnackBar) and steer the user to request a new
/// one. Consumers should reset it to `null` after showing it.
final passwordRecoveryError = ValueNotifier<String?>(null);
