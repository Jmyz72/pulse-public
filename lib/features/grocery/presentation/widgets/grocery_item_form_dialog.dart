import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../chat/domain/entities/message.dart';
import '../../domain/entities/grocery_item.dart';

class GroceryItemFormSubmission {
  final GroceryItem item;
  final String? imagePath;
  final bool clearImage;

  const GroceryItemFormSubmission({
    required this.item,
    this.imagePath,
    this.clearImage = false,
  });
}

class GroceryItemFormDialog extends StatefulWidget {
  final GroceryItem? existingItem;
  final List<ChatRoom> chatRooms;
  final String? preselectedChatRoomId;
  final void Function(GroceryItemFormSubmission submission) onSubmit;

  const GroceryItemFormDialog({
    super.key,
    this.existingItem,
    this.chatRooms = const [],
    this.preselectedChatRoomId,
    required this.onSubmit,
  });

  @override
  State<GroceryItemFormDialog> createState() => _GroceryItemFormDialogState();
}

class _GroceryItemFormDialogState extends State<GroceryItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _sizeController;
  late final TextEditingController _variantController;
  late final TextEditingController _quantityController;
  late final TextEditingController _noteController;
  final ImagePicker _imagePicker = ImagePicker();
  String? _selectedCategory;
  ChatRoom? _selectedChatRoom;
  String? _selectedImagePath;
  bool _clearExistingImage = false;

  bool get _isEditing => widget.existingItem != null;
  bool get _showChatRoomDropdown =>
      !_isEditing && widget.preselectedChatRoomId == null;

  static const _categories = [
    'Produce',
    'Dairy',
    'Meat',
    'Bakery',
    'Frozen',
    'Beverages',
    'Snacks',
    'Other',
  ];

  static final Color _sheetSurface = Color.alphaBlend(
    AppColors.background.withValues(alpha: 0.92),
    AppColors.backgroundLight,
  );

  static final Color _sectionSurface = Color.alphaBlend(
    Colors.white.withValues(alpha: 0.06),
    AppColors.backgroundLight,
  );

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameController = TextEditingController(text: item?.name ?? '');
    _brandController = TextEditingController(text: item?.brand ?? '');
    _sizeController = TextEditingController(text: item?.size ?? '');
    _variantController = TextEditingController(text: item?.variant ?? '');
    _quantityController = TextEditingController(
      text: item?.quantity.toString() ?? '1',
    );
    _noteController = TextEditingController(text: item?.note ?? '');
    _selectedCategory = item?.category;

    if (!_isEditing) {
      if (widget.preselectedChatRoomId != null) {
        final match = widget.chatRooms
            .where((r) => r.id == widget.preselectedChatRoomId)
            .toList();
        if (match.isNotEmpty) _selectedChatRoom = match.first;
      } else if (widget.chatRooms.isNotEmpty) {
        _selectedChatRoom = widget.chatRooms.first;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _sizeController.dispose();
    _variantController.dispose();
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditing && _selectedChatRoom == null) return;

    final quantity = int.tryParse(_quantityController.text) ?? 1;

    if (_isEditing) {
      final updated = widget.existingItem!.copyWith(
        name: _nameController.text.trim(),
        brand: _brandController.text.trim().isNotEmpty
            ? _brandController.text.trim()
            : null,
        clearBrand: _brandController.text.trim().isEmpty,
        size: _sizeController.text.trim().isNotEmpty
            ? _sizeController.text.trim()
            : null,
        clearSize: _sizeController.text.trim().isEmpty,
        variant: _variantController.text.trim().isNotEmpty
            ? _variantController.text.trim()
            : null,
        clearVariant: _variantController.text.trim().isEmpty,
        quantity: quantity,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
        clearNote: _noteController.text.trim().isEmpty,
        clearImageUrl: _clearExistingImage && _selectedImagePath == null,
        category: _selectedCategory,
        clearCategory: _selectedCategory == null,
      );
      widget.onSubmit(
        GroceryItemFormSubmission(
          item: updated,
          imagePath: _selectedImagePath,
          clearImage: _clearExistingImage && _selectedImagePath == null,
        ),
      );
    } else {
      widget.onSubmit(
        GroceryItemFormSubmission(
          item: GroceryItem(
            id: '', // caller sets real id
            name: _nameController.text.trim(),
            brand: _brandController.text.trim().isNotEmpty
                ? _brandController.text.trim()
                : null,
            size: _sizeController.text.trim().isNotEmpty
                ? _sizeController.text.trim()
                : null,
            variant: _variantController.text.trim().isNotEmpty
                ? _variantController.text.trim()
                : null,
            quantity: quantity,
            note: _noteController.text.trim().isNotEmpty
                ? _noteController.text.trim()
                : null,
            category: _selectedCategory,
            chatRoomId: _selectedChatRoom!.id,
            addedBy: '', // caller sets
            createdAt: DateTime.now(),
          ),
          imagePath: _selectedImagePath,
        ),
      );
    }

    Navigator.pop(context);
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1400,
      );
      if (pickedFile == null || !mounted) return;
      setState(() {
        _selectedImagePath = pickedFile.path;
        _clearExistingImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  void _removeImage() {
    setState(() {
      if (_selectedImagePath != null) {
        _selectedImagePath = null;
      } else if (widget.existingItem?.imageUrl != null) {
        _clearExistingImage = true;
      }
    });
  }

  void _adjustQuantity(int delta) {
    final current = int.tryParse(_quantityController.text) ?? 1;
    final next = (current + delta).clamp(1, 99);
    setState(() {
      _quantityController.text = '$next';
    });
  }

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        width: 48,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final subtitle = _isEditing
        ? 'Refine the details so housemates know exactly what to replace.'
        : 'Make the list specific with brand, size, variant, and a photo.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.grocery.withValues(alpha: 0.22),
            AppColors.primary.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.grocery.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.grocery.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.shopping_basket_rounded,
              color: AppColors.grocery,
              size: 28,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Grocery Item' : 'Add Grocery Item',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildHeaderPill(
                      theme,
                      icon: Icons.tune_rounded,
                      text: 'Specific buying details',
                    ),
                    if (_selectedChatRoom != null)
                      _buildHeaderPill(
                        theme,
                        icon: Icons.groups_rounded,
                        text: _selectedChatRoom!.name,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPill(
    ThemeData theme, {
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      decoration: BoxDecoration(
        color: _sectionSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          ...children,
        ],
      ),
    );
  }

  Widget _buildQuantityPicker(ThemeData theme) {
    final quantity = int.tryParse(_quantityController.text) ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quantity', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppDimensions.spacingSm),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.grey100.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              _buildQuantityButton(
                icon: Icons.remove_rounded,
                onTap: () => _adjustQuantity(-1),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$quantity',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      quantity == 1 ? 'unit' : 'units',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildQuantityButton(
                icon: Icons.add_rounded,
                onTap: () => _adjustQuantity(1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.grocery.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppColors.grocery),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppDimensions.spacingSm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category;
            return ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = isSelected ? null : category;
                });
              },
              selectedColor: AppColors.grocery.withValues(alpha: 0.16),
              backgroundColor: AppColors.grey100.withValues(alpha: 0.92),
              side: BorderSide(
                color: isSelected
                    ? AppColors.grocery.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.08),
              ),
              labelStyle: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? AppColors.grocery : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    final existingImageUrl = widget.existingItem?.imageUrl;
    final hasExistingImage =
        !_clearExistingImage &&
        existingImageUrl != null &&
        existingImageUrl.isNotEmpty;
    final hasSelectedImage = _selectedImagePath != null;
    final hasImage = hasSelectedImage || hasExistingImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Product Image (optional)', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppDimensions.spacingSm),
        if (hasImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: hasSelectedImage
                  ? Image.file(File(_selectedImagePath!), fit: BoxFit.cover)
                  : Image.network(
                      existingImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImageFallback(),
                    ),
            ),
          )
        else
          _buildImagePlaceholder(),
        const SizedBox(height: AppDimensions.spacingSm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showImageSourceSheet,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(hasImage ? 'Change Image' : 'Add Image'),
              ),
            ),
            if (hasImage) ...[
              const SizedBox(width: AppDimensions.spacingSm),
              TextButton(onPressed: _removeImage, child: const Text('Remove')),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.grey100.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, color: AppColors.textTertiary, size: 32),
          SizedBox(height: 8),
          Text(
            'Add a product photo for easier buying',
            style: TextStyle(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: AppColors.getGlassBackground(0.05),
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image_outlined,
        color: AppColors.textTertiary,
        size: 32,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.9;
    final formContent = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSheetHandle(),
          const SizedBox(height: AppDimensions.spacingMd),
          _buildHeader(theme),
          const SizedBox(height: AppDimensions.spacingMd),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_showChatRoomDropdown) ...[
                    _buildSectionCard(
                      theme: theme,
                      title: 'Shared List',
                      subtitle:
                          'Choose which household or chat this item belongs to.',
                      children: [
                        DropdownButtonFormField<ChatRoom>(
                          decoration: const InputDecoration(labelText: 'Group'),
                          initialValue: _selectedChatRoom,
                          items: widget.chatRooms.map((room) {
                            return DropdownMenuItem(
                              value: room,
                              child: Text(
                                room.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          validator: (value) =>
                              value == null ? 'Please select a group' : null,
                          onChanged: (value) {
                            setState(() {
                              _selectedChatRoom = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                  ],
                  _buildSectionCard(
                    theme: theme,
                    title: 'Core Item',
                    subtitle:
                        'Start with the exact product name, then add buying details.',
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                          hintText: 'e.g., Milk',
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        autofocus: true,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Please enter an item name'
                            : null,
                      ),
                      const SizedBox(height: AppDimensions.spacingMd),
                      _buildQuantityPicker(theme),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  _buildSectionCard(
                    theme: theme,
                    title: 'Purchase Details',
                    subtitle:
                        'Add the brand, size, and variant so no one has to guess.',
                    children: [
                      TextFormField(
                        controller: _brandController,
                        decoration: const InputDecoration(
                          labelText: 'Brand (optional)',
                          hintText: 'e.g., Dutch Lady',
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: AppDimensions.spacingMd),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _sizeController,
                              decoration: const InputDecoration(
                                labelText: 'Size (optional)',
                                hintText: 'e.g., 2L',
                              ),
                              textCapitalization: TextCapitalization.none,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingMd),
                          Expanded(
                            child: TextFormField(
                              controller: _variantController,
                              decoration: const InputDecoration(
                                labelText: 'Variant (optional)',
                                hintText: 'e.g., Low fat',
                              ),
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingMd),
                      _buildCategorySelector(theme),
                      const SizedBox(height: AppDimensions.spacingMd),
                      TextFormField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Note (optional)',
                          hintText: 'e.g., Blue cap only',
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 2,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  _buildSectionCard(
                    theme: theme,
                    title: 'Reference Photo',
                    subtitle:
                        'Attach a quick product shot to make the item instantly recognizable.',
                    children: [_buildImageSection(theme)],
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
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                child: Text(_isEditing ? 'Save' : 'Add'),
              ),
            ],
          ),
        ],
      ),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.viewInsetsOf(context).bottom + AppDimensions.spacingMd,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXl),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: maxSheetHeight),
              decoration: BoxDecoration(
                color: _sheetSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusXl),
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingLg,
                AppDimensions.spacingLg,
                AppDimensions.spacingLg,
                AppDimensions.spacingLg,
              ),
              child: formContent,
            ),
          ),
        ),
      ),
    );
  }
}
