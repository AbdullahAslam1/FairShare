import 'package:fairshare/model/group.dart';
import 'package:fairshare/services/group_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================
// STATE CLASS
// ============================================

class GroupsState {
  final List<Group> groups;
  final bool isLoading;
  final String? error;

  GroupsState({this.groups = const [], this.isLoading = false, this.error});

  GroupsState copyWith({List<Group>? groups, bool? isLoading, String? error}) {
    return GroupsState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ============================================
// STATE NOTIFIER
// ============================================

class GroupsNotifier extends StateNotifier<GroupsState> {
  final GroupService _groupService;

  GroupsNotifier(this._groupService) : super(GroupsState(isLoading: true)) {
    // Auto-load groups on initialization
    loadMyGroups();
    subscribeToRealtime();
  }

  /// Subscribe to Realtime updates for group membership
  void subscribeToRealtime() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    debugPrint('🔌 Subscribing to group updates for user: $userId');

    Supabase.instance.client
        .channel('public:group_members:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'group_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('⚡ Realtime: New group membership detected!');
            loadMyGroups(forceRefresh: true);
          },
        )
        .subscribe();
  }

  /// Load all groups for the current user
  /// [forceRefresh] if true, bypasses in-memory cache
  Future<void> loadMyGroups({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final groups = await _groupService.getMyGroups(forceRefresh: forceRefresh);
      state = state.copyWith(groups: groups, isLoading: false);
      debugPrint('✅ Loaded ${groups.length} groups');
    } catch (e) {
      debugPrint('❌ Error loading groups: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load groups: ${e.toString()}',
      );
    }
  }

  /// Create a new group
  Future<void> createGroup({required String name, String? description}) async {
    try {
      final newGroup = await _groupService.createGroup(
        name: name,
        description: description,
      );

      // Add to the list
      state = state.copyWith(groups: [...state.groups, newGroup]);

      debugPrint('✅ Group created: ${newGroup.name}');
    } catch (e) {
      debugPrint('❌ Error creating group: $e');
      state = state.copyWith(error: 'Failed to create group: ${e.toString()}');
      rethrow;
    }
  }

  /// Update a group
  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? description,
  }) async {
    try {
      await _groupService.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
      );

      // Update in the list
      final updatedGroups = state.groups.map((group) {
        if (group.id == groupId) {
          return Group(
            id: group.id,
            name: name ?? group.name,
            description: description ?? group.description,
            createdBy: group.createdBy,
            createdAt: group.createdAt,
            updatedAt: group.updatedAt,
          );
        }
        return group;
      }).toList();

      state = state.copyWith(groups: updatedGroups);
      debugPrint('✅ Group updated: $groupId');
    } catch (e) {
      debugPrint('❌ Error updating group: $e');
      state = state.copyWith(error: 'Failed to update group: ${e.toString()}');
      rethrow;
    }
  }

  /// Delete a group
  Future<void> deleteGroup(String groupId) async {
    try {
      await _groupService.deleteGroup(groupId);

      // Remove from the list
      final updatedGroups = state.groups
          .where((group) => group.id != groupId)
          .toList();

      state = state.copyWith(groups: updatedGroups);
      debugPrint('✅ Group deleted: $groupId');
    } catch (e) {
      debugPrint('❌ Error deleting group: $e');
      state = state.copyWith(error: 'Failed to delete group: ${e.toString()}');
      rethrow;
    }
  }

  /// Refresh groups (pull-to-refresh)
  Future<void> refreshGroups() async {
    await loadMyGroups(forceRefresh: true);
  }
}

// ============================================
// PROVIDER
// ============================================

final groupsProvider = StateNotifierProvider<GroupsNotifier, GroupsState>((
  ref,
) {
  final groupService = GroupService();
  return GroupsNotifier(groupService);
});
