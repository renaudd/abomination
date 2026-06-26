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
import 'package:abomination/models/combat_stats.dart';

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

  group('Combat Card and Ability Rebalancing Tests', () {
    late CombatManager manager;

    setUp(() {
      manager = CombatManager();
      manager.startCombat();
    });

    test('Magus Rosenkreuz special ability charge times are balanced', () {
      final rosen = CombatUnitFactory.createChristianRosenkreuz();
      final aoeHeal = rosen.abilities.firstWhere((a) => a.id == 'aoe_heal');
      final transmute = rosen.abilities.firstWhere((a) => a.id == 'health_transmute');

      expect(aoeHeal.chargeTime, 20.0);
      expect(transmute.chargeTime, 25.0);
    });

    test('General Rudolf Shield Wall grants complete damage immunity to self and allies', () {
      final rudolf = CombatUnitFactory.createBossRudolf().copyWith(specialCharge: 1.0);
      final ally = CombatUnitFactory.createGoon();

      manager.spawnUnit(rudolf, CombatSide.player, x: 50.0, y: 50.0);
      manager.spawnUnit(ally, CombatSide.player, x: 55.0, y: 50.0); // Within 30ft

      expect(manager.canExecuteSpecial('boss_rudolf'), isTrue);
      manager.executeSpecial('boss_rudolf');

      final rCombatant = manager.combatants.firstWhere((c) => c.npc.id == 'boss_rudolf');
      final aCombatant = manager.combatants.firstWhere((c) => c.npc.id.contains('goons'));

      expect(rCombatant.isInvulnerable, isTrue);
      expect(rCombatant.invulnerableDurationRemaining, 6.0);
      expect(aCombatant.isInvulnerable, isTrue);
      expect(aCombatant.invulnerableDurationRemaining, 6.0);
    });

    test('General Rudolf Battle Cry boosts self and allies attack by 25', () {
      final rudolf = CombatUnitFactory.createBossRudolf();
      // Let's force execution by simulating battle_cry as the first special
      final mockRudolf = rudolf.copyWith(
        specialCharge: 1.0,
        abilities: [
          const Ability(id: 'battle_cry', name: 'Battle Cry', type: AbilityType.special, chargeTime: 22.0, description: 'Battle Cry'),
          const Ability(id: 'shield_wall', name: 'Shield Wall', type: AbilityType.special, chargeTime: 15.0, description: 'Shield Wall'),
        ],
      );

      final ally = CombatUnitFactory.createGoon();

      manager.spawnUnit(mockRudolf, CombatSide.player, x: 50.0, y: 50.0);
      manager.spawnUnit(ally, CombatSide.player, x: 55.0, y: 50.0); // Within 30ft

      manager.executeSpecial('boss_rudolf');

      final rCombatant = manager.combatants.firstWhere((c) => c.npc.id == 'boss_rudolf');
      final aCombatant = manager.combatants.firstWhere((c) => c.npc.id.contains('goons'));

      expect(rCombatant.flatAttackBuff, 25.0);
      expect(rCombatant.flatAttackBuffDurationRemaining, 8.0);
      expect(aCombatant.flatAttackBuff, 25.0);
      expect(aCombatant.flatAttackBuffDurationRemaining, 8.0);
    });

    test('Warlock Lightning Strike deals 150 damage and stuns for 4 seconds', () {
      final warlock = CombatUnitFactory.createWarlock().copyWith(specialCharge: 1.0);
      final enemy = CombatUnitFactory.createGoon().copyWith(
        id: 'target_enemy',
        combatStats: CombatUnitFactory.createGoon().combatStats!.copyWith(health: 200, maxHealth: 200, defense: 0),
      );

      manager.spawnUnit(warlock, CombatSide.player, x: 50.0, y: 50.0);
      manager.spawnUnit(enemy, CombatSide.enemy, x: 55.0, y: 50.0);

      expect(manager.canExecuteSpecial(warlock.id), isTrue);
      manager.executeSpecial(warlock.id);

      final enemyCombatant = manager.combatants.firstWhere((c) => c.npc.id == 'target_enemy');
      // 200 health - 150 damage = 50 health remaining
      expect(enemyCombatant.npc.combatStats!.health, 50.0);
      expect(enemyCombatant.freezeTimer, 4.0);
    });

    test('Alphonse Frankenstein Lightning Strike (Special 2) deals 150 damage and stuns', () {
      final alphonse = CombatUnitFactory.createAlphonse();
      final enemy = CombatUnitFactory.createGoon().copyWith(
        id: 'target_enemy',
        combatStats: CombatUnitFactory.createGoon().combatStats!.copyWith(health: 200, maxHealth: 200, defense: 0),
      );

      manager.spawnUnit(alphonse, CombatSide.player, x: 50.0, y: 50.0);
      manager.spawnUnit(enemy, CombatSide.enemy, x: 55.0, y: 50.0);

      final alphonseCombatant = manager.combatants.firstWhere((c) => c.npc.id == alphonse.id);
      alphonseCombatant.specialCharge2 = 1.0; // Charge his second special

      expect(manager.canExecuteSpecial2(alphonse.id), isTrue);
      manager.executeSpecial2(alphonse.id);

      final enemyCombatant = manager.combatants.firstWhere((c) => c.npc.id == 'target_enemy');
      expect(enemyCombatant.npc.combatStats!.health, 50.0); // 200 - 150 = 50
      expect(enemyCombatant.freezeTimer, 4.0); // 4.0s stun
    });

    test('Undead Bats Vampiric Screech drains nearby enemies and heals allies', () {
      final bats = CombatUnitFactory.createUndeadBats().copyWith(specialCharge: 1.0);
      final enemy = CombatUnitFactory.createGoon().copyWith(
        id: 'target_enemy',
        combatStats: CombatUnitFactory.createGoon().combatStats!.copyWith(health: 100, maxHealth: 100, defense: 0),
      );

      manager.spawnUnit(bats, CombatSide.player, x: 50.0, y: 50.0);
      manager.spawnUnit(enemy, CombatSide.enemy, x: 55.0, y: 50.0); // Within 20ft

      final batsCombatant = manager.combatants.firstWhere((c) => c.npc.id == bats.id);
      // Set initial health to 30/55 to verify healing
      batsCombatant.npc = batsCombatant.npc.copyWith(
        combatStats: batsCombatant.npc.combatStats!.copyWith(health: 30),
      );

      manager.executeSpecial(bats.id);

      final enemyCombatant = manager.combatants.firstWhere((c) => c.npc.id == 'target_enemy');
      // Enemy: 100 health - 35 drain = 65 remaining
      expect(enemyCombatant.npc.combatStats!.health, 65.0);
      // Bats: healed by 20 -> 30 + 20 = 50
      expect(batsCombatant.npc.combatStats!.health, 50.0);
    });

    test('Witch Coven Restoration heals allies within 7 ft (14 units) but not beyond', () {
      manager.actionPoints = 10.0;
      final witch = CombatUnitFactory.createWitch().copyWith(specialCharge: 1.0);
      final ally1 = CombatUnitFactory.createGoon().copyWith(
        id: 'ally_near',
        combatStats: CombatUnitFactory.createGoon().combatStats!.copyWith(health: 50.0, maxHealth: 100.0),
      );
      final ally2 = CombatUnitFactory.createGoon().copyWith(
        id: 'ally_far',
        combatStats: CombatUnitFactory.createGoon().combatStats!.copyWith(health: 50.0, maxHealth: 100.0),
      );

      manager.spawnUnit(witch, CombatSide.player, x: 50.0, y: 50.0);
      manager.spawnUnit(ally1, CombatSide.player, x: 38.0, y: 50.0); // 12 units away (within 14)
      manager.spawnUnit(ally2, CombatSide.player, x: 34.0, y: 50.0); // 16 units away (outside 14)

      manager.executeSpecial(witch.id);

      final allyNearCombatant = manager.combatants.firstWhere((c) => c.npc.id == 'ally_near');
      final allyFarCombatant = manager.combatants.firstWhere((c) => c.npc.id == 'ally_far');

      expect(allyNearCombatant.npc.combatStats!.health, 100.0); // Healed +50
      expect(allyFarCombatant.npc.combatStats!.health, 50.0); // Not healed
    });

    test('Card balance stats are correct', () {
      final bats = CombatUnitFactory.createBats();
      expect(bats.combatStats!.cost, 3); // Bats cost 3 AP now

      final sniper = CombatUnitFactory.createSniper();
      expect(sniper.combatStats!.health, 160); // Sniper health is 160

      final brewers = CombatUnitFactory.createBrewers();
      expect(brewers.combatStats!.health, 110); // Brewers health nerfed to 110
      expect(brewers.combatStats!.meleeDamage, 18); // Brewers attack nerfed to 18
    });
  });
}
