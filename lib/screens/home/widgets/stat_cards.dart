// ============================================
// FILE: lib/screens/home/widgets/stat_cards.dart
// Stat Cards Widget (Receivable & Payable)
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairshare/riverpod/home_data_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class StatCards extends ConsumerWidget {
  const StatCards({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receivable = ref.watch(totalReceivableProvider);
    final payable = ref.watch(totalPayableProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'You\'ll Receive',
              'Rs ${receivable.toStringAsFixed(2)}',
              const Color(0xFF22C55E),
              Icons.arrow_downward_rounded,
              true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'You\'ll Pay',
              'Rs ${payable.toStringAsFixed(2)}',
              const Color(0xFFEF4444),
              Icons.arrow_upward_rounded,
              false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String amount,
    Color color,
    IconData icon,
    bool isPositive,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: GoogleFonts.inter(
              color: const Color(0xFF0F172A),
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
