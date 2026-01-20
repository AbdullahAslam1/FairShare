import 'package:fairshare/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BudgetInfoCard extends StatelessWidget {
  const BudgetInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.teal50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.teal100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.teal600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Budgets help your group track spending. Expenses are calculated based on the date they occurred.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.teal700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
