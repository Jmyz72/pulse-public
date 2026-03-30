# Features Documentation

This document provides a comprehensive overview of all features implemented in the Pulse co-living coordination app.

## Feature Status

**Implementation Status**: 12/13 major features complete (92%)

---

## Implemented Features

### 1. 🔐 Authentication & User Management

**Status**: ✅ Complete

**Description**: Comprehensive user authentication and profile management system.

**Capabilities**:
- Email/password authentication with Firebase Auth
- User registration with validation
- Password reset via email
- Username uniqueness checking
- Profile updates (name, photo, bio)
- Persistent authentication state
- Automatic session management

**Screens**:
- Login Screen
- Register Screen
- Forgot Password Screen
- Auth Gate (routing based on auth state)

**Use Cases**:
- `Login` - Authenticate user with email/password
- `Register` - Create new user account
- `Logout` - Sign out current user
- `GetCurrentUser` - Retrieve authenticated user
- `ResetPassword` - Send password reset email
- `CheckUsernameAvailability` - Verify username is unique
- `UpdateUserProfile` - Update user information

**BLoC**: `AuthBloc`

**Database Collections**: `users`

**Key Files**:
- `lib/features/auth/domain/entities/user.dart`
- `lib/features/auth/presentation/bloc/auth_bloc.dart`
- `lib/features/auth/presentation/screens/`

---

### 2. 👥 Friends & Social

**Status**: ✅ Complete

**Description**: Friend request system with user discovery.

**Capabilities**:
- Search users by username, email, or phone
- Send friend requests
- Accept/decline friend requests
- View pending friend requests
- View friends list
- Remove friends
- Friend profile viewing
- Privacy controls for friend visibility

**Screens**:
- Friends List Screen
- Add Friend Screen
- Friend Profile Screen

**Use Cases**:
- `SearchUsers` - Find users by username/email/phone
- `SendFriendRequest` - Send friend request
- `AcceptFriendRequest` - Accept pending request
- `DeclineFriendRequest` - Decline pending request
- `GetFriends` - Get user's friends list
- `GetPendingRequests` - Get incoming friend requests
- `RemoveFriend` - Remove friend

**BLoC**: `FriendBloc`

**Database Collections**: `friendships`

**Key Implementation Details**:
- Denormalized friendship data for efficient queries
- Two-way friendship documents for bidirectional queries
- Profile sync when user updates their information
- Search queries run in parallel for performance

---

### 3. 💬 Group Chat & Messaging

**Status**: ✅ Complete

**Description**: Real-time group messaging with rich features.

**Capabilities**:
- Create group chats
- Send text messages
- Edit messages
- Delete messages
- Real-time message streaming
- Typing indicators
- User presence tracking (online/offline)
- Read receipts
- Message timestamps
- Admin controls (add/remove members, promote/demote)
- Upload chat media (images)
- Support for expense and grocery cards in chat
- Read receipt indicators on special message cards
- Search highlighting in messages (RichText)
- Mark all messages as read
- Deep link navigation via getChatRoomById
- Failed message retry with local storage
- Leave group chats
- Delete chat rooms (admin only)

**Screens**:
- Chat List Screen
- Group Chat Screen
- Group Info Screen
- Group Selection Screen

**Widgets**:
- `MessageBubble` - Individual message display
- `MessageInput` - Text input with send button
- `TypingIndicator` - Shows who's typing
- `ExpenseCard` - Expense preview in chat
- `GroceryCard` - Grocery list preview in chat

