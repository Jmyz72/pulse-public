import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message.dart';

/// Use case for searching messages by query string.
///
/// Filters non-deleted messages using case-insensitive substring matching.
class SearchMessages
    extends UseCase<List<Message>, SearchMessagesParams> {
  @override
  Future<Either<Failure, List<Message>>> call(
      SearchMessagesParams params) async {
    try {
      if (params.query.isEmpty) {
        return const Right([]);
      }

      final query = params.query.toLowerCase();
      final results = params.messages
          .where((m) => !m.isDeleted && m.content.toLowerCase().contains(query))
          .toList();

      return Right(results);
    } catch (e) {
      return const Left(
          InvalidInputFailure(message: 'Failed to search messages'));
    }
  }
}

class SearchMessagesParams extends Equatable {
  final List<Message> messages;
  final String query;

  const SearchMessagesParams({
    required this.messages,
    required this.query,
  });

  @override
  List<Object> get props => [messages, query];
}
