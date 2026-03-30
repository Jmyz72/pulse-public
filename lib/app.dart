import 'dart:async';
import 'dart:developer' as developer;

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_routes.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/services/fcm_token_datasource.dart';
import 'shared/widgets/app_backdrop.dart';
import 'injection_container.dart' as di;

// Auth
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/email_verification_screen.dart';
import 'features/auth/presentation/screens/google_username_setup_screen.dart';
import 'features/auth/presentation/screens/profile_completion_screen.dart';
import 'features/auth/presentation/screens/auth_intro_screen.dart';

// Home
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/home/presentation/screens/home_screen.dart';

// Features
import 'features/expense/domain/entities/expense.dart';
import 'features/expense/presentation/bloc/expense_bloc.dart';
import 'features/expense/presentation/screens/expense_screen.dart';
import 'features/expense/presentation/screens/add_expense.dart';
import 'features/expense/presentation/screens/receipt_scan_screen.dart';
import 'features/expense/presentation/screens/expense_details_screen.dart';
import 'features/expense/presentation/screens/item_selection_screen.dart';
import 'features/expense/presentation/screens/balance_screen.dart';
import 'features/grocery/presentation/bloc/grocery_bloc.dart';
import 'features/grocery/presentation/screens/grocery_screen.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/chat/presentation/screens/group_chat_screen.dart';
import 'features/chat/presentation/screens/group_info_screen.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';
import 'features/tasks/presentation/screens/tasks_screen.dart';
import 'features/location/presentation/bloc/location_bloc.dart';
import 'features/location/presentation/bloc/event_bloc.dart';
import 'features/events/presentation/screens/events_screen.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/notifications/presentation/screens/notifications_screen.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/presentation/screens/privacy_settings.dart';
import 'features/settings/presentation/screens/profile_settings.dart';
import 'features/settings/presentation/screens/account_security_screen.dart';
import 'package:pulse/features/living_tools/presentation/bloc/living_tools_bloc.dart';
import 'package:pulse/features/living_tools/presentation/screens/living_tools_screen.dart';
import 'package:pulse/features/friends/presentation/bloc/friend_bloc.dart';
import 'features/friends/presentation/bloc/friend_event.dart';
import 'features/friends/presentation/bloc/friend_state.dart';
import 'features/friends/presentation/screens/friends_screen.dart';
import 'features/friends/presentation/screens/add_friend_screen.dart';
import 'features/friends/presentation/screens/friend_profile_screen.dart';
import 'features/friends/presentation/screens/user_profile_screen.dart';
import 'features/friends/domain/entities/friendship.dart';
import 'features/settings/presentation/screens/edit_profile_screen.dart';

// Timetable
import 'features/timetable/presentation/bloc/timetable_bloc.dart';
import 'features/timetable/domain/entities/timetable_entry.dart';
import 'features/timetable/presentation/screens/timetable_screen.dart';
import 'features/timetable/presentation/screens/add_edit_entry_screen.dart';
import 'features/timetable/presentation/screens/shared_timetable_screen.dart';

// Auth Gate
import 'features/auth/presentation/screens/auth_gate.dart';

class PulseApp extends StatefulWidget {
  const PulseApp({super.key});

  @override
  State<PulseApp> createState() => _PulseAppState();
}

