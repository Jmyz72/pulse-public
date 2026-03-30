import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/network/network_info.dart';

class MockInternetConnectionChecker extends Mock
    implements InternetConnectionChecker {}

void main() {
  late MockInternetConnectionChecker mockConnectionChecker;
  late NetworkInfoImpl networkInfo;
  late DateTime fakeNow;

  setUp(() {
    mockConnectionChecker = MockInternetConnectionChecker();
    fakeNow = DateTime(2026, 1, 1, 12);
    networkInfo = NetworkInfoImpl(
      mockConnectionChecker,
      now: () => fakeNow,
      checkTimeout: const Duration(milliseconds: 10),
    );
  });

  group('isConnected', () {
    test('returns true when checker reports connected', () async {
      when(
        () => mockConnectionChecker.hasConnection,
      ).thenAnswer((_) async => true);

      final result = await networkInfo.isConnected;

      expect(result, isTrue);
      verify(() => mockConnectionChecker.hasConnection).called(1);
    });

    test('returns false when checker reports disconnected', () async {
      when(
        () => mockConnectionChecker.hasConnection,
      ).thenAnswer((_) async => false);

      final result = await networkInfo.isConnected;

      expect(result, isFalse);
      verify(() => mockConnectionChecker.hasConnection).called(1);
    });

    test('returns false when checker throws', () async {
      when(
        () => mockConnectionChecker.hasConnection,
      ).thenThrow(Exception('boom'));

      final result = await networkInfo.isConnected;

      expect(result, isFalse);
      verify(() => mockConnectionChecker.hasConnection).called(1);
    });

    test('returns false when checker times out', () async {
      final completer = Completer<bool>();
      when(
        () => mockConnectionChecker.hasConnection,
      ).thenAnswer((_) => completer.future);

      final result = await networkInfo.isConnected;

      expect(result, isFalse);
      verify(() => mockConnectionChecker.hasConnection).called(1);
    });

    test('reuses a recent cached result', () async {
      when(
        () => mockConnectionChecker.hasConnection,
      ).thenAnswer((_) async => true);

      final first = await networkInfo.isConnected;
      final second = await networkInfo.isConnected;

      expect(first, isTrue);
      expect(second, isTrue);
      verify(() => mockConnectionChecker.hasConnection).called(1);
    });

    test('deduplicates concurrent checks', () async {
      final completer = Completer<bool>();
      when(
        () => mockConnectionChecker.hasConnection,
      ).thenAnswer((_) => completer.future);

      final first = networkInfo.isConnected;
      final second = networkInfo.isConnected;
      completer.complete(true);

      expect(await first, isTrue);
      expect(await second, isTrue);
      verify(() => mockConnectionChecker.hasConnection).called(1);
    });

    test('performs a fresh check after previous call completes', () async {
      networkInfo = NetworkInfoImpl(
        mockConnectionChecker,
        now: () => fakeNow,
        cacheTtl: Duration.zero,
        checkTimeout: const Duration(milliseconds: 10),
      );

      var callCount = 0;
      when(() => mockConnectionChecker.hasConnection).thenAnswer((_) async {
        callCount++;
        return callCount == 1;
      });

      final first = await networkInfo.isConnected;
      fakeNow = fakeNow.add(const Duration(milliseconds: 1));
      final second = await networkInfo.isConnected;

      expect(first, isTrue);
      expect(second, isFalse);
      verify(() => mockConnectionChecker.hasConnection).called(2);
    });

    test(
      'keeps last connected result during a transient checker error',
      () async {
        when(
          () => mockConnectionChecker.hasConnection,
        ).thenAnswer((_) async => true);

        expect(await networkInfo.isConnected, isTrue);
        verify(() => mockConnectionChecker.hasConnection).called(1);

        fakeNow = fakeNow.add(const Duration(seconds: 6));
        reset(mockConnectionChecker);
        when(
          () => mockConnectionChecker.hasConnection,
        ).thenThrow(Exception('temporary failure'));

        final result = await networkInfo.isConnected;

        expect(result, isTrue);
        verify(() => mockConnectionChecker.hasConnection).called(1);
      },
    );

    test('drops stale connected history after the grace period', () async {
      when(
        () => mockConnectionChecker.hasConnection,
      ).thenAnswer((_) async => true);

      expect(await networkInfo.isConnected, isTrue);
      verify(() => mockConnectionChecker.hasConnection).called(1);

      fakeNow = fakeNow.add(const Duration(seconds: 31));
      reset(mockConnectionChecker);
      when(
        () => mockConnectionChecker.hasConnection,
      ).thenThrow(Exception('temporary failure'));

      final result = await networkInfo.isConnected;

      expect(result, isFalse);
      verify(() => mockConnectionChecker.hasConnection).called(1);
    });
  });
}
