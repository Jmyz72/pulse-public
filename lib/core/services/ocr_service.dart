import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Service for OCR (Optical Character Recognition) using Google ML Kit
class OcrService {
  final TextRecognizer _textRecognizer;

  OcrService() : _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Extract text from an image file
  Future<String> extractTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      throw OcrException('Failed to extract text from image: $e');
    }
  }

  /// Extract text with detailed block information
  Future<OcrResult> extractDetailedText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final blocks = recognizedText.blocks.map((block) {
        return OcrBlock(
          text: block.text,
          lines: block.lines.map((line) => line.text).toList(),
          boundingBox: block.boundingBox,
        );
      }).toList();

      return OcrResult(
        fullText: recognizedText.text,
        blocks: blocks,
      );
    } catch (e) {
      throw OcrException('Failed to extract text from image: $e');
    }
  }

  /// Dispose of the text recognizer
  void dispose() {
    _textRecognizer.close();
  }
}

/// Result of OCR processing
class OcrResult {
  final String fullText;
  final List<OcrBlock> blocks;

  OcrResult({
    required this.fullText,
    required this.blocks,
  });
}

/// A block of recognized text
class OcrBlock {
  final String text;
  final List<String> lines;
  final dynamic boundingBox;

  OcrBlock({
    required this.text,
    required this.lines,
    this.boundingBox,
  });
}

/// Exception for OCR errors
class OcrException implements Exception {
  final String message;
  OcrException(this.message);

  @override
  String toString() => message;
}
