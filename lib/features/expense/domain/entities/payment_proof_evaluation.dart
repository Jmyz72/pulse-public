import 'package:equatable/equatable.dart';

class PaymentProofEvaluation extends Equatable {
  final double? extractedAmount;
  final String? extractedRecipient;
  final double confidence;
  final bool isAmountMatch;
  final bool isRecipientMatch;
  final bool canAutoSettle;

  const PaymentProofEvaluation({
    required this.extractedAmount,
    required this.extractedRecipient,
    required this.confidence,
    required this.isAmountMatch,
    required this.isRecipientMatch,
    required this.canAutoSettle,
  });

  @override
  List<Object?> get props => [
    extractedAmount,
    extractedRecipient,
    confidence,
    isAmountMatch,
    isRecipientMatch,
    canAutoSettle,
  ];
}
