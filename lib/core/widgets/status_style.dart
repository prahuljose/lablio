import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Resolved colours + label for a result's range status, used consistently
/// across chips, cards, tiles and the trend chart. Backgrounds come from the
/// theme-aware AppColors getters so they adapt to dark mode.
class StatusStyle {
  final Color color;
  final Color bg;
  final String label;

  /// A shape cue that conveys status *without relying on colour* (≈8% of men
  /// are red–green colour-blind, and this is medical data). Pair it with the
  /// colour everywhere status is shown.
  final IconData icon;
  const StatusStyle(this.color, this.bg, this.label, this.icon);

  static StatusStyle from({
    required bool isNormal,
    required bool isHigh,
    required bool isLow,
  }) {
    if (isNormal) {
      return StatusStyle(
          AppColors.normal, AppColors.normalBg, 'Normal', Icons.check_rounded);
    }
    if (isHigh) {
      return StatusStyle(
          AppColors.high, AppColors.highBg, 'High', Icons.arrow_upward_rounded);
    }
    if (isLow) {
      return StatusStyle(
          AppColors.low, AppColors.lowBg, 'Low', Icons.arrow_downward_rounded);
    }
    return StatusStyle(AppColors.textTertiary, AppColors.surfaceVariant, '—',
        Icons.remove_rounded);
  }
}

/// Tabular figures so columns of numbers align cleanly.
const kTabularFigures = TextStyle(
  fontFeatures: [FontFeature.tabularFigures()],
);
