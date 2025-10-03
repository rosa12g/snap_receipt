import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

class CompressedImageResult {
  final String base64Data;
  final int width;
  final int height;
  final String mimeType;

  CompressedImageResult({
    required this.base64Data,
    required this.width,
    required this.height,
    required this.mimeType,
  });
}

class ImageUtils {
  static Future<CompressedImageResult> compressToJpegBase64(File file, {int maxBytes = 1000000, int maxLongEdge = 1600}) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw const FormatException('Unsupported image');
    }

    // Resize maintaining aspect ratio if needed
    if (image.width > maxLongEdge || image.height > maxLongEdge) {
      final ratio = image.width >= image.height ? maxLongEdge / image.width : maxLongEdge / image.height;
      final newW = (image.width * ratio).round();
      final newH = (image.height * ratio).round();
      image = img.copyResize(image, width: newW, height: newH, interpolation: img.Interpolation.cubic);
    }

    int quality = 90;
    List<int> encoded = img.encodeJpg(image, quality: quality);
    while (encoded.length > maxBytes && quality > 40) {
      quality -= 10;
      encoded = img.encodeJpg(image, quality: quality);
    }

    final b64 = base64Encode(encoded);
    return CompressedImageResult(
      base64Data: b64,
      width: image.width,
      height: image.height,
      mimeType: 'image/jpeg',
    );
  }
}




