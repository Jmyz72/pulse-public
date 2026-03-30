import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/living_tools/domain/repositories/bill_repository.dart';
import 'package:pulse/features/living_tools/domain/usecases/mark_bill_as_paid.dart';

class MockBillRepository extends Mock implements BillRepository {}

void main() {
  late MarkBillAsPaid usecase;
  late MockBillRepository mockRepository;

  setUp(() {
    mockRepository = MockBillRepository();
    usecase = MarkBillAsPaid(mockRepository);
  });

  const tBillId = 'bill-123';
  const tMemberId = 'member-456';

  test('should return void when marking as paid is successful', () async {
    // arrange
    when(() => mockRepository.markBillAsPaid(tBillId, tMemberId))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(const MarkBillAsPaidParams(
      billId: tBillId,
      memberId: tMemberId,
    ));

    // assert
    expect(result.isRight(), true);
    verify(() => mockRepository.markBillAsPaid(tBillId, tMemberId)).called(1);
  });

  test('should return ServerFailure when marking as paid fails', () async {
    // arrange
    when(() => mockRepository.markBillAsPaid(tBillId, tMemberId))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to mark bill as paid')));

    // act
    final result = await usecase(const MarkBillAsPaidParams(
      billId: tBillId,
      memberId: tMemberId,
    ));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to mark bill as paid')));
    verify(() => mockRepository.markBillAsPaid(tBillId, tMemberId)).called(1);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockRepository.markBillAsPaid(tBillId, tMemberId))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const MarkBillAsPaidParams(
      billId: tBillId,
      memberId: tMemberId,
    ));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.markBillAsPaid(tBillId, tMemberId)).called(1);
  });
}
