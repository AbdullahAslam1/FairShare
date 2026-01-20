import 'package:fairshare/model/user_budget.dart';
import 'package:fairshare/services/user_budget_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserBudgetState {
  final UserBudget budget;
  final double weeklySpent;
  final double monthlySpent;
  final Map<DateTime, double> weeklyChartData;
  final Map<DateTime, double> monthlyChartData;
  final Map<String, double> groupBreakdown;
  final Map<String, double> categoryBreakdown;
  final bool isLoading;
  final String? error;

  UserBudgetState({
    required this.budget,
    this.weeklySpent = 0.0,
    this.monthlySpent = 0.0,
    this.weeklyChartData = const {},
    this.monthlyChartData = const {},
    this.groupBreakdown = const {},
    this.categoryBreakdown = const {},
    this.isLoading = true,
    this.error,
  });

  UserBudgetState copyWith({
    UserBudget? budget,
    double? weeklySpent,
    double? monthlySpent,
    Map<DateTime, double>? weeklyChartData,
    Map<DateTime, double>? monthlyChartData,
    Map<String, double>? groupBreakdown,
    Map<String, double>? categoryBreakdown,
    bool? isLoading,
    String? error,
  }) {
    return UserBudgetState(
      budget: budget ?? this.budget,
      weeklySpent: weeklySpent ?? this.weeklySpent,
      monthlySpent: monthlySpent ?? this.monthlySpent,
      weeklyChartData: weeklyChartData ?? this.weeklyChartData,
      monthlyChartData: monthlyChartData ?? this.monthlyChartData,
      groupBreakdown: groupBreakdown ?? this.groupBreakdown,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // ADDED: Helper to check if budget is set
  bool get hasBudgetSet => budget.weeklyLimit > 0 || budget.monthlyLimit > 0;

  // ADDED: Helper to get weekly percentage
  double get weeklyPercentage {
    if (budget.weeklyLimit <= 0) return 0.0;
    return (weeklySpent / budget.weeklyLimit * 100).clamp(0.0, 100.0);
  }

  // ADDED: Helper to get monthly percentage
  double get monthlyPercentage {
    if (budget.monthlyLimit <= 0) return 0.0;
    return (monthlySpent / budget.monthlyLimit * 100).clamp(0.0, 100.0);
  }

  // ADDED: Helper to check if over budget
  bool get isWeeklyOverBudget =>
      budget.weeklyLimit > 0 && weeklySpent > budget.weeklyLimit;
  bool get isMonthlyOverBudget =>
      budget.monthlyLimit > 0 && monthlySpent > budget.monthlyLimit;

  // ADDED: Helper to check if near limit (>80%)
  bool get isWeeklyNearLimit => weeklyPercentage > 80 && !isWeeklyOverBudget;
  bool get isMonthlyNearLimit => monthlyPercentage > 80 && !isMonthlyOverBudget;
}

class UserBudgetNotifier extends StateNotifier<UserBudgetState> {
  final UserBudgetService _service;

  UserBudgetNotifier(this._service)
    : super(
        UserBudgetState(
          budget: UserBudget(
            id: '',
            userId: '',
            weeklyLimit: 0,
            monthlyLimit: 0,
            currency: 'PKR',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      ) {
    loadBudget();
  }

  /// FIXED: Proper date range calculations with timezone handling
  DateTime _getStartOfWeek(DateTime date) {
    // Start of week = Monday at 00:00:00.000
    final daysSinceMonday = date.weekday - 1;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: daysSinceMonday));
  }

  DateTime _getEndOfWeek(DateTime startOfWeek) {
    // End of week = Sunday at 23:59:59.999
    return DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day + 6,
      23,
      59,
      59,
      999,
    );
  }

  DateTime _getStartOfMonth(DateTime date) {
    // Start of month = 1st at 00:00:00.000
    return DateTime(date.year, date.month, 1);
  }

  DateTime _getEndOfMonth(DateTime date) {
    // FIXED: Handle December -> January transition
    final nextMonth = date.month == 12 ? 1 : date.month + 1;
    final nextYear = date.month == 12 ? date.year + 1 : date.year;

    // Last day of current month = 0th day of next month
    return DateTime(nextYear, nextMonth, 0, 23, 59, 59, 999);
  }

  Future<void> loadBudget() async {
    print('🔄 Loading user budget...');
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. Fetch Budget Settings
      final budget = await _service.getUserBudget();
      print(
        '💰 Budget limits - Weekly: ${budget.weeklyLimit}, Monthly: ${budget.monthlyLimit}',
      );

      final now = DateTime.now();

      // 2. FIXED: Calculate date ranges properly
      final startOfWeek = _getStartOfWeek(now);
      final endOfWeek = _getEndOfWeek(startOfWeek);

      print(
        '📅 Week range: ${startOfWeek.toIso8601String()} to ${endOfWeek.toIso8601String()}',
      );

      final weeklyTotal = await _service.getAggregateSpending(
        startOfWeek,
        endOfWeek,
      );
      print('📊 Weekly total: Rs ${weeklyTotal.toStringAsFixed(2)}');

      // 3. FIXED: Month range calculation
      final startOfMonth = _getStartOfMonth(now);
      final endOfMonth = _getEndOfMonth(now);

      print(
        '📅 Month range: ${startOfMonth.toIso8601String()} to ${endOfMonth.toIso8601String()}',
      );

      final monthlyTotal = await _service.getAggregateSpending(
        startOfMonth,
        endOfMonth,
      );
      print('📊 Monthly total: Rs ${monthlyTotal.toStringAsFixed(2)}');

      // 4. FIXED: Use same date range for chart as weekly total
      print('📈 Fetching weekly chart data...');
      final weeklyChartData = await _service.getDailySpending(
        startOfWeek,
        endOfWeek,
      );

      // 5. FIXED: Monthly chart data (last 30 days for better visualization)
      print('📈 Fetching monthly chart data...');
      final monthlyChartStart = now.subtract(const Duration(days: 29));
      final monthlyChartData = await _service.getDailySpending(
        monthlyChartStart,
        now,
      );

      // 6. ADDED: Fetch group and category breakdowns
      print('📊 Fetching group breakdown...');
      final groupBreakdown = await _service.getSpendingByGroup(
        startOfMonth,
        endOfMonth,
      );

      print('📊 Fetching category breakdown...');
      final categoryBreakdown = await _service.getSpendingByCategory(
        startOfMonth,
        endOfMonth,
      );

      state = state.copyWith(
        budget: budget,
        weeklySpent: weeklyTotal,
        monthlySpent: monthlyTotal,
        weeklyChartData: weeklyChartData,
        monthlyChartData: monthlyChartData,
        groupBreakdown: groupBreakdown,
        categoryBreakdown: categoryBreakdown,
        isLoading: false,
        error: null,
      );

      print('✅ Budget loaded successfully');
      print(
        '📊 Weekly: Rs ${weeklyTotal.toStringAsFixed(0)} / Rs ${budget.weeklyLimit.toStringAsFixed(0)}',
      );
      print(
        '📊 Monthly: Rs ${monthlyTotal.toStringAsFixed(0)} / Rs ${budget.monthlyLimit.toStringAsFixed(0)}',
      );

      // ADDED: Warn if over budget
      if (state.isWeeklyOverBudget) {
        print('⚠️ WARNING: Weekly budget exceeded!');
      }
      if (state.isMonthlyOverBudget) {
        print('⚠️ WARNING: Monthly budget exceeded!');
      }
    } catch (e, stackTrace) {
      print('❌ Error loading user budget: $e');
      print('Stack trace: $stackTrace');

      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateLimits({double? weekly, double? monthly}) async {
    print('💾 Updating budget limits...');

    try {
      final newWeekly = weekly ?? state.budget.weeklyLimit;
      final newMonthly = monthly ?? state.budget.monthlyLimit;

      // Validation: Weekly shouldn't be more than 1.5x monthly
      if (newWeekly > 0 && newMonthly > 0 && newWeekly > newMonthly * 1.5) {
        throw Exception('Weekly limit cannot be more than 1.5x monthly limit');
      }

      await _service.updateUserBudget(
        weeklyLimit: newWeekly,
        monthlyLimit: newMonthly,
      );

      print('✅ Budget limits updated successfully');

      // Reload to get fresh data
      await loadBudget();
    } catch (e) {
      print('❌ Error updating budget limits: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    print('🔄 Refreshing budget data...');
    await loadBudget();
  }

  // ADDED: Method to be called after expense changes
  Future<void> onExpenseChanged() async {
    print('💰 Expense changed, refreshing budget...');

    // Quick refresh without showing loading state
    final now = DateTime.now();
    final startOfWeek = _getStartOfWeek(now);
    final endOfWeek = _getEndOfWeek(startOfWeek);
    final startOfMonth = _getStartOfMonth(now);
    final endOfMonth = _getEndOfMonth(now);

    try {
      final weeklyTotal = await _service.getAggregateSpending(
        startOfWeek,
        endOfWeek,
      );
      final monthlyTotal = await _service.getAggregateSpending(
        startOfMonth,
        endOfMonth,
      );
      final weeklyChartData = await _service.getDailySpending(
        startOfWeek,
        endOfWeek,
      );
      final groupBreakdown = await _service.getSpendingByGroup(
        startOfMonth,
        endOfMonth,
      );
      final categoryBreakdown = await _service.getSpendingByCategory(
        startOfMonth,
        endOfMonth,
      );

      state = state.copyWith(
        weeklySpent: weeklyTotal,
        monthlySpent: monthlyTotal,
        weeklyChartData: weeklyChartData,
        groupBreakdown: groupBreakdown,
        categoryBreakdown: categoryBreakdown,
      );

      print('✅ Budget refreshed after expense change');
    } catch (e) {
      print('⚠️ Failed to refresh budget after expense change: $e');
      // Don't throw - just log the error
    }
  }

  // ADDED: Get spending for a specific date range (for analytics)
  Future<double> getSpendingForRange(DateTime start, DateTime end) async {
    try {
      return await _service.getAggregateSpending(start, end);
    } catch (e) {
      print('❌ Error getting spending for range: $e');
      return 0.0;
    }
  }

  // ADDED: Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

final userBudgetProvider =
    StateNotifierProvider<UserBudgetNotifier, UserBudgetState>((ref) {
      return UserBudgetNotifier(UserBudgetService());
    });
