import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../widgets/tube_widget.dart';
import '../widgets/ball_widget.dart';
import '../logic/game_logic.dart';

class GameScreen extends StatefulWidget {
  final int? initialLevel;
  const GameScreen({Key? key, this.initialLevel}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // GlobalKeys to get positions
  final Map<int, GlobalKey> _tubeKeys = {};
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider()..init(widget.initialLevel), // Access widget.initialLevel
      child: Scaffold(
        body: Consumer<GameProvider>(
          builder: (context, game, child) {
            if (game.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            return Stack(
              children: [
                // Background
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1E1E2C), Color(0xFF2D2D44)],
                    ),
                  ),
                ),
                
                // Content
                SafeArea(
                  child: Column(
                    children: [
                      // HUD
                      _buildHUD(context, game),
                      
                      const Spacer(),
                      
                      // Board
                      Center(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                             // Adjust ball size based on screen width
                             double screenWidth = constraints.maxWidth;
                             double tubeWidth = 60;
                             if (game.state.tubes.length > 5 && screenWidth < 400) {
                               tubeWidth = 50; 
                             }
                             
                             return Wrap(
                              spacing: 16,
                              runSpacing: 40,
                              alignment: WrapAlignment.center,
                              children: List.generate(game.state.tubes.length, (index) {
                                final tube = game.state.tubes[index];
                                final isSelected = game.selectedTubeIndex == index;
                                
                                // Check if valid target
                                bool isValidTarget = false;
                                if (game.selectedTubeIndex != null && game.selectedTubeIndex != index) {
                                  isValidTarget = GameLogic.isValidMove(game.state, game.selectedTubeIndex!, index);
                                }
                                
                                final isHintTarget = game.hintTargetIndex == index;
                                
                                // Prepare Key
                                if (!_tubeKeys.containsKey(index)) {
                                  _tubeKeys[index] = GlobalKey();
                                }
                                
                                return TubeWidget(
                                  key: _tubeKeys[index],
                                  tube: tube,
                                  isSelected: isSelected,
                                  isValidTarget: isValidTarget,
                                  isHintTarget: isHintTarget,
                                  hiddenTopCount: (game.animatingFromIndex == index) ? game.animatingCount : 0,
                                  onTap: () => _handleInteraction(context, game, index),
                                  width: tubeWidth,
                                  ballSize: tubeWidth - 12,
                                );
                              }),
                            );
                          }
                        ),
                      ),
                      
                      const Spacer(),
                    ],
                  ),
                ),
                
