// ============================================
// FILE: lib/riverpod/home_data_provider.dart
// Home Screen Data Provider - Real Data Integration
// ============================================

import 'package:fairshare/model/group.dart';
import 'package:fairshare/services/expense_service.dart';
import 'package:fairshare/services/group_services.dart';
import 'package:fairshare/services/supabase_service.dart';
import 'package:fairshare/riverpod/group_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================
// STATE CLASSES
// ============================================

/// Home screen data state
class HomeData {
  final Map<String, dynamic>? userProfile;
  final List<Group> groups;
  final List<Map<String, dynamic>> recentExpenses;
  final double netBalance;
  final double totalReceivable;
  final double totalPayable;
  final bool isLoading;
  final String? error;

  HomeData({
    this.userProfile,
    this.groups = const [],
    this.recentExpenses = const [],
    this.netBalance = 0.0,
    this.totalReceivable = 0.0,
    this.totalPayable = 0.0,
    this.isLoading = false,
    this.error,
  });

  HomeData copyWith({
    Map<String, dynamic>? userProfile,
    List<Group>? groups,
    List<Map<String, dynamic>>? recentExpenses,
    double? netBalance,
    double? totalReceivable,
    double? totalPayable,
    bool? isLoading,
    String? error,
  }) {
    return HomeData(
      userProfile: userProfile ?? this.userProfile,
      groups: groups ?? this.groups,
      recentExpenses: recentExpenses ?? this.recentExpenses,
      netBalance: netBalance ?? this.netBalance,
      totalReceivable: totalReceivable ?? this.totalReceivable,
      totalPayable: totalPayable ?? this.totalPayable,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ============================================
// HOME DATA NOTIFIER
// ============================================

class HomeDataNotifier extends StateNotifier<HomeData> {
  final SupabaseService _supabaseService;
  final GroupService _groupService;
  final ExpenseService _expenseService;

  HomeDataNotifier(
    this._supabaseService,
    this._groupService,
    this._expenseService,
  ) : super(HomeData(isLoading: true)) {
    loadHomeData();
    subscribeToRealtime();
  }

  /// Subscribe to Realtime updates for expenses/splits
  void subscribeToRealtime() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    debugPrint('🔌 Subscribing to expense updates for user: $userId');

    // Channel 1: Splits (When I owe/share)
    Supabase.instance.client
        .channel('public:home_splits:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expense_splits',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => _handleRealtimeUpdate(),
        )
        .subscribe();
        
    // Channel 2: Expenses (When I pay)
    Supabase.instance.client
        .channel('public:home_expenses:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expenses',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'paid_by',
            value: userId,
          ),
          callback: (payload) => _handleRealtimeUpdate(),
        )
        .subscribe();
  }
  
  void _handleRealtimeUpdate() {
    debugPrint('⚡ Realtime: Balance-impacting change detected! Refreshing...');
    // Debounce/Delay to allow DB triggers to settle
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) loadHomeData();
    });
  }

  /// Load all home screen data
  Future<void> loadHomeData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Get current user
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      // 1. FAST PATH: Load Profile and Groups in parallel
      // These are critical for the initial UI structure.
      final initialResults = await Future.wait([
        _loadUserProfile(currentUser.id),
        _loadGroups(),
      ]);

      final userProfile = initialResults[0] as Map<String, dynamic>?;
      final groups = initialResults[1] as List<Group>;

      // 2. RENDER UI: Update state immediately with critical data
      // This unblocks the UI so the user sees the screen instantly.
      state = state.copyWith(
        userProfile: userProfile,
        groups: groups,
        isLoading: false, // <--- UNBLOCK UI HERE
      );

      // 3. BACKGROUND PATH: Load Balances and Expenses in parallel
      // These might take longer (RPC calls, complex queries) but shouldn't block the screen.
      final backgroundResults = await Future.wait([
        _calculateBalances(),
        _loadRecentExpenses(groups),
      ]);

      final balances = backgroundResults[0] as Map<String, dynamic>;
      final recentExpenses = backgroundResults[1] as List<Map<String, dynamic>>;

      // 4. UPDATE VALUES: Populate the remaining data
      if (mounted) {
        state = state.copyWith(
          recentExpenses: recentExpenses,
          netBalance: balances['net'] ?? 0.0,
          totalReceivable: balances['receivable'] ?? 0.0,
          totalPayable: balances['payable'] ?? 0.0,
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading home data: $e');
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load data: $e',
        );
      }
    }
  }

  /// Load user profile
  Future<Map<String, dynamic>?> _loadUserProfile(String userId) async {
    try {
      return await _supabaseService.getUserProfile(userId);
    } catch (e) {
      debugPrint('⚠️ Error loading user profile: $e');
      return null;
    }
  }

  /// Load user's groups
  Future<List<Group>> _loadGroups() async {
    try {
      return await _groupService.getMyGroups();
    } catch (e) {
      debugPrint('⚠️ Error loading groups: $e');
      return [];
    }
  }

  /// Load recent expenses across all groups (Batch Optimized)
  Future<List<Map<String, dynamic>>> _loadRecentExpenses(List<Group> groups) async {
    try {
      if (groups.isEmpty) return [];

      final groupIds = groups.map((g) => g.id).toList();
      
      // Use the new batch method to fetch expenses for all groups in one go
      final expenses = await _expenseService.getExpensesForGroups(groupIds);
      
      // Expenses are already sorted by the DB query
      return expenses.take(10).toList();
    } catch (e) {
      debugPrint('⚠️ Error loading recent expenses: $e');
      return [];
    }
  }

  /// Calculate total balances across all groups using RPC function
  /// No longer depends on 'groups' list, purely user-based RPC.
  Future<Map<String, double>> _calculateBalances() async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        print('❌ HOME BALANCE: No current user ID found');
        return {'net': 0.0, 'receivable': 0.0, 'payable': 0.0};
      }

      // ... (RPC call remains same)
      final response = await Supabase.instance.client
          .rpc('calculate_user_total_balance', params: {'p_user_id': currentUserId})
          .single();

      // ... (parsing logic remains same)
      final receivable = _parseDouble(response['total_receivable']);
      final payable = _parseDouble(response['total_payable']);
      final netBalance = _parseDouble(response['net_balance']);

      return {
        'net': netBalance,
        'receivable': receivable,
        'payable': payable,
      };
    } catch (e, stackTrace) {
      print('❌ HOME BALANCE: Error fetching total balance: $e');
      print('Stack trace: $stackTrace');
      return {'net': 0.0, 'receivable': 0.0, 'payable': 0.0};
    }
  }

  /// Safely parse a value to double
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is num) return value.toDouble();
    return 0.0;
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadHomeData();
  }
}

