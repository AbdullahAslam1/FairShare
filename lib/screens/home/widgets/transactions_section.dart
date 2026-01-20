// ============================================
// FILE: lib/screens/home/widgets/transactions_section.dart
// Transactions Section Widget
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairshare/riverpod/home_provider.dart';
import 'package:fairshare/riverpod/home_data_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionsSection extends ConsumerWidget {
  const TransactionsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(homeRecentExpensesProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(navigationProvider.notifier).state = 3;
                },
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF14B8A6),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Color(0xFF14B8A6),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (expenses.isEmpty)
            const EmptyTransactionsState()
          else
            ...expenses.take(3).map((expense) {
              final isPaidByUser = expense['paid_by'] == currentUserId;
              final category =
                  expense['expense_categories'] as Map<String, dynamic>?;
              final payer = expense['profiles'] as Map<String, dynamic>?;
              final amount = (expense['amount'] as num?)?.toDouble() ?? 0.0;
              final description =
                  expense['description'] as String? ?? 'Expense';
              final categoryName = category?['name'] as String? ?? 'General';
              final payerName = payer?['full_name'] as String? ?? 'Someone';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TransactionItem(
                  title: description,
                  subtitle: isPaidByUser
                      ? 'You paid for the group'
                      : '$payerName paid for the group',
                  amount: 'Rs ${amount.toStringAsFixed(2)}',
                  isPaid: isPaidByUser,
                  icon: _getCategoryIcon(categoryName),
                  iconColor: _getCategoryColor(categoryName),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'restaurant':
      case 'dining':
        return Icons.restaurant_rounded;
      case 'transport':
      case 'travel':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'utilities':
      case 'bills':
        return Icons.bolt_rounded;
      case 'groceries':
        return Icons.shopping_cart_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'restaurant':
      case 'dining':
        return const Color(0xFFEF4444);
      case 'transport':
      case 'travel':
        return const Color(0xFF3B82F6);
      case 'shopping':
        return const Color(0xFFF59E0B);
      case 'entertainment':
        return const Color(0xFF8B5CF6);
      case 'utilities':
      case 'bills':
        return const Color(0xFFF59E0B);
      case 'groceries':
        return const Color(0xFF14B8A6);
      default:
        return const Color(0xFF64748B);
    }
  }
}

class EmptyTransactionsState extends StatelessWidget {
  const EmptyTransactionsState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF14B8A6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF14B8A6),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Recent Activity',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your recent expenses will appear here',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class TransactionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final bool isPaid;
  final IconData icon;
  final Color iconColor;

  const TransactionItem({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isPaid,
    required this.icon,
    required this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isPaid
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPaid
                      ? const Color(0xFFEF4444).withOpacity(0.1)
                      : const Color(0xFF22C55E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPaid ? 'Paid' : 'Received',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isPaid
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF22C55E),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
