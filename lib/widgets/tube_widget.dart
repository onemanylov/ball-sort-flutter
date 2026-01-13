import 'package:flutter/material.dart';
import '../models/tube.dart';
import 'ball_widget.dart';

class TubeWidget extends StatelessWidget {
  final Tube tube;
  final bool isSelected;
  final bool isValidTarget;
  final VoidCallback onTap;
  final double width;
  final double ballSize;

  final bool isHintTarget;
  final int hiddenTopCount;

  const TubeWidget({
    Key? key,
    required this.tube,
    required this.isSelected,
    this.isValidTarget = false,
    this.isHintTarget = false,
    this.hiddenTopCount = 0,
    required this.onTap,
    this.width = 60,
    this.ballSize = 50,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Height calculation
    final tubeHeight = (tube.capacity * ballSize) + 16.0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Extra Space for the hovering ball
          SizedBox(
            width: width,
            height: tubeHeight + 60, // Sufficient space for hover
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                // The Tube Glass (Custom Shape)
                CustomPaint(
                  size: Size(width, tubeHeight),
                  painter: _TubePainter(
                    glassColor: Colors.white.withValues(alpha: 0.05),
                    borderColor: isHintTarget 
                        ? Colors.purpleAccent 
                        : (isValidTarget ? Colors.greenAccent.withValues(alpha: 0.8) : (isSelected ? Colors.amber.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.3))),
                    borderWidth: (isValidTarget || isSelected || isHintTarget) ? 3 : 2,
                    showShadow: isValidTarget || isHintTarget,
                    shadowColor: isHintTarget ? Colors.purpleAccent.withValues(alpha: 0.6) : Colors.greenAccent.withValues(alpha: 0.3),
                  ),
                ),
                
                // Balls
                ...List.generate(tube.balls.length, (index) {
                   // If hidden, skip
                   if (index >= tube.balls.length - hiddenTopCount) {
                     return const SizedBox.shrink();
                   }

                   // Selection Logic: ONLY the top ball hovers
                   bool isTopBall = index == tube.balls.length - 1;
                   bool isHovering = isSelected && isTopBall;
                   
                   double bottomPos = 8.0 + (index * ballSize);
                   if (isHovering) {
                     // Fly UP above the flask
                     // Tube height is tubeHeight. We want to be above it.
                     // Current bottomPos is relative to bottom of stack.
                     // easy way: set bottomPos to tubeHeight + padding
                     bottomPos = tubeHeight + 10.0; 
                   }

                   return AnimatedPositioned(
                     duration: const Duration(milliseconds: 200),
                     curve: Curves.easeOutBack,
                     bottom: bottomPos,
                     left: (width - (ballSize - 10)) / 2, // Center horizontally
                     child: BallWidget(
                       color: tube.balls[index].color,
                       size: ballSize - 10, 
                     ),
                   );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TubePainter extends CustomPainter {
  final Color glassColor;
  final Color borderColor;
  final double borderWidth;
  final bool showShadow;
  final Color shadowColor;

  _TubePainter({
    required this.glassColor,
    required this.borderColor,
    required this.borderWidth,
    this.showShadow = false,
    this.shadowColor = Colors.transparent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = glassColor
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
      
    if (showShadow) {
      final shadowPaint = Paint()
        ..color = shadowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth + 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      
      // Draw shadow path first
      final shadowPath = _getTubePath(size);
      canvas.drawPath(shadowPath, shadowPaint);
    }
    
    final path = _getTubePath(size);
    
    // Draw Glass Fill
    canvas.drawPath(path, paint);
    
    // Draw Border
    canvas.drawPath(path, borderPaint);
    
    // Draw subtle reflection/shine
    final shinePath = Path();
    shinePath.moveTo(size.width * 0.2, 10);
    shinePath.lineTo(size.width * 0.2, size.height - 20);
    
    final shinePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withValues(alpha: 0.1), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
    canvas.drawPath(shinePath, shinePaint);
  }
  
  Path _getTubePath(Size size) {
    final path = Path();
    final double lipHeight = 8.0;
    final double lipOverhang = 4.0;
    final double cornerRadius = size.width / 2; // Semi-circle bottom
    
    // Start Top Left Lip
    path.moveTo(0, 0); // Top Left Outer
    path.lineTo(size.width, 0); // Top Right Outer
    path.lineTo(size.width, lipHeight); // Lip visual height (we don't cut back in, we just draw the boxish lip?)
    
    // Actually, user wants "Flask with Lip". 
    // Usually: Wide top, necks in slightly? Or just straight tube with rim?
    // "Tube" puzzle usually straight sides.
    // Lip means:
    //  ____
    // |    |  <-- Rim
    // |    |
    // |    |
    // |____|
    
    // Let's do:
    // Move to Lip Top Left (-overhang) ? No, we are bounded by size.width.
    // Let's assume size.width includes the lip.
    // Main body is narrower.
    
    double bodyWidth = size.width - (lipOverhang * 2);
    // Left Start of Lip
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, lipHeight);
    // Neck in
    path.lineTo(size.width - lipOverhang, lipHeight); 
    // Go down
    path.lineTo(size.width - lipOverhang, size.height - cornerRadius);
    // Arc Close Bottom
    path.arcToPoint(
      Offset(lipOverhang, size.height - cornerRadius),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );
    // Go Up Left Side
    path.lineTo(lipOverhang, lipHeight);
    // Flare out
    path.lineTo(0, lipHeight);
    path.close();
    
    return path;
  }

  @override
  bool shouldRepaint(covariant _TubePainter oldDelegate) {
     return oldDelegate.borderColor != borderColor || oldDelegate.borderWidth != borderWidth;
  }
}