// ============================================
// PROVIDERS
// ============================================

/// Home data provider
final homeDataProvider = StateNotifierProvider<HomeDataNotifier, HomeData>((ref) {
  return HomeDataNotifier(
    SupabaseService(),
    GroupService(),
    ExpenseService(),
  );
});

/// User profile provider (derived from home data)
final userProfileProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(homeDataProvider).userProfile;
});

/// User display name provider
final userDisplayNameProvider = Provider<String>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile?['full_name'] as String? ?? 'User';
});

/// User initials provider
final userInitialsProvider = Provider<String>((ref) {
  final name = ref.watch(userDisplayNameProvider);
  final parts = name.split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }
  return 'U';
});

/// Groups provider (uses centralized groupsProvider)
final homeGroupsProvider = Provider<List<Group>>((ref) {
  return ref.watch(groupsProvider).groups;
});

/// Recent expenses provider (derived from home data)
final homeRecentExpensesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(homeDataProvider).recentExpenses;
});

/// Balance providers (derived from home data)
final netBalanceProvider = Provider<double>((ref) {
  return ref.watch(homeDataProvider).netBalance;
});

final totalReceivableProvider = Provider<double>((ref) {
  return ref.watch(homeDataProvider).totalReceivable;
});

final totalPayableProvider = Provider<double>((ref) {
  return ref.watch(homeDataProvider).totalPayable;
});

/// Loading state provider
final homeLoadingProvider = Provider<bool>((ref) {
  return ref.watch(homeDataProvider).isLoading;
});

/// Error provider
final homeErrorProvider = Provider<String?>((ref) {
  return ref.watch(homeDataProvider).error;
});
