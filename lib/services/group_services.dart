// ============================================
// FILE: lib/services/group_service.dart
// Group Service - Supabase Integration
// ============================================

import 'package:fairshare/model/group.dart';
import 'package:fairshare/services/supabase_service.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupService {
  final _supabase = Supabase.instance.client;
  final _supabaseService = SupabaseService();

  // --- Cache Storage ---
  // My Groups Cache (List of Groups)
  // 5 minute TTL
  static _CacheEntry<List<Group>>? _myGroupsCache;
  static const Duration _cacheTTL = Duration(minutes: 5);

  /// Get current user ID
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ============================================
  // GET GROUPS
  // ============================================

  /// Get all groups for the current user
  /// [forceRefresh] if true, bypasses the cache and fetches from DB
  Future<List<Group>> getMyGroups({bool forceRefresh = false}) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check Cache (Skip if forceRefresh is true)
      if (!forceRefresh &&
          _myGroupsCache != null &&
          DateTime.now().difference(_myGroupsCache!.timestamp) < _cacheTTL) {
        debugPrint('🎯 Groups returned from cache');
        return _myGroupsCache!.data;
      }

      debugPrint('📦 Fetching groups for user: $_currentUserId');

      // Query groups where user is a member
      final response = await _supabase
          .from('group_members')
          .select('groups(*)')
          .eq('user_id', _currentUserId!);

      debugPrint('📦 Groups response: $response');

      // Parse the response
      final List<Group> groups = [];
      for (var item in response) {
        if (item['groups'] != null) {
          groups.add(Group.fromJson(item['groups']));
        }
      }

      debugPrint('✅ Found ${groups.length} groups');

      // Cache the result
      _myGroupsCache = _CacheEntry(data: groups, timestamp: DateTime.now());

      return groups;
    } on PostgrestException catch (e) {
      debugPrint('❌ Database error fetching groups: ${e.message} (${e.code})');
      throw Exception('Failed to load groups: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error fetching groups: $e');
      rethrow;
    }
  }

  /// Get a single group by ID
  Future<Group> getGroupById(String groupId) async {
    try {
      debugPrint('🔍 Fetching group: $groupId');

      final response = await _supabase
          .from('groups')
          .select()
          .eq('id', groupId)
          .single();

      debugPrint('✅ Group found: ${response['name']}');
      return Group.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('❌ Database error fetching group: ${e.message} (${e.code})');
      throw Exception('Failed to load group: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error fetching group: $e');
      rethrow;
    }
  }

  // ============================================
  // CREATE GROUP
  // ============================================

  /// Create a new group (Simple version without additional members)
  Future<Group> createGroup({required String name, String? description}) async {
    return createGroupWithMembers(
      name: name,
      description: description,
      memberIds: [],
    );
  }

  /// Create a new group with initial members
  Future<Group> createGroupWithMembers({
    required String name,
    String? description,
    required List<String> memberIds,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated. Please log in.');
      }

      debugPrint('🚀 Starting group creation: $name');
      debugPrint('📋 Additional members: ${memberIds.length}');

      // CRITICAL: Ensure user profile exists BEFORE creating group
      await _ensureProfileExists();

      final now = DateTime.now();

      // 1. Create the group
      debugPrint('📝 Creating group in database...');
      final groupResponse = await _supabase
          .from('groups')
          .insert({
            'name': name,
            'description': description,
            'created_by': _currentUserId,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .select()
          .single();

      final newGroup = Group.fromJson(groupResponse);
      debugPrint('✅ Group created: ${newGroup.id}');

      // 2. Verify creator was added as admin by trigger
      // If not, add them manually (defensive programming)
      await _ensureCreatorIsAdmin(newGroup.id, now);

      // 3. Add other members (if any)
      if (memberIds.isNotEmpty) {
        await _addInitialMembers(newGroup.id, memberIds, now);
      }

      debugPrint('✅ Group creation complete: ${newGroup.name}');

      // Invalidate cache so new group shows up
      _invalidateCache();

      return newGroup;
    } on PostgrestException catch (e) {
      debugPrint('❌ Database error creating group: ${e.message} (${e.code})');

      // Handle specific error codes
      if (e.code == '23503') {
        throw Exception(
          'Failed to create group: User profile is missing. '
          'Please log out and back in.',
        );
      } else if (e.code == '42501') {
        throw Exception(
          'Permission denied. Please log out and back in to refresh your session.',
        );
      } else {
        throw Exception('Failed to create group: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Error creating group: $e');
      rethrow;
    }
  }

  /// Ensure creator is added as admin (defensive check)
  Future<void> _ensureCreatorIsAdmin(String groupId, DateTime now) async {
    try {
      debugPrint('🔍 Verifying creator is admin...');

      // Check if creator is already a member
      final existingMember = await _supabase
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', _currentUserId!)
          .maybeSingle();

      if (existingMember != null) {
        debugPrint('✅ Creator already added as admin by trigger');
        return;
      }

      // If not, add them manually (trigger might have failed)
      debugPrint('⚠️ Creator not found, adding manually...');
      await _supabase.from('group_members').insert({
        'group_id': groupId,
        'user_id': _currentUserId,
        'role': 'admin',
        'joined_at': now.toIso8601String(),
      });

      debugPrint('✅ Creator added as admin manually');
    } catch (e) {
      debugPrint('⚠️ Error verifying creator membership: $e');
      // Don't throw - this is a defensive check
    }
  }

  /// Add initial members to the group
  Future<void> _addInitialMembers(
    String groupId,
    List<String> memberIds,
    DateTime now,
  ) async {
    try {
      debugPrint('👥 Adding ${memberIds.length} initial members...');

      // Filter out creator (already admin)
      final validMemberIds = memberIds
          .where((uid) => uid != _currentUserId)
          .toList();

      if (validMemberIds.isEmpty) {
        debugPrint('⏭️ No additional members to add');
        return;
      }

      // Prepare batch data
      final membersData = validMemberIds
          .map(
            (uid) => {
              'group_id': groupId,
              'user_id': uid,
              'role': 'member',
              'joined_at': now.toIso8601String(),
            },
          )
          .toList();

      // Batch insert
      await _supabase.from('group_members').insert(membersData);

      debugPrint('✅ Added ${validMemberIds.length} members in batch');
    } catch (e) {
      debugPrint('⚠️ Error adding initial members: $e');
      // Don't throw - group is already created
    }
  }

  // ============================================
  // PROFILE VERIFICATION
  // ============================================

  /// Ensure the current user has a profile in the public.profiles table
  /// This is critical for foreign key constraints to work
  Future<void> _ensureProfileExists({int maxRetries = 2}) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        attempts++;

        // Validate user is authenticated
        if (_currentUserId == null) {
          throw Exception('User not authenticated. Please log in.');
        }

        debugPrint(
          '🔍 Checking profile exists (attempt $attempts/$maxRetries)...',
        );

        // Check if profile exists
        final profile = await _supabaseService.getUserProfile(_currentUserId!);

        if (profile != null) {
          debugPrint('✅ Profile exists for $_currentUserId');
          return; // Success - profile exists
        }

        // Profile doesn't exist - create it
        debugPrint('⚠️ Profile missing. Creating profile...');

        final user = _supabase.auth.currentUser;
        if (user == null) {
          throw Exception('User session expired. Please log in again.');
        }

        // Extract user data with fallbacks
        final metadata = user.userMetadata ?? {};
        final email = user.email ?? '';
        final fullName = _extractFullName(metadata, email);
        final avatarUrl =
            metadata['avatar_url'] as String? ?? metadata['picture'] as String?;

        // Create profile
        await _supabaseService.upsertUserProfile(
          userId: _currentUserId!,
          email: email,
          fullName: fullName,
          avatarUrl: avatarUrl,
        );

        debugPrint('⏳ Waiting for profile to be created...');
        await Future.delayed(const Duration(milliseconds: 500));

        // Verify profile was created
        final verifyProfile = await _supabaseService.getUserProfile(
          _currentUserId!,
        );
        if (verifyProfile != null) {
          debugPrint('✅ Profile created and verified for $_currentUserId');
          return; // Success
        }

        // Profile still doesn't exist after creation
        if (attempts >= maxRetries) {
          throw Exception(
            'Profile creation succeeded but could not be verified. '
            'Please try logging out and back in.',
          );
        }

        debugPrint('⚠️ Profile not found after creation, retrying...');
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      } on PostgrestException catch (e) {
        debugPrint(
          '❌ Database error (attempt $attempts): ${e.message} (${e.code})',
        );

        // Don't retry on permission errors
        if (e.code == '42501') {
          throw Exception(
            'Permission denied while creating profile. '
            'Please log out and back in to refresh your session.',
          );
        }

        // Don't retry if profile already exists
        if (e.code == '23505') {
          debugPrint('⚠️ Profile already exists, continuing...');
          return;
        }

        // Retry on other errors
        if (attempts >= maxRetries) {
          throw Exception(
            'Database error after $maxRetries attempts: ${e.message}',
          );
        }

        await Future.delayed(Duration(seconds: attempts));
      } catch (e) {
        debugPrint('❌ Error ensuring profile (attempt $attempts): $e');

        if (attempts >= maxRetries) {
          throw Exception(
            'Failed to ensure profile exists after $maxRetries attempts. '
            'Please try logging out and back in. Error: $e',
          );
        }

        await Future.delayed(Duration(seconds: attempts));
      }
    }

    throw Exception(
      'Failed to ensure profile exists after $maxRetries attempts. '
      'Please try logging out and back in.',
    );
  }

  /// Helper method to extract full name with fallbacks
  String _extractFullName(Map<String, dynamic> metadata, String email) {
    // Try metadata fields
    String? name =
        metadata['full_name'] as String? ?? metadata['name'] as String?;

    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }

    // Fallback to email username
    if (email.isNotEmpty && email.contains('@')) {
      final username = email.split('@').first;
      if (username.isNotEmpty) {
        // Capitalize first letter
        return username[0].toUpperCase() + username.substring(1);
      }
    }

    // Last resort
    return 'User';
  }

  // ============================================
  // UPDATE GROUP
  // ============================================

  /// Update group details
  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? description,
  }) async {
    try {
      debugPrint('📝 Updating group: $groupId');

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('groups').update(updateData).eq('id', groupId);

      await _supabase.from('groups').update(updateData).eq('id', groupId);

      debugPrint('✅ Group updated: $groupId');

      // Invalidate cache to reflect changes
      _invalidateCache();
    } on PostgrestException catch (e) {
      debugPrint('❌ Database error updating group: ${e.message} (${e.code})');

      if (e.code == '42501') {
        throw Exception('Permission denied. Only admins can update groups.');
      } else {
        throw Exception('Failed to update group: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Error updating group: $e');
      rethrow;
    }
  }

  // ============================================
  // DELETE GROUP
  // ============================================

  /// Check if the group can be deleted
  Future<Map<String, dynamic>> checkDeletionEligibility(String groupId) async {
    try {
      final response = await _supabase.rpc(
        'check_deletion_eligibility',
        params: {'p_group_id': groupId},
      );
      
      return Map<String, dynamic>.from(response ?? {});
    } catch (e) {
      debugPrint('Error checking deletion eligibility: $e');
      return {
        'allowed': false,
        'reason': 'Failed to verify eligibility. Please try again.',
      };
    }
  }

  /// Delete a group
  Future<void> deleteGroup(String groupId) async {
    try {
      debugPrint('🗑️ Deleting group: $groupId');

      // 1. Check Eligibility (Safe Delete)
      final eligibilityResponse = await _supabase.rpc(
        'check_deletion_eligibility',
        params: {'p_group_id': groupId},
      );

      // Handle null response gracefully
      if (eligibilityResponse == null) {
        // Fallback: assume allowed? Or block? Better block safely.
        throw Exception('Could not verify deletion eligibility.');
      }

      final eligibility = Map<String, dynamic>.from(eligibilityResponse);

      if (eligibility['allowed'] != true) {
        throw Exception(eligibility['reason'] ?? 'Cannot delete group due to existing restrictions.');
      }

      // 2. Proceed with Delete
      // Note: Members are automatically deleted via CASCADE
      // Just delete the group
      await _supabase.from('groups').delete().eq('id', groupId);

      debugPrint('✅ Group deleted: $groupId');

      // Invalidate cache
      _invalidateCache();
    } on PostgrestException catch (e) {
      debugPrint('❌ Database error deleting group: ${e.message} (${e.code})');

      if (e.code == '42501') {
        throw Exception('Permission denied. Only admins can delete groups.');
      } else {
        throw Exception('Failed to delete group: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Error deleting group: $e');
      rethrow;
    }
  }

  // ============================================
  // MEMBER MANAGEMENT
  // ============================================

  /// Get all members of a group with profile details
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    try {
      debugPrint('👥 Fetching members for group: $groupId');

      final response = await _supabase
          .from('group_members')
          .select('*, profiles(*)')
          .eq('group_id', groupId);

      debugPrint('✅ Found ${response.length} members');
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      debugPrint('❌ Database error fetching members: ${e.message} (${e.code})');
      throw Exception('Failed to load group members: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error fetching members: $e');
      rethrow;
    }
  }

  /// Check if the current user can leave the group
  Future<Map<String, dynamic>> checkExitEligibility(String groupId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase.rpc(
        'check_exit_eligibility',
        params: {'p_group_id': groupId, 'p_user_id': userId},
      );

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error checking exit eligibility: $e');
      // Default to allowing exit if check fails, or maybe blocking safely?
      // Let's safe fail to block and ask to try again.
      return {
        'allowed': false,
        'reason': 'Failed to verify eligibility. Please try again.',
      };
    }
  }

  /// Leave a group (for current user)
  // Future<void> leaveGroup(String groupId) async {
  //   try {
  //     final userId = _supabase.auth.currentUser?.id;
  //     if (userId == null) throw Exception('User not authenticated');

  //     await removeMember(groupId: groupId, userId: userId);
  //   } catch (e) {
  //     debugPrint('Error leaving group: $e');
  //     rethrow;
  //   }
  // }

  /// Add a member to a group by email
  Future<void> addMemberByEmail({
    required String groupId,
    required String email,
    String role = 'member',
  }) async {
    try {
      debugPrint('➕ Adding member by email: $email');

      // 1. Find user by email
      final userResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('No user found with email: $email');
      }

      final userId = userResponse['id'] as String;

      // 2. Add member to group (Upsert to avoid duplicates)
      await _supabase.from('group_members').upsert({
        'group_id': groupId,
        'user_id': userId,
        'role': role,
        'joined_at': DateTime.now().toIso8601String(),
      }, onConflict: 'group_id, user_id');

      debugPrint('✅ Member added: $email');
    } on PostgrestException catch (e) {
      debugPrint('❌ Database error adding member: ${e.message} (${e.code})');

      if (e.code == '42501') {
        throw Exception('Permission denied. Only admins can add members.');
      } else if (e.code == '23503') {
        throw Exception('User not found with email: $email');
      } else {
        throw Exception('Failed to add member: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Error adding member: $e');
      rethrow;
    }
  }

  /// Remove a member from a group
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      debugPrint('➖ Removing member: $userId from group: $groupId');

      await _supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);

      debugPrint('✅ Member removed');
    } on PostgrestException catch (e) {
      debugPrint('❌ Database error removing member: ${e.message} (${e.code})');

      if (e.code == '42501') {
        throw Exception('Permission denied. Only admins can remove members.');
      } else {
        throw Exception('Failed to remove member: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Error removing member: $e');
      rethrow;
    }
  }

  /// Update a member's role
  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required String newRole,
  }) async {
    try {
      debugPrint('🔄 Updating member role: $userId to $newRole');

      if (!['admin', 'member'].contains(newRole)) {
        throw Exception('Invalid role. Must be "admin" or "member".');
      }

      await _supabase
          .from('group_members')
          .update({'role': newRole})
          .eq('group_id', groupId)
          .eq('user_id', userId);

      debugPrint('✅ Member role updated');
    } on PostgrestException catch (e) {
      debugPrint('❌ Database error updating role: ${e.message} (${e.code})');

      if (e.code == '42501') {
        throw Exception('Permission denied. Only admins can update roles.');
      } else {
        throw Exception('Failed to update member role: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Error updating member role: $e');
      rethrow;
    }
  }

  /// Leave a group (remove yourself)
  Future<void> leaveGroup(String groupId) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🚪 Leaving group: $groupId');

      // Check if user is the last admin
      final admins = await _supabase
          .from('group_members')
          .select('user_id')
          .eq('group_id', groupId)
          .eq('role', 'admin');

      if (admins.length == 1 && admins.first['user_id'] == _currentUserId) {
        throw Exception(
          'Cannot leave group. You are the only admin. '
          'Please promote another member to admin first or delete the group.',
        );
      }

      // Remove yourself from the group
      await removeMember(groupId: groupId, userId: _currentUserId!);

      debugPrint('✅ Left group successfully');

      // Invalidate cache
      _invalidateCache();
    } catch (e) {
      debugPrint('❌ Error leaving group: $e');
      rethrow;
    }
  }
  // ============================================
  // FRIENDS / KNOWN MEMBERS
  // ============================================

  /// Get all unique members from all groups the user is part of
  Future<List<Map<String, dynamic>>> getAllKnownMembers() async {
    try {
      if (_currentUserId == null) throw Exception('User not authenticated');

      // 1. Get all group IDs the user is part of
      final myGroupsResponse = await _supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', _currentUserId!);

      final groupIds = (myGroupsResponse as List)
          .map((e) => e['group_id'] as String)
          .toList();

      if (groupIds.isEmpty) return [];

      // 2. Get all members of these groups
      final membersResponse = await _supabase
          .from('group_members')
          .select('*, profiles(*)')
          .filter(
            'group_id',
            'in',
            '(${groupIds.map((id) => '"$id"').join(',')})',
          );

      // 3. Filter out current user and duplicates
      final Map<String, Map<String, dynamic>> uniqueMembers = {};

      for (var member in membersResponse) {
        final userId = member['user_id'] as String;
        if (userId != _currentUserId) {
          // Store valid profile data if available
          if (member['profiles'] != null) {
            uniqueMembers[userId] = member;
          }
        }
      }

      return uniqueMembers.values.toList();
    } catch (e) {
      debugPrint('Error fetching known members: $e');
      throw Exception('Failed to load friends');
    }
  }

  /// Find or create a group with specific members
  Future<Group> findOrCreateGroupWithMembers(List<String> memberIds) async {
    // For now, simpler approach: Create a new group with these members
    // Naming it based on members or date
    final memberProfiles = await _supabase
        .from('profiles')
        .select('full_name')
        .filter('id', 'in', '(${memberIds.map((id) => '"$id"').join(',')})')
        .limit(3);

    String groupName = "Split with ";
    final names = (memberProfiles as List)
        .map((p) => p['full_name'] as String? ?? 'User')
        .toList();

    if (names.isNotEmpty) {
      groupName += names.join(', ');
      if (memberIds.length > names.length) groupName += '...';
    } else {
      groupName += "Friends";
    }

    // TODO: Ideally check if such a group exists perfectly.
    // For this MVP, we create a new one to ensure isolation of this expense event
    // or we could potentially search.

    return createGroupWithMembers(name: groupName, memberIds: memberIds);
  }

  /// Helper to invalidate cache
  void _invalidateCache() {
    _myGroupsCache = null;
    debugPrint('🧹 My Groups cache invalidated');
  }
}

// Simple Cache Entry Wrapper (Private to file)
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry({required this.data, required this.timestamp});
}
