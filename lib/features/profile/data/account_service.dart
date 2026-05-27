import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../biomarkers/data/biomarker_entry_model.dart';

class AccountService {
  final SupabaseClient _client;
  AccountService(this._client);

  String _csv(Object? v) {
    final s = (v ?? '').toString();
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  /// Builds a CSV of all biomarker entries and opens the system share sheet.
  Future<void> exportEntries(List<BiomarkerEntryModel> entries) async {
    final rows = <String>[
      'Date,Biomarker,Category,Value,Unit,Ref Low,Ref High,Status,Notes',
    ];
    final sorted = [...entries]..sort((a, b) => b.date.compareTo(a.date));
    for (final e in sorted) {
      final status = e.isNormal
          ? 'Normal'
          : e.isHigh
              ? 'High'
              : e.isLow
                  ? 'Low'
                  : '';
      rows.add([
        e.date.toIso8601String().split('T').first,
        e.biomarkerName,
        e.biomarkerCategory,
        e.value,
        e.unit,
        e.refRangeLow ?? '',
        e.refRangeHigh ?? '',
        status,
        e.notes ?? '',
      ].map(_csv).join(','));
    }

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().split('T').first;
    final file = File('${dir.path}/lablio_export_$stamp.csv');
    await file.writeAsString(rows.join('\n'));

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Lablio data export',
        text: 'My Lablio biomarker data ($stamp)',
      ),
    );
  }

  /// Permanently deletes the account via the `delete-account` Edge Function.
  /// The user's access token is attached automatically by the SDK.
  Future<void> deleteAccount() async {
    final res = await _client.functions.invoke('delete-account');
    if (res.status != 200) {
      final data = res.data;
      final msg = data is Map && data['error'] != null
          ? data['error'].toString()
          : 'Failed to delete account (status ${res.status})';
      throw Exception(msg);
    }
  }
}
