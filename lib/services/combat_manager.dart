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
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../models/combat_log_entry.dart';
import '../models/npc.dart';
import '../models/combat_stats.dart';
import '../models/schedule.dart';
import '../models/diet.dart';
import '../models/combat_map.dart';
import 'combat_unit_factory.dart';

enum CombatSide { player, enemy }

class HealingCauldron {
  final String id;
  final double x;
  final double y;
  bool isAvailable = true;
  double rechargeProgress = 1.0;
  static const double rechargeDuration = 20.0;

  HealingCauldron({
    required this.id,
    required this.x,
    required this.y,
  });
}

class FloatingMessage {
  final String text;
  final Color color;
  double lifetime; // in seconds
  double offsetY; // To stagger messages

  FloatingMessage({
    required this.text,
    required this.color,
    this.lifetime = 2.0,
    this.offsetY = 0.0,
  });
}

class Combatant {
  NPC npc;
  final CombatSide side;
  double x; // Horizontal position (0.0 to 200.0 feet)
  double y; // Vertical position (0.0 to 85.0 feet)
  double attackCooldown = 0.0;
  double freezeTimer = 0.0;
  String? targetId;
  String?
  specialActionId; // For ongoing special state (e.g. Giles moving to execute)
  String?
  specialTargetId; // The ID of the NPC being targeted by specialActionId
  bool isDead = false;
  final List<FloatingMessage> floatingMessages = [];
  double flashTimer = 0.0;
  double recentDamage = 0.0;

  // New Fields for Lane & Tower Mechanics
  int laneIndex;
  bool isTower;
  String? towerType;
  double? respawnTimer;
  int deathCount = 0;
  double specialCharge2 = 0.0;
  double? waypointX;
  double? waypointY;
  double? detourX;
  double? detourY;
  bool isAiLeader = false;

  // Regiment/Squad Fields
  String? squadId;
  String? leaderId;
  bool isSquadLeader;
  Offset? formationOffset;
  double activeDeploymentTimer;
  String? originCardName;

  Combatant({
    required this.npc,
    required this.side,
    this.x = 0.0,
    this.y = 42.5, // Center of 85ft field
    this.laneIndex = 1,
    this.isTower = false,
    this.towerType,
    this.respawnTimer,
    this.deathCount = 0,
    this.specialCharge2 = 0.0,
    this.waypointX,
    this.waypointY,
    this.detourX,
    this.detourY,
    this.isAiLeader = false,
    this.squadId,
    this.leaderId,
    this.isSquadLeader = false,
    this.formationOffset,
    this.activeDeploymentTimer = 0.0,
    this.originCardName,
  });

  // For continuous movement (Alphonse)
  double moveDirX = 0.0;
  double moveDirY = 0.0;

  double backstepTimer = 0.0;
  double backstepDirX = 0.0;
  double backstepDirY = 0.0;
  int stuckFrames = 0;

  bool isStampedeHorse = false;
  double supportDurationRemaining = 0.0;
  double gasSlowTimer = 0.0;
  double chargeDurationRemaining = 0.0;

  double get movementSpeedMultiplier {
    double mult = 1.0;
    if (gasSlowTimer > 0.0) {
      mult *= 0.4; // 60% slow
    }
    if (chargeDurationRemaining > 0.0) {
      mult *= 3.5; // 3.5x speed when charging!
    }
    return mult;
  }

  double get radius => npc.combatStats?.radius ?? 1.0;

  bool get isNonPhysicalSupport {
    return npc.combatStats?.unitType == UnitType.support &&
        (npc.combatStats?.maxHealth ?? 0) == 0;
  }
}

class Projectile {
  final String id;
  double x;
  double y;
  final double targetX;
  final double targetY;
  final CombatSide side;
  bool isExpired = false;
  final bool isSlowRocket;
  final double damage;
  final String attackerId;
  final double speed;

  Projectile({
    required this.id,
    required this.x,
    required this.y,
    required this.targetX,
    required this.targetY,
    required this.side,
    this.isSlowRocket = false,
    this.damage = 0.0,
    required this.attackerId,
    required this.speed,
  });

  void update(double dt, CombatManager manager) {
    // Physical collision hit-test against the 3 centerline impassable walls (Y inside [40, 100])
    final bool inWall = y >= 40.0 && y <= 100.0 &&
        ((x >= 70.0 && x <= 90.0) ||
         (x >= 140.0 && x <= 160.0) ||
         (x >= 210.0 && x <= 230.0));
    if (inWall) {
      isExpired = true;
      return;
    }

    final dx = targetX - x;
    final dy = targetY - y;
    final len = sqrt(dx * dx + dy * dy);
    
    if (isSlowRocket) {
      // Dodgeable slow rocket projectile: checks physical collision with active enemy targets!
      final enemyTargets = manager.combatants.where((c) => c.side != side && !c.isDead && !c.isNonPhysicalSupport).toList();
      for (final t in enemyTargets) {
        final tx = t.x - x;
        final ty = t.y - y;
        final dist = sqrt(tx * tx + ty * ty);
        if (dist < (t.npc.combatStats?.radius ?? 1.5) + 1.5) {
          manager.applyDirectDamage(t, damage, attackerId);
          isExpired = true;
          return;
        }
      }
    }

    if (len <= speed * dt || len < 0.4) {
      isExpired = true;
      x = targetX;
      y = targetY;
      return;
    }

    x += (dx / len) * speed * dt;
    y += (dy / len) * speed * dt;
  }
}

class CombatManager extends ChangeNotifier {
  CombatMap _map = CombatMap.allMaps.first;
  CombatMap get map => _map;

  set map(CombatMap val) {
    _map = val;
    notifyListeners();
  }

  final List<Combatant> _combatants = [];
  final List<Projectile> _projectiles = [];
  final List<CombatLogEntry> _logs = [];
  double _actionPoints = 6.0; // Start with 6
  static const double maxAP = 10.0;
  static const double apPerSecond = 1.0 / 3.0; // 1 point of energy every 3 seconds
  static const double fieldWidth = 140.0;
  static const double fieldLength = 300.0;

  final List<HealingCauldron> _cauldrons = [];
  List<HealingCauldron> get cauldrons => List.unmodifiable(_cauldrons);

  final List<NPC> _deck = [];
  final List<NPC> _hand = [];
  static const int maxHandSize = 5;

  // Simulation Mode Fields
  bool _isSimulation = false;
  double _aiActionPoints = 6.0;
  final List<NPC> _aiDeck = [];
  final List<NPC> _aiHand = [];
  Map<String, int> upgrades = {};
  bool isSurvivalMode = false;
  final Map<String, double> combatExp = {};
  final Map<String, NPC> _pendingRecycleSquads = {};
  final Map<String, int> _cardLevels = {};
  final Map<String, int> summonCounts = {};
  final Map<String, int> killCounts = {};
  final Map<String, double> killXpTotals = {};

  double _fieldScroll = 0.0;
  double _yFieldScroll = 0.0;
  double _manualCameraOverrideTimer = 0.0;
  double _zoomFactor = 1.0;
  bool _isScrolling = true;
  bool _isCombatActive = false;
  bool _isVictory = false;
  bool _isDefeat = false;
  double _combatTimeRemaining = 180.0;
  bool _isDraw = false;

  bool _cameraFollowPlayer = true;
  double? _targetCameraX;
  double? _targetCameraY;
  double _cameraResumeFollowDelay = 0.0;
  String _combatControlMode = 'pad';

  bool get cameraFollowPlayer => _cameraFollowPlayer;
  set cameraFollowPlayer(bool val) {
    if (_cameraFollowPlayer != val) {
      _cameraFollowPlayer = val;
      notifyListeners();
    }
  }

  double? get targetCameraX => _targetCameraX;
  double? get targetCameraY => _targetCameraY;

  double get cameraResumeFollowDelay => _cameraResumeFollowDelay;
  set cameraResumeFollowDelay(double val) {
    if (_cameraResumeFollowDelay != val) {
      _cameraResumeFollowDelay = val;
      notifyListeners();
    }
  }

  String get combatControlMode => _combatControlMode;
  set combatControlMode(String val) {
    if (_combatControlMode != val) {
      _combatControlMode = val;
      notifyListeners();
    }
  }

  void moveCameraTo(double worldX, double worldY) {
    _targetCameraX = worldX.clamp(0.0, _map.width);
    _targetCameraY = worldY.clamp(0.0, _map.height);
    _cameraFollowPlayer = false;
    notifyListeners();
  }

  final List<NPC> _killedEnemies = [];
  final Map<String, num> _accumulatedLoot = {'funds': 0, 'meat': 0};

  final List<String> _highlightedTargetIds = [];
  List<String> get highlightedTargetIds =>
      List.unmodifiable(_highlightedTargetIds);

  List<Combatant> get combatants => List.unmodifiable(_combatants);
  List<Projectile> get projectiles => List.unmodifiable(_projectiles);
  List<CombatLogEntry> get logs => List.unmodifiable(_logs);
  List<NPC> get hand => List.unmodifiable(_hand);
  List<NPC> get deck => List.unmodifiable(_deck);
  double get actionPoints => _actionPoints;
  double get fieldScroll => _fieldScroll;
  double get yFieldScroll => _yFieldScroll;
  double get zoomFactor => _zoomFactor;
  
  set zoomFactor(double val) {
    _zoomFactor = val.clamp(0.2, 1.5);
    notifyListeners();
  }

  bool get isCombatActive => _isCombatActive;
  bool get isVictory => _isVictory;
  bool get isDefeat => _isDefeat;
  double get combatTimeRemaining => _combatTimeRemaining;
  bool get isDraw => _isDraw;
  bool get isLastMinute => _combatTimeRemaining <= 60.0 && _isCombatActive;
  List<NPC> get killedEnemies => List.unmodifiable(_killedEnemies);
  Map<String, num> get accumulatedLoot => Map.unmodifiable(_accumulatedLoot);
  bool get isSimulation => _isSimulation;
  double get aiActionPoints => _aiActionPoints;
  List<NPC> get aiHand => List.unmodifiable(_aiHand);

  // Callbacks for GameState communication
  VoidCallback? onPlayerDeath;
  Function(NPC enemy)? onEnemyHeroDeath;
  Function(NPC tower)? onEnemyTowerDestroyed;
  Function(NPC enemy)? onEnemyKill;

  void spawnTower({
    required String name,
    required CombatSide side,
    required int lane,
    required double maxHealth,
    required double attack,
    required double range,
    required double speed,
    required String towerType,
  }) {
    final npc = NPC(
      id: '${side.name}_tower_$lane',
      name: name,
      role: 'Structure',
      age: 0,
      gender: 'N/A',
      specimenType: 'Structure',
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      isPlayer: false,
      bodyParts: const [],
      appearance: NPCAppearance.random(),
      combatStats: CombatStats(
        attack: attack,
        health: maxHealth,
        maxHealth: maxHealth,
        speed: speed,
        movement: 0.0,
        distance: range,
        defense: 10,
        accuracy: 0.95,
        cost: 0,
        radius: 3.0, // Small footprint structure
      ),
    );

    double x;
    double y;
    if (side == CombatSide.player) {
      if (lane == 0) {
        x = _map.playerCornerTowerX;
        y = _map.laneCenters.first;
      } else if (lane == 1) {
        x = _map.playerCornerTowerX;
        y = _map.laneCenters.last;
      } else {
        x = _map.playerCentralTowerX;
        y = _map.height / 2;
      }
    } else {
      if (lane == 0) {
        x = _map.enemyCornerTowerX;
        y = _map.laneCenters.first;
      } else if (lane == 1) {
        x = _map.enemyCornerTowerX;
        y = _map.laneCenters.last;
      } else {
        x = _map.enemyCentralTowerX;
        y = _map.height / 2;
      }
    }

    final combatant = Combatant(
      npc: npc,
      side: side,
      x: x,
      y: y,
      laneIndex: _map.laneCenters.length == 3 
          ? (lane == 0 ? 0 : (lane == 1 ? 2 : 1)) 
          : (lane == 2 ? 0 : lane),
      isTower: true,
      towerType: towerType,
    );

    _combatants.add(combatant);
    notifyListeners();
  }

  void setupTowersForEncounter(String encounterTitle) {
    _combatants.removeWhere((c) => c.isTower);

    String playerTowerType = 'wagon';
    String enemyTowerType = 'wagon';
    double enemyHealth = 600.0;
    double enemyAttack = 15.0;
    double enemyRange = 20.0; // Overlapping field of fire
    double enemySpeed = 2.0;
    
    String playerTowerName = 'Covered Wagon';
    String enemyTowerName = 'Covered Wagon';

    if (isSurvivalMode) {
      playerTowerType = 'watchtower';
      playerTowerName = 'Watchtower';
      if (encounterTitle.contains("Beasts") || encounterTitle.contains("Animals") || encounterTitle.contains("Feral")) {
        enemyTowerType = 'animal_den';
        enemyTowerName = 'Feral Den';
        enemyHealth = 500.0;
        enemyAttack = 10.0;
      } else {
        enemyTowerType = 'wagon';
        enemyTowerName = 'Supply Wagon';
        enemyHealth = 600.0;
        enemyAttack = 15.0;
      }
    } else {
      if (encounterTitle.contains("Highwaymen") || encounterTitle.contains("Bandits")) {
        playerTowerType = 'wagon';
        enemyTowerType = 'wagon_musket';
        enemyTowerName = 'Armored Wagon';
        enemyHealth = 800.0;
        enemyAttack = 20.0;
      } else if (encounterTitle.contains("Beasts") || encounterTitle.contains("Animals") || encounterTitle.contains("Feral")) {
        playerTowerType = 'wagon';
        enemyTowerType = 'animal_den';
        enemyTowerName = 'Feral Den';
        enemyHealth = 500.0;
        enemyAttack = 10.0;
        enemyRange = 20.0;
      } else if (encounterTitle.contains("Bologna") || encounterTitle.contains("City")) {
        playerTowerType = 'tower_house';
        enemyTowerType = 'tower_house';
        playerTowerName = 'Tower House';
        enemyTowerName = 'Tower House';
        enemyHealth = 1000.0;
        enemyAttack = 25.0;
      } else if (encounterTitle.contains("Fortress") || encounterTitle.contains("Castle")) {
        playerTowerType = 'fortification';
        enemyTowerType = 'castle_keep';
        playerTowerName = 'Field Fortification';
        enemyTowerName = 'Castle Tower';
        enemyHealth = 1500.0;
        enemyAttack = 40.0;
        enemyRange = 20.0;
      }
    }

    // Spawn 3 player towers
    final int hpLvl = upgrades['tower_hp'] ?? 0;
    final int atkLvl = upgrades['tower_atk'] ?? 0;
    final int rangeLvl = upgrades['tower_range'] ?? 0;
    final int speedLvl = upgrades['tower_speed'] ?? 0;

    for (int lane = 0; lane < 3; lane++) {
      final String towerId = lane == 0 ? 'tower_3' : (lane == 1 ? 'tower_1' : 'tower_2');
      final int indHpLvl = upgrades['${towerId}_hp'] ?? 0;
      final int indAtkLvl = upgrades['${towerId}_atk'] ?? 0;
      final int indRangeLvl = upgrades['${towerId}_range'] ?? 0;
      final int indSpeedLvl = upgrades['${towerId}_speed'] ?? 0;

      final double upgradedMaxHealth = 600.0 * (1.0 + hpLvl * 0.15 + indHpLvl * 0.08);
      final double upgradedAttack = 15.0 * (1.0 + atkLvl * 0.15 + indAtkLvl * 0.08);
      final double upgradedRange = 20.0 + (rangeLvl * 2.5) + (indRangeLvl * 1.5);
      final double upgradedSpeed = (2.0 - (speedLvl * 0.2) - (indSpeedLvl * 0.1)).clamp(0.4, 2.0);

      final String tName = isSurvivalMode
          ? (towerId == 'tower_1'
              ? 'West Watchtower'
              : (towerId == 'tower_2' ? 'Middle Watchtower' : 'East Watchtower'))
          : '$playerTowerName ${lane + 1}';

      spawnTower(
        name: tName,
        side: CombatSide.player,
        lane: lane,
        maxHealth: upgradedMaxHealth,
        attack: upgradedAttack,
        range: upgradedRange,
        speed: upgradedSpeed,
        towerType: playerTowerType,
      );
    }

    // Spawn 3 enemy towers
    for (int lane = 0; lane < 3; lane++) {
      spawnTower(
        name: '$enemyTowerName ${lane + 1}',
        side: CombatSide.enemy,
        lane: lane,
        maxHealth: enemyHealth,
        attack: enemyAttack,
        range: enemyRange, // Overlapping field of fire
        speed: enemySpeed,
        towerType: enemyTowerType,
      );
    }
  }

