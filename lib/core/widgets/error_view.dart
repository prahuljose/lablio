import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../network/network_error.dart';

/// Success feedback: a light haptic tap + a green confirmation SnackBar.
/// Resolves against the app-level ScaffoldMessenger, so it survives a pop
/// (e.g. when a form closes right after saving).
void showSuccessSnackBar(BuildContext context, String message) {
  HapticFeedback.lightImpact();
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.normal,
      behavior: SnackBarBehavior.floating,
    ));
}

/// Shows a transient, network-aware warning (used when a pull-to-refresh fails
/// but cached content is still on screen — no need to replace the whole view).
void showOfflineAwareSnackBar(BuildContext context, Object error) {
  final t = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(networkAwareMessage(error, t)),
      backgroundColor: AppColors.high,
      behavior: SnackBarBehavior.floating,
    ));
}

/// A friendly full-area error state: a wifi-off icon + plain-language message
/// for connectivity failures (or a generic message otherwise), with an
/// optional Retry button. Replaces leaking raw exception strings to the UI.
class ErrorView extends StatelessWidget {
  final Object error;
  final Future<void> Function()? onRetry;
  const ErrorView({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final offline = isNetworkError(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: 44,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              offline ? t.errorNoInternetTitle : t.errorGenericTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              offline ? t.errorNoInternetBody : t.errorGenericBody,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(t.commonRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
