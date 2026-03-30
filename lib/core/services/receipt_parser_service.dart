import 'vertex_ai_service.dart';

class ReceiptParserService {
  final VertexAiService vertexAiService;

  ReceiptParserService({required this.vertexAiService});

  Future<ReceiptParseResult> parseReceiptText(String ocrText) async {
    try {
      final payload = await vertexAiService.parseReceiptPayload(ocrText);
      return ReceiptParseResult.fromJson(payload);
    } on VertexAiParseException catch (e) {
      throw ReceiptParseException(e.message);
    } catch (e) {
      throw ReceiptParseException('Failed to parse receipt: $e');
    }
  }
}

class ReceiptParseResult {
  final List<ParsedItem> items;
  final double subtotal;
  final double tax;
  final double serviceCharge;
  final double discount;
  final double total;
  final String currency;

  ReceiptParseResult({
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.serviceCharge,
    required this.discount,
    required this.total,
    required this.currency,
  });

  factory ReceiptParseResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List<dynamic>) {
      throw const FormatException('Receipt parser returned invalid items');
    }

    return ReceiptParseResult(
      items: rawItems
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException(
                'Receipt parser returned an invalid item',
              );
            }
            return ParsedItem.fromJson(item);
          })
          .toList(growable: false),
      subtotal: _parseNumber(json['subtotal']),
      tax: _parseNumber(json['tax']),
      serviceCharge: _parseNumber(json['serviceCharge']),
      discount: _parseNumber(json['discount']),
      total: _parseNumber(json['total']),
      currency: _parseCurrency(json['currency']),
    );
  }

  static double _parseNumber(Object? value) {
    final number = value is num
        ? value.toDouble()
        : value is String
        ? double.tryParse(value)
        : null;
    if (number == null) {
      throw const FormatException('Receipt parser returned an invalid number');
    }
    return number;
  }

  static String _parseCurrency(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException(
        'Receipt parser returned an invalid currency',
      );
    }
    return value.trim();
  }

  double get calculatedTotal {
    if (total > 0) return total;
    return items.fold(0.0, (sum, item) => sum + item.totalPrice) +
        tax +
        serviceCharge -
        discount;
  }
}

class ParsedItem {
  final String name;
  final double price;
  final int quantity;

  ParsedItem({required this.name, required this.price, required this.quantity});

  factory ParsedItem.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    final price = json['price'] is num
        ? (json['price'] as num).toDouble()
        : json['price'] is String
        ? double.tryParse(json['price'] as String)
        : null;
    final quantity = json['quantity'] is num
        ? (json['quantity'] as num).toInt()
        : json['quantity'] is String
        ? int.tryParse(json['quantity'] as String)
        : null;

    if (name == null ||
        name.trim().isEmpty ||
        price == null ||
        quantity == null) {
      throw const FormatException('Receipt parser returned an invalid item');
    }

    return ParsedItem(name: name.trim(), price: price, quantity: quantity);
  }

  double get totalPrice => price * quantity;
}

class ReceiptParseException implements Exception {
  final String message;

  ReceiptParseException(this.message);

  @override
  String toString() => message;
}
