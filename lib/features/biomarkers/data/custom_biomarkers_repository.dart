import 'package:supabase_flutter/supabase_flutter.dart';
import 'biomarker_model.dart';

/// CRUD for user-defined biomarkers stored in `public.custom_biomarkers`.
/// Returns / consumes the same `BiomarkerModel` shape so they can be merged
/// with the reference set transparently in the rest of the app.
class CustomBiomarkersRepository {
  final SupabaseClient _client;
  static const _table = 'custom_biomarkers';

  CustomBiomarkersRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  BiomarkerModel _fromRow(Map<String, dynamic> m) => BiomarkerModel(
        id: m['id'] as String,
        name: m['name'] as String,
        shortName: m['short_name'] as String,
        category: m['category'] as String? ?? 'Custom',
        unit: m['unit'] as String? ?? '',
        refRangeLow: (m['ref_range_low'] as num?)?.toDouble(),
        refRangeHigh: (m['ref_range_high'] as num?)?.toDouble(),
        description: m['description'] as String?,
      );

  Future<List<BiomarkerModel>> fetchAll() async {
    final data =
        await _client.from(_table).select().eq('user_id', _userId).order('name');
    return (data as List).map((m) => _fromRow(m)).toList();
  }

  Future<BiomarkerModel> create(BiomarkerModel m) async {
    final row = await _client
        .from(_table)
        .insert({
          'id': m.id,
          'user_id': _userId,
          'name': m.name,
          'short_name': m.shortName,
          'category': m.category,
          'unit': m.unit,
          'ref_range_low': m.refRangeLow,
          'ref_range_high': m.refRangeHigh,
          'description': m.description,
        })
        .select()
        .single();
    return _fromRow(row);
  }

  Future<void> delete(String id) async {
    await _client
        .from(_table)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
