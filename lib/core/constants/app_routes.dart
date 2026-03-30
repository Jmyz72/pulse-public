/// Centralized route constants for the Pulse app.
/// Use these constants instead of hardcoding route strings.
class AppRoutes {
  AppRoutes._();

  // Auth
  static const String authIntro = '/auth-intro';
  static const String login = '/login';
  static const String register = '/register';
  static const String emailVerification = '/email-verification';
  static const String profileCompletion = '/profile-completion';
  static const String googleUsernameSetup = '/google-username-setup';
  static const String forgotPassword = '/forgot-password';
  static const String authGate = '/auth-gate';

  // Home
  static const String home = '/home';

  // Expense
  static const String expense = '/expense';
  static const String addExpense = '/add-expense';
  static const String editExpense = '/edit-expense';
  static const String receiptScan = '/receipt-scan';
  static const String expenseDetails = '/expense-details';
  static const String itemSelection = '/item-selection';
  static const String balance = '/balance';

  // Grocery
  static const String grocery = '/grocery';

  // Chat
  static const String groupChat = '/group-chat';
  static const String groupInfo = '/group-info';

  // Events
  static const String events = '/events';

  // Tasks
  static const String tasks = '/tasks';

  // Notifications
  static const String notifications = '/notifications';

  // Settings
  static const String privacySettings = '/privacy-settings';
  static const String settings = '/settings';

  // Living Tools
  static const String livingTools = '/living-tools';

  // Friends
  static const String friends = '/friends';
  static const String addFriend = '/friends/add';
  static const String friendProfile = '/friends/profile';
  static const String userProfile = '/friends/user-profile';

  // Settings (sub-routes)
  static const String editProfile = '/settings/edit-profile';
  static const String accountSecurity = '/settings/account-security';

  // Timetable
  static const String timetable = '/timetable';
  static const String timetableAdd = '/timetable/add';
  static const String timetableEdit = '/timetable/edit';
  static const String timetableShared = '/timetable/shared';
}
