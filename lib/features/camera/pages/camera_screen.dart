import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_receipt/core/theme/app_theme_constants.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraReady = false;
  bool _busy = false;
  DateTime _lastCapture = DateTime(1970); // Debounce captures

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset
            .low, // Use lowest valid resolution to minimize buffer size
        enableAudio: false,
        imageFormatGroup:
            ImageFormatGroup.jpeg, // Use JPEG to simplify buffer handling
      );

      await _controller!.initialize();
      if (!mounted) return;

      setState(() => _isCameraReady = true);
    } catch (e) {
      debugPrint('Camera init failed: $e');
    }
  }

  Future<void> _captureImage() async {
    // Debounce: Ignore captures within 3 seconds
    final now = DateTime.now();
    if (now.difference(_lastCapture).inMilliseconds < 3000) {
      debugPrint('Capture debounced: too soon after last capture');
      return;
    }

    if (!_isCameraReady || _controller == null || _busy) {
      debugPrint(
        'Capture skipped: cameraReady=$_isCameraReady, controller=${_controller != null}, busy=$_busy',
      );
      return;
    }

    _busy = true;
    try {
      // Pause preview to free resources
      await _controller!.pausePreview();
      final start = DateTime.now();
      final XFile shot = await _controller!.takePicture();
      final duration = DateTime.now().difference(start).inMilliseconds;
      debugPrint('Image captured: ${shot.path}, took ${duration}ms');
      final file = File(shot.path);
      if (!mounted) return;

      _lastCapture = DateTime.now();
      // Delay to ensure buffer release
      await Future.delayed(const Duration(milliseconds: 500));
      context.push('/preview', extra: file);
    } catch (e) {
      debugPrint('Capture failed: $e');
    } finally {
      // Resume preview
      if (_controller != null && _isCameraReady) {
        try {
          await _controller!.resumePreview();
        } catch (e) {
          debugPrint('Failed to resume preview: $e');
        }
      }
      _busy = false;
    }
  }

  Future<void> _pickImage() async {
    if (_busy) {
      debugPrint('Upload skipped: busy=$_busy');
      return;
    }

    _busy = true;
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        if (!mounted) return;
        debugPrint('Uploaded file: ${file.path}');
        context.push('/preview', extra: file);
      } else {
        debugPrint('No image selected from gallery');
      }
    } catch (e) {
      debugPrint('Gallery pick failed: $e');
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _isCameraReady && _controller != null
                ? CameraPreview(_controller!)
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
          ),
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
                  onPressed: _busy ? null : _pickImage,
                ),
                _CameraButton(
                  icon: Icons.camera_alt,
                  label: "Capture",
                  onPressed: _busy ? null : _captureImage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
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
          final height = width / 0.58;
          final left = (c.maxWidth - width) / 2;
          final top = (c.maxHeight - height) / 2;

          return Stack(
            children: [
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
                    border: Border.all(
                      color: Colors.white.withOpacity(0.95),
                      width: 3,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
