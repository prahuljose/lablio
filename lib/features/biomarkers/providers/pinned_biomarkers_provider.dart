import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'pinned_biomarker_ids';

/// Persisted, **ordered** list of biomarker IDs the user has pinned to their
/// home dashboard. Order is user-controlled (drag to reorder); newly pinned
/// markers append to the end.
class PinnedBiomarkersNotifier extends StateNotifier<List<String>> {
  PinnedBiomarkersNotifier() : super(const <String>[]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_key) ?? const <String>[];
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state);
  }

  Future<void> toggle(String id) async {
    state = state.contains(id)
        ? state.where((x) => x != id).toList()
        : [...state, id];
    await _persist();
  }

  Future<void> remove(String id) async {
    if (!state.contains(id)) return;
    state = state.where((x) => x != id).toList();
    await _persist();
  }

  /// Move a pinned marker (used by the reorderable manage sheet).
  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = [...state];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
    await _persist();
  }

  bool isPinned(String id) => state.contains(id);
}

final pinnedBiomarkersProvider =
    StateNotifierProvider<PinnedBiomarkersNotifier, List<String>>(
  (ref) => PinnedBiomarkersNotifier(),
);
