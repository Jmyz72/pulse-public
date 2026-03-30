import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/usecases/usecase.dart';
import 'package:pulse/features/living_tools/domain/entities/bill.dart';
import 'package:pulse/features/living_tools/domain/entities/bill_summary.dart';
import 'package:pulse/features/living_tools/domain/usecases/create_bill.dart';
import 'package:pulse/features/living_tools/domain/usecases/delete_bill.dart';
import 'package:pulse/features/living_tools/domain/usecases/get_bills.dart';
import 'package:pulse/features/living_tools/domain/usecases/get_bills_summary.dart';
import 'package:pulse/features/living_tools/domain/usecases/mark_bill_as_paid.dart';
import 'package:pulse/features/living_tools/domain/usecases/nudge_member.dart';
import 'package:pulse/features/living_tools/domain/usecases/update_bill.dart';
import 'package:pulse/features/living_tools/domain/usecases/watch_bills.dart';
import 'package:pulse/features/living_tools/presentation/bloc/living_tools_bloc.dart';

class MockGetBills extends Mock implements GetBills {}

class MockCreateBill extends Mock implements CreateBill {}

class MockDeleteBill extends Mock implements DeleteBill {}

class MockUpdateBill extends Mock implements UpdateBill {}

class MockMarkBillAsPaid extends Mock implements MarkBillAsPaid {}

class MockNudgeMember extends Mock implements NudgeMember {}

class MockWatchBills extends Mock implements WatchBills {}

class MockGetBillsSummary extends Mock implements GetBillsSummary {}

