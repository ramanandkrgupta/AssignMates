import 'package:flutter/material.dart';
import 'src/themes/light.dart';
import 'src/themes/dark.dart';
import 'src/screens/auth/splash_screen.dart';

class AssignMatesApp extends StatelessWidget {
  const AssignMatesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AssignMates',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
