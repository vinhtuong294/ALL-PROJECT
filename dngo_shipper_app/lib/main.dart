import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'feature/auth/presentation/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DNGO_ShipperApp());
}

class DNGO_ShipperApp extends StatelessWidget {
  const DNGO_ShipperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DNGO Shipper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        primaryColor: const Color(0xFF2F8000), // Primary Green
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2F8000), // Green app bar
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F8000),
          primary: const Color(0xFF2F8000),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

