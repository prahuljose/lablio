import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Resolved colours + label for a result's range status, used consistently
/// across chips, cards, tiles and the trend chart. Backgrounds come from the
/// theme-aware AppColors getters so they adapt to dark mode.
class StatusStyle {
  final Color color;
  final Color bg;
  final String label;
  const StatusStyle(this.color, this.bg, this.label);

  static StatusStyle from({
    required bool isNormal,
    required bool isHigh,
    required bool isLow,
  }) {
    if (isNormal) {
      return StatusStyle(AppColors.normal, AppColors.normalBg, 'Normal');
    }
    if (isHigh) return StatusStyle(AppColors.high, AppColors.highBg, 'High');
    if (isLow) return StatusStyle(AppColors.low, AppColors.lowBg, 'Low');
    return StatusStyle(AppColors.textTertiary, AppColors.surfaceVariant, '—');
  }
}

/// Tabular figures so columns of numbers align cleanly.
const kTabularFigures = TextStyle(
  fontFeatures: [FontFeature.tabularFigures()],
);