**Use Cases**:
- `GetChatRooms` - Get user's chat rooms
- `GetMessages` - Get messages for a room
- `SendMessage` - Send a message
- `WatchMessages` - Stream real-time messages
- `EditMessage` - Edit sent message
- `DeleteMessage` - Delete sent message
- `MarkAsRead` - Mark messages as read
- `SetTypingStatus` - Update typing status
- `WatchTypingUsers` - Stream typing users
- `UpdatePresence` - Update online/offline status
- `WatchUserPresence` - Stream user presence
- `UploadChatMedia` - Upload images
- `AddChatMember` - Add member to group (admin)
- `RemoveChatMember` - Remove member (admin)
- `MakeAdmin` - Promote to admin
- `RemoveAdmin` - Demote from admin
- `LeaveChatGroup` - Leave the chat
- `CreateChatRoom` - Create new group chat
- `DeleteChatRoom` - Delete chat (admin)
- `MarkAllAsRead` - Mark all messages as read
- `GetChatRoomById` - Get chat room by ID for deep linking

**BLoC**: `ChatBloc`

**Database Collections**: `chat_rooms`, `messages`, `presence`

**Key Implementation Details**:
- Real-time Firestore streams for messages
- Optimistic UI updates
- Failed message storage in SharedPreferences
- Presence system with automatic timeout
- Typing indicators with debouncing

---

### 4. 💰 Expense Management

**Status**: ✅ Complete

**Description**: Comprehensive expense tracking and bill splitting with AI-powered receipt scanning.

**Capabilities**:
- Create expenses manually
- AI-powered receipt scanning (Google ML Kit + Gemini AI)
- OCR text recognition from receipt photos
- Intelligent item parsing with Gemini AI
- Tax and service charge calculations
- Customizable bill splitting ratios
- Item-level splitting (select who pays for what)
- Ad-hoc expenses (one-time payments outside groups)
- Mark individual splits as paid/unpaid
- Balance overview across all chat rooms
- Payment status tracking per person
- Filterable expense list
- Quick expense navigation from chat with preselection
- Expense details view
- Edit and delete expenses

**Screens**:
- Expense List Screen
- Add Expense Screen
- Receipt Scan Screen (Camera/Gallery)
- Balance Screen
- Expense Details Screen
- Item Selection Screen

**Use Cases**:
- `GetExpenses` - Get expenses for chat rooms
- `GetExpenseById` - Get single expense details
- `CreateExpense` - Create group expense
- `CreateAdHocExpense` - Create one-time expense
- `UpdateExpense` - Edit existing expense
- `DeleteExpense` - Remove expense
- `SelectItems` - Choose items for expense split
- `MarkSplitPaid` - Mark payment status

**BLoC**: `ExpenseBloc`

**Database Collections**: `expenses`

**Key Implementation Details**:
- Expense types: `group` (tied to chatRoomId) and `adhoc` (standalone)
- AI-powered OCR uses Google ML Kit for text recognition
- Gemini AI parses receipt items, prices, tax, and service charges
- Expense splits track: userId, amount, paid status
- Balance calculations aggregate across all expenses
- Optimistic UI updates for marking payments

**AI Integration**:
- Google ML Kit for image text recognition
- Gemini AI (google_generative_ai) for intelligent parsing
- Structured prompt engineering for consistent results

---

### 5. 🛒 Grocery Lists

**Status**: ✅ Complete

**Description**: Shared shopping lists for co-living chat rooms.

**Capabilities**:
- Create grocery items for a chat room
- Mark items as purchased/unpurchased with purchaser tracking
- Restrict unpurchase to original purchaser
- Edit item details (name, quantity, notes)
- Delete items
- Real-time updates via Firestore streams (WatchGroceryItems)
- System messages in chat for grocery actions (add, purchase, unpurchase)
- Item categorization
- Quantity tracking

**Screens**:
- Grocery List Screen
- Add Grocery Item Screen

**Use Cases**:
- `AddGroceryItem` - Create new item
- `GetGroceryItems` - Get items for a chat room
- `WatchGroceryItems` - Stream real-time grocery items
- `UpdateGroceryItem` - Edit item details
- `DeleteGroceryItem` - Remove item
- `ToggleItemPurchased` - Mark as purchased/unpurchased

**BLoC**: `GroceryBloc`

**Database Collections**: `grocery_items`

