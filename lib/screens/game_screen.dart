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
                             // 1. Determine sizes
                             double screenWidth = constraints.maxWidth;
                             double tubeWidth = 60;
                             double spacing = 20; 
                             double runSpacing = 40;
                             
                             if (game.state.tubes.length > 5 && screenWidth < 400) {
                               tubeWidth = 50; 
                             }
                             
                             // 2. Calculate Balanced Layout
                             double itemFullWidth = tubeWidth + spacing;
                             int totalTubes = game.state.tubes.length;
                             
                             // Max columns that physically fit
                             int maxCols = (screenWidth / itemFullWidth).floor();
                             if (maxCols < 2) maxCols = 2; 
                             if (maxCols > totalTubes) maxCols = totalTubes;

                             // Calculate rows needed if we filled maxCols
                             int neededRows = (totalTubes / maxCols).ceil();
                             if (neededRows < 1) neededRows = 1;

                             // Find balanced columns count (e.g., 6 tubes / 2 rows = 3 cols)
                             int balancedCols = (totalTubes / neededRows).ceil();
                             
                             // Chunking
                             List<Widget> rows = [];
                             for (int i = 0; i < totalTubes; i += balancedCols) {
                               int end = (i + balancedCols < totalTubes) ? i + balancedCols : totalTubes;
                               
                               // Get indices for this row
                               List<int> chunkIndices = List.generate(end - i, (k) => i + k);
                               
                               rows.add(
                                 Row(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   children: chunkIndices.map((index) {
                                      final tube = game.state.tubes[index];
                                      final isSelected = game.selectedTubeIndex == index;
                                      
                                      bool isValidTarget = false;
                                      if (game.selectedTubeIndex != null && game.selectedTubeIndex != index) {
                                        isValidTarget = GameLogic.isValidMove(game.state, game.selectedTubeIndex!, index);
                                      }
                                      
                                      final isHintTarget = game.hintTargetIndex == index;
                                      
                                      if (!_tubeKeys.containsKey(index)) {
                                        _tubeKeys[index] = GlobalKey();
                                      }

                                      return Padding(
                                        padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                                        child: TubeWidget(
                                          key: _tubeKeys[index],
                                          tube: tube,
                                          isSelected: isSelected,
                                          isValidTarget: isValidTarget,
                                          isHintTarget: isHintTarget,
                                          hiddenTopCount: (game.animatingFromIndex == index) ? game.animatingCount : 0,
                                          onTap: () => _handleInteraction(context, game, index),
                                          width: tubeWidth,
                                          ballSize: tubeWidth - 12,
                                        ),
                                      );
                                   }).toList(),
                                 )
                               );
                             }

                             return Column(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 for (int i = 0; i < rows.length; i++) ...[
                                   rows[i],
                                   if (i < rows.length - 1) SizedBox(height: runSpacing),
                                 ]
                               ],
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
    // Match TubeWidget logic exactly to align positions
    final double tubeWidth = fromBox.size.width;
    
    // Parameter passed to TubeWidget (from build method)
    final double paramBallSize = tubeWidth - 12.0; 
    
    // Actual Visual Size of the ball (TubeWidget subtracts 10)
    final double visualBallSize = paramBallSize - 10.0;
    
    // Stride for stacking (TubeWidget uses paramBallSize - 4)
    final double stride = paramBallSize - 4.0;
    
    final ballsInFrom = game.state.tubes[from].balls.length;
    final ballsInTo = game.state.tubes[to].balls.length; // Before move
    
    // Top ball Y in From
    // Note: TubeWidget uses Stack. bottom: 8.0 + index * stride
    
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
                   // In TubeWidget, hover is at tubeHeight + 10.
                   // Here we approximate or use the same relative logic.
                   // Hover Top = BoxTop + (BoxHeight - (tubeHeight + 10) - visualBallSize)?
                   // Actually, simpler: Hover is 10px above the visual top of the tube glass?
                   // No, TubeWidget layout uses Stack from bottom. 
                   // Hover Bottom = Tube Height + 10.
                   // Tube Height in TubeWidget is calculated as (capacity * paramBallSize) + 12.
                   double estimatedTubeHeight = (game.state.tubes[from].capacity * paramBallSize) + 12.0;
                   double hoverBottom = estimatedTubeHeight + 10.0;
                   // Box Height matches estimatedTubeHeight + 60 (hover space).
                   // Let's rely on Box bottom.
                   // Ball Top Global = Box Bottom Global - Hover Bottom - Visual Height.
                   // Wait, Box Bottom is simply fromPos.dy + fromBox.size.height.
                   // But stack alignment is bottomCenter.
                   // So child bottom is relative to Box Bottom.
                   
                   startY = (fromPos.dy + fromBox.size.height) - hoverBottom - visualBallSize;
                } else {
                   // Inside Ball
                   int ballIndex = ballsInFrom - 1 - i;
                   double bottomOffset = 8.0 + (ballIndex * stride);
                   startY = (fromPos.dy + fromBox.size.height) - bottomOffset - visualBallSize;
                }
                
                double startX = fromPos.dx + (tubeWidth - visualBallSize) / 2;
                double endX = toPos.dx + (tubeWidth - visualBallSize) / 2;
                
                // Destination Y for THIS ball
                int destIndex = ballsInTo + (count - 1 - i);
                double destBottomOffset = 8.0 + (destIndex * stride);
                double destY = (toPos.dy + toBox.size.height) - destBottomOffset - visualBallSize;
                
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
                  child: BallWidget(color: color, size: visualBallSize),
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
