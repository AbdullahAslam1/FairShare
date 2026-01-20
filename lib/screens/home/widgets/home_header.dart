// ============================================
// FILE: lib/screens/home/widgets/home_header.dart
// Home Screen Header Widget
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairshare/riverpod/home_data_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeHeader extends ConsumerWidget {
  final AnimationController fadeController;

  const HomeHeader({
    Key? key,
    required this.fadeController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userDisplayNameProvider);
    final userInitials = ref.watch(userInitialsProvider);

    return FadeTransition(
      opacity: fadeController,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Profile Avatar with online indicator
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF14B8A6), Color(0xFF8B5CF6)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF14B8A6).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          userInitials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0A0E27),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Action buttons
            Row(
              children: [
                _buildHeaderIconButton(Icons.search_rounded),
                const SizedBox(width: 8),
                _buildHeaderIconButton(
                  Icons.notifications_rounded,
                  hasNotification: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton(IconData icon, {bool hasNotification = false}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Stack(
        children: [
          Center(child: Icon(icon, color: Colors.white, size: 20)),
          if (hasNotification)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
