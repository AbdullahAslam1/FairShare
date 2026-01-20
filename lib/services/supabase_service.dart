import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class to handle all Supabase authentication operations
class SupabaseService {
  // Get the Supabase client instance
  final SupabaseClient _supabase = Supabase.instance.client;

  // Getter for auth client
  GoTrueClient get auth => _supabase.auth;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Sign up with email and password
  /// Returns the AuthResponse which contains user data
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
        emailRedirectTo: kIsWeb
            ? 'http://localhost:3000/auth/callback'
            : 'com.example.fairshare://auth-callback',
      );

      return response;
    } on AuthException catch (e) {
      throw Exception('Sign up failed: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred during sign up');
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response;
    } on AuthException catch (e) {
      // Check if the error is related to email not being confirmed
      if (e.message?.toLowerCase().contains('email not confirmed') ?? false) {
        throw Exception(
          'Please verify your email before signing in. Check your inbox for the verification link.',
        );
      }
      throw Exception('Sign in failed: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with Google OAuth
  Future<bool> signInWithGoogle() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb
            ? 'http://localhost:3000/auth/callback'
            : 'com.example.fairshare://auth-callback',
      );

      return response;
    } on AuthException catch (e) {
      throw Exception('Google sign in failed: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred during Google sign in');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw Exception('Sign out failed: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred during sign out');
    }
  }

  /// Resend verification email
  Future<void> resendVerificationEmail(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: kIsWeb
            ? 'http://localhost:3000/auth/callback'
            : 'com.example.fairshare://auth-callback',
      );
    } on AuthException catch (e) {
      throw Exception('Failed to resend verification email: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred while resending email');
    }
  }

  /// Check if user's email is verified
  bool isEmailVerified() {
    final user = currentUser;
    if (user == null) return false;
    return user.emailConfirmedAt != null;
  }

  /// Refresh the current session to get updated user data
  Future<void> refreshSession() async {
    try {
      await _supabase.auth.refreshSession();
    } catch (e) {
      throw Exception('Failed to refresh session: $e');
    }
  }

  // ============================================
  // PROFILE METHODS - UPDATED
  // ============================================

  /// Get user profile by user ID
  /// Returns null if profile doesn't exist
  /// Throws exception on database errors
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      debugPrint(
        '📋 getUserProfile($userId): ${response != null ? "Found" : "Not found"}',
      );
      return response;
    } on PostgrestException catch (e) {
      debugPrint(
        '❌ Database error in getUserProfile: ${e.message} (${e.code})',
      );

      // If it's a "row not found" or similar, return null
      if (e.code == 'PGRST116' || e.code == '22P02') {
        return null;
      }

      // Otherwise, rethrow to let caller handle
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected error in getUserProfile: $e');
      rethrow;
    }
  }

  /// Get user profile by email address
  /// Returns null if user not found
  /// Throws exception on database errors
  Future<Map<String, dynamic>?> getUserProfileByEmail(String email) async {
    try {
      final cleanEmail = email.toLowerCase().trim();

      debugPrint('🔍 Searching for user with email: $cleanEmail');

      final response = await _supabase
          .from('profiles')
          .select('id, email, full_name, avatar_url, phone, created_at')
          .eq('email', cleanEmail)
          .maybeSingle();

      if (response != null) {
        debugPrint('✅ User found: ${response['email']} (${response['id']})');
        return response;
      }

      debugPrint('❌ No user found with email: $cleanEmail');
      return null;
    } on PostgrestException catch (e) {
      debugPrint(
        '❌ Database error in getUserProfileByEmail: ${e.message} (${e.code})',
      );

      // If it's a "row not found", return null
      if (e.code == 'PGRST116') {
        return null;
      }

      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected error in getUserProfileByEmail: $e');
      rethrow;
    }
  }

  /// Search users by email pattern (for autocomplete/search)
  /// Returns list of matching users
  Future<List<Map<String, dynamic>>> searchUsersByEmail(String query) async {
    try {
      final cleanQuery = query.toLowerCase().trim();

      if (cleanQuery.isEmpty) {
        return [];
      }

      debugPrint('🔍 Searching users with query: $cleanQuery');

      final response = await _supabase
          .from('profiles')
          .select('id, email, full_name, avatar_url')
          .ilike('email', '%$cleanQuery%')
          .limit(10);

      debugPrint('✅ Found ${response.length} matching users');
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      debugPrint(
        '❌ Database error in searchUsersByEmail: ${e.message} (${e.code})',
      );
      return [];
    } catch (e) {
      debugPrint('❌ Unexpected error in searchUsersByEmail: $e');
      return [];
    }
  }

  /// Create or update user profile
  /// Uses upsert to handle both insert and update cases
  Future<void> upsertUserProfile({
    required String userId,
    required String email,
    required String fullName,
    String? avatarUrl,
    String? phone,
  }) async {
    try {
      debugPrint('💾 Upserting profile for $userId...');

      final data = {
        'id': userId,
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'phone': phone,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Remove null values
      data.removeWhere((key, value) => value == null);

      await _supabase.from('profiles').upsert(data, onConflict: 'id');

      debugPrint('✅ Profile upserted successfully for $userId');
    } on PostgrestException catch (e) {
      debugPrint(
        '❌ Database error in upsertUserProfile: ${e.message} (${e.code})',
      );

      // Provide helpful error messages
      if (e.code == '42501') {
        throw Exception('Permission denied. Please log out and back in.');
      } else if (e.code == '23505') {
        throw Exception('Profile already exists with this email.');
      } else {
        throw Exception('Failed to save profile: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Unexpected error in upsertUserProfile: $e');
      throw Exception('Failed to save profile: $e');
    }
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Reset password - send reset link to email
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb
            ? 'http://localhost:3000/auth/callback?type=recovery'
            : 'com.example.fairshare://auth-callback?type=recovery',
      );
    } on AuthException catch (e) {
      throw Exception('Failed to send reset password email: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  /// Update user password (when user is already authenticated)
  Future<void> updatePassword(String newPassword) async { 
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw Exception('Failed to update password: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  // ============================================
  // DEPRECATED METHODS (kept for backward compatibility)
  // ============================================

  /// Check if a user exists by uid
  @Deprecated('Use getUserProfile() instead')
  Future<Map<String, dynamic>?> getUserById(String uid) async {
    return getUserProfile(uid);
  }

  /// Validate if user exists in database by email
  @Deprecated('Use getUserProfileByEmail() instead')
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    return getUserProfileByEmail(email);
  }

  /// DEBUG: Check what profiles exist in the database
  Future<void> debugListAllProfiles() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, email, full_name, created_at')
          .order('created_at', ascending: false)
          .limit(10);

      debugPrint('📋 === ALL PROFILES IN DATABASE ===');
      for (var profile in response) {
        debugPrint('  - Email: ${profile['email']}');
        debugPrint('    ID: ${profile['id']}');
        debugPrint('    Name: ${profile['full_name']}');
        debugPrint('    Created: ${profile['created_at']}');
        debugPrint('  ---');
      }
      debugPrint('📋 === END OF PROFILES (showing last 10) ===');
    } catch (e) {
      debugPrint('❌ Error listing profiles: $e');
    }
  }

  /// Enhanced getUserByEmail with better debugging
  @Deprecated('Use getUserProfileByEmail() with debugListAllProfiles() instead')
  Future<Map<String, dynamic>?> getUserByEmailEnhanced(String email) async {
    await debugListAllProfiles();
    return getUserProfileByEmail(email);
  }

  /// RPC method to validate email (if you have the RPC function set up)
  Future<Map<String, dynamic>?> validateEmailRPC(String email) async {
    try {
      final cleanEmail = email.toLowerCase().trim();

      debugPrint("🔍 RPC validating email: $cleanEmail");

      final response = await _supabase
          .rpc('check_user_by_email', params: {'target_email': cleanEmail})
          .maybeSingle();

      if (response != null) {
        debugPrint("✅ RPC FOUND USER: ${response['email']}");
        return {
          'id': response['id'],
          'email': response['email'],
          'full_name': response['full_name'],
          'avatar_url': response['avatar_url'],
        };
      }

      debugPrint("❌ RPC: No user found");
      return null;
    } catch (e) {
      debugPrint("❌ RPC ERROR: $e");
      return null;
    }
  }
}
