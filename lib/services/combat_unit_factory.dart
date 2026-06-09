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

import '../models/npc.dart';
import '../models/combat_stats.dart';
import '../models/schedule.dart';
import '../models/diet.dart';
import '../models/body_part.dart';
import 'dart:ui';

class CombatUnitFactory {
  static int _idCounter = 0;

  static String _generateId(String prefix) {
    _idCounter++;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
  }

  static NPC createAlphonse() {
    return NPC(
      id: 'alphonse',
      name: 'Alphonse Frankenstein',
      role: 'Master',
      age: 25,
      gender: 'Male',
      specimenType: 'Human',
      isPlayer: true,
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.defaultMaster(),
      combatStats: const CombatStats(
        attack: 35,
        health: 300,
        maxHealth: 300,
        speed: 1.0,
        movement: 1.0,
        distance: 7.5,
        defense: 0,
        accuracy: 0.85,
        cost: 0,
        unitType: UnitType.squad,
        unitCount: 1,
      ),
      abilities: [
        const Ability(
          id: 'master_command',
          name: "Master's Command",
          type: AbilityType.special,
          description: 'Nearby allies gain +50% Attack Speed for 8 seconds.',
          chargeTime: 20.0,
          effectData: {
            'buff_speed': 1.0,
            'duration': 10.0,
            'range': 15.0,
          },
        ),
        const Ability(
          id: 'lightning_strike',
          name: 'Lightning Strike',
          type: AbilityType.special,
          description: 'Strikes the nearest enemy with lightning, dealing 150 damage and stunning them for 4 seconds.',
          chargeTime: 25.0,
        ),
      ],
    );
  }

  static NPC createFlaubert() {
    return NPC.initialButler().copyWith(
      combatStats: const CombatStats(
        attack: 25,
        health: 180,
        maxHealth: 180,
        speed: 1.2,
        movement: 1.0,
        distance: 8.0,
        cost: 4,
        unitType: UnitType.squad,
        unitCount: 3,
        rangedDamage: 30,
        rangedRange: 8.0,
        rangedAttackSpeed: 1.5,
        meleeDamage: 25,
        meleeRange: 1.2,
        meleeAttackSpeed: 1.2,
        radius: 1.5,
      ),
      abilities: [
        const Ability(
          id: 'execute_low_health',
          name: 'Execute',
          type: AbilityType.special,
          description:
              'Instantly kills an enemy unit with less than 50% health.',
          chargeTime: 7.0,
          effectData: {'threshold': 0.5, 'type': 'interrupt_kill'},
        ),
      ],
    );
  }

  static NPC createCannoneer() {
    return NPC(
      id: _generateId('cannoneer'),
      name: 'Cannoneer',
      role: 'Artillery',
      age: 35,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Cannoneer'),
      combatStats: const CombatStats(
        attack: 5,
        health: 250,
        maxHealth: 250,
        speed: 2.0,
        movement: 0.9,
        distance: 21.0,
        cost: 3,
        unitType: UnitType.squad,
        unitCount: 1,
        rangedDamage: 90,
        rangedRange: 21.0,
        rangedAttackSpeed: 3.5,
        meleeDamage: 5,
        meleeRange: 1.0,
        meleeAttackSpeed: 2.0,
        targetingRule: TargetingRule.all,
        radius: 1.8,
      ),
    );
  }

  static NPC createMusketeers() {
    return NPC(
      id: _generateId('musketeers'),
      name: 'Musketeers',
      role: 'Troop',
      age: 28,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Musketeers'),
      combatStats: const CombatStats(
        attack: 25,
        health: 180,
        maxHealth: 180,
        speed: 1.2,
        movement: 1.0,
        distance: 8.0,
        cost: 4,
        unitType: UnitType.squad,
        unitCount: 3,
        rangedDamage: 30,
        rangedRange: 8.0,
        rangedAttackSpeed: 1.5,
        meleeDamage: 25,
        meleeRange: 1.2,
        meleeAttackSpeed: 1.2,
        radius: 1.5,
      ),
    );
  }

  static NPC createCavalry() {
    return NPC(
      id: _generateId('cavalry'),
      name: 'Cavalry',
      role: 'Troop',
      age: 25,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Cavalry'),
      combatStats: const CombatStats(
        attack: 35,
        health: 150,
        maxHealth: 150,
        speed: 1.0,
        movement: 1.8,
        distance: 1.5,
        cost: 5,
        unitType: UnitType.squad,
        unitCount: 3,
        meleeDamage: 35,
        meleeRange: 1.5,
        meleeAttackSpeed: 1.0,
        trait: CombatTrait.fireVulnerable,
        targetingRule: TargetingRule.nonTowers,
        radius: 1.8,
      ),
    );
  }

  static NPC createBicycleGang() {
    return NPC(
      id: _generateId('bicycle_gang'),
      name: 'Bicycle Gang',
      role: 'Troop',
      age: 22,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Bicycle Gang'),
      combatStats: const CombatStats(
        attack: 10,
        health: 130,
        maxHealth: 130,
        speed: 1.0,
        movement: 1.4,
        distance: 6.0,
        cost: 4,
        unitType: UnitType.squad,
        unitCount: 3,
        rangedDamage: 18,
        rangedRange: 6.0,
        rangedAttackSpeed: 1.2,
        meleeDamage: 10,
        meleeRange: 1.0,
        meleeAttackSpeed: 1.0,
        radius: 1.5,
      ),
    );
  }

  static NPC createMotorcycleGang() {
    return NPC(
      id: _generateId('motorcycle_gang'),
      name: 'Motorcycle Gang',
      role: 'Troop',
      age: 24,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Motorcycle Gang'),
      combatStats: const CombatStats(
        attack: 15,
        health: 200,
        maxHealth: 200,
        speed: 0.8,
        movement: 2.2,
        distance: 8.0,
        cost: 5,
        unitType: UnitType.squad,
        unitCount: 2,
        rangedDamage: 30,
        rangedRange: 8.0,
        rangedAttackSpeed: 1.0,
        meleeDamage: 15,
        meleeRange: 1.0,
        meleeAttackSpeed: 0.8,
        deploymentTime: 2.5,
        radius: 1.6,
      ),
    );
  }

