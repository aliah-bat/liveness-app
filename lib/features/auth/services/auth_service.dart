import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/constants.dart';
import '../models/user_model.dart';

class AuthService {
  SupabaseClient get _supabase => SupabaseService.client;

  // Direct sign up without OTP
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? name,
    String? phone,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
        },
      );

      if (response.user == null) {
        throw Exception('Failed to create user');
      }

      // Create user profile in database
      final userData = {
        'id': response.user!.id,
        'email': email,
        'name': name,
        'phone': phone,
        'is_biometric_enabled': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from(AppConstants.usersTable).insert(userData);

      return UserModel.fromJson(userData);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception(AppConstants.invalidCredentials);
      }

      // Fetch user profile
      final userData = await _supabase
          .from(AppConstants.usersTable)
          .select()
          .eq('id', response.user!.id)
          .single();

      return UserModel.fromJson(userData);
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      final userData = await _supabase
          .from(AppConstants.usersTable)
          .select()
          .eq('id', currentUser.id)
          .single();

      return UserModel.fromJson(userData);
    } catch (e) {
      return null;
    }
  }
}