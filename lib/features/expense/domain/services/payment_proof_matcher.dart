import '../entities/payment_proof_analysis.dart';
import '../entities/payment_proof_evaluation.dart';

class PaymentProofMatcher {
  static const double amountTolerance = 0.05;
  static const double minConfidence = 0.75;

  PaymentProofEvaluation evaluate({
    required double expectedAmount,
    required String? ownerPaymentIdentity,
    required PaymentProofAnalysis analysis,
  }) {
    final isAmountMatch =
        analysis.extractedAmount != null &&
        (analysis.extractedAmount! - expectedAmount).abs() <= amountTolerance;

    final normalizedRecipient = _normalize(analysis.extractedRecipient);
    final normalizedAliases = _aliases(ownerPaymentIdentity)
        .map(_normalize)
        .where((alias) => alias.isNotEmpty)
        .toList(growable: false);

    final isRecipientMatch =
        normalizedRecipient.isNotEmpty &&
        normalizedAliases.isNotEmpty &&
        normalizedAliases.any(
          (alias) =>
              normalizedRecipient.contains(alias) ||
              alias.contains(normalizedRecipient),
        );

    final canAutoSettle =
        isAmountMatch &&
        isRecipientMatch &&
        analysis.confidence >= minConfidence;

    return PaymentProofEvaluation(
      extractedAmount: analysis.extractedAmount,
      extractedRecipient: analysis.extractedRecipient,
      confidence: analysis.confidence,
      isAmountMatch: isAmountMatch,
      isRecipientMatch: isRecipientMatch,
      canAutoSettle: canAutoSettle,
    );
  }

  List<String> _aliases(String? value) {
    if (value == null) return const [];
    return value
        .split(RegExp(r'[\n,;|]+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
  }

  String _normalize(String? value) {
    return (value ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
