import '../models/game_state.dart';
import '../models/tube.dart';
import '../models/ball.dart';

class GameLogic {
  
  /// Checks if a move is valid
  static bool isValidMove(GameState state, int fromTubeIndex, int toTubeIndex) {
    if (fromTubeIndex < 0 || fromTubeIndex >= state.tubes.length) return false;
    if (toTubeIndex < 0 || toTubeIndex >= state.tubes.length) return false;
    if (fromTubeIndex == toTubeIndex) return false;

    final fromTube = state.tubes[fromTubeIndex];
    final toTube = state.tubes[toTubeIndex];

    if (fromTube.isEmpty) return false;
    if (toTube.isFull) return false;

    // If destination is empty, we can always move (unless we enforce not moving partially full same-color stacks to empty? No, usually valid)
    if (toTube.isEmpty) return true;

    // Check color match
    final fromBall = fromTube.topBall!;
    final toBall = toTube.topBall!;
    return fromBall.color == toBall.color;
  }

  /// Calculates how many balls will move from fromTube to toTube
  static int countBallsToMove(Tube fromTube, Tube toTube) {
     if (fromTube.isEmpty) return 0;
     
     final color = fromTube.topBall!.color;
     int countFrom = 0;
     // Count consecutive identical colors from top
     for (int i = fromTube.balls.length - 1; i >= 0; i--) {
       if (fromTube.balls[i].color == color) {
         countFrom++;
       } else {
         break;
       }
     }
     
     int spaceInTo = toTube.capacity - toTube.balls.length;
     // If toTube is not empty and colors valid (checked elsewhere or here)
     if (toTube.isNotEmpty && toTube.topBall!.color != color) return 0; 
     // Note: if toTube is empty, color check passes technically for any color

     return countFrom < spaceInTo ? countFrom : spaceInTo;
  }

  /// Executes the move and returns new GameState
  static GameState makeMove(GameState state, int fromTubeIndex, int toTubeIndex) {
    // Basic validation again, though usually called after isValidMove
    if (!isValidMove(state, fromTubeIndex, toTubeIndex)) return state;

    final fromTube = state.tubes[fromTubeIndex];
    final toTube = state.tubes[toTubeIndex];

    int count = countBallsToMove(fromTube, toTube);
    if (count == 0) return state;

    // Identify balls to move
    // We take the top `count` balls. Preserving order means taking the sublist.
    List<Ball> ballsToMove = fromTube.balls.sublist(fromTube.balls.length - count);
    
    // Remove from source
    List<Ball> newFromBalls = fromTube.balls.sublist(0, fromTube.balls.length - count);
    
    // Add to destination
    List<Ball> newToBalls = List.from(toTube.balls)..addAll(ballsToMove);

    final newFromTube = fromTube.copyWith(balls: newFromBalls);
    final newToTube = toTube.copyWith(balls: newToBalls);

    List<Tube> newTubes = List.from(state.tubes);
    newTubes[fromTubeIndex] = newFromTube;
    newTubes[toTubeIndex] = newToTube;

    // Check win condition
    // We can create a temp state to check
    final tempState = state.copyWith(tubes: newTubes);
    bool isWin = tempState.checkWinCondition;

    return state.copyWith(
      tubes: newTubes,
      moves: state.moves + 1,
      isWin: isWin,
    );
  }
}
