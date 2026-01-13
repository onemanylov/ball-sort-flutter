import 'package:flutter/material.dart';
import '../models/tube.dart';
import 'ball_widget.dart';

class TubeWidget extends StatelessWidget {
  final Tube tube;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;
  final double ballSize;

  final int hiddenTopCount;

  const TubeWidget({
    Key? key,
    required this.tube,
    required this.isSelected,
    this.hiddenTopCount = 0,
    required this.onTap,
    this.width = 60,
    this.ballSize = 50,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Height calculation
    // Increase padding to fit the round bottom better
    // Reduced padding to +12 (was +32, originally +16) to reduce top whitespace
    final tubeHeight = (tube.capacity * ballSize) + 12.0;

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
              clipBehavior: Clip.none, // Allow hover to go out
              children: [
                // The Tube Glass (Custom Shape)
                // We align it to bottom so it grows up
                Positioned(
                  bottom: 0,
                  child: CustomPaint(
                    size: Size(width, tubeHeight),
                    painter: _TubePainter(
                      glassColor: Colors.white.withValues(alpha: 0.05),
                      borderColor: Colors.white.withValues(alpha: 0.3),
                      borderWidth: 2,
                      showShadow: false,
                    ),
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
                   
                   // Stacking Logic
                   // Visual Ball Size is (ballSize - 10).
                   // User wants "in between" gap (~6px).
                   // Stride = VisualSize + Gap = (ballSize - 10) + 6 = ballSize - 4.
                   double stride = ballSize - 4;
                   
                   // Lift bottom base to account for the round bottom of the tube
                   // Adjusted to 8.0 as requested
                   double bottomPos = 8.0 + (index * stride);
                   
                   if (isHovering) {
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
  bool shouldRepaint(covariant _TubePainter oldDelegate) {
     return oldDelegate.borderColor != borderColor || 
            oldDelegate.borderWidth != borderWidth ||
            oldDelegate.glassColor != glassColor ||
            oldDelegate.showShadow != showShadow ||
            oldDelegate.shadowColor != shadowColor;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = glassColor
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth; // No StrokeCap needed for loop
      
    if (showShadow) {
      final shadowPaint = Paint()
        ..color = shadowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth + 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      
      final shadowPath = _getTubePath(size);
      canvas.drawPath(shadowPath, shadowPaint);
    }
    
    final path = _getTubePath(size);
    
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
    
    // Shine
    final shinePath = Path();
    shinePath.moveTo(size.width * 0.25, 12);
    shinePath.lineTo(size.width * 0.25, size.height - 25);
    final shinePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withValues(alpha: 0.15), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round; // Round shine ends
      
    canvas.drawPath(shinePath, shinePaint);
  }
  
  Path _getTubePath(Size size) {
    final path = Path();
    // Dimensions
    final double lipTotalWidth = size.width; 
    final double lipHeight = 8.0;
    final double lipOverhang = 3.0; // Reduced to widen body space
    final double bodyWidth = size.width - (lipOverhang * 2);
    final double cornerRadiusLow = bodyWidth / 2; // Full round bottom
    final double neckRadius = 3.0; // Smooth transition from lip to body
    
    // Start Top Left of Lip
    // We want rounded corners on the lip itself too? "No hard corners"
    final double lipCornerRadius = 3.0;

    // Start at Top-Center to be symmetrical (easier debugging?) No, path is fine.
    // 1. Top Left Lip Corner
    path.moveTo(lipCornerRadius, 0);
    path.lineTo(size.width - lipCornerRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, lipCornerRadius);
    
    // 2. Right Side Lip Down
    path.lineTo(size.width, lipHeight - lipCornerRadius);
    path.quadraticBezierTo(size.width, lipHeight, size.width - lipCornerRadius, lipHeight);
    
    // 3. Curve IN to Body (Neck)
    // We are at (W - corner, H_lip). Target is (W - overhang, H_lip + neck).
    // Control Point approx (W-overhang, H_lip).
    // Actually, simple line in? User wants smooth.
    // Let's go to Body Start.
    path.quadraticBezierTo(
      size.width - lipOverhang, lipHeight, // Control
      size.width - lipOverhang, lipHeight + neckRadius // End
    );
    
    // 4. Down Right Body
    path.lineTo(size.width - lipOverhang, size.height - cornerRadiusLow);
    
    // 5. Bottom Arc
    path.arcToPoint(
      Offset(lipOverhang, size.height - cornerRadiusLow),
      radius: Radius.circular(cornerRadiusLow),
      clockwise: true,
    );
    
    // 6. Up Left Body
    path.lineTo(lipOverhang, lipHeight + neckRadius);
    
    // 7. Curve OUT to Lip
    path.quadraticBezierTo(
      lipOverhang, lipHeight,
      lipCornerRadius, lipHeight
    );
    
    // 8. Left Side Lip Up
    path.lineTo(0, lipHeight - lipCornerRadius); // Wait, x=0? Yes, we started at x=radius.
    // Wait, step 7 ended at x=radius.
    // We need to go up to x=0.
    // My Step 7 ended at (radius, lipHeight). 
    // Wait, the lip starts at 0.
    // Actually, let's trace cleaner.
    
    // Re-do Left Lip Side Up
    path.lineTo(0, lipCornerRadius);
    path.quadraticBezierTo(0, 0, lipCornerRadius, 0);
    
    path.close();
    return path;
  }
}
