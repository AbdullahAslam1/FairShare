import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fairshare/model/user_model.dart';

/// Service class to handle all profile-related operations
class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user's profile
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user');
        return null;
      }

      debugPrint('📋 Fetching profile for user: ${user.id}');

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        debugPrint('❌ No profile found for user: ${user.id}');
        return null;
      }

      debugPrint('✅ Profile fetched successfully');
      return UserProfile.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('❌ Database error in getCurrentUserProfile: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected error in getCurrentUserProfile: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      debugPrint('💾 Updating profile for user: $userId');

      final data = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) data['full_name'] = fullName;
      if (phone != null) data['phone'] = phone;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;

      await _supabase.from('profiles').update(data).eq('id', userId);

      debugPrint('✅ Profile updated successfully');
    } on PostgrestException catch (e) {
      debugPrint('❌ Database error in updateProfile: ${e.message}');
      throw Exception('Failed to update profile: ${e.message}');
    } catch (e) {
      debugPrint('❌ Unexpected error in updateProfile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Upload avatar image
  /// Returns the public URL of the uploaded image
  Future<String> uploadAvatar(String userId, String filePath) async {
    try {
      debugPrint('📤 Uploading avatar for user: $userId');

      final fileName =
          'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'avatars/$fileName';

      // Upload file to Supabase storage
      await _supabase.storage
          .from('profiles')
          .upload(
            path,
            filePath as File,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get public URL
      final publicUrl = _supabase.storage.from('profiles').getPublicUrl(path);

      debugPrint('✅ Avatar uploaded successfully: $publicUrl');
      return publicUrl;
    } on StorageException catch (e) {
      debugPrint('❌ Storage error in uploadAvatar: ${e.message}');
      throw Exception('Failed to upload avatar: ${e.message}');
    } catch (e) {
      debugPrint('❌ Unexpected error in uploadAvatar: $e');
      throw Exception('Failed to upload avatar: $e');
    }
  }

  /// Delete old avatar from storage
  Future<void> deleteAvatar(String avatarUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(avatarUrl);
      final path = uri.pathSegments.last;

      await _supabase.storage.from('profiles').remove(['avatars/$path']);

      debugPrint('✅ Old avatar deleted successfully');
    } catch (e) {
      debugPrint('⚠️ Failed to delete old avatar: $e');
      // Don't throw error, just log it
    }
  }

  /// Get user statistics (for profile display)
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      debugPrint('📊 Fetching statistics for user: $userId');

      // Get total groups
      final groupsResponse = await _supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      final totalGroups = groupsResponse.length;

      // Get total expenses
      final expensesResponse = await _supabase
          .from('expenses')
          .select('id')
          .eq('paid_by', userId);

      final totalExpenses = expensesResponse.length;

      // Get total friends (unique users in same groups)
      final friendsResponse = await _supabase
          .from('group_members')
          .select('user_id')
          .neq('user_id', userId)
          .inFilter(
            'group_id',
            groupsResponse.map((g) => g['group_id']).toList(),
          );

      final uniqueFriends = friendsResponse
          .map((f) => f['user_id'])
          .toSet()
          .length;

      debugPrint(
        '✅ Statistics fetched: Groups=$totalGroups, Expenses=$totalExpenses, Friends=$uniqueFriends',
      );

      return {
        'totalGroups': totalGroups,
        'totalExpenses': totalExpenses,
        'totalFriends': uniqueFriends,
      };
    } catch (e) {
      debugPrint('❌ Error fetching statistics: $e');
      return {'totalGroups': 0, 'totalExpenses': 0, 'totalFriends': 0};
    }
  }

  /// Change user password
  Future<void> changePassword(String newPassword) async {
    try {
      debugPrint('🔒 Changing user password');

      await _supabase.auth.updateUser(UserAttributes(password: newPassword));

      debugPrint('✅ Password changed successfully');
    } on AuthException catch (e) {
      debugPrint('❌ Auth error in changePassword: ${e.message}');
      throw Exception('Failed to change password: ${e.message}');
    } catch (e) {
      debugPrint('❌ Unexpected error in changePassword: $e');
      throw Exception('Failed to change password: $e');
    }
  }
}
