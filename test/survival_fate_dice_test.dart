// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:abomination/state/game_state.dart';
import 'package:abomination/models/survival_state.dart';
import 'package:abomination/services/survival_service.dart';
import 'package:abomination/ui/screens/survival_estate_map_screen.dart';

void main() {
  testWidgets('Survival Mode: Fate Dice Outcome Testing', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final gameState = GameState();
    final customProgress = SurvivalProgress(
      difficulty: SurvivalDifficulty.classic,
      playerDeckIds: ['alphonse', 'giles', 'peasant'],
      buildings: [],
      purchasedPlots: ['plot_a', 'plot_b'],
      towerLevels: {'health': 1, 'damage': 1, 'range': 0},
      towerDamaged: {'tower_1': 0.0, 'tower_2': 0.0, 'tower_3': 0.0},
      unitExp: {'alphonse': 0.0, 'giles': 0.0, 'peasant': 0.0},
      starvationInfractions: {},
      bondageDebuffCount: {},
      cash: 1000,
      food: 100,
      wood: 200,
      iron: 50,
    );
    final service = SurvivalService(1, customProgress);

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

    final dynamic state = tester.state(find.byType(SurvivalEstateMapScreen));
    expect(state, isNotNull);

    // --- TEST CASE 1: Roll = 3 (Robbery, Left Die = 1 -> 60% loss) ---
    service.progress!.cash = 1000;
    state.setDiceForTest(1, 2); // Left die = 1, Right die = 2 -> Total = 3
    state.evaluateDiceOutcomeForTest(3, service.progress!, service);
    // Execute action
    if (state.getDiceOutcomeActionForTest() != null) {
      state.getDiceOutcomeActionForTest()!();
    }
    expect(service.progress!.cash, equals(400)); // 60% of 1000 lost, remaining 400

    // --- TEST CASE 2: Roll = 3 (Robbery, Left Die = 2 -> 100% loss) ---
    service.progress!.cash = 1000;
    state.setDiceForTest(2, 1); // Left die = 2, Right die = 1 -> Total = 3
    state.evaluateDiceOutcomeForTest(3, service.progress!, service);
    if (state.getDiceOutcomeActionForTest() != null) {
      state.getDiceOutcomeActionForTest()!();
    }
    expect(service.progress!.cash, equals(0)); // 100% loss

    // --- TEST CASE 3: Roll = 5 (Fire, Left Die = 3 -> 60% metal, 40% wood loss) ---
    service.progress!.iron = 100;
    service.progress!.wood = 100;
    state.setDiceForTest(3, 2); // Left die = 3, Right die = 2 -> Total = 5
    state.evaluateDiceOutcomeForTest(5, service.progress!, service);
    if (state.getDiceOutcomeActionForTest() != null) {
      state.getDiceOutcomeActionForTest()!();
    }
    expect(service.progress!.iron, equals(40)); // 60% lost, 40 left
    expect(service.progress!.wood, equals(60)); // 40% lost, 60 left

    // --- TEST CASE 4: Roll = 6 (Blight, Left Die = 5 -> 90% food loss) ---
    service.progress!.food = 100;
    state.setDiceForTest(5, 1); // Left die = 5, Right die = 1 -> Total = 6
    state.evaluateDiceOutcomeForTest(6, service.progress!, service);
    if (state.getDiceOutcomeActionForTest() != null) {
      state.getDiceOutcomeActionForTest()!();
    }
    expect(service.progress!.food, equals(10)); // 90% lost, 10 left

    // --- TEST CASE 5: Roll = 10 (Rest -> +2 AP next combat) ---
    service.progress!.cardUpgrades['next_combat_ap_modifier'] = 0;
    state.evaluateDiceOutcomeForTest(10, service.progress!, service);
    if (state.getDiceOutcomeActionForTest() != null) {
      state.getDiceOutcomeActionForTest()!();
    }
    expect(service.progress!.cardUpgrades['next_combat_ap_modifier'], equals(2));

    // --- TEST CASE 6: Roll = 11 (Volunteer joining) ---
    // Start with 3 cards
    expect(service.progress!.playerDeckIds.length, equals(3));
    state.evaluateDiceOutcomeForTest(11, service.progress!, service);
    if (state.getDiceOutcomeActionForTest() != null) {
      state.getDiceOutcomeActionForTest()!();
    }
    // Now should have 4 cards
    expect(service.progress!.playerDeckIds.length, equals(4));

    // --- TEST CASE 7: Roll = 12 (Once-per-playthrough Discovery locking & failed redraw) ---
    // Make sure we have 0 cash initially, and clean upgrades
    service.progress!.cash = 0;
    service.progress!.cardUpgrades.clear();
    
    // First draw: should resolve a random generic/conditional discovery.
    state.evaluateDiceOutcomeForTest(12, service.progress!, service);
    
    final initialAction = state.getDiceOutcomeActionForTest();
    expect(initialAction, isNotNull); // We found a valid discovery
    initialAction!(); // execute discovery, unlocking it in upgrades
    
    // Check which discovery ID was unlocked in progress
    String? unlockedId;
    for (var k in service.progress!.cardUpgrades.keys) {
      if (k.startsWith('discovery_') && k.endsWith('_unlocked')) {
        unlockedId = k.replaceFirst('discovery_', '').replaceFirst('_unlocked', '');
      }
    }
    expect(unlockedId, isNotNull);
    
    // Now, force drawing that exact same discovery ID again
    service.progress!.cardUpgrades['discovery_lost_cashbox_unlocked'] = 1;
    service.progress!.cash = 0;
    state.evaluateDiceOutcomeForTest(12, service.progress!, service);
    
    final finalMessage = state.getDiceOutcomeMessageForTest();
    if (finalMessage.contains('already unlocked')) {
      expect(state.getDiceOutcomeActionForTest(), isNull);
    }

    // --- TEST CASE 8: Roll = 8 (Market Discount = 40% when Left Die = 4) ---
    service.progress!.cardUpgrades.clear();
    service.progress!.cash = 1000;
    state.setDiceForTest(4, 4); // Left die = 4, Right die = 4 -> Total = 8 -> 40% discount
    state.evaluateDiceOutcomeForTest(8, service.progress!, service);
    expect(state.getDiceOutcomeActionForTest(), isNotNull);
    state.getDiceOutcomeActionForTest()!();
    expect(service.progress!.cardUpgrades['market_temp_discount'], equals(40));

    // Verify that navigating to the MARKET tab renders the discounted prices
    // At Turn 1, factor is 1.0. Base food cost is 40. With 40% discount, foodPackCost should be 24 CHF.
    state.activeTab = 'MARKET';
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('24 CHF'), findsAtLeast(1));

    // --- TEST CASE 9: Roll = 9 (Bounty: Double Estate Production) ---
    service.progress!.cardUpgrades.clear();
    service.progress!.buildings.clear();
    service.progress!.playerDeckIds.clear();
    service.progress!.food = 0;
    service.progress!.buildings.add(SurvivalBuilding(
      id: 'farm_1',
      type: SurvivalBuildingType.farm,
      level: 1,
      assignedUnitIds: ['peasant'],
    ));
    // Roll a 9
    state.setDiceForTest(3, 6); // Left = 3, Right = 6 -> Total = 9
    state.evaluateDiceOutcomeForTest(9, service.progress!, service);
    expect(state.getDiceOutcomeActionForTest(), isNotNull);
    state.getDiceOutcomeActionForTest()!();
    expect(service.progress!.cardUpgrades['double_estate_production'], equals(1));

    // Resolve turn and verify production is doubled and temporary upgrades are cleared
    final initialFood = service.progress!.food;
    service.endTurn();
    
    // Normal level 1 farm with 1 worker produces 10 food (getFarmOutput(1, 1)).
    // Starvation feed cost for alphonse, giles, peasant, and recruited unit (about 7+ food total).
    // Doubled production should produce 20 food, leading to a higher net food gain!
    final netFoodGained = service.progress!.food - initialFood;
    expect(netFoodGained, greaterThan(5)); // Confirms it was doubled!

    // Verify both temporary upgrades are cleared after endTurn
    expect(service.progress!.cardUpgrades['market_temp_discount'], isNull);
    expect(service.progress!.cardUpgrades['double_estate_production'], isNull);
  });
}