void main() {
  late LivingToolsBloc bloc;
  late MockGetBills mockGetBills;
  late MockCreateBill mockCreateBill;
  late MockDeleteBill mockDeleteBill;
  late MockUpdateBill mockUpdateBill;
  late MockMarkBillAsPaid mockMarkBillAsPaid;
  late MockNudgeMember mockNudgeMember;
  late MockWatchBills mockWatchBills;
  late MockGetBillsSummary mockGetBillsSummary;

  setUp(() {
    mockGetBills = MockGetBills();
    mockCreateBill = MockCreateBill();
    mockDeleteBill = MockDeleteBill();
    mockUpdateBill = MockUpdateBill();
    mockMarkBillAsPaid = MockMarkBillAsPaid();
    mockNudgeMember = MockNudgeMember();
    mockWatchBills = MockWatchBills();
    mockGetBillsSummary = MockGetBillsSummary();
    when(() => mockWatchBills(any())).thenAnswer((_) => const Stream.empty());

    bloc = LivingToolsBloc(
      getBills: mockGetBills,
      watchBills: mockWatchBills,
      createBill: mockCreateBill,
      deleteBill: mockDeleteBill,
      updateBill: mockUpdateBill,
      markBillAsPaid: mockMarkBillAsPaid,
      nudgeMember: mockNudgeMember,
      getBillsSummary: mockGetBillsSummary,
    );
  });

  tearDown(() {
    bloc.close();
  });

  const tUserId = 'user-1';
  const tChatRoomIds = ['chat-1', 'chat-2'];

  const tBillMember = BillMember(
    id: 'member-1',
    userId: 'user-1',
    userName: 'John Doe',
    share: 50.0,
    hasPaid: false,
  );

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

  const tBillSummary = BillSummary(
    totalOwed: 500.0,
    totalPaid: 300.0,
    yourOwed: 150.0,
    yourPaid: 100.0,
    pendingCount: 3,
    overdueCount: 1,
    paidCount: 2,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const GetBillsParams(chatRoomIds: ['chat-1']));
    registerFallbackValue(CreateBillParams(bill: tBill));
    registerFallbackValue(const DeleteBillParams(id: 'bill-1'));
    registerFallbackValue(
      const MarkBillAsPaidParams(billId: 'bill-1', memberId: 'member-1'),
    );
    registerFallbackValue(
      const GetBillsSummaryParams(userId: tUserId, chatRoomIds: tChatRoomIds),
    );
  });

  group('LivingToolsLoadRequested', () {
    blocTest<LivingToolsBloc, LivingToolsState>(
      'emits [loading, loaded] when GetBills and GetBillsSummary return successfully',
      build: () {
        when(() => mockGetBills(any())).thenAnswer((_) async => Right(tBills));
        when(
          () => mockGetBillsSummary(any()),
        ).thenAnswer((_) async => const Right(tBillSummary));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const LivingToolsLoadRequested(
          userId: tUserId,
          chatRoomIds: tChatRoomIds,
        ),
      ),
      expect: () => [
        const LivingToolsState(status: LivingToolsStatus.loading),
        LivingToolsState(
          status: LivingToolsStatus.loaded,
          bills: tBills,
          summary: tBillSummary,
        ),
      ],
      verify: (_) {
        verify(() => mockGetBills(any())).called(1);
        verify(() => mockGetBillsSummary(any())).called(1);
      },
    );

    blocTest<LivingToolsBloc, LivingToolsState>(
      'emits [loading, loaded] with bills only when summary fails',
      build: () {
        when(() => mockGetBills(any())).thenAnswer((_) async => Right(tBills));
        when(() => mockGetBillsSummary(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Summary error')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(
        const LivingToolsLoadRequested(
          userId: tUserId,
          chatRoomIds: tChatRoomIds,
        ),
      ),
      expect: () => [
        const LivingToolsState(status: LivingToolsStatus.loading),
        LivingToolsState(status: LivingToolsStatus.loaded, bills: tBills),
      ],
    );

    blocTest<LivingToolsBloc, LivingToolsState>(
      'emits [loading, error] when GetBills fails',
      build: () {
        when(() => mockGetBills(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Server error')),
        );
        when(
          () => mockGetBillsSummary(any()),
        ).thenAnswer((_) async => const Right(tBillSummary));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const LivingToolsLoadRequested(
          userId: tUserId,
          chatRoomIds: tChatRoomIds,
        ),
      ),
      expect: () => [
        const LivingToolsState(status: LivingToolsStatus.loading),
        const LivingToolsState(
          status: LivingToolsStatus.error,
          errorMessage: 'Server error',
        ),
      ],
    );

    blocTest<LivingToolsBloc, LivingToolsState>(
      'emits [loading, error] when network failure occurs',
      build: () {
        when(
          () => mockGetBills(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        when(
          () => mockGetBillsSummary(any()),
        ).thenAnswer((_) async => const Right(tBillSummary));
        return bloc;
      },
      act: (bloc) => bloc.add(
        const LivingToolsLoadRequested(
          userId: tUserId,
          chatRoomIds: tChatRoomIds,
        ),
      ),
      expect: () => [
        const LivingToolsState(status: LivingToolsStatus.loading),
        const LivingToolsState(
          status: LivingToolsStatus.error,
          errorMessage: 'No internet connection',
        ),
      ],
    );
  });

  group('LivingToolsBillCreated', () {
    blocTest<LivingToolsBloc, LivingToolsState>(
      'emits [loaded with new bill] when CreateBill succeeds',
      build: () {
        when(() => mockCreateBill(any())).thenAnswer((_) async => Right(tBill));
        return bloc;
      },
      act: (bloc) => bloc.add(LivingToolsBillCreated(bill: tBill)),
      expect: () => [
        LivingToolsState(status: LivingToolsStatus.loaded, bills: [tBill]),
      ],
      verify: (_) {
        verify(() => mockCreateBill(any())).called(1);
      },
    );

    blocTest<LivingToolsBloc, LivingToolsState>(
      'emits [error] when CreateBill fails',
      build: () {
        when(() => mockCreateBill(any())).thenAnswer(
          (_) async =>
              const Left(ServerFailure(message: 'Failed to create bill')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(LivingToolsBillCreated(bill: tBill)),
      expect: () => [
        const LivingToolsState(
          status: LivingToolsStatus.error,
          errorMessage: 'Failed to create bill',
        ),
      ],
    );

    blocTest<LivingToolsBloc, LivingToolsState>(
      'emits [error] when network failure occurs during creation',
      build: () {
        when(
          () => mockCreateBill(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      act: (bloc) => bloc.add(LivingToolsBillCreated(bill: tBill)),
      expect: () => [
        const LivingToolsState(
          status: LivingToolsStatus.error,
          errorMessage: 'No internet connection',
        ),
      ],
    );
  });

  group('LivingToolsBillDeleted', () {
    blocTest<LivingToolsBloc, LivingToolsState>(
      'emits [loaded without deleted bill] when DeleteBill succeeds',
      build: () {
        when(
          () => mockDeleteBill(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () =>
          LivingToolsState(status: LivingToolsStatus.loaded, bills: tBills),
      act: (bloc) => bloc.add(const LivingToolsBillDeleted(billId: 'bill-1')),
      expect: () => [
        const LivingToolsState(status: LivingToolsStatus.loaded, bills: []),
      ],
      verify: (_) {
        verify(() => mockDeleteBill(any())).called(1);
      },
    );

    blocTest<LivingToolsBloc, LivingToolsState>(
      'emits [error] when DeleteBill fails',
      build: () {
        when(() => mockDeleteBill(any())).thenAnswer(
          (_) async =>
              const Left(ServerFailure(message: 'Failed to delete bill')),
        );
        return bloc;
      },
      seed: () =>
          LivingToolsState(status: LivingToolsStatus.loaded, bills: tBills),
      act: (bloc) => bloc.add(const LivingToolsBillDeleted(billId: 'bill-1')),
      expect: () => [
        LivingToolsState(
          status: LivingToolsStatus.error,
          bills: tBills,
          errorMessage: 'Failed to delete bill',
        ),
      ],
    );

    blocTest<LivingToolsBloc, LivingToolsState>(
      'emits [error] when network failure occurs during deletion',
      build: () {
        when(
          () => mockDeleteBill(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      seed: () =>
          LivingToolsState(status: LivingToolsStatus.loaded, bills: tBills),
      act: (bloc) => bloc.add(const LivingToolsBillDeleted(billId: 'bill-1')),
      expect: () => [
        LivingToolsState(
          status: LivingToolsStatus.error,
          bills: tBills,
          errorMessage: 'No internet connection',
        ),
      ],
    );
  });

  group('LivingToolsBillMarkedAsPaid', () {
    blocTest<LivingToolsBloc, LivingToolsState>(
      'emits [loaded with updated bill] when MarkBillAsPaid succeeds',
      build: () {
        when(
          () => mockMarkBillAsPaid(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () =>
          LivingToolsState(status: LivingToolsStatus.loaded, bills: tBills),
      act: (bloc) => bloc.add(
        const LivingToolsBillMarkedAsPaid(
          billId: 'bill-1',
          memberId: 'member-1',
        ),
      ),
      expect: () => [
        isA<LivingToolsState>()
            .having((s) => s.status, 'status', LivingToolsStatus.loaded)
            .having(
              (s) => s.bills.first.members.first.hasPaid,
              'hasPaid',
              true,
            ),
      ],
      verify: (_) {
        verify(() => mockMarkBillAsPaid(any())).called(1);
      },
    );

    blocTest<LivingToolsBloc, LivingToolsState>(
      'emits [error] when MarkBillAsPaid fails',
      build: () {
        when(() => mockMarkBillAsPaid(any())).thenAnswer(
          (_) async =>
              const Left(ServerFailure(message: 'Failed to mark as paid')),
        );
        return bloc;
      },
      seed: () =>
          LivingToolsState(status: LivingToolsStatus.loaded, bills: tBills),
      act: (bloc) => bloc.add(
        const LivingToolsBillMarkedAsPaid(
          billId: 'bill-1',
          memberId: 'member-1',
        ),
      ),
      expect: () => [
        LivingToolsState(
          status: LivingToolsStatus.error,
          bills: tBills,
          errorMessage: 'Failed to mark as paid',
        ),
      ],
    );

    blocTest<LivingToolsBloc, LivingToolsState>(
      'emits [error] when network failure occurs',
      build: () {
        when(
          () => mockMarkBillAsPaid(any()),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      seed: () =>
          LivingToolsState(status: LivingToolsStatus.loaded, bills: tBills),
      act: (bloc) => bloc.add(
        const LivingToolsBillMarkedAsPaid(
          billId: 'bill-1',
          memberId: 'member-1',
        ),
      ),
      expect: () => [
        LivingToolsState(
          status: LivingToolsStatus.error,
          bills: tBills,
          errorMessage: 'No internet connection',
        ),
      ],
    );

    blocTest<LivingToolsBloc, LivingToolsState>(
      'updates bill status to paid when all members have paid',
      build: () {
        when(
          () => mockMarkBillAsPaid(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () =>
          LivingToolsState(status: LivingToolsStatus.loaded, bills: tBills),
      act: (bloc) => bloc.add(
        const LivingToolsBillMarkedAsPaid(
          billId: 'bill-1',
          memberId: 'member-1',
        ),
      ),
      expect: () => [
        isA<LivingToolsState>()
            .having((s) => s.status, 'status', LivingToolsStatus.loaded)
            .having(
              (s) => s.bills.first.status,
              'bill status',
              BillStatus.paid,
            ),
      ],
    );
  });

  group('LivingToolsTabChanged', () {
    blocTest<LivingToolsBloc, LivingToolsState>(
      'emits state with updated selectedTab',
      build: () => bloc,
      act: (bloc) => bloc.add(const LivingToolsTabChanged(tabIndex: 1)),
      expect: () => [const LivingToolsState(selectedTab: 1)],
    );

    blocTest<LivingToolsBloc, LivingToolsState>(
      'emits state with selectedTab 2 for paid bills tab',
      build: () => bloc,
      act: (bloc) => bloc.add(const LivingToolsTabChanged(tabIndex: 2)),
      expect: () => [const LivingToolsState(selectedTab: 2)],
    );

    blocTest<LivingToolsBloc, LivingToolsState>(
      'emits state with selectedTab 0 when switching back to all bills',
      build: () => bloc,
      seed: () => const LivingToolsState(selectedTab: 2),
      act: (bloc) => bloc.add(const LivingToolsTabChanged(tabIndex: 0)),
      expect: () => [const LivingToolsState(selectedTab: 0)],
    );
  });
}
