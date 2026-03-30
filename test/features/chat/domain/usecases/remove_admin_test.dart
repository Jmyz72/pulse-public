import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/chat/domain/repositories/chat_repository.dart';
import 'package:pulse/features/chat/domain/usecases/remove_admin.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late RemoveAdmin usecase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    usecase = RemoveAdmin(mockRepository);
  });

  const tChatRoomId = 'chat-room-1';
  const tUserId = 'user-2';
  final tParams = RemoveAdminParams(chatRoomId: tChatRoomId, userId: tUserId);

  test('should remove admin when successful', () async {
    // arrange
    when(() => mockRepository.removeAdmin(tChatRoomId, tUserId))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(tParams);

    // assert
    expect(result, const Right(null));
    verify(() => mockRepository.removeAdmin(tChatRoomId, tUserId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ServerFailure when trying to remove last admin', () async {
    // arrange
    when(() => mockRepository.removeAdmin(tChatRoomId, tUserId))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Cannot remove the last admin')));

    // act
    final result = await usecase(tParams);

    // assert
    expect(result, const Left(ServerFailure(message: 'Cannot remove the last admin')));
    verify(() => mockRepository.removeAdmin(tChatRoomId, tUserId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ServerFailure when server error occurs', () async {
    // arrange
    when(() => mockRepository.removeAdmin(tChatRoomId, tUserId))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

    // act
    final result = await usecase(tParams);

    // assert
    expect(result, const Left(ServerFailure(message: 'Server error')));
    verify(() => mockRepository.removeAdmin(tChatRoomId, tUserId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockRepository.removeAdmin(tChatRoomId, tUserId))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(tParams);

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.removeAdmin(tChatRoomId, tUserId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  group('RemoveAdminParams', () {
    test('should have correct props', () {
      // arrange
      final params1 = RemoveAdminParams(chatRoomId: 'room-1', userId: 'user-1');
      final params2 = RemoveAdminParams(chatRoomId: 'room-1', userId: 'user-1');
      final params3 = RemoveAdminParams(chatRoomId: 'room-1', userId: 'user-2');

      // act & assert
      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
      expect(params1.props, [params1.chatRoomId, params1.userId]);
    });
  });
}