  static NPC createArmoredCar() {
    return NPC(
      id: _generateId('armored_car'),
      name: 'Armored Car',
      role: 'Vehicle',
      age: 30,
      gender: 'Female',
      specimenType: 'Machine',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Armored Car'),
      combatStats: const CombatStats(
        attack: 18,
        health: 700,
        maxHealth: 700,
        speed: 0.8,
        movement: 1.2,
        distance: 7.0,
        cost: 6,
        unitType: UnitType.vehicle,
        unitCount: 1,
        rangedDamage: 18,
        rangedRange: 7.0,
        rangedAttackSpeed: 0.8,
        radius: 2.5,
      ),
    );
  }

  static NPC createWoodenTank() {
    return NPC(
      id: _generateId('wooden_tank'),
      name: 'Wooden Tank',
      role: 'Vehicle',
      age: 35,
      gender: 'Male',
      specimenType: 'Machine',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Wooden Tank'),
      combatStats: const CombatStats(
        attack: 110,
        health: 850,
        maxHealth: 850,
        speed: 4.0,
        movement: 0.5,
        distance: 10.0,
        cost: 7,
        unitType: UnitType.vehicle,
        unitCount: 1,
        rangedDamage: 110,
        rangedRange: 10.0,
        rangedAttackSpeed: 4.0,
        trait: CombatTrait.fireVulnerable,
        radius: 3.0,
      ),
    );
  }

  static NPC createUndeadRats() {
    return NPC(
      id: _generateId('undead_rats'),
      name: 'Undead Rats',
      role: 'Swarm',
      age: 1,
      gender: 'N/A',
      specimenType: 'Rat',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Undead Rats'),
      combatStats: const CombatStats(
        attack: 14,
        health: 65,
        maxHealth: 65,
        speed: 0.5,
        movement: 1.2,
        distance: 0.8,
        cost: 3,
        unitType: UnitType.squad,
        unitCount: 4,
        meleeDamage: 14,
        meleeRange: 0.8,
        meleeAttackSpeed: 0.5,
        trait: CombatTrait.constantHeal,
        radius: 1.0,
      ),
      abilities: [
        const Ability(
          id: 'undead_rot',
          name: 'Plague Rot Cloud',
          type: AbilityType.special,
          description: 'Releases a cloud of rotting plague, dealing 40 damage and slowing nearby enemies.',
          chargeTime: 10.0,
        ),
      ],
    );
  }

  static NPC createBrownRats() {
    return NPC(
      id: _generateId('brown_rats'),
      name: 'Brown Rats',
      role: 'Swarm',
      age: 1,
      gender: 'N/A',
      specimenType: 'Rat',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Brown Rats'),
      combatStats: const CombatStats(
        attack: 8,
        health: 45,
        maxHealth: 45,
        speed: 0.4,
        movement: 1.5,
        distance: 0.8,
        cost: 4,
        unitType: UnitType.squad,
        unitCount: 8,
        meleeDamage: 8,
        meleeRange: 0.8,
        meleeAttackSpeed: 0.4,
        trait: CombatTrait.fireVulnerable,
        radius: 0.8,
      ),
    );
  }

  static NPC createWerewolf() {
    return NPC(
      id: _generateId('werewolf'),
      name: 'Werewolf',
      role: 'Beast',
      age: 40,
      gender: 'Male',
      specimenType: 'Beast',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Werewolf'),
      combatStats: const CombatStats(
        attack: 75,
        health: 500,
        maxHealth: 500,
        speed: 0.9,
        movement: 1.6,
        distance: 1.5,
        cost: 5,
        unitType: UnitType.squad,
        unitCount: 1,
        meleeDamage: 75,
        meleeRange: 1.5,
        meleeAttackSpeed: 0.9,
        radius: 1.8,
      ),
      abilities: [
        const Ability(
          id: 'magical_howl',
          name: 'Terrifying Howl',
          type: AbilityType.special,
          description: 'Emits a bloodcurdling howl, stunning nearby enemies for 2.5 seconds.',
          chargeTime: 12.0,
        ),
      ],
    );
  }

  static NPC createChimera() {
    return NPC(
      id: _generateId('chimera'),
      name: 'Chimera',
      role: 'Beast',
      age: 0,
      gender: 'N/A',
      specimenType: 'Beast',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Chimera'),
      combatStats: const CombatStats(
        attack: 40,
        health: 650,
        maxHealth: 650,
        speed: 1.2,
        movement: 0.8,
        distance: 5.0,
        cost: 6,
        unitType: UnitType.squad,
        unitCount: 1,
        rangedDamage: 50,
        rangedRange: 5.0,
        rangedAttackSpeed: 2.0,
        meleeDamage: 40,
        meleeRange: 1.8,
        meleeAttackSpeed: 1.2,
        radius: 2.2,
      ),
      abilities: [
        const Ability(
          id: 'dragon_breath',
          name: 'Dragon Breath',
          type: AbilityType.special,
          description: 'Breathes a cone of fire, dealing 80 damage to enemies in a line.',
          chargeTime: 15.0,
        ),
      ],
    );
  }

  static NPC createFleshGolem() {
    return NPC(
      id: _generateId('flesh_golem'),
      name: 'Flesh Golem',
      role: 'Construct',
      age: 0,
      gender: 'Other',
      specimenType: 'Construct',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Flesh Golem'),
      combatStats: const CombatStats(
        attack: 60,
        health: 550,
        maxHealth: 550,
        speed: 1.4,
        movement: 0.7,
        distance: 1.2,
        cost: 4,
        unitType: UnitType.squad,
        unitCount: 1,
        meleeDamage: 60,
        meleeRange: 1.2,
        meleeAttackSpeed: 1.4,
        trait: CombatTrait.magicImmune,
        radius: 2.0,
      ),
      abilities: [
        const Ability(
          id: 'execute_low_health',
          name: 'Strangle',
          type: AbilityType.special,
          description: 'Approach and kill a nearby enemy with less than 50% health.',
          chargeTime: 12.0,
          effectData: {'threshold': 0.5, 'type': 'interrupt_kill'},
        ),
      ],
    );
  }

