// ============================================
// FILE: lib/screens/home/widgets/unified_balance_card.dart
// Balance Card - Updated Layout with Status Badge
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairshare/riverpod/home_data_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class UnifiedBalanceCard extends ConsumerWidget {
  final AnimationController fadeController;
  final AnimationController slideController;

  const UnifiedBalanceCard({
    Key? key,
    required this.fadeController,
    required this.slideController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netBalance = ref.watch(netBalanceProvider);
    final receivable = ref.watch(totalReceivableProvider);
    final payable = ref.watch(totalPayableProvider);

    // Determine status
    final isProfit = receivable > payable;
    final isBalanced = receivable == payable;

    // Colors based on status
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isProfit) {
      statusColor = const Color(0xFF10B981); // Green for profit
      statusText = 'PROFIT';
      statusIcon = Icons.trending_up_rounded;
    } else if (isBalanced) {
      statusColor = Colors.white; // White for balanced
      statusText = 'BALANCED';
      statusIcon = Icons.balance_rounded;
    } else {
      statusColor = const Color(0xFFEF4444); // Red for debt
      statusText = 'DEBT';
      statusIcon = Icons.trending_down_rounded;
    }

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: slideController,
              curve: Curves.easeOutCubic,
            ),
          ),
      child: FadeTransition(
        opacity: fadeController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F766E), // teal700
                  Color(0xFF115E59), // teal800
                  Color(0xFF134E4A), // teal900
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Subtle pattern overlay
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.05,
                      child: CustomPaint(painter: _DotPatternPainter()),
                    ),
                  ),

                  // Card Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Section - Net Balance + Status Badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Net Balance (Left)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Label with icon
                                  Row(
                                    children: [
                                      Icon(
                                        isProfit
                                            ? Icons.trending_up_rounded
                                            : isBalanced
                                            ? Icons.balance_rounded
                                            : Icons.trending_down_rounded,
                                        color: Colors.white.withOpacity(0.7),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Net Balance',
                                        style: GoogleFonts.inter(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Balance Amount
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          'Rs',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          netBalance.abs().toStringAsFixed(2),
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 42,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -1.5,
                                            height: 1.0,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Status Badge (Right)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, color: statusColor, size: 24),
                                const SizedBox(height: 4),
                                Text(
                                  statusText,
                                  style: GoogleFonts.inter(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Bottom Section - Two Cards Side by Side
                        Row(
                          children: [
                            // You Will Receive Section
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.arrow_downward_rounded,
                                          color: const Color(0xFF10B981),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'You will receive',
                                            style: GoogleFonts.inter(
                                              color: Colors.white.withOpacity(
                                                0.85,
                                              ),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Rs ${receivable.toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF10B981),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // You Have to Pay Section
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.arrow_upward_rounded,
                                          color: const Color.fromARGB(
                                            255,
                                            210,
                                            41,
                                            41,
                                          ),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'You have to pay',
                                            style: GoogleFonts.inter(
                                              color: Colors.white.withOpacity(
                                                0.85,
                                              ),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Rs ${payable.toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(
                                        color: const Color.fromARGB(
                                          255,
                                          210,
                                          41,
                                          41,
                                        ),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Dot pattern painter for subtle texture
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
