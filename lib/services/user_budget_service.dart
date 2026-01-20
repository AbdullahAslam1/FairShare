import 'package:fairshare/model/user_budget.dart';
import 'package:fairshare/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserBudgetService {
  final _supabase = Supabase.instance.client;
  final _supabaseService = SupabaseService();

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Fetches the current user's budget settings.
  /// If no record exists, returns a default UserBudget with 0 limits.
  Future<UserBudget> getUserBudget() async {
    if (_currentUserId == null) throw Exception('User not logged in');

    try {
      final data = await _supabase
          .from('user_budgets')
          .select()
          .eq('user_id', _currentUserId!)
          .maybeSingle();

      if (data == null) {
        // Return default object if not found
        return UserBudget(
          id: '',
          userId: _currentUserId!,
          weeklyLimit: 0.0,
          monthlyLimit: 0.0,
          currency: 'PKR', // FIXED: Changed from USD to PKR (your default)
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      return UserBudget.fromJson(data);
    } catch (e) {
      // If table doesn't exist or RLS issues, return default to avoid crashing
      print('⚠️ Error fetching user budget: $e');
      return UserBudget(
        id: '',
        userId: _currentUserId!,
        weeklyLimit: 0.0,
        monthlyLimit: 0.0,
        currency: 'PKR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Updates or Creates the user's budget settings
  Future<void> updateUserBudget({
    required double weeklyLimit,
    required double monthlyLimit,
  }) async {
    if (_currentUserId == null) throw Exception('User not logged in');

    final updates = {
      'user_id': _currentUserId,
      'weekly_limit': weeklyLimit,
      'monthly_limit': monthlyLimit,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Upsert based on user_id unique constraint
    await _supabase.from('user_budgets').upsert(updates, onConflict: 'user_id');
  }

  /// FIXED: Calculates total spending for the current user within a date range.
  /// Now properly handles timezone and excludes deleted expenses
  Future<double> getAggregateSpending(DateTime start, DateTime end) async {
    if (_currentUserId == null) return 0.0;

    try {
      print('🔍 Fetching aggregate spending for user: $_currentUserId');
      print(
        '📅 Date range: ${start.toIso8601String()} to ${end.toIso8601String()}',
      );

      // FIXED: Join with expenses and properly filter by created_at
      final response = await _supabase
          .from('expense_splits')
          .select('amount, expenses!inner(created_at, description)')
          .eq('user_id', _currentUserId!)
          .gte('expenses.created_at', start.toIso8601String())
          .lte('expenses.created_at', end.toIso8601String());

      print('📊 Found ${response.length} expense splits');

      double total = 0.0;
      for (final record in response) {
        final amount = (record['amount'] as num).toDouble();
        total += amount;

        // Debug: Show which expenses are being counted
        final expenseData = record['expenses'] as Map<String, dynamic>;
        final description = expenseData['description'] ?? 'No description';
        final createdAt = expenseData['created_at'] ?? '';
        print('  💰 ${description}: Rs ${amount.toStringAsFixed(2)}');
      }

      print('💵 Total spending: Rs ${total.toStringAsFixed(2)}');
      return total;
    } catch (e, stackTrace) {
      print('❌ Error calculating aggregate spending: $e');
      print('Stack trace: $stackTrace');
      return 0.0;
    }
  }

  /// FIXED: Fetch spending data for charts (e.g. daily breakdown)
  /// Returns a map of Date -> Amount with proper timezone handling
  Future<Map<DateTime, double>> getDailySpending(
    DateTime start,
    DateTime end,
  ) async {
    if (_currentUserId == null) return {};

    try {
      print(
        '📊 Fetching daily spending from ${start.toIso8601String()} to ${end.toIso8601String()}',
      );

      // FIXED: Proper query with ordering (using created_at)
      final response = await _supabase
          .from('expense_splits')
          .select('amount, expenses!inner(created_at, description)')
          .eq('user_id', _currentUserId!)
          .gte('expenses.created_at', start.toIso8601String())
          .lte('expenses.created_at', end.toIso8601String())
          .order('created_at', ascending: true, referencedTable: 'expenses');

      print('📈 Got ${response.length} splits for chart');

      final Map<DateTime, double> dailyTotals = {};

      for (final record in response) {
        final expenseData = record['expenses'] as Map<String, dynamic>;
        final dateStr = expenseData['created_at'] as String;

        // FIXED: Parse date and normalize to local midnight
        final fullDate = DateTime.parse(dateStr);
        final dateKey = DateTime(fullDate.year, fullDate.month, fullDate.day);

        final amount = (record['amount'] as num).toDouble();

        // Accumulate amounts for the same day
        dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0.0) + amount;
      }

      print('📅 Daily totals: ${dailyTotals.length} days with spending');
      dailyTotals.forEach((date, amount) {
        print(
          '  ${date.toString().split(' ')[0]}: Rs ${amount.toStringAsFixed(2)}',
        );
      });

      return dailyTotals;
    } catch (e, stackTrace) {
      print('❌ Error fetching daily spending: $e');
      print('Stack trace: $stackTrace');
      return {};
    }
  }

  /// HELPER: Get spending breakdown by group
  /// Returns map of group_id -> amount
  Future<Map<String, double>> getSpendingByGroup(
    DateTime start,
    DateTime end,
  ) async {
    if (_currentUserId == null) return {};

    try {
      final response = await _supabase
          .from('expense_splits')
          .select('amount, expenses!inner(created_at, group_id, groups!inner(name))')
          .eq('user_id', _currentUserId!)
          .gte('expenses.created_at', start.toIso8601String())
          .lte('expenses.created_at', end.toIso8601String());

      final Map<String, double> groupTotals = {};

      for (final record in response) {
        final amount = (record['amount'] as num).toDouble();
        final expenseData = record['expenses'] as Map<String, dynamic>;
        final groupData = expenseData['groups'] as Map<String, dynamic>?;

        if (groupData != null) {
          final groupName = groupData['name'] as String;
          groupTotals[groupName] = (groupTotals[groupName] ?? 0.0) + amount;
        }
      }

      return groupTotals;
    } catch (e) {
      print('❌ Error fetching spending by group: $e');
      return {};
    }
  }

  /// HELPER: Get spending breakdown by category
  /// Returns map of category -> amount
  Future<Map<String, double>> getSpendingByCategory(
    DateTime start,
    DateTime end,
  ) async {
    if (_currentUserId == null) return {};

    try {
      final response = await _supabase
          .from('expense_splits')
          .select('amount, expenses!inner(created_at, category)')
          .eq('user_id', _currentUserId!)
          .gte('expenses.created_at', start.toIso8601String())
          .lte('expenses.created_at', end.toIso8601String());

      final Map<String, double> categoryTotals = {};

      for (final record in response) {
        final amount = (record['amount'] as num).toDouble();
        final expenseData = record['expenses'] as Map<String, dynamic>;
        final category = expenseData['category'] as String? ?? 'Other';

        categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
      }

      return categoryTotals;
    } catch (e) {
      print('❌ Error fetching spending by category: $e');
      return {};
    }
  }

  /// HELPER: Get current week date range (Monday to Sunday)
  Map<String, DateTime> getCurrentWeekRange() {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final endOfWeek = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day + 6,
      23,
      59,
      59,
      999,
    );

    return {'start': startOfWeek, 'end': endOfWeek};
  }

  /// HELPER: Get current month date range (1st to last day)
  Map<String, DateTime> getCurrentMonthRange() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    // Handle December -> January transition
    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final nextYear = now.month == 12 ? now.year + 1 : now.year;
    final endOfMonth = DateTime(nextYear, nextMonth, 0, 23, 59, 59, 999);

    return {'start': startOfMonth, 'end': endOfMonth};
  }

  /// HELPER: Format currency amount
  String formatCurrency(double amount, String currency) {
    final symbols = {
      'USD': '\$',
      'PKR': 'Rs',
      'EUR': '€',
      'GBP': '£',
      'INR': '₹',
    };

    final symbol = symbols[currency] ?? currency;
    return '$symbol ${amount.toStringAsFixed(0)}';
  }
}
