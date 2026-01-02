import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MatnYarApp());
}

/// اپلیکیشن متن‌یار
/// ابزار تبدیل و بازسازی متن - آفلاین و متن‌محور
class MatnYarApp extends StatelessWidget {
  const MatnYarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'متن‌یار',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

