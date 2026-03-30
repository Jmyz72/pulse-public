import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// A reusable avatar widget with initials fallback and glassmorphism styling
///
/// Shows a circular avatar with:
/// - User's profile image if provided
/// - Initials with gradient background if no image
/// - Optional online status badge
/// - Glassmorphism border with cyan/teal glow
class InitialsAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final bool showOnlineBadge;

  const InitialsAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.showOnlineBadge = false,
  });

  /// Extract initials from name (first letter of first 2 words)
  String _getInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  /// Generate a consistent color based on name hash
  Color _getGradientColor(String name) {
    final hash = name.hashCode;
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.neonMagenta,
      AppColors.neonPurple,
      AppColors.neonGreen,
      AppColors.neonYellow,
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final gradientColor = _getGradientColor(name);

    return Stack(
      children: [
        // Main avatar with glassmorphism border
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.5),  // Stronger for visibility
              width: 2,
            ),
            // boxShadow removed - not allowed in Cyber-Teal design system
          ),
          child: ClipOval(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildInitialsWidget(gradientColor),
                  )
                : _buildInitialsWidget(gradientColor),
          ),
        ),
        // Online status badge
        if (showOnlineBadge)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitialsWidget(Color gradientColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradientColor,
            gradientColor.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(name),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
