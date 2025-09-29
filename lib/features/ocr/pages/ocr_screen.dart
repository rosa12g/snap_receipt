import 'dart:io';
import 'package:flutter/material.dart';
import 'package:snap_receipt/core/theme/app_theme_constants.dart';

class OCRScreen extends StatelessWidget {
  final File imageFile;

  const OCRScreen({super.key, required this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OCR Result"),
        backgroundColor: AppThemeConstants.primaryColor,
      ),
      body: Column(
        children: [
          // Display the image
          Expanded(
            child: Image.file(
              imageFile,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),

          // Placeholder for OCR result
          Padding(
            padding: const EdgeInsets.all(AppThemeConstants.pagePadding),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppThemeConstants.cardColor,
                borderRadius: BorderRadius.circular(
                  AppThemeConstants.cardRadius,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                "OCR result will appear here...",
                style: TextStyle(
                  fontSize: AppThemeConstants.bodyFontSize,
                  color: AppThemeConstants.secondaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
