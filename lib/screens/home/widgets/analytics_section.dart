// ============================================
// FILE: lib/screens/home/widgets/analytics_section.dart
// Analytics Section Widget (Charts) - FIXED with Real Data & Empty States
// ============================================

import 'dart:math' as math;
import 'package:fairshare/core/theme/app_theme.dart';
import 'package:fairshare/riverpod/user_budget_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AnalyticsSection extends ConsumerWidget {
  final AnimationController slideController;

  const AnalyticsSection({Key? key, required this.slideController})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(userBudgetProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Budget',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your spending across all groups',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              // FIXED: Show status based on actual state
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: budgetState.isLoading
                      ? Colors.grey.withOpacity(0.1)
                      : const Color(0xFF14B8A6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: budgetState.isLoading
                            ? Colors.grey
                            : const Color(0xFF14B8A6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      budgetState.isLoading ? 'Loading' : 'Live',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: budgetState.isLoading
                            ? Colors.grey
                            : const Color(0xFF14B8A6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // FIXED: Show loading, error, empty, or actual charts
        if (budgetState.isLoading)
          _buildLoadingState()
        else if (budgetState.error != null)
          _buildErrorState(budgetState.error!)
        else if (!budgetState.hasBudgetSet)
          _buildNoBudgetState(context)
        else
          SizedBox(
            height: 320, // FIXED: Increased from 280 to accommodate content
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                WeeklySpendingCard(slideController: slideController),
                const SizedBox(width: 16),
                MonthlyOverviewCard(slideController: slideController),
              ],
            ),
          ),
      ],
    );
  }

  // ADDED: Loading skeleton
  Widget _buildLoadingState() {
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading budget data...',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ADDED: Error state
  Widget _buildErrorState(String error) {
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.danger50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.danger200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.danger500),
            const SizedBox(height: 16),
            Text(
              'Failed to load budget',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.danger700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.danger600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ADDED: No budget set state
  Widget _buildNoBudgetState(BuildContext context) {
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.teal50, AppColors.teal100],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.teal200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: AppColors.teal600,
            ),
            const SizedBox(height: 16),
            Text(
              'Set Your Budget',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.teal900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your spending across all groups\nby setting weekly and monthly limits',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.teal700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/budget-settings');
              },
              icon: const Icon(Icons.add),
              label: Text(
                'Set Budget Now',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Weekly Spending Card - FIXED with Real Data & Empty State
class WeeklySpendingCard extends ConsumerWidget {
  final AnimationController slideController;

  const WeeklySpendingCard({Key? key, required this.slideController})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(userBudgetProvider);
    final chartData = budgetState.weeklyChartData;

    // FIXED: Get last 7 days dynamically
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final values = List<double>.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      final dateKey = DateTime(date.year, date.month, date.day);
      return chartData[dateKey] ?? 0.0;
    });

    // FIXED: Handle empty data
    final hasData = values.any((v) => v > 0);
    final maxValue = hasData ? values.reduce(math.max) : 1.0;
    final normalizedValues = maxValue > 0
        ? values.map((v) => v / maxValue).toList()
        : List<double>.filled(7, 0.0);

    final totalWeekly = budgetState.weeklySpent;
    final weeklyLimit = budgetState.budget.weeklyLimit;
    final percentage = weeklyLimit > 0
        ? (totalWeekly / weeklyLimit * 100).clamp(0, 100)
        : 0.0;

    return Container(
      width: 320,
      height: 320, // FIXED: Explicit height to prevent overflow
      padding: const EdgeInsets.all(20), // FIXED: Reduced padding from 24
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF14B8A6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Spending',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      weeklyLimit > 0
                          ? '${percentage.toStringAsFixed(0)}% of limit'
                          : 'No limit set',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // FIXED: Reduced spacing
          // FIXED: Show empty state or chart
          Expanded(
            child: hasData
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: TweenAnimationBuilder<double>(
                            duration: Duration(
                              milliseconds: 800 + (index * 100),
                            ),
                            curve: Curves.easeOutCubic,
                            tween: Tween(
                              begin: 0,
                              end: normalizedValues[index],
                            ),
                            builder: (context, value, child) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        height: 140 * value,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              const Color(0xFF14B8A6),
                                              const Color(
                                                0xFF14B8A6,
                                              ).withOpacity(0.6),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    days[index],
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    }),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No expenses this week',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Start adding expenses to see your chart',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),

          const SizedBox(height: 12), // FIXED: Reduced spacing
          Container(
            padding: const EdgeInsets.all(10), // FIXED: Reduced padding
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Spent',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Rs ${totalWeekly.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Monthly Overview Card - FIXED with Real Data & Better Status Colors
class MonthlyOverviewCard extends ConsumerWidget {
  final AnimationController slideController;

  const MonthlyOverviewCard({Key? key, required this.slideController})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(userBudgetProvider);
    final monthlySpent = budgetState.monthlySpent;
    final monthlyLimit = budgetState.budget.monthlyLimit;

    final percentage = monthlyLimit > 0
        ? (monthlySpent / monthlyLimit * 100).clamp(0, 100)
        : 0.0;

    // FIXED: Better status detection
    final isOverBudget = budgetState.isMonthlyOverBudget;
    final isNearLimit = budgetState.isMonthlyNearLimit;
    final hasSpending = monthlySpent > 0;

    // FIXED: Dynamic gradient colors based on status
    final gradientColors = isOverBudget
        ? [const Color(0xFFDC2626), const Color(0xFFB91C1C)]
        : isNearLimit
        ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
        : hasSpending
        ? [const Color(0xFF7C3AED), const Color(0xFF6D28D9)]
        : [const Color(0xFF64748B), const Color(0xFF475569)];

    return Container(
      width: 320,
      height: 320, // FIXED: Match weekly card height
      padding: const EdgeInsets.all(20), // FIXED: Reduced padding from 24
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isOverBudget
                      ? Icons.warning_rounded
                      : hasSpending
                      ? Icons.calendar_month_rounded
                      : Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Budget',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      monthlyLimit > 0
                          ? '${percentage.toStringAsFixed(0)}% used'
                          : hasSpending
                          ? 'No limit set'
                          : 'No expenses yet',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24), // FIXED: Reduced spacing
          // Circular Progress or Empty State
          Expanded(
            // FIXED: Made flexible to prevent overflow
            child: Center(
              child: hasSpending || monthlyLimit > 0
                  ? SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background circle
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value: 1.0,
                              strokeWidth: 12,
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          // Progress circle
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: percentage / 100),
                              duration: const Duration(milliseconds: 1500),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 12,
                                  color: Colors.white,
                                  strokeCap: StrokeCap.round,
                                );
                              },
                            ),
                          ),
                          // Center text
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                monthlyLimit > 0
                                    ? '${percentage.toStringAsFixed(0)}%'
                                    : 'Rs ${monthlySpent.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                monthlyLimit > 0 ? 'of limit' : 'spent',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 48,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No expenses yet',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          SizedBox(height: 16), // FIXED: Reduced spacing

          Container(
            padding: const EdgeInsets.all(10), // FIXED: Reduced padding
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Spent',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Rs ${monthlySpent.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (monthlyLimit > 0) ...[
                  const SizedBox(height: 6), // FIXED: Reduced spacing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Limit',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Rs ${monthlyLimit.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
