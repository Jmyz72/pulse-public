import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../chat/domain/entities/message.dart';
import '../../domain/entities/task.dart';

class TaskFormDialog extends StatefulWidget {
  final Task? existingTask;
  final List<ChatRoom> chatRooms;
  final String? preselectedChatRoomId;
  final String currentUserId;
  final void Function(Task task) onSubmit;

  const TaskFormDialog({
    super.key,
    this.existingTask,
    this.chatRooms = const [],
    this.preselectedChatRoomId,
    required this.currentUserId,
    required this.onSubmit,
  });

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final _subTaskController = TextEditingController();
  
  ChatRoom? _selectedChatRoom;
  String? _selectedAssigneeId;
  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskCategory _selectedCategory = TaskCategory.other;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  bool _isRecurring = false;
  String _selectedPattern = 'Weekly';
  List<TaskItem> _subTasks = [];

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    
    if (_isEditing) {
      _selectedPriority = task!.priority;
      _selectedCategory = task.category;
      _selectedDate = task.dueDate;
      _isRecurring = task.isRecurring;
      _selectedPattern = task.recurringPattern ?? 'Weekly';
      _selectedAssigneeId = task.assignedTo;
      _subTasks = List.from(task.subTasks);
      
      final match = widget.chatRooms.where((r) => r.id == task.chatRoomId).toList();
      if (match.isNotEmpty) _selectedChatRoom = match.first;
    } else {
      if (widget.preselectedChatRoomId != null) {
        final match = widget.chatRooms.where((r) => r.id == widget.preselectedChatRoomId).toList();
        if (match.isNotEmpty) _selectedChatRoom = match.first;
      } else if (widget.chatRooms.isNotEmpty) {
        _selectedChatRoom = widget.chatRooms.first;
      }
      _selectedAssigneeId = widget.currentUserId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  void _addSubTask() {
    final text = _subTaskController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _subTasks.add(TaskItem(
          id: const Uuid().v4(),
          title: text,
          isDone: false,
        ));
        _subTaskController.clear();
      });
    }
  }

  void _removeSubTask(String id) {
    setState(() {
      _subTasks.removeWhere((item) => item.id == id);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedChatRoom == null) return;

    final task = Task(
      id: widget.existingTask?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      chatRoomId: _selectedChatRoom!.id,
      assignedTo: _selectedAssigneeId ?? widget.currentUserId,
      assignedToName: _selectedChatRoom!.memberNames[_selectedAssigneeId] ?? 'Someone',
      dueDate: _selectedDate,
      priority: _selectedPriority,
      status: widget.existingTask?.status ?? TaskStatus.pending,
      category: _selectedCategory,
      createdAt: widget.existingTask?.createdAt ?? DateTime.now(),
      createdBy: widget.existingTask?.createdBy ?? widget.currentUserId,
      isRecurring: _isRecurring,
      recurringPattern: _isRecurring ? _selectedPattern : null,
      subTasks: _subTasks,
    );

    widget.onSubmit(task);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            decoration: BoxDecoration(
              color: AppColors.getGlassBackground(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              border: Border.all(
                color: AppColors.getGlassBorder(0.4),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(AppDimensions.spacingLg),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing ? 'Edit Task' : 'New Task',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Group Selector
                          DropdownButtonFormField<ChatRoom>(
                            dropdownColor: AppColors.background,
                            decoration: const InputDecoration(labelText: 'Group'),
                            initialValue: _selectedChatRoom,
                            items: widget.chatRooms.map((room) {
                              return DropdownMenuItem(
                                value: room,
                                child: Text(room.name, style: const TextStyle(color: AppColors.textPrimary)),
                              );
                            }).toList(),
                            onChanged: _isEditing ? null : (value) {
                              setState(() {
                                _selectedChatRoom = value;
                                if (value != null && !value.members.contains(_selectedAssigneeId)) {
                                  _selectedAssigneeId = widget.currentUserId;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: AppDimensions.spacingMd),

                          TextFormField(
                            controller: _titleController,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'What needs to be done?',
                              hintText: 'e.g., Clean the living room',
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
                          ),
                          const SizedBox(height: AppDimensions.spacingMd),

                          // Assignee Picker
                          if (_selectedChatRoom != null) ...[
                            DropdownButtonFormField<String>(
                              dropdownColor: AppColors.background,
                              decoration: const InputDecoration(labelText: 'Assign to'),
                              initialValue: _selectedAssigneeId,
                              items: _selectedChatRoom!.members.map((memberId) {
                                final name = _selectedChatRoom!.memberNames[memberId] ?? 'Member';
                                return DropdownMenuItem(
                                  value: memberId,
                                  child: Text(memberId == widget.currentUserId ? 'Me' : name, style: const TextStyle(color: AppColors.textPrimary)),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedAssigneeId = val),
                            ),
                            const SizedBox(height: AppDimensions.spacingMd),
                          ],

                          // Due Date
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) setState(() => _selectedDate = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Due Date'),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                    style: const TextStyle(color: AppColors.textPrimary),
                                  ),
                                  const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacingMd),

                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<TaskCategory>(
                                  dropdownColor: AppColors.background,
                                  decoration: const InputDecoration(labelText: 'Category'),
                                  initialValue: _selectedCategory,
                                  items: TaskCategory.values.map((cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                                  )).toList(),
                                  onChanged: (val) => setState(() => _selectedCategory = val!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<TaskPriority>(
                                  dropdownColor: AppColors.background,
                                  decoration: const InputDecoration(labelText: 'Priority'),
                                  initialValue: _selectedPriority,
                                  items: TaskPriority.values.map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                                  )).toList(),
                                  onChanged: (val) => setState(() => _selectedPriority = val!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spacingMd),

                          // Checklist Section
                          const Text('Checklist', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _subTaskController,
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                  decoration: const InputDecoration(
                                    hintText: 'Add a sub-task...',
                                    isDense: true,
                                  ),
                                  onSubmitted: (_) => _addSubTask(),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                                onPressed: _addSubTask,
                              ),
                            ],
                          ),
                          ..._subTasks.map((item) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.check_box_outline_blank, size: 18, color: AppColors.textTertiary),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.error),
                                  onPressed: () => _removeSubTask(item.id),
                                ),
                              ],
                            ),
                          )),
                          const SizedBox(height: AppDimensions.spacingMd),

                          SwitchListTile(
                            title: const Text('Recurring', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                            value: _isRecurring,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) => setState(() => _isRecurring = val),
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_isRecurring)
                            DropdownButtonFormField<String>(
                              dropdownColor: AppColors.background,
                              decoration: const InputDecoration(labelText: 'Frequency'),
                              initialValue: _selectedPattern,
                              items: ['Daily', 'Weekly', 'Monthly'].map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p, style: const TextStyle(color: AppColors.textPrimary)),
                              )).toList(),
                              onChanged: (val) => setState(() => _selectedPattern = val!),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spacingLg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      const SizedBox(width: AppDimensions.spacingSm),
                      ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(_isEditing ? 'Save' : 'Create'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
