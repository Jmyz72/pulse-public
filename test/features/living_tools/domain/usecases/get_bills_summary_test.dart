import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/living_tools/domain/entities/bill_summary.dart';
import 'package:pulse/features/living_tools/domain/repositories/bill_repository.dart';
import 'package:pulse/features/living_tools/domain/usecases/get_bills_summary.dart';

class MockBillRepository extends Mock implements BillRepository {}

void main() {
  late GetBillsSummary usecase;
  late MockBillRepository mockRepository;

  setUp(() {
    mockRepository = MockBillRepository();
    usecase = GetBillsSummary(mockRepository);
  });

  const tUserId = 'user-123';
  const tChatRoomIds = ['chat-1', 'chat-2'];

  const tBillSummary = BillSummary(
    totalOwed: 500.0,
    totalPaid: 300.0,
    yourOwed: 150.0,
    yourPaid: 100.0,
    pendingCount: 3,
    overdueCount: 1,
    paidCount: 2,
  );

  test('should return BillSummary when successful', () async {
    // arrange
    when(() => mockRepository.getBillsSummary(tUserId, tChatRoomIds))
        .thenAnswer((_) async => const Right(tBillSummary));

    // act
    final result = await usecase(const GetBillsSummaryParams(userId: tUserId, chatRoomIds: tChatRoomIds));

    // assert
    expect(result.isRight(), true);
    result.fold(
      (l) => fail('Should be Right'),
      (r) {
        expect(r.totalOwed, 500.0);
        expect(r.totalPaid, 300.0);
        expect(r.yourOwed, 150.0);
        expect(r.yourPaid, 100.0);
        expect(r.pendingCount, 3);
        expect(r.overdueCount, 1);
        expect(r.paidCount, 2);
      },
    );
    verify(() => mockRepository.getBillsSummary(tUserId, tChatRoomIds)).called(1);
  });

  test('should return ServerFailure when fetching summary fails', () async {
    // arrange
    when(() => mockRepository.getBillsSummary(tUserId, tChatRoomIds))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to get bills summary')));

    // act
    final result = await usecase(const GetBillsSummaryParams(userId: tUserId, chatRoomIds: tChatRoomIds));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to get bills summary')));
    verify(() => mockRepository.getBillsSummary(tUserId, tChatRoomIds)).called(1);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockRepository.getBillsSummary(tUserId, tChatRoomIds))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const GetBillsSummaryParams(userId: tUserId, chatRoomIds: tChatRoomIds));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.getBillsSummary(tUserId, tChatRoomIds)).called(1);
  });
}
