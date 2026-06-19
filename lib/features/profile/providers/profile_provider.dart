import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/profile_model.dart';
import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider(
  (ref) => ProfileRepository(Supabase.instance.client),
);

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, ProfileModel?>(ProfileNotifier.new);

class ProfileNotifier extends AsyncNotifier<ProfileModel?> {
  @override
  Future<ProfileModel?> build() => ref.read(profileRepositoryProvider).fetch();

  Future<void> save(ProfileModel profile) async {
    final updated = await ref.read(profileRepositoryProvider).update(profile);
    state = AsyncData(updated);
  }

  Future<void> uploadAvatar(File file) async {
    final updated =
        await ref.read(profileRepositoryProvider).uploadAvatar(file);
    state = AsyncData(updated);
  }

  Future<void> refresh() async {
    try {
      final data = await ref.read(profileRepositoryProvider).fetch();
      state = AsyncData(data);
    } catch (e, st) {
      // Keep cached profile visible on a failed refresh; rethrow to warn.
      if (state.valueOrNull == null) state = AsyncError(e, st);
      rethrow;
    }
  }
}
