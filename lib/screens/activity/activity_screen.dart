import 'package:fairshare/core/theme/app_theme.dart';
import 'package:fairshare/riverpod/group_provider.dart';
import 'package:fairshare/services/expense_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  final ExpenseService _expenseService = ExpenseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _activities = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    // Load data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActivity();
    });
  }

  Future<void> _loadActivity({bool forceRefresh = false}) async {
    if (mounted) setState(() => _isLoading = true);

    try {
      // 1. Ensure we have groups to fetch for
      final groupsState = ref.read(groupsProvider);
      var groups = groupsState.groups;

      // If no groups loaded yet, wait for them
      if (groups.isEmpty) {
        await ref
            .read(groupsProvider.notifier)
            .loadMyGroups(forceRefresh: forceRefresh);
        groups = ref.read(groupsProvider).groups;
      }

      if (groups.isEmpty) {
        if (mounted) {
          setState(() {
            _activities = [];
            _isLoading = false;
          });
        }
        return;
      }

      final groupIds = groups.map((g) => g.id).toList();

      // 2. Fetch recent activity (last 50 items)
      final expenses = await _expenseService.getExpensesForGroups(
        groupIds,
        limit: 50,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _activities = expenses;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading activity: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load activity';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadActivity(forceRefresh: true);
  }

  /// Group activities by date (Today, Yesterday, etc.)
  Map<String, List<Map<String, dynamic>>> _groupActivitiesByDate() {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (var activity in _activities) {
      final dateStr = activity['expense_date'] as String;
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final activityDate = DateTime(date.year, date.month, date.day);

      String header;
      if (activityDate == today) {
        header = 'Today';
      } else if (activityDate == yesterday) {
        header = 'Yesterday';
      } else {
        header = DateFormat('MMMM d, y').format(date);
      }

      grouped.putIfAbsent(header, () => []).add(activity);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_activities.isEmpty) {
      return _buildEmptyState();
    }

    final groupedActivities = _groupActivitiesByDate();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Activity',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.teal600,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: groupedActivities.length,
          itemBuilder: (context, index) {
            final header = groupedActivities.keys.elementAt(index);
            final items = groupedActivities[header]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 4,
                  ),
                  child: Text(
                    header.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                ...items.map((item) => _buildActivityItem(item)).toList(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> item) {
    final payer = item['profiles'];
    final category = item['expense_categories'];
    final amount = (item['amount'] as num).toDouble();
    final description = item['description'] as String;
    final date = DateTime.parse(item['expense_date']).toLocal();
    final time = DateFormat('h:mm a').format(date);

    // Determine icon and color based on category
    final iconData = category != null && category['icon'] != null
        ? _getIconData(category['icon'])
        : Icons.receipt_long_rounded;

    final colorHex = category != null ? category['color'] : null;
    final color = colorHex != null
        ? Color(int.parse(colorHex.replaceAll('#', '0xff')))
        : AppColors.teal600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(iconData, color: color, size: 24),
        ),
        title: Text(
          description,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              '${payer?['full_name'] ?? 'Someone'} paid',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '• $time',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        trailing: Text(
          'Rs ${amount.toStringAsFixed(2)}',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.danger500),
          const SizedBox(height: 16),
          Text(
            'Could not load activity',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextButton(onPressed: _onRefresh, child: const Text('Try Again')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'No recent activity',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper to map icon names to IconData
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'movie':
        return Icons.movie_rounded;
      case 'flight':
        return Icons.flight_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'sports_esports':
        return Icons.sports_esports_rounded;
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'work':
        return Icons.work_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}
