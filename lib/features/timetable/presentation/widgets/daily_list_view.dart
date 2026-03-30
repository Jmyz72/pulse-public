import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/timetable_entry.dart';
import 'schedule_item_card.dart';
import 'timetable_constants.dart';

class DailyListView extends StatelessWidget {
  final List<TimetableEntry> entries;
  final DateTime date;
  final void Function(TimetableEntry)? onEntryTap;
  final void Function(TimetableEntry)? onEntryLongPress;
  final bool isOwner;

  const DailyListView({
    super.key,
    required this.entries,
    required this.date,
    this.onEntryTap,
    this.onEntryLongPress,
    this.isOwner = true,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.event_available,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  Text(
                    'No schedule for ${TimetableConstants.formatHeaderDate(date)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.spacingSm),
                  if (isOwner)
                    const Text(
                      'Tap + to add an entry',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return ScheduleItemCard(
          entry: entry,
          onTap: onEntryTap != null ? () => onEntryTap!(entry) : null,
          onLongPress: onEntryLongPress != null
              ? () => onEntryLongPress!(entry)
              : null,
          showVisibility: isOwner,
        );
      },
    );
  }
}
