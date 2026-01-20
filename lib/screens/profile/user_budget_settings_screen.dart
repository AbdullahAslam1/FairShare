import 'package:fairshare/core/theme/app_theme.dart';
import 'package:fairshare/model/user_budget.dart';
import 'package:fairshare/riverpod/user_budget_provider.dart';
import 'package:fairshare/screens/groups/widgets/budget_info_card.dart';
import 'package:fairshare/screens/groups/widgets/budget_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class UserBudgetSettingsScreen extends ConsumerStatefulWidget {
  const UserBudgetSettingsScreen({super.key});

  @override
  ConsumerState<UserBudgetSettingsScreen> createState() =>
      _UserBudgetSettingsScreenState();
}

class _UserBudgetSettingsScreenState
    extends ConsumerState<UserBudgetSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _weeklyController;
  late TextEditingController _monthlyController;

  bool _isSaving = false;
  bool _hasInitialized = false; // ADDED: Track if we've populated fields

  @override
  void initState() {
    super.initState();
    _weeklyController = TextEditingController();
    _monthlyController = TextEditingController();

    // Load budget data on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userBudgetProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _weeklyController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }

  // FIXED: Better validation logic
  String? _validateWeeklyLimit(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a weekly limit';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid number';
    }

    if (amount < 0) {
      return 'Amount cannot be negative';
    }

    if (amount > 1000000) {
      return 'Amount is too large';
    }

    // Check if weekly > 1.5x monthly
    final monthlyText = _monthlyController.text;
    if (monthlyText.isNotEmpty) {
      final monthly = double.tryParse(monthlyText);
      if (monthly != null && monthly > 0 && amount > monthly * 1.5) {
        return 'Weekly limit too high for monthly budget';
      }
    }

    return null;
  }

  String? _validateMonthlyLimit(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a monthly limit';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid number';
    }

    if (amount < 0) {
      return 'Amount cannot be negative';
    }

    if (amount > 10000000) {
      return 'Amount is too large';
    }

    return null;
  }

  Future<void> _saveBudget() async {
    // Clear any existing errors
    ref.read(userBudgetProvider.notifier).clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final weeklyLimit = double.parse(_weeklyController.text);
      final monthlyLimit = double.parse(_monthlyController.text);

      await ref
          .read(userBudgetProvider.notifier)
          .updateLimits(weekly: weeklyLimit, monthly: monthlyLimit);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Personal budget updated successfully'),
                ),
              ],
            ),
            backgroundColor: AppColors.success500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to save budget: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppColors.danger500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(userBudgetProvider);

    // FIXED: Populate fields only once when data loads
    ref.listen(userBudgetProvider, (previous, next) {
      if (!_hasInitialized && !next.isLoading && next.error == null) {
        // Only populate if user hasn't typed anything yet
        if (_weeklyController.text.isEmpty && next.budget.weeklyLimit > 0) {
          _weeklyController.text = next.budget.weeklyLimit.toStringAsFixed(0);
        }
        if (_monthlyController.text.isEmpty && next.budget.monthlyLimit > 0) {
          _monthlyController.text = next.budget.monthlyLimit.toStringAsFixed(0);
        }
        _hasInitialized = true;
      }

      // Show error snackbar if loading failed
      if (next.error != null && previous?.error != next.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading budget: ${next.error}'),
                backgroundColor: AppColors.danger500,
              ),
            );
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Personal Budget',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          // ADDED: Info button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'About Personal Budget',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  content: Text(
                    'Your personal budget tracks all your expenses across all groups.\n\n'
                    '• Weekly limit resets every Monday\n'
                    '• Monthly limit resets on the 1st\n'
                    '• Get alerts when you reach 80% of your limit\n\n'
                    'This helps you stay within your spending goals!',
                    style: GoogleFonts.inter(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: budgetState.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your budget...',
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card
                    const BudgetInfoCard(),
                    const SizedBox(height: 24),

                    // ADDED: Current spending overview
                    if (budgetState.hasBudgetSet) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.teal50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.teal200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  color: AppColors.teal600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Current Spending',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.teal900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSpendingItem(
                                    'This Week',
                                    budgetState.weeklySpent,
                                    budgetState.budget.weeklyLimit,
                                    budgetState.weeklyPercentage,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildSpendingItem(
                                    'This Month',
                                    budgetState.monthlySpent,
                                    budgetState.budget.monthlyLimit,
                                    budgetState.monthlyPercentage,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    Text(
                      'Set Personal Limits',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'These limits apply to your total spending across all groups.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // FIXED: Added validation
                    BudgetInputField(
                      label: 'Weekly Limit',
                      controller: _weeklyController,
                      icon: Icons.calendar_view_week_rounded,
                      helperText: 'Resets every Monday',
                      currency: budgetState.budget.currency,
                      validator: _validateWeeklyLimit,
                    ),

                    const SizedBox(height: 16),

                    BudgetInputField(
                      label: 'Monthly Limit',
                      controller: _monthlyController,
                      icon: Icons.calendar_month_rounded,
                      helperText: 'Resets on the 1st of each month',
                      currency: budgetState.budget.currency,
                      validator: _validateMonthlyLimit,
                    ),

                    const SizedBox(height: 48),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveBudget,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal600,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: AppColors.teal300,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Save Settings',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ADDED: Helper widget for spending overview
  Widget _buildSpendingItem(
    String label,
    double spent,
    double limit,
    double percentage,
  ) {
    final isOverBudget = limit > 0 && spent > limit;
    final color = isOverBudget
        ? AppColors.danger500
        : percentage > 80
        ? AppColors.warning500
        : AppColors.teal600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Rs ${spent.toStringAsFixed(0)}',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        if (limit > 0) ...[
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(0)}% of Rs ${limit.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
