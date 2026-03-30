import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/friendship.dart';
import '../bloc/friend_bloc.dart';
import '../bloc/friend_event.dart';
import '../bloc/friend_state.dart';
import '../widgets/friend_tile.dart';

enum _FriendsSection { friends, requests }

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  _FriendsSection _selectedSection = _FriendsSection.friends;

  String get _currentUserId => context.read<AuthBloc>().state.user?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final uid = _currentUserId;
    if (uid.isNotEmpty) {
      context.read<FriendBloc>()
        ..add(FriendsLoadRequested(uid))
        ..add(PendingRequestsLoadRequested(uid));
    }
  }

  void _onSectionSelected(_FriendsSection section) {
    if (_selectedSection == section) return;
    setState(() => _selectedSection = section);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: GlassAppBar(
        title: AppStrings.friends,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh friends',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: BlocConsumer<FriendBloc, FriendState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: AppColors.success.withValues(alpha: 0.9),
                ),
              );
            context.read<FriendBloc>().add(const FriendMessageCleared());
            _loadData();
          }
          if (state.errorMessage != null &&
              state.actionStatus == ActionStatus.error) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.error.withValues(alpha: 0.9),
                ),
              );
            context.read<FriendBloc>().add(const FriendMessageCleared());
          }
        },
        builder: (context, state) {
          final isInitialLoad =
              state.friendsStatus == FriendLoadStatus.loading &&
              state.requestsStatus == FriendLoadStatus.loading &&
              state.friends.isEmpty &&
              state.pendingRequests.isEmpty &&
              state.sentRequests.isEmpty;

          if (isInitialLoad) {
            return const Center(child: LoadingIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.spacingMd,
                      AppDimensions.spacingMd,
                      AppDimensions.spacingMd,
                      AppDimensions.spacingXxl + 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroCard(context, theme, state),
                        const SizedBox(height: AppDimensions.spacingLg),
                        _buildSectionSwitcher(state),
                        const SizedBox(height: AppDimensions.spacingLg),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: KeyedSubtree(
                            key: ValueKey(_selectedSection),
                            child: _selectedSection == _FriendsSection.friends
                                ? _buildFriendsSection(state)
                                : _buildRequestsSection(state),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    ThemeData theme,
    FriendState state,
  ) {
    final friendCount = state.friends.length;
    final incomingCount = state.pendingRequests.length;
    final outgoingCount = state.sentRequests.length;

    return GlassCard(
      key: const Key('friends_header_card'),
      borderRadius: 32,
      backgroundOpacity: 0.08,
      borderOpacity: 0.48,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryMetricCard(
                  label: AppStrings.friends,
                  value: friendCount,
                  icon: Icons.group_rounded,
                  color: AppColors.primary,
                  onTap: () => _onSectionSelected(_FriendsSection.friends),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetricCard(
                  label: 'Incoming',
                  value: incomingCount,
                  icon: Icons.mark_email_unread_rounded,
                  color: AppColors.warning,
                  onTap: () => _onSectionSelected(_FriendsSection.requests),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetricCard(
                  label: 'Sent',
                  value: outgoingCount,
                  icon: Icons.north_east_rounded,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  text: AppStrings.addFriend,
                  icon: Icons.person_add_alt_1_rounded,
                  isPrimary: true,
                  width: double.infinity,
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.addFriend),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SecondaryActionButton(
                  key: const Key('requests_quick_action'),
                  label: incomingCount > 0 ? 'Review requests' : 'Refresh',
                  icon: incomingCount > 0
                      ? Icons.mail_outline_rounded
                      : Icons.refresh_rounded,
                  onPressed: incomingCount > 0
                      ? () => _onSectionSelected(_FriendsSection.requests)
                      : _loadData,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSwitcher(FriendState state) {
    final selectedTitle = _selectedSection == _FriendsSection.friends
        ? '${state.friends.length} friends in your network'
        : '${state.pendingRequests.length} request${state.pendingRequests.length == 1 ? '' : 's'} to review';
    final selectedSubtitle = _selectedSection == _FriendsSection.friends
        ? 'Tap a friend to open their profile and manage the connection.'
        : 'Accept, decline, or open a profile before you decide.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassContainer(
          borderRadius: 24,
          backgroundOpacity: 0.04,
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              Expanded(
                child: _SectionButton(
                  key: const Key('friends_section_button'),
                  label: AppStrings.friends,
                  count: state.friends.length,
                  isSelected: _selectedSection == _FriendsSection.friends,
                  onTap: () => _onSectionSelected(_FriendsSection.friends),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SectionButton(
                  key: const Key('requests_section_button'),
                  label: AppStrings.requests,
                  count: state.pendingRequests.length,
                  isSelected: _selectedSection == _FriendsSection.requests,
                  onTap: () => _onSectionSelected(_FriendsSection.requests),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          selectedTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          selectedSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildFriendsSection(FriendState state) {
    if (state.friendsStatus == FriendLoadStatus.error &&
        state.friends.isEmpty) {
      return _SectionFeedbackCard(
        icon: Icons.wifi_off_rounded,
        title: 'Could not load friends',
        description: state.errorMessage ?? AppStrings.errorGeneric,
        actionLabel: AppStrings.retry,
        onPressed: _loadData,
      );
    }

    if (state.friends.isEmpty) {
      return _SectionFeedbackCard(
        icon: Icons.people_outline_rounded,
        title: AppStrings.noFriendsYet,
        description:
            'Your closest collaborators, housemates, and friends will show up here once you connect.',
        actionLabel: AppStrings.addFriend,
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addFriend),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.friendsStatus == FriendLoadStatus.loading) ...[
          const LinearProgressIndicator(
            minHeight: 2,
            color: AppColors.primary,
            backgroundColor: AppColors.progressTrack,
          ),
          const SizedBox(height: AppDimensions.spacingMd),
        ],
        ...state.friends.map(
          (friend) => FriendTile(
            name: friend.friendDisplayName,
            email: friend.friendEmail,
            username: friend.friendUsername,
            imageUrl: friend.friendPhotoUrl,
            statusLabel: 'Connected',
            statusColor: AppColors.success,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.friendProfile,
                arguments: {'friendship': friend},
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsSection(FriendState state) {
    final hasIncoming = state.pendingRequests.isNotEmpty;
    final hasSent = state.sentRequests.isNotEmpty;

    if (state.requestsStatus == FriendLoadStatus.error &&
        !hasIncoming &&
        !hasSent) {
      return _SectionFeedbackCard(
        icon: Icons.mark_email_unread_outlined,
        title: 'Could not load requests',
        description: state.errorMessage ?? AppStrings.errorGeneric,
        actionLabel: AppStrings.retry,
        onPressed: _loadData,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.requestsStatus == FriendLoadStatus.loading) ...[
          const LinearProgressIndicator(
            minHeight: 2,
            color: AppColors.warning,
            backgroundColor: AppColors.progressTrack,
          ),
          const SizedBox(height: AppDimensions.spacingMd),
        ],
        if (!hasIncoming && !hasSent)
          _SectionFeedbackCard(
            icon: Icons.mail_outline_rounded,
            title: AppStrings.noPendingRequests,
            description:
                'New requests will appear here, alongside quick actions to accept or decline them.',
            actionLabel: AppStrings.addFriend,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addFriend),
          )
        else ...[
          if (hasIncoming) ...[
            const _RequestSectionHeader(
              title: 'Incoming',
              subtitle: 'Requests waiting for your response.',
            ),
            ...state.pendingRequests.map(
              (request) =>
                  _RequestCard(request: request, userId: _currentUserId),
            ),
          ],
          if (hasIncoming && hasSent)
            const SizedBox(height: AppDimensions.spacingSm),
          if (hasSent) ...[
            const _RequestSectionHeader(
              title: 'Sent',
              subtitle: 'Requests you have already sent out.',
            ),
            ...state.sentRequests.map(
              (request) => _SentRequestCard(
                request: request,
                currentUserId: _currentUserId,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _SummaryMetricCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _SummaryMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 14),
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionButton extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _SectionButton({
    super.key,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionFeedbackCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onPressed;

  const _SectionFeedbackCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 28,
      backgroundOpacity: 0.05,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              text: actionLabel,
              isPrimary: true,
              width: double.infinity,
              onPressed: onPressed,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _SecondaryActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        backgroundColor: Colors.white.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

class _RequestSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _RequestSectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Friendship request;
  final String userId;

  const _RequestCard({required this.request, required this.userId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FriendBloc>().state;
    final isProcessing = state.actionStatus == ActionStatus.processing;

    return FriendTile(
      name: request.requesterDisplayName,
      email: request.requesterEmail,
      username: request.requesterUsername,
      imageUrl: request.requesterPhotoUrl,
      trailing: _CompactActionStack(
        primaryLabel: 'Accept',
        primaryColor: AppColors.success,
        primaryOnPressed: isProcessing
            ? null
            : () => context.read<FriendBloc>().add(
                FriendRequestAcceptRequested(request.id, userId: userId),
              ),
        secondaryLabel: 'Decline',
        secondaryColor: AppColors.error,
        secondaryOnPressed: isProcessing
            ? null
            : () => context.read<FriendBloc>().add(
                FriendRequestDeclineRequested(request.id),
              ),
      ),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.userProfile,
        arguments: {
          'name': request.requesterDisplayName,
          'username': request.requesterUsername,
          'email': request.requesterEmail,
          'phone': request.requesterPhone,
          'photoUrl': request.requesterPhotoUrl,
          'context': 'pendingRequest',
          'friendshipId': request.id,
          'currentUserId': userId,
        },
      ),
    );
  }
}

class _SentRequestCard extends StatelessWidget {
  final Friendship request;
  final String currentUserId;

  const _SentRequestCard({required this.request, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FriendBloc>().state;
    final isProcessing = state.actionStatus == ActionStatus.processing;

    return FriendTile(
      name: request.friendDisplayName,
      email: request.friendEmail,
      username: request.friendUsername,
      imageUrl: request.friendPhotoUrl,
      trailing: _CompactRequestButton(
        label: 'Cancel',
        color: AppColors.warning,
        onPressed: isProcessing
            ? null
            : () => context.read<FriendBloc>().add(
                FriendRequestDeclineRequested(request.id),
              ),
      ),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.userProfile,
        arguments: {
          'name': request.friendDisplayName,
          'username': request.friendUsername,
          'email': request.friendEmail,
          'phone': request.friendPhone,
          'photoUrl': request.friendPhotoUrl,
          'context': 'searchResult',
          'userId': currentUserId,
          'targetEmail': request.friendEmail,
          'isFriend': false,
          'isPending': true,
        },
      ),
    );
  }
}

class _CompactActionStack extends StatelessWidget {
  final String primaryLabel;
  final Color primaryColor;
  final VoidCallback? primaryOnPressed;
  final String secondaryLabel;
  final Color secondaryColor;
  final VoidCallback? secondaryOnPressed;

  const _CompactActionStack({
    required this.primaryLabel,
    required this.primaryColor,
    required this.primaryOnPressed,
    required this.secondaryLabel,
    required this.secondaryColor,
    required this.secondaryOnPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _CompactRequestButton(
          label: primaryLabel,
          color: primaryColor,
          onPressed: primaryOnPressed,
        ),
        const SizedBox(height: 8),
        _CompactRequestButton(
          label: secondaryLabel,
          color: secondaryColor,
          onPressed: secondaryOnPressed,
        ),
      ],
    );
  }
}

class _CompactRequestButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _CompactRequestButton({
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          side: BorderSide(color: color.withValues(alpha: 0.28)),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