**Key Implementation Details**:
- Items scoped to `chatRoomId`
- Purchase status tracked per item with purchaser info (`purchasedBy`, `purchasedByName`)
- Real-time sync via Firestore streams
- System messages sent to chat when grocery actions occur

---

### 6. 📅 Timetable & Scheduling

**Status**: ✅ Complete

**Description**: Personal schedule management with visibility controls and friend sharing.

**Capabilities**:
- Create schedule entries with title, start/end time, location
- Recurring schedule support (daily, weekly patterns)
- Visibility controls:
  - **Private**: Only visible to owner
  - **Friends**: Visible to accepted friends
  - **Public**: Visible to all users
  - **Specific Users**: Visible to selected users
- Weekly grid view
- Daily list view
- View friends' shared schedules
- Color-coded entries
- Day of week filtering

**Screens**:
- Timetable View Screen (Weekly/Daily)
- Add/Edit Entry Screen
- Shared Timetable Screen

**Widgets**:
- `TimeSlotPicker` - Select time range
- `DaySelector` - Choose days of week
- `ScheduleItemCard` - Display entry
- `DailyListView` - List view by day
- `WeeklyGridView` - Grid view by week
- `VisibilitySelector` - Choose who can see

**Use Cases**:
- `AddTimetableEntry` - Create new entry
- `UpdateTimetableEntry` - Edit existing entry
- `DeleteTimetableEntry` - Remove entry
- `GetMyTimetable` - Get personal schedule
- `GetSharedTimetable` - Get friends' visible schedules
- `UpdateEntryVisibility` - Change visibility setting

**BLoC**: `TimetableBloc`

**Database Collections**: `timetable_entries`

**Key Implementation Details**:
- Entries owned by individual users (not tied to groups)
- Visibility enforced in Firestore rules
- Friend checks for "friends-only" visibility
- Cached computed values (`entriesByDay`) for performance
- Optimistic UI updates

---

### 7. 🏠 Living Tools & Bills

**Status**: ✅ Complete

**Description**: Recurring bill management for co-living groups.

**Capabilities**:
- Create recurring bills (rent, utilities, internet, cleaning)
- Bill categorization
- Split bills among group members
- Mark bills as paid/unpaid
- Due date tracking
- Payment status monitoring
- Bill summary dashboard

**Screens**:
- Living Tools Screen

**Widgets**:
- `AddBillForm` - Create bill form
- `BillCard` - Display bill details
- `BillSummaryHeader` - Overview dashboard

**Use Cases**:
- `CreateBill` - Create new bill
- `UpdateBill` - Edit bill details
- `MarkBillAsPaid` - Update payment status
- `DeleteBill` - Remove bill
- `GetBills` - Get bills for a chat room
- `GetBillsSummary` - Get overview stats

**BLoC**: `LivingToolsBloc`

**Database Collections**: `bills`

**Key Implementation Details**:
- Bills scoped to `chatRoomId`
- Categories: rent, utilities, internet, cleaning, other
- Recurring: monthly, weekly, one-time
- Split evenly among group members

---

### 8. ✅ Task & Chore Management

**Status**: ✅ Complete

**Description**: Shared task lists for co-living groups.

**Capabilities**:
- Create tasks with title, description, due date
- Priority levels: High, Medium, Low
- Status tracking: Pending, In Progress, Completed
- Task categories for organization
- Assign tasks to specific members
- Recurring tasks support
- Due date notifications
- Task filtering and sorting

**Screens**:
- Tasks List Screen

**Use Cases**:
- `CreateTask` - Create new task
- `UpdateTask` - Edit task details
- `GetTasks` - Get tasks for a chat room

**BLoC**: `TaskBloc`

**Database Collections**: `tasks`

**Key Implementation Details**:
- Tasks scoped to `chatRoomId`
- Priority: high, medium, low
- Status: pending, inProgress, completed
- Recurring patterns supported

---

### 9. 📍 Location Sharing

**Status**: ✅ Complete

