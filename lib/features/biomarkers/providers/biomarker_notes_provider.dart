import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/biomarker_note_model.dart';
import '../data/biomarker_notes_repository.dart';

final biomarkerNotesRepositoryProvider = Provider(
  (ref) => BiomarkerNotesRepository(Supabase.instance.client),
);

final biomarkerNotesProvider = AsyncNotifierProvider<BiomarkerNotesNotifier,
    Map<String, BiomarkerNoteModel>>(BiomarkerNotesNotifier.new);

class BiomarkerNotesNotifier
    extends AsyncNotifier<Map<String, BiomarkerNoteModel>> {
  @override
  Future<Map<String, BiomarkerNoteModel>> build() =>
      ref.read(biomarkerNotesRepositoryProvider).fetchAll();

  Future<void> save(String biomarkerId, String body) async {
    final updated = await ref
        .read(biomarkerNotesRepositoryProvider)
        .upsert(biomarkerId, body);
    final next = Map<String, BiomarkerNoteModel>.from(state.value ?? {});
    next[biomarkerId] = updated;
    state = AsyncData(next);
  }

  Future<void> remove(String biomarkerId) async {
    await ref.read(biomarkerNotesRepositoryProvider).remove(biomarkerId);
    final next = Map<String, BiomarkerNoteModel>.from(state.value ?? {});
    next.remove(biomarkerId);
    state = AsyncData(next);
  }
}
