import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message.dart';
import '../repositories/failed_message_storage.dart';

class SaveFailedMessage extends UseCase<void, SaveFailedMessageParams> {
  final FailedMessageStorage storage;

  SaveFailedMessage(this.storage);

  @override
  Future<Either<Failure, void>> call(SaveFailedMessageParams params) async {
    try {
      await storage.saveFailedMessage(params.message);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}

class SaveFailedMessageParams extends Equatable {
  final Message message;

  const SaveFailedMessageParams({required this.message});

  @override
  List<Object> get props => [message];
}
