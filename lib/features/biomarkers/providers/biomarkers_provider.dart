import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../data/biomarker_model.dart';
import '../data/biomarker_entry_model.dart';
import '../data/biomarkers_repository.dart';

final biomarkersRepositoryProvider = Provider(
  (ref) => BiomarkersRepository(Supabase.instance.client),
);

// All reference biomarkers — fetched from Supabase, falls back to bundled JSON
final referenceBiomarkersProvider = FutureProvider<List<BiomarkerModel>>((ref) async {
  try {
    return await ref.read(biomarkersRepositoryProvider).fetchReferenceBiomarkers();
  } catch (_) {
    // Offline fallback: load from bundled asset
    final jsonStr = await rootBundle.loadString('assets/data/biomarkers.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final list = data['biomarkers'] as List;
    return list.map((e) => BiomarkerModel.fromMap(e)).toList();
  }
});

// All user entries
final biomarkerEntriesProvider =
    AsyncNotifierProvider<BiomarkerEntriesNotifier, List<BiomarkerEntryModel>>(
  BiomarkerEntriesNotifier.new,
);

class BiomarkerEntriesNotifier
    extends AsyncNotifier<List<BiomarkerEntryModel>> {
  @override
  Future<List<BiomarkerEntryModel>> build() =>
      ref.read(biomarkersRepositoryProvider).fetchAll();

  Future<void> add(BiomarkerEntryModel entry) async {
    final saved = await ref.read(biomarkersRepositoryProvider).create(entry);
    state = AsyncData([saved, ...state.value ?? []]);
  }

  Future<void> remove(String entryId) async {
    await ref.read(biomarkersRepositoryProvider).delete(entryId);
    state = AsyncData(
      (state.value ?? []).where((e) => e.id != entryId).toList(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(biomarkersRepositoryProvider).fetchAll(),
    );
  }
}

// Entries for a specific biomarker — derived from the in-memory list so the
// detail screen updates instantly when an entry is added or removed.
final biomarkerHistoryProvider =
    Provider.family<AsyncValue<List<BiomarkerEntryModel>>, String>(
  (ref, biomarkerId) => ref.watch(biomarkerEntriesProvider).whenData(
        (entries) => entries
            .where((e) => e.biomarkerId == biomarkerId)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date)),
      ),
);

// Unique biomarkers the user has logged, each represented by its *latest*
// entry by date. Order-independent: we explicitly keep the entry with the
// greatest date per biomarker (a backdated add must not become "latest").
final trackedBiomarkersProvider =
    Provider<AsyncValue<List<BiomarkerEntryModel>>>((ref) {
  final entriesAsync = ref.watch(biomarkerEntriesProvider);
  return entriesAsync.whenData((entries) {
    final latest = <String, BiomarkerEntryModel>{};
    for (final e in entries) {
      final cur = latest[e.biomarkerId];
      if (cur == null ||
          e.date.isAfter(cur.date) ||
          // Tie-break on same date: prefer the more recently created entry.
          (e.date.isAtSameMomentAs(cur.date) &&
              e.createdAt.isAfter(cur.createdAt))) {
        latest[e.biomarkerId] = e;
      }
    }
    return latest.values.toList();
  });
});

// ── Biomarkers list UI state (search / filter / sort) ──────────────────────
enum BiomarkerFilter { all, normal, outOfRange, high, low }

enum BiomarkerSort { name, recent, status }

/// Set by the Home screen before navigating so the list opens pre-filtered.
final biomarkerInitialFilterProvider =
    StateProvider<BiomarkerFilter>((ref) => BiomarkerFilter.all);
