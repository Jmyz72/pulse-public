import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

/// Event transformers for BLoC to prevent rapid-fire events.
/// Use these to debounce or throttle user interactions.

/// Debounce transformer - waits for a pause in events before processing.
/// Useful for search fields, form validation, etc.
EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

/// Throttle transformer - processes first event, then ignores for duration.
/// Useful for button clicks, scroll events, etc.
EventTransformer<E> throttle<E>(Duration duration) {
  return (events, mapper) => events.throttle(duration).switchMap(mapper);
}

/// Throttle with trailing - processes first and last events in duration window.
EventTransformer<E> throttleWithTrailing<E>(Duration duration) {
  return (events, mapper) =>
      events.throttle(duration, trailing: true).switchMap(mapper);
}

/// Drop events while another event is being processed.
/// Prevents duplicate submissions.
EventTransformer<E> droppable<E>() {
  return (events, mapper) => events.switchMap(mapper);
}

/// Sequential processing - processes events one at a time in order.
EventTransformer<E> sequential<E>() {
  return (events, mapper) => events.asyncExpand(mapper);
}
