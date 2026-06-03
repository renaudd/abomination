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

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/arena_progress.dart';
import '../models/survival_state.dart';
import '../models/npc.dart';
import '../models/combat_stats.dart';
import 'combat_unit_service.dart';
import 'arena_save_service.dart';

class SurvivalService extends ChangeNotifier {
  SurvivalProgress? _progress;
  final int _activeSlot;

  final List<String> _logs = [];

  SurvivalProgress? get progress => _progress;
  List<String> get logs => _logs;
  int get activeSlot => _activeSlot;

  SurvivalService(this._activeSlot, [this._progress]) {
    if (_progress == null) {
      _loadProgress();
    }
  }

  Future<void> _loadProgress() async {
    final saved = await ArenaSaveService.loadProgress(_activeSlot);
    if (saved != null && saved.survival != null) {
      _progress = saved.survival;
      notifyListeners();
    }
  }

  void _save({bool isManual = false}) {
    if (_progress == null) return;
    if (!isManual && !_progress!.autoSaveEnabled) return;

    final t1Destroyed = (_progress!.towerDamaged['tower_1'] ?? 0.0) >= 1.0;
    final t2Destroyed = (_progress!.towerDamaged['tower_2'] ?? 0.0) >= 1.0;
    final t3Destroyed = (_progress!.towerDamaged['tower_3'] ?? 0.0) >= 1.0;
    final allTowersDestroyed = t1Destroyed && t2Destroyed && t3Destroyed;
    if (_progress!.difficulty == SurvivalDifficulty.arcade && allTowersDestroyed) {
      return; // Do not save defeated Arcade game
    }

    ArenaSaveService.loadProgress(_activeSlot).then((current) {
      final updated = ArenaProgress(
        slot: _activeSlot,
        saveTime: DateTime.now(),
        campaign: current?.campaign,
        tournament: current?.tournament,
        survival: _progress,
      );
      ArenaSaveService.saveProgress(updated);
    });
    notifyListeners();
  }

  void manualSave() {
    _save(isManual: true);
    addLog('Manual Save completed.');
  }

  void manualSaveToSlot(int slot) {
    if (_progress == null) return;
    ArenaSaveService.loadProgress(slot).then((current) {
      final updated = ArenaProgress(
        slot: slot,
        saveTime: DateTime.now(),
        campaign: current?.campaign,
        tournament: current?.tournament,
        survival: _progress,
      );
      ArenaSaveService.saveProgress(updated);
    });
    addLog('Manual Save to Slot #$slot completed.');
    notifyListeners();
  }

  Future<void> manualLoadFromSlot(int slot) async {
    final saved = await ArenaSaveService.loadProgress(slot);
    if (saved != null && saved.survival != null) {
      _progress = saved.survival;
      addLog('Loaded game state from Slot #$slot.');
      notifyListeners();
    } else {
      addLog('Failed to load: Slot #$slot has no survival save data.');
    }
  }

  void toggleAutoSave() {
    if (_progress == null) return;
    _progress!.autoSaveEnabled = !_progress!.autoSaveEnabled;
    addLog('Auto-Save is now ${_progress!.autoSaveEnabled ? "ENABLED" : "DISABLED"}.');
    _save(isManual: true);
  }

  Future<void> reloadProgress() async {
    await _loadProgress();
    addLog('Survival progress loaded from slot #$_activeSlot.');
  }

  void addLog(String msg) {
    _logs.add(msg);
    if (_logs.length > 40) {
      _logs.removeAt(0);
    }
    notifyListeners();
  }

