// ============================================
// FILE: lib/screens/home/home_screen.dart
// Modern Home Screen - With Unified Balance Card
// ============================================

import 'package:fairshare/screens/home/widgets/balance_card.dart';
import 'package:fairshare/riverpod/user_budget_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fairshare/riverpod/home_data_provider.dart';
import 'package:fairshare/screens/home/widgets/home_background.dart';
import 'package:fairshare/screens/home/widgets/home_header.dart';
import 'package:fairshare/screens/home/widgets/error_card.dart';
import 'package:fairshare/screens/home/widgets/analytics_section.dart';
import 'package:fairshare/screens/home/widgets/groups_section.dart';
import 'package:fairshare/screens/home/widgets/transactions_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    
    // ADDED: Add lifecycle observer to detect when screen becomes visible
    WidgetsBinding.instance.addObserver(this);
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    // ADDED: Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    _animationController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ADDED: Lifecycle handler to refresh budget when app resumes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // When app comes to foreground, refresh budget data
    if (state == AppLifecycleState.resumed) {
      ref.read(userBudgetProvider.notifier).onExpenseChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final error = ref.watch(homeErrorProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: Stack(
        children: [
          // Enhanced Animated Background
          HomeBackground(size: size, animationController: _animationController),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Compact Header
                HomeHeader(fadeController: _fadeController),

                const SizedBox(height: 24),

                // Main Scrollable Content
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FB),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await Future.wait([
                          ref.read(homeDataProvider.notifier).refresh(),
                          ref.read(userBudgetProvider.notifier).refresh(),
                        ]);
                      },
                      color: const Color(0xFF14B8A6),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.only(bottom: 100),
                        child: Column(
                          children: [
                            const SizedBox(height: 28),

                            // Show error if exists
                            if (error != null) ErrorCard(error: error),

                            // Unified Balance Card (ATM Card Style)
                            UnifiedBalanceCard(
                              fadeController: _fadeController,
                              slideController: _slideController,
                            ),

                            const SizedBox(height: 20),

                            // Analytics Insights - Horizontal Scroll Charts
                            AnalyticsSection(slideController: _slideController),

                            const SizedBox(height: 28),

                            // Quick Action Groups
                            const GroupsSection(),

                            const SizedBox(height: 28),

                            // Recent Transactions
                            const TransactionsSection(),
                          ],
                        ),
                      ),
                    ),
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
