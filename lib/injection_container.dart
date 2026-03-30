import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/api_keys.dart';
import 'core/network/network_info.dart';
import 'core/services/bill_payment_verification_service.dart';
import 'core/services/ocr_service.dart';
import 'core/services/payment_proof_parser_service.dart';
import 'core/services/profile_sync_service.dart';
import 'core/services/receipt_parser_service.dart';
import 'core/services/vertex_ai_service.dart';

// FCM Notifications
import 'core/services/fcm_token_datasource.dart';
import 'features/chat/data/datasources/notification_datasource.dart';

// Auth
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/domain/usecases/complete_google_onboarding.dart';
import 'features/auth/domain/usecases/login.dart';
import 'features/auth/domain/usecases/link_google_sign_in.dart';
import 'features/auth/domain/usecases/logout.dart';
import 'features/auth/domain/usecases/register.dart';
import 'features/auth/domain/usecases/reset_password.dart';
import 'features/auth/domain/usecases/sign_in_with_google.dart';
import 'features/auth/domain/usecases/check_phone_availability.dart';
import 'features/auth/domain/usecases/check_username_availability.dart';
import 'features/auth/domain/usecases/complete_email_link_sign_in.dart';
import 'features/auth/domain/usecases/update_profile.dart';
import 'features/auth/domain/usecases/upload_profile_image.dart';
import 'features/auth/domain/usecases/validate_password_policy.dart';
import 'features/auth/domain/usecases/get_auth_security.dart';
import 'features/auth/domain/usecases/get_pending_email_link_email.dart';
import 'features/auth/domain/usecases/send_email_link_sign_in.dart';
import 'features/auth/domain/usecases/set_password.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Expense
import 'features/expense/data/datasources/expense_remote_datasource.dart';
import 'features/expense/data/repositories/expense_repository_impl.dart';
import 'features/expense/domain/repositories/expense_repository.dart';
import 'features/expense/domain/services/expense_submission_service.dart';
import 'features/expense/domain/services/expense_payment_announcement_service.dart';
import 'features/expense/domain/services/payment_proof_matcher.dart';
import 'features/expense/domain/usecases/approve_payment_proof.dart';
import 'features/expense/domain/usecases/create_expense.dart';
import 'features/expense/domain/usecases/create_adhoc_expense.dart';
import 'features/expense/domain/usecases/delete_expense.dart';
import 'features/expense/domain/usecases/get_expenses.dart';
import 'features/expense/domain/usecases/get_expense_by_id.dart';
import 'features/expense/domain/usecases/update_expense.dart';
import 'features/expense/domain/usecases/select_items.dart';
import 'features/expense/domain/usecases/mark_split_paid.dart';
import 'features/expense/domain/usecases/refresh_expense_owner_payment_identity.dart';
import 'features/expense/domain/usecases/reject_payment_proof.dart';
import 'features/expense/domain/usecases/submit_payment_proof.dart';
import 'features/expense/domain/usecases/sync_owner_payment_identity_to_pending_expenses.dart';
import 'features/expense/presentation/bloc/expense_bloc.dart';

