import 'package:supabase_flutter/supabase_flutter.dart';
import 'medical_record_model.dart';

class MedicalRecordRepository {
  final SupabaseClient _client;
  static const _table = 'medical_record';

  MedicalRecordRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<MedicalRecordEntry>> fetchAll() async {
    final data = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .order('occurred_on', ascending: false, nullsFirst: false)
        .order('created_at', ascending: false);
    return (data as List).map((e) => MedicalRecordEntry.fromMap(e)).toList();
  }

  Future<MedicalRecordEntry> create(MedicalRecordEntry entry) async {
    final result = await _client
        .from(_table)
        .insert(entry.toInsertMap(_userId))
        .select()
        .single();
    return MedicalRecordEntry.fromMap(result);
  }

  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id).eq('user_id', _userId);
  }
}
