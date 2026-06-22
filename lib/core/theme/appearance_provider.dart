import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';

/// Curated accent choices shown in Settings (label + seed colour).
const kAccentOptions = <(String, Color)>[
  ('Lablio Blue', AppColors.defaultAccent),
  ('Teal', Color(0xFF0E9594)),
  ('Indigo', Color(0xFF5B5BD6)),
  ('Violet', Color(0xFF7C3AED)),
  ('Green', Color(0xFF16A34A)),
  ('Rose', Color(0xFFE11D48)),
  ('Amber', Color(0xFFD97706)),
];

const _accentKey = 'accent_color';
const _amoledKey = 'amoled';

class AccentColorNotifier extends StateNotifier<Color> {
  AccentColorNotifier() : super(AppColors.defaultAccent) {
    AppColors.applyAccent(state);
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_accentKey);
    if (v != null) {
      state = Color(v);
      AppColors.applyAccent(state);
    }
  }

  Future<void> set(Color color) async {
    state = color;
    AppColors.applyAccent(color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentKey, color.toARGB32());
  }
}

class AmoledNotifier extends StateNotifier<bool> {
  AmoledNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_amoledKey) ?? false;
    AppColors.amoled = state;
  }

  Future<void> set(bool value) async {
    state = value;
    AppColors.amoled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_amoledKey, value);
  }
}

final accentColorProvider =
    StateNotifierProvider<AccentColorNotifier, Color>((ref) =>
        AccentColorNotifier());

final amoledProvider =
    StateNotifierProvider<AmoledNotifier, bool>((ref) => AmoledNotifier());