  static NPC createVillagerMob() {
    return NPC(
      id: _generateId('villager_mob'),
      name: 'Villager Mob',
      role: 'Troop',
      age: 32,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Villager Mob'),
      combatStats: const CombatStats(
        attack: 15,
        health: 90,
        maxHealth: 90,
        speed: 1.1,
        movement: 0.9,
        distance: 1.0,
        cost: 3,
        unitType: UnitType.squad,
        unitCount: 6,
        meleeDamage: 15,
        meleeRange: 1.0,
        meleeAttackSpeed: 1.1,
        radius: 1.2,
      ),
    );
  }

  static NPC createSamurai() {
    return NPC(
      id: _generateId('samurai'),
      name: 'Samurai',
      role: 'Troop',
      age: 29,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Samurai'),
      combatStats: const CombatStats(
        attack: 45,
        health: 160,
        maxHealth: 160,
        speed: 0.8,
        movement: 1.2,
        distance: 1.2,
        cost: 4,
        unitType: UnitType.squad,
        unitCount: 3,
        meleeDamage: 45,
        meleeRange: 1.2,
        meleeAttackSpeed: 0.8,
        radius: 1.4,
      ),
    );
  }

  static NPC createMercenaries() {
    return NPC(
      id: _generateId('mercenaries'),
      name: 'Mercenaries',
      role: 'Troop',
      age: 30,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Mercenaries'),
      combatStats: const CombatStats(
        attack: 12,
        health: 120,
        maxHealth: 120,
        speed: 1.2,
        movement: 1.0,
        distance: 7.0,
        cost: 4,
        unitType: UnitType.squad,
        unitCount: 4,
        rangedDamage: 20,
        rangedRange: 7.0,
        rangedAttackSpeed: 1.4,
        meleeDamage: 12,
        meleeRange: 1.0,
        meleeAttackSpeed: 1.2,
        radius: 1.4,
      ),
    );
  }

  static NPC createCommandos() {
    return NPC(
      id: _generateId('commandos'),
      name: 'Commandos',
      role: 'Troop',
      age: 27,
      gender: 'Female',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Commandos'),
      combatStats: const CombatStats(
        attack: 35,
        health: 260,
        maxHealth: 260,
        speed: 0.7,
        movement: 1.3,
        distance: 4.0,
        cost: 5,
        unitType: UnitType.squad,
        unitCount: 3,
        rangedDamage: 40,
        rangedRange: 4.0,
        rangedAttackSpeed: 0.7,
        meleeDamage: 35,
        meleeRange: 1.0,
        meleeAttackSpeed: 0.7,
        radius: 1.4,
      ),
    );
  }

  static NPC createSniper() {
    return NPC(
      id: _generateId('sniper'),
      name: 'Sniper',
      role: 'Troop',
      age: 28,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Sniper'),
      combatStats: const CombatStats(
        attack: 5,
        health: 90,
        maxHealth: 90,
        speed: 2.5,
        movement: 0.8,
        distance: 18.0,
        cost: 3,
        unitType: UnitType.squad,
        unitCount: 1,
        rangedDamage: 120,
        rangedRange: 18.0,
        rangedAttackSpeed: 2.5,
        targetingRule: TargetingRule.all,
        meleeDamage: 5,
        meleeRange: 1.0,
        meleeAttackSpeed: 1.0,
        radius: 1.4,
      ),
    );
  }

  static NPC createWildFoxes() {
    return NPC(
      id: _generateId('wild_foxes'),
      name: 'Wild Foxes',
      role: 'Beast',
      age: 2,
      gender: 'N/A',
      specimenType: 'Fox',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Wild Foxes'),
      combatStats: const CombatStats(
        attack: 8,
        health: 45,
        maxHealth: 45,
        speed: 0.4,
        movement: 1.6,
        distance: 0.6,
        cost: 2,
        unitType: UnitType.squad,
        unitCount: 4,
        meleeDamage: 8,
        meleeRange: 0.6,
        meleeAttackSpeed: 0.4,
        trait: CombatTrait.fireVulnerable,
        radius: 0.9,
      ),
    );
  }

  static NPC createWildWolves() {
    return NPC(
      id: _generateId('wild_wolves'),
      name: 'Wild Wolves',
      role: 'Beast',
      age: 4,
      gender: 'N/A',
      specimenType: 'Wolf',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Wild Wolves'),
      combatStats: const CombatStats(
        attack: 20,
        health: 90,
        maxHealth: 90,
        speed: 0.8,
        movement: 1.5,
        distance: 1.0,
        cost: 3,
        unitType: UnitType.squad,
        unitCount: 3,
        meleeDamage: 20,
        meleeRange: 1.0,
        meleeAttackSpeed: 0.8,
        radius: 1.2,
      ),
    );
  }

  static NPC createWildBear() {
    return NPC(
      id: _generateId('wild_bear'),
      name: 'Wild Bear',
      role: 'Beast',
      age: 6,
      gender: 'N/A',
      specimenType: 'Bear',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Wild Bear'),
      combatStats: const CombatStats(
        attack: 55,
        health: 420,
        maxHealth: 420,
        speed: 1.3,
        movement: 0.8,
        distance: 1.4,
        cost: 4,
        unitType: UnitType.squad,
        unitCount: 1,
        meleeDamage: 55,
        meleeRange: 1.4,
        meleeAttackSpeed: 1.3,
        trait: CombatTrait.constantHeal,
        radius: 2.2,
      ),
    );
  }

  static NPC createWildBears() => createWildBear();

  static NPC createBandits() {
    return NPC(
      id: _generateId('bandits'),
      name: 'Bandits',
      role: 'Troop',
      age: 26,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Bandits'),
      combatStats: const CombatStats(
        attack: 15,
        health: 60,
        maxHealth: 60,
        speed: 0.9,
        movement: 1.3,
        distance: 1.0,
        cost: 2,
        unitType: UnitType.squad,
        unitCount: 4,
        meleeDamage: 15,
        meleeRange: 1.0,
        meleeAttackSpeed: 0.9,
        radius: 1.2,
      ),
    );
  }

