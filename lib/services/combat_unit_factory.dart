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
import '../models/npc.dart';
import '../models/combat_stats.dart';
import '../models/schedule.dart';
import '../models/diet.dart';
import '../models/body_part.dart';

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
      appearance: NPCAppearance.random(),
      combatStats: const CombatStats(
        attack: 5,
        health: 250,
        maxHealth: 250,
        speed: 2.0,
        movement: 0.6,
        distance: 15.0,
        cost: 3,
        unitType: UnitType.squad,
        unitCount: 1,
        rangedDamage: 90,
        rangedRange: 15.0,
        rangedAttackSpeed: 3.5,
        meleeDamage: 5,
        meleeRange: 1.0,
        meleeAttackSpeed: 2.0,
        targetingRule: TargetingRule.towersOnly,
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
      appearance: NPCAppearance.random(),
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
      appearance: NPCAppearance.random(),
      combatStats: const CombatStats(
        attack: 45,
        health: 220,
        maxHealth: 220,
        speed: 1.0,
        movement: 1.8,
        distance: 1.5,
        cost: 5,
        unitType: UnitType.squad,
        unitCount: 3,
        meleeDamage: 45,
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
      appearance: NPCAppearance.random(),
      combatStats: const CombatStats(
        attack: 10,
        health: 110,
        maxHealth: 110,
        speed: 1.0,
        movement: 1.4,
        distance: 6.0,
        cost: 4,
        unitType: UnitType.squad,
        unitCount: 3,
        rangedDamage: 15,
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
      appearance: NPCAppearance.random(),
      combatStats: const CombatStats(
        attack: 15,
        health: 165,
        maxHealth: 165,
        speed: 0.8,
        movement: 2.2,
        distance: 8.0,
        cost: 5,
        unitType: UnitType.squad,
        unitCount: 2,
        rangedDamage: 20,
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
      appearance: NPCAppearance.random(),
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
      appearance: NPCAppearance.random(),
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
      appearance: NPCAppearance.random(),
      combatStats: const CombatStats(
        attack: 12,
        health: 65,
        maxHealth: 65,
        speed: 0.5,
        movement: 1.2,
        distance: 0.8,
        cost: 3,
        unitType: UnitType.squad,
        unitCount: 4,
        meleeDamage: 12,
        meleeRange: 0.8,
        meleeAttackSpeed: 0.5,
        trait: CombatTrait.constantHeal,
        radius: 1.0,
      ),
    );
  }

  static NPC createRats2() {
    return NPC(
      id: _generateId('rats_2'),
      name: 'Rats 2',
      role: 'Swarm',
      age: 1,
      gender: 'N/A',
      specimenType: 'Rat',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random(),
      combatStats: const CombatStats(
        attack: 8,
        health: 45,
        maxHealth: 45,
        speed: 0.4,
        movement: 1.5,
        distance: 0.8,
        cost: 6,
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
      appearance: NPCAppearance.random(),
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
      appearance: NPCAppearance.random(),
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
      appearance: NPCAppearance.random(),
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
      appearance: NPCAppearance.random(),
      combatStats: const CombatStats(
        attack: 15,
        health: 90,
        maxHealth: 90,
        speed: 1.1,
        movement: 0.9,
        distance: 1.0,
        cost: 3,
        unitType: UnitType.squad,
        unitCount: 5,
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
      appearance: NPCAppearance.random(),
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
      appearance: NPCAppearance.random(),
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
      appearance: NPCAppearance.random(),
      combatStats: const CombatStats(
        attack: 35,
        health: 150,
        maxHealth: 150,
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
      appearance: NPCAppearance.random(),
      combatStats: const CombatStats(
        attack: 0,
        health: 90,
        maxHealth: 90,
        speed: 3.0,
        movement: 0.8,
        distance: 18.0,
        cost: 3,
        unitType: UnitType.squad,
        unitCount: 1,
        rangedDamage: 85,
        rangedRange: 18.0,
        rangedAttackSpeed: 3.0,
        targetingRule: TargetingRule.nonTowers,
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
      appearance: NPCAppearance.random(),
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
      appearance: NPCAppearance.random(),
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

  static NPC createWildBears() {
    return NPC(
      id: _generateId('wild_bears'),
      name: 'Wild Bears',
      role: 'Beast',
      age: 6,
      gender: 'N/A',
      specimenType: 'Bear',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random(),
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
      appearance: NPCAppearance.random(),
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
      appearance: NPCAppearance.random(),
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
      appearance: NPCAppearance.random(),
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
      appearance: NPCAppearance.random(),
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
      appearance: NPCAppearance.random(),
      combatStats: const CombatStats(
        attack: 20,
        health: 105,
        maxHealth: 105,
        speed: 1.3,
        movement: 0.8,
        distance: 1.6,
        cost: 3,
        unitType: UnitType.squad,
        unitCount: 3,
        meleeDamage: 20,
        meleeRange: 1.6,
        meleeAttackSpeed: 1.3,
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
      appearance: NPCAppearance.random(),
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
      appearance: NPCAppearance.random(),
      combatStats: const CombatStats(
        attack: 0,
        health: 85,
        maxHealth: 85,
        speed: 2.0,
        movement: 0.9,
        distance: 10.0,
        cost: 3,
        unitType: UnitType.squad,
        unitCount: 2,
        rangedDamage: 35,
        rangedRange: 10.0,
        rangedAttackSpeed: 2.0,
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
      appearance: NPCAppearance.random(),
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
      appearance: NPCAppearance.random(),
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
          id: 'tear_gas_effect',
          name: 'Tear Gas Grenade',
          type: AbilityType.special,
          description: 'Slows enemies by 60% and deals 15 DPS in a circular area for 8 seconds.',
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
      appearance: NPCAppearance.random(),
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
      appearance: NPCAppearance.random(),
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
  static NPC createGoon() => createThugs().copyWith(name: 'Goon');
  static NPC createMilitia() => createHalberdiers().copyWith(name: 'Militia');
  static NPC createBanditCaptain() => createThugs().copyWith(name: 'Bandit Captain');
  static NPC createFleshHound() => createWildWolves().copyWith(name: 'Flesh Hound');
  static NPC createRatsUnit() => createUndeadRats().copyWith(name: 'Rats Unit');
  static NPC createBatsUnit() => createWildFoxes().copyWith(name: 'Bats Unit');
  static NPC createWingedRat() => createWildFoxes().copyWith(name: 'Winged Rat');
  static NPC createBully() => createThugs().copyWith(name: 'Bully');
  static NPC createStitchedHorror() => createFleshGolem().copyWith(name: 'Stitched Horror');
  static NPC createGalvanizedCorpse() => createFleshGolem().copyWith(name: 'Galvanized Corpse');
  static NPC createChemicalSlinger() => createMarksmen().copyWith(name: 'Chemical Slinger');
  static NPC createShadowCreeper() => createThugs().copyWith(name: 'Shadow Creeper');
  static NPC createGravedigger() => createThugs().copyWith(name: 'Gravedigger');
  static NPC createPlagueMonk() => createThugs().copyWith(name: 'Plague Monk');
  static NPC createInquisitor() => createMarksmen().copyWith(name: 'Inquisitor');
  static NPC createIronMaiden() => createFleshGolem().copyWith(name: 'Iron Maiden');
  static NPC createAlchemicalGolem() => createFleshGolem().copyWith(name: 'Alchemical Golem');
}
