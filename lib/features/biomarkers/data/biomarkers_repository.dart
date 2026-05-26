import 'package:supabase_flutter/supabase_flutter.dart';
import 'biomarker_entry_model.dart';
import 'biomarker_model.dart';

class BiomarkersRepository {
  final SupabaseClient _client;
  static const _table = 'biomarker_entries';
  static const _refTable = 'biomarkers';

  BiomarkersRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<BiomarkerEntryModel>> fetchAll() async {
    final data = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .order('date', ascending: false);
    return (data as List).map((e) => BiomarkerEntryModel.fromMap(e)).toList();
  }

  Future<List<BiomarkerEntryModel>> fetchForBiomarker(String biomarkerId) async {
    final data = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .eq('biomarker_id', biomarkerId)
        .order('date', ascending: true);
    return (data as List).map((e) => BiomarkerEntryModel.fromMap(e)).toList();
  }

  Future<BiomarkerEntryModel> create(BiomarkerEntryModel entry) async {
    final result = await _client
        .from(_table)
        .insert(entry.toMap())
        .select()
        .single();
    return BiomarkerEntryModel.fromMap(result);
  }

  Future<void> delete(String entryId) async {
    await _client.from(_table).delete().eq('id', entryId);
  }

  /// Fetch all reference biomarkers from Supabase (public read, no auth required).
  Future<List<BiomarkerModel>> fetchReferenceBiomarkers() async {
    final data = await _client
        .from(_refTable)
        .select()
        .order('category')
        .order('name');
    return (data as List).map((e) => BiomarkerModel.fromDb(e)).toList();
  }

  Future<Map<String, BiomarkerEntryModel>> fetchLatestPerBiomarker() async {
    final data = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .order('date', ascending: false);

    final entries = (data as List).map((e) => BiomarkerEntryModel.fromMap(e));
    final Map<String, BiomarkerEntryModel> latest = {};
    for (final entry in entries) {
      latest.putIfAbsent(entry.biomarkerId, () => entry);
    }
    return latest;
  }
}
