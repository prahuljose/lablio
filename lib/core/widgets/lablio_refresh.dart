import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'animated_lablio_logo.dart';

/// Pull-to-refresh that shows the animated Lablio mark instead of the default
/// Material spinner. Drop-in replacement for [RefreshIndicator].
class LablioRefresh extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  const LablioRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomMaterialIndicator(
      onRefresh: onRefresh,
      backgroundColor: AppColors.surface,
      elevation: 2,
      indicatorBuilder: (context, controller) {
        // Fade the logo in as the user pulls; it breathes while refreshing.
        final v = controller.value.clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.all(7),
          child: Opacity(
            opacity: (0.35 + 0.65 * v).clamp(0.0, 1.0),
            child: const AnimatedLablioLogo(size: 26, repeat: true),
          ),
        );
      },
      child: child,
    );
  }
}
