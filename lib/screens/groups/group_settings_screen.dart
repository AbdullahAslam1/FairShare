// ============================================
// FILE: lib/screens/groups/group_settings_screen.dart
// Comprehensive Group Settings Screen with Member Management
// ============================================

import 'package:fairshare/core/theme/app_theme.dart';
import 'package:fairshare/model/group.dart';
import 'package:fairshare/services/group_services.dart';
import 'package:fairshare/services/supabase_service.dart';
import 'package:fairshare/riverpod/group_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fairshare/screens/groups/widgets/budget_management_tile.dart';
import 'package:fairshare/screens/groups/widgets/danger_zone_section.dart';
import 'package:fairshare/screens/groups/widgets/group_info_form.dart';
import 'package:fairshare/screens/groups/widgets/members_list_section.dart';

class GroupSettingsScreen extends ConsumerStatefulWidget {
  final Group group;

  const GroupSettingsScreen({super.key, required this.group});

  @override
  ConsumerState<GroupSettingsScreen> createState() =>
      _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen>
    with TickerProviderStateMixin {
  final GroupService _groupService = GroupService();
  final SupabaseService _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _currentUserId;
  bool _isCurrentUserAdmin = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _descriptionController = TextEditingController(
      text: widget.group.description,
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _currentUserId = _supabaseService.currentUser?.id;

    // Ensure current user id is not null for widget
    if (_currentUserId != null) {
      _currentUserIdForWidget = _currentUserId!;
    }
    _loadGroupData();
  }

  String _currentUserIdForWidget = '';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupData() async {
    setState(() => _isLoading = true);
    try {
      final members = await _groupService.getGroupMembers(widget.group.id);
      if (mounted) {
        setState(() {
          _members = members;
          _isCurrentUserAdmin = _members.any(
            (m) => m['user_id'] == _currentUserId && m['role'] == 'admin',
          );
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to load group data', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal600),
            )
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAnimatedSection(
                          delay: 0,
                          child: MembersListSection(
                            members: _members,
                            currentUserId: _currentUserIdForWidget,
                            isCurrentUserAdmin: _isCurrentUserAdmin,
                            onAddMember: _showAddMemberDialog,
                            onRemoveMember: _removeMember,
                            onChangeRole: _changeRole,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildAnimatedSection(
                          delay: 100,
                          child: GroupInfoForm(
                            formKey: _formKey,
                            nameController: _nameController,
                            descriptionController: _descriptionController,
                            isSaving: _isSaving,
                            onSave: _updateGroup,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildAnimatedSection(
                          delay: 150,
                          child: BudgetManagementTile(groupId: widget.group.id),
                        ),
                        const SizedBox(height: 28),
                        _buildAnimatedSection(
                          delay: 200,
                          child: DangerZoneSection(
                            isCurrentUserAdmin: _isCurrentUserAdmin,
                            isNaming: _isSaving,
                            onDeleteGroup: _deleteGroup,
                            onLeaveGroup: _leaveGroup,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ============================================
  // APP BAR
  // ============================================

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.teal500, AppColors.teal600, AppColors.teal800],
            ),
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Group Settings',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // MEMBERS SECTION
  // ============================================



  Widget _buildAnimatedSection({required Widget child, required int delay}) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, childWidget) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              (delay / 600).clamp(0.0, 1.0),
              ((delay + 300) / 600).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        );

        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(opacity: animation.value, child: childWidget),
        );
      },
      child: child,
    );
  }

  // ============================================
  // ACTIONS
  // ============================================

  void _showAddMemberDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.teal50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_add_rounded,
                color: AppColors.teal600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Add Member',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: emailController,
          decoration: InputDecoration(
            hintText: 'Enter member email',
            labelText: 'Email',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.email_rounded),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addMember(emailController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Add',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addMember(String email) async {
    if (email.isEmpty) return;

    try {
      await _groupService.addMemberByEmail(
        groupId: widget.group.id,
        email: email,
      );
      if (mounted) {
        _showSnackBar('✓ Member added successfully');
        _loadGroupData();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  Future<void> _removeMember(String userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_remove_rounded,
                color: AppColors.danger600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Remove Member'),
          ],
        ),
        content: Text(
          'Remove $name from the group?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Remove',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _groupService.removeMember(
        groupId: widget.group.id,
        userId: userId,
      );
      if (mounted) {
        _showSnackBar('✓ Member removed');
        _loadGroupData();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to remove member', isError: true);
      }
    }
  }

  Future<void> _changeRole(String userId, String name, String newRole) async {
    final action = newRole == 'admin' ? 'promote' : 'demote';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.teal50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                newRole == 'admin'
                    ? Icons.admin_panel_settings_rounded
                    : Icons.person_rounded,
                color: AppColors.teal600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text('${action == 'promote' ? 'Promote' : 'Demote'} Member'),
          ],
        ),
        content: Text(
          newRole == 'admin'
              ? 'Make $name an admin? They will be able to manage members and settings.'
              : 'Remove admin privileges from $name?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Confirm',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _groupService.updateMemberRole(
        groupId: widget.group.id,
        userId: userId,
        newRole: newRole,
      );
      if (mounted) {
        _showSnackBar('✓ Role updated');
        _loadGroupData();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to update role', isError: true);
      }
    }
  }

  Future<void> _updateGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _groupService.updateGroup(
        groupId: widget.group.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      // Update provider to refresh UI
      await ref.read(groupsProvider.notifier).loadMyGroups();

      if (mounted) {
        _showSnackBar('✓ Group updated successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to update group', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _leaveGroup() async {
    // 1. Check Eligibility
    setState(() => _isSaving = true);
    try {
      final eligibility = await _groupService.checkExitEligibility(
        widget.group.id,
      );
      setState(() => _isSaving = false);

      if (eligibility['allowed'] == true) {
        // 2. Allowed -> Show Confirm Dialog
        if (!mounted) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.exit_to_app_rounded,
                    color: AppColors.warning600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Leave Group?'),
              ],
            ),
            content: Text(
              'Are you sure you want to leave "${widget.group.name}"? You will lose access to all expenses.',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning500,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Leave',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );

        if (confirm == true) {
          setState(() => _isSaving = true);
          await _groupService.leaveGroup(widget.group.id);

          await ref.read(groupsProvider.notifier).loadMyGroups();

          if (mounted) {
            Navigator.of(
              context,
            ).popUntil((route) => route.isFirst); // Go to home
            _showSnackBar('You left the group');
          }
        }
      } else {
        // 3. Blocked -> Show Error Dialog
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.danger50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.block_rounded,
                    color: AppColors.danger600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Cannot Leave Group'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eligibility['reason'] ?? 'Unknown reason',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                if (eligibility['code'] == 'UNSETTLED_BALANCE')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppColors.danger600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Balance: Rs ${(eligibility['balance'] as num).toDouble().abs().toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: GoogleFonts.inter(color: AppColors.teal600),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to leave group: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteGroup() async {
    // 1. Check Eligibility First
    setState(() => _isSaving = true);
    
    try {
      final eligibility = await _groupService.checkDeletionEligibility(widget.group.id);
      
      setState(() => _isSaving = false);

      if (eligibility['allowed'] != true) {
        // 2. Blocked -> Show Error Dialog
        if (!mounted) return;
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.danger50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.block_rounded,
                    color: AppColors.danger600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Deletion Blocked'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eligibility['reason'] ?? 'Unknown reason',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                if (eligibility['code'] == 'UNSETTLED_DEBTS' && eligibility['unsettled_amount'] != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.money_off_csred_rounded,
                          color: AppColors.danger600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Unsettled',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.danger600.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              'Rs ${(eligibility['unsettled_amount'] as num).toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK', style: GoogleFonts.inter(color: AppColors.teal600)),
              ),
            ],
          ),
        );
        return;
      }

      // 3. Allowed -> Show Confirmation Dialog
      if (!mounted) return;
      
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: AppColors.danger600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Delete Group?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${widget.group.name}"?',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.danger100),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.danger600,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.danger600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      setState(() => _isSaving = true);
      await _groupService.deleteGroup(widget.group.id);

      // Update provider to refresh UI
      await ref.read(groupsProvider.notifier).loadMyGroups();

      if (mounted) {
        Navigator.pop(context); // Close settings
        Navigator.pop(context, true); // Return to previous screen
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Group deleted successfully'),
              ],
            ),
            backgroundColor: AppColors.success500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('Failed to delete group: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.danger500 : AppColors.success500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