  // Initialize a new Survival Mode game slot
  void initializeNewSurvivalGame(String leaderId, SurvivalDifficulty difficulty) {
    _logs.clear();
    final rand = Random();
    final firstEncounterTurn = rand.nextBool() ? 4 : 5;
    _progress = SurvivalProgress(
      currentTurn: 1,
      cash: 1000,
      food: 15,
      wood: 40,
      iron: 20,
      selectedLeaderId: leaderId,
      playerDeckIds: [], // Embark shop draft fills this
      buildings: [
        // Starting Farm at Level 1
        SurvivalBuilding(id: 'plot_c', type: SurvivalBuildingType.farm, level: 1, assignedUnitIds: []),
      ],
      purchasedPlots: [],
      towerLevels: {
        'health': 1,
        'damage': 1,
        'range': 1,
        'rateOfFire': 1,
      },
      towerDamaged: {
        'tower_1': 0.0,
        'tower_2': 0.0,
        'tower_3': 0.0,
      },
      unitExp: {},
      starvationInfractions: {},
      bondageDebuffCount: {},
      trainingUnitIds: [],
      cardUpgrades: {
        'next_encounter_turn': firstEncounterTurn,
        'next_encounter_index': 0,
      },
      difficulty: difficulty,
      autoSaveEnabled: true,
    );
    addLog('Survival Mode begun! Starting draft embarked.');
    _save();
  }

  // EMBARK SHOP DRAFT: Buy cards using starting money
  bool buyDraftCard(String type, int costGhc) {
    if (_progress == null || _progress!.cash < costGhc) return false;
    if (_progress!.playerDeckIds.length >= 12) return false;

    _progress!.cash -= costGhc;
    _progress!.playerDeckIds.add(type);
    addLog('Purchased ${type.replaceAll("_", " ").toUpperCase()} for $costGhc CHF.');
    _save();
    return true;
  }

  void commitDraftSquad(List<String> squad, int totalCost) {
    if (_progress == null) return;
    _progress!.cash = 1000 - totalCost;
    _progress!.playerDeckIds.clear();
    _progress!.playerDeckIds.addAll(squad);
    addLog('Embark Squad committed: ${squad.length} units recruited for $totalCost CHF.');
    _save();
  }

  bool upgradeCard(String cardId, String stat, int cost) {
    if (_progress == null || _progress!.cash < cost) return false;
    _progress!.cash -= cost;
    final key = '${cardId}_$stat';
    final currentLvl = _progress!.cardUpgrades[key] ?? 0;
    _progress!.cardUpgrades[key] = currentLvl + 1;
    addLog('Upgraded $cardId $stat to Lvl ${currentLvl + 1} for $cost CHF.');
    _save();
    return true;
  }

  bool buyTrainingPoints(String cardId, int xpAmount, int cashCost) {
    if (_progress == null || _progress!.cash < cashCost) return false;
    final tempNpc = CombatUnitService.createUnit(cardId);
    if (isUndead(tempNpc)) return false;
    _progress!.cash -= cashCost;
    final currentXp = _progress!.unitExp[cardId] ?? 0.0;
    final nextXp = currentXp + xpAmount;
    _progress!.unitExp[cardId] = nextXp;
    
    final oldLvl = SurvivalProgress.getLevelFromXp(currentXp);
    final newLvl = SurvivalProgress.getLevelFromXp(nextXp);
    if (newLvl > oldLvl) {
      addLog('LEVEL UP! Bought training points for ${cardId.toUpperCase()} promoting to Level $newLvl!');
    } else {
      addLog('Bought +$xpAmount XP for ${cardId.toUpperCase()} for $cashCost CHF.');
    }
    _save();
    return true;
  }

  bool upgradeLeader(String stat, int cost) {
    if (_progress == null || _progress!.cash < cost) return false;
    _progress!.cash -= cost;
    final key = 'leader_$stat';
    final currentLvl = _progress!.cardUpgrades[key] ?? 0;
    _progress!.cardUpgrades[key] = currentLvl + 1;
    addLog('Upgraded Leader $stat to Lvl ${currentLvl + 1} for $cost CHF.');
    _save();
    return true;
  }

  bool upgradeTower(String stat, int cost) {
    if (_progress == null || _progress!.cash < cost) return false;
    _progress!.cash -= cost;
    final key = 'tower_$stat';
    final currentLvl = _progress!.cardUpgrades[key] ?? 0;
    _progress!.cardUpgrades[key] = currentLvl + 1;
    addLog('Upgraded Watchtower Covenant $stat to Lvl ${currentLvl + 1} for $cost CHF.');
    _save();
    return true;
  }

