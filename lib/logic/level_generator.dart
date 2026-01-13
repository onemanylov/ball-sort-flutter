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

  /// Generates a valid, solvable level using Reverse Shuffle
  static Future<GameState> generateLevel({
    required int numberOfColors,
    required int numberOfTubes,
    int tubeCapacity = 4,
    int levelNumber = 1,
  }) async {
    // Start with a solved state
    List<Tube> tubes = _createSolvedState(numberOfColors, numberOfTubes, tubeCapacity);
    
    // Scramble by performing valid reverse moves
    // Logic: A move is valid REVERSE if the ball can be put back legally.
    // Legally put back means: Dest (Original Src) is Empty OR Top matches.
    // So in Scramble: We can only TAKE from Src if:
    // 1. Src becomes Empty
    // 2. OR Src's new top (previously 2nd) matches the ball we took.
    
    // Number of scramble steps
    int iterations = 50 + (levelNumber * 2); 
    if (iterations > 200) iterations = 200;
    
    final random = Random();
    int lastSrcId = -1; // Avoid immediate ping-pong
    
    for (int i = 0; i < iterations; i++) {
        // Find all scrambled-valid moves
        List<Map<String, int>> validMoves = [];
        
        for (int srcIndex = 0; srcIndex < tubes.length; srcIndex++) {
           Tube src = tubes[srcIndex];
           if (src.isEmpty) continue;
           
           // Check Scramble Constraint
           bool canTake = false;
           if (src.balls.length == 1) {
             canTake = true;
           } else {
             // Check if 2nd ball matches top
             // ball[last] is top. ball[last-1] is under.
             if (src.balls[src.balls.length - 1].color == src.balls[src.balls.length - 2].color) {
               canTake = true;
             }
           }
           
           if (!canTake) continue;
           
           // Find Dests
           for (int dstIndex = 0; dstIndex < tubes.length; dstIndex++) {
              if (srcIndex == dstIndex) continue;
              if (srcIndex == lastSrcId && dstIndex == srcIndex) continue; // weak check
              
              if (tubes[dstIndex].balls.length < tubeCapacity) {
                 validMoves.add({'from': srcIndex, 'to': dstIndex});
              }
           }
        }
        
        if (validMoves.isEmpty) break; // Dead end (rare)
        
        final move = validMoves[random.nextInt(validMoves.length)];
        
        // Execute Move
        final sId = move['from']!;
        final dId = move['to']!;
        
        // Move top ball
        final ball = tubes[sId].balls.removeLast();
        tubes[dId].balls.add(ball);
        
        // Update Tube objects state ? We are modifying the lists inside Tube references but 'balls' is final list?
        // Tube.balls is final List<Ball>. We can mutate it.
        // But we should ideally return new State. 
        // Here we mutate for performance then package in GameState.
        
        lastSrcId = dId; // The new source was the destination? 
        // To avoid picking the ball we just moved and moving it back immediately.
        // If we moved S->D. Ball is now at D. 
        // Next turn, can we take from D? 
        // Only if D has matching under or was empty. 
        // If we moved Red to Empty D. D has [Red]. CanTake = True.
        // We could move D->S immediately.
        // We might want to prevent D->S.
        // Ideally we prevent (from: dId, to: sId).
    }
    
    return GameState(tubes: tubes, level: levelNumber);
  }

  static List<Tube> _createSolvedState(int colorsCount, int tubesCount, int capacity) {
     List<Color> colorsUsed = _availableColors.sublist(0, colorsCount);
     List<Tube> tubes = [];
     
     for (int i = 0; i < tubesCount; i++) {
        List<Ball> balls = [];
        if (i < colorsCount) {
          for(int k=0; k<capacity; k++) {
            balls.add(Ball.newBall(colorsUsed[i]));
          }
        }
        tubes.add(Tube(id: i, balls: balls, capacity: capacity));
     }
     return tubes;
  }
}
