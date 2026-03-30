import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/living_tools/domain/entities/bill.dart';
import 'package:pulse/features/living_tools/domain/repositories/bill_repository.dart';
import 'package:pulse/features/living_tools/domain/usecases/get_bills.dart';

class MockBillRepository extends Mock implements BillRepository {}

void main() {
  late GetBills usecase;
  late MockBillRepository mockRepository;

  setUp(() {
    mockRepository = MockBillRepository();
    usecase = GetBills(mockRepository);
  });

  const tBillMember = BillMember(
    id: 'member-1',
    userId: 'user-1',
    userName: 'John Doe',
    share: 50.0,
    hasPaid: false,
  );

  const tChatRoomIds = ['chat-1', 'chat-2'];

  final tBill = Bill(
    id: 'bill-1',
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

  final tBills = [tBill];

  test('should return list of Bills when successful', () async {
    // arrange
    when(() => mockRepository.getBills(tChatRoomIds))
        .thenAnswer((_) async => Right(tBills));

    // act
    final result = await usecase(const GetBillsParams(chatRoomIds: tChatRoomIds));

    // assert
    expect(result.isRight(), true);
    result.fold(
      (l) => fail('Should be Right'),
      (r) {
        expect(r.length, 1);
        expect(r.first.id, 'bill-1');
        expect(r.first.title, 'Electric Bill');
        expect(r.first.amount, 100.0);
      },
    );
    verify(() => mockRepository.getBills(tChatRoomIds)).called(1);
  });

  test('should return ServerFailure when repository fails', () async {
    // arrange
    when(() => mockRepository.getBills(tChatRoomIds))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to get bills')));

    // act
    final result = await usecase(const GetBillsParams(chatRoomIds: tChatRoomIds));

    // assert
    expect(result, const Left(ServerFailure(message: 'Failed to get bills')));
    verify(() => mockRepository.getBills(tChatRoomIds)).called(1);
  });

  test('should return NetworkFailure when there is no internet', () async {
    // arrange
    when(() => mockRepository.getBills(tChatRoomIds))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    // act
    final result = await usecase(const GetBillsParams(chatRoomIds: tChatRoomIds));

    // assert
    expect(result, const Left(NetworkFailure()));
    verify(() => mockRepository.getBills(tChatRoomIds)).called(1);
  });
}