// Chat
import 'features/chat/data/datasources/chat_local_datasource.dart';
import 'features/chat/domain/repositories/failed_message_storage.dart';
import 'features/chat/data/datasources/chat_remote_datasource.dart';
import 'features/chat/data/datasources/presence_datasource.dart';
import 'features/chat/domain/repositories/presence_repository.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/domain/repositories/chat_repository.dart';
import 'features/chat/domain/usecases/get_chat_room_by_id.dart';
import 'features/chat/domain/usecases/get_chat_rooms.dart';
import 'features/chat/domain/usecases/watch_chat_room.dart';
import 'features/chat/domain/usecases/watch_chat_rooms.dart';
import 'features/chat/domain/usecases/get_messages.dart';
import 'features/chat/domain/usecases/send_message.dart';
import 'features/chat/domain/usecases/watch_messages.dart';
import 'features/chat/domain/usecases/add_chat_member.dart';
import 'features/chat/domain/usecases/create_chat_room.dart';
import 'features/chat/domain/usecases/delete_chat_room.dart';
import 'features/chat/domain/usecases/make_admin.dart';
import 'features/chat/domain/usecases/mark_as_read.dart' as chat;
import 'features/chat/domain/usecases/remove_admin.dart';
import 'features/chat/domain/usecases/remove_chat_member.dart';
import 'features/chat/domain/usecases/edit_message.dart';
import 'features/chat/domain/usecases/leave_chat_group.dart';
import 'features/chat/domain/usecases/delete_message.dart';
import 'features/chat/domain/usecases/set_typing_status.dart';
import 'features/chat/domain/usecases/watch_typing_users.dart';
import 'features/chat/domain/usecases/update_presence.dart';
import 'features/chat/domain/usecases/upload_chat_media.dart';
import 'features/chat/domain/usecases/watch_user_presence.dart';
import 'features/chat/domain/usecases/save_failed_message.dart';
import 'features/chat/domain/usecases/get_failed_messages.dart';
import 'features/chat/domain/usecases/get_merged_messages.dart';
import 'features/chat/domain/usecases/remove_failed_message.dart';
import 'features/chat/domain/usecases/search_messages.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';

// Tasks
import 'features/tasks/data/datasources/task_remote_datasource.dart';
import 'features/tasks/data/repositories/task_repository_impl.dart';
import 'features/tasks/domain/repositories/task_repository.dart';
import 'features/tasks/domain/usecases/create_task.dart';
import 'features/tasks/domain/usecases/get_tasks.dart';
import 'features/tasks/domain/usecases/update_task.dart';
import 'features/tasks/domain/usecases/complete_task_with_evidence.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';

// Grocery
import 'features/grocery/data/datasources/grocery_remote_datasource.dart';
import 'features/grocery/data/repositories/grocery_repository_impl.dart';
import 'features/grocery/domain/repositories/grocery_repository.dart';
import 'features/grocery/domain/usecases/add_grocery_item.dart';
import 'features/grocery/domain/usecases/delete_grocery_item.dart';
import 'features/grocery/domain/usecases/get_grocery_items.dart';
import 'features/grocery/domain/usecases/toggle_purchased.dart';
import 'features/grocery/domain/usecases/update_grocery_item.dart';
import 'features/grocery/domain/usecases/watch_grocery_items.dart';
import 'features/grocery/presentation/bloc/grocery_bloc.dart';

// Location
import 'features/location/data/datasources/location_remote_datasource.dart';
import 'features/location/data/repositories/location_repository_impl.dart';
import 'features/location/domain/repositories/location_repository.dart';
import 'features/location/domain/usecases/get_current_location.dart';
import 'features/location/domain/usecases/get_friends_locations.dart';
import 'features/location/domain/usecases/calculate_nearby_friends.dart';
import 'features/location/domain/usecases/toggle_location_sharing.dart';
import 'features/location/domain/usecases/update_location.dart';
import 'features/location/domain/usecases/update_location_privacy.dart';
import 'features/location/domain/usecases/watch_friends_locations.dart';
import 'features/location/presentation/bloc/location_bloc.dart';

// Events
import 'features/location/data/datasources/event_remote_datasource.dart';
import 'features/location/data/repositories/event_repository_impl.dart';
import 'features/location/domain/repositories/event_repository.dart';
import 'features/location/domain/usecases/create_event.dart';
import 'features/location/domain/usecases/leave_event.dart';
import 'features/location/domain/usecases/watch_events.dart';
import 'features/location/domain/usecases/join_event.dart';
import 'features/location/domain/usecases/delete_event.dart';
import 'features/location/presentation/bloc/event_bloc.dart';

// Notifications
import 'features/notifications/data/datasources/notification_remote_datasource.dart';
import 'features/notifications/data/repositories/notification_repository_impl.dart';
import 'features/notifications/domain/repositories/notification_repository.dart';
import 'features/notifications/domain/usecases/delete_notification.dart';
import 'features/notifications/domain/usecases/get_notifications.dart';
import 'features/notifications/domain/usecases/mark_all_as_read.dart';
import 'features/notifications/domain/usecases/mark_as_read.dart';
import 'features/notifications/domain/usecases/send_notification.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';

