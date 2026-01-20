import 'package:flutter/material.dart';
import 'package:fairshare/core/theme/app_theme.dart';
import 'dart:ui';

class CustomBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onCenterButtonTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onTap(2); // Center button (Add Expense)
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(color: Colors.transparent),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Glass Morphic Background
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 75,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        icon: Icons.home_rounded,
                        label: 'Home',
                        index: 0,
                        isActive: widget.currentIndex == 0,
                      ),
                      _buildNavItem(
                        icon: Icons.group_rounded,
                        label: 'Groups',
                        index: 1,
                        isActive: widget.currentIndex == 1,
                      ),
                      // Empty space for center button
                      const SizedBox(width: 60),
                      _buildNavItem(
                        icon: Icons.receipt_long_rounded,
                        label: 'Activity',
                        index: 3,
                        isActive: widget.currentIndex == 3,
                      ),
                      _buildNavItem(
                        icon: Icons.person_rounded,
                        label: 'Profile',
                        index: 4,
                        isActive: widget.currentIndex == 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floating Center Button
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 35,
            top: 0,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value * 3.14159,
                    child: GestureDetector(
                      onTap: _onCenterButtonTap,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal600.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: AppColors.purple600.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Center button indicator ring
          if (widget.currentIndex == 2)
            Positioned(
              left: MediaQuery.of(context).size.width / 2 - 40,
              top: -5,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.teal600.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => widget.onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with active indicator
            Stack(
              alignment: Alignment.center,
              children: [
                // Active indicator background
                if (isActive)
                  Container(
                    width: 50,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.teal600.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                // Icon
                Icon(
                  icon,
                  color: isActive ? AppColors.teal600 : AppColors.textSecondary,
                  size: 26,
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.teal600 : AppColors.textSecondary,
              ),
            ),
            // Active dot indicator
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.teal600,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
