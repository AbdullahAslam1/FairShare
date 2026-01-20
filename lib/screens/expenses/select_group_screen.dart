import 'package:fairshare/core/theme/app_theme.dart';
import 'package:fairshare/model/group.dart';
import 'package:fairshare/screens/expenses/add_expense_screen.dart';
import 'package:fairshare/services/group_services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SelectGroupScreen extends StatefulWidget {
  const SelectGroupScreen({super.key});

  @override
  State<SelectGroupScreen> createState() => _SelectGroupScreenState();
}

class _SelectGroupScreenState extends State<SelectGroupScreen>
    with SingleTickerProviderStateMixin {
  final GroupService _groupService = GroupService();
  late TabController _tabController;

  // Groups State
  List<Group> _groups = [];
  bool _isLoadingGroups = true;

  // Friends State
  List<Map<String, dynamic>> _allFriends = [];
  List<Map<String, dynamic>> _filteredFriends = [];
  final Set<String> _selectedFriendIds = {};
  bool _isLoadingFriends = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isCreatingGroup = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGroups();
    _loadFriends();
    _searchController.addListener(_filterFriends);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await _groupService.getMyGroups();
      if (mounted) {
        setState(() {
          _groups = groups;
          _isLoadingGroups = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingGroups = false);
    }
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await _groupService.getAllKnownMembers();
      if (mounted) {
        setState(() {
          _allFriends = friends;
          _filteredFriends = friends;
          _isLoadingFriends = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingFriends = false);
    }
  }

  void _filterFriends() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFriends = _allFriends.where((friend) {
        final profile = friend['profiles'] ?? {};
        final name = (profile['full_name'] as String? ?? '').toLowerCase();
        final email = (profile['email'] as String? ?? '').toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  void _onGroupSelected(Group group) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(groupId: group.id),
      ),
    );
  }

  Future<void> _onFriendsSelected() async {
    if (_selectedFriendIds.isEmpty) return;

    setState(() => _isCreatingGroup = true);

    try {
      // Create a temporary group for these friends
      final group = await _groupService.findOrCreateGroupWithMembers(
        _selectedFriendIds.toList(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AddExpenseScreen(groupId: group.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create split: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingGroup = false);
    }
  }

  void _toggleFriend(String id) {
    setState(() {
      if (_selectedFriendIds.contains(id)) {
        _selectedFriendIds.remove(id);
      } else {
        _selectedFriendIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Slightly off-white background
      appBar: AppBar(
        title: Text(
          "New Expense",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.teal600,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
          indicatorColor: AppColors.teal600,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: "Groups"),
            Tab(text: "Friends"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGroupsTab(),
          _buildFriendsTab(),
        ],
      ),
    );
  }

  // ============================================
  // GROUPS TAB
  // ============================================

  Widget _buildGroupsTab() {
    if (_isLoadingGroups) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.teal600));
    }

    if (_groups.isEmpty) {
      return _buildEmptyState("No groups found", Icons.group_off_rounded);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        return _buildGroupCard(group);
      },
    );
  }

  Widget _buildGroupCard(Group group) {
    return GestureDetector(
      onTap: () => _onGroupSelected(group),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neutral200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.teal400, AppColors.teal600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to add expense',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppColors.neutral400),
          ],
        ),
      ),
    );
  }

  // ============================================
  // FRIENDS TAB
  // ============================================

  Widget _buildFriendsTab() {
    if (_isLoadingFriends) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.teal600));
    }

    return Stack(
      children: [
        Column(
          children: [
            // Search Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search friends...',
                  hintStyle: GoogleFonts.inter(color: AppColors.textTertiary),
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.neutral50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            
            // Friends List
            Expanded(
              child: _filteredFriends.isEmpty
                  ? _buildEmptyState(
                      _allFriends.isEmpty
                          ? "No friends found from groups"
                          : "No matches found",
                      Icons.person_off_rounded)
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, top: 8, bottom: 100),
                      itemCount: _filteredFriends.length,
                      itemBuilder: (context, index) {
                        final friend = _filteredFriends[index];
                        return _buildFriendCard(friend);
                      },
                    ),
            ),
          ],
        ),
        
        // Bottom Action Bar
        if (_selectedFriendIds.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24, // Safety margin
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                     color: AppColors.teal600.withOpacity(0.3),
                     blurRadius: 16,
                     offset: const Offset(0, 8),
                  )
                ]
              ),
              child: ElevatedButton(
                onPressed: _isCreatingGroup ? null : _onFriendsSelected,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal600,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isCreatingGroup
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Split with ${_selectedFriendIds.length} Friends",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    final userId = friend['user_id'] as String;
    final profile = friend['profiles'] ?? {};
    final name = profile['full_name'] as String? ?? 'Unknown';
    final email = profile['email'] as String? ?? '';
    final isSelected = _selectedFriendIds.contains(userId);

    return GestureDetector(
      onTap: () => _toggleFriend(userId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.teal50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.teal600 : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.teal100,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.outfit(
                  color: AppColors.teal800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.teal600, size: 24)
            else
              const Icon(Icons.circle_outlined,
                  color: AppColors.neutral300, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.neutral300),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
