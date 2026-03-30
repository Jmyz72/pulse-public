import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../domain/entities/dashboard_data.dart';
import '../../widgets/member_avatar_card.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';

// Location & Event BLoCs
import '../../../../location/presentation/bloc/location_bloc.dart';
import '../../../../location/presentation/bloc/event_bloc.dart';
import '../../../../location/domain/entities/event.dart';

// Bottom sheets
import '../../../../location/presentation/widgets/create_event_bottom_sheet.dart';
import '../../../../location/presentation/widgets/event_details_sheet.dart';

// BLoCs needed for bottom sheet providers
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../chat/presentation/bloc/chat_bloc.dart';

/// Default map center (Kuala Lumpur) used when no position is available.
const _defaultMapCenter = LatLng(3.1390, 101.6869);

/// Bottom offset to clear the GlassBottomNav (72px height + 16px margin).
const _bottomNavClearance = 88.0;

/// Location tab showing Google Map with user/friends/events markers.
/// Self-contained: owns all map logic, dispatches to LocationBloc & EventBloc.
class LocationTab extends StatefulWidget {
  final List<MemberSummary> members;
  final Map<String, dynamic>? initialLocation;
  final VoidCallback? onLocationHandled;

  const LocationTab({
    super.key,
    required this.members,
    this.initialLocation,
    this.onLocationHandled,
  });

