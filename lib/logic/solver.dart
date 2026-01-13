import '../models/game_state.dart';
import '../models/tube.dart';
import 'game_logic.dart';

class SolverMove {
  final int from;
  final int to;
  const SolverMove(this.from, this.to);
  
  @override
  String toString() => 'Move($from -> $to)';
}

class Solver {
  
  static String stateToKey(GameState state) {
    // Preserve Tube ordering to keep move indices valid.
    // Flatten ball colors.
    StringBuffer sb = StringBuffer();
    for (final tube in state.tubes) {
      if (tube.isEmpty) {
        sb.write('E|');
      } else {
        for (final ball in tube.balls) {
          // Use color value
          sb.write('${ball.color.value}-');
        }
        sb.write('|');
      }
    }
    return sb.toString();
  }

  /// Returns a list of moves to solve the state, or null if unsolvable within limits
  static List<SolverMove>? solve(GameState initialState) {
    // If already solved
    if (initialState.checkWinCondition) return [];

    final Set<String> visited = {};
    // Stack for DFS: stores State and the path taken
    final List<MapEntry<GameState, List<SolverMove>>> stack = [];
    
    stack.add(MapEntry(initialState, []));
    visited.add(stateToKey(initialState));
    
    int iterations = 0;
    // Limit to prevent FREEZE
    const int MAX_ITERATIONS = 50000;

    while (stack.isNotEmpty) {
      iterations++;
       if (iterations > MAX_ITERATIONS) break;

       final current = stack.removeLast();
       final state = current.key;
       final moves = current.value;
       
       // Optimization: heuristic?
       // DFS doesn't guarantee shortest path. BFS does.
       // Plan said "DFS backtracking".
       
       // Attempt all possible moves
       // To optimize, maybe prefer moves that complete a tube?
       // For now, pure exhaustive.
       
       for (int i = 0; i < state.tubes.length; i++) {
         // Optimization: If tube is already solved (full and uniform), don't move FROM it?
         // Exception: Sometimes you might need to break a solved tube to solve others (rare in this game type? usually not).
         // Actually in Ball Sort, once a tube is 'Completed' (Full same color), it's locked usually.
         // Let's check logic: isValidMove allows moving from uniform tube?
         // If a tube is Full and Uniform, isValidMove allows moving from it if dest is empty or match.
         // But usually we shouldn't touch completed tubes.
         if (state.tubes[i].isSolved) continue;

         for (int j = 0; j < state.tubes.length; j++) {
           if (i == j) continue;
           
           if (GameLogic.isValidMove(state, i, j)) {
             
             // Optimization: Don't move a single color ball from A to Empty B if A only has that color?
             // E.g. A=[R,R]. B=Empty. Move R->B => A=[R], B=[R]. Pointless?
             // IF Tube A is "Uniform" (all same color), moving to Empty is useless unless A is not Full and we need to merge?
             // If A is [R,R], B is Empty. Move -> A=[R], B=[R]. Next we might move A->B => B=[R,R].
             // To prevent loops, visited set handles it. But pruning helps speed.
             // Pruning: Do not move from Uniform Tube to Empty Tube. 
             // Logic: Merging stacks is good. Splitting a uniform stack into an empty tube is usually bad/reversible.
             if (state.tubes[i].isUniform && state.tubes[j].isEmpty) continue;

             final nextState = GameLogic.makeMove(state, i, j);
             final key = stateToKey(nextState);
             
             if (!visited.contains(key)) {
               if (nextState.checkWinCondition) {
                 return [...moves, SolverMove(i, j)];
               }
               
               visited.add(key);
               stack.add(MapEntry(nextState, [...moves, SolverMove(i, j)]));
             }
           }
         }
       }
    }
    return null;
  }
}
