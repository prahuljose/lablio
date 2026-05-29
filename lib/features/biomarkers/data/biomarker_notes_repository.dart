import 'package:supabase_flutter/supabase_flutter.dart';
import 'biomarker_note_model.dart';

class BiomarkerNotesRepository {
  final SupabaseClient _client;
  static const _table = 'biomarker_notes';

  BiomarkerNotesRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<Map<String, BiomarkerNoteModel>> fetchAll() async {
    final data = await _client.from(_table).select().eq('user_id', _userId);
    final notes =
        (data as List).map((e) => BiomarkerNoteModel.fromMap(e)).toList();
    return {for (final n in notes) n.biomarkerId: n};
  }

  Future<BiomarkerNoteModel> upsert(String biomarkerId, String body) async {
    final result = await _client
        .from(_table)
        .upsert(
          {
            'user_id': _userId,
            'biomarker_id': biomarkerId,
            'body': body,
            'updated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'user_id,biomarker_id',
        )
        .select()
        .single();
    return BiomarkerNoteModel.fromMap(result);
  }

  Future<void> remove(String biomarkerId) async {
    await _client
        .from(_table)
        .delete()
        .eq('user_id', _userId)
        .eq('biomarker_id', biomarkerId);
  }
}
