class AppStrings {
  AppStrings._();

  // App Info
  static const String appName = 'Pulse';

  // Auth
  static const String login = 'Login';
  static const String register = 'Register';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String name = 'Name';
  static const String phone = 'Phone';

  // Navigation
  static const String home = 'Home';
  static const String expenses = 'Expenses';
  static const String chat = 'Chat';
  static const String tasks = 'Tasks';
  static const String profile = 'Profile';

  // Error Messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNoInternet = 'No internet connection.';
  static const String errorInvalidEmail = 'Please enter a valid email address.';
  static const String errorInvalidPassword =
      'Password does not meet the current account policy.';
  static const String errorPasswordMismatch = 'Passwords do not match.';
  static const String errorEmptyField = 'This field cannot be empty.';
  static const String errorInvalidName = 'Name must be at least 2 characters.';
  static const String errorInvalidPhone = 'Please enter a valid phone number.';
  static const String errorInvalidUsername =
      'Username must be 3-20 characters, lowercase letters, numbers, and underscores only.';
  static const String errorUsernameTaken = 'This username is already taken.';
  static const String errorPhoneTaken =
      'This phone number is already registered.';

  // Auth Error Messages
  static const String errorInvalidCredentials = 'Invalid email or password.';
  static const String errorAccountDisabled = 'This account has been disabled.';
  static const String errorEmailAlreadyInUse =
      'An account already exists with this email.';
  static const String errorWeakPassword =
      'Password is too weak. Please choose a stronger password.';
  static const String errorTooManyRequests =
      'Too many attempts. Please try again later.';
  static const String errorNetworkFailed =
      'Network error. Please check your connection.';
  static const String errorUnexpected =
      'An unexpected error occurred. Please try again.';
  static const String errorEmailNotVerified =
      'Please verify your email before signing in. Check your inbox for a verification link.';

  // Chat
  static const String messages = 'Messages';
  static const String searchMessages = 'Search messages...';
  static const String searchFriends = 'Search friends...';
  static const String noConversations = 'No conversations yet';
  static const String startNewChat = 'Start a new chat to connect with others';
  static const String noMessagesYet = 'No messages yet';
  static const String sendMessageToStart =
      'Send a message to start the conversation';
  static const String failedToLoadMessages = 'Failed to load messages';
  static const String retry = 'Retry';
  static const String newChat = 'New Chat';
  static const String message = 'Message';
  static const String createGroup = 'Create Group';
  static const String groupName = 'Group name';
  static const String selectFriends = 'Select friends to chat with';
  static const String noFriendsFound = 'No friends found';
  static const String addFriendsFirst = 'Add friends to start chatting';
  static const String unreadConversations = 'unread conversations';

  // Chat Actions
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String editMessage = 'Edit Message';
  static const String editMessageHint = 'Edit message...';
  static const String messageDeleted = 'This message was deleted';
  static const String edited = '(edited)';
  static const String deleteConversation = 'Delete Conversation';
  static const String deleteConversationConfirm =
      'Delete your conversation with';
  static const String newLabel = 'NEW';
  static const String today = 'Today';
  static const String yesterday = 'Yesterday';

  // Chat Quick Actions
  static const String splitExpense = 'Split Expense';
  static const String shoppingList = 'Shopping List';
  static const String newEvent = 'New Event';
  static const String split = 'Split';
  static const String grocery = 'Grocery';
  static const String bill = 'Bill';
  static const String location = 'Location';
  static const String event = 'Event';
  static const String groceryItems = 'Grocery Items';
  static const String taskItems = 'Task Items';

  // Group Management
  static const String comingSoon = 'Coming Soon';
  static const String makeAdmin = 'Make Admin';
  static const String removeAdmin = 'Remove Admin';
  static const String remove = 'Remove';
  static const String noFriendsAvailable = 'No friends available to add';
  static const String you = 'You';
  static const String admin = 'Admin';
  static const String exitGroup = 'Exit Group';
  static const String removeFromGroup = 'Remove from Group';
  static const String messageHint = 'Message...';

  // Chat Special Cards
  static const String viewDetails = 'View Details';
  static const String viewExpenses = 'View Expenses';
  static const String viewList = 'View List';
  static const String going = 'Going';
  static const String maybe = 'Maybe';

  // Success Messages
  static const String successLogin = 'Login successful!';
  static const String successRegister = 'Registration successful!';
  static const String successPasswordReset = 'Password reset email sent.';

  // Friends
  static const String friends = 'Friends';
  static const String friendProfile = 'Friend Profile';
  static const String addFriend = 'Add Friend';
  static const String requests = 'Requests';
  static const String noFriendsYet = 'No friends yet';
  static const String tapToAddFriends = 'Tap + to add friends';
  static const String noPendingRequests = 'No pending requests';
  static const String requestsWillAppearHere =
      'Friend requests you receive will appear here';
  static const String searchByUsernameEmailPhone =
      'Search by username, email, or phone';
  static const String searchForUsers = 'Search for users to add as friends';
  static const String noUsersFound = 'No users found';
  static const String removeFriend = 'Remove Friend';
  static const String blockUserComingSoon = 'Block User (Coming Soon)';
  static const String friendRequestSent = 'Friend request sent!';
  static const String friendRequestAccepted = 'Friend request accepted!';
  static const String friendRequestDeclined = 'Friend request declined';
  static const String friendRemoved = 'Friend removed';

  // Settings
  static const String settingUpdated = 'Setting updated';
  static const String failedToLoadSettings = 'Failed to load settings';
  static const String noSettingsAvailable = 'No settings available';
}
