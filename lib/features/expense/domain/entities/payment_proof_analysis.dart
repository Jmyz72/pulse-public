import 'package:equatable/equatable.dart';

class PaymentProofAnalysis extends Equatable {
  final double? extractedAmount;
  final String? extractedRecipient;
  final double confidence;
  final String rawText;

  const PaymentProofAnalysis({
    required this.extractedAmount,
    required this.extractedRecipient,
    required this.confidence,
    required this.rawText,
  });

  @override
  List<Object?> get props => [
    extractedAmount,
    extractedRecipient,
    confidence,
    rawText,
  ];
}
