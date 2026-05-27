import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    DateTime? dateOfBirth,
    String? sex,
    double? heightCm,
    double? weightKg,
    String? bloodType,
  }) =>
      _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          if (dateOfBirth != null)
            'date_of_birth':
                dateOfBirth.toIso8601String().split('T').first,
          if (sex != null && sex.isNotEmpty) 'sex': sex,
          if (heightCm != null) 'height_cm': heightCm,
          if (weightKg != null) 'weight_kg': weightKg,
          if (bloodType != null && bloodType.isNotEmpty)
            'blood_type': bloodType,
        },
      );

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _client.auth.signOut();

  Future<void> resetPassword(String email) =>
      _client.auth.resetPasswordForEmail(email);
}
