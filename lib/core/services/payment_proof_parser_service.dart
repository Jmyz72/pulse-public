import 'vertex_ai_service.dart';

class PaymentProofParserService {
  final VertexAiService vertexAiService;

  PaymentProofParserService({required this.vertexAiService});

  Future<PaymentProofParseResult> parsePaymentProofText(String ocrText) async {
    try {
      final payload = await vertexAiService.parsePaymentProofPayload(ocrText);
      return PaymentProofParseResult.fromJson(payload);
    } on VertexAiParseException catch (e) {
      throw PaymentProofParseException(e.message);
    } catch (e) {
      throw PaymentProofParseException('Failed to parse payment proof: $e');
    }
  }
}

class PaymentProofParseResult {
  final double? amount;
  final String? recipient;
  final double confidence;

  PaymentProofParseResult({
    required this.amount,
    required this.recipient,
    required this.confidence,
  });

  factory PaymentProofParseResult.fromJson(Map<String, dynamic> json) {
    final rawConfidence = (json['confidence'] as num?)?.toDouble() ?? 0.0;
    return PaymentProofParseResult(
      amount: (json['amount'] as num?)?.toDouble(),
      recipient: json['recipient'] as String?,
      confidence: rawConfidence.clamp(0.0, 1.0),
    );
  }
}

class PaymentProofParseException implements Exception {
  final String message;

  PaymentProofParseException(this.message);

  @override
  String toString() => message;
}
