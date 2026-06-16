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
  group('Giles Execute Ability Tests', () {
    late CombatManager manager;

    setUp(() {
      manager = CombatManager();
      manager.startCombat();
    });

    test('Execute is unavailable if target health > 50%', () {
      final giles = CombatUnitFactory.createFlaubert();
      // Force charge to 100%
      final chargedGiles = giles.copyWith(specialCharge: 1.0);

      final enemy = CombatUnitFactory.createGoon().copyWith(
        combatStats: CombatUnitFactory.createGoon().combatStats!.copyWith(
          health: 200, // 200/220 > 50%
          maxHealth: 220,
        ),
      );

      manager.spawnUnit(chargedGiles, CombatSide.player, x: 50.0, y: 42.5);
      manager.spawnUnit(
        enemy,
        CombatSide.enemy,
        x: 55.0,
        y: 42.5,
      ); // Close range

      expect(manager.canExecuteSpecial('butler'), isFalse);
    });

    test('Execute is available if target health <= 50% and in range', () {
      final giles = CombatUnitFactory.createFlaubert();
      final chargedGiles = giles.copyWith(specialCharge: 1.0);

      final enemy = CombatUnitFactory.createGoon().copyWith(
        id: 'target_enemy',
        combatStats: CombatUnitFactory.createGoon().combatStats!.copyWith(
          health: 100, // < 50%
          maxHealth: 220,
        ),
      );

      manager.spawnUnit(chargedGiles, CombatSide.player, x: 50.0, y: 42.5);
      manager.spawnUnit(
        enemy,
        CombatSide.enemy,
        x: 58.0,
        y: 42.5,
      ); // Centers are 8ft apart

      // Giles radius: 3.5, Goon radius: 1.5.
      // Distance between centers = 8.0.
      // Edge-to-edge = 8.0 - 3.5 - 1.5 = 3.0ft.
      // 3.0ft <= 12.0ft range.

      expect(manager.canExecuteSpecial('butler'), isTrue);
    });

    test('Execute is unavailable if target is out of range', () {
      final giles = CombatUnitFactory.createFlaubert();
      final chargedGiles = giles.copyWith(specialCharge: 1.0);

      final enemy = CombatUnitFactory.createGoon().copyWith(
        combatStats: CombatUnitFactory.createGoon().combatStats!.copyWith(
          health: 50,
          maxHealth: 220,
        ),
      );

      manager.spawnUnit(chargedGiles, CombatSide.player, x: 50.0, y: 42.5);
      manager.spawnUnit(
        enemy,
        CombatSide.enemy,
        x: 70.0,
        y: 42.5,
      ); // Centers 20ft apart

      // Edge-to-edge: 20 - 3.5 - 1.5 = 15ft > 12ft range.
      expect(manager.canExecuteSpecial('butler'), isFalse);
    });

    test('Execute resets special charge after use', () {
      final giles = CombatUnitFactory.createFlaubert();
      final chargedGiles = giles.copyWith(specialCharge: 1.0);

      final enemy = CombatUnitFactory.createGoon().copyWith(
        id: 'target_enemy',
        combatStats: CombatUnitFactory.createGoon().combatStats!.copyWith(
          health: 50,
          maxHealth: 220,
        ),
      );

      manager.spawnUnit(chargedGiles, CombatSide.player, x: 50.0, y: 42.5);
      manager.spawnUnit(enemy, CombatSide.enemy, x: 55.0, y: 42.5);

      expect(manager.canExecuteSpecial('butler'), isTrue);

      manager.executeSpecial('butler');

      final gilesCombatant = manager.combatants.firstWhere(
        (c) => c.npc.id == 'butler',
      );
      expect(gilesCombatant.npc.specialCharge, 0.0);
    });

    test('Execute treats low-health Giles as a valid user', () {
      final giles = CombatUnitFactory.createFlaubert().copyWith(
        combatStats: CombatUnitFactory.createFlaubert().combatStats!.copyWith(
          health: 10.0, // Giles is near death
        ),
        specialCharge: 1.0,
      );

      final enemy = CombatUnitFactory.createGoon().copyWith(
        combatStats: CombatUnitFactory.createGoon().combatStats!.copyWith(
          health: 50, // Enemy is < 50%
        ),
      );

      manager.spawnUnit(giles, CombatSide.player, x: 50.0, y: 42.5);
      manager.spawnUnit(enemy, CombatSide.enemy, x: 55.0, y: 42.5);

      expect(manager.canExecuteSpecial('butler'), isTrue);
    });

    test('Ground Melee (Giles) cannot target Flying Rat', () {
      // Force distance to 1.0 (melee) so Giles is not a ranged unit in this test
      final giles = CombatUnitFactory.createFlaubert().copyWith(
        combatStats: CombatUnitFactory.createFlaubert().combatStats!.copyWith(distance: 1.0),
      );
      final rat = CombatUnitFactory.createBrownRats().copyWith(
        combatStats: CombatUnitFactory.createBrownRats().combatStats!.copyWith(isFlying: true),
      );

      manager.spawnUnit(giles, CombatSide.player, x: 50.0, y: 42.5);
      manager.spawnUnit(rat, CombatSide.enemy, x: 55.0, y: 42.5);

      // Give it a few ticks to try and find a target
      manager.update(0.1);

      final gilesCombatant = manager.combatants.firstWhere(
        (c) => c.npc.id == 'butler',
      );
      expect(gilesCombatant.targetId, isNull); // Should not find the rat
    });

    test('Sniper (Ranged) CAN target Flying Rat', () {
      final sniper = CombatUnitFactory.createSniper();
      final rat = CombatUnitFactory.createBrownRats().copyWith(
        combatStats: CombatUnitFactory.createBrownRats().combatStats!.copyWith(isFlying: true),
      );

      manager.spawnUnit(sniper, CombatSide.player, x: 10.0, y: 42.5);
      manager.spawnUnit(rat, CombatSide.enemy, x: 55.0, y: 42.5);

      manager.update(0.1);

      final sniperCombatant = manager.combatants.firstWhere(
        (c) => c.npc.id.contains('sniper'),
      );
      expect(sniperCombatant.targetId, isNotNull);
    });

    test('Bat (Flyer) CAN target Flying Rat', () {
      final bat = CombatUnitFactory.createBatsUnit().copyWith(
        combatStats: CombatUnitFactory.createBatsUnit().combatStats!.copyWith(isFlying: true),
      );
      final rat = CombatUnitFactory.createBrownRats().copyWith(
        combatStats: CombatUnitFactory.createBrownRats().combatStats!.copyWith(isFlying: true),
      );

      manager.spawnUnit(bat, CombatSide.player, x: 50.0, y: 42.5);
      manager.spawnUnit(rat, CombatSide.enemy, x: 55.0, y: 42.5);

      manager.update(0.1);

      final batCombatant = manager.combatants.firstWhere(
        (c) => c.npc.name.contains('Bats'),
      );
      expect(batCombatant.targetId, isNotNull);
    });

    test('Cards stay out of deck/hand while unit is alive on field', () {
      final baseGoon = CombatUnitFactory.createGoon();
      final unitA = baseGoon.copyWith(
        id: 'unit_a',
        combatStats: baseGoon.combatStats!.copyWith(unitCount: 1),
      );
      final unitB = baseGoon.copyWith(
        id: 'unit_b',
        combatStats: baseGoon.combatStats!.copyWith(unitCount: 1),
      );

      manager.prepareDeck([unitA, unitB]);
      // hand size is maxHandSize (5) by default, here 2
      expect(manager.hand.length, 2);

      // Spawn unitA
      manager.spawnUnit(unitA, CombatSide.player, x: 50, y: 40);
      expect(manager.hand.length, 1);
      expect(manager.hand.any((u) => u.id == 'unit_b'), isTrue);

      // Try to draw again (should fail because unitA is on field and unitB is in hand)
      manager.drawCard();
      expect(manager.hand.length, 1);

      // Kill unitA
      final combatantA = manager.combatants.firstWhere(
        (c) => c.npc.id == 'unit_a',
      );
      combatantA.npc = combatantA.npc.copyWith(
        combatStats: combatantA.npc.combatStats!.copyWith(health: 0),
      );
      combatantA.isDead = true; // MUST set this for cleanup
      manager.update(0.1); // Process cleanup

      // Now it should be drawn back
      manager.drawCard();
      expect(manager.hand.length, 2);
      expect(manager.hand.any((u) => u.id == 'unit_a'), isTrue);
    });

    test('Squad cards stay out of deck/hand until all members of the squad are dead (Leader dies first)', () {
      final rats = CombatUnitFactory.createBrownRats().copyWith(id: 'rats_unit');
      manager.prepareDeck([rats]);
      expect(manager.hand.length, 1);

      // Spawn squad
      manager.spawnUnit(rats, CombatSide.player, x: 50, y: 40);
      expect(manager.hand.length, 0);

      // Verify combatants spawned
      final squadCombatants = manager.combatants.where((c) => c.npc.id.contains('rats_unit') || c.npc.name.contains('Rats Unit')).toList();
      expect(squadCombatants.length, 8);

      final leader = squadCombatants.firstWhere((c) => c.isSquadLeader);
      final followers = squadCombatants.where((c) => !c.isSquadLeader).toList();
      expect(followers.length, 7);

      final String squadId = leader.squadId!;
      for (final f in followers) {
        expect(f.squadId, squadId);
      }

      // Kill the leader first
      leader.npc = leader.npc.copyWith(
        combatStats: leader.npc.combatStats!.copyWith(health: 0),
      );
      leader.isDead = true;
      manager.update(0.1);

      // Verify leader is removed, but card is NOT recycled to deck/hand
      expect(manager.combatants.any((c) => c.isSquadLeader && c.squadId == squadId), isFalse);
      expect(manager.deck.length, 0);
      manager.drawCard();
      expect(manager.hand.length, 0);

      // Kill all followers except the last one
      for (int i = 0; i < followers.length - 1; i++) {
        followers[i].npc = followers[i].npc.copyWith(
          combatStats: followers[i].npc.combatStats!.copyWith(health: 0),
        );
        followers[i].isDead = true;
      }
      manager.update(0.1);

      // Still 1 follower alive, deck is empty
      expect(manager.deck.length, 0);
      manager.drawCard();
      expect(manager.hand.length, 0);

      // Kill the last follower
      followers.last.npc = followers.last.npc.copyWith(
        combatStats: followers.last.npc.combatStats!.copyWith(health: 0),
      );
      followers.last.isDead = true;
      manager.update(0.1);

      // Last follower dead, squad should be automatically recycled and drawn back to hand by continuous draw
      expect(manager.deck.length, 0);
      expect(manager.hand.length, 1);
      expect(manager.hand.first.id, 'rats_unit');
    });

    test('Squad cards stay out of deck/hand until all members of the squad are dead (Followers die first)', () {
      final rats = CombatUnitFactory.createBrownRats().copyWith(id: 'rats_unit');
      manager.prepareDeck([rats]);
      expect(manager.hand.length, 1);

      // Spawn squad
      manager.spawnUnit(rats, CombatSide.player, x: 50, y: 40);
      expect(manager.hand.length, 0);

      final squadCombatants = manager.combatants.where((c) => c.npc.id.contains('rats_unit') || c.npc.name.contains('Rats Unit')).toList();
      expect(squadCombatants.length, 8);

      final leader = squadCombatants.firstWhere((c) => c.isSquadLeader);
      final followers = squadCombatants.where((c) => !c.isSquadLeader).toList();
      expect(followers.length, 7);

      // Kill all followers first
      for (final f in followers) {
        f.npc = f.npc.copyWith(
          combatStats: f.npc.combatStats!.copyWith(health: 0),
        );
        f.isDead = true;
      }
      manager.update(0.1);

      // Leader is still alive, so card is NOT recycled
      expect(manager.deck.length, 0);
      manager.drawCard();
      expect(manager.hand.length, 0);

      // Kill leader
      leader.npc = leader.npc.copyWith(
        combatStats: leader.npc.combatStats!.copyWith(health: 0),
      );
      leader.isDead = true;
      manager.update(0.1);

      // Leader dead, squad should be automatically recycled and drawn back to hand immediately
      expect(manager.deck.length, 0);
      expect(manager.hand.length, 1);
      expect(manager.hand.first.id, 'rats_unit');
    });
  });
}
