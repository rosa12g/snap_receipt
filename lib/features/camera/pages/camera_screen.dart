import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snap_receipt/core/theme/app_theme_constants.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_receipt/features/receipts/services/ocr_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraReady = false;
  final ImagePicker _picker = ImagePicker();
  Timer? _scanTimer;
  bool _busy = false;
  final OcrService _ocr = OcrService();

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _controller = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (!mounted) return;
        setState(() => _isCameraReady = true);
        _startAutoScan();
      }
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
      // fallback: user can still pick from gallery
    }
  }

  // Capture image from camera
  Future<void> _captureImage() async {
    if (!_isCameraReady || _controller == null) return;

    try {
      if (_controller!.value.isTakingPicture) return;
      await _controller!.pausePreview();
      final XFile capturedFile = await _controller!.takePicture();
      final file = File(capturedFile.path);
      if (!mounted) return;
      context.push('/preview', extra: file);
    } catch (e) {
      debugPrint('Capture failed: $e');
    } finally {
      try { await _controller?.resumePreview(); } catch (_) {}
    }
  }

  void _startAutoScan() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted || !_isCameraReady || _controller == null || _busy) return;
      try {
        _busy = true;
        if (_controller!.value.isTakingPicture) return;
        await _controller!.pausePreview();
        final XFile shot = await _controller!.takePicture();
        final data = await _ocr.processImage(shot);
        if (_ocr.shouldAutoCapture(data.rawText ?? '')) {
          if (!mounted) return;
          _scanTimer?.cancel();
          final file = File(shot.path);
          context.push('/preview', extra: file);
        }
      } catch (_) {
        // ignore scan errors
      } finally {
        try { await _controller?.resumePreview(); } catch (_) {}
        _busy = false;
      }
    });
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        if (!mounted) return;
        context.push('/preview', extra: file);
      }
    } catch (e) {
      debugPrint('Gallery pick failed: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scanTimer?.cancel();
    _ocr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen camera preview
          Positioned.fill(
            child: _isCameraReady && _controller != null
                ? CameraPreview(_controller!)
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: Text(
                        'Camera Preview',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
          ),

          // Guide overlay
          const _ReceiptGuideOverlay(),

         
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CameraButton(
                  icon: Icons.upload,
                  label: "Upload",
                  onPressed: _pickImage,
                ),
                _CameraButton(
                  icon: Icons.camera_alt,
                  label: "Capture",
                  onPressed: _captureImage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable camera button
class _CameraButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _CameraButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppThemeConstants.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeConstants.buttonRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}

class _ReceiptGuideOverlay extends StatelessWidget {
  const _ReceiptGuideOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, c) {
          final width = c.maxWidth * 0.86;
          final height = width / 0.58; // typical receipt aspect
          final left = (c.maxWidth - width) / 2;
          final top = (c.maxHeight - height) / 2;
          return Stack(children: [
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.45)),
            ),
            Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.95), width: 3),
                  color: Colors.transparent,
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

