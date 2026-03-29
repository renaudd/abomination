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
import 'package:frankensteinoss/services/combat_manager.dart';
import 'package:frankensteinoss/services/combat_unit_factory.dart';

void main() {
  group('CombatManager Logging Tests', () {
    late CombatManager manager;

    setUp(() {
      manager = CombatManager();
      // Ensure we have enough AP for any unit in tests
      manager.update(100.0);
      manager.startCombat();
    });

    test('Log is generated when an attack occurs', () {
      final alphonse = CombatUnitFactory.createAlphonse();
      final attackerNPC = CombatUnitFactory.createFlaubert();
      final targetNPC = CombatUnitFactory.createGoon();

      manager.spawnUnit(alphonse, CombatSide.player, x: 0.0, y: 0.5);
      manager.spawnUnit(attackerNPC, CombatSide.player, x: 1.0, y: 0.5);
      manager.spawnUnit(targetNPC, CombatSide.enemy, x: 2.0, y: 0.5);

      // Verify log is empty initially
      expect(manager.logs, isEmpty);

      // Manually trigger updates in small steps to simulate passage of time
      for (int i = 0; i < 100; i++) {
        manager.update(0.1);
      }

      expect(manager.logs.isNotEmpty, isTrue);
      expect(
        manager.logs.any(
          (l) => l.message.contains('hit') || l.message.contains('missed'),
        ),
        isTrue,
      );
    });

    test('Log records death', () {
      final alphonse = CombatUnitFactory.createAlphonse();
      final attackerNPC = CombatUnitFactory.createFlaubert().copyWith(
        combatStats: CombatUnitFactory.createFlaubert().combatStats!.copyWith(
          attack: 100,
          accuracy: 1.0,
        ),
      );
      final targetNPC = CombatUnitFactory.createGoon().copyWith(
        combatStats: CombatUnitFactory.createGoon().combatStats!.copyWith(
          health: 1,
        ),
      );

      manager.spawnUnit(alphonse, CombatSide.player, x: 0.0, y: 0.5);
      manager.spawnUnit(attackerNPC, CombatSide.player, x: 1.0, y: 0.5);
      manager.spawnUnit(targetNPC, CombatSide.enemy, x: 1.2, y: 0.5);

      for (int i = 0; i < 50; i++) {
        manager.update(0.1);
      }

      expect(manager.logs.any((l) => l.message.contains('defeated')), isTrue);
    });
  });
}
