import 'package:fairshare/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DangerZoneSection extends StatelessWidget {
  final bool isCurrentUserAdmin;
  final bool isNaming;
  final VoidCallback onDeleteGroup;
  final VoidCallback onLeaveGroup;

  const DangerZoneSection({
    super.key,
    required this.isCurrentUserAdmin,
    required this.isNaming,
    required this.onDeleteGroup,
    required this.onLeaveGroup,
  });

  @override
  Widget build(BuildContext context) {
    final title = isCurrentUserAdmin ? 'Delete Group' : 'Leave Group';
    final icon = isCurrentUserAdmin
        ? Icons.delete_forever_rounded
        : Icons.exit_to_app_rounded;
    final description = isCurrentUserAdmin
        ? 'Permanently delete this group and all data'
        : 'Leave this group. You must settle debts first.';
    final buttonText = isCurrentUserAdmin ? 'Delete Group' : 'Leave Group';
    final buttonColor = isCurrentUserAdmin
        ? AppColors.danger600
        : AppColors.warning600;
    final containerColor = isCurrentUserAdmin
        ? AppColors.danger50
        : AppColors.warning50;
    final borderColor = isCurrentUserAdmin
        ? AppColors.danger200
        : AppColors.warning100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Danger Zone'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: containerColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.warning_rounded,
                      color: buttonColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: buttonColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: isNaming
                      ? null
                      : (isCurrentUserAdmin ? onDeleteGroup : onLeaveGroup),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: buttonColor, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: buttonColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        buttonText,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: buttonColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
