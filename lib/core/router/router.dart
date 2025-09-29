import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_receipt/features/camera/pages/camera_screen.dart';
import 'package:snap_receipt/features/ocr/pages/ocr_screen.dart';
import 'package:snap_receipt/features/preview/pages/preview_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/camera',
    routes: [
      GoRoute(
        path: '/camera',
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/preview',
        builder: (context, state) {
          final file = state.extra as File;
          return PreviewScreen(imageFile: file);
        },
      ),
      GoRoute(
        path: '/ocr',
        builder: (context, state) {
          final file = state.extra as File;
          return OCRScreen(imageFile: file);
        },
      ),
    ],
  );
}
