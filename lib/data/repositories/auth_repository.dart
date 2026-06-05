import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';

class AuthRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'https://focusforge-confirmemail.netlify.app/', // ← YEH ADD KAR
      data: {'full_name': name},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Sends a password reset email via Supabase.
  Future<void> resetPassword({required String email}) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'https://focusforge-resetpassword.netlify.app',
    );
  }

  User? get currentUser => _client.auth.currentUser;
}