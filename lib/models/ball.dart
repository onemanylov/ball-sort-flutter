import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Ball extends Equatable {
  final String id;
  final Color color;

  const Ball({
    required this.id,
    required this.color,
  });

  factory Ball.newBall(Color color) {
    return Ball(id: const Uuid().v4(), color: color);
  }

  Ball copyWith({String? id, Color? color}) {
    return Ball(
      id: id ?? this.id,
      color: color ?? this.color,
    );
  }

  @override
  List<Object> get props => [id, color];
}
