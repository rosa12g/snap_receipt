import 'package:flutter/material.dart';

class AppThemeConstants {
  // Colors
  static const Color primaryColor = Color(0xFFFF6F00); // Orange accent
  static const Color secondaryColor = Color(0xFF212121); // Dark text
  static const Color successColor = Color(0xFF4CAF50); // Green for high confidence
  static const Color warningColor = Color(0xFFFFC107); // Amber for low confidence
  static const Color errorColor = Color(0xFFF44336); // Red for invalid/mismatch

  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;

  // Typography
  static const double titleFontSize = 20.0;
  static const double subtitleFontSize = 16.0;
  static const double bodyFontSize = 14.0;

  // Padding & Radius
  static const double pagePadding = 16.0;
  static const double cardRadius = 12.0;
  static const double buttonRadius = 8.0;

  // Icons
  static const IconData captureIcon = Icons.camera_alt;
  static const IconData editIcon = Icons.edit;
  static const IconData sendIcon = Icons.send;
  static const IconData warningIcon = Icons.warning_amber_rounded;

  // Animations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);

  // OCR Overlay
  static const double receiptGuideBorderWidth = 3.0;
  static const Color receiptGuideBorderColor = Colors.orangeAccent;
  static const Color ocrHighlightColor = Colors.yellowAccent;

  // Confidence thresholds
  static const double highConfidence = 0.85;
  static const double mediumConfidence = 0.60;
  static const double lowConfidence = 0.40;
}


