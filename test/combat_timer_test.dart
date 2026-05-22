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
      // 1. Verify standard rate (0.3 AP/sec)
      // Starting AP is 6.0. Tick 10 seconds:
      final apStart = manager.actionPoints; // 6.0
      manager.update(10.0);
      expect(manager.actionPoints, closeTo(apStart + 3.0, 0.01)); // 9.0 AP

      // 2. Tick to final minute
      manager.update(110.0); // Remaining time is 180 - 120 = 60.0s. AP caps at 10.0.
      
      // Drain AP so we don't hit maxAP (10.0) during the test tick
      // Spawn Rats (costs 3 AP) twice:
      manager.spawnUnit(CombatUnitFactory.createRatsUnit(), CombatSide.player);
      manager.spawnUnit(CombatUnitFactory.createRatsUnit(), CombatSide.player);
      
      final apStartOverdrive = manager.actionPoints; // 4.0
      expect(apStartOverdrive, 4.0);
      
      // Tick 5 seconds (Overdrive rate is 0.6 AP/sec).
      manager.update(5.0);
      // AP should increase by 0.6 * 5 = 3.0 AP, ending at 7.0 AP
      expect(manager.actionPoints, closeTo(apStartOverdrive + 3.0, 0.01));
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
  });
}
