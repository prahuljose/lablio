import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'unit_converter.dart';

const _prefKey = 'unit_system';

/// Persisted preference for displaying values in conventional vs SI units.
class UnitSystemNotifier extends StateNotifier<UnitSystem> {
  UnitSystemNotifier() : super(UnitSystem.conventional) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    if (stored == 'si') state = UnitSystem.si;
  }

  Future<void> set(UnitSystem system) async {
    state = system;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefKey, system == UnitSystem.si ? 'si' : 'conventional');
  }

  void toggle() =>
      set(state == UnitSystem.si ? UnitSystem.conventional : UnitSystem.si);
}

final unitSystemProvider =
    StateNotifierProvider<UnitSystemNotifier, UnitSystem>(
  (ref) => UnitSystemNotifier(),
);
