import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool showOnlineIndicator;
  final bool isOnline;
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AppDimensions.avatarMd,
    this.showOnlineIndicator = false,
    this.isOnline = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
            ),
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildInitials(theme),
                    ),
                  )
                : _buildInitials(theme),
          ),
          if (showOnlineIndicator)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                height: size * 0.25,
                width: size * 0.25,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInitials(ThemeData theme) {
    final initials = _getInitials();
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.35,
        ),
      ),
    );
  }

  String _getInitials() {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }
}
