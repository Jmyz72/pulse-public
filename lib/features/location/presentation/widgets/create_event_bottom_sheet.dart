import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/config/api_keys.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/event.dart';
import '../bloc/event_bloc.dart';

class CreateEventBottomSheet extends StatefulWidget {
  final double latitude;
  final double longitude;

  const CreateEventBottomSheet({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<CreateEventBottomSheet> createState() => _CreateEventBottomSheetState();
}

class _CreateEventBottomSheetState extends State<CreateEventBottomSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxCapacityController = TextEditingController();
  final _searchController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedCategory = 'other';
  late double _currentLatitude;
  late double _currentLongitude;
  String? _selectedPlaceName;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'other', 'name': 'Other', 'icon': Icons.category},
    {'id': 'restaurant', 'name': 'Food & Drink', 'icon': Icons.restaurant},
    {'id': 'gym', 'name': 'Sports & Fitness', 'icon': Icons.fitness_center},
    {'id': 'study', 'name': 'Study', 'icon': Icons.book},
    {'id': 'movie', 'name': 'Movie', 'icon': Icons.movie},
    {'id': 'party', 'name': 'Party', 'icon': Icons.celebration},
    {'id': 'shopping', 'name': 'Shopping', 'icon': Icons.shopping_bag},
  ];

  @override
  void initState() {
    super.initState();
    _currentLatitude = widget.latitude;
    _currentLongitude = widget.longitude;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxCapacityController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _openSearch() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationSearchSheet(
        currentLatitude: _currentLatitude,
        currentLongitude: _currentLongitude,
      ),
    );

    if (result != null && mounted) {
      final name = result['displayName']?['text'] ?? 'Unknown Place';
      final location = result['location'];
      setState(() {
        if (location != null) {
          _currentLatitude = location['latitude'];
          _currentLongitude = location['longitude'];
        }
        _selectedPlaceName = name;
        _searchController.text = name;
      });
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final maxCapacity = int.tryParse(_maxCapacityController.text);

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an event title')),
      );
      return;
    }

    final authUser = context.read<AuthBloc>().state.user;
    if (authUser == null) return;

    final timeString = _selectedTime.format(context);

    final event = Event(
      id: '',
      title: title,
      description: description.isNotEmpty ? description : null,
      category: _selectedCategory,
      maxCapacity: maxCapacity,
      latitude: _currentLatitude,
      longitude: _currentLongitude,
      eventDate: _selectedDate,
      eventTime: timeString,
      creatorId: authUser.id,
      creatorName: authUser.displayName,
      createdAt: DateTime.now(),
    );

    context.read<EventBloc>().add(EventCreateRequested(event: event));
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event created!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
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
            child: SingleChildScrollView(
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

                  // Title
                  Text(
                    'Create Event',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Event title field
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Event title',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.event, color: AppColors.event),
                      filled: true,
                      fillColor: AppColors.getGlassBackground(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        borderSide: BorderSide(color: AppColors.getGlassBorder(0.4)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        borderSide: BorderSide(color: AppColors.getGlassBorder(0.4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description field
                  TextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Description (optional)',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.description, color: AppColors.event),
                      filled: true,
                      fillColor: AppColors.getGlassBackground(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        borderSide: BorderSide(color: AppColors.getGlassBorder(0.4)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        borderSide: BorderSide(color: AppColors.getGlassBorder(0.4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category & Capacity
                  Row(
                    children: [
                      // Category Dropdown
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.getGlassBackground(0.05),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                            border: Border.all(color: AppColors.getGlassBorder(0.4)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              dropdownColor: AppColors.background,
                              icon: const Icon(Icons.arrow_drop_down, color: AppColors.event),
                              items: _categories.map((cat) {
                                return DropdownMenuItem<String>(
                                  value: cat['id'],
                                  child: Row(
                                    children: [
                                      Icon(cat['icon'], color: AppColors.event, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        cat['name'],
                                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCategory = val);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Max Capacity
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _maxCapacityController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Max Cap.',
                            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            prefixIcon: const Icon(Icons.group, color: AppColors.event, size: 18),
                            filled: true,
                            fillColor: AppColors.getGlassBackground(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                              borderSide: BorderSide(color: AppColors.getGlassBorder(0.4)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                              borderSide: BorderSide(color: AppColors.getGlassBorder(0.4)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date & Time pickers
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.getGlassBackground(0.05),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                              border: Border.all(color: AppColors.getGlassBorder(0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: AppColors.event, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormatter.formatDate(_selectedDate),
                                  style: const TextStyle(color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.getGlassBackground(0.05),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                              border: Border.all(color: AppColors.getGlassBorder(0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: AppColors.event, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedTime.format(context),
                                  style: const TextStyle(color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search place field
                  TextField(
                    controller: _searchController,
                    readOnly: true,
                    onTap: _openSearch,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search place',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.search, color: AppColors.event),
                      filled: true,
                      fillColor: AppColors.getGlassBackground(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        borderSide: BorderSide(color: AppColors.getGlassBorder(0.4)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        borderSide: BorderSide(color: AppColors.getGlassBorder(0.4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.getGlassBackground(0.05),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(color: AppColors.getGlassBorder(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.event, size: 18),
                        const SizedBox(width: 8),
                        Text(
                        _selectedPlaceName != null
                            ? _selectedPlaceName!
                            : '${_currentLatitude.toStringAsFixed(4)}, ${_currentLongitude.toStringAsFixed(4)}',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          ),
                        ),
                        child: const Text(
                          'Create Event',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationSearchSheet extends StatefulWidget {
  final double currentLatitude;
  final double currentLongitude;

  const _LocationSearchSheet({
    required this.currentLatitude,
    required this.currentLongitude,
  });

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _searchPlaces(query);
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    setState(() => _isLoading = true);
    if (ApiKeys.googleMapsApiKey.contains('YOUR_API_KEY')) {
      setState(() => _errorMessage = 'API Key not configured.\nPlease update lib/core/config/api_keys.dart');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Dio().post(
        'https://places.googleapis.com/v1/places:searchText',
        options: Options(
          headers: {
            'X-Goog-Api-Key': ApiKeys.googleMapsApiKey,
            'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.location,places.types',
          },
        ),
        data: {
          'textQuery': query,
          'locationBias': {
            'circle': {
              'center': {
                'latitude': widget.currentLatitude,
                'longitude': widget.currentLongitude,
              },
              'radius': 5000.0,
            },
          },
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic>? places = data['places'];
        setState(() {
          _searchResults = places != null ? List<Map<String, dynamic>>.from(places) : [];
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() {
        if (e is DioException) {
          _errorMessage = e.response?.data?['error']?['message'] ?? 'Connection error';
        } else {
          _errorMessage = 'Failed to search places';
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _getPlaceIcon(List<dynamic>? types) {
    if (types == null) return Icons.place;
    if (types.contains('restaurant') || types.contains('food')) return Icons.restaurant;
    if (types.contains('cafe') || types.contains('coffee_shop')) return Icons.local_cafe;
    if (types.contains('store') || types.contains('shopping_store')) return Icons.shopping_bag;
    if (types.contains('gym')) return Icons.fitness_center;
    if (types.contains('park')) return Icons.park;
    if (types.contains('hospital')) return Icons.local_hospital;
    if (types.contains('school') || types.contains('university')) return Icons.school;
    if (types.contains('bar') || types.contains('night_club')) return Icons.local_bar;
    return Icons.place;
  }

  String _calculateDistance(Map<String, dynamic> location) {
    if (widget.currentLatitude == 0 && widget.currentLongitude == 0) return '';
    
    final lat = location['latitude'] as double;
    final lng = location['longitude'] as double;
    
    final distanceInMeters = Geolocator.distanceBetween(
      widget.currentLatitude,
      widget.currentLongitude,
      lat,
      lng,
    );
    
    return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: AppColors.getGlassBackground(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
            border: Border.all(color: AppColors.getGlassBorder(0.4)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                'Search Location',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search place...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search, color: AppColors.event),
                  suffixIcon: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.getGlassBackground(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    borderSide: BorderSide(color: AppColors.getGlassBorder(0.4)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    borderSide: BorderSide(color: AppColors.getGlassBorder(0.4)),
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _searchResults.isEmpty && _searchController.text.isEmpty
                    ? _buildCategories()
                    : _buildResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nearby Categories',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildCategoryChip('Restaurants', Icons.restaurant),
            _buildCategoryChip('Cafes', Icons.local_cafe),
            _buildCategoryChip('Shops', Icons.shopping_bag),
            _buildCategoryChip('Groceries', Icons.local_grocery_store),
            _buildCategoryChip('Parks', Icons.park),
            _buildCategoryChip('Gyms', Icons.fitness_center),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.event),
      label: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
      backgroundColor: AppColors.getGlassBackground(0.1),
      side: BorderSide(color: AppColors.getGlassBorder(0.4)),
      onPressed: () {
        _searchController.text = label;
        _searchPlaces(label);
      },
    );
  }

  Widget _buildResults() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      );
    }

    if (_searchResults.isEmpty && !_isLoading && _searchController.text.isNotEmpty) {
      return const Center(
        child: Text(
          'No places found',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => Divider(color: AppColors.getGlassBorder(0.2)),
      itemBuilder: (context, index) {
        final place = _searchResults[index];
        final name = place['displayName']?['text'] ?? 'Unknown Place';
        final address = place['formattedAddress'] ?? '';
        final location = place['location'];
        final types = place['types'] as List<dynamic>?;
        final distance = location != null ? _calculateDistance(location) : '';

        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.getGlassBackground(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_getPlaceIcon(types), color: AppColors.event),
          ),
          title: Text(
            name,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (address.isNotEmpty)
                Text(
                  address,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          trailing: distance.isNotEmpty
              ? Text(
                  distance,
                  style: const TextStyle(color: AppColors.event, fontWeight: FontWeight.bold, fontSize: 12),
                )
              : null,
          onTap: () => Navigator.pop(context, place),
        );
      },
    );
  }
}