**Description**: Real-time location sharing with friends, integrated into the Home screen.

**Capabilities**:
- Share current location with friends
- View friends' locations on map (integrated into HomeScreen LocationTab)
- Privacy toggle (enable/disable sharing)
- Nearby dining place recommendations
- Location accuracy controls
- Real-time location updates

**Screens**:
- Location Tab (integrated into HomeScreen)

**Use Cases**:
- `GetCurrentLocation` - Get device GPS location
- `UpdateLocation` - Share location with friends
- `ToggleLocationSharing` - Enable/disable sharing
- `GetFriendsLocations` - View friends' locations
- `GetNearbyDiningPlaces` - Find nearby restaurants

**BLoC**: `LocationBloc`

**Database Collections**: `user_locations`

**Dependencies**:
- `google_maps_flutter` - Map display
- `geolocator` - GPS location access
- `permission_handler` - Location permissions

**Key Implementation Details**:
- Location updates with timestamp
- Privacy: only friends can see location
- Dining places from Google Places API
- Geohash for efficient nearby queries

---

### 10. 🔔 Notifications

**Status**: ✅ Complete

**Description**: In-app and push notification system with deep linking.

**Capabilities**:
- Multi-type notifications:
  - Task assignments and updates
  - Expense updates and payment requests
  - Chat messages
  - Location sharing updates
  - Friend requests
- FCM push notifications via Cloud Functions
- Local notification banners for foreground messages
- Read/unread status tracking
- Mark individual notifications as read
- Mark all as read
- Delete notifications
- Unread count badges
- Deep linking to related content (chat deep link navigation)
- Notification timestamp

**Screens**:
- Notifications List Screen

**Use Cases**:
- `GetNotifications` - Fetch user notifications
- `MarkNotificationAsRead` - Mark single notification as read
- `MarkAllNotificationsAsRead` - Mark all as read
- `DeleteNotification` - Remove notification
- `GetUnreadNotificationCount` - Get unread count

**BLoC**: `NotificationBloc`

**Database Collections**: `notifications`

**Key Implementation Details**:
- Notifications scoped to `userId`
- Types: task, expense, chat, location, friend_request, system
- Deep linking via `relatedId` and `relatedType`
- Real-time unread count for badges
- Cloud Function (`onNewChatMessage`) creates notifications on new messages
- FCM tokens managed via NotificationService lifecycle (onUserAuthenticated/onUserLogout)
- Foreground messages show SnackBar with "View" action

---

### 11. ⚙️ Settings & Privacy

**Status**: ✅ Complete

**Description**: User preferences and privacy controls.

**Capabilities**:
- **Appearance**: Dark mode toggle
- **Notifications**: Push notification preferences
- **Privacy Controls**:
  - Timeline visibility (who can see schedule)
  - Profile visibility (public/friends/private)
  - Invisible mode (appear offline)
- **Searchability Settings**:
  - Search by username
  - Search by email
  - Search by phone number
- **Profile Management**:
  - Edit name, bio, photo
  - Update contact information
- **Cache Management**: Clear local cache

**Screens**:
- Profile Settings Screen
- Privacy Settings Screen
- Edit Profile Screen

**Use Cases**:
- `GetUserSettings` - Fetch user preferences
- `UpdateUserSettings` - Update preferences
- `UpdatePrivacySettings` - Update privacy controls
- `ClearCache` - Clear local data

**BLoC**: `SettingsBloc`

**Database Collections**: `users` (settings embedded)

**Local Storage**: `SharedPreferences` for cache

**Key Implementation Details**:
- Settings cached locally for offline access
- Privacy settings enforced in Firestore rules
- Profile updates sync across denormalized data (ProfileSyncService)
- Dark mode persisted locally

---

### 12. 🏠 Home Dashboard

**Status**: ✅ Complete

**Description**: Main navigation hub with 5-tab layout and polished UI.

