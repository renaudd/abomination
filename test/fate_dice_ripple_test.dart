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
  testWidgets('Survival Mode: Delayed Ripple Effects Verification', (WidgetTester tester) async {
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
      towerDamaged: {'tower_1': 0.5, 'tower_2': 0.5, 'tower_3': 0.5},
      unitExp: {'alphonse': 0.0, 'giles': 0.0, 'peasant': 0.0},
      starvationInfractions: {},
      bondageDebuffCount: {'peasant': 1},
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

    // --- TEST 1: Schedule and Trigger gnomes_artillery (Choice A) ---
    service.progress!.currentTurn = 1;
    service.progress!.cardUpgrades['ripple_turn_gnomes_artillery'] = 1;
    service.progress!.cardUpgrades['ripple_choice_gnomes_artillery'] = 1;

    state.triggerRippleEffectsForTest(tester.element(find.byType(SurvivalEstateMapScreen)));
    await tester.pump();

    final ackButton = find.text('ACKNOWLEDGE');
    expect(ackButton, findsOneWidget);
    await tester.tap(ackButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(service.progress!.cash, equals(1250));
    expect(service.progress!.cardUpgrades['next_combat_ap_modifier'], equals(2));
    expect(service.progress!.cardUpgrades['ripple_turn_gnomes_artillery'], isNull);
    expect(service.progress!.cardUpgrades['ripple_choice_gnomes_artillery'], isNull);

    // --- TEST 2: Schedule and Trigger freemasons_tribute (Choice A) ---
    service.progress!.currentTurn = 2;
    service.progress!.cardUpgrades['ripple_turn_freemasons_tribute'] = 2;
    service.progress!.cardUpgrades['ripple_choice_freemasons_tribute'] = 1;

    state.triggerRippleEffectsForTest(tester.element(find.byType(SurvivalEstateMapScreen)));
    await tester.pump();

    final ackButton2 = find.text('ACKNOWLEDGE');
    expect(ackButton2, findsOneWidget);
    await tester.tap(ackButton2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(service.progress!.towerDamaged['tower_1'], equals(0.0));
    expect(service.progress!.towerDamaged['tower_2'], equals(0.0));
    expect(service.progress!.towerDamaged['tower_3'], equals(0.0));
    expect(service.progress!.cardUpgrades['tower_health_multiplier'], equals(110));

    // --- TEST 3: Schedule and Trigger templar_levy (Choice C) ---
    service.progress!.currentTurn = 3;
    service.progress!.cardUpgrades['ripple_turn_templar_levy'] = 3;
    service.progress!.cardUpgrades['ripple_choice_templar_levy'] = 3;

    state.triggerRippleEffectsForTest(tester.element(find.byType(SurvivalEstateMapScreen)));
    await tester.pump();

    final ackButton3 = find.text('ACKNOWLEDGE');
    expect(ackButton3, findsOneWidget);
    await tester.tap(ackButton3);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(service.progress!.bondageDebuffCount.isEmpty, isTrue);
  });
}
