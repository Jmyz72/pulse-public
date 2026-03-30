# Testing Guide for Pulse

This guide covers testing strategies, patterns, and best practices for the Pulse Flutter app.

## Table of Contents

- [Overview](#overview)
- [Testing Strategy](#testing-strategy)
- [Test Structure](#test-structure)
- [Running Tests](#running-tests)
- [Testing Patterns by Layer](#testing-patterns-by-layer)
- [Test Examples](#test-examples)
- [Mocking Strategies](#mocking-strategies)
- [Naming Conventions](#naming-conventions)
- [Best Practices](#best-practices)
- [Common Pitfalls](#common-pitfalls)

## Overview

Pulse follows a comprehensive testing strategy that ensures code quality and reliability across all layers of the Clean Architecture implementation.

### Test Coverage

The project includes:
- **Unit Tests**: Business logic in UseCases, Repositories, and DataSources
- **BLoC Tests**: State management logic in BLoCs
- **Model Tests**: Data transformation and serialization
- **Entity Tests**: Domain object behavior
- **Widget Tests**: UI component behavior (future work)
- **Integration Tests**: End-to-end workflows (future work)

### Testing Tools

- **flutter_test**: Flutter's testing framework
- **mocktail**: Modern mocking library for Dart
- **bloc_test**: Specialized testing for BLoC pattern
- **dartz**: Functional programming for Either types

## Testing Strategy

### Test Pyramid

```
        /\
       /  \      Integration Tests (Few)
      /____\
     /      \    Widget Tests (Some)
    /________\
   /          \  Unit Tests (Many)
  /__________\
```

### Layer-Specific Testing

1. **Domain Layer**
   - Test UseCases with mocked repositories
   - Verify business logic correctness
   - Test error handling (Left/Right from Either)
   - Validate parameter classes

2. **Data Layer**
   - Test Repository implementations with mocked data sources
   - Test network connectivity handling
   - Test data model serialization (toJson/fromJson)
   - Test entity conversion (fromEntity/toEntity)

3. **Presentation Layer**
   - Test BLoC event handling
   - Test state transitions
   - Verify side effects (use case calls)
   - Test error state handling

## Test Structure

### Directory Organization

```
test/
└── features/
    └── {feature}/
        ├── data/
        │   ├── datasources/
        │   │   └── {feature}_remote_datasource_test.dart
        │   ├── models/
        │   │   └── {feature}_model_test.dart
        │   └── repositories/
        │       └── {feature}_repository_impl_test.dart
        ├── domain/
        │   ├── entities/
        │   │   └── {entity}_test.dart
        │   └── usecases/
        │       └── {usecase}_test.dart
        └── presentation/
            └── bloc/
                └── {feature}_bloc_test.dart
```

### Test File Naming

- Test files end with `_test.dart`
- Mirror the structure of the `lib/` directory
- Use descriptive names matching the file being tested

## Running Tests

### Basic Commands

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/auth/domain/usecases/login_test.dart

# Run tests with coverage
flutter test --coverage

# Run tests in a specific directory
flutter test test/features/expense/

# Run tests matching a pattern
flutter test --name="should return User when login is successful"

# Run tests with verbose output
flutter test --verbose

# Run tests and watch for changes
flutter test --watch
```

### Coverage Report

```bash
# Generate coverage report
flutter test --coverage

# View coverage in browser (requires lcov)
# macOS: brew install lcov
# Linux: sudo apt-get install lcov
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Running Specific Test Suites

```bash
# Run only UseCase tests
flutter test test/features/*/domain/usecases/

# Run only BLoC tests
flutter test test/features/*/presentation/bloc/

# Run only Repository tests
flutter test test/features/*/data/repositories/
```

## Testing Patterns by Layer

### Domain Layer: UseCase Tests

UseCases contain business logic and should be tested with mocked repositories.

**Pattern Structure:**
1. Create mock repository
2. Set up test data
3. Stub repository methods
4. Call use case
5. Verify result
6. Verify repository interactions

**Example Template:**

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';

class MockRepository extends Mock implements YourRepository {}

void main() {
  late YourUseCase usecase;
  late MockRepository mockRepository;

  setUp(() {
    mockRepository = MockRepository();
    usecase = YourUseCase(mockRepository);
  });

  // Test data
  const tInput = 'test-input';
  const tOutput = YourEntity(/* ... */);

  test('should return entity when repository call is successful', () async {
    // arrange
    when(() => mockRepository.someMethod(tInput))
        .thenAnswer((_) async => const Right(tOutput));

    // act
    final result = await usecase(const YourParams(input: tInput));

    // assert
    expect(result, const Right(tOutput));
    verify(() => mockRepository.someMethod(tInput)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return Failure when repository call fails', () async {
    // arrange
    when(() => mockRepository.someMethod(tInput))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));

    // act
    final result = await usecase(const YourParams(input: tInput));

    // assert
    expect(result, const Left(ServerFailure(message: 'Error')));
    verify(() => mockRepository.someMethod(tInput)).called(1);
  });
}
```

### Data Layer: Repository Tests

Repositories coordinate between data sources and handle network connectivity.

**Pattern Structure:**
1. Mock data sources and network info
2. Set up test data (models)
3. Test online/offline scenarios separately
4. Verify exception handling
5. Test data transformation

**Example Template:**

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/exceptions.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/core/network/network_info.dart';

class MockRemoteDataSource extends Mock implements YourRemoteDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late YourRepositoryImpl repository;
  late MockRemoteDataSource mockRemoteDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockRemoteDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = YourRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  final tModel = YourModel(/* ... */);

  void runTestsOnline(Function body) {
    group('device is online', () {
      setUp(() {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      });
      body();
    });
  }

  void runTestsOffline(Function body) {
    group('device is offline', () {
      setUp(() {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      });
      body();
    });
  }

  group('yourMethod', () {
    runTestsOnline(() {
      test('should return data when call is successful', () async {
        // arrange
        when(() => mockRemoteDataSource.yourMethod())
            .thenAnswer((_) async => tModel);

        // act
        final result = await repository.yourMethod();

        // assert
        expect(result.isRight(), true);
        verify(() => mockRemoteDataSource.yourMethod()).called(1);
      });

      test('should return ServerFailure when ServerException is thrown', () async {
        // arrange
        when(() => mockRemoteDataSource.yourMethod())
            .thenThrow(const ServerException(message: 'Server error'));

        // act
        final result = await repository.yourMethod();

        // assert
        expect(result, const Left(ServerFailure(message: 'Server error')));
      });
    });

    runTestsOffline(() {
      test('should return NetworkFailure when offline', () async {
        // act
        final result = await repository.yourMethod();

        // assert
        expect(result, const Left(NetworkFailure()));
        verifyNever(() => mockRemoteDataSource.yourMethod());
      });
    });
  });
}
```

### Data Layer: Model Tests

Models handle JSON serialization and entity conversion.

**Test Coverage:**
- Constructor with all fields
- Constructor with default values
- fromJson with complete data
- fromJson with missing fields
- fromJson with type conversion (int to double, etc.)
- toJson serialization
- fromEntity conversion
- Round-trip conversion (entity -> model -> json -> model)

**Example Template:**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/your_feature/data/models/your_model.dart';
import 'package:pulse/features/your_feature/domain/entities/your_entity.dart';

void main() {
  group('YourModel', () {
    final tDate = DateTime(2024, 1, 15);

    final tModel = YourModel(
      id: 'id-1',
      name: 'Test',
      amount: 100.0,
      date: tDate,
    );

    group('constructor', () {
      test('should create model with all fields', () {
        expect(tModel.id, 'id-1');
        expect(tModel.name, 'Test');
        expect(tModel.amount, 100.0);
        expect(tModel.date, tDate);
      });

      test('should be a subclass of Entity', () {
        expect(tModel, isA<YourEntity>());
      });
    });

    group('fromJson', () {
      test('should return valid model when JSON has all fields', () {
        final json = {
          'id': 'id-1',
          'name': 'Test',
          'amount': 100.0,
          'date': '2024-01-15T00:00:00.000',
        };

        final result = YourModel.fromJson(json);

        expect(result.id, 'id-1');
        expect(result.name, 'Test');
        expect(result.amount, 100.0);
      });

      test('should convert integer amount to double', () {
        final json = {
          'id': 'id-1',
          'name': 'Test',
          'amount': 100,
          'date': '2024-01-15T00:00:00.000',
        };

        final result = YourModel.fromJson(json);

        expect(result.amount, 100.0);
        expect(result.amount, isA<double>());
      });
    });

    group('toJson', () {
      test('should return JSON map with all fields', () {
        final result = tModel.toJson();

        expect(result['id'], 'id-1');
        expect(result['name'], 'Test');
        expect(result['amount'], 100.0);
        expect(result['date'], tDate.toIso8601String());
      });
    });

    group('fromEntity', () {
      test('should create model from entity', () {
        final entity = YourEntity(
          id: 'id-1',
          name: 'Test',
          amount: 100.0,
          date: tDate,
        );

        final result = YourModel.fromEntity(entity);

        expect(result.id, entity.id);
        expect(result.name, entity.name);
        expect(result.amount, entity.amount);
      });
    });

    group('round-trip conversion', () {
      test('should preserve data through toJson -> fromJson', () {
        final json = tModel.toJson();
        final result = YourModel.fromJson(json);

        expect(result.id, tModel.id);
        expect(result.name, tModel.name);
        expect(result.amount, tModel.amount);
      });
    });
  });
}
```

### Presentation Layer: BLoC Tests

BLoC tests verify state transitions and side effects.

**Pattern Structure:**
1. Mock all use cases
2. Set up fallback values for parameters
3. Test each event separately
4. Verify state emissions
5. Verify use case calls
6. Test error scenarios

**Example Template:**

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';

class MockYourUseCase extends Mock implements YourUseCase {}

void main() {
  late YourBloc bloc;
  late MockYourUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockYourUseCase();
    bloc = YourBloc(yourUseCase: mockUseCase);
  });

  tearDown(() {
    bloc.close();
  });

  const tData = YourEntity(/* ... */);

  setUpAll(() {
    registerFallbackValue(const YourParams(/* ... */));
  });

  group('YourEventName', () {
    blocTest<YourBloc, YourState>(
      'emits [loading, loaded] when use case succeeds',
      build: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => const Right(tData));
        return bloc;
      },
      act: (bloc) => bloc.add(const YourEventName(/* ... */)),
      expect: () => [
        const YourState(status: YourStatus.loading),
        const YourState(status: YourStatus.loaded, data: tData),
      ],
      verify: (_) {
        verify(() => mockUseCase(any())).called(1);
      },
    );

    blocTest<YourBloc, YourState>(
      'emits [loading, error] when use case fails',
      build: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const YourEventName(/* ... */)),
      expect: () => [
        const YourState(status: YourStatus.loading),
        const YourState(status: YourStatus.error, errorMessage: 'Error'),
      ],
    );

    blocTest<YourBloc, YourState>(
      'emits correct state when starting from specific state',
      build: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => const Right(tData));
        return bloc;
      },
      seed: () => const YourState(status: YourStatus.loaded, data: initialData),
      act: (bloc) => bloc.add(const YourEventName(/* ... */)),
      expect: () => [
        const YourState(status: YourStatus.loading, data: initialData),
        const YourState(status: YourStatus.loaded, data: tData),
      ],
    );
  });
}
```

## Test Examples

### Example 1: UseCase Test (Login)

From `/Users/jimmyhew/Documents/pulse/test/features/auth/domain/usecases/login_test.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/error/failures.dart';
import 'package:pulse/features/auth/domain/entities/user.dart';
import 'package:pulse/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse/features/auth/domain/usecases/login.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late Login usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = Login(mockAuthRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tUser = User(
    id: '1',
    username: 'testuser',
    displayName: 'Test User',
    email: tEmail,
    phone: '',
  );

  test('should return User when login is successful', () async {
    // arrange
    when(() => mockAuthRepository.signInWithEmail(tEmail, tPassword))
        .thenAnswer((_) async => const Right(tUser));

    // act
    final result = await usecase(const LoginParams(email: tEmail, password: tPassword));

    // assert
    expect(result, const Right(tUser));
    verify(() => mockAuthRepository.signInWithEmail(tEmail, tPassword)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return AuthFailure when login fails', () async {
    // arrange
    when(() => mockAuthRepository.signInWithEmail(tEmail, tPassword))
        .thenAnswer((_) async => const Left(AuthFailure(message: 'Invalid credentials')));

    // act
    final result = await usecase(const LoginParams(email: tEmail, password: tPassword));

    // assert
    expect(result, const Left(AuthFailure(message: 'Invalid credentials')));
    verify(() => mockAuthRepository.signInWithEmail(tEmail, tPassword)).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });
}
```

**Key Points:**
- Uses `mocktail` for mocking
- Tests both success and failure paths
- Uses `dartz` Either type for error handling
- Verifies repository interactions

### Example 2: Repository Test (Expense)

From `/Users/jimmyhew/Documents/pulse/test/features/expense/data/repositories/expense_repository_impl_test.dart`:

```dart
void runTestsOnline(Function body) {
  group('device is online', () {
    setUp(() {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    });
    body();
  });
}

void runTestsOffline(Function body) {
  group('device is offline', () {
    setUp(() {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
    });
  });
  body();
}

group('getExpenses', () {
  runTestsOnline(() {
    test('should return list of expenses when call is successful', () async {
      // arrange
      when(() => mockRemoteDataSource.getExpenses(tChatRoomIds))
          .thenAnswer((_) async => [tExpenseModel, tExpenseModel2]);

      // act
      final result = await repository.getExpenses(tChatRoomIds);

      // assert
      expect(result.isRight(), true);
      verify(() => mockRemoteDataSource.getExpenses(tChatRoomIds)).called(1);
    });
  });

  runTestsOffline(() {
    test('should return NetworkFailure when offline', () async {
      // act
      final result = await repository.getExpenses(tChatRoomIds);

      // assert
      expect(result, const Left(NetworkFailure()));
      verifyNever(() => mockRemoteDataSource.getExpenses(any()));
    });
  });
});
```

**Key Points:**
- Helper functions for online/offline scenarios
- Tests network connectivity handling
- Verifies data source is not called when offline

### Example 3: BLoC Test (Auth)

From `/Users/jimmyhew/Documents/pulse/test/features/auth/presentation/bloc/auth_bloc_test.dart`:

```dart
group('AuthLoginRequested', () {
  blocTest<AuthBloc, AuthState>(
    'emits [loading, authenticated] when login succeeds',
    build: () {
      when(() => mockLogin(any()))
          .thenAnswer((_) async => const Right(tUser));
      return bloc;
    },
    act: (bloc) => bloc.add(const AuthLoginRequested(email: tEmail, password: tPassword)),
    expect: () => [
      const AuthState(status: AuthStatus.loading),
      const AuthState(status: AuthStatus.authenticated, user: tUser),
    ],
    verify: (_) {
      verify(() => mockLogin(any())).called(1);
    },
  );

  blocTest<AuthBloc, AuthState>(
    'emits [loading, error] when login fails with invalid credentials',
    build: () {
      when(() => mockLogin(any()))
          .thenAnswer((_) async => const Left(AuthFailure(message: 'Invalid credentials')));
      return bloc;
    },
    act: (bloc) => bloc.add(const AuthLoginRequested(email: tEmail, password: tPassword)),
    expect: () => [
      const AuthState(status: AuthStatus.loading),
      const AuthState(status: AuthStatus.error, errorMessage: 'Invalid credentials'),
    ],
  );
});
```

**Key Points:**
- Uses `bloc_test` package
- Tests state emission sequence
- Verifies use case interactions
- Tests different failure scenarios

## Mocking Strategies

### Creating Mocks

Use `mocktail` for creating test doubles:

```dart
import 'package:mocktail/mocktail.dart';

// Create mock class
class MockYourRepository extends Mock implements YourRepository {}

// In test
late MockYourRepository mockRepository;

setUp(() {
  mockRepository = MockYourRepository();
});
```

### Stubbing Methods

```dart
// Simple return value
when(() => mockRepository.getData()).thenReturn(data);

// Async return value
when(() => mockRepository.getData()).thenAnswer((_) async => data);

// Throw exception
when(() => mockRepository.getData()).thenThrow(Exception('Error'));

// Different returns on consecutive calls
when(() => mockRepository.getData())
    .thenAnswer((_) async => data1)
    .thenAnswer((_) async => data2);
```

### Verifying Calls

```dart
// Verify method was called once
verify(() => mockRepository.getData()).called(1);

// Verify method was never called
verifyNever(() => mockRepository.getData());

// Verify no other interactions
verifyNoMoreInteractions(mockRepository);

// Verify call order
verifyInOrder([
  () => mockRepository.getData(),
  () => mockRepository.saveData(any()),
]);
```

### Registering Fallback Values

For parameter objects, register fallback values:

```dart
setUpAll(() {
  registerFallbackValue(const LoginParams(email: '', password: ''));
  registerFallbackValue(const NoParams());
});
```

This allows using `any()` matcher in stubs and verifications.

## Naming Conventions

### Test Names

Use descriptive test names that explain the behavior:

```dart
// Good
test('should return User when login is successful', () {});
test('should return AuthFailure when credentials are invalid', () {});
test('should emit [loading, loaded] when data fetch succeeds', () {});

// Bad
test('test login', () {});
test('success case', () {});
test('test1', () {});
```

### Group Names

Organize tests with descriptive group names:

```dart
group('Login UseCase', () {
  group('successful login', () {});
  group('failed login', () {});
});

group('ExpenseRepository', () {
  group('getExpenses', () {
    group('device is online', () {});
    group('device is offline', () {});
  });
});
```

### Variable Naming

Use consistent prefixes for test data:

```dart
// Use 't' prefix for test data
const tEmail = 'test@example.com';
const tPassword = 'password123';
final tUser = User(/* ... */);
final tExpense = Expense(/* ... */);

// Use 'mock' prefix for mocks
late MockAuthRepository mockAuthRepository;
late MockExpenseDataSource mockExpenseDataSource;
```

## Best Practices

### 1. Follow AAA Pattern

Structure tests with Arrange-Act-Assert:

```dart
test('description', () async {
  // Arrange: Set up test data and stubs
  when(() => mockRepository.getData())
      .thenAnswer((_) async => testData);

  // Act: Execute the code under test
  final result = await usecase(params);

  // Assert: Verify the outcome
  expect(result, expectedResult);
  verify(() => mockRepository.getData()).called(1);
});
```

### 2. One Assertion Per Test

Keep tests focused on a single behavior:

```dart
// Good
test('should return User when successful', () {
  // Single assertion about the success case
});

test('should call repository once', () {
  // Single assertion about repository interaction
});

// Bad
test('should work correctly', () {
  // Multiple unrelated assertions
});
```

### 3. Use setUp and tearDown

Initialize and clean up in lifecycle methods:

```dart
setUp(() {
  mockRepository = MockRepository();
  usecase = UseCase(mockRepository);
});

tearDown(() {
  // Clean up if needed
  bloc?.close();
});
```

### 4. Test Error Cases

Always test failure scenarios:

```dart
test('success case', () {});
test('should return Failure when error occurs', () {});
test('should return NetworkFailure when offline', () {});
test('should handle null data gracefully', () {});
```

### 5. Use const Where Possible

Make test data immutable:

```dart
const tUser = User(
  id: '1',
  name: 'Test',
  email: 'test@example.com',
);

// Not: final tUser = User(...);
```

### 6. Test State Properties

For BLoCs, test computed properties in state:

```dart
group('ExpenseState', () {
  test('totalExpenses calculates sum correctly', () {
    final state = ExpenseState(expenses: [expense1, expense2]);
    expect(state.totalExpenses, 250.0);
  });

  test('pendingExpenses filters correctly', () {
    final state = ExpenseState(expenses: [expense1, expense2]);
    expect(state.pendingExpenses.length, 1);
  });
});
```

### 7. Test Edge Cases

Consider boundary conditions:

```dart
test('should handle empty list', () {});
test('should handle null values', () {});
test('should handle very large numbers', () {});
test('should handle special characters in input', () {});
```

### 8. Keep Tests Fast

- Mock external dependencies
- Avoid real network calls
- Avoid file I/O
- Use synchronous operations where possible

### 9. Make Tests Independent

Each test should be able to run in isolation:

```dart
// Good: Each test sets up its own data
test('test 1', () {
  final data = TestData();
  // ...
});

test('test 2', () {
  final data = TestData();
  // ...
});

// Bad: Tests share mutable state
final sharedData = MutableData();

test('test 1', () {
  sharedData.modify();
});

test('test 2', () {
  // Depends on test 1 running first
});
```

### 10. Use Descriptive Matchers

Choose the most expressive matcher:

```dart
// Good
expect(result.isRight(), true);
expect(expenses, isEmpty);
expect(user, isA<User>());
expect(amount, greaterThan(0));

// Less clear
expect(result.isRight() == true, true);
expect(expenses.length == 0, true);
```

## Shimmer & Animation Testing

### Shimmer Skeleton Tests

When testing widgets that include shimmer skeleton loading (e.g., `HomeSkeleton`, `ProfileSkeleton`, `ChatSkeleton`), shimmer animations **never settle**. Using `pumpAndSettle()` will timeout.

```dart
// BAD: Will timeout because shimmer animations never settle
await tester.pumpAndSettle();

// GOOD: Pump a fixed duration to advance past animations
await tester.pump(const Duration(milliseconds: 500));
```

### StaggerAnimationMixin Tests

Widgets using `StaggerAnimationMixin` for entrance animations also require fixed-duration pumps:

```dart
// Pump enough time for stagger animations to complete
await tester.pump(const Duration(milliseconds: 500));
```

### BLoC Event Fallback Values

When testing BLoCs that use other BLoCs (e.g., ChatTab uses ChatBloc), register fallback values for all event types:

```dart
setUpAll(() {
  registerFallbackValue(FakeChatEvent());
  registerFallbackValue(FakeHomeEvent());
});
```

---

## Common Pitfalls

### 1. Not Using Fallback Values

```dart
// Error: Missing fallback value
test('test', () {
  when(() => mockUseCase(any())).thenAnswer(/* ... */);
  // Fails because 'any()' doesn't know what type to match
});

// Fix: Register fallback value
setUpAll(() {
  registerFallbackValue(const YourParams(/* ... */));
});
```

### 2. Forgetting to Close BLoCs

```dart
// Memory leak
test('test', () {
  final bloc = YourBloc();
  // Test...
  // BLoC not closed!
});

// Fix: Use tearDown
tearDown(() {
  bloc.close();
});
```

### 3. Mocking Concrete Classes

```dart
// Wrong: Trying to mock a concrete class
class MockExpense extends Mock implements Expense {} // Won't work well

// Right: Mock the repository interface
class MockExpenseRepository extends Mock implements ExpenseRepository {}
```

### 4. Not Testing Error States

```dart
// Incomplete testing
test('should return data when successful', () {});
// Missing: What happens when it fails?

// Complete testing
test('should return data when successful', () {});
test('should return Failure when error occurs', () {});
test('should return NetworkFailure when offline', () {});
```

### 5. Hardcoding Test Data in Tests

```dart
// Bad: Hard to maintain
test('test 1', () {
  final user = User(id: '1', name: 'Test', email: 'test@example.com');
});

test('test 2', () {
  final user = User(id: '1', name: 'Test', email: 'test@example.com');
});

// Good: Shared test data
const tUser = User(id: '1', name: 'Test', email: 'test@example.com');

test('test 1', () {
  // Use tUser
});

test('test 2', () {
  // Use tUser
});
```

### 6. Testing Implementation Details

```dart
// Bad: Testing internal state
test('should set _isLoading to true', () {
  // Accessing private members
});

// Good: Testing public behavior
test('should emit loading state', () {
  // Testing observable state
});
```

### 7. Async Test Without await

```dart
// Wrong: Test completes before async operation
test('async test', () {
  usecase.call(); // Returns Future, but not awaited
  expect(result, expected); // Runs before Future completes
});

// Right: Await async operations
test('async test', () async {
  await usecase.call();
  expect(result, expected);
});
```

### 8. Not Verifying Mock Interactions

```dart
// Incomplete: Doesn't verify the method was called
test('should call repository', () async {
  when(() => mockRepository.getData()).thenAnswer((_) async => data);
  await usecase.call();
  expect(result, expected);
  // Missing: verify() call
});

// Complete: Verifies interaction
test('should call repository', () async {
  when(() => mockRepository.getData()).thenAnswer((_) async => data);
  await usecase.call();
  expect(result, expected);
  verify(() => mockRepository.getData()).called(1);
});
```

### 9. Overly Complex Test Setup

```dart
// Bad: Too much setup obscures the test intent
test('complex test', () {
  // 50 lines of setup
  // 1 line of actual test
  // Hard to understand what's being tested
});

// Good: Extract setup to helper methods
void setupSuccessScenario() {
  // Setup code
}

test('success case', () {
  setupSuccessScenario();
  // Clear test logic
});
```

### 10. Testing Multiple Things at Once

```dart
// Bad: Tests multiple concerns
test('should login user and fetch profile and update settings', () {
  // Too much in one test
});

// Good: Separate tests for separate concerns
test('should login user', () {});
test('should fetch profile after login', () {});
test('should update settings', () {});
```

## Summary

Testing is a critical part of the Pulse development workflow. By following these patterns and best practices:

- **Write tests first** when adding new features (TDD)
- **Test all layers** of the Clean Architecture
- **Keep tests simple and focused** on single behaviors
- **Use descriptive names** for tests and test data
- **Mock external dependencies** to keep tests fast and isolated
- **Test both success and failure paths**
- **Verify mock interactions** to ensure correct behavior
- **Run tests frequently** during development
- **Maintain high test coverage** for confidence in refactoring

For more examples, explore the existing test files in the `/Users/jimmyhew/Documents/pulse/test/` directory.
