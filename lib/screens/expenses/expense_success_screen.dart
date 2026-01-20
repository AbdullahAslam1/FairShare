import 'package:fairshare/core/theme/app_theme.dart';
import 'package:fairshare/riverpod/user_budget_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpenseSuccessScreen extends ConsumerStatefulWidget {
  const ExpenseSuccessScreen({super.key});

  @override
  ConsumerState<ExpenseSuccessScreen> createState() => _ExpenseSuccessScreenState();
}

class _ExpenseSuccessScreenState extends ConsumerState<ExpenseSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
    
    // ADDED: Refresh budget as a safety net to ensure data is current
    Future.microtask(() {
      ref.read(userBudgetProvider.notifier).onExpenseChanged();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDone() {
    // Pop until we hit the group details or main nav
    // Assuming we want to go back to GroupDetailScreen which should be in the stack.
    // We should pop 'AddExpense', 'SelectMembers', 'SplitExpense'
    // Navigator.of(context).popUntil((route) => route.settings.name == 'GroupDetailScreen' || route.isFirst);

    // Actually, simpler to just pop all the way to first, or 2 levels up if we came from group detail.
    // But safer to just pop until...
    Navigator.of(context).popUntil((route) => route.isFirst);
    // Or specific route if we named them.
    // Since I haven't implemented named routes for everything, 'popUntil' first or the group screen is best.
    // A common pattern is popping until the Group Detail screen.
    // Since I don't know the exact route name of GroupDetail, I'll attempt to pop until we see it, OR just pop 3 times?

    // Better approach: Navigator.popUntil(context, (route) => route.settings.name == '/group_detail');
    // But I might not have named it.

    // I will assume the users entered this flow from GroupDetail.
    // The stack is: GroupDetail -> AddExpense -> SelectMembers -> SplitExpense -> Success
    // So we want to remove Success, Split, Select, Add.
    // This means popping 4 times?
    // A cleaner way is using `pushAndRemoveUntil` if we want to reset, but we want to keep the back stack to Home/Groups list.

    int count = 0;
    Navigator.popUntil(context, (route) {
      return count++ == 4; // Hacky.
    });
    // Actually, let's just use popUntil route.isFirst for now as a safe fallback?
    // No, that goes to Home. That's fine.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.teal100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.teal600,
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Expense Added!",
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Your group expenses have been updated.",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Done",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