// Settings
import 'features/settings/data/datasources/settings_local_datasource.dart';
import 'features/settings/data/datasources/settings_remote_datasource.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';
import 'features/settings/domain/repositories/settings_repository.dart';
import 'features/settings/domain/usecases/clear_settings_cache.dart';
import 'features/settings/domain/usecases/get_settings.dart';
import 'features/settings/domain/usecases/update_privacy_setting.dart';
import 'features/settings/domain/usecases/update_settings.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';

// Living Tools
import 'features/living_tools/data/datasources/bill_remote_datasource.dart';
import 'features/living_tools/data/repositories/bill_repository_impl.dart';
import 'features/living_tools/domain/repositories/bill_repository.dart';
import 'features/living_tools/domain/usecases/watch_bills.dart';
import 'features/living_tools/domain/usecases/create_bill.dart';
import 'features/living_tools/domain/usecases/delete_bill.dart';
import 'features/living_tools/domain/usecases/get_bills.dart';
import 'features/living_tools/domain/usecases/get_bills_summary.dart';
import 'features/living_tools/domain/usecases/mark_bill_as_paid.dart';
import 'features/living_tools/domain/usecases/nudge_member.dart';
import 'features/living_tools/domain/usecases/update_bill.dart';
import 'features/living_tools/presentation/bloc/living_tools_bloc.dart';

// Home
import 'features/home/data/datasources/home_remote_datasource.dart';
import 'features/home/data/repositories/home_repository_impl.dart';
import 'features/home/domain/repositories/home_repository.dart';
import 'features/home/domain/usecases/get_dashboard_data.dart';
import 'features/home/presentation/bloc/home_bloc.dart';

// Friends
import 'features/friends/data/datasources/friend_remote_datasource.dart';
import 'features/friends/data/repositories/friend_repository_impl.dart';
import 'features/friends/domain/repositories/friend_repository.dart';
import 'features/friends/domain/usecases/accept_friend_request.dart';
import 'features/friends/domain/usecases/decline_friend_request.dart';
import 'features/friends/domain/usecases/get_friend_profile_stats.dart';
import 'features/friends/domain/usecases/get_friends.dart';
import 'features/friends/domain/usecases/get_pending_requests.dart';
import 'features/friends/domain/usecases/get_sent_requests.dart';
import 'features/friends/domain/usecases/remove_friend.dart';
import 'features/friends/domain/usecases/search_users.dart';
import 'features/friends/domain/usecases/send_friend_request.dart';
import 'features/friends/presentation/bloc/friend_bloc.dart';