  bool upgradeIndividualTower(String towerId, String stat, int cost) {
    if (_progress == null || _progress!.cash < cost) return false;
    _progress!.cash -= cost;
    final key = '${towerId}_$stat';
    final currentLvl = _progress!.cardUpgrades[key] ?? 0;
    _progress!.cardUpgrades[key] = currentLvl + 1;
    addLog('Upgraded $towerId $stat to Lvl ${currentLvl + 1} for $cost CHF.');
    _save();
    return true;
  }

  bool buyResource(String resourceType, int amount, int cost) {
    if (_progress == null || _progress!.cash < cost) return false;
    _progress!.cash -= cost;
    if (resourceType == 'food') _progress!.food += amount;
    if (resourceType == 'wood') _progress!.wood += amount;
    if (resourceType == 'iron') _progress!.iron += amount;
    addLog('Purchased +$amount $resourceType for $cost CHF.');
    _save();
    return true;
  }

  bool buyCombatCard(String type, int cost) {
    if (_progress == null || _progress!.cash < cost) return false;
    if (_progress!.playerDeckIds.length >= 12) {
      addLog('Cannot purchase card: Deck is full (max 12 cards).');
      return false;
    }
    _progress!.cash -= cost;
    _progress!.playerDeckIds.add(type);
    addLog('Recruited card ${type.toUpperCase()} for $cost CHF.');
    _save();
    return true;
  }

  // Unit properties classifier helper
  static bool isUndead(NPC npc) {
    return npc.specimenType == 'Undead' || 
           npc.name.toLowerCase().contains('undead') || 
           npc.name.toLowerCase().contains('corpse') || 
           npc.name.toLowerCase().contains('horror') ||
           (npc.name.toLowerCase().contains('rats') && !npc.id.contains('brown_rats'));
  }

  static bool isWildAnimal(NPC npc) {
    final type = npc.specimenType.toLowerCase();
    return (type == 'beast' || type == 'fox' || type == 'wolf' || type == 'bear' || 
            (type == 'rat' && npc.id.contains('brown_rats'))) && 
           !npc.name.toLowerCase().contains('chimera');
  }

  static bool isChimera(NPC npc) {
    return npc.name.toLowerCase().contains('chimera');
  }

  static bool isConstruct(NPC npc) {
    return npc.specimenType == 'Construct' || npc.name.toLowerCase().contains('golem');
  }

  static int getFoodCost(NPC npc) {
    if (isUndead(npc) || isWildAnimal(npc) || isConstruct(npc)) return 0;
    return npc.combatStats?.unitCount ?? 1;
  }

  // Worker Assignment Mechanics
  bool assignWorker(String buildingId, String unitCardId) {
    if (_progress == null) return false;
    
    // Validate if unit is eligible to work
    final npc = CombatUnitService.createUnit(unitCardId);
    if (isWildAnimal(npc)) {
      addLog('${npc.name} is a wild beast and cannot do industrial work.');
      return false;
    }
    if (isChimera(npc)) {
      addLog('Chimera cannot be assigned to work or training.');
      return false;
    }

    // Check if unit is committed to tower repair
    for (var list in _progress!.towerRepairWorkers.values) {
      if (list.contains(unitCardId)) {
        addLog('Cannot reassign ${npc.name} because they are committed to watchtower repair.');
        return false;
      }
    }

    // Find the building
    final b = _progress!.buildings.firstWhere((x) => x.id == buildingId);
    if (b.assignedUnitIds.length >= b.getWorkerCap()) {
      addLog('This facility is at maximum worker capacity.');
      return false;
    }

    // Unassign unit from everywhere else first
    unassignUnitEverywhere(unitCardId);

    b.assignedUnitIds.add(unitCardId);
    addLog('Assigned ${npc.name} to ${b.type.name.replaceAll("_", " ").toUpperCase()}.');
    _save();
    return true;
  }

  void unassignUnitEverywhere(String unitCardId, {bool force = false}) {
    if (_progress == null) return;
    // Remove from buildings
    for (var b in _progress!.buildings) {
      b.assignedUnitIds.remove(unitCardId);
    }
    // Remove from training
    _progress!.trainingUnitIds.remove(unitCardId);
    // Remove from tower repairs ONLY if force is true
    if (force) {
      for (var list in _progress!.towerRepairWorkers.values) {
        list.remove(unitCardId);
      }
    }
  }

