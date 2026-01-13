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
    // Determine how many balls to lift if selected
    int liftCount = 0;
    if (isSelected && tube.balls.isNotEmpty) {
      final topColor = tube.balls.last.color;
      for (int i = tube.balls.length - 1; i >= 0; i--) {
        if (tube.balls[i].color == topColor) {
           liftCount++;
        } else {
          break;
        }
      }
    }

    // Height calculation
    // Tube height needs to fit capacity
    final tubeHeight = (tube.capacity * ballSize) + 16.0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // If lifted, we need space above the tube so they don't get clipped or overlap weirdly if in a tight Stack.
          // But here we'll just let them translate up. 
          // However, using Stack with Clip.none is best.
          
          SizedBox(
            width: width,
            height: tubeHeight + 50, // Extra space for lift
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                // The Tube Glass
                Container(
                  height: tubeHeight,
                  width: width,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    border: Border.all(
                      color: isHintTarget 
                          ? Colors.purpleAccent 
                          : (isValidTarget ? Colors.greenAccent.withOpacity(0.8) : (isSelected ? Colors.amber.withOpacity(0.8) : Colors.white.withOpacity(0.3))),
                      width: (isValidTarget || isSelected || isHintTarget) ? 3 : 2,
                    ),
                    boxShadow: [
                      if (isValidTarget) BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 10),
                      if (isHintTarget) BoxShadow(color: Colors.purpleAccent.withOpacity(0.6), blurRadius: 15, spreadRadius: 2),
                    ],
                  ),
                ),
                
                // Balls
                ...List.generate(tube.balls.length, (index) {
                   // If hidden, skip
                   if (index >= tube.balls.length - hiddenTopCount) {
                     return const SizedBox.shrink();
                   }

                   bool isLifted = false;
                   if (isSelected) {
                     // Check if this ball is part of the top group
                     int distFromTop = (tube.balls.length - 1) - index;
                     if (distFromTop < liftCount) {
                       isLifted = true;
                     }
                   }
                   
                   double bottomPos = 8.0 + (index * ballSize);
                   if (isLifted) {
                     bottomPos += 30.0; 
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
