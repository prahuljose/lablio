import 'dart:io';
import '../../l10n/app_localizations.dart';

/// Whether [error] looks like a connectivity failure (offline, DNS failure,
/// dropped connection) rather than a server/logic error. Supabase surfaces
/// these as `SocketException` / http `ClientException` when there's no network.
bool isNetworkError(Object? error) {
  if (error is SocketException) return true;
  final s = error.toString();
  return s.contains('SocketException') ||
      s.contains('Failed host lookup') ||
      s.contains('ClientException') ||
      s.contains('Connection closed') ||
      s.contains('Connection reset') ||
      s.contains('Connection refused') ||
      s.contains('Network is unreachable') ||
      s.contains('Software caused connection abort');
}

/// A short, user-facing message for an error — a friendly "you're offline"
/// line for connectivity failures, otherwise a generic try-again message.
/// Never leaks raw exception text to the UI.
String networkAwareMessage(Object? error, AppLocalizations t) =>
    isNetworkError(error) ? t.errorNoInternetBody : t.errorGenericBody;
