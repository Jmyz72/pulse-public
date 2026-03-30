import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/chat/domain/repositories/chat_repository.dart';
import 'package:pulse/features/chat/domain/usecases/make_admin.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MakeAdmin usecase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    usecase = MakeAdmin(mockRepository);
  });

  const tChatRoomId = 'chat-room-1';
  const tUserId = 'user-2';
  final tParams = MakeAdminParams(chatRoomId: tChatRoomId, userId: tUserId);

  test('should make user admin when successful', () async {
    // arrange
    when(() => mockRepository.makeAdmin(tChatRoomId, tUserId))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(tParams);

    // assert
    expect(result, const Right(null));
    verify(() => mockRepository.makeAdmin(tChatRoomId, tUserId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ServerFailure when server error occurs', () async {
    // arrange
    when(() => mockRepository.makeAdmin(tChatRoomId, tUserId))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

    // act
    final result = await usecase(tParams);

    // assert
    expect(result, const Left(ServerFailure(message: 'Server error')));
    verify(() => mockRepository.makeAdmin(tChatRoomId, tUserId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockRepository.makeAdmin(tChatRoomId, tUserId))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(tParams);

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.makeAdmin(tChatRoomId, tUserId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  group('MakeAdminParams', () {
    test('should have correct props', () {
      // arrange
      final params1 = MakeAdminParams(chatRoomId: 'room-1', userId: 'user-1');
      final params2 = MakeAdminParams(chatRoomId: 'room-1', userId: 'user-1');
      final params3 = MakeAdminParams(chatRoomId: 'room-2', userId: 'user-1');

      // act & assert
      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
      expect(params1.props, [params1.chatRoomId, params1.userId]);
    });
  });
}
