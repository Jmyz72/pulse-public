import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/services/vertex_ai_service.dart';

void main() {
  group('decodeStructuredJsonResponse', () {
    test('decodes plain JSON object', () {
      final result = decodeStructuredJsonResponse(
        '{"items":[],"subtotal":0,"tax":0,"serviceCharge":0,"discount":0,"total":0,"currency":"RM"}',
        responseType: 'receipt',
      );

      expect(result['currency'], 'RM');
      expect(result['items'], isA<List<dynamic>>());
    });

    test('strips code fences and surrounding text', () {
      final result = decodeStructuredJsonResponse(
        'Here is the JSON:\n```json\n{"amount":26.84,"recipient":"Jimmy","confidence":0.91}\n```',
        responseType: 'payment proof',
      );

      expect(result['amount'], 26.84);
      expect(result['recipient'], 'Jimmy');
    });

    test('throws a VertexAiParseException for malformed JSON', () {
      expect(
        () => decodeStructuredJsonResponse(
          '{"items":[{"name":"Tea","price',
          responseType: 'receipt',
        ),
        throwsA(
          isA<VertexAiParseException>().having(
            (e) => e.message,
            'message',
            contains('invalid JSON'),
          ),
        ),
      );
    });
  });
}