// Timetable
import 'features/timetable/data/datasources/timetable_remote_datasource.dart';
import 'features/timetable/data/repositories/timetable_repository_impl.dart';
import 'features/timetable/domain/repositories/timetable_repository.dart';
import 'features/timetable/domain/usecases/add_timetable_entry.dart';
import 'features/timetable/domain/usecases/delete_timetable_entry.dart';
import 'features/timetable/domain/usecases/expand_timetable_occurrences.dart';
import 'features/timetable/domain/usecases/get_my_timetable.dart';
import 'features/timetable/domain/usecases/get_shared_timetable.dart';
import 'features/timetable/domain/usecases/update_entry_visibility.dart';
import 'features/timetable/domain/usecases/update_timetable_entry.dart';
import 'features/timetable/presentation/bloc/timetable_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      getCurrentUser: sl(),
      getAuthSecurity: sl(),
      login: sl(),
      signInWithGoogle: sl(),
      sendEmailLinkSignIn: sl(),
      getPendingEmailLinkEmail: sl(),
      completeEmailLinkSignIn: sl(),
      completeGoogleOnboarding: sl(),
      linkGoogleSignIn: sl(),
      register: sl(),
      logout: sl(),
      resetPassword: sl(),
      setPassword: sl(),
      updateProfile: sl(),
      checkUsernameAvailability: sl(),
      checkPhoneAvailability: sl(),
      validatePasswordPolicy: sl(),
      uploadProfileImage: sl(),
      syncOwnerPaymentIdentityToPendingExpenses: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => GetAuthSecurity(sl()));
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SendEmailLinkSignIn(sl()));
  sl.registerLazySingleton(() => GetPendingEmailLinkEmail(sl()));
  sl.registerLazySingleton(() => CompleteEmailLinkSignIn(sl()));
  sl.registerLazySingleton(() => CompleteGoogleOnboarding(sl()));
  sl.registerLazySingleton(() => LinkGoogleSignIn(sl()));
  sl.registerLazySingleton(() => Login(sl()));
  sl.registerLazySingleton(() => Register(sl()));
  sl.registerLazySingleton(() => Logout(sl()));
  sl.registerLazySingleton(() => ResetPassword(sl()));
  sl.registerLazySingleton(() => SetPassword(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));
  sl.registerLazySingleton(() => CheckUsernameAvailability(sl()));
  sl.registerLazySingleton(() => CheckPhoneAvailability(sl()));
  sl.registerLazySingleton(() => ValidatePasswordPolicy(sl()));
  sl.registerLazySingleton(() => UploadProfileImage(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
      profileSyncService: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl(),
      firestore: sl(),
      firebaseStorage: sl(),
    ),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(secureStorage: sl()),
  );

  //! Features - Expense
  sl.registerFactory(
    () => ExpenseBloc(
      getExpenses: sl(),
      getExpenseById: sl(),
      createExpense: sl(),
      createAdHocExpense: sl(),
      updateExpense: sl(),
      deleteExpense: sl(),
      selectItems: sl(),
      markSplitPaid: sl(),
      submitPaymentProof: sl(),
      approvePaymentProof: sl(),
      rejectPaymentProof: sl(),
      refreshExpenseOwnerPaymentIdentity: sl(),
      currentUserId: sl<AuthBloc>().state.user?.id ?? '',
    ),
  );
  sl.registerLazySingleton(() => GetExpenses(sl()));
  sl.registerLazySingleton(() => GetExpenseById(sl()));
  sl.registerLazySingleton(ExpenseSubmissionService.new);
  sl.registerLazySingleton(
    () => ExpensePaymentAnnouncementService(sendMessage: sl()),
  );
  sl.registerLazySingleton(PaymentProofMatcher.new);
  sl.registerLazySingleton(
    () => CreateExpense(
      repository: sl(),
      submissionService: sl(),
      sendMessage: sl(),
    ),
  );
  sl.registerLazySingleton(() => CreateAdHocExpense(sl()));
  sl.registerLazySingleton(
    () => UpdateExpense(repository: sl(), submissionService: sl()),
  );
  sl.registerLazySingleton(() => DeleteExpense(sl()));
  sl.registerLazySingleton(() => SelectItems(sl()));
  sl.registerLazySingleton(
    () => MarkSplitPaid(repository: sl(), announcementService: sl()),
  );
  sl.registerLazySingleton(() => RefreshExpenseOwnerPaymentIdentity(sl()));
  sl.registerLazySingleton(
    () => SubmitPaymentProof(
      repository: sl(),
      matcher: sl(),
      announcementService: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => ApprovePaymentProof(repository: sl(), announcementService: sl()),
  );
  sl.registerLazySingleton(() => RejectPaymentProof(sl()));
  sl.registerLazySingleton(
    () => SyncOwnerPaymentIdentityToPendingExpenses(sl()),
  );
  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<ExpenseRemoteDataSource>(
    () => ExpenseRemoteDataSourceImpl(
      firestore: sl(),
      firebaseStorage: sl(),
      ocrService: sl(),
      paymentProofParserService: sl(),
    ),
  );

  //! Features - Chat
  sl.registerFactory(
    () => ChatBloc(
      getChatRooms: sl(),
      watchChatRooms: sl(),
      watchChatRoom: sl(),
      getMessages: sl(),
      sendMessage: sl(),
      watchMessages: sl(),
      createChatRoom: sl(),
      deleteChatRoom: sl(),
      markAsRead: sl(),
      editMessage: sl(),
      deleteMessage: sl(),
      setTypingStatus: sl(),
      watchTypingUsers: sl(),
      uploadChatMedia: sl(),
      saveFailedMessage: sl(),
      getFailedMessages: sl(),
      getMergedMessages: sl(),
      searchMessages: sl(),
      removeFailedMessage: sl(),
      updatePresence: sl(),
      watchUserPresence: sl(),
      addChatMember: sl(),
      removeChatMember: sl(),
      leaveChatGroup: sl(),
      makeAdmin: sl(),
      removeAdmin: sl(),
      getChatRoomById: sl(),
    ),
  );
  sl.registerLazySingleton<ChatLocalDataSource>(
    () => ChatLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<FailedMessageStorage>(sl.call<ChatLocalDataSource>);
  sl.registerLazySingleton(() => GetChatRooms(sl()));
  sl.registerLazySingleton(() => WatchChatRooms(sl()));
  sl.registerLazySingleton(() => WatchChatRoom(sl()));
  sl.registerLazySingleton(() => GetMessages(sl()));
  sl.registerLazySingleton(() => SendMessage(sl()));
  sl.registerLazySingleton(() => WatchMessages(sl()));
  sl.registerLazySingleton(() => CreateChatRoom(sl()));
  sl.registerLazySingleton(() => DeleteChatRoom(sl()));
  sl.registerLazySingleton(() => chat.MarkAsRead(sl()));
  sl.registerLazySingleton(() => EditMessage(sl()));
  sl.registerLazySingleton(() => DeleteMessage(sl()));
  sl.registerLazySingleton(() => SetTypingStatus(sl()));
  sl.registerLazySingleton(() => WatchTypingUsers(sl()));
  sl.registerLazySingleton(() => UploadChatMedia(sl()));
  sl.registerLazySingleton(() => UpdatePresence(sl<PresenceRepository>()));
  sl.registerLazySingleton(() => WatchUserPresence(sl<PresenceRepository>()));
  sl.registerLazySingleton(() => AddChatMember(sl()));
  sl.registerLazySingleton(() => RemoveChatMember(sl()));
  sl.registerLazySingleton(() => LeaveChatGroup(sl()));
  sl.registerLazySingleton(() => MakeAdmin(sl()));
  sl.registerLazySingleton(() => RemoveAdmin(sl()));
  sl.registerLazySingleton(() => GetChatRoomById(sl()));
  sl.registerLazySingleton(() => SaveFailedMessage(sl()));
  sl.registerLazySingleton(() => GetFailedMessages(sl()));
  sl.registerLazySingleton(() => RemoveFailedMessage(sl()));
  sl.registerLazySingleton(SearchMessages.new);
  sl.registerLazySingleton(() => GetMergedMessages(getFailedMessages: sl()));
  sl.registerLazySingleton<PresenceDataSource>(
    () => PresenceDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<PresenceRepository>(sl.call<PresenceDataSource>);
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(
      firestore: sl(),
      firebaseAuth: sl(),
      firebaseStorage: sl(),
    ),
  );
  sl.registerLazySingleton<ChatNotificationDataSource>(
    () => ChatNotificationDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<FcmTokenDataSource>(
    sl.call<ChatNotificationDataSource>,
  );

  //! Features - Tasks
  sl.registerFactory(
    () => TaskBloc(
      getTasks: sl(),
      createTask: sl(),
      updateTask: sl(),
      completeTaskWithEvidence: sl(),
      sendNotification: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetTasks(sl()));
  sl.registerLazySingleton(() => CreateTask(sl()));
  sl.registerLazySingleton(() => UpdateTask(sl()));
  sl.registerLazySingleton(() => CompleteTaskWithEvidence(sl()));
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      firebaseStorage: sl(),
    ),
  );
  sl.registerLazySingleton<TaskRemoteDataSource>(
    () => TaskRemoteDataSourceImpl(firestore: sl()),
  );

  //! Features - Grocery
  sl.registerFactory(
    () => GroceryBloc(
      getGroceryItems: sl(),
      addGroceryItem: sl(),
      deleteGroceryItem: sl(),
      togglePurchased: sl(),
      updateGroceryItem: sl(),
      watchGroceryItems: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetGroceryItems(sl()));
  sl.registerLazySingleton(() => AddGroceryItem(sl()));
  sl.registerLazySingleton(() => DeleteGroceryItem(sl()));
  sl.registerLazySingleton(() => TogglePurchased(sl()));
  sl.registerLazySingleton(() => UpdateGroceryItem(sl()));
  sl.registerLazySingleton(() => WatchGroceryItems(sl()));
  sl.registerLazySingleton<GroceryRepository>(
    () => GroceryRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<GroceryRemoteDataSource>(
    () => GroceryRemoteDataSourceImpl(firestore: sl(), firebaseStorage: sl()),
  );

  //! Features - Location
  sl.registerFactory(
    () => LocationBloc(
      getCurrentLocation: sl(),
      getFriendsLocations: sl(),
      calculateNearbyFriends: sl(),
      toggleLocationSharing: sl(),
      updateLocation: sl(),
      updateLocationPrivacy: sl(),
      watchFriendsLocations: sl(),
      watchUserPresence: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetCurrentLocation(sl()));
  sl.registerLazySingleton(() => GetFriendsLocations(sl()));
  sl.registerLazySingleton(CalculateNearbyFriends.new);
  sl.registerLazySingleton(() => ToggleLocationSharing(sl()));
  sl.registerLazySingleton(() => UpdateLocation(sl()));
  sl.registerLazySingleton(() => UpdateLocationPrivacy(sl()));
  sl.registerLazySingleton(() => WatchFriendsLocations(sl()));
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      firebaseAuth: sl(),
    ),
  );
  sl.registerLazySingleton<LocationRemoteDataSource>(
    () => LocationRemoteDataSourceImpl(firestore: sl()),
  );

  //! Features - Events
  sl.registerFactory(
    () => EventBloc(
      createEvent: sl(),
      watchEvents: sl(),
      joinEvent: sl(),
      leaveEvent: sl(),
      deleteEvent: sl(),
    ),
  );
  sl.registerLazySingleton(() => CreateEvent(sl()));
  sl.registerLazySingleton(() => WatchEvents(sl()));
  sl.registerLazySingleton(() => JoinEvent(sl()));
  sl.registerLazySingleton(() => LeaveEvent(sl()));
  sl.registerLazySingleton(() => DeleteEvent(sl()));
  sl.registerLazySingleton<EventRepository>(
    () => EventRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<EventRemoteDataSource>(
    () => EventRemoteDataSourceImpl(firestore: sl()),
  );

  //! Features - Notifications
  sl.registerFactory(
    () => NotificationBloc(
      getNotifications: sl(),
      markAsRead: sl(),
      markAllAsRead: sl(),
      deleteNotification: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetNotifications(sl()));
  sl.registerLazySingleton(() => MarkAsRead(sl()));
  sl.registerLazySingleton(() => MarkAllAsRead(sl()));
  sl.registerLazySingleton(() => DeleteNotification(sl()));
  sl.registerLazySingleton(() => SendNotification(sl()));
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      firebaseAuth: sl(),
    ),
  );
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(firestore: sl()),
  );

  //! Features - Settings
  sl.registerFactory(
    () => SettingsBloc(
      getSettings: sl(),
      updateSettings: sl(),
      updatePrivacySetting: sl(),
      clearSettingsCache: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetSettings(sl()));
  sl.registerLazySingleton(() => UpdateSettings(sl()));
  sl.registerLazySingleton(() => UpdatePrivacySetting(sl()));
  sl.registerLazySingleton(() => ClearSettingsCache(sl()));
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! Features - Living Tools
  sl.registerFactory(
    () => LivingToolsBloc(
      getBills: sl(),
      watchBills: sl(),
      createBill: sl(),
      deleteBill: sl(),
      markBillAsPaid: sl(),
      updateBill: sl(),
      nudgeMember: sl(),
      getBillsSummary: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetBills(sl()));
  sl.registerLazySingleton(() => WatchBills(sl()));
  sl.registerLazySingleton(() => CreateBill(sl()));
  sl.registerLazySingleton(() => UpdateBill(sl()));
  sl.registerLazySingleton(() => DeleteBill(sl()));
  sl.registerLazySingleton(() => MarkBillAsPaid(sl()));
  sl.registerLazySingleton(() => NudgeMember(sl()));
  sl.registerLazySingleton(() => GetBillsSummary(sl()));
  sl.registerLazySingleton<BillRepository>(
    () => BillRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<BillRemoteDataSource>(
    () => BillRemoteDataSourceImpl(firestore: sl()),
  );

  //! Features - Home
  sl.registerFactory(() => HomeBloc(getDashboardData: sl()));
  sl.registerLazySingleton(() => GetDashboardData(sl()));
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(firestore: sl(), firebaseAuth: sl()),
  );

  //! Features - Friends
  sl.registerFactory(
    () => FriendBloc(
      getFriends: sl(),
      getPendingRequests: sl(),
      getSentRequests: sl(),
      sendFriendRequest: sl(),
      acceptFriendRequest: sl(),
      declineFriendRequest: sl(),
      removeFriend: sl(),
      searchUsers: sl(),
      getFriendProfileStats: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetFriends(sl()));
  sl.registerLazySingleton(() => GetPendingRequests(sl()));
  sl.registerLazySingleton(() => GetSentRequests(sl()));
  sl.registerLazySingleton(() => SendFriendRequest(sl()));
  sl.registerLazySingleton(() => AcceptFriendRequest(sl()));
  sl.registerLazySingleton(() => DeclineFriendRequest(sl()));
  sl.registerLazySingleton(() => RemoveFriend(sl()));
  sl.registerLazySingleton(() => SearchUsers(sl()));
  sl.registerLazySingleton(() => GetFriendProfileStats(sl()));
  sl.registerLazySingleton<FriendRepository>(
    () => FriendRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<FriendRemoteDataSource>(
    () => FriendRemoteDataSourceImpl(firestore: sl(), functions: sl()),
  );
  sl.registerLazySingleton<ProfileSyncService>(
    () => sl<FriendRemoteDataSource>() as ProfileSyncService,
  );

  //! Features - Timetable
  sl.registerFactory(
    () => TimetableBloc(
      getMyTimetable: sl(),
      addTimetableEntry: sl(),
      updateTimetableEntry: sl(),
      deleteTimetableEntry: sl(),
      getSharedTimetable: sl(),
      updateEntryVisibility: sl(),
      expandTimetableOccurrences: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetMyTimetable(sl()));
  sl.registerLazySingleton(() => AddTimetableEntry(sl()));
  sl.registerLazySingleton(() => UpdateTimetableEntry(sl()));
  sl.registerLazySingleton(() => DeleteTimetableEntry(sl()));
  sl.registerLazySingleton(() => GetSharedTimetable(sl()));
  sl.registerLazySingleton(() => UpdateEntryVisibility(sl()));
  sl.registerLazySingleton(ExpandTimetableOccurrences.new);
  sl.registerLazySingleton<TimetableRepository>(
    () => TimetableRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<TimetableRemoteDataSource>(
    () => TimetableRemoteDataSourceImpl(firestore: sl(), functions: sl()),
  );

  //! Core Services
  sl.registerLazySingleton(OcrService.new);
  sl.registerLazySingleton(() => VertexAiService(firebaseAuth: sl()));
  sl.registerLazySingleton(() => ReceiptParserService(vertexAiService: sl()));
  sl.registerLazySingleton(
    () => PaymentProofParserService(vertexAiService: sl()),
  );
  sl.registerLazySingleton(
    () => BillPaymentVerificationService(apiKey: ApiKeys.geminiApiKey),
  );

  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => InternetConnectionChecker.instance);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(
    () => FirebaseFunctions.instanceFor(region: 'asia-southeast1'),
  );
  sl.registerLazySingleton(() => FirebaseStorage.instance);
}