  bool assignTowerRepair(String towerId, String unitCardId) {
    if (_progress == null) return false;

    final npc = CombatUnitService.createUnit(unitCardId);
    if (isWildAnimal(npc)) {
      addLog('${npc.name} is a wild beast and cannot do construction work.');
      return false;
    }
    if (isChimera(npc)) {
      addLog('Chimera cannot be assigned to work or training.');
      return false;
    }

    // Check if new worker is already repairing another tower
    for (var entry in _progress!.towerRepairWorkers.entries) {
      if (entry.value.contains(unitCardId)) {
        if (entry.key == towerId) {
          return false; // Already here
        } else {
          addLog('${npc.name} is already repairing another tower.');
          return false;
        }
      }
    }

    final list = _progress!.towerRepairWorkers[towerId] ?? [];
    final cap = _progress!.getTowerRepairSlotsCap(towerId);

    if (list.length >= cap) {
      // Swapping! Remove the first worker in the list
      final removedId = list.removeAt(0);
      final removedNpc = CombatUnitService.createUnit(removedId);
      addLog('Swapped out ${removedNpc.name} from ${towerId.toUpperCase()} repair.');
    }

    unassignUnitEverywhere(unitCardId, force: true);
    list.add(unitCardId);
    _progress!.towerRepairWorkers[towerId] = list;
    addLog('Assigned ${npc.name} to repair ${towerId.replaceAll("_", " ").toUpperCase()}.');
    _save();
    return true;
  }

  bool assignTraining(String unitCardId) {
    if (_progress == null) return false;
    
    final npc = CombatUnitService.createUnit(unitCardId);
    if (isUndead(npc)) {
      addLog('${npc.name} is undead and cannot be trained.');
      return false;
    }
    if (isChimera(npc)) {
      addLog('Chimera cannot be assigned to work or training.');
      return false;
    }

    // Check if unit is committed to tower repair
    for (var list in _progress!.towerRepairWorkers.values) {
      if (list.contains(unitCardId)) {
        addLog('Cannot reassign ${npc.name} because they are committed to watchtower repair.');
        return false;
      }
    }

    if (_progress!.trainingUnitIds.length >= 8) {
      addLog('The Training Yard is at full capacity (limit of 8 trainees).');
      return false;
    }

    unassignUnitEverywhere(unitCardId);
    _progress!.trainingUnitIds.add(unitCardId);
    addLog('Assigned ${npc.name} to the Training Yard.');
    _save();
    return true;
  }

  // Plot and Building Upgrades
  bool unlockPlot(String plotKey, int costGhc) {
    if (_progress == null) return false;
    if (_progress!.cash < costGhc) {
      addLog('Cannot unlock plot: Insufficient CHF (needs $costGhc CHF).');
      return false;
    }
    _progress!.cash -= costGhc;
    _progress!.purchasedPlots.add(plotKey);
    addLog('Unlocked Estate Plot slot $plotKey.');
    _save();
    return true;
  }

  bool buildFacility(String plotKey, SurvivalBuildingType type, int woodCost, int ironCost, int cashCost) {
    if (_progress == null) return false;

    // Enforce basic vs advanced plot validation
    final isAdvancedType = type == SurvivalBuildingType.arsenal ||
                           type == SurvivalBuildingType.garage ||
                           type == SurvivalBuildingType.munitionsFactory;
    final isAdvancedPlot = plotKey == 'plot_a' || plotKey == 'plot_b';

    if (isAdvancedType != isAdvancedPlot) {
      addLog('Cannot construct ${type.name.toUpperCase()} on ${isAdvancedPlot ? 'ADVANCED' : 'BASIC'} plot.');
      return false;
    }

    if (_progress!.wood < woodCost || _progress!.iron < ironCost || _progress!.cash < cashCost) {
      addLog('Cannot build: Insufficient resources. Requires $woodCost Wood, $ironCost Iron, $cashCost CHF.');
      return false;
    }

    _progress!.wood -= woodCost;
    _progress!.iron -= ironCost;
    _progress!.cash -= cashCost;

    _progress!.cardUpgrades.remove('${plotKey}_fallow');
    _progress!.buildings.add(SurvivalBuilding(id: plotKey, type: type, level: 1, assignedUnitIds: []));
    addLog('Constructed ${type.name.replaceAll("_", " ").toUpperCase()} on Plot ${plotKey.replaceAll("plot_", "").toUpperCase()}.');
    _save();
    return true;
  }

