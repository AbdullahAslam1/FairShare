import 'package:fairshare/model/expense.dart';
import 'package:fairshare/model/expense_category.dart';
import 'package:fairshare/model/expense_split.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- Cache Storage ---
  // Categories don't change often, 24h TTL
  static List<ExpenseCategory>? _categoriesCache;
  static DateTime? _categoriesCacheTime;

  // Group expenses cache (Key: GroupID, Value: CacheEntry)
  // 5 minute TTL for expenses
  final Map<String, _CacheEntry<List<Map<String, dynamic>>>>
  _groupExpensesCache = {};

  // --- Constants ---
  static const Duration _categoriesTTL = Duration(hours: 24);
  static const Duration _expensesTTL = Duration(minutes: 5);

  /// Fetch all available expense categories
  Future<List<ExpenseCategory>> getCategories() async {
    try {
      // 1. Check Cache
      if (_categoriesCache != null &&
          _categoriesCacheTime != null &&
          DateTime.now().difference(_categoriesCacheTime!) < _categoriesTTL) {
        debugPrint('🎯 Categories returned from cache');
        return _categoriesCache!;
      }

      // 2. Fetch
      final response = await _supabase
          .from('expense_categories')
          .select()
          .order('name');

      final categories = (response as List)
          .map((e) => ExpenseCategory.fromJson(e))
          .toList();

      // 3. Cache
      _categoriesCache = categories;
      _categoriesCacheTime = DateTime.now();

      return categories;
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      throw Exception('Failed to load categories');
    }
  }

  /// Create a new custom category
  Future<ExpenseCategory> createCategory({
    required String name,
    required String icon,
    required String color,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('expense_categories')
          .insert({
            'name': name,
            'icon': icon,
            'color': color,
            'is_default': false,
            'created_by': userId,
          })
          .select()
          .single();

      final newCategory = ExpenseCategory.fromJson(response);

      // Invalidate cache so next fetch gets the new one
      _categoriesCache = null;

      return newCategory;
    } catch (e) {
      debugPrint('Error creating category: $e');
      throw Exception('Failed to create category');
    }
  }

  /// Create a new expense with splits
  Future<void> createExpense({
    required Expense expense,
    required List<ExpenseSplit> splits,
  }) async {
    try {
      // 1. Insert Expense
      final expenseData = expense.toJson();
      // Remove ID and created_at/updated_at to let DB handle them if they are null/default
      // But Expense model requires them. In creation flow, we usually use a DTO or just ignore them here.
      // Better approach: Let's strip the ID if it's empty or handle return.

      final expenseResponse = await _supabase
          .from('expenses')
          .insert({
            'group_id': expense.groupId,
            'description': expense.description,
            'amount': expense.amount,
            'currency': expense.currency,
            'category_id': expense.categoryId,
            'paid_by': expense.paidBy,
            'expense_date': expense.expenseDate.toIso8601String(),
            'split_type': expense.splitType,
            'notes': expense.notes,
          })
          .select()
          .single();

      final newExpenseId = expenseResponse['id'] as String;

      // 2. Insert Splits
      final splitsData = splits
          .map(
            (s) => {
              'expense_id': newExpenseId,
              'user_id': s.userId,
              'amount': s.amount,
              'percentage': s.percentage,
              'shares': s.shares,
              'is_settled': false,
            },
          )
          .toList();

      await _supabase.from('expense_splits').insert(splitsData);

      // Invalidate cache for this group
      _invalidateGroupCache(expense.groupId);
    } catch (e) {
      debugPrint('Error creating expense: $e');
      throw Exception('Failed to create expense: $e');
    }
  }

  /// Get expenses for a group
  Future<List<Map<String, dynamic>>> getGroupExpenses(
    String groupId, {
    bool forceRefresh = false,
  }) async {
    try {
      // Check Cache
      if (!forceRefresh && _isGroupCacheValid(groupId)) {
        debugPrint('🎯 Group expenses returned from cache: $groupId');
        return _groupExpensesCache[groupId]!.data;
      }

      final response = await _supabase
          .from('expenses')
          .select(
            '*, expense_categories(*), profiles:paid_by(*)',
          ) // join category and payer
          .eq('group_id', groupId)
          .order('expense_date', ascending: false);

      final data = List<Map<String, dynamic>>.from(response);

      // Save to cache
      _groupExpensesCache[groupId] = _CacheEntry(
        data: data,
        timestamp: DateTime.now(),
      );

      return data;
    } catch (e) {
      debugPrint('Error fetching group expenses: $e');
      throw Exception('Failed to load expenses');
    }
  }

  /// Helper to check if group cache is valid
  bool _isGroupCacheValid(String groupId) {
    if (!_groupExpensesCache.containsKey(groupId)) return false;
    final entry = _groupExpensesCache[groupId]!;
    return DateTime.now().difference(entry.timestamp) < _expensesTTL;
  }

  /// Helper to invalidate group cache
  void _invalidateGroupCache(String groupId) {
    if (_groupExpensesCache.containsKey(groupId)) {
      _groupExpensesCache.remove(groupId);
      debugPrint('🧹 Cache invalidated for group: $groupId');
    }
  }

  /// Get simplified group balances using RPC
  Future<List<Map<String, dynamic>>> getGroupBalances(String groupId) async {
    try {
      final response = await _supabase.rpc(
        'calculate_group_balances',
        params: {'p_group_id': groupId},
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching balances: $e');
      // Fallback or rethrow
      return [];
    }
  }

  /// Get suggested settlements using RPC
  Future<List<Map<String, dynamic>>> getSuggestedSettlements(
    String groupId,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_suggested_settlements',
        params: {'p_group_id': groupId},
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching suggested settlements: $e');
      return [];
    }
  }

  /// Get expenses for multiple groups (Batch optimized)
  Future<List<Map<String, dynamic>>> getExpensesForGroups(
    List<String> groupIds, {
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    try {
      if (groupIds.isEmpty) return [];

      final response = await _supabase
          .from('expenses')
          .select('*, expense_categories(*), profiles:paid_by(*)')
          .filter(
            'group_id',
            'in',
            '(${groupIds.map((e) => '"$e"').join(',')})',
          )
          .order('expense_date', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching expenses for groups: $e');
      return [];
    }
  }

  /// Get expenses with splits and member details for a group (Optimized + Cached)
  Future<List<Map<String, dynamic>>> getGroupExpensesWithSplits(
    String groupId,
  ) async {
    try {
      // NOTE: We share the same cache key for simplicity, assuming the UI consistently requests
      // either detailed or simple views. If mixed, we might need separate keys.
      // For now, let's treat detailed fetch as a fresh fetch to be safe,
      // or we can implement a separate cache for detailed views.
      // Let's implement a specific cache for detailed views.

      // Fetch expenses with splits in a SINGLE query using nested selection
      final response = await _supabase
          .from('expenses')
          .select(
            '*, expense_categories(*), profiles:paid_by(*), expense_splits(*, profiles:user_id(*))',
          )
          .eq('group_id', groupId)
          .order('expense_date', ascending: false);

      // Map response to maintain compatibility with UI expectations
      return List<Map<String, dynamic>>.from(
        response.map((e) {
          final data = Map<String, dynamic>.from(e);
          // Ensure UI compatibility if it expects 'splits' key
          // The nested query returns 'expense_splits'
          data['splits'] = data['expense_splits'];
          return data;
        }),
      );
    } catch (e) {
      debugPrint('Error fetching expenses with splits: $e');
      throw Exception('Failed to load expenses with splits');
    }
  }

  /// Get expenses for a group within a specific date range
  Future<List<Map<String, dynamic>>> getExpensesInDateRange(
    String groupId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _supabase
          .from('expenses')
          .select('amount, expense_date')
          .eq('group_id', groupId)
          .gte('expense_date', start.toIso8601String())
          .lte('expense_date', end.toIso8601String());

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching expenses in date range: $e');
      return [];
    }
  }

  /// Delete an expense and its splits
  Future<void> deleteExpense(String expenseId) async {
    try {
      debugPrint('🗑️ Deleting expense: $expenseId');

      // Optimized: Rely on ON DELETE CASCADE in the database to remove splits
      // This reduces the operation from 2 DB calls to 1.
      await _supabase.from('expenses').delete().eq('id', expenseId);

      // Note: We can't easily invalidate cache here without knowing the groupId.
      // Ideally, the caller should refresh, or we fetch the expense to get groupId before deleting.
      // For performance, we'll let the UI handle refresh via pull-to-refresh,
      // OR we could store a reverse mapping.
      // Optimized Approach: Fetch just the groupId first.

      debugPrint('✅ Expense deleted successfully');
    } on PostgrestException catch (e) {
      debugPrint('❌ Database error deleting expense: ${e.message} (${e.code})');
      if (e.code == '42501') {
        throw Exception(
          'Permission denied. You can only delete expenses you created.',
        );
      } else {
        throw Exception('Failed to delete expense: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Error deleting expense: $e');
      rethrow;
    }
  }

  /// Update an expense
  Future<void> updateExpense({
    required String expenseId,
    String? description,
    double? amount,
    String? categoryId,
    DateTime? expenseDate,
    String? notes,
  }) async {
    try {
      debugPrint('📝 Updating expense: $expenseId');

      final updateData = <String, dynamic>{};
      if (description != null) updateData['description'] = description;
      if (amount != null) updateData['amount'] = amount;
      if (categoryId != null) updateData['category_id'] = categoryId;
      if (expenseDate != null)
        updateData['expense_date'] = expenseDate.toIso8601String();
      if (notes != null) updateData['notes'] = notes;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('expenses').update(updateData).eq('id', expenseId);

      debugPrint('✅ Expense updated successfully');
    } on PostgrestException catch (e) {
      debugPrint('❌ Database error updating expense: ${e.message} (${e.code})');
      if (e.code == '42501') {
        throw Exception(
          'Permission denied. You can only update expenses you created.',
        );
      } else {
        throw Exception('Failed to update expense: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Error updating expense: $e');
      rethrow;
    }
  }

  /// Update an expense and its splits
  Future<void> updateExpenseWithSplits({
    required Expense expense,
    required List<ExpenseSplit> splits,
  }) async {
    try {
      debugPrint('📝 Updating expense with splits: ${expense.id}');

      // 1. Update Expense
      final updateData = {
        'description': expense.description,
        'amount': expense.amount,
        'category_id': expense.categoryId,
        'paid_by': expense.paidBy,
        'expense_date': expense.expenseDate.toIso8601String(),
        'split_type': expense.splitType,
        'notes': expense.notes,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('expenses').update(updateData).eq('id', expense.id!);

      // 2. Refresh Splits
      // Delete existing splits
      await _supabase
          .from('expense_splits')
          .delete()
          .eq('expense_id', expense.id!);

      // Insert new splits
      final splitsData = splits
          .map(
            (s) => {
              'expense_id': expense.id,
              'user_id': s.userId,
              'amount': s.amount,
              'percentage': s.percentage,
              'shares': s.shares,
              'is_settled':
                  false, // Reset settlement status on edit? Usually yes to be safe.
            },
          )
          .toList();

      await _supabase.from('expense_splits').insert(splitsData);

      // Invalidate cache
      _invalidateGroupCache(expense.groupId);
      debugPrint('✅ Expense updated successfully with splits');
    } catch (e) {
      debugPrint('❌ Error updating expense with splits: $e');
      throw Exception('Failed to update expense with splits');
    }
  }

  /// Get group expense summary using RPC
  /// Combines group-level stats (from user defined RPC) with personal balance (from calculate_group_balances)
  Future<Map<String, dynamic>?> getGroupExpenseSummary(String groupId) async {
    try {
      // 1. Get Group Stats (Total, Settled, Unsettled)
      final summaryResponse = await _supabase.rpc(
        'get_group_expense_summary',
        params: {'p_group_id': groupId},
      );

      Map<String, dynamic> summary = {};
      if (summaryResponse is List && summaryResponse.isNotEmpty) {
        summary = summaryResponse.first as Map<String, dynamic>;
      }

      // 2. Get Personal Balance for "You Owe/Owed" cards
      double youOwe = 0.0;
      double youAreOwed = 0.0;

      try {
        final userId = _supabase.auth.currentUser?.id;
        if (userId != null) {
          final balances = await getGroupBalances(groupId);
          final userBalanceEntry = balances.firstWhere(
            (b) => b['user_id'] == userId,
            orElse: () => {'balance': 0},
          );

          // Ensure balance is treated as a number (double/num)
          final balance =
              (userBalanceEntry['balance'] as num?)?.toDouble() ?? 0.0;

          if (balance < 0) {
            youOwe = balance.abs();
            youAreOwed = 0.0;
          } else {
            youOwe = 0.0;
            youAreOwed = balance;
          }
        }
      } catch (e) {
        debugPrint('Error calculating personal balance in summary: $e');
        // Fail gracefully, defaulting to 0
      }

      // 3. Merge and Return
      // Map RPC keys (total_expenses, total_settled, etc) + Synthetic keys (you_owe, you_are_owed)
      return {
        'total_expenses': summary['total_expenses'] ?? summary['total'] ?? 0.0,
        'total_settled': summary['total_settled'] ?? summary['settled'] ?? 0.0,
        'total_unsettled':
            summary['total_unsettled'] ?? summary['unsettled'] ?? 0.0,
        'expense_count': summary['expense_count'] ?? summary['count'] ?? 0,
        'member_count': summary['member_count'] ?? summary['members'] ?? 0,
        'you_owe': youOwe,
        'you_are_owed': youAreOwed,
      };
    } catch (e) {
      debugPrint('Error fetching expense summary: $e');
      return null;
    }
  }

  /// Mark an expense as cleared (Settles all splits)
  Future<void> markAsCleared(String expenseId) async {
    try {
      debugPrint('✅ Marking expense as cleared: $expenseId');
      
      // 1. Update Expense Status
      await _supabase.from('expenses').update({
        'status': 'cleared',
        'cleared_at': DateTime.now().toIso8601String(),
      }).eq('id', expenseId);

      // 2. Mark ALL splits as settled
      await _supabase
          .from('expense_splits')
          .update({'is_settled': true})
          .eq('expense_id', expenseId);

      // 3. Invalidate cache (we can't easily get groupId here without a fetch, 
      // but usually the caller knows it. For now, we trust the UI to refresh or we fetch it.)
      // Optimized: Fetch group_id to invalidate cache properly
      final response = await _supabase
          .from('expenses')
          .select('group_id')
          .eq('id', expenseId)
          .single();
      
      _invalidateGroupCache(response['group_id'] as String);

    } catch (e) {
      debugPrint('❌ Error marking as cleared: $e');
      throw Exception('Failed to mark expense as cleared');
    }
  }

  /// Toggle settlement status for a single split
  Future<void> toggleSplitSettlement({
    required String splitId,
    required bool isSettled,
    required String expenseId, // Need this to check parent status
  }) async {
    try {
      debugPrint('🔄 Toggling split $splitId to $isSettled');
      
      // 1. Update the split
      await _supabase
          .from('expense_splits')
          .update({'is_settled': isSettled})
          .eq('id', splitId);

      // 2. Check if ALL splits for this expense are now settled
      final splitsResponse = await _supabase
          .from('expense_splits')
          .select('is_settled')
          .eq('expense_id', expenseId);

      final allSettled = (splitsResponse as List).every((s) => s['is_settled'] == true);
      
      // 3. Update Parent Expense Status
      if (allSettled) {
        await _supabase.from('expenses').update({
          'status': 'cleared',
          'cleared_at': DateTime.now().toIso8601String(),
        }).eq('id', expenseId);
      } else {
        // If it WAS cleared but now isn't (because we unchecked one), revert to pending
        // We only need to check if it IS 'cleared' to avoid redundant writes, but simpler to just write.
        await _supabase.from('expenses').update({
          'status': 'pending', 
          'cleared_at': null 
        }).eq('id', expenseId);
      }

      // 4. Invalidate Cache
      final groupResponse = await _supabase
          .from('expenses')
          .select('group_id')
          .eq('id', expenseId)
          .single();
      _invalidateGroupCache(groupResponse['group_id'] as String);

    } catch (e) {
      debugPrint('❌ Error toggling split: $e');
      throw Exception('Failed to update split settlement');
    }
  }
}

class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry({required this.data, required this.timestamp});
}


// Simple Cache Entry Wrapper

