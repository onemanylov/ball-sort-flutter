import 'package:flutter/material.dart';

class BallWidget extends StatelessWidget {
  final Color color;
  final double size;

  const BallWidget({Key? key, required this.color, required this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final assetPath = _getAssetPath(color);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Shadow Layer (Simple offset darker image)
          Positioned(
            top: 3,
            left: 2,
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                assetPath,
                width: size,
                height: size,
                color: Colors.black, // Tint shadow black
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Main Candy
          Image.asset(
            assetPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  String _getAssetPath(Color color) {
    if (color == Colors.red) return 'assets/1.png';
    if (color == Colors.blue) return 'assets/2.png';
    if (color == Colors.green) return 'assets/3.png';
    if (color == Colors.yellow) return 'assets/4.png';
    if (color == Colors.purple) return 'assets/5.png';
    if (color == Colors.orange) return 'assets/6.png';
    if (color == Colors.pink) return 'assets/7.png';
    if (color == Colors.teal) return 'assets/8.png';
    // Fallbacks or extras
    if (color == Colors.cyan) return 'assets/9.png';
    if (color == Colors.lime) return 'assets/10.png';
    
    return 'assets/1.png'; // Default
  }
}
