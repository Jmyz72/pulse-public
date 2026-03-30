import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/services/payment_proof_parser_service.dart';
import 'package:pulse/core/services/vertex_ai_service.dart';

class MockVertexAiService extends Mock implements VertexAiService {}

void main() {
  late MockVertexAiService vertexAiService;
  late PaymentProofParserService service;

  setUp(() {
    vertexAiService = MockVertexAiService();
    service = PaymentProofParserService(vertexAiService: vertexAiService);
  });

  test('returns Vertex AI result when parsing succeeds', () async {
    when(() => vertexAiService.parsePaymentProofPayload(any())).thenAnswer(
      (_) async => {
        'amount': 26.84,
        'recipient': 'Jimmy Test',
        'confidence': 0.91,
      },
    );

    final result = await service.parsePaymentProofText(
      'Transfer to Jimmy Test RM 26.84',
    );

    expect(result.amount, 26.84);
    expect(result.recipient, 'Jimmy Test');
    expect(result.confidence, 0.91);
  });

  test('throws payment proof parse exception when Vertex AI fails', () async {
    when(
      () => vertexAiService.parsePaymentProofPayload(any()),
    ).thenThrow(VertexAiParseException('quota exceeded'));

    await expectLater(
      () => service.parsePaymentProofText('Paid RM 3.00 to Hew Mann Jie'),
      throwsA(
        isA<PaymentProofParseException>().having(
          (e) => e.message,
          'message',
          contains('quota exceeded'),
        ),
      ),
    );
  });
}
