import 'package:flutter/material.dart';

/// App palette.
///
/// Brand + status colors are constant across themes. The "semantic" surface /
/// text / divider colors resolve from [brightness], which [AppTheme] keeps in
/// sync with the active theme — so existing `AppColors.surface` call sites work
/// in both light and dark mode without touching every widget.
class AppColors {
  AppColors._();

  /// Updated by the MaterialApp builder whenever the active theme changes.
  static Brightness brightness = Brightness.light;
  static bool get _dark => brightness == Brightness.dark;

  // ── Brand (accent) ────────────────────────────────────────────
  // Mutable so the user can choose an accent colour; [applyAccent] re-tints the
  // whole ramp and the MaterialApp builder calls it from the accent provider.
  static const defaultAccent = Color(0xFF0077B6);
  static Color primary = defaultAccent;
  static Color primaryLight = const Color(0xFF00B4D8);
  static Color primaryDark = const Color(0xFF023E8A);

  static void applyAccent(Color seed) {
    primary = seed;
    final h = HSLColor.fromColor(seed);
    primaryLight =
        h.withLightness((h.lightness + 0.12).clamp(0.0, 1.0)).toColor();
    primaryDark =
        h.withLightness((h.lightness - 0.16).clamp(0.0, 1.0)).toColor();
  }

  /// True-black (AMOLED) dark mode — darkens dark surfaces toward pure black.
  static bool amoled = false;

  // ── Status (constant) ─────────────────────────────────────────
  static const normal = Color(0xFF10B981);
  static const high = Color(0xFFEF4444);
  static const low = Color(0xFFF59E0B);

  // Status background chips — slightly translucent so they read on both themes.
  static Color get normalBg =>
      _dark ? const Color(0x3310B981) : const Color(0xFFD1FAE5);
  static Color get highBg =>
      _dark ? const Color(0x33EF4444) : const Color(0xFFFEE2E2);
  static Color get lowBg =>
      _dark ? const Color(0x33F59E0B) : const Color(0xFFFEF3C7);

  // ── Light raw values ──────────────────────────────────────────
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFF4F7FB);
  static const lightBackground = Color(0xFFF4F7FB);
  static const lightTextPrimary = Color(0xFF1A1D23);
  static const lightTextSecondary = Color(0xFF6B7280);
  static const lightTextTertiary = Color(0xFF9CA3AF);
  static const lightDivider = Color(0xFFE5E7EB);

  // ── Dark raw values ───────────────────────────────────────────
  static Color get darkSurface =>
      amoled ? const Color(0xFF0C0C0E) : const Color(0xFF1A1F26);
  static Color get darkSurfaceVariant =>
      amoled ? const Color(0xFF161618) : const Color(0xFF222A33);
  static Color get darkBackground =>
      amoled ? const Color(0xFF000000) : const Color(0xFF0F1419);
  static const darkTextPrimary = Color(0xFFF3F4F6);
  static const darkTextSecondary = Color(0xFF9CA3AF);
  static const darkTextTertiary = Color(0xFF6B7280);
  static const darkDivider = Color(0xFF2D333B);

  // ── Semantic (theme-resolved) ─────────────────────────────────
  static Color get surface => _dark ? darkSurface : lightSurface;
  static Color get surfaceVariant =>
      _dark ? darkSurfaceVariant : lightSurfaceVariant;
  static Color get background => _dark ? darkBackground : lightBackground;
  static Color get textPrimary => _dark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary =>
      _dark ? darkTextSecondary : lightTextSecondary;
  static Color get textTertiary =>
      _dark ? darkTextTertiary : lightTextTertiary;
  static Color get divider => _dark ? darkDivider : lightDivider;

  static const cardShadow = Color(0x0A000000);
}
