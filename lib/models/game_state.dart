import 'package:equatable/equatable.dart';
import 'tube.dart';

class GameState extends Equatable {
  final List<Tube> tubes;
  final int moves;
  final int level;
  final bool isWin; // Helper to store cached win state if needed, or computed

  const GameState({
    required this.tubes,
    this.moves = 0,
    this.level = 1,
    this.isWin = false,
  });

  bool get checkWinCondition {
     // A game is won if all tubes are either empty or full of the same color.
     return tubes.every((tube) => tube.isEmpty || tube.isSolved);
  }

  GameState copyWith({
    List<Tube>? tubes,
    int? moves,
    int? level,
    bool? isWin,
  }) {
    return GameState(
      tubes: tubes ?? this.tubes,
      moves: moves ?? this.moves,
      level: level ?? this.level,
      isWin: isWin ?? this.isWin,
    );
  }

  @override
  List<Object> get props => [tubes, moves, level, isWin];
}
