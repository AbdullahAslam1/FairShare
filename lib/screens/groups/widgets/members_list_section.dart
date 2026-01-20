import 'package:fairshare/core/theme/app_theme.dart';
import 'package:fairshare/screens/groups/widgets/group_member_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MembersListSection extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final String currentUserId;
  final bool isCurrentUserAdmin;
  final VoidCallback onAddMember;
  final Function(String, String) onRemoveMember;
  final Function(String, String, String) onChangeRole;

  const MembersListSection({
    super.key,
    required this.members,
    required this.currentUserId,
    required this.isCurrentUserAdmin,
    required this.onAddMember,
    required this.onRemoveMember,
    required this.onChangeRole,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('Members (${members.length})'),
            if (isCurrentUserAdmin)
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.teal500, AppColors.teal600],
                  ),
                  borderRadius: BorderRadius.circular(12),
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
                    onTap: onAddMember,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: members.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No members',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.border.withOpacity(0.5),
                  ),
                  itemBuilder: (context, index) {
                    return GroupMemberCard(
                      memberData: members[index],
                      currentUserId: currentUserId,
                      isCurrentUserAdmin: isCurrentUserAdmin,
                      onRemove: onRemoveMember,
                      onChangeRole: onChangeRole,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.teal500, AppColors.teal600],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
