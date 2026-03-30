import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/core/services/receipt_parser_service.dart';
import 'package:pulse/core/services/vertex_ai_service.dart';

class MockVertexAiService extends Mock implements VertexAiService {}

void main() {
  late MockVertexAiService vertexAiService;
  late ReceiptParserService service;

  setUp(() {
    vertexAiService = MockVertexAiService();
    service = ReceiptParserService(vertexAiService: vertexAiService);
  });

  test('returns parsed receipt result when Vertex AI succeeds', () async {
    when(() => vertexAiService.parseReceiptPayload(any())).thenAnswer(
      (_) async => {
        'items': [
          {'name': 'Nasi Lemak', 'price': 7.75, 'quantity': 2},
        ],
        'subtotal': 15.5,
        'tax': 0,
        'serviceCharge': 0,
        'discount': 0,
        'total': 15.5,
        'currency': 'RM',
      },
    );

    final result = await service.parseReceiptText('2x Nasi Lemak RM 15.50');

    expect(result.items, hasLength(1));
    expect(result.items.first.name, 'Nasi Lemak');
    expect(result.items.first.price, 7.75);
    expect(result.items.first.quantity, 2);
    expect(result.total, 15.5);
    expect(result.currency, 'RM');
  });

  test('throws receipt parse exception when Vertex AI fails', () async {
    when(
      () => vertexAiService.parseReceiptPayload(any()),
    ).thenThrow(VertexAiParseException('network down'));

    await expectLater(
      () => service.parseReceiptText('receipt text'),
      throwsA(
        isA<ReceiptParseException>().having(
          (e) => e.message,
          'message',
          contains('network down'),
        ),
      ),
    );
  });

  test(
    'throws receipt parse exception for invalid Vertex AI payload',
    () async {
      when(() => vertexAiService.parseReceiptPayload(any())).thenAnswer(
        (_) async => {
          'items': 'invalid',
          'subtotal': 12,
          'tax': 0,
          'serviceCharge': 0,
          'discount': 0,
          'total': 12,
          'currency': 'RM',
        },
      );

      await expectLater(
        () => service.parseReceiptText('receipt text'),
        throwsA(
          isA<ReceiptParseException>().having(
            (e) => e.message,
            'message',
            contains('Receipt parser returned invalid items'),
          ),
        ),
      );
    },
  );
}