  bool demolishBuilding(String plotKey) {
    if (_progress == null) return false;
    final index = _progress!.buildings.indexWhere((x) => x.id == plotKey);
    if (index == -1) return false;

    final b = _progress!.buildings[index];
    b.assignedUnitIds.clear();
    _progress!.buildings.removeAt(index);
    _progress!.cardUpgrades['${plotKey}_fallow'] = 1;

    addLog('Demolished building on Plot ${plotKey.replaceAll("plot_", "").toUpperCase()}.');
    _save();
    return true;
  }

  bool upgradeBuilding(String id, int woodCost, int ironCost, int cashCost) {
    if (_progress == null) return false;
    final b = _progress!.buildings.firstWhere((x) => x.id == id);
    final maxLvl = (b.type == SurvivalBuildingType.arsenal ||
                    b.type == SurvivalBuildingType.garage ||
                    b.type == SurvivalBuildingType.munitionsFactory) ? 3 : 7;
    
    if (b.level >= maxLvl) return false;
    if (_progress!.wood < woodCost || _progress!.iron < ironCost || _progress!.cash < cashCost) {
      addLog('Cannot upgrade: Insufficient resources. Requires $woodCost Wood, $ironCost Iron, $cashCost CHF.');
      return false;
    }

    _progress!.wood -= woodCost;
    _progress!.iron -= ironCost;
    _progress!.cash -= cashCost;

    b.level++;
    addLog('Upgraded ${b.type.name.replaceAll("_", " ").toUpperCase()} to Level ${b.level}.');
    _save();
    return true;
  }

  // Feed Construct / Bondage Curing
  bool cureBondageConstruct(String cardType, int foodCost) {
    if (_progress == null || _progress!.food < foodCost) return false;
    final count = _progress!.bondageDebuffCount[cardType] ?? 0;
    if (count <= 0) return false;

    _progress!.food -= foodCost;
    _progress!.bondageDebuffCount[cardType] = count - 1;
    addLog('Perform maintenance feeding: cured 1 bondage penalty on ${cardType.toUpperCase()}.');
    _save();
    return true;
  }

  // Resource production calculation
  int getFarmOutput(int level, int workers) {
    // Farm yields 15 food per worker per level
    if (level >= 4) {
      double efficiency = 0.0;
      for (int i = 0; i < workers; i++) {
        if (i == 0) efficiency += 1.0;
        else if (i == 1) efficiency += 0.8;
        else efficiency += 0.6;
      }
      return (efficiency * 15 * level).round();
    }
    return workers * 15 * level;
  }

  int getLumberMillOutput(int level, int workers) {
    if (level == 7) return 300; // Fully automated passive output
    if (level >= 4) {
      double efficiency = 0.0;
      for (int i = 0; i < workers; i++) {
        if (i == 0) efficiency += 1.0;
        else if (i == 1) efficiency += 0.8;
        else efficiency += 0.6;
      }
      final basePerWorker = level == 6 ? 50 : (25 + 5 * level);
      return (efficiency * basePerWorker).round();
    }
    if (level == 6) return workers * 50;
    return workers * (25 + 5 * level);
  }

  int getMineOutput(int level, int workers) {
    final caps = const [1, 2, 2, 3, 3, 1, 2];
    final cap = caps[(level - 1).clamp(0, 6)];
    double output = workers * (5 + 2 * level).toDouble();
    if (workers < cap) {
      output *= 0.7; // 30% under-staffing penalty
    }
    return output.round();
  }

  int getAdvancedOutput(int level, int workers) {
    // Level 1: 50, Level 2: 80, Level 3: 120 CHF
    final wages = const [50, 80, 120];
    final wage = wages[(level - 1).clamp(0, 2)];
    final cap = level.clamp(1, 3);
    double output = workers * wage.toDouble();
    if (workers < cap) {
      output *= 0.7; // 30% under-staffing penalty
    }
    return output.round();
  }

