import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/menu_screen.dart';

void main() {
  runApp(const BallSortApp());
}

class BallSortApp extends StatelessWidget {
  const BallSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ball Sort Puzzle',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF1E1E2C),
        useMaterial3: true,
        textTheme: GoogleFonts.snigletTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      ),
      home: const MenuScreen(),
    );
  }
}
