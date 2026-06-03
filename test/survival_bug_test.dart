import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:abomination/state/game_state.dart';
import 'package:abomination/services/survival_service.dart';
import 'package:abomination/models/survival_state.dart';
import 'package:abomination/ui/screens/survival_estate_map_screen.dart';

void main() {
  testWidgets('Test building other facilities in SurvivalEstateMapScreen widget', (WidgetTester tester) async {
    // Set viewport size to 1920x1080
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final gameState = GameState();
    final service = SurvivalService(1);
    service.initializeNewSurvivalGame('alphonse', SurvivalDifficulty.classic);

    // Add cards to deck to make sure _isDrafting gets set to false!
    service.progress!.playerDeckIds.add('peasant');

    // Give plenty of resources
    service.progress!.wood = 1000;
    service.progress!.iron = 1000;
    service.progress!.cash = 10000;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GameState>.value(value: gameState),
          ChangeNotifierProvider<SurvivalService>.value(value: service),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SurvivalEstateMapScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Find the plot_d button (Davos Plot)
    final plotFinder = find.text('DAVOS PLOT (BASIC)');
    expect(plotFinder, findsOneWidget);

    // Tap the plot to open build menu
    await tester.tap(plotFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify dialog is open and shows construction options
    expect(find.text('CONSTRUCT BASIC FACILITY'), findsOneWidget);
    expect(find.text('LUMBERMILL'), findsOneWidget);

    // Tap "LUMBERMILL" option to construct it
    await tester.tap(find.text('LUMBERMILL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Check if dialog is closed
    expect(find.text('CONSTRUCT BASIC FACILITY'), findsNothing);

    // Check if the building was added to the service
    final hasMill = service.progress!.buildings.any((b) => b.id == 'plot_d' && b.type == SurvivalBuildingType.lumberMill);
    print('Lumber Mill constructed in service: $hasMill');
    
    // In the main estate map, it should now render the built Lumber Mill button
    expect(find.text('MILL'), findsOneWidget);
  });
}
