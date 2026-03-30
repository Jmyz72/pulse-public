import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class VertexAiService {
  VertexAiService({required FirebaseAuth firebaseAuth})
    : _firebaseAI = FirebaseAI.vertexAI(auth: firebaseAuth, location: 'global');

  static const _modelName = 'gemini-2.5-flash';
  static const _minCallInterval = Duration(seconds: 1);
  static const _receiptMaxOutputTokens = 65536;
  static const _paymentProofMaxOutputTokens = 65536;

  final FirebaseAI _firebaseAI;
  DateTime? _lastCallTime;

  late final GenerativeModel _receiptModel = _firebaseAI.generativeModel(
    model: _modelName,
    generationConfig: GenerationConfig(
      temperature: 0.1,
      maxOutputTokens: _receiptMaxOutputTokens,
      responseMimeType: 'application/json',
      responseSchema: _receiptSchema,
    ),
  );

  late final GenerativeModel _paymentProofModel = _firebaseAI.generativeModel(
    model: _modelName,
    generationConfig: GenerationConfig(
      temperature: 0.1,
      maxOutputTokens: _paymentProofMaxOutputTokens,
      responseMimeType: 'application/json',
      responseSchema: _paymentProofSchema,
    ),
  );

  static final Schema _receiptSchema = Schema.object(
    properties: {
      'items': Schema.array(
        items: Schema.object(
          properties: {
            'name': Schema.string(),
            'price': Schema.number(),
            'quantity': Schema.integer(),
          },
          propertyOrdering: const ['name', 'price', 'quantity'],
        ),
      ),
      'subtotal': Schema.number(),
      'tax': Schema.number(),
      'serviceCharge': Schema.number(),
      'discount': Schema.number(),
      'total': Schema.number(),
      'currency': Schema.string(),
    },
    propertyOrdering: const [
      'items',
      'subtotal',
      'tax',
      'serviceCharge',
      'discount',
      'total',
      'currency',
    ],
  );

  static final Schema _paymentProofSchema = Schema.object(
    properties: {
      'amount': Schema.number(nullable: true),
      'recipient': Schema.string(nullable: true),
      'confidence': Schema.number(),
    },
    optionalProperties: const ['amount', 'recipient'],
    propertyOrdering: const ['amount', 'recipient', 'confidence'],
  );

  Future<Map<String, dynamic>> parseReceiptPayload(String ocrText) async {
    await _waitForRateLimit();

    final sanitizedText = _sanitizeText(
      ocrText,
      maxLength: 5000,
      emptyMessage: 'No receipt text to parse',
      tooLongMessage: 'Receipt text too long (max 5000 characters)',
    );

    try {
      return await _generateStructuredPayload(
        model: _receiptModel,
        prompt: _buildReceiptPrompt(sanitizedText),
        responseType: 'receipt',
      );
    } on VertexAiParseException {
      rethrow;
    } catch (e) {
      throw VertexAiParseException('Vertex AI request failed for receipt: $e');
    }
  }

  Future<Map<String, dynamic>> parsePaymentProofPayload(String ocrText) async {
    await _waitForRateLimit();

    final sanitizedText = _sanitizeText(
      ocrText,
      maxLength: 5000,
      emptyMessage: 'No payment proof text to parse',
      tooLongMessage: 'Payment proof text too long (max 5000 characters)',
    );

    try {
      return await _generateStructuredPayload(
        model: _paymentProofModel,
        prompt: _buildPaymentProofPrompt(sanitizedText),
        responseType: 'payment proof',
      );
    } on VertexAiParseException {
      rethrow;
    } catch (e) {
      throw VertexAiParseException(
        'Vertex AI request failed for payment proof: $e',
      );
    }
  }

  Future<void> _waitForRateLimit() async {
    if (_lastCallTime != null) {
      final elapsed = DateTime.now().difference(_lastCallTime!);
      if (elapsed < _minCallInterval) {
        await Future.delayed(_minCallInterval - elapsed);
      }
    }
    _lastCallTime = DateTime.now();
  }

  String _sanitizeText(
    String text, {
    required int maxLength,
    required String emptyMessage,
    required String tooLongMessage,
  }) {
    final sanitizedText = text.replaceAll(RegExp(r'[{}"\[\]]'), '').trim();
    if (sanitizedText.length > maxLength) {
      throw VertexAiParseException(tooLongMessage);
    }
    if (sanitizedText.isEmpty) {
      throw VertexAiParseException(emptyMessage);
    }
    return sanitizedText;
  }

  Future<Map<String, dynamic>> _generateStructuredPayload({
    required GenerativeModel model,
    required String prompt,
    required String responseType,
  }) async {
    final response = await model.generateContent([Content.text(prompt)]);
    final responseText = response.text;

    try {
      return decodeStructuredJsonResponse(
        responseText,
        responseType: responseType,
      );
    } on VertexAiParseException catch (e) {
      final rawResponse = responseText?.trim() ?? '';
      if (rawResponse.isEmpty) rethrow;

      return _repairStructuredPayload(
        model: model,
        invalidResponse: rawResponse,
        responseType: responseType,
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> _repairStructuredPayload({
    required GenerativeModel model,
    required String invalidResponse,
    required String responseType,
    required VertexAiParseException originalError,
  }) async {
    final repairResponse = await model.generateContent([
      Content.text(
        _buildJsonRepairPrompt(
          invalidResponse,
          responseType: responseType,
          originalError: originalError.message,
        ),
      ),
    ]);

    try {
      return decodeStructuredJsonResponse(
        repairResponse.text,
        responseType: responseType,
      );
    } on VertexAiParseException catch (repairError) {
      throw VertexAiParseException(
        'Vertex AI returned invalid JSON for $responseType after repair. '
        'Original error: ${originalError.message}. '
        'Repair error: ${repairError.message}',
      );
    }
  }

  String _buildReceiptPrompt(String ocrText) {
    return '''
Extract receipt items and totals from this OCR text.
Return exactly one valid JSON object only.

OCR text:
$ocrText

Rules:
1. Extract line items with name, price, and quantity.
2. If quantity is missing, assume 1.
3. Use numeric values, not strings, for all numbers.
4. Detect currency; default to RM if unclear.
5. Include subtotal, tax, service charge, discount, and total when present.
6. Ignore store info, address, date, cashier, and payment method.
7. If "x" or "X" appears before a number, that is the quantity.
8. If no items are identifiable, return an empty items array.
9. No markdown, no code fences, no extra text.
10. JSON must be syntactically valid.
''';
  }

  String _buildPaymentProofPrompt(String ocrText) {
    return '''
Extract the transferred amount and recipient from this payment proof OCR text.
Return exactly one valid JSON object only.

OCR text:
$ocrText

Rules:
1. amount is the transferred amount as a number, or null if unclear.
2. recipient is the payee / receiver / beneficiary name, or null if unclear.
3. confidence is a number between 0 and 1.
4. Ignore sender names, balances, reference IDs, and timestamps unless needed.
5. No markdown, no code fences, no extra text.
6. JSON must be syntactically valid.
''';
  }

  String _buildJsonRepairPrompt(
    String invalidResponse, {
    required String responseType,
    required String originalError,
  }) {
    return '''
The following $responseType response is intended to be JSON but is invalid.

Error:
$originalError

Invalid response:
$invalidResponse

Rewrite it as a single valid JSON object only.
Do not add markdown, code fences, explanation, or extra text.
If a field is unclear, use null for nullable fields, 0 for numeric totals, and [] for items.
JSON must be syntactically valid.
''';
  }
}

@visibleForTesting
Map<String, dynamic> decodeStructuredJsonResponse(
  String? responseText, {
  required String responseType,
}) {
  var jsonString = responseText?.trim() ?? '';
  if (jsonString.isEmpty) {
    throw VertexAiParseException(
      'Vertex AI returned an empty $responseType response',
    );
  }

  if (jsonString.startsWith('```json')) {
    jsonString = jsonString.substring(7);
  }
  if (jsonString.startsWith('```')) {
    jsonString = jsonString.substring(3);
  }
  if (jsonString.endsWith('```')) {
    jsonString = jsonString.substring(0, jsonString.length - 3);
  }

  jsonString = jsonString.trim();

  final firstBrace = jsonString.indexOf('{');
  final lastBrace = jsonString.lastIndexOf('}');
  if (firstBrace >= 0 && lastBrace > firstBrace) {
    jsonString = jsonString.substring(firstBrace, lastBrace + 1);
  }

  try {
    final decoded = json.decode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw VertexAiParseException(
        'Vertex AI returned a non-object $responseType response',
      );
    }
    return decoded;
  } on FormatException catch (e) {
    throw VertexAiParseException(
      'Vertex AI returned invalid JSON for $responseType: ${e.message}',
    );
  }
}

class VertexAiParseException implements Exception {
  final String message;

  VertexAiParseException(this.message);

  @override
  String toString() => message;
}
