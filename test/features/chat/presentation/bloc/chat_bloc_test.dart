import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/usecases/usecase.dart';
import 'package:pulse/features/chat/domain/entities/message.dart';
import 'package:pulse/features/chat/domain/usecases/get_chat_rooms.dart';
import 'package:pulse/features/chat/domain/usecases/get_messages.dart';
import 'package:pulse/features/chat/domain/usecases/send_message.dart';
import 'package:pulse/features/chat/domain/usecases/watch_messages.dart';
import 'package:pulse/features/chat/domain/usecases/create_chat_room.dart';
import 'package:pulse/features/chat/domain/usecases/delete_chat_room.dart';
import 'package:pulse/features/chat/domain/usecases/mark_as_read.dart';
import 'package:pulse/features/chat/domain/usecases/edit_message.dart';
import 'package:pulse/features/chat/domain/usecases/delete_message.dart';
import 'package:pulse/features/chat/domain/usecases/set_typing_status.dart';
import 'package:pulse/features/chat/domain/usecases/watch_typing_users.dart';
import 'package:pulse/features/chat/domain/usecases/upload_chat_media.dart';
import 'package:pulse/features/chat/domain/usecases/get_chat_room_by_id.dart';
import 'package:pulse/features/chat/domain/usecases/get_merged_messages.dart';
import 'package:pulse/features/chat/domain/usecases/make_admin.dart';
import 'package:pulse/features/chat/domain/usecases/search_messages.dart';
import 'package:pulse/features/chat/domain/usecases/remove_admin.dart';
import 'package:pulse/features/chat/domain/usecases/watch_chat_room.dart';
import 'package:pulse/features/chat/domain/usecases/watch_chat_rooms.dart';
import 'package:pulse/features/chat/presentation/bloc/chat_bloc.dart';

class MockGetChatRooms extends Mock implements GetChatRooms {}

class MockGetMessages extends Mock implements GetMessages {}

class MockSendMessage extends Mock implements SendMessage {}

class MockWatchMessages extends Mock implements WatchMessages {}

class MockCreateChatRoom extends Mock implements CreateChatRoom {}

class MockDeleteChatRoom extends Mock implements DeleteChatRoom {}

class MockMarkAsRead extends Mock implements MarkAsRead {}

class MockEditMessage extends Mock implements EditMessage {}

class MockDeleteMessage extends Mock implements DeleteMessage {}

class MockSetTypingStatus extends Mock implements SetTypingStatus {}

class MockWatchTypingUsers extends Mock implements WatchTypingUsers {}

class MockUploadChatMedia extends Mock implements UploadChatMedia {}

class MockMakeAdmin extends Mock implements MakeAdmin {}

class MockRemoveAdmin extends Mock implements RemoveAdmin {}

class MockGetChatRoomById extends Mock implements GetChatRoomById {}

class MockGetMergedMessages extends Mock implements GetMergedMessages {}

class MockSearchMessages extends Mock implements SearchMessages {}

class MockWatchChatRoom extends Mock implements WatchChatRoom {}

class MockWatchChatRooms extends Mock implements WatchChatRooms {}

