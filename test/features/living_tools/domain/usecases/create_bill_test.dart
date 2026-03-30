import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/living_tools/domain/entities/bill.dart';
import 'package:pulse/features/living_tools/domain/repositories/bill_repository.dart';
import 'package:pulse/features/living_tools/domain/usecases/create_bill.dart';

class MockBillRepository extends Mock implements BillRepository {}

void main() {
  late CreateBill usecase;
  late MockBillRepository mockRepository;

  setUp(() {
    mockRepository = MockBillRepository();
    usecase = CreateBill(mockRepository);
  });

  const tBillMember = BillMember(
    id: 'member-1',
    userId: 'user-1',
    userName: 'John Doe',
    share: 50.0,
    hasPaid: false,
  );

  final tBill = Bill(
    id: '',
    type: BillType.utilities,
    title: 'Electric Bill',
    amount: 100.0,
    dueDate: DateTime(2024, 2, 1),
    status: BillStatus.pending,
    members: [tBillMember],
    createdBy: 'user-1',
    createdAt: DateTime(2024, 1, 15),
    chatRoomId: 'chat-1',
  );

  final tCreatedBill = Bill(
    id: 'bill-123',
    type: BillType.utilities,
    title: 'Electric Bill',
    amount: 100.0,
    dueDate: DateTime(2024, 2, 1),
    status: BillStatus.pending,
    members: [tBillMember],
    createdBy: 'user-1',
    createdAt: DateTime(2024, 1, 15),
    chatRoomId: 'chat-1',
  );

  setUpAll(() {
    registerFallbackValue(tBill);
  });

  test('should return created Bill when successful', () async {
    // arrange
    when(() => mockRepository.createBill(any()))
        .thenAnswer((_) async => Right(tCreatedBill));

    // act
    final result = await usecase(CreateBillParams(bill: tBill));

    // assert
    expect(result.isRight(), true);
    result.fold(
      (l) => fail('Should be Right'),
      (r) {
        expect(r.id, 'bill-123');
        expect(r.title, 'Electric Bill');
        expect(r.amount, 100.0);
      },
    );
    verify(() => mockRepository.createBill(any())).called(1);
  });

  test('should return ServerFailure when creation fails', () async {
    // arrange
    when(() => mockRepository.createBill(any()))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to create bill')));

    // act
    final result = await usecase(CreateBillParams(bill: tBill));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to create bill')));
    verify(() => mockRepository.createBill(any())).called(1);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockRepository.createBill(any()))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(CreateBillParams(bill: tBill));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.createBill(any())).called(1);
  });
}
