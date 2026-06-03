import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:abomination/main.dart';
import 'package:abomination/state/game_state.dart';
import 'package:abomination/services/game_engine.dart';
import 'package:flutter/services.dart';

void main() {
  testWidgets('Test starting new game and key press does not crash', (WidgetTester tester) async {
    final gameState = GameState();
    final gameEngine = GameEngine(gameState);
    addTearDown(() => gameEngine.dispose());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GameState>.value(value: gameState),
          Provider<GameEngine>.value(value: gameEngine),
        ],
        child: const AbominationApp(),
      ),
    );

    // Complete loading screen
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    // Tap "BEGIN EXPERIMENT" button to open introduction screen
    final beginButtonFinder = find.text('BEGIN EXPERIMENT');
    expect(beginButtonFinder, findsOneWidget);
    await tester.tap(beginButtonFinder);
    await tester.pumpAndSettle();

    // Select options in introduction screen to get to the finish page
    // Scene 1: Select a death cause
    await tester.tap(find.text('TRAIN CRASH.'));
    await tester.pumpAndSettle();

    // Scene 2: Text fields for names. Tap "NEXT"
    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();

    // Scene 3: Age
    await tester.tap(find.text('25 YEARS OLD.'));
    await tester.pumpAndSettle();

    // Scene 4: Butler trait
    await tester.tap(find.text('GIVING SAGE ADVICE.'));
    await tester.pumpAndSettle();

    // Scene 5: Life objective
    await tester.tap(find.text('SCIENCE.'));
    await tester.pumpAndSettle();

    // Scene 6: Begin the work
    final beginWorkButtonFinder = find.text('BEGIN THE WORK');
    expect(beginWorkButtonFinder, findsOneWidget);
    await tester.tap(beginWorkButtonFinder);
    await tester.pump();
    
    // Simulate pressing a key (e.g. Digit 1) immediately during transition
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    
    await tester.pump(const Duration(seconds: 1));
    gameEngine.dispose();
  });
}
