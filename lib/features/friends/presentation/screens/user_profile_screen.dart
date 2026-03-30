import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../bloc/friend_bloc.dart';
import '../bloc/friend_event.dart';
import '../bloc/friend_state.dart';

enum ProfileContext { searchResult, pendingRequest }

class UserProfileScreen extends StatelessWidget {
  final String name;
  final String username;
  final String email;
  final String phone;
  final String? photoUrl;
  final ProfileContext profileContext;
  final String? userId;
  final String? targetEmail;
  final bool isFriend;
  final bool isPending;
  final String? friendshipId;
  final String? currentUserId;

  const UserProfileScreen({
    super.key,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.profileContext,
    this.userId,
    this.targetEmail,
    this.isFriend = false,
    this.isPending = false,
    this.friendshipId,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<FriendBloc, FriendState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: GlassAppBar(
          title: AppStrings.profile,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
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
                    _buildHeroCard(theme),
                    const SizedBox(height: AppDimensions.spacingLg),
                    _buildRelationshipCard(theme),
                    const SizedBox(height: AppDimensions.spacingLg),
                    _buildContactCard(theme),
                    const SizedBox(height: AppDimensions.spacingLg),
                    if (profileContext == ProfileContext.searchResult)
                      _buildSearchResultActions(context, theme),
                    if (profileContext == ProfileContext.pendingRequest)
                      _buildPendingRequestActions(context, theme),
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

  Widget _buildHeroCard(ThemeData theme) {
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
              AvatarWidget(
                imageUrl: photoUrl,
                name: name,
                size: AppDimensions.avatarXl,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfilePill(
                      label: _relationshipLabel,
                      color: _relationshipColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '@$username',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      _heroDescription,
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

  Widget _buildRelationshipCard(ThemeData theme) {
    return GlassCard(
      borderRadius: 28,
      backgroundOpacity: 0.05,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _relationshipColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_relationshipIcon, color: _relationshipColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relationship status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _relationshipDescription,
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
    );
  }

  Widget _buildContactCard(ThemeData theme) {
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
                _ProfileInfoTile(
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
                _ProfileInfoTile(
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

  Widget _buildSearchResultActions(BuildContext context, ThemeData theme) {
    if (isFriend) {
      return const _StatusActionCard(
        title: 'Already connected',
        description:
            'This person is already in your friends list, so there is nothing else to send from here.',
        child: _FullWidthStateChip(
          label: AppStrings.friends,
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        ),
      );
    }

    if (isPending) {
      return const _StatusActionCard(
        title: 'Request in progress',
        description:
            'A request already exists between both accounts. Wait for a response before sending another one.',
        child: _FullWidthStateChip(
          label: 'Pending',
          icon: Icons.schedule_rounded,
          color: AppColors.warning,
        ),
      );
    }

    return _StatusActionCard(
      title: 'Send friend request',
      description:
          'If this is the right profile, send a request and they will see it in their incoming queue.',
      child: BlocBuilder<FriendBloc, FriendState>(
        builder: (context, state) {
          return SizedBox(
            width: double.infinity,
            child: GlassButton(
              text: AppStrings.addFriend,
              icon: Icons.person_add_alt_1_rounded,
              isPrimary: true,
              width: double.infinity,
              isLoading: state.actionStatus == ActionStatus.processing,
              onPressed: () {
                if (userId != null && targetEmail != null) {
                  context.read<FriendBloc>().add(
                    FriendRequestSendRequested(
                      userId: userId!,
                      email: targetEmail!,
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingRequestActions(BuildContext context, ThemeData theme) {
    return _StatusActionCard(
      title: 'Respond to request',
      description:
          'Review the profile details, then accept to connect or decline to dismiss the request.',
      child: BlocBuilder<FriendBloc, FriendState>(
        builder: (context, state) {
          final isProcessing = state.actionStatus == ActionStatus.processing;
          return Row(
            children: [
              Expanded(
                child: _ProfileActionButton(
                  label: 'Decline',
                  icon: Icons.close_rounded,
                  color: AppColors.error,
                  onPressed: isProcessing
                      ? null
                      : () {
                          if (friendshipId != null) {
                            context.read<FriendBloc>().add(
                              FriendRequestDeclineRequested(friendshipId!),
                            );
                          }
                        },
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: GlassButton(
                  text: 'Accept',
                  icon: Icons.check_rounded,
                  isPrimary: true,
                  width: double.infinity,
                  isLoading: isProcessing,
                  onPressed: () {
                    if (friendshipId != null && currentUserId != null) {
                      context.read<FriendBloc>().add(
                        FriendRequestAcceptRequested(
                          friendshipId!,
                          userId: currentUserId!,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String get _relationshipLabel {
    if (profileContext == ProfileContext.pendingRequest) {
      return 'Pending request';
    }
    if (isFriend) return AppStrings.friends;
    if (isPending) return 'Pending';
    return 'Discover';
  }

  Color get _relationshipColor {
    if (profileContext == ProfileContext.pendingRequest || isPending) {
      return AppColors.warning;
    }
    if (isFriend) return AppColors.success;
    return AppColors.primary;
  }

  IconData get _relationshipIcon {
    if (profileContext == ProfileContext.pendingRequest || isPending) {
      return Icons.schedule_rounded;
    }
    if (isFriend) return Icons.check_circle_rounded;
    return Icons.person_add_alt_1_rounded;
  }

  String get _heroDescription {
    if (profileContext == ProfileContext.pendingRequest) {
      return 'This person sent you a friend request. Review their details before responding.';
    }
    if (isFriend) {
      return 'You are already connected. This profile is here for quick reference.';
    }
    if (isPending) {
      return 'A request is already in progress between both accounts.';
    }
    return 'Review the profile details before deciding whether to connect.';
  }

  String get _relationshipDescription {
    if (profileContext == ProfileContext.pendingRequest) {
      return 'A request from this user is waiting for your response right now.';
    }
    if (isFriend) {
      return 'This profile is already part of your friend network.';
    }
    if (isPending) {
      return 'The connection request is already pending.';
    }
    return 'You have not connected with this profile yet.';
  }
}

class _ProfilePill extends StatelessWidget {
  final String label;
  final Color color;

  const _ProfilePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.22)),
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

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoTile({
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

class _StatusActionCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _StatusActionCard({
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 28,
      backgroundOpacity: 0.05,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _FullWidthStateChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _FullWidthStateChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ProfileActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.10),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