                if (game.state.isWin)
                  Container(
                    color: Colors.black.withOpacity(0.85),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
                          const SizedBox(height: 20),
                          const Text("LEVEL COMPLETED!", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                          Text("Moves: ${game.state.moves}", style: const TextStyle(color: Colors.white70, fontSize: 18)),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () => game.nextLevel(),
                            label: const Text("Next Level"),
                          )
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHUD(BuildContext context, GameProvider game) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text("LEVEL ${game.state.level}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
               Text("Moves: ${game.state.moves}", style: const TextStyle(color: Colors.white70)),
            ],
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.undo), color: Colors.white, onPressed: game.undo, tooltip: "Undo"),
              IconButton(icon: const Icon(Icons.refresh), color: Colors.white, onPressed: game.resetLevel, tooltip: "Reset"),
              IconButton(icon: const Icon(Icons.lightbulb_outline), color: Colors.amber, onPressed: game.getHint, tooltip: "Hint"),
            ],
          )
        ],
      ),
    );
  }
  
  void _handleInteraction(BuildContext context, GameProvider game, int index) {
    game.handleInteraction(index, onMoveAuthorized: (from, to, count) {
      _animateMove(context, game, from, to, count);
    });
  }

  void _animateMove(BuildContext context, GameProvider game, int from, int to, int count) {
    // 1. Get Positions
    final RenderBox? fromBox = _tubeKeys[from]?.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? toBox = _tubeKeys[to]?.currentContext?.findRenderObject() as RenderBox?;
    
    if (fromBox == null || toBox == null) {
      game.executeMove(from, to);
      return;
    }
    
    final fromPos = fromBox.localToGlobal(Offset.zero);
    final toPos = toBox.localToGlobal(Offset.zero);
    
    // 2. Ball Details
    // We can assume RenderBox size matches TubeWidget logic: 
    // Tube Width is ~50-60.
    // We need exact Ball size and positions. 
    // This is tricky without exposing layout logic. 
    // Approximation:
    final double tubeWidth = fromBox.size.width;
    final double ballSize = tubeWidth - 10;
    
    final ballsInFrom = game.state.tubes[from].balls.length;
    final ballsInTo = game.state.tubes[to].balls.length; // Before move
    
    // Top ball Y in From
    // Note: TubeWidget uses Stack. bottom: 8.0 + index * ballSize
    // In global coords: (Box Top + Box Height) - (bottom offset + ballSize)
    // Actually easier: Box Top + Box Height - 8 - (index+1)*ballSize? No
    
    // Let's rely on standard calculation:
    // Tube Height = ~ (Capacity * BallSize) + 16.0
    // But TubeWidget might be taller due to "Lift".
    // Let's use the bottom anchor.
    
    final double bottomPadding = 8.0;
    
    OverlayEntry? entry;
    
    // Create Animation Controller
    // SNAPPY but CLEAN duration
    final controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 300), 
    );
    
    // Animation Curves
    // Phase 1: Up - Fast launch, no wobble
    final animUp = CurvedAnimation(
       parent: controller, 
       curve: const Interval(0.0, 0.4, curve: Curves.easeOutQuad)
    );
    // Phase 2: Peer (Travel) - Direct
    final animMove = CurvedAnimation(
       parent: controller, 
       curve: const Interval(0.1, 0.9, curve: Curves.easeInOutCubic)
    );
    // Phase 3: Drop - Clean landing
    final animDrop = CurvedAnimation(
       parent: controller, 
       curve: const Interval(0.5, 1.0, curve: Curves.easeInCubic)
    );

    // Color
    final color = game.state.tubes[from].balls.last.color;
    
    entry = OverlayEntry(builder: (context) {
      return AnimatedBuilder(
         animation: controller,
         builder: (context, child) {
            // Calculate positions dynamically based on animation values
            
            // "Lifted" state of From Tube implies ball was already up +30.
            // But we start animation from that "Selected" state? 
            // Or from resting state?
            // When we deselect, the tube might snap down. 
            // Let's assume start position is the "Lifted" position if it was selected.
            // GameProvider deselects immediately upon authorizing move.
            // So TubeWidget snaps back.
            // We should start from "Resting Top" or "Lifted Top". 
            // Visually smoother if we start from Lifted.
            // But Provider state changed to null selection.
            // This is a race.
            // It's fine to start from "In Tube" position and fly up fast.
            
            // Start Logic
            // If i == 0 (Topmost ball), it was hovering.
            // If i > 0, it was inside the tube.
            
            // From Box Top
            double fromTopY = fromPos.dy;
            double tubeHeight = fromBox.size.height; 
            // Calculated hover Y (same as TubeWidget logic):
            // TubeWidget uses bottomPos = tubeHeight + 10.0
            // In Global Y: fromTopY + (tubeHeight - (tubeHeight + 10.0 + ballSize)) ?
            // Wait, TubeWidget stack alignment is bottomCenter.
            // Global Y of bottom anchor = fromTopY + tubeHeight.
            // Hover Ball Bottom = Anchor - (tubeHeight + 10.0).
            // Hover Ball Top = Anchor - (tubeHeight + 10.0) - ballSize.
            // Simplify: Hover Ball Top = fromTopY + tubeHeight - tubeHeight - 10.0 - ballSize
            // = fromTopY - 10.0 - ballSize. 
            // So it floats 10px above the top edge of the box?
            // Wait, TubeWidget actually adds height to the SizedBox to accommodate.
            // RenderBox includes that height.
            // If TubeWidget height = capacity*size + 16 + 60.
            // The "Glass" is at bottom. glass height = capacity*size + 16.
            // top of glass relative to box top = 60.
            // Hover ball is at bottomPos = glassHeight + 10.
            // Rel to bottom: glassHeight + 10.
            // Rel to top of Box: BoxHeight - (glassHeight + 10) - ballSize.
            // If BoxHeight = glassHeight + 60.
            // Top = (glassHeight + 60) - glassHeight - 10 - ballSize
            // Top = 50 - ballSize.
            
            // Standard Inside Ball:
            // Index K (from bottom). 
            // BottomPos = 8 + K*size.
            // TopRelBox = BoxHeight - (8 + K*size) - ballSize.
            
            // Adjust loop to account for "ballsInFrom" indices.
            // The top ball being moved is at index: ballsInFrom - 1.
            // The next is at ballsInFrom - 2.
            // Loop i goes from 0 to count-1.
            // i=0 is top ball.
            // Ball Index in Tube = ballsInFrom - 1 - i.
            
            double glassHeight = (fromBox.size.height - 60); // Approx based on new TubeWidget
            // Actually relying on hard numbers is brittle but necessary if we can't ask TubeWidget.
            // TubeWidget height logic: (capacity * size) + 16 + 60.
            // Let's assume glass starts at offset 60 from top.
            
             // We need to render each ball individually because they have different startY
             List<Widget> animatedBalls = List.generate(count, (i) {
                double startY;
                if (i == 0) {
                   // Top ball (Hovering) - already high up
                   startY = fromPos.dy + (60 - 10 - ballSize); 
                } else {
                   // Inside Ball
                   int ballIndex = ballsInFrom - 1 - i;
                   double bottomOffset = 8.0 + (ballIndex * ballSize);
                   startY = fromPos.dy + fromBox.size.height - bottomOffset - ballSize;
                }
                
                double startX = fromPos.dx + (tubeWidth - ballSize) / 2;
                double endX = toPos.dx + (tubeWidth - ballSize) / 2;
                
                // Destination Y for THIS ball
                // They stack up at destination. 
                // Top ball (i=0) goes to highest pos. 
                // Bottom ball (i=count-1) goes to lowest pos (on top of existing).
                // Existing balls count = ballsInTo.
                // Ball i will be at index = ballsInTo + (count - 1 - i).
                // Example: Moving 2 balls to empty tube.
                // i=0 (Top) -> becomes index 1.
                // i=1 (Bottom) -> becomes index 0.
                
                int destIndex = ballsInTo + (count - 1 - i);
                double destBottomOffset = 8.0 + (destIndex * ballSize);
                double destY = toPos.dy + toBox.size.height - destBottomOffset - ballSize;
                
                double hoverY = (fromPos.dy < toPos.dy ? fromPos.dy : toPos.dy) - 50;
                
                double currentX = startX + (endX - startX) * animMove.value;
                
                double upProgress = animUp.value;
                double dropProgress = animDrop.value;
                
                double yPhase1 = startY + (hoverY - startY) * upProgress;
                double currentY;
                if (dropProgress > 0) {
                   currentY = yPhase1 + (destY - hoverY) * dropProgress;
                } else {
                   currentY = yPhase1;
                }
                
                return Positioned(
                  left: currentX,
                  top: currentY,
                  child: BallWidget(color: color, size: ballSize),
                );
             });

             return Stack(
               children: animatedBalls,
             );

         } 
      );
    });
    
    Overlay.of(context).insert(entry);
    
    controller.forward().then((_) {
       entry?.remove();
       game.executeMove(from, to);
    });
  }
}