void main() {
  late ChatBloc bloc;
  late MockGetChatRooms mockGetChatRooms;
  late MockGetMessages mockGetMessages;
  late MockSendMessage mockSendMessage;
  late MockWatchMessages mockWatchMessages;
  late MockCreateChatRoom mockCreateChatRoom;
  late MockDeleteChatRoom mockDeleteChatRoom;
  late MockMarkAsRead mockMarkAsRead;
  late MockEditMessage mockEditMessage;
  late MockDeleteMessage mockDeleteMessage;
  late MockSetTypingStatus mockSetTypingStatus;
  late MockWatchTypingUsers mockWatchTypingUsers;
  late MockUploadChatMedia mockUploadChatMedia;
  late MockMakeAdmin mockMakeAdmin;
  late MockRemoveAdmin mockRemoveAdmin;
  late MockGetChatRoomById mockGetChatRoomById;
  late MockGetMergedMessages mockGetMergedMessages;
  late MockSearchMessages mockSearchMessages;
  late MockWatchChatRoom mockWatchChatRoom;
  late MockWatchChatRooms mockWatchChatRooms;

  setUp(() {
    mockGetChatRooms = MockGetChatRooms();
    mockGetMessages = MockGetMessages();
    mockSendMessage = MockSendMessage();
    mockWatchMessages = MockWatchMessages();
    mockCreateChatRoom = MockCreateChatRoom();
    mockDeleteChatRoom = MockDeleteChatRoom();
    mockMarkAsRead = MockMarkAsRead();
    mockEditMessage = MockEditMessage();
    mockDeleteMessage = MockDeleteMessage();
    mockSetTypingStatus = MockSetTypingStatus();
    mockWatchTypingUsers = MockWatchTypingUsers();
    mockUploadChatMedia = MockUploadChatMedia();
    mockMakeAdmin = MockMakeAdmin();
    mockRemoveAdmin = MockRemoveAdmin();
    mockGetChatRoomById = MockGetChatRoomById();
    mockGetMergedMessages = MockGetMergedMessages();
    mockSearchMessages = MockSearchMessages();
    mockWatchChatRoom = MockWatchChatRoom();
    mockWatchChatRooms = MockWatchChatRooms();

    bloc = ChatBloc(
      getChatRooms: mockGetChatRooms,
      watchChatRooms: mockWatchChatRooms,
      watchChatRoom: mockWatchChatRoom,
      getMessages: mockGetMessages,
      sendMessage: mockSendMessage,
      watchMessages: mockWatchMessages,
      createChatRoom: mockCreateChatRoom,
      deleteChatRoom: mockDeleteChatRoom,
      markAsRead: mockMarkAsRead,
      editMessage: mockEditMessage,
      deleteMessage: mockDeleteMessage,
      setTypingStatus: mockSetTypingStatus,
      watchTypingUsers: mockWatchTypingUsers,
      uploadChatMedia: mockUploadChatMedia,
      getMergedMessages: mockGetMergedMessages,
      searchMessages: mockSearchMessages,
      makeAdmin: mockMakeAdmin,
      removeAdmin: mockRemoveAdmin,
      getChatRoomById: mockGetChatRoomById,
    );
  });

  tearDown(() {
    bloc.close();
  });

  final tChatRoom = ChatRoom(
    id: '1',
    name: 'General',
    members: ['user-1', 'user-2'],
    createdAt: DateTime(2024, 1, 1),
    isGroup: true,
  );

  final tChatRooms = [tChatRoom];

  final tMessage = Message(
    id: '1',
    senderId: 'user-1',
    senderName: 'John Doe',
    content: 'Hello!',
    chatRoomId: '1',
    timestamp: DateTime(2024, 1, 1, 10, 0),
  );

  final tMessages = [tMessage];

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const GetMessagesParams(chatRoomId: '1'));
    registerFallbackValue(SendMessageParams(message: tMessage));
    registerFallbackValue(
      const EditMessageParams(
        chatRoomId: '1',
        messageId: '1',
        newContent: 'edited',
      ),
    );
    registerFallbackValue(
      const DeleteMessageParams(chatRoomId: '1', messageId: '1'),
    );
    registerFallbackValue(
      const MarkAsReadParams(chatRoomId: '1', userId: 'user-1'),
    );
    registerFallbackValue(
      const SetTypingStatusParams(
        chatRoomId: '1',
        userId: 'user-1',
        isTyping: true,
      ),
    );
    registerFallbackValue(
      const WatchTypingUsersParams(chatRoomId: '1', currentUserId: 'user-1'),
    );
    registerFallbackValue(
      const UploadChatMediaParams(
        chatRoomId: '1',
        filePath: '/tmp/img.png',
        fileName: 'img.png',
      ),
    );
    registerFallbackValue(MakeAdminParams(chatRoomId: '1', userId: 'user-2'));
    registerFallbackValue(RemoveAdminParams(chatRoomId: '1', userId: 'user-2'));
    registerFallbackValue(const GetChatRoomByIdParams(chatRoomId: '1'));
    registerFallbackValue(
      SearchMessagesParams(messages: [tMessage], query: 'Hello'),
    );
  });

  group('ChatRoomsLoadRequested', () {
    blocTest<ChatBloc, ChatState>(
      'emits [loading, loaded] when chat rooms are loaded successfully',
      build: () {
        when(
          () => mockGetChatRooms(any()),
        ).thenAnswer((_) async => Right(tChatRooms));
        return bloc;
      },
      act: (bloc) => bloc.add(ChatRoomsLoadRequested()),
      expect: () => [
        const ChatState(status: ChatStatus.loading),
        ChatState(status: ChatStatus.loaded, chatRooms: tChatRooms),
      ],
      verify: (_) {
        verify(() => mockGetChatRooms(any())).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'emits [loading, loaded] with empty list when no chat rooms exist',
      build: () {
        when(
          () => mockGetChatRooms(any()),
        ).thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (bloc) => bloc.add(ChatRoomsLoadRequested()),
      expect: () => [
        const ChatState(status: ChatStatus.loading),
        const ChatState(status: ChatStatus.loaded, chatRooms: []),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits [loading, error] when loading chat rooms fails',
      build: () {
        when(() => mockGetChatRooms(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Server error')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(ChatRoomsLoadRequested()),
      expect: () => [
        const ChatState(status: ChatStatus.loading),
        const ChatState(status: ChatStatus.error, errorMessage: 'Server error'),
      ],
    );
  });

  group('ChatMessagesLoadRequested', () {
    blocTest<ChatBloc, ChatState>(
      'emits [loading, loaded] when messages are loaded successfully',
      build: () {
        when(
          () => mockGetMessages(any()),
        ).thenAnswer((_) async => Right(tMessages));
        return bloc;
      },
      act: (bloc) => bloc.add(const ChatMessagesLoadRequested(chatRoomId: '1')),
      expect: () => [
        const ChatState(status: ChatStatus.loading),
        ChatState(
          status: ChatStatus.loaded,
          messages: tMessages,
          currentChatRoomId: '1',
          hasMoreMessages: false,
        ),
      ],
      verify: (_) {
        verify(() => mockGetMessages(any())).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'emits [loading, loaded] with empty list when no messages exist',
      build: () {
        when(
          () => mockGetMessages(any()),
        ).thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (bloc) => bloc.add(const ChatMessagesLoadRequested(chatRoomId: '1')),
      expect: () => [
        const ChatState(status: ChatStatus.loading),
        const ChatState(
          status: ChatStatus.loaded,
          messages: [],
          currentChatRoomId: '1',
          hasMoreMessages: false,
        ),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits [loading, error] when loading messages fails',
      build: () {
        when(() => mockGetMessages(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Server error')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const ChatMessagesLoadRequested(chatRoomId: '1')),
      expect: () => [
        const ChatState(status: ChatStatus.loading),
        const ChatState(status: ChatStatus.error, errorMessage: 'Server error'),
      ],
    );
  });

  group('MessageSendRequested', () {
    blocTest<ChatBloc, ChatState>(
      'emits [sending, sent] when message is sent successfully',
      build: () {
        when(
          () => mockSendMessage(any()),
        ).thenAnswer((_) async => Right(tMessage));
        return bloc;
      },
      act: (bloc) => bloc.add(MessageSendRequested(message: tMessage)),
      expect: () => [
        ChatState(messages: [tMessage], sendingStatus: SendStatus.sending),
        ChatState(messages: [tMessage], sendingStatus: SendStatus.sent),
      ],
      verify: (_) {
        verify(() => mockSendMessage(any())).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'emits [sending, error] when sending message fails - marks as failed',
      build: () {
        when(() => mockSendMessage(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Failed to send')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(MessageSendRequested(message: tMessage)),
      expect: () => [
        ChatState(messages: [tMessage], sendingStatus: SendStatus.sending),
        ChatState(
          messages: [tMessage.copyWith(sendStatus: MessageSendStatus.failed)],
          sendingStatus: SendStatus.error,
          errorMessage: 'Failed to send',
        ),
      ],
    );
  });

  group('MessageEditRequested', () {
    blocTest<ChatBloc, ChatState>(
      'calls editMessage use case successfully',
      build: () {
        when(
          () => mockEditMessage(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const MessageEditRequested(
          chatRoomId: '1',
          messageId: '1',
          newContent: 'edited',
        ),
      ),
      verify: (_) {
        verify(() => mockEditMessage(any())).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'emits error when edit fails',
      build: () {
        when(() => mockEditMessage(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Edit failed')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(
        const MessageEditRequested(
          chatRoomId: '1',
          messageId: '1',
          newContent: 'edited',
        ),
      ),
      expect: () => [const ChatState(errorMessage: 'Edit failed')],
    );
  });

  group('MessageDeleteRequested', () {
    blocTest<ChatBloc, ChatState>(
      'calls deleteMessage use case successfully',
      build: () {
        when(
          () => mockDeleteMessage(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const MessageDeleteRequested(chatRoomId: '1', messageId: '1'),
      ),
      verify: (_) {
        verify(() => mockDeleteMessage(any())).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'emits error when delete fails',
      build: () {
        when(() => mockDeleteMessage(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Delete failed')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(
        const MessageDeleteRequested(chatRoomId: '1', messageId: '1'),
      ),
      expect: () => [const ChatState(errorMessage: 'Delete failed')],
    );
  });

  group('ChatMoreMessagesLoadRequested', () {
    blocTest<ChatBloc, ChatState>(
      'loads older messages and prepends them',
      seed: () => ChatState(
        status: ChatStatus.loaded,
        messages: tMessages,
        currentChatRoomId: '1',
        hasMoreMessages: true,
      ),
      build: () {
        final olderMessage = Message(
          id: '0',
          senderId: 'user-2',
          senderName: 'Jane',
          content: 'Hi',
          chatRoomId: '1',
          timestamp: DateTime(2024, 1, 1, 9, 0),
        );
        when(
          () => mockGetMessages(any()),
        ).thenAnswer((_) async => Right([olderMessage]));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const ChatMoreMessagesLoadRequested(chatRoomId: '1')),
      expect: () => [
        ChatState(
          status: ChatStatus.loaded,
          messages: tMessages,
          currentChatRoomId: '1',
          hasMoreMessages: true,
          isLoadingMore: true,
        ),
        isA<ChatState>()
            .having((s) => s.messages.length, 'messages.length', 2)
            .having((s) => s.isLoadingMore, 'isLoadingMore', false)
            .having((s) => s.hasMoreMessages, 'hasMoreMessages', false),
      ],
      verify: (_) {
        verify(() => mockGetMessages(any())).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'does nothing when already loading more',
      seed: () => const ChatState(
        status: ChatStatus.loaded,
        messages: [],
        isLoadingMore: true,
      ),
      build: () => bloc,
      act: (bloc) =>
          bloc.add(const ChatMoreMessagesLoadRequested(chatRoomId: '1')),
      expect: () => [],
    );
  });

  group('MessageRetryRequested', () {
    final failedMessage = tMessage.copyWith(
      sendStatus: MessageSendStatus.failed,
    );

    blocTest<ChatBloc, ChatState>(
      'retries sending and removes local message on success',
      seed: () =>
          ChatState(status: ChatStatus.loaded, messages: [failedMessage]),
      build: () {
        when(
          () => mockSendMessage(any()),
        ).thenAnswer((_) async => Right(tMessage));
        return bloc;
      },
      act: (bloc) => bloc.add(MessageRetryRequested(message: failedMessage)),
      expect: () => [
        // Marked as sending
        ChatState(
          status: ChatStatus.loaded,
          messages: [
            failedMessage.copyWith(sendStatus: MessageSendStatus.sending),
          ],
          sendingStatus: SendStatus.sending,
        ),
        // Removed after success (stream will bring real one)
        const ChatState(
          status: ChatStatus.loaded,
          messages: [],
          sendingStatus: SendStatus.sent,
        ),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'marks message as failed again on retry failure',
      seed: () =>
          ChatState(status: ChatStatus.loaded, messages: [failedMessage]),
      build: () {
        when(() => mockSendMessage(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Still failing')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(MessageRetryRequested(message: failedMessage)),
      expect: () => [
        ChatState(
          status: ChatStatus.loaded,
          messages: [
            failedMessage.copyWith(sendStatus: MessageSendStatus.sending),
          ],
          sendingStatus: SendStatus.sending,
        ),
        ChatState(
          status: ChatStatus.loaded,
          messages: [failedMessage],
          sendingStatus: SendStatus.error,
          errorMessage: 'Still failing',
        ),
      ],
    );
  });

  group('ChatTypingWatchRequested', () {
    blocTest<ChatBloc, ChatState>(
      'subscribes to typing users stream',
      build: () {
        when(
          () => mockWatchTypingUsers(any()),
        ).thenAnswer((_) => const Stream<List<String>>.empty());
        return bloc;
      },
      act: (bloc) => bloc.add(
        const ChatTypingWatchRequested(
          chatRoomId: '1',
          currentUserId: 'user-1',
        ),
      ),
      verify: (_) {
        verify(() => mockWatchTypingUsers(any())).called(1);
      },
    );
  });

  group('MessageSearchRequested / Cleared', () {
    blocTest<ChatBloc, ChatState>(
      'filters messages by search query',
      seed: () => ChatState(
        status: ChatStatus.loaded,
        messages: [
          tMessage,
          Message(
            id: '2',
            senderId: 'user-2',
            senderName: 'Jane',
            content: 'Goodbye!',
            chatRoomId: '1',
            timestamp: DateTime(2024, 1, 1, 11, 0),
          ),
        ],
      ),
      build: () {
        when(
          () => mockSearchMessages(any()),
        ).thenAnswer((_) async => Right([tMessage]));
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const MessageSearchRequested(query: 'Hello'));
        // Wait for debounce (300ms) + processing time
        await Future.delayed(const Duration(milliseconds: 350));
      },
      wait: const Duration(milliseconds: 400),
      expect: () => [
        isA<ChatState>()
            .having((s) => s.searchQuery, 'searchQuery', 'Hello')
            .having((s) => s.searchResults.length, 'searchResults.length', 1)
            .having((s) => s.searchResults.first.content, 'content', 'Hello!'),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'clears search results',
      seed: () => ChatState(
        status: ChatStatus.loaded,
        messages: [tMessage],
        searchQuery: 'Hello',
        searchResults: [tMessage],
      ),
      build: () => bloc,
      act: (bloc) => bloc.add(MessageSearchClearRequested()),
      expect: () => [
        isA<ChatState>()
            .having((s) => s.searchQuery, 'searchQuery', isNull)
            .having((s) => s.searchResults, 'searchResults', isEmpty),
      ],
    );
  });

  group('MediaMessageSendRequested', () {
    blocTest<ChatBloc, ChatState>(
      'uploads media then sends message on success',
      build: () {
        when(
          () => mockUploadChatMedia(any()),
        ).thenAnswer((_) async => const Right('https://example.com/img.png'));
        when(
          () => mockSendMessage(any()),
        ).thenAnswer((_) async => Right(tMessage));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const MediaMessageSendRequested(
          chatRoomId: '1',
          senderId: 'user-1',
          senderName: 'John Doe',
          filePath: '/tmp/img.png',
          fileName: 'img.png',
        ),
      ),
      expect: () => [
        // Upload started
        const ChatState(uploadProgress: 0.0),
        // Upload complete
        const ChatState(),
        // Message optimistic add + send
        isA<ChatState>().having((s) => s.messages.length, 'messages.length', 1),
        isA<ChatState>().having(
          (s) => s.sendingStatus,
          'sendingStatus',
          SendStatus.sent,
        ),
      ],
      verify: (_) {
        verify(() => mockUploadChatMedia(any())).called(1);
        verify(() => mockSendMessage(any())).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'emits error when upload fails',
      build: () {
        when(() => mockUploadChatMedia(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Upload failed')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(
        const MediaMessageSendRequested(
          chatRoomId: '1',
          senderId: 'user-1',
          senderName: 'John Doe',
          filePath: '/tmp/img.png',
          fileName: 'img.png',
        ),
      ),
      expect: () => [
        const ChatState(uploadProgress: 0.0),
        const ChatState(errorMessage: 'Upload failed'),
      ],
    );
  });

  group('MakeAdminRequested', () {
    blocTest<ChatBloc, ChatState>(
      'emits success message when make admin succeeds',
      build: () {
        when(
          () => mockMakeAdmin(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const MakeAdminRequested(chatRoomId: '1', userId: 'user-2')),
      expect: () => [
        const ChatState(isProcessingAdminAction: true),
        const ChatState(
          successMessage: 'User is now an admin',
          lastAction: ChatAction.madeAdmin,
          isProcessingAdminAction: false,
        ),
      ],
      verify: (_) {
        verify(() => mockMakeAdmin(any())).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'emits error message when make admin fails',
      build: () {
        when(() => mockMakeAdmin(any())).thenAnswer(
          (_) async =>
              const Left(ServerFailure(message: 'Failed to make admin')),
        );
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const MakeAdminRequested(chatRoomId: '1', userId: 'user-2')),
      expect: () => [
        const ChatState(isProcessingAdminAction: true),
        const ChatState(
          errorMessage: 'Failed to make admin',
          isProcessingAdminAction: false,
        ),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits error when network failure occurs',
      build: () {
        when(
          () => mockMakeAdmin(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const MakeAdminRequested(chatRoomId: '1', userId: 'user-2')),
      expect: () => [
        const ChatState(isProcessingAdminAction: true),
        const ChatState(
          errorMessage: 'No internet connection',
          isProcessingAdminAction: false,
        ),
      ],
    );
  });

  group('RemoveAdminRequested', () {
    blocTest<ChatBloc, ChatState>(
      'emits success message when remove admin succeeds',
      build: () {
        when(
          () => mockRemoveAdmin(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const RemoveAdminRequested(chatRoomId: '1', userId: 'user-2'),
      ),
      expect: () => [
        const ChatState(isProcessingAdminAction: true),
        const ChatState(
          successMessage: 'Admin role removed',
          lastAction: ChatAction.removedAdmin,
          isProcessingAdminAction: false,
        ),
      ],
      verify: (_) {
        verify(() => mockRemoveAdmin(any())).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'emits error message when remove admin fails',
      build: () {
        when(() => mockRemoveAdmin(any())).thenAnswer(
          (_) async =>
              const Left(ServerFailure(message: 'Failed to remove admin')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(
        const RemoveAdminRequested(chatRoomId: '1', userId: 'user-2'),
      ),
      expect: () => [
        const ChatState(isProcessingAdminAction: true),
        const ChatState(
          errorMessage: 'Failed to remove admin',
          isProcessingAdminAction: false,
        ),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits error when trying to remove last admin',
      build: () {
        when(() => mockRemoveAdmin(any())).thenAnswer(
          (_) async => const Left(
            ServerFailure(message: 'Cannot remove the last admin'),
          ),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(
        const RemoveAdminRequested(chatRoomId: '1', userId: 'user-1'),
      ),
      expect: () => [
        const ChatState(isProcessingAdminAction: true),
        const ChatState(
          errorMessage: 'Cannot remove the last admin',
          isProcessingAdminAction: false,
        ),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits error when network failure occurs',
      build: () {
        when(
          () => mockRemoveAdmin(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const RemoveAdminRequested(chatRoomId: '1', userId: 'user-2'),
      ),
      expect: () => [
        const ChatState(isProcessingAdminAction: true),
        const ChatState(
          errorMessage: 'No internet connection',
          isProcessingAdminAction: false,
        ),
      ],
    );
  });

  group('ChatClearedRequested', () {
    blocTest<ChatBloc, ChatState>(
      'resets state to initial when chat is cleared',
      build: () => bloc,
      seed: () => ChatState(
        status: ChatStatus.error,
        chatRooms: tChatRooms,
        messages: tMessages,
        currentChatRoomId: '1',
        errorMessage: 'User not authenticated',
      ),
      act: (bloc) => bloc.add(ChatClearedRequested()),
      expect: () => [const ChatState()],
    );
  });
}
