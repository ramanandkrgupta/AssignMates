import 'package:flutter/material.dart';
import 'src/themes/light.dart';
import 'src/themes/dark.dart';
import 'src/screens/auth/splash_screen.dart';
import 'src/screens/notification_handler.dart';

class AssignMatesApp extends StatelessWidget {
  const AssignMatesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AssignMates',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const NotificationHandler(child: SplashScreen()),
    );
  }
}
