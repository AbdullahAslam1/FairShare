import 'package:fairshare/model/group_budget.dart';
import 'package:fairshare/services/budget_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================
// STATE CLASS
// ============================================

class BudgetState {
  final GroupBudget? budget;
  final Map<String, dynamic> stats;
  final bool isLoading;
  final String? error;

  BudgetState({
    this.budget,
    this.stats = const {},
    this.isLoading = false,
    this.error,
  });

  BudgetState copyWith({
    GroupBudget? budget,
    Map<String, dynamic>? stats,
    bool? isLoading,
    String? error,
  }) {
    return BudgetState(
      budget: budget ?? this.budget,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ============================================
// STATE NOTIFIER
// ============================================

class BudgetNotifier extends StateNotifier<BudgetState> {
  final BudgetService _budgetService;
  final String groupId;

  BudgetNotifier(this._budgetService, this.groupId)
      : super(BudgetState(isLoading: true)) {
    loadBudgetAndStats();
  }

  /// Load budget and stats
  Future<void> loadBudgetAndStats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Fetch budget settings
      final budget = await _budgetService.fetchBudget(groupId);
      
      // Fetch stats
      final stats = await _budgetService.getBudgetStats(groupId);

      state = state.copyWith(
        budget: budget,
        stats: stats,
        isLoading: false,
      );
      debugPrint('✅ Budget loaded for group: $groupId');
    } catch (e) {
      debugPrint('❌ Error loading budget: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load budget: ${e.toString()}',
      );
    }
  }

  /// Update budget
  Future<void> updateBudget(double weeklyLimit, double monthlyLimit) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final currentBudget = state.budget;
      final newBudget = GroupBudget(
        id: currentBudget?.id ?? '', // Service handles upsert
        groupId: groupId,
        weeklyLimit: weeklyLimit,
        monthlyLimit: monthlyLimit,
        currency: currentBudget?.currency ?? 'USD',
        createdAt: currentBudget?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: currentBudget?.createdBy,
      );

      await _budgetService.updateBudget(newBudget);

      // Reload stats immediately to reflect new limits
      // We could ideally just calculate locally, but fetching ensures consistency
      await loadBudgetAndStats();

      debugPrint('✅ Budget updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating budget: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update budget: ${e.toString()}',
      );
      rethrow;
    }
  }
}

// ============================================
// PROVIDER FAMILY
// ============================================

// Using autoDispose so it cleans up when the group screen is closed
final budgetProvider = StateNotifierProvider.autoDispose.family<BudgetNotifier, BudgetState, String>((
  ref,
  groupId,
) {
  final budgetService = BudgetService();
  return BudgetNotifier(budgetService, groupId);
});
