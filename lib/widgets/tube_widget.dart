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
                // The Tube Glass
                Container(
                  height: tubeHeight,
                  width: width,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    border: Border.all(
                      color: isHintTarget 
                          ? Colors.purpleAccent 
                          : (isValidTarget ? Colors.greenAccent.withValues(alpha: 0.8) : (isSelected ? Colors.amber.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.3))),
                      width: (isValidTarget || isSelected || isHintTarget) ? 3 : 2,
                    ),
                    boxShadow: [
                      if (isValidTarget) BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.3), blurRadius: 10),
                      if (isHintTarget) BoxShadow(color: Colors.purpleAccent.withValues(alpha: 0.6), blurRadius: 15, spreadRadius: 2),
                    ],
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
                     duration: const Duration(milliseconds: 300),
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
