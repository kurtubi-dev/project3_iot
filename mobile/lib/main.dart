import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PUPR Subang - Smart IoT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0C2444),
          primary: const Color(0xFF0C2444),
          secondary: const Color(0xFFF59E0B),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
