import 'package:fairshare/core/theme/app_theme.dart';
import 'package:fairshare/model/group.dart';
import 'package:fairshare/riverpod/group_provider.dart';
import 'package:fairshare/screens/groups/create_group.dart';
import 'package:fairshare/screens/groups/group_detail.dart';
import 'package:fairshare/services/expense_service.dart';
import 'package:fairshare/services/group_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupsListScreen extends ConsumerStatefulWidget {
  const GroupsListScreen({super.key});

  @override
  ConsumerState<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends ConsumerState<GroupsListScreen>
    with TickerProviderStateMixin {
  final ExpenseService _expenseService = ExpenseService();
  final GroupService _groupService = GroupService();

  Map<String, int> _memberCounts = {};
  Map<String, int> _expenseCounts = {};
  List<Map<String, dynamic>> _personalExpenses = [];

  String _searchQuery = '';
  bool _isLoadingCounts = false;

  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint('🔄 GroupsListScreen: initState()');

    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();

    // Load data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAdditionalData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAdditionalData({bool forceRefresh = false}) async {
    if (_isLoadingCounts) return; // Prevent concurrent loading

    debugPrint('🔄 Loading additional data (counts & personal expenses)...');
    setState(() => _isLoadingCounts = true);

    try {
      await Future.wait([
        _loadGroupCounts(forceRefresh: forceRefresh),
        _loadPersonalExpenses(forceRefresh: forceRefresh),
      ]);
      debugPrint('✅ Additional data loaded');
    } catch (e) {
      debugPrint('❌ Error loading additional data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingCounts = false);
      }
    }
  }

  Future<void> _onRefresh() async {
    debugPrint('🔄 Pull-to-refresh triggered');
    try {
      // Refresh groups from provider first
      await ref.read(groupsProvider.notifier).refreshGroups();

      // Then reload additional data
      await _loadAdditionalData(forceRefresh: true);

      if (mounted) {
        _animationController.forward(from: 0.0);
      }

      debugPrint('✅ Refresh complete');
    } catch (e) {
      debugPrint('❌ Error refreshing: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to refresh');
      }
    }
  }

  Future<void> _loadGroupCounts({bool forceRefresh = false}) async {
    try {
      debugPrint('🔄 Loading group counts...');
      final groupsState = ref.read(groupsProvider);
      final groups = groupsState.groups;

      if (groups.isEmpty) {
        debugPrint('⚠️ No groups to load counts for');
        if (mounted) {
          setState(() {
            _memberCounts = {};
            _expenseCounts = {};
          });
        }
        return;
      }

      final memberCounts = <String, int>{};
      final expenseCounts = <String, int>{};

      await Future.wait(
        groups.map((group) async {
          try {
            final members = await _groupService.getGroupMembers(group.id);
            memberCounts[group.id] = members.length;

            final expenses = await _expenseService.getGroupExpenses(
              group.id,
              forceRefresh: forceRefresh,
            );
            expenseCounts[group.id] = expenses.length;
          } catch (e) {
            debugPrint('❌ Error loading counts for ${group.id}: $e');
            memberCounts[group.id] = 0;
            expenseCounts[group.id] = 0;
          }
        }),
      );

      if (mounted) {
        setState(() {
          _memberCounts = memberCounts;
          _expenseCounts = expenseCounts;
        });
        debugPrint('✅ Group counts loaded: $_memberCounts');
      }
    } catch (e) {
      debugPrint('❌ Error loading group counts: $e');
    }
  }

  Future<void> _loadPersonalExpenses({bool forceRefresh = false}) async {
    try {
      debugPrint('🔄 Loading personal expenses...');

      final groupsState = ref.read(groupsProvider);
      final allGroups = groupsState.groups;

      final personalGroups = allGroups
          .where((g) => g.name.startsWith('Split with'))
          .toList();

      debugPrint('📊 Found ${personalGroups.length} personal groups');

      final personalExpenses = <Map<String, dynamic>>[];

      await Future.wait(
        personalGroups.map((group) async {
          try {
            final expenses = await _expenseService.getGroupExpenses(
              group.id,
              forceRefresh: forceRefresh,
            );
            if (expenses.isNotEmpty) {
              personalExpenses.add({
                'group': group,
                'expense_count': expenses.length,
              });
            }
          } catch (e) {
            debugPrint('❌ Error loading expenses for ${group.id}: $e');
          }
        }),
      );

      if (mounted) {
        setState(() {
          _personalExpenses = personalExpenses;
        });
        debugPrint(
          '✅ Personal expenses loaded: ${personalExpenses.length} items',
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading personal expenses: $e');
    }
  }

  List<Group> get _filteredGroups {
    final groupsState = ref.watch(groupsProvider);
    final groups = groupsState.groups;

    if (_searchQuery.isEmpty) return groups;
    return groups.where((group) {
      return group.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredPersonalExpenses {
    if (_searchQuery.isEmpty) return _personalExpenses;
    return _personalExpenses.where((item) {
      final group = item['group'] as Group;
      return group.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final groupsState = ref.watch(groupsProvider);
    final isLoading = groupsState.isLoading;
    final hasError = groupsState.error != null;

    debugPrint(
      '🎨 Building GroupsListScreen - isLoading: $isLoading, hasError: $hasError, groups: ${groupsState.groups.length}',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isLoading && groupsState.groups.isEmpty
          ? _buildLoadingState()
          : hasError
          ? _buildErrorState(groupsState.error!)
          : RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.teal600,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [_buildEnhancedAppBar(), _buildTabBar()];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [_buildGroupsTab(), _buildPersonalTab()],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateGroup(),
        backgroundColor: AppColors.teal600,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Create Group',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        _buildEnhancedAppBar(),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.teal600),
                const SizedBox(height: 16),
                Text(
                  'Loading groups...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return CustomScrollView(
      slivers: [
        _buildEnhancedAppBar(),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.danger500),
                const SizedBox(height: 16),
                Text(
                  'Failed to load groups',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    error,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    'Try Again',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedAppBar() {
    return SliverAppBar(
      expandedHeight: 80.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _onRefresh,
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.teal600, AppColors.teal700, AppColors.teal800],
            ),
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'My Groups',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.teal600,
          indicatorWeight: 3,
          labelColor: AppColors.teal600,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Groups'),
            Tab(text: 'Personal'),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsTab() {
    return CustomScrollView(
      slivers: [
        _buildSearchBar(),
        if (_filteredGroups.isEmpty)
          _searchQuery.isEmpty ? _buildEmptyState() : _buildNoResults()
        else
          _buildGroupsList(_filteredGroups),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: GoogleFonts.inter(
                color: AppColors.textTertiary,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.teal600,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.textTertiary,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupsList(List<Group> groups) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return _buildGroupCard(group: groups[index], index: index);
        }, childCount: groups.length),
      ),
    );
  }

  Widget _buildGroupCard({required Group group, required int index}) {
    final colors = [
      [AppColors.teal600, AppColors.teal700],
      [AppColors.purple600, AppColors.purple700],
      [AppColors.success500, AppColors.success600],
      [AppColors.warning500, AppColors.warning600],
    ];
    final colorPair = colors[index % colors.length];
    final memberCount = _memberCounts[group.id] ?? 0;
    final expenseCount = _expenseCounts[group.id] ?? 0;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              (index * 0.08).clamp(0.0, 0.6),
              ((index * 0.08) + 0.4).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        );

        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      child: Container(
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToGroupDetail(group.id),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colorPair),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.group_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildInfoChip(
                              icon: Icons.people_rounded,
                              text:
                                  '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                              color: colorPair[0],
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              icon: Icons.receipt_long_rounded,
                              text:
                                  '$expenseCount ${expenseCount == 1 ? 'expense' : 'expenses'}',
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalTab() {
    return CustomScrollView(
      slivers: [
        _buildSearchBar(),
        if (_filteredPersonalExpenses.isEmpty)
          _buildEmptyPersonalState()
        else
          _buildPersonalExpensesList(_filteredPersonalExpenses),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  Widget _buildPersonalExpensesList(List<Map<String, dynamic>> items) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          final group = item['group'] as Group;
          final expenseCount = item['expense_count'] as int;
          return _buildPersonalExpenseCard(
            group: group,
            expenseCount: expenseCount,
            index: index,
          );
        }, childCount: items.length),
      ),
    );
  }

  Widget _buildPersonalExpenseCard({
    required Group group,
    required int expenseCount,
    required int index,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              (index * 0.08).clamp(0.0, 0.6),
              ((index * 0.08) + 0.4).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        );

        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      child: Container(
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToGroupDetail(group.id),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.purple600, AppColors.purple700],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoChip(
                          icon: Icons.receipt_long_rounded,
                          text:
                              '$expenseCount ${expenseCount == 1 ? 'expense' : 'expenses'}',
                          color: AppColors.purple600,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.teal50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups_rounded,
                size: 48,
                color: AppColors.teal600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No groups yet',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first group to start\nsplitting expenses',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateGroup(),
              icon: const Icon(Icons.add_circle_rounded, size: 20),
              label: Text(
                'Create Group',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPersonalState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.neutral400,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                size: 48,
                color: AppColors.background,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No personal expenses',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add expenses with friends to see\nthem here',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateGroup() async {
    debugPrint('🔄 Navigating to Create Group screen');
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
      );

      if (result != null && mounted) {
        debugPrint('✅ Group created, refreshing...');
        await _onRefresh(); // Use the unified refresh method
        _showSuccessSnackBar('Group created successfully!');
      }
    } catch (e) {
      debugPrint('❌ Error after creating group: $e');
    }
  }

  void _navigateToGroupDetail(String groupId) async {
    try {
      final groupsState = ref.read(groupsProvider);
      final group = groupsState.groups.firstWhere((g) => g.id == groupId);

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupDetailScreen(group: group),
        ),
      );

      if (mounted) {
        if (result == 'updated' || result == 'deleted') {
          debugPrint('✅ Group changed ($result), refreshing...');
          await _onRefresh(); // Use the unified refresh method

          if (result == 'deleted') {
            _showSuccessSnackBar('Group deleted successfully!');
          } else {
            _showSuccessSnackBar('Group updated successfully!');
          }
        } else {
          // Just reload counts if group was viewed without changes
          await _loadGroupCounts();
        }
      }
    } catch (e) {
      debugPrint('❌ Error navigating to group detail: $e');
      _showErrorSnackBar('Error finding group');
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.danger500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.background, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
