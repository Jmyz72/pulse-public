import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/exceptions.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/network/network_info.dart';
import 'package:pulse/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:pulse/features/chat/data/repositories/chat_repository_impl.dart';

class MockChatRemoteDataSource extends Mock implements ChatRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late ChatRepositoryImpl repository;
  late MockChatRemoteDataSource mockRemoteDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockChatRemoteDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = ChatRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('makeAdmin', () {
    const tChatRoomId = 'chat-room-1';
    const tUserId = 'user-2';

    test('should return Right(null) when make admin succeeds', () async {
      // arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.makeAdmin(tChatRoomId, tUserId))
          .thenAnswer((_) async => Future.value());

      // act
      final result = await repository.makeAdmin(tChatRoomId, tUserId);

      // assert
      expect(result, const Right(null));
      verify(() => mockRemoteDataSource.makeAdmin(tChatRoomId, tUserId)).called(1);
    });

    test('should return NetworkFailure when not connected', () async {
      // arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // act
      final result = await repository.makeAdmin(tChatRoomId, tUserId);

      // assert
      expect(result, const Left(NetworkFailure()));
      verifyNever(() => mockRemoteDataSource.makeAdmin(any(), any()));
    });

    test('should return ServerFailure when remote data source throws', () async {
      // arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.makeAdmin(tChatRoomId, tUserId))
          .thenThrow(const ServerException(message: 'Server error'));

      // act
      final result = await repository.makeAdmin(tChatRoomId, tUserId);

      // assert
      expect(result, const Left(ServerFailure(message: 'Server error')));
    });
  });

  group('removeAdmin', () {
    const tChatRoomId = 'chat-room-1';
    const tUserId = 'user-2';

    test('should return Right(null) when remove admin succeeds', () async {
      // arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.removeAdmin(tChatRoomId, tUserId))
          .thenAnswer((_) async => Future.value());

      // act
      final result = await repository.removeAdmin(tChatRoomId, tUserId);

      // assert
      expect(result, const Right(null));
      verify(() => mockRemoteDataSource.removeAdmin(tChatRoomId, tUserId)).called(1);
    });

    test('should return NetworkFailure when not connected', () async {
      // arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // act
      final result = await repository.removeAdmin(tChatRoomId, tUserId);

      // assert
      expect(result, const Left(NetworkFailure()));
      verifyNever(() => mockRemoteDataSource.removeAdmin(any(), any()));
    });

    test('should return ServerFailure when trying to remove last admin', () async {
      // arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.removeAdmin(tChatRoomId, tUserId))
          .thenThrow(const ServerException(message: 'Cannot remove the last admin'));

      // act
      final result = await repository.removeAdmin(tChatRoomId, tUserId);

      // assert
      expect(result, const Left(ServerFailure(message: 'Cannot remove the last admin')));
    });

    test('should return ServerFailure when remote data source throws', () async {
      // arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.removeAdmin(tChatRoomId, tUserId))
          .thenThrow(const ServerException(message: 'Server error'));

      // act
      final result = await repository.removeAdmin(tChatRoomId, tUserId);

      // assert
      expect(result, const Left(ServerFailure(message: 'Server error')));
    });
  });
}
