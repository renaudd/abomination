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

enum SurvivalBuildingType {
  farm,
  lumberMill,
  mine,
  weaponsmith,
  garage,
  munitionsFactory,
}

class SurvivalBuilding {
  final String id;
  final SurvivalBuildingType type;
  int level;
  List<String> assignedUnitIds;

  SurvivalBuilding({
    required this.id,
    required this.type,
    this.level = 1,
    required this.assignedUnitIds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'level': level,
        'assignedUnitIds': assignedUnitIds,
      };

  factory SurvivalBuilding.fromJson(Map<String, dynamic> json) => SurvivalBuilding(
        id: json['id'] as String,
        type: SurvivalBuildingType.values.byName(json['type'] as String),
        level: json['level'] as int? ?? 1,
        assignedUnitIds: List<String>.from(json['assignedUnitIds'] as List? ?? []),
      );

  // Returns the maximum worker capacity for this facility based on its level and type
  int getWorkerCap() {
    switch (type) {
      case SurvivalBuildingType.farm:
        final caps = const [2, 3, 3, 2, 2, 2, 3];
        return caps[(level - 1).clamp(0, 6)];
      case SurvivalBuildingType.lumberMill:
        final caps = const [2, 3, 3, 2, 2, 2, 0];
        return caps[(level - 1).clamp(0, 6)];
      case SurvivalBuildingType.mine:
        final caps = const [1, 2, 2, 3, 3, 1, 2];
        return caps[(level - 1).clamp(0, 6)];
      case SurvivalBuildingType.weaponsmith:
      case SurvivalBuildingType.garage:
      case SurvivalBuildingType.munitionsFactory:
        // Advanced facilities: level 1: 1 slot, 2: 2 slots, 3: 3 slots (Max Level 3)
        return level.clamp(1, 3);
    }
  }
}

class SurvivalProgress {
  int currentTurn;
  int cash;
  int food;
  int wood;
  int iron;
  String selectedLeaderId;
  List<String> playerDeckIds;
  List<SurvivalBuilding> buildings;
  List<String> purchasedPlots;
  Map<String, int> towerLevels; // e.g. {'health': 1, 'damage': 1, 'range': 0}
  Map<String, double> towerDamaged; // tower_1/2/3 -> double (damage status: 0.0 fully healthy, 1.0 destroyed)
  Map<String, double> unitExp; // cardType -> total XP
  Map<String, int> starvationInfractions; // cardType -> consecutive turns unfed
  Map<String, int> bondageDebuffCount; // cardType -> negative debuffs accumulated
  List<String> trainingUnitIds; // Unit cardTypes currently assigned to training
  Map<String, int> cardUpgrades; // e.g. {'peasant_hp': 1, 'leader_hp': 0}

  SurvivalProgress({
    this.currentTurn = 1,
    this.cash = 1000,
    this.food = 50,
    this.wood = 200,
    this.iron = 30,
    this.selectedLeaderId = 'alphonse',
    required this.playerDeckIds,
    required this.buildings,
    required this.purchasedPlots,
    required this.towerLevels,
    required this.towerDamaged,
    required this.unitExp,
    required this.starvationInfractions,
    required this.bondageDebuffCount,
    this.trainingUnitIds = const [],
    this.cardUpgrades = const {},
  });

  Map<String, dynamic> toJson() => {
        'currentTurn': currentTurn,
        'cash': cash,
        'food': food,
        'wood': wood,
        'iron': iron,
        'selectedLeaderId': selectedLeaderId,
        'playerDeckIds': playerDeckIds,
        'buildings': buildings.map((b) => b.toJson()).toList(),
        'purchasedPlots': purchasedPlots,
        'towerLevels': towerLevels,
        'towerDamaged': towerDamaged,
        'unitExp': unitExp,
        'starvationInfractions': starvationInfractions,
        'bondageDebuffCount': bondageDebuffCount,
        'trainingUnitIds': trainingUnitIds,
        'cardUpgrades': cardUpgrades,
      };

  factory SurvivalProgress.fromJson(Map<String, dynamic> json) => SurvivalProgress(
        currentTurn: json['currentTurn'] as int? ?? 1,
        cash: json['cash'] as int? ?? 1000,
        food: json['food'] as int? ?? 50,
        wood: json['wood'] as int? ?? 200,
        iron: json['iron'] as int? ?? 30,
        selectedLeaderId: json['selectedLeaderId'] as String? ?? 'alphonse',
        playerDeckIds: List<String>.from(json['playerDeckIds'] as List? ?? []),
        buildings: (json['buildings'] as List? ?? [])
            .map((b) => SurvivalBuilding.fromJson(b as Map<String, dynamic>))
            .toList(),
        purchasedPlots: List<String>.from(json['purchasedPlots'] as List? ?? []),
        towerLevels: Map<String, int>.from(json['towerLevels'] as Map? ?? {}),
        towerDamaged: (json['towerDamaged'] as Map? ?? {}).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
        unitExp: (json['unitExp'] as Map? ?? {}).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        ),
        starvationInfractions: Map<String, int>.from(json['starvationInfractions'] as Map? ?? {}),
        bondageDebuffCount: Map<String, int>.from(json['bondageDebuffCount'] as Map? ?? {}),
        trainingUnitIds: List<String>.from(json['trainingUnitIds'] as List? ?? []),
        cardUpgrades: Map<String, int>.from(json['cardUpgrades'] as Map? ?? {}),
      );

  // Progressive Level milestones
  static int getRequiredXpForLevel(int nextLevel) {
    switch (nextLevel) {
      case 2: return 6;
      case 3: return 20;
      case 4: return 60;
      case 5: return 150;
      case 6: return 350;
      case 7: return 1000;
      default: return 9999999;
    }
  }

  // Calculates current level based on accumulated XP
  static int getLevelFromXp(double xp) {
    int lvl = 1;
    while (lvl < 7) {
      final req = getRequiredXpForLevel(lvl + 1);
      if (xp >= req) {
        lvl++;
      } else {
        break;
      }
    }
    return lvl;
  }
}
