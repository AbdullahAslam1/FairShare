// ============================================
// FILE: lib/screens/groups/create_group_screen.dart
// Beautiful Create Group Screen - Premium Redesign
// ============================================

import 'package:fairshare/core/theme/app_theme.dart';
import 'package:fairshare/riverpod/group_provider.dart';
import 'package:fairshare/services/group_services.dart';
import 'package:fairshare/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  final GroupService _groupService = GroupService();
  final SupabaseService _supabaseService = SupabaseService();

  final List<Map<String, dynamic>> _selectedMembers = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _selectedCategory;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'General',
      'icon': Icons.groups_rounded,
      'gradient': [AppColors.teal500, AppColors.teal600],
    },
    {
      'name': 'Trip',
      'icon': Icons.flight_rounded,
      'gradient': [AppColors.purple600, AppColors.purple700],
    },
    {
      'name': 'Home',
      'icon': Icons.home_rounded,
      'gradient': [AppColors.success500, AppColors.success600],
    },
    {
      'name': 'Couple',
      'icon': Icons.favorite_rounded,
      'gradient': [AppColors.danger500, AppColors.danger600],
    },
    {
      'name': 'Other',
      'icon': Icons.more_horiz_rounded,
      'gradient': [AppColors.warning500, AppColors.warning600],
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildPremiumAppBar(),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnimatedSection(
                      delay: 0,
                      child: _buildGroupNameSection(),
                    ),
                    const SizedBox(height: 28),
                    _buildAnimatedSection(
                      delay: 100,
                      child: _buildCategorySection(),
                    ),
                    const SizedBox(height: 28),
                    _buildAnimatedSection(
                      delay: 200,
                      child: _buildDescriptionSection(),
                    ),
                    const SizedBox(height: 28),
                    _buildAnimatedSection(
                      delay: 300,
                      child: _buildAddMembersSection(),
                    ),
                    if (_selectedMembers.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _buildAnimatedSection(
                        delay: 400,
                        child: _buildSelectedMembersList(),
                      ),
                    ],
                    const SizedBox(height: 40),
                    _buildAnimatedSection(
                      delay: 500,
                      child: _buildCreateButton(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // PREMIUM APP BAR
  // ============================================

  Widget _buildPremiumAppBar() {
    return SliverAppBar(
      expandedHeight: 180.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Premium Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.teal500,
                    AppColors.teal600,
                    AppColors.teal700,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Animated Orbs
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.teal800.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 24, bottom: 20),
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.add_circle_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Create Group',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 26,
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
  // SECTION COMPONENTS
  // ============================================

  Widget _buildGroupNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Group Name', Icons.label_rounded, true),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal600.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: _nameController,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'e.g., Summer Trip 2024',
              hintStyle: GoogleFonts.inter(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.teal500, AppColors.teal600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.group_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 22,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a group name';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Category', Icons.category_rounded, false),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category['name'];
            final gradient = category['gradient'] as List<Color>;
            final icon = category['icon'] as IconData;

            return GestureDetector(
              onTap: () => setState(
                () => _selectedCategory = isSelected
                    ? null
                    : category['name'] as String,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(colors: gradient)
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? gradient[0]
                        : AppColors.border.withOpacity(0.5),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: gradient[0].withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isSelected ? Colors.white : gradient[0],
                    ),
                    const SizedBox(width: 10),
                    Text(
                      category['name'] as String,
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.white : gradient[0],
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Description', Icons.notes_rounded, false),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'What is this group for?',
              hintStyle: GoogleFonts.inter(color: AppColors.textTertiary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Add Members', Icons.person_add_rounded, false),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Enter email address',
                    hintStyle: GoogleFonts.inter(color: AppColors.textTertiary),
                    prefixIcon: const Icon(
                      Icons.email_rounded,
                      color: AppColors.teal600,
                      size: 22,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                  ),
                  onFieldSubmitted: (_) => _addMemberByEmail(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.teal500, AppColors.teal600],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal600.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSearching ? null : _addMemberByEmail,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        child: _isSearching
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedMembersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.teal50,
                    AppColors.teal100.withOpacity(0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.people_rounded,
                color: AppColors.teal600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Selected Members (${_selectedMembers.length})',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedMembers.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: AppColors.border.withOpacity(0.3),
              indent: 76,
            ),
            itemBuilder: (context, index) {
              final member = _selectedMembers[index];
              final name = member['full_name'] ?? member['email'];
              final initial = name.substring(0, 1).toUpperCase();

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.teal400, AppColors.teal600],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal600.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
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
                          const SizedBox(height: 2),
                          Text(
                            member['email'],
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.danger50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.danger500,
                          size: 20,
                        ),
                        onPressed: () => _removeMember(member['id']),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.teal500, AppColors.teal700],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal600.withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _createGroup,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    height: 26,
                    width: 26,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Create Group',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // HELPER WIDGETS
  // ============================================

  Widget _buildSectionHeader(String title, IconData icon, bool required) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.teal50, AppColors.teal100.withOpacity(0.5)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.teal600, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.danger50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.danger100, width: 1),
            ),
            child: Text(
              'Required',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.danger600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Optional',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnimatedSection({required Widget child, required int delay}) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, childWidget) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              (delay / 800).clamp(0.0, 1.0),
              ((delay + 300) / 800).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        );

        return Transform.translate(
          offset: Offset(0, 30 * (1 - animation.value)),
          child: Opacity(opacity: animation.value, child: childWidget),
        );
      },
      child: child,
    );
  }

  // ============================================
  // ACTIONS
  // ============================================

  Future<void> _addMemberByEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('Please enter an email address', isError: true);
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar('Please enter a valid email address', isError: true);
      return;
    }

    if (_selectedMembers.any((m) => m['email'] == email)) {
      _showSnackBar('Member already added', isError: true);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final profile = await _supabaseService.getUserProfileByEmail(email);

      if (profile == null) {
        _showSnackBar('No user found with email: $email', isError: true);
        return;
      }

      setState(() {
        _selectedMembers.add(profile);
        _emailController.clear();
      });

      _showSnackBar('✓ ${profile['full_name'] ?? email} added');
    } catch (e) {
      _showSnackBar('Failed to add member', isError: true);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _removeMember(String userId) {
    setState(() {
      _selectedMembers.removeWhere((m) => m['id'] == userId);
    });
    _showSnackBar('Member removed');
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Please enter a group name', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final memberIds = _selectedMembers.map((m) => m['id'] as String).toList();

      // Create group using provider
      final group = await _groupService.createGroupWithMembers(
        name: name,
        description: _descriptionController.text.trim(),
        memberIds: memberIds,
      );

      // Update provider state
      await ref.read(groupsProvider.notifier).loadMyGroups();

      if (!mounted) return;

      Navigator.pop(context, group);
      _showSnackBar("✓ Group '${group.name}' created successfully!");
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to create group', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }
}
