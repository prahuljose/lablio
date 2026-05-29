import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/medical_record_model.dart';
import '../data/medical_record_repository.dart';

final medicalRecordRepositoryProvider = Provider(
  (ref) => MedicalRecordRepository(Supabase.instance.client),
);

final medicalRecordProvider =
    AsyncNotifierProvider<MedicalRecordNotifier, List<MedicalRecordEntry>>(
  MedicalRecordNotifier.new,
);

class MedicalRecordNotifier extends AsyncNotifier<List<MedicalRecordEntry>> {
  @override
  Future<List<MedicalRecordEntry>> build() =>
      ref.read(medicalRecordRepositoryProvider).fetchAll();

  Future<void> add(MedicalRecordEntry entry) async {
    final saved =
        await ref.read(medicalRecordRepositoryProvider).create(entry);
    state = AsyncData([saved, ...state.value ?? []]);
  }

  Future<void> remove(String id) async {
    await ref.read(medicalRecordRepositoryProvider).delete(id);
    state = AsyncData((state.value ?? []).where((e) => e.id != id).toList());
  }
}