  void _addLog(String message, {CombatSide? side}) {
    _logs.insert(0, CombatLogEntry(message: message, side: side));
    if (_logs.length > 50) _logs.removeLast();
    notifyListeners();
  }

  void _addFloatingMessage(Combatant c, String text, Color color) {
    // Offset based on existing messages
    double offset = 0.0;
    if (c.floatingMessages.isNotEmpty) {
      offset = c.floatingMessages.map((m) => m.offsetY).reduce(max) + 20.0;
    }
    c.floatingMessages.add(
      FloatingMessage(text: text, color: color, offsetY: offset),
    );
    notifyListeners();
  }

  void prepareDeck(List<NPC> units) {
    _deck.clear();
    for (var u in units) {
      if (u.id == 'butler' || u.role == 'Butler') {
        final musketeer = CombatUnitFactory.createMusketeers();
        final abilities = List<Ability>.from(u.abilities);
        if (!abilities.any((a) => a.id == 'execute_low_health')) {
          abilities.add(const Ability(
            id: 'execute_low_health',
            name: 'Execute',
            type: AbilityType.special,
            description: 'Instantly kills an enemy unit with less than 50% health.',
            chargeTime: 7.0,
            effectData: {'threshold': 0.5, 'type': 'interrupt_kill'},
          ));
        }
        final transformed = u.copyWith(
          combatStats: musketeer.combatStats,
          abilities: abilities,
        );
        _deck.add(transformed);
      } else {
        _deck.add(u);
      }
    }
    _deck.shuffle();
    _hand.clear();
    _pendingRecycleSquads.clear();
    _cardLevels.clear();
    summonCounts.clear();
    killCounts.clear();
    killXpTotals.clear();
    combatExp.clear();
    for (int i = 0; i < maxHandSize && _deck.isNotEmpty; i++) {
      _hand.add(_deck.removeAt(0));
    }
  }

  void setupAIDeck(List<NPC> units) {
    _aiHand.clear();
    _aiDeck.clear();
    _aiDeck.addAll(units);
    _aiDeck.shuffle();
    for (int i = 0; i < maxHandSize && _aiDeck.isNotEmpty; i++) {
      _aiHand.add(_aiDeck.removeAt(0));
    }
    _aiActionPoints = 6.0;
  }

  void drawCard() {
    if (_hand.length < maxHandSize && _deck.isNotEmpty) {
      // Find a card that isn't currently alive on the field
      final aliveIds = _combatants
          .where((c) => !c.isDead)
          .map((c) => c.npc.id)
          .toSet();

      NPC? toDraw;
      int drawIndex = -1;

      for (int i = 0; i < _deck.length; i++) {
        if (!aliveIds.contains(_deck[i].id)) {
          toDraw = _deck[i];
          drawIndex = i;
          break;
        }
      }

      if (toDraw != null) {
        _deck.removeAt(drawIndex);
        _hand.add(toDraw);
        notifyListeners();
      }
    }
  }

  void startCombat() {
    _isCombatActive = true;
    _isScrolling = true;
    _isDefeat = false;
    _isVictory = false;
    _combatTimeRemaining = 180.0;
    _isDraw = false;
    _killedEnemies.clear();
    _accumulatedLoot.updateAll((key, value) => 0);
    _cameraFollowPlayer = true;
    _targetCameraX = null;
    _targetCameraY = null;
    _cameraResumeFollowDelay = 0.0;
    _combatControlMode = 'pad';

    _cauldrons.clear();
    _cauldrons.addAll([
      HealingCauldron(id: 'c1', x: 20.0, y: 50.0),
      HealingCauldron(id: 'c2', x: 20.0, y: 90.0),
      HealingCauldron(id: 'c3', x: 280.0, y: 50.0),
      HealingCauldron(id: 'c4', x: 280.0, y: 90.0),
    ]);

    notifyListeners();
  }

  void setupSimulation(List<NPC> playerDeck, List<NPC> aiDeck) {
    _isSimulation = true;
    prepareDeck(playerDeck);

    _aiHand.clear();
    _aiDeck.clear();
    _aiDeck.addAll(aiDeck);
    _aiDeck.shuffle();
    for (int i = 0; i < maxHandSize && _aiDeck.isNotEmpty; i++) {
      _aiHand.add(_aiDeck.removeAt(0));
    }

    _aiActionPoints = 6.0;
  }

  Offset _getFormationOffset(int index) {
    switch (index) {
      case 0: return const Offset(-2.5, -2.5);
      case 1: return const Offset(-2.5, 2.5);
      case 2: return const Offset(-5.0, -5.0);
      case 3: return const Offset(-5.0, 5.0);
      case 4: return const Offset(-7.5, 0.0);
      case 5: return const Offset(-7.5, -2.5);
      case 6: return const Offset(-7.5, 2.5);
      case 7: return const Offset(-10.0, 0.0);
      default: return Offset(-2.5 * (index ~/ 2 + 1).toDouble(), (index % 2 == 0 ? -2.5 : 2.5));
    }
  }

  bool isValidPlacement(NPC npc, double worldX, double worldY) {
    if (npc.isPlayer) return true;

    final stats = npc.combatStats;
    if (stats == null) return false;

    final isSupport = npc.name.contains('Barrage') ||
        npc.name.contains('Artillery') ||
        npc.name.contains('Gas') ||
        npc.name.contains('Tear') ||
        npc.name.contains('Caltrops') ||
        npc.name.contains('Totem') ||
        stats.unitType == UnitType.support;

    // If 2 channels, block non-support units in the central 30% band of the battlefield
    if (_map.laneCenters.length == 2 && !isSupport && worldX > 0.2 * _map.width) {
      final centerY = _map.height / 2.0;
      final halfBand = _map.height * 0.15;
      if (worldY >= centerY - halfBand && worldY <= centerY + halfBand) {
        return false;
      }
    }

    // Always allow casting anywhere in the player's back 20% of the field
    if (worldX <= 0.2 * _map.width) {
      return true;
    }

    if (isSupport) {
      final alphonse = _combatants.firstWhereOrNull((c) => c.npc.isPlayer && !c.isDead);
      if (alphonse == null) return false;

      if (npc.name.contains('Barrage') || npc.name.contains('Artillery')) {
        if (worldX > 0.8 * _map.width) {
          final hasPresence = _combatants.any((c) => c.side == CombatSide.player && !c.isDead && c.x >= 0.7 * _map.width);
          if (!hasPresence) return false;
        }
        return true;
      } else if (npc.name.contains('Gas') || npc.name.contains('Tear')) {
        final dist = sqrt(pow(worldX - alphonse.x, 2) + pow(worldY - alphonse.y, 2));
        return dist <= 0.25 * _map.width;
      } else if (npc.name.contains('Caltrops')) {
        final dist = sqrt(pow(worldX - alphonse.x, 2) + pow(worldY - alphonse.y, 2));
        return dist <= 5.0;
      } else if (npc.name.contains('Totem') || npc.name.contains('Vampiric')) {
        return isValidPlacementForTroop(worldX, worldY);
      }
      return true;
    } else {
      return isValidPlacementForTroop(worldX, worldY);
    }
  }

  bool isValidPlacementForTroop(double worldX, double worldY) {
    if (worldX > 0.8 * _map.width) return false;
    final double startingZoneLimit = 0.2 * _map.width;
    if (worldX > startingZoneLimit) {
      if (_map.laneCenters.length == 2) {
        final alphonse = _combatants.firstWhereOrNull((c) => c.npc.isPlayer && !c.isDead);
        if (alphonse != null) {
          final double centerY = _map.height / 2.0;
          final bool playerOnTop = alphonse.y < centerY;
          final bool targetOnTop = worldY < centerY;
          if (playerOnTop != targetOnTop) {
            return false;
          }
        }
      }

      int targetLaneIdx = 0;
      double minDist = 99999.0;
      for (int i = 0; i < _map.laneCenters.length; i++) {
        final dist = (worldY - _map.laneCenters[i]).abs();
        if (dist < minDist) {
          minDist = dist;
          targetLaneIdx = i;
        }
      }

      // Determine checking region of the field based on the lane index
      double minY;
      double maxY;

      if (_map.laneCenters.length == 3 && targetLaneIdx == 1) {
        // Middle lane for 3-lane maps: middle 40% of the field
        minY = 0.3 * _map.height;
        maxY = 0.7 * _map.height;
      } else {
        // Top lane(s) correspond to the top half, bottom lane(s) to the bottom half (with a 5-unit center line buffer)
        if (targetLaneIdx == 0) {
          minY = 0.0;
          maxY = _map.height / 2.0 + 5.0;
        } else {
          minY = _map.height / 2.0 - 5.0;
          maxY = _map.height;
        }
      }

      bool hasUnitAhead = false;
      for (final c in _combatants) {
        if (c.side == CombatSide.player && !c.isDead && !c.isTower) {
          if (c.y >= minY && c.y <= maxY && c.x >= worldX) {
            hasUnitAhead = true;
            break;
          }
        }
      }
      if (!hasUnitAhead) return false;
    }
    return true;
  }

  bool spawnUnit(NPC npc, CombatSide side, {double? x, double? y, bool isAiLeader = false}) {
    final stats = npc.combatStats;
    if (stats == null) return false;

    if (side == CombatSide.player) {
      final playerCharacter = _combatants.firstWhereOrNull((c) => c.npc.isPlayer);
      if (playerCharacter != null && playerCharacter.isDead) return false;
    }

    // 1. Calculate proposed spawn location
    final double spawnX = x ?? (side == CombatSide.player ? (_fieldScroll + 15.0) : (_fieldScroll + 190.0));
    final double spawnY = (y ?? (Random().nextDouble() * _map.height)).clamp(2.0, _map.height - 2.0);

    // 2. Enforce player spawn limits
    if (side == CombatSide.player) {
      if (!isValidPlacement(npc, spawnX, spawnY)) return false;
    }

    // 3. Check and deduct Action Points
    if (side == CombatSide.player && _actionPoints < stats.cost) return false;

    if (side == CombatSide.player) {
      _actionPoints -= stats.cost;
      _hand.removeWhere((n) => n.id == npc.id);
      drawCard();
    }

    // Find closest lane center index
    int closestLaneIdx = 0;
    double minDist = 99999.0;
    for (int i = 0; i < _map.laneCenters.length; i++) {
      final dist = (spawnY - _map.laneCenters[i]).abs();
      if (dist < minDist) {
        minDist = dist;
        closestLaneIdx = i;
      }
    }

    // Snap Y coordinate to closest lane center for Artillery Barrage so it perfectly matches the preview
    double finalSpawnY = spawnY;
    if (npc.name.contains('Barrage') || npc.name.contains('Artillery')) {
      finalSpawnY = _map.laneCenters[closestLaneIdx];
    }

    // Generate unique squad ID
    final String squadId = 'squad_${npc.id}_${DateTime.now().microsecondsSinceEpoch}';

    double initialSupportDuration = 0.0;
    if (stats.unitType == UnitType.support) {
      if (npc.name.contains('Barrage') || npc.name.contains('Artillery')) {
        initialSupportDuration = 3.0;
      } else if (npc.name.contains('Gas') || npc.name.contains('Tear')) {
        initialSupportDuration = 6.0;
      } else if (npc.name.contains('Stampede')) {
        initialSupportDuration = 12.0;
      } else {
        initialSupportDuration = 60.0; // Default for Caltrops, Vampiric Totem, etc.
      }
    }

    Combatant? spawnedLeader;
    if (npc.name.contains('Stampede')) {
      final offsets = [
        const Offset(0, 0),
        const Offset(-6.0, -5.0),
        const Offset(-6.0, 5.0),
        const Offset(-12.0, -10.0),
        const Offset(-12.0, 10.0),
      ];
      for (int i = 0; i < 5; i++) {
        final horse =
            Combatant(
                npc: npc.copyWith(
                  id: '${npc.id}_horse_$i',
                  name: 'Stampede Horse',
                ),
                side: side,
                x: spawnX + offsets[i].dx,
                y: (finalSpawnY + offsets[i].dy).clamp(2.0, _map.height - 2.0),
                laneIndex: closestLaneIdx,
                isTower: false,
                isAiLeader: isAiLeader,
                squadId: squadId,
                isSquadLeader: i == 0,
                activeDeploymentTimer: stats.deploymentTime,
                originCardName: npc.name,
              )
              ..supportDurationRemaining = initialSupportDuration
              ..isStampedeHorse = true;
        _combatants.add(horse);
        if (i == 0) spawnedLeader = horse;
      }
    } else {
      // Spawn the Leader
      final leader = Combatant(
        npc: npc,
        side: side,
        x: spawnX,
        y: finalSpawnY,
        laneIndex: closestLaneIdx,
        isTower: false,
        isAiLeader: isAiLeader,
        squadId: squadId,
        isSquadLeader: true,
        activeDeploymentTimer: stats.deploymentTime,
        originCardName: npc.name,
      )..supportDurationRemaining = initialSupportDuration;

      _combatants.add(leader);
      spawnedLeader = leader;
    }

    if (side == CombatSide.player && isSurvivalMode) {
      final cardType = npc.metadata['cardType'];
      if (cardType != null) {
        final lvl = npc.metadata['level'] as int? ?? 1;
        _cardLevels[cardType] = lvl;
        summonCounts[cardType] = (summonCounts[cardType] ?? 0) + 1;
      }
    }

    // Spawn Followers if unit count > 1
    if (stats.unitCount > 1) {
      final followersToSpawn = stats.unitCount - 1;
      for (int i = 0; i < followersToSpawn; i++) {
        final offset = _getFormationOffset(i);
        
        // Calculate spawn position based on offset direction
        final double followerX = (spawnX + (side == CombatSide.player ? offset.dx : -offset.dx));
        final double followerY = (spawnY + offset.dy).clamp(2.0, _map.height - 2.0);

        final isButlerSquad = npc.id == 'butler' || npc.role == 'Butler';
        final followerName = isButlerSquad ? 'Musketeer' : '${npc.name} Recruit';
        final followerAppearance = isButlerSquad
            ? NPCAppearance.deterministic('Musketeers')
            : npc.appearance;

        final followerNpc = NPC(
          id: '${npc.id}_follower_${i}_${DateTime.now().microsecondsSinceEpoch}',
          name: followerName,
          age: npc.age,
          gender: npc.gender,
          specimenType: npc.specimenType,
          role: 'Troop',
          bodyParts: npc.bodyParts,
          schedule: npc.schedule,
          diet: npc.diet,
          appearance: followerAppearance,
          combatStats: stats.copyWith(unitCount: 1), // Followers themselves represent single entities
          metadata: npc.metadata, // Copy metadata including cardType!
        );

        final follower = Combatant(
          npc: followerNpc,
          side: side,
          x: followerX,
          y: followerY,
          laneIndex: closestLaneIdx,
          isTower: false,
          squadId: squadId,
          leaderId: npc.id,
          isSquadLeader: false,
          formationOffset: offset,
          activeDeploymentTimer: stats.deploymentTime,
          originCardName: npc.name,
        );

        _combatants.add(follower);
      }
    }

    // Trigger Horn abilities
    if (spawnedLeader != null) {
      for (final ability in npc.abilities) {
        if (ability.type == AbilityType.horn) {
          _applyAbilityEffect(spawnedLeader, ability);
        }
      }
    }

    notifyListeners();
    return true;
  }

