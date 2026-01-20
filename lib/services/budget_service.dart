import 'package:fairshare/model/group_budget.dart';
import 'package:fairshare/services/expense_service.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BudgetService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ExpenseService _expenseService = ExpenseService();

  /// Fetch budget settings for a group
  Future<GroupBudget?> fetchBudget(String groupId) async {
    try {
      final response = await _supabase
          .from('group_budgets')
          .select()
          .eq('group_id', groupId)
          .maybeSingle();

      if (response == null) return null;
      return GroupBudget.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching budget: $e');
      return null;
    }
  }

  /// Update or create budget settings
  Future<void> updateBudget(GroupBudget budget) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final data = budget.toJson();
      // Remove ID to allow DB to handle generation on insert if needed,
      // or simplistic upsert on group_id
      data.remove('id');
      data['updated_at'] = DateTime.now().toIso8601String();
      if (budget.id.isEmpty) {
        data['created_by'] = userId;
      }

      await _supabase.from('group_budgets').upsert(
        data,
        onConflict: 'group_id',
      );
    } catch (e) {
      debugPrint('Error updating budget: $e');
      throw Exception('Failed to update budget');
    }
  }

  /// Calculate budget stats for the current period (Week and Month)
  Future<Map<String, dynamic>> getBudgetStats(String groupId) async {
    try {
      final budget = await fetchBudget(groupId);
      if (budget == null) {
        return {'hasBudget': false};
      }

      final now = DateTime.now();

      // 1. Calculate Date Ranges
      // Week starts on Monday
      // If today is Wednesday (3), we subtract 2 days to get Monday (1)
      final currentWeekday = now.weekday;
      final startOfWeek = now.subtract(Duration(days: currentWeekday - 1));
      final startOfWeekDate = DateTime(
          startOfWeek.year, startOfWeek.month, startOfWeek.day); // Trim time

      final startOfMonthDate = DateTime(now.year, now.month, 1);
      final endOfToday = DateTime(
          now.year, now.month, now.day, 23, 59, 59); // End of today

      // 2. Fetch Expenses
      // Optimization: Fetch all expenses from startOfMonth (since week usually falls within month, or close enough)
      // Actually, if week spans across months (e.g. Mon 29th to Sun 4th), startOfMonth might be later than startOfWeek.
      // So take the earlier of the two.
      final fetchStartDate = startOfWeekDate.isBefore(startOfMonthDate)
          ? startOfWeekDate
          : startOfMonthDate;

      final expenses = await _expenseService.getExpensesInDateRange(
        groupId,
        fetchStartDate,
        endOfToday,
      );

      // 3. Calculate Totals
      double spentThisWeek = 0.0;
      double spentThisMonth = 0.0;

      for (var e in expenses) {
        final date = DateTime.parse(e['expense_date']);
        final amount = (e['amount'] as num).toDouble();

        if (date.isAfter(startOfWeekDate) ||
            date.isAtSameMomentAs(startOfWeekDate)) {
          spentThisWeek += amount;
        }

        if (date.isAfter(startOfMonthDate) ||
            date.isAtSameMomentAs(startOfMonthDate)) {
          spentThisMonth += amount;
        }
      }

      return {
        'hasBudget': true,
        'budget': budget,
        'weekly': {
          'spent': spentThisWeek,
          'limit': budget.weeklyLimit,
          'remaining': budget.weeklyLimit - spentThisWeek,
          'status': _getStatus(spentThisWeek, budget.weeklyLimit),
        },
        'monthly': {
          'spent': spentThisMonth,
          'limit': budget.monthlyLimit,
          'remaining': budget.monthlyLimit - spentThisMonth,
          'status': _getStatus(spentThisMonth, budget.monthlyLimit),
        },
      };
    } catch (e) {
      debugPrint('Error calculating budget stats: $e');
      return {'hasBudget': false, 'error': e.toString()};
    }
  }

  String _getStatus(double spent, double limit) {
    if (limit <= 0) return 'No Limit';
    final percentage = spent / limit;
    if (percentage >= 1.0) return 'Over Budget';
    if (percentage >= 0.8) return 'Near Limit';
    return 'On Track';
  }
}
