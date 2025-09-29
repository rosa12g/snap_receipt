import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snap_receipt/core/theme/app_theme_constants.dart';
import 'package:camera/camera.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraReady = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

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
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (!mounted) return;
        setState(() => _isCameraReady = true);
      }
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
      // Fallback: user can pick from gallery
    }
  }

  // Capture image from camera
  Future<void> _captureImage() async {
    if (!_isCameraReady || _controller == null) return;

    try {
      final XFile capturedFile = await _controller!.takePicture();
      setState(() => _imageFile = File(capturedFile.path));
    } catch (e) {
      debugPrint('Capture failed: $e');
    }
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Gallery pick failed: $e');
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
          // Full-screen camera preview or image
          Positioned.fill(
            child: _imageFile != null
                ? Image.file(_imageFile!, fit: BoxFit.cover)
                : _isCameraReady && _controller != null
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

          // Bottom buttons
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
