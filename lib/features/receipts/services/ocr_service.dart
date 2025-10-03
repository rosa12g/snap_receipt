import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

import '../models/receipt_data.dart';
import 'receipt_parser.dart';
import '../../../shared/utils/image_utils.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);


  bool shouldAutoCapture(String text, {int threshold = 120}) {
    final normalized = text.replaceAll(RegExp(r'\s+'), '');
    return normalized.length >= threshold;
  }

  Future<ReceiptData> processImage(XFile image) async {
    // 1) Normalize + compress to improve OCR reliability
    final tempDir = await getTemporaryDirectory();
    final srcFile = File(image.path);
    final compressed = await ImageUtils.compressToJpegBase64(srcFile);
    final normalizedPath = '${tempDir.path}/ocr_normalized.jpg';
    await File(normalizedPath).writeAsBytes(
      // Decode base64 back to bytes for ML Kit file processing
      // (keeps EXIF-normalized orientation and size <= ~1600px)
      List<int>.from(UriData.parse('data:image/jpeg;base64,${compressed.base64Data}').contentAsBytes()),
      flush: true,
    );

    // 2) Run ML Kit Text Recognition
    final input = InputImage.fromFilePath(normalizedPath);
    final recognized = await _textRecognizer.processImage(input);
    final rawText = recognized.text;

    // 3) Parse
    final parser = ReceiptParser();
    final parsed = parser.parse(rawText);

    return ReceiptData(
      storeName: parsed.storeName,
      purchaseDate: parsed.purchaseDate,
      currency: parsed.currency,
      totalAmount: parsed.totalAmount,
      items: parsed.items,
      confidence: parsed.confidence,
      rawText: rawText,
    );
  }

  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}



