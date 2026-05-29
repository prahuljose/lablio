import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'pinned_biomarker_ids';

/// Persisted set of biomarker IDs the user has pinned to their home dashboard.
class PinnedBiomarkersNotifier extends StateNotifier<Set<String>> {
  PinnedBiomarkersNotifier() : super(<String>{}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = (prefs.getStringList(_key) ?? const <String>[]).toSet();
  }

  Future<void> toggle(String id) async {
    final next = Set<String>.from(state);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }

  bool isPinned(String id) => state.contains(id);
}

final pinnedBiomarkersProvider =
    StateNotifierProvider<PinnedBiomarkersNotifier, Set<String>>(
  (ref) => PinnedBiomarkersNotifier(),
);
