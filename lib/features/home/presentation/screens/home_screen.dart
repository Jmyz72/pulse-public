import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../chat/presentation/screens/new_chat_sheet.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import 'home_tabs/chat_tab.dart';
import '../bloc/home_bloc.dart';
import 'home_tabs/location_tab.dart';
import 'home_tabs/home_tab.dart';
import 'home_tabs/activity_tab.dart';
import 'home_tabs/profile_tab.dart';
import '../../../../shared/widgets/glass_bottom_nav.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../widgets/skeletons/home_skeleton.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../chat/domain/usecases/update_presence.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../../injection_container.dart' as di;

/// Heartbeat interval for presence updates.
const _presenceHeartbeatInterval = Duration(seconds: 60);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // Presence
  Timer? _presenceHeartbeatTimer;
  String? _currentUserId;
  bool _isInvisibleMode = false;
  Map<String, dynamic>? _pendingDeepLink;
  bool _hasStartedChatWatch = false;
  bool _hasStartedLocationLoad = false;

  // Refresh completer for pull-to-refresh feedback
  Completer<void>? _refreshCompleter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = context.read<AuthBloc>().state;
    if (!_hasStartedChatWatch &&
        authState.status == AuthStatus.authenticated &&
        authState.user != null) {
      _hasStartedChatWatch = true;
      context.read<ChatBloc>().add(ChatRoomsWatchRequested());
    }
    if (!_hasStartedLocationLoad &&
        authState.status == AuthStatus.authenticated &&
        authState.user != null) {
      _hasStartedLocationLoad = true;
      context.read<LocationBloc>().add(
        LocationLoadRequested(userId: authState.user!.id),
      );
    }

    if (_currentUserId == null) {
      _currentUserId = authState.user?.id;
      _isInvisibleMode =
          context.read<SettingsBloc>().state.settings?.invisibleMode ?? false;
      if (_isInvisibleMode) {
        _hidePresenceNow();
      } else {
        _goOnlineVisible();
      }

      // Check for deep-link arguments (like initialTab)
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('initialTab')) {
        setState(() {
          _pendingDeepLink = args;
        });
        final initialTab = args['initialTab'] as int;
        context.read<HomeBloc>().add(
          HomeTabChangeRequested(tabIndex: initialTab),
        );
      }
    }
  }

  void _onDeepLinkHandled() {
    setState(() {
      _pendingDeepLink = null;
    });
  }

  void _handleDeepLink(Map<String, dynamic> args) {
    if (!mounted) return;

    setState(() {
      _pendingDeepLink = args;
    });

    if (args.containsKey('initialTab')) {
      final initialTab = args['initialTab'] as int;
      context.read<HomeBloc>().add(
        HomeTabChangeRequested(tabIndex: initialTab),
      );
    }
  }

  void _setPresence(bool online, {bool updateLastSeen = true}) {
    final uid = _currentUserId;
    if (uid != null && uid.isNotEmpty) {
      di.sl<UpdatePresence>().call(uid, online, updateLastSeen: updateLastSeen);
    }
  }

  void _goOnlineVisible() {
    _setPresence(true, updateLastSeen: true);
    _startHeartbeat();
  }

  void _goOfflineVisible() {
    _presenceHeartbeatTimer?.cancel();
    _setPresence(false, updateLastSeen: true);
  }

  void _hidePresenceNow() {
    _presenceHeartbeatTimer?.cancel();
    _setPresence(false, updateLastSeen: false);
  }

  void _onInvisibleModeChanged(bool isInvisibleMode) {
    if (_isInvisibleMode == isInvisibleMode) return;
    _isInvisibleMode = isInvisibleMode;

    if (_isInvisibleMode) {
      _hidePresenceNow();
      return;
    }

    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (lifecycleState == null || lifecycleState == AppLifecycleState.resumed) {
      _goOnlineVisible();
    }
  }

  void _startHeartbeat() {
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = Timer.periodic(_presenceHeartbeatInterval, (_) {
      _setPresence(true, updateLastSeen: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isInvisibleMode) {
        _hidePresenceNow();
      } else {
        _goOnlineVisible();
      }
      context.read<HomeBloc>().add(const HomeRefreshRequested());
    } else if (state == AppLifecycleState.paused) {
      if (_isInvisibleMode) {
        _presenceHeartbeatTimer?.cancel();
      } else {
        _goOfflineVisible();
      }
    }
  }

  /// Dispatches refresh and returns a Future that completes when the BLoC
  /// emits a non-loading state. This keeps the [RefreshIndicator] spinner
  /// visible until data actually arrives.
  Future<void> _onRefresh() {
    _refreshCompleter = Completer<void>();
    context.read<HomeBloc>().add(const HomeRefreshRequested(force: true));
    return _refreshCompleter!.future;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isInvisibleMode) {
      _presenceHeartbeatTimer?.cancel();
    } else {
      _goOfflineVisible();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, authState) {
        if (authState.status == AuthStatus.unauthenticated) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.authIntro,
            (route) => false,
          );
        }
      },
      child: BlocListener<SettingsBloc, SettingsState>(
        listenWhen: (previous, current) =>
            previous.settings?.invisibleMode != current.settings?.invisibleMode,
        listener: (context, settingsState) {
          _onInvisibleModeChanged(
            settingsState.settings?.invisibleMode ?? false,
          );
        },
        child: BlocConsumer<HomeBloc, HomeState>(
          listener: (context, state) {
            // Complete the refresh completer when data finishes loading
            if (state.status != HomeStatus.loading) {
              _refreshCompleter?.complete();
              _refreshCompleter = null;
            }

            if (context.read<AuthBloc>().state.status ==
                AuthStatus.unauthenticated) {
              return;
            }

            if (state.status == HomeStatus.error &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  action: SnackBarAction(
                    label: 'Retry',
                    textColor: AppColors.white,
                    onPressed: () => context.read<HomeBloc>().add(
                      const HomeRefreshRequested(force: true),
                    ),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.status == HomeStatus.loading) {
              return Scaffold(
                body: const HomeSkeleton(),
                extendBody: true,
                bottomNavigationBar: GlassBottomNav(
                  currentIndex: state.currentTab,
                  onTap: (index) {
                    HapticFeedback.selectionClick();
                    context.read<HomeBloc>().add(
                      HomeTabChangeRequested(tabIndex: index),
                    );
                  },
                ),
              );
            }

            return Scaffold(
              body: IndexedStack(
                index: state.currentTab,
                children: [
                  // Tab 0: Map (self-contained)
                  LocationTab(
                    members: state.friends?.friends ?? [],
                    initialLocation: _pendingDeepLink,
                    onLocationHandled: _onDeepLinkHandled,
                  ),
                  // Tab 1: Chat
                  ChatTab(
                    onNewChat: () => NewChatSheet.show(context),
                    onDeepLink: _handleDeepLink,
                  ),
                  // Tab 2: Home Dashboard
                  BlocBuilder<LocationBloc, LocationState>(
                    builder: (context, locationState) {
                      final nearbySummary = locationState.nearbyFriendsSummary;
                      final onlineCount =
                          state.friends?.friends
                              .where((member) => member.isOnline)
                              .length ??
                          0;
                      final aroundNowCount = nearbySummary.isReliable
                          ? nearbySummary.count
                          : onlineCount;
                      final aroundNowMode = nearbySummary.isReliable
                          ? HomeHeroAroundNowMode.nearby
                          : HomeHeroAroundNowMode.onlineFallback;

                      return TickerMode(
                        enabled: state.currentTab == 2,
                        child: HomeTab(
                          user: state.user,
                          friends: state.friends,
                          expenses: state.expenses,
                          unreadNotificationsCount:
                              state.unreadNotificationsCount,
                          recentActivities: state.recentActivities,
                          pendingTasksCount: state.pendingTasksCount,
                          upcomingEventsCount: state.upcomingEventsCount,
                          groceryItemsCount: state.groceryItemsCount,
                          aroundNowCount: aroundNowCount,
                          aroundNowMode: aroundNowMode,
                          onViewAllActivities: () => context
                              .read<HomeBloc>()
                              .add(const HomeTabChangeRequested(tabIndex: 3)),
                          onRefresh: _onRefresh,
                        ),
                      );
                    },
                  ),
                  // Tab 3: Activity Feed
                  ActivityTab(
                    activities: state.recentActivities,
                    onRefresh: _onRefresh,
                    isLoading: state.status == HomeStatus.loading,
                    errorMessage: state.status == HomeStatus.error
                        ? state.errorMessage
                        : null,
                  ),
                  // Tab 4: Profile
                  ProfileTab(user: state.user),
                ],
              ),
              extendBody: true,
              floatingActionButton: state.currentTab == 1
                  ? FloatingActionButton(
                      onPressed: () => NewChatSheet.show(context),
                      backgroundColor: AppColors.primary,
                      tooltip: 'New message',
                      child: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                      ),
                    )
                  : null,
              bottomNavigationBar: GlassBottomNav(
                currentIndex: state.currentTab,
                onTap: (index) {
                  HapticFeedback.selectionClick();
                  context.read<HomeBloc>().add(
                    HomeTabChangeRequested(tabIndex: index),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
