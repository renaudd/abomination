import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:abomination/main.dart';
import 'package:abomination/state/game_state.dart';
import 'package:abomination/services/game_engine.dart';
import 'package:abomination/ui/screens/combat_screen.dart';
import 'package:abomination/services/combat_unit_factory.dart';
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

    // Tap "AWAKEN" button to enter Main Menu
    await tester.tap(find.text('AWAKEN'));
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
    await tester.tap(find.textContaining('GIVING SAGE ADVICE.'));
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

  testWidgets('Test pressing key events (WASD, numbers) in CombatScreen does not crash global KeyboardListener', (WidgetTester tester) async {
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

    // Push CombatScreen
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => CombatScreen(
          customPlayerHero: CombatUnitFactory.createAlphonse(),
          customPlayerDeck: const [],
          customAiDeck: const [],
          cardUpgrades: const {},
          survivalTurn: 1,
          onSurvivalVictory: (towers, enemyDeck, f, c, ir, w, hp, exp, ctx) {},
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Fire WASD keys and digits
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.pump();

    // Verify no crash occurred and CombatScreen is still active
    expect(find.byType(CombatScreen), findsOneWidget);
    gameEngine.dispose();
  });

  testWidgets('Test entering combat from Normal game (const CombatScreen()) does not crash', (WidgetTester tester) async {
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

    // Push const CombatScreen() simulating normal game mode transition
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => const CombatScreen(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify no crash occurred and CombatScreen is still active
    expect(find.byType(CombatScreen), findsOneWidget);
    gameEngine.dispose();
  });
}
