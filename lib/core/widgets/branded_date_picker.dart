import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// A [showDatePicker] wrapper themed in Lablio's brand palette (blue header,
/// brand-blue selected day and action buttons) so the picker matches the app
/// instead of the platform default. Use everywhere a date is picked.
Future<DateTime?> showBrandedDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    builder: (ctx, child) {
      final dark = Theme.of(ctx).brightness == Brightness.dark;
      final base = dark ? ColorScheme.dark() : ColorScheme.light();
      return Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: base.copyWith(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: AppColors.surface,
            headerBackgroundColor: AppColors.primary,
            headerForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ),
        child: child!,
      );
    },
  );
}