  // TOWER REPAIRS
  bool repairTower(String towerId, String method, int woodCost, int cashCost) {
    if (_progress == null) return false;
    
    if (method == 'wood') {
      if (_progress!.wood < woodCost) return false;
      _progress!.wood -= woodCost;
      _progress!.towerDamaged[towerId] = 0.0;
      _progress!.towerRepairWorkers[towerId]?.clear();
      addLog('Repaired $towerId with raw Wood.');
    } else if (method == 'cash') {
      if (_progress!.cash < cashCost) return false;
      _progress!.cash -= cashCost;
      _progress!.towerDamaged[towerId] = 0.0;
      _progress!.towerRepairWorkers[towerId]?.clear();
      addLog('Repaired $towerId via Cash contract.');
    } else if (method == 'labor') {
      autoAssignTowerRepairs();
    }
    
    _save();
    return true;
  }

  void autoAssignTowerRepairs() {
    if (_progress == null) return;
    
    final damagedTowers = _progress!.towerDamaged.entries
        .where((entry) => entry.value > 0.0)
        .map((entry) => entry.key)
        .toList();
        
    if (damagedTowers.isEmpty) return;

    final pool = <String>[];
    for (final type in _progress!.playerDeckIds) {
      final npc = CombatUnitService.createUnit(type);
      if (isWildAnimal(npc) || isChimera(npc)) continue;
      
      bool isRepairing = false;
      for (final list in _progress!.towerRepairWorkers.values) {
        if (list.contains(type)) isRepairing = true;
      }
      if (!isRepairing) {
        pool.add(type);
      }
    }

    final idleUnits = <String>[];
    final trainingUnits = <String>[];
    final buildingUnits = <String>[];

    for (final type in pool) {
      if (_progress!.trainingUnitIds.contains(type)) {
        trainingUnits.add(type);
      } else {
        bool inBuilding = false;
        for (final b in _progress!.buildings) {
          if (b.assignedUnitIds.contains(type)) {
            inBuilding = true;
            break;
          }
        }
        if (inBuilding) {
          buildingUnits.add(type);
        } else {
          idleUnits.add(type);
        }
      }
    }

    final sortedPool = [...idleUnits, ...trainingUnits, ...buildingUnits];

    for (final towerId in damagedTowers) {
      final list = _progress!.towerRepairWorkers[towerId] ?? [];
      final cap = _progress!.getTowerRepairSlotsCap(towerId);
      while (list.length < cap && sortedPool.isNotEmpty) {
        final unitCardId = sortedPool.removeAt(0);
        unassignUnitEverywhere(unitCardId, force: true);
        list.add(unitCardId);
        final npc = CombatUnitService.createUnit(unitCardId);
        addLog('Assigned ${npc.name} to repair ${towerId.toUpperCase()} by default.');
      }
      _progress!.towerRepairWorkers[towerId] = list;
    }
  }

