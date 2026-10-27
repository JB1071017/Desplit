import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/app_colors.dart';

import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initialize();
  runApp(const DeSplitApp());
}

class DeSplitApp extends StatelessWidget {
  const DeSplitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'deSplit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.canvasBackground,
        primaryColor: AppColors.brandAccent,
        canvasColor: AppColors.canvasBackground,
        colorScheme: ColorScheme.dark(
          primary: AppColors.brandAccent,
          secondary: AppColors.accentHover,
          surface: AppColors.cardSurface,
        ),
        fontFamily: 'Segoe UI',
      ),
      home: const SplashScreen(),
    );
  }
}
