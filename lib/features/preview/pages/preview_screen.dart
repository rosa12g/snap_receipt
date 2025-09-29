import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_receipt/core/theme/app_theme_constants.dart';

class PreviewScreen extends StatelessWidget {
  final File imageFile;

  const PreviewScreen({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
        
          Positioned.fill(child: Image.file(imageFile, fit: BoxFit.cover)),

     
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Retake button
                ElevatedButton.icon(
                  onPressed: () => context.pop(), // Go back to camera
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retake"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeConstants.errorColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppThemeConstants.buttonRadius,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),

                // Next button
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to OCR screen
                    context.push('/ocr', extra: imageFile);
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text("Next"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeConstants.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppThemeConstants.buttonRadius,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
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
}
