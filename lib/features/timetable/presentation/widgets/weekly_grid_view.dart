import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/timetable_entry.dart';
import 'timetable_constants.dart';

class WeeklyGridView extends StatelessWidget {
  final List<DateTime> weekDates;
  final Map<DateTime, List<TimetableEntry>> entriesByDate;
  final void Function(TimetableEntry)? onEntryTap;
  final void Function(DateTime day)? onDayTap;

  const WeeklyGridView({
    super.key,
    required this.weekDates,
    required this.entriesByDate,
    this.onEntryTap,
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final today = TimetableConstants.startOfDay(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      child: Column(
        children: List.generate(weekDates.length, (index) {
          final date = weekDates[index];
          final entries = entriesByDate[date] ?? const [];
          final isToday = TimetableConstants.isSameDate(date, today);

          return Semantics(
            label:
                '${TimetableConstants.formatHeaderDate(date)}${isToday ? ', today' : ''}, ${entries.length} entries',
            child: GestureDetector(
              onTap: onDayTap != null ? () => onDayTap!(date) : null,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
                child: GlassContainer(
                  padding: const EdgeInsets.all(AppDimensions.spacingMd - 4),
                  borderRadius: AppDimensions.radiusXl,
                  backgroundOpacity: isToday ? 0.08 : 0.03,
                  borderOpacity: isToday ? 0.5 : 0.15,
                  borderColor: AppColors.schedule,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: AppDimensions.iconXl,
                        child: Column(
                          children: [
                            Text(
                              TimetableConstants.formatShortDay(date),
                              style: TextStyle(
                                fontSize: 12,
                                color: isToday
                                    ? AppColors.schedule
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spacingXs),
                            Text(
                              TimetableConstants.formatDayNumber(date),
                              style: TextStyle(
                                fontSize: 20,
                                color: isToday
                                    ? AppColors.schedule
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(height: AppDimensions.spacingXs),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.schedule,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingMd - 4),
                      Expanded(
                        child: entries.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.only(
                                  top: AppDimensions.spacingXs,
                                ),
                                child: Text(
                                  'No schedule',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : Wrap(
                                spacing: AppDimensions.spacingSm,
                                runSpacing: AppDimensions.spacingSm,
                                children: entries.map((entry) {
                                  final entryColor =
                                      parseColor(entry.color) ??
                                      AppColors.schedule;
                                  return GestureDetector(
                                    onTap: onEntryTap != null
                                        ? () => onEntryTap!(entry)
                                        : null,
                                    child: GlassContainer(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppDimensions.spacingSm + 2,
                                        vertical: AppDimensions.spacingSm + 2,
                                      ),
                                      borderRadius: AppDimensions.radiusSm,
                                      backgroundOpacity: 0.0,
                                      borderOpacity: 0.3,
                                      borderColor: entryColor,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: entryColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: AppDimensions.spacingXs + 2,
                                          ),
                                          Text(
                                            TimetableConstants.formatTime(
                                              entry.startAt,
                                            ),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: entryColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: AppDimensions.spacingXs + 2,
                                          ),
                                          Flexible(
                                            child: Text(
                                              entry.title,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
