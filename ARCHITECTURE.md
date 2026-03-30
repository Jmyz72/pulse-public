# Architecture Documentation

This document provides a comprehensive overview of the Pulse app's architecture, design patterns, and implementation guidelines.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Clean Architecture Layers](#clean-architecture-layers)
3. [BLoC Pattern](#bloc-pattern)
4. [Dependency Injection](#dependency-injection)
5. [Error Handling](#error-handling)
6. [Data Flow](#data-flow)
7. [Testing Strategy](#testing-strategy)
8. [Design Patterns](#design-patterns)

---

## Architecture Overview

Pulse follows **Clean Architecture** principles combined with the **BLoC (Business Logic Component)** pattern for state management. This architecture ensures:

- **Separation of Concerns**: Each layer has a single, well-defined responsibility
- **Testability**: Pure business logic isolated from framework dependencies
- **Maintainability**: Changes in one layer don't cascade to others
- **Scalability**: Easy to add new features following established patterns
- **Independence**: Business logic is independent of UI, database, and external frameworks

### Key Principles

1. **Dependency Rule**: Source code dependencies point inward (toward business logic)
2. **Abstraction**: Inner layers define interfaces, outer layers implement them
3. **Pure Business Logic**: Domain layer has zero external dependencies
4. **Single Responsibility**: Each class/module has one reason to change

---

## Clean Architecture Layers

```
┌─────────────────────────────────────────────┐
│          Presentation Layer                  │
│  (UI, Widgets, BLoCs, Screens)              │
│  Dependencies: Domain only                   │
└─────────────┬───────────────────────────────┘
              │
              ↓
┌─────────────────────────────────────────────┐
│          Domain Layer                        │
│  (Entities, UseCases, Repository Contracts) │
│  Dependencies: None (Pure Dart)             │
└─────────────┬───────────────────────────────┘
              ↑
              │
┌─────────────┴───────────────────────────────┐
│          Data Layer                          │
│  (Models, DataSources, Repository Impls)    │
│  Dependencies: Domain                        │
└─────────────────────────────────────────────┘
```

### 1. Domain Layer (Innermost)

**Purpose**: Contains business logic and business entities.

**Location**: `lib/features/{feature}/domain/`

**Components**:

#### Entities (`domain/entities/`)
Pure Dart objects representing business concepts.

```dart
class Expense extends Equatable {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final List<ExpenseSplit> splits;

  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.splits,
  });

  @override
  List<Object?> get props => [id, title, amount, date, splits];
}
```

**Rules**:
- No Flutter dependencies
- No Firebase dependencies
- Extends `Equatable` for value equality
- Immutable (all fields final)
- Pure Dart classes only

#### Repository Contracts (`domain/repositories/`)
Abstract interfaces defining data operations.

```dart
abstract class ExpenseRepository {
  Future<Either<Failure, List<Expense>>> getExpenses(List<String> chatRoomIds);
  Future<Either<Failure, Expense>> getExpenseById(String id);
  Future<Either<Failure, void>> createExpense(Expense expense);
  Future<Either<Failure, void>> updateExpense(Expense expense);
  Future<Either<Failure, void>> deleteExpense(String id);
}
```

**Rules**:
- Return `Either<Failure, T>` for error handling
- No implementation details
- No Firebase/Flutter types

#### Use Cases (`domain/usecases/`)
Single-purpose business operations.

```dart
class GetExpenses implements UseCase<List<Expense>, GetExpensesParams> {
  final ExpenseRepository repository;

  GetExpenses(this.repository);

  @override
  Future<Either<Failure, List<Expense>>> call(GetExpensesParams params) {
    return repository.getExpenses(params.chatRoomIds);
  }
}

class GetExpensesParams extends Equatable {
  final List<String> chatRoomIds;

  const GetExpensesParams({required this.chatRoomIds});

  @override
  List<Object?> get props => [chatRoomIds];
}
```

**Rules**:
- One public method: `call()`
- Extends `UseCase<ReturnType, Params>`
- Parameters wrapped in Params class extending `Equatable`
- Use `NoParams` for parameterless use cases

---

### 2. Data Layer

**Purpose**: Implements domain contracts and handles external data sources.

**Location**: `lib/features/{feature}/data/`

**Components**:

#### Models (`data/models/`)
Data representations that extend domain entities.

```dart
class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.date,
    required super.splits,
  });

  // Convert from Firestore document
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      date: (json['date'] as Timestamp).toDate(),
      splits: (json['splits'] as List)
          .map((s) => ExpenseSplitModel.fromJson(s))
          .toList(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'splits': splits.map((s) => (s as ExpenseSplitModel).toJson()).toList(),
    };
  }
}
```

**Rules**:
- Extends corresponding entity
- Has `fromJson` and `toJson` methods
- Handles serialization/deserialization
- May contain Firebase-specific types (Timestamp, GeoPoint)

#### DataSources (`data/datasources/`)
Handle data retrieval/storage from external sources.

**Remote DataSource** (Firebase):
```dart
abstract class ExpenseRemoteDataSource {
  Future<List<ExpenseModel>> getExpenses(List<String> chatRoomIds);
  Future<ExpenseModel> getExpenseById(String id);
  Future<void> createExpense(ExpenseModel expense);
  Future<void> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(String id);
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final FirebaseFirestore firestore;

  ExpenseRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<ExpenseModel>> getExpenses(List<String> chatRoomIds) async {
    if (chatRoomIds.isEmpty) return [];

    final snapshot = await firestore
        .collection('expenses')
        .where('chatRoomId', whereIn: chatRoomIds)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ExpenseModel.fromJson(doc.data()))
        .toList();
  }

  // ... other methods
}
```

**Local DataSource** (SharedPreferences, Hive, etc.):
```dart
abstract class SettingsLocalDataSource {
  Future<SettingsModel?> getCachedSettings(String userId);
  Future<void> cacheSettings(SettingsModel settings);
  Future<void> clearCache();
}
```

**Rules**:
- Returns models, not entities
- Throws exceptions (handled by repository)
- Contains all Firebase/API logic
- May cache data locally

#### Repositories (`data/repositories/`)
Implement domain repository contracts.

```dart
class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ExpenseRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Expense>>> getExpenses(
    List<String> chatRoomIds,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure());
    }

    try {
      final expenses = await remoteDataSource.getExpenses(chatRoomIds);
      return Right(expenses);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.message ?? 'Firebase error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ... other methods
}
```

**Rules**:
- Implements domain repository interface
- Converts models to entities
- Converts exceptions to `Failure` types
- Returns `Either<Failure, T>`
- Checks network connectivity before remote calls

---

### 3. Presentation Layer

**Purpose**: Handles UI and user interaction.

**Location**: `lib/features/{feature}/presentation/`

**Components**:

#### BLoC (`presentation/bloc/`)
Manages feature state and business logic flow.

**Event** (User Actions):
```dart
abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();
}

class ExpenseLoadRequested extends ExpenseEvent {
  final List<String> chatRoomIds;

  const ExpenseLoadRequested({required this.chatRoomIds});

  @override
  List<Object> get props => [chatRoomIds];
}

class ExpenseCreateRequested extends ExpenseEvent {
  final Expense expense;

  const ExpenseCreateRequested({required this.expense});

  @override
  List<Object> get props => [expense];
}
```

**State** (UI State):
```dart
enum ExpenseLoadStatus { initial, loading, loaded, error }

class ExpenseState extends Equatable {
  final ExpenseLoadStatus status;
  final List<Expense> expenses;
  final String? errorMessage;

  const ExpenseState({
    this.status = ExpenseLoadStatus.initial,
    this.expenses = const [],
    this.errorMessage,
  });

  ExpenseState copyWith({
    ExpenseLoadStatus? status,
    List<Expense>? expenses,
    String? errorMessage,
  }) {
    return ExpenseState(
      status: status ?? this.status,
      expenses: expenses ?? this.expenses,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, expenses, errorMessage];
}
```

**BLoC** (Business Logic):
```dart
class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final GetExpenses getExpenses;
  final CreateExpense createExpense;

  ExpenseBloc({
    required this.getExpenses,
    required this.createExpense,
  }) : super(const ExpenseState()) {
    on<ExpenseLoadRequested>(_onLoadRequested);
    on<ExpenseCreateRequested>(
      _onCreateRequested,
      transformer: throttle(const Duration(milliseconds: 500)),
    );
  }

  Future<void> _onLoadRequested(
    ExpenseLoadRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseLoadStatus.loading));

    final result = await getExpenses(
      GetExpensesParams(chatRoomIds: event.chatRoomIds),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: ExpenseLoadStatus.error,
        errorMessage: _mapFailureToMessage(failure),
      )),
      (expenses) => emit(state.copyWith(
        status: ExpenseLoadStatus.loaded,
        expenses: expenses,
      )),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'No internet connection';
    } else if (failure is ServerFailure) {
      return failure.message;
    }
    return 'Unexpected error occurred';
  }
}
```

**Rules**:
- Events are user actions (e.g., button clicks, page loads)
- States represent UI state
- BLoC registers event handlers in constructor
- Use event transformers (throttle, debounce, droppable)
- Call use cases, never repositories directly
- Use `result.fold()` for Either handling

#### Screens (`presentation/screens/`)
Full-page UI components.

```dart
class ExpenseListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        if (state.status == ExpenseLoadStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == ExpenseLoadStatus.error) {
          return Center(child: Text(state.errorMessage ?? 'Error'));
        }

        return ListView.builder(
          itemCount: state.expenses.length,
          itemBuilder: (context, index) {
            return ExpenseCard(expense: state.expenses[index]);
          },
        );
      },
    );
  }
}
```

**Rules**:
- Use `BlocBuilder` for reactive UI updates
- Use `BlocListener` for side effects (navigation, dialogs)
- Use `BlocConsumer` for both
- Keep widgets small and focused
- Extract reusable widgets to separate files

#### Widgets (`presentation/widgets/`)
Reusable feature-specific UI components.

---

## BLoC Pattern

### Event Transformers

Control how events are processed:

```dart
// Throttle: Ignore events for a duration after processing one
on<ButtonClicked>(
  _onButtonClicked,
  transformer: throttle(const Duration(milliseconds: 500)),
);

// Debounce: Wait for user to stop before processing
on<SearchQueryChanged>(
  _onSearchQueryChanged,
  transformer: debounce(const Duration(milliseconds: 400)),
);

// Droppable: Ignore new events while processing
on<ApiCallRequested>(
  _onApiCallRequested,
  transformer: droppable(),
);

// Sequential: Process events in order (default)
on<EventName>(_onEventName);
```

### Best Practices

1. **Event Naming**: `{Feature}{Action}Requested`
   - ✅ `ExpenseLoadRequested`
   - ✅ `FriendRequestSendRequested`
   - ❌ `LoadExpense` (missing "Requested")

2. **State Status Enums**: Use specific status enums, not booleans
   - ✅ `enum ExpenseLoadStatus { initial, loading, loaded, error }`
   - ❌ `bool isLoading, bool hasError` (multiple booleans)

3. **Immutability**: All events and states are immutable
   - Use `const` constructors
   - All fields are `final`
   - Implement `copyWith()` for states

4. **Equatable**: Extend Equatable for automatic equality checks
   - Prevents unnecessary rebuilds
   - Implement `props` getter

5. **Stream Subscriptions**: Properly manage stream lifecycles
   ```dart
   StreamSubscription? _messagesSubscription;

   void _onWatchMessages(WatchMessages event, Emitter<ChatState> emit) {
     _messagesSubscription?.cancel();
     _messagesSubscription = watchMessages(event.roomId).listen(
       (messages) => add(MessagesUpdated(messages)),
     );
   }

   @override
   Future<void> close() {
     _messagesSubscription?.cancel();
     return super.close();
   }
   ```

---

## Dependency Injection

Pulse uses **GetIt** for dependency injection.

### Registration (`injection_container.dart`)

```dart
final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Expenses

  // BLoC - Factory (new instance each time)
  sl.registerFactory(() => ExpenseBloc(
    getExpenses: sl(),
    createExpense: sl(),
    updateExpense: sl(),
    deleteExpense: sl(),
  ));

  // Use Cases - Lazy Singleton (created when first needed)
  sl.registerLazySingleton(() => GetExpenses(sl()));
  sl.registerLazySingleton(() => CreateExpense(sl()));

  // Repository - Lazy Singleton
  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // DataSource - Lazy Singleton
  sl.registerLazySingleton<ExpenseRemoteDataSource>(
    () => ExpenseRemoteDataSourceImpl(firestore: sl()),
  );

  //! Core

  // External - Singleton (created immediately)
  final firestore = FirebaseFirestore.instance;
  sl.registerSingleton<FirebaseFirestore>(firestore);
}
```

### Registration Types

- **Factory**: New instance every time (BLoCs)
- **LazySingleton**: Single instance, created when first needed (UseCases, Repositories)
- **Singleton**: Single instance, created immediately (External services)

### Usage in Widgets

```dart
// In app.dart
BlocProvider(
  create: (_) => sl<ExpenseBloc>(),
  child: MyApp(),
)

// In any widget
context.read<ExpenseBloc>().add(ExpenseLoadRequested(...));
```

---

## Error Handling

### Failure Types (`core/error/failures.dart`)

```dart
abstract class Failure extends Equatable {
  @override
  List<Object> get props => [];
}

class ServerFailure extends Failure {
  final String message;
  ServerFailure([this.message = 'Server error']);

  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {}

class CacheFailure extends Failure {}
```

### Exception Types (`core/error/exceptions.dart`)

```dart
class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Server error']);
}

class CacheException implements Exception {}
```

### Flow

1. **DataSource** throws `Exception`
2. **Repository** catches and converts to `Failure`
3. **UseCase** returns `Either<Failure, T>`
4. **BLoC** handles with `fold()`
5. **UI** displays error message

---

## Data Flow

### Read Operation Flow

```
User Action (Button Click)
    ↓
Widget dispatches Event
    ↓
BLoC receives Event
    ↓
BLoC calls UseCase
    ↓
UseCase calls Repository
    ↓
Repository calls DataSource
    ↓
DataSource queries Firebase
    ↓
DataSource returns Model
    ↓
Repository converts to Entity
    ↓
UseCase returns Either<Failure, Entity>
    ↓
BLoC emits new State
    ↓
Widget rebuilds with new data
```

### Write Operation Flow

```
User Action (Form Submit)
    ↓
Widget dispatches Event with data
    ↓
BLoC validates and calls UseCase
    ↓
UseCase calls Repository
    ↓
Repository converts Entity to Model
    ↓
Repository calls DataSource
    ↓
DataSource writes to Firebase
    ↓
DataSource returns success/throws exception
    ↓
Repository returns Either<Failure, void>
    ↓
UseCase returns Either
    ↓
BLoC emits success/error State
    ↓
Widget shows feedback
```

---

## Testing Strategy

### Unit Tests

**UseCases**: Test business logic in isolation
```dart
test('should get expenses from repository', () async {
  // arrange
  when(() => mockRepository.getExpenses(any()))
      .thenAnswer((_) async => Right(tExpenses));

  // act
  final result = await usecase(GetExpensesParams(chatRoomIds: tChatRoomIds));

  // assert
  expect(result, Right(tExpenses));
  verify(() => mockRepository.getExpenses(tChatRoomIds));
  verifyNoMoreInteractions(mockRepository);
});
```

**Repositories**: Test data flow and error handling
```dart
test('should return ServerFailure when Firebase throws', () async {
  // arrange
  when(() => mockDataSource.getExpenses(any()))
      .thenThrow(FirebaseException(plugin: 'test'));

  // act
  final result = await repository.getExpenses(tChatRoomIds);

  // assert
  expect(result, Left(ServerFailure()));
});
```

**BLoCs**: Test state emissions
```dart
blocTest<ExpenseBloc, ExpenseState>(
  'emits [loading, loaded] when GetExpenses succeeds',
  build: () {
    when(() => mockGetExpenses(any()))
        .thenAnswer((_) async => Right(tExpenses));
    return bloc;
  },
  act: (bloc) => bloc.add(ExpenseLoadRequested(chatRoomIds: tChatRoomIds)),
  expect: () => [
    state.copyWith(status: ExpenseLoadStatus.loading),
    state.copyWith(status: ExpenseLoadStatus.loaded, expenses: tExpenses),
  ],
);
```

See `TESTING.md` for complete testing guide.

---

## Design Patterns

### Repository Pattern
Abstracts data sources behind a clean interface.

### UseCase Pattern
Encapsulates single business operations.

### Dependency Inversion
High-level modules depend on abstractions, not implementations.

### Observer Pattern
BLoC uses streams to notify UI of state changes.

### Factory Pattern
GetIt acts as a service locator and factory.

### Singleton Pattern
Single instances for repositories and services.

---

## Summary

The Pulse architecture follows industry best practices:

✅ **Clean Architecture** - Separation of concerns across layers
✅ **BLoC Pattern** - Predictable state management
✅ **Dependency Injection** - Loose coupling and testability
✅ **Either Type** - Functional error handling
✅ **Equatable** - Value equality and performance
✅ **Immutability** - Predictable state updates
✅ **Pure Business Logic** - Framework-independent domain layer
✅ **Comprehensive Testing** - Unit tests for all layers

This architecture ensures the codebase is:
- **Maintainable**: Easy to understand and modify
- **Testable**: All layers can be tested in isolation
- **Scalable**: New features follow established patterns
- **Robust**: Error handling at every layer
- **Clean**: Clear separation of concerns
