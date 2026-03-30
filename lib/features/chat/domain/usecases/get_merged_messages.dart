import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message.dart';
import 'get_failed_messages.dart';

/// Use case for merging messages from multiple sources.
///
/// This orchestrates:
/// - Retrieving persisted failed messages
/// - Merging stream, paginated, state-failed, and persisted-failed messages
/// - Deduplication and sorting
///
/// This keeps the BLoC simple and moves business logic to the domain layer.
class GetMergedMessages
    extends UseCase<List<Message>, GetMergedMessagesParams> {
  final GetFailedMessages getFailedMessages;

  GetMergedMessages({
    required this.getFailedMessages,
  });

  @override
  Future<Either<Failure, List<Message>>> call(
      GetMergedMessagesParams params) async {
    try {
      // Validate chatRoomId
      if (params.chatRoomId.isEmpty) {
        return const Left(
            InvalidInputFailure(message: 'Chat room ID cannot be empty'));
      }

      // Get persisted failed messages for this chat room
      final persistedFailedResult = await getFailedMessages.call(
        GetFailedMessagesParams(chatRoomId: params.chatRoomId),
      );

      final persistedFailedMessages = persistedFailedResult.fold(
        (_) => <Message>[], // If failed to load, use empty list
        (messages) => messages,
      );

      // Merge all message sources
      final merged = _mergeMessages(
        streamMessages: params.streamMessages,
        paginatedMessages: params.paginatedMessages,
        failedMessages: params.failedMessages,
        persistedFailedMessages: persistedFailedMessages,
        chatRoomId: params.chatRoomId,
      );

      return Right(merged);
    } catch (e) {
      return const Left(ServerFailure(message: 'Failed to merge messages'));
    }
  }

  /// Merges messages from multiple sources with deduplication and sorting.
  ///
  /// Algorithm:
  /// 1. Filter all sources by [chatRoomId]
  /// 2. Find oldest stream message timestamp (boundary)
  /// 3. Keep paginated messages older than boundary
  /// 4. Deduplicate all messages by ID
  /// 5. Sort by timestamp ascending
  List<Message> _mergeMessages({
    required List<Message> streamMessages,
    required List<Message> paginatedMessages,
    required List<Message> failedMessages,
    required List<Message> persistedFailedMessages,
    required String chatRoomId,
  }) {
    if (chatRoomId.isEmpty) {
      return [];
    }

    // Extract stream message IDs for deduplication
    final streamIds = streamMessages.map((m) => m.id).toSet();

    // Find the oldest stream message timestamp to establish boundary
    DateTime? oldestStreamTs;
    for (final m in streamMessages) {
      if (oldestStreamTs == null || m.timestamp.isBefore(oldestStreamTs)) {
        oldestStreamTs = m.timestamp;
      }
    }

    // Keep paginated messages that are:
    // 1. For the current chat room
    // 2. Older than the stream boundary
    // 3. Not duplicated in stream results
    final olderMessages = oldestStreamTs == null
        ? <Message>[]
        : paginatedMessages
            .where((m) =>
                m.chatRoomId == chatRoomId &&
                m.timestamp.isBefore(oldestStreamTs!) &&
                !streamIds.contains(m.id))
            .toList();

    // Keep failed messages that are:
    // 1. For the current chat room
    // 2. Have failed send status
    // 3. Not duplicated in stream results
    final filteredFailedMessages = failedMessages
        .where((m) =>
            m.chatRoomId == chatRoomId &&
            m.sendStatus == MessageSendStatus.failed &&
            !streamIds.contains(m.id))
        .toList();

    // Keep persisted failed messages that are:
    // 1. For the current chat room
    // 2. Not duplicated in stream results
    final filteredPersistedFailed = persistedFailedMessages
        .where((m) => m.chatRoomId == chatRoomId && !streamIds.contains(m.id))
        .toList();

    // Deduplicate all messages by ID
    final mergedIds = <String>{};
    final merged = <Message>[];

    for (final m in [
      ...olderMessages,
      ...streamMessages,
      ...filteredFailedMessages,
      ...filteredPersistedFailed,
    ]) {
      if (mergedIds.add(m.id)) {
        merged.add(m);
      }
    }

    // Sort by timestamp ascending (oldest first)
    merged.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return merged;
  }
}

/// Parameters for GetMergedMessages use case.
class GetMergedMessagesParams extends Equatable {
  /// Messages from Firestore real-time stream (latest N messages)
  final List<Message> streamMessages;

  /// Messages from pagination (older messages from "load more")
  final List<Message> paginatedMessages;

  /// Failed messages from current BLoC state (in-memory)
  final List<Message> failedMessages;

  /// Current chat room ID to filter messages
  final String chatRoomId;

  const GetMergedMessagesParams({
    required this.streamMessages,
    required this.paginatedMessages,
    required this.failedMessages,
    required this.chatRoomId,
  });

  @override
  List<Object> get props => [
        streamMessages,
        paginatedMessages,
        failedMessages,
        chatRoomId,
      ];
}