  void _aiDrawCard() {
    if (_aiHand.length < maxHandSize && _aiDeck.isNotEmpty) {
      final npc = _aiDeck.removeAt(0);
      _aiHand.add(npc);
      if (_isSimulation) {
        _aiDeck.add(
          npc.copyWith(
            id: '${npc.id}_refill_${DateTime.now().microsecondsSinceEpoch}',
          ),
        );
      }
      notifyListeners();
    }
  }

  void update(double dt) {
    if (!_isCombatActive) return;

    // Decrement camera resume follow delay
    if (_cameraResumeFollowDelay > 0.0) {
      _cameraResumeFollowDelay = max(0.0, _cameraResumeFollowDelay - dt);
    }

    // 0. Decrement combat timer
    _combatTimeRemaining = max(0.0, _combatTimeRemaining - dt);

    // 1. AP Generation (doubled in final minute)
    final rateMultiplier = (_combatTimeRemaining <= 60.0) ? 2.0 : 1.0;
    _actionPoints = min(maxAP, _actionPoints + apPerSecond * rateMultiplier * dt);

    // 1b. Projectile Ticks
    for (var p in _projectiles) {
      p.update(dt, this);
    }
    _projectiles.removeWhere((p) => p.isExpired);

    // 2. Battlefield Scrolling (Gradual camera follow/centering on player character)
    if (_combatants.isNotEmpty) {
      final alphonse = _combatants.firstWhere(
        (c) => c.npc.isPlayer,
        orElse: () => _combatants.first,
      );

      // Update manual camera override timer
      if (_manualCameraOverrideTimer > 0.0) {
        _manualCameraOverrideTimer -= dt;
      }

      // Determine if we should auto-scroll forward when no enemies remain
      final hasEnemies = _combatants.any(
        (c) => c.side == CombatSide.enemy && !c.isDead,
      );
      _isScrolling = !hasEnemies;

      if (_isScrolling && _combatControlMode != 'click') {
        // Auto-drift Alphonse forward if they are not moving manually
        if (alphonse.moveDirX == 0) {
          alphonse.x += alphonse.npc.combatStats!.movement * dt * 3.75;
          enforceUnitBoundaries(alphonse);
        }
      }



      if (_cameraFollowPlayer) {
        if (_manualCameraOverrideTimer <= 0.0) {
          // Target scroll coordinates to center on as much battlefield as possible
          // focused above and to the right of the character (shifting camera target to the right and up)
          final targetFieldScroll = (alphonse.x + 35.0 / _zoomFactor).clamp(0.0, _map.width);
          final targetYFieldScroll = (alphonse.y - 12.0 / _zoomFactor).clamp(0.0, _map.height);

          // Lerp smoothly with a factor of 1.5 so it takes ~2 full seconds to completely transition
          _fieldScroll += (targetFieldScroll - _fieldScroll) * 1.5 * dt;
          _yFieldScroll += (targetYFieldScroll - _yFieldScroll) * 1.5 * dt;
        }
      } else {
        if (_targetCameraX != null && _targetCameraY != null) {
          _fieldScroll += (_targetCameraX! - _fieldScroll) * 3.0 * dt;
          _yFieldScroll += (_targetCameraY! - _yFieldScroll) * 3.0 * dt;
        }
      }
    }

    // 3. Unit Ticks
    for (final c in _combatants) {
      if (c.isDead) continue;

      // Update freeze and flash timers
      if (c.freezeTimer > 0) {
        c.freezeTimer -= dt;
      }
      if (c.flashTimer > 0.0) {
        c.flashTimer = max(0.0, c.flashTimer - dt);
      }

      // Update floating messages
      c.floatingMessages.removeWhere((m) {
        m.lifetime -= dt;
        return m.lifetime <= 0;
      });

      if (c.freezeTimer > 0) continue; // Skip movement/attack while frozen

      _processUnitTick(c, dt);
    }

    // 4. Cleanup dead units (with Hero and Tower exclusions)
    _combatants.removeWhere((c) {
      if (c.isDead) {
        // If it is a tower or a hero, DO NOT remove it from the active battlefield!
        if (c.isTower || c.npc.isPlayer || c.isAiLeader) {
          if (c.respawnTimer == null && (c.npc.isPlayer || c.isAiLeader)) {
            // Trigger first-time death and set respawn
            c.deathCount++;
            double respawnDuration = 5.0;
            c.respawnTimer = respawnDuration;
            c.waypointX = null;
            c.waypointY = null;
            c.detourX = null;
            c.detourY = null;
            c.moveDirX = 0.0;
            c.moveDirY = 0.0;
            _addLog('${c.npc.name} has fainted and will respawn in ${respawnDuration.toInt()} seconds.', side: c.side);
            
            // Invoke state callbacks
            if (c.side == CombatSide.player && c.npc.isPlayer) {
              onPlayerDeath?.call();
              _cameraFollowPlayer = true;
            } else if (c.side == CombatSide.enemy && c.isAiLeader) {
              onEnemyHeroDeath?.call(c.npc);
            }
          } else if (c.isTower) {
            // Trigger first-time tower destruction
            if (c.npc.role != 'Ruins') {
              _addLog('${c.npc.name} has been destroyed!', side: c.side);
              c.npc = c.npc.copyWith(role: 'Ruins'); // Mutate role to stop duplicate alerts
              
              if (c.side == CombatSide.enemy) {
                onEnemyTowerDestroyed?.call(c.npc);
              }
            }
          }
          return false; // Keep in the list so we can draw them as ruins or tick respawn
        }

        _addLog('${c.npc.name} has been vanquished.', side: c.side);
        // Trigger Knell abilities before removal
        for (final ability in c.npc.abilities) {
          if (ability.type == AbilityType.knell) {
            _applyAbilityEffect(c, ability);
          }
        }
        // Return player units to deck (Only recycle the main Squad Leader card when the ENTIRE squad is dead)
        if (c.side == CombatSide.player && !c.npc.isPlayer) {
          final String? sqId = c.squadId;
          if (sqId != null) {
            final bool anyOthersAlive = _combatants.any((other) => other != c && other.squadId == sqId && !other.isDead);
            if (c.isSquadLeader) {
              final resetNpc = c.npc.copyWith(
                combatStats: c.npc.combatStats?.copyWith(
                  health: c.npc.combatStats?.maxHealth,
                ),
                specialCharge: 0.0,
                status: NPCStatus.idle,
              );
              if (anyOthersAlive) {
                _pendingRecycleSquads[sqId] = resetNpc;
              } else {
                _deck.add(resetNpc);
              }
            } else {
              if (!anyOthersAlive) {
                final leaderNpc = _pendingRecycleSquads.remove(sqId);
                if (leaderNpc != null) {
                  _deck.add(leaderNpc);
                }
              }
            }
          }
        } else if (c.side == CombatSide.enemy) {
          _killedEnemies.add(c.npc);
          
          // Trigger standard kill callback
          onEnemyKill?.call(c.npc);
          
          // Roll for loot
          final rand = Random();
          if (rand.nextDouble() < 0.4) {
            _accumulatedLoot['funds'] =
                (_accumulatedLoot['funds'] ?? 0) + 5 + rand.nextInt(15);
          }
          if (rand.nextDouble() < 0.6) {
            _accumulatedLoot['meat'] =
                (_accumulatedLoot['meat'] ?? 0) + 1 + rand.nextInt(3);
          }
        }
        return true;
      }
      return false;
    });

    // 4b. Hero Respawn Tick
    for (final c in _combatants) {
      if (c.isDead && c.respawnTimer != null) {
        c.respawnTimer = max(0.0, c.respawnTimer! - dt);
        if (c.respawnTimer! <= 0.0) {
          c.isDead = false;
          c.respawnTimer = null;
          c.waypointX = null;
          c.waypointY = null;
          c.detourX = null;
          c.detourY = null;
          c.moveDirX = 0.0;
          c.moveDirY = 0.0;
          
          // Reset health
          c.npc = c.npc.copyWith(
            combatStats: c.npc.combatStats?.copyWith(
              health: c.npc.combatStats?.maxHealth,
            ),
          );
          
          // Respawn at home zone
           if (c.side == CombatSide.player) {
            final centralTower = _combatants.firstWhereOrNull(
              (t) => t.isTower && t.side == CombatSide.player && (t.x - _map.playerCentralTowerX).abs() < 5.0 && !t.isDead
            );
            if (centralTower != null) {
              c.x = _map.playerCornerTowerX;
              c.y = _map.height / 2;
            } else {
              final standing = _combatants.where(
                (t) => t.isTower && t.side == CombatSide.player && !t.isDead
              ).toList();
              if (standing.isNotEmpty) {
                final pick = standing[Random().nextInt(standing.length)];
                c.x = pick.x + 15.0;
                c.y = pick.y;
              } else {
                c.x = _map.playerCornerTowerX;
                c.y = _map.height / 2;
              }
            }
          } else {
            c.x = _map.enemyCornerTowerX;
            c.y = _map.height / 2;
            
            if (c.isAiLeader) {
              // Clear and refill AI deck/hand upon respawn so they continue summoning fresh guards!
              _aiDeck.clear();
              _aiHand.clear();
              _aiDeck.addAll([
                CombatUnitFactory.createGoon(),
                CombatUnitFactory.createGoon(),
                CombatUnitFactory.createMilitia(),
                CombatUnitFactory.createMilitia(),
              ]);
            }
          }
          c.attackCooldown = 0.0;
          
          if (c.npc.isPlayer) {
            _fieldScroll = 0.0; // Reset camera scroll to show home base respawn
            _cameraFollowPlayer = true;
          }
          
          _addLog('${c.npc.name} has respawned!', side: c.side);
        }
      }
    }

    // 5. Replenish Hands (Continuous Draw)
    if (_hand.length < maxHandSize && _deck.isNotEmpty) {
      drawCard();
    }
    if (_aiHand.length < maxHandSize && _aiDeck.isNotEmpty) {
      _aiDrawCard();
    }

    // 6. AI Mirror Logic
    if (_isCombatActive) {
      final rateMultiplier = (_combatTimeRemaining <= 60.0) ? 2.0 : 1.0;
      _aiActionPoints = min(maxAP, _aiActionPoints + apPerSecond * rateMultiplier * dt);

      // AI Spawning Strategy: Spawn the most expensive thing we can afford from hand
      if (_aiHand.isNotEmpty) {
        _aiHand.sort(
          (a, b) =>
              (b.combatStats?.cost ?? 0).compareTo(a.combatStats?.cost ?? 0),
        );
        for (var i = 0; i < _aiHand.length; i++) {
          final unit = _aiHand[i];

          // Prevent the NPC opponent from summoning a unit that is already on the board.
          // If a card/unit is already in play, it cannot be summoned again until all active instances are eliminated.
          final bool isAlreadyOnBoard = _combatants.any((c) {
            if (c.side != CombatSide.enemy ||
                c.isDead ||
                c.isTower ||
                c.isAiLeader) {
              return false;
            }

            final uCardType = unit.metadata['cardType'];
            final cCardType = c.npc.metadata['cardType'];
            if (uCardType != null && cCardType != null && uCardType == cCardType) {
              return true;
            }

            final String uBaseId = unit.id.split('_').first;
            final String cBaseId = c.npc.id.split('_').first;
            if (uBaseId == cBaseId && uBaseId.length > 2) {
              return true;
            }

            final String uName = unit.name.replaceAll('s', '').trim().toLowerCase();
            final String oName = (c.originCardName ?? c.npc.name).replaceAll('s', '').trim().toLowerCase();
            final String cName = c.npc.name.replaceAll('s', '').trim().toLowerCase();

            return oName == uName ||
                cName == uName ||
                cName.startsWith(uName) ||
                oName.startsWith(uName) ||
                uName.startsWith(oName) ||
                (unit.name.contains('Stampede') && (oName.contains('stampede') || cName.contains('stampede'))) ||
                (unit.name == 'Butler' && (oName.contains('butler') || cName.contains('musketeer')));
          });

          if (isAlreadyOnBoard) continue;

          final cost = unit.combatStats?.cost ?? 0;
          if (_aiActionPoints >= cost) {
            _aiActionPoints -= cost;
            _aiHand.removeAt(i);
            
            // Pick a random lane Y coordinate to spawn
            final lane = Random().nextInt(_map.laneCenters.length);
            final spawnYs = _map.laneCenters;
            
            // Find the active AI Leader if alive
            final aiLeader = _combatants.firstWhereOrNull(
              (c) => c.side == CombatSide.enemy && c.isAiLeader && !c.isDead
            );
            
            // If AI Leader is alive, spawn slightly behind them (to their right, since they march left).
            // Otherwise, spawn near the enemy base/corner tower.
            final double spawnX;
            if (aiLeader != null) {
              spawnX = (aiLeader.x + 25.0).clamp(100.0, _map.width - 20.0);
            } else {
              spawnX = (_map.enemyCornerTowerX - 20.0).clamp(100.0, _map.width - 20.0);
            }
            
            spawnUnit(unit, CombatSide.enemy, x: spawnX, y: spawnYs[lane]);
            break; // One per tick
          }
        }
      }
    }

    // Cauldron Ticks
    for (final cauldron in _cauldrons) {
      if (!cauldron.isAvailable) {
        cauldron.rechargeProgress = min(1.0, cauldron.rechargeProgress + dt / HealingCauldron.rechargeDuration);
        if (cauldron.rechargeProgress >= 1.0) {
          cauldron.isAvailable = true;
        }
      }

      // Check proximity to player's character or opponent's character
      if (cauldron.isAvailable) {
        final characters = _combatants.where((c) => !c.isDead && (c.npc.isPlayer || c.isAiLeader));
        for (final character in characters) {
          final dist = sqrt(pow(character.x - cauldron.x, 2) + pow(character.y - cauldron.y, 2));
          if (dist < 8.0) {
            final stats = character.npc.combatStats!;
            // rough 1/3 of Alphonse's overall health (assume ~300/500, let's use stats.maxHealth / 3.0)
            final healAmount = stats.maxHealth / 3.0;
            character.npc = character.npc.copyWith(
              combatStats: stats.copyWith(
                health: min(stats.maxHealth, stats.health + healAmount),
              ),
            );
            
            // Trigger cooldown
            cauldron.isAvailable = false;
            cauldron.rechargeProgress = 0.0;

            _addLog('${character.npc.name} consumed a meal and healed for ${healAmount.toInt()} HP!', side: character.side);
            _addFloatingMessage(character, '+${healAmount.toInt()} HP', Colors.greenAccent);
            break; // Only one character can consume it per tick
          }
        }
      }
    }

    // 7. Win/Loss/Draw Conditions (Victory Point-Based)
    final playerTowers = _combatants.where((c) => c.isTower && c.side == CombatSide.player);
    final enemyTowers = _combatants.where((c) => c.isTower && c.side == CombatSide.enemy);

    final playerVPs = enemyTowers.where((t) => t.isDead).length;
    final enemyVPs = playerTowers.where((t) => t.isDead).length;

    if (enemyVPs >= 3) {
      _isDefeat = true;
      _isCombatActive = false;
      _projectiles.clear();
    } else if (playerVPs >= 3) {
      _isVictory = true;
      _isCombatActive = false;
      _projectiles.clear();
    } else if (_combatTimeRemaining <= 0.0) {
      _isCombatActive = false;
      _projectiles.clear();
      if (playerVPs > enemyVPs) {
        _isVictory = true;
      } else if (enemyVPs > playerVPs) {
        _isDefeat = true;
      } else {
        _isDraw = true;
      }
    }
    if (!_isCombatActive) {
      _finalizeCombatExp();
    }

    notifyListeners();
  }

