import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Isolated service for verifying Bill Payment Proofs using Gemini AI.
/// This is separate from the Receipt OCR service to avoid conflicts.
class BillPaymentVerificationService {
  final String apiKey;
  late final GenerativeModel _model;

  BillPaymentVerificationService({required this.apiKey}) {
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
  }

  /// Analyzes a bank/e-wallet screenshot to verify payment details.
  Future<BillPaymentVerificationResult> verifyPaymentProof({
    required Uint8List imageBytes,
    required double expectedAmount,
    String? expectedRecipient,
  }) async {
    try {
      final content = [
        Content.multi([
          DataPart('image/png', imageBytes),
          TextPart("""
            Analyze this bank transfer or e-wallet transaction receipt.
            Extract:
            1. Total Amount paid
            2. Transaction Date
            3. Recipient Name/Account
            4. Reference/Transaction ID
            
            Expected Amount: RM $expectedAmount
            ${expectedRecipient != null ? 'Expected Recipient: $expectedRecipient' : ''}
            
            Respond ONLY in valid JSON:
            {
              "extracted_amount": double,
              "extracted_date": "string",
              "extracted_recipient": "string",
              "transaction_id": "string",
              "is_match": boolean,
              "confidence": double (0-1),
              "reason": "explanation"
            }
          """),
        ]),
      ];

      final response = await _model.generateContent(content);
      final text = response.text;

      if (text == null) throw Exception('AI response was empty');

      final jsonString = text.contains('```json')
          ? text.split('```json')[1].split('```')[0].trim()
          : text.trim();

      final Map<String, dynamic> data = jsonDecode(jsonString);

      return BillPaymentVerificationResult.fromJson(data);
    } catch (e) {
      return BillPaymentVerificationResult(
        isMatch: false,
        confidence: 0,
        reason: 'Verification error: $e',
      );
    }
  }
}

class BillPaymentVerificationResult {
  final bool isMatch;
  final double? extractedAmount;
  final String? extractedDate;
  final String? extractedRecipient;
  final String? transactionId;
  final double confidence;
  final String? reason;

  BillPaymentVerificationResult({
    required this.isMatch,
    this.extractedAmount,
    this.extractedDate,
    this.extractedRecipient,
    this.transactionId,
    required this.confidence,
    this.reason,
  });

  factory BillPaymentVerificationResult.fromJson(Map<String, dynamic> json) {
    return BillPaymentVerificationResult(
      isMatch: json['is_match'] ?? false,
      extractedAmount: (json['extracted_amount'] ?? 0).toDouble(),
      extractedDate: json['extracted_date'],
      extractedRecipient: json['extracted_recipient'],
      transactionId: json['transaction_id'],
      confidence: (json['confidence'] ?? 0).toDouble(),
      reason: json['reason'],
    );
  }
}
