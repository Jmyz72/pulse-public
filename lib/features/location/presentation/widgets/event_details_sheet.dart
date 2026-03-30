import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/calendar_service.dart';
import '../../../auth/domain/entities/user.dart' as auth;
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/event.dart';
import '../bloc/event_bloc.dart';

// Chat imports for sharing
import '../../../chat/presentation/bloc/chat_bloc.dart';
import '../../../chat/domain/entities/message.dart';

class EventDetailsSheet extends StatelessWidget {
  final Event event;

  const EventDetailsSheet({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authUser = context.read<AuthBloc>().state.user;
    final isAttending = authUser != null && event.attendeeIds.contains(authUser.id);
    final isCreator = authUser != null && event.creatorId == authUser.id;
    final isFull = event.maxCapacity != null && event.attendeeIds.length >= event.maxCapacity!;
    final categoryColor = _getCategoryColor(event.category);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppDimensions.radiusXl),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.getGlassBackground(0.08),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusXl),
            ),
            border: Border.all(
              color: AppColors.getGlassBorder(0.4),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Event title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getCategoryIcon(event.category), color: categoryColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'by ${event.creatorName}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mini Map Preview
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(event.latitude, event.longitude),
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('event_preview'),
                            position: LatLng(event.latitude, event.longitude),
                          ),
                        },
                        zoomControlsEnabled: false,
                        scrollGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled: false,
                      ),
                      // Overlay to make map non-interactive but clickable for directions
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _openMap(event.latitude, event.longitude),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.directions, color: AppColors.primary, size: 14),
                              SizedBox(width: 4),
                              Text('Open Maps', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description (if available)
              if (event.description != null && event.description!.isNotEmpty) ...[
                Text(
                  event.description!,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 16),
              ],

              // Date & Time
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.event, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    '${DateFormatter.formatFullDayOfWeek(event.eventDate)}, ${DateFormatter.formatDate(event.eventDate)}',
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.access_time, color: AppColors.event, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    event.eventTime,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.event, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    '${event.latitude.toStringAsFixed(4)}, ${event.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Attendees
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Attendees (${event.attendeeNames.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (event.maxCapacity != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFull ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isFull ? AppColors.error : AppColors.success, width: 1),
                      ),
                      child: Text(
                        'Capacity: ${event.attendeeNames.length}/${event.maxCapacity}',
                        style: TextStyle(
                          color: isFull ? AppColors.error : AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: event.attendeeNames.map((name) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.getGlassBackground(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Action buttons
              if (isCreator) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeleteConfirmation(context),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Remove Event'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (authUser == null) return;

                        if (isAttending) {
                          context.read<EventBloc>().add(EventLeaveRequested(
                            eventId: event.id,
                            userId: authUser.id,
                          ));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Left event!')),
                          );
                        } else {
                          if (isFull) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Event is already full!')),
                            );
                            return;
                          }
                          context.read<EventBloc>().add(EventJoinRequested(
                            eventId: event.id,
                            userId: authUser.id,
                            userName: authUser.displayName,
                          ));
                          Navigator.pop(context);
                          
                          // Automatically add to calendar
                          CalendarService.addEventToCalendar(event);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Joined event! Added to calendar.'),
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        isAttending ? Icons.check_circle : (isFull ? Icons.block : Icons.add_circle_outline),
                        size: 18,
                      ),
                      label: Text(isAttending ? 'Joined' : (isFull ? 'Full' : 'Join')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAttending ? Colors.green : (isFull ? AppColors.textTertiary : categoryColor),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openMap(event.latitude, event.longitude),
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Directions'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: categoryColor,
                        side: BorderSide(color: categoryColor.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final chatBloc = context.read<ChatBloc>();
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    _showShareToChatDialog(context, chatBloc, authUser, messenger);
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share to Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.getGlassBorder(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Event'),
        content: const Text('Are you sure you want to remove this event? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<EventBloc>().add(EventDeleteRequested(eventId: event.id));
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Event removed successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'restaurant': return Icons.restaurant;
      case 'gym': return Icons.fitness_center;
      case 'study': return Icons.book;
      case 'movie': return Icons.movie;
      case 'party': return Icons.celebration;
      case 'shopping': return Icons.shopping_bag;
      default: return Icons.event;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'restaurant': return AppColors.success;
      case 'gym': return AppColors.primary;
      case 'study': return AppColors.warning;
      case 'movie': return AppColors.neonPurple;
      case 'party': return AppColors.neonMagenta;
      case 'shopping': return AppColors.secondary;
      default: return AppColors.event;
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    final appleMapsUrl = Uri.parse('https://maps.apple.com/?q=$lat,$lng');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _showShareToChatDialog(
    BuildContext context,
    ChatBloc chatBloc,
    auth.User? authUser,
    ScaffoldMessengerState messenger,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final query = TextEditingController();
          var filteredRooms = chatBloc.state.chatRooms;

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusXl),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: BoxDecoration(
                  color: AppColors.getGlassBackground(0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDimensions.radiusXl),
                  ),
                  border: Border.all(
                    color: AppColors.getGlassBorder(0.3),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textTertiary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.share, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Share to Chat',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Text(
                                'Select a group to share this event',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Search Bar
                    TextField(
                      controller: query,
                      onChanged: (value) {
                        setModalState(() {
                          filteredRooms = chatBloc.state.chatRooms
                              .where((r) => r.name.toLowerCase().contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search groups...',
                        hintStyle: const TextStyle(color: AppColors.textTertiary),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary, size: 20),
                        filled: true,
                        fillColor: AppColors.getGlassBackground(0.05),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.getGlassBorder(0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.getGlassBorder(0.2)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Chat Rooms List
                    Expanded(
                      child: filteredRooms.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.forum_outlined, size: 48, color: AppColors.textTertiary),
                                  const SizedBox(height: 16),
                                  Text(
                                    chatBloc.state.chatRooms.isEmpty 
                                        ? 'No chat rooms available' 
                                        : 'No groups match your search',
                                    style: const TextStyle(color: AppColors.textTertiary),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredRooms.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final room = filteredRooms[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.getGlassBackground(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.getGlassBorder(0.1)),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                      child: Text(
                                        room.name.isNotEmpty ? room.name[0].toUpperCase() : '?',
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(
                                      room.name,
                                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      '${room.members.length} members',
                                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        if (authUser == null) return;

                                        final now = DateTime.now();
                                        final message = Message(
                                          id: 'share_${now.millisecondsSinceEpoch}_${authUser.id.substring(0, 5)}',
                                          senderId: authUser.id,
                                          senderName: authUser.displayName,
                                          content: 'Shared an event: ${event.title}',
                                          chatRoomId: room.id,
                                          timestamp: now,
                                          type: MessageType.event,
                                          eventData: {
                                            'eventId': event.id,
                                            'title': event.title,
                                            'description': event.description,
                                            'category': event.category,
                                            'latitude': event.latitude,
                                            'longitude': event.longitude,
                                            'eventDate': event.eventDate.toIso8601String(),
                                            'eventTime': event.eventTime,
                                            'creatorName': event.creatorName,
                                            'attendeeNames': event.attendeeNames,
                                            'attendeeIds': event.attendeeIds,
                                            'maxCapacity': event.maxCapacity,
                                          },
                                        );
                                        chatBloc.add(MessageSendRequested(message: message));

                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text('Event shared to ${room.name}'),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: AppColors.primaryDark,
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        minimumSize: const Size(0, 36),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Share', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
