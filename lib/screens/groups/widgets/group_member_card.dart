import 'package:fairshare/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupMemberCard extends StatelessWidget {
  final Map<String, dynamic> memberData;
  final String currentUserId;
  final bool isCurrentUserAdmin;
  final Function(String, String) onRemove;
  final Function(String, String, String) onChangeRole;

  const GroupMemberCard({
    super.key,
    required this.memberData,
    required this.currentUserId,
    required this.isCurrentUserAdmin,
    required this.onRemove,
    required this.onChangeRole,
  });

  @override
  Widget build(BuildContext context) {
    final profile = memberData['profiles'] as Map<String, dynamic>? ?? {};
    final role = memberData['role'] as String;
    final memberId = memberData['user_id'] as String;
    final email = profile['email'] as String? ?? 'Unknown';
    final name = profile['full_name'] as String? ?? email.split('@')[0];
    final avatarUrl = profile['avatar_url'] as String?;
    final isCurrentUser = memberId == currentUserId;
    final isAdmin = role == 'admin';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.teal50.withOpacity(0.3)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isAdmin
                    ? [AppColors.teal500, AppColors.teal600]
                    : [AppColors.neutral400, AppColors.neutral500],
              ),
              borderRadius: BorderRadius.circular(12),
              image: avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarUrl == null
                ? Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isCurrentUser ? '$name (You)' : name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.teal500, AppColors.teal600],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ADMIN',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isCurrentUserAdmin && !isCurrentUser)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'remove') {
                  onRemove(memberId, name);
                } else if (value == 'promote') {
                  onChangeRole(memberId, name, 'admin');
                } else if (value == 'demote') {
                  onChangeRole(memberId, name, 'member');
                }
              },
              itemBuilder: (context) => [
                if (!isAdmin)
                  PopupMenuItem(
                    value: 'promote',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: AppColors.teal600,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Make Admin',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                if (isAdmin)
                  PopupMenuItem(
                    value: 'demote',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_rounded,
                          color: AppColors.warning600,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Remove Admin',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_remove_rounded,
                        color: AppColors.danger500,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Remove',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.danger500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