  static NPC createThugs() {
    return NPC(
      id: _generateId('thugs'),
      name: 'Thugs',
      role: 'Troop',
      age: 30,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Thugs'),
      combatStats: const CombatStats(
        attack: 22,
        health: 130,
        maxHealth: 130,
        speed: 1.2,
        movement: 0.9,
        distance: 1.0,
        cost: 3,
        unitType: UnitType.squad,
        unitCount: 3,
        meleeDamage: 22,
        meleeRange: 1.0,
        meleeAttackSpeed: 1.2,
        radius: 1.4,
      ),
    );
  }

  static NPC createDeserters() {
    return NPC(
      id: _generateId('deserters'),
      name: 'Deserters',
      role: 'Troop',
      age: 24,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Deserters'),
      combatStats: const CombatStats(
        attack: 10,
        health: 80,
        maxHealth: 80,
        speed: 1.2,
        movement: 0.9,
        distance: 7.0,
        cost: 3,
        unitType: UnitType.squad,
        unitCount: 3,
        rangedDamage: 18,
        rangedRange: 7.0,
        rangedAttackSpeed: 1.6,
        meleeDamage: 10,
        meleeRange: 1.0,
        meleeAttackSpeed: 1.2,
        radius: 1.4,
      ),
    );
  }

  static NPC createHalberdiers() {
    return NPC(
      id: _generateId('halberdiers'),
      name: 'Halberdiers',
      role: 'Troop',
      age: 26,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Halberdiers'),
      combatStats: const CombatStats(
        attack: 25,
        health: 110,
        maxHealth: 110,
        speed: 1.1,
        movement: 1.0,
        distance: 1.4,
        cost: 3,
        unitType: UnitType.squad,
        unitCount: 3,
        meleeDamage: 25,
        meleeRange: 1.4,
        meleeAttackSpeed: 1.1,
        targetingRule: TargetingRule.nonTowers,
        radius: 1.4,
      ),
    );
  }

  static NPC createPikemen() {
    return NPC(
      id: _generateId('pikemen'),
      name: 'Pikemen',
      role: 'Troop',
      age: 25,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Pikemen'),
      combatStats: const CombatStats(
        attack: 20,
        health: 105,
        maxHealth: 105,
        speed: 0.6,
        movement: 0.8,
        distance: 2.2,
        cost: 3,
        unitType: UnitType.squad,
        unitCount: 4,
        meleeDamage: 20,
        meleeRange: 2.2,
        meleeAttackSpeed: 0.6,
        radius: 1.4,
      ),
    );
  }

  static NPC createPolicemen() {
    return NPC(
      id: _generateId('policemen'),
      name: 'Policemen',
      role: 'Troop',
      age: 31,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Policemen'),
      combatStats: const CombatStats(
        attack: 15,
        health: 150,
        maxHealth: 150,
        speed: 1.0,
        movement: 1.0,
        distance: 5.0,
        cost: 4,
        unitType: UnitType.squad,
        unitCount: 2,
        rangedDamage: 25,
        rangedRange: 5.0,
        rangedAttackSpeed: 1.5,
        meleeDamage: 15,
        meleeRange: 1.0,
        meleeAttackSpeed: 1.0,
        radius: 1.4,
      ),
    );
  }

  static NPC createMarksmen() {
    return NPC(
      id: _generateId('marksmen'),
      name: 'Marksmen',
      role: 'Troop',
      age: 28,
      gender: 'Female',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Marksmen'),
      combatStats: const CombatStats(
        attack: 0,
        health: 100,
        maxHealth: 100,
        speed: 1.5,
        movement: 1.0,
        distance: 10.0,
        cost: 3,
        unitType: UnitType.squad,
        unitCount: 2,
        rangedDamage: 35,
        rangedRange: 10.0,
        rangedAttackSpeed: 1.5,
        targetingRule: TargetingRule.squadsOnly,
        radius: 1.4,
      ),
    );
  }

  static NPC createArtilleryBarrage() {
    return NPC(
      id: _generateId('artillery_barrage'),
      name: 'Artillery Barrage',
      role: 'Support',
      age: 0,
      gender: 'N/A',
      specimenType: 'Tactical',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Artillery Barrage'),
      combatStats: const CombatStats(
        attack: 0,
        health: 0,
        maxHealth: 0,
        speed: 0,
        movement: 0,
        distance: 0,
        cost: 5,
        unitType: UnitType.support,
        unitCount: 0,
        deploymentTime: 3.0,
      ),
      abilities: [
        const Ability(
          id: 'artillery_barrage_effect',
          name: 'Artillery Barrage',
          type: AbilityType.special,
          description: 'Deals 80 DPS in a long lane-width rectangle for 4 seconds.',
        ),
      ],
    );
  }

  static NPC createTearGasGrenade() {
    return NPC(
      id: _generateId('tear_gas_grenade'),
      name: 'Tear Gas Grenade',
      role: 'Support',
      age: 0,
      gender: 'N/A',
      specimenType: 'Tactical',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Tear Gas Grenade'),
      combatStats: const CombatStats(
        attack: 0,
        health: 0,
        maxHealth: 0,
        speed: 0,
        movement: 0,
        distance: 0,
        cost: 3,
        unitType: UnitType.support,
        unitCount: 0,
        deploymentTime: 1.5,
      ),
      abilities: [
        const Ability(
          id: 'tear_gas_effect',
          name: 'Tear Gas Grenade',
          type: AbilityType.special,
          description:
              'Slows enemies by 60% and deals 15 DPS in a circular area for 6 seconds.',
        ),
      ],
    );
  }

  static NPC createCaltrops() {
    return NPC(
      id: _generateId('caltrops'),
      name: 'Caltrops',
      role: 'Support',
      age: 0,
      gender: 'N/A',
      specimenType: 'Tactical',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Caltrops'),
      combatStats: const CombatStats(
        attack: 0,
        health: 0,
        maxHealth: 0,
        speed: 0,
        movement: 0,
        distance: 0,
        cost: 3,
        unitType: UnitType.support,
        unitCount: 0,
      ),
      abilities: [
        const Ability(
          id: 'caltrops_effect',
          name: 'Caltrops',
          type: AbilityType.special,
          description: 'Damages and slows enemies stepping over it. 2.5x damage to vehicles. Lasts 60 seconds.',
        ),
      ],
    );
  }

