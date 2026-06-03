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

import 'package:flutter/foundation.dart';

enum AbilityType { horn, special, trait, knell }

enum UnitType { squad, vehicle, support }

enum TargetingRule {
  all,
  towersOnly,
  enemyCharacterOnly,
  squadsOnly,
  vehiclesOnly,
  nonTowers,
}

enum CombatTrait {
  none,
  magicImmune,
  fireVulnerable,
  constantHeal,
}

enum DeathknellEffect {
  none,
  explosion,
  mindControl,
}

enum BattlehornEffect {
  none,
  charge,
  heal,
}

@immutable
class CombatStats {
  final double attack;
  final double health;
  final double maxHealth;
  final double speed; // seconds per attack
  final double movement; // meters per second
  final double distance; // attack range
  final double defense;
  final double accuracy;
  final int cost; // AP cost to summon
  final bool isFlying;
  final int swarmSize; // 0 if single unit, >0 for swarms
  final double radius; // Physics radius for collision
  final String? damageFormula; // e.g. "4d6+2"

  // Regiment Overhaul Fields
  final UnitType unitType;
  final int unitCount;
  final double rangedDamage;
  final double rangedRange;
  final double rangedAttackSpeed;
  final double meleeDamage;
  final double meleeRange;
  final double meleeAttackSpeed;
  final double deploymentTime;
  final TargetingRule targetingRule;
  final CombatTrait trait;
  final DeathknellEffect deathknell;
  final BattlehornEffect battlehorn;

  const CombatStats({
    required this.attack,
    required this.health,
    required this.maxHealth,
    required this.speed,
    required this.movement,
    required this.distance,
    this.defense = 0,
    this.accuracy = 0.85,
    required this.cost,
    this.isFlying = false,
    this.swarmSize = 0,
    this.radius = 1.5,
    this.damageFormula,
    this.unitType = UnitType.squad,
    this.unitCount = 1,
    this.rangedDamage = 0.0,
    this.rangedRange = 0.0,
    this.rangedAttackSpeed = 1.0,
    this.meleeDamage = 0.0,
    this.meleeRange = 1.0,
    this.meleeAttackSpeed = 1.0,
    this.deploymentTime = 0.0,
    this.targetingRule = TargetingRule.all,
    this.trait = CombatTrait.none,
    this.deathknell = DeathknellEffect.none,
    this.battlehorn = BattlehornEffect.none,
  });

  CombatStats copyWith({
    double? attack,
    double? health,
    double? maxHealth,
    double? speed,
    double? movement,
    double? distance,
    double? defense,
    double? accuracy,
    int? cost,
    bool? isFlying,
    int? swarmSize,
    double? radius,
    String? damageFormula,
    UnitType? unitType,
    int? unitCount,
    double? rangedDamage,
    double? rangedRange,
    double? rangedAttackSpeed,
    double? meleeDamage,
    double? meleeRange,
    double? meleeAttackSpeed,
    double? deploymentTime,
    TargetingRule? targetingRule,
    CombatTrait? trait,
    DeathknellEffect? deathknell,
    BattlehornEffect? battlehorn,
  }) {
    return CombatStats(
      attack: attack ?? this.attack,
      health: health ?? this.health,
      maxHealth: maxHealth ?? this.maxHealth,
      speed: speed ?? this.speed,
      movement: movement ?? this.movement,
      distance: distance ?? this.distance,
      defense: defense ?? this.defense,
      accuracy: accuracy ?? this.accuracy,
      cost: cost ?? this.cost,
      isFlying: isFlying ?? this.isFlying,
      swarmSize: swarmSize ?? this.swarmSize,
      radius: radius ?? this.radius,
      damageFormula: damageFormula ?? this.damageFormula,
      unitType: unitType ?? this.unitType,
      unitCount: unitCount ?? this.unitCount,
      rangedDamage: rangedDamage ?? this.rangedDamage,
      rangedRange: rangedRange ?? this.rangedRange,
      rangedAttackSpeed: rangedAttackSpeed ?? this.rangedAttackSpeed,
      meleeDamage: meleeDamage ?? this.meleeDamage,
      meleeRange: meleeRange ?? this.meleeRange,
      meleeAttackSpeed: meleeAttackSpeed ?? this.meleeAttackSpeed,
      deploymentTime: deploymentTime ?? this.deploymentTime,
      targetingRule: targetingRule ?? this.targetingRule,
      trait: trait ?? this.trait,
      deathknell: deathknell ?? this.deathknell,
      battlehorn: battlehorn ?? this.battlehorn,
    );
  }

