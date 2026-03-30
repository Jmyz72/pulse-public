import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/friend_bloc.dart';
import '../bloc/friend_event.dart';
import '../bloc/friend_state.dart';
import '../widgets/friend_tile.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _searchController = TextEditingController();
  late final FriendBloc _friendBloc;

  String get _currentUserId => context.read<AuthBloc>().state.user?.id ?? '';

  @override
  void initState() {
    super.initState();
    _friendBloc = context.read<FriendBloc>();
    _friendBloc.add(const FriendSearchCleared());
    _searchController.addListener(_handleSearchFieldChanged);
  }

  @override
  void dispose() {
    _friendBloc.add(const FriendSearchCleared());
    _searchController
      ..removeListener(_handleSearchFieldChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchFieldChanged() {
    if (mounted) setState(() {});
  }

  void _onSearchChanged(String query) {
    _friendBloc.add(UserSearchRequested(query));
  }

  void _clearSearch() {
    _searchController.clear();
    _friendBloc.add(const FriendSearchCleared());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: GlassAppBar(
        title: AppStrings.addFriend,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
            _friendBloc.add(const FriendMessageCleared());
            final uid = _currentUserId;
            if (uid.isNotEmpty) {
              _friendBloc
                ..add(FriendsLoadRequested(uid))
                ..add(PendingRequestsLoadRequested(uid));
            }
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
            _friendBloc.add(const FriendMessageCleared());
          }
        },
        builder: (context, state) {
          final visibleResults = state.searchResults
              .where((user) => user.id != _currentUserId)
              .toList();
          final query = _searchController.text.trim();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(state),
                      const SizedBox(height: AppDimensions.spacingLg),
                      _buildSearchField(),
                      const SizedBox(height: AppDimensions.spacingMd),
                      if (query.isNotEmpty || visibleResults.isNotEmpty)
                        _ResultsSummary(
                          query: query,
                          count: visibleResults.length,
                          isLoading: state.searchStatus == SearchStatus.loading,
                          onClear: query.isNotEmpty ? _clearSearch : null,
                        ),
                      if (query.isNotEmpty || visibleResults.isNotEmpty)
                        const SizedBox(height: AppDimensions.spacingMd),
                      _buildContent(theme, state, visibleResults, query),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroCard(FriendState state) {
    final incomingCount = state.pendingRequests.length;
    final outgoingCount = state.sentRequests.length;

    return GlassCard(
      borderRadius: 32,
      backgroundOpacity: 0.08,
      borderOpacity: 0.5,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _AddFriendMetric(
                  label: 'Pending in',
                  value: '$incomingCount',
                  icon: Icons.mark_email_unread_rounded,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AddFriendMetric(
                  label: 'Pending out',
                  value: '$outgoingCount',
                  icon: Icons.north_east_rounded,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AddFriendMetric(
                  label: 'Ready',
                  value: _searchController.text.trim().isEmpty
                      ? 'Search'
                      : 'Review',
                  icon: Icons.bolt_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return GlassContainer(
      borderRadius: 26,
      backgroundOpacity: 0.05,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: AppStrings.searchByUsernameEmailPhone,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Clear search',
                  onPressed: _clearSearch,
                )
              : null,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    ThemeData theme,
    FriendState state,
    List<dynamic> visibleResults,
    String query,
  ) {
    if (state.searchStatus == SearchStatus.loading) {
      return const Padding(
        padding: EdgeInsets.only(top: AppDimensions.spacingXl),
        child: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (visibleResults.isEmpty && query.isNotEmpty) {
      return const _SearchFeedbackCard(
        icon: Icons.search_off_rounded,
        title: AppStrings.noUsersFound,
        description:
            'Try a username, full email, or phone number. If they are already connected, they may appear with a status badge instead of an add action.',
      );
    }

    if (visibleResults.isEmpty) {
      return const _SearchFeedbackCard(
        icon: Icons.travel_explore_rounded,
        title: AppStrings.searchForUsers,
        description:
            'Start with a username, email, or phone number. Matching profiles will appear here with relationship context and quick actions.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: visibleResults.map<Widget>((user) {
        final isFriend = state.friends.any(
          (f) => f.friendId == user.id || f.userId == user.id,
        );
        final incomingRequest = state.pendingRequests
            .where((r) => r.userId == user.id)
            .firstOrNull;
        final sentRequest = state.sentRequests
            .where((r) => r.friendId == user.id)
            .firstOrNull;
        final isPending = incomingRequest != null || sentRequest != null;

        return FriendTile(
          name: user.displayName,
          email: user.email,
          username: user.username,
          imageUrl: user.photoUrl,
          statusLabel: isFriend
              ? AppStrings.friends
              : incomingRequest != null
              ? 'Requested you'
              : null,
          statusColor: isFriend
              ? AppColors.success
              : incomingRequest != null
              ? AppColors.warning
              : AppColors.primary,
          trailing: sentRequest != null
              ? _CompactActionButton(
                  label: 'Cancel',
                  color: AppColors.warning,
                  isLoading: state.actionStatus == ActionStatus.processing,
                  onPressed: () {
                    _friendBloc.add(
                      FriendRequestDeclineRequested(sentRequest.id),
                    );
                  },
                )
              : !isFriend && !isPending
              ? _CompactActionButton(
                  label: 'Add',
                  color: AppColors.primary,
                  isLoading: state.actionStatus == ActionStatus.processing,
                  onPressed: () {
                    _friendBloc.add(
                      FriendRequestSendRequested(
                        userId: _currentUserId,
                        email: user.email,
                      ),
                    );
                  },
                )
              : null,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.userProfile,
            arguments: {
              'name': user.displayName,
              'username': user.username,
              'email': user.email,
              'phone': user.phone,
              'photoUrl': user.photoUrl,
              'context': 'searchResult',
              'userId': _currentUserId,
              'targetEmail': user.email,
              'isFriend': isFriend,
              'isPending': isPending,
            },
          ),
        );
      }).toList(),
    );
  }
}

class _AddFriendMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _AddFriendMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
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
    );
  }
}

class _ResultsSummary extends StatelessWidget {
  final String query;
  final int count;
  final bool isLoading;
  final VoidCallback? onClear;

  const _ResultsSummary({
    required this.query,
    required this.count,
    required this.isLoading,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = isLoading
        ? 'Searching for matches...'
        : '$count result${count == 1 ? '' : 's'} for "$query"';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Results',
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
        ),
        if (onClear != null)
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Clear'),
          ),
      ],
    );
  }
}

class _SearchFeedbackCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _SearchFeedbackCard({
    required this.icon,
    required this.title,
    required this.description,
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
        ],
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String label;
  final Color color;

  const _CompactActionButton({
    required this.onPressed,
    required this.label,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          side: BorderSide(color: color.withValues(alpha: 0.28)),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