  static NPC createVampiricTotem() {
    return NPC(
      id: _generateId('vampiric_totem'),
      name: 'Vampiric Totem',
      role: 'Support',
      age: 0,
      gender: 'N/A',
      specimenType: 'Tactical',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Vampiric Totem'),
      combatStats: const CombatStats(
        attack: 0,
        health: 150,
        maxHealth: 150,
        speed: 0,
        movement: 0,
        distance: 0,
        cost: 4,
        unitType: UnitType.support,
        unitCount: 0,
      ),
      abilities: [
        const Ability(
          id: 'totem_effect',
          name: 'Vampiric Totem',
          type: AbilityType.special,
          description: 'Drains 12 HP/sec from nearby enemies, transferring it to heal active allies. Lasts 60 seconds.',
        ),
      ],
    );
  }

  static List<BodyPart> _defaultBodyParts() {
    return [
      BodyPart(type: BodyPartType.head, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.torso, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.rightArm, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.leftArm, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.rightLeg, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.leftLeg, health: 100, maxHealth: 100),
    ];
  }

  // Backwards-Compatible Squad Fallback Methods
  static NPC createFootman() {
    final v = createVillagerMob();
    return v.copyWith(
      id: _generateId('footman'),
      name: 'Footman',
      combatStats: v.combatStats?.copyWith(unitCount: 5),
    );
  }

  static NPC createGoons() {
    final t = createThugs();
    return t.copyWith(
      id: _generateId('goons'),
      name: 'Goons',
      combatStats: t.combatStats?.copyWith(
        movement: 1.1,
        cost: 2,
      ),
    );
  }

  static NPC createGoon() => createGoons();

  static NPC createMilitia() {
    final h = createHalberdiers();
    return h.copyWith(
      id: _generateId('militia'),
      name: 'Militia',
      combatStats: h.combatStats?.copyWith(
        distance: 12.0,
        rangedDamage: 18,
        rangedRange: 12.0,
        rangedAttackSpeed: 1.5,
      ),
    );
  }
  static NPC createBanditCaptain() => createThugs().copyWith(name: 'Bandit Captain');
  static NPC createFleshHound() => createWildWolves().copyWith(
    name: 'Flesh Hound',
    abilities: [
      const Ability(
        id: 'magical_howl',
        name: 'Terrifying Howl',
        type: AbilityType.special,
        description: 'Emits a bloodcurdling howl, stunning nearby enemies for 2.5 seconds.',
        chargeTime: 12.0,
      ),
    ],
  );
  static NPC createBatsUnit() => createWildFoxes().copyWith(
    name: 'Bats Unit',
    abilities: [
      const Ability(
        id: 'undead_rot',
        name: 'Plague Rot Cloud',
        type: AbilityType.special,
        description: 'Releases a cloud of rotting plague, dealing 40 damage and slowing nearby enemies.',
        chargeTime: 10.0,
      ),
    ],
  );
  static NPC createWingedRat() => createWildFoxes().copyWith(
    name: 'Winged Rat',
    abilities: [
      const Ability(
        id: 'undead_rot',
        name: 'Plague Rot Cloud',
        type: AbilityType.special,
        description: 'Releases a cloud of rotting plague, dealing 40 damage and slowing nearby enemies.',
        chargeTime: 10.0,
      ),
    ],
  );
  static NPC createBully() => createThugs().copyWith(name: 'Bully');
  static NPC createStitchedHorror() => createFleshGolem().copyWith(name: 'Stitched Horror');
  static NPC createGalvanizedCorpse() => createFleshGolem().copyWith(name: 'Galvanized Corpse');
  static NPC createChemicalSlinger() => createMarksmen().copyWith(name: 'Chemical Slinger');
  static NPC createShadowCreeper() => createThugs().copyWith(
    name: 'Shadow Creeper',
    abilities: [
      const Ability(
        id: 'undead_rot',
        name: 'Plague Rot Cloud',
        type: AbilityType.special,
        description: 'Releases a cloud of rotting plague, dealing 40 damage and slowing nearby enemies.',
        chargeTime: 10.0,
      ),
    ],
  );
  static NPC createGravedigger() => createThugs().copyWith(
    name: 'Gravedigger',
    abilities: [
      const Ability(
        id: 'undead_rot',
        name: 'Plague Rot Cloud',
        type: AbilityType.special,
        description: 'Releases a cloud of rotting plague, dealing 40 damage and slowing nearby enemies.',
        chargeTime: 10.0,
      ),
    ],
  );
  static NPC createPlagueMonk() => createThugs().copyWith(
    name: 'Plague Monk',
    abilities: [
      const Ability(
        id: 'undead_rot',
        name: 'Plague Rot Cloud',
        type: AbilityType.special,
        description: 'Releases a cloud of rotting plague, dealing 40 damage and slowing nearby enemies.',
        chargeTime: 10.0,
      ),
    ],
  );
  static NPC createInquisitor() => createMarksmen().copyWith(name: 'Inquisitor');
  static NPC createIronMaiden() => createFleshGolem().copyWith(name: 'Iron Maiden');
  static NPC createAlchemicalGolem() => createFleshGolem().copyWith(name: 'Alchemical Golem');

  // AI Boss Generals for Arena Campaigns and Tournaments
  static NPC createBossRudolf() {
    return NPC(
      id: 'boss_rudolf',
      name: 'General Rudolf',
      role: 'Warlord',
      age: 48,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('General Rudolf'),
      combatStats: const CombatStats(
        attack: 40,
        health: 500,
        maxHealth: 500,
        speed: 0.8,
        movement: 0.9,
        distance: 1.5,
        defense: 10,
        accuracy: 0.9,
        cost: 0,
        unitType: UnitType.squad,
        unitCount: 1,
        meleeDamage: 40,
        meleeRange: 1.5,
        meleeAttackSpeed: 0.8,
      ),
      abilities: [
        const Ability(
          id: 'shield_wall',
          name: 'Shield Wall',
          type: AbilityType.special,
          description: 'Rudolf and nearby allies gain +20 Defense for 8 seconds.',
          chargeTime: 15.0,
        ),
        const Ability(
          id: 'battle_cry',
          name: 'Battle Cry',
          type: AbilityType.special,
          description: 'Rudolf rallies his troops, increasing their Attack by +15 for 6 seconds.',
          chargeTime: 22.0,
        ),
      ],
    );
  }

