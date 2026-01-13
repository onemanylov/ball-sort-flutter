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
    if (color == Colors.red) return 'assets/RoundCandy_Strawberry.png';
    if (color == Colors.blue) return 'assets/RoundCandy_Blueberry.png';
    if (color == Colors.green) return 'assets/RoundCandy_Gauva.png';
    if (color == Colors.yellow) return 'assets/RoundCandy_Mango.png';
    if (color == Colors.purple) return 'assets/RoundCandy_JavaPlum.png';
    
    return 'assets/RoundCandy_Strawberry.png'; // Default fallback
  }
}
