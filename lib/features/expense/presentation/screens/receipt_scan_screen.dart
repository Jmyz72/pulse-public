import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../core/services/receipt_parser_service.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/image_lightbox.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart';

/// OCR Receipt Scanning Screen with AI-powered parsing.
/// Uses Google ML Kit for OCR and Vertex AI for intelligent item extraction.
class ReceiptScanScreen extends StatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

/// Mutable item for editing in the UI
class _EditableItem {
  String name;
  double price;
  int quantity;

  _EditableItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get totalPrice => price * quantity;

  factory _EditableItem.fromParsedItem(ParsedItem item) {
    return _EditableItem(
      name: item.name,
      price: item.price,
      quantity: item.quantity,
    );
  }
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final OcrService _ocrService = GetIt.instance<OcrService>();
  final ReceiptParserService _receiptParserService =
      GetIt.instance<ReceiptParserService>();

  File? _selectedImage;
  bool _isProcessing = false;
  String _statusMessage = '';
  String? _extractedText;
  ReceiptParseResult? _parseResult;
  List<_EditableItem> _editableItems = [];
  double _taxPercent = 0;
  double _serviceChargePercent = 0;
  double _discountPercent = 0;
  String _currency = 'RM';
  String? _errorMessage;

  // Controllers for inline TextFields
  late final TextEditingController _taxController;
  late final TextEditingController _serviceChargeController;
  late final TextEditingController _discountController;

  @override
  void initState() {
    super.initState();
    _taxController = TextEditingController(
      text: _taxPercent.toStringAsFixed(0),
    );
    _serviceChargeController = TextEditingController(
      text: _serviceChargePercent.toStringAsFixed(0),
    );
    _discountController = TextEditingController(
      text: _discountPercent.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _taxController.dispose();
    _serviceChargeController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _processReceipt(File imageFile) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Extracting text from image...';
      _errorMessage = null;
      _parseResult = null;
      _editableItems = [];
      _taxPercent = 0;
      _serviceChargePercent = 0;
      _discountPercent = 0;
      _currency = 'RM';
      _syncAdjustmentControllers();
    });

