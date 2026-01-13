import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../logic/game_logic.dart';
import '../logic/level_generator.dart';
import '../logic/solver.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/history_manager.dart';

class GameProvider extends ChangeNotifier {
  GameState _state;
  final HistoryManager _history = HistoryManager();
  
  
  bool _isLoading = false;
  int? _selectedTubeIndex;
  int _currentLevel = 1;

  GameProvider() : _state = const GameState(tubes: []);

  GameState get state => _state;
  int? get selectedTubeIndex => _selectedTubeIndex;
  bool get isLoading => _isLoading;
  int? get hintTargetIndex => _hintTargetIndex;
  
  int? _hintTargetIndex;
  
  // Animation state
  int? _animatingFromIndex;
  int _animatingCount = 0;
  
  int? get animatingFromIndex => _animatingFromIndex;
  int get animatingCount => _animatingCount;


  Future<void> init(int? startingLevel) async {
    _isLoading = true; 
    notifyListeners();
    
    if (startingLevel != null) {
      _currentLevel = startingLevel;
    } else {
       final prefs = await SharedPreferences.getInstance();
       _currentLevel = prefs.getInt('level') ?? 1;
    }
    await startNewGame();
  }

  Future<void> startNewGame({int? colors, int? tubes}) async {
    _isLoading = true;
    notifyListeners();
    
    // Difficulty progression
    int c;
    int t;
    
    if (colors != null) {
      c = colors;
      t = tubes ?? (c + 2);
    } else {
      if (_currentLevel <= 2) {
        c = 2;
        t = 3; // 2 filled + 1 empty
      } else if (_currentLevel <= 4) {
        c = 3;
        t = 4; // 3 filled + 1 empty
      } else {
        // Level 5+:
        // Level 5-9: 4 colors
        // Level 10+: 5 colors (Max)
        c = 3 + ((_currentLevel - 4) / 5).ceil();
        if (c > 5) c = 5;
        
        // Standard Difficulty: 2 empty tubes
        t = c + 2;
      }
    }
    
    _state = await LevelGenerator.generateLevel(
      numberOfColors: c, 
      numberOfTubes: t,
      levelNumber: _currentLevel
    );
    
    _history.clear();
    _selectedTubeIndex = null;
    _hintTargetIndex = null;
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> nextLevel() async {
    _currentLevel++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('level', _currentLevel);
    await startNewGame();
  }


  // Returns true if move is valid and sets up for animation, or executes if we want instant
  // Actually, to support animation, we just return info to the UI? 
  // But we are in a void handler.
  // Let's create a Stream or Callback for "MoveValidated".
  // OR, we stick to the View-Driven approach:
  // View calls `handleInteraction`.
  // If we identify a move, we DON'T execute immediately.
  
  // Revised approach:
  // We add a callback `onMoveCallback` to `handleInteraction`? No, too messy.
  // Better: expose strictly methods for the UI to call.
  // But currently UI calls `handleInteraction` for everything.
  
  // Let's add a `Function(int from, int to, int count)` onMoveRequest listener?
  // Or just return the move details?
  
  // Let's keep it simple:
  // `Future<bool> requestMove(int from, int to)`
  // This is hard with the current `handleInteraction` state machine.
  
  // Let's ADD a `Function(int from, int to, int count)? onMoveAuthorized;` callback to the provider?
  // No, Provider shouldn't hold UI callbacks ideally.
  
  // Let's use `handleInteraction` to return a Status?
  
  // Actually, easiest way:
  // `verifyMove(int from, int to)` returns `MoveRequest?`
  
  // Modified handleInteraction:
  // It handles selection login.
  // If it detects a move attempt, it calls `onMove` callback provided by the UI.
  
  void handleInteraction(int tubeIndex, {Function(int from, int to, int count)? onMoveAuthorized}) {
    if (_state.isWin) return;
    
    // Clear hint
    if (_hintTargetIndex != null) {
       _hintTargetIndex = null;
    }

    if (_selectedTubeIndex == null) {
       // Select source
       if (_state.tubes[tubeIndex].isNotEmpty) {
         _selectedTubeIndex = tubeIndex;
         notifyListeners();
       }
    } else {
      if (_selectedTubeIndex == tubeIndex) {
         _selectedTubeIndex = null;
         notifyListeners();
      } else {
         // Check move
         final from = _selectedTubeIndex!;
         final to = tubeIndex;
         
         if (GameLogic.isValidMove(_state, from, to)) {
            final count = GameLogic.countBallsToMove(_state.tubes[from], _state.tubes[to]);
            
             // Invoke callback to start animation
            if (onMoveAuthorized != null) {
              _animatingFromIndex = from;
              _animatingCount = count;
              notifyListeners();
              
              onMoveAuthorized(from, to, count);
              
              _selectedTubeIndex = null; // keep selection? No, animation starts.
              notifyListeners();
            } else {
              executeMove(from, to);
            }
         } else {
            HapticFeedback.heavyImpact();
            // Invalid
         }
      }
    }
  }

  void executeMove(int from, int to) {
      if (!GameLogic.isValidMove(_state, from, to)) return;
      
      HapticFeedback.lightImpact();
      SystemSound.play(SystemSoundType.click);
      
      _history.push(_state);
      _state = GameLogic.makeMove(_state, from, to);
      _selectedTubeIndex = null;
      _animatingFromIndex = null;
      _animatingCount = 0;
      notifyListeners();
      
      if (_state.isWin) {
        HapticFeedback.mediumImpact();
      }
  }
  
  void undo() {
    final prev = _history.pop();
    if (prev != null) {
      _state = prev;
      _selectedTubeIndex = null;
      notifyListeners();
    }
  }
  
  void resetLevel() {
      // To strictly reset, we need the initial state. 
      // We can store it or just undo until beginning.
      // For now, let's just use undo all.
      while(_history.canUndo) {
        undo();
      }
      _selectedTubeIndex = null;
      _hintTargetIndex = null;
      notifyListeners();
  }

  Future<void> getHint() async {
    if (_state.isWin) return;
    
    // Run solver
    // For better UX, might want to show loading or run in compute isolate
    final solution = Solver.solve(_state);
    
    if (solution != null && solution.isNotEmpty) {
      final nextMove = solution.first;
      _selectedTubeIndex = nextMove.from;
      _hintTargetIndex = nextMove.to;
      notifyListeners();
    } else {
      // No solution or already solved (shouldn't happen if checkWin)
      // Maybe show a snackbar?
    }
  }
}
