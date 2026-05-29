import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/biomarker_model.dart';
import '../data/custom_biomarkers_repository.dart';
import 'biomarkers_provider.dart';

final customBiomarkersRepositoryProvider = Provider(
  (ref) => CustomBiomarkersRepository(Supabase.instance.client),
);

final customBiomarkersProvider =
    AsyncNotifierProvider<CustomBiomarkersNotifier, List<BiomarkerModel>>(
  CustomBiomarkersNotifier.new,
);

class CustomBiomarkersNotifier extends AsyncNotifier<List<BiomarkerModel>> {
  @override
  Future<List<BiomarkerModel>> build() =>
      ref.read(customBiomarkersRepositoryProvider).fetchAll();

  Future<BiomarkerModel> add(BiomarkerModel m) async {
    final saved =
        await ref.read(customBiomarkersRepositoryProvider).create(m);
    state = AsyncData([...(state.value ?? []), saved]);
    return saved;
  }

  Future<void> remove(String id) async {
    await ref.read(customBiomarkersRepositoryProvider).delete(id);
    state = AsyncData((state.value ?? []).where((b) => b.id != id).toList());
  }
}

/// Reference biomarkers + the user's own custom ones, merged.
/// Browse / search flows use this so customs appear alongside built-ins.
final allBiomarkersProvider =
    Provider<AsyncValue<List<BiomarkerModel>>>((ref) {
  final reference = ref.watch(referenceBiomarkersProvider);
  final customs = ref.watch(customBiomarkersProvider);
  if (reference.isLoading || customs.isLoading) {
    return const AsyncValue.loading();
  }
  if (reference.hasError) {
    return AsyncValue.error(
        reference.error!, reference.stackTrace ?? StackTrace.current);
  }
  if (customs.hasError) {
    return AsyncValue.error(
        customs.error!, customs.stackTrace ?? StackTrace.current);
  }
  return AsyncValue.data([
    ...reference.value ?? const <BiomarkerModel>[],
    ...customs.value ?? const <BiomarkerModel>[],
  ]);
});