  Map<String, dynamic> toJson() => {
    'attack': attack,
    'health': health,
    'maxHealth': maxHealth,
    'speed': speed,
    'movement': movement,
    'distance': distance,
    'defense': defense,
    'accuracy': accuracy,
    'cost': cost,
    'isFlying': isFlying,
    'swarmSize': swarmSize,
    'radius': radius,
    'damageFormula': damageFormula,
    'unitType': unitType.name,
    'unitCount': unitCount,
    'rangedDamage': rangedDamage,
    'rangedRange': rangedRange,
    'rangedAttackSpeed': rangedAttackSpeed,
    'meleeDamage': meleeDamage,
    'meleeRange': meleeRange,
    'meleeAttackSpeed': meleeAttackSpeed,
    'deploymentTime': deploymentTime,
    'targetingRule': targetingRule.name,
    'trait': trait.name,
    'deathknell': deathknell.name,
    'battlehorn': battlehorn.name,
  };

  factory CombatStats.fromJson(Map<String, dynamic> json) => CombatStats(
    attack: (json['attack'] as num).toDouble(),
    health: (json['health'] as num).toDouble(),
    maxHealth: (json['maxHealth'] as num).toDouble(),
    speed: (json['speed'] as num).toDouble(),
    movement: (json['movement'] as num).toDouble(),
    distance: (json['distance'] as num).toDouble(),
    defense: (json['defense'] as num? ?? 0).toDouble(),
    accuracy: (json['accuracy'] as num).toDouble(),
    cost: json['cost'] as int,
    isFlying: json['isFlying'] as bool? ?? false,
    swarmSize: json['swarmSize'] as int? ?? 0,
    radius: (json['radius'] as num? ?? 1.5).toDouble(),
    damageFormula: json['damageFormula'] as String?,
    unitType: json['unitType'] != null ? UnitType.values.byName(json['unitType'] as String) : UnitType.squad,
    unitCount: json['unitCount'] as int? ?? 1,
    rangedDamage: (json['rangedDamage'] as num? ?? 0.0).toDouble(),
    rangedRange: (json['rangedRange'] as num? ?? 0.0).toDouble(),
    rangedAttackSpeed: (json['rangedAttackSpeed'] as num? ?? 1.0).toDouble(),
    meleeDamage: (json['meleeDamage'] as num? ?? 0.0).toDouble(),
    meleeRange: (json['meleeRange'] as num? ?? 1.0).toDouble(),
    meleeAttackSpeed: (json['meleeAttackSpeed'] as num? ?? 1.0).toDouble(),
    deploymentTime: (json['deploymentTime'] as num? ?? 0.0).toDouble(),
    targetingRule: json['targetingRule'] != null ? TargetingRule.values.byName(json['targetingRule'] as String) : TargetingRule.all,
    trait: json['trait'] != null ? CombatTrait.values.byName(json['trait'] as String) : CombatTrait.none,
    deathknell: json['deathknell'] != null ? DeathknellEffect.values.byName(json['deathknell'] as String) : DeathknellEffect.none,
    battlehorn: json['battlehorn'] != null ? BattlehornEffect.values.byName(json['battlehorn'] as String) : BattlehornEffect.none,
  );
}

@immutable
class Ability {
  final String id;
  final String name;
  final AbilityType type;
  final String description;
  final double? chargeTime; // For special attacks
  final Map<String, dynamic> effectData;

  const Ability({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    this.chargeTime,
    this.effectData = const {},
  });

  String get detailedDescription {
    final List<String> details = [];
    if (chargeTime != null) {
      details.add('Cooldown: ${chargeTime!.toStringAsFixed(1)}s');
    }
    final castTime = effectData['castingTime'] ?? effectData['castTime'];
    if (castTime != null) {
      details.add('Cast: ${castTime}s');
    } else if (type == AbilityType.special) {
      details.add('Cast: Instant');
    }

    final aoe = effectData['aoe'] ?? effectData['radius'] ?? effectData['range'] ?? effectData['area'];
    if (aoe != null) {
      details.add('AoE: ${aoe}ft');
    }

    if (effectData.isNotEmpty) {
      effectData.forEach((key, value) {
        if (key != 'castingTime' && key != 'castTime' && key != 'aoe' && key != 'radius' && key != 'range' && key != 'area') {
          if (key != 'type' && key != 'buffType') {
            final String capKey = key[0].toUpperCase() + key.substring(1);
            details.add('$capKey: $value');
          }
        }
      });
    }

    if (details.isEmpty) {
      return description;
    }
    return '$description (${details.join(" | ")})';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'description': description,
    'chargeTime': chargeTime,
    'effectData': effectData,
  };

  factory Ability.fromJson(Map<String, dynamic> json) => Ability(
    id: json['id'] as String,
    name: json['name'] as String,
    type: AbilityType.values.byName(json['type'] as String),
    description: json['description'] as String,
    chargeTime: (json['chargeTime'] as num?)?.toDouble(),
    effectData: json['effectData'] as Map<String, dynamic>? ?? {},
  );
}
