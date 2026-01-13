import 'package:flutter/material.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Select Level", style: TextStyle(fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.transparent, 
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E1E2C), Color(0xFF2D2D44)],
          ),
        ),
        child: SafeArea( // Use SafeArea to avoid overlap with status bar/app bar
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
               crossAxisCount: 4,
               crossAxisSpacing: 16,
               mainAxisSpacing: 16,
               childAspectRatio: 1.0,
            ),
            itemCount: 50,
            itemBuilder: (context, index) {
               final level = index + 1;
               return Material(
                 color: Colors.transparent,
                 child: InkWell(
                   borderRadius: BorderRadius.circular(16),
                   onTap: () {
                     Navigator.push(context, MaterialPageRoute(
                       builder: (_) => GameScreen(initialLevel: level)
                     ));
                   },
                   child: Container(
                     decoration: BoxDecoration(
                       color: Colors.white.withOpacity(0.05),
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1.5),
                       boxShadow: [
                         BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(2,2))
                       ],
                     ),
                     child: Center(
                       child: Text(
                         "$level", 
                         style: const TextStyle(
                           color: Colors.white, 
                           fontSize: 20, 
                           fontWeight: FontWeight.bold,
                           fontFamily: 'Roboto', // Default
                         )
                       ),
                     ),
                   ),
                 ),
               );
            },
          ),
        ),
      ),
    );
  }
}
