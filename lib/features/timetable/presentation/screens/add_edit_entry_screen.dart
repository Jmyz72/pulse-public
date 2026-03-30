import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/glass_text_field.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/timetable_entry.dart';
import '../bloc/timetable_bloc.dart';
import '../widgets/time_slot_picker.dart';
import '../widgets/timetable_constants.dart';
import '../widgets/visibility_selector.dart';

enum _RecurrenceEndMode { never, until, count }

class AddEditEntryScreen extends StatefulWidget {
  final TimetableEntry? entry;
  final DateTime? initialDate;
  final TimetableEditScope editScope;

  const AddEditEntryScreen({
    super.key,
    this.entry,
    this.initialDate,
    this.editScope = TimetableEditScope.wholeSeries,
  });

  @override
  State<AddEditEntryScreen> createState() => _AddEditEntryScreenState();
}

class _AddEditEntryScreenState extends State<AddEditEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _intervalController = TextEditingController(text: '1');
  final _countController = TextEditingController();

  late DateTime _selectedDate;
  String _startTime = '09:00';
  String _endTime = '10:00';
  String _selectedColor = '#0EA5E9';
  String _visibility = 'private';
  bool _isRecurring = false;
  TimetableRecurrenceFrequency _recurrenceFrequency =
      TimetableRecurrenceFrequency.none;
  Set<int> _recurrenceWeekdays = <int>{};
  _RecurrenceEndMode _recurrenceEndMode = _RecurrenceEndMode.never;
  DateTime? _recurrenceUntil;
  bool _isSaving = false;

  TimetableEntry? get _existingEntry => widget.entry;
  bool get _isEditing => widget.entry != null;
  bool get _isOccurrenceEdit =>
      _isEditing && widget.editScope == TimetableEditScope.thisOccurrence;

  @override
  void initState() {
    super.initState();
    _selectedDate = TimetableConstants.startOfDay(
      widget.initialDate ?? widget.entry?.startAt ?? DateTime.now(),
    );

    if (_existingEntry != null) {
      _populateFromEntry(_existingEntry!);
    } else {
      _recurrenceWeekdays = {_selectedDate.weekday};
    }
  }

  void _populateFromEntry(TimetableEntry entry) {
    _titleController.text = entry.title;
    _descriptionController.text = entry.description ?? '';
    _selectedDate = TimetableConstants.startOfDay(entry.startAt);
    _startTime =
        '${entry.startAt.hour.toString().padLeft(2, '0')}:${entry.startAt.minute.toString().padLeft(2, '0')}';
    _endTime =
        '${entry.endAt.hour.toString().padLeft(2, '0')}:${entry.endAt.minute.toString().padLeft(2, '0')}';
    _selectedColor = entry.color ?? '#0EA5E9';
    _visibility = entry.visibility;

    if (!_isOccurrenceEdit) {
      _isRecurring = entry.isRecurring;
      _recurrenceFrequency = entry.recurrenceFrequency;
      _intervalController.text = entry.recurrenceInterval.toString();
      _recurrenceWeekdays = entry.recurrenceWeekdays.isEmpty
          ? {entry.startAt.weekday}
          : entry.recurrenceWeekdays.toSet();
      _recurrenceUntil = entry.recurrenceUntil;
      if (entry.recurrenceCount != null) {
        _recurrenceEndMode = _RecurrenceEndMode.count;
        _countController.text = entry.recurrenceCount.toString();
      } else if (entry.recurrenceUntil != null) {
        _recurrenceEndMode = _RecurrenceEndMode.until;
      } else {
        _recurrenceEndMode = _RecurrenceEndMode.never;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _intervalController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TimetableBloc, TimetableState>(
      listener: (context, state) {
        if (state.status == TimetableStatus.loaded &&
            (state.lastOperation == LastOperation.add ||
                state.lastOperation == LastOperation.update)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.success.withValues(alpha: 0.9),
                content: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.white,
                      size: 20,
                    ),
                    const SizedBox(width: AppDimensions.spacingSm),
                    Text(_isEditing ? 'Entry updated' : 'Entry added'),
                  ],
                ),
              ),
            );
            Navigator.pop(context, true);
          }
        } else if (state.status == TimetableStatus.loaded &&
            state.lastOperation == LastOperation.delete) {
          Navigator.pop(context, true);
        } else if (state.status == TimetableStatus.error) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error.withValues(alpha: 0.9),
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.white,
                    size: 20,
                  ),
                  const SizedBox(width: AppDimensions.spacingSm),
                  Expanded(
                    child: Text(state.errorMessage ?? 'An error occurred'),
                  ),
                ],
              ),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: GlassAppBar(
          title: _isEditing
              ? (_isOccurrenceEdit ? 'Edit Occurrence' : 'Edit Entry')
              : 'Add Entry',
          actions: [
            if (_isEditing)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: _isSaving ? AppColors.textTertiary : AppColors.error,
                ),
                onPressed: _isSaving ? null : _deleteEntry,
              ),
            IconButton(
              icon: Icon(
                Icons.check,
                color: _isSaving ? AppColors.textTertiary : AppColors.schedule,
              ),
              onPressed: _isSaving ? null : _saveEntry,
            ),
          ],
        ),
        body: LoadingOverlay(
          isLoading: _isSaving,
          message: 'Saving...',
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.spacingMd),
              children: [
                if (_isOccurrenceEdit) _buildOccurrenceBanner(),
                GlassTextField(
                  controller: _titleController,
                  labelText: 'Title *',
                  hintText: 'e.g., Study Session',
                  textInputAction: TextInputAction.next,
                  autofocus: !_isEditing,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                _buildDatePicker(),
                const SizedBox(height: AppDimensions.spacingMd),
                const Text(
                  'Time *',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                TimeSlotPicker(
                  startTime: _startTime,
                  endTime: _endTime,
                  onStartTimeChanged: (time) {
                    setState(() => _startTime = time);
                  },
                  onEndTimeChanged: (time) {
                    setState(() => _endTime = time);
                  },
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                GlassTextField(
                  controller: _descriptionController,
                  labelText: 'Description',
                  hintText: 'Optional details',
                  textInputAction: TextInputAction.done,
                  maxLines: 3,
                ),
                const SizedBox(height: AppDimensions.spacingMd),
                const Text(
                  'Color',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                _buildColorPicker(),
                const SizedBox(height: AppDimensions.spacingLg),
                if (!_isOccurrenceEdit) ...[
                  _buildRecurrenceSection(),
                  const SizedBox(height: AppDimensions.spacingLg),
                ],
                VisibilitySelector(
                  visibility: _visibility,
                  onChanged: (value) {
                    setState(() => _visibility = value);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOccurrenceBanner() {
    return const Padding(
      padding: EdgeInsets.only(bottom: AppDimensions.spacingMd),
      child: GlassContainer(
        padding: EdgeInsets.all(AppDimensions.spacingMd),
        borderRadius: AppDimensions.radiusLg,
        borderColor: AppColors.schedule,
        backgroundOpacity: 0.08,
        child: Row(
          children: [
            Icon(Icons.event_repeat, color: AppColors.schedule),
            SizedBox(width: AppDimensions.spacingSm),
            Expanded(
              child: Text(
                'Editing this occurrence only. Series rules stay unchanged.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        borderRadius: AppDimensions.radiusLg,
        borderColor: AppColors.schedule,
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.schedule),
            const SizedBox(width: AppDimensions.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date *',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    TimetableConstants.formatHeaderDate(_selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrenceSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      borderRadius: AppDimensions.radiusXl,
      borderColor: AppColors.schedule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Repeat entry'),
            subtitle: const Text('Create a recurring calendar series'),
            activeThumbColor: AppColors.schedule,
            value: _isRecurring,
            onChanged: (value) {
              setState(() {
                _isRecurring = value;
                if (!value) {
                  _recurrenceFrequency = TimetableRecurrenceFrequency.none;
                } else if (_recurrenceFrequency ==
                    TimetableRecurrenceFrequency.none) {
                  _recurrenceFrequency = TimetableRecurrenceFrequency.weekly;
                }
                _recurrenceWeekdays = _recurrenceWeekdays.isEmpty
                    ? {_selectedDate.weekday}
                    : _recurrenceWeekdays;
              });
            },
          ),
          if (_isRecurring) ...[
            const SizedBox(height: AppDimensions.spacingSm),
            DropdownButtonFormField<TimetableRecurrenceFrequency>(
              initialValue:
                  _recurrenceFrequency == TimetableRecurrenceFrequency.none
                  ? TimetableRecurrenceFrequency.weekly
                  : _recurrenceFrequency,
              dropdownColor: AppColors.background,
              decoration: _dropdownDecoration('Repeat'),
              items: const [
                DropdownMenuItem(
                  value: TimetableRecurrenceFrequency.daily,
                  child: Text('Daily'),
                ),
                DropdownMenuItem(
                  value: TimetableRecurrenceFrequency.weekly,
                  child: Text('Weekly'),
                ),
                DropdownMenuItem(
                  value: TimetableRecurrenceFrequency.monthly,
                  child: Text('Monthly'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _recurrenceFrequency = value;
                    if (value == TimetableRecurrenceFrequency.weekly &&
                        _recurrenceWeekdays.isEmpty) {
                      _recurrenceWeekdays = {_selectedDate.weekday};
                    }
                  });
                }
              },
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            GlassTextField(
              controller: _intervalController,
              labelText: 'Interval *',
              hintText: '1',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (!_isRecurring) return null;
                final parsed = int.tryParse(value ?? '');
                if (parsed == null || parsed < 1) {
                  return 'Enter a valid interval';
                }
                return null;
              },
            ),
            if (_recurrenceFrequency ==
                TimetableRecurrenceFrequency.weekly) ...[
              const SizedBox(height: AppDimensions.spacingMd),
              const Text(
                'Repeat on',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimensions.spacingSm),
              Wrap(
                spacing: AppDimensions.spacingSm,
                children: List.generate(7, (index) {
                  final weekday = index + 1;
                  final isSelected = _recurrenceWeekdays.contains(weekday);
                  final date = DateTime(
                    2024,
                    1,
                    weekday,
                  ); // Monday anchored sample
                  return FilterChip(
                    selected: isSelected,
                    label: Text(TimetableConstants.formatShortDay(date)),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _recurrenceWeekdays.add(weekday);
                        } else {
                          _recurrenceWeekdays.remove(weekday);
                        }
                      });
                    },
                    selectedColor: AppColors.schedule.withValues(alpha: 0.18),
                    checkmarkColor: AppColors.schedule,
                    side: BorderSide(
                      color: AppColors.schedule.withValues(alpha: 0.25),
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: AppDimensions.spacingMd),
            DropdownButtonFormField<_RecurrenceEndMode>(
              initialValue: _recurrenceEndMode,
              dropdownColor: AppColors.background,
              decoration: _dropdownDecoration('Ends'),
              items: const [
                DropdownMenuItem(
                  value: _RecurrenceEndMode.never,
                  child: Text('Never'),
                ),
                DropdownMenuItem(
                  value: _RecurrenceEndMode.until,
                  child: Text('Until date'),
                ),
                DropdownMenuItem(
                  value: _RecurrenceEndMode.count,
                  child: Text('After count'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _recurrenceEndMode = value);
                }
              },
            ),
            if (_recurrenceEndMode == _RecurrenceEndMode.until) ...[
              const SizedBox(height: AppDimensions.spacingMd),
              InkWell(
                onTap: _pickRecurrenceUntil,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                child: GlassContainer(
                  padding: const EdgeInsets.all(AppDimensions.spacingMd),
                  borderRadius: AppDimensions.radiusLg,
                  borderColor: AppColors.schedule,
                  child: Row(
                    children: [
                      const Icon(Icons.event, color: AppColors.schedule),
                      const SizedBox(width: AppDimensions.spacingSm),
                      Expanded(
                        child: Text(
                          _recurrenceUntil == null
                              ? 'Select end date'
                              : TimetableConstants.formatHeaderDate(
                                  _recurrenceUntil!,
                                ),
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_recurrenceEndMode == _RecurrenceEndMode.count) ...[
              const SizedBox(height: AppDimensions.spacingMd),
              GlassTextField(
                controller: _countController,
                labelText: 'Occurrence count *',
                hintText: '10',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_recurrenceEndMode != _RecurrenceEndMode.count) {
                    return null;
                  }
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed < 1) {
                    return 'Enter a valid count';
                  }
                  return null;
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textTeal, fontSize: 16),
      filled: true,
      fillColor: AppColors.glassBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        borderSide: const BorderSide(color: AppColors.glassBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        borderSide: const BorderSide(color: AppColors.glassBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: AppDimensions.spacingMd - 4,
      runSpacing: AppDimensions.spacingMd - 4,
      children: TimetableConstants.colorOptions.map((color) {
        final hexColor =
            '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
        final isSelected = _selectedColor.toUpperCase() == hexColor;
        final colorName = TimetableConstants.getColorName(color);
        return Semantics(
          label: '$colorName${isSelected ? ', selected' : ''}',
          child: GestureDetector(
            onTap: () => setState(() => _selectedColor = hexColor),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: AppDimensions.iconXl,
              height: AppDimensions.iconXl,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.textPrimary
                      : Colors.transparent,
                  width: isSelected ? 3 : 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: _getContrastColor(color),
                      size: AppDimensions.iconMd,
                    )
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getContrastColor(Color color) {
    final luminance =
        (0.299 * color.r * 255 +
            0.587 * color.g * 255 +
            0.114 * color.b * 255) /
        255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        _selectedDate = TimetableConstants.startOfDay(date);
        if (_recurrenceWeekdays.isEmpty) {
          _recurrenceWeekdays = {_selectedDate.weekday};
        }
      });
    }
  }

  Future<void> _pickRecurrenceUntil() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _recurrenceUntil ?? _selectedDate,
      firstDate: _selectedDate,
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() => _recurrenceUntil = TimetableConstants.startOfDay(date));
    }
  }

  Future<void> _deleteEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.glassBorder, width: 1.5),
        ),
        title: const Text('Delete Entry'),
        content: Text(
          _isOccurrenceEdit
              ? 'Delete this occurrence only?'
              : 'Are you sure you want to delete "${_titleController.text}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || _existingEntry == null || !mounted) {
      return;
    }

    setState(() => _isSaving = true);
    context.read<TimetableBloc>().add(
      TimetableOccurrenceDeleteRequested(
        entry: _existingEntry!,
        scope: widget.editScope,
      ),
    );
  }

  void _saveEntry() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isRecurring &&
        _recurrenceFrequency == TimetableRecurrenceFrequency.weekly &&
        _recurrenceWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error.withValues(alpha: 0.9),
          content: const Text('Select at least one weekday'),
        ),
      );
      return;
    }

    if (_startTime.compareTo(_endTime) >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error.withValues(alpha: 0.9),
          content: const Text('End time must be after start time'),
        ),
      );
      return;
    }

    if (_isRecurring &&
        _recurrenceEndMode == _RecurrenceEndMode.until &&
        _recurrenceUntil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error.withValues(alpha: 0.9),
          content: const Text('Select an end date for the series'),
        ),
      );
      return;
    }

    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error.withValues(alpha: 0.9),
          content: const Text('Please sign in to continue'),
        ),
      );
      return;
    }

    final interval = int.tryParse(_intervalController.text.trim()) ?? 1;
    final recurrenceCount = _recurrenceEndMode == _RecurrenceEndMode.count
        ? int.tryParse(_countController.text.trim())
        : null;
    final startAt = _combine(_selectedDate, _startTime);
    final endAt = _combine(_selectedDate, _endTime);

    setState(() => _isSaving = true);

    final entry = TimetableEntry(
      id: _existingEntry?.id ?? 'temp-${DateTime.now().microsecondsSinceEpoch}',
      userId: userId,
      startAt: startAt,
      endAt: endAt,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      color: _selectedColor,
      visibility: _visibility,
      visibleTo: _existingEntry?.visibleTo ?? const [],
      createdAt: _existingEntry?.createdAt ?? DateTime.now(),
      updatedAt: _isEditing ? DateTime.now() : null,
      entryType: _resolveEntryType(),
      seriesId: _existingEntry?.seriesId,
      recurrenceFrequency: _isRecurring && !_isOccurrenceEdit
          ? _recurrenceFrequency
          : TimetableRecurrenceFrequency.none,
      recurrenceInterval: _isRecurring && !_isOccurrenceEdit ? interval : 1,
      recurrenceWeekdays:
          _isRecurring &&
              !_isOccurrenceEdit &&
              _recurrenceFrequency == TimetableRecurrenceFrequency.weekly
          ? (_recurrenceWeekdays.toList()..sort())
          : const [],
      recurrenceUntil:
          _isRecurring &&
              !_isOccurrenceEdit &&
              _recurrenceEndMode == _RecurrenceEndMode.until
          ? DateTime(
              _recurrenceUntil!.year,
              _recurrenceUntil!.month,
              _recurrenceUntil!.day,
              23,
              59,
              59,
              999,
            )
          : null,
      recurrenceCount:
          _isRecurring &&
              !_isOccurrenceEdit &&
              _recurrenceEndMode == _RecurrenceEndMode.count
          ? recurrenceCount
          : null,
      occurrenceDate: _existingEntry?.occurrenceDate,
      isCancelled: _existingEntry?.isCancelled ?? false,
    );

    if (!_isEditing) {
      context.read<TimetableBloc>().add(
        TimetableEntryAddRequested(entry: entry),
      );
      return;
    }

    if (_isOccurrenceEdit && _existingEntry != null) {
      context.read<TimetableBloc>().add(
        TimetableOccurrenceUpdateRequested(
          originalEntry: _existingEntry!,
          updatedEntry: entry,
          scope: TimetableEditScope.thisOccurrence,
        ),
      );
      return;
    }

    context.read<TimetableBloc>().add(
      TimetableEntryUpdateRequested(entry: entry),
    );
  }

  TimetableEntryType _resolveEntryType() {
    if (_isOccurrenceEdit) {
      return _existingEntry?.entryType ?? TimetableEntryType.single;
    }
    if (_isRecurring) {
      return TimetableEntryType.series;
    }
    return TimetableEntryType.single;
  }

  DateTime _combine(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = int.tryParse(parts.last) ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
