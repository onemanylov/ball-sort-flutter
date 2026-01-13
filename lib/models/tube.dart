import 'package:equatable/equatable.dart';
import 'ball.dart';

class Tube extends Equatable {
  final int id;
  final List<Ball> balls;
  final int capacity;

  const Tube({
    required this.id,
    this.balls = const [],
    this.capacity = 4,
  });

  bool get isFull => balls.length >= capacity;
  bool get isEmpty => balls.isEmpty;
  bool get isNotEmpty => balls.isNotEmpty;
  
  bool get isSolved {
    if (isEmpty) return true; // Empty tube is considered "solved" in the sense it doesn't block winning, but usually "solved" means full of same color? 
    // Wait, win condition is: all tubes are either empty or full with same color.
    // So isSolved for a single tube:
    if (balls.length != capacity) return false;
    final firstColor = balls.first.color;
    return balls.every((b) => b.color == firstColor);
  }

  // Returns true if the tube is empty or all balls are the same color (but maybe not full)
  bool get isUniform {
    if (isEmpty) return true;
    final firstColor = balls.first.color;
    return balls.every((b) => b.color == firstColor);
  }

  Ball? get topBall => balls.isEmpty ? null : balls.last;

  Tube copyWith({
    int? id,
    List<Ball>? balls,
    int? capacity,
  }) {
    return Tube(
      id: id ?? this.id,
      balls: balls ?? this.balls,
      capacity: capacity ?? this.capacity,
    );
  }

  @override
  List<Object> get props => [id, balls, capacity];
}
