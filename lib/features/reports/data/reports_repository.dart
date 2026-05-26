import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'report_model.dart';

class ReportsRepository {
  final SupabaseClient _client;
  static const _table = 'reports';
  static const _bucket = 'reports';

  ReportsRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<ReportModel>> fetchAll() async {
    final data = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .order('date', ascending: false);
    return (data as List).map((e) => ReportModel.fromMap(e)).toList();
  }

  Future<ReportModel> create({
    required String title,
    required DateTime date,
    String? notes,
    File? pdfFile,
  }) async {
    String? pdfPath;
    String? pdfUrl;

    if (pdfFile != null) {
      final ext = pdfFile.path.split('.').last;
      pdfPath = '$_userId/${const Uuid().v4()}.$ext';
      await _client.storage.from(_bucket).upload(pdfPath, pdfFile);
      // Bucket is private — signed URL valid for 10 years (max Supabase allows)
      pdfUrl = await _client.storage
          .from(_bucket)
          .createSignedUrl(pdfPath, 60 * 60 * 24 * 365 * 10);
    }

    final model = ReportModel(
      id: '',
      userId: _userId,
      title: title,
      date: date,
      notes: notes,
      pdfUrl: pdfUrl,
      pdfPath: pdfPath,
      createdAt: DateTime.now(),
    );

    final result = await _client
        .from(_table)
        .insert(model.toMap())
        .select()
        .single();
    return ReportModel.fromMap(result);
  }

  Future<void> delete(String reportId, {String? pdfPath}) async {
    if (pdfPath != null) {
      await _client.storage.from(_bucket).remove([pdfPath]);
    }
    await _client.from(_table).delete().eq('id', reportId);
  }
}