  bool _isPointInWall(double x, double y) {
    for (final rect in _map.walls) {
      final padded = Rect.fromLTRB(
        rect.left - 2.0,
        rect.top - 2.0,
        rect.right + 2.0,
        rect.bottom + 2.0,
      );
      if (padded.contains(Offset(x, y))) {
        return true;
      }
    }
    return false;
  }

  bool _segmentsIntersect(double ax, double ay, double bx, double by, double cx, double cy, double dx, double dy) {
    final double denominator = (bx - ax) * (dy - cy) - (by - ay) * (dx - cx);
    if (denominator == 0) return false; // Parallel or collinear

    final double u = ((cx - ax) * (dy - cy) - (cy - ay) * (dx - cx)) / denominator;
    final double v = ((cx - ax) * (by - ay) - (cy - ay) * (bx - ax)) / denominator;

    return u >= 0.0 && u <= 1.0 && v >= 0.0 && v <= 1.0;
  }

  bool isPathObstructed(double x1, double y1, double x2, double y2) {
    for (final rect in _map.walls) {
      // Padded walls check to ensure safe buffer clearance
      final double L = rect.left - 2.0;
      final double T = rect.top - 2.0;
      final double R = rect.right + 2.0;
      final double B = rect.bottom + 2.0;

      // Path is obstructed if it intersects any of the 4 edges of the padded wall
      if (_segmentsIntersect(x1, y1, x2, y2, L, T, L, B) ||
          _segmentsIntersect(x1, y1, x2, y2, R, T, R, B) ||
          _segmentsIntersect(x1, y1, x2, y2, L, T, R, T) ||
          _segmentsIntersect(x1, y1, x2, y2, L, B, R, B)) {
        return true;
      }
    }
    return false;
  }

  void enforceUnitBoundaries(Combatant unit) {
    if (unit.isDead || unit.isTower) return;
    unit.x = unit.x.clamp(0.0, _map.width);
    unit.y = unit.y.clamp(2.0, _map.height - 2.0);

    if (_isPointInWall(unit.x, unit.y)) {
      Rect? closestWall;
      double minDist = 99999.0;
      for (final rect in _map.walls) {
        final double distY1 = (unit.y - rect.top).abs();
        final double distY2 = (unit.y - rect.bottom).abs();
        final double dist = min(distY1, distY2);
        if (dist < minDist) {
          minDist = dist;
          closestWall = rect;
        }
      }
      if (closestWall != null) {
        if (unit.y < closestWall.top + closestWall.height / 2) {
          unit.y = closestWall.top - 4.0;
        } else {
          unit.y = closestWall.bottom + 4.0;
        }
      }
    }
  }

  List<Combatant> filterTargets(Combatant seeker, List<Combatant> candidates) {
    if (seeker.npc.name.contains('Cannoneer')) {
      candidates = candidates.where((c) {
        final dist = sqrt(pow(c.x - seeker.x, 2) + pow(c.y - seeker.y, 2));
        return dist >= 4.0;
      }).toList();
    }
    final rule = seeker.npc.combatStats?.targetingRule ?? TargetingRule.all;
    switch (rule) {
      case TargetingRule.towersOnly:
        return candidates.where((c) => c.isTower).toList();
      case TargetingRule.enemyCharacterOnly:
        return candidates.where((c) => c.npc.isPlayer || c.isAiLeader).toList();
      case TargetingRule.squadsOnly:
        return candidates.where((c) => !c.isTower && c.npc.combatStats?.unitType == UnitType.squad).toList();
      case TargetingRule.vehiclesOnly:
        return candidates.where((c) => !c.isTower && c.npc.combatStats?.unitType == UnitType.vehicle).toList();
      case TargetingRule.nonTowers:
        return candidates.where((c) => !c.isTower).toList();
      case TargetingRule.all:
        return candidates;
    }
  }

