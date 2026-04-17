import 'package:flutter/material.dart';
import 'package:habit_tracker/auth/auth_screen.dart';
import 'package:habit_tracker/config/app_config.dart';

void main() {
  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro', // optional
      ),
      home: const AuthScreen(),
    );
  }
}
