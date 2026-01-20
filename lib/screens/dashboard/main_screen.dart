// ============================================
// FILE: lib/screens/dashboard/main_screen.dart
// Main Screen with Smart FAB Management
// ============================================

import 'package:fairshare/core/theme/app_theme.dart';
import 'package:fairshare/riverpod/home_provider.dart';
import 'package:fairshare/screens/groups/groups_list_screen.dart';
import 'package:fairshare/screens/home/home_screen.dart';
import 'package:fairshare/screens/profile/profile_screen.dart';
import 'package:fairshare/screens/groups/create_group.dart';
import 'package:fairshare/screens/expenses/select_group_screen.dart';
import 'package:fairshare/screens/activity/activity_screen.dart';
import 'package:fairshare/widgets/navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);

    // Define all screens
    final screens = [
      const HomeScreen(), // Index 0
      const GroupsListScreen(), // Index 1 - GROUPS SCREEN
      _buildPlaceholderScreen('Add Expense', Icons.add_rounded), // Index 2
      const ActivityScreen(), // Index 3 - ACTIVITY
      _buildPlaceholderScreen('Profile', Icons.person_rounded), // Index 4
    ];

    // Trigger FAB animation when switching to Groups screen
    if (currentIndex == 1) {
      _fabController.forward();
    } else {
      _fabController.reverse();
    }

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      extendBody: true, // CRITICAL for transparent navbar overlay
      bottomNavigationBar: CustomBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 2) {
             // Add Expense Flow
             Navigator.push(
               context,
               MaterialPageRoute(builder: (context) => const SelectGroupScreen()),
             );
          } else {
             ref.read(navigationProvider.notifier).state = index;
          }
        },
      ),
      // Show FAB only on Groups screen (index 1)
      floatingActionButton: currentIndex == 1 ? _buildGroupsFAB() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ============================================
  // FAB FOR GROUPS SCREEN
  // ============================================

  Widget _buildGroupsFAB() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30), // Lift above navbar
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabController,
          curve: Curves.elasticOut,
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToCreateGroup(),
          backgroundColor: AppColors.teal600,
          icon: const Icon(Icons.add_rounded, size: 24),
          label: Text(
            'New Group',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // ============================================
  // NAVIGATION
  // ============================================

  void _navigateToCreateGroup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );
    // Provider will automatically update, no manual refresh needed
  }

  // ============================================
  // PLACEHOLDER SCREENS
  // ============================================

  Widget _buildPlaceholderScreen(String title, IconData icon) {
    // If the title is "Profile", return the ProfileScreen directly
    if (title.toLowerCase().contains("profile")) {
      return ProfileScreen();
    }

    // Original implementation for other titles
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Coming Soon',
                style: TextStyle(fontSize: 16, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
