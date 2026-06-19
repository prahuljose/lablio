import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/report_model.dart';
import '../data/reports_repository.dart';

final reportsRepositoryProvider = Provider(
  (ref) => ReportsRepository(Supabase.instance.client),
);

final reportsProvider =
    AsyncNotifierProvider<ReportsNotifier, List<ReportModel>>(
  ReportsNotifier.new,
);

class ReportsNotifier extends AsyncNotifier<List<ReportModel>> {
  @override
  Future<List<ReportModel>> build() =>
      ref.read(reportsRepositoryProvider).fetchAll();

  Future<void> add({
    required String title,
    required DateTime date,
    String? notes,
    File? pdfFile,
  }) async {
    final repo = ref.read(reportsRepositoryProvider);
    final newReport = await repo.create(
      title: title,
      date: date,
      notes: notes,
      pdfFile: pdfFile,
    );
    state = AsyncData([newReport, ...state.value ?? []]);
  }

  Future<void> remove(String reportId, {String? pdfPath}) async {
    await ref.read(reportsRepositoryProvider).delete(reportId, pdfPath: pdfPath);
    state = AsyncData(
      (state.value ?? []).where((r) => r.id != reportId).toList(),
    );
  }

  Future<void> refresh() async {
    try {
      final data = await ref.read(reportsRepositoryProvider).fetchAll();
      state = AsyncData(data);
    } catch (e, st) {
      // Keep cached data visible on a failed refresh; rethrow to warn.
      if (state.valueOrNull == null) state = AsyncError(e, st);
      rethrow;
    }
  }
}