  // END TURN: Transition loop
  void endTurn() {
    if (_progress == null) return;

    // Auto-assign and resolve tower repairs
    autoAssignTowerRepairs();
    for (final towerId in _progress!.towerRepairWorkers.keys.toList()) {
      final list = _progress!.towerRepairWorkers[towerId] ?? [];
      final cap = _progress!.getTowerRepairSlotsCap(towerId);
      if (list.length >= cap) {
        _progress!.towerDamaged[towerId] = 0.0;
        list.clear();
        addLog('Watchtower ${towerId.toUpperCase()} was successfully repaired by manual labor.');
      }
    }

    addLog('--- TURN ${_progress!.currentTurn} RESOLUTION ---');

    // 1. Deduct food cost
    int totalFoodCost = 1; // 1 unit of food for the player's character (Alphonse)
    final Map<String, int> unitCosts = {};
    for (var type in _progress!.playerDeckIds) {
      final npc = CombatUnitService.createUnit(type);
      final c = getFoodCost(npc);
      totalFoodCost += c;
      unitCosts[type] = c;
    }

    final deficit = totalFoodCost - _progress!.food;
    if (deficit <= 0) {
      _progress!.food -= totalFoodCost;
      addLog('Fed entire army and leader Alphonse (-$totalFoodCost Food).');
      // Cure basic temporary starvation infractions
      _progress!.starvationInfractions.clear();
    } else {
      _progress!.food = 0;
      addLog('Food deficit! Army is starving (deficit: $deficit food)!');

      // Process Elite unit desertion
      final eliteStarving = _progress!.playerDeckIds.where((t) {
        final npc = CombatUnitService.createUnit(t);
        return getFoodCost(npc) >= 1 && npc.combatStats!.cost >= 5 && !isConstruct(npc);
      }).toList();
      
      int eliteDesertersCount = min(deficit, eliteStarving.length);
      for (int i = 0; i < eliteDesertersCount; i++) {
        final deserter = eliteStarving[i];
        _progress!.playerDeckIds.remove(deserter);
        unassignUnitEverywhere(deserter);
        addLog('ELITE UNIT DESERTED: ${deserter.toUpperCase()} abandoned the army due to starvation.');
      }

      // Process Basic unit infractions
      final basicStarving = _progress!.playerDeckIds.where((t) {
        final npc = CombatUnitService.createUnit(t);
        return getFoodCost(npc) >= 1 && npc.combatStats!.cost < 5 && !isConstruct(npc);
      }).toList();

      for (var t in basicStarving) {
        final infractions = (_progress!.starvationInfractions[t] ?? 0) + 1;
        if (infractions >= 2) {
          _progress!.playerDeckIds.remove(t);
          unassignUnitEverywhere(t);
          _progress!.starvationInfractions.remove(t);
          addLog('BASIC UNIT DESERTED: ${t.toUpperCase()} permanently deserted after missing 2 consecutive feedings.');
        } else {
          _progress!.starvationInfractions[t] = infractions;
          addLog('Starvation Infraction! ${t.toUpperCase()} is starving (suffers -50% stats debuff next combat).');
        }
      }

      // Process Construct / Bondage overwork infractions
      final constructs = _progress!.playerDeckIds.where((t) {
        final npc = CombatUnitService.createUnit(t);
        return isConstruct(npc);
      }).toList();
      for (var t in constructs) {
        final debuffs = (_progress!.bondageDebuffCount[t] ?? 0) + 1;
        _progress!.bondageDebuffCount[t] = debuffs;
        addLog('Construct wear! ${t.toUpperCase()} accumulates a bondage debuff (-15% effectiveness). Curing requires maintenance food.');
      }
    }

    // 2. Industry Production
    for (var b in _progress!.buildings) {
      final workers = b.assignedUnitIds.length;
      if (b.type == SurvivalBuildingType.farm) {
        final out = getFarmOutput(b.level, workers);
        _progress!.food += out;
        if (out > 0) addLog('Farm produced +$out Food (workers: $workers).');
      } else if (b.type == SurvivalBuildingType.lumberMill) {
        final out = getLumberMillOutput(b.level, workers);
        _progress!.wood += out;
        if (out > 0) addLog('Lumber Mill produced +$out Wood.');
      } else if (b.type == SurvivalBuildingType.mine) {
        final out = getMineOutput(b.level, workers);
        _progress!.iron += out;
        if (out > 0) addLog('Iron Mine produced +$out Iron (workers: $workers).');
      } else {
        final out = getAdvancedOutput(b.level, workers);
        _progress!.cash += out;
        if (out > 0) addLog('${b.type.displayName.toUpperCase()} produced +$out CHF (workers: $workers).');
      }
    }

    // 3. Apply Training XP
    for (var t in _progress!.trainingUnitIds) {
      final currentXp = _progress!.unitExp[t] ?? 0.0;
      final oldLvl = SurvivalProgress.getLevelFromXp(currentXp);
      final gainedXp = 1.0 + oldLvl;
      final nextXp = currentXp + gainedXp;
      _progress!.unitExp[t] = nextXp;
      final newLvl = SurvivalProgress.getLevelFromXp(nextXp);
      if (newLvl > oldLvl) {
        addLog('LEVEL UP! Trained ${t.toUpperCase()} has promoted to Level $newLvl!');
      } else {
        addLog('Trained ${t.toUpperCase()} gained +${gainedXp.toInt()} XP (Current: ${nextXp.toInt()} XP).');
      }
    }

    // Increment Turn Counter
    _progress!.currentTurn += 1;
    _save();
  }

