import 'package:fairshare/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BudgetInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String helperText;
  final String currency;
  final String? Function(String?)? validator; // Made optional

  const BudgetInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    required this.helperText,
    required this.currency,
    this.validator, // Optional parameter
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textTertiary),
            suffixText: currency,
            hintText: '0.00',
            filled: true,
            fillColor: Colors.white,
            helperText: helperText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.neutral200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.neutral200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.teal600, width: 2),
            ),
          ),
          style: GoogleFonts.inter(fontSize: 16),
          validator:
              validator ??
              (value) {
                if (value == null || value.isEmpty) return null; // Optional
                final number = double.tryParse(value);
                if (number == null) return 'Please enter a valid amount';
                if (number < 0) return 'Amount cannot be negative';
                return null;
              },
        ),
      ],
    );
  }
}