  void _processUnitTick(Combatant c, double dt) {
    if (c.isDead) return;

    // Tick down gas slow timer
    if (c.gasSlowTimer > 0.0) {
      c.gasSlowTimer = max(0.0, c.gasSlowTimer - dt);
    }

    // Process Persistent Passive Healing Auras (Brewers & Hag)
    if (c.npc.role == 'Coven') {
      final nameLower = c.npc.name.toLowerCase();
      final isBrewer = nameLower.contains('brewer');
      final isHag = nameLower.contains('hag');

      if (isBrewer || isHag) {
        final double healRadius = isBrewer ? 15.0 : 20.0;
        final double healPerSecond = isBrewer ? 4.0 : 10.0;
        final double healAmount = healPerSecond * dt;

        final allies = _combatants.where((other) {
          if (other.side != c.side || other.isDead) return false;
          if (isHag && other == c) {
            return false; // Hag heals nearby allies but not herself
          }
          final dx = other.x - c.x;
          final dy = other.y - c.y;
          return sqrt(dx * dx + dy * dy) <= healRadius;
        }).toList();

        for (final ally in allies) {
          final aStats = ally.npc.combatStats!;
          if (aStats.health < aStats.maxHealth) {
            final newHealth = min(aStats.maxHealth, aStats.health + healAmount);
            ally.npc = ally.npc.copyWith(
              combatStats: aStats.copyWith(health: newHealth),
            );
            if (Random().nextDouble() < 0.05) {
              // Occasional floating green healing popup
              ally.floatingMessages.add(
                FloatingMessage(
                  text: '+${(healPerSecond / 2).ceil()}',
                  color: Colors.greenAccent,
                ),
              );
            }
          }
        }
      }
    }

    final stats = c.npc.combatStats!.copyWith(
      movement: c.npc.combatStats!.movement * c.movementSpeedMultiplier,
    );

    // A-1. Support Unit Deployment & Action ticking
    if (stats.unitType == UnitType.support) {
      if (c.activeDeploymentTimer > 0.0) {
        c.activeDeploymentTimer = max(0.0, c.activeDeploymentTimer - dt);
        return; // Skip normal updates while deploying
      }

      c.supportDurationRemaining = max(0.0, c.supportDurationRemaining - dt);
      if (c.supportDurationRemaining <= 0.0) {
        c.isDead = true;
        return;
      }

      // Apply support area of effect damage/slowing
      final targets = _combatants.where((other) => other.side != c.side && !other.isDead).toList();

      if (c.npc.name.contains('Barrage') || c.npc.name.contains('Artillery')) {
        // Reduced rectangle bounds: width and length by half
        final rectWidth = _map.width * 0.375;
        final rectHeight = (_map.height / _map.laneCenters.length) * 0.5;

        final double leftX = c.x - rectWidth / 2.0;
        final double rightX = c.x + rectWidth / 2.0;
        final double topY = c.y - rectHeight / 2.0;
        final double bottomY = c.y + rectHeight / 2.0;

        // High DPS: enough to kill median troop (120 health) in 3s. 55 DPS = 165 total damage.
        final damageThisTick = 55.0 * dt;

        for (final t in targets) {
          if (t.x >= leftX && t.x <= rightX && t.y >= topY && t.y <= bottomY) {
            final tStats = t.npc.combatStats!;
            final newHealth = max(0.0, tStats.health - damageThisTick);
            t.npc = t.npc.copyWith(
              combatStats: tStats.copyWith(health: newHealth),
            );
            t.flashTimer = 0.25;
            t.recentDamage += damageThisTick;
            if (newHealth <= 0) {
              _onCombatantDeath(t, c);
            }
          }
        }
      } else if (c.npc.name.contains('Gas') || c.npc.name.contains('Tear')) {
        // Tear Gas: slows by 60%, deals 15 DPS in a circle of radius 15.0
        const radius = 15.0;
        final damageThisTick = 15.0 * dt;

        for (final t in targets) {
          final dx = t.x - c.x;
          final dy = t.y - c.y;
          final dist = sqrt(dx * dx + dy * dy);
          if (dist <= radius) {
            final tStats = t.npc.combatStats!;
            final newHealth = max(0.0, tStats.health - damageThisTick);
            t.npc = t.npc.copyWith(
              combatStats: tStats.copyWith(health: newHealth),
            );
            t.flashTimer = 0.25;
            t.recentDamage += damageThisTick;
            t.gasSlowTimer = 0.5; // Keep slow refreshed
            if (newHealth <= 0) {
              _onCombatantDeath(t, c);
            }
          }
        }
      } else if (c.npc.name.contains('Caltrops')) {
        // Caltrops: slows ground units by 60%, deals 10 DPS (2.5x / 25 DPS to vehicles) in a square
        // Each side is 15.0 feet (long side of original layout)
        const halfSide = 15.0;

        final double leftX = c.x - halfSide;
        final double rightX = c.x + halfSide;
        final double topY = c.y - halfSide;
        final double bottomY = c.y + halfSide;

        final baseDamageThisTick = 10.0 * dt;

        for (final t in targets) {
          if (t.npc.combatStats!.isFlying) continue; // Caltrops only affects ground units

          if (t.x >= leftX && t.x <= rightX && t.y >= topY && t.y <= bottomY) {
            final isVehicle = t.npc.combatStats?.unitType == UnitType.vehicle;
            final damageThisTick = baseDamageThisTick * (isVehicle ? 2.5 : 1.0);

            final tStats = t.npc.combatStats!;
            final newHealth = max(0.0, tStats.health - damageThisTick);
            t.npc = t.npc.copyWith(
              combatStats: tStats.copyWith(health: newHealth),
            );
            t.flashTimer = 0.25;
            t.recentDamage += damageThisTick;
            t.gasSlowTimer = 0.5; // Slow down
            if (newHealth <= 0) {
              _onCombatantDeath(t, c);
            }
          }
        }
      } else if (c.isStampedeHorse) {
        final dir = c.side == CombatSide.player ? 1.0 : -1.0;
        c.x += dir * 25.0 * dt;

        if ((c.side == CombatSide.player && c.x >= _map.width - 5.0) ||
            (c.side == CombatSide.enemy && c.x <= 5.0)) {
          c.isDead = true;
          return;
        }

        for (final t in targets) {
          if (t.isTower) {
            final dist = (t.x - c.x).abs();
            if (dist < 8.0) {
              c.isDead = true;
              return;
            }
          } else {
            final dx = t.x - c.x;
            final dy = t.y - c.y;
            final dist = sqrt(dx * dx + dy * dy);
            if (dist <= c.npc.combatStats!.radius + t.npc.combatStats!.radius) {
              final newHealth = max(0.0, t.npc.combatStats!.health - 45.0 * dt);
              t.npc = t.npc.copyWith(
                combatStats: t.npc.combatStats!.copyWith(health: newHealth),
              );
              t.flashTimer = 0.25;
              t.recentDamage += 45.0 * dt;
              if (newHealth <= 0) {
                _onCombatantDeath(t, c);
              }
            }
          }
        }
      }

      return; // Skip normal locomotion, auto-targeting, or auto-attacks for Support units
    }

    // A-1b. Standard Deployment Timer ticking
    if (c.activeDeploymentTimer > 0.0) {
      c.activeDeploymentTimer = max(0.0, c.activeDeploymentTimer - dt);
      return; // Skip normal updates while deploying
    }

    // Backstep (stuck prevention backup)
    if (c.backstepTimer > 0.0) {
      c.backstepTimer -= dt;
      c.x += c.backstepDirX * stats.movement * dt * 4.0;
      c.y += c.backstepDirY * stats.movement * dt * 4.0;
      enforceUnitBoundaries(c);
      return; // Skip normal updates while backing away
    }

    final double oldX = c.x;
    final double oldY = c.y;

    // A0. Attack Cooldown Ticking (Wind up while moving)
    c.attackCooldown -= dt;

    // 0. Collision Repulsion (Push units apart if they overlap, respecting static towers)
    for (final other in _combatants) {
      if (other == c || other.isDead) continue;
      if (stats.unitType == UnitType.support || other.npc.combatStats?.unitType == UnitType.support) continue;
      final otherStats = other.npc.combatStats!;
      final dx = other.x - c.x;
      final dy = other.y - c.y;
      final distSq = dx * dx + dy * dy;
      final minDist =
          stats.radius + otherStats.radius + 2.0; // Added 2.0ft minimum buffer
      if (distSq < minDist * minDist) {
        final dist = sqrt(distSq);
        final overlap = minDist - dist;
        // Decisive repulsion
        final pushFactor = (overlap / 2.0) + 0.1;
        final nx = dist > 0.001 ? dx / dist : (Random().nextDouble() * 2 - 1);
        final ny = dist > 0.001 ? dy / dist : (Random().nextDouble() * 2 - 1);
        
        if (c.isTower && other.isTower) {
          // Both are static towers, do not move either
        } else if (c.isTower) {
          // Tower is static, only push the other unit
          other.x += nx * pushFactor * 2.0;
          other.y += ny * pushFactor * 2.0;
          enforceUnitBoundaries(other);
        } else if (other.isTower) {
          // Other unit is a static tower, only push c
          c.x -= nx * pushFactor * 2.0;
          c.y -= ny * pushFactor * 2.0;
          enforceUnitBoundaries(c);
        } else {
          // Both are mobile units, push both
          c.x -= nx * pushFactor;
          c.y -= ny * pushFactor;
          other.x += nx * pushFactor;
          other.y += ny * pushFactor;
          enforceUnitBoundaries(c);
          enforceUnitBoundaries(other);
        }
      }
    }

    // A. Special Action State (Progressive special abilities like Giles' Execute)
    if (c.specialActionId == 'execute_low_health') {
      final target = _combatants.firstWhereOrNull(
        (t) => t.npc.id == c.specialTargetId && !t.isDead,
      );

      if (target == null) {
        // Target lost or already dead, clear state
        c.specialActionId = null;
        c.specialTargetId = null;
      } else {
        // 1. Stun target (Stop them from moving/attacking)
        target.attackCooldown = max(
          target.attackCooldown,
          0.5,
        ); // Constant stun refresh
        target.freezeTimer = max(target.freezeTimer, 0.5);

        // 2. Move Giles to target at 2x speed
        final dx = target.x - c.x;
        final dy = target.y - c.y;
        final dist = sqrt(dx * dx + dy * dy);

        final tStats = target.npc.combatStats!;
        if (dist > stats.radius + tStats.radius + 2.5) {
          final moveDist =
              stats.movement *
              dt *
              2.25; // Slower movement (was 3.0)
          c.x += (dx / dist) * moveDist;
          c.y += (dy / dist) * moveDist;
          
          // Re-stun target
          target.attackCooldown = 0.5;
          target.freezeTimer = 0.5;
          return; // Skip normal targeting/movement while in special state
        } else {
          // 3. Close enough to EXECUTE
          target.npc = target.npc.copyWith(
            combatStats: tStats.copyWith(health: 0.0),
          );
          _onCombatantDeath(target, c);
          c.specialActionId = null;
          c.specialTargetId = null;
          final abilityName = c.npc.abilities.firstWhereOrNull((a) => a.id == 'execute_low_health')?.name ?? 'Execute';
          final actionMsg = abilityName == 'Strangle' ? 'strangled' : 'executed';
          final floatMsg = abilityName == 'Strangle' ? 'STRANGLED' : 'EXECUTED';
          _addLog('${c.npc.name} $actionMsg ${target.npc.name}!', side: c.side);
          _addFloatingMessage(target, floatMsg, Colors.redAccent);
          return;
        }
      }
    }

    // A2. Special Charge
    if (c.npc.abilities.any((a) => a.type == AbilityType.special)) {
      final special = c.npc.abilities.firstWhere(
        (a) => a.type == AbilityType.special,
      );
      final chargeInc = dt / (special.chargeTime ?? 10.0);
      c.npc = c.npc.copyWith(
        specialCharge: min(1.0, c.npc.specialCharge + chargeInc),
      );

      // Auto-fire special ability if charged and ready (AI ONLY or in Survival Mode for ALL units!)
      if (c.npc.specialCharge >= 1.0 &&
          (c.side == CombatSide.enemy || (isSurvivalMode && !c.npc.isPlayer))) {
        if (canExecuteSpecial(c.npc.id)) {
          executeSpecial(c.npc.id);
        }
      }
    }
    if (c.npc.isPlayer) {
      c.specialCharge2 = min(1.0, c.specialCharge2 + dt / 25.0);
    }

    if (c.chargeDurationRemaining > 0.0) {
      c.chargeDurationRemaining = max(0.0, c.chargeDurationRemaining - dt);
      final collidedEnemies =
          _combatants
              .where(
                (other) =>
                    other.side != c.side &&
                    !other.isDead &&
                    !other.isTower &&
                    sqrt(pow(other.x - c.x, 2) + pow(other.y - c.y, 2)) <=
                        c.radius +
                            (other.npc.combatStats?.radius ?? 1.0) +
                            1.8,
              )
              .toList();

      for (final col in collidedEnemies) {
        final colStats = col.npc.combatStats!;
        final colDmg = 85.0 * dt;
        final colHealth = max(0.0, colStats.health - colDmg);
        col.npc = col.npc.copyWith(
          combatStats: colStats.copyWith(health: colHealth),
        );
        _addFloatingMessage(col, 'COLLIDE', Colors.redAccent);
        if (colHealth <= 0) {
          _onCombatantDeath(col, c);
        }
      }
    }

    // B. Targeting
    // Grid spatial partitioning (5 horizontal sectors across map.width)
    final double sectorWidth = _map.width / 5.0;
    final int mySector = (c.x / sectorWidth).floor().clamp(0, 4);
    
    List<Combatant> targets = _combatants.where((other) {
      if (other.side == c.side || other.isDead || other.isNonPhysicalSupport) return false;
      final int otherSector = (other.x / sectorWidth).floor().clamp(0, 4);
      return (otherSector - mySector).abs() <= 1; // same or adjacent sector
    }).toList();
    
    // Fallback to all targets if adjacent sectors are empty to preserve baseline reactivity
    if (targets.isEmpty) {
      targets = _combatants
          .where((other) => other.side != c.side && !other.isDead && !other.isNonPhysicalSupport)
          .toList();
    }

    // Filter by Targeting Rule
    targets = filterTargets(c, targets);

    // Flyer targeting rules
    final bool isRanged = stats.distance >= 3.0; // Standardize ranged threshold
    if (!stats.isFlying && !isRanged) {
      // Ground melee units can only hit other ground units
      targets = targets.where((t) => !t.npc.combatStats!.isFlying).toList();
    }

    // Clean up leader reference if leader fainted or died
    if (c.leaderId != null) {
      final leader = _combatants.firstWhereOrNull((other) => other.npc.id == c.leaderId && !other.isDead);
      if (leader == null) {
        c.leaderId = null;
        c.formationOffset = null;
      }
    }

    // Dynamic Lane/Channel index tracking based on Y position
    int currentLaneIdx = 0;
    double minLaneDist = 99999.0;
    for (int i = 0; i < _map.laneCenters.length; i++) {
      final dist = (c.y - _map.laneCenters[i]).abs();
      if (dist < minLaneDist) {
        minLaneDist = dist;
        currentLaneIdx = i;
      }
    }
    c.laneIndex = currentLaneIdx;

    // Channel engagement prioritization
    List<Combatant> prioritizedTargets = [];
    final enemyTowers = _combatants.where((other) => other.isTower && other.side != c.side && !other.isDead).toList();
    final lastTower = (isSurvivalMode && enemyTowers.length == 1) ? enemyTowers.first : null;

    if (lastTower != null) {
      prioritizedTargets.add(lastTower);
    } else {
      for (final t in targets) {
        final double dist = sqrt(pow(t.x - c.x, 2) + pow(t.y - c.y, 2));
        final double dx = (t.x - c.x).abs();
        final bool sameLane = t.laneIndex == c.laneIndex;

        if (sameLane) {
          prioritizedTargets.add(t);
        } else {
          final int laneDiff = (t.laneIndex - c.laneIndex).abs();
          if (_map.laneCenters.length == 3) {
            // 3-lane map rules: neighboring lane crossover if very close (dist <= 45.0), passing (dx <= 25.0), and clear line-of-sight
            if (laneDiff == 1) {
              if (dist <= 45.0 && dx <= 25.0 && !isPathObstructed(c.x, c.y, t.x, t.y)) {
                prioritizedTargets.add(t);
              }
            }
            // Far lane (laneDiff == 2) is blocked from direct targeting
          } else if (_map.laneCenters.length == 2) {
            // 2-lane map rules: neighboring lane crossover if close (dist <= 40.0) and clear LOS,
            // or a leader standing near vertical center (within 20ft) and close horizontally (dx <= 35.0)
            final double centerY = _map.height / 2;
            final bool isLeader = t.npc.isPlayer || t.isAiLeader;
            final bool leaderNearCenter = isLeader && (t.y - centerY).abs() <= 20.0;

            if (leaderNearCenter && dx <= 35.0) {
              prioritizedTargets.add(t);
            } else if (dist <= 40.0 && !isPathObstructed(c.x, c.y, t.x, t.y)) {
              prioritizedTargets.add(t);
            }
          }
        }
      }
    }

    // Fallback to all visible/reachable targets if the prioritized channel is clear
    if (prioritizedTargets.isEmpty) {
      prioritizedTargets = targets;
    }
    targets = prioritizedTargets;

    if (targets.isNotEmpty && !c.npc.isPlayer) {
      // Prefer nearest targets that are NOT obstructed by the centerline walls
      var visibleTargets = targets.where((t) => !isPathObstructed(c.x, c.y, t.x, t.y)).toList();
      if (visibleTargets.isEmpty) {
        visibleTargets = targets; // Fallback to all targets if everything is behind walls
      }
      visibleTargets.sort((a, b) {
        final distA = sqrt(pow(a.x - c.x, 2) + pow(a.y - c.y, 2));
        final distB = sqrt(pow(b.x - c.x, 2) + pow(b.y - c.y, 2));
        return distA.compareTo(distB);
      });
      targets = visibleTargets;
    }

    // 1. Static Tower Logic: Static structures never move, but fire automatically at any target in range
    if (c.isTower) {
      if (targets.isNotEmpty) {
        targets.sort((a, b) {
          final distA = sqrt(pow(a.x - c.x, 2) + pow(a.y - c.y, 2));
          final distB = sqrt(pow(b.x - c.x, 2) + pow(b.y - c.y, 2));
          return distA.compareTo(distB);
        });
        final target = targets.first;
        final distToTarget = sqrt(pow(target.x - c.x, 2) + pow(target.y - c.y, 2));
        final rangeInFeet = stats.distance * 3.28;
        final myRadius = stats.radius;
        final targetRadius = target.npc.combatStats?.radius ?? 1.0;

        if (distToTarget - myRadius - targetRadius <= rangeInFeet) {
          if (c.attackCooldown <= 0) {
            _performAttack(c, target);
            c.attackCooldown = stats.speed * 1.2;
          }
        }
      }
      return;
    }

    // 2. Mobile Player Hero Locomotion & Auto-Attack Logic
    if (c.npc.isPlayer) {
      if (c.waypointX != null && c.waypointY != null) {
        // Check if path to final waypoint is obstructed by a centerline wall
        final bool pathBlocked = isPathObstructed(c.x, c.y, c.waypointX!, c.waypointY!);
        if (pathBlocked) {
          if (c.detourX == null || c.detourY == null) {
            // Find nearest gap X among: 35.0, 115.0, 185.0, 265.0
            final gaps = [35.0, 115.0, 185.0, 265.0];
            double nearestGapX = 115.0;
            double minDist = 99999.0;
            for (final gx in gaps) {
              final dist = (gx - c.x).abs();
              if (dist < minDist) {
                minDist = dist;
                nearestGapX = gx;
              }
            }
            c.detourX = nearestGapX;
            c.detourY = 70.0;
          }
        }

        // Walk towards detour first, then final waypoint
        final double tx = (c.detourX != null && c.detourY != null) ? c.detourX! : c.waypointX!;
        final double ty = (c.detourX != null && c.detourY != null) ? c.detourY! : c.waypointY!;

        final wdx = tx - c.x;
        final wdy = ty - c.y;
        final wlen = sqrt(wdx * wdx + wdy * wdy);

        if (wlen > 2.0) {
          c.moveDirX = wdx / wlen;
          c.moveDirY = wdy / wlen;
        } else {
          if (c.detourX != null && c.detourY != null) {
            // Arrived at detour! Clear detour and proceed to final waypoint
            c.detourX = null;
            c.detourY = null;
          } else {
            c.moveDirX = 0.0;
            c.moveDirY = 0.0;
            c.waypointX = null;
            c.waypointY = null;
          }
        }
      }

      double nextX = c.x + c.moveDirX * stats.movement * dt * 7.5 * 2.25;
      double nextY = c.y + c.moveDirY * stats.movement * dt * 7.5 * 2.25;

      bool inWall = _isPointInWall(nextX, nextY);

      if (!inWall) {
        c.x = nextX;
        c.y = nextY;
      } else {
        // Slide along collision boundaries
        double tryX = c.x + c.moveDirX * stats.movement * dt * 7.5 * 2.25;
        bool tryXObstructed = _isPointInWall(tryX, c.y);
        if (!tryXObstructed) {
          c.x = tryX;
        }

        double tryY = c.y + c.moveDirY * stats.movement * dt * 7.5 * 2.25;
        bool tryYObstructed = _isPointInWall(c.x, tryY);
        if (!tryYObstructed) {
          c.y = tryY;
        }
      }

      enforceUnitBoundaries(c);

      // Auto-attack nearest enemy within weapon range
      if (targets.isNotEmpty) {
        targets.sort((a, b) {
          final distA = sqrt(pow(a.x - c.x, 2) + pow(a.y - c.y, 2));
          final distB = sqrt(pow(b.x - c.x, 2) + pow(b.y - c.y, 2));
          return distA.compareTo(distB);
        });
        final target = targets.first;
        final distToTarget = sqrt(pow(target.x - c.x, 2) + pow(target.y - c.y, 2));
        final rangeInFeet = stats.distance * 3.28;
        final myRadius = stats.radius;
        final targetRadius = target.npc.combatStats?.radius ?? 1.0;

        if (distToTarget - myRadius - targetRadius <= rangeInFeet) {
          if (c.attackCooldown <= 0) {
            _performAttack(c, target);
            c.attackCooldown = stats.speed * 1.2;
          }
        }
      }
      return;
    }

    // 3. Mobile AI Hero (Opponent Leader) Locomotion & Attack AI
    if (c.isAiLeader) {
      final double healthRatio = stats.health / stats.maxHealth;
      HealingCauldron? targetCauldron;
      if (healthRatio < 0.70) {
        double minCauldronDist = 99999.0;
        for (final caul in _cauldrons) {
          if (caul.isAvailable) {
            final dist = sqrt(pow(caul.x - c.x, 2) + pow(caul.y - c.y, 2));
            if (dist < 100.0 && dist < minCauldronDist) {
              minCauldronDist = dist;
              targetCauldron = caul;
            }
          }
        }
      }

      if (targetCauldron != null) {
        // Move towards the healing cauldron instead of attacking or following normal targets
        double tx = targetCauldron.x;
        double ty = targetCauldron.y;

        if (isPathObstructed(c.x, c.y, tx, ty)) {
          double minDist = 99999.0;
          double myLaneY = _map.laneCenters.first;
          for (final ly in _map.laneCenters) {
            final dist = (c.y - ly).abs();
            if (dist < minDist) {
              minDist = dist;
              myLaneY = ly;
            }
          }
          ty = myLaneY;
        }

        final dx = tx - c.x;
        final dy = ty - c.y;
        final len = sqrt(dx * dx + dy * dy);

        double nextX = c.x + (len > 0.0 ? (dx / len) : 0.0) * stats.movement * dt * 6.0 * 2.25;
        double nextY = c.y + (len > 0.0 ? (dy / len) : 0.0) * stats.movement * dt * 6.0 * 2.25;

        bool inWall = _isPointInWall(nextX, nextY);

        if (!inWall) {
          c.x = nextX;
          c.y = nextY;
        } else {
          double tryX = c.x + (len > 0.0 ? (dx / len) : 0.0) * stats.movement * dt * 6.0 * 2.25;
          bool tryXObstructed = _isPointInWall(tryX, c.y);
          if (!tryXObstructed) {
            c.x = tryX;
          }

          double tryY = c.y + (len > 0.0 ? (dy / len) : 0.0) * stats.movement * dt * 6.0 * 2.25;
          bool tryYObstructed = _isPointInWall(c.x, tryY);
          if (!tryYObstructed) {
            c.y = tryY;
          }
        }
        enforceUnitBoundaries(c);
        return; // Avoid attacking or targeting other characters this frame
      }

      if (targets.isNotEmpty) {
        targets.sort((a, b) {
          final distA = sqrt(pow(a.x - c.x, 2) + pow(a.y - c.y, 2));
          final distB = sqrt(pow(b.x - c.x, 2) + pow(b.y - c.y, 2));
          return distA.compareTo(distB);
        });
        final target = targets.first;
        final distToTarget = sqrt(pow(target.x - c.x, 2) + pow(target.y - c.y, 2));
        final rangeInFeet = stats.distance * 3.28;
        final myRadius = stats.radius;
        final targetRadius = target.npc.combatStats?.radius ?? 1.0;

        if (distToTarget - myRadius - targetRadius > rangeInFeet) {
          // Approach target (+50% speed boost), prioritizing combat channels if path is obstructed by walls!
          double tx = target.x;
          double ty = target.y;

          if (isPathObstructed(c.x, c.y, target.x, target.y)) {
            double minDist = 99999.0;
            double myLaneY = _map.laneCenters.first;
            for (final ly in _map.laneCenters) {
              final dist = (c.y - ly).abs();
              if (dist < minDist) {
                minDist = dist;
                myLaneY = ly;
              }
            }
            tx = target.x;
            ty = myLaneY; // Align within our safe lane to bypass wall!
          }

          final dx = tx - c.x;
          final dy = ty - c.y;
          final len = sqrt(dx * dx + dy * dy);
          
          double nextX = c.x + (len > 0.0 ? (dx / len) : 0.0) * stats.movement * dt * 6.0 * 2.25;
          double nextY = c.y + (len > 0.0 ? (dy / len) : 0.0) * stats.movement * dt * 6.0 * 2.25;

          bool inWall = _isPointInWall(nextX, nextY);

          if (!inWall) {
            c.x = nextX;
            c.y = nextY;
          } else {
            // Slide
            double tryX = c.x + (len > 0.0 ? (dx / len) : 0.0) * stats.movement * dt * 6.0 * 2.25;
            bool tryXObstructed = _isPointInWall(tryX, c.y);
            if (!tryXObstructed) {
              c.x = tryX;
            }

            double tryY = c.y + (len > 0.0 ? (dy / len) : 0.0) * stats.movement * dt * 6.0 * 2.25;
            bool tryYObstructed = _isPointInWall(c.x, tryY);
            if (!tryYObstructed) {
              c.y = tryY;
            }
          }
        } else {
          // Perform attack
          if (c.attackCooldown <= 0) {
            _performAttack(c, target);
            c.attackCooldown = stats.speed * 1.2;
          }
          if (c.npc.specialCharge >= 1.0) {
            executeSpecial(c.npc.id);
          }
        }
      } else {
        // No active targets! Seek nearest channel and proceed towards player central/corner towers!
        double minDist = 99999.0;
        double nearestLaneY = _map.laneCenters.first;
        for (final ly in _map.laneCenters) {
          final dist = (c.y - ly).abs();
          if (dist < minDist) {
            minDist = dist;
            nearestLaneY = ly;
          }
        }

        // 1. Seek channel alignment Y first
        double dy = nearestLaneY - c.y;
        if (dy.abs() > 2.0) {
          c.moveDirY = dy > 0.0 ? 1.0 : -1.0;
          c.y += c.moveDirY * stats.movement * dt * 1.5 * 2.25;
        } else {
          c.moveDirY = 0.0;
        }

        // 2. Proceed down channel towards player central/corner towers (X = 0)
        c.moveDirX = -1.0;
        c.x += c.moveDirX * stats.movement * dt * 1.5 * 2.25;
      }
      
      enforceUnitBoundaries(c);
      return;
    }

    if (targets.isEmpty) {
      // Followers follow their leader if targets are empty
      if (c.leaderId != null) {
        final leader = _combatants.firstWhereOrNull((other) => other.npc.id == c.leaderId && !other.isDead);
        if (leader != null) {
          final double targetX = leader.x + (leader.side == CombatSide.player ? c.formationOffset!.dx : -c.formationOffset!.dx);
          final double targetY = (leader.y + c.formationOffset!.dy).clamp(2.0, _map.height - 2.0);
          
          final dx = targetX - c.x;
          final dy = targetY - c.y;
          final len = sqrt(dx * dx + dy * dy);
          
          if (len > 1.0) {
            c.x += (dx / len) * stats.movement * dt * 6.0;
            c.y += (dy / len) * stats.movement * dt * 6.0;
            enforceUnitBoundaries(c);
          }
          return;
        }
      }

      // Find nearest channel Y center
      double minDist = 99999.0;
      double nearestLaneY = _map.laneCenters.first;
      for (final ly in _map.laneCenters) {
        final dist = (c.y - ly).abs();
        if (dist < minDist) {
          minDist = dist;
          nearestLaneY = ly;
        }
      }

      // 1. Seek channel Y alignment first
      double dy = nearestLaneY - c.y;
      if (dy.abs() > 2.0) {
        c.moveDirY = dy > 0.0 ? 1.0 : -1.0;
        c.y += c.moveDirY * stats.movement * dt * 1.125;
      } else {
        c.moveDirY = 0.0;
      }

      // 2. Proceed down channel towards opponent base
      final moveSpeed = stats.movement * dt * 1.125;
      double nextX = c.x;
      if (c.side == CombatSide.player) {
        c.moveDirX = 1.0;
        nextX += moveSpeed;
      } else {
        c.moveDirX = -1.0;
        nextX -= moveSpeed;
      }

      bool inWall = _isPointInWall(nextX, c.y);
      if (!inWall) {
        c.x = nextX;
      } else {
        // Slide towards closest channel center Y dynamically
        final targetY = c.y < _map.height / 2 ? _map.laneCenters.first : _map.laneCenters.last;
        final sdy = targetY - c.y;
        if (sdy.abs() > 0.1) {
          c.y += (sdy > 0 ? 1.0 : -1.0) * stats.movement * dt * 1.125;
        }
      }

      enforceUnitBoundaries(c);
      return;
    }

    // Targeting Logic for normal units:
    Combatant? target;
    if (c.targetId != null) {
      target = _combatants.firstWhereOrNull(
        (t) => t.npc.id == c.targetId && !t.isDead && t.side != c.side,
      );

      if (target != null) {
        final dist = sqrt(pow(target.x - c.x, 2) + pow(target.y - c.y, 2));
        final rangeInFeet = stats.distance * 3.28;
        final myRadius = stats.radius;
        final targetRadius = target.npc.combatStats?.radius ?? 1.0;

        if (dist - myRadius - targetRadius > rangeInFeet) {
          target = null; // Forces re-targeting below
        }
      }
    }

    if (target == null) {
      targets.sort((a, b) {
        final distA = sqrt(pow(a.x - c.x, 2) + pow(a.y - c.y, 2));
        final distB = sqrt(pow(b.x - c.x, 2) + pow(b.y - c.y, 2));
        return distA.compareTo(distB);
      });
      target = targets.first;
      c.targetId = target.npc.id;
    }

    final distToTarget = sqrt(pow(target.x - c.x, 2) + pow(target.y - c.y, 2));

    // C. Movement/Attack Logic for normal units
    final rangeInFeet = stats.distance * 3.28;
    final myRadius = stats.radius;
    final targetRadius = target.npc.combatStats?.radius ?? 1.0;

    if (distToTarget - myRadius - targetRadius > rangeInFeet) {
      // Approach target OR follow leader in tight formation
      double tx = target.x;
      double ty = target.y;

      if (c.leaderId != null) {
        final leader = _combatants.firstWhereOrNull((other) => other.npc.id == c.leaderId && !other.isDead);
        if (leader != null) {
          tx = leader.x + (leader.side == CombatSide.player ? c.formationOffset!.dx : -c.formationOffset!.dx);
          ty = (leader.y + c.formationOffset!.dy).clamp(2.0, _map.height - 2.0);
        }
      }

      if (isPathObstructed(c.x, c.y, target.x, target.y)) {
        double minDist = 99999.0;
        double myLaneY = _map.laneCenters.first;
        for (final ly in _map.laneCenters) {
          final dist = (c.y - ly).abs();
          if (dist < minDist) {
            minDist = dist;
            myLaneY = ly;
          }
        }
        tx = target.x;
        ty = myLaneY; // Align within our safe lane to bypass wall!
      }

      final dx = tx - c.x;
      final dy = ty - c.y;
      final len = sqrt(dx * dx + dy * dy);
      
      double nextX = c.x + (len > 0.0 ? (dx / len) : 0.0) * stats.movement * dt * 6.0;
      double nextY = c.y + (len > 0.0 ? (dy / len) : 0.0) * stats.movement * dt * 6.0;

      bool inWall = _isPointInWall(nextX, nextY);

      if (!inWall) {
        c.x = nextX;
        c.y = nextY;
      } else {
        // Slide
        double tryX = c.x + (len > 0.0 ? (dx / len) : 0.0) * stats.movement * dt * 6.0;
        bool tryXObstructed = _isPointInWall(tryX, c.y);
        if (!tryXObstructed) {
          c.x = tryX;
        }

        double tryY = c.y + (len > 0.0 ? (dy / len) : 0.0) * stats.movement * dt * 6.0;
        bool tryYObstructed = _isPointInWall(c.x, tryY);
        if (!tryYObstructed) {
          c.y = tryY;
        }
      }
    } else {
      if (c.attackCooldown <= 0) {
        _performAttack(c, target);
        c.attackCooldown = stats.speed * 1.2;
      }
    }

    enforceUnitBoundaries(c);

    // Stuck detection (Obstacle stuck prevention)
    if (!c.isTower && !c.isDead) {
      final distMoved = sqrt(pow(c.x - oldX, 2) + pow(c.y - oldY, 2));
      final expectedStep = stats.movement * dt;
      if (expectedStep > 0.001 && distMoved < expectedStep * 0.1) {
        c.stuckFrames++;
        if (c.stuckFrames >= 15) { // Blocked for 15 frames (~0.25 seconds)
          c.backstepTimer = 0.5; // Backup for 0.5 seconds (about 2 steps!)
          
          final dx = c.moveDirX != 0 || c.moveDirY != 0 
              ? -c.moveDirX 
              : (c.side == CombatSide.player ? -1.0 : 1.0);
          final dy = c.moveDirY != 0 
              ? -c.moveDirY 
              : (c.y < _map.height / 2 ? 1.0 : -1.0);
          final len = sqrt(dx * dx + dy * dy);
          c.backstepDirX = len > 0.0 ? dx / len : (c.side == CombatSide.player ? -1.0 : 1.0);
          c.backstepDirY = len > 0.0 ? dy / len : (c.y < _map.height / 2 ? 1.0 : -1.0);
          
          c.stuckFrames = 0;
          c.waypointX = null;
          c.waypointY = null;
          c.detourX = null;
          c.detourY = null;
        }
      } else {
        c.stuckFrames = 0;
      }
    } else {
      c.stuckFrames = 0;
    }
  }

