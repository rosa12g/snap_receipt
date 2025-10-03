import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:snap_receipt/core/theme/app_theme_constants.dart';

class PreviewScreen extends StatefulWidget {
  final File imageFile;

  const PreviewScreen({super.key, required this.imageFile});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  double left = 0.07;
  double top = 0.15;
  double width = 0.86;
  double height = 0.70;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Receipt'),
        backgroundColor: AppThemeConstants.primaryColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.file(widget.imageFile, fit: BoxFit.contain),
          ),
          _CropOverlay(
            left: left,
            top: top,
            width: width,
            height: height,
            onDrag: (dx, dy) {
              setState(() {
                left = (left + dx).clamp(0.0, 1.0 - width);
                top = (top + dy).clamp(0.0, 1.0 - height);
              });
            },
            onResize: (corner, dx, dy) {
              setState(() {
                if (corner == 'topLeft') {
                  final newWidth = width - dx;
                  final newHeight = height - dy;
                  if (newWidth >= 0.1 && newHeight >= 0.1) {
                    left += dx;
                    top += dy;
                    width = newWidth;
                    height = newHeight;
                  }
                } else if (corner == 'bottomRight') {
                  final newWidth = width + dx;
                  final newHeight = height + dy;
                  if (newWidth <= 1.0 - left && newHeight <= 1.0 - top) {
                    width = newWidth;
                    height = newHeight;
                  }
                }
              });
            },
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Retake button
                ElevatedButton.icon(
                  onPressed: () {
                    context.go('/camera'); // Go back to camera screen
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retake"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: AppThemeConstants.primaryColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppThemeConstants.buttonRadius,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
                // Crop & Next button
                ElevatedButton.icon(
                  onPressed: () async {
                    final file = await _cropToFile();
                    if (!mounted) return;
                    debugPrint(
                      'Navigating to OCR with cropped file: ${file.path}',
                    );
                    context.push('/ocr', extra: file);
                  },
                  icon: const Icon(Icons.crop),
                  label: const Text("Crop & Next"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeConstants.primaryColor,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppThemeConstants.buttonRadius,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<File> _cropToFile() async {
    final start = DateTime.now();
    final bytes = await widget.imageFile.readAsBytes();
    final src = img.decodeImage(bytes);
    if (src == null) {
      debugPrint('Failed to decode image: ${widget.imageFile.path}');
      return widget.imageFile;
    }

    final x = (left * src.width).round();
    final y = (top * src.height).round();
    final w = (width * src.width).round();
    final h = (height * src.height).round();

    final rect = img.copyCrop(
      src,
      x: math.max(0, x),
      y: math.max(0, y),
      width: math.min(w, src.width - x),
      height: math.min(h, src.height - y),
    );

    final out = img.encodeJpg(rect, quality: 85);
    final file = File(
      '${widget.imageFile.path}_${DateTime.now().millisecondsSinceEpoch}_crop.jpg',
    );
    await file.writeAsBytes(out, flush: true);

    final duration = DateTime.now().difference(start).inMilliseconds;
    debugPrint('Cropped image saved: ${file.path}, took ${duration}ms');

    // Delete original file
    if (await widget.imageFile.exists()) {
      try {
        await widget.imageFile.delete();
        debugPrint('Deleted original file: ${widget.imageFile.path}');
      } catch (e) {
        debugPrint('Failed to delete original file: $e');
      }
    }

    return file;
  }
}

class _CropOverlay extends StatelessWidget {
  final double left;
  final double top;
  final double width;
  final double height;
  final Function(double dx, double dy) onDrag;
  final Function(String corner, double dx, double dy) onResize;

  const _CropOverlay({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.onDrag,
    required this.onResize,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cropLeft = left * constraints.maxWidth;
        final cropTop = top * constraints.maxHeight;
        final cropWidth = width * constraints.maxWidth;
        final cropHeight = height * constraints.maxHeight;

        return Stack(
          children: [
            // Darkened background outside crop area
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
            // Crop area
            Positioned(
              left: cropLeft,
              top: cropTop,
              width: cropWidth,
              height: cropHeight,
              child: GestureDetector(
                onPanUpdate: (details) {
                  onDrag(
                    details.delta.dx / constraints.maxWidth,
                    details.delta.dy / constraints.maxHeight,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.95),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            // Top-left handle
            _buildHandle(
              context,
              left: cropLeft - 10,
              top: cropTop - 10,
              onUpdate: (dx, dy) => onResize(
                'topLeft',
                dx / constraints.maxWidth,
                dy / constraints.maxHeight,
              ),
            ),
            // Bottom-right handle
            _buildHandle(
              context,
              left: cropLeft + cropWidth - 10,
              top: cropTop + cropHeight - 10,
              onUpdate: (dx, dy) => onResize(
                'bottomRight',
                dx / constraints.maxWidth,
                dy / constraints.maxHeight,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHandle(
    BuildContext context, {
    required double left,
    required double top,
    required Function(double dx, double dy) onUpdate,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanUpdate: (details) => onUpdate(details.delta.dx, details.delta.dy),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppThemeConstants.primaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(1, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
