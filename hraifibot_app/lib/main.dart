import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HraifiBotApp());
}

class HraifiBotApp extends StatelessWidget {
  const HraifiBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Le7rayfi Bot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D16),
        primaryColor: const Color(0xFFD97706),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD97706),
          secondary: Color(0xFF06B6D4),
          surface: Color(0xFF0F172A),
          background: Color(0xFF090D16),
        ),
        fontFamily: GoogleFonts.tajawal().fontFamily,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
