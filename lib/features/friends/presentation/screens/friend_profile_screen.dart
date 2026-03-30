import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/friendship.dart';
import '../bloc/friend_bloc.dart';
import '../bloc/friend_event.dart';
import '../bloc/friend_state.dart';

class FriendProfileScreen extends StatefulWidget {
  final Friendship friendship;

  const FriendProfileScreen({super.key, required this.friendship});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  Friendship get friendship => widget.friendship;

  @override
  void initState() {
    super.initState();
    _loadProfileStats();
  }

  void _loadProfileStats() {
    final currentUserId = context.read<AuthBloc>().state.user?.id ?? '';
    if (currentUserId.isEmpty) return;

    context.read<FriendBloc>().add(
      FriendProfileStatsRequested(
        currentUserId: currentUserId,
        friendUserId: friendship.friendId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAt = friendship.createdAt;
    final sinceText = '${_monthName(createdAt.month)} ${createdAt.year}';

    return BlocListener<FriendBloc, FriendState>(
      listenWhen: (previous, current) =>
          previous.profileStatsStatus != current.profileStatsStatus ||
          previous.errorMessage != current.errorMessage ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        if (state.successMessage == AppStrings.friendRemoved) {
          Navigator.pop(context);
          return;
        }

        if (state.profileStatsStatus == FriendLoadStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                action: SnackBarAction(
                  label: AppStrings.retry,
                  onPressed: _loadProfileStats,
                ),
              ),
            );
          context.read<FriendBloc>().add(const FriendMessageCleared());
        }
      },
      child: Scaffold(
        appBar: GlassAppBar(
          title: AppStrings.friendProfile,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_horiz_rounded),
              tooltip: 'Manage friend',
              onPressed: _showManageSheet,
            ),
          ],
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroCard(theme, sinceText),
                    const SizedBox(height: AppDimensions.spacingLg),
                    _buildStatsSection(theme),
                    const SizedBox(height: AppDimensions.spacingLg),
                    _buildContactSection(theme),
                    const SizedBox(height: AppDimensions.spacingXl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme, String sinceText) {
    return GlassCard(
      borderRadius: 32,
      backgroundOpacity: 0.08,
      borderOpacity: 0.48,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: AvatarWidget(
                  imageUrl: friendship.friendPhotoUrl,
                  name: friendship.friendDisplayName,
                  size: 96,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ProfileStatusPill(
                      label: 'Connected',
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      friendship.friendDisplayName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    if (friendship.friendUsername.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '@${friendship.friendUsername}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'Connected since $sinceText. View mutual rooms, mutual friends, and contact details below.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
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

  Widget _buildStatsSection(ThemeData theme) {
    return BlocBuilder<FriendBloc, FriendState>(
      buildWhen: (previous, current) =>
          previous.profileStatsStatus != current.profileStatsStatus ||
          previous.friendProfileStats != current.friendProfileStats,
      builder: (context, state) {
        final stats = state.friendProfileStats;
        final isLoading = state.profileStatsStatus == FriendLoadStatus.loading;
        final hasStats =
            state.profileStatsStatus == FriendLoadStatus.loaded &&
            stats != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shared snapshot',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AppDimensions.spacingMd,
              crossAxisSpacing: AppDimensions.spacingMd,
              childAspectRatio: 1.55,
              children: [
                _StatCard(
                  title: 'Mutual Rooms',
                  value: isLoading
                      ? '...'
                      : hasStats
                      ? '${stats.mutualRoomsCount}'
                      : '-',
                  subtitle: 'Pulse Groups',
                  icon: Icons.groups_rounded,
                  color: AppColors.secondary,
                ),
                _StatCard(
                  title: 'Mutual Friends',
                  value: isLoading
                      ? '...'
                      : hasStats
                      ? '${stats.mutualFriendsCount}'
                      : '-',
                  subtitle: 'Shared Contacts',
                  icon: Icons.people_outline_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactSection(ThemeData theme) {
    final email = friendship.friendEmail;
    final phone = friendship.friendPhone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 28,
          child: Column(
            children: [
              if (email.isNotEmpty)
                _ContactTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: email,
                ),
              if (email.isNotEmpty && phone.isNotEmpty)
                const Divider(
                  height: 1,
                  indent: 58,
                  color: AppColors.glassBorder,
                ),
              if (phone.isNotEmpty)
                _ContactTile(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: Validators.formatPhoneForDisplay(phone),
                ),
              if (email.isEmpty && phone.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingLg),
                  child: Text(
                    'No contact info available',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmRemoveFriend(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text(
          AppStrings.removeFriend,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Remove ${friendship.friendDisplayName} from your friends?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<FriendBloc>().add(
                FriendRemoveRequested(friendship.id),
              );
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showManageSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spacingMd,
              0,
              AppDimensions.spacingMd,
              AppDimensions.spacingMd,
            ),
            child: GlassCard(
              borderRadius: 28,
              backgroundOpacity: 0.10,
              borderOpacity: 0.5,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Manage friend',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    friendship.friendDisplayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _ManageActionTile(
                    icon: Icons.block_rounded,
                    title: 'Block user',
                    subtitle: 'Coming soon',
                    color: AppColors.textTertiary,
                    enabled: false,
                  ),
                  const SizedBox(height: 10),
                  _ManageActionTile(
                    icon: Icons.person_remove_alt_1_rounded,
                    title: AppStrings.removeFriend,
                    subtitle: 'Remove this connection',
                    color: AppColors.error,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _confirmRemoveFriend(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class _ManageActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const _ManageActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: enabled ? color : AppColors.textTertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileStatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _ProfileStatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 24,
      backgroundOpacity: 0.05,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
