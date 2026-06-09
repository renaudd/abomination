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

import 'package:flutter_test/flutter_test.dart';
import 'package:abomination/services/combat_manager.dart';
import 'package:abomination/services/combat_unit_factory.dart';

void main() {
  group('CombatManager Timer and Energy Overdrive Tests', () {
    late CombatManager manager;

    setUp(() {
      manager = CombatManager();
      manager.startCombat();

      // Spawn Alphonse (Player) and Goon (Enemy) to keep combat active
      final alphonse = CombatUnitFactory.createAlphonse();
      final enemyGoon = CombatUnitFactory.createGoon();
      manager.spawnUnit(alphonse, CombatSide.player, x: 10.0, y: 42.5);
      manager.spawnUnit(enemyGoon, CombatSide.enemy, x: 160.0, y: 20.0);
    });

    test('Initial combat timer states are correct', () {
      expect(manager.combatTimeRemaining, 180.0);
      expect(manager.isDraw, isFalse);
      expect(manager.isLastMinute, isFalse);
      expect(manager.isCombatActive, isTrue);
    });

    test('Combat timer decrements correctly per tick', () {
      manager.update(1.0);
      expect(manager.combatTimeRemaining, 179.0);
      expect(manager.isLastMinute, isFalse);

      manager.update(2.5);
      expect(manager.combatTimeRemaining, 176.5);
      expect(manager.isLastMinute, isFalse);
    });

    test('Transitions to last minute state correctly', () {
      // Tick 120 seconds off
      manager.update(120.0);
      expect(manager.combatTimeRemaining, 60.0);
      expect(manager.isLastMinute, isTrue);

      manager.update(10.0);
      expect(manager.combatTimeRemaining, 50.0);
      expect(manager.isLastMinute, isTrue);
    });

    test('AP generation doubles during the final minute', () {
      // 1. Verify standard rate (1/3 AP/sec)
      // Starting AP is 6.0. Tick 9 seconds:
      final apStart = manager.actionPoints; // 6.0
      manager.update(9.0);
      expect(manager.actionPoints, closeTo(apStart + 3.0, 0.01)); // 9.0 AP

      // 2. Tick to final minute
      manager.update(111.0); // Remaining time is 180 - 120 = 60.0s. AP caps at 10.0.
      
      // Drain AP so we don't hit maxAP (10.0) during the test tick
      // Spawn Rats (costs 3 AP) twice:
      manager.spawnUnit(CombatUnitFactory.createBrownRats(), CombatSide.player, y: 30.0);
      manager.spawnUnit(CombatUnitFactory.createBrownRats(), CombatSide.player, y: 30.0);
      
      final apStartOverdrive = manager.actionPoints; // 4.0
      expect(apStartOverdrive, 4.0);
      
      // Tick 6 seconds (Overdrive rate is 2/3 AP/sec).
      manager.update(6.0);
      // AP should increase by (2/3) * 6 = 4.0 AP, ending at 8.0 AP
      expect(manager.actionPoints, closeTo(apStartOverdrive + 4.0, 0.01));
    });

    test('Combat ends in a draw when timer reaches 0', () {
      // Tick 180 seconds to run out the clock
      manager.update(180.0);

      expect(manager.combatTimeRemaining, 0.0);
      expect(manager.isDraw, isTrue);
      expect(manager.isCombatActive, isFalse);
      expect(manager.isVictory, isFalse);
      expect(manager.isDefeat, isFalse);
    });

    test('isValidPlacementForTroop checks top/bottom lanes correctly off-center', () {
      // Starting zone limit is 0.2 * 300 = 60.0. Let's test with worldX = 75.0 (outside starting zone)
      // 1. Relocate the spawned Alphonse (from setUp) to top lane at x: 90.0, y: 30.0
      final playerUnit = manager.combatants.firstWhere((c) => c.npc.isPlayer);
      playerUnit.x = 90.0;
      playerUnit.y = 30.0;

      // - Top lane summoning behind Alphonse at x: 75.0, y: 30.0 (exact center) is valid
      expect(manager.isValidPlacementForTroop(75.0, 30.0), isTrue);
      // - Top lane summoning off-center near edge at x: 75.0, y: 10.0 is valid
      expect(manager.isValidPlacementForTroop(75.0, 10.0), isTrue);
      // - Top lane summoning ahead of Alphonse at x: 110.0, y: 30.0 is invalid
      expect(manager.isValidPlacementForTroop(110.0, 30.0), isFalse);

      // - Bottom lane summoning at x: 75.0, y: 110.0 (exact center) is invalid (no unit in bottom half)
      expect(manager.isValidPlacementForTroop(75.0, 110.0), isFalse);
      // - Bottom lane summoning off-center at x: 75.0, y: 135.0 is invalid
      expect(manager.isValidPlacementForTroop(75.0, 135.0), isFalse);

      // 2. Now spawn a player unit in the starting zone (x: 10.0, y: 110.0) and move it to x: 100.0, y: 110.0
      final peasant = CombatUnitFactory.createMilitia();
      manager.spawnUnit(peasant, CombatSide.player, x: 10.0, y: 110.0);
      final peasantUnit = manager.combatants.firstWhere((c) => c.npc.id == peasant.id);
      peasantUnit.x = 100.0;
      peasantUnit.y = 110.0;

      // Move player character to bottom lane to allow summoning into the bottom channel
      playerUnit.y = 110.0;

      // - Bottom lane summoning behind unit at x: 75.0, y: 110.0 (exact center) is now valid
      expect(manager.isValidPlacementForTroop(75.0, 110.0), isTrue);
      // - Bottom lane summoning off-center near bottom edge at x: 75.0, y: 135.0 is now valid
      expect(manager.isValidPlacementForTroop(75.0, 135.0), isTrue);
      // - Bottom lane summoning ahead of unit at x: 120.0, y: 110.0 is invalid
      expect(manager.isValidPlacementForTroop(120.0, 110.0), isFalse);
    });
  });
}