  // Apply combat details to progress state
  void processCombatOutcome(
    bool playerWon,
    bool isTie,
    Map<String, double> towerFinalHealth,
    Map<String, double> combatExpAwarded, {
    List<NPC>? opponentDeck,
    int destroyedEnemyTowers = 0,
    int? customSpoilsFood,
    int? customSpoilsCash,
    int? customSpoilsIron,
    int? customSpoilsWood,
  }) {
    if (_progress == null) return;

    addLog('--- COMBAT POST-ACTION REPORT ---');

    // Apply spoils of combat
    if (playerWon && !isTie) {
      final rand = Random();
      final currentTurn = _progress!.currentTurn;

      int wildAnimals = 0;
      int humans = 0;
      int vehicles = 0;

      if (opponentDeck != null) {
        for (var npc in opponentDeck) {
          if (isWildAnimal(npc)) {
            wildAnimals++;
          } else if (npc.combatStats?.unitType == UnitType.vehicle || npc.specimenType == 'Machine') {
            vehicles++;
          } else {
            // Standard human troops / support / constructs
            humans++;
          }
        }
      }

      // Calculate Dynamic Spoils based on Opponent Deck and Destroyed Towers!
      // 1) Food: 2-3 per animal card + 10 baseline
      final spoilsFood = customSpoilsFood ?? (10 + wildAnimals * (2 + rand.nextInt(2)));
      // 2) Cash: 10-15 chf per human card + 100 + turn * 20 baseline
      final spoilsCash = customSpoilsCash ?? (100 + currentTurn * 20 + humans * (10 + rand.nextInt(6)));
      // 3) Iron: 4-6 per vehicle card
      final spoilsIron = customSpoilsIron ?? (vehicles * (4 + rand.nextInt(3)));
      // 4) Wood: 10 wood per enemy tower level destroyed (tower level = currentTurn) + 30 baseline
      final spoilsWood = customSpoilsWood ?? (30 + destroyedEnemyTowers * 10 * currentTurn);

      _progress!.cash += spoilsCash;
      _progress!.wood += spoilsWood;
      _progress!.food += spoilsFood;
      _progress!.iron += spoilsIron;

      addLog('Victory spoils: +$spoilsCash CHF | +$spoilsWood Wood | +$spoilsFood Food | +$spoilsIron Iron.');
    } else if (isTie) {
      addLog('Combat ended in a Draw! No spoils collected.');
    }

    // Apply Tower damage
    for (var entry in towerFinalHealth.entries) {
      if (entry.value <= 0.0) {
        _progress!.towerDamaged[entry.key] = 1.0; // Destroyed!
        addLog('DISASTER: ${entry.key.toUpperCase()} was destroyed in the siege!');
      }
    }

    // Apply Combat XP
    for (var entry in combatExpAwarded.entries) {
      final current = _progress!.unitExp[entry.key] ?? 0.0;
      final npc = CombatUnitService.createUnit(entry.key);
      
      double finalXp = entry.value;
      if (isUndead(npc)) {
        finalXp = 0.0; // Undead get no experience
      }
      
      final oldLvl = SurvivalProgress.getLevelFromXp(current);
      final maxAllowedLvl = oldLvl + 1;
      final maxAllowedXp = maxAllowedLvl < 7
          ? SurvivalProgress.getRequiredXpForLevel(maxAllowedLvl + 1) - 0.01
          : double.infinity;

      final nextXp = min(maxAllowedXp, max(0.0, current + finalXp));
      _progress!.unitExp[entry.key] = nextXp;
      
      final newLvl = SurvivalProgress.getLevelFromXp(nextXp);
      
      if (finalXp > 0) {
        if (newLvl > oldLvl) {
          addLog('LEVEL UP! ${entry.key.toUpperCase()} reached Level $newLvl in battle!');
        } else {
          addLog('${entry.key.toUpperCase()} gained +${finalXp.toInt()} XP in combat.');
        }
      } else if (finalXp < 0) {
        addLog('${entry.key.toUpperCase()} suffered -${(-finalXp).toInt()} XP demerits.');
      }
    }

    final isArcadeDefeat = _progress!.difficulty == SurvivalDifficulty.arcade && !playerWon && !isTie;
    if (!isArcadeDefeat) {
      _save();
    }
  }
}
