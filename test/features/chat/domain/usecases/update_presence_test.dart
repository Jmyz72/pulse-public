import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/chat/domain/repositories/presence_repository.dart';
import 'package:pulse/features/chat/domain/usecases/update_presence.dart';

class MockPresenceRepository extends Mock implements PresenceRepository {}

void main() {
  late UpdatePresence usecase;
  late MockPresenceRepository mockRepository;

  setUp(() {
    mockRepository = MockPresenceRepository();
    usecase = UpdatePresence(mockRepository);
  });

  const tUserId = 'user-123';

  test('updates presence with default lastSeen behavior', () async {
    when(
      () => mockRepository.updatePresence(tUserId, true),
    ).thenAnswer((_) async {});

    await usecase(tUserId, true);

    verify(() => mockRepository.updatePresence(tUserId, true)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('updates presence without touching lastSeen when disabled', () async {
    when(
      () =>
          mockRepository.updatePresence(tUserId, false, updateLastSeen: false),
    ).thenAnswer((_) async {});

    await usecase(tUserId, false, updateLastSeen: false);

    verify(
      () =>
          mockRepository.updatePresence(tUserId, false, updateLastSeen: false),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
