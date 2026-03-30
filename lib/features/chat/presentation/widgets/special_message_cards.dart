import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../location/presentation/bloc/event_bloc.dart';
import '../../../living_tools/presentation/bloc/living_tools_bloc.dart';
import '../../../living_tools/domain/entities/bill.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/image_lightbox.dart';

class ExpenseMessageCard extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final bool showSenderInCard;
  final VoidCallback? onViewDetails;
  final bool hasBeenRead;
  final bool isFailed;
  final VoidCallback? onReadReceiptsTap;
  final VoidCallback? onRetry;

  const ExpenseMessageCard({
    super.key,
    required this.message,
    required this.isMe,
    this.showSenderInCard = true,
    this.onViewDetails,
    this.hasBeenRead = false,
    this.isFailed = false,
    this.onReadReceiptsTap,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expense = message['expense'];
    final requiresItemSelection = expense['requiresItemSelection'] == true;
    const expenseColor = AppColors.expense;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppDimensions.chatBubbleRadius),
          topRight: const Radius.circular(AppDimensions.chatBubbleRadius),
          bottomLeft: Radius.circular(
            isMe ? AppDimensions.chatBubbleRadius : 6,
          ),
          bottomRight: Radius.circular(
            isMe ? 6 : AppDimensions.chatBubbleRadius,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            decoration: BoxDecoration(
              color: AppColors.getGlassBackground(0.05),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppDimensions.chatBubbleRadius),
                topRight: const Radius.circular(AppDimensions.chatBubbleRadius),
                bottomLeft: Radius.circular(
                  isMe ? AppDimensions.chatBubbleRadius : 6,
                ),
                bottomRight: Radius.circular(
                  isMe ? 6 : AppDimensions.chatBubbleRadius,
                ),
              ),
              border: Border.all(
                color: expenseColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        expenseColor,
                        expenseColor.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(19),
                      topRight: Radius.circular(19),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe && showSenderInCard)
                              Text(
                                message['senderName'],
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const Text(
                              AppStrings.splitExpense,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'RM ${expense['amount'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense['description'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildChip(
                            theme,
                            '${expense['members'].length} people',
                            Icons.people_outline,
                          ),
                          const SizedBox(width: 8),
                          _buildChip(
                            theme,
                            requiresItemSelection
                                ? 'Items selected later'
                                : 'RM ${expense['perPerson'].toStringAsFixed(2)}/each',
                            requiresItemSelection
                                ? Icons.pending_actions_outlined
                                : Icons.pie_chart_outline,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormatter.formatTime(message['timestamp']),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                if (isFailed)
                                  Icon(
                                    Icons.error_outline,
                                    size: 14,
                                    color: AppColors.error.withValues(
                                      alpha: 0.7,
                                    ),
                                  )
                                else
                                  GestureDetector(
                                    onTap: onReadReceiptsTap,
                                    child: Icon(
                                      Icons.done_all,
                                      size: 14,
                                      color: hasBeenRead
                                          ? Colors.lightBlueAccent
                                          : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                    ),
                                  ),
                                if (isFailed && onRetry != null) ...[
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: onRetry,
                                    child: Icon(
                                      Icons.refresh,
                                      size: 16,
                                      color: AppColors.error.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                          GestureDetector(
                            onTap: onViewDetails,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: expenseColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                AppStrings.viewExpenses,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: expenseColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(ThemeData theme, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.getGlassBackground(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class GroceryMessageCard extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final bool showSenderInCard;
  final VoidCallback? onViewList;
  final bool hasBeenRead;
  final bool isFailed;
  final VoidCallback? onReadReceiptsTap;
  final VoidCallback? onRetry;

  const GroceryMessageCard({
    super.key,
    required this.message,
    required this.isMe,
    this.showSenderInCard = true,
    this.onViewList,
    this.hasBeenRead = false,
    this.isFailed = false,
    this.onReadReceiptsTap,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grocery = message['grocery'];
    const groceryColor = AppColors.grocery;
    final items = List<Map<String, dynamic>>.from(
      grocery['items'] as List? ?? [],
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppDimensions.chatBubbleRadius),
          topRight: const Radius.circular(AppDimensions.chatBubbleRadius),
          bottomLeft: Radius.circular(
            isMe ? AppDimensions.chatBubbleRadius : 6,
          ),
          bottomRight: Radius.circular(
            isMe ? 6 : AppDimensions.chatBubbleRadius,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            decoration: BoxDecoration(
              color: AppColors.getGlassBackground(0.05),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppDimensions.chatBubbleRadius),
                topRight: const Radius.circular(AppDimensions.chatBubbleRadius),
                bottomLeft: Radius.circular(
                  isMe ? AppDimensions.chatBubbleRadius : 6,
                ),
                bottomRight: Radius.circular(
                  isMe ? 6 : AppDimensions.chatBubbleRadius,
                ),
              ),
              border: Border.all(
                color: groceryColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        groceryColor,
                        groceryColor.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(19),
                      topRight: Radius.circular(19),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.shopping_bag,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe && showSenderInCard)
                              Text(
                                message['senderName'],
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const Text(
                              AppStrings.shoppingList,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${items.length} items',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...items.map<Widget>(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildItemRow(context, theme, item),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormatter.formatTime(message['timestamp']),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                if (isFailed)
                                  Icon(
                                    Icons.error_outline,
                                    size: 14,
                                    color: AppColors.error.withValues(
                                      alpha: 0.7,
                                    ),
                                  )
                                else
                                  GestureDetector(
                                    onTap: onReadReceiptsTap,
                                    child: Icon(
                                      Icons.done_all,
                                      size: 14,
                                      color: hasBeenRead
                                          ? Colors.lightBlueAccent
                                          : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                    ),
                                  ),
                                if (isFailed && onRetry != null) ...[
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: onRetry,
                                    child: Icon(
                                      Icons.refresh,
                                      size: 16,
                                      color: AppColors.error.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                          GestureDetector(
                            onTap: onViewList,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: groceryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                AppStrings.viewList,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: groceryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemRow(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> item,
  ) {
    const groceryColor = AppColors.grocery;
    final name = (item['name'] as String?)?.trim();
    final quantity = _formatQuantity(item['quantity']);
    final brand = (item['brand'] as String?)?.trim();
    final size = (item['size'] as String?)?.trim();
    final variant = (item['variant'] as String?)?.trim();
    final category = (item['category'] as String?)?.trim();
    final note = (item['note'] as String?)?.trim();
    final imageUrl = (item['imageUrl'] as String?)?.trim();
    final specParts = [
      if (brand != null && brand.isNotEmpty) brand,
      if (size != null && size.isNotEmpty) size,
      if (variant != null && variant.isNotEmpty) variant,
      if (category != null && category.isNotEmpty) category,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: groceryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: groceryColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name?.isNotEmpty == true ? name! : 'Unnamed item',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (specParts.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  specParts.join(' • '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  note,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (imageUrl != null && imageUrl.isNotEmpty) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ImageLightbox.show(context, imageUrl, imageUrl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: AppColors.getGlassBackground(0.05),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textTertiary,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.getGlassBackground(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            quantity,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  String _formatQuantity(dynamic value) {
    if (value is int) return 'x$value';
    if (value is double) {
      return 'x${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}';
    }
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return 'x$parsed';
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return 'x1';
    return raw.startsWith('x') ? raw : 'x$raw';
  }
}

class EventMessageCard extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final bool showSenderInCard;
  final VoidCallback? onJoinTap;
  final VoidCallback? onLeaveTap;
  final VoidCallback? onViewDetails;
  final bool hasBeenRead;
  final bool isFailed;
  final VoidCallback? onReadReceiptsTap;
  final VoidCallback? onRetry;

  const EventMessageCard({
    super.key,
    required this.message,
    required this.isMe,
    this.showSenderInCard = true,
    this.onJoinTap,
    this.onLeaveTap,
    this.onViewDetails,
    this.hasBeenRead = false,
    this.isFailed = false,
    this.onReadReceiptsTap,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initialEvent = message['event'];
    final eventId = initialEvent['eventId'] as String?;
    const eventColor = AppColors.event;
    final eventDate = initialEvent['date'] as DateTime;
    final authUser = context.read<AuthBloc>().state.user;

    return BlocBuilder<EventBloc, EventState>(
      builder: (context, state) {
        // Find real-time event data from Bloc state if available
        final realTimeEvent = eventId != null
            ? state.events.where((e) => e.id == eventId).firstOrNull
            : null;

        final attendees =
            realTimeEvent?.attendeeNames ??
            List<String>.from(initialEvent['attendees'] ?? []);
        final attendeeIds =
            realTimeEvent?.attendeeIds ??
            List<String>.from(initialEvent['attendeeIds'] ?? []);
        final maxCapacity =
            realTimeEvent?.maxCapacity ?? initialEvent['maxCapacity'] as int?;
        final isAttending =
            authUser != null && attendeeIds.contains(authUser.id);
        final isFull = maxCapacity != null && attendeeIds.length >= maxCapacity;

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppDimensions.chatBubbleRadius),
              topRight: const Radius.circular(AppDimensions.chatBubbleRadius),
              bottomLeft: Radius.circular(
                isMe ? AppDimensions.chatBubbleRadius : 6,
              ),
              bottomRight: Radius.circular(
                isMe ? 6 : AppDimensions.chatBubbleRadius,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.getGlassBackground(0.05),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(
                      AppDimensions.chatBubbleRadius,
                    ),
                    topRight: const Radius.circular(
                      AppDimensions.chatBubbleRadius,
                    ),
                    bottomLeft: Radius.circular(
                      isMe ? AppDimensions.chatBubbleRadius : 6,
                    ),
                    bottomRight: Radius.circular(
                      isMe ? 6 : AppDimensions.chatBubbleRadius,
                    ),
                  ),
                  border: Border.all(
                    color: eventColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            eventColor,
                            eventColor.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(19),
                          topRight: Radius.circular(19),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.event,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe && showSenderInCard)
                                  Text(
                                    message['senderName'],
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                const Text(
                                  AppStrings.newEvent,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.people,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  maxCapacity != null
                                      ? '${attendees.length}/$maxCapacity'
                                      : '${attendees.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            initialEvent['title'],
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: eventColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.calendar_today,
                                  color: eventColor,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${DateFormatter.formatDayOfWeek(eventDate)}, ${DateFormatter.formatDate(eventDate)}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    initialEvent['time'],
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: eventColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: eventColor,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                initialEvent['location'],
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: attendees
                                .map<Widget>(
                                  (name) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.getGlassBackground(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      name,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    DateFormatter.formatTime(
                                      message['timestamp'],
                                    ),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    if (isFailed)
                                      Icon(
                                        Icons.error_outline,
                                        size: 14,
                                        color: AppColors.error.withValues(
                                          alpha: 0.7,
                                        ),
                                      )
                                    else
                                      GestureDetector(
                                        onTap: onReadReceiptsTap,
                                        child: Icon(
                                          Icons.done_all,
                                          size: 14,
                                          color: hasBeenRead
                                              ? Colors.lightBlueAccent
                                              : theme.colorScheme.onSurface
                                                    .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    if (isFailed && onRetry != null) ...[
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: onRetry,
                                        child: Icon(
                                          Icons.refresh,
                                          size: 16,
                                          color: AppColors.error.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: isAttending
                                        ? onLeaveTap
                                        : (isFull ? null : onJoinTap),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isAttending
                                            ? Colors.green.withValues(
                                                alpha: 0.2,
                                              )
                                            : (isFull
                                                  ? AppColors.textTertiary
                                                        .withValues(alpha: 0.1)
                                                  : eventColor.withValues(
                                                      alpha: 0.1,
                                                    )),
                                        borderRadius: BorderRadius.circular(12),
                                        border: isAttending
                                            ? Border.all(
                                                color: Colors.green.withValues(
                                                  alpha: 0.5,
                                                ),
                                              )
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isAttending
                                                ? Icons.check_circle
                                                : (isFull
                                                      ? Icons.block
                                                      : Icons
                                                            .add_circle_outline),
                                            color: isAttending
                                                ? Colors.green
                                                : (isFull
                                                      ? AppColors.textTertiary
                                                      : eventColor),
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isAttending
                                                ? 'Joined'
                                                : (isFull
                                                      ? 'Full'
                                                      : AppStrings.going),
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: isAttending
                                                      ? Colors.green
                                                      : (isFull
                                                            ? AppColors
                                                                  .textTertiary
                                                            : eventColor),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: onViewDetails,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.getGlassBackground(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: theme.colorScheme.outline
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.visibility_outlined,
                                            color: AppColors.textPrimary,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'View',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class PaymentRequestMessageCard extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final VoidCallback? onConfirmTap;
  final bool hasBeenRead;

  const PaymentRequestMessageCard({
    super.key,
    required this.message,
    required this.isMe,
    this.onConfirmTap,
    this.hasBeenRead = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = message['paymentRequest'];
    final authUser = context.read<AuthBloc>().state.user;

    return BlocBuilder<LivingToolsBloc, LivingToolsState>(
      builder: (context, state) {
        final billId = data['billId'] as String?;
        final realTimeBill = billId != null
            ? state.bills.where((b) => b.id == billId).firstOrNull
            : null;

        // The 'Confirm' button should only be active for the bill creator
        final isCreator =
            authUser != null &&
            realTimeBill != null &&
            realTimeBill.createdBy == authUser.id;

        // Check if already paid in real-time
        final memberId = data['memberId'] as String?;
        final member = realTimeBill?.members
            .where((m) => m.id == memberId || m.userId == memberId)
            .firstOrNull;
        final alreadyConfirmed = member?.hasPaid ?? false;

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderColor: alreadyConfirmed
                ? AppColors.success
                : AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      alreadyConfirmed
                          ? Icons.verified_user_rounded
                          : Icons.payment_rounded,
                      color: alreadyConfirmed
                          ? AppColors.success
                          : AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      alreadyConfirmed
                          ? 'Payment Confirmed'
                          : 'Payment Notification',
                      style: TextStyle(
                        color: alreadyConfirmed
                            ? AppColors.success
                            : AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${data['memberName']} has paid RM ${data['amount'].toStringAsFixed(2)} for ${data['billTitle']}.',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                if (!alreadyConfirmed && isCreator)
                  ElevatedButton(
                    onPressed: onConfirmTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Confirm & Mark as Paid',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                else if (alreadyConfirmed)
                  const Center(
                    child: Text(
                      'This payment has been verified.',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    DateFormatter.formatTime(message['timestamp']),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BillMessageCard extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final bool showSenderInCard;
  final VoidCallback? onPayTap;
  final bool hasBeenRead;
  final bool isFailed;
  final VoidCallback? onReadReceiptsTap;
  final VoidCallback? onRetry;

  const BillMessageCard({
    super.key,
    required this.message,
    required this.isMe,
    this.showSenderInCard = true,
    this.onPayTap,
    this.hasBeenRead = false,
    this.isFailed = false,
    this.onReadReceiptsTap,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final billData = message['bill'];
    final amount = billData['amount'] as double;
    final dueDate = billData['dueDate'] as DateTime;
    final type = _parseBillType(billData['type'] as String);
    final billColor = _getBillColor(type);
    final authUser = context.read<AuthBloc>().state.user;

    return BlocBuilder<LivingToolsBloc, LivingToolsState>(
      builder: (context, state) {
        // Find real-time bill data if available
        final billId = billData['billId'] as String?;
        final realTimeBill = billId != null
            ? state.bills.where((b) => b.id == billId).firstOrNull
            : null;

        final hasPaid =
            authUser != null &&
            (realTimeBill?.hasUserPaid(authUser.id) ?? false);
        final yourShare = authUser != null
            ? (realTimeBill?.getShareForUser(authUser.id) ??
                  billData['yourShare'] as double? ??
                  0.0)
            : 0.0;

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppDimensions.chatBubbleRadius),
              topRight: const Radius.circular(AppDimensions.chatBubbleRadius),
              bottomLeft: Radius.circular(
                isMe ? AppDimensions.chatBubbleRadius : 6,
              ),
              bottomRight: Radius.circular(
                isMe ? 6 : AppDimensions.chatBubbleRadius,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.getGlassBackground(0.05),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(
                      AppDimensions.chatBubbleRadius,
                    ),
                    topRight: const Radius.circular(
                      AppDimensions.chatBubbleRadius,
                    ),
                    bottomLeft: Radius.circular(
                      isMe ? AppDimensions.chatBubbleRadius : 6,
                    ),
                    bottomRight: Radius.circular(
                      isMe ? 6 : AppDimensions.chatBubbleRadius,
                    ),
                  ),
                  border: Border.all(
                    color: billColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [billColor, billColor.withValues(alpha: 0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(19),
                          topRight: Radius.circular(19),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getBillIcon(type),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe && showSenderInCard)
                                  Text(
                                    message['senderName'],
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                const Text(
                                  'Shared Bill',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            billData['title'],
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.payments_outlined,
                            'Total',
                            'RM ${amount.toStringAsFixed(2)}',
                            billColor,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.calendar_today_outlined,
                            'Due',
                            DateFormatter.formatDate(dueDate),
                            billColor,
                          ),
                          const SizedBox(height: 16),

                          // Your Share Card
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: billColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: billColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Your Share',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'RM ${yourShare.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                if (hasPaid)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.success.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      'PAID',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormatter.formatTime(message['timestamp']),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  if (!hasPaid)
                                    GestureDetector(
                                      onTap: onPayTap,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Text(
                                          'Pay Now',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppColors.success,
                                      size: 24,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  BillType _parseBillType(String type) {
    return BillType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => BillType.other,
    );
  }

  IconData _getBillIcon(BillType type) {
    switch (type) {
      case BillType.rent:
        return Icons.home_rounded;
      case BillType.utilities:
        return Icons.bolt_rounded;
      case BillType.internet:
        return Icons.wifi_rounded;
      case BillType.cleaning:
        return Icons.cleaning_services_rounded;
      case BillType.water:
        return Icons.water_drop_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
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
      default:
        return const Color(0xFF6B7280);
    }
  }
}

class LocationMessageCard extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final bool showSenderInCard;
  final bool hasBeenRead;
  final bool isFailed;
  final VoidCallback? onReadReceiptsTap;
  final VoidCallback? onRetry;
  final VoidCallback? onViewInPulse;

  const LocationMessageCard({
    super.key,
    required this.message,
    required this.isMe,
    this.showSenderInCard = true,
    this.hasBeenRead = false,
    this.isFailed = false,
    this.onReadReceiptsTap,
    this.onRetry,
    this.onViewInPulse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationData = message['location'];
    final lat = locationData['latitude'] as double;
    final lng = locationData['longitude'] as double;
    const locationColor = AppColors.location;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppDimensions.chatBubbleRadius),
          topRight: const Radius.circular(AppDimensions.chatBubbleRadius),
          bottomLeft: Radius.circular(
            isMe ? AppDimensions.chatBubbleRadius : 6,
          ),
          bottomRight: Radius.circular(
            isMe ? 6 : AppDimensions.chatBubbleRadius,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            decoration: BoxDecoration(
              color: AppColors.getGlassBackground(0.05),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppDimensions.chatBubbleRadius),
                topRight: const Radius.circular(AppDimensions.chatBubbleRadius),
                bottomLeft: Radius.circular(
                  isMe ? AppDimensions.chatBubbleRadius : 6,
                ),
                bottomRight: Radius.circular(
                  isMe ? 6 : AppDimensions.chatBubbleRadius,
                ),
              ),
              border: Border.all(
                color: locationColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Matching Event Card style)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        locationColor,
                        locationColor.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(19),
                      topRight: Radius.circular(19),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe && showSenderInCard)
                              Text(
                                message['senderName'],
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const Text(
                              'Shared Location',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Map Preview
                SizedBox(
                  height: 160,
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(lat, lng),
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('shared_loc'),
                            position: LatLng(lat, lng),
                          ),
                        },
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        scrollGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        mapToolbarEnabled: false,
                      ),
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(onTap: () => _openMap(lat, lng)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Details & Actions
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: locationColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.place_outlined,
                              color: locationColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              locationData['address'] ?? 'Current Location',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormatter.formatTime(message['timestamp']),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                if (isFailed)
                                  Icon(
                                    Icons.error_outline,
                                    size: 14,
                                    color: AppColors.error.withValues(
                                      alpha: 0.7,
                                    ),
                                  )
                                else
                                  GestureDetector(
                                    onTap: onReadReceiptsTap,
                                    child: Icon(
                                      Icons.done_all,
                                      size: 14,
                                      color: hasBeenRead
                                          ? Colors.lightBlueAccent
                                          : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: onViewInPulse,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.getGlassBackground(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.outline
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.map_outlined,
                                        color: AppColors.textPrimary,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'In App',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _openMap(lat, lng),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: locationColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: locationColor.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.directions_outlined,
                                        color: locationColor,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Directions',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: locationColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openMap(double lat, double lng) async {
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    final appleMapsUrl = Uri.parse('https://maps.apple.com/?q=$lat,$lng');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }
}