class _PulseAppState extends State<PulseApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _authLinkSubscription;
  bool _didSetupAuthLinks = false;

  @override
  void initState() {
    super.initState();
    _setupFcmHandlers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAuthLinkHandlers();
    });
  }

  void _setupFcmHandlers() {
    NotificationService.setMessageTapHandler((data) {
      final chatRoomId = data['chatRoomId'] as String?;
      if (chatRoomId != null) {
        _navigatorKey.currentState?.pushNamed(
          AppRoutes.groupChat,
          arguments: {'id': chatRoomId},
        );
      }
    });
  }

  Future<void> _setupAuthLinkHandlers() async {
    if (_didSetupAuthLinks) {
      return;
    }
    _didSetupAuthLinks = true;

    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleIncomingAuthLink(initialLink);
      }

      _authLinkSubscription = _appLinks.uriLinkStream.listen(
        _handleIncomingAuthLink,
        onError: (Object error, StackTrace stackTrace) {
          developer.log(
            'Auth link stream failed',
            error: error,
            stackTrace: stackTrace,
            name: 'PulseApp',
          );
        },
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to initialize auth link handlers',
        error: error,
        stackTrace: stackTrace,
        name: 'PulseApp',
      );
    }
  }

  void _handleIncomingAuthLink(Uri uri) {
    final link = uri.toString();
    if (!firebase_auth.FirebaseAuth.instance.isSignInWithEmailLink(link)) {
      return;
    }

    final navigator = _navigatorKey.currentState;
    final context = _navigatorKey.currentContext;
    if (navigator == null || context == null) {
      return;
    }

    final authBloc = context.read<AuthBloc>();
    final authStatus = authBloc.state.status;
    final isInAuthenticatedFlow =
        authStatus == AuthStatus.authenticated ||
        authStatus == AuthStatus.profileCompletionRequired ||
        authStatus == AuthStatus.usernameSetupRequired ||
        authStatus == AuthStatus.googleLinkRequired;

    if (isInAuthenticatedFlow) {
      return;
    }

    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    authBloc.add(AuthEmailLinkDetected(emailLink: link));
  }

  @override
  void dispose() {
    _authLinkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider(
          create: (_) => di.sl<HomeBloc>()..add(const HomeDashboardRequested()),
        ),
        BlocProvider(create: (_) => di.sl<ExpenseBloc>()),
        BlocProvider(create: (_) => di.sl<ChatBloc>()),
        BlocProvider(create: (_) => di.sl<TaskBloc>()),
        BlocProvider(create: (_) => di.sl<GroceryBloc>()),
        BlocProvider(create: (_) => di.sl<LocationBloc>()),
        BlocProvider(create: (_) => di.sl<EventBloc>()),
        BlocProvider(create: (_) => di.sl<NotificationBloc>()),
        BlocProvider(create: (_) => di.sl<SettingsBloc>()),
        BlocProvider(create: (_) => di.sl<LivingToolsBloc>()),
        BlocProvider(create: (_) => di.sl<FriendBloc>()),
        BlocProvider(create: (_) => di.sl<TimetableBloc>()),
      ],
      child: MultiBlocListener(
        listeners: [
          // Orchestrate feature lifecycle on auth state changes
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, authState) {
              if (authState.status == AuthStatus.authenticated &&
                  authState.user != null) {
                context.read<HomeBloc>().add(const HomeDashboardRequested());
                context.read<ExpenseBloc>().add(
                  ExpenseCurrentUserUpdated(userId: authState.user!.id),
                );
                context.read<FriendBloc>().add(
                  FriendsLoadRequested(authState.user!.id),
                );
                context.read<FriendBloc>().add(
                  PendingRequestsLoadRequested(authState.user!.id),
                );
                context.read<SettingsBloc>().add(
                  SettingsLoadRequested(userId: authState.user!.id),
                );
                context.read<NotificationBloc>().add(
                  const NotificationLoadRequested(),
                );

                // Wire up FCM token lifecycle
                NotificationService.onUserAuthenticated(
                  authState.user!.id,
                  di.sl<FcmTokenDataSource>(),
                );
              } else if (authState.status == AuthStatus.unauthenticated) {
                context.read<HomeBloc>().add(const HomeClearedRequested());
                context.read<ExpenseBloc>().add(
                  const ExpenseCurrentUserUpdated(userId: ''),
                );
                context.read<ExpenseBloc>().add(
                  const ExpenseFriendDisplayNamesUpdated(
                    friendDisplayNamesById: {},
                  ),
                );
                context.read<ChatBloc>().add(ChatClearedRequested());
                context.read<SettingsBloc>().add(SettingsClearRequested());
                context.read<FriendBloc>().add(const FriendClearRequested());
                context.read<NotificationBloc>().add(
                  const NotificationClearRequested(),
                );

                // Clean up FCM tokenx
                NotificationService.onUserLogout();
              }
            },
          ),
          // Sync friend name lookup map into expense state (for 1:1 room titles)
          BlocListener<FriendBloc, FriendState>(
            listenWhen: (previous, current) =>
                previous.friends != current.friends,
            listener: (context, friendState) {
              final friendDisplayNames = <String, String>{
                for (final friend in friendState.friends)
                  friend.friendId: friend.friendDisplayName,
              };
              context.read<ExpenseBloc>().add(
                ExpenseFriendDisplayNamesUpdated(
                  friendDisplayNamesById: friendDisplayNames,
                ),
              );
            },
          ),
        ],
        child: BlocBuilder<SettingsBloc, SettingsState>(
          buildWhen: (previous, current) =>
              previous.settings?.darkMode != current.settings?.darkMode,
          builder: (context, settingsState) {
            // Cyber-Teal is a dark-only design system
            // User can still toggle dark mode in settings but both modes use Cyber-Teal
            const themeMode =
                ThemeMode.dark; // Always use dark mode for Cyber-Teal

            return MaterialApp(
              title: 'Pulse',
              navigatorKey: _navigatorKey,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.cyberTealTheme, // Cyber-Teal theme
              darkTheme: AppTheme.cyberTealTheme, // Same for both modes
              themeMode: themeMode,
              builder: (context, child) {
                return AppBackdrop(child: child ?? const SizedBox.shrink());
              },
              initialRoute: AppRoutes.authGate,
              routes: {
                // Auth
                AppRoutes.authIntro: (context) => const AuthIntroScreen(),
                AppRoutes.login: (context) => const LoginScreen(),
                AppRoutes.register: (context) => const RegisterScreen(),
                AppRoutes.emailVerification: (context) =>
                    const EmailVerificationScreen(),
                AppRoutes.profileCompletion: (context) =>
                    const ProfileCompletionScreen(),
                AppRoutes.googleUsernameSetup: (context) =>
                    const GoogleUsernameSetupScreen(),
                AppRoutes.forgotPassword: (context) =>
                    const ForgotPasswordScreen(),
                AppRoutes.authGate: (context) => const AuthGate(),

                // Home
                AppRoutes.home: (context) => const HomeScreen(),

                // Features
                AppRoutes.events: (context) => const EventsScreen(),
                AppRoutes.expense: (context) => const ExpenseScreen(),
                AppRoutes.addExpense: (context) => const AddExpenseScreen(),
                AppRoutes.receiptScan: (context) => const ReceiptScanScreen(),
                AppRoutes.balance: (context) => const BalanceScreen(),
                AppRoutes.grocery: (context) => const GroceryScreen(),
                AppRoutes.groupChat: (context) => const GroupChatScreen(),
                AppRoutes.groupInfo: (context) => const GroupInfoScreen(),
                AppRoutes.tasks: (context) => const TasksScreen(),
                AppRoutes.notifications: (context) =>
                    const NotificationsScreen(),
                AppRoutes.privacySettings: (context) =>
                    const PrivacySettingsScreen(),
                AppRoutes.settings: (context) => const ProfileSettingsScreen(),
                AppRoutes.accountSecurity: (context) =>
                    const AccountSecurityScreen(),
                AppRoutes.livingTools: (context) => const LivingToolsScreen(),
                AppRoutes.friends: (context) => const FriendsScreen(),
                AppRoutes.addFriend: (context) => const AddFriendScreen(),
                AppRoutes.editProfile: (context) => const EditProfileScreen(),
                AppRoutes.timetable: (context) => const TimetableScreen(),
              },
              onGenerateRoute: (settings) {
                if (settings.name == AppRoutes.editExpense) {
                  final args = settings.arguments as Map<String, dynamic>?;
                  final expense = args?['expense'] as Expense?;
                  if (expense != null) {
                    return MaterialPageRoute(
                      builder: (_) =>
                          AddExpenseScreen(existingExpense: expense),
                      settings: settings,
                    );
                  }
                }
                if (settings.name == AppRoutes.expenseDetails) {
                  final args = settings.arguments as Map<String, dynamic>?;
                  final expenseId = args?['expenseId'] as String?;
                  if (expenseId != null) {
                    return MaterialPageRoute(
                      builder: (_) =>
                          ExpenseDetailsScreen(expenseId: expenseId),
                      settings: settings,
                    );
                  }
                }
                if (settings.name == AppRoutes.itemSelection) {
                  final args = settings.arguments as Map<String, dynamic>?;
                  final expenseId = args?['expenseId'] as String?;
                  if (expenseId != null) {
                    return MaterialPageRoute(
                      builder: (_) => ItemSelectionScreen(expenseId: expenseId),
                      settings: settings,
                    );
                  }
                }
                if (settings.name == AppRoutes.friendProfile) {
                  final args = settings.arguments as Map<String, dynamic>?;
                  final friendship = args?['friendship'] as Friendship?;
                  if (friendship != null) {
                    return MaterialPageRoute(
                      builder: (_) =>
                          FriendProfileScreen(friendship: friendship),
                      settings: settings,
                    );
                  }
                }
                if (settings.name == AppRoutes.userProfile) {
                  final args = settings.arguments as Map<String, dynamic>?;
                  if (args != null) {
                    final profileContext = args['context'] == 'pendingRequest'
                        ? ProfileContext.pendingRequest
                        : ProfileContext.searchResult;
                    return MaterialPageRoute(
                      builder: (_) => UserProfileScreen(
                        name: args['name'] as String? ?? '',
                        username: args['username'] as String? ?? '',
                        email: args['email'] as String? ?? '',
                        phone: args['phone'] as String? ?? '',
                        photoUrl: args['photoUrl'] as String?,
                        profileContext: profileContext,
                        userId: args['userId'] as String?,
                        targetEmail: args['targetEmail'] as String?,
                        isFriend: args['isFriend'] as bool? ?? false,
                        isPending: args['isPending'] as bool? ?? false,
                        friendshipId: args['friendshipId'] as String?,
                        currentUserId: args['currentUserId'] as String?,
                      ),
                      settings: settings,
                    );
                  }
                }
                if (settings.name == AppRoutes.timetableAdd) {
                  final args = settings.arguments as Map<String, dynamic>?;
                  final initialDate = args?['initialDate'] as DateTime?;
                  return MaterialPageRoute(
                    builder: (_) =>
                        AddEditEntryScreen(initialDate: initialDate),
                    settings: settings,
                  );
                }
                if (settings.name == AppRoutes.timetableEdit) {
                  final args = settings.arguments as Map<String, dynamic>?;
                  final entry = args?['entry'] as dynamic;
                  final editScope =
                      args?['editScope'] as TimetableEditScope? ??
                      TimetableEditScope.wholeSeries;
                  if (entry != null) {
                    return MaterialPageRoute(
                      builder: (_) => AddEditEntryScreen(
                        entry: entry,
                        editScope: editScope,
                      ),
                      settings: settings,
                    );
                  }
                }
                if (settings.name == AppRoutes.timetableShared) {
                  final args = settings.arguments as Map<String, dynamic>?;
                  final targetUserId = args?['targetUserId'] as String?;
                  final userName = args?['userName'] as String?;
                  if (targetUserId != null) {
                    return MaterialPageRoute(
                      builder: (_) => SharedTimetableScreen(
                        targetUserId: targetUserId,
                        userName: userName,
                      ),
                      settings: settings,
                    );
                  }
                }
                return null;
              },
              onUnknownRoute: (settings) {
                developer.log(
                  'Unknown route: ${settings.name}',
                  name: 'PulseApp',
                );
                return MaterialPageRoute(
                  builder: (_) => Scaffold(
                    body: Center(
                      child: Text('Route not found: ${settings.name}'),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