  void _performAttack(Combatant attacker, Combatant target) {
    if (target.isDead || target.isNonPhysicalSupport) return;
    final stats = attacker.npc.combatStats!;
    final targetStats = target.npc.combatStats!;

    // Determine if it's a slow rocket unit (e.g., ChemicalSlinger / Artillery / Rocket)
    final bool isSlowRocketUnit = attacker.npc.role.toLowerCase() == 'artillery' ||
        attacker.npc.name.toLowerCase().contains('slinger') ||
        attacker.npc.name.toLowerCase().contains('rocket');

    if (stats.distance > 1.0) {
      if (isSlowRocketUnit) {
        // Dodgeable slow-moving rocket (speed = 14.0)
        _projectiles.add(
          Projectile(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            x: attacker.x,
            y: attacker.y,
            targetX: target.x,
            targetY: target.y,
            side: attacker.side,
            isSlowRocket: true,
            damage: stats.attack.toDouble(),
            attackerId: attacker.npc.id,
            speed: 14.0,
          ),
        );
        _addLog('${attacker.npc.name} launched a rocket toward ${target.npc.name}!', side: attacker.side);
        return; // Bypass predetermined roll completely!
      } else {
        // Ordinary fast-moving projectile (speed = 120.0)
        _projectiles.add(
          Projectile(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            x: attacker.x,
            y: attacker.y,
            targetX: target.x,
            targetY: target.y,
            side: attacker.side,
            isSlowRocket: false,
            attackerId: attacker.npc.id,
            speed: 240.0,
          ),
        );
      }
    }

    // Accuracy check (melee & ordinary fast projectiles)
    if (Random().nextDouble() > stats.accuracy) {
      // Miss!
      _addLog(
        '${attacker.npc.name} missed ${target.npc.name}!',
        side: attacker.side,
      );
      _addFloatingMessage(attacker, 'MISS', Colors.white70);
      return;
    }

    // Damage calculation
    double damage;
    if (attacker.npc.name.contains('Cannoneer')) {
      final isTowerOrVehicle =
          target.isTower || targetStats.unitType == UnitType.vehicle;
      damage = isTowerOrVehicle ? 115.0 : 75.0;
    } else if (stats.damageFormula != null &&
        stats.damageFormula!.contains('-')) {
      final parts = stats.damageFormula!.split('-');
      final minDmg = double.tryParse(parts[0]) ?? stats.attack;
      final maxDmg = double.tryParse(parts[1]) ?? stats.attack * 1.5;
      damage = minDmg + Random().nextDouble() * (maxDmg - minDmg);
      damage = max(1.0, damage - targetStats.defense);
    } else {
      damage = max(
        1.0,
        (stats.attack - targetStats.defense) * 1.5,
      );
    }

    if (targetStats.swarmSize > 0) {
      final maxDamagePerHit = targetStats.maxHealth / targetStats.swarmSize;
      damage = min(damage, maxDamagePerHit);
    }

    _addLog(
      '${attacker.npc.name} hit ${target.npc.name} for ${damage.toStringAsFixed(1)} damage.',
      side: attacker.side,
    );

    _addFloatingMessage(target, '-${damage.toInt()}', Colors.red);
    _addFloatingMessage(
      attacker,
      'HIT',
      attacker.side == CombatSide.player ? Colors.cyanAccent : Colors.orangeAccent,
    );

    // Apply damage to target NPC
    final newHealth = max(0.0, targetStats.health - damage);
    target.npc = target.npc.copyWith(
      combatStats: targetStats.copyWith(health: newHealth),
    );

    if (newHealth <= 0) {
      _onCombatantDeath(target, attacker);
      _addLog('${target.npc.name} has been defeated!', side: target.side);
    }

    final bool isMeleeStrike = stats.distance <= 2.0;
    if (isMeleeStrike) {
      final nameLower = attacker.npc.name.toLowerCase();
      final bool isConeCleave =
          nameLower.contains('bear') || nameLower.contains('mech');
      final bool isCircularCleave = nameLower.contains('werewolf');

      if (isConeCleave || isCircularCleave) {
        final double cleaveRadius = isCircularCleave ? 6.5 : 5.0;
        final double attackSign = (target.x - attacker.x).sign;

        final secondaryTargets =
            _combatants
                .where((other) {
                  if (other == target ||
                      other.side == attacker.side ||
                      other.isDead ||
                      other.isNonPhysicalSupport ||
                      other.isTower) {
                    return false;
                  }
                  if (other.npc.combatStats?.isFlying == true) return false;

                  final double dist = sqrt(
                    pow(other.x - attacker.x, 2) + pow(other.y - attacker.y, 2),
                  );
                  if (dist > cleaveRadius) return false;

                  if (isConeCleave &&
                      (other.x - attacker.x).sign != attackSign &&
                      attackSign != 0) {
                    return false;
                  }
                  return true;
                })
                .toList();

        for (final sec in secondaryTargets) {
          final secStats = sec.npc.combatStats!;
          final secDmg = damage * 0.65;
          final secHealth = max(0.0, secStats.health - secDmg);
          sec.npc = sec.npc.copyWith(
            combatStats: secStats.copyWith(health: secHealth),
          );
          _addFloatingMessage(
            sec,
            '-${secDmg.toInt()}',
            Colors.deepOrangeAccent,
          );
          if (secHealth <= 0) {
            _onCombatantDeath(sec, attacker);
          }
        }
      }
    }

    // Handle Trait effects
    for (final ability in attacker.npc.abilities) {
      if (ability.type == AbilityType.trait &&
          ability.effectData['on_hit'] == true) {
        _applyAbilityEffect(attacker, ability);
      }
    }
  }