  static NPC createBossGearbox() {
    return NPC(
      id: 'boss_gearbox',
      name: 'Baron von Gearbox',
      role: 'Engineer',
      age: 52,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Baron von Gearbox'),
      combatStats: const CombatStats(
        attack: 25,
        health: 280,
        maxHealth: 280,
        speed: 1.2,
        movement: 1.0,
        distance: 10.0,
        defense: 2,
        accuracy: 0.88,
        cost: 0,
        unitType: UnitType.squad,
        unitCount: 1,
        rangedDamage: 25,
        rangedRange: 10.0,
        rangedAttackSpeed: 1.2,
      ),
      abilities: [
        const Ability(
          id: 'overclock',
          name: 'Overclock',
          type: AbilityType.special,
          description: 'All clockwork units on the field gain +60% Attack Speed for 10 seconds.',
          chargeTime: 18.0,
        ),
        const Ability(
          id: 'tesla_discharge',
          name: 'Tesla Discharge',
          type: AbilityType.special,
          description: 'Discharges electric current, dealing 40 damage and stunning nearby enemies for 2 seconds.',
          chargeTime: 25.0,
        ),
      ],
    );
  }

  static NPC createBossElizabeth() {
    return NPC(
      id: 'boss_elizabeth',
      name: 'Lady Elizabeth',
      role: 'Vampire',
      age: 200,
      gender: 'Female',
      specimenType: 'Undead',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Lady Elizabeth'),
      combatStats: const CombatStats(
        attack: 45,
        health: 320,
        maxHealth: 320,
        speed: 1.3,
        movement: 1.2,
        distance: 1.2,
        defense: 0,
        accuracy: 0.92,
        cost: 0,
        unitType: UnitType.squad,
        unitCount: 1,
        meleeDamage: 45,
        meleeRange: 1.2,
        meleeAttackSpeed: 1.3,
      ),
      abilities: [
        const Ability(
          id: 'vampiric_mist',
          name: 'Vampiric Mist',
          type: AbilityType.special,
          description: 'Elizabeth recovers HP equal to 50% of damage dealt by her and her allies for 10 seconds.',
          chargeTime: 16.0,
        ),
        const Ability(
          id: 'bat_swarm',
          name: 'Bat Swarm',
          type: AbilityType.special,
          description: 'Summons a swarm of bats that deals 15 damage per second and slows enemies by 30% for 6 seconds.',
          chargeTime: 20.0,
        ),
      ],
    );
  }

  static NPC createBossThorne() {
    return NPC(
      id: 'boss_thorne',
      name: 'Keeper Thorne',
      role: 'Ranger',
      age: 38,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Keeper Thorne'),
      combatStats: const CombatStats(
        attack: 30,
        health: 260,
        maxHealth: 260,
        speed: 1.1,
        movement: 1.1,
        distance: 9.0,
        defense: 1,
        accuracy: 0.95,
        cost: 0,
        unitType: UnitType.squad,
        unitCount: 1,
        rangedDamage: 30,
        rangedRange: 9.0,
        rangedAttackSpeed: 1.1,
      ),
      abilities: [
        const Ability(
          id: 'entangling_roots',
          name: 'Entangling Roots',
          type: AbilityType.special,
          description: 'Roots entangle and slow the player hero by 70% for 5 seconds.',
          chargeTime: 14.0,
        ),
        const Ability(
          id: 'feral_howl',
          name: 'Feral Howl',
          type: AbilityType.special,
          description: 'Summons a spectral wolf and increases speed of all beast units by +40% for 8 seconds.',
          chargeTime: 24.0,
        ),
      ],
    );
  }

  static NPC createBats() {
    return NPC(
      id: 'bats_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Bats',
      specimenType: 'Beast',
      role: 'Creature',
      age: 2,
      gender: 'Unknown',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Bats'),
      combatStats: const CombatStats(
        attack: 25,
        health: 220,
        maxHealth: 220,
        speed: 1.1,
        movement: 6.4,
        distance: 1.5,
        cost: 2,
        isFlying: true,
        unitType: UnitType.squad,
        unitCount: 3,
        meleeDamage: 25,
        meleeRange: 1.5,
        meleeAttackSpeed: 1.1,
      ),
    );
  }

  static NPC createStampede() {
    return NPC(
      id: 'stampede_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Stampede',
      specimenType: 'Beast',
      role: 'Support',
      age: 4,
      gender: 'Unknown',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Stampede'),
      combatStats: const CombatStats(
        attack: 85,
        health: 350,
        maxHealth: 350,
        speed: 1.0,
        movement: 8.0,
        distance: 1.5,
        cost: 3,
        isFlying: false,
        unitType: UnitType.support,
        unitCount: 5,
        meleeDamage: 85,
        meleeRange: 1.5,
        meleeAttackSpeed: 1.0,
      ),
    );
  }

