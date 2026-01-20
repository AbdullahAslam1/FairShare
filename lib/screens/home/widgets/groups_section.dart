// ============================================
// FILE: lib/screens/home/widgets/groups_section.dart
// Groups Section Widget
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairshare/riverpod/home_provider.dart';
import 'package:fairshare/riverpod/home_data_provider.dart';
import 'package:fairshare/model/group.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupsSection extends ConsumerWidget {
  const GroupsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(homeGroupsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Groups',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(navigationProvider.notifier).state = 1;
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
        ),
        const SizedBox(height: 16),
        if (groups.isEmpty)
          const EmptyGroupsState()
        else
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: groups.length > 5 ? 5 : groups.length,
              itemBuilder: (context, index) =>
                  GroupCard(group: groups[index], index: index),
            ),
          ),
      ],
    );
  }
}

class EmptyGroupsState extends StatelessWidget {
  const EmptyGroupsState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(32),
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
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF14B8A6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.group_add_rounded,
                color: Color(0xFF14B8A6),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Groups Yet',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a group to start splitting expenses',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class GroupCard extends StatelessWidget {
  final Group group;
  final int index;

  const GroupCard({
    Key? key,
    required this.group,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gradients = [
      [const Color(0xFF14B8A6), const Color(0xFF0D9488)],
      [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
      [const Color(0xFF22C55E), const Color(0xFF16A34A)],
      [const Color(0xFFEF4444), const Color(0xFFDC2626)],
    ];
    final icons = [
      Icons.home_rounded,
      Icons.flight_takeoff_rounded,
      Icons.celebration_rounded,
      Icons.shopping_bag_rounded,
      Icons.restaurant_rounded,
    ];

    final colorIndex = index % gradients.length;

    return GestureDetector(
      onTap: () {
        // Navigate to group detail screen
        // Navigator.pushNamed(context, '/group-detail', arguments: group.id);
      },
      child: Container(
        width: 160,
        height: 120,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradients[colorIndex],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradients[colorIndex][0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icons[colorIndex], color: Colors.white, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${group.memberCount ?? 0}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              group.name,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to view',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
