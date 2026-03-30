import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/bill_payment_verification_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../injection_container.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../chat/domain/entities/message.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart';
import 'package:pulse/features/living_tools/domain/entities/bill.dart';
import 'package:pulse/features/living_tools/domain/services/bill_report_service.dart';
import 'package:pulse/features/living_tools/presentation/bloc/living_tools_bloc.dart';
import 'package:pulse/features/living_tools/presentation/widgets/add_bill_form.dart';
import 'package:pulse/features/living_tools/presentation/widgets/bill_card.dart';
import 'package:pulse/features/living_tools/presentation/widgets/bill_payment_proof_sheet.dart';

class LivingToolsScreen extends StatefulWidget {
  const LivingToolsScreen({super.key});

  @override
  State<LivingToolsScreen> createState() => _LivingToolsScreenState();
}

class _LivingToolsScreenState extends State<LivingToolsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final LivingToolsBloc _livingToolsBloc;
  String? _currentUserId;
  String? _currentUserName;
  String _selectedGroupId = 'all';
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _livingToolsBloc = context.read<LivingToolsBloc>();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        _livingToolsBloc.add(
          LivingToolsTabChanged(tabIndex: _tabController.index),
        );
      }
    });

    final user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid ?? '';
    _currentUserName = user?.displayName ?? 'Unknown';

    _loadBills();
  }

  void _loadBills() {
    final chatState = context.read<ChatBloc>().state;
    final chatRoomIds = chatState.chatRooms.map((r) => r.id).toList();
    _livingToolsBloc.add(
      LivingToolsLoadRequested(
        userId: _currentUserId!,
        chatRoomIds: chatRoomIds,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Bill> _getFilteredBills(List<Bill> bills) {
    return bills.where((bill) {
      final matchesGroup =
          _selectedGroupId == 'all' || bill.chatRoomId == _selectedGroupId;
      final matchesCategory =
          _selectedCategory == 'all' || bill.type.name == _selectedCategory;
      return matchesGroup && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Shared Bills',
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: _livingToolsBloc.state.bills.isEmpty
                ? null
                : () {
                    final chatState = context.read<ChatBloc>().state;
                    final Map<String, String> roomNames = {
                      for (var room in chatState.chatRooms) room.id: room.name,
                    };

                    BillReportService.generateAndPrintReport(
                      bills: _livingToolsBloc.state.allBills,
                      userName: _currentUserName ?? 'Pulse User',
                      chatRoomNames: roomNames,
                    );
                  },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<LivingToolsBloc, LivingToolsState>(
        bloc: _livingToolsBloc,
        builder: (context, state) {
          final filteredBills = _getFilteredBills(state.allBills);
          double filteredTotalOwed = 0;
          for (final bill in filteredBills) {
            final member = bill.members
                .where((m) => m.userId == _currentUserId)
                .firstOrNull;
            if (member != null && !member.hasPaid) {
              filteredTotalOwed += member.share;
            }
          }

          return Column(
            children: [
              _buildSummaryHeader(state, filteredTotalOwed),
              _buildFilterBar(),
              _buildTabChips(state),
              Expanded(child: _buildContent(state)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBillSheet(context),
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 32),
      ),
    );
  }

  Widget _buildSummaryHeader(LivingToolsState state, double filteredTotalOwed) {
    final filteredBills = _getFilteredBills(state.allBills);
    double filteredGroupTotal = 0;
    for (final bill in filteredBills) {
      filteredGroupTotal += bill.amount;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR BALANCE',
                      style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RM ${filteredTotalOwed.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 1,
              width: double.infinity,
              color: AppColors.getGlassBorder(0.1),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildMiniStat(
                  'Group Total',
                  'RM ${filteredGroupTotal.toStringAsFixed(2)}',
                  Icons.group_outlined,
                ),
                const Spacer(),
                _buildMiniStat(
                  'Pending',
                  '${_getFilteredBills(state.pendingBills).length} Bills',
                  Icons.timer_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final chatRooms = context.read<ChatBloc>().state.chatRooms;
    final categories = [
      {'id': 'all', 'name': 'All', 'icon': Icons.all_inclusive},
      {'id': 'rent', 'name': 'Rent', 'icon': Icons.home_rounded},
      {'id': 'utilities', 'name': 'Utilities', 'icon': Icons.bolt_rounded},
      {'id': 'internet', 'name': 'Internet', 'icon': Icons.wifi_rounded},
      {
        'id': 'cleaning',
        'name': 'Cleaning',
        'icon': Icons.cleaning_services_rounded,
      },
      {'id': 'water', 'name': 'Water', 'icon': Icons.water_drop_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
          child: Text(
            'GROUPS',
            style: TextStyle(
              color: AppColors.textTertiary.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
        // Group Filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _buildFilterChip(
                label: 'All Groups',
                isSelected: _selectedGroupId == 'all',
                onTap: () => setState(() => _selectedGroupId = 'all'),
              ),
              ...chatRooms.map(
                (room) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _buildFilterChip(
                    label: room.name,
                    isSelected: _selectedGroupId == room.id,
                    onTap: () => setState(() => _selectedGroupId = room.id),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
          child: Text(
            'CATEGORIES',
            style: TextStyle(
              color: AppColors.textTertiary.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
        // Category Filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: categories
                .map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(
                      label: cat['name'] as String,
                      isSelected: _selectedCategory == cat['id'],
                      onTap: () => setState(
                        () => _selectedCategory = cat['id'] as String,
                      ),
                      icon: cat['icon'] as IconData,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.getGlassBackground(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.getGlassBorder(0.2),
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.black : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabChips(LivingToolsState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildTabChip(
            icon: Icons.receipt_long_rounded,
            label: 'All',
            count: state.allBills.length,
            color: AppColors.primary,
            index: 0,
            selectedIndex: state.selectedTab,
          ),
          const SizedBox(width: 10),
          _buildTabChip(
            icon: Icons.schedule_rounded,
            label: 'Pending',
            count: state.pendingBills.length,
            color: AppColors.warning,
            index: 1,
            selectedIndex: state.selectedTab,
            badgeCount: state.overdueBills.length,
          ),
          const SizedBox(width: 10),
          _buildTabChip(
            icon: Icons.check_circle_rounded,
            label: 'Paid',
            count: state.paidBills.length,
            color: AppColors.success,
            index: 2,
            selectedIndex: state.selectedTab,
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required int index,
    required int selectedIndex,
    int badgeCount = 0,
  }) {
    final isSelected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withValues(alpha: 0.2),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? color : Colors.grey[500],
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$label ($count)',
                    style: TextStyle(
                      color: isSelected ? color : Colors.grey[600],
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (badgeCount > 0)
                Positioned(
                  right: 8,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(LivingToolsState state) {
    if (state.status == LivingToolsStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == LivingToolsStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(state.errorMessage ?? 'An error occurred'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadBills, child: const Text('Retry')),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildBillsList(_getFilteredBills(state.allBills)),
        _buildBillsList(_getFilteredBills(state.pendingBills)),
        _buildBillsList(_getFilteredBills(state.paidBills)),
      ],
    );
  }

  Widget _buildBillsList(List<Bill> bills) {
    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No bills here',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a bill to get started',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: bills.length,
        itemBuilder: (context, index) {
          final bill = bills[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: BillCard(
                  bill: bill,
                  currentUserId: _currentUserId!,
                  onTap: () => _showBillDetails(context, bill),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showBillDetails(BuildContext context, Bill bill) {
    final theme = Theme.of(context);
    final isPaid = bill.status == BillStatus.paid;
    final hasUserPaid = bill.hasUserPaid(_currentUserId!);
    final yourShare = bill.getShareForUser(_currentUserId!);
    final yourMember = bill.members
        .where((m) => m.userId == _currentUserId)
        .firstOrNull;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      bill.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (bill.isRecurring)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'Recurring',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(
                'Total Amount',
                'RM ${bill.amount.toStringAsFixed(2)}',
              ),
              _buildDetailRow(
                'Your Share',
                'RM ${yourShare.toStringAsFixed(2)}',
              ),
              _buildDetailRow(
                'Issued At',
                DateFormatter.formatDateTime(bill.createdAt),
              ),
              _buildDetailRow('Due Date', _formatDate(bill.dueDate)),
              _buildDetailRow('Split Between', '${bill.members.length} people'),
              const SizedBox(height: 28),
              Text(
                'Payment Status',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...bill.members.map(
                (member) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.secondary.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            member.userName.isNotEmpty
                                ? member.userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.userId == _currentUserId
                                    ? 'You'
                                    : member.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'RM ${member.share.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (member.hasPaid)
                          const Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.success,
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Paid',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          if (member.userId != _currentUserId &&
                              _currentUserId == bill.createdBy)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.notifications_active_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                tooltip: 'Send Nudge',
                                onPressed: () {
                                  _livingToolsBloc.add(
                                    LivingToolsBillMemberNudged(
                                      billId: bill.id,
                                      memberId: member.id,
                                    ),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Nudged ${member.userName}!',
                                      ),
                                      backgroundColor: AppColors.primary,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ),
                          const Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Pending',
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (!hasUserPaid && yourMember != null)
                bill.createdBy == _currentUserId
                    ? CustomButton(
                        text: 'Mark as Paid',
                        icon: Icons.check_circle_outline,
                        backgroundColor: AppColors.success,
                        onPressed: () {
                          _livingToolsBloc.add(
                            LivingToolsBillPaymentStatusUpdated(
                              billId: bill.id,
                              memberId: _currentUserId!,
                              status: BillPaymentStatus.verified,
                            ),
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Marked yourself as paid!')),
                          );
                        },
                      )
                    : CustomButton(
                        text: 'Pay & Upload Proof',
                        icon: Icons.payments_outlined,
                        backgroundColor: AppColors.secondary,
                        onPressed: () {
                          // Close the detail dialog first
                          Navigator.pop(context);
                          // Show the payment proof sheet
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => BillPaymentProofSheet(
                              bill: bill,
                              member: yourMember,
                              verificationService: sl<BillPaymentVerificationService>(),
                            ),
                          );
                        },
                      )
              else if (isPaid || hasUserPaid)
                const GlassCard(
                  padding: EdgeInsets.all(18),
                  borderColor: AppColors.success,
                  borderOpacity: 0.4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'You have paid this bill',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _shareBillToChat(bill);
                },
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share to Group Chat'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  void _shareBillToChat(Bill bill) {
    final chatState = context.read<ChatBloc>().state;
    final chatRoom = chatState.chatRooms
        .where((r) => r.id == bill.chatRoomId)
        .firstOrNull;

    if (chatRoom != null) {
      final yourShare = bill.getShareForUser(_currentUserId!);
      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _currentUserId!,
        senderName: _currentUserName!,
        content: 'Shared a bill: ${bill.title}',
        chatRoomId: chatRoom.id,
        timestamp: DateTime.now(),
        type: MessageType.bill,
        eventData: {
          'billId': bill.id,
          'title': bill.title,
          'amount': bill.amount,
          'dueDate': bill.dueDate.toIso8601String(),
          'type': bill.type.name,
          'yourShare': yourShare,
        },
      );

      context.read<ChatBloc>().add(MessageSendRequested(message: message));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bill "${bill.title}" shared to ${chatRoom.name}!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showAddBillSheet(BuildContext context) {
    final chatState = context.read<ChatBloc>().state;
    final chatRooms = chatState.chatRooms;

    if (chatRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please start a chat first')),
      );
      return;
    }

    if (chatRooms.length == 1) {
      _openAddBillForm(context, chatRooms.first);
    } else {
      _showChatRoomSelector(context, chatRooms);
    }
  }

  void _showChatRoomSelector(BuildContext context, List<dynamic> chatRooms) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppColors.getGlassBorder(0.3)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Chat Room',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: chatRooms.length,
                itemBuilder: (context, index) {
                  final room = chatRooms[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: EdgeInsets.zero,
                      onTap: () {
                        Navigator.pop(context);
                        _openAddBillForm(context, room);
                      },
                      child: ListTile(
                        leading: const Icon(
                          Icons.group_rounded,
                          color: AppColors.secondary,
                        ),
                        title: Text(
                          room.name,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _openAddBillForm(BuildContext context, dynamic chatRoom) {
    final List<Map<String, String>> members = [];
    for (final memberId in chatRoom.members) {
      final name = chatRoom.memberNames[memberId] ?? 'Unknown';
      members.add({
        'id': memberId,
        'name': name,
        'avatar': name.isNotEmpty ? name[0].toUpperCase() : '?',
      });
    }

    final livingToolsBloc = context.read<LivingToolsBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AddBillForm(
        currentUserId: _currentUserId!,
        currentUserName: _currentUserName!,
        chatRoomId: chatRoom.id,
        chatRoomName: chatRoom.name,
        members: members,
        onSubmit: (bill) {
          livingToolsBloc.add(LivingToolsBillCreated(bill: bill));
          Navigator.pop(sheetContext); // Close the sheet after submission
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bill "${bill.title}" added to ${chatRoom.name}!'),
              backgroundColor: AppColors.secondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
