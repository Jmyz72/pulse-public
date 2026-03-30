import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/initials_avatar.dart';
import '../../domain/entities/bill.dart';

class AddBillForm extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String chatRoomId;
  final String chatRoomName;
  final List<Map<String, String>> members;
  final Function(Bill) onSubmit;

  const AddBillForm({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.chatRoomId,
    required this.chatRoomName,
    required this.members,
    required this.onSubmit,
  });

  @override
  State<AddBillForm> createState() => _AddBillFormState();
}

class _AddBillFormState extends State<AddBillForm> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _duitNowIdController = TextEditingController();
  
  BillType _selectedType = BillType.utilities;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isRecurring = false;
  String _recurringInterval = 'monthly';
  Set<String> _selectedMemberIds = {};

  @override
  void initState() {
    super.initState();
    _selectedMemberIds = widget.members.map((m) => m['id']!).toSet();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _duitNowIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = double.tryParse(_amountController.text) ?? 0;
    final splitCount = _selectedMemberIds.length;
    final perPerson = splitCount > 0 ? amount / splitCount : 0.0;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.getGlassBorder(0.3)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.getGlassBorder(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildHeader(theme),
            const SizedBox(height: 28),
            _buildCategorySelector(theme),
            const SizedBox(height: 24),
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 16),
            _buildAmountField(),
            const SizedBox(height: 20),
            _buildMemberSelector(theme),
            const SizedBox(height: 16),
            _buildDueDatePicker(theme),
            const SizedBox(height: 24),
            _buildPaymentDetailsFields(theme),
            const SizedBox(height: 16),
            _buildRecurringToggle(theme),
            const SizedBox(height: 20),
            if (amount > 0) _buildPerPersonPreview(perPerson),
            const SizedBox(height: 28),
            _buildSubmitButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsFields(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Details (Where members should pay)',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.secondary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bankNameController,
          decoration: InputDecoration(
            labelText: 'Bank Name',
            hintText: 'e.g., Maybank',
            prefixIcon: const Icon(Icons.account_balance_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _accountNumberController,
          decoration: InputDecoration(
            labelText: 'Account Number',
            prefixIcon: const Icon(Icons.numbers_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _accountNameController,
          decoration: InputDecoration(
            labelText: 'Account Name',
            prefixIcon: const Icon(Icons.person_pin_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _duitNowIdController,
          decoration: InputDecoration(
            labelText: 'DuitNow ID (Optional)',
            hintText: 'Phone or IC',
            prefixIcon: const Icon(Icons.qr_code_2_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.secondary, Color(0xFF0D9488)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 16),
        Text(
          'Add New Bill',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(ThemeData theme) {
    final types = [
      {'type': BillType.rent, 'label': 'Rent', 'icon': Icons.home_rounded},
      {'type': BillType.utilities, 'label': 'Utilities', 'icon': Icons.bolt_rounded},
      {'type': BillType.internet, 'label': 'Internet', 'icon': Icons.wifi_rounded},
      {'type': BillType.cleaning, 'label': 'Cleaning', 'icon': Icons.cleaning_services_rounded},
      {'type': BillType.water, 'label': 'Water', 'icon': Icons.water_drop_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: types.map((type) {
              final billType = type['type'] as BillType;
              final isSelected = _selectedType == billType;
              final typeColor = _getBillColor(billType);

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedType = billType),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? typeColor : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? typeColor : Colors.grey.withValues(alpha: 0.25),
                        width: isSelected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          type['icon'] as IconData,
                          size: 20,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          type['label'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Bill Title',
        hintText: 'e.g., Electricity Bill',
        prefixIcon: const Icon(Icons.description_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'Add extra details (optional)',
        prefixIcon: const Icon(Icons.info_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: 'Amount (RM)',
        hintText: '0.00',
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  Widget _buildMemberSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Split With',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_selectedMemberIds.length == widget.members.length) {
                    _selectedMemberIds = {widget.currentUserId};
                  } else {
                    _selectedMemberIds = widget.members.map((m) => m['id']!).toSet();
                  }
                });
              },
              child: Text(
                _selectedMemberIds.length == widget.members.length ? 'Deselect All' : 'Select All',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: widget.members.map((member) {
            final isSelected = _selectedMemberIds.contains(member['id']);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected && _selectedMemberIds.length > 1) {
                    _selectedMemberIds.remove(member['id']);
                  } else if (!isSelected) {
                    _selectedMemberIds.add(member['id']!);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.secondary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.secondary : Colors.grey.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InitialsAvatar(
                      name: member['name']!,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      member['name']!,
                      style: TextStyle(
                        color: isSelected ? Colors.black : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: Colors.black,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDueDatePicker(ThemeData theme) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _dueDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) setState(() => _dueDate = date);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_today_rounded, color: AppColors.secondary, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Due Date', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  _formatDate(_dueDate),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringToggle(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isRecurring ? AppColors.secondary.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.04),
        border: Border.all(
          color: _isRecurring ? AppColors.secondary.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.autorenew_rounded,
                    color: _isRecurring ? AppColors.secondary : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Recurring',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _isRecurring ? AppColors.secondary : null,
                        ),
                      ),
                      Text(
                        'Auto-split every period',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
                activeThumbColor: AppColors.secondary,
              ),
            ],
          ),
          if (_isRecurring) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Weekly', 'Monthly', '1st of Month', 'Yearly'].map((interval) {
                final isSelected = _recurringInterval == interval.toLowerCase().replaceAll(' ', '_');
                return GestureDetector(
                  onTap: () => setState(() => _recurringInterval = interval.toLowerCase().replaceAll(' ', '_')),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.secondary : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? AppColors.secondary : Colors.grey.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      interval,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerPersonPreview(double perPerson) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Each person pays', style: TextStyle(color: Colors.grey[700])),
            ],
          ),
          Text(
            'RM ${perPerson.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _handleSubmit,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline_rounded),
          SizedBox(width: 10),
          Text('Add Bill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  void _handleSubmit() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (_titleController.text.isEmpty || amount <= 0) return;

    final sharePerPerson = amount / _selectedMemberIds.length;
    final members = _selectedMemberIds.map((id) {
      final member = widget.members.firstWhere((m) => m['id'] == id);
      return BillMember(
        id: DateTime.now().millisecondsSinceEpoch.toString() + id,
        userId: id,
        userName: member['name']!,
        share: sharePerPerson,
      );
    }).toList();

    final bill = Bill(
      id: '',
      type: _selectedType,
      title: _titleController.text,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      amount: amount,
      dueDate: _dueDate,
      status: BillStatus.pending,
      members: members,
      isRecurring: _isRecurring,
      recurringInterval: _isRecurring ? _recurringInterval : null,
      createdBy: widget.currentUserId,
      createdAt: DateTime.now(),
      chatRoomId: widget.chatRoomId,
      paymentDetails: BillPaymentDetails(
        bankName: _bankNameController.text.isNotEmpty ? _bankNameController.text : null,
        accountNumber: _accountNumberController.text.isNotEmpty ? _accountNumberController.text : null,
        accountName: _accountNameController.text.isNotEmpty ? _accountNameController.text : null,
        duitNowId: _duitNowIdController.text.isNotEmpty ? _duitNowIdController.text : null,
      ),
    );

    widget.onSubmit(bill);
    Navigator.pop(context);
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _getBillColor(BillType type) {
    switch (type) {
      case BillType.rent:
        return const Color(0xFF8B5CF6);
      case BillType.utilities:
        return const Color(0xFFF59E0B);
      case BillType.internet:
        return const Color(0xFF3B82F6);
      case BillType.cleaning:
        return const Color(0xFF10B981);
      case BillType.water:
        return const Color(0xFF06B6D4);
      case BillType.other:
        return const Color(0xFF6B7280);
    }
  }
}
