// ============================================
// FILE: lib/screens/groups/group_detail_screen.dart
// Group Detail Screen - Expense-Focused Redesign
// ============================================

import 'package:fairshare/core/theme/app_theme.dart';
import 'package:fairshare/model/group.dart';
import 'package:fairshare/screens/expenses/add_expense_screen.dart';
import 'package:fairshare/screens/expenses/widgets/expense_card.dart';
import 'package:fairshare/screens/groups/group_settings_screen.dart';
import 'package:fairshare/services/expense_service.dart';
import 'package:fairshare/services/budget_service.dart';
import 'package:fairshare/screens/groups/widgets/budget_overview_card.dart';
import 'package:fairshare/screens/groups/widgets/group_detail_app_bar.dart';
import 'package:fairshare/screens/groups/widgets/group_stats_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairshare/riverpod/budget_provider.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  final ExpenseService _expenseService = ExpenseService();

  List<Map<String, dynamic>> _expenses = [];
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Track expanded state for each expense
  final Set<String> _expandedExpenses = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadGroupDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupDetails() async {
    // Refresh budget data via Riverpod
    ref.refresh(budgetProvider(widget.group.id));

    setState(() => _isLoading = true);
    try {
      final expenses = await _expenseService.getGroupExpensesWithSplits(
        widget.group.id,
      );
      final summary = await _expenseService.getGroupExpenseSummary(
        widget.group.id,
      );
      if (mounted) {
        setState(() {
          _expenses = expenses;
          _summary = summary;
        });
        _animationController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to load expenses', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal600),
            )
          : CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                GroupDetailAppBar(
                  group: widget.group,
                  onSettingsPressed: _navigateToSettings,
                ),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: GroupStatsCard(summary: _summary, onSettleUp: () {}),
                  ),
                ),
                _buildBudgetOverviewWrapper(),
                _buildExpensesHeader(),
                _buildExpensesList(),
                const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
              ],
            ),
    );
  }

  Widget _buildBudgetOverviewWrapper() {
    final budgetState = ref.watch(budgetProvider(widget.group.id));

    if (budgetState.isLoading && budgetState.stats.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: BudgetOverviewCard(stats: budgetState.stats),
      ),
    );
  }

  // ============================================
  // MINIMAL SINGLE-LINE APPBAR
  // ============================================

  Widget _buildExpensesHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.teal50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.teal600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Expenses (${_expenses.length})',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList() {
    if (_expenses.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No expenses yet',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add an expense',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final expense = _expenses[index];
          final expenseId = expense['id'] as String;
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (index * 0.05).clamp(0.0, 0.6),
                    ((index * 0.05) + 0.4).clamp(0.0, 1.0),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              );

              return Transform.translate(
                offset: Offset(0, 15 * (1 - animation.value)),
                child: Opacity(opacity: animation.value, child: child),
              );
            },
            child: ExpenseCard(
              expenseData: expense,
              currentUserId:
                  Supabase.instance.client.auth.currentUser?.id ?? '',
              isExpanded: _expandedExpenses.contains(expenseId),
              onToggleExpand: () {
                setState(() {
                  if (_expandedExpenses.contains(expenseId)) {
                    _expandedExpenses.remove(expenseId);
                  } else {
                    _expandedExpenses.add(expenseId);
                  }
                });
              },
              onDelete: _deleteExpense,
              onEdit: _navigateToEditExpense,
              onMarkAsCleared: _markExpenseAsCleared,
              onToggleSplit: _toggleSplit,
            ),
          );
        }, childCount: _expenses.length),
      ),
    );
  }

  void _navigateToEditExpense(Map<String, dynamic> expenseData) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          groupId: widget.group.id,
          expenseToEdit: expenseData,
        ),
      ),
    );

    if (result == true && mounted) {
      _loadGroupDetails();
    }
  }

  void _navigateToSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupSettingsScreen(group: widget.group),
      ),
    );

    if (result == true && mounted) {
      _loadGroupDetails();
    }
  }

  // ============================================
  // EXPENSE MANAGEMENT
  // ============================================

  Future<void> _deleteExpense(String expenseId, String description) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_rounded,
                color: AppColors.danger600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Delete Expense'),
          ],
        ),
        content: Text(
          'Delete "$description"? This action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _expenseService.deleteExpense(expenseId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Expense deleted successfully'),
              ],
            ),
            backgroundColor: AppColors.success500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        _loadGroupDetails();
      }
    } catch (e) {
      if (mounted) {
        // Check if it's a permission error
        final errorMessage =
            e.toString().toLowerCase().contains('policy') ||
                e.toString().toLowerCase().contains('permission')
            ? 'You can only delete expenses you created'
            : 'Failed to delete expense';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: AppColors.danger500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _markExpenseAsCleared(String expenseId) async {
    try {
      await _expenseService.markAsCleared(expenseId);
      if (mounted) {
        _showSnackBar('Expense marked as cleared', isError: false);
        _loadGroupDetails();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to mark as cleared: $e', isError: true);
      }
    }
  }

  Future<void> _toggleSplit(
    String splitId,
    bool isSettled,
    String expenseId,
  ) async {
    try {
      // Optimistic Update (Optional) or just wait for load
      // For simplicity, we wait for the server
      await _expenseService.toggleSplitSettlement(
        splitId: splitId,
        isSettled: isSettled,
        expenseId: expenseId,
      );
      if (mounted) {
        // No snackbar needed for granular toggles to avoid spam, maybe small haptic feedback if possible
        _loadGroupDetails();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to update split: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.danger500 : AppColors.success500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
