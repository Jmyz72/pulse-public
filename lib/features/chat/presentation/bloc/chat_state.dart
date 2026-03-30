part of 'chat_bloc.dart';

enum ChatStatus { initial, loading, loaded, error }

enum SendStatus { idle, sending, sent, error }

enum ChatAction { none, memberAdded, memberRemoved, madeAdmin, removedAdmin, leftGroup }

class ChatState extends Equatable {
  final ChatStatus status;
  final List<ChatRoom> chatRooms;
  final List<Message> messages;
  final String? currentChatRoomId;
  final ChatRoom? currentChatRoom; // Real-time chat room data for read receipts
  final String? errorMessage;
  final SendStatus sendingStatus;
  final ChatRoom? createdChatRoom;
  final bool hasMoreMessages;
  final bool isLoadingMore;
  final List<String> typingUserIds;
  final String? searchQuery;
  final List<Message> searchResults;
  final double? uploadProgress;
  final Map<String, bool> onlineStatus;
  final String? successMessage;
  final ChatAction lastAction;
  final bool isProcessingAdminAction;
  final ChatRoom? fetchedChatRoom;

  const ChatState({
    this.status = ChatStatus.initial,
    this.chatRooms = const [],
    this.messages = const [],
    this.currentChatRoomId,
    this.currentChatRoom,
    this.errorMessage,
    this.sendingStatus = SendStatus.idle,
    this.createdChatRoom,
    this.hasMoreMessages = true,
    this.isLoadingMore = false,
    this.typingUserIds = const [],
    this.searchQuery,
    this.searchResults = const [],
    this.uploadProgress,
    this.onlineStatus = const {},
    this.successMessage,
    this.lastAction = ChatAction.none,
    this.isProcessingAdminAction = false,
    this.fetchedChatRoom,
  });

  ChatState copyWith({
    ChatStatus? status,
    List<ChatRoom>? chatRooms,
    List<Message>? messages,
    String? currentChatRoomId,
    ChatRoom? currentChatRoom,
    String? errorMessage,
    bool clearError = false,
    SendStatus? sendingStatus,
    ChatRoom? createdChatRoom,
    bool clearCreatedChatRoom = false,
    bool? hasMoreMessages,
    bool? isLoadingMore,
    List<String>? typingUserIds,
    String? searchQuery,
    bool clearSearch = false,
    List<Message>? searchResults,
    double? uploadProgress,
    bool clearUploadProgress = false,
    Map<String, bool>? onlineStatus,
    String? successMessage,
    bool clearSuccess = false,
    ChatAction? lastAction,
    bool? isProcessingAdminAction,
    ChatRoom? fetchedChatRoom,
    bool clearFetchedChatRoom = false,
  }) {
    return ChatState(
      status: status ?? this.status,
      chatRooms: chatRooms ?? this.chatRooms,
      messages: messages ?? this.messages,
      currentChatRoomId: currentChatRoomId ?? this.currentChatRoomId,
      currentChatRoom: currentChatRoom ?? this.currentChatRoom,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      sendingStatus: sendingStatus ?? this.sendingStatus,
      createdChatRoom: clearCreatedChatRoom ? null : (createdChatRoom ?? this.createdChatRoom),
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      typingUserIds: typingUserIds ?? this.typingUserIds,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      searchResults: clearSearch ? const [] : (searchResults ?? this.searchResults),
      uploadProgress: clearUploadProgress ? null : (uploadProgress ?? this.uploadProgress),
      onlineStatus: onlineStatus ?? this.onlineStatus,
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      lastAction: lastAction ?? this.lastAction,
      isProcessingAdminAction: isProcessingAdminAction ?? this.isProcessingAdminAction,
      fetchedChatRoom: clearFetchedChatRoom ? null : (fetchedChatRoom ?? this.fetchedChatRoom),
    );
  }

  @override
  List<Object?> get props => [
        status,
        chatRooms,
        messages,
        currentChatRoomId,
        currentChatRoom,
        errorMessage,
        sendingStatus,
        createdChatRoom,
        hasMoreMessages,
        isLoadingMore,
        typingUserIds,
        searchQuery,
        searchResults,
        uploadProgress,
        onlineStatus,
        successMessage,
        lastAction,
        isProcessingAdminAction,
        fetchedChatRoom,
      ];
}
