# Ball Sort Puzzle

A beautiful, modern Ball Sort Puzzle game built with Flutter.

## Features

- **Dynamic Level Generation**: Infinite levels with increasing difficulty.
- **Smart Solver**: Built-in solver for validation and Hints.
- **Undo System**: Unlimited undo capabilities.
- **Rich Aesthetics**: Glassmorphism design, smooth animations, and haptic feedback.
- **Responsive**: Works on phones and tablets.
- **Progress Saving**: Automatically saves your current level.

## Getting Started

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run the App**:
   ```bash
   flutter run
   ```

## Architecture

- **Models**: `GameState`, `Tube`, `Ball` (Immutable with Equatable).
- **Logic**: Pure Dart logic for Rules (`GameLogic`), Solving (`Solver`), and Generation (`LevelGenerator`).
- **State Management**: `Provider` with `GameProvider` handling game loop and interaction.
- **UI**: Custom widgets (`TubeWidget`, `BallWidget`) with animations.

## Assets

- App Icon: Located in `assets/icon.png`.

## Credits

Developed with Antigravity.
