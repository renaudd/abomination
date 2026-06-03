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
  arsenal,
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
      case SurvivalBuildingType.arsenal:
      case SurvivalBuildingType.garage:
      case SurvivalBuildingType.munitionsFactory:
        // Advanced facilities: level 1: 1 slot, 2: 2 slots, 3: 3 slots (Max Level 3)
        return level.clamp(1, 3);
    }
  }
}

enum SurvivalDifficulty {
  elementary,
  classic,
  arcade,
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
  int villageHealth;
  SurvivalDifficulty difficulty;
  bool autoSaveEnabled;
  Map<String, int> factionStandings; // e.g. {'Freemasons': 0, 'Rosicrucians': 0, 'Glarus': 0, 'Army': 0...}
  Map<String, List<String>> towerRepairWorkers; // towerId -> list of cardTypes

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
    Map<String, int>? cardUpgrades,
    this.villageHealth = 100,
    this.difficulty = SurvivalDifficulty.classic,
    this.autoSaveEnabled = true,
    Map<String, int>? factionStandings,
    Map<String, List<String>>? towerRepairWorkers,
  }) : this.cardUpgrades = cardUpgrades ?? {},
       this.factionStandings = factionStandings ?? {
         'Freemasons': 0,
         'Rosicrucians': 0,
         'Knights Templar': 0,
         'Gnomes of Zurich': 0,
         'Carbonari': 0,
         'Golden Dawn': 0,
         'Fenian Brotherhood': 0,
         'Chevaliers de la foi': 0,
         'Ancient Order of Foresters': 0,
         'Glarus': 10,
         'Army': 40,
       },
       this.towerRepairWorkers = towerRepairWorkers ?? {
         'tower_1': [],
         'tower_2': [],
         'tower_3': [],
       };

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
        'villageHealth': villageHealth,
        'difficulty': difficulty.name,
        'autoSaveEnabled': autoSaveEnabled,
        'factionStandings': factionStandings,
        'towerRepairWorkers': towerRepairWorkers,
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
        villageHealth: json['villageHealth'] as int? ?? 100,
        difficulty: () {
          final diffStr = json['difficulty'] as String? ?? 'classic';
          if (diffStr == 'childPlay') return SurvivalDifficulty.elementary;
          return SurvivalDifficulty.values.firstWhere(
            (e) => e.name == diffStr,
            orElse: () => SurvivalDifficulty.classic,
          );
        }(),
        autoSaveEnabled: json['autoSaveEnabled'] as bool? ?? true,
        factionStandings: Map<String, int>.from(json['factionStandings'] as Map? ?? {
          'Freemasons': 0,
          'Rosicrucians': 0,
          'Knights Templar': 0,
          'Gnomes of Zurich': 0,
          'Carbonari': 0,
          'Golden Dawn': 0,
          'Fenian Brotherhood': 0,
          'Chevaliers de la foi': 0,
          'Ancient Order of Foresters': 0,
          'Glarus': 10,
          'Army': 40,
        }),
        towerRepairWorkers: (json['towerRepairWorkers'] as Map? ?? {}).map(
          (k, v) => MapEntry(k as String, List<String>.from(v as List? ?? [])),
        ),
      );



  // Progressive Level milestones
  static int getRequiredXpForLevel(int nextLevel) {
    switch (nextLevel) {
      case 2: return 10;
      case 3: return 40;
      case 4: return 120;
      case 5: return 300;
      case 6: return 800;
      case 7: return 2500;
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

  int getTowerLevel(String towerId) {
    final globalHp = cardUpgrades['tower_hp'] ?? 0;
    final globalAtk = cardUpgrades['tower_atk'] ?? 0;
    final globalRange = cardUpgrades['tower_range'] ?? 0;
    final globalSpeed = cardUpgrades['tower_speed'] ?? 0;

    final indHp = cardUpgrades['${towerId}_hp'] ?? 0;
    final indAtk = cardUpgrades['${towerId}_atk'] ?? 0;
    final indRange = cardUpgrades['${towerId}_range'] ?? 0;
    final indSpeed = cardUpgrades['${towerId}_speed'] ?? 0;

    final total = globalHp + globalAtk + globalRange + globalSpeed +
                  indHp + indAtk + indRange + indSpeed;

    if (total >= 38) return 7;
    if (total >= 33) return 6;
    if (total >= 26) return 5;
    if (total >= 18) return 4;
    if (total >= 10) return 3;
    if (total >= 4) return 2;
    return 1;
  }

  int getTowerRepairSlotsCap(String towerId) {
    final lvl = getTowerLevel(towerId);
    if (lvl >= 7) return 5;
    if (lvl == 6) return 4;
    if (lvl >= 4) return 3;
    if (lvl >= 2) return 2;
    return 1;
  }
}

extension SurvivalBuildingTypeExtension on SurvivalBuildingType {
  String get displayName {
    switch (this) {
      case SurvivalBuildingType.farm:
        return 'Farm';
      case SurvivalBuildingType.lumberMill:
        return 'Lumber Mill';
      case SurvivalBuildingType.mine:
        return 'Mine';
      case SurvivalBuildingType.arsenal:
        return 'Arsenal';
      case SurvivalBuildingType.garage:
        return 'Garage';
      case SurvivalBuildingType.munitionsFactory:
        return 'Munitions Factory';
    }
  }
}
