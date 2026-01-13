import '../models/game_state.dart';

class HistoryManager {
  final List<GameState> _history = [];

  void push(GameState state) {
    _history.add(state);
  }

  GameState? pop() {
    if (_history.isEmpty) return null;
    return _history.removeLast();
  }
  
  bool get canUndo => _history.isNotEmpty;
  
  void clear() {
    _history.clear();
  }
  
  // Optional: current state tracking if we want HistoryManager to own the state, 
  // but usually Provider owns the "current" state and HistoryManager owns the "past".
}
