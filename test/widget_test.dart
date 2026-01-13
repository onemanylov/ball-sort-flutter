import 'package:flutter_test/flutter_test.dart';
import 'package:ball_game_antigravity/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BallSortApp());

    // Verify that the menu shows up
    expect(find.text('BALL SORT'), findsOneWidget);
  });
}