  void _applyAbilityEffect(Combatant c, Ability ability) {
    switch (ability.id) {
      case 'accuracy_boost':
        final stats = c.npc.combatStats!;
        c.npc = c.npc.copyWith(
          combatStats: stats.copyWith(
            accuracy: min(1.0, stats.accuracy + 0.05),
          ),
        );
        _addLog('${c.npc.name} accuracy boosted!', side: c.side);
        break;

      case 'witch_charge_heal':
        const reach = 9.0;
        final allies =
            _combatants
                .where(
                  (other) =>
                      other.side == c.side &&
                      !other.isDead &&
                      sqrt(pow(other.x - c.x, 2) + pow(other.y - c.y, 2)) <=
                          reach,
                )
                .toList();
        allies.sort(
          (a, b) => sqrt(pow(a.x - c.x, 2) + pow(a.y - c.y, 2)).compareTo(
            sqrt(pow(b.x - c.x, 2) + pow(b.y - c.y, 2)),
          ),
        );
        for (int i = 0; i < min(4, allies.length); i++) {
          final ally = allies[i];
          final stats = ally.npc.combatStats!;
          ally.npc = ally.npc.copyWith(
            combatStats: stats.copyWith(
              health: min(stats.maxHealth, stats.health + 50.0),
            ),
          );
          _addFloatingMessage(ally, '+50', Colors.greenAccent);
        }
        _addLog('${c.npc.name} cast Coven Restoration!', side: c.side);
        break;

      case 'horn_heal':
        final healAmount = (ability.effectData['heal'] as num).toDouble();
        final range = (ability.effectData['range'] as num).toDouble();
        final friendlies = _combatants
            .where(
              (other) => other.side == c.side && other != c && !other.isDead,
            )
            .toList();
        if (friendlies.isNotEmpty) {
          friendlies.sort(
            (a, b) => (a.x - c.x).abs().compareTo((b.x - c.x).abs()),
          );
          final nearest = friendlies.first;
          if ((nearest.x - c.x).abs() <= range) {
            final stats = nearest.npc.combatStats!;
            nearest.npc = nearest.npc.copyWith(
              combatStats: stats.copyWith(
                health: min(stats.maxHealth, stats.health + healAmount),
              ),
            );
            _addLog(
              '${c.npc.name} healed ${nearest.npc.name} for ${healAmount.toStringAsFixed(1)}.',
              side: c.side,
            );
          }
        }
        break;

      case 'execute_low_health':
        final threshold = (ability.effectData['threshold'] as num).toDouble();
        final targets = _combatants
            .where(
              (other) =>
                  other.side != c.side &&
                  !other.isDead &&
                  !other.npc.combatStats!.isFlying,
            )
            .toList();
        final stats = c.npc.combatStats!;
        if (targets.isNotEmpty) {
          targets.sort((a, b) {
            final distA = sqrt(pow(a.x - c.x, 2) + pow(a.y - c.y, 2));
            final distB = sqrt(pow(b.x - c.x, 2) + pow(b.y - c.y, 2));
            return distA.compareTo(distB);
          });

          final target = targets.firstWhereOrNull((t) {
            final dx = t.x - c.x;
            final dy = t.y - c.y;
            final dist = sqrt(dx * dx + dy * dy);
            final tStats = t.npc.combatStats!;
            // Edge-to-edge check
            return (dist - stats.radius - tStats.radius) <= 12.0 &&
                (tStats.health / tStats.maxHealth) <= threshold;
          });

          if (target != null) {
            // Set special state for walk-over-and-kill
            c.specialActionId = 'execute_low_health';
            c.specialTargetId = target.npc.id;
            _addLog(
              '${c.npc.name} is moving to EXECUTE ${target.npc.name}!',
              side: c.side,
            );
          }
        }
        break;

      case 'push_back':
        final pushDist = (ability.effectData['push'] as num).toDouble();
        final damage = (ability.effectData['damage'] as num).toDouble();
        final targets = _combatants
            .where((other) => other.side != c.side && !other.isDead)
            .toList();
        for (final target in targets) {
          if ((target.x - c.x).abs() <= c.npc.combatStats!.distance) {
            final dir = target.x > c.x ? 1.0 : -1.0;
            target.x += dir * pushDist;
            final stats = target.npc.combatStats!;
            target.npc = target.npc.copyWith(
              combatStats: stats.copyWith(
                health: max(0, stats.health - damage),
              ),
            );
            if (target.npc.combatStats!.health <= 0) {
              _onCombatantDeath(target, c);
              _addLog(
                '${target.npc.name} was crushed by the push!',
                side: target.side,
              );
            } else {
              _addLog(
                '${c.npc.name} pushed back ${target.npc.name}.',
                side: c.side,
              );
            }
          }
        }
        break;

      case 'freeze_line':
        final duration = (ability.effectData['freeze_duration'] as num)
            .toDouble();
        final targets = _combatants
            .where((other) => other.side != c.side && !other.isDead)
            .toList();
        if (targets.isNotEmpty) {
          targets.sort(
            (a, b) => (b.x - c.x).abs().compareTo((a.x - c.x).abs()),
          );
          final furthest = targets.first;
          
          // Freeze logic: Anyone within a 'line' (narrow rectangle) toward furthest
          final minX = min(c.x, furthest.x);
          final maxX = max(c.x, furthest.x);
          final midY = c.y;
          const lineThickness = 15.0; // 7.5ft each side

          for (final t in targets) {
            if (t.x >= minX &&
                t.x <= maxX &&
                (t.y - midY).abs() <= lineThickness) {
              _applyFreeze(t, duration);
              _addLog(
                '${t.npc.name} was frozen for ${duration.toStringAsFixed(1)}s!',
                side: t.side,
              );
              _addFloatingMessage(t, 'FROZEN', Colors.lightBlueAccent);
            }
          }
        }
        break;

      case 'corpse_arc':
        final damage = (ability.effectData['damage'] as num).toDouble();
        final aoeDamage = (ability.effectData['aoe_damage'] as num).toDouble();
        final range =
            (ability.effectData['range'] as num).toDouble() *
            3.28; // Meters to feet

        final targets = _combatants
            .where((other) => other.side != c.side && !other.isDead)
            .toList();
        if (targets.isNotEmpty) {
          targets.sort(
            (a, b) => (a.x - c.x).abs().compareTo((b.x - c.x).abs()),
          );
          final primary = targets.first;

          if ((primary.x - c.x).abs() <= range) {
            // Apply primary damage
            _applyDamage(c, primary, damage);
            _addLog(
              '${c.npc.name} struck ${primary.npc.name} with Lightning Arc!',
              side: c.side,
            );

            // Apply AoE to others nearby primary
            for (final t in targets) {
              if (t == primary) continue;
              final distToPrimary = sqrt(
                pow(t.x - primary.x, 2) + pow(t.y - primary.y, 2),
              );
              if (distToPrimary <= 25.0) {
                // 25ft AoE jump
                _applyDamage(c, t, aoeDamage);
                _addFloatingMessage(t, 'ARCED', Colors.yellowAccent);
              }
            }
          }
        }
        break;

      case 'undead_rot':
        final damage = 40.0;
        final duration = 5.0;
        final radius = 25.0;
        final targets = _combatants
            .where((other) => other.side != c.side && !other.isDead)
            .toList();
        for (final t in targets) {
          final dist = sqrt(pow(t.x - c.x, 2) + pow(t.y - c.y, 2));
          if (dist <= radius) {
            final stats = t.npc.combatStats!;
            t.npc = t.npc.copyWith(
              combatStats: stats.copyWith(
                health: max(0, stats.health - damage),
              ),
            );
            t.gasSlowTimer = duration; // slow them
            _addFloatingMessage(t, 'ROT CLOUD', Colors.green);
            if (t.npc.combatStats!.health <= 0) {
              _onCombatantDeath(t, c);
            }
          }
        }
        _addLog('${c.npc.name} released a Plague Rot Cloud!', side: c.side);
        break;

      case 'magical_howl':
        final duration = 2.5;
        final radius = 20.0;
        final targets = _combatants
            .where((other) => other.side != c.side && !other.isDead)
            .toList();
        for (final t in targets) {
          final dist = sqrt(pow(t.x - c.x, 2) + pow(t.y - c.y, 2));
          if (dist <= radius) {
            _applyFreeze(t, duration); // Stun
            _addFloatingMessage(t, 'TERRIFIED', Colors.purpleAccent);
          }
        }
        _addLog('${c.npc.name} emitted a Terrifying Howl!', side: c.side);
        break;

      case 'dragon_breath':
        final damage = 80.0;
        final range = 30.0;
        final targets = _combatants
            .where((other) => other.side != c.side && !other.isDead)
            .toList();
        if (targets.isNotEmpty) {
          targets.sort(
            (a, b) => (a.x - c.x).abs().compareTo((b.x - c.x).abs()),
          );
          final target = targets.first;
          final dx = target.x - c.x;
          final dy = target.y - c.y;
          final len = sqrt(dx * dx + dy * dy);
          if (len > 0.0) {
            final ndx = dx / len;
            final ndy = dy / len;
            for (final t in targets) {
              final tx = t.x - c.x;
              final ty = t.y - c.y;
              final projection = tx * ndx + ty * ndy;
              if (projection >= 0.0 && projection <= range) {
                final perpDist = (tx * -ndy + ty * ndx).abs();
                if (perpDist <= 12.0) {
                  final stats = t.npc.combatStats!;
                  t.npc = t.npc.copyWith(
                    combatStats: stats.copyWith(
                      health: max(0, stats.health - damage),
                    ),
                  );
                  _addFloatingMessage(t, 'BURNED', Colors.orangeAccent);
                  if (t.npc.combatStats!.health <= 0) {
                    _onCombatantDeath(t, c);
                  }
                }
              }
            }
          }
        }
        _addLog('${c.npc.name} breathed a cone of fire!', side: c.side);
        break;

      case 'ap_steal':
        final amount = (ability.effectData['steal_ap'] as num).toDouble();
        // In this simplified model, AP is global for the player.
        // If we want to simulate enemy AP, we could decrease it there,
        // but for now we just give it to the player.
        _actionPoints = min(maxAP, _actionPoints + amount);
        _addLog(
          '${c.npc.name} stole ${amount.toStringAsFixed(1)} Action Points!',
          side: c.side,
        );
        break;
    }
  }

