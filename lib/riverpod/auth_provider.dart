import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fairshare/services/supabase_service.dart';
import 'dart:async';

/// User profile model
class UserProfile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Authentication state
class AuthState {
  final User? user;
  final UserProfile? profile;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final bool isEmailVerified;

  AuthState({
    this.user,
    this.profile,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.isEmailVerified = false,
  });

  AuthState copyWith({
    User? user,
    UserProfile? profile,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    bool? isEmailVerified,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}

/// Supabase service provider
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseService _supabaseService;
  StreamSubscription<AuthState>? _authSubscription;

  AuthNotifier(this._supabaseService) : super(AuthState()) {
    _initialize();
  }

  /// Initialize auth state and listen to changes
  Future<void> _initialize() async {
    // Check current session
    final user = _supabaseService.currentUser;
    if (user != null) {
      await _loadUserProfile(user);
    }

    // Listen to auth state changes
    _authSubscription =
        _supabaseService.authStateChanges.listen((authState) async {
              final user = authState.session?.user;

              if (user != null) {
                await _loadUserProfile(user);
              } else {
                state = AuthState(
                  isAuthenticated: false,
                  isEmailVerified: false,
                );
              }
            })
            as StreamSubscription<AuthState>?;
  }

  /// Load user profile from database
  Future<void> _loadUserProfile(User user) async {
    try {
      final profileData = await _supabaseService.getUserProfile(user.id);
      final profile = profileData != null
          ? UserProfile.fromJson(profileData)
          : null;

      state = AuthState(
        user: user,
        profile: profile,
        isAuthenticated: true,
        isEmailVerified: user.emailConfirmedAt != null,
      );
    } catch (e) {
      // If profile doesn't exist, it will be created by the database trigger
      // Just set the user state without profile for now
      print('⚠️ Profile not found (will be created by trigger): $e');

      state = AuthState(
        user: user,
        profile: null,
        isAuthenticated: true,
        isEmailVerified: user.emailConfirmedAt != null,
      );
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _supabaseService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (response.user != null) {
        // CRITICAL FIX: Removed duplicate profile creation
        // The database trigger automatically creates the profile
        // No need to create it here - this was causing RLS violation

        print(
          '✅ Signup successful - profile will be created by database trigger',
        );

        state = state.copyWith(isLoading: false, user: response.user);
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Sign up failed. Please try again.',
      );
      return false;
    } catch (e) {
      print('❌ Signup error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _supabaseService.signInWithEmail(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserProfile(response.user!);
        state = state.copyWith(isLoading: false);
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Sign in failed. Please try again.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final success = await _supabaseService.signInWithGoogle();

      if (success) {
        // Auth state listener will handle the rest
        state = state.copyWith(isLoading: false);
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Google sign in failed. Please try again.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _supabaseService.signOut();
      state = AuthState(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Resend verification email
  Future<bool> resendVerification(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _supabaseService.resendVerificationEmail(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _supabaseService.resetPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return AuthNotifier(supabaseService);
});
