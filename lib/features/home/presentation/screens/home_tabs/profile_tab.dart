import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/dashboard_data.dart';
import '../../widgets/menu_option.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_routes.dart';
import '../../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../../shared/widgets/avatar_widget.dart';
import '../../../../../shared/mixins/stagger_animation_mixin.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';

/// Profile tab showing personal identity and account actions.
class ProfileTab extends StatefulWidget {
  final UserSummary? user;

  const ProfileTab({super.key, this.user});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> with StaggerAnimationMixin {
  @override
  int get staggerCount => 4;

  @override
  void initState() {
    super.initState();
    startStaggerAnimation();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authUser = context.read<AuthBloc>().state.user;
    final displayName = widget.user?.name ?? authUser?.displayName ?? 'User';
    final username = widget.user?.username ?? authUser?.username ?? '';
    final email = widget.user?.email ?? authUser?.email ?? '';
    final photoUrl = widget.user?.photoUrl ?? authUser?.photoUrl;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('Profile'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                staggerIn(
                  index: 0,
                  child: Column(
                    children: [
                      _buildAvatar(photoUrl, displayName),
                      const SizedBox(height: AppDimensions.spacingMd),
                      Text(
                        displayName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (username.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.spacingXs),
                        Text(
                          '@$username',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.spacingXs),
                        Text(
                          email,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppDimensions.spacingMd),
                      OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.editProfile),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit Profile'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXl),
                staggerIn(
                  index: 1,
                  child: Text(
                    'ACCOUNT',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                staggerIn(
                  index: 2,
                  child: Column(
                    children: [
                      MenuOption(
                        title: 'Notifications',
                        icon: Icons.notifications_outlined,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.notifications,
                        ),
                      ),
                      MenuOption(
                        title: 'My Friends',
                        icon: Icons.people_outline,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.friends),
                      ),
                      MenuOption(
                        title: 'Timetable',
                        icon: Icons.calendar_today_outlined,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.timetable),
                      ),
                      MenuOption(
                        title: 'Settings',
                        icon: Icons.settings_outlined,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.settings),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXl),
                staggerIn(index: 3, child: _buildLogoutButton(context)),
                const SizedBox(height: AppDimensions.spacingXl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String? photoUrl, String displayName) {
    return AvatarWidget(imageUrl: photoUrl, name: displayName, size: 100);
  }

  Widget _buildLogoutButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => ConfirmationDialog.show(
        context,
        title: 'Logout',
        message:
            'Are you sure you want to logout? You will need to sign in again.',
        confirmText: 'Logout',
        isDestructive: true,
        onConfirm: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
      ),
      icon: const Icon(Icons.logout),
      label: const Text('Logout'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
