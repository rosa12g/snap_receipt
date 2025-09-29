import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snap_receipt/features/camera/pages/camera_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/camera',
    routes: [
      GoRoute(
        path: '/camera',
        builder: (context, state) => const CameraScreen(),
      ),
      // Add preview & OCR screens later
    ],
  );
}
