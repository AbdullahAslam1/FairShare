import 'package:fairshare/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BudgetOverviewCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const BudgetOverviewCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats['hasBudget'] != true) return const SizedBox.shrink();

    final weekly = stats['weekly'] as Map<String, dynamic>?;
    final monthly = stats['monthly'] as Map<String, dynamic>?;

    if (weekly == null || monthly == null) return const SizedBox.shrink();

    final showWeekly = (weekly['limit'] as double) > 0;
    final showMonthly = (monthly['limit'] as double) > 0;

    if (!showWeekly && !showMonthly) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Overview',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 20),
            if (showWeekly) ...[
              _buildBudgetBar(
                label: 'Weekly',
                spent: weekly['spent'] as double,
                limit: weekly['limit'] as double,
                status: weekly['status'] as String,
              ),
              if (showMonthly) const SizedBox(height: 20),
            ],
            if (showMonthly)
              _buildBudgetBar(
                label: 'Monthly',
                spent: monthly['spent'] as double,
                limit: monthly['limit'] as double,
                status: monthly['status'] as String,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetBar({
    required String label,
    required double spent,
    required double limit,
    required String status,
  }) {
    final progress = (spent / limit).clamp(0.0, 1.0);
    final color = status == 'Over Budget'
        ? Colors.red[500]!
        : status == 'Near Limit'
        ? Colors.orange[500]!
        : AppColors.teal600;

    final percentage = (limit > 0)
        ? (spent / limit * 100).toStringAsFixed(0)
        : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Rs ${spent.toStringAsFixed(0)} / ${limit.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 10,
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$percentage%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              status,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
