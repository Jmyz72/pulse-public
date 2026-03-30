/// Firestore collection name constants.
/// Use these instead of hardcoded strings to prevent typos and enable easy refactoring.
abstract class FirestoreCollections {
  // User-related
  static const String users = 'users';
  static const String userSettings = 'user_settings';
  static const String userSearchSettings = 'user_search_settings';
  static const String usernames = 'usernames';
  static const String phoneNumbers = 'phone_numbers';
  static const String locations = 'locations';

  // Features
  static const String expenses = 'expenses';
  static const String bills = 'bills';
  static const String tasks = 'tasks';
  static const String events = 'events';
  static const String notifications = 'notifications';
  static const String activities = 'activities';
  static const String timetableEntries = 'timetable_entries';
  static const String groceryItems = 'grocery_items';
  static const String chatRooms = 'chatRooms';
  static const String messages = 'messages';

  // Chat sub-collections
  static const String typing = 'typing';

  // Presence
  static const String presence = 'presence';

  // Friends
  static const String friendships = 'friendships';

  // Location
  static const String userLocations = 'user_locations';
}
