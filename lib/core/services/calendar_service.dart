import 'package:add_2_calendar/add_2_calendar.dart' as calendar;
import 'package:intl/intl.dart';

import '../../features/location/domain/entities/event.dart';

class CalendarService {
  CalendarService._();

  static Future<void> addEventToCalendar(Event event) async {
    final startDate = _buildStartDate(event.eventDate, event.eventTime);
    final endDate = startDate.add(const Duration(hours: 2));

    final calendarEvent = calendar.Event(
      title: event.title,
      description: event.description ?? '',
      location:
          '${event.latitude.toStringAsFixed(4)}, ${event.longitude.toStringAsFixed(4)}',
      startDate: startDate,
      endDate: endDate,
    );

    await calendar.Add2Calendar.addEvent2Cal(calendarEvent);
  }

  static DateTime _buildStartDate(DateTime eventDate, String eventTime) {
    final trimmedTime = eventTime.trim();

    try {
      final parsedTime = DateFormat('h:mm a').parseStrict(trimmedTime);
      return DateTime(
        eventDate.year,
        eventDate.month,
        eventDate.day,
        parsedTime.hour,
        parsedTime.minute,
      );
    } catch (_) {
      return DateTime(eventDate.year, eventDate.month, eventDate.day, 12);
    }
  }
}
