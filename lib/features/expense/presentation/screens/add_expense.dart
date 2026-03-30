import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../chat/domain/entities/message.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_item.dart';
import '../../domain/entities/expense_submission.dart';
import '../bloc/expense_bloc.dart';
import '../widgets/glass_step_indicator.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? existingExpense;

  const AddExpenseScreen({super.key, this.existingExpense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  bool get _isEditing => widget.existingExpense != null;

  static const _stepLabels = ['Setup', 'People'];

  int _currentStep = 0;
  bool _adjustmentsExpanded = false;
  bool _hasLoadedRouteArgs = false;
  bool _hasRequestedChatRooms = false;
  bool _isSubmitting = false;

  String? _pendingPreselectedChatRoomId;
  List<ChatRoom> _chatRooms = [];
  StreamSubscription<ChatState>? _chatRoomsSubscription;
  _PendingSubmission? _pendingSubmission;

  _ExpenseDraft _draft = const _ExpenseDraft();

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_syncDraftFromControllers);
    _descriptionController.addListener(_syncDraftFromControllers);
    _amountController.addListener(_syncDraftFromControllers);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasLoadedRouteArgs) return;

    _loadRouteArguments();
    _startChatRoomSync();
    if (_isEditing) {
      _loadExistingExpense();
    }
    _hasLoadedRouteArgs = true;
  }

  @override
  void dispose() {
    _chatRoomsSubscription?.cancel();
    _titleController.removeListener(_syncDraftFromControllers);
    _descriptionController.removeListener(_syncDraftFromControllers);
    _amountController.removeListener(_syncDraftFromControllers);
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _syncDraftFromControllers() {
    final parsedAmount = double.tryParse(_amountController.text.trim());
    final nextDraft = _draft.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      manualAmount: parsedAmount,
      clearManualAmount: parsedAmount == null,
    );
    if (nextDraft == _draft || !mounted) return;
    setState(() {
      _draft = nextDraft;
    });
  }

  void _loadRouteArguments() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Compatibility-only. The flow is now always started from Setup.
    final routeChatRooms = args?['chatRooms'] as List<ChatRoom>?;
    _pendingPreselectedChatRoomId = args?['preselectedChatRoomId'] as String?;

    if (routeChatRooms != null && routeChatRooms.isNotEmpty) {
      _applyChatRooms(routeChatRooms);
    } else {
      final blocChatRooms = context.read<ChatBloc>().state.chatRooms;
      if (blocChatRooms.isNotEmpty) {
        _applyChatRooms(blocChatRooms);
      } else {
        _requestChatRoomsIfNeeded();
      }
    }

    _applyScannedItemsFromPayload(args);
  }

  void _loadExistingExpense() {
    final expense = widget.existingExpense!;
    _titleController.text = expense.title;
    _descriptionController.text = expense.description ?? '';
    _amountController.text = expense.items.isEmpty
        ? expense.totalAmount.toStringAsFixed(2)
        : '';
    _pendingPreselectedChatRoomId ??= expense.chatRoomId;
    _adjustmentsExpanded =
        expense.taxPercent != null ||
        expense.serviceChargePercent != null ||
        expense.discountPercent != null;

    _draft = _draft.copyWith(
      title: expense.title,
      description: expense.description ?? '',
      expenseType: expense.type,
      splitType: expense.items.isNotEmpty ? SplitType.custom : SplitType.equal,
      items: List<ExpenseItem>.from(expense.items),
      manualAmount: expense.items.isEmpty ? expense.totalAmount : null,
      clearManualAmount: expense.items.isNotEmpty,
      taxPercent: expense.taxPercent,
      clearTaxPercent: expense.taxPercent == null,
      serviceChargePercent: expense.serviceChargePercent,
      clearServiceChargePercent: expense.serviceChargePercent == null,
      discountPercent: expense.discountPercent,
      clearDiscountPercent: expense.discountPercent == null,
      selectedMembers: expense.splits
          .map(
            (split) => SelectedMember(
              id: split.userId,
              name: split.userName,
              isSelected: true,
              isCreator:
                  split.userId ==
                  (context.read<AuthBloc>().state.user?.id ??
                      context.read<ExpenseBloc>().state.currentUserId),
            ),
          )
          .toList(),
    );

    if (_chatRooms.isNotEmpty && expense.chatRoomId != null) {
      _applyChatRooms(_chatRooms);
    }
  }

  void _startChatRoomSync() {
    if (_chatRoomsSubscription != null) return;
    _chatRoomsSubscription = context.read<ChatBloc>().stream.listen((
      chatState,
    ) {
      if (!mounted || chatState.chatRooms.isEmpty) return;
      _applyChatRooms(chatState.chatRooms);
    });
  }

  void _requestChatRoomsIfNeeded() {
    if (_hasRequestedChatRooms) return;
    _hasRequestedChatRooms = true;
    context.read<ChatBloc>().add(ChatRoomsWatchRequested());
  }

  void _applyChatRooms(List<ChatRoom> chatRooms) {
    if (chatRooms.isEmpty) return;

    final eligibleRooms = _eligibleChatRooms(chatRooms: chatRooms);
    final previousSelectedId = _draft.selectedChatRoom?.id;

    ChatRoom? nextSelectedRoom = _draft.selectedChatRoom;
    if (nextSelectedRoom != null &&
        eligibleRooms.every((room) => room.id != nextSelectedRoom!.id)) {
      nextSelectedRoom = null;
    }

    if (nextSelectedRoom == null && _pendingPreselectedChatRoomId != null) {
      final matchIndex = eligibleRooms.indexWhere(
        (room) => room.id == _pendingPreselectedChatRoomId,
      );
      if (matchIndex != -1) {
        nextSelectedRoom = eligibleRooms[matchIndex];
      }
    }

    if (nextSelectedRoom == null && eligibleRooms.length == 1) {
      nextSelectedRoom = eligibleRooms.first;
    }

    final shouldReloadMembers =
        nextSelectedRoom != null &&
        (previousSelectedId != nextSelectedRoom.id ||
            _draft.selectedMembers.isEmpty);

    setState(() {
      _chatRooms = List<ChatRoom>.from(chatRooms);
      _draft = _draft.copyWith(
        expenseType: _deriveExpenseType(nextSelectedRoom),
        selectedChatRoom: nextSelectedRoom,
        clearSelectedChatRoom: nextSelectedRoom == null,
        selectedMembers: nextSelectedRoom == null && !_isEditing
            ? const []
            : _draft.selectedMembers,
      );
    });

    if (_pendingPreselectedChatRoomId == nextSelectedRoom?.id) {
      _pendingPreselectedChatRoomId = null;
    }

    if (shouldReloadMembers &&
        (!_isEditing || _draft.selectedMembers.isEmpty)) {
      _loadMembersFromChatRoom(nextSelectedRoom);
    }
  }

  List<ChatRoom> _eligibleChatRooms({List<ChatRoom>? chatRooms}) {
    final rooms = List<ChatRoom>.from(chatRooms ?? _chatRooms);
    rooms.sort(_compareChatRooms);
    return rooms;
  }

  int _compareChatRooms(ChatRoom a, ChatRoom b) {
    final aStamp = a.lastMessageAt ?? a.createdAt;
    final bStamp = b.lastMessageAt ?? b.createdAt;
    return bStamp.compareTo(aStamp);
  }

  ExpenseType _deriveExpenseType(ChatRoom? room) {
    if (_draft.expenseType == ExpenseType.adHoc && room == null) {
      return ExpenseType.adHoc;
    }
    if (room == null) {
      return ExpenseType.group;
    }
    return room.members.length == 2 ? ExpenseType.oneOnOne : ExpenseType.group;
  }

  void _applyScannedItemsFromPayload(Map<String, dynamic>? payload) {
    final scannedItems = payload?['scannedItems'] as List<dynamic>?;
    if (scannedItems == null || scannedItems.isEmpty) return;

    final parsedItems = scannedItems.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return ExpenseItem(
        id: const Uuid().v4(),
        name: map['name'] as String? ?? 'Unknown Item',
        price: (map['price'] as num?)?.toDouble() ?? 0,
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      );
    }).toList();

    setState(() {
      _draft = _draft.copyWith(
        splitType: SplitType.custom,
        items: parsedItems,
        taxPercent: (payload?['taxPercent'] as num?)?.toDouble(),
        clearTaxPercent: payload?['taxPercent'] == null,
        serviceChargePercent: (payload?['serviceChargePercent'] as num?)
            ?.toDouble(),
        clearServiceChargePercent: payload?['serviceChargePercent'] == null,
        discountPercent: (payload?['discountPercent'] as num?)?.toDouble(),
        clearDiscountPercent: payload?['discountPercent'] == null,
      );
      _adjustmentsExpanded = true;
      _currentStep = 0;
    });
  }

  Future<void> _openReceiptScanner() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.receiptScan,
      arguments: {'returnResultOnly': true},
    );
    if (!mounted || result == null || result is! Map) return;
    _applyScannedItemsFromPayload(Map<String, dynamic>.from(result));
  }

  Future<void> _loadMembersFromChatRoom(ChatRoom chatRoom) async {
    final expenseState = context.read<ExpenseBloc>().state;
    final authState = context.read<AuthBloc>().state;
    final currentUserId = expenseState.currentUserId ?? '';
    final currentUserName = authState.user?.displayName ?? 'You';

    final members = chatRoom.members.map((memberId) {
      final isCreator = memberId == currentUserId;
      final name = isCreator
          ? currentUserName
          : (chatRoom.memberNames[memberId] ??
                'Member ${memberId.substring(0, 4)}');
      return SelectedMember(
        id: memberId,
        name: name,
        isSelected: !isCreator || _draft.includeCreator,
        isCreator: isCreator,
      );
    }).toList();

    if (!mounted) return;
    setState(() {
      _draft = _draft.copyWith(selectedMembers: members);
    });
  }

  void _onChatRoomChanged(ChatRoom? value) {
    setState(() {
      _draft = _draft.copyWith(
        expenseType: _deriveExpenseType(value),
        selectedChatRoom: value,
        clearSelectedChatRoom: value == null,
        selectedMembers: const [],
      );
    });
    if (value != null) {
      _loadMembersFromChatRoom(value);
    }
  }

  Future<void> _openChatRoomPicker() async {
    final currentUserId = context.read<AuthBloc>().state.user?.id ?? '';
    final selectedRoom = await showModalBottomSheet<ChatRoom>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundLight,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (context) => _ChatRoomPickerSheet(
        currentUserId: currentUserId,
        chatRooms: _eligibleChatRooms(),
        selectedChatRoomId: _draft.selectedChatRoom?.id,
      ),
    );

    if (!mounted || selectedRoom == null) return;
    _onChatRoomChanged(selectedRoom);
  }

  void _onSplitTypeChanged(SplitType value) {
    setState(() {
      _draft = _draft.copyWith(
        splitType: value,
        items: value == SplitType.equal ? const [] : _draft.items,
      );
    });
  }

  void _toggleIncludeCreator(bool value) {
    final updatedMembers = _draft.selectedMembers.map((member) {
      if (!member.isCreator) return member;
      return member.copyWith(isSelected: value);
    }).toList();

    setState(() {
      _draft = _draft.copyWith(
        includeCreator: value,
        selectedMembers: updatedMembers,
      );
    });
  }

  void _toggleMemberSelection(String memberId, bool? isSelected) {
    final nextValue = isSelected ?? false;
    final updatedMembers = _draft.selectedMembers.map((member) {
      if (member.id != memberId) return member;
      return member.copyWith(isSelected: nextValue);
    }).toList();

    setState(() {
      _draft = _draft.copyWith(
        selectedMembers: updatedMembers,
        includeCreator: updatedMembers.any(
          (member) => member.isCreator && member.isSelected,
        ),
      );
    });
  }

  void _showAddItemDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _AddItemDialog(
          onItemAdded: (name, price, quantity) {
            setState(() {
              _draft = _draft.copyWith(
                splitType: SplitType.custom,
                items: [
                  ..._draft.items,
                  ExpenseItem(
                    id: const Uuid().v4(),
                    name: name,
                    price: price,
                    quantity: quantity,
                  ),
                ],
              );
            });
          },
        );
      },
    );
  }

  void _removeItem(String itemId) {
    setState(() {
      _draft = _draft.copyWith(
        items: _draft.items.where((item) => item.id != itemId).toList(),
      );
    });
  }

  String? _validateSetup() {
    if (_draft.title.isEmpty) return 'Please enter a title';
    if (!_isEditing &&
        _draft.expenseType != ExpenseType.adHoc &&
        _draft.selectedChatRoom == null) {
      return 'Please select a chat room';
    }
    if (_draft.splitType == SplitType.equal) {
      if (_draft.manualAmount == null) return 'Please enter a valid amount';
      if (_draft.manualAmount! <= 0) return 'Amount must be greater than 0';
      if (_draft.manualAmount! > 999999) return 'Amount is too large';
    } else if (_draft.items.isEmpty) {
      return 'Please add at least one item';
    }
    return null;
  }

  String? _validatePeopleStep() {
    if (_draft.selectedMemberCount < 2) {
      return 'Please select at least 2 members';
    }
    return null;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      final message = _validateSetup();
      if (message != null) {
        _showValidationError(message);
        return;
      }
      setState(() {
        _currentStep = 1;
      });
      return;
    }

    final message = _validatePeopleStep();
    if (message != null) {
      _showValidationError(message);
      return;
    }

    _handleSubmit();
  }

  void _onStepCancel() {
    if (_currentStep == 0) return;
    setState(() {
      _currentStep = 0;
    });
  }

  bool _canSubmit() =>
      _validateSetup() == null && _validatePeopleStep() == null;

  void _handleSubmit() {
    if (!_canSubmit()) return;

    final selectedMembers = _draft.selectedMembers
        .where((member) => member.isSelected)
        .toList();
    final authState = context.read<AuthBloc>().state;
    final submission = ExpenseSubmission(
      currentUserId: authState.user?.id ?? '',
      currentUserName: authState.user?.displayName ?? 'You',
      ownerPaymentIdentity: authState.user?.paymentIdentity,
      title: _draft.title,
      description: _draft.description,
      expenseType: _draft.expenseType,
      chatRoomId: _draft.selectedChatRoom?.id,
      participants: selectedMembers
          .map((member) => ExpenseParticipant(id: member.id, name: member.name))
          .toList(growable: false),
      items: _draft.items,
      manualAmount: _draft.manualAmount,
      taxPercent: _draft.taxPercent,
      serviceChargePercent: _draft.serviceChargePercent,
      discountPercent: _draft.discountPercent,
      isCustomSplit: _draft.splitType == SplitType.custom,
    );

    setState(() {
      _isSubmitting = true;
    });

    if (_isEditing) {
      final existing = widget.existingExpense!;
      _pendingSubmission = _PendingSubmission.forUpdate(
        splitType: _draft.splitType,
      );
      context.read<ExpenseBloc>().add(
        ExpenseUpdateRequested(
          existingExpense: existing,
          submission: submission,
        ),
      );
      return;
    }

    _pendingSubmission = _PendingSubmission.forCreate(
      splitType: _draft.splitType,
    );
    context.read<ExpenseBloc>().add(
      ExpenseCreateRequested(submission: submission),
    );
  }

  void _handleBlocState(ExpenseState state) {
    if (state.status == ExpenseLoadStatus.error && state.errorMessage != null) {
      _isSubmitting = false;
      _pendingSubmission = null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      if (mounted) {
        setState(() {});
      }
      return;
    }

    if (!_isSubmitting || _pendingSubmission == null) return;
    if (state.status != ExpenseLoadStatus.loaded) return;

    final pending = _pendingSubmission!;
    if (pending.isUpdate) {
      _completeSuccess(
        createdExpense: state.selectedExpense,
        message: 'Expense updated successfully',
      );
      return;
    }

    final createdExpense = state.selectedExpense;
    if (createdExpense == null) return;

    final message = pending.splitType == SplitType.custom
        ? 'Expense created. Select your items next.'
        : 'Expense created successfully';
    _completeSuccess(createdExpense: createdExpense, message: message);
  }

  void _completeSuccess({
    required Expense? createdExpense,
    required String message,
  }) {
    final pending = _pendingSubmission;
    _isSubmitting = false;

    _pendingSubmission = null;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    if (!mounted) return;

    if (pending != null &&
        !pending.isUpdate &&
        pending.splitType == SplitType.custom &&
        createdExpense != null) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.itemSelection,
        arguments: {'expenseId': createdExpense.id},
      );
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = context.watch<ChatBloc>().state;
    final currentUserId = context.read<AuthBloc>().state.user?.id ?? '';
    final isWaitingForChatRooms =
        _chatRooms.isEmpty &&
        (chatState.status == ChatStatus.initial ||
            chatState.status == ChatStatus.loading);

    return BlocConsumer<ExpenseBloc, ExpenseState>(
      listener: (context, state) => _handleBlocState(state),
      builder: (context, state) {
        return Scaffold(
          appBar: GlassAppBar(
            title: _isEditing ? 'Edit Expense' : 'Add Expense',
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              GlassStepIndicator(
                currentStep: _currentStep,
                totalSteps: _stepLabels.length,
                stepLabels: _stepLabels,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: GlassContainer(
                    borderRadius: 24,
                    child: _currentStep == 0
                        ? _SetupStep(
                            isEditing: _isEditing,
                            draft: _draft,
                            chatRooms: _eligibleChatRooms(),
                            isWaitingForChatRooms: isWaitingForChatRooms,
                            currentUserId: currentUserId,
                            titleController: _titleController,
                            descriptionController: _descriptionController,
                            amountController: _amountController,
                            adjustmentsExpanded: _adjustmentsExpanded,
                            onChatRoomChanged: _onChatRoomChanged,
                            onOpenChatRoomPicker: _openChatRoomPicker,
                            onSplitTypeChanged: _onSplitTypeChanged,
                            onOpenReceiptScanner: _openReceiptScanner,
                            onAddItem: _showAddItemDialog,
                            onRemoveItem: _removeItem,
                            onToggleAdjustments: () {
                              setState(() {
                                _adjustmentsExpanded = !_adjustmentsExpanded;
                              });
                            },
                            onTaxChanged: (value) {
                              setState(() {
                                _draft = _draft.copyWith(
                                  taxPercent: value,
                                  clearTaxPercent: value == null,
                                );
                              });
                            },
                            onServiceChargeChanged: (value) {
                              setState(() {
                                _draft = _draft.copyWith(
                                  serviceChargePercent: value,
                                  clearServiceChargePercent: value == null,
                                );
                              });
                            },
                            onDiscountChanged: (value) {
                              setState(() {
                                _draft = _draft.copyWith(
                                  discountPercent: value,
                                  clearDiscountPercent: value == null,
                                );
                              });
                            },
                          )
                        : _PeopleSubmitStep(
                            draft: _draft,
                            isEditing: _isEditing,
                            onIncludeCreatorChanged: _toggleIncludeCreator,
                            onMemberSelectionChanged: _toggleMemberSelection,
                          ),
                  ),
                ),
              ),
              _NavigationBar(
                currentStep: _currentStep,
                isSubmitting: _isSubmitting,
                isEditing: _isEditing,
                canSubmit: _currentStep == 0
                    ? _validateSetup() == null
                    : _canSubmit(),
                onContinue: _onStepContinue,
                onBack: _currentStep > 0 ? _onStepCancel : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SetupStep extends StatelessWidget {
  final bool isEditing;
  final _ExpenseDraft draft;
  final List<ChatRoom> chatRooms;
  final bool isWaitingForChatRooms;
  final String currentUserId;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController amountController;
  final bool adjustmentsExpanded;
  final ValueChanged<ChatRoom?> onChatRoomChanged;
  final VoidCallback onOpenChatRoomPicker;
  final ValueChanged<SplitType> onSplitTypeChanged;
  final VoidCallback onOpenReceiptScanner;
  final VoidCallback onAddItem;
  final void Function(String itemId) onRemoveItem;
  final VoidCallback onToggleAdjustments;
  final ValueChanged<double?> onTaxChanged;
  final ValueChanged<double?> onServiceChargeChanged;
  final ValueChanged<double?> onDiscountChanged;

  const _SetupStep({
    required this.isEditing,
    required this.draft,
    required this.chatRooms,
    required this.isWaitingForChatRooms,
    required this.currentUserId,
    required this.titleController,
    required this.descriptionController,
    required this.amountController,
    required this.adjustmentsExpanded,
    required this.onChatRoomChanged,
    required this.onOpenChatRoomPicker,
    required this.onSplitTypeChanged,
    required this.onOpenReceiptScanner,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onToggleAdjustments,
    required this.onTaxChanged,
    required this.onServiceChargeChanged,
    required this.onDiscountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: titleController,
          label: 'Title',
          hint: 'e.g., Dinner at Restaurant',
          prefixIcon: Icons.receipt,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: descriptionController,
          label: 'Description (Optional)',
          hint: 'Add any notes',
          prefixIcon: Icons.notes,
          maxLines: 2,
        ),
        const SizedBox(height: 24),
        if (draft.expenseType == ExpenseType.adHoc)
          const GlassContainer(
            borderRadius: 24,
            child: Text(
              'Ad-hoc still uses the legacy flow and is not optimized in this pass.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          _RoomContextSelector(
            currentUserId: currentUserId,
            selectedChatRoom: draft.selectedChatRoom,
            chatRooms: chatRooms,
            isWaitingForChatRooms: isWaitingForChatRooms,
            isEditing: isEditing,
            onPressed: onOpenChatRoomPicker,
          ),
        const SizedBox(height: 24),
        Text(
          'Split Setup',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        RadioGroup<SplitType>(
          groupValue: draft.splitType,
          onChanged: (value) {
            if (value != null) {
              onSplitTypeChanged(value);
            }
          },
          child: const Column(
            children: [
              RadioListTile<SplitType>(
                title: Text('Equal Split'),
                subtitle: Text('Everyone pays the same amount'),
                value: SplitType.equal,
              ),
              RadioListTile<SplitType>(
                title: Text('Custom Split (By Items)'),
                subtitle: Text(
                  'Participants select their own items after create',
                ),
                value: SplitType.custom,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (draft.splitType == SplitType.equal)
          _EqualSplitInput(controller: amountController)
        else
          _ItemsInput(
            items: draft.items,
            subtotal: draft.subtotal,
            onOpenReceiptScanner: onOpenReceiptScanner,
            onAddItem: onAddItem,
            onRemoveItem: onRemoveItem,
          ),
        const SizedBox(height: 24),
        _AdjustmentsSection(
          expanded: adjustmentsExpanded,
          draft: draft,
          onToggle: onToggleAdjustments,
          onTaxChanged: onTaxChanged,
          onServiceChargeChanged: onServiceChargeChanged,
          onDiscountChanged: onDiscountChanged,
        ),
      ],
    );
  }
}

class _PeopleSubmitStep extends StatelessWidget {
  final _ExpenseDraft draft;
  final bool isEditing;
  final ValueChanged<bool> onIncludeCreatorChanged;
  final void Function(String memberId, bool? isSelected)
  onMemberSelectionChanged;

  const _PeopleSubmitStep({
    required this.draft,
    required this.isEditing,
    required this.onIncludeCreatorChanged,
    required this.onMemberSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedMembers = draft.selectedMembers
        .where((member) => member.isSelected)
        .toList();
    final isCompactOneOnOne =
        draft.expenseType == ExpenseType.oneOnOne &&
        draft.selectedMembers.length <= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'People & Submit',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Switch(
              value: draft.includeCreator,
              onChanged: onIncludeCreatorChanged,
              activeThumbColor: AppColors.primary,
            ),
            const Text(
              'Include me',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (draft.selectedMembers.isEmpty)
          GlassContainer(
            borderRadius: 24,
            child: Text(
              draft.expenseType == ExpenseType.adHoc
                  ? 'Ad-hoc participants are not available in this screen yet.'
                  : 'Select a chat room first to load members.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else if (isCompactOneOnOne)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: draft.selectedMembers.map((member) {
              return FilterChip(
                selected: member.isSelected,
                onSelected: isEditing
                    ? null
                    : (value) => onMemberSelectionChanged(member.id, value),
                label: Text(
                  member.isCreator ? '${member.name} (You)' : member.name,
                ),
                selectedColor: AppColors.primary.withValues(alpha: 0.18),
                checkmarkColor: AppColors.primary,
                side: const BorderSide(color: AppColors.glassBorder),
              );
            }).toList(),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: draft.selectedMembers.length,
            itemBuilder: (context, index) {
              final member = draft.selectedMembers[index];
              return CheckboxListTile(
                value: member.isSelected,
                onChanged: isEditing
                    ? null
                    : (value) => onMemberSelectionChanged(member.id, value),
                title: Text(
                  member.name,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: member.isCreator
                    ? const Text(
                        '(You)',
                        style: TextStyle(color: AppColors.textSecondary),
                      )
                    : null,
                activeColor: AppColors.primary,
                checkColor: AppColors.background,
                secondary: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 20),
        if (draft.splitType == SplitType.custom)
          const GlassContainer(
            borderRadius: 24,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Final custom shares are calculated after each participant selects their items.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              _SummaryRow(
                label: 'Total',
                value: 'RM ${draft.total.toStringAsFixed(2)}',
                isWhite: true,
              ),
              _SummaryRow(
                label: 'Selected members',
                value: '${selectedMembers.length}',
                isWhite: true,
              ),
              _SummaryRow(
                label: draft.splitType == SplitType.equal
                    ? 'Per person'
                    : 'Split mode',
                value: draft.splitType == SplitType.equal
                    ? 'RM ${draft.perPersonAmount.toStringAsFixed(2)}'
                    : 'Item selection required',
                isWhite: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (selectedMembers.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedMembers
                .map(
                  (member) => Chip(
                    avatar: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        member.name.isNotEmpty
                            ? member.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.background,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    label: Text(
                      member.name,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    backgroundColor: AppColors.glassBackground,
                    side: const BorderSide(color: AppColors.glassBorder),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _NavigationBar extends StatelessWidget {
  final int currentStep;
  final bool isSubmitting;
  final bool isEditing;
  final bool canSubmit;
  final VoidCallback onContinue;
  final VoidCallback? onBack;

  const _NavigationBar({
    required this.currentStep,
    required this.isSubmitting,
    required this.isEditing,
    required this.canSubmit,
    required this.onContinue,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final canTapPrimary = canSubmit || currentStep == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(
          top: BorderSide(color: AppColors.glassBorder, width: 1.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: IgnorePointer(
                ignoring: !canTapPrimary || isSubmitting,
                child: Opacity(
                  opacity: canTapPrimary ? 1 : 0.45,
                  child: GlassButton(
                    text: currentStep == 0
                        ? 'Continue'
                        : (isEditing ? 'Update Expense' : 'Create Expense'),
                    onPressed: onContinue,
                    isLoading: isSubmitting,
                    isPrimary: true,
                  ),
                ),
              ),
            ),
            if (onBack != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: IgnorePointer(
                  ignoring: isSubmitting,
                  child: GlassButton(text: 'Back', onPressed: onBack!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoomContextSelector extends StatelessWidget {
  final String currentUserId;
  final ChatRoom? selectedChatRoom;
  final List<ChatRoom> chatRooms;
  final bool isWaitingForChatRooms;
  final bool isEditing;
  final VoidCallback onPressed;

  const _RoomContextSelector({
    required this.currentUserId,
    required this.selectedChatRoom,
    required this.chatRooms,
    required this.isWaitingForChatRooms,
    required this.isEditing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedRoom = selectedChatRoom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Who is this with?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (isWaitingForChatRooms)
          GlassContainer(
            borderRadius: 24,
            child: Text(
              'Loading chats...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else if (selectedRoom != null)
          GlassCard(
            onTap: isEditing ? null : onPressed,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    selectedRoom.members.length == 2
                        ? Icons.person_outline
                        : Icons.groups_2_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedRoom.displayNameFor(currentUserId),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedRoom.members.length == 2
                            ? 'Split with a direct chat'
                            : 'Split with a group chat',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${selectedRoom.members.length} members',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isEditing)
                  TextButton(onPressed: onPressed, child: const Text('Change')),
              ],
            ),
          )
        else if (chatRooms.isEmpty)
          GlassContainer(
            borderRadius: 24,
            child: Text(
              'No chats available for expenses.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          GlassCard(
            onTap: onPressed,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose a chat',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pick a direct or group chat to derive the expense type.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.expand_more, color: AppColors.primary),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChatRoomPickerSheet extends StatefulWidget {
  final String currentUserId;
  final List<ChatRoom> chatRooms;
  final String? selectedChatRoomId;

  const _ChatRoomPickerSheet({
    required this.currentUserId,
    required this.chatRooms,
    required this.selectedChatRoomId,
  });

  @override
  State<_ChatRoomPickerSheet> createState() => _ChatRoomPickerSheetState();
}

class _ChatRoomPickerSheetState extends State<_ChatRoomPickerSheet> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final directs = _filteredRooms(isDirect: true);
    final groups = _filteredRooms(isDirect: false);

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.55),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Who is this with?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose a direct or group chat. The expense type is derived automatically.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('chat_room_search_field'),
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Search chats',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: directs.isEmpty && groups.isEmpty
                    ? const Center(
                        child: Text(
                          'No chats match your search.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView(
                        children: [
                          if (directs.isNotEmpty) ...[
                            const _SectionHeader(title: 'Recent Direct Chats'),
                            ...directs.map(_buildRoomTile),
                          ],
                          if (groups.isNotEmpty) ...[
                            const _SectionHeader(title: 'Recent Group Chats'),
                            ...groups.map(_buildRoomTile),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ChatRoom> _filteredRooms({required bool isDirect}) {
    final normalized = _query.toLowerCase();
    return widget.chatRooms.where((room) {
      final roomIsDirect = room.members.length == 2;
      if (roomIsDirect != isDirect) return false;
      if (normalized.isEmpty) return true;
      final name = room.displayNameFor(widget.currentUserId).toLowerCase();
      return name.contains(normalized);
    }).toList();
  }

  Widget _buildRoomTile(ChatRoom room) {
    final displayName = room.displayNameFor(widget.currentUserId);
    final isSelected = room.id == widget.selectedChatRoomId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: () => Navigator.pop(context, room),
        padding: const EdgeInsets.all(16),
        borderColor: isSelected ? AppColors.primary : null,
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isSelected
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : AppColors.secondary.withValues(alpha: 0.12),
              child: Icon(
                room.members.length == 2
                    ? Icons.person_outline
                    : Icons.groups_2_outlined,
                color: isSelected ? AppColors.primary : AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName.isEmpty ? 'Chat' : displayName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    room.members.length == 2
                        ? 'Direct chat'
                        : '${room.members.length} members',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EqualSplitInput extends StatelessWidget {
  final TextEditingController controller;

  const _EqualSplitInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: controller,
          label: 'Total Amount',
          hint: 'Enter total amount',
          prefixIcon: Icons.attach_money,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }
}

class _ItemsInput extends StatelessWidget {
  final List<ExpenseItem> items;
  final double subtotal;
  final VoidCallback onOpenReceiptScanner;
  final VoidCallback onAddItem;
  final void Function(String itemId) onRemoveItem;

  const _ItemsInput({
    required this.items,
    required this.subtotal,
    required this.onOpenReceiptScanner,
    required this.onAddItem,
    required this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Items (${items.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onOpenReceiptScanner,
                  icon: const Icon(
                    Icons.document_scanner,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'Scan',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
                TextButton.icon(
                  onPressed: onAddItem,
                  icon: const Icon(
                    Icons.add,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'Add',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          GlassContainer(
            borderRadius: 24,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 180),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No items added yet',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add items manually or scan a receipt',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${item.quantity}x',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'RM ${item.price.toStringAsFixed(2)} each',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'RM ${item.subtotal.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        onPressed: () => onRemoveItem(item.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'RM ${subtotal.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AdjustmentsSection extends StatelessWidget {
  final bool expanded;
  final _ExpenseDraft draft;
  final VoidCallback onToggle;
  final ValueChanged<double?> onTaxChanged;
  final ValueChanged<double?> onServiceChargeChanged;
  final ValueChanged<double?> onDiscountChanged;

  const _AdjustmentsSection({
    required this.expanded,
    required this.draft,
    required this.onToggle,
    required this.onTaxChanged,
    required this.onServiceChargeChanged,
    required this.onDiscountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Fees & Discounts',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  expanded ? 'Hide' : 'Add',
                  style: const TextStyle(color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 8),
          _PercentageField(
            label: 'Tax %',
            value: draft.taxPercent,
            amountLabel: '+ RM ${draft.taxAmount.toStringAsFixed(2)}',
            onChanged: onTaxChanged,
          ),
          const SizedBox(height: 12),
          _PercentageField(
            label: 'Service Charge %',
            value: draft.serviceChargePercent,
            amountLabel: '+ RM ${draft.serviceChargeAmount.toStringAsFixed(2)}',
            onChanged: onServiceChargeChanged,
          ),
          const SizedBox(height: 12),
          _PercentageField(
            label: 'Discount %',
            value: draft.discountPercent,
            amountLabel: '- RM ${draft.discountAmount.toStringAsFixed(2)}',
            onChanged: onDiscountChanged,
            isDiscount: true,
          ),
          const SizedBox(height: 24),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              _SummaryRow(
                label: 'Subtotal',
                value: 'RM ${draft.subtotal.toStringAsFixed(2)}',
                isWhite: true,
              ),
              if (draft.taxAmount > 0)
                _SummaryRow(
                  label: 'Tax',
                  value: 'RM ${draft.taxAmount.toStringAsFixed(2)}',
                  isWhite: true,
                ),
              if (draft.serviceChargeAmount > 0)
                _SummaryRow(
                  label: 'Service',
                  value: 'RM ${draft.serviceChargeAmount.toStringAsFixed(2)}',
                  isWhite: true,
                ),
              if (draft.discountAmount > 0)
                _SummaryRow(
                  label: 'Discount',
                  value: '-RM ${draft.discountAmount.toStringAsFixed(2)}',
                  isWhite: true,
                ),
              const Divider(color: Colors.white24),
              _SummaryRow(
                label: 'Total',
                value: 'RM ${draft.total.toStringAsFixed(2)}',
                isWhite: true,
                isStrong: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PercentageField extends StatelessWidget {
  final String label;
  final double? value;
  final String amountLabel;
  final bool isDiscount;
  final ValueChanged<double?> onChanged;

  const _PercentageField({
    required this.label,
    required this.value,
    required this.amountLabel,
    required this.onChanged,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
        Expanded(
          flex: 3,
          child: TextFormField(
            key: ValueKey('${label}_${value ?? 'empty'}'),
            initialValue: value?.toString() ?? '',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: '0',
              suffixText: '%',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            onChanged: (text) => onChanged(double.tryParse(text)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            amountLabel,
            style: TextStyle(
              color: isDiscount ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isWhite;
  final bool isStrong;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isWhite = false,
    this.isStrong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isWhite ? Colors.white70 : AppColors.textSecondary,
              fontWeight: isStrong ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isWhite ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: isStrong ? 20 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

enum SplitType { equal, custom }

class SelectedMember {
  final String id;
  final String name;
  final bool isSelected;
  final bool isCreator;

  const SelectedMember({
    required this.id,
    required this.name,
    this.isSelected = true,
    this.isCreator = false,
  });

  SelectedMember copyWith({
    String? id,
    String? name,
    bool? isSelected,
    bool? isCreator,
  }) {
    return SelectedMember(
      id: id ?? this.id,
      name: name ?? this.name,
      isSelected: isSelected ?? this.isSelected,
      isCreator: isCreator ?? this.isCreator,
    );
  }
}

class _ExpenseDraft {
  final String title;
  final String description;
  final ExpenseType expenseType;
  final SplitType splitType;
  final bool includeCreator;
  final ChatRoom? selectedChatRoom;
  final List<ExpenseItem> items;
  final double? manualAmount;
  final double? taxPercent;
  final double? serviceChargePercent;
  final double? discountPercent;
  final List<SelectedMember> selectedMembers;

  const _ExpenseDraft({
    this.title = '',
    this.description = '',
    this.expenseType = ExpenseType.group,
    this.splitType = SplitType.equal,
    this.includeCreator = true,
    this.selectedChatRoom,
    this.items = const [],
    this.manualAmount,
    this.taxPercent,
    this.serviceChargePercent,
    this.discountPercent,
    this.selectedMembers = const [],
  });

  double get subtotal {
    if (splitType == SplitType.equal) {
      return manualAmount ?? 0;
    }
    return items.fold(0, (sum, item) => sum + item.subtotal);
  }

  double get taxAmount =>
      taxPercent == null ? 0 : subtotal * (taxPercent! / 100);
  double get serviceChargeAmount => serviceChargePercent == null
      ? 0
      : subtotal * (serviceChargePercent! / 100);
  double get discountAmount =>
      discountPercent == null ? 0 : subtotal * (discountPercent! / 100);
  double get total =>
      subtotal + taxAmount + serviceChargeAmount - discountAmount;
  int get selectedMemberCount =>
      selectedMembers.where((member) => member.isSelected).length;
  double get perPersonAmount =>
      selectedMemberCount == 0 ? 0 : total / selectedMemberCount;

  _ExpenseDraft copyWith({
    String? title,
    String? description,
    ExpenseType? expenseType,
    SplitType? splitType,
    bool? includeCreator,
    ChatRoom? selectedChatRoom,
    bool clearSelectedChatRoom = false,
    List<ExpenseItem>? items,
    double? manualAmount,
    bool clearManualAmount = false,
    double? taxPercent,
    bool clearTaxPercent = false,
    double? serviceChargePercent,
    bool clearServiceChargePercent = false,
    double? discountPercent,
    bool clearDiscountPercent = false,
    List<SelectedMember>? selectedMembers,
  }) {
    return _ExpenseDraft(
      title: title ?? this.title,
      description: description ?? this.description,
      expenseType: expenseType ?? this.expenseType,
      splitType: splitType ?? this.splitType,
      includeCreator: includeCreator ?? this.includeCreator,
      selectedChatRoom: clearSelectedChatRoom
          ? null
          : (selectedChatRoom ?? this.selectedChatRoom),
      items: items ?? this.items,
      manualAmount: clearManualAmount
          ? null
          : (manualAmount ?? this.manualAmount),
      taxPercent: clearTaxPercent ? null : (taxPercent ?? this.taxPercent),
      serviceChargePercent: clearServiceChargePercent
          ? null
          : (serviceChargePercent ?? this.serviceChargePercent),
      discountPercent: clearDiscountPercent
          ? null
          : (discountPercent ?? this.discountPercent),
      selectedMembers: selectedMembers ?? this.selectedMembers,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _ExpenseDraft &&
        other.title == title &&
        other.description == description &&
        other.expenseType == expenseType &&
        other.splitType == splitType &&
        other.includeCreator == includeCreator &&
        other.selectedChatRoom == selectedChatRoom &&
        _listEquals(other.items, items) &&
        other.manualAmount == manualAmount &&
        other.taxPercent == taxPercent &&
        other.serviceChargePercent == serviceChargePercent &&
        other.discountPercent == discountPercent &&
        _listEquals(other.selectedMembers, selectedMembers);
  }

  @override
  int get hashCode => Object.hash(
    title,
    description,
    expenseType,
    splitType,
    includeCreator,
    selectedChatRoom,
    items.length,
    manualAmount,
    taxPercent,
    serviceChargePercent,
    discountPercent,
    selectedMembers.length,
  );
}

class _PendingSubmission {
  final bool isUpdate;
  final SplitType splitType;

  const _PendingSubmission._({required this.isUpdate, required this.splitType});

  factory _PendingSubmission.forCreate({required SplitType splitType}) {
    return _PendingSubmission._(isUpdate: false, splitType: splitType);
  }

  factory _PendingSubmission.forUpdate({required SplitType splitType}) {
    return _PendingSubmission._(isUpdate: true, splitType: splitType);
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class _AddItemDialog extends StatefulWidget {
  final void Function(String name, double price, int quantity) onItemAdded;

  const _AddItemDialog({required this.onItemAdded});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _quantityController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundLight,
      title: const Text(
        'Add Item',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Item Name',
              hintText: 'e.g., Nasi Lemak',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              hintStyle: TextStyle(color: AppColors.textTertiary),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Price',
              prefixText: 'RM ',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              prefixStyle: TextStyle(color: AppColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Quantity',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final price = double.tryParse(_priceController.text);
            final quantity = int.tryParse(_quantityController.text) ?? 1;

            if (name.isNotEmpty && price != null && price > 0 && quantity > 0) {
              widget.onItemAdded(name, price, quantity);
              Navigator.pop(context);
            }
          },
          child: const Text('Add', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }
}
