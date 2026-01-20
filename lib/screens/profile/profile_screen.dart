import 'package:fairshare/screens/auth/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:fairshare/core/theme/app_theme.dart';
import 'package:fairshare/services/profile_service.dart';
import 'package:fairshare/services/supabase_service.dart';
import 'package:fairshare/model/user_model.dart';
import 'package:fairshare/widgets/profile_widgets.dart';
import 'package:fairshare/screens/profile/edit_profile_screen.dart';
import 'package:fairshare/screens/profile/change_password_screen.dart';
import 'package:fairshare/screens/profile/settings_screen.dart';
import 'package:fairshare/screens/profile/friends_screen.dart';
import 'package:fairshare/screens/profile/user_budget_settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final SupabaseService _supabaseService = SupabaseService();

  UserProfile? _userProfile;
  Map<String, dynamic>? _userStats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _profileService.getCurrentUserProfile();
      if (profile != null) {
        final stats = await _profileService.getUserStatistics(profile.id);
        setState(() {
          _userProfile = profile;
          _userStats = stats;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style: GoogleFonts.inter(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _supabaseService.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SignInScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to logout: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadProfileData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    ProfileHeader(
                      avatarUrl: _userProfile?.avatarUrl,
                      userName: _userProfile?.fullName ?? 'User',
                      userEmail: _userProfile?.email ?? '',
                      onEditTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditProfileScreen(userProfile: _userProfile!),
                          ),
                        );
                        if (result == true) {
                          _loadProfileData();
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // Statistics Cards
                    if (_userStats != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: ProfileStatCard(
                                label: 'Groups',
                                value: '${_userStats!['totalGroups']}',
                                icon: Icons.group_rounded,
                                color: AppColors.teal600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ProfileStatCard(
                                label: 'Expenses',
                                value: '${_userStats!['totalExpenses']}',
                                icon: Icons.receipt_long_rounded,
                                color: AppColors.purple600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const FriendsScreen(),
                                    ),
                                  );
                                },
                                child: ProfileStatCard(
                                  label: 'Friends',
                                  value: '${_userStats!['totalFriends']}',
                                  icon: Icons.people_rounded,
                                  color: const Color(0xFF22C55E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Personal Information
                    ProfileInfoCard(
                      fullName: _userProfile?.fullName,
                      email: _userProfile?.email,
                      phone: _userProfile?.phone,
                      joinedDate: _userProfile?.createdAt,
                    ),

                    const SizedBox(height: 24),

                    // Account Section
                    const ProfileSectionHeader(title: 'Account'),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ProfileMenuItem(
                            icon: Icons.edit_outlined,
                            title: 'Edit Profile',
                            subtitle: 'Update your personal information',
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProfileScreen(
                                    userProfile: _userProfile!,
                                  ),
                                ),
                              );
                              if (result == true) {
                                _loadProfileData();
                              }
                            },
                          ),
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: AppColors.border,
                          ),
                          ProfileMenuItem(
                            icon: Icons.lock_outline,
                            title: 'Change Password',
                            subtitle: 'Update your password',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ChangePasswordScreen(),
                                ),
                              );
                            },
                          ),
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: AppColors.border,
                          ),
                          ProfileMenuItem(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Budget Settings',
                            subtitle: 'Manage your personal spending limits',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const UserBudgetSettingsScreen(),
                                ),
                              );
                            },
                          ),
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: AppColors.border,
                          ),
                          ProfileMenuItem(
                            icon: Icons.settings_outlined,
                            title: 'Settings',
                            subtitle: 'App preferences and notifications',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // More Section
                    const ProfileSectionHeader(title: 'More'),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ProfileMenuItem(
                            icon: Icons.help_outline,
                            title: 'Help & Support',
                            onTap: () {
                              // TODO: Navigate to help screen
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Help & Support coming soon'),
                                ),
                              );
                            },
                          ),
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: AppColors.border,
                          ),
                          ProfileMenuItem(
                            icon: Icons.info_outline,
                            title: 'About',
                            subtitle: 'Version 1.0.0',
                            onTap: () {
                              // TODO: Show about dialog
                              showAboutDialog(
                                context: context,
                                applicationName: 'FairShare',
                                applicationVersion: '1.0.0',
                                applicationIcon: Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 48,
                                  color: AppColors.teal600,
                                ),
                              );
                            },
                          ),
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: AppColors.border,
                          ),
                          ProfileMenuItem(
                            icon: Icons.logout_rounded,
                            title: 'Logout',
                            onTap: _handleLogout,
                            isDanger: true,
                            showArrow: false,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }
}