  static NPC createBrewers() {
    return NPC(
      id: _generateId('brewers'),
      name: 'Brewers',
      role: 'Coven',
      age: 32,
      gender: 'Female',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Brewers').copyWith(
        outfitColor: const Color(0xFF181818), // Black torso
        hairColor: const Color(0xFF222222),
      ),
      equippedVisuals: const ['Broom', 'WitchHat'],
      combatStats: const CombatStats(
        attack: 30,
        health: 220,
        maxHealth: 220,
        speed: 0.9,
        movement: 0.8,
        distance: 1.2,
        cost: 3,
        unitType: UnitType.squad,
        unitCount: 3,
        meleeDamage: 30,
        meleeRange: 1.2,
        meleeAttackSpeed: 0.9,
        radius: 1.3,
      ),
      abilities: const [
        Ability(
          id: 'brewers_persistent_heal',
          name: 'Coven Brew',
          type: AbilityType.trait,
          description:
              'Persistently heals herself and friendly units within 2 ft by 2 HP every 0.5 seconds (12 HP/s total when grouped).',
        ),
      ],
    );
  }

  static NPC createHag() {
    return NPC(
      id: _generateId('hag'),
      name: 'Hag',
      role: 'Coven',
      age: 68,
      gender: 'Female',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Hag').copyWith(
        outfitColor: const Color(0xFF5A1827), // Dark burgundy color
        bodyType: BodyType.heavy, // Oversize body & corpulent torso
      ),
      equippedVisuals: const ['Broom', 'WitchHat'],
      combatStats: const CombatStats(
        attack: 45,
        health: 650,
        maxHealth: 650,
        speed: 0.7,
        movement: 0.8,
        distance: 1.2,
        cost: 4,
        unitType: UnitType.squad,
        unitCount: 1,
        meleeDamage: 45,
        meleeRange: 1.2,
        meleeAttackSpeed: 0.7,
        radius: 1.6,
      ),
      abilities: const [
        Ability(
          id: 'hag_persistent_heal',
          name: 'Hag Vitality',
          type: AbilityType.trait,
          description:
              'Heals friendly units within 3 ft (but not herself) by 5 HP every 0.5 seconds (10 HP/s total).',
        ),
      ],
    );
  }

  static NPC createWitch() {
    return NPC(
      id: _generateId('witch'),
      name: 'Witch',
      role: 'Coven',
      age: 29,
      gender: 'Female',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Witch').copyWith(
        outfitColor: const Color(0xFF616161), // Gray torso
      ),
      equippedVisuals: const ['Sling', 'WitchHat'],
      combatStats: const CombatStats(
        attack: 35,
        health: 280,
        maxHealth: 280,
        speed: 0.8,
        movement: 0.8,
        distance: 10.0,
        cost: 3,
        unitType: UnitType.squad,
        unitCount: 1,
        rangedDamage: 35,
        rangedRange: 10.0,
        rangedAttackSpeed: 0.8, // High rate of fire sling
        radius: 1.3,
      ),
      abilities: const [
        Ability(
          id: 'witch_charge_heal',
          name: 'Coven Restoration',
          type: AbilityType.special,
          description:
              'Heals the 4 closest friendly units within 4.5 ft by 50 health each.',
          chargeTime: 12.0,
        ),
      ],
    );
  }

  static NPC createWarlock() {
    return NPC(
      id: _generateId('warlock'),
      name: 'Warlock',
      role: 'Coven',
      age: 54,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Warlock').copyWith(
        outfitColor: const Color(0xFF4A1C40), // Dark plum hat and torso
        bodyType: BodyType.muscular, // Less curved, masculine torso
        facialHairStyle: FacialHairStyle.beard, // Long beard
      ),
      equippedVisuals: const ['Crossbow', 'PlumHat'],
      combatStats: const CombatStats(
        attack: 95,
        health: 300,
        maxHealth: 300,
        speed: 2.8,
        movement: 0.8,
        distance: 15.0, // Crossbow better range than sling
        cost: 3,
        unitType: UnitType.squad,
        unitCount: 1,
        rangedDamage: 95, // Much more powerful per hit
        rangedRange: 15.0,
        rangedAttackSpeed: 2.8, // Very slow rate of fire
        radius: 1.4,
      ),
      abilities: const [
        Ability(
          id: 'warlock_lightning',
          name: 'Lightning Strike',
          type: AbilityType.special,
          description:
              'Strikes the nearest enemy for 150 damage and stuns them for 4 seconds.',
          chargeTime: 15.0,
        ),
      ],
    );
  }

  static NPC createGatlingGun() {
    return NPC(
      id: _generateId('gatling_gun'),
      name: 'Gatling Gun',
      role: 'Weapon',
      age: 35,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('GatlingGun'),
      equippedVisuals: const ['GatlingGun'],
      combatStats: const CombatStats(
        attack: 15,
        health: 200,
        maxHealth: 200,
        speed: 0.15,
        movement: 0.8,
        distance: 9.0, // 9 ft range
        cost: 4,
        unitType: UnitType.squad,
        unitCount: 1,
        rangedDamage: 15,
        rangedRange: 9.0,
        rangedAttackSpeed: 0.15, // Very high rate of fire once firing
        radius: 1.5,
      ),
    );
  }

  static NPC createZeppelin() {
    return NPC(
      id: _generateId('zeppelin'),
      name: 'Zeppelin',
      role: 'Airship',
      age: 50,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Zeppelin'),
      equippedVisuals: const ['Zeppelin'],
      combatStats: const CombatStats(
        attack: 90,
        health: 540,
        maxHealth: 540,
        speed: 2.0,
        movement: 0.4,
        distance: 4.0,
        cost: 7,
        unitType: UnitType.squad,
        unitCount: 1,
        rangedDamage: 90,
        rangedRange: 4.0,
        rangedAttackSpeed: 2.0,
        radius: 2.5,
        isFlying: true,
      ),
    );
  }

  static NPC createValkyrie() {
    return NPC(
      id: _generateId('valkyrie'),
      name: 'Valkyrie',
      role: 'Air',
      age: 25,
      gender: 'Female',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Valkyrie'),
      equippedVisuals: const ['Spear'],
      combatStats: const CombatStats(
        attack: 38,
        health: 280,
        maxHealth: 280,
        speed: 1.0,
        movement: 1.5,
        distance: 1.5,
        cost: 4,
        unitType: UnitType.squad,
        unitCount: 1,
        meleeDamage: 38,
        meleeRange: 1.5,
        meleeAttackSpeed: 1.0,
        radius: 1.4,
        isFlying: true,
      ),
    );
  }

  static NPC createMinotaur() {
    return NPC(
      id: _generateId('minotaur'),
      name: 'Minotaur',
      role: 'Charger',
      age: 34,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Minotaur'),
      equippedVisuals: const ['Axe'],
      combatStats: const CombatStats(
        attack: 65,
        health: 520,
        maxHealth: 520,
        speed: 1.2,
        movement: 1.3,
        distance: 1.5,
        cost: 6,
        unitType: UnitType.squad,
        unitCount: 1,
        meleeDamage: 65,
        meleeRange: 1.5,
        meleeAttackSpeed: 1.2,
        radius: 1.6,
      ),
      abilities: const [
        Ability(
          id: 'minotaur_charge',
          name: 'Bull Charge',
          type: AbilityType.charge,
          description:
              'Charges the nearest enemy at high speed dealing 100 collision damage.',
          chargeTime: 10.0,
        ),
      ],
    );
  }

  static NPC createPhoenix() {
    return NPC(
      id: _generateId('phoenix'),
      name: 'Phoenix',
      role: 'Air',
      age: 100,
      gender: 'Female',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Phoenix'),
      combatStats: const CombatStats(
        attack: 42,
        health: 360,
        maxHealth: 360,
        speed: 1.1,
        movement: 1.4,
        distance: 8.0,
        cost: 5,
        unitType: UnitType.squad,
        unitCount: 1,
        rangedDamage: 42,
        rangedRange: 8.0,
        rangedAttackSpeed: 1.1,
        radius: 1.5,
        isFlying: true,
      ),
    );
  }

  static NPC createNecromancer() {
    return NPC(
      id: _generateId('necromancer'),
      name: 'Necromancer',
      role: 'Coven',
      age: 65,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Necromancer'),
      equippedVisuals: const ['SkullStaff'],
      combatStats: const CombatStats(
        attack: 28,
        health: 240,
        maxHealth: 240,
        speed: 1.4,
        movement: 0.8,
        distance: 12.0,
        cost: 4,
        unitType: UnitType.squad,
        unitCount: 1,
        rangedDamage: 28,
        rangedRange: 12.0,
        rangedAttackSpeed: 1.4,
        radius: 1.3,
      ),
    );
  }

  static NPC createBatteringRam() {
    return NPC(
      id: _generateId('battering_ram'),
      name: 'Battering Ram',
      role: 'Siege',
      age: 20,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('BatteringRam'),
      combatStats: const CombatStats(
        attack: 85,
        health: 480,
        maxHealth: 480,
        speed: 1.8,
        movement: 0.6,
        distance: 1.6,
        cost: 4,
        unitType: UnitType.squad,
        unitCount: 1,
        meleeDamage: 85,
        meleeRange: 1.6,
        meleeAttackSpeed: 1.8,
        radius: 1.8,
      ),
    );
  }

  static NPC createSteampunkRobot() {
    return NPC(
      id: _generateId('steampunk_robot'),
      name: 'Steampunk Robot',
      role: 'Behemoth',
      age: 40,
      gender: 'None',
      specimenType: 'Machine',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('SteampunkRobot'),
      combatStats: const CombatStats(
        attack: 80,
        health: 750,
        maxHealth: 750,
        speed: 1.6,
        movement: 0.6,
        distance: 2.0,
        cost: 7,
        unitType: UnitType.squad,
        unitCount: 1,
        meleeDamage: 80,
        meleeRange: 2.0,
        meleeAttackSpeed: 1.6,
        radius: 2.0,
      ),
    );
  }

  static NPC createSteampunkMech() {
    return NPC(
      id: _generateId('steampunk_mech'),
      name: 'Steampunk Mech',
      role: 'Behemoth',
      age: 35,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('SteampunkMech'),
      combatStats: const CombatStats(
        attack: 85,
        health: 700,
        maxHealth: 700,
        speed: 1.5,
        movement: 0.8,
        distance: 2.0,
        cost: 6,
        unitType: UnitType.squad,
        unitCount: 1,
        meleeDamage: 85,
        meleeRange: 2.0,
        meleeAttackSpeed: 1.5,
        radius: 2.0,
      ),
    );
  }

  static NPC createPoisonGas() {
    return NPC(
      id: _generateId('poison_gas'),
      name: 'Poison Gas Cloud',
      role: 'Support',
      age: 1,
      gender: 'None',
      specimenType: 'Support',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('PoisonGas'),
      combatStats: const CombatStats(
        attack: 25,
        health: 0,
        maxHealth: 0,
        speed: 1.0,
        movement: 0.0,
        distance: 15.0,
        cost: 3,
        unitType: UnitType.support,
      ),
    );
  }

  static NPC createLightningStorm() {
    return NPC(
      id: _generateId('lightning_storm'),
      name: 'Lightning Storm',
      role: 'Support',
      age: 1,
      gender: 'None',
      specimenType: 'Support',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('LightningStorm'),
      combatStats: const CombatStats(
        attack: 40,
        health: 0,
        maxHealth: 0,
        speed: 1.0,
        movement: 0.0,
        distance: 15.0,
        cost: 4,
        unitType: UnitType.support,
      ),
    );
  }

  static NPC createAirdrop() {
    return NPC(
      id: _generateId('airdrop'),
      name: 'Reinforcement Airdrop',
      role: 'Support',
      age: 1,
      gender: 'None',
      specimenType: 'Support',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('Airdrop'),
      combatStats: const CombatStats(
        attack: 0,
        health: 0,
        maxHealth: 0,
        speed: 1.0,
        movement: 0.0,
        distance: 15.0,
        cost: 3,
        unitType: UnitType.support,
      ),
    );
  }

  static NPC createDivineShield() {
    return NPC(
      id: _generateId('divine_shield'),
      name: 'Divine Shield',
      role: 'Support',
      age: 1,
      gender: 'None',
      specimenType: 'Support',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('DivineShield'),
      combatStats: const CombatStats(
        attack: 0,
        health: 0,
        maxHealth: 0,
        speed: 1.0,
        movement: 0.0,
        distance: 15.0,
        cost: 2,
        unitType: UnitType.support,
      ),
    );
  }

  static NPC createNapalmStrike() {
    return NPC(
      id: _generateId('napalm_strike'),
      name: 'Napalm Strike',
      role: 'Support',
      age: 1,
      gender: 'None',
      specimenType: 'Support',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.deterministic('NapalmStrike'),
      combatStats: const CombatStats(
        attack: 60,
        health: 0,
        maxHealth: 0,
        speed: 1.0,
        movement: 0.0,
        distance: 15.0,
        cost: 4,
        unitType: UnitType.support,
      ),
    );
  }
}

