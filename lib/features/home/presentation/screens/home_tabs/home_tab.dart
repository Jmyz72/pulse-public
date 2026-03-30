import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_routes.dart';
import '../../../../../shared/mixins/stagger_animation_mixin.dart';
import '../../../../../shared/widgets/glass_card.dart';
import '../../../../../shared/widgets/pulse_lottie.dart';
import '../../../domain/entities/dashboard_data.dart';
import '../../../domain/usecases/get_activity_metadata.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/online_members_row.dart';

enum HomeHeroAroundNowMode { nearby, onlineFallback }

/// Home tab showing a shared-group dashboard.
class HomeTab extends StatefulWidget {
  final UserSummary? user;
  final FriendsSummary? friends;
  final ExpenseSummary? expenses;
  final int unreadNotificationsCount;
  final List<RecentActivity> recentActivities;
  final int pendingTasksCount;
  final int upcomingEventsCount;
  final int groceryItemsCount;
  final int aroundNowCount;
  final HomeHeroAroundNowMode aroundNowMode;
  final VoidCallback onViewAllActivities;
  final Future<void> Function() onRefresh;

  const HomeTab({
    super.key,
    this.user,
    this.friends,
    this.expenses,
    required this.unreadNotificationsCount,
    required this.recentActivities,
    required this.pendingTasksCount,
    required this.upcomingEventsCount,
    required this.groceryItemsCount,
    required this.aroundNowCount,
    required this.aroundNowMode,
    required this.onViewAllActivities,
    required this.onRefresh,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with StaggerAnimationMixin {
  static const _copyRotationWindow = Duration(minutes: 10);

  Timer? _copyRotationTimer;
  late int _copySeed;

  @override
  int get staggerCount => 6;

  int get _memberCount => widget.friends?.friendCount ?? 0;

  int get _attentionCount =>
      widget.pendingTasksCount +
      (widget.expenses?.pendingBillsCount ?? 0) +
      widget.upcomingEventsCount +
      widget.groceryItemsCount;

  @override
  void initState() {
    super.initState();
    _copySeed = _currentCopySeed();
    _startCopyRotationTimer();
    startStaggerAnimation();
  }

  @override
  void dispose() {
    _copyRotationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = _greetingForNow();
    final firstName = widget.user?.firstName ?? 'there';

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: Stack(
        children: [
          const Positioned.fill(child: _HomeTabBackdrop()),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                centerTitle: false,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                title: staggerIn(
                  index: 0,
                  child: Text(
                    '$greeting, $firstName',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Notifications',
                    icon: Badge(
                      label: Text('${widget.unreadNotificationsCount}'),
                      isLabelVisible: widget.unreadNotificationsCount > 0,
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.notifications),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppDimensions.spacingLg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    staggerIn(
                      index: 1,
                      child: _PulseHeroCard(
                        copySeed: _copySeed,
                        aroundNowCount: widget.aroundNowCount,
                        aroundNowMode: widget.aroundNowMode,
                        memberCount: _memberCount,
                        attentionCount: _attentionCount,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    staggerIn(
                      index: 2,
                      child: _NeedAttentionSection(
                        unreadNotificationsCount:
                            widget.unreadNotificationsCount,
                        pendingTasksCount: widget.pendingTasksCount,
                        pendingBillsCount:
                            widget.expenses?.pendingBillsCount ?? 0,
                        upcomingEventsCount: widget.upcomingEventsCount,
                        groceryItemsCount: widget.groceryItemsCount,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    staggerIn(
                      index: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(title: 'Who is online?'),
                          const SizedBox(height: AppDimensions.spacingSm),
                          OnlineMembersRow(
                            members: widget.friends?.friends ?? const [],
                            onSeeAll: () =>
                                Navigator.pushNamed(context, AppRoutes.friends),
                            onAddFriends: () => Navigator.pushNamed(
                              context,
                              AppRoutes.addFriend,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    staggerIn(
                      index: 4,
                      child: _TodayTogetherSection(
                        copySeed: _copySeed,
                        upcomingEventsCount: widget.upcomingEventsCount,
                        pendingTasksCount: widget.pendingTasksCount,
                        groceryItemsCount: widget.groceryItemsCount,
                        userShare: widget.expenses?.userShare ?? 0,
                        pendingBillsCount:
                            widget.expenses?.pendingBillsCount ?? 0,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingLg),
                    staggerIn(
                      index: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: _SectionHeader(title: 'Latest updates'),
                              ),
                              TextButton(
                                onPressed: widget.onViewAllActivities,
                                child: const Text('View all'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spacingSm),
                          _buildActivityPreview(theme),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPreview(ThemeData theme) {
    final activities = widget.recentActivities
        .where(ActivityMetadata.isSupported)
        .take(3)
        .toList(growable: false);

    if (activities.isEmpty) {
      return GlassContainer(
        borderRadius: AppDimensions.radiusXl,
        backgroundOpacity: 0.04,
        borderOpacity: 0.3,
        padding: const EdgeInsets.all(AppDimensions.spacingLg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingSm),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Icon(
                Icons.wb_twilight_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quiet for now',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    'New updates will show here.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: activities.map((activity) {
        final presentation = ActivityMetadata.resolve(activity);
        return ActivityCard(
          title: activity.title,
          description: activity.description,
          timeAgo: activity.timeAgo,
          icon: presentation.icon,
          color: presentation.color,
          onTap: presentation.buildOnTap(context),
          variant: ActivityCardVariant.preview,
        );
      }).toList(),
    );
  }

  String _greetingForNow() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 18) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  int _currentCopySeed() {
    return DateTime.now().millisecondsSinceEpoch ~/
        _copyRotationWindow.inMilliseconds;
  }

  void _startCopyRotationTimer() {
    _copyRotationTimer?.cancel();
    _copyRotationTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final nextSeed = _currentCopySeed();
      if (nextSeed == _copySeed || !mounted) return;
      setState(() {
        _copySeed = nextSeed;
      });
    });
  }
}

class _PulseHeroCard extends StatelessWidget {
  final int copySeed;
  final int aroundNowCount;
  final HomeHeroAroundNowMode aroundNowMode;
  final int memberCount;
  final int attentionCount;

  const _PulseHeroCard({
    required this.copySeed,
    required this.aroundNowCount,
    required this.aroundNowMode,
    required this.memberCount,
    required this.attentionCount,
  });

  bool get _isNearbyMode => aroundNowMode == HomeHeroAroundNowMode.nearby;

  int _copyIndex(int salt, int length) {
    final seed =
        copySeed +
        (aroundNowCount * 3) +
        (memberCount * 5) +
        (attentionCount * 7) +
        salt;
    return seed % length;
  }

  String _pick(List<String> options, {int salt = 0}) {
    return options[_copyIndex(salt, options.length)];
  }

  _HeroCopy get _copy {
    if (memberCount == 0) {
      return _HeroCopy(
        headline: _pick(const [
          'Ready when your people are.',
          'Start your first circle.',
          'Bring people into the mix.',
        ]),
        subline: _pick(const [
          'Invite friends or housemates to start sharing plans and updates.',
          'Add a few people and this space becomes a shared dashboard.',
          'The more people you add, the more useful this becomes.',
        ], salt: 1),
        footer: _pick(const [
          'Start by inviting one person',
          'Bring in your people to make this come alive',
          'Your next group plan can start here',
        ], salt: 2),
      );
    }

    if (attentionCount > 0 && aroundNowCount > 0) {
      if (_isNearbyMode) {
        return _HeroCopy(
          headline: _pick([
            '$attentionCount things need action.',
            '$attentionCount loose ends are waiting.',
            'A few things could use attention.',
          ]),
          subline: _pick([
            '$aroundNowCount of $memberCount are within 5 km right now, so this is a good time to clear things up.',
            'Some of your group is physically nearby, and a few items are waiting.',
            'People are close by if you want to sort something out quickly.',
          ], salt: 1),
          footer: _pick(const [
            'Good moment to sort things face to face',
            'A nearby group makes coordination easier',
            'Clear one thing while people are close',
          ], salt: 2),
        );
      }

      return _HeroCopy(
        headline: _pick([
          '$attentionCount things need action.',
          '$attentionCount loose ends are waiting.',
          'A few things could use attention.',
        ]),
        subline: _pick([
          '$aroundNowCount of $memberCount are online, so this is a good time to clear things up.',
          'Your group is active right now, and a few items are waiting.',
          'People are around if you want to close the loop quickly.',
        ], salt: 1),
        footer: _pick(const [
          'Jump into the urgent list below',
          'Good moment to get everyone aligned',
          'Clear one thing and the rest will feel lighter',
        ], salt: 2),
      );
    }

    if (attentionCount > 0) {
      if (_isNearbyMode) {
        return _HeroCopy(
          headline: _pick([
            '$attentionCount things are waiting.',
            '$attentionCount items need attention.',
            'A few loose ends are sitting here.',
          ]),
          subline: _pick(const [
            'No one is nearby right now, but the list is ready when people are close again.',
            'Things are queued up for the next time someone is around.',
            'Nothing is chaotic, but this may be easier once people are nearby.',
          ], salt: 1),
          footer: _pick(const [
            'Keep the list ready for the next meet-up',
            'A quick clean-up later will help',
            'Save this for when people are close by',
          ], salt: 2),
        );
      }

      return _HeroCopy(
        headline: _pick([
          '$attentionCount things are waiting.',
          '$attentionCount items need attention.',
          'A few loose ends are sitting here.',
        ]),
        subline: _pick(const [
          'No one is online right now, but the list is ready when you are.',
          'Things are queued up for the next check-in.',
          'Nothing is chaotic, but it is worth clearing soon.',
        ], salt: 1),
        footer: _pick(const [
          'Start with the urgent list below',
          'A quick clean-up here will help later',
          'Pick off one item and the rest gets easier',
        ], salt: 2),
      );
    }

    if (aroundNowCount > 0) {
      if (_isNearbyMode) {
        return _HeroCopy(
          headline: _pick(const [
            'People are nearby.',
            'Your circle is close by.',
            'A few friends are around town.',
          ]),
          subline: _pick([
            '$aroundNowCount of $memberCount are within 5 km with nothing urgent pending.',
            'A calm moment when part of the group is already nearby.',
            'A good time for a quick plan, chat, or errand together.',
          ], salt: 1),
          footer: _pick(const [
            'Nice moment to make a nearby plan',
            'A local catch-up would fit well here',
            'Use the calm while people are close',
          ], salt: 2),
        );
      }

      return _HeroCopy(
        headline: _pick(const [
          'Good energy right now.',
          'Quiet, but active.',
          'Everyone looks in sync.',
        ]),
        subline: _pick([
          '$aroundNowCount of $memberCount are online with nothing urgent pending.',
          'People are around and the board is clear.',
          'A good moment to start a plan, chat, or errand.',
        ], salt: 1),
        footer: _pick(const [
          'Good time to coordinate something',
          'Use the calm to start the next plan',
          'Nice moment to kick off something shared',
        ], salt: 2),
      );
    }

    if (_isNearbyMode) {
      return _HeroCopy(
        headline: _pick(const [
          'All clear nearby.',
          'Nothing urgent nearby.',
          'A quiet moment around your groups.',
        ]),
        subline: _pick(const [
          'No one is nearby right now, and nothing urgent is waiting.',
          'Everything looks settled until the next local plan comes up.',
          'The board is calm for now, even if no one is close by.',
        ], salt: 1),
        footer: _pick(const [
          'Quiet nearby for the moment',
          'Nothing needs an in-person reaction right now',
          'Use this when the next nearby plan shows up',
        ], salt: 2),
      );
    }

    return _HeroCopy(
      headline: _pick(const [
        'All clear today.',
        'Nothing is piling up.',
        'A quiet moment across your groups.',
      ]),
      subline: _pick(const [
        'No one is online right now, and nothing urgent is waiting.',
        'Everything looks settled for the moment.',
        'The board is calm until the next update comes in.',
      ], salt: 1),
      footer: _pick(const [
        'Quiet across your groups',
        'Nothing needs a quick reaction right now',
        'Use this space when the next plan comes up',
      ], salt: 2),
    );
  }

  IconData get _footerIcon {
    if (memberCount == 0) {
      return Icons.person_add_alt_1;
    }
    if (attentionCount > 0) {
      return Icons.arrow_downward_rounded;
    }
    if (aroundNowCount > 0) {
      if (_isNearbyMode) {
        return Icons.location_on_outlined;
      }
      return Icons.wb_sunny_outlined;
    }
    if (_isNearbyMode) {
      return Icons.place_outlined;
    }
    return Icons.nightlight_round;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary.withValues(alpha: 0.82),
            AppColors.backgroundLight.withValues(alpha: 0.97),
            AppColors.backdropGlowA.withValues(alpha: 0.55),
          ],
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                key: ValueKey('home-hero-walker-repaint-boundary'),
                child: _HeroCardWalker(),
              ),
            ),
          ),
          Positioned(
            top: -12,
            right: -8,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spacingLg,
              AppDimensions.spacingXl + 6,
              AppDimensions.spacingLg,
              AppDimensions.spacingLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _copy.headline,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXs),
                Text(
                  _copy.subline,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.82),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                Row(
                  children: [
                    Expanded(
                      child: _HeroStatCard(
                        icon: Icons.people_alt_outlined,
                        label: _isNearbyMode ? 'Around now' : 'Online now',
                        value: '$aroundNowCount',
                        color: AppColors.neonGreen,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingSm),
                    Expanded(
                      child: _HeroStatCard(
                        icon: Icons.notifications_active_outlined,
                        label: 'Need action',
                        value: '$attentionCount',
                        color: AppColors.neonYellow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingMd,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(_footerIcon, size: 18, color: AppColors.white),
                      const SizedBox(width: AppDimensions.spacingSm),
                      Expanded(
                        child: Text(
                          _copy.footer,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.white.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCardWalker extends StatefulWidget {
  const _HeroCardWalker();

  @override
  State<_HeroCardWalker> createState() => _HeroCardWalkerState();
}

class _HeroCardWalkerState extends State<_HeroCardWalker>
    with SingleTickerProviderStateMixin {
  static const _pencilWidth = 126.0;
  static const _pencilHeight = 74.0;
  static const _horizontalInset = AppDimensions.spacingLg;
  static const _topOffset = -32.0;
  static const _travelDuration = Duration(seconds: 6);

  late final AnimationController _controller;
  late final Animation<double> _travel;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _travelDuration)
      ..repeat(reverse: true);
    _travel = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxTravel = math.max(
          0.0,
          constraints.maxWidth - (_horizontalInset * 2) - _pencilWidth,
        );

        return AnimatedBuilder(
          animation: _travel,
          builder: (context, child) {
            final isReturning = _controller.status == AnimationStatus.reverse;
            final left = _horizontalInset + (maxTravel * _travel.value);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: _topOffset,
                  left: left,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(
                      isReturning ? -1 : 1,
                      1,
                      1,
                    ),
                    child: child,
                  ),
                ),
              ],
            );
          },
          child: const PulseLottie(
            key: ValueKey('home-hero-walking-pencil'),
            assetPath: 'assets/animations/Walking Pencil.lottie',
            width: _pencilWidth,
            height: _pencilHeight,
            semanticLabel: 'Walking pencil animation',
            renderCache: RenderCache.drawingCommands,
          ),
        );
      },
    );
  }
}

class _HeroCopy {
  final String headline;
  final String subline;
  final String footer;

  const _HeroCopy({
    required this.headline,
    required this.subline,
    required this.footer,
  });
}

class _NeedAttentionSection extends StatelessWidget {
  final int unreadNotificationsCount;
  final int pendingTasksCount;
  final int pendingBillsCount;
  final int upcomingEventsCount;
  final int groceryItemsCount;

  const _NeedAttentionSection({
    required this.unreadNotificationsCount,
    required this.pendingTasksCount,
    required this.pendingBillsCount,
    required this.upcomingEventsCount,
    required this.groceryItemsCount,
  });

  List<_AttentionItem> _items() {
    final items = <_AttentionItem>[];

    if (pendingBillsCount > 0) {
      items.add(
        _AttentionItem(
          title: pendingBillsCount == 1
              ? '1 unpaid bill'
              : '$pendingBillsCount unpaid bills',
          actionLabel: 'Bills',
          route: AppRoutes.livingTools,
          icon: Icons.receipt_long,
          color: AppColors.bill,
        ),
      );
    }

    if (pendingTasksCount > 0) {
      items.add(
        _AttentionItem(
          title: pendingTasksCount == 1
              ? '1 open task'
              : '$pendingTasksCount open tasks',
          actionLabel: 'Tasks',
          route: AppRoutes.tasks,
          icon: Icons.task_alt,
          color: AppColors.task,
        ),
      );
    }

    if (groceryItemsCount > 0) {
      items.add(
        _AttentionItem(
          title: groceryItemsCount == 1
              ? '1 item to buy'
              : '$groceryItemsCount items to buy',
          actionLabel: 'Grocery',
          route: AppRoutes.grocery,
          icon: Icons.shopping_basket_outlined,
          color: AppColors.grocery,
        ),
      );
    }

    if (upcomingEventsCount > 0) {
      items.add(
        _AttentionItem(
          title: upcomingEventsCount == 1
              ? '1 upcoming event'
              : '$upcomingEventsCount upcoming events',
          actionLabel: 'Events',
          route: AppRoutes.events,
          icon: Icons.event_available,
          color: AppColors.event,
        ),
      );
    }

    if (unreadNotificationsCount > 0) {
      items.add(
        _AttentionItem(
          title: unreadNotificationsCount == 1
              ? '1 unread update'
              : '$unreadNotificationsCount unread updates',
          actionLabel: 'Inbox',
          route: AppRoutes.notifications,
          icon: Icons.notifications_active_outlined,
          color: AppColors.primary,
        ),
      );
    }

    return items.take(3).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _items();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Urgent first'),
        const SizedBox(height: AppDimensions.spacingSm),
        if (items.isEmpty)
          GlassContainer(
            borderRadius: AppDimensions.radiusXl,
            backgroundOpacity: 0.04,
            borderOpacity: 0.28,
            padding: const EdgeInsets.all(AppDimensions.spacingLg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingSm),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nothing urgent',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXs),
                      Text(
                        'Everything looks under control.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: [
              for (final item in items) ...[
                _AttentionCard(item: item),
                if (item != items.last)
                  const SizedBox(height: AppDimensions.spacingSm),
              ],
            ],
          ),
      ],
    );
  }
}

class _TodayTogetherSection extends StatelessWidget {
  final int copySeed;
  final int upcomingEventsCount;
  final int pendingTasksCount;
  final int groceryItemsCount;
  final double userShare;
  final int pendingBillsCount;

  const _TodayTogetherSection({
    required this.copySeed,
    required this.upcomingEventsCount,
    required this.pendingTasksCount,
    required this.groceryItemsCount,
    required this.userShare,
    required this.pendingBillsCount,
  });

  int _copyIndex(int salt, int length) {
    final seed =
        copySeed +
        (upcomingEventsCount * 3) +
        (pendingTasksCount * 5) +
        (groceryItemsCount * 7) +
        (pendingBillsCount * 11) +
        userShare.floor() +
        salt;
    return seed % length;
  }

  String _pick(List<String> options, {int salt = 0}) {
    return options[_copyIndex(salt, options.length)];
  }

  _StoryCardData _buildScheduleCard() {
    return _StoryCardData(
      eyebrow: 'Schedule',
      title: _pick(const [
        'Open shared schedule',
        'See the day at a glance',
        'Line up today’s timing',
      ]),
      subtitle: _pick(const [
        'Plan your day',
        'Keep timing in sync',
        'Map out the week',
      ], salt: 1),
      icon: Icons.calendar_view_week_outlined,
      color: AppColors.schedule,
      route: AppRoutes.timetable,
    );
  }

  _StoryCardData _buildPlansCard() {
    final title = upcomingEventsCount > 0
        ? _pick([
            '$upcomingEventsCount plans coming up',
            '$upcomingEventsCount things on the calendar',
            '$upcomingEventsCount plans to look forward to',
          ])
        : _pick(const [
            'No plans yet',
            'The calendar is open',
            'Nothing planned yet',
          ]);
    final subtitle = upcomingEventsCount > 0
        ? _pick(const [
            'Open calendar',
            'See what is next',
            'Check the details',
          ], salt: 1)
        : _pick(const ['Add one', 'Start a plan', 'Create something'], salt: 1);

    return _StoryCardData(
      eyebrow: 'Plans',
      title: title,
      subtitle: subtitle,
      icon: Icons.event_note_outlined,
      color: AppColors.event,
      route: AppRoutes.events,
    );
  }

  _StoryCardData _buildBillsCard() {
    final title = pendingBillsCount > 0
        ? _pick([
            '$pendingBillsCount bills pending',
            '$pendingBillsCount bills waiting',
            'Bills need a check-in',
          ])
        : _pick(const [
            'Bills look clear',
            'No bills waiting',
            'All bills settled',
          ]);
    final subtitle = pendingBillsCount > 0
        ? _pick(const [
            'Payments waiting',
            'Open and settle them',
            'Keep bills tidy',
          ], salt: 1)
        : _pick(const [
            'All settled',
            'Nothing pending',
            'You are in the clear',
          ], salt: 1);

    return _StoryCardData(
      eyebrow: 'Bills',
      title: title,
      subtitle: subtitle,
      icon: Icons.receipt_long,
      color: AppColors.bill,
      route: AppRoutes.livingTools,
    );
  }

  _StoryCardData _buildExpensesCard() {
    final title = userShare > 0
        ? _pick([
            'RM ${userShare.toStringAsFixed(2)} tracked',
            'RM ${userShare.toStringAsFixed(2)} in shared spend',
            'Shared spend at RM ${userShare.toStringAsFixed(2)}',
          ])
        : _pick(const [
            'No shared spend yet',
            'Nothing tracked yet',
            'Expenses are quiet',
          ]);
    final subtitle = userShare > 0
        ? _pick(const [
            'View shared spend',
            'Review recent receipts',
            'See how spending looks',
          ], salt: 1)
        : _pick(const [
            'Start tracking',
            'Add a first expense',
            'Split something',
          ], salt: 1);

    return _StoryCardData(
      eyebrow: 'Expenses',
      title: title,
      subtitle: subtitle,
      icon: Icons.account_balance_wallet_outlined,
      color: AppColors.expense,
      route: AppRoutes.expense,
    );
  }

  _StoryCardData _buildShoppingCard() {
    final title = groceryItemsCount > 0
        ? _pick([
            '$groceryItemsCount items to pick up',
            '$groceryItemsCount things on the list',
            'Shopping list is active',
          ])
        : _pick(const [
            'Shopping list is clear',
            'Nothing to buy',
            'No items on the list',
          ]);
    final subtitle = groceryItemsCount > 0
        ? _pick(const [
            'Open shopping',
            'Shared list',
            'Grab the basics',
          ], salt: 1)
        : _pick(const [
            'All stocked',
            'Add items anytime',
            'Nothing to buy',
          ], salt: 1);

    return _StoryCardData(
      eyebrow: 'Shopping',
      title: title,
      subtitle: subtitle,
      icon: Icons.shopping_cart_outlined,
      color: AppColors.grocery,
      route: AppRoutes.grocery,
    );
  }

  _StoryCardData _buildTasksCard() {
    final title = pendingTasksCount > 0
        ? _pick([
            '$pendingTasksCount tasks waiting',
            '$pendingTasksCount things to tick off',
            'Tasks need attention',
          ])
        : _pick(const [
            'No open tasks',
            'Task list is clear',
            'Nothing waiting',
          ]);
    final subtitle = pendingTasksCount > 0
        ? _pick(const [
            'Open tasks',
            'Check your list',
            'Clear the queue',
          ], salt: 1)
        : _pick(const [
            'All caught up',
            'Keep it moving',
            'Add a new task',
          ], salt: 1);

    return _StoryCardData(
      eyebrow: 'Tasks',
      title: title,
      subtitle: subtitle,
      icon: Icons.task_alt_outlined,
      color: AppColors.neonYellow,
      route: AppRoutes.tasks,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _buildScheduleCard(),
      _buildPlansCard(),
      _buildBillsCard(),
      _buildExpensesCard(),
      _buildShoppingCard(),
      _buildTasksCard(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'What\'s on'),
        const SizedBox(height: AppDimensions.spacingSm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppDimensions.spacingMd,
            crossAxisSpacing: AppDimensions.spacingMd,
            mainAxisExtent: 172,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => _StoryCard(card: cards[index]),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _HeroStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HeroStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  final _AttentionItem item;

  const _AttentionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, item.route),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: GlassContainer(
          borderRadius: AppDimensions.radiusXl,
          backgroundOpacity: 0.05,
          borderOpacity: 0.42,
          borderColor: item.color,
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingSm + 2),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.actionLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: item.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Icon(Icons.chevron_right, color: item.color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final _StoryCardData card;

  const _StoryCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, card.route),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: GlassContainer(
          borderRadius: AppDimensions.radiusXl,
          backgroundOpacity: 0.05,
          borderOpacity: 0.34,
          borderColor: card.color,
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spacingMd,
            14,
            AppDimensions.spacingMd,
            14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingSm),
                decoration: BoxDecoration(
                  color: card.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(card.icon, color: card.color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                card.eyebrow.toUpperCase(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: card.color,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                card.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              Text(
                card.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTabBackdrop extends StatelessWidget {
  const _HomeTabBackdrop();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned(
          top: -90,
          left: -40,
          child: _BackdropOrb(
            size: 220,
            color: AppColors.backdropGlowA,
            opacity: 0.10,
          ),
        ),
        Positioned(
          top: 220,
          right: -70,
          child: _BackdropOrb(
            size: 240,
            color: AppColors.backdropGlowB,
            opacity: 0.08,
          ),
        ),
        Positioned(
          bottom: 100,
          left: -50,
          child: _BackdropOrb(
            size: 180,
            color: AppColors.backdropGlowC,
            opacity: 0.08,
          ),
        ),
      ],
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _BackdropOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: opacity),
              blurRadius: size * 0.55,
              spreadRadius: size * 0.06,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttentionItem {
  final String title;
  final String actionLabel;
  final String route;
  final IconData icon;
  final Color color;

  const _AttentionItem({
    required this.title,
    required this.actionLabel,
    required this.route,
    required this.icon,
    required this.color,
  });
}

class _StoryCardData {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _StoryCardData({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}
