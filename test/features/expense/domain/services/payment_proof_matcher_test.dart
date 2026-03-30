import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/expense/domain/entities/payment_proof_analysis.dart';
import 'package:pulse/features/expense/domain/services/payment_proof_matcher.dart';

void main() {
  group('PaymentProofMatcher', () {
    final matcher = PaymentProofMatcher();

    test('auto-settles when amount, recipient, and confidence match', () {
      const analysis = PaymentProofAnalysis(
        extractedAmount: 26.84,
        extractedRecipient: 'Jimmy Test',
        confidence: 0.92,
        rawText: 'Transfer to Jimmy Test RM 26.84',
      );

      final result = matcher.evaluate(
        expectedAmount: 26.84,
        ownerPaymentIdentity: 'Jimmy Test',
        analysis: analysis,
      );

      expect(result.isAmountMatch, true);
      expect(result.isRecipientMatch, true);
      expect(result.canAutoSettle, true);
    });

    test('stays pending review when recipient does not match', () {
      const analysis = PaymentProofAnalysis(
        extractedAmount: 26.84,
        extractedRecipient: 'Another Recipient',
        confidence: 0.92,
        rawText: 'Transfer to Another Recipient RM 26.84',
      );

      final result = matcher.evaluate(
        expectedAmount: 26.84,
        ownerPaymentIdentity: 'Jimmy Test',
        analysis: analysis,
      );

      expect(result.isAmountMatch, true);
      expect(result.isRecipientMatch, false);
      expect(result.canAutoSettle, false);
    });
  });
}
