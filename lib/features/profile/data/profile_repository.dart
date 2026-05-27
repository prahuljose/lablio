import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_model.dart';

class ProfileRepository {
  final SupabaseClient _client;
  static const _table = 'profiles';
  static const _avatarBucket = 'avatars';

  ProfileRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<ProfileModel?> fetch() async {
    final data =
        await _client.from(_table).select().eq('id', _userId).maybeSingle();
    if (data == null) return null;
    return ProfileModel.fromMap(data);
  }

  Future<ProfileModel> update(ProfileModel profile) async {
    final result = await _client
        .from(_table)
        .update(profile.toUpdateMap())
        .eq('id', _userId)
        .select()
        .single();
    return ProfileModel.fromMap(result);
  }

  /// Uploads a new avatar image, stores a long-lived signed URL on the
  /// profile row, and returns the updated profile.
  Future<ProfileModel> uploadAvatar(File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    final path = '$_userId/avatar.$ext';

    await _client.storage.from(_avatarBucket).upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    // Private bucket → signed URL valid for ~10 years (Supabase max).
    final signedUrl = await _client.storage
        .from(_avatarBucket)
        .createSignedUrl(path, 60 * 60 * 24 * 365 * 10);

    final result = await _client
        .from(_table)
        .update({'avatar_url': signedUrl, 'avatar_path': path})
        .eq('id', _userId)
        .select()
        .single();
    return ProfileModel.fromMap(result);
  }
}
