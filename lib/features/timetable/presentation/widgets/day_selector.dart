import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import 'timetable_constants.dart';

class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback? onPreviousWeek;
  final VoidCallback? onNextWeek;
  final VoidCallback? onPickDate;

  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.onPreviousWeek,
    this.onNextWeek,
    this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    final today = TimetableConstants.startOfDay(DateTime.now());
    final weekStart = TimetableConstants.startOfWeek(selectedDate);
    final dates = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spacingMd,
            AppDimensions.spacingSm,
            AppDimensions.spacingMd,
            AppDimensions.spacingSm,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onPreviousWeek,
                icon: const Icon(Icons.chevron_left),
                color: AppColors.schedule,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onPickDate,
                  child: Column(
                    children: [
                      Text(
                        TimetableConstants.formatMonthLabel(selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        TimetableConstants.formatHeaderDate(selectedDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: onNextWeek,
                icon: const Icon(Icons.chevron_right),
                color: AppColors.schedule,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 78,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingMd - 4,
            ),
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected = TimetableConstants.isSameDate(
                date,
                selectedDate,
              );
              final isToday = TimetableConstants.isSameDate(date, today);

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingXs,
                ),
                child: Semantics(
                  label:
                      '${TimetableConstants.formatHeaderDate(date)}${isToday ? ', today' : ''}',
                  selected: isSelected,
                  child: GestureDetector(
                    onTap: () => onDateSelected(date),
                    child: GlassContainer(
                      width: 60,
                      padding: EdgeInsets.zero,
                      borderRadius: AppDimensions.radiusLg,
                      backgroundOpacity: isSelected
                          ? 0.15
                          : (isToday ? 0.05 : 0.0),
                      borderOpacity: isSelected || isToday ? 0.6 : 0.0,
                      borderColor: AppColors.schedule,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            TimetableConstants.formatShortDay(date),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected || isToday
                                  ? AppColors.schedule
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacingXs),
                          Text(
                            TimetableConstants.formatDayNumber(date),
                            style: TextStyle(
                              fontSize: 18,
                              color: isSelected
                                  ? AppColors.schedule
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacingXs),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? AppColors.schedule
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