  void _applyFreeze(Combatant target, double duration) {
    // This requires a freeze state on the combatant or NPC status effect.
    // For now, let's just make them "dead" for a duration by setting a cooldown
    target.attackCooldown = max(target.attackCooldown, duration);
    target.freezeTimer = duration;
  }

  bool canExecuteSpecial(String combatantId) {
    final c = _combatants.firstWhere(
      (c) => c.npc.id == combatantId,
      orElse: () => _combatants.first,
    );
    if (c.isDead || c.npc.specialCharge < 1.0) return false;

    final special = c.npc.abilities.firstWhere(
      (a) => a.type == AbilityType.special,
      orElse: () => const Ability(
        id: 'none',
        name: 'None',
        type: AbilityType.trait,
        description: 'No ability',
      ),
    );
    if (special.id == 'none') return false;

    switch (special.id) {
      case 'execute_low_health':
        final threshold = (special.effectData['threshold'] as num).toDouble();
        const range = 12.0; // Melee execution range
        return _combatants.any(
          (other) =>
              other.side != c.side &&
              !other.isDead &&
              !other.npc.combatStats!.isFlying && // Giles cannot execute flyers
              (sqrt(pow(other.x - c.x, 2) + pow(other.y - c.y, 2)) -
                      c.npc.combatStats!.radius -
                      other.npc.combatStats!.radius) <=
                  range &&
              (other.npc.combatStats!.health /
                      other.npc.combatStats!.maxHealth) <=
                  threshold,
        );
      case 'master_command':
      case 'captain_rally':
      case 'monk_chant':
        final range = (special.effectData['range'] as num).toDouble();
        return _combatants.any(
          (other) =>
              other.side == c.side &&
              other != c &&
              !other.isDead &&
              (other.x - c.x).abs() <= range,
        );
      case 'push_back':
      case 'captain_strike':
      case 'slinger_cloud':
      case 'digger_bury':
      case 'hound_leap':
      case 'golem_slam':
      case 'corpse_arc':
        final range = (c.npc.combatStats?.distance ?? 1.0) * 3.28;
        return _combatants.any(
          (other) =>
              other.side != c.side &&
              !other.isDead &&
              (other.x - c.x).abs() <= range,
        );
      case 'freeze_line':
      case 'ap_steal':
        // These are always valid if there are ANY enemies
        return _combatants.any(
          (other) => other.side != c.side && !other.isDead,
        );
      case 'undead_rot':
        return _combatants.any(
          (other) =>
              other.side != c.side &&
              !other.isDead &&
              (sqrt(pow(other.x - c.x, 2) + pow(other.y - c.y, 2)) -
                      c.npc.combatStats!.radius -
                      other.npc.combatStats!.radius) <=
                  25.0,
        );
      case 'magical_howl':
        return _combatants.any(
          (other) =>
              other.side != c.side &&
              !other.isDead &&
              (sqrt(pow(other.x - c.x, 2) + pow(other.y - c.y, 2)) -
                      c.npc.combatStats!.radius -
                      other.npc.combatStats!.radius) <=
                  20.0,
        );
      case 'dragon_breath':
        return _combatants.any(
          (other) => other.side != c.side && !other.isDead && (other.x - c.x).abs() <= 30.0,
        );
      case 'witch_charge_heal':
        return _combatants.any(
          (other) =>
              other.side == c.side &&
              other != c &&
              !other.isDead &&
              sqrt(pow(other.x - c.x, 2) + pow(other.y - c.y, 2)) <= 9.0,
        );
      default:
        return true;
    }
  }

  void executeSpecial(String combatantId) {
    if (!canExecuteSpecial(combatantId)) return;
    
    final c = _combatants.firstWhere(
      (c) => c.npc.id == combatantId,
      orElse: () => _combatants.first,
    );

    final special = c.npc.abilities.firstWhere(
      (a) => a.type == AbilityType.special,
    );
    _applyAbilityEffect(c, special);

    c.npc = c.npc.copyWith(specialCharge: 0.0);
    notifyListeners();
  }

  bool canExecuteSpecial2(String combatantId) {
    final c = _combatants.firstWhereOrNull((c) => c.npc.id == combatantId);
    if (c == null || c.specialCharge2 < 1.0 || c.isDead) return false;
    return _combatants.any((other) => other.side != c.side && !other.isDead);
  }

  void executeSpecial2(String combatantId) {
    if (!canExecuteSpecial2(combatantId)) return;

    final c = _combatants.firstWhere((c) => c.npc.id == combatantId);
    final enemies = _combatants.where((other) => other.side != c.side && !other.isDead).toList();
    if (enemies.isNotEmpty) {
      enemies.sort((a, b) {
        final distA = sqrt(pow(a.x - c.x, 2) + pow(a.y - c.y, 2));
        final distB = sqrt(pow(b.x - c.x, 2) + pow(b.y - c.y, 2));
        return distA.compareTo(distB);
      });
      final target = enemies.first;
      
      _applyDamage(c, target, 150.0);
      _applyFreeze(target, 4.0); // 4s stun
      
      _addLog('${c.npc.name} cast Lightning Strike on ${target.npc.name}!', side: c.side);
      _addFloatingMessage(target, 'STUNNED', Colors.yellowAccent);
      _addFloatingMessage(target, '-150', Colors.red);
    }

    c.specialCharge2 = 0.0;
    notifyListeners();
  }

  void setPlayerTarget(String enemyId) {
    // Force Alphonse or units to target a specific enemy
    final alphonse = _combatants.firstWhere((c) => c.npc.isPlayer);
    alphonse.targetId = enemyId;
  }

  void scrollField(double dx, double dy) {
    _fieldScroll = (_fieldScroll + dx).clamp(0.0, _map.width);
    _yFieldScroll = (_yFieldScroll + dy).clamp(0.0, _map.height);
    _manualCameraOverrideTimer = 1.5; // Block auto-recenter for 1.5 seconds after a manual drag/pan!
    notifyListeners();
  }

  void movePlayer(double targetX, double targetY) {
    final alphonse = _combatants.firstWhere((c) => c.npc.isPlayer);
    double tx = targetX.clamp(0.0, _map.width);
    double ty = targetY.clamp(2.0, _map.height - 2.0);

    if (_isPointInWall(tx, ty)) {
      Rect? closestWall;
      double minDist = 99999.0;
      for (final rect in _map.walls) {
        final double distY1 = (ty - rect.top).abs();
        final double distY2 = (ty - rect.bottom).abs();
        final double dist = min(distY1, distY2);
        if (dist < minDist) {
          minDist = dist;
          closestWall = rect;
        }
      }
      if (closestWall != null) {
        if (ty < closestWall.top + closestWall.height / 2) {
          ty = closestWall.top - 4.0;
        } else {
          ty = closestWall.bottom + 4.0;
        }
      }
    }

    alphonse.waypointX = tx;
    alphonse.waypointY = ty;
    notifyListeners();
  }

  void applyDirectDamage(Combatant target, double damage, String attackerId) {
    if (target.isDead || target.isNonPhysicalSupport) return;
    final attacker = _combatants.firstWhereOrNull((c) => c.npc.id == attackerId);
    final targetStats = target.npc.combatStats!;
    final actualDamage = max(1.0, damage - targetStats.defense);

    target.npc = target.npc.copyWith(
      combatStats: targetStats.copyWith(
        health: max(0.0, targetStats.health - actualDamage),
      ),
    );

    target.flashTimer = 0.25;
    target.recentDamage += actualDamage;

    if (target.npc.combatStats!.health <= 0.0) {
      _onCombatantDeath(target, attacker);
      _addLog('${target.npc.name} has been vanquished!', side: target.side);
    } else {
      _addFloatingMessage(target, '-${actualDamage.toInt()}', Colors.redAccent);
    }

    if (attacker != null) {
      attacker.npc = attacker.npc.copyWith(
        specialCharge: min(1.0, attacker.npc.specialCharge + 0.08),
      );
    }
    notifyListeners();
  }


  void _applyDamage(Combatant attacker, Combatant target, double damage) {
    if (target.isDead || target.isNonPhysicalSupport) return;
    final tStats = target.npc.combatStats!;
    final actualDamage = max(1.0, damage - tStats.defense);

    final newHealth = max(0.0, tStats.health - actualDamage);
    target.npc = target.npc.copyWith(
      combatStats: tStats.copyWith(health: newHealth),
    );
    target.flashTimer = 0.5; // 500ms flash
    target.recentDamage = actualDamage;

    _addFloatingMessage(target, '-${actualDamage.toInt()}', Colors.red);
    if (newHealth <= 0) {
      _onCombatantDeath(target, attacker);
    }
  }

  void setHoveredAbility(String? combatantId) {
    _highlightedTargetIds.clear();
    if (combatantId == null) {
      notifyListeners();
      return;
    }

    final c = _combatants.firstWhereOrNull((c) => c.npc.id == combatantId);
    if (c == null) {
      notifyListeners();
      return;
    }

    final special = c.npc.abilities.firstWhereOrNull(
      (a) => a.type == AbilityType.special,
    );
    if (special == null) {
      notifyListeners();
      return;
    }

    switch (special.id) {
      case 'execute_low_health':
        final targets = _combatants
            .where(
              (other) =>
                  other.side != c.side &&
                  !other.isDead &&
                  !other.npc.combatStats!.isFlying,
            )
            .toList();
        targets.sort(
          (a, b) => sqrt(
            pow(a.x - c.x, 2) + pow(a.y - c.y, 2),
          ).compareTo(sqrt(pow(b.x - c.x, 2) + pow(b.y - c.y, 2))),
        );

        final threshold = (special.effectData['threshold'] as num).toDouble();
        final target = targets.firstWhereOrNull((t) {
          final distSq = pow(t.x - c.x, 2) + pow(t.y - c.y, 2);
          final tStats = t.npc.combatStats!;
          return (sqrt(distSq) - c.npc.combatStats!.radius - tStats.radius) <=
                  12.0 &&
              (tStats.health / tStats.maxHealth) <= threshold;
        });
        if (target != null) _highlightedTargetIds.add(target.npc.id);
        break;

      case 'freeze_line':
        final enemies = _combatants
            .where((other) => other.side != c.side && !other.isDead)
            .toList();
        if (enemies.isNotEmpty) {
          enemies.sort(
            (a, b) => (b.x - c.x).abs().compareTo((a.x - c.x).abs()),
          );
          final furthest = enemies.first;
          final minX = min(c.x, furthest.x);
          final maxX = max(c.x, furthest.x);
          final midY = c.y;
          for (final t in enemies) {
            if (t.x >= minX && t.x <= maxX && (t.y - midY).abs() <= 15.0) {
              _highlightedTargetIds.add(t.npc.id);
            }
          }
        }
        break;

      case 'corpse_arc':
        final enemies = _combatants
            .where((other) => other.side != c.side && !other.isDead)
            .toList();
        if (enemies.isNotEmpty) {
          enemies.sort(
            (a, b) => (a.x - c.x).abs().compareTo((b.x - c.x).abs()),
          );
          final primary = enemies.first;
          final range = (special.effectData['range'] as num).toDouble() * 3.28;
          if ((primary.x - c.x).abs() <= range) {
            _highlightedTargetIds.add(primary.npc.id);
            for (final t in enemies) {
              if (t == primary) continue;
              if (sqrt(pow(t.x - primary.x, 2) + pow(t.y - primary.y, 2)) <=
                  25.0) {
                _highlightedTargetIds.add(t.npc.id);
              }
            }
          }
        }
        break;
    }
    notifyListeners();
  }
  void _onCombatantDeath(Combatant target, Combatant? killer) {
    target.isDead = true;
    if (isSurvivalMode) {
      if (killer != null && killer.side == CombatSide.player) {
        final cardType = killer.npc.metadata['cardType'];
        if (cardType != null) {
          final enemyLevel = target.npc.metadata['level'] as int? ?? 1;
          final killXp = enemyLevel == 1 ? 0.5 : (enemyLevel * 2.0);
          killCounts[cardType] = (killCounts[cardType] ?? 0) + 1;
          killXpTotals[cardType] = (killXpTotals[cardType] ?? 0.0) + killXp;
        }
      }
    }
  }

  void _finalizeCombatExp() {
    if (!isSurvivalMode) return;
    combatExp.clear();
    for (final cardType in summonCounts.keys) {
      final summons = summonCounts[cardType] ?? 0;
      if (summons == 0) continue;
      final level = _cardLevels[cardType] ?? 1;
      final baseSummonXp = 2.0 * level;
      final totalSummonXp = baseSummonXp * summons;
      final kills = killCounts[cardType] ?? 0;
      final killsXp = killXpTotals[cardType] ?? 0.0;

      double finalXpChange = 0.0;
      if (_isVictory) {
        finalXpChange = totalSummonXp + killsXp;
      } else {
        if (kills > 0) {
          finalXpChange = (totalSummonXp + killsXp) * 0.5;
        } else {
          finalXpChange = -baseSummonXp;
        }
      }
      combatExp[cardType] = finalXpChange;
    }
  }
}