**Capabilities**:
- 5-tab bottom navigation: Home, Chat, Location, Activity, Profile
- IndexedStack for tab state preservation
- Dashboard with quick overview:
  - Upcoming tasks and recent expenses
  - Unread messages count
  - Today's schedule and grocery items count
- Shimmer skeleton loading screens (HomeSkeleton, ProfileSkeleton, ActivityCardSkeleton, ChatSkeleton)
- Stagger entrance animations via StaggerAnimationMixin
- Glassmorphism widgets (GlassContainer, GlassBottomNav)
- RepaintBoundary performance optimization on heavy widgets
- AnimatedSwitcher for smooth tab transitions
- Pull-to-refresh with Completer pattern
- Haptic feedback on tab navigation
- Lazy location loading

**Screens**:
- HomeScreen (5-tab navigation)

**Tab Widgets**:
- HomeTab - Dashboard overview
- ChatTab - Chat rooms list (BlocConsumer<ChatBloc>)
- LocationTab - Friend locations on map
- ActivityTab - Recent activity feed
- ProfileTab - User profile with stats and menu

**Use Cases**:
- `GetDashboardData` - Fetch dashboard overview

**BLoC**: `HomeBloc`

---

## Missing Features

### 13. 📅 Events & Calendar

**Status**: ⏳ Planned

**Description**: Group event management with calendar view.

**Planned Capabilities**:
- Create group events with date, time, location
- Event categories (meeting, dinner, outing, etc.)
- RSVP system (attending, maybe, not attending)
- Event reminders and notifications
- Calendar view (monthly/weekly)
- Event details with attendee list
- Recurring events
- Event updates and cancellations

**Planned Screens**:
- Event List Screen
- Calendar View Screen
- Create/Edit Event Screen
- Event Details Screen
- RSVP Management Screen

**Planned Use Cases**:
- `CreateEvent` - Create new event
- `UpdateEvent` - Edit event details
- `DeleteEvent` - Remove event
- `GetEvents` - Fetch events for a group
- `RSVPToEvent` - Respond to event invitation
- `GetEventAttendees` - View who's attending

**Planned BLoC**: `EventBloc`

**Planned Database Collection**: `events`

**Notes**:
- Mentioned in `firestore.rules` but not yet implemented
- Would integrate with chat for event announcements
- Would integrate with notifications for reminders
- Assigned to Cheah's module list

---

## Feature Completeness Matrix

| Feature | Domain | Data | Presentation | BLoC | Tests | Routes | Firebase | Status |
|---------|--------|------|--------------|------|-------|--------|----------|--------|
| Auth | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Complete |
| Friends | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Complete |
| Chat | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Complete |
| Expense | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Complete |
| Grocery | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Complete |
| Timetable | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Complete |
| Living Tools | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Complete |
| Tasks | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Complete |
| Location | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ✅ | Complete |
| Notifications | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | ✅ | Complete |
| Settings | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Complete |
| Home | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Complete |
| **Events** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ⚠️ | **Missing** |

---

## Statistics

- **Total Features**: 13 planned
- **Implemented**: 12 (92%)
- **Missing**: 1 (8%)
- **Total Screens**: 25+
- **Total Use Cases**: 85+
- **Total BLoCs**: 12
- **Test Coverage**: Comprehensive unit tests for all implemented features (990+ tests)

---

## Next Steps

1. **Implement Events/Calendar Feature** - The only major missing feature
2. **Deploy Cloud Functions** - Deploy FCM push notification functions and test on device
3. **Add Integration Tests** - Test complete user flows
4. **Performance Optimization** - Further data loading and caching improvements
5. **Additional Feature Polish** - Refine remaining feature screens

---

## Contributing

When adding new features:
1. Follow Clean Architecture structure (Domain → Data → Presentation)
2. Use BLoC pattern for state management
3. Write comprehensive unit tests
4. Update Firebase rules and indexes
5. Document in this file
6. Follow existing naming conventions

---

For detailed architecture information, see `ARCHITECTURE.md`.
