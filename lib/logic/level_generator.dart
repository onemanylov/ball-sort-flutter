import 'dart:math';
import 'package:flutter/material.dart';
import '../models/ball.dart';
import '../models/tube.dart';
import '../models/game_state.dart';
import 'solver.dart';

class LevelGenerator {
  static final List<Color> _availableColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
  ];

  /// Generates a valid, solvable level by creating random FULL tubes and verifying with Solver.
  static Future<GameState> generateLevel({
    required int numberOfColors,
    required int numberOfTubes,
    int tubeCapacity = 4,
    int levelNumber = 1,
  }) async {
    int attempts = 0;
    // Try up to 500 times to find a solvable random shuffle.
    // Random shuffle ensures tubes are either FULL or EMPTY (no partials).
    while (attempts < 500) {
      attempts++;
      final state = _createRandomFullTubesState(numberOfColors, numberOfTubes, tubeCapacity, levelNumber);
      
      // Fast check: If already solved (lucky shuffle), skip
      if (state.checkWinCondition) continue; 
      
      // Verify solvability
      try {
        final solution = Solver.solve(state);
        if (solution != null && solution.isNotEmpty) {
          return state;
        }
      } catch (e) {
        // In case solver crashes, ignore
        continue;
      }
    }
    
    // In the extremely rare case we fail, return a known simple state
    // (A sorted state with 1 simple swap is guaranteed solvable and full-ish)
    // But to ensure "FULL TUBES" strictly, we just return a solved state with a swap that maintains fullness?
    // Swapping top balls of 2 full tubes maintains fullness.
    return _generateGuaranteedFallback(numberOfColors, numberOfTubes, tubeCapacity, levelNumber);
  }
  
  static GameState _generateGuaranteedFallback(int c, int t, int cap, int lvl) {
      // 1. Create Solved State
      List<Color> colorsUsed = _availableColors.sublist(0, c);
      List<Tube> tubes = [];
      
      // Create N full tubes
      for (int i = 0; i < t; i++) {
        List<Ball> balls = [];
        if (i < c) {
           for(int k=0; k<cap; k++) {
             balls.add(Ball.newBall(colorsUsed[i]));
           }
        }
        tubes.add(Tube(id: i, balls: balls, capacity: cap));
      }
      
      // 2. Perform a few valid swaps of Top Balls to mix it slightly
      // Requires at least 1 empty tube (t > c)
      if (t > c) {
         // Swap Top of Tube 0 and Tube 1
         if (c >= 2) {
            // Move T0->Empty
            tubes[c].balls.add(tubes[0].balls.removeLast());
            // Move T1->T0
             tubes[0].balls.add(tubes[1].balls.removeLast());
            // Move Empty->T1
             tubes[1].balls.add(tubes[c].balls.removeLast());
         }
      }
      
      return GameState(tubes: tubes, level: lvl);
  }

  static GameState _createRandomFullTubesState(int colorsCount, int tubesCount, int capacity, int levelNum) {
     if (tubesCount < colorsCount + 1) {
       tubesCount = colorsCount + 1; // Ensure 1 empty tube min
     }
     
     List<Color> colorsUsed = _availableColors.sublist(0, colorsCount);
     List<Ball> allBalls = [];
     
     // Create pairs of balls
     for (var color in colorsUsed) {
       for (int i = 0; i < capacity; i++) {
         allBalls.add(Ball.newBall(color));
       }
     }
     
     allBalls.shuffle();
     
     List<Tube> tubes = [];
     
     // Fill tubes 0 to colorsCount-1 with balls. 
     // Tubes colorsCount to end are empty.
     
     int ballIndex = 0;
     for (int i = 0; i < tubesCount; i++) {
       List<Ball> tubeBalls = [];
       
       if (i < colorsCount) {
         // This tube should be full
         for (int k = 0; k < capacity; k++) {
           if (ballIndex < allBalls.length) {
              tubeBalls.add(allBalls[ballIndex++]);
           }
         }
       }
       // Else tube is empty
       
       tubes.add(Tube(id: i, balls: tubeBalls, capacity: capacity));
     }
     
     return GameState(tubes: tubes, level: levelNum);
  }
}
