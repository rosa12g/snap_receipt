import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_receipt/core/theme/app_theme_constants.dart';
import 'package:image/image.dart' as img;

class PreviewScreen extends StatefulWidget {
  final File imageFile;

  const PreviewScreen({super.key, required this.imageFile});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  // Normalized crop rect [0..1]
  double left = 0.07;
  double top = 0.15;
  double width = 0.86;
  double height = 0.6;

  Offset? _dragStart;
  late double _startLeft;
  late double _startTop;
  late double _startWidth;
  late double _startHeight;

  void _onPanStart(DragStartDetails d, Size size) {
    _dragStart = d.localPosition;
    _startLeft = left;
    _startTop = top;
  }

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    if (_dragStart == null) return;
    final dx = d.localPosition.dx - _dragStart!.dx;
    final dy = d.localPosition.dy - _dragStart!.dy;
    final nl = (_startLeft + dx / size.width).clamp(0.0, 1.0 - width);
    final nt = (_startTop + dy / size.height).clamp(0.0, 1.0 - height);
    setState(() {
      left = nl;
      top = nt;
    });
  }

  // Resize via drag handles
  void _onResizeStart(Size size) {
    _startWidth = width;
    _startHeight = height;
    _startLeft = left;
    _startTop = top;
  }

  void _applyBounds() {
    width = width.clamp(0.25, 0.98);
    height = height.clamp(0.18, 0.98);
    left = left.clamp(0.0, 1.0 - width);
    top = top.clamp(0.0, 1.0 - height);
  }

  Future<File> _cropToFile() async {
    final bytes = await widget.imageFile.readAsBytes();
    final src = img.decodeImage(bytes);
    if (src == null) return widget.imageFile;
    final x = (left * src.width).round();
    final y = (top * src.height).round();
    final w = (width * src.width).round();
    final h = (height * src.height).round();
    final rect = img.copyCrop(src, x: math.max(0, x), y: math.max(0, y), width: math.min(w, src.width - x), height: math.min(h, src.height - y));
    final out = img.encodeJpg(rect, quality: 90);
    final file = File(widget.imageFile.path.replaceFirst('.jpg', '_crop.jpg'));
    await file.writeAsBytes(out, flush: true);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final box = Size(c.maxWidth, c.maxHeight);
          return Stack(
            children: [
              Positioned.fill(child: Image.file(widget.imageFile, fit: BoxFit.cover)),

              // Crop overlay with hole
              Positioned.fill(
                child: GestureDetector(
                  onPanStart: (d) => _onPanStart(d, box),
                  onPanUpdate: (d) => _onPanUpdate(d, box),
                  child: CustomPaint(
                    painter: _CropOverlayPainter(left, top, width, height),
                  ),
                ),
              ),

              // Drag handles (corners)
              _CornerHandle(
                positionBuilder: (s) => Offset(left * s.width, top * s.height),
                onPanStart: (sz) => setState(() => _onResizeStart(sz)),
                onPanUpdate: (delta, sz) {
                  setState(() {
                    final dx = delta.dx / sz.width;
                    final dy = delta.dy / sz.height;
                    left = _startLeft + dx;
                    top = _startTop + dy;
                    width = _startWidth - dx;
                    height = _startHeight - dy;
                    _applyBounds();
                  });
                },
              ),
              _CornerHandle(
                positionBuilder: (s) => Offset((left + width) * s.width, top * s.height),
                onPanStart: (sz) => setState(() => _onResizeStart(sz)),
                onPanUpdate: (delta, sz) {
                  setState(() {
                    final dx = delta.dx / sz.width;
                    final dy = delta.dy / sz.height;
                    top = _startTop + dy;
                    width = _startWidth + dx;
                    height = _startHeight - dy;
                    _applyBounds();
                  });
                },
              ),
              _CornerHandle(
                positionBuilder: (s) => Offset(left * s.width, (top + height) * s.height),
                onPanStart: (sz) => setState(() => _onResizeStart(sz)),
                onPanUpdate: (delta, sz) {
                  setState(() {
                    final dx = delta.dx / sz.width;
                    final dy = delta.dy / sz.height;
                    left = _startLeft + dx;
                    width = _startWidth - dx;
                    height = _startHeight + dy;
                    _applyBounds();
                  });
                },
              ),
              _CornerHandle(
                positionBuilder: (s) => Offset((left + width) * s.width, (top + height) * s.height),
                onPanStart: (sz) => setState(() => _onResizeStart(sz)),
                onPanUpdate: (delta, sz) {
                  setState(() {
                    final dx = delta.dx / sz.width;
                    final dy = delta.dy / sz.height;
                    width = _startWidth + dx;
                    height = _startHeight + dy;
                    _applyBounds();
                  });
                },
              ),

              // Bottom buttons
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Retake button
                    ElevatedButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retake"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemeConstants.errorColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppThemeConstants.buttonRadius),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),

                    // Crop & Next
                    ElevatedButton.icon(
                      onPressed: () async {
                        final file = await _cropToFile();
                        if (!mounted) return;
                        context.push('/ocr', extra: file);
                      },
                      icon: const Icon(Icons.crop),
                      label: const Text("Crop & Next"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemeConstants.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppThemeConstants.buttonRadius),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // removed +/- controls in favor of draggable corners
}

class _CropOverlayPainter extends CustomPainter {
  final double left;
  final double top;
  final double width;
  final double height;
  _CropOverlayPainter(this.left, this.top, this.width, this.height);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.5);
    final rect = Rect.fromLTWH(left * size.width, top * size.height, width * size.width, height * size.height);
    // dim everything
    canvas.drawRect(Offset.zero & size, paint);
    // cut out crop area
    final clear = Paint()..blendMode = BlendMode.clear;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(rect, clear);
    canvas.restore();
    // border
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)), border);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return left != oldDelegate.left || top != oldDelegate.top || width != oldDelegate.width || height != oldDelegate.height;
  }
}

class _CornerHandle extends StatelessWidget {
  final Offset Function(Size) positionBuilder;
  final void Function(Size) onPanStart;
  final void Function(Offset delta, Size) onPanUpdate;
  const _CornerHandle({required this.positionBuilder, required this.onPanStart, required this.onPanUpdate});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      final pos = positionBuilder(size);
      return Positioned(
        left: pos.dx - 16,
        top: pos.dy - 16,
        child: GestureDetector(
          onPanStart: (_) => onPanStart(size),
          onPanUpdate: (d) => onPanUpdate(d.delta, size),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: const Icon(Icons.drag_handle, size: 16, color: Colors.black87),
          ),
        ),
      );
    });
  }
}
