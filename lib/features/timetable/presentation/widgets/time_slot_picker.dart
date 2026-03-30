import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/glass_card.dart';

class TimeSlotPicker extends StatelessWidget {
  final String startTime;
  final String endTime;
  final ValueChanged<String> onStartTimeChanged;
  final ValueChanged<String> onEndTimeChanged;

  const TimeSlotPicker({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildTimePicker(
            context,
            label: 'Start Time',
            time: startTime,
            onChanged: onStartTimeChanged,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingMd),
          child: Icon(Icons.arrow_forward, color: AppColors.textTertiary),
        ),
        Expanded(
          child: _buildTimePicker(
            context,
            label: 'End Time',
            time: endTime,
            onChanged: onEndTimeChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(
    BuildContext context, {
    required String label,
    required String time,
    required ValueChanged<String> onChanged,
  }) {
    return Semantics(
      label: '$label: ${time.isEmpty ? 'not set' : time}',
      child: InkWell(
        onTap: () => _showTimePicker(context, time, onChanged),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          borderRadius: AppDimensions.radiusMd,
          borderColor: AppColors.schedule,
          borderOpacity: 0.3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXs),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 20,
                    color: AppColors.schedule,
                  ),
                  const SizedBox(width: AppDimensions.spacingSm),
                  Text(
                    time.isEmpty ? '--:--' : time,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTimePicker(
    BuildContext context,
    String currentTime,
    ValueChanged<String> onChanged,
  ) async {
    TimeOfDay initialTime;
    if (currentTime.isNotEmpty) {
      final parts = currentTime.split(':');
      initialTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    } else {
      initialTime = const TimeOfDay(hour: 9, minute: 0);
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onChanged(formattedTime);
    }
  }
}
