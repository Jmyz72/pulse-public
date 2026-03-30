import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/living_tools/domain/repositories/bill_repository.dart';
import 'package:pulse/features/living_tools/domain/usecases/delete_bill.dart';

class MockBillRepository extends Mock implements BillRepository {}

void main() {
  late DeleteBill usecase;
  late MockBillRepository mockRepository;

  setUp(() {
    mockRepository = MockBillRepository();
    usecase = DeleteBill(mockRepository);
  });

  const tBillId = 'bill-123';

  test('should return void when deletion is successful', () async {
    // arrange
    when(() => mockRepository.deleteBill(tBillId))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(const DeleteBillParams(id: tBillId));

    // assert
    expect(result.isRight(), true);
    verify(() => mockRepository.deleteBill(tBillId)).called(1);
  });

  test('should return ServerFailure when deletion fails', () async {
    // arrange
    when(() => mockRepository.deleteBill(tBillId))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to delete bill')));

    // act
    final result = await usecase(const DeleteBillParams(id: tBillId));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to delete bill')));
    verify(() => mockRepository.deleteBill(tBillId)).called(1);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockRepository.deleteBill(tBillId))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const DeleteBillParams(id: tBillId));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.deleteBill(tBillId)).called(1);
  });
}