  @override
  State<LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends State<LocationTab> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  String? _darkMapStyle;
  bool _blocsInitialized = false;
  Set<Marker> _markers = {};
  bool _showEvents = true;
  String _selectedCategory = 'all'; // 'all', 'restaurant', 'gym', 'other'
  double _currentZoom = 14.0;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMapStyle();
  }

  void _onCameraMove(CameraPosition position) {
    if ((position.zoom - _currentZoom).abs() > 0.5) {
      _currentZoom = position.zoom;

      // Debounce marker updates to prevent lag during rapid zooming
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          final locState = context.read<LocationBloc>().state;
          final evtState = context.read<EventBloc>().state;
          _updateMarkers(locState, evtState);
        }
      });
    }
  }

  @override
  void didUpdateWidget(LocationTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If a new initial location was passed via props
    if (widget.initialLocation != null &&
        widget.initialLocation != oldWidget.initialLocation) {
      _moveToInitialLocation();
    }
  }

  void _moveToInitialLocation() {
    if (_mapController == null || widget.initialLocation == null) return;

    final lat = widget.initialLocation!['targetLat'] as double?;
    final lng = widget.initialLocation!['targetLng'] as double?;

    if (lat != null && lng != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16.0),
      );
      // Notify parent that we've handled this link
      widget.onLocationHandled?.call();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_blocsInitialized) {
      _blocsInitialized = true;
      final locationBloc = context.read<LocationBloc>();
      final eventBloc = context.read<EventBloc>();
      final user = context.read<AuthBloc>().state.user;

      if (user != null && locationBloc.state.status == LocationStatus.initial) {
        locationBloc.add(LocationLoadRequested(userId: user.id));
      }
      if (user != null) {
        eventBloc.add(EventWatchRequested(userId: user.id));
      }

      _updateMarkers(locationBloc.state, eventBloc.state);
    }
  }

  Future<void> _loadMapStyle() async {
    _darkMapStyle = await rootBundle.loadString(
      'assets/map_styles/dark_mode.json',
    );
    if (mounted) setState(() {});
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      final locState = context.read<LocationBloc>().state;
      final evtState = context.read<EventBloc>().state;
      _updateMarkers(locState, evtState);
    });
  }

  Future<void> _updateMarkers(
    LocationState locationState,
    EventState eventState,
  ) async {
    final markers = <Marker>{};

    // Current user marker (green)
    if (locationState.currentLocation != null) {
      final loc = locationState.currentLocation!;
      final user = context.read<AuthBloc>().state.user;
      final icon = await _createCustomMarkerBitmap(
        loc.userName,
        true, // Self is always online
        photoUrl: user?.photoUrl,
      );

      markers.add(
        Marker(
          markerId: MarkerId('me_${loc.userId}'),
          position: LatLng(loc.latitude, loc.longitude),
          infoWindow: InfoWindow(
            title: '${loc.userName} (You)',
            snippet: 'Your location',
          ),
          icon: icon,
          zIndexInt: 2,
        ),
      );
    }

    // Friend markers
    for (final friend in locationState.friendsLocations) {
      final isOnline = locationState.onlineUsers[friend.userId] ?? false;

      // Find member summary for initials if available
      final member = widget.members
          .where((m) => m.id == friend.userId)
          .firstOrNull;
      final name = member?.name ?? friend.userName;
      final photoUrl = member?.photoUrl;

      final icon = await _createCustomMarkerBitmap(
        name,
        isOnline,
        photoUrl: photoUrl,
      );

      markers.add(
        Marker(
          markerId: MarkerId('friend_${friend.userId}'),
          position: LatLng(friend.latitude, friend.longitude),
          infoWindow: InfoWindow(
            title: name,
            snippet: _formatLastActive(friend.lastUpdated, isOnline),
          ),
          icon: icon,
          zIndexInt: 1,
        ),
      );
    }

    // Event markers
    if (_showEvents) {
      for (final event in eventState.events) {
        final category = event.category;

        if (_selectedCategory != 'all' && category != _selectedCategory) {
          continue;
        }

        double markerHue;
        switch (category) {
          case 'restaurant':
            markerHue = BitmapDescriptor.hueOrange;
            break;
          case 'gym':
            markerHue = BitmapDescriptor.hueGreen;
            break;
          case 'study':
            markerHue = BitmapDescriptor.hueYellow;
            break;
          case 'movie':
            markerHue = BitmapDescriptor.hueViolet;
            break;
          case 'party':
            markerHue = BitmapDescriptor.hueRose;
            break;
          case 'shopping':
            markerHue = BitmapDescriptor.hueCyan;
            break;
          default:
            markerHue = BitmapDescriptor.hueAzure;
        }

        markers.add(
          Marker(
            markerId: MarkerId('event_${event.id}'),
            position: LatLng(event.latitude, event.longitude),
            infoWindow: InfoWindow(title: event.title),
            icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
            onTap: () => _showEventDetails(event),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _markers = markers);
    }
  }

  Future<ui.Image?> _loadImage(String url) async {
    try {
      final completer = Completer<ui.Image?>();
      final image = NetworkImage(url);
      final stream = image.resolve(const ImageConfiguration());
      final listener = ImageStreamListener(
        (info, _) => completer.complete(info.image),
        onError: (error, stack) => completer.complete(null),
      );
      stream.addListener(listener);
      return await completer.future.timeout(const Duration(seconds: 5));
    } catch (e) {
      return null;
    }
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(
    String name,
    bool isOnline, {
    String? photoUrl,
  }) async {
    // Dynamic size based on zoom level:
    // Zoom < 14: Small (60)
    // Zoom 14-16: Medium (80)
    // Zoom > 16: Large (100)
    double targetSize = 80;
    if (_currentZoom < 14) {
      targetSize = 60;
    } else if (_currentZoom > 16) {
      targetSize = 100;
    }

    final size = Size(targetSize, targetSize);
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - (targetSize * 0.1); // Proportional margin

    // 1. Draw Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, targetSize * 0.05);
    canvas.drawCircle(
      center + Offset(0, targetSize * 0.02),
      radius,
      shadowPaint,
    );

    // 2. Draw Status Border
    final borderPaint = Paint()
      ..color = isOnline ? AppColors.statusOnline : AppColors.statusOffline
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + (targetSize * 0.04), borderPaint);

    // 3. Draw Gradient Background
    final rect = Rect.fromCircle(center: center, radius: radius);
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.secondary],
      ).createShader(rect);
    canvas.drawCircle(center, radius, bgPaint);

    // 4. Try to load and draw photo
    ui.Image? avatarImage;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      avatarImage = await _loadImage(photoUrl);
    }

    if (avatarImage != null) {
      canvas.save();
      final clipPath = Path()..addOval(rect);
      canvas.clipPath(clipPath);

      // Draw image scaled to fit
      final src = Rect.fromLTWH(
        0,
        0,
        avatarImage.width.toDouble(),
        avatarImage.height.toDouble(),
      );
      canvas.drawImageRect(
        avatarImage,
        src,
        rect,
        Paint()..filterQuality = ui.FilterQuality.high,
      );
      canvas.restore();
    } else {
      // 5. Draw Initials (match AvatarWidget logic)
      final initials = _getInitialsForMarker(name);
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.text = TextSpan(
        text: initials,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  String _getInitialsForMarker(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  void _showEventDetails(Event event) {
    final authBloc = context.read<AuthBloc>();
    final eventBloc = context.read<EventBloc>();
    final chatBloc = context.read<ChatBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider.value(value: eventBloc),
          BlocProvider.value(value: chatBloc),
        ],
        child: EventDetailsSheet(event: event),
      ),
    );
  }

  void _showCreateEvent(LatLng position) {
    final authBloc = context.read<AuthBloc>();
    final eventBloc = context.read<EventBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider.value(value: eventBloc),
        ],
        child: CreateEventBottomSheet(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      ),
    );
  }

  void _flyToMember(String memberId, LocationState locationState) {
    final match = locationState.friendsLocations
        .where((loc) => loc.userId == memberId)
        .firstOrNull;
    if (match != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(match.latitude, match.longitude), 16),
      );
    }
  }

  void _showPrivacyDialog(BuildContext context) {
    final locationBloc = context.read<LocationBloc>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BlocProvider.value(
        value: locationBloc,
        child: BlocBuilder<LocationBloc, LocationState>(
          builder: (context, currentState) {
            final hiddenFrom = List<String>.from(currentState.hiddenFrom);

            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusXl),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
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
                              color: AppColors.location.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.security,
                              color: AppColors.location,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Location Privacy',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                                const Text(
                                  'Select friends to hide your location from',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Friends Grid (Avatar Only)
                      Expanded(
                        child: widget.members.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 48,
                                      color: AppColors.textTertiary,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No friends found',
                                      style: TextStyle(
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 20,
                                      childAspectRatio: 0.85,
                                    ),
                                itemCount: widget.members.length,
                                itemBuilder: (context, index) {
                                  final member = widget.members[index];
                                  final isHidden = hiddenFrom.contains(
                                    member.id,
                                  );

                                  return GestureDetector(
                                    onTap: () {
                                      final newHiddenFrom = List<String>.from(
                                        hiddenFrom,
                                      );
                                      if (isHidden) {
                                        newHiddenFrom.remove(member.id);
                                      } else {
                                        newHiddenFrom.add(member.id);
                                      }
                                      context.read<LocationBloc>().add(
                                        LocationPrivacyUpdated(
                                          hiddenFromUserIds: newHiddenFrom,
                                        ),
                                      );
                                    },
                                    child: Stack(
                                      alignment: Alignment.topCenter,
                                      children: [
                                        // Custom styled avatar
                                        Container(
                                          decoration: isHidden
                                              ? BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppColors.error
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                      blurRadius: 10,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                )
                                              : null,
                                          child: MemberAvatarCard(
                                            name: member.name,
                                            avatarInitial: member.avatarInitial,
                                            imageUrl: member.photoUrl,
                                            isOnline: member.isOnline,
                                            showStatus: !isHidden,
                                            showName: false,
                                            size: 64,
                                          ),
                                        ),

                                        // Hidden Overlay
                                        if (isHidden)
                                          Positioned(
                                            top: 0,
                                            child: Container(
                                              width: 64,
                                              height: 64,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.black.withValues(
                                                  alpha: 0.4,
                                                ),
                                                border: Border.all(
                                                  color: AppColors.error,
                                                  width: 2,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.visibility_off,
                                                color: AppColors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),

                                        // Mini Name Label (very small, unobtrusive)
                                        Positioned(
                                          bottom: 0,
                                          child: Text(
                                            member.name.split(' ')[0],
                                            style: TextStyle(
                                              color: isHidden
                                                  ? AppColors.textTertiary
                                                  : AppColors.textSecondary,
                                              fontSize: 10,
                                              fontWeight: isHidden
                                                  ? FontWeight.normal
                                                  : FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),

                      const SizedBox(height: 16),

                      // Close Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMd,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatLastActive(DateTime? lastUpdated, bool isOnline) {
    if (isOnline) return 'Online now';
    if (lastUpdated == null) return 'Offline';

    final difference = DateTime.now().difference(lastUpdated);
    if (difference.inMinutes < 1) return 'Active just now';
    if (difference.inMinutes < 60) return 'Active ${difference.inMinutes}m ago';
    if (difference.inHours < 24) return 'Active ${difference.inHours}h ago';
    return 'Active ${difference.inDays}d ago';
  }

  void _fitAllMarkers(LocationState state) {
    if (_mapController == null) return;

    final points = <LatLng>[];
    if (state.currentLocation != null) {
      points.add(
        LatLng(
          state.currentLocation!.latitude,
          state.currentLocation!.longitude,
        ),
      );
    }
    for (final friend in state.friendsLocations) {
      points.add(LatLng(friend.latitude, friend.longitude));
    }

    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 15),
      );
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60, // padding
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool isToggle = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isToggle ? AppColors.primary : AppColors.event)
              : AppColors.getGlassBackground(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppColors.getGlassBorder(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? (isToggle ? Colors.black : Colors.white)
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? (isToggle ? Colors.black : Colors.white)
                    : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<LocationBloc, LocationState>(
          listener: (context, state) {
            final eventState = context.read<EventBloc>().state;
            _updateMarkers(state, eventState);
          },
        ),
        BlocListener<EventBloc, EventState>(
          listener: (context, state) {
            final locationState = context.read<LocationBloc>().state;
            _updateMarkers(locationState, state);
          },
        ),
      ],
      child: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, locationState) {
          return BlocBuilder<EventBloc, EventState>(
            builder: (context, eventState) {
              final initialPosition = locationState.currentLocation != null
                  ? LatLng(
                      locationState.currentLocation!.latitude,
                      locationState.currentLocation!.longitude,
                    )
                  : _defaultMapCenter;

              return Stack(
                children: [
                  // Google Map with dark style
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initialPosition,
                      zoom: 14.0,
                    ),
                    style: _darkMapStyle,
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _moveToInitialLocation();
                    },
                    onCameraMove: _onCameraMove,
                    onLongPress: _showCreateEvent,
                  ),

                  // Top gradient overlay with title and my-location button
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(
                            AppDimensions.spacingMd,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Map',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Ghost Mode Toggle
                                      IconButton(
                                        tooltip: locationState.isSharing
                                            ? 'Go Invisible'
                                            : 'Go Visible',
                                        icon: Icon(
                                          locationState.isSharing
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: locationState.isSharing
                                              ? AppColors.white
                                              : AppColors.textTertiary,
                                        ),
                                        onPressed: () {
                                          context.read<LocationBloc>().add(
                                            LocationSharingToggled(
                                              isSharing:
                                                  !locationState.isSharing,
                                            ),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                !locationState.isSharing
                                                    ? 'You are now visible to friends'
                                                    : 'You are now invisible (Ghost Mode)',
                                              ),
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      // Location Privacy
                                      IconButton(
                                        tooltip: 'Location Privacy',
                                        icon: const Icon(
                                          Icons.security,
                                          color: AppColors.white,
                                        ),
                                        onPressed: () =>
                                            _showPrivacyDialog(context),
                                      ),
                                      // Fit Group
                                      IconButton(
                                        tooltip: 'Show everyone',
                                        icon: const Icon(
                                          Icons.zoom_out_map,
                                          color: AppColors.white,
                                        ),
                                        onPressed: () =>
                                            _fitAllMarkers(locationState),
                                      ),
                                      // My Location
                                      IconButton(
                                        tooltip: 'My location',
                                        icon: const Icon(
                                          Icons.my_location,
                                          color: AppColors.white,
                                        ),
                                        onPressed: () {
                                          if (locationState.currentLocation !=
                                                  null &&
                                              _mapController != null) {
                                            _mapController!.animateCamera(
                                              CameraUpdate.newLatLng(
                                                LatLng(
                                                  locationState
                                                      .currentLocation!
                                                      .latitude,
                                                  locationState
                                                      .currentLocation!
                                                      .longitude,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Filter Row
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    // Visibility Toggle
                                    _buildFilterChip(
                                      label: _showEvents ? 'Visible' : 'Hidden',
                                      icon: _showEvents
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      isSelected: _showEvents,
                                      onTap: () {
                                        setState(() {
                                          _showEvents = !_showEvents;
                                          final locState = context
                                              .read<LocationBloc>()
                                              .state;
                                          final evtState = context
                                              .read<EventBloc>()
                                              .state;
                                          _updateMarkers(locState, evtState);
                                        });
                                      },
                                      isToggle: true,
                                    ),

                                    const SizedBox(width: 8),

                                    // Categories
                                    if (_showEvents) ...[
                                      _buildFilterChip(
                                        label: 'All',
                                        isSelected: _selectedCategory == 'all',
                                        onTap: () => _selectCategory('all'),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildFilterChip(
                                        label: 'Food',
                                        icon: Icons.restaurant,
                                        isSelected:
                                            _selectedCategory == 'restaurant',
                                        onTap: () =>
                                            _selectCategory('restaurant'),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildFilterChip(
                                        label: 'Gym',
                                        icon: Icons.fitness_center,
                                        isSelected: _selectedCategory == 'gym',
                                        onTap: () => _selectCategory('gym'),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildFilterChip(
                                        label: 'Study',
                                        icon: Icons.book,
                                        isSelected:
                                            _selectedCategory == 'study',
                                        onTap: () => _selectCategory('study'),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildFilterChip(
                                        label: 'Movie',
                                        icon: Icons.movie,
                                        isSelected:
                                            _selectedCategory == 'movie',
                                        onTap: () => _selectCategory('movie'),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildFilterChip(
                                        label: 'Party',
                                        icon: Icons.celebration,
                                        isSelected:
                                            _selectedCategory == 'party',
                                        onTap: () => _selectCategory('party'),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildFilterChip(
                                        label: 'Shopping',
                                        icon: Icons.shopping_bag,
                                        isSelected:
                                            _selectedCategory == 'shopping',
                                        onTap: () =>
                                            _selectCategory('shopping'),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildFilterChip(
                                        label: 'Other',
                                        icon: Icons.category,
                                        isSelected:
                                            _selectedCategory == 'other',
                                        onTap: () => _selectCategory('other'),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Compact member avatar row above nav bar
                  if (widget.members.isNotEmpty)
                    Positioned(
                      bottom: _bottomNavClearance + 8,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 92,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingMd,
                          ),
                          itemCount: widget.members.length,
                          itemBuilder: (context, index) {
                            final member = widget.members[index];
                            final friendLoc = locationState.friendsLocations
                                .where((l) => l.userId == member.id)
                                .firstOrNull;
                            final isOnline =
                                locationState.onlineUsers[member.id] ??
                                member.isOnline;
                            final lastActiveText = _formatLastActive(
                              friendLoc?.lastUpdated,
                              isOnline,
                            );

                            return GestureDetector(
                              onTap: () =>
                                  _flyToMember(member.id, locationState),
                              child: Container(
                                width: 200,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.getGlassBackground(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.getGlassBorder(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    MemberAvatarCard(
                                      name: member.name,
                                      avatarInitial: member.avatarInitial,
                                      imageUrl: member.photoUrl,
                                      isOnline: isOnline,
                                      showStatus: true,
                                      compact: true,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            member.name,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimary,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            lastActiveText,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: isOnline
                                                      ? AppColors.success
                                                      : AppColors.textTertiary,
                                                  fontSize: 11,
                                                  fontWeight: isOnline
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
