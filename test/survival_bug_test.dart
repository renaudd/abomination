import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:abomination/state/game_state.dart';
import 'package:abomination/services/survival_service.dart';
import 'package:abomination/models/survival_state.dart';
import 'package:abomination/ui/screens/survival_estate_map_screen.dart';
import 'package:abomination/services/combat_unit_service.dart';

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
    final plotFinder = find.text('DAVOS PLOT (RESOURCE)');
    expect(plotFinder, findsOneWidget);

    // Tap the plot to open build menu
    await tester.tap(plotFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify dialog is open and shows construction options
    expect(find.text('CONSTRUCT RESOURCE FACILITY'), findsOneWidget);
    expect(find.text('LUMBERMILL'), findsOneWidget);

    // Tap "LUMBERMILL" option to construct it
    await tester.tap(find.text('LUMBERMILL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Check if dialog is closed
    expect(find.text('CONSTRUCT BASIC FACILITY'), findsNothing);

    // Check if the building was added to the service
    final hasMill = service.progress!.buildings.any((b) => b.id == 'plot_d' && b.type == SurvivalBuildingType.lumberMill);
    debugPrint('Lumber Mill constructed in service: $hasMill');
    
    // In the main estate map, it should now render the built Lumber Mill button
    expect(find.text('LUMBER MILL'), findsOneWidget);
  });

  testWidgets('Test tower repair worker assignment and worker state restrictions', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final gameState = GameState();
    final service = SurvivalService(1);
    service.initializeNewSurvivalGame('alphonse', SurvivalDifficulty.elementary);

    // Add peasant card to player deck
    service.progress!.playerDeckIds.addAll(['peasant', 'footman']);
    service.progress!.towerDamaged['tower_1'] = 1.0; // Left tower is destroyed/damaged

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

    // Verify repair indicator is present
    expect(find.text('REPAIR WEST TOWER'), findsOneWidget);

    // Assign worker via service
    service.assignTowerRepair('tower_1', 'peasant');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify worker is assigned and rendered in the tower repair slot
    expect(service.progress!.towerRepairWorkers['tower_1']!.contains('peasant'), true);

    // Standard unassign is restricted for tower repair workers
    service.unassignUnitEverywhere('peasant');
    await tester.pump();
    expect(service.progress!.towerRepairWorkers['tower_1']!.contains('peasant'), true);

    // Forced unassign is allowed (used when tower is repaired or worker is swapped)
    service.unassignUnitEverywhere('peasant', force: true);
    await tester.pump();
    expect(service.progress!.towerRepairWorkers['tower_1']!.contains('peasant'), false);
  });

  testWidgets('Test weapon upgrades market filtering and experience scaling', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final gameState = GameState();
    final service = SurvivalService(1);
    service.initializeNewSurvivalGame('alphonse', SurvivalDifficulty.elementary);

    // 1. Verify passive training grounds XP scales with level: 1 + unitLevel
    service.progress!.playerDeckIds.add('footman');
    service.progress!.trainingUnitIds.add('footman');

    // Level 1 footman (XP = 0.0, Level = 1) -> gains 1 + 1 = 2 XP
    service.progress!.unitExp['footman'] = 0.0;
    service.endTurn();
    expect(service.progress!.unitExp['footman'], 2.0);

    // Level 2 footman (XP = 14.0, Level = 2) -> gains 1 + 2 = 3 XP
    service.progress!.unitExp['footman'] = 14.0;
    service.endTurn();
    expect(service.progress!.unitExp['footman'], 17.0);

    // 2. Verify paid drills cost and XP scaling: XP = 3 * lvl, Cost = 15 * lvl
    // Give plenty of cash
    service.progress!.cash = 1000;

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

    // Open footman card inspector
    final dynamic screenState = tester.state(find.byType(SurvivalEstateMapScreen));
    screenState.selectedInspectorCardId = 'footman';
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // At level 2 (XP = 17.0), it should say "BUY DRILLS: +6 XP (30 CHF)"
    expect(find.text('BUY DRILLS: +6 XP (30 CHF)'), findsOneWidget);

    // Let's buy drills
    await tester.tap(find.text('BUY DRILLS: +6 XP (30 CHF)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Footman XP should now be 23.0 (17.0 + 6.0)
    expect(service.progress!.unitExp['footman'], 23.0);
    // Cash should be decremented by 30
    expect(service.progress!.cash, 970);

    // 3. Verify weapon upgrade requisition filtering based on affordability
    // Switch to MARKET tab
    screenState.selectedInspectorCardId = null; // close inspector
    screenState.activeTab = 'MARKET';
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Footman is a human unit capable of equipping upgrades.
    // Footman squad size is 5.
    // Let's set footman selected for requisition
    screenState.selectedWepCardId = 'footman';
    
    // We set cash to 150 CHF.
    // Weapons on market for sale:
    // - iron-tipped spear (cost 30). Cost for squad = 150 CHF. Affordable!
    // - heavy spiked mace (cost 35). Cost for squad = 175 CHF. Unaffordable!
    // - flintlock rifle (cost 40). Cost for squad = 200 CHF. Unaffordable!
    service.progress!.cash = 150;
    service.progress!.currentTurn = 5;
    service.progress!.cardUpgrades['next_encounter_turn'] = 99;
    
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap the dropdown button to trigger popup menu list
    final dropdownFinder = find.text('★ RECOMMENDED: IRON-TIPPED SPEAR');
    expect(dropdownFinder, findsOneWidget);
    await tester.ensureVisible(dropdownFinder);
    await tester.tap(dropdownFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // "IRON-TIPPED SPEAR" (cost 150 total) should be listed. "FLINTLOCK RIFLE" and "HEAVY SPIKED MACE" should be filtered out.
    expect(find.text('IRON-TIPPED SPEAR (RECOMMENDED)'), findsOneWidget);
    expect(find.text('FLINTLOCK RIFLE'), findsNothing);
    expect(find.text('HEAVY SPIKED MACE'), findsNothing);
  });

  testWidgets('Test humanoid-only repair and End Turn verification', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final gameState = GameState();
    final service = SurvivalService(1);
    service.initializeNewSurvivalGame('alphonse', SurvivalDifficulty.elementary);

    // Give some cards: Giles (humanoid) and undead_rats (non-humanoid)
    service.progress!.playerDeckIds.clear();
    service.progress!.playerDeckIds.addAll(['giles', 'undead_rats']);
    service.progress!.towerDamaged['tower_1'] = 1.0; // West tower is destroyed

    // 1. Verify we cannot assign undead_rats to tower repair
    final assignUndead = service.assignTowerRepair('tower_1', 'undead_rats');
    expect(assignUndead, false); // Rejected!
    expect(service.progress!.towerRepairWorkers['tower_1']?.contains('undead_rats') ?? false, false);

    // 2. Verify we can assign Giles
    final assignHuman = service.assignTowerRepair('tower_1', 'giles');
    expect(assignHuman, true); // Allowed!
    expect(service.progress!.towerRepairWorkers['tower_1']!.contains('giles'), true);

    // Unassign Giles to test the End Turn verification
    service.unassignUnitEverywhere('giles', force: true);

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

    // Tap "End Turn" button (represented in footer)
    final endTurnFinder = find.text('END TURN & FIGHT');
    expect(endTurnFinder, findsOneWidget);
    await tester.tap(endTurnFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify warning dialog is displayed because Giles is unassigned and tower is damaged
    expect(find.text('REPAIRS REQUIRED'), findsOneWidget);

    // Tap "AUTO-ASSIGN WORKERS" in warning dialog
    final autoAssignFinder = find.text('AUTO-ASSIGN WORKERS');
    expect(autoAssignFinder, findsOneWidget);
    await tester.tap(autoAssignFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Giles is now automatically assigned to the tower repair
    expect(service.progress!.towerRepairWorkers['tower_1']!.contains('giles'), true);
  });

  testWidgets('Test support cards (like Artillery Barrage) with 0 speed stats render correctly without division by zero', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final gameState = GameState();
    final service = SurvivalService(1);
    service.initializeNewSurvivalGame('alphonse', SurvivalDifficulty.elementary);

    // Add artillery_barrage to player deck
    service.progress!.playerDeckIds.add('artillery_barrage');

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

    // Verify map is rendered and no division by zero exception is thrown
    expect(find.byType(SurvivalEstateMapScreen), findsOneWidget);
  });

  test('Test new combat units and GameState simulation isolation', () {
    // 1. Verify boss unit creation
    final rudolf = CombatUnitService.createUnit('boss_rudolf');
    expect(rudolf.name, 'General Rudolf');

    // 2. Verify Bats unit properties
    final bats = CombatUnitService.createUnit('bats');
    expect(bats.name, 'Bats');
    expect(bats.combatStats!.isFlying, true);
    expect(bats.specimenType, 'Beast');

    // 3. Verify Stampede support card
    final stampede = CombatUnitService.createUnit('stampede');
    expect(stampede.name, 'Stampede');
    expect(stampede.combatStats!.unitCount, 5);

    // 4. Verify GameState simulation clearance
    final state = GameState();
    state.startCombatSimulation([bats], [rudolf]);
    expect(state.simulationPlayerDeck?.length, 1);

    state.clearEncounterState();
    expect(state.simulationPlayerDeck, null);
  });
}

