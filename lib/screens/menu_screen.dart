import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';


class MenuScreen extends StatelessWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1E2C), Color(0xFF4A4A6A)],
          ),
        ),
        child: Center(
          child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               const Icon(Icons.blur_on, size: 100, color: Colors.cyanAccent),
               const SizedBox(height: 20),
               const Text("BALL SORT", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
               const Text("PUZZLE", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: Colors.white70, letterSpacing: 8)),
               const SizedBox(height: 60),
               
               _buildMenuButton(context, "PLAY", Colors.cyanAccent, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
               }),
               const SizedBox(height: 20),
               _buildMenuButton(context, "LEVELS", Colors.purpleAccent, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LevelSelectScreen()));
               }),
               const SizedBox(height: 20),
               _buildMenuButton(context, "SETTINGS", Colors.orangeAccent, () async {
                  // Reset Game State
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('level', 1);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Game progress has been reset to Level 1!", style: TextStyle(color: Colors.white))),
                    );
                  }
               }),
             ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String text, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 220,
      height: 64,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
           backgroundColor: Colors.white.withOpacity(0.05),
           foregroundColor: color,
           side: BorderSide(color: color.withOpacity(0.5), width: 2),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
           elevation: 10,
           shadowColor: color.withOpacity(0.2),
        ),
        onPressed: onTap,
        child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ),
    );
  }
}
