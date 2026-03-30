import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Floating glass bottom navigation bar following Pulse Cyber-Teal design system
///
/// Specs:
/// - Floating: 20px left/right margin, 16px bottom margin
/// - Height: 72px
/// - Background: White 3% opacity with 12px blur
/// - Border: 1.5px Electric Teal at 40% opacity
/// - Active Icon: Neon Cyan with glow effect (0.2 opacity circle + 16px blur shadow)
/// - Inactive Icon: White 40% opacity
/// - Label: 11px, active cyan/inactive tertiary
class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.location_on_outlined,
                  activeIcon: Icons.location_on,
                  label: 'Map',
                  index: 0,
                  iconSize: 24,
                ),
                _buildNavItem(
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: 'Messages',
                  index: 1,
                  iconSize: 24,
                ),
                _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  index: 2,
                  iconSize: 28, // Larger home icon
                ),
                _buildNavItem(
                  icon: Icons.auto_awesome_outlined,
                  activeIcon: Icons.auto_awesome,
                  label: 'Activity',
                  index: 3,
                  iconSize: 24,
                ),
                _buildNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  index: 4,
                  iconSize: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required double iconSize,
  }) {
    final isActive = currentIndex == index;

    return Expanded(
      child: Semantics(
        label: label,
        selected: isActive,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(index),
            borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with neon glow effect when active
                Container(
                  width: iconSize + 12,
                  height: iconSize + 12,
                  decoration: isActive
                      ? BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              blurRadius: 16,
                              spreadRadius: 0,
                            ),
                          ],
                        )
                      : null,
                  child: Icon(
                    isActive ? activeIcon : icon,
                    size: iconSize,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textPrimary.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 4),
                // Label
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
