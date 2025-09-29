import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/router/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Snap Receipt',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
