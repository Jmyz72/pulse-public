import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_animations.dart';
import '../../core/constants/app_colors.dart';

/// Glassmorphism card widget following Pulse Cyber-Teal design system
///
/// Specs:
/// - Background: White at 3-5% opacity
/// - Border: 1.5px Electric Teal (#008B9D) at 40% opacity
/// - Blur: 12px BackdropFilter
/// - Border Radius: 24px
/// - Internal Padding: 20px (default)
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blurStrength;
  final double backgroundOpacity;
  final double borderOpacity;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.borderRadius = 24.0,
    this.blurStrength = 12.0,
    this.backgroundOpacity = 0.05,
    this.borderOpacity = 0.4,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: backgroundOpacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: (borderColor ?? AppColors.secondary).withValues(
            alpha: borderOpacity,
          ),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardContent,
      );
    }

    return cardContent;
  }
}

/// Lightweight glass container without blur (for performance)
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double borderRadius;
  final double backgroundOpacity;
  final double borderOpacity;
  final Color? borderColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.borderRadius = 24.0,
    this.backgroundOpacity = 0.05,
    this.borderOpacity = 0.4,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: backgroundOpacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: (borderColor ?? AppColors.secondary).withValues(
            alpha: borderOpacity,
          ),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}

/// Glass button with neon cyan accent
class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isPrimary;
  final IconData? icon;
  final double? width;

  const GlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isPrimary = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isPrimary
        ? AppColors.primary.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.05);

    final borderColor = isPrimary ? AppColors.primary : AppColors.secondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: borderColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: AnimatedSwitcher(
                duration: AppAnimations.fast,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: isLoading
                    ? SizedBox(
                        key: const ValueKey('loading'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            isPrimary
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      )
                    : Row(
                        key: const ValueKey('content'),
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(
                              icon,
                              color: isPrimary
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            fit: FlexFit.loose,
                            child: Text(
                              text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isPrimary
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass app bar for consistent navigation
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            border: Border(
              bottom: BorderSide(
                color: AppColors.secondary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
          ),
          child: AppBar(
            title: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: leading,
            actions: actions,
            centerTitle: centerTitle,
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            bottom: bottom,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

/// Icon with colored circle background (from screenshot)
class IconCircle extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final double size;

  const IconCircle({
    super.key,
    required this.icon,
    this.backgroundColor = AppColors.primary,
    this.iconColor = AppColors.white,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: size * 0.5),
    );
  }
}
