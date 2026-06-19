import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'password_recovery.dart';

/// Drives the app into "password recovery" mode based on the incoming reset
/// deep link itself — rather than relying on catching the one-shot
/// [AuthChangeEvent.passwordRecovery], which can fire before any listener is
/// attached on a cold start (the app is launched *by* the link). Reading the
/// launching URI directly makes recovery detection deterministic.
///
/// Handles both:
///  - the PKCE `code` link (`lablio://reset-callback?code=…`) — supabase_flutter
///    exchanges the code itself; we just switch the UI into recovery mode.
///  - the token-hash link (`?token_hash=…&type=recovery`) — we verify it
///    ourselves via [GoTrueClient.verifyOTP], which needs no local code-verifier
///    and therefore also works when the link is opened on a different device.
class RecoveryLinkObserver {
  RecoveryLinkObserver._();
  static final RecoveryLinkObserver instance = RecoveryLinkObserver._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _started = false;
  String? _lastHandled;

  /// Begins observing. Safe to call once at startup. Awaits the cold-start
  /// initial link so the very first router build can already be in recovery
  /// mode (no flash of Home).
  Future<void> start() async {
    if (_started || kIsWeb) return;
    _started = true;
    _sub = _appLinks.uriLinkStream.listen(_handle, onError: (_) {});
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (_) {/* getInitialLink can throw on some platforms — ignore */}
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _started = false;
  }

  void _handle(Uri uri) {
    if (!_isRecoveryLink(uri)) return;
    // The initial link is also re-emitted on the stream — de-dupe so we don't
    // verify the same token twice (the second attempt would fail as "used").
    final key = uri.toString();
    if (key == _lastHandled) return;
    _lastHandled = key;

    if (_carriesError(uri)) {
      passwordRecoveryError.value =
          _errorMessage(uri) ?? 'This password reset link is invalid or has expired.';
      return;
    }

    final tokenHash = uri.queryParameters['token_hash'];
    final type = uri.queryParameters['type'];
    if (tokenHash != null && (type == null || type == 'recovery')) {
      _verifyTokenHash(tokenHash); // flips the flag on success
      return;
    }

    // PKCE `code` link: supabase_flutter performs the exchange; we only need to
    // enter recovery mode so the router shows the Set-new-password screen.
    passwordRecoveryNotifier.value = true;
  }

  Future<void> _verifyTokenHash(String tokenHash) async {
    try {
      await Supabase.instance.client.auth
          .verifyOTP(type: OtpType.recovery, tokenHash: tokenHash);
      passwordRecoveryNotifier.value = true;
    } catch (_) {
      passwordRecoveryNotifier.value = false;
      passwordRecoveryError.value =
          'This password reset link is invalid or has expired.';
    }
  }

  bool _isRecoveryLink(Uri uri) {
    if (uri.host == 'reset-callback') return true;
    if (uri.queryParameters['type'] == 'recovery') return true;
    if (uri.fragment.contains('type=recovery')) return true;
    return false;
  }

  bool _carriesError(Uri uri) =>
      uri.queryParameters.containsKey('error') ||
      uri.queryParameters.containsKey('error_description') ||
      uri.fragment.contains('error=') ||
      uri.fragment.contains('error_description=');

  String? _errorMessage(Uri uri) {
    final q =
        uri.queryParameters['error_description'] ?? uri.queryParameters['error'];
    if (q != null) return q.replaceAll('+', ' ');
    final frag = Uri.splitQueryString(uri.fragment);
    final f = frag['error_description'] ?? frag['error'];
    return f;
  }
}
