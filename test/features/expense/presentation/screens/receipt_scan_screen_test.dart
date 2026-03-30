import 'dart:io';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pulse/core/services/ocr_service.dart';
import 'package:pulse/core/services/receipt_parser_service.dart';
import 'package:pulse/features/chat/domain/entities/message.dart';
import 'package:pulse/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:pulse/features/expense/presentation/screens/receipt_scan_screen.dart';

class MockChatBloc extends MockBloc<ChatEvent, ChatState> implements ChatBloc {}

class MockOcrService extends Mock implements OcrService {}

class MockReceiptParserService extends Mock implements ReceiptParserService {}

class FakeChatEvent extends Fake implements ChatEvent {}

class FakeImagePickerPlatform extends ImagePickerPlatform
    with MockPlatformInterfaceMixin {
  XFile? pickedImage;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    return pickedImage;
  }
}

void main() {
  late MockChatBloc mockChatBloc;
  late MockOcrService mockOcrService;
  late MockReceiptParserService mockReceiptParserService;
  late FakeImagePickerPlatform fakeImagePickerPlatform;
  late ImagePickerPlatform originalImagePickerPlatform;
  late String tempImagePath;

  final getIt = GetIt.instance;

  final chatRoom = ChatRoom(
    id: 'group-1',
    name: 'House Group',
    members: const ['user-1', 'user-2'],
    memberNames: const {'user-1': 'Jimmy', 'user-2': 'Alice'},
    createdAt: DateTime(2026, 1, 1),
    lastMessageAt: DateTime(2026, 3, 13),
    isGroup: true,
  );

  Future<String> createTempImage() async {
    const pngBytes = <int>[
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9C,
      0x63,
      0xF8,
      0xCF,
      0xC0,
      0x00,
      0x00,
      0x03,
      0x01,
      0x01,
      0x00,
      0x18,
      0xDD,
      0x8D,
      0xB1,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ];

    final directory = await Directory.systemTemp.createTemp(
      'receipt_scan_test',
    );
    final file = File('${directory.path}/receipt.png');
    await file.writeAsBytes(Uint8List.fromList(pngBytes));
    return file.path;
  }

  Widget buildApp(GlobalKey<NavigatorState> navigatorKey) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: const Scaffold(body: Text('Launcher')),
    );
  }

  Future<Object?> openReceiptScreen(GlobalKey<NavigatorState> navigatorKey) {
    final resultFuture = navigatorKey.currentState!.push<Object?>(
      MaterialPageRoute<Object?>(
        settings: const RouteSettings(arguments: {'returnResultOnly': true}),
        builder: (_) => BlocProvider<ChatBloc>.value(
          value: mockChatBloc,
          child: const ReceiptScanScreen(),
        ),
      ),
    );
    return resultFuture;
  }

  setUpAll(() {
    registerFallbackValue(FakeChatEvent());
    registerFallbackValue(File('fallback_receipt.png'));
  });

  setUp(() async {
    mockChatBloc = MockChatBloc();
    mockOcrService = MockOcrService();
    mockReceiptParserService = MockReceiptParserService();
    originalImagePickerPlatform = ImagePickerPlatform.instance;
    fakeImagePickerPlatform = FakeImagePickerPlatform();
    ImagePickerPlatform.instance = fakeImagePickerPlatform;
    tempImagePath = await createTempImage();
    fakeImagePickerPlatform.pickedImage = XFile(tempImagePath);

    when(
      () => mockChatBloc.state,
    ).thenReturn(ChatState(status: ChatStatus.loaded, chatRooms: [chatRoom]));
    whenListen(
      mockChatBloc,
      const Stream<ChatState>.empty(),
      initialState: ChatState(status: ChatStatus.loaded, chatRooms: [chatRoom]),
    );

    await getIt.reset();
    getIt.registerSingleton<OcrService>(mockOcrService);
    getIt.registerSingleton<ReceiptParserService>(mockReceiptParserService);
  });

  tearDown(() async {
    ImagePickerPlatform.instance = originalImagePickerPlatform;
    await getIt.reset();
    final file = File(tempImagePath);
    if (await file.exists()) {
      await file.parent.delete(recursive: true);
    }
  });

  testWidgets('shows Vertex copy and no Gemini API warning', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.binding.setSurfaceSize(const Size(900, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildApp(navigatorKey));
    openReceiptScreen(navigatorKey);
    await tester.pumpAndSettle();

    expect(find.text('Powered by Google ML Kit + Vertex AI'), findsOneWidget);
    expect(find.text('Vertex AI'), findsOneWidget);
    expect(find.text('Gemini AI'), findsNothing);
    expect(find.text('API Key Required'), findsNothing);
  });

  testWidgets('successful parse populates editable items and totals', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.binding.setSurfaceSize(const Size(900, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    when(
      () => mockOcrService.extractTextFromImage(any()),
    ).thenAnswer((_) async => '2x Nasi Lemak 15.50');
    when(() => mockReceiptParserService.parseReceiptText(any())).thenAnswer(
      (_) async => ReceiptParseResult(
        items: [ParsedItem(name: 'Nasi Lemak', price: 7.75, quantity: 2)],
        subtotal: 15.5,
        tax: 0,
        serviceCharge: 0,
        discount: 0,
        total: 15.5,
        currency: 'RM',
      ),
    );

    await tester.pumpWidget(buildApp(navigatorKey));
    openReceiptScreen(navigatorKey);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose from Gallery'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Nasi Lemak'), findsOneWidget);
    expect(find.text('RM 15.50'), findsWidgets);
    expect(find.text('Continue to Add Expense'), findsOneWidget);
  });

  testWidgets('receipt preview opens full-screen lightbox on tap', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.binding.setSurfaceSize(const Size(900, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    when(
      () => mockOcrService.extractTextFromImage(any()),
    ).thenAnswer((_) async => 'Nasi Goreng RM 9.00');
    when(() => mockReceiptParserService.parseReceiptText(any())).thenAnswer(
      (_) async => ReceiptParseResult(
        items: [ParsedItem(name: 'Nasi Goreng', price: 9, quantity: 1)],
        subtotal: 9,
        tax: 0,
        serviceCharge: 0,
        discount: 0,
        total: 9,
        currency: 'RM',
      ),
    );

    await tester.pumpWidget(buildApp(navigatorKey));
    openReceiptScreen(navigatorKey);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose from Gallery'));
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('receipt-image-preview')));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Close'), findsOneWidget);
  });

  testWidgets(
    'parse failure allows manual item entry and returns expense args',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.binding.setSurfaceSize(const Size(900, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      when(
        () => mockOcrService.extractTextFromImage(any()),
      ).thenAnswer((_) async => 'Transfer receipt OCR');
      when(
        () => mockReceiptParserService.parseReceiptText(any()),
      ).thenThrow(ReceiptParseException('Vertex function unavailable'));

      await tester.pumpWidget(buildApp(navigatorKey));
      final resultFuture = openReceiptScreen(navigatorKey);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choose from Gallery'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('AI Parsing Error'), findsOneWidget);
      expect(find.text('Add Item Manually'), findsOneWidget);

      await tester.ensureVisible(find.text('Add Item Manually'));
      await tester.tap(find.text('Add Item Manually'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Manual Tea');
      await tester.enterText(find.byType(TextField).at(1), '4.50');
      await tester.enterText(find.byType(TextField).at(2), '2');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Manual Tea'), findsOneWidget);
      expect(find.text('Continue to Add Expense'), findsOneWidget);

      await tester.ensureVisible(find.text('Continue to Add Expense'));
      await tester.tap(find.text('Continue to Add Expense'));
      await tester.pumpAndSettle();

      final result = await resultFuture;
      expect(result, isA<Map<String, dynamic>>());
      expect((result as Map<String, dynamic>)['scannedItems'], [
        {'name': 'Manual Tea', 'price': 4.5, 'quantity': 2},
      ]);
      expect(result['chatRooms'], [chatRoom]);
    },
  );
}
