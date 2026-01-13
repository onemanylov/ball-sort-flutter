import 'package:flutter/material.dart';

class BallWidget extends StatelessWidget {
  final Color color;
  final double size;

  const BallWidget({Key? key, required this.color, required this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.9),
            color,
            color.withOpacity(0.8), // shadow side
          ],
          center: Alignment.topLeft,
          radius: 1.2,
        ),
      ),
      child: Stack(
        children: [
          // Shine reflection
          Positioned(
            top: size * 0.15,
            left: size * 0.15,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.white)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