    try {
      // Step 1: OCR - Extract text from image
      final extractedText = await _ocrService.extractTextFromImage(imageFile);

      if (extractedText.isEmpty) {
        setState(() {
          _isProcessing = false;
          _errorMessage =
              'No text found in image. Please try again with a clearer photo.';
        });
        return;
      }

      setState(() {
        _extractedText = extractedText;
        _statusMessage = 'Vertex AI is parsing receipt items...';
      });

      final parseResult = await _receiptParserService.parseReceiptText(
        extractedText,
      );

      setState(() {
        _parseResult = parseResult;
        _editableItems = parseResult.items
            .map(_EditableItem.fromParsedItem)
            .toList();
        _currency = parseResult.currency;
        _syncAdjustmentPercents(parseResult);
        _isProcessing = false;
        _statusMessage = '';
      });
    } on OcrException catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'OCR Error: ${e.message}';
      });
    } on ReceiptParseException catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'AI Parsing Error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Unexpected error: $e';
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _parseResult = null;
          _editableItems = [];
          _extractedText = null;
          _errorMessage = null;
          _taxPercent = 0;
          _serviceChargePercent = 0;
          _discountPercent = 0;
          _currency = 'RM';
          _syncAdjustmentControllers();
        });
        await _processReceipt(File(image.path));
      }
    } on PlatformException catch (e) {
      setState(() {
        _errorMessage =
            e.code == 'photo_access_denied' || e.code == 'camera_access_denied'
            ? 'Permission denied. Please enable access in Settings.'
            : 'Failed to pick image: ${e.message}';
      });
    }
  }

  Future<void> _selectImageFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  Future<void> _captureImageFromCamera() async {
    await _pickImage(ImageSource.camera);
  }

  void _resetScanner() {
    setState(() {
      _selectedImage = null;
      _parseResult = null;
      _editableItems = [];
      _extractedText = null;
      _errorMessage = null;
      _isProcessing = false;
      _statusMessage = '';
      _taxPercent = 0;
      _serviceChargePercent = 0;
      _discountPercent = 0;
      _syncAdjustmentControllers();
    });
  }

  double get _itemsSubtotal {
    return _editableItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get _calculatedTotal {
    final subtotal = _itemsSubtotal;
    final tax = subtotal * (_taxPercent / 100);
    final service = subtotal * (_serviceChargePercent / 100);
    final discount = subtotal * (_discountPercent / 100);
    return subtotal + tax + service - discount;
  }

  bool get _canManuallyAddItems =>
      !_isProcessing && _selectedImage != null && _extractedText != null;

  bool get _showItemEditor =>
      !_isProcessing &&
      _errorMessage == null &&
      (_parseResult != null || _editableItems.isNotEmpty);

  void _syncAdjustmentPercents(ReceiptParseResult result) {
    final subtotal = result.subtotal > 0 ? result.subtotal : _itemsSubtotal;
    if (subtotal <= 0) {
      _taxPercent = 0;
      _serviceChargePercent = 0;
      _discountPercent = 0;
      _syncAdjustmentControllers();
      return;
    }

    _taxPercent = result.tax > 0 ? (result.tax / subtotal) * 100 : 0;
    _serviceChargePercent = result.serviceCharge > 0
        ? (result.serviceCharge / subtotal) * 100
        : 0;
    _discountPercent = result.discount > 0
        ? (result.discount / subtotal) * 100
        : 0;
    _syncAdjustmentControllers();
  }

  void _syncAdjustmentControllers() {
    _taxController.text = _formatPercent(_taxPercent);
    _serviceChargeController.text = _formatPercent(_serviceChargePercent);
    _discountController.text = _formatPercent(_discountPercent);
  }

  String _formatPercent(double value) {
    if (value == 0) return '0';
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  void _showEditItemDialog(_EditableItem item, int index) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(
      text: item.price.toStringAsFixed(2),
    );
    final quantityController = TextEditingController(
      text: item.quantity.toString(),
    );

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundLight,
          title: const Text(
            'Edit Item',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
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
                  controller: priceController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Price ($_currency)',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _editableItems[index] = _EditableItem(
                    name: nameController.text.trim(),
                    price: double.tryParse(priceController.text) ?? 0,
                    quantity: int.tryParse(quantityController.text) ?? 1,
                  );
                });
                Navigator.pop(context);
              },
              child: const Text(
                'Save',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nameController.dispose();
        priceController.dispose();
        quantityController.dispose();
      });
    });
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController(text: '1');

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundLight,
          title: const Text(
            'Add Item',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
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
                  controller: priceController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Price ($_currency)',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text) ?? 0;
                final quantity = int.tryParse(quantityController.text) ?? 1;

                if (name.isNotEmpty && price > 0) {
                  setState(() {
                    _errorMessage = null;
                    _editableItems.add(
                      _EditableItem(
                        name: name,
                        price: price,
                        quantity: quantity,
                      ),
                    );
                  });
                }
                Navigator.pop(context);
              },
              child: const Text(
                'Add',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        nameController.dispose();
        priceController.dispose();
        quantityController.dispose();
      });
    });
  }

  void _deleteItem(int index) {
    setState(() {
      _editableItems.removeAt(index);
    });
  }

  Map<String, dynamic> _buildAddExpenseArguments() {
    return {
      'scannedItems': _editableItems
          .map(
            (item) => {
              'name': item.name,
              'price': item.price,
              'quantity': item.quantity,
            },
          )
          .toList(),
      'taxPercent': _taxPercent,
      'serviceChargePercent': _serviceChargePercent,
      'discountPercent': _discountPercent,
      'imageFile': _selectedImage,
      'chatRooms': context.read<ChatBloc>().state.chatRooms,
    };
  }

  void _proceedToAddExpense() {
    if (_editableItems.isEmpty) return;

    final addExpenseArguments = _buildAddExpenseArguments();
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    final shouldReturnResultOnly =
        routeArgs is Map && routeArgs['returnResultOnly'] == true;

    if (shouldReturnResultOnly) {
      Navigator.pop(context, addExpenseArguments);
      return;
    }

    // Navigate to Add Expense with pre-filled items
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.addExpense,
      arguments: {...addExpenseArguments, 'initialStep': 1},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(
        title: 'Scan Receipt',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetScanner,
              tooltip: 'Scan New Receipt',
            ),
        ],
      ),
      body: _selectedImage == null
          ? _buildSelectionView()
          : _buildProcessingView(),
    );
  }

  Widget _buildSelectionView() {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AI Icon
            Container(
              height: 120,
              width: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              'AI Receipt Scanner',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Powered by Google ML Kit + Vertex AI',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            // Camera Button
            SizedBox(
              width: double.infinity,
              height: 140,
              child: ElevatedButton(
                onPressed: _captureImageFromCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_rounded, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Take Photo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Use camera to scan receipt',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.background.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Gallery Button
            SizedBox(
              width: double.infinity,
              height: 140,
              child: OutlinedButton(
                onPressed: _selectImageFromGallery,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library_rounded, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'Choose from Gallery',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Select existing receipt image',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Features Info
            GlassContainer(
              borderRadius: 24,
              child: Column(
                children: [
                  _buildFeatureRow(
                    Icons.text_fields,
                    'ML Kit OCR',
                    'On-device text extraction (free)',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureRow(
                    Icons.auto_awesome,
                    'Vertex AI',
                    'Smart parsing of items & prices',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureRow(
                    Icons.translate,
                    'Multi-language',
                    'Supports BM, EN, CN receipts',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingView() {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Receipt Image Preview
        Container(
          height: 200,
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(24),
          ),
          child: GestureDetector(
            key: const ValueKey('receipt-image-preview'),
            onTap: _selectedImage == null
                ? null
                : () => ImageLightbox.showFile(
                    context,
                    _selectedImage!.path,
                    'receipt-scan-preview-${_selectedImage!.path}',
                  ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  if (_selectedImage != null)
                    Hero(
                      tag: 'receipt-scan-preview-${_selectedImage!.path}',
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    ),

                  // Processing overlay
                  if (_isProcessing)
                    Container(
                      color: Colors.black54,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _statusMessage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                  if (!_isProcessing && _selectedImage != null)
                    const Positioned(
                      right: 12,
                      bottom: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            'Tap to view',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Success Badge
                  if (!_isProcessing && _parseResult != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Scanned',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Error Message
        if (_errorMessage != null)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GlassButton(
                      text: 'Try Again',
                      icon: Icons.refresh,
                      isPrimary: true,
                      onPressed: _resetScanner,
                    ),
                    if (_canManuallyAddItems) ...[
                      const SizedBox(height: 12),
                      GlassButton(
                        text: 'Add Item Manually',
                        icon: Icons.edit_note,
                        onPressed: _showAddItemDialog,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

        // Extracted Text Preview (collapsible)
        if (!_isProcessing && _extractedText != null)
          ExpansionTile(
            title: const Text(
              'Extracted Text (OCR)',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _extractedText!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

        // Scanned Items List (Editable)
        if (_showItemEditor)
          Expanded(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items (${_editableItems.length})',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAddItemDialog,
                        icon: const Icon(
                          Icons.add,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        label: const Text(
                          'Add Item',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),

                // Hint text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Tap to edit, swipe to delete',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Items List
                Expanded(
                  child: _editableItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.receipt_long,
                                size: 64,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No items detected',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GlassButton(
                                text: 'Add Item Manually',
                                onPressed: _showAddItemDialog,
                                isPrimary: true,
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _resetScanner,
                                child: const Text(
                                  'Try Another Image',
                                  style: TextStyle(color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _editableItems.length,
                          itemBuilder: (context, index) {
                            final item = _editableItems[index];
                            return Dismissible(
                              key: Key('item_$index'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (_) => _deleteItem(index),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: GlassContainer(
                                  borderRadius: 24,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: InkWell(
                                    onTap: () =>
                                        _showEditItemDialog(item, index),
                                    borderRadius: BorderRadius.circular(24),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.15,
                                            ),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                '$_currency ${item.price.toStringAsFixed(2)} each',
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '$_currency ${item.totalPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.edit,
                                          size: 16,
                                          color: AppColors.textTertiary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Total and Split Section
                if (_editableItems.isNotEmpty) _buildTotalSection(theme),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTotalSection(ThemeData theme) {
    final subtotal = _itemsSubtotal;
    final taxAmount = subtotal * (_taxPercent / 100);
    final serviceAmount = subtotal * (_serviceChargePercent / 100);
    final discountAmount = subtotal * (_discountPercent / 100);
    final total = _calculatedTotal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(
          top: BorderSide(color: AppColors.glassBorder, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                '$_currency ${subtotal.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Tax adjustment
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tax/SST',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              SizedBox(
                width: 60,
                child: TextField(
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    suffixText: '%',
                  ),
                  controller: _taxController,
                  onChanged: (value) {
                    setState(() {
                      _taxPercent = double.tryParse(value) ?? 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: Text(
                  '$_currency ${taxAmount.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Service charge adjustment
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Service Charge',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              SizedBox(
                width: 60,
                child: TextField(
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    suffixText: '%',
                  ),
                  controller: _serviceChargeController,
                  onChanged: (value) {
                    setState(() {
                      _serviceChargePercent = double.tryParse(value) ?? 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: Text(
                  '$_currency ${serviceAmount.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Discount adjustment
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Discount',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              SizedBox(
                width: 60,
                child: TextField(
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    suffixText: '%',
                  ),
                  controller: _discountController,
                  onChanged: (value) {
                    setState(() {
                      _discountPercent = double.tryParse(value) ?? 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: Text(
                  '- $_currency ${discountAmount.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Divider(color: AppColors.glassBorder),
          const SizedBox(height: 8),

          // Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$_currency ${total.toStringAsFixed(2)}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Proceed Button
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              text: 'Continue to Add Expense',
              icon: Icons.arrow_forward,
              isPrimary: true,
              onPressed: _proceedToAddExpense,
            ),
          ),
        ],
      ),
    );
  }
}
