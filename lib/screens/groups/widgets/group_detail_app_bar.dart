import 'package:fairshare/core/theme/app_theme.dart';
import 'package:fairshare/model/group.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupDetailAppBar extends StatelessWidget {
  final Group group;
  final VoidCallback onSettingsPressed;

  const GroupDetailAppBar({
    super.key,
    required this.group,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.teal600,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.group_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              group.name,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded, color: Colors.white),
          onPressed: onSettingsPressed,
        ),
      ],
    );
  }
}
