import 'package:fairshare/core/theme/app_theme.dart';
import 'package:fairshare/model/group_budget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fairshare/screens/groups/widgets/budget_info_card.dart';
import 'package:fairshare/screens/groups/widgets/budget_input_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairshare/riverpod/budget_provider.dart';

class BudgetSettingsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const BudgetSettingsScreen({super.key, required this.groupId});

  @override
  ConsumerState<BudgetSettingsScreen> createState() =>
      _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends ConsumerState<BudgetSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _weeklyController;
  late TextEditingController _monthlyController;

  bool _isSaving = false;
  String _currency = 'Rs';

  @override
  void initState() {
    super.initState();
    _weeklyController = TextEditingController();
    _monthlyController = TextEditingController();
    // Initialize with current state if available (optional optimization)
    // But better to just load in post frame or let provider handle it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final budgetState = ref.read(budgetProvider(widget.groupId));
    if (budgetState.budget != null) {
      _populateFields(budgetState.budget!);
    }
  }

  void _populateFields(GroupBudget budget) {
    _weeklyController.text = budget.weeklyLimit > 0
        ? budget.weeklyLimit.toStringAsFixed(2)
        : '';
    _monthlyController.text = budget.monthlyLimit > 0
        ? budget.monthlyLimit.toStringAsFixed(2)
        : '';
    setState(() {
      _currency = budget.currency;
    });
  }

  @override
  void dispose() {
    _weeklyController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final weeklyLimit = double.tryParse(_weeklyController.text) ?? 0.0;
      final monthlyLimit = double.tryParse(_monthlyController.text) ?? 0.0;

      await ref
          .read(budgetProvider(widget.groupId).notifier)
          .updateBudget(weeklyLimit, monthlyLimit);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget updated successfully'),
            backgroundColor: AppColors.success500,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save budget: $e'),
            backgroundColor: AppColors.danger500,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Group Budget',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ref.watch(budgetProvider(widget.groupId)).isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BudgetInfoCard(),
                    const SizedBox(height: 24),
                    Text(
                      'Set Spending Limits',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 24),
                    BudgetInputField(
                      label: 'Weekly Limit',
                      controller: _weeklyController, 
                      icon: Icons.calendar_view_week_rounded,
                      helperText: 'Resets every Monday',
                      currency: _currency,
                    ),
                    const SizedBox(height: 16),
                    BudgetInputField(
                      label: 'Monthly Limit',
                      controller: _monthlyController,
                      icon: Icons.calendar_month_rounded,
                      helperText: 'Resets on the 1st of each month',
                      currency: _currency,
                    ),
                    const SizedBox(height: 48),
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
                                'Save Budget',
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
}
