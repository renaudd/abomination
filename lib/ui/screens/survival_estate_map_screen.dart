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
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import '../../main.dart' show globalGameState;
import '../../models/survival_state.dart';
import '../widgets/submarine_dock_dialog.dart';
import '../../models/npc.dart';
import '../../models/combat_stats.dart';
import '../../services/survival_service.dart';
import '../../services/combat_unit_service.dart';
import '../../services/combat_unit_factory.dart';
import '../../services/arena_save_service.dart';
import '../widgets/character_blob_renderer.dart';
import '../widgets/fireworks_overlay.dart';
import 'combat_screen.dart';
import 'game_over_screen.dart';
import 'help_screen.dart';
import '../widgets/options_dialog.dart';
import '../widgets/combat_card_detail_modal.dart';
class WeaponUpgradeSpec {
  final String name;
  final int cost;
  final bool isRanged;
  final double damage;
  final double speed;
  final double range;
  final double aoe;
  final String targetingRule;
  final int tier;

  const WeaponUpgradeSpec({
    required this.name,
    required this.cost,
    required this.isRanged,
    required this.damage,
    required this.speed,
    required this.range,
    required this.aoe,
    required this.targetingRule,
    required this.tier,
  });
}

class GeneralWeaponSpec {
  final String name;
  final int cost;
  final bool isRanged;
  final double damage;
  final double speed;
  final double range;
  final double aoe;
  final String targetingRule;
  final int tier;

  const GeneralWeaponSpec({
    required this.name,
    required this.cost,
    required this.isRanged,
    required this.damage,
    required this.speed,
    required this.range,
    required this.aoe,
    required this.targetingRule,
    required this.tier,
  });
}

final List<GeneralWeaponSpec> _generalWeaponMarket = [
  const GeneralWeaponSpec(
    name: 'Iron-Tipped Spear',
    cost: 35,
    isRanged: false,
    damage: 16,
    speed: 1.0,
    range: 1.6,
    aoe: 0.0,
    targetingRule: 'Closest',
    tier: 1,
  ),
  const GeneralWeaponSpec(
    name: 'Heavy Spiked Mace',
    cost: 45,
    isRanged: false,
    damage: 22,
    speed: 1.2,
    range: 1.0,
    aoe: 0.1,
    targetingRule: 'Closest',
    tier: 1,
  ),
  const GeneralWeaponSpec(
    name: 'Standard Matchlock',
    cost: 40,
    isRanged: true,
    damage: 32,
    speed: 3.2,
    range: 7.5,
    aoe: 0.0,
    targetingRule: 'Closest',
    tier: 1,
  ),
  const GeneralWeaponSpec(
    name: 'Flintlock Rifle',
    cost: 65,
    isRanged: true,
    damage: 24,
    speed: 2.2,
    range: 9.5,
    aoe: 0.0,
    targetingRule: 'Closest',
    tier: 1,
  ),
  const GeneralWeaponSpec(
    name: 'Training Musket',
    cost: 25,
    isRanged: true,
    damage: 16,
    speed: 2.4,
    range: 6.0,
    aoe: 0.0,
    targetingRule: 'Closest',
    tier: 1,
  ),

  const GeneralWeaponSpec(
    name: 'Vanguard Halberd',
    cost: 125,
    isRanged: false,
    damage: 18,
    speed: 1.2,
    range: 2.0,
    aoe: 0.3,
    targetingRule: 'Closest',
    tier: 2,
  ),
  const GeneralWeaponSpec(
    name: 'Rifled Carbine',
    cost: 140,
    isRanged: true,
    damage: 34,
    speed: 2.0,
    range: 10.0,
    aoe: 0.0,
    targetingRule: 'Closest',
    tier: 2,
  ),
  const GeneralWeaponSpec(
    name: 'Voltaic Chain Electrodes',
    cost: 160,
    isRanged: true,
    damage: 32,
    speed: 0.9,
    range: 6.0,
    aoe: 0.6,
    targetingRule: 'Closest',
    tier: 2,
  ),

  const GeneralWeaponSpec(
    name: 'Industrial Rivet Gun',
    cost: 200,
    isRanged: true,
    damage: 30,
    speed: 0.9,
    range: 5.0,
    aoe: 0.0,
    targetingRule: 'Low Health',
    tier: 3,
  ),
  const GeneralWeaponSpec(
    name: 'Grenade Splash Grenadier',
    cost: 240,
    isRanged: true,
    damage: 38,
    speed: 1.4,
    range: 7.0,
    aoe: 0.8,
    targetingRule: 'Highest HP',
    tier: 3,
  ),
  const GeneralWeaponSpec(
    name: 'Precision Long-Rifle',
    cost: 280,
    isRanged: true,
    damage: 58,
    speed: 2.3,
    range: 14.0,
    aoe: 0.0,
    targetingRule: 'Weakest',
    tier: 3,
  ),
  const GeneralWeaponSpec(
    name: 'Rocket Launcher Package',
    cost: 320,
    isRanged: true,
    damage: 48,
    speed: 1.5,
    range: 9.0,
    aoe: 1.5,
    targetingRule: 'Towers Only',
    tier: 3,
  ),
];

final List<WeaponUpgradeSpec> _samuraiUpgrades = [
  const WeaponUpgradeSpec(
    name: 'Steel Katana',
    cost: 0,
    isRanged: false,
    damage: 45,
    speed: 0.8,
    range: 1.2,
    aoe: 0.0,
    targetingRule: 'Closest',
    tier: 1,
  ),
  const WeaponUpgradeSpec(
    name: 'Demon-Forged Odachi',
    cost: 180,
    isRanged: false,
    damage: 65,
    speed: 1.2,
    range: 1.8,
    aoe: 0.5,
    targetingRule: 'Closest',
    tier: 2,
  ),
  const WeaponUpgradeSpec(
    name: 'Sacred Dragon Blade',
    cost: 350,
    isRanged: false,
    damage: 90,
    speed: 1.5,
    range: 2.2,
    aoe: 0.8,
    targetingRule: 'Low Health',
    tier: 3,
  ),
];

List<GeneralWeaponSpec> _getAvailableMarketWeapons(
  int turn,
  int villageHealth,
) {
  if (villageHealth <= 0) {
    return _generalWeaponMarket
        .where((w) => w.tier == 1)
        .map(
          (w) => GeneralWeaponSpec(
            name: w.name,
            cost: w.cost * 2,
            isRanged: w.isRanged,
            damage: w.damage,
            speed: w.speed,
            range: w.range,
            aoe: w.aoe,
            targetingRule: w.targetingRule,
            tier: w.tier,
          ),
        )
        .toList();
  }
  final maxTier = turn <= 3
      ? 1
      : turn <= 7
      ? 2
      : 3;
  return _generalWeaponMarket.where((w) => w.tier <= maxTier).toList();
}

WeaponUpgradeSpec _getStartingWeapon(String cardId) {
  switch (cardId) {
    case 'peasant':
      return const WeaponUpgradeSpec(
        name: 'Improvised Pitchfork',
        cost: 0,
        isRanged: false,
        damage: 6,
        speed: 1.3,
        range: 1.0,
        aoe: 0.0,
        targetingRule: 'Closest',
        tier: 1,
      );
    case 'goon':
      return const WeaponUpgradeSpec(
        name: 'Rusty Cleaver',
        cost: 0,
        isRanged: false,
        damage: 14,
        speed: 1.4,
        range: 1.0,
        aoe: 0.0,
        targetingRule: 'Closest',
        tier: 1,
      );
    case 'militia':
      return const WeaponUpgradeSpec(
        name: 'Training Musket',
        cost: 0,
        isRanged: true,
        damage: 16,
        speed: 2.4,
        range: 6.0,
        aoe: 0.0,
        targetingRule: 'Closest',
        tier: 1,
      );
    case 'musketeers':
      return const WeaponUpgradeSpec(
        name: 'Standard Matchlock',
        cost: 0,
        isRanged: true,
        damage: 20,
        speed: 2.8,
        range: 8.0,
        aoe: 0.0,
        targetingRule: 'Closest',
        tier: 1,
      );
    case 'commandos':
      return const WeaponUpgradeSpec(
        name: 'Standard Sub-Carbine',
        cost: 0,
        isRanged: true,
        damage: 22,
        speed: 0.8,
        range: 5.0,
        aoe: 0.0,
        targetingRule: 'Closest',
        tier: 1,
      );
    case 'samurai':
      return const WeaponUpgradeSpec(
        name: 'Steel Katana',
        cost: 0,
        isRanged: false,
        damage: 45,
        speed: 0.8,
        range: 1.2,
        aoe: 0.0,
        targetingRule: 'Closest',
        tier: 1,
      );
    default:
      return const WeaponUpgradeSpec(
        name: 'Fists',
        cost: 0,
        isRanged: false,
        damage: 5,
        speed: 1.0,
        range: 1.0,
        aoe: 0.0,
        targetingRule: 'Closest',
        tier: 1,
      );
  }
}

bool _weaponRequiresArsenal(String name) {
  final n = name.toLowerCase();
  return n.contains('laser') ||
      n.contains('rocket') ||
      n.contains('gatling') ||
      n.contains('sub-carbine') ||
      n.contains('carbine') ||
      n.contains('submachine') ||
      n.contains('assault') ||
      n.contains('rivet') ||
      n.contains('voltaic') ||
      n.contains('dragon');
}

String? _getWeaponCompatibilityError(String cardId, String weaponName) {
  final wn = weaponName.toLowerCase();
  final sampleUnit = CombatUnitService.createUnit(cardId);
  final bool hasSpecialAbilities =
      sampleUnit.abilities.isNotEmpty ||
      cardId == 'witch' ||
      cardId == 'warlock' ||
      cardId == 'hag' ||
      cardId == 'brewers' ||
      cardId == 'necromancer' ||
      cardId == 'minotaur' ||
      cardId == 'phoenix' ||
      cardId == 'valkyrie' ||
      cardId == 'steampunk_mech';

  if (hasSpecialAbilities) {
    if (wn.contains('musket') ||
        wn.contains('matchlock') ||
        wn.contains('flintlock') ||
        wn.contains('sub-carbine') ||
        wn.contains('rivet')) {
      return 'Units with specialized magical or physical abilities cannot equip standard industrial firearms.';
    }
  }

  if (cardId == 'peasant') {
    if (wn.contains('laser') ||
        wn.contains('voltaic') ||
        wn.contains('rocket') ||
        wn.contains('rivet')) {
      return 'Peasants cannot handle advanced high-tech weapons.';
    }
  }
  if (cardId == 'goon') {
    if (wn.contains('precision') || wn.contains('long-rifle')) {
      return 'Goons lack the precision required for sniper rifles.';
    }
  }
  if (cardId == 'militia') {
    if (wn.contains('halberd')) {
      return 'Militia are not trained to wield heavy halberds.';
    }
  }
  if (cardId == 'musketeers') {
    if (wn.contains('spear') || wn.contains('mace') || wn.contains('halberd')) {
      return 'Musketeers are strictly ranged combatants and cannot wield melee weapons.';
    }
  }
  return null;
}

String? _getWeaponAdvantageOrDisadvantage(String cardId, String weaponName) {
  final wn = weaponName.toLowerCase();
  final baseWep =
      _generalWeaponMarket.where((w) => w.name == weaponName).firstOrNull;
  int tier = 1;
  final samWepIndex = _samuraiUpgrades.indexWhere((w) => w.name == weaponName);
  if (samWepIndex != -1) {
    tier = _samuraiUpgrades[samWepIndex].tier;
  } else if (baseWep != null) {
    tier = baseWep.tier;
  }

  if (tier == 2) {
    return 'PERFORMANCE IMPACT: +1 AP Summon Cost & -15% Locomotion Speed (Tier 2 Advanced Gear)';
  } else if (tier == 3) {
    return 'PERFORMANCE IMPACT: +2 AP Summon Cost & -25% Locomotion Speed (Tier 3 Masterwork Gear)';
  }

  if (cardId == 'peasant') {
    if (wn.contains('spear') || wn.contains('mace') || wn.contains('halberd')) {
      return 'ADVANTAGE: +10% Melee Damage (Peasant affinity)';
    }
  }
  if (cardId == 'goon') {
    if (wn.contains('mace') || wn.contains('rocket') || wn.contains('rivet')) {
      return 'ADVANTAGE: +15% Heavy Weapon Damage';
    }
    if (wn.contains('matchlock') ||
        wn.contains('rifle') ||
        wn.contains('musket')) {
      return 'DISADVANTAGE: 20% slower speed with light ranged firearms';
    }
  }
  if (cardId == 'militia') {
    if (wn.contains('spear') || wn.contains('mace')) {
      return 'DISADVANTAGE: -15% Melee Damage (Unskilled hand-to-hand)';
    }
  }
  if (cardId == 'musketeers') {
    if (wn.contains('rifle') ||
        wn.contains('musket') ||
        wn.contains('matchlock')) {
      return 'ADVANTAGE: +15% Ranged Weapon Damage';
    }
  }
  if (cardId == 'commandos') {
    if (wn.contains('laser') ||
        wn.contains('voltaic') ||
        wn.contains('rocket')) {
      return 'ADVANTAGE: +10% attack rate with advanced energy/explosive gear';
    }
  }
  return null;
}

WeaponUpgradeSpec _getEquippedWeaponStats(String cardId, String weaponName) {
  final starting = _getStartingWeapon(cardId);
  if (starting.name == weaponName) {
    return starting;
  }

  // Check if it is a specialized Samurai upgrade
  final samWepIndex = _samuraiUpgrades.indexWhere((w) => w.name == weaponName);
  if (samWepIndex != -1) {
    return _samuraiUpgrades[samWepIndex];
  }

  final baseWep = _generalWeaponMarket.firstWhere(
    (w) => w.name == weaponName,
    orElse: () => GeneralWeaponSpec(
      name: weaponName,
      cost: 0,
      isRanged: false,
      damage: 10,
      speed: 1.0,
      range: 1.0,
      aoe: 0.0,
      targetingRule: 'Closest',
      tier: 1,
    ),
  );

  double finalDmg = baseWep.damage;
  double finalSpeed = baseWep.speed;

  if (cardId == 'peasant') {
    final wn = weaponName.toLowerCase();
    if (wn.contains('spear') || wn.contains('mace') || wn.contains('halberd')) {
      finalDmg *= 1.1;
    }
  }

  if (cardId == 'goon') {
    final wn = weaponName.toLowerCase();
    if (wn.contains('mace') || wn.contains('rocket') || wn.contains('rivet')) {
      finalDmg *= 1.15;
    }
    if (wn.contains('matchlock') ||
        wn.contains('rifle') ||
        wn.contains('musket')) {
      finalSpeed *= 1.2; // 20% slower speed
    }
  }

  if (cardId == 'militia') {
    final wn = weaponName.toLowerCase();
    if (wn.contains('spear') || wn.contains('mace')) {
      finalDmg *= 0.85;
    }
  }

  if (cardId == 'musketeers') {
    final wn = weaponName.toLowerCase();
    if (wn.contains('rifle') ||
        wn.contains('musket') ||
        wn.contains('matchlock')) {
      finalDmg *= 1.15;
    }
  }

  if (cardId == 'commandos') {
    final wn = weaponName.toLowerCase();
    if (wn.contains('laser') ||
        wn.contains('voltaic') ||
        wn.contains('rocket')) {
      finalSpeed *= 0.9; // 10% faster attack rate
    }
  }

  return WeaponUpgradeSpec(
    name: baseWep.name,
    cost: baseWep.cost,
    isRanged: baseWep.isRanged,
    damage: finalDmg,
    speed: finalSpeed,
    range: baseWep.range,
    aoe: baseWep.aoe,
    targetingRule: baseWep.targetingRule,
    tier: baseWep.tier,
  );
}

int _getSquadSize(String type) {
  try {
    final npc = CombatUnitService.createUnit(type);
    return npc.combatStats?.unitCount ?? 1;
  } catch (_) {
    return 1;
  }
}

class SurvivalEstateMapScreen extends StatefulWidget {
  const SurvivalEstateMapScreen({super.key});

  @override
  State<SurvivalEstateMapScreen> createState() =>
      _SurvivalEstateMapScreenState();
}

class _SurvivalEstateMapScreenState extends State<SurvivalEstateMapScreen> {
  bool _isDrafting = true;
  final List<String> _selectedCart = [];
  bool _hasCheckedInitialEvents = false;

  String _activeTab =
      'ESTATE'; // 'ESTATE', 'DECK', 'LEADER', 'TOWERS', 'MARKET', 'MANOR_RECORDS'
  final Map<String, GeneralWeaponSpec?> _evaluatedWeaponForCard = {};

  late TransformationController _transformationController;
  bool _initialScaleSet = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController(
      Matrix4.diagonal3Values(0.35, 0.35, 1.0),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  double _scoreWeapon(String cardId, WeaponUpgradeSpec spec) {
    double score = spec.damage / (spec.speed <= 0 ? 1.0 : spec.speed);
    score += spec.range * 0.5;
    if (spec.aoe > 0) {
      score *= (1.0 + spec.aoe);
    }
    return score;
  }

  GeneralWeaponSpec? _getEvaluatedWeapon(
    BuildContext context,
    String cardId,
    List<GeneralWeaponSpec> availableWeps,
  ) {
    final service = Provider.of<SurvivalService>(context, listen: false);
    final progress = service.progress!;
    final currentWepIdx =
        progress.cardUpgrades['${cardId}_equipped_weapon_idx'] ?? 0;
    final currentWepName = currentWepIdx == 0
        ? _getStartingWeapon(cardId).name
        : _generalWeaponMarket[currentWepIdx - 1].name;
    final currWep = _getEquippedWeaponStats(cardId, currentWepName);
    final currentScore = _scoreWeapon(cardId, currWep);

    final arsenalBuilding = progress.buildings.firstWhere(
      (b) => b.type == SurvivalBuildingType.arsenal,
      orElse: () => SurvivalBuilding(
        id: '',
        type: SurvivalBuildingType.arsenal,
        level: 0,
        assignedUnitIds: [],
      ),
    );
    final arsenalLvl = arsenalBuilding.level;
    final squadSize = _getSquadSize(cardId);

    final compatibleWeps = availableWeps.where((w) {
      if (_getWeaponCompatibilityError(cardId, w.name) != null) return false;
      if (progress.cash < w.cost * squadSize) return false;
      final reqLvl = _weaponRequiresArsenal(w.name) ? w.tier : 0;
      if (arsenalLvl < reqLvl) return false;
      return true;
    }).toList();

    if (compatibleWeps.isEmpty) return null;

    if (!_evaluatedWeaponForCard.containsKey(cardId) ||
        _evaluatedWeaponForCard[cardId] == null) {
      GeneralWeaponSpec? recommended;
      double bestScore = currentScore;
      for (var wep in compatibleWeps) {
        final wepStats = _getEquippedWeaponStats(cardId, wep.name);
        final score = _scoreWeapon(cardId, wepStats);
        if (score > bestScore) {
          bestScore = score;
          recommended = wep;
        }
      }
      _evaluatedWeaponForCard[cardId] = recommended ?? compatibleWeps.first;
    } else {
      final prevSelected = _evaluatedWeaponForCard[cardId];
      if (!compatibleWeps.contains(prevSelected)) {
        _evaluatedWeaponForCard.remove(cardId);
        return _getEvaluatedWeapon(context, cardId, availableWeps);
      }
    }

    return _evaluatedWeaponForCard[cardId];
  }

  bool _showCardDetails = false;
  bool _showDraftCardDetails = false;
  String? _selectedWepCardId;
  String? _selectedInspectorCardId;

  bool _showDiceOverlay = false;
  bool _isDiceRolling = false;
  int _die1 = 1;
  int _die2 = 1;
  String _diceOutcomeMessage = '';
  VoidCallback? _diceOutcomeAction;
  int? _lastDiceTotal;

  set selectedInspectorCardId(String? val) {
    setState(() {
      _selectedInspectorCardId = val;
    });
  }

  set selectedWepCardId(String? val) {
    setState(() {
      _selectedWepCardId = val;
    });
  }

  set activeTab(String val) {
    setState(() {
      _activeTab = val;
    });
  }

  final List<Map<String, dynamic>> _draftPool = [
    {'type': 'peasant', 'cost': 150, 'name': 'Peasant'},
    {'type': 'bats', 'cost': 200, 'name': 'Bats'},
    {'type': 'militia', 'cost': 220, 'name': 'Militia'},
    {'type': 'brown_rats', 'cost': 180, 'name': 'Brown Rats Swarm'},
    {'type': 'undead_rats', 'cost': 190, 'name': 'Undead Rats Swarm'},
    {'type': 'samurai', 'cost': 250, 'name': 'Samurai'},
    {'type': 'musketeers', 'cost': 260, 'name': 'Musketeers'},
    {'type': 'commandos', 'cost': 300, 'name': 'Commandos'},
    {'type': 'bicycle_gang', 'cost': 240, 'name': 'Bicycle Gang'},
    {'type': 'werewolf', 'cost': 350, 'name': 'Werewolf'},
    {'type': 'chimera', 'cost': 500, 'name': 'Chimera (Behemoth)'},
    {'type': 'flesh_golem', 'cost': 320, 'name': 'Flesh Golem'},
    {'type': 'cavalry', 'cost': 280, 'name': 'Cavalry'},
    {'type': 'cannoneer', 'cost': 320, 'name': 'Cannoneer'},
    {'type': 'sniper', 'cost': 300, 'name': 'Sniper'},
    {'type': 'pikemen', 'cost': 230, 'name': 'Pikemen'},
    {'type': 'marksmen', 'cost': 240, 'name': 'Marksmen'},
    {'type': 'wild_bear', 'cost': 290, 'name': 'Wild Bear'},
    {'type': 'brewers', 'cost': 210, 'name': 'Brewers'},
    {'type': 'hag', 'cost': 280, 'name': 'Hag'},
    {'type': 'witch', 'cost': 240, 'name': 'Witch'},
    {'type': 'warlock', 'cost': 250, 'name': 'Warlock'},
    {'type': 'goon', 'cost': 220, 'name': 'Goons'},
    {'type': 'deserters', 'cost': 210, 'name': 'Deserters'},
  ];

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<SurvivalService>(context);
    final state = Provider.of<GameState>(context);
    final progress = service.progress;

    if (progress == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF15100B),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFC4B89B)),
        ),
      );
    }

    final bool redHandUnlocked =
        state.unlockedDiscoveries.contains('red_hand_insignia') ||
        progress.cardUpgrades['red_hand_insignia_unlocked'] == 1;
    if (redHandUnlocked &&
        progress.cardUpgrades['red_hand_insignia_unlocked'] != 1) {
      progress.cardUpgrades['red_hand_insignia_unlocked'] = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        service.manualSave();
      });
    }

    if (!_hasCheckedInitialEvents) {
      _hasCheckedInitialEvents = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndTriggerRippleEffects(context);
      });
    }

    final t1Destroyed = (progress.towerDamaged['tower_1'] ?? 0.0) >= 1.0;
    final t2Destroyed = (progress.towerDamaged['tower_2'] ?? 0.0) >= 1.0;
    final t3Destroyed = (progress.towerDamaged['tower_3'] ?? 0.0) >= 1.0;
    final allTowersDestroyed = t1Destroyed && t2Destroyed && t3Destroyed;

    if (allTowersDestroyed &&
        progress.difficulty != SurvivalDifficulty.elementary) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (progress.difficulty == SurvivalDifficulty.arcade) {
          ArenaSaveService.deleteSave(service.activeSlot);
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameOverScreen(
              reason: 'All watchtowers have fallen. The estate is overrun.',
              difficulty: progress.difficulty,
              turnsSurvived: progress.currentTurn,
            ),
          ),
        );
      });
    }

    // Turn off embark shop overlay if player already finished drafting (deck contains cards and we aren't showing drafting)
    if (_isDrafting &&
        progress.playerDeckIds.isNotEmpty &&
        _selectedCart.isEmpty) {
      _isDrafting = false;
    }



    Widget centerArea;
    switch (_activeTab) {
      case 'ESTATE':
        centerArea = Row(
          children: [
            // Left: Estate Board (Organic 2D map)
            Expanded(flex: 3, child: _buildEstateBoard(progress, service)),
            // Right: Side Deck / Worker placement source drawer
            Container(
              width: 220,
              decoration: const BoxDecoration(
                color: Color(0xFF1E1712),
                border: Border(left: BorderSide(color: Colors.white10)),
              ),
              child: _buildSideDeckDrawer(progress, service),
            ),
          ],
        );
        break;
      case 'DECK':
        centerArea = _buildFullDeckView(progress, service, state);
        break;
      case 'LEADER':
        centerArea = _buildFullLeaderView(progress, service);
        break;
      case 'TOWERS':
        centerArea = _buildFullTowersView(progress, service);
        break;
      case 'MARKET':
        centerArea = _buildFullMarketView(progress, service);
        break;
      case 'MANOR_RECORDS':
        centerArea = _buildFullManorRecordsView(progress, service);
        break;
      default:
        centerArea = const SizedBox();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF15100B),
      body: Stack(
        children: [
          // 1. MAIN VIEWPORT (Interactive Map & HUD)
          Column(
            children: [
              // Top HUD Header
              _buildHUD(progress, service, state),
              // Main Content Area
              Expanded(child: centerArea),
              // Bottom Control & Logs Footer
              if (_activeTab == 'ESTATE')
                _buildFooter(progress, service, state),
            ],
          ),

          // 2. DRAFT EMBARK SHOP OVERLAY
          if (_isDrafting) _buildDraftOverlay(progress, service),

          // 3. COMBAT CARD DETAIL INSPECTOR OVERLAY
          if (_selectedInspectorCardId != null)
            _buildCardInspector(
              context,
              progress,
              service,
              _selectedInspectorCardId!,
            ),

          // 4. DICE ROLL OVERLAY
          if (_showDiceOverlay) _buildDiceRollOverlay(progress, service, state),
        ],
      ),
    );
  }

  // HUD HEADER
  Widget _buildHUD(
    SurvivalProgress progress,
    SurvivalService service,
    GameState state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.terrain, color: Color(0xFFC4B89B), size: 18),
              const SizedBox(width: 6),
              Text(
                'TURN ${progress.currentTurn} - ESTATE',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNavButton(
                'ESTATE',
                () => setState(() => _activeTab = 'ESTATE'),
              ),
              _buildNavButton(
                'DECK',
                () => setState(() => _activeTab = 'DECK'),
              ),
              _buildNavButton(
                'LEADER',
                () => setState(() => _activeTab = 'LEADER'),
              ),
              _buildNavButton(
                'TOWERS',
                () => setState(() => _activeTab = 'TOWERS'),
              ),
              _buildNavButton(
                'MARKET',
                () => setState(() => _activeTab = 'MARKET'),
              ),
              _buildNavButton(
                'MENU',
                () => _showMenuOverlay(progress, service, state),
              ),
            ],
          ),

          Row(
            children: [
              _buildResourceChip(
                Icons.monetization_on,
                '${progress.cash} CHF',
                Colors.amber.shade700,
              ),
              const SizedBox(width: 8),
              _buildResourceChip(
                Icons.restaurant,
                '${progress.food} FOOD',
                Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              _buildResourceChip(
                Icons.forest,
                '${progress.wood} WOOD',
                Colors.brown.shade700,
              ),
              const SizedBox(width: 8),
              _buildResourceChip(
                Icons.construction,
                '${progress.iron} IRON',
                Colors.blueGrey.shade600,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF211B15),
          border: Border.all(
            color: const Color(0xFFC4B89B).withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFE5D5B0),
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildResourceChip(IconData icon, String val, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.1),
        border: Border.all(color: col.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: col),
          const SizedBox(width: 4),
          Text(
            val,
            style: GoogleFonts.oswald(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ORGANIC ESTATE BOARD
  Widget _buildEstateBoard(SurvivalProgress progress, SurvivalService service) {
    final List<String> letters = [];
    if ((progress.towerDamaged['tower_1'] ?? 0.0) >= 1.0) letters.add('W');
    if ((progress.towerDamaged['tower_2'] ?? 0.0) >= 1.0) letters.add('M');
    if ((progress.towerDamaged['tower_3'] ?? 0.0) >= 1.0) letters.add('E');
    letters.sort();
    final towerLetters = letters.join('');
    final hasTowerDamage = towerLetters.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double minScaleX = constraints.maxWidth / 2782;
        final double minScaleY = constraints.maxHeight / 1536;
        final double computedMinScale = max(
          minScaleX,
          minScaleY,
        ).clamp(0.1, 3.0);

        if (!_initialScaleSet) {
          _initialScaleSet = true;
          final double initialScale = (1.05 * computedMinScale).clamp(0.1, 3.0);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _transformationController.value = Matrix4.diagonal3Values(initialScale, initialScale, 1.0);
            }
          });
        }

        return InteractiveViewer(
          transformationController: _transformationController,
          constrained: false,
          minScale: computedMinScale,
          maxScale: 3.0,
          boundaryMargin: EdgeInsets.zero,
          child: SizedBox(
            width: 2782,
            height: 1536,
            child: Stack(
              children: [
                // 1. Base Map Image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/survival/Estate.png',
                    fit: BoxFit.cover,
                  ),
                ),

                // 2. Tower Damage Overlay
                if (hasTowerDamage)
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/survival/${towerLetters}damage.png',
                      fit: BoxFit.cover,
                    ),
                  ),

                // 3. Village Fallow Overlay
                if (progress.villageHealth <= 0)
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/survival/VillagetoFallow.png',
                      fit: BoxFit.cover,
                    ),
                  ),

                // 4. Plot Upgrades Overlays
                ..._buildPlotOverlays(progress),

                // 5. Transparent Interactive Buttons

                // Manor House Button
                _buildManorHouseButton(440, 610, 420, 320),

                // Towers Buttons
                _buildTowerButton(
                  progress,
                  service,
                  'tower_1',
                  'WEST TOWER',
                  150,
                  900,
                  160,
                  280,
                ),
                _buildTowerButton(
                  progress,
                  service,
                  'tower_2',
                  'MIDDLE TOWER',
                  420,
                  940,
                  160,
                  280,
                ),
                _buildTowerButton(
                  progress,
                  service,
                  'tower_3',
                  'EAST TOWER',
                  640,
                  900,
                  160,
                  280,
                ),

                // Village Button
                _buildVillageButton(progress, 1630, 780, 360, 250),

                // Training Yard
                _buildTrainingYardButton(progress, service, 1240, 50, 700, 280),

                // Plots (A, B, C, D, E, F, G)
                _buildPlotButton(
                  progress,
                  service,
                  'plot_a',
                  'AROSA PLOT (INDUSTRY)',
                  205,
                  290,
                  340,
                  240,
                  cost: 0,
                ),
                _buildPlotButton(
                  progress,
                  service,
                  'plot_b',
                  'BERN PLOT (INDUSTRY)',
                  785,
                  290,
                  340,
                  240,
                  cost: 5000,
                ),
                _buildPlotButton(
                  progress,
                  service,
                  'plot_c',
                  'CHUR FARM PLOT',
                  1180,
                  720,
                  380,
                  280,
                  cost: 0,
                ),
                _buildPlotButton(
                  progress,
                  service,
                  'plot_d',
                  'DAVOS PLOT (RESOURCE)',
                  1660,
                  540,
                  340,
                  240,
                  cost: 0,
                ),
                _buildPlotButton(
                  progress,
                  service,
                  'plot_e',
                  'ENGELBERG PLOT (RESOURCE)',
                  2360,
                  595,
                  340,
                  240,
                  cost: 2000,
                ),
                _buildPlotButton(
                  progress,
                  service,
                  'plot_f',
                  'FRIBOURG PLOT (RESOURCE)',
                  1980,
                  847,
                  340,
                  240,
                  cost: 0,
                ),
                _buildPlotButton(
                  progress,
                  service,
                  'plot_g',
                  'GRINDELWALD PLOT (RESOURCE)',
                  1520,
                  1065,
                  380,
                  260,
                  cost: 5000,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPlotOverlays(SurvivalProgress progress) {
    final List<Widget> list = [];

    SurvivalBuilding? getBuilding(String plotKey) {
      final idx = progress.buildings.indexWhere((x) => x.id == plotKey);
      return idx == -1 ? null : progress.buildings[idx];
    }

    final plots = [
      'plot_a',
      'plot_b',
      'plot_c',
      'plot_d',
      'plot_e',
      'plot_f',
      'plot_g',
    ];
    for (var plotKey in plots) {
      final b = getBuilding(plotKey);
      final letter = plotKey.replaceAll("plot_", "").toUpperCase();

      if (b != null) {
        String? assetName;
        if (plotKey == 'plot_c') {
          if (b.level >= 6) {
            assetName = 'CtoFarm6.png';
          } else if (b.level >= 4) {
            assetName = 'CtoFarm4.png';
          } else if (b.level >= 2) {
            assetName = 'CtoFarm2.png';
          }
        } else {
          switch (b.type) {
            case SurvivalBuildingType.farm:
              assetName = '${letter}toFarm.png';
              break;
            case SurvivalBuildingType.lumberMill:
              assetName = '${letter}toMill.png';
              break;
            case SurvivalBuildingType.mine:
              if (b.level >= 5 &&
                  (plotKey == 'plot_d' ||
                      plotKey == 'plot_e' ||
                      plotKey == 'plot_f')) {
                assetName = '${letter}toMine5.png';
              } else {
                assetName = '${letter}toMine.png';
              }
              break;
            case SurvivalBuildingType.arsenal:
              assetName = '${letter}toArsenal.png';
              break;
            case SurvivalBuildingType.garage:
              assetName = '${letter}toGarage.png';
              break;
            case SurvivalBuildingType.munitionsFactory:
              assetName = '${letter}toMunitions.png';
              break;
          }
        }

        if (assetName != null) {
          list.add(
            Positioned.fill(
              child: Image.asset(
                'assets/images/survival/$assetName',
                fit: BoxFit.cover,
              ),
            ),
          );
        }
      } else {
        final isFallow =
            progress.cardUpgrades['${plotKey}_fallow'] == 1 ||
            (plotKey == 'plot_c');
        if (isFallow) {
          list.add(
            Positioned.fill(
              child: Image.asset(
                'assets/images/survival/${letter}toFallow.png',
                fit: BoxFit.cover,
              ),
            ),
          );
        }
      }
    }

    return list;
  }

  bool _isStartingPlot(String plotKey) {
    return plotKey == 'plot_a' ||
        plotKey == 'plot_c' ||
        plotKey == 'plot_d' ||
        plotKey == 'plot_f';
  }

  Widget _buildManorHouseButton(
    double left,
    double top,
    double width,
    double height,
  ) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _activeTab = 'MANOR_RECORDS';
            });
          },
          hoverColor: Colors.amber.withValues(alpha: 0.05),
          splashColor: Colors.amber.withValues(alpha: 0.1),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.0),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.castle, color: Color(0xFFD4AF37), size: 48),
                const SizedBox(height: 4),
                Text(
                  'MANOR HOUSE',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTowerButton(
    SurvivalProgress progress,
    SurvivalService service,
    String towerId,
    String label,
    double left,
    double top,
    double width,
    double height,
  ) {
    final isDestroyed = (progress.towerDamaged[towerId] ?? 0.0) >= 1.0;
    final lvl = progress.getTowerLevel(towerId);
    final workers = progress.towerRepairWorkers[towerId] ?? [];

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              _showTowerDetailsDialog(context, progress, service, towerId),
          hoverColor: Colors.red.withValues(alpha: 0.05),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isDestroyed
                    ? Colors.red.withValues(alpha: 0.5)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDestroyed) ...[
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.orangeAccent,
                    size: 44,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'REPAIR $label',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.redAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      progress.getTowerRepairSlotsCap(towerId),
                      (idx) {
                        final hasWorker = idx < workers.length;
                        final workerId = hasWorker ? workers[idx] : null;
                        final cap = progress.getTowerRepairSlotsCap(towerId);

                        return DragTarget<String>(
                          onWillAcceptWithDetails: (details) {
                            final npc = CombatUnitService.createUnit(details.data);
                            return workers.length < cap && SurvivalService.isHumanoid(npc);
                          },
                          onAcceptWithDetails: (details) {
                            service.assignTowerRepair(towerId, details.data);
                            setState(() {});
                          },
                          builder: (context, candidateData, rejectedData) {
                            final isOver = candidateData.isNotEmpty;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasWorker
                                    ? const Color(0xFF4E342E)
                                    : Colors.black45,
                                border: Border.all(
                                  color: isOver
                                      ? const Color(0xFFD4AF37)
                                      : const Color(
                                          0xFFD4AF37,
                                        ).withValues(alpha: 0.6),
                                  width: isOver ? 3.0 : 2.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: hasWorker
                                  ? Draggable<String>(
                                      data: workerId!,
                                      dragAnchorStrategy:
                                          (draggable, context, position) =>
                                              const Offset(24, 24),
                                      feedback: Material(
                                        color: Colors.transparent,
                                        child: CharacterBlobRenderer(
                                          npc: CombatUnitService.createUnit(
                                            workerId,
                                          ),
                                          size: 48,
                                          isCombat: true,
                                        ),
                                      ),
                                      onDragCompleted: () {
                                        setState(() {});
                                      },
                                      child: CharacterBlobRenderer(
                                        npc: CombatUnitService.createUnit(
                                          workerId,
                                        ),
                                        size: 44,
                                        isCombat: true,
                                      ),
                                    )
                                  : const SizedBox(),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.security, color: Colors.white24, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    '$label Lvl $lvl',
                    style: GoogleFonts.oldStandardTt(
                      color: Colors.white30,
                      fontSize: 16,
                      shadows: const [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVillageButton(
    SurvivalProgress progress,
    double left,
    double top,
    double width,
    double height,
  ) {
    final isFallow = progress.villageHealth <= 0;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  backgroundColor: const Color(0xFF1E1712),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: isFallow
                          ? Colors.redAccent
                          : const Color(0xFFC4B89B),
                      width: 2,
                    ),
                  ),
                  title: Center(
                    child: Text(
                      'THE HAMLET OF GLARUS',
                      style: GoogleFonts.playfairDisplay(
                        color: isFallow
                            ? Colors.redAccent
                            : const Color(0xFFD4AF37),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isFallow
                            ? 'The Village of Glarus lies in ruins, completely abandoned and cleared. No human squads can be recruited and the armory is depleted.'
                            : 'The Village is healthy and supporting Frankenstein Estate. Human units and advanced weapons configurations are available in the marketplace.',
                        style: GoogleFonts.oldStandardTt(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 13,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Village Condition: ${isFallow ? "DESTROYED (Fallow)" : "HEALTHY (100%)"}',
                        style: GoogleFonts.oswald(
                          color: isFallow ? Colors.red : Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'CLOSE',
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          hoverColor: Colors.green.withValues(alpha: 0.05),
          child: Container(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFallow ? Icons.home_work_outlined : Icons.home_work,
                  color: isFallow
                      ? Colors.redAccent.withValues(alpha: 0.5)
                      : const Color(0xFFC4B89B).withValues(alpha: 0.6),
                  size: 44,
                ),
                const SizedBox(height: 4),
                Text(
                  isFallow ? 'GLARUS VILLAGE\n(DESTROYED)' : 'GLARUS VILLAGE',
                  style: GoogleFonts.playfairDisplay(
                    color: isFallow
                        ? Colors.redAccent
                        : const Color(0xFFE5D5B0).withValues(alpha: 0.8),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingYardButton(
    SurvivalProgress progress,
    SurvivalService service,
    double left,
    double top,
    double width,
    double height,
  ) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) =>
            progress.trainingUnitIds.length < 8,
        onAcceptWithDetails: (details) {
          service.assignTraining(details.data);
        },
        builder: (context, candidateData, rejectedData) {
          final isOver = candidateData.isNotEmpty;
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isOver ? const Color(0xFFD4AF37) : Colors.white12,
                width: isOver ? 2 : 1,
              ),
              color: isOver
                  ? Colors.brown.withValues(alpha: 0.1)
                  : Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'TRAINING GROUNDS',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(8, (idx) {
                    final hasTrainee = idx < progress.trainingUnitIds.length;
                    return Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasTrainee
                            ? const Color(0xFF4E342E)
                            : Colors.black45,
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                          width: 2.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: hasTrainee
                          ? Draggable<String>(
                              data: progress.trainingUnitIds[idx],
                              dragAnchorStrategy:
                                  (draggable, context, position) =>
                                      const Offset(24, 24),
                              feedback: Material(
                                color: Colors.transparent,
                                child: CharacterBlobRenderer(
                                  npc: CombatUnitService.createUnit(
                                    progress.trainingUnitIds[idx],
                                  ),
                                  size: 48,
                                  isCombat: true,
                                ),
                              ),
                              onDragCompleted: () {
                                setState(() {});
                              },
                              child: CharacterBlobRenderer(
                                npc: CombatUnitService.createUnit(
                                  progress.trainingUnitIds[idx],
                                ),
                                size: 44,
                                isCombat: true,
                              ),
                            )
                          : const SizedBox(),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlotButton(
    SurvivalProgress progress,
    SurvivalService service,
    String plotKey,
    String name,
    double left,
    double top,
    double width,
    double height, {
    required int cost,
  }) {
    final isStarting = _isStartingPlot(plotKey);
    final isPurchased = progress.purchasedPlots.contains(plotKey);
    final isLocked = !isStarting && !isPurchased;

    final bIdx = progress.buildings.indexWhere((x) => x.id == plotKey);
    final isBuilt = bIdx != -1;
    final b = isBuilt ? progress.buildings[bIdx] : null;

    if (isLocked) {
      return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () =>
                _showPurchasePlotConfirmation(context, service, plotKey, cost),
            hoverColor: Colors.amber.withValues(alpha: 0.1),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: Colors.redAccent,
                    size: 44,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'BUY: $cost CHF',
                    style: GoogleFonts.oswald(
                      color: const Color(0xFFD4AF37),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!isBuilt) {
      return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showBuildMenu(context, service, plotKey),
            hoverColor: Colors.amber.withValues(alpha: 0.08),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFC4B89B).withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_box, color: Color(0xFFC4B89B), size: 44),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final caps = b!.getWorkerCap();

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) {
          final npc = CombatUnitService.createUnit(details.data);
          final state = Provider.of<GameState>(context, listen: false);
          final hasBeastLabor = state.unlockedDiscoveries.contains(
            'beast_labor',
          );
          return b.assignedUnitIds.length < caps &&
              (SurvivalService.isHumanoid(npc) ||
                  (SurvivalService.isWildAnimal(npc) && hasBeastLabor));
        },
        onAcceptWithDetails: (details) {
          service.assignWorker(plotKey, details.data);
        },
        builder: (context, candidateData, rejectedData) {
          final isOver = candidateData.isNotEmpty;
          return GestureDetector(
            onTap: () => _showFacilityDetailsDialog(context, service, b),
            child: Container(
              decoration: BoxDecoration(
                color: isOver
                    ? Colors.brown.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: Border.all(
                  color: isOver
                      ? const Color(0xFFD4AF37)
                      : const Color(0xFFC4B89B).withValues(alpha: 0.4),
                  width: isOver ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    b.type.displayName.toUpperCase(),
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Lvl ${b.level}',
                    style: GoogleFonts.oldStandardTt(
                      color: Colors.white70,
                      fontSize: 18,
                      shadows: const [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(caps, (idx) {
                      final hasWorker = idx < b.assignedUnitIds.length;
                      return Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasWorker
                              ? const Color(0xFF4E342E)
                              : Colors.black45,
                          border: Border.all(
                            color: const Color(
                              0xFFD4AF37,
                            ).withValues(alpha: 0.6),
                            width: 2.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: hasWorker
                            ? Draggable<String>(
                                data: b.assignedUnitIds[idx],
                                dragAnchorStrategy:
                                    (draggable, context, position) =>
                                        const Offset(24, 24),
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: CharacterBlobRenderer(
                                    npc: CombatUnitService.createUnit(
                                      b.assignedUnitIds[idx],
                                    ),
                                    size: 48,
                                    isCombat: true,
                                  ),
                                ),
                                onDragCompleted: () {
                                  setState(() {});
                                },
                                child: CharacterBlobRenderer(
                                  npc: CombatUnitService.createUnit(
                                    b.assignedUnitIds[idx],
                                  ),
                                  size: 44,
                                  isCombat: true,
                                ),
                              )
                            : const SizedBox(),
                      );
                    }),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  NPC getUpgradedUnitForModal(String t, SurvivalProgress progress) {
    final npc = CombatUnitService.createUnit(t);
    final lvl = progress.getUnitLevel(t);
    final mult = 1.0 + (lvl - 1) * 0.1;
    double distance = npc.combatStats!.distance;
    double rangedRange = npc.combatStats!.rangedRange;
    double baseAttack = npc.combatStats!.attack.toDouble();
    double baseSpeed = npc.combatStats!.speed;
    double baseMovement = npc.combatStats!.movement;
    int baseCost = npc.combatStats!.cost;

    if (t == 'cannoneer' && lvl >= 6) {
      distance = 23.0;
      rangedRange = 23.0;
    }

    bool hasRanged = npc.combatStats!.rangedDamage > 0.0;

    final int rawWepIdx = progress.cardUpgrades['${t}_equipped_weapon_idx'] ??
        (t == 'samurai' ? progress.cardUpgrades['samurai_equipped_weapon'] : 0) ??
        0;
    if (rawWepIdx > 0) {
      final int cSamIdx = rawWepIdx.clamp(0, _samuraiUpgrades.length - 1);
      final int cGenIdx = (rawWepIdx - 1).clamp(0, _generalWeaponMarket.length - 1);
      final String wepName = t == 'samurai'
          ? _samuraiUpgrades[cSamIdx].name
          : _generalWeaponMarket[cGenIdx].name;
      final wepStats = _getEquippedWeaponStats(t, wepName);

      baseAttack = wepStats.damage;
      distance = wepStats.range;
      rangedRange = wepStats.range;
      hasRanged = wepStats.isRanged;
      baseSpeed = wepStats.speed;

      if (wepStats.tier == 2) {
        baseCost += 1;
        baseMovement *= 0.85;
      } else if (wepStats.tier == 3) {
        baseCost += 2;
        baseMovement *= 0.75;
      }
    }

    final bool isLeader = (t == progress.selectedLeaderId);
    final bool redHandActive =
        progress.cardUpgrades['red_hand_insignia_active'] == 1;
    if (redHandActive && !isLeader) {
      baseMovement *= 1.10;
    }

    final bool hasRosicrucianCurse = isLeader && (progress.cardUpgrades['rosicrucian_curse_active'] == 1);
    final double healthVal = (npc.combatStats!.health * mult) - (hasRosicrucianCurse ? 100.0 : 0.0);
    final double maxHealthVal = (npc.combatStats!.maxHealth * mult) - (hasRosicrucianCurse ? 100.0 : 0.0);

    double finalAttack;
    double finalMeleeDamage;
    double finalRangedDamage;

    if (rawWepIdx > 0) {
      finalAttack = baseAttack * mult;
      finalMeleeDamage = baseAttack * mult;
      finalRangedDamage = hasRanged ? baseAttack * mult : 0.0;
    } else {
      finalAttack = npc.combatStats!.attack * mult;
      finalMeleeDamage = (npc.combatStats!.meleeDamage > 0
              ? npc.combatStats!.meleeDamage.toDouble()
              : npc.combatStats!.attack.toDouble()) *
          mult;
      finalRangedDamage = npc.combatStats!.rangedDamage * mult;
    }

    if (redHandActive && !isLeader) {
      finalAttack *= 1.20;
      finalMeleeDamage *= 1.20;
      finalRangedDamage *= 1.20;
    }

    return npc.copyWith(
      metadata: {
        ...npc.metadata,
        'cardType': t,
        'level': lvl,
        if (isLeader && progress.cardUpgrades['rosicrucian_blessing_active'] == 1) 'rosicrucian_blessing_active': 1,
      },
      combatStats: npc.combatStats?.copyWith(
        cost: baseCost,
        speed: baseSpeed,
        movement: baseMovement,
        health: max(1.0, healthVal),
        maxHealth: max(1.0, maxHealthVal),
        attack: finalAttack,
        meleeDamage: finalMeleeDamage,
        rangedDamage: finalRangedDamage,
        distance: hasRanged ? distance : npc.combatStats!.distance,
        rangedRange: hasRanged ? rangedRange : 0.0,
      ),
    );
  }

  // DRAWERS & FOOTERS
  Widget _buildSideDeckDrawer(
    SurvivalProgress progress,
    SurvivalService service,
  ) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        service.unassignUnitEverywhere(details.data);
        setState(() {});
      },
      builder: (context, candidateData, rejectedData) {
        final isOver = candidateData.isNotEmpty;
        return Container(
          color: isOver ? const Color(0xFF2A1E16) : Colors.transparent,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: progress.playerDeckIds.length,
                  itemBuilder: (context, index) {
                    final type = progress.playerDeckIds[index];
                    final npc = CombatUnitService.createUnit(type);

                    // Check working state
                    bool isAssigned = false;
                    for (var b in progress.buildings) {
                      if (b.assignedUnitIds.contains(type)) isAssigned = true;
                    }
                    if (progress.trainingUnitIds.contains(type)) {
                      isAssigned = true;
                    }
                    for (var list in progress.towerRepairWorkers.values) {
                      if (list.contains(type)) {
                        isAssigned = true;
                      }
                    }

                    final lvl = progress.getUnitLevel(type);

                    return Draggable<String>(
                      data: type,
                      dragAnchorStrategy: (draggable, context, position) =>
                          const Offset(18, 18),
                      feedback: Material(
                        color: Colors.transparent,
                        child: Opacity(
                          opacity: 0.9,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF2E1A0A),
                              border: Border.all(
                                color: const Color(0xFFC4B89B),
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: CharacterBlobRenderer(
                                npc: npc,
                                size: 28,
                                isCombat: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                      onDragStarted: () {},
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isAssigned
                              ? const Color(0xFF19130F)
                              : const Color(0xFF2A2118),
                          border: Border.all(
                            color: const Color(
                              0xFFC4B89B,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            CharacterBlobRenderer(
                              npc: npc,
                              size: 22,
                              isCombat: true,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      final upgradedNpc = getUpgradedUnitForModal(type, progress);
                                      CombatCardDetailModal.show(context, upgradedNpc, level: lvl);
                                    },
                                    child: Text(
                                      npc.name.toUpperCase(),
                                      style: GoogleFonts.oldStandardTt(
                                        color: isAssigned
                                            ? Colors.white38
                                            : const Color(0xFFE5D5B0),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        decorationColor: isAssigned
                                            ? Colors.white38
                                            : const Color(0xFFE5D5B0),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Lvl $lvl | Food cost: ${SurvivalService.getFoodCost(npc, level: lvl)}',
                                    style: GoogleFonts.oswald(
                                      color: isAssigned
                                          ? Colors.white38
                                          : Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isAssigned)
                              const Icon(
                                Icons.work,
                                size: 10,
                                color: Colors.amber,
                              )
                            else
                              const Icon(
                                Icons.drag_indicator,
                                size: 12,
                                color: Colors.white24,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter(
    SurvivalProgress progress,
    SurvivalService service,
    GameState state,
  ) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          // Left: Mini Logs
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black38,
                border: Border.all(color: Colors.white10),
              ),
              child: ListView.builder(
                reverse: true,
                itemCount: service.logs.length,
                itemBuilder: (context, index) {
                  final idx = service.logs.length - 1 - index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      service.logs[idx],
                      style: GoogleFonts.oldStandardTt(
                        color: Colors.white54,
                        fontSize: 13.5,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Right: End Turn Button
          SizedBox(
            width: 160,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                // Check if there are damaged towers
                final damagedTowers = progress.towerDamaged.entries
                    .where((e) => e.value >= 1.0)
                    .map((e) => e.key)
                    .toList();

                bool needsEnforcement = false;
                if (damagedTowers.isNotEmpty) {
                  // Check if any damaged tower has unfilled slots (unpaid/unassigned repairs)
                  bool hasUnpaidTower = false;
                  for (final towerId in damagedTowers) {
                    final workers = progress.towerRepairWorkers[towerId] ?? [];
                    final cap = progress.getTowerRepairSlotsCap(towerId);
                    if (workers.length < cap) {
                      hasUnpaidTower = true;
                      break;
                    }
                  }

                  if (hasUnpaidTower) {
                    // Check if player has any humanoid units that are not assigned to tower repair
                    final List<String> humanoids = [];
                    for (final type in progress.playerDeckIds) {
                      final npc = CombatUnitService.createUnit(type);
                      if (SurvivalService.isHumanoid(npc)) {
                        humanoids.add(type);
                      }
                    }

                    final Set<String> assigned = {};
                    for (final list in progress.towerRepairWorkers.values) {
                      assigned.addAll(list);
                    }

                    final unassignedHumanoids = humanoids.where((h) => !assigned.contains(h)).toList();
                    if (unassignedHumanoids.isNotEmpty) {
                      needsEnforcement = true;
                    }
                  }
                }

                if (needsEnforcement) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1A130E),
                      title: Text(
                        'REPAIRS REQUIRED',
                        style: GoogleFonts.oswald(
                          color: const Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: Text(
                        'You must assign all available humanoid units to watchtower repairs, or pay for repairs using wood or cash, before proceeding to combat.',
                        style: GoogleFonts.playfairDisplay(color: Colors.white),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              service.autoAssignTowerRepairs();
                            });
                          },
                          child: Text(
                            'AUTO-ASSIGN WORKERS',
                            style: GoogleFonts.oswald(color: const Color(0xFFD4AF37)),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'CANCEL',
                            style: GoogleFonts.oswald(color: Colors.white54),
                          ),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                // Capture levels before turn resolution
                final Map<String, int> levelsBefore = {};
                for (var t in progress.playerDeckIds) {
                  levelsBefore[t] = progress.getUnitLevel(t);
                }

                // Trigger turn resolution
                service.endTurn();

                // Check for level-ups
                final List<Map<String, dynamic>> levelUps = [];
                for (var t in progress.playerDeckIds) {
                  final currentLvl = progress.getUnitLevel(t);
                  final oldLvl = levelsBefore[t] ?? 1;
                  if (currentLvl > oldLvl) {
                    levelUps.add({
                      'cardId': t,
                      'oldLvl': oldLvl,
                      'newLvl': currentLvl,
                    });
                  }
                }

                Future<void> processLevelUps() async {
                  for (final levelUp in levelUps) {
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        final screenHeight = MediaQuery.of(context).size.height;
                        return Dialog(
                          backgroundColor: Colors.transparent,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Positioned.fill(child: FireworksOverlay()),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: 320,
                                  maxHeight: screenHeight * 0.9,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A130E),
                                    border: Border.all(
                                      color: const Color(0xFFD4AF37),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black87,
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'LEVEL UP!',
                                          style: GoogleFonts.oswald(
                                            color: const Color(0xFFD4AF37),
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2.0,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        CharacterBlobRenderer(
                                          npc: CombatUnitService.createUnit(
                                            levelUp['cardId'],
                                          ),
                                          size: 60,
                                          isCombat: true,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          CombatUnitService.createUnit(
                                            levelUp['cardId'],
                                          ).name.toUpperCase(),
                                          style: GoogleFonts.playfairDisplay(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Level ${levelUp['oldLvl']} ➔ Level ${levelUp['newLvl']}',
                                          style: GoogleFonts.oswald(
                                            color: const Color(0xFFE5D5B0),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Divider(color: Colors.white10),
                                        const SizedBox(height: 6),
                                        _buildLevelUpStatRow(
                                          'MAX HEALTH (HP)',
                                          (CombatUnitService.createUnit(
                                                    levelUp['cardId'],
                                                  ).combatStats!.maxHealth *
                                                  (1.0 +
                                                      (levelUp['oldLvl'] - 1) * 0.1))
                                              .toInt()
                                              .toString(),
                                          (CombatUnitService.createUnit(
                                                    levelUp['cardId'],
                                                  ).combatStats!.maxHealth *
                                                  (1.0 +
                                                      (levelUp['newLvl'] - 1) * 0.1))
                                              .toInt()
                                              .toString(),
                                        ),
                                        const SizedBox(height: 6),
                                        _buildLevelUpStatRow(
                                          'ATTACK POWER',
                                          (CombatUnitService.createUnit(
                                                    levelUp['cardId'],
                                                  ).combatStats!.attack *
                                                  (1.0 +
                                                      (levelUp['oldLvl'] - 1) * 0.1))
                                              .toInt()
                                              .toString(),
                                          (CombatUnitService.createUnit(
                                                    levelUp['cardId'],
                                                  ).combatStats!.attack *
                                                  (1.0 +
                                                      (levelUp['newLvl'] - 1) * 0.1))
                                              .toInt()
                                              .toString(),
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 36,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFFC4B89B,
                                              ),
                                              foregroundColor: Colors.black,
                                              shape: const RoundedRectangleBorder(),
                                            ),
                                            onPressed: () => Navigator.pop(context),
                                            child: Text(
                                              'CONTINUE',
                                              style: GoogleFonts.playfairDisplay(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                }

                processLevelUps().then((_) {
                  // Route straight to Combat stage! Leveled-up stats are dynamically mapped here!
                  final playerUnits = progress.playerDeckIds.map((t) {
                    final npc = CombatUnitService.createUnit(t);
                    final lvl = progress.getUnitLevel(t);
                    final mult = 1.0 + (lvl - 1) * 0.1;
                    double distance = npc.combatStats!.distance;
                    double rangedRange = npc.combatStats!.rangedRange;
                    double baseAttack = npc.combatStats!.attack.toDouble();
                    double baseSpeed = npc.combatStats!.speed;
                    double baseMovement = npc.combatStats!.movement;
                    int baseCost = npc.combatStats!.cost;

                    bool hasRanged = npc.combatStats!.rangedDamage > 0.0;

                    if (t == 'cannoneer' && lvl >= 6) {
                      distance = 23.0;
                      rangedRange = 23.0;
                    }

                    final int rawWepIdx =
                        progress.cardUpgrades['${t}_equipped_weapon_idx'] ??
                        (t == 'samurai'
                            ? progress.cardUpgrades['samurai_equipped_weapon']
                            : 0) ??
                        0;
                    if (rawWepIdx > 0) {
                      final int cSamIdx = rawWepIdx.clamp(
                        0,
                        _samuraiUpgrades.length - 1,
                      );
                      final int cGenIdx = (rawWepIdx - 1).clamp(
                        0,
                        _generalWeaponMarket.length - 1,
                      );
                      final String wepName =
                          t == 'samurai'
                              ? _samuraiUpgrades[cSamIdx].name
                              : _generalWeaponMarket[cGenIdx].name;
                      final wepStats = _getEquippedWeaponStats(t, wepName);

                      baseAttack = wepStats.damage;
                      distance = wepStats.range;
                      rangedRange = wepStats.range;
                      hasRanged = wepStats.isRanged;
                      baseSpeed = wepStats.speed;

                      if (wepStats.tier == 2) {
                        baseCost += 1;
                        baseMovement *= 0.85;
                      } else if (wepStats.tier == 3) {
                        baseCost += 2;
                        baseMovement *= 0.75;
                      }
                    }

                    // Apply permanent Fate Dice encounter stat bonuses/penalties
                    final movementBonus =
                        (progress.cardUpgrades['${t}_stat_movement_bonus'] ??
                            0) /
                        100.0;
                    final speedBonus =
                        (progress.cardUpgrades['${t}_stat_speed_bonus'] ?? 0) /
                        100.0;
                    final meleeDamageBonus =
                        (progress.cardUpgrades['${t}_stat_meleeDamage_bonus'] ??
                                0)
                            .toDouble();
                    final rangedDamageBonus =
                        (progress.cardUpgrades['${t}_stat_rangedDamage_bonus'] ??
                                0)
                            .toDouble();
                    final maxHealthBonus =
                        (progress.cardUpgrades['${t}_stat_maxHealth_bonus'] ??
                                0)
                            .toDouble();
                    final meleeRangeBonus =
                        (progress.cardUpgrades['${t}_stat_meleeRange_bonus'] ??
                            0) /
                        100.0;
                    final rangedRangeBonus =
                        (progress.cardUpgrades['${t}_stat_rangedRange_bonus'] ??
                            0) /
                        100.0;
                    final meleeAttackSpeedBonus =
                        (progress
                                .cardUpgrades['${t}_stat_meleeAttackSpeed_bonus'] ??
                            0) /
                        100.0;
                    final rangedAttackSpeedBonus =
                        (progress
                                .cardUpgrades['${t}_stat_rangedAttackSpeed_bonus'] ??
                            0) /
                        100.0;

                    final bool isLeader = (t == progress.selectedLeaderId);
                    final bool redHandActive =
                        progress.cardUpgrades['red_hand_insignia_active'] == 1;

                    baseMovement = (baseMovement + movementBonus).clamp(
                      0.1,
                      15.0,
                    );
                    if (redHandActive && !isLeader) {
                      baseMovement *= 1.10;
                    }
                    baseSpeed = (baseSpeed + speedBonus).clamp(0.1, 10.0);

                    final bool hasRosicrucianBlessing =
                        isLeader &&
                        (progress.cardUpgrades['rosicrucian_blessing_active'] ==
                            1);
                    final bool hasRosicrucianCurse =
                        isLeader &&
                        (progress.cardUpgrades['rosicrucian_curse_active'] ==
                            1);

                    double finalMaxHealth =
                        (npc.combatStats!.maxHealth * mult + maxHealthBonus)
                            .clamp(1.0, 9999.0);
                    if (hasRosicrucianCurse) {
                      finalMaxHealth = max(1.0, finalMaxHealth - 100.0);
                    }

                    double finalHealth =
                        (npc.combatStats!.health * mult + maxHealthBonus).clamp(
                          1.0,
                          finalMaxHealth,
                        );
                    if (hasRosicrucianCurse) {
                      finalHealth = max(1.0, finalHealth - 100.0);
                    }

                    double finalAttack = (baseAttack * mult + meleeDamageBonus)
                        .clamp(1.0, 999.0);
                    double finalMeleeDamage =
                        (baseAttack * mult + meleeDamageBonus).clamp(
                          1.0,
                          999.0,
                        );
                    double finalRangedDamage = hasRanged
                        ? (baseAttack * mult + rangedDamageBonus).clamp(
                            0.0,
                            999.0,
                          )
                        : 0.0;

                    if (redHandActive && !isLeader) {
                      finalAttack = finalAttack * 1.20;
                      finalMeleeDamage = finalMeleeDamage * 1.20;
                      finalRangedDamage = finalRangedDamage * 1.20;
                    }

                    final double finalDistance = hasRanged
                        ? (distance + rangedRangeBonus).clamp(1.0, 50.0)
                        : (npc.combatStats!.distance + meleeRangeBonus).clamp(
                            1.0,
                            15.0,
                          );

                    final double finalRangedRange = hasRanged
                        ? (rangedRange + rangedRangeBonus).clamp(1.0, 50.0)
                        : 0.0;

                    final double finalMeleeAttackSpeed =
                        (npc.combatStats!.meleeAttackSpeed +
                                meleeAttackSpeedBonus)
                            .clamp(0.1, 10.0);
                    final double finalRangedAttackSpeed =
                        (npc.combatStats!.rangedAttackSpeed +
                                rangedAttackSpeedBonus)
                            .clamp(0.1, 10.0);

                    return npc.copyWith(
                      metadata: {
                        ...npc.metadata,
                        'cardType': t,
                        'level': lvl,
                        if (hasRosicrucianBlessing) 'rosicrucian_blessing_active': 1,
                      },
                      combatStats: npc.combatStats?.copyWith(
                        cost: baseCost,
                        speed: baseSpeed,
                        movement: baseMovement,
                        health: finalHealth,
                        maxHealth: finalMaxHealth,
                        attack: finalAttack,
                        meleeDamage: finalMeleeDamage,
                        rangedDamage: finalRangedDamage,
                        distance: finalDistance,
                        rangedRange: finalRangedRange,
                        meleeAttackSpeed: finalMeleeAttackSpeed,
                        rangedAttackSpeed: finalRangedAttackSpeed,
                      ),
                    );
                  }).toList();
                  final aiUnits = _generateDiverseSurvivalOpponentDeck(progress.currentTurn);

                  final baseEnemyHero = CombatUnitFactory.createAlphonse().copyWith(
                    id: 'ai_mirror',
                    name: 'Bandit Captain',
                    isPlayer: false,
                  );
                  double meanLvl = 1.0;
                  final turn = progress.currentTurn;
                  if (turn < 9) {
                    meanLvl = 2.0;
                  } else if (turn < 20) {
                    meanLvl = 3.0;
                  } else {
                    meanLvl = (3.0 + (turn - 20) * 0.15).clamp(3.0, 7.0);
                  }
                  final int enemyLvl = meanLvl.round().clamp(1, 7);
                  final double enemyUpgradeMult = 1.0 + (turn * 0.03).clamp(0.0, 0.75);
                  final enemyLvlMult = 1.0 + (enemyLvl - 1) * 0.1;

                  final enemyHero = baseEnemyHero.copyWith(
                    metadata: {
                      ...baseEnemyHero.metadata,
                      'level': enemyLvl,
                    },
                    combatStats: baseEnemyHero.combatStats?.copyWith(
                      health: baseEnemyHero.combatStats!.health * enemyLvlMult,
                      maxHealth: baseEnemyHero.combatStats!.maxHealth * enemyLvlMult,
                      attack: baseEnemyHero.combatStats!.attack * enemyLvlMult * enemyUpgradeMult,
                      meleeDamage: baseEnemyHero.combatStats!.meleeDamage * enemyLvlMult * enemyUpgradeMult,
                      rangedDamage: baseEnemyHero.combatStats!.rangedDamage * enemyLvlMult * enemyUpgradeMult,
                    ),
                  );

                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CombatScreen(
                        customPlayerHero: CombatUnitService.createUnit(progress.selectedLeaderId).copyWith(isPlayer: true),
                        customPlayerDeck: playerUnits,
                        customAiDeck: aiUnits,
                        customEnemyHero: enemyHero,
                        cardUpgrades: progress.cardUpgrades,
                        survivalTurn: progress.currentTurn,
                        survivalDifficulty: progress.difficulty,
                        onSurvivalVictory:
                            (
                              destroyedTowersCount,
                              enemyDeck,
                              spoilsFood,
                              spoilsCash,
                              spoilsIron,
                              spoilsWood,
                              playerTowerHealth,
                              combatExp,
                              activeContext,
                            ) {
                              state.recordCombatVictory();
                              final levelUps = service.processCombatOutcome(
                                true,
                                false,
                                playerTowerHealth,
                                combatExp,
                                opponentDeck: enemyDeck,
                                destroyedEnemyTowers: destroyedTowersCount,
                                customSpoilsFood: spoilsFood,
                                customSpoilsCash: spoilsCash,
                                customSpoilsIron: spoilsIron,
                                customSpoilsWood: spoilsWood,
                              );
                              state.clearEncounterState();
                              Navigator.pop(activeContext);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (levelUps.isNotEmpty) {
                                  _showPendingLevelUps(levelUps.entries.toList(), onComplete: _triggerDiceRollSequence);
                                } else {
                                  _triggerDiceRollSequence();
                                }
                              });
                            },
                        onSurvivalDefeat:
                            (
                              destroyedTowersCount,
                              enemyDeck,
                              playerTowerHealth,
                              combatExp,
                              activeContext,
                            ) {
                              final levelUps = service.processCombatOutcome(
                                false,
                                false,
                                playerTowerHealth,
                                combatExp,
                                opponentDeck: enemyDeck,
                                destroyedEnemyTowers: destroyedTowersCount,
                                customSpoilsFood: 0,
                                customSpoilsCash: 0,
                                customSpoilsIron: 0,
                                customSpoilsWood: 0,
                              );
                              state.clearEncounterState();
                              if (progress.difficulty ==
                                  SurvivalDifficulty.arcade) {
                                ArenaSaveService.deleteSave(service.activeSlot);
                                Navigator.pushReplacement(
                                  activeContext,
                                  MaterialPageRoute(
                                    builder: (context) => GameOverScreen(
                                      reason:
                                          'Your forces were defeated in combat.',
                                      difficulty: progress.difficulty,
                                      turnsSurvived: progress.currentTurn,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.pop(activeContext);
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (levelUps.isNotEmpty) {
                                    _showPendingLevelUps(levelUps.entries.toList(), onComplete: _triggerDiceRollSequence);
                                  } else {
                                    _triggerDiceRollSequence();
                                  }
                                });
                              }
                            },
                        onSurvivalDraw:
                            (
                              destroyedTowersCount,
                              enemyDeck,
                              playerTowerHealth,
                              combatExp,
                              activeContext,
                            ) {
                              final levelUps = service.processCombatOutcome(
                                false,
                                true,
                                playerTowerHealth,
                                combatExp,
                                opponentDeck: enemyDeck,
                                destroyedEnemyTowers: destroyedTowersCount,
                                customSpoilsFood: 0,
                                customSpoilsCash: 0,
                                customSpoilsIron: 0,
                                customSpoilsWood: 0,
                              );
                              state.clearEncounterState();
                              Navigator.pop(activeContext);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (levelUps.isNotEmpty) {
                                  _showPendingLevelUps(levelUps.entries.toList(), onComplete: _triggerDiceRollSequence);
                                } else {
                                  _triggerDiceRollSequence();
                                }
                              });
                            },
                      ),
                    ),
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC4B89B),
                foregroundColor: Colors.black,
                shape: const RoundedRectangleBorder(),
              ),
              child: Text(
                "END TURN & FIGHT",
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.bold,
                  fontSize: 10.5,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // EMBARK SHOP DRAFT OVERLAY
  Widget _buildDraftOverlay(
    SurvivalProgress progress,
    SurvivalService service,
  ) {
    int totalCost = 0;
    for (var type in _selectedCart) {
      final match = _draftPool.firstWhere((x) => x['type'] == type);
      totalCost += match['cost'] as int;
    }
    final budgetRemaining = 1000 - totalCost;

    final size = MediaQuery.of(context).size;
    // Calculate cellWidth based on screen width to fit 6 columns with 12px spacing and horizontal margins
    // We reserve 64px for horizontal padding (32px on each side)
    final double horizontalPadding = 64.0;
    // Cap the cellWidth to 115.0 so that cards don't become too massive on wide screens
    final double maxCellWidth = 115.0;
    final double cellWidth = min(maxCellWidth, (size.width - horizontalPadding - 60.0) / 6);
    // Ordinary playing card aspect ratio is 0.7
    final double cardAspectRatio = 0.7;
    final double cardHeight = cellWidth / cardAspectRatio;
    // cellHeight accounts for cardHeight + spacer (6px) + recruit footer (24px)
    final double cellHeight = cardHeight + 30.0;
    // 6 columns with 12px spacing between them
    final double draftGridWidth = cellWidth * 6 + 5 * 12.0;
    final double aspectRatio = cellWidth / cellHeight;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.9),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RECRUIT YOUR SURVIVAL SQUAD',
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFFE5D5B0),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Spend your 1000 CHF budget wisely. Clicking a card opens its details.',
                      style: GoogleFonts.oldStandardTt(
                        color: const Color(0xFFE5D5B0),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'BUDGET: $budgetRemaining / 1000 CHF',
                        style: GoogleFonts.oswald(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'SQUAD: ${_selectedCart.length}/12',
                        style: GoogleFonts.oswald(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Card flip toggle icon button
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          _showDraftCardDetails
                              ? Icons.portrait
                              : Icons.menu_book,
                          color: const Color(0xFFD4AF37),
                          size: 22,
                        ),
                        tooltip: _showDraftCardDetails
                            ? 'Show Portraits'
                            : 'Show Tactical Specs',
                        onPressed: () => setState(
                          () => _showDraftCardDetails = !_showDraftCardDetails,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF3A2F25)),
            const SizedBox(height: 8),

            Expanded(
              child: Center(
                child: SizedBox(
                  width: draftGridWidth,
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: aspectRatio,
                    ),
                    itemCount: _draftPool.length,
                    itemBuilder: (context, index) {
                      final item = _draftPool[index];
                      final type = item['type'] as String;
                      final cost = item['cost'] as int;

                      final unit = CombatUnitService.createUnit(type);
                      final stats = unit.combatStats!;
                      final isSelected = _selectedCart.contains(type);

                      return Column(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedInspectorCardId = type;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF211B15),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.greenAccent
                                        : const Color(
                                            0xFFC4B89B,
                                          ).withValues(alpha: 0.4),
                                    width: isSelected ? 2.5 : 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.greenAccent
                                                .withValues(alpha: 0.4),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: _showDraftCardDetails
                                    ? _buildTacticalCardFace(
                                        type,
                                        unit,
                                        stats,
                                        1,
                                        0.0,
                                      )
                                    : _buildPortraitCardFace(
                                        type,
                                        unit,
                                        1,
                                        0.0,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Recruit footer below card
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$cost CHF',
                                  style: GoogleFonts.oswald(
                                    color: Colors.amber,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(
                                  height: 20,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      backgroundColor: isSelected
                                          ? Colors.red.shade900
                                          : Colors.green.shade900,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedCart.remove(type);
                                        } else {
                                          if (totalCost + cost <= 1000 &&
                                              _selectedCart.length < 12) {
                                            _selectedCart.add(type);
                                          } else if (_selectedCart.length >=
                                              12) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Squad limit is 12 units!',
                                                ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Insufficient CHF budget!',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      });
                                    },
                                    child: Text(
                                      isSelected ? 'REMOVE' : 'ADD',
                                      style: GoogleFonts.playfairDisplay(
                                        color: Colors.white,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            const Divider(color: Color(0xFF3A2F25)),
            const SizedBox(height: 6),

            // Cart tally & proceed button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CART TALLY: $totalCost / 1000 CHF spent (${_selectedCart.length} units)',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedCart.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Draft at least 1 squad unit to embark!',
                          ),
                        ),
                      );
                      return;
                    }
                    service.commitDraftSquad(_selectedCart, totalCost);
                    setState(() {
                      _isDrafting = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC4B89B),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: Text(
                    "PROCEED TO EMBARK",
                    style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // POP-UPS & CONTEXT MENUS
  void _showTowerDetailsDialog(
    BuildContext context,
    SurvivalProgress progress,
    SurvivalService service,
    String towerId,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentProgress = service.progress!;

            // Global Covenant Upgrade levels
            final globalHpLvl = currentProgress.cardUpgrades['tower_hp'] ?? 0;
            final globalAtkLvl = currentProgress.cardUpgrades['tower_atk'] ?? 0;
            final globalRangeLvl =
                currentProgress.cardUpgrades['tower_range'] ?? 0;
            final globalSpeedLvl =
                currentProgress.cardUpgrades['tower_speed'] ?? 0;

            // Individual Spire Upgrade levels
            final indHpLvl = currentProgress.cardUpgrades['${towerId}_hp'] ?? 0;
            final indAtkLvl =
                currentProgress.cardUpgrades['${towerId}_atk'] ?? 0;
            final indRangeLvl =
                currentProgress.cardUpgrades['${towerId}_range'] ?? 0;
            final indSpeedLvl =
                currentProgress.cardUpgrades['${towerId}_speed'] ?? 0;

            // Combined Stats
            final currentHealth = 200 + (globalHpLvl * 50) + (indHpLvl * 25);
            final currentDamage = 30 + (globalAtkLvl * 10) + (indAtkLvl * 5);
            final currentRange =
                20.0 + (globalRangeLvl * 2.5) + (indRangeLvl * 1.5);
            final currentRateOfFire =
                (2.0 - (globalSpeedLvl * 0.2) - (indSpeedLvl * 0.1)).clamp(
                  0.4,
                  2.0,
                );

            final isDestroyed =
                (currentProgress.towerDamaged[towerId] ?? 0.0) >= 1.0;
            final friendlyName = towerId == 'tower_1'
                ? 'WEST WATCHTOWER'
                : towerId == 'tower_2'
                ? 'MIDDLE WATCHTOWER'
                : 'EAST WATCHTOWER';

            const woodRepairCost = 50;
            const cashRepairCost = 180;

            return AlertDialog(
              backgroundColor: const Color(0xFF1E1712),
              contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: isDestroyed
                      ? Colors.redAccent
                      : const Color(0xFFC4B89B),
                  width: 2,
                ),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    friendlyName,
                    style: GoogleFonts.playfairDisplay(
                      color: isDestroyed
                          ? Colors.redAccent
                          : const Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDestroyed
                          ? Colors.red.withValues(alpha: 0.2)
                          : Colors.green.withValues(alpha: 0.2),
                      border: Border.all(
                        color: isDestroyed ? Colors.redAccent : Colors.green,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isDestroyed ? 'DESTROYED' : 'OPERATIONAL',
                      style: GoogleFonts.oswald(
                        color: isDestroyed ? Colors.redAccent : Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Watchtowers protect the estate during defense rounds. Upgrade this individual tower spire cheaply below, or perform global upgrades via the Covenant tab in the estate menu.',
                        style: GoogleFonts.oldStandardTt(
                          color: Colors.white70,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'COMBINED STATS',
                                  style: GoogleFonts.playfairDisplay(
                                    color: const Color(0xFFC4B89B),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildStatsPanel(
                                  'Structural Integrity',
                                  '$currentHealth HP',
                                  'Cov Lvl ${globalHpLvl + 1} | Ind Lvl ${indHpLvl + 1}',
                                  Icons.favorite,
                                  Colors.redAccent,
                                ),
                                _buildStatsPanel(
                                  'Attack Power',
                                  '$currentDamage DMG',
                                  'Cov Lvl ${globalAtkLvl + 1} | Ind Lvl ${indAtkLvl + 1}',
                                  Icons.local_fire_department,
                                  Colors.orangeAccent,
                                ),
                                _buildStatsPanel(
                                  'Ballistic Range',
                                  '${currentRange.toStringAsFixed(1)} ft',
                                  'Cov Lvl ${globalRangeLvl + 1} | Ind Lvl ${indRangeLvl + 1}',
                                  Icons.gps_fixed,
                                  Colors.blueAccent,
                                ),
                                _buildStatsPanel(
                                  'Rate of Fire',
                                  '${currentRateOfFire.toStringAsFixed(1)}s',
                                  'Cov Lvl ${globalSpeedLvl + 1} | Ind Lvl ${indSpeedLvl + 1}',
                                  Icons.speed,
                                  Colors.greenAccent,
                                ),
                                if (isDestroyed) ...[
                                  const SizedBox(height: 8),
                                  const Divider(color: Colors.white10),
                                  const SizedBox(height: 4),
                                  Text(
                                    'RECONSTRUCT TOWER',
                                    style: GoogleFonts.playfairDisplay(
                                      color: Colors.redAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildRepairOptionButton(
                                    context: context,
                                    service: service,
                                    towerId: towerId,
                                    label: 'WOOD (50 Wood)',
                                    method: 'wood',
                                    woodCost: woodRepairCost,
                                    cashCost: 0,
                                    color: Colors.brown,
                                    enabled:
                                        currentProgress.wood >= woodRepairCost,
                                    onSuccess: () => setDialogState(() {}),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildRepairOptionButton(
                                    context: context,
                                    service: service,
                                    towerId: towerId,
                                    label: 'CONTRACT (180 CHF)',
                                    method: 'cash',
                                    woodCost: 0,
                                    cashCost: cashRepairCost,
                                    color: Colors.amber,
                                    enabled:
                                        currentProgress.cash >= cashRepairCost,
                                    onSuccess: () => setDialogState(() {}),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildRepairOptionButton(
                                    context: context,
                                    service: service,
                                    towerId: towerId,
                                    label:
                                        'MANUAL LABOR (${currentProgress.getTowerRepairSlotsCap(towerId)} Workers)',
                                    method: 'labor',
                                    woodCost: 0,
                                    cashCost: 0,
                                    color: Colors.blue,
                                    enabled: true,
                                    onSuccess: () => setDialogState(() {}),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SPIRE UPGRADES (INDIVIDUAL)',
                                  style: GoogleFonts.playfairDisplay(
                                    color: const Color(0xFFD4AF37),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildIndividualUpgradeActionRow(
                                  label: 'Spire HP',
                                  stat: 'hp',
                                  currentLvl: indHpLvl,
                                  maxLvl: 5,
                                  cost: 200 + indHpLvl * 100,
                                  towerId: towerId,
                                  progress: currentProgress,
                                  service: service,
                                  onSuccess: () => setDialogState(() {}),
                                ),
                                const SizedBox(height: 8),
                                _buildIndividualUpgradeActionRow(
                                  label: 'Spire Damage',
                                  stat: 'atk',
                                  currentLvl: indAtkLvl,
                                  maxLvl: 5,
                                  cost: 200 + indAtkLvl * 100,
                                  towerId: towerId,
                                  progress: currentProgress,
                                  service: service,
                                  onSuccess: () => setDialogState(() {}),
                                ),
                                const SizedBox(height: 8),
                                _buildIndividualUpgradeActionRow(
                                  label: 'Spire Range',
                                  stat: 'range',
                                  currentLvl: indRangeLvl,
                                  maxLvl: 5,
                                  cost: 250 + indRangeLvl * 125,
                                  towerId: towerId,
                                  progress: currentProgress,
                                  service: service,
                                  onSuccess: () => setDialogState(() {}),
                                ),
                                const SizedBox(height: 8),
                                _buildIndividualUpgradeActionRow(
                                  label: 'Spire Speed',
                                  stat: 'speed',
                                  currentLvl: indSpeedLvl,
                                  maxLvl: 5,
                                  cost: 300 + indSpeedLvl * 150,
                                  towerId: towerId,
                                  progress: currentProgress,
                                  service: service,
                                  onSuccess: () => setDialogState(() {}),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: Text(
                    'CLOSE',
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFC4B89B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildIndividualUpgradeActionRow({
    required String label,
    required String stat,
    required int currentLvl,
    required int maxLvl,
    required int cost,
    required String towerId,
    required SurvivalProgress progress,
    required SurvivalService service,
    required VoidCallback onSuccess,
  }) {
    final completed = currentLvl >= maxLvl;
    final canAfford = progress.cash >= cost;
    final enabled = canAfford && !completed;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        border: Border.all(
          color: completed
              ? Colors.green.withValues(alpha: 0.3)
              : const Color(0xFFC4B89B).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                completed ? 'MAX' : 'Lvl ${currentLvl + 1}',
                style: GoogleFonts.oswald(
                  color: completed ? Colors.green : const Color(0xFFC4B89B),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (!completed)
            SizedBox(
              width: double.infinity,
              height: 28,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: enabled
                      ? const Color(0xFF2E1A0A)
                      : Colors.transparent,
                  side: BorderSide(
                    color: enabled ? const Color(0xFFD4AF37) : Colors.white10,
                  ),
                  shape: const RoundedRectangleBorder(),
                  padding: EdgeInsets.zero,
                ),
                onPressed: enabled
                    ? () {
                        if (service.upgradeIndividualTower(
                          towerId,
                          stat,
                          cost,
                        )) {
                          onSuccess();
                        }
                      }
                    : null,
                child: Text(
                  'UPGRADE FOR $cost CHF',
                  style: GoogleFonts.oswald(
                    color: enabled ? const Color(0xFFE5D5B0) : Colors.white24,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsPanel(
    String label,
    String value,
    String lvl,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white70,
                    fontSize: 10.5,
                  ),
                ),
                Text(
                  lvl,
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white38,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.oswald(
              color: const Color(0xFFE5D5B0),
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairOptionButton({
    required BuildContext context,
    required SurvivalService service,
    required String towerId,
    required String label,
    required String method,
    required int woodCost,
    required int cashCost,
    required Color color,
    required bool enabled,
    required VoidCallback onSuccess,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 32,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled
              ? const Color(0xFF2E1A0A)
              : Colors.transparent,
          side: BorderSide(
            color: enabled ? color.withValues(alpha: 0.5) : Colors.white10,
          ),
          shape: const RoundedRectangleBorder(),
          padding: EdgeInsets.zero,
        ),
        onPressed: enabled
            ? () {
                if (service.repairTower(towerId, method, woodCost, cashCost)) {
                  onSuccess();
                }
              }
            : null,
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.oswald(
            color: enabled ? Colors.white : Colors.white24,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  bool _isAdvancedPlot(String plotKey) {
    return plotKey == 'plot_a' || plotKey == 'plot_b';
  }

  void _showBuildMenu(
    BuildContext context,
    SurvivalService service,
    String plotKey,
  ) {
    final progress = service.progress!;
    if (progress.cardUpgrades['${plotKey}_permanently_locked'] == 1) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1F1109),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.redAccent, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          title: Text(
            'PLOT PERMANENTLY LOCKED',
            style: GoogleFonts.playfairDisplay(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          content: Text(
            'This plot of land has been permanently confiscated or destroyed as a consequence of your hostile standing with the factions of the valley. It cannot be used for construction.',
            style: GoogleFonts.oldStandardTt(color: const Color(0xFFE5D5B0), fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'UNDERSTOOD',
                style: GoogleFonts.oswald(color: const Color(0xFFE5D5B0)),
              ),
            ),
          ],
        ),
      );
      return;
    }

    if (plotKey == 'plot_c') {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return SimpleDialog(
            backgroundColor: const Color(0xFF2E1A0A),
            title: Text(
              'CONSTRUCT FARM FACILITY',
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFE5D5B0),
              ),
            ),
            children: [
              _buildBuildOption(
                dialogContext,
                service,
                plotKey,
                SurvivalBuildingType.farm,
                40,
                0,
                100,
              ),
            ],
          );
        },
      );
      return;
    }

    final isAdvanced = _isAdvancedPlot(plotKey);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          backgroundColor: const Color(0xFF2E1A0A),
          title: Text(
            isAdvanced
                ? 'CONSTRUCT INDUSTRY FACILITY'
                : 'CONSTRUCT RESOURCE FACILITY',
            style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0)),
          ),
          children: isAdvanced
              ? [
                  _buildBuildOption(
                    dialogContext,
                    service,
                    plotKey,
                    SurvivalBuildingType.arsenal,
                    100,
                    30,
                    300,
                  ),
                  _buildBuildOption(
                    dialogContext,
                    service,
                    plotKey,
                    SurvivalBuildingType.garage,
                    120,
                    40,
                    400,
                  ),
                  _buildBuildOption(
                    dialogContext,
                    service,
                    plotKey,
                    SurvivalBuildingType.munitionsFactory,
                    150,
                    50,
                    500,
                  ),
                ]
              : [
                  _buildBuildOption(
                    dialogContext,
                    service,
                    plotKey,
                    SurvivalBuildingType.farm,
                    40,
                    0,
                    100,
                  ),
                  _buildBuildOption(
                    dialogContext,
                    service,
                    plotKey,
                    SurvivalBuildingType.lumberMill,
                    60,
                    5,
                    150,
                  ),
                  _buildBuildOption(
                    dialogContext,
                    service,
                    plotKey,
                    SurvivalBuildingType.mine,
                    80,
                    15,
                    200,
                  ),
                ],
        );
      },
    );
  }

  Widget _buildBuildOption(
    BuildContext dialogContext,
    SurvivalService service,
    String plotKey,
    SurvivalBuildingType type,
    int wood,
    int iron,
    int cash,
  ) {
    return SimpleDialogOption(
      onPressed: () {
        if (service.buildFacility(plotKey, type, wood, iron, cash)) {
          Navigator.pop(dialogContext);
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            type.name.replaceAll("_", " ").toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          Text(
            '$wood W | $iron I | $cash CHF',
            style: const TextStyle(color: Colors.amber, fontSize: 9),
          ),
        ],
      ),
    );
  }

  void _showFacilityDetailsDialog(
    BuildContext context,
    SurvivalService service,
    SurvivalBuilding b,
  ) {
    if (b.type == SurvivalBuildingType.garage) {
      showSubmarineDockDialog(context, survivalService: service);
      return;
    }
    final level = b.level;
    final maxLvl =
        (b.type == SurvivalBuildingType.arsenal ||
            b.type == SurvivalBuildingType.garage ||
            b.type == SurvivalBuildingType.munitionsFactory)
        ? 3
        : 7;
    final isMax = level >= maxLvl;

    final costWood = 30 * level;
    final costIron = 10 * level;
    final costCash = 100 * level;

    final String resName;
    final int currentOutput;
    final int? nextOutput;

    final workers = b.assignedUnitIds.length;

    switch (b.type) {
      case SurvivalBuildingType.farm:
        resName = 'Food';
        currentOutput = service.getFarmOutput(level, workers);
        nextOutput = isMax ? null : service.getFarmOutput(level + 1, workers);
        break;
      case SurvivalBuildingType.lumberMill:
        resName = 'Wood';
        currentOutput = service.getLumberMillOutput(level, workers);
        nextOutput = isMax
            ? null
            : service.getLumberMillOutput(level + 1, workers);
        break;
      case SurvivalBuildingType.mine:
        resName = 'Iron';
        currentOutput = service.getMineOutput(level, workers);
        nextOutput = isMax ? null : service.getMineOutput(level + 1, workers);
        break;
      case SurvivalBuildingType.arsenal:
      case SurvivalBuildingType.garage:
      case SurvivalBuildingType.munitionsFactory:
        resName = 'CHF';
        currentOutput = service.getAdvancedOutput(level, workers);
        nextOutput = isMax
            ? null
            : service.getAdvancedOutput(level + 1, workers);
        break;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1712),
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: const Color(0xFFC4B89B).withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          title: Text(
            '${b.type.name.replaceAll("lumberMill", "Mill").replaceAll("arsenal", "Arsenal").toUpperCase()} DETAILS (LEVEL $level)',
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFE5D5B0),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: 290,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInspectorStatRow('Current Level', 'Lvl $level / $maxLvl'),
                _buildInspectorStatRow(
                  'Assigned Workers',
                  '$workers / ${b.getWorkerCap()}',
                ),
                _buildInspectorStatRow(
                  'Present Output',
                  '$currentOutput $resName / turn',
                ),
                if (!isMax)
                  _buildInspectorStatRow(
                    'Output at Next Level',
                    '${nextOutput!} $resName / turn',
                  ),
                const SizedBox(height: 6),
                const Divider(color: Colors.white10),
                const SizedBox(height: 4),
                Text(
                  isMax
                      ? 'Maximum facility level achieved.'
                      : 'Upgrade requires:\n• $costWood Wood\n• $costIron Iron\n• $costCash CHF',
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF3E1A1A),
                    title: Text(
                      'DEMOLISH FACILITY?',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.redAccent,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to demolish this facility? This will clear all workers and reduce the plot to a Fallow lot.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (service.demolishBuilding(b.id)) {
                            Navigator.pop(ctx); // pop confirm
                            Navigator.pop(context); // pop details
                            setState(() {});
                          }
                        },
                        child: const Text(
                          'DEMOLISH',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Text(
                'DEMOLISH',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CLOSE',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!isMax)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      (service.progress!.wood >= costWood &&
                          service.progress!.iron >= costIron &&
                          service.progress!.cash >= costCash)
                      ? const Color(0xFF2E1A0A)
                      : Colors.transparent,
                  side: BorderSide(
                    color:
                        (service.progress!.wood >= costWood &&
                            service.progress!.iron >= costIron &&
                            service.progress!.cash >= costCash)
                        ? const Color(0xFFC4B89B)
                        : Colors.white10,
                  ),
                  shape: const RoundedRectangleBorder(),
                ),
                onPressed:
                    (service.progress!.wood >= costWood &&
                        service.progress!.iron >= costIron &&
                        service.progress!.cash >= costCash)
                    ? () {
                        if (service.upgradeBuilding(
                          b.id,
                          costWood,
                          costIron,
                          costCash,
                        )) {
                          Navigator.pop(context);
                          setState(() {});
                        }
                      }
                    : null,
                child: Text(
                  'PAY TO UPGRADE',
                  style: GoogleFonts.playfairDisplay(
                    color:
                        (service.progress!.wood >= costWood &&
                            service.progress!.iron >= costIron &&
                            service.progress!.cash >= costCash)
                        ? const Color(0xFFE5D5B0)
                        : Colors.white24,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showPurchasePlotConfirmation(
    BuildContext context,
    SurvivalService service,
    String plotKey,
    int costGhc,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E1A0A),
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          title: Text(
            'ACQUIRE ESTATE LAND',
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFE5D5B0),
              fontSize: 15,
            ),
          ),
          content: Text(
            'Would you like to clear and unlock this plot slot for $costGhc CHF?',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                if (service.unlockPlot(plotKey, costGhc)) {
                  Navigator.pop(context);
                }
              },
              child: const Text('ACQUIRE LAND'),
            ),
          ],
        );
      },
    );
  }

  void _showMenuOverlay(
    SurvivalProgress progress,
    SurvivalService service,
    GameState state,
  ) {
    final isElementary = progress.difficulty == SurvivalDifficulty.elementary;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1D1712),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: const Color(0xFFC4B89B).withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              title: Text(
                'COMMAND MENU',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: SizedBox(
                width: 340,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMenuOptionBtn('HELP', () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen()));
                      }),
                      const SizedBox(height: 8),
                      _buildMenuOptionBtn('GAME OPTIONS', () {
                        showDialog(context: context, builder: (context) => const OptionsDialog(isSurvivalMode: true));
                      }),
                      const SizedBox(height: 8),
                      if (isElementary) ...[
                        // Auto-Save Toggle
                        _buildMenuOptionBtn(
                          'AUTO-SAVE: ${progress.autoSaveEnabled ? "ON" : "OFF"}',
                          () {
                            service.toggleAutoSave();
                            setModalState(() {});
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'MANUAL SAVE SLOTS',
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFFC4B89B),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [1, 2, 3].map((slot) {
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2.0,
                                ),
                                child: _buildMenuOptionBtn('SAVE $slot', () {
                                  service.manualSaveToSlot(slot);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'State saved to Slot #$slot!',
                                      ),
                                    ),
                                  );
                                  Navigator.pop(context);
                                }),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'MANUAL LOAD SLOTS',
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFFC4B89B),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [1, 2, 3].map((slot) {
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2.0,
                                ),
                                child: _buildMenuOptionBtn(
                                  'LOAD $slot',
                                  () async {
                                    await service.manualLoadFromSlot(slot);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Loaded state from Slot #$slot!',
                                        ),
                                      ),
                                    );
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFF352B24)),
                      const SizedBox(height: 8),
                      _buildMenuOptionBtn('QUIT TO ARENA HUB', () {
                        Navigator.pop(context); // Close Menu
                        Navigator.pop(context); // Quit Survival
                      }, isDanger: true),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMenuOptionBtn(
    String label,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 28,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDanger
                ? Colors.red.shade800
                : const Color(0xFFC4B89B).withValues(alpha: 0.4),
          ),
          backgroundColor: Colors.black26,
          shape: const RoundedRectangleBorder(),
        ),
        child: Text(
          label,
          style: GoogleFonts.playfairDisplay(
            color: isDanger ? Colors.redAccent : const Color(0xFFE5D5B0),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- FULL-SCREEN TAB 1: MANOR RECORDS & CHRONICLES ---
  Widget _buildFullManorRecordsView(
    SurvivalProgress progress,
    SurvivalService service,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF18120D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'MANOR COMMAND RECORDS & REGISTRY',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column: Chronicles, Covenants, Troop Status (Vertically Scrollable)
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chronicles of Completed Actions
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF15100B),
                            border: Border.all(
                              color: const Color(
                                0xFFC4B89B,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CHRONICLES OF COMPLETED ACTIONS',
                                style: GoogleFonts.playfairDisplay(
                                  color: const Color(0xFFD4AF37),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Divider(color: Colors.white10),
                              const SizedBox(height: 3),
                              service.logs.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'The chronicle is empty. Actions are recorded here as turns progress.',
                                          style: GoogleFonts.oldStandardTt(
                                            color: Colors.white24,
                                            fontStyle: FontStyle.italic,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: service.logs.reversed.map((
                                        log,
                                      ) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 2,
                                          ),
                                          child: Text(
                                            '• $log',
                                            style: GoogleFonts.oldStandardTt(
                                              color: const Color(
                                                0xFFE5D5B0,
                                              ).withValues(alpha: 0.8),
                                              fontSize: 10,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Covenants & Treaties
                        Container(
                          padding: const EdgeInsets.all(6),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF15100B),
                            border: Border.all(
                              color: const Color(
                                0xFFC4B89B,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'COVENANTS & TREATIES',
                                style: GoogleFonts.playfairDisplay(
                                  color: const Color(0xFFD4AF37),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Divider(color: Colors.white10),
                              const SizedBox(height: 3),
                              progress.currentTurn < 4
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'The registry of treaties remains vacant. No formal covenants or agreements ratified.',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.playfairDisplay(
                                            color: const Color(
                                              0xFFE5D5B0,
                                            ).withValues(alpha: 0.4),
                                            fontSize: 9,
                                            fontStyle: FontStyle.italic,
                                            height: 1.15,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildCovenantItem(
                                          'RAT ERADICATION COVENANT',
                                          'Exterminate undead vermin threat in eastern cellar. Status: Active.',
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Troop Registry Status
                        Container(
                          padding: const EdgeInsets.all(6),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF15100B),
                            border: Border.all(
                              color: const Color(
                                0xFFC4B89B,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TROOP REGISTRY STATUS',
                                style: GoogleFonts.playfairDisplay(
                                  color: const Color(0xFFD4AF37),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Divider(color: Colors.white10),
                              const SizedBox(height: 3),
                              _buildTroopRegistryStatusList(progress),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Right column: Current Labor & Training, Secret Society Standings (Vertically Scrollable)
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current Labor & Training Assignments
                        Container(
                          padding: const EdgeInsets.all(6),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF15100B),
                            border: Border.all(
                              color: const Color(
                                0xFFC4B89B,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CURRENT LABOR & TRAINING ASSIGNMENTS',
                                style: GoogleFonts.playfairDisplay(
                                  color: const Color(0xFFD4AF37),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Divider(color: Colors.white10),
                              const SizedBox(height: 3),
                              _buildManorAssignmentsList(progress, service),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Secret Society Standings
                        Container(
                          padding: const EdgeInsets.all(6),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF15100B),
                            border: Border.all(
                              color: const Color(
                                0xFFC4B89B,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SECRET SOCIETY STANDINGS',
                                style: GoogleFonts.playfairDisplay(
                                  color: const Color(0xFFD4AF37),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Divider(color: Colors.white10),
                              const SizedBox(height: 4),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: progress.factionStandings.entries.map(
                                  (entry) {
                                    final factionName = entry.key == 'Army'
                                        ? 'Your Army'
                                        : entry.key;
                                    final rating = entry.value;
                                    Color ratingColor = Colors.white70;
                                    if (rating > 0)
                                      ratingColor = Colors.greenAccent;
                                    if (rating < 0)
                                      ratingColor = Colors.redAccent;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 3.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            factionName,
                                            style: GoogleFonts.playfairDisplay(
                                              color: const Color(0xFFE5D5B0),
                                              fontSize: 10.5,
                                            ),
                                          ),
                                          Text(
                                            rating >= 0
                                                ? '+$rating'
                                                : '$rating',
                                            style: GoogleFonts.oswald(
                                              color: ratingColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroopRegistryStatusList(SurvivalProgress progress) {
    final List<Widget> items = [];
    final allCardTypes = <String>{
      ...progress.starvationInfractions.keys,
      ...progress.bondageDebuffCount.keys,
    };

    for (final cardType in allCardTypes) {
      final starvation = progress.starvationInfractions[cardType] ?? 0;
      final bondage = progress.bondageDebuffCount[cardType] ?? 0;
      if (starvation > 0 || bondage > 0) {
        String name = cardType;
        try {
          name = CombatUnitService.createUnit(cardType).name;
        } catch (_) {
          name = cardType.replaceAll('_', ' ').toUpperCase();
        }
        final List<String> statusStrings = [];
        if (starvation > 0) {
          statusStrings.add('Starving ($starvation turns)');
        }
        if (bondage > 0) {
          statusStrings.add('Debuffs: $bondage');
        }
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name.toUpperCase(),
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 9.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  statusStrings.join(', '),
                  style: GoogleFonts.oldStandardTt(
                    color: starvation >= 2
                        ? Colors.redAccent
                        : Colors.orangeAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'All troops in prime condition. No starvation or physical bondage recorded.',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFE5D5B0).withValues(alpha: 0.4),
              fontSize: 9,
              fontStyle: FontStyle.italic,
              height: 1.15,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  Widget _buildCovenantItem(String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF211B15),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFD4AF37),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: GoogleFonts.oldStandardTt(
              color: const Color(0xFFE5D5B0),
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManorAssignmentsList(
    SurvivalProgress progress,
    SurvivalService service,
  ) {
    final List<Widget> children = [];

    for (final b in progress.buildings) {
      final assigned = b.assignedUnitIds;
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${b.type.name.replaceAll("_", " ").toUpperCase()} (Lvl ${b.level})',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                assigned.isEmpty
                    ? 'NO WORKERS'
                    : assigned
                          .map((id) {
                            final npc = CombatUnitService.createUnit(id);
                            return npc.name;
                          })
                          .join(', '),
                style: GoogleFonts.oldStandardTt(
                  color: assigned.isEmpty
                      ? Colors.white24
                      : const Color(0xFFD4AF37),
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final training = progress.trainingUnitIds;
    children.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TRAINING GROUNDS',
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFE5D5B0),
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              training.isEmpty
                  ? 'NO TRAINEES'
                  : training
                        .map((id) {
                          final npc = CombatUnitService.createUnit(id);
                          return npc.name;
                        })
                        .join(', '),
              style: GoogleFonts.oldStandardTt(
                color: training.isEmpty
                    ? Colors.white24
                    : const Color(0xFFD4AF37),
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    // Tower repairs
    for (final towerId in progress.towerRepairWorkers.keys) {
      final list = progress.towerRepairWorkers[towerId] ?? [];
      if (list.isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${towerId.replaceAll("_", " ").toUpperCase()} REPAIR',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  list
                      .map((id) => CombatUnitService.createUnit(id).name)
                      .join(', '),
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFD4AF37),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    final deck = progress.playerDeckIds;
    final List<String> idle = [];
    for (final id in deck) {
      bool isAssigned = false;
      for (final b in progress.buildings) {
        if (b.assignedUnitIds.contains(id)) isAssigned = true;
      }
      if (progress.trainingUnitIds.contains(id)) isAssigned = true;
      for (final list in progress.towerRepairWorkers.values) {
        if (list.contains(id)) isAssigned = true;
      }
      if (!isAssigned) idle.add(id);
    }

    children.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'IDLE COVENANT FORCES',
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFE5D5B0),
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              idle.isEmpty
                  ? 'ALL FORCES DEPLOYED'
                  : idle
                        .map((id) {
                          final npc = CombatUnitService.createUnit(id);
                          return npc.name;
                        })
                        .join(', '),
              style: GoogleFonts.oldStandardTt(
                color: idle.isEmpty ? Colors.white24 : Colors.white54,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  // --- FULL-SCREEN TAB 2: DECK VIEW OVERHAUL ---
  Widget _buildFullDeckView(
    SurvivalProgress progress,
    SurvivalService service,
    GameState state,
  ) {
    final deck = progress.playerDeckIds;
    double avgCost = 0.0;
    if (deck.isNotEmpty) {
      int totalCost = 0;
      for (final id in deck) {
        final npc = CombatUnitService.createUnit(id);
        totalCost += npc.combatStats?.cost ?? 0;
      }
      avgCost = totalCost / deck.length;
    }

    final size = MediaQuery.of(context).size;

    // The grid of 12 cards should take up about 78% of the screen height (making cards slightly larger)
    final double totalGridHeight = size.height * 0.78;
    // The grid has 2 rows, so calculate cellHeight dynamically
    final double cellHeight = (totalGridHeight - 12.0) / 2.0;
    // Card height is cellHeight minus the 20px XP bar at the bottom
    final double cardHeight = cellHeight - 20.0;
    // Ordinary playing card dimensions have an aspect ratio of ~0.7
    final double cardAspectRatio = 0.7;
    final double cellWidth = cardHeight * cardAspectRatio;

    final double totalGridWidth = cellWidth * 6 + 5 * 12.0;
    final double aspectRatio = cellWidth / cellHeight;

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF18120D),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CHRONICLE OF SQUADS (DECK MANAGEMENT)',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'AVG AP COST: ${avgCost.toStringAsFixed(1)} AP',
                      style: GoogleFonts.oswald(
                        color: const Color(0xFFD4AF37),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Fixed-size card flip toggle icon button with no text
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        _showCardDetails ? Icons.portrait : Icons.menu_book,
                        color: const Color(0xFFD4AF37),
                        size: 22,
                      ),
                      tooltip: _showCardDetails
                          ? 'Show Portraits'
                          : 'Show Tactical Specs',
                      onPressed: () =>
                          setState(() => _showCardDetails = !_showCardDetails),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (state.unlockedDiscoveries.contains('red_hand_insignia') ||
              progress.cardUpgrades['red_hand_insignia_unlocked'] == 1) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: progress.cardUpgrades['red_hand_insignia_active'] == 1
                    ? const Color(0xFF3A1212).withAlpha(100)
                    : Colors.black26,
                border: Border.all(
                  color: progress.cardUpgrades['red_hand_insignia_active'] == 1
                      ? const Color(0xFFC42020).withAlpha(100)
                      : Colors.white10,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value:
                        progress.cardUpgrades['red_hand_insignia_active'] == 1,
                    activeColor: const Color(0xFFC42020),
                    checkColor: const Color(0xFFE5D5B0),
                    onChanged: (val) {
                      setState(() {
                        progress.cardUpgrades['red_hand_insignia_active'] =
                            val == true ? 1 : 0;
                      });
                      service.manualSave();
                    },
                  ),
                  Text(
                    'ACTIVATE "RED HAND" INSIGNIA (+20% DMG, +10% SPEED SQUAD BUFF | -5 GLARUS & FORESTERS STANDING PER TURN)',
                    style: GoogleFonts.oldStandardTt(
                      color:
                          progress.cardUpgrades['red_hand_insignia_active'] == 1
                          ? const Color(0xFFFF4D4D)
                          : const Color(0xFFC4B89B),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Expanded(
            child: Center(
              child: SizedBox(
                width: totalGridWidth,
                height: totalGridHeight,
                child: GridView.builder(
                  physics:
                      const NeverScrollableScrollPhysics(), // prevent grid vertical scrolling entirely
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: aspectRatio,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final isOccupied = index < deck.length;
                    if (!isOccupied) {
                      return _buildEmptyDeckCardSlot();
                    }

                    final cardId = deck[index];
                    final npc = CombatUnitService.createUnit(cardId);
                    final stats = npc.combatStats!;
                    final lvl = progress.getUnitLevel(cardId);
                    final exp = progress.unitExp[cardId] ?? 0.0;

                    return Column(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedInspectorCardId = cardId;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF211B15),
                                border: Border.all(
                                  color: const Color(
                                    0xFFC4B89B,
                                  ).withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: _showCardDetails
                                        ? _buildTacticalCardFace(
                                            cardId,
                                            npc,
                                            stats,
                                            lvl,
                                            exp,
                                          )
                                        : _buildPortraitCardFace(
                                            cardId,
                                            npc,
                                            lvl,
                                            exp,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildBeneathXpBar(lvl, exp),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDeckCardSlot() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF15100B),
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.15),
          style: BorderStyle.solid,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_circle_outline,
              color: Colors.white10,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              'VACANT COVENANT',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white12,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitCardFace(String cardId, NPC npc, int lvl, double exp) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Card textured backing: assets/images/card_background.png with deep brown fallback
        Positioned.fill(
          child: Image.asset(
            'assets/images/card_background.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF1A130E),
            ),
          ),
        ),
        // Elegant inner border
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
                width: 0.8,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        // Character Portrait centered inside the card
        Positioned(
          top: 24,
          bottom: 4,
          left: 4,
          right: 4,
          child: Center(
            child: CharacterBlobRenderer(npc: npc, size: 76, isCombat: true),
          ),
        ),
        // Top Banner Overlay showing ONLY squad name
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              border: const Border(
                bottom: BorderSide(color: Color(0xFFC4B89B), width: 0.8),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                npc.name.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        // Bottom-Left circular AP Cost indicator in the exact same position/manner as detail side
        Positioned(
          left: 6,
          bottom: 6,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF3E2723), // Mahogany Cost Backing
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '${npc.combatStats?.cost ?? 1}',
              style: GoogleFonts.oswald(
                color: const Color(0xFFE5D5B0),
                fontSize: 17.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTacticalCardFace(
    String cardId,
    NPC npc,
    CombatStats stats,
    int lvl,
    double exp,
  ) {
    final squadSize = _getSquadSize(cardId);
    final cost = stats.cost;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDF5E6), // Parchment / Old Lace backing
        border: Border.all(color: const Color(0xFF5D4037), width: 1.8),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Unit name running the full width of the top of the card
          SizedBox(
            width: double.infinity,
            height: 22,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                npc.name.toUpperCase(),
                style: GoogleFonts.oldStandardTt(
                  color: const Color(0xFF2E1A0A), // Dark Saddle Brown ink
                  fontSize: 18.0, // considerably larger unit name
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),

          // 2. Special symbols directly beneath the title of the card, as a subtitle line
          const SizedBox(height: 2),
          SizedBox(
            height: 14,
            child: Row(
              children: [
                if (stats.rangedDamage > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 5.0),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${stats.rangedRange.toInt()}',
                        style: GoogleFonts.oldStandardTt(
                          color: Colors.white,
                          fontSize: 9.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (stats.isFlying == true)
                  const Padding(
                    padding: EdgeInsets.only(right: 5.0),
                    child: Icon(
                      Icons.flutter_dash,
                      size: 12.0,
                      color: Color(0xFF4E342E),
                    ),
                  ),
                if (stats.trait == CombatTrait.magicImmune)
                  const Padding(
                    padding: EdgeInsets.only(right: 5.0),
                    child: Icon(
                      Icons.block,
                      size: 12.0,
                      color: Color(0xFFC62828),
                    ),
                  ),
                if (stats.unitType == UnitType.support)
                  const Padding(
                    padding: EdgeInsets.only(right: 5.0),
                    child: Icon(
                      Icons.local_fire_department,
                      size: 12.0,
                      color: Color(0xFFE64A19),
                    ),
                  ),
                if (npc.abilities.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(right: 5.0),
                    child: Icon(
                      Icons.flash_on,
                      size: 12.0,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
              ],
            ),
          ),

          const Spacer(),

          // 3. Bottom Row containing Cost Emblem (bottom-left) and Stats Column (bottom-right quadrant)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Casting cost in the bottom left corner (JUST the number, modestly smaller circular emblem)
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF3E2723), // Mahogany Cost Backing
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD4AF37),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '$cost',
                  style: GoogleFonts.oswald(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 17.0, // modestly smaller cost number
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Stats column in bottom-right quadrant, starting higher than the midline but not stretching to the left
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Melee Attack stat row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DaggerIcon(color: Colors.deepOrange.shade800, size: 13.0),
                      const SizedBox(width: 4),
                      Text(
                        '${stats.meleeAttackSpeed <= 0 ? 0 : (stats.meleeDamage / stats.meleeAttackSpeed).round()}',
                        style: GoogleFonts.oswald(
                          color: Colors.deepOrange.shade800,
                          fontSize: 13.0, // smaller
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (stats.rangedDamage > 0) ...[
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.gps_fixed,
                          size: 13.0,
                          color: Colors.deepOrange.shade800,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${stats.rangedAttackSpeed <= 0 ? 0 : (stats.rangedDamage / stats.rangedAttackSpeed).round()}',
                          style: GoogleFonts.oswald(
                            color: Colors.deepOrange.shade800,
                            fontSize: 13.0, // smaller
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 3),
                  // Health stat row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 13.0,
                        color: Colors.green.shade900,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${stats.maxHealth.toInt()}',
                        style: GoogleFonts.oswald(
                          color: Colors.green.shade900,
                          fontSize: 13.0, // smaller
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Squad unit count row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.group,
                        size: 13.0,
                        color: Color(0xFF4E342E),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'x$squadSize',
                        style: GoogleFonts.oldStandardTt(
                          color: const Color(0xFF4E342E),
                          fontSize: 13.0, // smaller
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBeneathXpBar(int lvl, double exp) {
    final nextReq = SurvivalProgress.getRequiredXpForLevel(lvl + 1);
    final prevReq = lvl == 1 ? 0 : SurvivalProgress.getRequiredXpForLevel(lvl);
    final range = nextReq - prevReq;
    final pct = range == 0 ? 1.0 : ((exp - prevReq) / range).clamp(0.0, 1.0);

    return SizedBox(
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 14,
              backgroundColor: Colors.black45,
              color: const Color(0xFFD4AF37),
            ),
          ),
          Text(
            '${exp.toInt()} / $nextReq XP',
            style: GoogleFonts.oswald(
              color: Colors.white,
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 2,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildMonitorCard({
    required String title,
    required String value,
    required String status,
    required Color statusColor,
    required IconData icon,
    required double progress,
    required Color progressColor,
  }) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFC4B89B),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: const Color(0xFFC4B89B), size: 12),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.oswald(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: GoogleFonts.playfairDisplay(
                  color: statusColor,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFactionIcon(String factionName) {
    final name = factionName.toLowerCase();
    if (name.contains('gnome') || name.contains('zurich'))
      return Icons.account_balance;
    if (name.contains('carbonari')) return Icons.local_fire_department;
    if (name.contains('chevaliers')) return Icons.shield;
    if (name.contains('freemason') || name.contains('cbcs'))
      return Icons.architecture;
    if (name.contains('illuminati')) return Icons.visibility;
    if (name.contains('rosicrucian')) return Icons.filter_vintage;
    if (name.contains('templar')) return Icons.brightness_5;
    if (name.contains('forester')) return Icons.forest;
    if (name.contains('army')) return Icons.military_tech;
    return Icons.group;
  }

  // --- FULL-SCREEN TAB 3: LEADER COMMANDER PROFILE ---
  Widget _buildFullLeaderView(
    SurvivalProgress progress,
    SurvivalService service,
  ) {
    final leader = CombatUnitService.createUnit(progress.selectedLeaderId);
    final stats = leader.combatStats!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF18120D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'COMMANDER PROFILE & PASSIVES',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel: Leader Bio (Scrollable)
                Expanded(
                  flex: 3,
                  child: Card(
                    color: const Color(0xFF130E0A),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD4AF37),
                                width: 2.0,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: ClipOval(
                              child: CharacterBlobRenderer(
                                npc: leader,
                                size: 72,
                                isCombat: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            leader.name.toUpperCase(),
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFE5D5B0),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            leader.role.toUpperCase(),
                            style: GoogleFonts.oldStandardTt(
                              color: const Color(0xFFD4AF37),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            leader.id == 'boss_rudolf'
                                ? 'Passive Bonuses: Shield formations gain +20% structural integrity and infantry units receive +10% morale.'
                                : leader.id == 'boss_gearbox'
                                ? 'Passive Bonuses: Clockwork constructs deploy 15% faster and gain +10 armor.'
                                : leader.id == 'boss_elizabeth'
                                ? 'Passive Bonuses: Undead swarms gain +15% lifesteal and nocturnal vision.'
                                : leader.id == 'boss_thorne' || leader.id == 'chief_ranger_robin'
                                ? 'Passive Bonuses: All friendly ranged units receive +2 ft attack range.'
                                : 'Passive Bonuses: Military units gain +10% critical chance, and defensive towers receive +15% armor when under the direct command of Alphonse.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.oldStandardTt(
                              color: Colors.white70,
                              fontSize: 11.5,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              border: Border.all(
                                color: const Color(
                                  0xFFC4B89B,
                                ).withValues(alpha: 0.2),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'MENTAL ACUITY (SANITY)',
                                      style: GoogleFonts.playfairDisplay(
                                        color: const Color(0xFFD4AF37),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.psychology,
                                      color: Color(0xFFD4AF37),
                                      size: 14,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${progress.sanity}%',
                                      style: GoogleFonts.oswald(
                                        color: const Color(0xFFE5D5B0),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      progress.sanity > 75
                                          ? 'STABLE'
                                          : progress.sanity > 40
                                          ? 'STRESSED'
                                          : 'INSANE',
                                      style: GoogleFonts.playfairDisplay(
                                        color: progress.sanity > 75
                                            ? Colors.green[400]!
                                            : progress.sanity > 40
                                            ? Colors.orange[400]!
                                            : Colors.red[400]!,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(1),
                                  child: LinearProgressIndicator(
                                    value: progress.sanity / 100.0,
                                    minHeight: 4,
                                    backgroundColor: Colors.white10,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      progress.sanity > 75
                                          ? const Color(0xFFC4B89B)
                                          : progress.sanity > 40
                                          ? Colors.orangeAccent
                                          : Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Middle Panel: Detailed Stats (Scrollable)
                Expanded(
                  flex: 4,
                  child: Card(
                    color: const Color(0xFF130E0A),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TACTICAL LEADER PROFILE DETAILS',
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFC4B89B),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),

                          _buildInspectorStatRow(
                            'Leader Class / Rank',
                            leader.name.toUpperCase(),
                          ),
                          _buildInspectorStatRow(
                            'Specimen Lineage',
                            leader.specimenType.toUpperCase(),
                          ),
                          _buildInspectorStatRow(
                            'Direct Placement Cost',
                            '${stats.cost} AP',
                          ),
                          _buildInspectorStatRow(
                            'Structural Vitality (HP)',
                            '${stats.health.toInt()} HP',
                          ),
                          _buildInspectorStatRow(
                            'Action Speed Multiplier',
                            '${stats.movement.toStringAsFixed(1)} m/s',
                          ),

                          const Divider(color: Colors.white10, height: 12),

                          _buildInspectorStatRow(
                            'Melee Strike Force',
                            '${stats.meleeDamage.toInt() > 0 ? stats.meleeDamage.toInt() : stats.attack.toInt()} Damage',
                          ),
                          _buildInspectorStatRow(
                            'Melee Strike Cooldown',
                            '${stats.meleeAttackSpeed.toStringAsFixed(1)}s',
                          ),
                          _buildInspectorStatRow(
                            'Melee Strike Distance',
                            '${stats.meleeRange.toStringAsFixed(1)} ft',
                          ),
                          _buildInspectorStatRow(
                            'Target Selector Rule',
                            stats.targetingRule.name.toUpperCase(),
                          ),

                          const SizedBox(height: 12),
                          Text(
                            'COMMANDER SPECIAL ABILITIES',
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFD4AF37),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (leader.abilities.isEmpty)
                            Text(
                              'NO SPECIAL ABILITIES REGISTERED.',
                              style: GoogleFonts.oldStandardTt(
                                color: Colors.white38,
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else
                            ...leader.abilities.map((a) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.name.toUpperCase(),
                                        style: GoogleFonts.playfairDisplay(
                                          color: const Color(0xFFE5D5B0),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        a.detailedDescription.toUpperCase(),
                                        style: GoogleFonts.oldStandardTt(
                                          color: const Color(0xFFC4B89B),
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Right Panel: Commander Reinforcements (Scrollable)
                Expanded(
                  flex: 4,
                  child: Card(
                    color: const Color(0xFF130E0A),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COMMANDER REINFORCEMENTS',
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFD4AF37),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reinforce commander attributes. Attributes are dynamically applied during defensive combat matches.',
                            style: GoogleFonts.oldStandardTt(
                              color: Colors.white54,
                              fontSize: 9.5,
                            ),
                          ),
                          const SizedBox(height: 8),

                          _buildLeaderStatUpgradeBtnFull(
                            progress,
                            service,
                            'hp',
                            'VITALITY (+15% Max Health)',
                            Icons.favorite,
                          ),
                          const SizedBox(height: 8),
                          _buildLeaderStatUpgradeBtnFull(
                            progress,
                            service,
                            'atk',
                            'FIREPOWER (+15% Attack Force)',
                            Icons.flash_on,
                          ),
                          const SizedBox(height: 8),
                          _buildLeaderStatUpgradeBtnFull(
                            progress,
                            service,
                            'spd',
                            'SPEED (+5% Move Velocity)',
                            Icons.speed,
                          ),
                          const SizedBox(height: 8),
                          _buildLeaderStatUpgradeBtnFull(
                            progress,
                            service,
                            'horn',
                            'TACTICAL HORN (+5% AP Regen)',
                            Icons.campaign,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderStatUpgradeBtnFull(
    SurvivalProgress progress,
    SurvivalService service,
    String stat,
    String label,
    IconData icon,
  ) {
    final key = 'leader_$stat';
    final currentLvl = progress.cardUpgrades[key] ?? 0;
    final cost = 50 + currentLvl * 25;
    final canAfford = progress.cash >= cost;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black12,
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: const Color(0xFFD4AF37)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Level $currentLvl Reinforcement',
                      style: GoogleFonts.oldStandardTt(
                        color: Colors.white38,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 24,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford
                    ? const Color(0xFF2E1A0A)
                    : Colors.transparent,
                side: BorderSide(
                  color: canAfford ? const Color(0xFFC4B89B) : Colors.white10,
                ),
                shape: const RoundedRectangleBorder(),
                padding: EdgeInsets.zero,
              ),
              onPressed: canAfford
                  ? () {
                      if (service.upgradeLeader(stat, cost)) {
                        setState(() {});
                      }
                    }
                  : null,
              child: Text(
                'UPGRADE FOR $cost CHF',
                style: GoogleFonts.playfairDisplay(
                  color: canAfford ? const Color(0xFFE5D5B0) : Colors.white24,
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- FULL-SCREEN TAB 4: DEFENSIVE TOWERS TREE VIEW ---
  Widget _buildFullTowersView(
    SurvivalProgress progress,
    SurvivalService service,
  ) {
    final hpLvl = progress.cardUpgrades['tower_hp'] ?? 0;
    final atkLvl = progress.cardUpgrades['tower_atk'] ?? 0;
    final rangeLvl = progress.cardUpgrades['tower_range'] ?? 0;
    final speedLvl = progress.cardUpgrades['tower_speed'] ?? 0;

    // Upgrades start at baseline 1 (upgrade value 0). Level 3 corresponds to upgrade value >= 2, and Level 6 to upgrade value >= 5.
    final rangeUnlocked = hpLvl >= 2 && atkLvl >= 2;
    final speedUnlocked = hpLvl >= 5 && atkLvl >= 5;

    final currentDamage = 30 + (atkLvl * 10);
    final currentRange = 20.0 + (rangeLvl * 2.5);
    final currentRateOfFire = 2.0 - (speedLvl * 0.2);
    final currentHealth = 200 + (hpLvl * 50);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF18120D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'ESTATE DEFENSIVE COVENANT & WATCHTOWERS',
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFE5D5B0),
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT COLUMN: PORTRAIT ICON & DESCRIPTION (Scrollable)
                Expanded(
                  flex: 3,
                  child: Card(
                    color: const Color(0xFF130E0A),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            'DEFENSIVE TOWERS',
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFC4B89B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Circular Portrait Frame representing Watchtower Spires
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD4AF37),
                                width: 2.0,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: ClipOval(
                              child: Container(
                                color: Colors.black38,
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _buildGothicSpire(36),
                                    _buildGothicSpire(48),
                                    _buildGothicSpire(36),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'WATCHTOWER COVENANT',
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFE5D5B0),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Defensive watchtowers constructed along the Frankenstein Manor defensive walls. Towers automatically target hostile invaders in the active lanes and supply critical artillery fire support during combat stages.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.oldStandardTt(
                              color: Colors.white70,
                              fontSize: 9.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // CENTER COLUMN: DETAILED STATS & ABILITIES (Scrollable)
                Expanded(
                  flex: 4,
                  child: Card(
                    color: const Color(0xFF130E0A),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STATS & CORE SUBSYSTEMS',
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFC4B89B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInspectorStatRow(
                            'Damage Rating',
                            '$currentDamage DMG',
                          ),
                          _buildInspectorStatRow(
                            'Ballistic Range',
                            '${currentRange.toStringAsFixed(1)} ft',
                          ),
                          _buildInspectorStatRow(
                            'Rate of Fire',
                            '${currentRateOfFire.toStringAsFixed(1)}s',
                          ),
                          _buildInspectorStatRow(
                            'Structural Integrity',
                            '$currentHealth HP',
                          ),

                          const Divider(color: Colors.white10, height: 24),

                          Text(
                            'PASSIVE COVENANT SPECIALIZATIONS',
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFD4AF37),
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.shield,
                                size: 16,
                                color: Color(0xFFC4B89B),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Covenant Aegis',
                                      style: GoogleFonts.playfairDisplay(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Watchtowers generate a protective shield. Repairing damaged towers costs 10% less cash when adjacent infrastructure is fully functional.',
                                      style: GoogleFonts.oldStandardTt(
                                        color: Colors.white38,
                                        fontSize: 9.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.gps_fixed,
                                size: 16,
                                color: Color(0xFFC4B89B),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Armor-Piercing Ballistics',
                                      style: GoogleFonts.playfairDisplay(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Upon unlocking Ballistic Range milestones, tower artillery fire automatically bypasses 15% of hostile heavy unit armor plating.',
                                      style: GoogleFonts.oldStandardTt(
                                        color: Colors.white38,
                                        fontSize: 9.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // RIGHT COLUMN: UPGRADES TREE CHART (Scrollable)
                Expanded(
                  flex: 4,
                  child: Card(
                    color: const Color(0xFF130E0A),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WATCHTOWER UPGRADE TREE',
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFD4AF37),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Left Sub-column: Firepower (Sword/Dagger icon + 5 bubbles)
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    DaggerIcon(
                                      color: const Color(0xFFD4AF37),
                                      size: 14.0,
                                    ),
                                    const SizedBox(height: 8),
                                    ...List.generate(5, (index) {
                                      final targetLvl = index + 2;
                                      final cost = 200 + (targetLvl - 2) * 100;
                                      final isCompleted =
                                          (atkLvl + 1) >= targetLvl;
                                      final isUnlocked =
                                          atkLvl >= targetLvl - 2;

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
                                        ),
                                        child: _buildTowerNodeBubble(
                                          stat: 'atk',
                                          targetLevel: targetLvl,
                                          cost: cost,
                                          isUnlocked: isUnlocked,
                                          isCompleted: isCompleted,
                                          icon: Icons.local_fire_department,
                                          label: 'Firepower',
                                          progress: progress,
                                          service: service,
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),

                              // 2. Center Sub-column: Milestones (Range at Level 3, Speed at bottom)
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Spacing equivalent to Sword icon + first 2 bubbles
                                    const SizedBox(height: 104.0),
                                    Text(
                                      'Range',
                                      style: GoogleFonts.playfairDisplay(
                                        color: const Color(0xFFC4B89B),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildTowerNodeBubble(
                                      stat: 'range',
                                      targetLevel: 1,
                                      cost: 350,
                                      isUnlocked:
                                          rangeUnlocked && rangeLvl == 0,
                                      isCompleted: rangeLvl >= 1,
                                      icon: Icons.gps_fixed,
                                      label: 'Ballistics Range',
                                      progress: progress,
                                      service: service,
                                    ),
                                    // Spacing placing reload speed lower than all 5 left/right bubbles
                                    const SizedBox(height: 90.0),
                                    Text(
                                      'Rate of Fire',
                                      style: GoogleFonts.playfairDisplay(
                                        color: const Color(0xFFC4B89B),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildTowerNodeBubble(
                                      stat: 'speed',
                                      targetLevel: 1,
                                      cost: 500,
                                      isUnlocked:
                                          speedUnlocked && speedLvl == 0,
                                      isCompleted: speedLvl >= 1,
                                      icon: Icons.speed,
                                      label: 'Reload Speed',
                                      progress: progress,
                                      service: service,
                                    ),
                                  ],
                                ),
                              ),

                              // 3. Right Sub-column: Health (Heart icon + 5 bubbles)
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.favorite,
                                      color: Color(0xFFE57373),
                                      size: 14.0,
                                    ),
                                    const SizedBox(height: 8),
                                    ...List.generate(5, (index) {
                                      final targetLvl = index + 2;
                                      final cost = 200 + (targetLvl - 2) * 100;
                                      final isCompleted =
                                          (hpLvl + 1) >= targetLvl;
                                      final isUnlocked = hpLvl >= targetLvl - 2;

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8.0,
                                        ),
                                        child: _buildTowerNodeBubble(
                                          stat: 'hp',
                                          targetLevel: targetLvl,
                                          cost: cost,
                                          isUnlocked: isUnlocked,
                                          isCompleted: isCompleted,
                                          icon: Icons.shield,
                                          label: 'Fortress HP',
                                          progress: progress,
                                          service: service,
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGothicSpire(double height) {
    return SizedBox(
      width: 24,
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Base pillar
          Positioned(
            bottom: 0,
            child: Container(
              width: 8,
              height: height - 16,
              color: const Color(0xFFC4B89B).withValues(alpha: 0.3),
            ),
          ),
          // Pointed gothic arrow tip
          Positioned(
            bottom: height - 16,
            child: const Icon(
              Icons.arrow_drop_up,
              size: 24,
              color: Color(0xFFC4B89B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTowerNodeBubble({
    required String stat,
    required int targetLevel,
    required int cost,
    required bool isUnlocked,
    required bool isCompleted,
    required IconData icon,
    required String label,
    required SurvivalProgress progress,
    required SurvivalService service,
  }) {
    final canAfford = progress.cash >= cost;
    final activeColor = isCompleted
        ? const Color(0xFF4CAF50) // Completed Green
        : (isUnlocked && canAfford)
        ? const Color(0xFFD4AF37) // Purchaseable Gold
        : Colors.white10;

    return GestureDetector(
      onTap: isUnlocked && canAfford
          ? () {
              if (service.upgradeTower(stat, cost)) {
                setState(() {});
              }
            }
          : null,
      child: Tooltip(
        message: isCompleted
            ? '$label: Level $targetLevel Active'
            : isUnlocked
            ? 'Upgrade $label to Lvl $targetLevel - Cost: $cost CHF'
            : 'Upgrade Locked: requires previous tiers',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? const Color(0xFF1E2A1C)
                    : isUnlocked
                    ? const Color(0xFF211A12)
                    : const Color(0xFF15100C),
                border: Border.all(
                  color: activeColor,
                  width: isUnlocked ? 1.5 : 1.0,
                ),
                boxShadow: [
                  if (isUnlocked && canAfford)
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check_circle,
                        size: 15,
                        color: Color(0xFF4CAF50),
                      )
                    : isUnlocked
                    ? Icon(icon, size: 13, color: const Color(0xFFD4AF37))
                    : const Icon(
                        Icons.lock_outline,
                        size: 12,
                        color: Colors.white24,
                      ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isCompleted
                  ? 'L$targetLevel'
                  : isUnlocked
                  ? '$cost'
                  : 'Locked',
              style: GoogleFonts.oswald(
                color: isCompleted
                    ? Colors.white70
                    : isUnlocked
                    ? const Color(0xFFE5D5B0)
                    : Colors.white10,
                fontSize: 7.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- FULL-SCREEN TAB 5: REQUISITIONS MARKET & ARMORY ---
  Widget _buildFullMarketView(
    SurvivalProgress progress,
    SurvivalService service,
  ) {
    final tempDiscount = progress.cardUpgrades['market_temp_discount'] ?? 0;
    final permDiscount = progress.cardUpgrades['market_discount_percent'] ?? 0;
    final totalDiscount = (tempDiscount + permDiscount).clamp(0, 80);
    final discountFactor = 1.0 - (totalDiscount / 100.0);

    final factor = 1.0 + (progress.currentTurn - 1) * 0.2;
    final foodPackCost = (40 * factor * discountFactor).toInt();
    final woodTimberCost = (60 * factor * discountFactor).toInt();
    final ironCrateCost = (85 * factor * discountFactor).toInt();

    final List<Map<String, dynamic>> availableHires = [];
    if (progress.villageHealth <= 0) {
      // Village is fallow/destroyed. Only one beast unit is available, alternating based on turn.
      final index = (progress.currentTurn) % 3;
      final choices = [
        {'type': 'undead_rats', 'cost': 190},
        {'type': 'werewolf', 'cost': 350},
        {'type': 'flesh_golem', 'cost': 320},
      ];
      availableHires.add(choices[index]);
    } else {
      final resettlement = progress.cardUpgrades['glarus_resettlement_type'] ?? 0;
      if (resettlement == 1) { // refugees
        availableHires.addAll([
          {'type': 'peasant', 'cost': 120},
          {'type': 'militia', 'cost': 180},
        ]);
      } else if (resettlement == 2) { // caravan
        availableHires.addAll([
          {'type': 'samurai', 'cost': 250},
          {'type': 'commandos', 'cost': 300},
        ]);
      } else if (resettlement == 3) { // missionaries
        availableHires.addAll([
          {'type': 'musketeers', 'cost': 220},
        ]);
      } else if (resettlement == 4) { // farmers
        availableHires.addAll([
          {'type': 'peasant', 'cost': 100},
          {'type': 'goon', 'cost': 160},
        ]);
      } else {
        if (progress.currentTurn <= 3) {
          availableHires.addAll([
            {'type': 'peasant', 'cost': 150},
            {'type': 'goon', 'cost': 200},
            {'type': 'militia', 'cost': 220},
          ]);
        } else if (progress.currentTurn <= 7) {
          availableHires.addAll([
            {'type': 'samurai', 'cost': 250},
            {'type': 'musketeers', 'cost': 260},
            {'type': 'commandos', 'cost': 300},
          ]);
        } else {
          availableHires.addAll([
            {'type': 'werewolf', 'cost': 350},
            {'type': 'flesh_golem', 'cost': 320},
            {'type': 'chimera', 'cost': 500},
          ]);
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      color: const Color(0xFF18120D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'FRANKENSTEIN BLACK MARKET & ARMORY',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel: Scrollable Raw Resources and Hires List
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACQUIRE RAW RESOURCES',
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFFC4B89B),
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMarketResourceBtnFull(
                              progress,
                              service,
                              'food',
                              30,
                              foodPackCost,
                              Icons.restaurant,
                            ),
                            _buildMarketResourceBtnFull(
                              progress,
                              service,
                              'wood',
                              50,
                              woodTimberCost,
                              Icons.forest,
                            ),
                            _buildMarketResourceBtnFull(
                              progress,
                              service,
                              'iron',
                              15,
                              ironCrateCost,
                              Icons.construction,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Text(
                          'HIRE SQUAD MERCENARIES',
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFFC4B89B),
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Column(
                          children: List.generate(availableHires.length, (
                            index,
                          ) {
                            final hire = availableHires[index];
                            final type = hire['type'] as String;
                            final baseCost = hire['cost'] as int;
                            final cost = (baseCost * discountFactor).toInt();
                            final npc = CombatUnitService.createUnit(type);
                            final bool isAlreadyOwned = progress.playerDeckIds.contains(type);
                            final canAfford =
                                progress.cash >= cost &&
                                progress.playerDeckIds.length < 12;
                            final canRecruit = canAfford && !isAlreadyOwned;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF15100B),
                                border: Border.all(
                                  color: const Color(
                                    0xFFC4B89B,
                                  ).withValues(alpha: 0.15),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CharacterBlobRenderer(
                                    npc: npc,
                                    size: 30,
                                    isCombat: true,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          npc.name.toUpperCase(),
                                          style: GoogleFonts.playfairDisplay(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '$cost CHF | Type: ${npc.specimenType.toUpperCase()}',
                                          style: GoogleFonts.oldStandardTt(
                                            color: Colors.white54,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: canRecruit
                                            ? const Color(0xFFC4B89B)
                                            : Colors.white10,
                                      ),
                                      backgroundColor: canRecruit
                                          ? const Color(0xFF2E1A0A)
                                          : Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                    ),
                                    onPressed: canRecruit
                                        ? () {
                                            if (service.buyCombatCard(
                                              type,
                                              cost,
                                            )) {
                                              setState(() {});
                                            }
                                          }
                                        : null,
                                    child: Text(
                                      isAlreadyOwned ? 'OWNED' : 'RECRUIT',
                                      style: GoogleFonts.playfairDisplay(
                                        color: canRecruit
                                            ? const Color(0xFFE5D5B0)
                                            : Colors.white24,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],

                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Right Panel: Scrollable Weapons Engineering requisition Section
                Expanded(
                  flex: 5,
                  child: Transform.translate(
                    offset: const Offset(0, -10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15100B),
                        border: Border.all(
                          color: const Color(0xFFC4B89B).withValues(alpha: 0.25),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ARMORY: SQUAD WEAPON REQUISITION',
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFD4AF37),
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upgrade weapon kits for military forces. Beasts and chimeric specimens cannot equip weapons.',
                              style: GoogleFonts.oldStandardTt(
                                color: Colors.white38,
                                fontSize: 10.5,
                              ),
                            ),
                            const SizedBox(height: 8),
      
                            _buildWeaponsRequisitionSection(progress, service),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketResourceBtnFull(
    SurvivalProgress progress,
    SurvivalService service,
    String res,
    int amount,
    int cost,
    IconData icon,
  ) {
    final bool isDestroyed = progress.villageHealth <= 0;
    final canAfford = progress.cash >= cost && !isDestroyed;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 42,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: canAfford ? const Color(0xFFC4B89B) : Colors.white10,
            ),
            backgroundColor: canAfford ? Colors.black26 : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: const RoundedRectangleBorder(),
          ),
          onPressed: canAfford
              ? () {
                  if (service.buyResource(res, amount, cost)) {
                    setState(() {});
                  }
                }
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: canAfford ? const Color(0xFFE5D5B0) : Colors.white24,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  isDestroyed ? 'N/A' : '+$amount $res\n$cost CHF',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    color: canAfford ? const Color(0xFFE5D5B0) : Colors.white24,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeaponsSelector(
    SurvivalProgress progress,
    SurvivalService service,
    String cardId,
    int arsenalLvl, {
    required bool isMiniPanel,
  }) {
    final npc = CombatUnitService.createUnit(cardId);

    if (cardId == 'samurai') {
      // Specialized Linear Samurai Path
      final currentWepIdx =
          progress.cardUpgrades['samurai_equipped_weapon'] ?? 0;
      final currWep = currentWepIdx < _samuraiUpgrades.length
          ? _samuraiUpgrades[currentWepIdx]
          : _samuraiUpgrades.first;
      final WeaponUpgradeSpec? nextWep =
          (currentWepIdx + 1) < _samuraiUpgrades.length
          ? _samuraiUpgrades[currentWepIdx + 1]
          : null;

      if (nextWep == null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, color: Color(0xFFD4AF37), size: 24),
              const SizedBox(height: 8),
              Text(
                'MAXIMUM WEAPON UPGRADE ACHIEVED',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFD4AF37),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Current: ${currWep.name}',
                style: GoogleFonts.oldStandardTt(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }

      final tempDiscount = progress.cardUpgrades['market_temp_discount'] ?? 0;
      final permDiscount =
          progress.cardUpgrades['market_discount_percent'] ?? 0;
      final totalDiscount = (tempDiscount + permDiscount).clamp(0, 80);
      final discountFactor = 1.0 - (totalDiscount / 100.0);

      final baseCost = nextWep.cost;
      final cost = (baseCost * discountFactor).toInt();
      final requiredArsenalLvl = _weaponRequiresArsenal(nextWep.name)
          ? (currentWepIdx + 1)
          : 0;
      final isLocked = arsenalLvl < requiredArsenalLvl;
      final squadSize = _getSquadSize(cardId);
      final totalLinearCost = cost * squadSize;
      final canAffordLinear = progress.cash >= totalLinearCost && !isLocked;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPECIALIZED LINEAR SAMURAI UPGRADE',
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFE5D5B0),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.black38,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildComparisonRow(
                  'Weapon Package',
                  currWep.name,
                  nextWep.name,
                  highlight: true,
                ),
                _buildComparisonRow(
                  'Base Damage',
                  currWep.damage.toStringAsFixed(0),
                  nextWep.damage.toStringAsFixed(0),
                ),
                _buildComparisonRow(
                  'Rate of Fire',
                  '${currWep.speed.toStringAsFixed(1)}s',
                  '${nextWep.speed.toStringAsFixed(1)}s',
                ),
                _buildComparisonRow(
                  'Attack Range',
                  '${currWep.range.toStringAsFixed(1)} ft',
                  '${nextWep.range.toStringAsFixed(1)} ft',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (isLocked) ...[
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.withValues(alpha: 0.1),
              width: double.infinity,
              child: Text(
                'LOCKED: Requires Arsenal Level $requiredArsenalLvl on the Estate Map!',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canAffordLinear
                    ? const Color(0xFF2E1A0A)
                    : Colors.transparent,
                side: BorderSide(
                  color: canAffordLinear
                      ? const Color(0xFFD4AF37)
                      : Colors.white10,
                ),
                shape: const RoundedRectangleBorder(),
              ),
              onPressed: canAffordLinear
                  ? () {
                      progress.cash -= totalLinearCost;
                      progress.cardUpgrades['samurai_equipped_weapon'] =
                          currentWepIdx + 1;
                      service.addLog(
                        'Upgraded weapons of Samurai to ${nextWep.name} for $totalLinearCost CHF ($squadSize troops x $cost CHF).',
                      );
                      service.manualSave();
                      setState(() {});
                    }
                  : null,
              child: Text(
                'PURCHASE WEAPON UPGRADE FOR $totalLinearCost CHF',
                style: GoogleFonts.playfairDisplay(
                  color: canAffordLinear
                      ? const Color(0xFFE5D5B0)
                      : Colors.white24,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Standard General Market Weapons Selector with custom seed, automatic recommendation & list popup button
    final currentWepIdx =
        progress.cardUpgrades['${cardId}_equipped_weapon_idx'] ?? 0;
    final currentWepName = currentWepIdx == 0
        ? _getStartingWeapon(cardId).name
        : _generalWeaponMarket[currentWepIdx - 1].name;
    final currWep = _getEquippedWeaponStats(cardId, currentWepName);
    final currentScore = _scoreWeapon(cardId, currWep);

    final squadSize = _getSquadSize(cardId);

    final tempDiscount = progress.cardUpgrades['market_temp_discount'] ?? 0;
    final permDiscount = progress.cardUpgrades['market_discount_percent'] ?? 0;
    final totalDiscount = (tempDiscount + permDiscount).clamp(0, 80);
    final discountFactor = 1.0 - (totalDiscount / 100.0);

    final rawWeps = _getAvailableMarketWeapons(
      progress.currentTurn,
      progress.villageHealth,
    );
    // Compatible, affordable, and unlocked weapons for sale
    final compatibleWeps = rawWeps.where((w) {
      if (_getWeaponCompatibilityError(cardId, w.name) != null) return false;
      final discountedCost = (w.cost * discountFactor).toInt();
      if (progress.cash < discountedCost * squadSize) return false;
      final reqLvl = _weaponRequiresArsenal(w.name) ? w.tier : 0;
      if (arsenalLvl < reqLvl) return false;
      return true;
    }).toList();

    // Auto-propose the best upgrade (if any compatible is better)
    GeneralWeaponSpec? recommendedWep;
    double bestScore = currentScore;
    for (var wep in compatibleWeps) {
      final wepStats = _getEquippedWeaponStats(cardId, wep.name);
      final score = _scoreWeapon(cardId, wepStats);
      if (score > bestScore) {
        bestScore = score;
        recommendedWep = wep;
      }
    }

    // Default evaluated weapon to recommended, or fallback
    final evaluatedWep = _getEvaluatedWeapon(context, cardId, rawWeps);
    final evaluatedStats = evaluatedWep != null
        ? _getEquippedWeaponStats(cardId, evaluatedWep.name)
        : null;
    final totalCost = evaluatedWep != null
        ? (evaluatedWep.cost * discountFactor).toInt() * squadSize
        : 0;

    final reqLvl = evaluatedWep != null
        ? (_weaponRequiresArsenal(evaluatedWep.name) ? evaluatedWep.tier : 0)
        : 0;
    final isLockedByArsenal = arsenalLvl < reqLvl;
    final canAfford =
        evaluatedWep != null &&
        progress.cash >= totalCost &&
        !isLockedByArsenal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EQUIPPED WEAPON: ${currWep.name.toUpperCase()}',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFD4AF37),
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'DMG: ${currWep.damage.toStringAsFixed(0)} | SPD: ${currWep.speed.toStringAsFixed(1)}s | RNG: ${currWep.range.toStringAsFixed(1)} ft',
          style: GoogleFonts.oldStandardTt(
            color: Colors.white54,
            fontSize: 10.0,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(color: Colors.white10, height: 4),
        const SizedBox(height: 6),
        Text(
          'BLACK MARKET WEAPON REQUISITION LIST:',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFC4B89B),
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),

        // The popup / list button
        PopupMenuButton<GeneralWeaponSpec>(
          onSelected: (selected) {
            setState(() {
              _evaluatedWeaponForCard[cardId] = selected;
            });
          },
          itemBuilder: (context) => compatibleWeps.map((wep) {
            final isRec = wep == recommendedWep;
            return PopupMenuItem<GeneralWeaponSpec>(
              value: wep,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      wep.name.toUpperCase() + (isRec ? ' (RECOMMENDED)' : ''),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 11,
                        fontWeight: isRec ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    tempDiscount > 0
                        ? '${(wep.cost * discountFactor).toInt()} CHF'
                        : '${wep.cost} CHF',
                    style: GoogleFonts.oswald(
                      color: const Color(0xFFD4AF37),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF211B15),
              border: Border.all(
                color: const Color(0xFFC4B89B).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    evaluatedWep != null
                        ? '${evaluatedWep == recommendedWep ? "★ RECOMMENDED: " : ""}${evaluatedWep.name.toUpperCase()}'
                        : 'NO COMPATIBLE OR AFFORDABLE WEAPONS FOR SALE',
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFFC4B89B),
                  size: 18,
                ),
              ],
            ),
          ),
        ),

        if (evaluatedWep != null && evaluatedStats != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(6),
            color: Colors.black26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UPGRADE STAT EVALUATION:',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _buildComparisonRow(
                  'Base Damage',
                  currWep.damage.toStringAsFixed(0),
                  evaluatedStats.damage.toStringAsFixed(0),
                ),
                _buildComparisonRow(
                  'Attack Cooldown',
                  '${currWep.speed.toStringAsFixed(1)}s',
                  '${evaluatedStats.speed.toStringAsFixed(1)}s',
                ),
                _buildComparisonRow(
                  'Effective Range',
                  '${currWep.range.toStringAsFixed(1)} ft',
                  '${evaluatedStats.range.toStringAsFixed(1)} ft',
                ),
              ],
            ),
          ),

          // Advantage/Disadvantage text
          if (_getWeaponAdvantageOrDisadvantage(cardId, evaluatedWep.name) !=
              null) ...[
            const SizedBox(height: 6),
            Text(
              _getWeaponAdvantageOrDisadvantage(cardId, evaluatedWep.name)!,
              style: GoogleFonts.oldStandardTt(
                color:
                    _getWeaponAdvantageOrDisadvantage(
                      cardId,
                      evaluatedWep.name,
                    )!.contains('ADVANTAGE')
                    ? Colors.greenAccent.shade700
                    : Colors.orangeAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],

          if (isLockedByArsenal) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(6),
              color: Colors.red.withValues(alpha: 0.1),
              width: double.infinity,
              child: Text(
                'LOCKED: Requires Arsenal Level $reqLvl on the Estate Map!',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford
                    ? const Color(0xFF2E1A0A)
                    : Colors.transparent,
                side: BorderSide(
                  color: canAfford ? const Color(0xFFD4AF37) : Colors.white10,
                ),
                shape: const RoundedRectangleBorder(),
                padding: EdgeInsets.zero,
              ),
              onPressed: canAfford
                  ? () {
                      progress.cash -= totalCost;
                      final marketIndex = _generalWeaponMarket.indexOf(
                        evaluatedWep,
                      );
                      progress.cardUpgrades['${cardId}_equipped_weapon_idx'] =
                          marketIndex + 1;
                      service.addLog(
                        'Equipped ${evaluatedWep.name} on ${npc.name} for $totalCost CHF ($squadSize troops x ${evaluatedWep.cost} CHF).',
                      );
                      service.manualSave();
                      setState(() {
                        _evaluatedWeaponForCard.remove(cardId);
                      });
                    }
                  : null,
              child: Text(
                'REQUISITION UPGRADE FOR $totalCost CHF',
                style: GoogleFonts.playfairDisplay(
                  color: canAfford ? const Color(0xFFE5D5B0) : Colors.white24,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              'No weapon upgrade currently selected for evaluation.',
              style: GoogleFonts.oldStandardTt(
                color: Colors.white24,
                fontSize: 10.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeaponsRequisitionSection(
    SurvivalProgress progress,
    SurvivalService service,
  ) {
    if (progress.villageHealth <= 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Text(
            'ARMORY DEPLETED\n(The Village of Glarus lies in ruins. Weapon requisition is unavailable.)',
            textAlign: TextAlign.center,
            style: GoogleFonts.oldStandardTt(
              color: Colors.redAccent.withValues(alpha: 0.6),
              fontSize: 11,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    final deck = progress.playerDeckIds;

    final List<String> nonBeastSquads = deck.where((cardId) {
      final isAnimal =
          cardId.contains('rat') || cardId == 'werewolf' || cardId == 'chimera';
      return !isAnimal;
    }).toList();

    if (nonBeastSquads.isEmpty) {
      return Center(
        child: Text(
          'No human or mechanical squads in deck capable of equipping weapon upgrades.',
          textAlign: TextAlign.center,
          style: GoogleFonts.oldStandardTt(
            color: Colors.white24,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    if (_selectedWepCardId == null ||
        !nonBeastSquads.contains(_selectedWepCardId)) {
      _selectedWepCardId = nonBeastSquads.first;
    }

    final cardId = _selectedWepCardId!;

    final arsenalBuilding = progress.buildings.firstWhere(
      (b) => b.type == SurvivalBuildingType.arsenal,
      orElse: () => SurvivalBuilding(
        id: '',
        type: SurvivalBuildingType.arsenal,
        level: 0,
        assignedUnitIds: [],
      ),
    );
    final arsenalLvl = arsenalBuilding.level;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'SELECT SQUAD: ',
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFC4B89B),
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                color: const Color(0xFF211B15),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: cardId,
                    dropdownColor: const Color(0xFF211B15),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFFC4B89B),
                    ),
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _selectedWepCardId = val;
                      });
                    },
                    items: nonBeastSquads.map((id) {
                      final sNpc = CombatUnitService.createUnit(id);
                      return DropdownMenuItem(
                        value: id,
                        child: Text(sNpc.name.toUpperCase()),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildWeaponsSelector(
          progress,
          service,
          cardId,
          arsenalLvl,
          isMiniPanel: false,
        ),
      ],
    );
  }

  Widget _buildComparisonRow(
    String label,
    String currentVal,
    String nextVal, {
    bool highlight = false,
  }) {
    final isChanged = currentVal != nextVal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.oldStandardTt(
                color: highlight ? const Color(0xFFC4B89B) : Colors.white38,
                fontSize: 11.0,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentVal,
                style: GoogleFonts.oswald(
                  color: Colors.white54,
                  fontSize: 11.5,
                ),
              ),
              if (isChanged) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward,
                  color: Color(0xFFD4AF37),
                  size: 11,
                ),
                const SizedBox(width: 6),
                Text(
                  nextVal,
                  style: GoogleFonts.oswald(
                    color: const Color(0xFFD4AF37),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardInspector(
    BuildContext context,
    SurvivalProgress progress,
    SurvivalService service,
    String cardId,
  ) {
    final npc = CombatUnitService.createUnit(cardId);
    final exp = progress.unitExp[cardId] ?? 0.0;
    final lvl = progress.getUnitLevel(cardId);
    var stats = npc.combatStats!;
    if (cardId == 'cannoneer' && lvl >= 6) {
      stats = stats.copyWith(
        distance: 23.0,
        rangedRange: 23.0,
      );
    }
    final nextReq = SurvivalProgress.getRequiredXpForLevel(lvl + 1);
    final pct = nextReq == 0 ? 1.0 : (exp / nextReq).clamp(0.0, 1.0);

    final bool isMeleeOnly = stats.rangedDamage == 0.0;
    final bool isUndeadUnit = SurvivalService.isUndead(npc);
    final bool isRightCapable =
        !(cardId.contains('rat') ||
            cardId == 'werewolf' ||
            cardId == 'chimera');

    final squadSize = _getSquadSize(cardId);

    final arsenalBuilding = progress.buildings.firstWhere(
      (b) => b.type == SurvivalBuildingType.arsenal,
      orElse: () => SurvivalBuilding(
        id: '',
        type: SurvivalBuildingType.arsenal,
        level: 0,
        assignedUnitIds: [],
      ),
    );
    final arsenalLvl = arsenalBuilding.level;

    return Positioned.fill(
      child: Container(
        color: const Color(0xFF18120D),
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SQUAD COVENANT DETAIL INSPECTOR',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isDrafting)
                      Builder(
                        builder: (context) {
                          final isSelected = _selectedCart.contains(cardId);
                          final cost =
                              _draftPool.firstWhere(
                                    (x) => x['type'] == cardId,
                                    orElse: () => {'cost': 0},
                                  )['cost']
                                  as int;
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            height: 28,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? Colors.red.shade900
                                    : Colors.green.shade900,
                                foregroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedCart.remove(cardId);
                                  } else {
                                    int currentTotal = 0;
                                    for (var type in _selectedCart) {
                                      final match = _draftPool.firstWhere(
                                        (x) => x['type'] == type,
                                      );
                                      currentTotal += match['cost'] as int;
                                    }
                                    if (currentTotal + cost <= 1000 &&
                                        _selectedCart.length < 12) {
                                      _selectedCart.add(cardId);
                                    } else if (_selectedCart.length >= 12) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Squad limit is 12 units!',
                                          ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Insufficient CHF budget!',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                });
                              },
                              child: Text(
                                isSelected
                                    ? 'REMOVE (-$cost CHF)'
                                    : 'ADD (+$cost CHF)',
                                style: GoogleFonts.playfairDisplay(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFFD4AF37),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedInspectorCardId = null;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: Color(0xFF3A2F25), height: 8),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT PANEL
                  Expanded(
                    child: Card(
                      color: const Color(0xFF130E0A),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFD4AF37),
                                  width: 2.0,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: ClipOval(
                                child: CharacterBlobRenderer(
                                  npc: npc,
                                  size: 64,
                                  isCombat: true,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'MILITARY STANDING',
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFC4B89B),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'LEVEL $lvl',
                              style: GoogleFonts.oswald(
                                color: const Color(0xFFD4AF37),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 14,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      minHeight: 14,
                                      backgroundColor: Colors.black54,
                                      color: const Color(0xFFD4AF37),
                                    ),
                                  ),
                                  Text(
                                    '${exp.toInt()} / $nextReq XP',
                                    style: GoogleFonts.oswald(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 1,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'MILITARY TRAINING LEVELING',
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFE5D5B0),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Deploy unit to training ground to earn +${1 + lvl} XP per turn passively, or spend cash budget directly below to purchase tactical drills.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.oldStandardTt(
                                color: Colors.white38,
                                fontSize: 9.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Builder(
                              builder: (context) {
                                final drillXp = 3 * lvl;
                                final drillCost = 15 * lvl;
                                final hasUndeadTraining =
                                    Provider.of<GameState>(
                                      context,
                                      listen: false,
                                    ).unlockedDiscoveries.contains(
                                      'undead_training',
                                    );
                                final canAffordDrills =
                                    (progress.cash >= drillCost &&
                                    !_isDrafting &&
                                    (!isUndeadUnit || hasUndeadTraining));

                                return ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: canAffordDrills
                                        ? const Color(0xFF2E1A0A)
                                        : Colors.transparent,
                                    side: BorderSide(
                                      color: canAffordDrills
                                          ? const Color(0xFFC4B89B)
                                          : Colors.white10,
                                    ),
                                    shape: const RoundedRectangleBorder(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed: canAffordDrills
                                      ? () {
                                          final oldLvl = progress.getUnitLevel(cardId);
                                          if (service.buyTrainingPoints(
                                            cardId,
                                            drillXp,
                                            drillCost,
                                          )) {
                                            final newLvl = progress.getUnitLevel(cardId);
                                            if (newLvl > oldLvl) {
                                              _showLevelUpDialog(
                                                context,
                                                cardId,
                                                oldLvl,
                                                newLvl,
                                              );
                                            }
                                            setState(() {});
                                          }
                                        }
                                      : null,
                                  child: Text(
                                    _isDrafting
                                        ? 'LOCKED DURING DRAFT'
                                        : (isUndeadUnit && !hasUndeadTraining
                                              ? 'UNDEAD CANNOT DRILL'
                                              : 'BUY DRILLS: +$drillXp XP ($drillCost CHF)'),
                                    style: GoogleFonts.playfairDisplay(
                                      color: canAffordDrills
                                          ? const Color(0xFFE5D5B0)
                                          : Colors.white24,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // MIDDLE PANEL
                  Expanded(
                    child: Card(
                      color: const Color(0xFF130E0A),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REGIMENTAL ATTRIBUTES & PROFILE',
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFC4B89B),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),

                            _buildInspectorStatRow(
                              'Squad Class / Name',
                              npc.name.toUpperCase(),
                            ),
                            _buildInspectorStatRow(
                              'Specimen / Specie',
                              npc.specimenType.toUpperCase(),
                            ),
                            _buildInspectorStatRow(
                              'Action Point (AP) Cost',
                              '${stats.cost} AP',
                            ),
                            _buildInspectorStatRow(
                              'Combat Squad Count',
                              'x$squadSize',
                            ),
                            _buildInspectorStatRow(
                              'Structural Vitality (HP)',
                              '${(stats.health * (1.0 + (lvl - 1) * 0.1)).toInt()} HP',
                            ),
                            _buildInspectorStatRow(
                              'Tactical Move Speed',
                              '${stats.movement.toStringAsFixed(1)} m/s',
                            ),

                            const Divider(color: Colors.white10, height: 10),

                            Builder(
                              builder: (context) {
                                final double mult = 1.0 + (lvl - 1) * 0.1;
                                final double baseMelee = stats.meleeDamage > 0
                                    ? stats.meleeDamage
                                    : stats.attack;
                                final double meleeHit = baseMelee * mult;
                                final double meleeSpd =
                                    stats.meleeAttackSpeed > 0
                                        ? stats.meleeAttackSpeed
                                        : stats.speed;
                                final double meleeDps = meleeSpd > 0
                                    ? (meleeHit / meleeSpd)
                                    : meleeHit;

                                return Column(
                                  children: [
                                    _buildInspectorStatRow(
                                      'Melee Damage per Attack',
                                      '${meleeHit.toStringAsFixed(1)} Dmg',
                                    ),
                                    _buildInspectorStatRow(
                                      'Melee Damage per Second (DPS)',
                                      '${meleeDps.toStringAsFixed(1)} DPS',
                                    ),
                                  ],
                                );
                              },
                            ),
                            _buildInspectorStatRow(
                              'Melee Strike Cooldown',
                              '${stats.meleeAttackSpeed.toStringAsFixed(1)}s',
                            ),
                            _buildInspectorStatRow(
                              'Melee Engage Distance',
                              '${stats.meleeRange.toStringAsFixed(1)} ft',
                            ),

                            if (!isMeleeOnly) ...[
                              const Divider(color: Colors.white10, height: 10),
                              Text(
                                'AMMUNITION & RANGED SPECIALIZATION',
                                style: GoogleFonts.playfairDisplay(
                                  color: const Color(0xFFD4AF37),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Builder(
                                builder: (context) {
                                  final double mult = 1.0 + (lvl - 1) * 0.1;
                                  final double rangedHit =
                                      stats.rangedDamage * mult;
                                  final double rangedSpd =
                                      stats.rangedAttackSpeed > 0
                                          ? stats.rangedAttackSpeed
                                          : stats.speed;
                                  final double rangedDps = rangedSpd > 0
                                      ? (rangedHit / rangedSpd)
                                      : rangedHit;

                                  return Column(
                                    children: [
                                      _buildInspectorStatRow(
                                        'Ranged Damage per Attack',
                                        '${rangedHit.toStringAsFixed(1)} Dmg',
                                      ),
                                      _buildInspectorStatRow(
                                        'Ranged Damage per Second (DPS)',
                                        '${rangedDps.toStringAsFixed(1)} DPS',
                                      ),
                                    ],
                                  );
                                },
                              ),
                              _buildInspectorStatRow(
                                'Ranged Fire Rate Cooldown',
                                '${stats.rangedAttackSpeed.toStringAsFixed(1)}s',
                              ),
                              _buildInspectorStatRow(
                                'Ranged Effective Range',
                                '${stats.rangedRange.toStringAsFixed(1)} ft',
                              ),
                              _buildInspectorStatRow(
                                'Targeting Strategy priority',
                                stats.targetingRule.name.toUpperCase(),
                              ),
                            ],
                            if (npc.abilities.isNotEmpty) ...[
                              const Divider(color: Colors.white10, height: 10),
                              Text(
                                'SPECIAL ABILITIES',
                                style: GoogleFonts.playfairDisplay(
                                  color: const Color(0xFFD4AF37),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ...npc.abilities.map(
                                (a) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.name.toUpperCase(),
                                        style: GoogleFonts.playfairDisplay(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        a.detailedDescription,
                                        style: GoogleFonts.oldStandardTt(
                                          color: Colors.white70,
                                          fontSize: 9.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // RIGHT PANEL
                  Expanded(
                    child: Card(
                      color: const Color(0xFF130E0A),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ARMORY WEAPONS ENGINEERING',
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFC4B89B),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Buy manufactured weapon engineering configurations directly changing all attack properties.',
                              style: GoogleFonts.oldStandardTt(
                                color: Colors.white38,
                                fontSize: 9.5,
                              ),
                            ),
                            const SizedBox(height: 8),

                            if (_isDrafting) ...[
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16.0,
                                  ),
                                  child: Text(
                                    'Armory modifications are locked during recruitment.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.oldStandardTt(
                                      color: Colors.white24,
                                      fontSize: 10.5,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                            ] else if (!isRightCapable) ...[
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16.0,
                                  ),
                                  child: Text(
                                    'Beasts, undead vermin swarms, and chimeras cannot equip weaponry.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.oldStandardTt(
                                      color: Colors.white24,
                                      fontSize: 10.5,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              _buildWeaponsSelector(
                                progress,
                                service,
                                cardId,
                                arsenalLvl,
                                isMiniPanel: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectorStatRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.oldStandardTt(
              color: Colors.white38,
              fontSize: 11.5,
            ),
          ),
          Text(
            val,
            style: GoogleFonts.oswald(
              color: Colors.white70,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showNarrativeEncounter(
    BuildContext context,
    String encounterId,
    SurvivalProgress progress,
    SurvivalService service,
    GameState state,
  ) {
    progress.cardUpgrades['last_visitor_turn'] = progress.currentTurn;
    progress.cardUpgrades['encounter_${encounterId}_resolved'] = 1;

    final isConditional = encounterId == 'davos_smallpox_vaccine' || encounterId == 'smallpox_outbreak';

    if (!isConditional) {
      final rand = Random();
      final nextInterval = rand.nextBool() ? 3 : 4;
      progress.cardUpgrades['next_encounter_turn'] =
          progress.currentTurn + nextInterval;

      final currentIndex = progress.cardUpgrades['next_encounter_index'] ?? 0;
      progress.cardUpgrades['next_encounter_index'] = currentIndex + 1;
    }

    service.manualSave();

    String title = "";
    String faction = "";
    String story = "";
    final List<Map<String, dynamic>> options = [];

    switch (encounterId) {
      case 'glarus_refugees_resettle':
        title = "GLARUS REFUGEES RESETTLEMENT OPPORTUNITY";
        faction = "Glarus Refugees";
        story = "A group of wandering Glarus refugees has returned, looking to resettle the ruins. They request resources to rebuild.";
        options.add({
          'title': 'A) "Provide 300 food and 200 wood to help them rebuild."',
          'subtitle': 'Effect: Rebuild Glarus village, set Glarus to refugees faction, gain +20 Glarus standing.',
          'checkAffordable': () => progress.food >= 300 && progress.wood >= 200,
          'onPress': () {
            progress.food -= 300;
            progress.wood -= 200;
            progress.villageHealth = 100;
            progress.cardUpgrades['glarus_resettlement_type'] = 1;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) + 20;
            service.addLog(
              'Refugees resettled Glarus. Human units unlocked in market.',
            );
          },
        });
        options.add({
          'title': 'B) "Turn them away. (Glarus remains in ruins)."',
          'subtitle': 'Effect: Lose -10 Glarus standing.',
          'onPress': () {
            progress.factionStandings['Glarus'] = (progress.factionStandings['Glarus'] ?? 0) - 10;
            service.addLog('Turned away refugees. Glarus remains fallow.');
          },
        });
        break;

      case 'glarus_caravan_stay':
        title = "VISITING CARAVAN PROPOSAL";
        faction = "Traveling Merchants";
        story = "A wealthy merchant caravan asks if they can establish a temporary trading hub in Glarus ruins. They offer a buyout payment.";
        options.add({
          'title': 'A) "Accept their proposal (Pay 500 CHF for security, they pay 1000 CHF upfront)."',
          'subtitle': 'Effect: Rebuild Glarus village, set Glarus to caravan faction, +500 CHF net gain, +10 Gnomes standing.',
          'checkAffordable': () => progress.cash >= 500,
          'onPress': () {
            progress.cash += 500; // -500 + 1000 = +500 net
            progress.villageHealth = 100;
            progress.cardUpgrades['glarus_resettlement_type'] = 2;
            progress.factionStandings['Gnomes of Zurich'] =
                (progress.factionStandings['Gnomes of Zurich'] ?? 0) + 10;
            service.addLog(
              'Caravan established in Glarus. Exotic units unlocked.',
            );
          },
        });
        options.add({
          'title': 'B) "Decline their proposal."',
          'subtitle': 'Effect: No effect. Glarus remains in ruins.',
          'onPress': () {
            service.addLog('Declined caravan. Glarus remains fallow.');
          },
        });
        break;

      case 'glarus_missionaries_buy':
        title = "MISSIONARY PURCHASE ORDER";
        faction = "Order of Saint Leopold";
        story = "Zealous missionaries offer to purchase the Glarus ruins to build a holy chapel. They demand we keep our army free of abominations.";
        options.add({
          'title': 'A) "Sell them the land for 800 CHF."',
          'subtitle': 'Effect: Rebuild Glarus village, set Glarus to missionaries faction, gain +800 CHF, gain +15 Glarus standing.',
          'onPress': () {
            progress.cash += 800;
            progress.villageHealth = 100;
            progress.cardUpgrades['glarus_resettlement_type'] = 3;
            progress.factionStandings['Glarus'] = (progress.factionStandings['Glarus'] ?? 0) + 15;
            service.addLog('Sold Glarus to holy Order. Watch out for supernatural unit penalties!');
          },
        });
        options.add({
          'title': 'B) "We reject their religious fanaticism."',
          'subtitle': 'Effect: Lose -15 Glarus standing.',
          'onPress': () {
            progress.factionStandings['Glarus'] = (progress.factionStandings['Glarus'] ?? 0) - 15;
            service.addLog('Rejected missionaries. Glarus remains fallow.');
          },
        });
        break;

      case 'glarus_farmers_grant':
        title = "CONSEIL D'ETAT LAND DECREE";
        faction = "displaced Farmers";
        story = "The Canton Conseil d'Etat has granted Glarus lands to displaced Swiss farmers. They offer to supply crops in exchange for protection.";
        options.add({
          'title': 'A) "Accept Canton decree (Provide 150 iron for protection watchtowers)."',
          'subtitle': 'Effect: Rebuild Glarus, set Glarus to farmers faction, gain +200 food, gain +15 Glarus standing.',
          'checkAffordable': () => progress.iron >= 150,
          'onPress': () {
            progress.iron -= 150;
            progress.food += 200;
            progress.villageHealth = 100;
            progress.cardUpgrades['glarus_resettlement_type'] = 4;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) + 15;
            service.addLog(
              'Displaced farmers resettled Glarus under Canton protection.',
            );
          },
        });
        options.add({
          'title': 'B) "Ignore the decree. Glarus belongs to no one."',
          'subtitle': 'Effect: Lose -10 Glarus standing with Canton.',
          'onPress': () {
            progress.factionStandings['Glarus'] = (progress.factionStandings['Glarus'] ?? 0) - 10;
            service.addLog('Ignored decree. Glarus remains fallow.');
          },
        });
        break;

      case 'davos_smallpox_vaccine':
        title = "THE DAVOS VACCINE DISCOVERY";
        faction = "Davos Farm workers";
        story =
            "A farm worker assigned to the Davos Plot has discovered a viable vaccine for smallpox by observing cowpox pustules on the dairy cows. How shall we utilize this breakthrough?";
        options.add({
          'title': 'A) "Sell the formula to the Arsenal for mass production."',
          'subtitle': 'Effect: Gain +1000 CHF immediately. Future Arsenal production yields +50% profits. Outbreak scheduled.',
          'onPress': () {
            progress.cash += 1000;
            progress.cardUpgrades['davos_vaccine_choice'] = 1;
            progress.cardUpgrades['next_smallpox_outbreak_turn'] = progress.currentTurn + 3;
            service.addLog('Vaccine formula sold to the Arsenal. High-volume pharmaceutical profits unlocked.');
          },
        });
        options.add({
          'title': 'B) "Provide it to the Secret Societies in exchange for funding and favor."',
          'subtitle': 'Effect: Gain +600 CHF. Gain +25 Standing with Gnomes of Zurich and Freemasons. Outbreak scheduled.',
          'onPress': () {
            progress.cash += 600;
            progress.cardUpgrades['davos_vaccine_choice'] = 2;
            progress.factionStandings['Gnomes of Zurich'] = (progress.factionStandings['Gnomes of Zurich'] ?? 0) + 25;
            progress.factionStandings['Freemasons'] = (progress.factionStandings['Freemasons'] ?? 0) + 25;
            progress.cardUpgrades['next_smallpox_outbreak_turn'] = progress.currentTurn + 3;
            service.addLog('Vaccine formula shared with the Secret Societies. Influence increased.');
          },
        });
        options.add({
          'title': 'C) "Immunize our watchtower guards and local village immediately."',
          'subtitle': 'Effect: Fully protects watchtowers and Glarus village from future outbreak. (+20 Glarus standing). Outbreak scheduled.',
          'onPress': () {
            progress.factionStandings['Glarus'] = (progress.factionStandings['Glarus'] ?? 0) + 20;
            progress.cardUpgrades['davos_vaccine_choice'] = 3;
            progress.cardUpgrades['next_smallpox_outbreak_turn'] = progress.currentTurn + 3;
            service.addLog('Valley immunized immediately. Security and local relations secured.');
          },
        });
        break;

      case 'smallpox_outbreak':
        title = "THE SMALLPOX OUTBREAK";
        faction = "Glarus Village";
        final choice = progress.cardUpgrades['davos_vaccine_choice'] ?? 0;
        if (choice == 3) {
          story =
              "Smallpox has broken out in the valley! Fortunately, our immediate immunization campaigns have completely protected both the watchtowers and the residents of Glarus village. We suffer no losses.";
          options.add({
            'title': 'A) "Thank goodness we prepared."',
            'subtitle': 'Effect: No casualties. (+10 Standing with Glarus)',
            'onPress': () {
              progress.factionStandings['Glarus'] = (progress.factionStandings['Glarus'] ?? 0) + 10;
              service.addLog('Valley successfully weathered the outbreak with zero casualties.');
            },
          });
        } else {
          story =
              "Smallpox has broken out in the valley! Because we sold or shared the formula, we only have a limited supply of vaccine doses. We must choose how to allocate them.";
          options.add({
            'title': 'A) "Prioritize Glarus Village."',
            'subtitle': 'Effect: Glarus village is saved (+20 Standing). Watchtowers suffer -20% health damage from sick guards.',
            'onPress': () {
              progress.factionStandings['Glarus'] = (progress.factionStandings['Glarus'] ?? 0) + 20;
              progress.towerDamaged['tower_1'] = min(1.0, (progress.towerDamaged['tower_1'] ?? 0.0) + 0.2);
              progress.towerDamaged['tower_2'] = min(1.0, (progress.towerDamaged['tower_2'] ?? 0.0) + 0.2);
              progress.towerDamaged['tower_3'] = min(1.0, (progress.towerDamaged['tower_3'] ?? 0.0) + 0.2);
              service.addLog('Outbreak: Village protected, watchtowers suffered casualties.');
            },
          });
          options.add({
            'title': 'B) "Prioritize Watchtower Guards."',
            'subtitle': 'Effect: Watchtowers are saved. Glarus village health is reduced by 40% (-20 Glarus Standing).',
            'onPress': () {
              progress.villageHealth = max(0, progress.villageHealth - 40);
              progress.factionStandings['Glarus'] = (progress.factionStandings['Glarus'] ?? 0) - 20;
              service.addLog('Outbreak: Watchtowers protected, Glarus village devastated.');
            },
          });
          options.add({
            'title': 'C) "Sell the limited vaccine doses on the black market."',
            'subtitle': 'Effect: Gain +800 CHF. Both watchtowers (-20% health) and Glarus village (-40% health) suffer casualties (-25 Standing).',
            'onPress': () {
              progress.cash += 800;
              progress.villageHealth = max(0, progress.villageHealth - 40);
              progress.factionStandings['Glarus'] = (progress.factionStandings['Glarus'] ?? 0) - 25;
              progress.towerDamaged['tower_1'] = min(1.0, (progress.towerDamaged['tower_1'] ?? 0.0) + 0.2);
              progress.towerDamaged['tower_2'] = min(1.0, (progress.towerDamaged['tower_2'] ?? 0.0) + 0.2);
              progress.towerDamaged['tower_3'] = min(1.0, (progress.towerDamaged['tower_3'] ?? 0.0) + 0.2);
              service.addLog('Outbreak: Black market vaccine sales completed. Outbreak devastated valley.');
            },
          });
        }
        break;

      case 'gnomes_artillery':
        title = "THE GNOMES OF ZURICH ARTILLERY";
        faction = "Gnomes of Zurich";
        story =
            "The Gnomes of Zurich have brought heavy artillery to pummel Glarus in fulfillment of a deceased client's trust. "
            "Glarus village is in their direct line of fire. How do you respond?";

        options.add({
          'title': 'A) "That\'s Glarus, right there."',
          'subtitle':
              'Effect: Destroy any one facility, advance a level for marksmen/cannoneer/artillery. (+10 Gnomes, +10 Glarus)',
          'onPress': () {
            if (progress.buildings.isNotEmpty) {
              final b = progress.buildings.removeAt(0);
              service.addLog(
                'Destroyed facility: ${b.type.displayName.toUpperCase()}',
              );
            }
            final targetTypes = ['marksmen', 'cannoneer', 'artillery_barrage'];
            for (var t in targetTypes) {
              if (progress.playerDeckIds.contains(t)) {
                final curLvl = progress.getUnitLevel(t);
                if (curLvl < 7) {
                  progress.cardUpgrades['level_$t'] = curLvl + 1;
                  progress.unitExp[t] = 0.0;
                  service.addLog('Promoted $t by 1 level.');
                }
              }
            }
            progress.factionStandings['Gnomes of Zurich'] =
                (progress.factionStandings['Gnomes of Zurich'] ?? 0) + 10;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) + 10;
            service.addLog('Satisfied client\'s trust at a minor loss.');
          },
        });
        options.add({
          'title':
              'B) "If that\'s your idea of a good time, you would love it here."',
          'subtitle':
              'Effect: Destroy Glarus village, receive advanced artillery barrage card. (-15 Gnomes, -20 Glarus)',
          'onPress': () {
            progress.villageHealth = 0;
            int totalLevels = 0;
            for (var t in progress.playerDeckIds) {
              totalLevels += progress.getUnitLevel(t);
            }
            final calcLvl = (1 + (totalLevels ~/ 6)).clamp(1, 6);
            progress.playerDeckIds.add('artillery_barrage');
            progress.cardUpgrades['level_artillery_barrage'] = calcLvl;
            progress.unitExp['artillery_barrage'] = 0.0;
            progress.factionStandings['Gnomes of Zurich'] =
                (progress.factionStandings['Gnomes of Zurich'] ?? 0) - 15;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) - 20;
            service.addLog(
              'Village destroyed. Reclaimed advanced artillery card (Lvl $calcLvl).',
            );
          },
        });
        options.add({
          'title': 'C) "That sounds like a great idea."',
          'subtitle':
              'Effect: Destroy village, receive tear gas grenade card & +500 CHF. (+15 Gnomes, -20 Glarus)',
          'onPress': () {
            progress.villageHealth = 0;
            progress.cash += 500;
            int totalLevels = 0;
            for (var t in progress.playerDeckIds) {
              totalLevels += progress.getUnitLevel(t);
            }
            final calcLvl = (1 + (totalLevels ~/ 6)).clamp(1, 6);
            progress.playerDeckIds.add('tear_gas_grenade');
            progress.cardUpgrades['level_tear_gas_grenade'] = calcLvl;
            progress.unitExp['tear_gas_grenade'] = 0.0;
            progress.factionStandings['Gnomes of Zurich'] =
                (progress.factionStandings['Gnomes of Zurich'] ?? 0) + 15;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) - 20;
            service.addLog(
              'Faced Glarus ruins. Looted +500 CHF & tear gas card.',
            );
          },
        });
        options.add({
          'title': 'D) "Over my dead body!"',
          'subtitle':
              'Effect: Triggers immediate combat with Gnomes Artillery guard. (-15 Gnomes, +15 Glarus)',
          'onPress': () {
            progress.factionStandings['Gnomes of Zurich'] =
                (progress.factionStandings['Gnomes of Zurich'] ?? 0) - 15;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) + 15;
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createCannoneer(),
                CombatUnitFactory.createCannoneer(),
                CombatUnitFactory.createWoodenTank(),
                CombatUnitFactory.createGoon(),
              ],
              eventTitle: title,
              spoilsFood: 25,
              spoilsCash: 350,
              spoilsIron: 15,
              spoilsWood: 40,
            );
            return;
          },
        });
        break;

      case 'freemasons_tribute':
        title = "THE GRAND ARCHITECT'S LODGE";
        faction = "Freemasons";
        story =
            "The Freemasons request permission to build a lodge on your estate plots. The Carbonari strongly protest, demanding it remain a public assembly area.";
        options.add({
          'title': 'A) "Build the Lodge."',
          'subtitle':
              'Cost: 150 Wood, 50 Iron. Reward: +300 CHF, +100 Wood. (+15 Freemasons, -15 Carbonari)',
          'checkAffordable': () => progress.wood >= 150 && progress.iron >= 50,
          'onPress': () {
            progress.wood -= 150;
            progress.wood += 100;
            progress.iron -= 50;
            progress.cash += 300;
            progress.factionStandings['Freemasons'] =
                (progress.factionStandings['Freemasons'] ?? 0) + 15;
            progress.factionStandings['Carbonari'] =
                (progress.factionStandings['Carbonari'] ?? 0) - 15;
            service.addLog('Lodges authorized. Mason trade channels opened.');
          },
        });
        options.add({
          'title': 'B) "Support the Carbonari assembly."',
          'subtitle': 'Reward: +20 Food. (-15 Freemasons, +15 Carbonari)',
          'onPress': () {
            progress.food += 20;
            progress.factionStandings['Freemasons'] =
                (progress.factionStandings['Freemasons'] ?? 0) - 15;
            progress.factionStandings['Carbonari'] =
                (progress.factionStandings['Carbonari'] ?? 0) + 15;
            service.addLog('Supported community assemblies.');
          },
        });
        options.add({
          'title': 'C) "Bribe both factions."',
          'subtitle': 'Cost: 200 CHF. (+5 Freemasons, +5 Carbonari)',
          'checkAffordable': () => progress.cash >= 200,
          'onPress': () {
            progress.cash -= 200;
            progress.factionStandings['Freemasons'] =
                (progress.factionStandings['Freemasons'] ?? 0) + 5;
            progress.factionStandings['Carbonari'] =
                (progress.factionStandings['Carbonari'] ?? 0) + 5;
            service.addLog('Greased palms to avoid conflict.');
          },
        });
        options.add({
          'title': 'D) "Clear them from my land!"',
          'subtitle':
              'Effect: Combat with Freemasons & Carbonari rioters. (-10 Masons, -10 Carbonari)',
          'onPress': () {
            progress.factionStandings['Freemasons'] =
                (progress.factionStandings['Freemasons'] ?? 0) - 10;
            progress.factionStandings['Carbonari'] =
                (progress.factionStandings['Carbonari'] ?? 0) - 10;
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createGoon(),
                CombatUnitFactory.createGoon(),
                CombatUnitFactory.createMilitia(),
              ],
              eventTitle: title,
              spoilsFood: 15,
              spoilsCash: 200,
              spoilsIron: 5,
              spoilsWood: 20,
            );
            return;
          },
        });
        break;

      case 'alchemist_transmutation':
        title = "THE TRANSMUTATION FORMULA";
        faction = "Rosicrucians";
        story =
            "A Rosicrucian alchemist offers to convert raw wood into solid iron, but the Golden Dawn claims this is a forbidden heresy.";
        options.add({
          'title': 'A) "Perform transmutation."',
          'subtitle':
              'Cost: 60 Wood. Reward: +30 Iron. (+15 Rosicrucians, -15 Golden Dawn)',
          'checkAffordable': () => progress.wood >= 60,
          'onPress': () {
            progress.wood -= 60;
            progress.iron += 30;
            progress.factionStandings['Rosicrucians'] =
                (progress.factionStandings['Rosicrucians'] ?? 0) + 15;
            progress.factionStandings['Golden Dawn'] =
                (progress.factionStandings['Golden Dawn'] ?? 0) - 15;
            service.addLog('Wood converted to Iron.');
          },
        });
        options.add({
          'title': 'B) "Exile the alchemist."',
          'subtitle':
              'Reward: +100 CHF bounty. (-15 Rosicrucians, +15 Golden Dawn)',
          'onPress': () {
            progress.cash += 100;
            progress.factionStandings['Rosicrucians'] =
                (progress.factionStandings['Rosicrucians'] ?? 0) - 15;
            progress.factionStandings['Golden Dawn'] =
                (progress.factionStandings['Golden Dawn'] ?? 0) + 15;
            service.addLog('Alchemist exiled.');
          },
        });
        options.add({
          'title': 'C) "Host collaborative study."',
          'subtitle':
              'Cost: 100 CHF. Reward: Receive Vampiric Totem card. (+10 Rosicrucians, +5 Golden Dawn)',
          'checkAffordable': () => progress.cash >= 100,
          'onPress': () {
            progress.cash -= 100;
            progress.playerDeckIds.add('vampiric_totem');
            progress.factionStandings['Rosicrucians'] =
                (progress.factionStandings['Rosicrucians'] ?? 0) + 10;
            progress.factionStandings['Golden Dawn'] =
                (progress.factionStandings['Golden Dawn'] ?? 0) + 5;
            service.addLog('Obtained Vampiric Totem.');
          },
        });
        options.add({
          'title': 'D) "Seize their secret laboratory!"',
          'subtitle':
              'Effect: Combat with Rosicrucian alchemical guards. (-15 Rosicrucians, -15 Golden Dawn)',
          'onPress': () {
            progress.factionStandings['Rosicrucians'] =
                (progress.factionStandings['Rosicrucians'] ?? 0) - 15;
            progress.factionStandings['Golden Dawn'] =
                (progress.factionStandings['Golden Dawn'] ?? 0) - 15;
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createFleshGolem(),
                CombatUnitFactory.createGoon(),
              ],
              eventTitle: title,
              spoilsFood: 10,
              spoilsCash: 150,
              spoilsIron: 35,
              spoilsWood: 10,
            );
            return;
          },
        });
        break;

      case 'templar_levy':
        title = "THE CRUSADER LEVY";
        faction = "Knights Templar";
        story =
            "The Knights Templar demand a crusade levy. The Rosicrucians suggest smuggling resources to hide them.";
        options.add({
          'title': 'A) "Pay the Crusade Levy."',
          'subtitle':
              'Cost: 200 CHF, 20 Iron. (+15 Knights Templar, -5 Rosicrucians)',
          'checkAffordable': () => progress.cash >= 200 && progress.iron >= 20,
          'onPress': () {
            progress.cash -= 200;
            progress.iron -= 20;
            progress.factionStandings['Knights Templar'] =
                (progress.factionStandings['Knights Templar'] ?? 0) + 15;
            progress.factionStandings['Rosicrucians'] =
                (progress.factionStandings['Rosicrucians'] ?? 0) - 5;
            service.addLog('Paid crusader tribute.');
          },
        });
        options.add({
          'title': 'B) "Smuggle resources."',
          'subtitle':
              'Cost: 20 Wood. Reward: +50 Food. (-15 Knights Templar, +15 Rosicrucians)',
          'checkAffordable': () => progress.wood >= 20,
          'onPress': () {
            progress.wood -= 20;
            progress.food += 50;
            progress.factionStandings['Knights Templar'] =
                (progress.factionStandings['Knights Templar'] ?? 0) - 15;
            progress.factionStandings['Rosicrucians'] =
                (progress.factionStandings['Rosicrucians'] ?? 0) + 15;
            service.addLog('Smuggled provisions.');
          },
        });
        options.add({
          'title':
              'C) "Offer shelter (Assign our most experienced unit as a guide)."',
          'subtitle':
              'Effect: Guided unit gains +150 XP. (+10 Templar, -5 Rosicrucians)',
          'onPress': () {
            if (progress.playerDeckIds.isNotEmpty) {
              String? bestCard;
              double maxExp = -1;
              for (final t in progress.playerDeckIds) {
                final xp = progress.unitExp[t] ?? 0.0;
                if (xp > maxExp) {
                  maxExp = xp;
                  bestCard = t;
                }
              }
              if (bestCard != null) {
                progress.addXpToUnit(bestCard, 150.0);
                service.addLog(
                  '$bestCard guided the Templars and gained +150 XP.',
                );
              }
            }
            progress.factionStandings['Knights Templar'] =
                (progress.factionStandings['Knights Templar'] ?? 0) + 10;
            progress.factionStandings['Rosicrucians'] =
                (progress.factionStandings['Rosicrucians'] ?? 0) - 5;
          },
        });
        options.add({
          'title': 'D) "We pay no taxes!"',
          'subtitle':
              'Effect: Combat with Templar crusaders. (-25 Knights Templar, +10 Iron, +100 CHF)',
          'onPress': () {
            progress.factionStandings['Knights Templar'] =
                (progress.factionStandings['Knights Templar'] ?? 0) - 25;
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createCavalry(),
                CombatUnitFactory.createPikemen(),
              ],
              eventTitle: title,
              spoilsFood: 15,
              spoilsCash: 250,
              spoilsIron: 15,
              spoilsWood: 10,
            );
            return;
          },
        });
        break;

      case 'carbonari_strike':
        title = "THE COALITION LABOUR STRIKE";
        faction = "Carbonari";
        story =
            "Carbonari radicals are instigating strike action among your workers. They demand double rations and pay.";
        options.add({
          'title': 'A) "Accede to rations and wage demands."',
          'subtitle': 'Cost: 40 Food, 100 CHF. (+15 Carbonari, +15 Army)',
          'checkAffordable': () => progress.food >= 40 && progress.cash >= 100,
          'onPress': () {
            progress.food -= 40;
            progress.cash -= 100;
            progress.factionStandings['Carbonari'] =
                (progress.factionStandings['Carbonari'] ?? 0) + 15;
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) + 15;
            service.addLog('Wages increased.');
          },
        });
        options.add({
          'title': 'B) "Compromise with bonus wages."',
          'subtitle': 'Cost: 150 CHF. (+10 Carbonari, +5 Army)',
          'checkAffordable': () => progress.cash >= 150,
          'onPress': () {
            progress.cash -= 150;
            progress.factionStandings['Carbonari'] =
                (progress.factionStandings['Carbonari'] ?? 0) + 10;
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) + 5;
            service.addLog('Wages compromised.');
          },
        });
        options.add({
          'title':
              'C) "Enforce martial law (Crackdown on strikes, but some desert)."',
          'subtitle':
              'Effect: A random non-leader unit deserts in protest. Next combat starting AP is increased by 3. (+15 Army, -25 Carbonari)',
          'onPress': () {
            if (progress.playerDeckIds.length > 1) {
              final eligible = progress.playerDeckIds
                  .where(
                    (id) => id != progress.selectedLeaderId && id != 'alphonse',
                  )
                  .toList();
              if (eligible.isNotEmpty) {
                final departed = eligible[Random().nextInt(eligible.length)];
                progress.playerDeckIds.remove(departed);
                service.addLog(
                  'Crackdown: $departed has deserted your army in protest!',
                );
              }
            }
            progress.cardUpgrades['next_combat_ap_modifier'] =
                (progress.cardUpgrades['next_combat_ap_modifier'] ?? 0) + 3;
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) + 15;
            progress.factionStandings['Carbonari'] =
                (progress.factionStandings['Carbonari'] ?? 0) - 25;
          },
        });
        options.add({
          'title': 'D) "Arrest the Carbonari leaders!"',
          'subtitle':
              'Effect: Combat with striking workers. (-25 Carbonari, -15 Army)',
          'onPress': () {
            progress.factionStandings['Carbonari'] =
                (progress.factionStandings['Carbonari'] ?? 0) - 25;
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) - 15;
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createGoon(),
                CombatUnitFactory.createMilitia(),
              ],
              eventTitle: title,
              spoilsFood: 10,
              spoilsCash: 120,
              spoilsIron: 5,
              spoilsWood: 15,
            );
            return;
          },
        });
        break;

      case 'golden_dawn_seance':
        title = "THE ELEUSINIAN SÉANCE";
        faction = "Golden Dawn";
        story =
            "The Golden Dawn wants to perform a séance in the estate cemetery. The Knights Templar demand you ban it.";
        options.add({
          'title': 'A) "Approve the Séance."',
          'subtitle':
              'Reward: Receive Werewolf card. (+15 Golden Dawn, -15 Knights Templar)',
          'onPress': () {
            progress.playerDeckIds.add('werewolf');
            progress.factionStandings['Golden Dawn'] =
                (progress.factionStandings['Golden Dawn'] ?? 0) + 15;
            progress.factionStandings['Knights Templar'] =
                (progress.factionStandings['Knights Templar'] ?? 0) - 15;
            service.addLog('Werewolf card acquired.');
          },
        });
        options.add({
          'title': 'B) "Ban the Séance."',
          'subtitle':
              'Reward: +50 CHF donation. (-15 Golden Dawn, +15 Knights Templar)',
          'onPress': () {
            progress.cash += 50;
            progress.factionStandings['Golden Dawn'] =
                (progress.factionStandings['Golden Dawn'] ?? 0) - 15;
            progress.factionStandings['Knights Templar'] =
                (progress.factionStandings['Knights Templar'] ?? 0) + 15;
            service.addLog('Séance prohibited.');
          },
        });
        options.add({
          'title': 'C) "Charge admission fee."',
          'subtitle': 'Reward: +200 CHF. (+5 Golden Dawn, -10 Knights Templar)',
          'onPress': () {
            progress.cash += 200;
            progress.factionStandings['Golden Dawn'] =
                (progress.factionStandings['Golden Dawn'] ?? 0) + 5;
            progress.factionStandings['Knights Templar'] =
                (progress.factionStandings['Knights Templar'] ?? 0) - 10;
            service.addLog('Charged admission.');
          },
        });
        options.add({
          'title': 'D) "Purge the cemetery!"',
          'subtitle':
              'Effect: Combat with Golden Dawn spirits. (-25 Golden Dawn, +20 Knights Templar)',
          'onPress': () {
            progress.factionStandings['Golden Dawn'] =
                (progress.factionStandings['Golden Dawn'] ?? 0) - 25;
            progress.factionStandings['Knights Templar'] =
                (progress.factionStandings['Knights Templar'] ?? 0) + 20;
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [CombatUnitFactory.createWerewolf()],
              eventTitle: title,
              spoilsFood: 5,
              spoilsCash: 180,
              spoilsIron: 10,
              spoilsWood: 10,
            );
            return;
          },
        });
        break;

      case 'fenian_gunrunning':
        title = "THE FENIAN GUN-RUNNING CONTRACT";
        faction = "Fenian Brotherhood";
        story =
            "The Fenian Brotherhood offers high-grade weapon packages. The Gnomes of Zurich demand an immediate tax audit.";
        options.add({
          'title': 'A) "Buy the weapon packages."',
          'subtitle':
              'Cost: 200 CHF. Reward: Receive Cannoneer card. (+15 Fenian, -10 Gnomes)',
          'checkAffordable': () => progress.cash >= 200,
          'onPress': () {
            progress.cash -= 200;
            progress.playerDeckIds.add('cannoneer');
            progress.factionStandings['Fenian Brotherhood'] =
                (progress.factionStandings['Fenian Brotherhood'] ?? 0) + 15;
            progress.factionStandings['Gnomes of Zurich'] =
                (progress.factionStandings['Gnomes of Zurich'] ?? 0) - 10;
            service.addLog('Cannoneer card acquired.');
          },
        });
        options.add({
          'title': 'B) "Report gun runners to Gnomes."',
          'subtitle': 'Reward: +100 CHF bounty. (-15 Fenian, +15 Gnomes)',
          'onPress': () {
            progress.cash += 100;
            progress.factionStandings['Fenian Brotherhood'] =
                (progress.factionStandings['Fenian Brotherhood'] ?? 0) - 15;
            progress.factionStandings['Gnomes of Zurich'] =
                (progress.factionStandings['Gnomes of Zurich'] ?? 0) + 15;
            service.addLog('Reported gun runners.');
          },
        });
        options.add({
          'title': 'C) "Facilitate backroom deal."',
          'subtitle':
              'Cost: 100 CHF. Reward: Receive Tear Gas Grenade card. (+10 Fenian, +10 Gnomes)',
          'checkAffordable': () => progress.cash >= 100,
          'onPress': () {
            progress.cash -= 100;
            progress.playerDeckIds.add('tear_gas_grenade');
            progress.factionStandings['Fenian Brotherhood'] =
                (progress.factionStandings['Fenian Brotherhood'] ?? 0) + 10;
            progress.factionStandings['Gnomes of Zurich'] =
                (progress.factionStandings['Gnomes of Zurich'] ?? 0) + 10;
            service.addLog('Obtained Tear Gas Grenade.');
          },
        });
        options.add({
          'title': 'D) "Seize the weapon caches!"',
          'subtitle':
              'Effect: Combat with Fenian gun runners. (-25 Fenian, +20 Iron)',
          'onPress': () {
            progress.factionStandings['Fenian Brotherhood'] =
                (progress.factionStandings['Fenian Brotherhood'] ?? 0) - 25;
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [CombatUnitFactory.createCommandos()],
              eventTitle: title,
              spoilsFood: 10,
              spoilsCash: 100,
              spoilsIron: 30,
              spoilsWood: 10,
            );
            return;
          },
        });
        break;

      case 'french_cavalry':
        title = "THE MONARCHIST MANEUVERS";
        faction = "Chevaliers de la foi";
        story =
            "Monarchist Chevaliers are destroying Glarus wheat crops with cavalry exercises. The Carbonari demand they leave.";
        options.add({
          'title': 'A) "Join their aristocratic drills."',
          'subtitle':
              'Reward: Receive Cavalry card. (+15 Chevaliers, -15 Glarus, -10 Carbonari)',
          'onPress': () {
            progress.playerDeckIds.add('cavalry');
            progress.factionStandings['Chevaliers de la foi'] =
                (progress.factionStandings['Chevaliers de la foi'] ?? 0) + 15;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) - 15;
            progress.factionStandings['Carbonari'] =
                (progress.factionStandings['Carbonari'] ?? 0) - 10;
            service.addLog('Joined Knight Cavalry.');
          },
        });
        options.add({
          'title': 'B) "Order them off the crops."',
          'subtitle':
              'Standings change: +15 Glarus, +10 Carbonari, -15 Chevaliers.',
          'onPress': () {
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) + 15;
            progress.factionStandings['Carbonari'] =
                (progress.factionStandings['Carbonari'] ?? 0) + 10;
            progress.factionStandings['Chevaliers de la foi'] =
                (progress.factionStandings['Chevaliers de la foi'] ?? 0) - 15;
            service.addLog('Ordered Chevaliers away.');
          },
        });
        options.add({
          'title': 'C) "Perform weapons drill collab."',
          'subtitle':
              'Effect: A random card receives a Weapon Upgrade, but training fatigue reduces next combat starting AP by 2. (+15 Chevaliers, -10 Carbonari)',
          'onPress': () {
            if (progress.playerDeckIds.isNotEmpty) {
              final target =
                  progress.playerDeckIds[Random().nextInt(
                    progress.playerDeckIds.length,
                  )];
              final currentIdx =
                  progress.cardUpgrades['${target}_equipped_weapon_idx'] ?? 0;
              progress.cardUpgrades['${target}_equipped_weapon_idx'] =
                  (currentIdx + 1).clamp(0, 3);
              service.addLog('Collab: $target received a weapon upgrade!');
            }
            progress.cardUpgrades['next_combat_ap_modifier'] =
                (progress.cardUpgrades['next_combat_ap_modifier'] ?? 0) - 2;
            progress.factionStandings['Chevaliers de la foi'] =
                (progress.factionStandings['Chevaliers de la foi'] ?? 0) + 15;
            progress.factionStandings['Carbonari'] =
                (progress.factionStandings['Carbonari'] ?? 0) - 10;
          },
        });
        options.add({
          'title': 'D) "Challenge them to mock combat."',
          'subtitle':
              'Effect: Combat with Chevaliers knights. (-20 Chevaliers, +15 Army)',
          'onPress': () {
            progress.factionStandings['Chevaliers de la foi'] =
                (progress.factionStandings['Chevaliers de la foi'] ?? 0) - 20;
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) + 15;
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createCavalry(),
                CombatUnitFactory.createCavalry(),
              ],
              eventTitle: title,
              spoilsFood: 20,
              spoilsCash: 220,
              spoilsIron: 10,
              spoilsWood: 10,
            );
            return;
          },
        });
        break;

      case 'adrenochrome_syndicate':
        title = "THE DEEP FOREST COVENANT";
        faction = "Ancient Order of Foresters";
        story =
            "The Foresters request a quiet lodge on your borders. Local rumors suggest they are running an illegal adrenochrome market.";
        options.add({
          'title': 'A) "Lease the land for their operations."',
          'subtitle': 'Reward: +400 CHF. (+20 Foresters, -25 Glarus)',
          'onPress': () {
            progress.cash += 400;
            progress.factionStandings['Ancient Order of Foresters'] =
                (progress.factionStandings['Ancient Order of Foresters'] ?? 0) +
                20;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) - 25;
            service.addLog('Leased lodge plots.');
          },
        });
        options.add({
          'title': 'B) "Reject their lease requests."',
          'subtitle': 'Reward: +20 Food. (+15 Glarus, -15 Foresters)',
          'onPress': () {
            progress.food += 20;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) + 15;
            progress.factionStandings['Ancient Order of Foresters'] =
                (progress.factionStandings['Ancient Order of Foresters'] ?? 0) -
                15;
            service.addLog('Lease requests rejected.');
          },
        });
        options.add({
          'title': 'C) "Quietly investigate the site."',
          'subtitle': 'Reward: Receive Vampiric Totem card. (-10 Foresters)',
          'onPress': () {
            progress.playerDeckIds.add('vampiric_totem');
            progress.factionStandings['Ancient Order of Foresters'] =
                (progress.factionStandings['Ancient Order of Foresters'] ?? 0) -
                10;
            service.addLog('Obtained Vampiric Totem.');
          },
        });
        options.add({
          'title': 'D) "Raid the secret Forester lab!"',
          'subtitle':
              'Effect: Combat with Forester druids & beasts. (-25 Foresters, +20 Glarus, +50 Food)',
          'onPress': () {
            progress.factionStandings['Ancient Order of Foresters'] =
                (progress.factionStandings['Ancient Order of Foresters'] ?? 0) -
                25;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) + 20;
            progress.food += 50;
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createFleshGolem(),
                CombatUnitFactory.createBrownRats(),
              ],
              eventTitle: title,
              spoilsFood: 40,
              spoilsCash: 100,
              spoilsIron: 5,
              spoilsWood: 15,
            );
            return;
          },
        });
        break;

      case 'bank_audit':
        title = "THE DEBT AUDIT FORECLOSURE";
        faction = "Gnomes of Zurich";
        story =
            "The Gnomes of Zurich seek to inspect Frankenstein Manor's accounts, backed by Freemasons wishing to foreclose on your estate.";
        options.add({
          'title': 'A) "Bribe the auditors."',
          'subtitle': 'Cost: 300 CHF. (+15 Gnomes, -10 Freemasons)',
          'checkAffordable': () => progress.cash >= 300,
          'onPress': () {
            progress.cash -= 300;
            progress.factionStandings['Gnomes of Zurich'] =
                (progress.factionStandings['Gnomes of Zurich'] ?? 0) + 15;
            progress.factionStandings['Freemasons'] =
                (progress.factionStandings['Freemasons'] ?? 0) - 10;
            service.addLog('Greased banking gears.');
          },
        });
        options.add({
          'title':
              'B) "Lock estate gates & hide resources (Guards are exhausted)."',
          'subtitle':
              'Effect: Protects resources. However, next combat units suffer a -15% movement speed penalty due to fatigue. (-10 Gnomes, -10 Freemasons)',
          'onPress': () {
            progress.cardUpgrades['next_combat_speed_reduction'] = 15;
            progress.factionStandings['Gnomes of Zurich'] =
                (progress.factionStandings['Gnomes of Zurich'] ?? 0) - 10;
            progress.factionStandings['Freemasons'] =
                (progress.factionStandings['Freemasons'] ?? 0) - 10;
            service.addLog(
              'Locked gates: units suffer 15% speed penalty in next combat.',
            );
          },
        });
        options.add({
          'title': 'C) "Route funds via Templar vaults."',
          'subtitle': 'Cost: 150 CHF. (+10 Knights Templar, -10 Gnomes)',
          'checkAffordable': () => progress.cash >= 150,
          'onPress': () {
            progress.cash -= 150;
            progress.factionStandings['Knights Templar'] =
                (progress.factionStandings['Knights Templar'] ?? 0) + 10;
            progress.factionStandings['Gnomes of Zurich'] =
                (progress.factionStandings['Gnomes of Zurich'] ?? 0) - 10;
            service.addLog('Funds rerouted.');
          },
        });
        options.add({
          'title': 'D) "Repel the bailiffs!"',
          'subtitle':
              'Effect: Combat with bank enforcers. (-25 Gnomes, -25 Freemasons)',
          'onPress': () {
            progress.factionStandings['Gnomes of Zurich'] =
                (progress.factionStandings['Gnomes of Zurich'] ?? 0) - 25;
            progress.factionStandings['Freemasons'] =
                (progress.factionStandings['Freemasons'] ?? 0) - 25;
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createGoon(),
                CombatUnitFactory.createGoon(),
              ],
              eventTitle: title,
              spoilsFood: 10,
              spoilsCash: 400,
              spoilsIron: 10,
              spoilsWood: 10,
            );
            return;
          },
        });
        break;

      case 'mystic_herbs':
        title = "THE DRUIDIC FOREST HERBS";
        faction = "Ancient Order of Foresters";
        story =
            "Druids offer ancient forest herbs to treat your mutated forces, but Rosicrucian mystical scholars claim they are deadly poisons.";
        options.add({
          'title': 'A) "Accept and feed herbs to constructs."',
          'subtitle':
              'Effect: Cure all construct bondage debuffs. (+15 Foresters, -10 Rosicrucians)',
          'onPress': () {
            progress.bondageDebuffCount.clear();
            progress.factionStandings['Ancient Order of Foresters'] =
                (progress.factionStandings['Ancient Order of Foresters'] ?? 0) +
                15;
            progress.factionStandings['Rosicrucians'] =
                (progress.factionStandings['Rosicrucians'] ?? 0) - 10;
            service.addLog('Construct bondage debuffs cleared.');
          },
        });
        options.add({
          'title': 'B) "Decline the herbs politely."',
          'subtitle': 'Reward: +50 Food. (+15 Rosicrucians, -10 Foresters)',
          'onPress': () {
            progress.food += 50;
            progress.factionStandings['Rosicrucians'] =
                (progress.factionStandings['Rosicrucians'] ?? 0) + 15;
            progress.factionStandings['Ancient Order of Foresters'] =
                (progress.factionStandings['Ancient Order of Foresters'] ?? 0) -
                10;
            service.addLog('Herbs declined.');
          },
        });
        options.add({
          'title': 'C) "Test herbs in laboratory."',
          'subtitle':
              'Cost: 50 CHF. Reward: +10 Iron. (+10 Rosicrucians, +5 Foresters)',
          'checkAffordable': () => progress.cash >= 50,
          'onPress': () {
            progress.cash -= 50;
            progress.iron += 10;
            progress.factionStandings['Rosicrucians'] =
                (progress.factionStandings['Rosicrucians'] ?? 0) + 10;
            progress.factionStandings['Ancient Order of Foresters'] =
                (progress.factionStandings['Ancient Order of Foresters'] ?? 0) +
                5;
            service.addLog('Herbs tested.');
          },
        });
        options.add({
          'title': 'D) "Burn the poisoned weeds!"',
          'subtitle':
              'Effect: Combat with rabid forest beasts. (-20 Foresters, +10 Rosicrucians)',
          'onPress': () {
            progress.factionStandings['Ancient Order of Foresters'] =
                (progress.factionStandings['Ancient Order of Foresters'] ?? 0) -
                20;
            progress.factionStandings['Rosicrucians'] =
                (progress.factionStandings['Rosicrucians'] ?? 0) + 10;
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [CombatUnitFactory.createWildWolves()],
              eventTitle: title,
              spoilsFood: 30,
              spoilsCash: 80,
              spoilsIron: 5,
              spoilsWood: 25,
            );
            return;
          },
        });
        break;

      case 'irish_mutiny':
        title = "THE BARRACKS AGITATION";
        faction = "Fenian Brotherhood";
        story =
            "Fenian agitators inside your barracks are encouraging soldiers to demand Irish Independence and whiskey rations.";
        options.add({
          'title': 'A) "Distribute whiskey and host feast."',
          'subtitle': 'Cost: 100 CHF, 20 Food. (+15 Army, +15 Fenian)',
          'checkAffordable': () => progress.cash >= 100 && progress.food >= 20,
          'onPress': () {
            progress.cash -= 100;
            progress.food -= 20;
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) + 15;
            progress.factionStandings['Fenian Brotherhood'] =
                (progress.factionStandings['Fenian Brotherhood'] ?? 0) + 15;
            service.addLog('Whiskey distributed.');
          },
        });
        options.add({
          'title': 'B) "Discipline the Fenian agitators."',
          'subtitle': 'Reward: +50 CHF bounty. (-10 Army, -15 Fenian)',
          'onPress': () {
            progress.cash += 50;
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) - 10;
            progress.factionStandings['Fenian Brotherhood'] =
                (progress.factionStandings['Fenian Brotherhood'] ?? 0) - 15;
            service.addLog('Agitators locked up.');
          },
        });
        options.add({
          'title': 'C) "Deploy soldiers to frontlines."',
          'subtitle':
              'Effect: Next combat gains +20% XP. (+10 Army, -10 Fenian)',
          'onPress': () {
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) + 10;
            progress.factionStandings['Fenian Brotherhood'] =
                (progress.factionStandings['Fenian Brotherhood'] ?? 0) - 10;
            progress.cardUpgrades['next_combat_xp_bonus'] = 1;
            service.addLog('Frontline orders issued.');
          },
        });
        options.add({
          'title': 'D) "Repress mutiny with armed guard!"',
          'subtitle':
              'Effect: Combat with rebel soldiers. (-20 Army, -25 Fenian)',
          'onPress': () {
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) - 20;
            progress.factionStandings['Fenian Brotherhood'] =
                (progress.factionStandings['Fenian Brotherhood'] ?? 0) - 25;
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createGoon(),
                CombatUnitFactory.createGoon(),
              ],
              eventTitle: title,
              spoilsFood: 10,
              spoilsCash: 120,
              spoilsIron: 10,
              spoilsWood: 10,
            );
            return;
          },
        });
        break;

      case 'monarchist_ball':
        title = "THE FRENCH ROYALIST BALL";
        faction = "Chevaliers de la foi";
        story =
            "Monarchists Chevaliers demand that the village of Glarus host a massive ball in your honor, tax-funding it directly from villagers.";
        options.add({
          'title': 'A) "Support the grand royalist ball."',
          'subtitle': 'Cost: 250 CHF. (+20 Chevaliers, -20 Glarus, +10 Army)',
          'checkAffordable': () => progress.cash >= 250,
          'onPress': () {
            progress.cash -= 250;
            progress.factionStandings['Chevaliers de la foi'] =
                (progress.factionStandings['Chevaliers de la foi'] ?? 0) + 20;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) - 20;
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) + 10;
            service.addLog('Aristocratic feast hosted.');
          },
        });
        options.add({
          'title': 'B) "Reject the royalist ball requests."',
          'subtitle': 'Standings change: +15 Glarus, -15 Chevaliers.',
          'onPress': () {
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) + 15;
            progress.factionStandings['Chevaliers de la foi'] =
                (progress.factionStandings['Chevaliers de la foi'] ?? 0) - 15;
            service.addLog('Royalist request denied.');
          },
        });
        options.add({
          'title': 'C) "Compromise with modest peasant feast."',
          'subtitle': 'Cost: 50 CHF, 30 Food. (+10 Glarus, +5 Chevaliers)',
          'checkAffordable': () => progress.cash >= 50 && progress.food >= 30,
          'onPress': () {
            progress.cash -= 50;
            progress.food -= 30;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) + 10;
            progress.factionStandings['Chevaliers de la foi'] =
                (progress.factionStandings['Chevaliers de la foi'] ?? 0) + 5;
            service.addLog('Peasant feast hosted.');
          },
        });
        options.add({
          'title': 'D) "Crash the royalist assembly!"',
          'subtitle':
              'Effect: Combat with Royal Guard. (-25 Chevaliers, +15 Carbonari)',
          'onPress': () {
            progress.factionStandings['Chevaliers de la foi'] =
                (progress.factionStandings['Chevaliers de la foi'] ?? 0) - 25;
            progress.factionStandings['Carbonari'] =
                (progress.factionStandings['Carbonari'] ?? 0) + 15;
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createCavalry(),
                CombatUnitFactory.createCavalry(),
              ],
              eventTitle: title,
              spoilsFood: 15,
              spoilsCash: 250,
              spoilsIron: 5,
              spoilsWood: 10,
            );
            return;
          },
        });
        break;

      case 'masonic_toll':
        title = "THE MASONIC BRIDGE TOLL";
        faction = "Freemasons";
        story =
            "Freemasons set up a commercial toll bridge blocking access to Glarus market routes. Villagers are starving.";
        options.add({
          'title': 'A) "Support and enforce the bridge toll."',
          'subtitle': 'Reward: +150 CHF. (+15 Freemasons, -20 Glarus)',
          'onPress': () {
            progress.cash += 150;
            progress.factionStandings['Freemasons'] =
                (progress.factionStandings['Freemasons'] ?? 0) + 15;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) - 20;
            service.addLog('Toll collection authorized.');
          },
        });
        options.add({
          'title': 'B) "Pay tolls for Glarus merchants."',
          'subtitle': 'Cost: 150 CHF. (+15 Glarus, +5 Freemasons)',
          'checkAffordable': () => progress.cash >= 150,
          'onPress': () {
            progress.cash -= 150;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) + 15;
            progress.factionStandings['Freemasons'] =
                (progress.factionStandings['Freemasons'] ?? 0) + 5;
            service.addLog('Merchant tolls sponsored.');
          },
        });
        options.add({
          'title': 'C) "Construct forest detour paths."',
          'subtitle': 'Cost: 100 Wood. (+10 Glarus, -10 Freemasons)',
          'checkAffordable': () => progress.wood >= 100,
          'onPress': () {
            progress.wood -= 100;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) + 10;
            progress.factionStandings['Freemasons'] =
                (progress.factionStandings['Freemasons'] ?? 0) - 10;
            service.addLog('Detour paths constructed.');
          },
        });
        options.add({
          'title': 'D) "Destroy the toll booth!"',
          'subtitle':
              'Effect: Combat with toll enforcers. (-25 Freemasons, +20 Glarus)',
          'onPress': () {
            progress.factionStandings['Freemasons'] =
                (progress.factionStandings['Freemasons'] ?? 0) - 25;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) + 20;
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createGoon(),
                CombatUnitFactory.createGoon(),
              ],
              eventTitle: title,
              spoilsFood: 15,
              spoilsCash: 120,
              spoilsIron: 10,
              spoilsWood: 15,
            );
            return;
          },
        });
        break;

      case 'alchemical_explosion':
        title = "THE CRYPT WATER CONTAMINATION";
        faction = "Rosicrucians";
        story =
            "A critical Rosicrucian lab failure has contaminated the water wells of Glarus village. Sickness is spreading.";
        options.add({
          'title': 'A) "Supply food and water filters."',
          'subtitle': 'Cost: 40 Food, 10 Iron. (+15 Glarus, +5 Rosicrucians)',
          'checkAffordable': () => progress.food >= 40 && progress.iron >= 10,
          'onPress': () {
            progress.food -= 40;
            progress.iron -= 10;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) + 15;
            progress.factionStandings['Rosicrucians'] =
                (progress.factionStandings['Rosicrucians'] ?? 0) + 5;
            service.addLog('Clean water supplied.');
          },
        });
        options.add({
          'title': 'B) "Conceal contamination logs."',
          'subtitle': 'Reward: +100 CHF. (+15 Rosicrucians, -20 Glarus)',
          'onPress': () {
            progress.cash += 100;
            progress.factionStandings['Rosicrucians'] =
                (progress.factionStandings['Rosicrucians'] ?? 0) + 15;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) - 20;
            service.addLog('Incident cover-up complete.');
          },
        });
        options.add({
          'title': 'C) "Flee the area temporarily."',
          'subtitle': 'Standings change: -15 Glarus, -10 Rosicrucians.',
          'onPress': () {
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) - 15;
            progress.factionStandings['Rosicrucians'] =
                (progress.factionStandings['Rosicrucians'] ?? 0) - 10;
            service.addLog('Fled the area.');
          },
        });
        options.add({
          'title': 'D) "Arrest the lead alchemist!"',
          'subtitle':
              'Effect: Combat with escaped lab monstrosities. (+15 Glarus, -25 Rosicrucians)',
          'onPress': () {
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) + 15;
            progress.factionStandings['Rosicrucians'] =
                (progress.factionStandings['Rosicrucians'] ?? 0) - 25;
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createFleshGolem(),
                CombatUnitFactory.createFleshGolem(),
              ],
              eventTitle: title,
              spoilsFood: 10,
              spoilsCash: 200,
              spoilsIron: 20,
              spoilsWood: 10,
            );
            return;
          },
        });
        break;

      case 'secret_treaty':
        title = "THE DEEP STATE ALLIANCE";
        faction = "Knights Templar";
        story =
            "The Knights Templar propose a joint defensive treaty, demanding total secrecy to keep Freemasons in the dark.";
        options.add({
          'title': 'A) "Ratify the secret alliance."',
          'subtitle': 'Reward: +15 Iron. (+20 Knights Templar, -15 Freemasons)',
          'onPress': () {
            progress.iron += 15;
            progress.factionStandings['Knights Templar'] =
                (progress.factionStandings['Knights Templar'] ?? 0) + 20;
            progress.factionStandings['Freemasons'] =
                (progress.factionStandings['Freemasons'] ?? 0) - 15;
            service.addLog('Alliance signed.');
          },
        });
        options.add({
          'title': 'B) "Report treaty details to Freemasons."',
          'subtitle': 'Reward: +200 CHF. (+20 Freemasons, -20 Knights Templar)',
          'onPress': () {
            progress.cash += 200;
            progress.factionStandings['Freemasons'] =
                (progress.factionStandings['Freemasons'] ?? 0) + 20;
            progress.factionStandings['Knights Templar'] =
                (progress.factionStandings['Knights Templar'] ?? 0) - 20;
            service.addLog('Alliance betrayed.');
          },
        });
        options.add({
          'title': 'C) "Decline both options politely."',
          'subtitle': 'Standings change: -5 Templar, -5 Freemasons.',
          'onPress': () {
            progress.factionStandings['Knights Templar'] =
                (progress.factionStandings['Knights Templar'] ?? 0) - 5;
            progress.factionStandings['Freemasons'] =
                (progress.factionStandings['Freemasons'] ?? 0) - 5;
            service.addLog('Remained neutral.');
          },
        });
        options.add({
          'title': 'D) "Arrest both diplomatic envoys!"',
          'subtitle':
              'Effect: Combat with guard details. (-20 Templar, -20 Freemasons)',
          'onPress': () {
            progress.factionStandings['Knights Templar'] =
                (progress.factionStandings['Knights Templar'] ?? 0) - 20;
            progress.factionStandings['Freemasons'] =
                (progress.factionStandings['Freemasons'] ?? 0) - 20;
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createCavalry(),
                CombatUnitFactory.createGoon(),
              ],
              eventTitle: title,
              spoilsFood: 10,
              spoilsCash: 250,
              spoilsIron: 10,
              spoilsWood: 10,
            );
            return;
          },
        });
        break;

      case 'carbonari_press':
        title = "THE REVOLUTIONARY PAMPHLETS";
        faction = "Carbonari";
        story =
            "The Carbonari seek estate wood to run their print press. The Golden Dawn warns these sheets cause spiritual madness.";
        options.add({
          'title': 'A) "Supply wood for print operations."',
          'subtitle':
              'Cost: 80 Wood. Reward: +50 CHF. (+20 Carbonari, -10 Golden Dawn)',
          'checkAffordable': () => progress.wood >= 80,
          'onPress': () {
            progress.wood -= 80;
            progress.cash += 50;
            progress.factionStandings['Carbonari'] =
                (progress.factionStandings['Carbonari'] ?? 0) + 20;
            progress.factionStandings['Golden Dawn'] =
                (progress.factionStandings['Golden Dawn'] ?? 0) - 10;
            service.addLog('Pamphlet wood supplied.');
          },
        });
        options.add({
          'title': 'B) "Seize the printing press."',
          'subtitle': 'Reward: +15 Iron. (+15 Golden Dawn, -20 Carbonari)',
          'onPress': () {
            progress.iron += 15;
            progress.factionStandings['Golden Dawn'] =
                (progress.factionStandings['Golden Dawn'] ?? 0) + 15;
            progress.factionStandings['Carbonari'] =
                (progress.factionStandings['Carbonari'] ?? 0) - 20;
            service.addLog('Printing press seized.');
          },
        });
        options.add({
          'title': 'C) "Tax printing operations."',
          'subtitle': 'Reward: +100 CHF. (+5 Carbonari, -5 Golden Dawn)',
          'onPress': () {
            progress.cash += 100;
            progress.factionStandings['Carbonari'] =
                (progress.factionStandings['Carbonari'] ?? 0) + 5;
            progress.factionStandings['Golden Dawn'] =
                (progress.factionStandings['Golden Dawn'] ?? 0) - 5;
            service.addLog('Taxes collected.');
          },
        });
        options.add({
          'title': 'D) "Raid the printing house!"',
          'subtitle':
              'Effect: Combat with Carbonari printing guards. (-25 Carbonari, +10 Golden Dawn)',
          'onPress': () {
            progress.factionStandings['Carbonari'] =
                (progress.factionStandings['Carbonari'] ?? 0) - 25;
            progress.factionStandings['Golden Dawn'] =
                (progress.factionStandings['Golden Dawn'] ?? 0) + 10;
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createGoon(),
                CombatUnitFactory.createGoon(),
              ],
              eventTitle: title,
              spoilsFood: 5,
              spoilsCash: 150,
              spoilsIron: 10,
              spoilsWood: 30,
            );
            return;
          },
        });
        break;

      case 'golden_dawn_relic':
        title = "THE ELEUSINIAN CRYPT RELIC";
        faction = "Golden Dawn";
        story =
            "The Golden Dawn uncovers a sacred relic on estate grounds and requests storage space in your vault rooms.";
        options.add({
          'title': 'A) "Accept and study the relic."',
          'subtitle':
              'Reward: Receive Vampiric Totem card. (+15 Golden Dawn, +10 Rosicrucians)',
          'onPress': () {
            progress.playerDeckIds.add('vampiric_totem');
            progress.factionStandings['Golden Dawn'] =
                (progress.factionStandings['Golden Dawn'] ?? 0) + 15;
            progress.factionStandings['Rosicrucians'] =
                (progress.factionStandings['Rosicrucians'] ?? 0) + 10;
            service.addLog('Stored Eleusinian Relic.');
          },
        });
        options.add({
          'title': 'B) "Sell relic to foreign dealers."',
          'subtitle': 'Reward: +350 CHF. (-15 Golden Dawn, -5 Rosicrucians)',
          'onPress': () {
            progress.cash += 350;
            progress.factionStandings['Golden Dawn'] =
                (progress.factionStandings['Golden Dawn'] ?? 0) - 15;
            progress.factionStandings['Rosicrucians'] =
                (progress.factionStandings['Rosicrucians'] ?? 0) - 5;
            service.addLog('Sold relic.');
          },
        });
        options.add({
          'title': 'C) "Donate relic to local cathedral."',
          'subtitle':
              'Standings change: +15 Knights Templar, -10 Golden Dawn, -5 Rosicrucians.',
          'onPress': () {
            progress.factionStandings['Knights Templar'] =
                (progress.factionStandings['Knights Templar'] ?? 0) + 15;
            progress.factionStandings['Golden Dawn'] =
                (progress.factionStandings['Golden Dawn'] ?? 0) - 10;
            progress.factionStandings['Rosicrucians'] =
                (progress.factionStandings['Rosicrucians'] ?? 0) - 5;
            service.addLog('Donated relic.');
          },
        });
        options.add({
          'title': 'D) "The relic is cursed: smash it!"',
          'subtitle':
              'Effect: Combat with spectral spirits. (-20 Golden Dawn, +5 Rosicrucians)',
          'onPress': () {
            progress.factionStandings['Golden Dawn'] =
                (progress.factionStandings['Golden Dawn'] ?? 0) - 20;
            progress.factionStandings['Rosicrucians'] =
                (progress.factionStandings['Rosicrucians'] ?? 0) + 5;
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [CombatUnitFactory.createWerewolf()],
              eventTitle: title,
              spoilsFood: 10,
              spoilsCash: 250,
              spoilsIron: 5,
              spoilsWood: 10,
            );
            return;
          },
        });
        break;

      case 'forester_woodcutters':
        title = "THE DRUIDIC TIMBER PROTEST";
        faction = "Ancient Order of Foresters";
        story =
            "The Foresters druidic council demands you cease all logging operations. The Army demands more timber for watchtower defense.";
        options.add({
          'title': 'A) "Cease all timber harvesting."',
          'subtitle':
              'Effect: Halve wood production next turn. (+20 Foresters, -15 Army)',
          'onPress': () {
            progress.factionStandings['Ancient Order of Foresters'] =
                (progress.factionStandings['Ancient Order of Foresters'] ?? 0) +
                20;
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) - 15;
            progress.cardUpgrades['wood_halved_next_turn'] = 1;
            service.addLog('Timber harvesting ceased.');
          },
        });
        options.add({
          'title': 'B) "Double logging quotas."',
          'subtitle': 'Reward: +150 Wood. (+15 Army, -25 Foresters)',
          'onPress': () {
            progress.wood += 150;
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) + 15;
            progress.factionStandings['Ancient Order of Foresters'] =
                (progress.factionStandings['Ancient Order of Foresters'] ?? 0) -
                25;
            service.addLog('Timber logging doubled.');
          },
        });
        options.add({
          'title': 'C) "Harvest timber selectively."',
          'subtitle':
              'Cost: 50 CHF. Reward: +40 Wood. (+10 Foresters, +5 Army)',
          'checkAffordable': () => progress.cash >= 50,
          'onPress': () {
            progress.cash -= 50;
            progress.wood += 40;
            progress.factionStandings['Ancient Order of Foresters'] =
                (progress.factionStandings['Ancient Order of Foresters'] ?? 0) +
                10;
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) + 5;
            service.addLog('Selective logging implemented.');
          },
        });
        options.add({
          'title': 'D) "Clear the wood druids!"',
          'subtitle':
              'Effect: Combat with forest druids. (-25 Foresters, +15 Army)',
          'onPress': () {
            progress.factionStandings['Ancient Order of Foresters'] =
                (progress.factionStandings['Ancient Order of Foresters'] ?? 0) -
                25;
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) + 15;
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createWerewolf(),
                CombatUnitFactory.createBrownRats(),
              ],
              eventTitle: title,
              spoilsFood: 20,
              spoilsCash: 120,
              spoilsIron: 5,
              spoilsWood: 150,
            );
            return;
          },
        });
        break;

      case 'swiss_banker_loan':
        title = "THE DEEP POCKETS CREDIT";
        faction = "Gnomes of Zurich";
        story =
            "The Swiss bankers offer an emergency line of credit. The Army wants to use it for imported brandy, but interest is steep.";
        options.add({
          'title': 'A) "Accept high-interest credit."',
          'subtitle':
              'Reward: +500 CHF, Army turn delay. (+15 Gnomes, +10 Army)',
          'onPress': () {
            progress.cash += 500;
            progress.factionStandings['Gnomes of Zurich'] =
                (progress.factionStandings['Gnomes of Zurich'] ?? 0) + 15;
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) + 10;
            progress.cardUpgrades['bank_debt_due_turn'] =
                progress.currentTurn + 3;
            service.addLog('Accepted emergency credit.');
          },
        });
        options.add({
          'title': 'B) "Decline credit offer."',
          'subtitle': 'Reward: +10 Food. (-5 Gnomes)',
          'onPress': () {
            progress.food += 10;
            progress.factionStandings['Gnomes of Zurich'] =
                (progress.factionStandings['Gnomes of Zurich'] ?? 0) - 5;
            service.addLog('Credit offer declined.');
          },
        });
        options.add({
          'title': 'C) "Borrow from soldier pension funds."',
          'subtitle': 'Reward: +200 CHF. (-20 Army)',
          'onPress': () {
            progress.cash += 200;
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) - 20;
            service.addLog('Borrowed from pensions.');
          },
        });
        options.add({
          'title': 'D) "Rob the banker\'s carriage!"',
          'subtitle':
              'Effect: Combat with Gnome bank guards. (-25 Gnomes, +20 Army, +400 CHF)',
          'onPress': () {
            progress.factionStandings['Gnomes of Zurich'] =
                (progress.factionStandings['Gnomes of Zurich'] ?? 0) - 25;
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) + 20;
            progress.cash += 400;
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createGoon(),
                CombatUnitFactory.createGoon(),
              ],
              eventTitle: title,
              spoilsFood: 15,
              spoilsCash: 400,
              spoilsIron: 5,
              spoilsWood: 10,
            );
            return;
          },
        });
        break;

      case 'grenadier_sabotage':
        title = "THE GRENADIER WINDMILL ACCIDENT";
        faction = "Player's Army";
        story =
            "Drunk Army grenadiers have accidentally blown up the central windmill of Glarus. The villagers demand restitution.";
        options.add({
          'title': 'A) "Pay full damages to Glarus."',
          'subtitle': 'Cost: 200 CHF, 30 Wood. (+20 Glarus, -10 Army)',
          'checkAffordable': () => progress.cash >= 200 && progress.wood >= 30,
          'onPress': () {
            progress.cash -= 200;
            progress.wood -= 30;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) + 20;
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) - 10;
            service.addLog('Paid windmill restitution.');
          },
        });
        options.add({
          'title': 'B) "Court-martial the grenadiers."',
          'subtitle': 'Standings change: +15 Glarus, -20 Army.',
          'onPress': () {
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) + 15;
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) - 20;
            service.addLog('Agitators disciplined.');
          },
        });
        options.add({
          'title': 'C) "Blame the wind cycles."',
          'subtitle': 'Standings change: +15 Army, -20 Glarus.',
          'onPress': () {
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) + 15;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) - 20;
            service.addLog('Blamed wind cycles.');
          },
        });
        options.add({
          'title': 'D) "Repel the complaining villagers!"',
          'subtitle':
              'Effect: Combat with angry villagers. (-25 Glarus, +10 Army)',
          'onPress': () {
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) - 25;
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) + 10;
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [CombatUnitFactory.createGoon()],
              eventTitle: title,
              spoilsFood: 10,
              spoilsCash: 50,
              spoilsIron: 5,
              spoilsWood: 15,
            );
            return;
          },
        });
        break;

      // =======================================================================
      // FACTION STORY ARCS: GLARUS PEASANTS
      // =======================================================================
      case 'Glarus_positive_step1':
        title = "THE CANTON DEFENSE INITIATIVE";
        faction = "Glarus Peasants";
        story = "Your high reputation with the Canton has inspired local representatives. They offer a formal alliance and ask you to lead the valley's joint defense council. To seal the pact, they request 200 Wood to fortify outer borders.";
        options.add({
          'title': 'A) "Pledge our leadership and supply 200 Wood."',
          'subtitle': 'Effect: Form Canton Alliance, deduct 200 Wood, gain +10 Glarus standing.',
          'checkAffordable': () => progress.wood >= 200,
          'onPress': () {
            progress.wood -= 200;
            progress.factionStandings['Glarus'] = (progress.factionStandings['Glarus'] ?? 0) + 10;
            service.addLog('Formed Canton Alliance. Supplied 200 Wood.');
          },
        });
        options.add({
          'title': 'B) "Declined. Our resources are for the Manor alone."',
          'subtitle': 'Effect: Relieve Glarus leadership role. No resource cost.',
          'onPress': () {
            service.addLog('Declined Glarus joint defense invitation.');
          },
        });
        break;

      case 'Glarus_positive_step2':
        title = "THE PASSES OF GLARUS";
        faction = "Glarus Peasants";
        story = "Our alliance flourishes! However, aggressive rogue bands have occupied the mountain passes, threatening all trade. The Canton begs for 300 CHF and 50 Iron to arm their local volunteer patrols.";
        options.add({
          'title': 'A) "Equip the patrols with 300 CHF and 50 Iron."',
          'subtitle': 'Effect: Canton patrols armed, deduct 300 CHF & 50 Iron, gain +15 Glarus standing.',
          'checkAffordable': () => progress.cash >= 300 && progress.iron >= 50,
          'onPress': () {
            progress.cash -= 300;
            progress.iron -= 50;
            progress.factionStandings['Glarus'] = (progress.factionStandings['Glarus'] ?? 0) + 15;
            service.addLog('Equipped Canton patrols, clearing mountain passes.');
          },
        });
        options.add({
          'title': 'B) "We cannot spare the cash or iron. Stand down."',
          'subtitle': 'Effect: Lose -5 Glarus standing as trade corridors suffer.',
          'onPress': () {
            progress.factionStandings['Glarus'] = (progress.factionStandings['Glarus'] ?? 0) - 5;
            service.addLog('Refused to fund Canton patrols.');
          },
        });
        break;

      case 'Glarus_positive_step3':
        title = "SOVEREIGN PROTECTOR OF THE CANTON";
        faction = "Glarus Peasants";
        story = "The Canton Council stands in awe of your leadership! In a grand assembly, Jacob Landolt presents you with a sovereign decree: you are elected the Sovereign Protector of Glarus! They offer you a key to a new estate sector and command of their finest troops.";
        options.add({
          'title': 'A) "Accept the Crown and merge Glarus under our banner!"',
          'subtitle': 'Effect: Unlocks new Estate Plot E for free and receive the elite Militia Leader card!',
          'onPress': () {
            if (!progress.purchasedPlots.contains('plot_e')) {
              progress.purchasedPlots.add('plot_e');
            }
            progress.playerDeckIds.add('militia');
            progress.factionStandings['Glarus'] = (progress.factionStandings['Glarus'] ?? 0) + 20;
            service.addLog('Crowned Sovereign Protector of Glarus! Unlocked Plot E and recruited Militia Leader.');
          },
        });
        options.add({
          'title': 'B) "Decline the crown but sign a heavy trade treaty."',
          'subtitle': 'Effect: Gain +800 CHF immediately and +10 Glarus standing.',
          'onPress': () {
            progress.cash += 800;
            progress.factionStandings['Glarus'] = (progress.factionStandings['Glarus'] ?? 0) + 10;
            service.addLog('Declined sovereign crown. Signed Glarus trade treaty.');
          },
        });
        break;

      case 'Glarus_negative_step1':
        title = "THE ANGRY MOB OUTSIDE";
        faction = "Glarus Rebels";
        story = "Your extreme hostility with the local population has ignited a crisis! A massive, angry mob of Glarus peasants stands outside the Manor gates, throwing stones and demanding 200 Food to feed their starving families.";
        options.add({
          'title': 'A) "Hand over 200 Food to appease the mob."',
          'subtitle': 'Effect: Deduct 200 Food, mob disperses. Gain +5 Glarus standing.',
          'checkAffordable': () => progress.food >= 200,
          'onPress': () {
            progress.food -= 200;
            progress.factionStandings['Glarus'] = (progress.factionStandings['Glarus'] ?? 0) + 5;
            service.addLog('Appeased the peasant mob with food reserves.');
          },
        });
        options.add({
          'title': 'B) "Order guards to disperse them with force!"',
          'subtitle': 'Effect: Mob driven off. Lose -10 Glarus standing. Tensions escalate.',
          'onPress': () {
            progress.factionStandings['Glarus'] = (progress.factionStandings['Glarus'] ?? 0) - 10;
            service.addLog('Dispersed peasant mob with force.');
          },
        });
        break;

      case 'Glarus_negative_step2':
        title = "SABOTAGE IN THE FOREST";
        faction = "Glarus Rebels";
        story = "Peasant saboteurs have struck in the dark! Your lumber mill and outer timber supplies have been set on fire, halting all operations. The arsonists stand armed in the woods.";
        options.add({
          'title': 'A) "Pay 300 CHF to hire professional mercenary guards."',
          'subtitle': 'Effect: Mill secured and repaired. Deduct 300 CHF.',
          'checkAffordable': () => progress.cash >= 300,
          'onPress': () {
            progress.cash -= 300;
            service.addLog('Hired mercenaries to secure the logging camps.');
          },
        });
        options.add({
          'title': 'B) "Confront the rebel saboteurs in open combat!"',
          'subtitle': 'Effect: Immediate battle with Glarus peasant rebels. No cash cost.',
          'onPress': () {
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createGoon(),
                CombatUnitFactory.createGoon(),
                CombatUnitFactory.createMilitia(),
              ],
              eventTitle: title,
              spoilsFood: 15,
              spoilsCash: 120,
              spoilsIron: 5,
              spoilsWood: 30,
            );
            return;
          },
        });
        break;

      case 'Glarus_negative_step3':
        title = "THE GREAT SWISS PEASANT REBELLION";
        faction = "Glarus Rebels";
        story = "A full-scale armed rebellion of thousands of peasants has surrounded the Manor, determined to seize back your land. They demand that you sign a charter surrendering the outer farm fields.";
        options.add({
          'title': 'A) "Surrender the fields to save the Manor."',
          'subtitle': 'Effect: Plot C is PERMANENTLY locked and its building demolished! Standing set to -10.',
          'onPress': () {
            progress.cardUpgrades['plot_c_permanently_locked'] = 1;
            progress.buildings.removeWhere((b) => b.id == 'plot_c');
            progress.factionStandings['Glarus'] = -10;
            service.addLog('CONSEQUENCE: Surrendered the outer fields. Plot C is permanently locked and building demolished.');
          },
        });
        options.add({
          'title': 'B) "Crush the rebellion once and for all!"',
          'subtitle': 'Effect: Massive combat battle against elite peasant forces! High risk of defeat.',
          'onPress': () {
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createCavalry(),
                CombatUnitFactory.createPikemen(),
                CombatUnitFactory.createMusketeers(),
              ],
              eventTitle: title,
              spoilsFood: 25,
              spoilsCash: 350,
              spoilsIron: 15,
              spoilsWood: 40,
            );
            return;
          },
        });
        break;

      // =======================================================================
      // FACTION STORY ARCS: GNOMES OF ZURICH
      // =======================================================================
      case 'Gnomes of Zurich_positive_step1':
        title = "THE ZURICH CO-INVESTMENT";
        faction = "Gnomes of Zurich";
        story = "Your stellar financial standing has earned you an invitation to participate in a high-grade smuggling and speculative silver cargo scheme with the Swiss banking cartel. They request 400 CHF to fund the carriage.";
        options.add({
          'title': 'A) "Invest 400 CHF in the silver cargo scheme."',
          'subtitle': 'Effect: Deduct 400 CHF, gain +10 Gnomes standing.',
          'checkAffordable': () => progress.cash >= 400,
          'onPress': () {
            progress.cash -= 400;
            progress.factionStandings['Gnomes of Zurich'] = (progress.factionStandings['Gnomes of Zurich'] ?? 0) + 10;
            service.addLog('Invested 400 CHF in Gnomes cargo scheme.');
          },
        });
        options.add({
          'title': 'B) "Decline. We do not engage in speculative trade."',
          'subtitle': 'Effect: No cost, standing remains unchanged.',
          'onPress': () {
            service.addLog('Declined Gnomes cargo scheme invitation.');
          },
        });
        break;

      case 'Gnomes of Zurich_positive_step2':
        title = "THE BRIBED CUSTOMS AGENT";
        faction = "Gnomes of Zurich";
        story = "The silver carriage has reached the border, but a stubborn customs agent refuses passage unless a massive bribe is paid, or you use your immense credit to bypass him.";
        options.add({
          'title': 'A) "Pay 250 CHF to bribe the customs agent."',
          'subtitle': 'Effect: Smuggling succeeds, deduct 250 CHF, gain +10 Gnomes standing.',
          'checkAffordable': () => progress.cash >= 250,
          'onPress': () {
            progress.cash -= 250;
            progress.factionStandings['Gnomes of Zurich'] = (progress.factionStandings['Gnomes of Zurich'] ?? 0) + 10;
            service.addLog('Bribed customs agent to secure silver carriage passage.');
          },
        });
        options.add({
          'title': 'B) "Bypass him using our high standing."',
          'subtitle': 'Effect: Requires Gnomes standing >= 22. Gain +15 Gnomes standing.',
          'checkAffordable': () => (progress.factionStandings['Gnomes of Zurich'] ?? 0) >= 22,
          'onPress': () {
            progress.factionStandings['Gnomes of Zurich'] = (progress.factionStandings['Gnomes of Zurich'] ?? 0) + 15;
            service.addLog('Used immense financial standing to bypass customs.');
          },
        });
        break;

      case 'Gnomes of Zurich_positive_step3':
        title = "THE SYNDICATE PARTNERSHIP";
        faction = "Gnomes of Zurich";
        story = "The silver carriage was a colossal triumph! Regina von Stauffacher welcomes you as a Grand Syndicate Partner. They offer you their ultimate defense asset and a direct share of the bank's dividends.";
        options.add({
          'title': 'A) "Accept the Grand Syndicate Seat."',
          'subtitle': 'Effect: Receive the elite Gatling Gun card and +50% PERMANENT cash income from all sources!',
          'onPress': () {
            progress.playerDeckIds.add('gatling_gun');
            progress.cardUpgrades['gnomes_syndicate_active'] = 1;
            progress.factionStandings['Gnomes of Zurich'] = (progress.factionStandings['Gnomes of Zurich'] ?? 0) + 20;
            service.addLog('Became Grand Syndicate Partner! Recruited Gatling Gun and unlocked +50% passive cash multiplier.');
          },
        });
        options.add({
          'title': 'B) "Take a massive lump sum cash payout of 1500 CHF."',
          'subtitle': 'Effect: Gain +1500 CHF immediately.',
          'onPress': () {
            progress.cash += 1500;
            service.addLog('Claimed 1500 CHF lump sum payout from the Gnomes.');
          },
        });
        break;

      case 'Gnomes of Zurich_negative_step1':
        title = "THE CREDITOR'S WARNING";
        faction = "Gnomes of Zurich";
        story = "Your hostile standing has prompted the bank to freeze your credit lines. Armed collectors stand at the Manor gate, demanding immediate payment of 300 CHF in 'outstanding interest penalties'.";
        options.add({
          'title': 'A) "Pay the 300 CHF interest penalty."',
          'subtitle': 'Effect: Penalty paid, deduct 300 CHF. Gain +5 Gnomes standing.',
          'checkAffordable': () => progress.cash >= 300,
          'onPress': () {
            progress.cash -= 300;
            progress.factionStandings['Gnomes of Zurich'] = (progress.factionStandings['Gnomes of Zurich'] ?? 0) + 5;
            service.addLog('Paid outstanding bank interest penalty.');
          },
        });
        options.add({
          'title': 'B) "Tell them to leave, or face our steel!"',
          'subtitle': 'Effect: Collectors driven off, lose -10 Gnomes standing. Tensions escalate.',
          'onPress': () {
            progress.factionStandings['Gnomes of Zurich'] = (progress.factionStandings['Gnomes of Zurich'] ?? 0) - 10;
            service.addLog('Threatened bank debt collectors. Credit frozen.');
          },
        });
        break;

      case 'Gnomes of Zurich_negative_step2':
        title = "CARAVAN EMBARGO & AMBUSH";
        faction = "Gnomes of Zurich";
        story = "The Gnomes have retaliated! Armed mercenary collectors have ambushed one of your supply caravans, seizing all resource carriage routes.";
        options.add({
          'title': 'A) "Pay a heavy penalty fee of 500 CHF to lift the embargo."',
          'subtitle': 'Effect: Caravan routes cleared. Deduct 500 CHF.',
          'checkAffordable': () => progress.cash >= 500,
          'onPress': () {
            progress.cash -= 500;
            service.addLog('Paid Gnomes penalty fee to clear trade corridors.');
          },
        });
        options.add({
          'title': 'B) "Fight the debt collectors in open skirmish!"',
          'subtitle': 'Effect: Immediate combat against Zurich guard forces. No cash cost.',
          'onPress': () {
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createCavalry(),
                CombatUnitFactory.createCavalry(),
                CombatUnitFactory.createGoon(),
              ],
              eventTitle: title,
              spoilsFood: 10,
              spoilsCash: 200,
              spoilsIron: 20,
              spoilsWood: 10,
            );
            return;
          },
        });
        break;

      case 'Gnomes of Zurich_negative_step3':
        title = "THE SYNDICATE FORECLOSURE";
        faction = "Gnomes of Zurich";
        story = "The Gnomes have executed a foreclosure decree! A heavily armed private military force has arrived to seize your estate assets and recover unpaid debts.";
        options.add({
          'title': 'A) "Submit to foreclosure and pay 600 CHF."',
          'subtitle': 'Effect: Deduct 600 CHF and suffer a permanent -30% cash penalty on all future income!',
          'checkAffordable': () => progress.cash >= 600,
          'onPress': () {
            progress.cash -= 600;
            progress.cardUpgrades['gnomes_foreclosure_penalty'] = 1;
            progress.factionStandings['Gnomes of Zurich'] = -10;
            service.addLog('CONSEQUENCE: Foreclosure active. Suffer -30% permanent cash penalty on all future income.');
          },
        });
        options.add({
          'title': 'B) "Burn their ledgers in open war!"',
          'subtitle': 'Effect: High-difficulty combat against elite commandos! High risk of defeat.',
          'onPress': () {
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createCommandos(),
                CombatUnitFactory.createCommandos(),
                CombatUnitFactory.createCavalry(),
              ],
              eventTitle: title,
              spoilsFood: 15,
              spoilsCash: 500,
              spoilsIron: 30,
              spoilsWood: 20,
            );
            return;
          },
        });
        break;

      // =======================================================================
      // FACTION STORY ARCS: BAVARIAN ILLUMINATI
      // =======================================================================
      case 'Bavarian Illuminati_positive_step1':
        title = "THE LODGE OF LIGHT";
        faction = "Bavarian Illuminati";
        story = "Professor Fritz Weishaupt invites you to join the secret Outer Circle. To construct their technological lodge in the valley, they request 150 Wood and 100 Iron.";
        options.add({
          'title': 'A) "Pledge resources to the Lodge of Light."',
          'subtitle': 'Effect: Join Lodge, deduct 150 Wood & 100 Iron, gain +10 Illuminati standing.',
          'checkAffordable': () => progress.wood >= 150 && progress.iron >= 100,
          'onPress': () {
            progress.wood -= 150;
            progress.iron -= 100;
            progress.factionStandings['Bavarian Illuminati'] = (progress.factionStandings['Bavarian Illuminati'] ?? 0) + 10;
            service.addLog('Joined Lodge of Light. Supplied construction materials.');
          },
        });
        options.add({
          'title': 'B) "We keep our timber and iron. Decline."',
          'subtitle': 'Effect: Refuse invitation. Standing remains unchanged.',
          'onPress': () {
            service.addLog('Declined Illuminati Lodge invitation.');
          },
        });
        break;

      case 'Bavarian Illuminati_positive_step2':
        title = "THE REFUGEE INVENTOR";
        faction = "Bavarian Illuminati";
        story = "A brilliant renegade cybernetic scientist is fleeing Church persecution and begs for sanctuary at the Manor. Fritz offers 300 CHF to fund his research laboratory.";
        options.add({
          'title': 'A) "Shelter and fund the scientist for 300 CHF."',
          'subtitle': 'Effect: Sponsor research, deduct 300 CHF, gain +15 Illuminati standing.',
          'checkAffordable': () => progress.cash >= 300,
          'onPress': () {
            progress.cash -= 300;
            progress.factionStandings['Bavarian Illuminati'] = (progress.factionStandings['Bavarian Illuminati'] ?? 0) + 15;
            service.addLog('Sheltered cybernetic scientist. Sponsored advanced research.');
          },
        });
        options.add({
          'title': 'B) "Turn him away. We do not harbor heretics."',
          'subtitle': 'Effect: Gain +5 Templar standing, lose -5 Glarus standing.',
          'onPress': () {
            progress.factionStandings['Knights Templar'] = (progress.factionStandings['Knights Templar'] ?? 0) + 5;
            progress.factionStandings['Glarus'] = (progress.factionStandings['Glarus'] ?? 0) - 5;
            service.addLog('Refused scientist sanctuary to appease the Templars.');
          },
        });
        break;

      case 'Bavarian Illuminati_positive_step3':
        title = "THE SCIENTIFIC RENAISSANCE";
        faction = "Bavarian Illuminati";
        story = "The sponsored research is complete! The Bavarian Illuminati welcome you to their Inner Circle, gifting you a self-operating prototype automaton and an Advanced Laboratory blueprint.";
        options.add({
          'title': 'A) "Induct the Automaton and blueprints!"',
          'subtitle': 'Effect: Receive the elite Steampunk Robot card and unlock a free Advanced Laboratory on the estate!',
          'onPress': () {
            progress.playerDeckIds.add('steampunk_robot');
            final nextId = 'plot_' + String.fromCharCode(97 + progress.buildings.length);
            if (!progress.purchasedPlots.contains(nextId) && progress.buildings.length < 6) {
              progress.purchasedPlots.add(nextId);
              progress.buildings.add(SurvivalBuilding(id: nextId, type: SurvivalBuildingType.mine, level: 3, assignedUnitIds: []));
            }
            progress.factionStandings['Bavarian Illuminati'] = (progress.factionStandings['Bavarian Illuminati'] ?? 0) + 20;
            service.addLog('Inducted Inner Circle! Recruited Steampunk Robot and constructed Advanced Facility.');
          },
        });
        options.add({
          'title': 'B) "Accept a technological cash grant of 1000 CHF."',
          'subtitle': 'Effect: Gain +1000 CHF immediately.',
          'onPress': () {
            progress.cash += 1000;
            service.addLog('Claimed 1000 CHF Illuminati research grant.');
          },
        });
        break;

      case 'Bavarian Illuminati_negative_step1':
        title = "THE SHADOW SPY";
        faction = "Bavarian Illuminati";
        story = "Your servants have caught a shadowy Bavarian Illuminati spy in your study attempting to copy your alchemical blueprints!";
        options.add({
          'title': 'A) "Release him to avoid a shadow war."',
          'subtitle': 'Effect: Spy released. Gain +5 Illuminati standing.',
          'onPress': () {
            progress.factionStandings['Bavarian Illuminati'] = (progress.factionStandings['Bavarian Illuminati'] ?? 0) + 5;
            service.addLog('Released captured Illuminati spy to de-escalate.');
          },
        });
        options.add({
          'title': 'B) "Imprison and interrogate him!"',
          'subtitle': 'Effect: Spy interrogated, lose -10 Illuminati standing. Shadow war begins.',
          'onPress': () {
            progress.factionStandings['Bavarian Illuminati'] = (progress.factionStandings['Bavarian Illuminati'] ?? 0) - 10;
            service.addLog('Imprisoned spy. Blueprint secrets secured.');
          },
        });
        break;

      case 'Bavarian Illuminati_negative_step2':
        title = "THE CHEMICAL SABOTAGE";
        faction = "Bavarian Illuminati";
        story = "The shadow war has struck home! An Illuminati infiltrator has introduced a chemical toxin into your Manor, infecting your humanoid troops and corrupting your archives.";
        options.add({
          'title': 'A) "Pay 400 CHF on alchemical neutralizers to purge the toxin."',
          'subtitle': 'Effect: Toxin purged, deduct 400 CHF.',
          'checkAffordable': () => progress.cash >= 400,
          'onPress': () {
            progress.cash -= 400;
            service.addLog('Purged toxic contamination from barracks.');
          },
        });
        options.add({
          'title': 'B) "Isolate the wing and accept the permanent loss."',
          'subtitle': 'Effect: Permanent -10% attack speed penalty to all humanoid units due to toxin exposure!',
          'onPress': () {
            progress.cardUpgrades['illuminati_toxin_penalty'] = 1;
            service.addLog('CONSEQUENCE: Barracks contaminated. Humanoid attack speed permanently reduced by 10%.');
          },
        });
        break;

      case 'Bavarian Illuminati_negative_step3':
        title = "THE NEURAL MEMORY WIPE";
        faction = "Bavarian Illuminati";
        story = "An elite Illuminati assassination squad has bypassed your guards, cornering you in your study. They demand you submit to a neural memory-wipe serum to erase all alchemical secrets.";
        options.add({
          'title': 'A) "Submit to the memory wipe to save your life."',
          'subtitle': 'Effect: Your highest-level combat card is reset back to Level 1!',
          'onPress': () {
            String highestCard = 'peasant';
            int maxLvl = -1;
            for (var t in progress.playerDeckIds) {
              final lvl = progress.getUnitLevel(t);
              if (lvl > maxLvl) {
                maxLvl = lvl;
                highestCard = t;
              }
            }
            progress.cardUpgrades['level_$highestCard'] = 1;
            progress.cardUpgrades['${highestCard}_xp'] = 0;
            progress.factionStandings['Bavarian Illuminati'] = -10;
            service.addLog('CONSEQUENCE: Neural memory wipe reset ${highestCard.toUpperCase()} back to Level 1.');
          },
        });
        options.add({
          'title': 'B) "Fight the assassins!"',
          'subtitle': 'Effect: High-difficulty combat against cybernetic soldiers and a Steampunk Robot!',
          'onPress': () {
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createCommandos(),
                CombatUnitFactory.createCommandos(),
                CombatUnitFactory.createSteampunkRobot(),
              ],
              eventTitle: title,
              spoilsFood: 10,
              spoilsCash: 400,
              spoilsIron: 25,
              spoilsWood: 15,
            );
            return;
          },
        });
        break;

      // =======================================================================
      // FACTION STORY ARCS: ROSICRUCIANS
      // =======================================================================
      case 'Rosicrucians_positive_step1':
        title = "THE LEADING SPIRIT";
        faction = "Rosicrucians";
        story = "Johannes the Hermit believes your Manor lies directly on a powerful alchemical leyline node. He requests 200 Wood and 100 Food to construct a sacred alchemical circle to tap the cosmic power.";
        options.add({
          'title': 'A) "Donate 200 Wood and 100 Food to tap the leyline."',
          'subtitle': 'Effect: Build Leyline Circle, deduct 200 Wood & 100 Food, gain +10 Rosicrucian standing.',
          'checkAffordable': () => progress.wood >= 200 && progress.food >= 100,
          'onPress': () {
            progress.wood -= 200;
            progress.food -= 100;
            progress.factionStandings['Rosicrucians'] = (progress.factionStandings['Rosicrucians'] ?? 0) + 10;
            service.addLog('Constructed alchemical leyline circle on the estate.');
          },
        });
        options.add({
          'title': 'B) "Refuse. Occult circles have no place here."',
          'subtitle': 'Effect: Decline request, standing remains unchanged.',
          'onPress': () {
            service.addLog('Declined Rosicrucian leyline circle proposal.');
          },
        });
        break;

      case 'Rosicrucians_positive_step2':
        title = "THE COSMIC CHANNEL";
        faction = "Rosicrucians";
        story = "The leyline circle is active, but it requires a human mind to act as the spiritual leyline anchor. The process is exhausting and will temporarily weaken your leader.";
        options.add({
          'title': 'A) "Volunteer our leader to anchor the leyline."',
          'subtitle': 'Effect: Leader anchors leyline, gain +15 Rosicrucian standing.',
          'onPress': () {
            progress.cardUpgrades['rosicrucian_leyline_anchored'] = 1;
            progress.factionStandings['Rosicrucians'] = (progress.factionStandings['Rosicrucians'] ?? 0) + 15;
            service.addLog('Leader anchored the alchemical leyline. Spiritual node secured.');
          },
        });
        options.add({
          'title': 'B) "Decline. We do not risk our minds."',
          'subtitle': 'Effect: Cancel leyline project, lose -5 Rosicrucian standing.',
          'onPress': () {
            progress.factionStandings['Rosicrucians'] = (progress.factionStandings['Rosicrucians'] ?? 0) - 5;
            service.addLog('Cancelled alchemical leyline project.');
          },
        });
        break;

      case 'Rosicrucians_positive_step3':
        title = "THE ALCHEMICAL MARRIAGE";
        faction = "Rosicrucians";
        story = "The spiritual nodes are perfectly aligned! Johannes offers to seal the Alchemical Marriage, merging your leader's soul with the Rose and Cross. This grants ultimate battle regeneration and their elite spellcaster.";
        options.add({
          'title': 'A) "Drink the Alchemical Elixir and seal the marriage."',
          'subtitle': 'Effect: Recruited elite Warlock card, and leader gains permanent HP regeneration (+5 HP/sec) in combat!',
          'onPress': () {
            progress.playerDeckIds.add('warlock');
            progress.cardUpgrades['rosicrucian_blessing_active'] = 1;
            progress.factionStandings['Rosicrucians'] = (progress.factionStandings['Rosicrucians'] ?? 0) + 20;
            service.addLog('Sealed Alchemical Marriage! Recruited Warlock and unlocked leader battle HP regeneration.');
          },
        });
        options.add({
          'title': 'B) "Decline the marriage but accept alchemical gold."',
          'subtitle': 'Effect: Gain +1200 CHF immediately and +10 Rosicrucian standing.',
          'onPress': () {
            progress.cash += 1200;
            progress.factionStandings['Rosicrucians'] = (progress.factionStandings['Rosicrucians'] ?? 0) + 10;
            service.addLog('Refused alchemical marriage. Claimed 1200 CHF alchemical gold.');
          },
        });
        break;

      case 'Rosicrucians_negative_step1':
        title = "THE OCCULT HEX";
        faction = "Rosicrucians";
        story = "Angered by your hostility, Rosicrucian mystics have placed an occult hex on your pantry! A mysterious rot is turning your food to ash. They demand 150 CHF to lift the hex.";
        options.add({
          'title': 'A) "Appease the spirits with a 150 CHF offering."',
          'subtitle': 'Effect: Hex lifted, deduct 150 CHF.',
          'checkAffordable': () => progress.cash >= 150,
          'onPress': () {
            progress.cash -= 150;
            service.addLog('Appeased the mystics with a financial offering. Hex lifted.');
          },
        });
        options.add({
          'title': 'B) "Ignore their silly superstitions!"',
          'subtitle': 'Effect: Food rot spreads! Instantly lose 150 Food.',
          'onPress': () {
            progress.food = max(0, progress.food - 150);
            service.addLog('CONSEQUENCE: Food rot spread. Lost 150 food reserves.');
          },
        });
        break;

      case 'Rosicrucians_negative_step2':
        title = "PLAGUE OF THE ALCHEMICAL VERMIN";
        faction = "Rosicrucians";
        story = "Occult conjurers have summoned a plague of giant alchemical vermin and monstrosities to swarm your outer watchtowers!";
        options.add({
          'title': 'A) "Pay 300 CHF to hire professional pest exterminators."',
          'subtitle': 'Effect: Vermin cleared, deduct 300 CHF.',
          'checkAffordable': () => progress.cash >= 300,
          'onPress': () {
            progress.cash -= 300;
            service.addLog('Hired alchemical exterminators to clear outer watchtowers.');
          },
        });
        options.add({
          'title': 'B) "Cleanse the vermin in open battle!"',
          'subtitle': 'Effect: Immediate combat against alchemical beasts. No cash cost.',
          'onPress': () {
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createFleshGolem(),
                CombatUnitFactory.createFleshGolem(),
              ],
              eventTitle: title,
              spoilsFood: 30,
              spoilsCash: 100,
              spoilsIron: 10,
              spoilsWood: 10,
            );
            return;
          },
        });
        break;

      case 'Rosicrucians_negative_step3':
        title = "THE CURSE OF THE WITHERED SOUL";
        faction = "Rosicrucians";
        story = "The Grand Master of the Rose and Cross has cast a devastating spiritual blight upon your Manor, cursing your leader and your fields.";
        options.add({
          'title': 'A) "Submit to the curse and yield alchemical notes."',
          'subtitle': 'Effect: Leader max health permanently reduced by -100 HP, and starvation infractions accumulate twice as fast!',
          'onPress': () {
            progress.cardUpgrades['rosicrucian_curse_active'] = 1;
            progress.factionStandings['Rosicrucians'] = -10;
            service.addLog('CONSEQUENCE: Spiritual blight active. Leader max health reduced by 100 HP and starvation doubled.');
          },
        });
        options.add({
          'title': 'B) "Burn their occult sanctuary in open war!"',
          'subtitle': 'Effect: High-difficulty combat against coven warlocks and flesh golems!',
          'onPress': () {
            Navigator.pop(context);
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createFleshGolem(),
                CombatUnitFactory.createFleshGolem(),
              ],
              eventTitle: title,
              spoilsFood: 10,
              spoilsCash: 300,
              spoilsIron: 35,
              spoilsWood: 15,
            );
            return;
          },
        });
        break;

      default:
        return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1712),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: const Color(0xFFD4AF37), width: 2.0),
            borderRadius: BorderRadius.circular(8),
          ),
          title: Column(
            children: [
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFD4AF37),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Faction Involved: $faction'.toUpperCase(),
                style: GoogleFonts.oldStandardTt(
                  color: const Color(0xFFC4B89B),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    story,
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 12,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),
                  ...options.map((opt) {
                    final String titleStr = opt['title'] as String;
                    final String subtitleStr = opt['subtitle'] as String;
                    final VoidCallback cb = opt['onPress'] as VoidCallback;
                    final bool isAffordable = opt['checkAffordable'] != null
                        ? (opt['checkAffordable'] as bool Function())()
                        : true;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAffordable
                                ? const Color(0xFF2A1E16)
                                : const Color(0xFF18120E),
                            disabledBackgroundColor: const Color(0xFF18120E),
                            side: BorderSide(
                              color: isAffordable
                                  ? const Color(0xFFC4B89B)
                                  : Colors.white12,
                              width: 1.0,
                            ),
                            shape: const RoundedRectangleBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onPressed: isAffordable
                              ? () {
                                  int choiceVal = 1;
                                  if (titleStr.contains('B)'))
                                    choiceVal = 2;
                                  else if (titleStr.contains('C)'))
                                    choiceVal = 3;
                                  else if (titleStr.contains('D)'))
                                    choiceVal = 4;

                                  final nonRippleEncounters = [
                                    'davos_smallpox_vaccine',
                                    'smallpox_outbreak',
                                    'glarus_refugees_resettle',
                                    'glarus_caravan_stay',
                                    'glarus_missionaries_buy',
                                    'glarus_farmers_grant',
                                  ];
                                  if (!nonRippleEncounters.contains(
                                    encounterId,
                                  )) {
                                    progress.cardUpgrades['ripple_turn_$encounterId'] =
                                        progress.currentTurn + 3;
                                    progress.cardUpgrades['ripple_choice_$encounterId'] =
                                        choiceVal;
                                  }

                            if (titleStr.contains('D)')) {
                              Navigator.pop(context);
                              cb();
                            } else {
                              cb();
                              service.manualSave();
                              Navigator.pop(context);
                            }

                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    _checkAndTriggerRippleEffects(context);
                                  });
                                }
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                titleStr,
                                style: GoogleFonts.playfairDisplay(
                                  color: isAffordable
                                      ? const Color(0xFFE5D5B0)
                                      : Colors.white24,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAffordable
                                    ? subtitleStr
                                    : "[UNAFFORDABLE] $subtitleStr",
                                style: GoogleFonts.oldStandardTt(
                                  color: isAffordable
                                      ? Colors.white54
                                      : const Color(0xFFCF6679),
                                  fontSize: 8.5,
                                  fontWeight: isAffordable
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _startEventCombat({
    required SurvivalProgress progress,
    required SurvivalService service,
    required GameState state,
    required List<NPC> aiUnits,
    required String eventTitle,
    required int spoilsFood,
    required int spoilsCash,
    required int spoilsIron,
    required int spoilsWood,
  }) {
    final playerUnits = progress.playerDeckIds.map((t) {
      final npc = CombatUnitService.createUnit(t);
      final lvl = progress.getUnitLevel(t);
      final mult = 1.0 + (lvl - 1) * 0.1;
      double distance = npc.combatStats!.distance;
      double rangedRange = npc.combatStats!.rangedRange;
      double baseAttack = npc.combatStats!.attack.toDouble();
      double baseSpeed = npc.combatStats!.speed;
      double baseMovement = npc.combatStats!.movement;
      int baseCost = npc.combatStats!.cost;

      if (t == 'cannoneer' && lvl >= 6) {
        distance = 23.0;
        rangedRange = 23.0;
      }

      final int rawWepIdx =
          progress.cardUpgrades['${t}_equipped_weapon_idx'] ??
          (t == 'samurai'
              ? progress.cardUpgrades['samurai_equipped_weapon']
              : 0) ??
          0;
      if (rawWepIdx > 0) {
        final int cSamIdx = rawWepIdx.clamp(0, _samuraiUpgrades.length - 1);
        final int cGenIdx = (rawWepIdx - 1).clamp(
          0,
          _generalWeaponMarket.length - 1,
        );
        final String wepName =
            t == 'samurai'
                ? _samuraiUpgrades[cSamIdx].name
                : _generalWeaponMarket[cGenIdx].name;
        final wepStats = _getEquippedWeaponStats(t, wepName);

        baseAttack = wepStats.damage;
        distance = wepStats.range;
        rangedRange = wepStats.range;
        baseSpeed = wepStats.speed;

        if (wepStats.tier == 2) {
          baseCost += 1;
          baseMovement *= 0.85;
        } else if (wepStats.tier == 3) {
          baseCost += 2;
          baseMovement *= 0.75;
        }
      }

      // Apply permanent Fate Dice encounter stat bonuses/penalties
      final movementBonus =
          (progress.cardUpgrades['${t}_stat_movement_bonus'] ?? 0) / 100.0;
      final speedBonus =
          (progress.cardUpgrades['${t}_stat_speed_bonus'] ?? 0) / 100.0;
      final meleeDamageBonus =
          (progress.cardUpgrades['${t}_stat_meleeDamage_bonus'] ?? 0)
              .toDouble();
      final rangedDamageBonus =
          (progress.cardUpgrades['${t}_stat_rangedDamage_bonus'] ?? 0)
              .toDouble();
      final maxHealthBonus =
          (progress.cardUpgrades['${t}_stat_maxHealth_bonus'] ?? 0).toDouble();
      final meleeRangeBonus =
          (progress.cardUpgrades['${t}_stat_meleeRange_bonus'] ?? 0) / 100.0;
      final rangedRangeBonus =
          (progress.cardUpgrades['${t}_stat_rangedRange_bonus'] ?? 0) / 100.0;
      final meleeAttackSpeedBonus =
          (progress.cardUpgrades['${t}_stat_meleeAttackSpeed_bonus'] ?? 0) /
          100.0;
      final rangedAttackSpeedBonus =
          (progress.cardUpgrades['${t}_stat_rangedAttackSpeed_bonus'] ?? 0) /
          100.0;

      baseMovement = (baseMovement + movementBonus).clamp(0.1, 15.0);
      baseSpeed = (baseSpeed + speedBonus).clamp(0.1, 10.0);

      final bool isLeader = (t == progress.selectedLeaderId);
      final bool hasRosicrucianBlessing = isLeader && (progress.cardUpgrades['rosicrucian_blessing_active'] == 1);
      final bool hasRosicrucianCurse = isLeader && (progress.cardUpgrades['rosicrucian_curse_active'] == 1);

      double finalMaxHealth =
          (npc.combatStats!.maxHealth * mult + maxHealthBonus).clamp(
            1.0,
            9999.0,
          );
      if (hasRosicrucianCurse) {
        finalMaxHealth = max(1.0, finalMaxHealth - 100.0);
      }

      double finalHealth =
          (npc.combatStats!.health * mult + maxHealthBonus).clamp(
            1.0,
            finalMaxHealth,
          );
      if (hasRosicrucianCurse) {
        finalHealth = max(1.0, finalHealth - 100.0);
      }

      final bool hasRanged = npc.combatStats!.rangedDamage > 0.0;
      final double finalAttack = (baseAttack * mult + meleeDamageBonus).clamp(
        1.0,
        999.0,
      );
      final double finalMeleeDamage = (baseAttack * mult + meleeDamageBonus)
          .clamp(1.0, 999.0);
      final double finalRangedDamage = hasRanged
          ? (baseAttack * mult + rangedDamageBonus).clamp(0.0, 999.0)
          : 0.0;

      final double finalDistance = hasRanged
          ? (distance + rangedRangeBonus).clamp(1.0, 50.0)
          : (npc.combatStats!.distance + meleeRangeBonus).clamp(1.0, 15.0);

      final double finalRangedRange = hasRanged
          ? (rangedRange + rangedRangeBonus).clamp(1.0, 50.0)
          : 0.0;

      final double finalMeleeAttackSpeed =
          (npc.combatStats!.meleeAttackSpeed + meleeAttackSpeedBonus).clamp(
            0.1,
            10.0,
          );
      final double finalRangedAttackSpeed =
          (npc.combatStats!.rangedAttackSpeed + rangedAttackSpeedBonus).clamp(
            0.1,
            10.0,
          );

      return npc.copyWith(
        metadata: {
          ...npc.metadata,
          'cardType': t,
          'level': lvl,
          if (hasRosicrucianBlessing) 'rosicrucian_blessing_active': 1,
        },
        combatStats: npc.combatStats?.copyWith(
          cost: baseCost,
          speed: baseSpeed,
          movement: baseMovement,
          health: finalHealth,
          maxHealth: finalMaxHealth,
          attack: finalAttack,
          meleeDamage: finalMeleeDamage,
          rangedDamage: finalRangedDamage,
          distance: finalDistance,
          rangedRange: finalRangedRange,
          meleeAttackSpeed: finalMeleeAttackSpeed,
          rangedAttackSpeed: finalRangedAttackSpeed,
        ),
      );
    }).toList();

    final baseEnemyHero = CombatUnitFactory.createAlphonse().copyWith(
      id: 'ai_mirror',
      name: 'Bandit Captain',
      isPlayer: false,
    );
    double meanLvl = 1.0;
    final turn = progress.currentTurn;
    if (turn < 9) {
      meanLvl = 2.0;
    } else if (turn < 20) {
      meanLvl = 3.0;
    } else {
      meanLvl = (3.0 + (turn - 20) * 0.15).clamp(3.0, 7.0);
    }
    final int enemyLvl = meanLvl.round().clamp(1, 7);
    final double enemyUpgradeMult = 1.0 + (turn * 0.03).clamp(0.0, 0.75);
    final enemyLvlMult = 1.0 + (enemyLvl - 1) * 0.1;

    final enemyHero = baseEnemyHero.copyWith(
      metadata: {
        ...baseEnemyHero.metadata,
        'level': enemyLvl,
      },
      combatStats: baseEnemyHero.combatStats?.copyWith(
        health: baseEnemyHero.combatStats!.health * enemyLvlMult,
        maxHealth: baseEnemyHero.combatStats!.maxHealth * enemyLvlMult,
        attack: baseEnemyHero.combatStats!.attack * enemyLvlMult * enemyUpgradeMult,
        meleeDamage: baseEnemyHero.combatStats!.meleeDamage * enemyLvlMult * enemyUpgradeMult,
        rangedDamage: baseEnemyHero.combatStats!.rangedDamage * enemyLvlMult * enemyUpgradeMult,
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CombatScreen(
          customPlayerHero: CombatUnitService.createUnit(progress.selectedLeaderId).copyWith(isPlayer: true),
          customPlayerDeck: playerUnits,
          customAiDeck: aiUnits,
          customEnemyHero: enemyHero,
          cardUpgrades: progress.cardUpgrades,
          survivalTurn: progress.currentTurn,
          survivalDifficulty: progress.difficulty,
          onSurvivalVictory:
              (
                destroyedTowersCount,
                enemyDeck,
                finalSpoilsFood,
                finalSpoilsCash,
                finalSpoilsIron,
                finalSpoilsWood,
                playerTowerHealth,
                combatExp,
                activeContext,
              ) {
                final levelUps = service.processCombatOutcome(
                  true,
                  false,
                  playerTowerHealth,
                  combatExp,
                  opponentDeck: enemyDeck,
                  destroyedEnemyTowers: destroyedTowersCount,
                  customSpoilsFood: finalSpoilsFood,
                  customSpoilsCash: finalSpoilsCash,
                  customSpoilsIron: finalSpoilsIron,
                  customSpoilsWood: finalSpoilsWood,
                );
                state.clearEncounterState();
                Navigator.pop(activeContext);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (levelUps.isNotEmpty) {
                    _showPendingLevelUps(levelUps.entries.toList(), onComplete: _triggerDiceRollSequence);
                  } else {
                    _triggerDiceRollSequence();
                  }
                });
              },
          onSurvivalDefeat:
              (
                destroyedTowersCount,
                enemyDeck,
                playerTowerHealth,
                combatExp,
                activeContext,
              ) {
                final levelUps = service.processCombatOutcome(
                  false,
                  false,
                  playerTowerHealth,
                  combatExp,
                  opponentDeck: enemyDeck,
                  destroyedEnemyTowers: destroyedTowersCount,
                  customSpoilsFood: 0,
                  customSpoilsCash: 0,
                  customSpoilsIron: 0,
                  customSpoilsWood: 0,
                );
                state.clearEncounterState();
                if (progress.difficulty == SurvivalDifficulty.arcade) {
                  ArenaSaveService.deleteSave(service.activeSlot);
                  Navigator.pushReplacement(
                    activeContext,
                    MaterialPageRoute(
                      builder: (context) => GameOverScreen(
                        reason: 'Your forces were defeated in combat.',
                        difficulty: progress.difficulty,
                        turnsSurvived: progress.currentTurn,
                      ),
                    ),
                  );
                } else {
                  Navigator.pop(activeContext);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (levelUps.isNotEmpty) {
                      _showPendingLevelUps(levelUps.entries.toList(), onComplete: _triggerDiceRollSequence);
                    } else {
                      _triggerDiceRollSequence();
                    }
                  });
                }
              },
          onSurvivalDraw:
              (
                destroyedTowersCount,
                enemyDeck,
                playerTowerHealth,
                combatExp,
                activeContext,
              ) {
                final levelUps = service.processCombatOutcome(
                  false,
                  true,
                  playerTowerHealth,
                  combatExp,
                  opponentDeck: enemyDeck,
                  destroyedEnemyTowers: destroyedTowersCount,
                  customSpoilsFood: 0,
                  customSpoilsCash: 0,
                  customSpoilsIron: 0,
                  customSpoilsWood: 0,
                );
                state.clearEncounterState();
                Navigator.pop(activeContext);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (levelUps.isNotEmpty) {
                    _showPendingLevelUps(levelUps.entries.toList(), onComplete: _triggerDiceRollSequence);
                  } else {
                    _triggerDiceRollSequence();
                  }
                });
              },
        ),
      ),
    );
  }

  void _showPendingLevelUps(
    List<MapEntry<String, List<int>>> remaining, {
    required VoidCallback onComplete,
  }) {
    if (remaining.isEmpty) {
      onComplete();
      return;
    }
    final first = remaining.first;
    final cardId = first.key;
    final oldLvl = first.value[0];
    final newLvl = first.value[1];

    final npc = CombatUnitService.createUnit(cardId);
    final stats = npc.combatStats!;

    final oldMult = 1.0 + (oldLvl - 1) * 0.1;
    final newMult = 1.0 + (newLvl - 1) * 0.1;

    final oldHP = stats.maxHealth * oldMult;
    final newHP = stats.maxHealth * newMult;

    final oldAtk = stats.attack * oldMult;
    final newAtk = stats.attack * newMult;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Fireworks
              const Positioned.fill(child: FireworksOverlay()),

              // Content Card
              Container(
                width: 320,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A130E),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'LEVEL UP!',
                        style: GoogleFonts.oswald(
                          color: const Color(0xFFD4AF37),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CharacterBlobRenderer(npc: npc, size: 64, isCombat: true),
                      const SizedBox(height: 8),
                      Text(
                        npc.name.toUpperCase(),
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Level $oldLvl ➔ Level $newLvl',
                        style: GoogleFonts.oswald(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 8),
                      _buildLevelUpStatRow(
                        'MAX HEALTH (HP)',
                        oldHP.toInt().toString(),
                        newHP.toInt().toString(),
                      ),
                      const SizedBox(height: 6),
                      _buildLevelUpStatRow(
                        'ATTACK POWER',
                        oldAtk.toInt().toString(),
                        newAtk.toInt().toString(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC4B89B),
                            foregroundColor: Colors.black,
                            shape: const RoundedRectangleBorder(),
                          ),
                          onPressed: () {
                            Navigator.pop(dlgContext);
                            _showPendingLevelUps(remaining.sublist(1), onComplete: onComplete);
                          },
                          child: Text(
                            'CONTINUE',
                            style: GoogleFonts.playfairDisplay(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLevelUpDialog(
    BuildContext context,
    String cardId,
    int oldLvl,
    int newLvl,
  ) {
    final npc = CombatUnitService.createUnit(cardId);
    final stats = npc.combatStats!;

    final oldMult = 1.0 + (oldLvl - 1) * 0.1;
    final newMult = 1.0 + (newLvl - 1) * 0.1;

    final oldHP = stats.maxHealth * oldMult;
    final newHP = stats.maxHealth * newMult;

    final oldAtk = stats.attack * oldMult;
    final newAtk = stats.attack * newMult;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Fireworks
              const Positioned.fill(child: FireworksOverlay()),

              // Content Card
              Container(
                width: 320,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A130E),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'LEVEL UP!',
                        style: GoogleFonts.oswald(
                          color: const Color(0xFFD4AF37),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CharacterBlobRenderer(npc: npc, size: 64, isCombat: true),
                      const SizedBox(height: 8),
                      Text(
                        npc.name.toUpperCase(),
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Level $oldLvl ➔ Level $newLvl',
                        style: GoogleFonts.oswald(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 8),
                      _buildLevelUpStatRow(
                        'MAX HEALTH (HP)',
                        oldHP.toInt().toString(),
                        newHP.toInt().toString(),
                      ),
                      const SizedBox(height: 6),
                      _buildLevelUpStatRow(
                        'ATTACK POWER',
                        oldAtk.toInt().toString(),
                        newAtk.toInt().toString(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC4B89B),
                            foregroundColor: Colors.black,
                            shape: const RoundedRectangleBorder(),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'CONTINUE',
                            style: GoogleFonts.playfairDisplay(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelUpStatRow(String label, String oldVal, String newVal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 12),
        ),
        Row(
          children: [
            Text(
              oldVal,
              style: GoogleFonts.oswald(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: Color(0xFFD4AF37), size: 12),
            const SizedBox(width: 8),
            Text(
              newVal,
              style: GoogleFonts.oswald(
                color: const Color(0xFFD4AF37),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<NPC> _generateDiverseSurvivalOpponentDeck(int turn) {
    final int combatIndex = turn - 1;
    final rand = Random();

    int targetDeckSize = 5;
    if (combatIndex >= 8) {
      targetDeckSize = 12;
    } else if (combatIndex >= 5) {
      targetDeckSize = 9;
    } else if (combatIndex >= 2) {
      targetDeckSize = 7;
    }

    final pool = [
      CombatUnitFactory.createGoons(),
      CombatUnitFactory.createMilitia(),
      CombatUnitFactory.createPikemen(),
      CombatUnitFactory.createMarksmen(),
      if (turn >= 1) CombatUnitFactory.createBats(),
      if (turn >= 2) ...[
        CombatUnitFactory.createBrewers(),
        CombatUnitFactory.createZurichDebtCollector(),
      ],
      if (turn >= 3) ...[
        CombatUnitFactory.createFleshGolem(),
        CombatUnitFactory.createMasonicSapper(),
        CombatUnitFactory.createRoyalistStandardBearer(),
      ],
      if (turn >= 4) ...[
        CombatUnitFactory.createArmoredCar(),
        CombatUnitFactory.createFenianNightRaider(),
        CombatUnitFactory.createSacredGeometry(),
      ],
      if (turn >= 5) ...[
        CombatUnitFactory.createWitch(),
        CombatUnitFactory.createForesterHerbalist(),
        CombatUnitFactory.createElixirOfVitality(),
      ],
      if (turn >= 6) ...[
        CombatUnitFactory.createWerewolf(),
        CombatUnitFactory.createTemplarPyreKnight(),
        CombatUnitFactory.createGreekFireFlask(),
      ],
      if (turn >= 7) ...[
        CombatUnitFactory.createHag(),
        CombatUnitFactory.createCarbonariArsonist(),
        CombatUnitFactory.createRevolutionaryMartyr(),
      ],
      if (turn >= 8) ...[
        CombatUnitFactory.createWarlock(),
        CombatUnitFactory.createHermeticMesmerist(),
        CombatUnitFactory.createAstralHypnosis(),
      ],
      if (turn >= 9) ...[
        CombatUnitFactory.createStampede(),
        CombatUnitFactory.createChimera(),
        CombatUnitFactory.createGatlingGun(),
        CombatUnitFactory.createVaultAssassin(),
        CombatUnitFactory.createHomunculusBehemoth(),
        CombatUnitFactory.createRoyalistCuirassier(),
        CombatUnitFactory.createInsurgentCell(),
        CombatUnitFactory.createForesterBeastmaster(),
      ],
    ];

    final List<int> cardLevels = [];
    if (combatIndex < 8) {
      final int numLvl2 = combatIndex.clamp(1, targetDeckSize);
      for (int i = 0; i < numLvl2; i++) {
        cardLevels.add(2);
      }
      for (int i = 0; i < targetDeckSize - numLvl2; i++) {
        cardLevels.add(1);
      }
    } else {
      final int numLvl3 = (combatIndex - 7).clamp(0, 12);
      if (numLvl3 >= 12) {
        final double targetMean = (3.0 + (combatIndex - 19) * 0.15).clamp(
          3.0,
          7.0,
        );
        for (int i = 0; i < 12; i++) {
          final double offset = (i % 2 == 0) ? -0.5 : 0.5;
          final double noise = (rand.nextDouble() - 0.5) * 0.4;
          final int lvl = (targetMean + offset + noise).round().clamp(3, 7);
          cardLevels.add(lvl);
        }
      } else {
        final int numLvl2 = 12 - numLvl3;
        for (int i = 0; i < numLvl3; i++) {
          cardLevels.add(3);
        }
        for (int i = 0; i < numLvl2; i++) {
          cardLevels.add(2);
        }
      }
    }

    final double upgradeMult = 1.0 + (turn * 0.03).clamp(0.0, 0.75);
    final list = <NPC>[];
    for (int i = 0; i < targetDeckSize; i++) {
      final baseNpc = pool[i % pool.length];
      final int cardLevel = cardLevels[i];

      final mult = 1.0 + (cardLevel - 1) * 0.1;
      final npc = baseNpc.copyWith(
        metadata: {
          ...baseNpc.metadata,
          'level': cardLevel,
        },
        combatStats: baseNpc.combatStats?.copyWith(
          health: baseNpc.combatStats!.health * mult,
          maxHealth: baseNpc.combatStats!.maxHealth * mult,
          attack: baseNpc.combatStats!.attack * mult * upgradeMult,
          meleeDamage: baseNpc.combatStats!.meleeDamage * mult * upgradeMult,
          rangedDamage: baseNpc.combatStats!.rangedDamage * mult * upgradeMult,
        ),
      );
      list.add(npc);
    }
    return list;
  }

  void _triggerDiceRollSequence() {
    final service = Provider.of<SurvivalService>(context, listen: false);
    final progress = service.progress;
    if (progress == null) return;

    if (progress.currentTurn < 2) return;

    setState(() {
      _showDiceOverlay = true;
      _isDiceRolling = true;
      _diceOutcomeMessage = 'ROLLING THE DICE...';
      _diceOutcomeAction = null;
    });

    final rand = Random();
    int count = 0;

    void rollTick() {
      if (!mounted) return;
      if (count < 15) {
        setState(() {
          _die1 = rand.nextInt(6) + 1;
          _die2 = rand.nextInt(6) + 1;
        });
        count++;
        Future.delayed(const Duration(milliseconds: 100), rollTick);
      } else {
        final finalDie1 = rand.nextInt(6) + 1;
        final finalDie2 = rand.nextInt(6) + 1;
        final total = finalDie1 + finalDie2;

        setState(() {
          _die1 = finalDie1;
          _die2 = finalDie2;
          _isDiceRolling = false;
        });

        _evaluateDiceOutcome(total, progress, service);
      }
    }

    Future.delayed(const Duration(milliseconds: 100), rollTick);
  }

  int _getPlotEventIdFromString(String key) {
    switch (key) {
      case 'Glarus_positive_step1': return 101;
      case 'Glarus_positive_step2': return 102;
      case 'Glarus_positive_step3': return 103;
      case 'Glarus_negative_step1': return 104;
      case 'Glarus_negative_step2': return 105;
      case 'Glarus_negative_step3': return 106;

      case 'Gnomes of Zurich_positive_step1': return 201;
      case 'Gnomes of Zurich_positive_step2': return 202;
      case 'Gnomes of Zurich_positive_step3': return 203;
      case 'Gnomes of Zurich_negative_step1': return 204;
      case 'Gnomes of Zurich_negative_step2': return 205;
      case 'Gnomes of Zurich_negative_step3': return 206;

      case 'Bavarian Illuminati_positive_step1': return 301;
      case 'Bavarian Illuminati_positive_step2': return 302;
      case 'Bavarian Illuminati_positive_step3': return 303;
      case 'Bavarian Illuminati_negative_step1': return 304;
      case 'Bavarian Illuminati_negative_step2': return 305;
      case 'Bavarian Illuminati_negative_step3': return 306;

      case 'Rosicrucians_positive_step1': return 401;
      case 'Rosicrucians_positive_step2': return 402;
      case 'Rosicrucians_positive_step3': return 403;
      case 'Rosicrucians_negative_step1': return 404;
      case 'Rosicrucians_negative_step2': return 405;
      case 'Rosicrucians_negative_step3': return 406;
      default: return 0;
    }
  }

  String? _getPlotEventStringFromId(int id) {
    switch (id) {
      case 101: return 'Glarus_positive_step1';
      case 102: return 'Glarus_positive_step2';
      case 103: return 'Glarus_positive_step3';
      case 104: return 'Glarus_negative_step1';
      case 105: return 'Glarus_negative_step2';
      case 106: return 'Glarus_negative_step3';

      case 201: return 'Gnomes of Zurich_positive_step1';
      case 202: return 'Gnomes of Zurich_positive_step2';
      case 203: return 'Gnomes of Zurich_positive_step3';
      case 204: return 'Gnomes of Zurich_negative_step1';
      case 205: return 'Gnomes of Zurich_negative_step2';
      case 206: return 'Gnomes of Zurich_negative_step3';

      case 301: return 'Bavarian Illuminati_positive_step1';
      case 302: return 'Bavarian Illuminati_positive_step2';
      case 303: return 'Bavarian Illuminati_positive_step3';
      case 304: return 'Bavarian Illuminati_negative_step1';
      case 305: return 'Bavarian Illuminati_negative_step2';
      case 306: return 'Bavarian Illuminati_negative_step3';

      case 401: return 'Rosicrucians_positive_step1';
      case 402: return 'Rosicrucians_positive_step2';
      case 403: return 'Rosicrucians_positive_step3';
      case 404: return 'Rosicrucians_negative_step1';
      case 405: return 'Rosicrucians_negative_step2';
      case 406: return 'Rosicrucians_negative_step3';
      default: return null;
    }
  }

  void _checkAndTriggerRippleEffects(BuildContext context) {
    final service = Provider.of<SurvivalService>(context, listen: false);
    final progress = service.progress;
    if (progress == null) return;

    final state = Provider.of<GameState>(context, listen: false);

    // Check last visitor turn spacing (must be at least 2 days/turns apart)
    final lastVisitorTurn = progress.cardUpgrades['last_visitor_turn'] ?? 0;
    final bool isCooldownActive = (progress.currentTurn - lastVisitorTurn) < 2;

    // 1. Check if a scheduled faction plot event is due on this turn
    int? duePlotEventId;
    String? duePlotKey;
    for (final key in progress.cardUpgrades.keys.toList()) {
      if (key.startsWith('scheduled_plot_event_')) {
        final scheduledTurnStr = key.substring('scheduled_plot_event_'.length);
        final scheduledTurn = int.tryParse(scheduledTurnStr);
        if (scheduledTurn == progress.currentTurn) {
          duePlotEventId = progress.cardUpgrades[key];
          duePlotKey = key;
          break;
        }
      }
    }

    if (duePlotEventId != null && duePlotKey != null) {
      if (isCooldownActive) {
        // Postpone it to next turn to maintain spacing of at least 2 days
        progress.cardUpgrades.remove(duePlotKey);
        progress.cardUpgrades['scheduled_plot_event_${progress.currentTurn + 1}'] =
            duePlotEventId;
        service.manualSave();
        return; // Don't trigger it yet
      }

      // Remove it from the schedule so it doesn't trigger repeatedly
      progress.cardUpgrades.remove(duePlotKey);
      service.manualSave();

      // Trigger the narrative encounter for this plot event!
      final eventString = _getPlotEventStringFromId(duePlotEventId);
      if (eventString != null) {
        _showNarrativeEncounter(context, eventString, progress, service, state);
        return; // Only trigger one narrative encounter per check to avoid overlap
      }
    }

    // 2. Check for new faction plotline triggers (standing thresholds)
    for (final faction in ['Glarus', 'Gnomes of Zurich', 'Bavarian Illuminati', 'Rosicrucians']) {
      final standing = progress.factionStandings[faction] ?? 0;
      final posTriggerKey = 'plot_triggered_${faction}_positive';
      final negTriggerKey = 'plot_triggered_${faction}_negative';

      if (standing >= 20 && progress.cardUpgrades[posTriggerKey] != 1) {
        progress.cardUpgrades[posTriggerKey] = 1;
        // Schedule the series of events: turn +1, turn +3, turn +5
        progress.cardUpgrades['scheduled_plot_event_${progress.currentTurn + 1}'] = _getPlotEventIdFromString('${faction}_positive_step1');
        progress.cardUpgrades['scheduled_plot_event_${progress.currentTurn + 3}'] = _getPlotEventIdFromString('${faction}_positive_step2');
        progress.cardUpgrades['scheduled_plot_event_${progress.currentTurn + 5}'] = _getPlotEventIdFromString('${faction}_positive_step3');
        service.addLog('CRITICAL: Standing with $faction has unlocked their faction story arc!');
        service.manualSave();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CRITICAL: High reputation with $faction has unlocked their faction story arc!'),
            backgroundColor: const Color(0xFF2E1A0A),
          ),
        );
        break;
      } else if (standing <= -20 && progress.cardUpgrades[negTriggerKey] != 1) {
        progress.cardUpgrades[negTriggerKey] = 1;
        // Schedule the series of events: turn +1, turn +3, turn +5
        progress.cardUpgrades['scheduled_plot_event_${progress.currentTurn + 1}'] = _getPlotEventIdFromString('${faction}_negative_step1');
        progress.cardUpgrades['scheduled_plot_event_${progress.currentTurn + 3}'] = _getPlotEventIdFromString('${faction}_negative_step2');
        progress.cardUpgrades['scheduled_plot_event_${progress.currentTurn + 5}'] = _getPlotEventIdFromString('${faction}_negative_step3');
        service.addLog('CRITICAL: Hostility with $faction has triggered their revenge story arc!');
        service.manualSave();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WARNING: Extreme hostility with $faction has triggered their revenge story arc!'),
            backgroundColor: const Color(0xFF4C1010),
          ),
        );
        break;
      }
    }

    final encounterIds = [
      'gnomes_artillery',
      'freemasons_tribute',
      'alchemist_transmutation',
      'templar_levy',
      'carbonari_strike',
      'golden_dawn_seance',
      'fenian_gunrunning',
      'french_cavalry',
      'adrenochrome_syndicate',
      'bank_audit',
      'mystic_herbs',
      'irish_mutiny',
      'monarchist_ball',
      'masonic_toll',
      'alchemical_explosion',
      'secret_treaty',
      'carbonari_press',
      'golden_dawn_relic',
      'forester_woodcutters',
      'swiss_banker_loan',
      'grenadier_sabotage',
    ];

    String? dueEncounterId;
    for (var encId in encounterIds) {
      final dueTurn = progress.cardUpgrades['ripple_turn_$encId'];
      if (dueTurn != null && dueTurn == progress.currentTurn) {
        dueEncounterId = encId;
        break;
      }
    }

    if (dueEncounterId == null) return;

    final choiceVal = progress.cardUpgrades['ripple_choice_$dueEncounterId'];
    final choice = choiceVal == 1
        ? 'A'
        : choiceVal == 2
        ? 'B'
        : choiceVal == 3
        ? 'C'
        : 'D';
    progress.cardUpgrades.remove('ripple_turn_$dueEncounterId');
    progress.cardUpgrades.remove('ripple_choice_$dueEncounterId');
    service.manualSave();

    _resolveRippleEffect(
      context,
      dueEncounterId,
      choice,
      progress,
      service,
      state,
    );
  }

  void _showRippleEffectDialog(
    BuildContext context,
    String title,
    String description,
    VoidCallback? onConfirm,
    SurvivalService service,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A130E),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFD4AF37), width: 2.0),
            borderRadius: BorderRadius.circular(8),
          ),
          title: Text(
            title,
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFD4AF37),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: 400,
            child: Text(
              description,
              style: GoogleFonts.oldStandardTt(
                color: const Color(0xFFE5D5B0),
                fontSize: 12,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC4B89B),
                  foregroundColor: Colors.black,
                  shape: const RoundedRectangleBorder(),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (onConfirm != null) {
                    onConfirm();
                  }
                  service.manualSave();
                },
                child: Text(
                  'ACKNOWLEDGE',
                  style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _applyPermanentStatModifierToCurrentDeck({
    required SurvivalProgress progress,
    double movement = 0.0,
    double speed = 0.0,
    double meleeDamage = 0.0,
    double rangedDamage = 0.0,
    double maxHealth = 0.0,
    double meleeRange = 0.0,
    double rangedRange = 0.0,
    double meleeAttackSpeed = 0.0,
    double rangedAttackSpeed = 0.0,
  }) {
    for (final t in progress.playerDeckIds) {
      if (movement != 0.0) {
        final current = progress.cardUpgrades['${t}_stat_movement_bonus'] ?? 0;
        progress.cardUpgrades['${t}_stat_movement_bonus'] =
            current + (movement * 100).round();
      }
      if (speed != 0.0) {
        final current = progress.cardUpgrades['${t}_stat_speed_bonus'] ?? 0;
        progress.cardUpgrades['${t}_stat_speed_bonus'] =
            current + (speed * 100).round();
      }
      if (meleeDamage != 0.0) {
        final current =
            progress.cardUpgrades['${t}_stat_meleeDamage_bonus'] ?? 0;
        progress.cardUpgrades['${t}_stat_meleeDamage_bonus'] =
            current + meleeDamage.round();
      }
      if (rangedDamage != 0.0) {
        final current =
            progress.cardUpgrades['${t}_stat_rangedDamage_bonus'] ?? 0;
        progress.cardUpgrades['${t}_stat_rangedDamage_bonus'] =
            current + rangedDamage.round();
      }
      if (maxHealth != 0.0) {
        final current = progress.cardUpgrades['${t}_stat_maxHealth_bonus'] ?? 0;
        progress.cardUpgrades['${t}_stat_maxHealth_bonus'] =
            current + maxHealth.round();
      }
      if (meleeRange != 0.0) {
        final current =
            progress.cardUpgrades['${t}_stat_meleeRange_bonus'] ?? 0;
        progress.cardUpgrades['${t}_stat_meleeRange_bonus'] =
            current + (meleeRange * 100).round();
      }
      if (rangedRange != 0.0) {
        final current =
            progress.cardUpgrades['${t}_stat_rangedRange_bonus'] ?? 0;
        progress.cardUpgrades['${t}_stat_rangedRange_bonus'] =
            current + (rangedRange * 100).round();
      }
      if (meleeAttackSpeed != 0.0) {
        final current =
            progress.cardUpgrades['${t}_stat_meleeAttackSpeed_bonus'] ?? 0;
        progress.cardUpgrades['${t}_stat_meleeAttackSpeed_bonus'] =
            current + (meleeAttackSpeed * 100).round();
      }
      if (rangedAttackSpeed != 0.0) {
        final current =
            progress.cardUpgrades['${t}_stat_rangedAttackSpeed_bonus'] ?? 0;
        progress.cardUpgrades['${t}_stat_rangedAttackSpeed_bonus'] =
            current + (rangedAttackSpeed * 100).round();
      }
    }
  }

  void _resolveRippleEffect(
    BuildContext context,
    String encounterId,
    String? choice,
    SurvivalProgress progress,
    SurvivalService service,
    GameState state,
  ) {
    String title = "";
    String description = "";
    VoidCallback? onConfirmAction;

    switch (encounterId) {
      case 'gnomes_artillery':
        title = "GNOMES OF ZURICH: THE REPERCUSSIONS";
        if (choice == 'A') {
          description =
              "The Zurich banking syndicate is pleased with your respect for their client's trust. They send a dividend payout of +250 CHF and bonus AP (+2 AP) for your next battle.";
          onConfirmAction = () {
            progress.cash += 250;
            progress.cardUpgrades['next_combat_ap_modifier'] =
                (progress.cardUpgrades['next_combat_ap_modifier'] ?? 0) + 2;
          };
        } else if (choice == 'B') {
          description =
              "Survivors from Glarus have formed a vengeance coalition to punish you for destroying their village. They launch a surprise ambush on your estate!";
          onConfirmAction = () {
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createMilitia(),
                CombatUnitFactory.createMilitia(),
                CombatUnitFactory.createMusketeers(),
              ],
              eventTitle: "GLARUS REBELS AMBUSH",
              spoilsFood: 10,
              spoilsCash: 100,
              spoilsIron: 5,
              spoilsWood: 5,
            );
          };
        } else if (choice == 'C') {
          description =
              "The Gnomes of Zurich realize you profited from Glarus's destruction and demand a cut. You must pay 400 CHF or face an immediate audit attack!";
          onConfirmAction = () {
            if (progress.cash >= 400) {
              progress.cash -= 400;
            } else {
              progress.cash = 0;
              _startEventCombat(
                progress: progress,
                service: service,
                state: state,
                aiUnits: [
                  CombatUnitFactory.createZurichDebtCollector(),
                  CombatUnitFactory.createZurichDebtCollector(),
                ],
                eventTitle: "ZURICH ENFORCERS RAID",
                spoilsFood: 5,
                spoilsCash: 150,
                spoilsIron: 5,
                spoilsWood: 5,
              );
            }
          };
        } else {
          description =
              "The Gnomes of Zurich have blacklisted your estate. Your units suffer a -15% AP gain rate during the next combat due to supply chain sabotage.";
          onConfirmAction = () {
            progress.cardUpgrades['next_combat_ap_gain_rate_multiplier'] = 85;
          };
        }
        break;

      case 'freemasons_tribute':
        title = "THE LODGE'S AFTERMATH";
        if (choice == 'A') {
          description =
              "The completed Masonic Lodge has attracted elite architects. They reinforce your watchtowers, restoring all towers to 100% health and increasing their maximum health by 10% permanently!";
          onConfirmAction = () {
            progress.towerDamaged['tower_1'] = 0.0;
            progress.towerDamaged['tower_2'] = 0.0;
            progress.towerDamaged['tower_3'] = 0.0;
            progress.cardUpgrades['tower_health_multiplier'] =
                (progress.cardUpgrades['tower_health_multiplier'] ?? 100) + 10;
          };
        } else if (choice == 'B') {
          description =
              "Grateful for your support against the Masons, the Carbonari mobilize local rebel sympathizers. A veteran Militia unit joins your army!";
          onConfirmAction = () {
            if (progress.playerDeckIds.length < 12) {
              progress.playerDeckIds.add('militia');
              progress.cardUpgrades['level_militia'] = 3;
            } else {
              progress.food += 50;
            }
          };
        } else if (choice == 'C') {
          description =
              "Both factions realize you bribed them to play both sides. Angered by your double-dealing, they raid your stockpiles, stealing 150 wood and 150 iron.";
          onConfirmAction = () {
            progress.wood = max(0, progress.wood - 150);
            progress.iron = max(0, progress.iron - 150);
          };
        } else {
          description =
              "Striking rioters return to sabotage your estate infrastructure, setting one of your watchtowers to 100% damaged!";
          onConfirmAction = () {
            progress.towerDamaged['tower_1'] = 1.0;
          };
        }
        break;

      case 'alchemist_transmutation':
        title = "ALCHEMICAL RESONANCE";
        if (choice == 'A') {
          description =
              "The transmutated iron proved molecularly unstable. It disintegrates in your stockpiles, costing you 40 iron.";
          onConfirmAction = () {
            progress.iron = max(0, progress.iron - 40);
          };
        } else if (choice == 'B') {
          description =
              "The exiled Rosicrucian alchemist curses your troops from afar. Your units start the next combat with a -50% health penalty!\n\n(All units currently in your deck permanently suffer -5 maxHealth and +0.1s attack delay!)";
          onConfirmAction = () {
            progress.cardUpgrades['next_combat_health_penalty'] = 1;
            _applyPermanentStatModifierToCurrentDeck(
              progress: progress,
              maxHealth: -5,
              speed: 0.1,
              meleeAttackSpeed: 0.1,
              rangedAttackSpeed: 0.1,
            );
          };
        } else if (choice == 'C') {
          description =
              "The collaborative study yields a major breakthrough in combat stims! Your units gain +3 starting AP for the next combat.\n\n(All units currently in your deck permanently gain +5 maxHealth and +0.1 movement speed!)";
          onConfirmAction = () {
            progress.cardUpgrades['next_combat_ap_modifier'] =
                (progress.cardUpgrades['next_combat_ap_modifier'] ?? 0) + 3;
            _applyPermanentStatModifierToCurrentDeck(
              progress: progress,
              maxHealth: 5,
              movement: 0.1,
            );
          };
        } else {
          description =
              "Your scholars successfully decode the secrets of the seized laboratory, adding +200 wood and +100 iron to your stores.";
          onConfirmAction = () {
            progress.wood += 200;
            progress.iron += 100;
          };
        }
        break;

      case 'templar_levy':
        title = "TEMPLAR JUDGMENT";
        if (choice == 'A') {
          description =
              "Pleased with your piety and tribute, the Knights Templar send a veteran Cavalry squad to join your army!";
          onConfirmAction = () {
            if (progress.playerDeckIds.length < 12) {
              progress.playerDeckIds.add('cavalry');
              progress.cardUpgrades['level_cavalry'] = 3;
            } else {
              progress.cash += 250;
            }
          };
        } else if (choice == 'B') {
          description =
              "The Templar inquisitors discover your smuggling operation! They confiscate 150 food and 100 CHF as penalty.";
          onConfirmAction = () {
            progress.food = max(0, progress.food - 150);
            progress.cash = max(0, progress.cash - 100);
          };
        } else if (choice == 'C') {
          description =
              "The Knights Templar you sheltered bless your estate. All your combat units are fully cured of their injuries!";
          onConfirmAction = () {
            progress.bondageDebuffCount.clear();
          };
        } else {
          description =
              "The Templar Grand Master launches an Inquisition Crusade against your estate to punish your heresy!";
          onConfirmAction = () {
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createCavalry(),
                CombatUnitFactory.createPikemen(),
              ],
              eventTitle: "TEMPLAR INQUISITION CRUSADE",
              spoilsFood: 20,
              spoilsCash: 300,
              spoilsIron: 10,
              spoilsWood: 10,
            );
          };
        }
        break;

      case 'carbonari_strike':
        title = "THE UNION'S RECONCILIATION";
        if (choice == 'A') {
          description =
              "Your satisfied workforce works double-time! You receive a massive production boost of +200 wood and +100 iron.";
          onConfirmAction = () {
            progress.wood += 200;
            progress.iron += 100;
          };
        } else if (choice == 'B') {
          description =
              "The wage compromise was only temporary. Discontented laborers slow down operations, costing you 50 wood and 50 iron.";
          onConfirmAction = () {
            progress.wood = max(0, progress.wood - 50);
            progress.iron = max(0, progress.iron - 50);
          };
        } else if (choice == 'C') {
          description =
              "The oppressed workers sabotage your watchtowers in secret! All towers start the next combat with only 50% maximum health.";
          onConfirmAction = () {
            progress.cardUpgrades['next_combat_tower_health_multiplier'] = 50;
          };
        } else {
          description =
              "The violent suppression of the strike has left your agricultural fields empty. You produce 0 food this turn!";
          onConfirmAction = () {
            progress.food = max(0, progress.food - 100);
          };
        }
        break;

      case 'golden_dawn_seance':
        title = "THE SÉANCE'S ECHO";
        if (choice == 'A') {
          description =
              "The spiritual veil remains thin. Chimerical energy mutates your guards; they start the next combat with +2 starting AP but -20% maximum health.";
          onConfirmAction = () {
            progress.cardUpgrades['next_combat_ap_modifier'] =
                (progress.cardUpgrades['next_combat_ap_modifier'] ?? 0) + 2;
            progress.cardUpgrades['next_combat_health_penalty_percent'] = 20;
          };
        } else if (choice == 'B') {
          description =
              "Angered by your ban, Golden Dawn sorcerers curse your barracks. A random unit becomes terrified and deserts your army permanently!";
          onConfirmAction = () {
            if (progress.playerDeckIds.isNotEmpty) {
              progress.playerDeckIds.removeAt(
                Random().nextInt(progress.playerDeckIds.length),
              );
            }
          };
        } else if (choice == 'C') {
          description =
              "Restless spirits haunt your estate to protest being commercialized. Your units suffer a -15% AP gain rate during the next combat.";
          onConfirmAction = () {
            progress.cardUpgrades['next_combat_ap_gain_rate_multiplier'] = 85;
          };
        } else {
          description =
              "The consecrated cemetery yields holy blessings. The Knights Templar reward your purity by sending a Pikemen squad to join your army!";
          onConfirmAction = () {
            if (progress.playerDeckIds.length < 12) {
              progress.playerDeckIds.add('militia');
              progress.cardUpgrades['level_militia'] = 3;
            } else {
              progress.cash += 150;
            }
          };
        }
        break;

      case 'fenian_gunrunning':
        title = "GUN-RUNNING REPERCUSSIONS";
        if (choice == 'A') {
          description =
              "The Fenian weapon packages prove highly effective! Your towers deal +25% damage in the next combat.\n\n(All units currently in your deck permanently gain +1 damage and +0.1 attack range!)";
          onConfirmAction = () {
            progress.cardUpgrades['next_combat_tower_damage_bonus'] = 25;
            _applyPermanentStatModifierToCurrentDeck(
              progress: progress,
              meleeDamage: 1,
              rangedDamage: 1,
              meleeRange: 0.1,
              rangedRange: 0.1,
            );
          };
        } else if (choice == 'B') {
          description =
              "The Fenians discover your betrayal. Rebel commandos infiltrate your camp and blow up your munitions yards, costing you 150 iron.";
          onConfirmAction = () {
            progress.iron = max(0, progress.iron - 150);
          };
        } else if (choice == 'C') {
          description =
              "The backroom deal opens steady smuggling channels. You receive a generous share of the black market profits (+300 CHF).";
          onConfirmAction = () {
            progress.cash += 300;
          };
        } else {
          description =
              "Angered by your raid, Fenian cell members launch a coordinated strike on your estate!";
          onConfirmAction = () {
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createCommandos(),
                CombatUnitFactory.createGoon(),
              ],
              eventTitle: "FENIAN RETALIATION",
              spoilsFood: 10,
              spoilsCash: 150,
              spoilsIron: 20,
              spoilsWood: 10,
            );
          };
        }
        break;

      case 'french_cavalry':
        title = "THE CAVALRY'S TRAIL";
        if (choice == 'A') {
          description =
              "The monarchist drills pay off! Your cavalry units gain a permanent +20% movement speed in combat.";
          onConfirmAction = () {
            progress.cardUpgrades['cavalry_speed_multiplier'] = 120;
          };
        } else if (choice == 'B') {
          description =
              "The insulted Chevaliers lobby the canton to block your imports. You cannot purchase cards from the market for the next 2 turns.";
          onConfirmAction = () {
            progress.cardUpgrades['market_blocked_turns'] = 2;
          };
        } else if (choice == 'C') {
          description =
              "Grateful for the horse feed, the Chevaliers escort your trade caravan, yielding +300 CHF.";
          onConfirmAction = () {
            progress.cash += 300;
          };
        } else {
          description =
              "The royalists return with heavy cavalry reinforcements to avenge their mock combat defeat!";
          onConfirmAction = () {
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createCavalry(),
                CombatUnitFactory.createCavalry(),
              ],
              eventTitle: "CHEVALIERS VENDETTA",
              spoilsFood: 15,
              spoilsCash: 250,
              spoilsIron: 10,
              spoilsWood: 10,
            );
          };
        }
        break;

      case 'adrenochrome_syndicate':
        title = "THE COVENANT'S PAYMENT";
        if (choice == 'A') {
          description =
              "The illegal blood trade corrupts your lands. Glarus standing decreases by 20, and a random unit contracts a disease (-30% max health permanently).";
          onConfirmAction = () {
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) - 20;
            if (progress.playerDeckIds.isNotEmpty) {
              final randUnit =
                  progress.playerDeckIds[Random().nextInt(
                    progress.playerDeckIds.length,
                  )];
              progress.cardUpgrades['level_penalty_$randUnit'] =
                  (progress.cardUpgrades['level_penalty_$randUnit'] ?? 0) + 1;
            }
          };
        } else if (choice == 'B') {
          description =
              "The Foresters druid council is grateful for your boundary. They bless your estate crops, granting you +150 food.";
          onConfirmAction = () {
            progress.food += 150;
          };
        } else if (choice == 'C') {
          description =
              "Your investigation results are leaked. Quiet blackmail payments arrive from the syndicate, yielding +300 CHF.";
          onConfirmAction = () {
            progress.cash += 300;
          };
        } else {
          description =
              "The Ancient Order of Foresters launches a massive forest war to avenge their raided laboratory!";
          onConfirmAction = () {
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createFleshGolem(),
                CombatUnitFactory.createWildWolves(),
              ],
              eventTitle: "FORESTERS RETALIATION WAR",
              spoilsFood: 30,
              spoilsCash: 100,
              spoilsIron: 5,
              spoilsWood: 20,
            );
          };
        }
        break;

      case 'bank_audit':
        title = "THE AUDIT'S CONCLUSION";
        if (choice == 'A') {
          description =
              "The bribed audit passes cleanly! The syndicate sends an elite High Banker Rothschild card to manage your finances!";
          onConfirmAction = () {
            if (progress.playerDeckIds.length < 12) {
              progress.playerDeckIds.add('banker_rothschild');
              progress.cardUpgrades['level_banker_rothschild'] = 1;
            } else {
              progress.cash += 500;
            }
          };
        } else if (choice == 'B') {
          description =
              "Outraged by your lockout, the Zurich bank freezes your accounts. You lose 50% of your current cash in transaction fees!";
          onConfirmAction = () {
            progress.cash = (progress.cash * 0.5).toInt();
          };
        } else if (choice == 'C') {
          description =
              "The Templars demand a high protection fee to keep your accounts hidden. You must pay 200 CHF or lose 20 standing with them.";
          onConfirmAction = () {
            if (progress.cash >= 200) {
              progress.cash -= 200;
            } else {
              progress.factionStandings['Knights Templar'] =
                  (progress.factionStandings['Knights Templar'] ?? 0) - 20;
            }
          };
        } else {
          description =
              "The banking syndicate sends heavily armed debt collectors to seize your estate assets by force!";
          onConfirmAction = () {
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createZurichDebtCollector(),
                CombatUnitFactory.createZurichDebtCollector(),
                CombatUnitFactory.createGoon(),
              ],
              eventTitle: "ZURICH BAILIFFS SEIZURE",
              spoilsFood: 10,
              spoilsCash: 400,
              spoilsIron: 10,
              spoilsWood: 10,
            );
          };
        }
        break;

      case 'mystic_herbs':
        title = "HERBAL EFFECTIVENESS";
        if (choice == 'A') {
          description =
              "The forest herbs cause a secondary alchemical mutation! Your constructs gain a permanent +15% damage boost in combat.";
          onConfirmAction = () {
            progress.cardUpgrades['construct_damage_multiplier'] =
                (progress.cardUpgrades['construct_damage_multiplier'] ?? 100) +
                15;
          };
        } else if (choice == 'B') {
          description =
              "The slighted forest druids curse your estate. Your farm food production is halved for the next 2 turns.";
          onConfirmAction = () {
            progress.cardUpgrades['farm_output_halved_turns'] = 2;
          };
        } else if (choice == 'C') {
          description =
              "Your laboratory successfully synthesizes a miracle panacea! All units are cured of all injuries, and you sell the surplus for +200 CHF.";
          onConfirmAction = () {
            progress.bondageDebuffCount.clear();
            progress.cash += 200;
          };
        } else {
          description =
              "Burning the herbs released toxic, weakening spores. Your units suffer -2 starting AP in the next combat.\n\n(All units currently in your deck permanently suffer -0.1 movement speed and -5 maxHealth!)";
          onConfirmAction = () {
            progress.cardUpgrades['next_combat_ap_modifier'] =
                (progress.cardUpgrades['next_combat_ap_modifier'] ?? 0) - 2;
            _applyPermanentStatModifierToCurrentDeck(
              progress: progress,
              movement: -0.1,
              maxHealth: -5,
            );
          };
        }
        break;

      case 'irish_mutiny':
        title = "BARRACKS RESOLUTION";
        if (choice == 'A') {
          description =
              "Your soldiers are in high spirits! All units start the next combat with +2 starting AP and +20% damage.";
          onConfirmAction = () {
            progress.cardUpgrades['next_combat_ap_modifier'] =
                (progress.cardUpgrades['next_combat_ap_modifier'] ?? 0) + 2;
            progress.cardUpgrades['next_combat_damage_multiplier'] = 120;
          };
        } else if (choice == 'B') {
          description =
              "Fenian sympathizers sabotage your armory. You lose 100 iron and a random unit's weapon is damaged (-30% damage next combat).";
          onConfirmAction = () {
            progress.iron = max(0, progress.iron - 100);
            if (progress.playerDeckIds.isNotEmpty) {
              final randUnit =
                  progress.playerDeckIds[Random().nextInt(
                    progress.playerDeckIds.length,
                  )];
              progress.cardUpgrades['weapon_debuff_$randUnit'] = 1;
            }
          };
        } else if (choice == 'C') {
          description =
              "The veterans return from their frontline deployment! An experienced Commandos unit joins your army.";
          onConfirmAction = () {
            if (progress.playerDeckIds.length < 12) {
              progress.playerDeckIds.add('commandos');
              progress.cardUpgrades['level_commandos'] = 3;
            } else {
              progress.cash += 150;
            }
          };
        } else {
          description =
              "Jailed mutineers break out of the dungeons and launch an armed rebellion inside your estate!";
          onConfirmAction = () {
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createMilitia(),
                CombatUnitFactory.createMilitia(),
              ],
              eventTitle: "BARRACKS MUTINY REBELLION",
              spoilsFood: 10,
              spoilsCash: 100,
              spoilsIron: 10,
              spoilsWood: 10,
            );
          };
        }
        break;

      case 'monarchist_ball':
        title = "THE BALL'S AFTERMATH";
        if (choice == 'A') {
          description =
              "Impressed by the grand ball, a wealthy royalist patron sends a donation of +500 CHF and sponsors a Cavalry unit to join your army.";
          onConfirmAction = () {
            progress.cash += 500;
            if (progress.playerDeckIds.length < 12 &&
                !progress.playerDeckIds.contains('cavalry')) {
              progress.playerDeckIds.add('cavalry');
              progress.cardUpgrades['level_cavalry'] = 3;
            }
          };
        } else if (choice == 'B') {
          description =
              "The insulted Chevaliers blacklist your estate from noble trade, increasing all market upgrade costs by 20% for 3 turns.";
          onConfirmAction = () {
            progress.cardUpgrades['market_inflation_turns'] = 3;
          };
        } else if (choice == 'C') {
          description =
              "The modest peasant feast builds strong community ties. Glarus villagers volunteer to fully repair all your watchtowers!";
          onConfirmAction = () {
            progress.towerDamaged['tower_1'] = 0.0;
            progress.towerDamaged['tower_2'] = 0.0;
            progress.towerDamaged['tower_3'] = 0.0;
          };
        } else {
          description =
              "Insulted by your disruption, the Chevaliers send royal guards to execute your commanders!";
          onConfirmAction = () {
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createCavalry(),
                CombatUnitFactory.createMusketeers(),
              ],
              eventTitle: "ROYALIST RETALIATION",
              spoilsFood: 10,
              spoilsCash: 200,
              spoilsIron: 10,
              spoilsWood: 10,
            );
          };
        }
        break;

      case 'masonic_toll':
        title = "THE TOLL'S BURDEN";
        if (choice == 'A') {
          description =
              "The bridge toll strangles Glarus trade. You receive +300 CHF in toll dividends, but Glarus standing drops by 15.";
          onConfirmAction = () {
            progress.cash += 300;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) - 15;
          };
        } else if (choice == 'B') {
          description =
              "Grateful Glarus merchants reward your generous toll sponsorship, supplying your estate with +150 food and +100 wood.";
          onConfirmAction = () {
            progress.food += 150;
            progress.wood += 100;
          };
        } else if (choice == 'C') {
          description =
              "Angry about your detour, the Masons block your iron trade routes, costing you 100 iron.";
          onConfirmAction = () {
            progress.iron = max(0, progress.iron - 100);
          };
        } else {
          description =
              "The Masonic Lodge sends armed enforcers to rebuild the toll booth and punish your defiance!";
          onConfirmAction = () {
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createGoon(),
                CombatUnitFactory.createGoon(),
              ],
              eventTitle: "MASONIC REBUILDERS FORCE",
              spoilsFood: 15,
              spoilsCash: 150,
              spoilsIron: 10,
              spoilsWood: 10,
            );
          };
        }
        break;

      case 'alchemical_explosion':
        title = "THE CONTAMINATION REPORT";
        if (choice == 'A') {
          description =
              "The water filters successfully contain the epidemic! Glarus rewards your help with +200 CHF and +15 standing.";
          onConfirmAction = () {
            progress.cash += 200;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) + 15;
          };
        } else if (choice == 'B') {
          description =
              "The water cover-up fails! Furious villagers riot, setting fire to your storage yards and destroying 150 wood and 100 food.";
          onConfirmAction = () {
            progress.wood = max(0, progress.wood - 150);
            progress.food = max(0, progress.food - 100);
          };
        } else if (choice == 'C') {
          description =
              "The unchecked disease spreads to your estate. Your units contract sickness, suffering -20% health in the next 2 battles.\n\n(All units currently in your deck permanently suffer -1 damage and -5 maxHealth!)";
          onConfirmAction = () {
            progress.cardUpgrades['next_combat_health_penalty_percent'] = 20;
            _applyPermanentStatModifierToCurrentDeck(
              progress: progress,
              meleeDamage: -1,
              rangedDamage: -1,
              maxHealth: -5,
            );
          };
        } else {
          description =
              "Angry Rosicrucians deploy alchemical chimeras to break their lead scientist out of your dungeons!";
          onConfirmAction = () {
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createFleshGolem(),
                CombatUnitFactory.createBrownRats(),
              ],
              eventTitle: "ROSICRUCIAN PRISON BREAK",
              spoilsFood: 10,
              spoilsCash: 200,
              spoilsIron: 15,
              spoilsWood: 10,
            );
          };
        }
        break;

      case 'secret_treaty':
        title = "THE ALLIANCE'S RESOLVE";
        if (choice == 'A') {
          description =
              "In fulfillment of the secret treaty, the Knights Templar send an elite veteran Samurai to reinforce your army!";
          onConfirmAction = () {
            if (progress.playerDeckIds.length < 12 &&
                !progress.playerDeckIds.contains('samurai')) {
              progress.playerDeckIds.add('samurai');
              progress.cardUpgrades['level_samurai'] = 3;
            } else {
              progress.iron += 100;
            }
          };
        } else if (choice == 'B') {
          description =
              "The Templars send a shadow assassin to punish your betrayal. Your leader Alphonse is injured, losing 25% max health permanently!";
          onConfirmAction = () {
            progress.cardUpgrades['alphonse_health_penalty'] =
                (progress.cardUpgrades['alphonse_health_penalty'] ?? 0) + 25;
          };
        } else if (choice == 'C') {
          description =
              "Your peaceful neutrality keeps you out of their war. Masons and Templars send small trade dividends, yielding +100 CHF.";
          onConfirmAction = () {
            progress.cash += 100;
          };
        } else {
          description =
              "Templars and Masons launch a coordinated raid to rescue their captured envoys from your dungeons!";
          onConfirmAction = () {
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createCavalry(),
                CombatUnitFactory.createGoon(),
              ],
              eventTitle: "PRISONER RESCUE RAID",
              spoilsFood: 10,
              spoilsCash: 200,
              spoilsIron: 10,
              spoilsWood: 10,
            );
          };
        }
        break;

      case 'carbonari_press':
        title = "THE PRESS'S INFLUENCE";
        if (choice == 'A') {
          description =
              "The pamhplets inspire local rebels! A veteran Goon joins your army, and your units start the next combat with +1 starting AP.";
          onConfirmAction = () {
            if (progress.playerDeckIds.length < 12 &&
                !progress.playerDeckIds.contains('goon')) {
              progress.playerDeckIds.add('goon');
              progress.cardUpgrades['level_goon'] = 3;
            }
            progress.cardUpgrades['next_combat_ap_modifier'] =
                (progress.cardUpgrades['next_combat_ap_modifier'] ?? 0) + 1;
          };
        } else if (choice == 'B') {
          description =
              "Angry Carbonari rebels sabotage your iron mines. You produce 0 iron this turn!";
          onConfirmAction = () {
            progress.iron = max(0, progress.iron - 50);
          };
        } else if (choice == 'C') {
          description =
              "The Carbonari refuse to pay your heavy taxes and steal 200 CHF from your reserves in a late-night heist.";
          onConfirmAction = () {
            progress.cash = max(0, progress.cash - 200);
          };
        } else {
          description =
              "The Carbonari launch an armed assault on your estate to reclaim their printing press!";
          onConfirmAction = () {
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createGoon(),
                CombatUnitFactory.createMilitia(),
              ],
              eventTitle: "PRESS RECLAMATION STRIKE",
              spoilsFood: 5,
              spoilsCash: 100,
              spoilsIron: 5,
              spoilsWood: 20,
            );
          };
        }
        break;

      case 'golden_dawn_relic':
        title = "THE RELIC'S ENERGY";
        if (choice == 'A') {
          description =
              "The relic whispers ancient knowledge. Your scholars achieve a major breakthrough, granting +100 XP distributed to all units in your deck!\n\n(All units currently in your deck permanently gain +0.2 attack range!)";
          onConfirmAction = () {
            for (var t in progress.playerDeckIds) {
              progress.unitExp[t] = (progress.unitExp[t] ?? 0.0) + 100.0;
            }
            _applyPermanentStatModifierToCurrentDeck(
              progress: progress,
              meleeRange: 0.2,
              rangedRange: 0.2,
            );
          };
        } else if (choice == 'B') {
          description =
              "The sold relic was heavily cursed! Your cashbox wood rots, causing a loss of 200 CHF.\n\n(All units currently in your deck permanently suffer -0.1 movement speed and +0.1s attack delay!)";
          onConfirmAction = () {
            progress.cash = max(0, progress.cash - 200);
            _applyPermanentStatModifierToCurrentDeck(
              progress: progress,
              movement: -0.1,
              speed: 0.1,
              meleeAttackSpeed: 0.1,
              rangedAttackSpeed: 0.1,
            );
          };
        } else if (choice == 'C') {
          description =
              "The cathedral blesses your donation, granting all units +2 starting AP and restoring all towers by 30%.";
          onConfirmAction = () {
            progress.cardUpgrades['next_combat_ap_modifier'] =
                (progress.cardUpgrades['next_combat_ap_modifier'] ?? 0) + 2;
            progress.towerDamaged['tower_1'] = max(
              0.0,
              (progress.towerDamaged['tower_1'] ?? 0.0) - 0.3,
            );
            progress.towerDamaged['tower_2'] = max(
              0.0,
              (progress.towerDamaged['tower_2'] ?? 0.0) - 0.3,
            );
            progress.towerDamaged['tower_3'] = max(
              0.0,
              (progress.towerDamaged['tower_3'] ?? 0.0) - 0.3,
            );
          };
        } else {
          description =
              "Smashing the relic released ancient, vengeful spirits that swarm your estate!";
          onConfirmAction = () {
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createWerewolf(),
                CombatUnitFactory.createBrownRats(),
              ],
              eventTitle: "SPECTRAL SPIRITS SWARM",
              spoilsFood: 10,
              spoilsCash: 150,
              spoilsIron: 10,
              spoilsWood: 10,
            );
          };
        }
        break;

      case 'forester_woodcutters':
        title = "THE FOREST'S REACTION";
        if (choice == 'A') {
          description =
              "Nature is pleased by your restraint! Forest druids enrich your estate soil, granting you +200 food.";
          onConfirmAction = () {
            progress.food += 200;
          };
        } else if (choice == 'B') {
          description =
              "Nature strikes back! A pack of rabid wild beasts raids your farms, destroying 150 food and injuring workers (adds 1 bondage debuff to all units).";
          onConfirmAction = () {
            progress.food = max(0, progress.food - 150);
            for (var t in progress.playerDeckIds) {
              progress.bondageDebuffCount[t] =
                  (progress.bondageDebuffCount[t] ?? 0) + 1;
            }
          };
        } else if (choice == 'C') {
          description =
              "Your balanced logging approach pays off! You receive a bonus of +100 wood and +10 standing with both Foresters and Glarus.";
          onConfirmAction = () {
            progress.wood += 100;
            progress.factionStandings['Ancient Order of Foresters'] =
                (progress.factionStandings['Ancient Order of Foresters'] ?? 0) +
                10;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) + 10;
          };
        } else {
          description =
              "Feral forest guardians launch a massive stampede to crush your logging camps!";
          onConfirmAction = () {
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createWildWolves(),
                CombatUnitFactory.createFleshGolem(),
              ],
              eventTitle: "FERAL FOREST STAMPEDE",
              spoilsFood: 20,
              spoilsCash: 100,
              spoilsIron: 5,
              spoilsWood: 100,
            );
          };
        }
        break;

      case 'swiss_banker_loan':
        title = "DEBT COLLECTION DAY";
        if (choice == 'A') {
          description =
              "The Swiss loan is due! You must pay 600 CHF (500 principal + 100 interest). If you cannot afford it, the bank forecloses, seizing 200 wood and 200 iron!";
          onConfirmAction = () {
            if (progress.cash >= 600) {
              progress.cash -= 600;
            } else {
              progress.cash = 0;
              progress.wood = max(0, progress.wood - 200);
              progress.iron = max(0, progress.iron - 200);
            }
          };
        } else if (choice == 'B') {
          description =
              "Your fiscal discipline pays off! Local merchants trust your estate, granting you a permanent 10% discount on all upgrades in the market.";
          onConfirmAction = () {
            progress.cardUpgrades['market_discount_percent'] =
                (progress.cardUpgrades['market_discount_percent'] ?? 0) + 10;
          };
        } else if (choice == 'C') {
          description =
              "Angered by your stolen pensions, your soldiers go on strike, refusing to coordinate. You suffer -3 starting AP in the next combat.";
          onConfirmAction = () {
            progress.cardUpgrades['next_combat_ap_modifier'] =
                (progress.cardUpgrades['next_combat_ap_modifier'] ?? 0) - 3;
          };
        } else {
          description =
              "The Zurich bank sends elite syndicate enforcers to reclaim their stolen gold and eliminate your commanders!";
          onConfirmAction = () {
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createZurichDebtCollector(),
                CombatUnitFactory.createZurichDebtCollector(),
              ],
              eventTitle: "ZURICH HIT SQUAD",
              spoilsFood: 10,
              spoilsCash: 350,
              spoilsIron: 10,
              spoilsWood: 10,
            );
          };
        }
        break;

      case 'grenadier_sabotage':
        title = "THE WINDMILL'S LEGACY";
        if (choice == 'A') {
          description =
              "The rebuilt windmill is fully operational! Grateful Glarus villagers supply your estate with +150 food.";
          onConfirmAction = () {
            progress.food += 150;
          };
        } else if (choice == 'B') {
          description =
              "Insulted by the court-martial, a group of elite grenadiers deserts your army, stealing 100 iron from your armory.";
          onConfirmAction = () {
            progress.iron = max(0, progress.iron - 100);
            if (progress.playerDeckIds.isNotEmpty) {
              progress.playerDeckIds.removeAt(
                Random().nextInt(progress.playerDeckIds.length),
              );
            }
          };
        } else if (choice == 'C') {
          description =
              "Without the windmill, Glarus suffers a terrible famine. Angry, starving villagers raid your estate, stealing 100 food and 100 wood.";
          onConfirmAction = () {
            progress.food = max(0, progress.food - 100);
            progress.wood = max(0, progress.wood - 100);
          };
        } else {
          description =
              "Furious Glarus peasants launch an armed insurrection to burn down your estate in revenge for the windmill!";
          onConfirmAction = () {
            _startEventCombat(
              progress: progress,
              service: service,
              state: state,
              aiUnits: [
                CombatUnitFactory.createMilitia(),
                CombatUnitFactory.createGoon(),
              ],
              eventTitle: "PEASANT INSURRECTION",
              spoilsFood: 15,
              spoilsCash: 80,
              spoilsIron: 5,
              spoilsWood: 10,
            );
          };
        }
        break;

      default:
        return;
    }

    _showRippleEffectDialog(
      context,
      title,
      description,
      onConfirmAction,
      service,
    );
  }
 
  void _evaluateDiceOutcome(int total, SurvivalProgress progress, SurvivalService service) {
    _lastDiceTotal = total;
    final state = Provider.of<GameState>(context, listen: false);

    String logDesc = 'Fate Event triggered.';
    switch (total) {
      case 2:
        logDesc = 'Disaster check triggered.';
        break;
      case 3:
        logDesc = 'Robbery check triggered.';
        break;
      case 4:
        logDesc = 'Disease check: -2 AP next combat.';
        break;
      case 5:
        logDesc = 'Fire check triggered.';
        break;
      case 6:
        logDesc = 'Crop Blight check triggered.';
        break;
      case 7:
        logDesc = 'Travel Encounter triggered.';
        break;
      case 8:
        logDesc = 'Market discount sale triggered.';
        break;
      case 9:
        logDesc = 'Bounty: Double estate production.';
        break;
      case 10:
        logDesc = 'Rest: +2 AP next combat.';
        break;
      case 11:
        logDesc = 'Volunteer joins army.';
        break;
      case 12:
        logDesc = 'Discovery check triggered.';
        break;
      default:
        logDesc = 'Nothing happens.';
    }
    service.addLog('FATE\'S ROLL: Rolled $total ($_die1 + $_die2). $logDesc');

    switch (total) {
      case 2:
        _diceOutcomeMessage = "ROLLED A 2!\nA disaster threatens the estate! Acknowledge to resolve.";
        _diceOutcomeAction = () {
          _showDisasterOutcome(progress, service);
        };
        break;

      case 3:
        final int lossPercent = _die1 == 2 ? 100 : (_die1 == 1 ? 60 : 0);
        if (lossPercent > 0 && progress.cash > 0) {
          final lostAmount = (progress.cash * (lossPercent / 100.0)).toInt();
          _diceOutcomeMessage = "ROLLED A 3! Robbery!\nLost $lostAmount CHF.";
          _diceOutcomeAction = () {
            progress.cash = max(0, progress.cash - lostAmount);
            service.manualSave();
          };
          service.addLog('Robbery: Lost $lostAmount CHF.');
        } else {
          _diceOutcomeMessage = "ROLLED A 3! Robbery!\nOutlaws failed to breach our cashbox. No loss.";
          _diceOutcomeAction = null;
        }
        break;

      case 4:
        _diceOutcomeMessage = "ROLLED A 4! Disease!\nOutbreak: Starting combat AP is reduced by 2 in the next combat.";
        _diceOutcomeAction = () {
          progress.cardUpgrades['next_combat_ap_modifier'] = (progress.cardUpgrades['next_combat_ap_modifier'] ?? 0) - 2;
          service.manualSave();
        };
        service.addLog('Disease: -2 starting AP next combat.');
        break;

      case 5:
        int metalLossPercent = 0;
        int woodLossPercent = 0;
        if (_die1 == 4) {
          metalLossPercent = 100;
        } else if (_die1 == 3) {
          metalLossPercent = 60;
          woodLossPercent = 40;
        } else if (_die1 == 2) {
          metalLossPercent = 40;
          woodLossPercent = 60;
        } else if (_die1 == 1) {
          woodLossPercent = 100;
        }
        final lostMetal = (progress.iron * (metalLossPercent / 100.0)).toInt();
        final lostWood = (progress.wood * (woodLossPercent / 100.0)).toInt();
        
        final List<String> losses = [];
        if (lostMetal > 0) losses.add('Lost $lostMetal Metal');
        if (lostWood > 0) losses.add('Lost $lostWood Wood');
        
        if (losses.isNotEmpty) {
          _diceOutcomeMessage = "ROLLED A 5! Fire!\n${losses.join(' and ')}.";
        } else {
          _diceOutcomeMessage = "ROLLED A 5! Fire!\nNo resources were lost.";
        }
        
        _diceOutcomeAction = () {
          progress.iron = max(0, progress.iron - lostMetal);
          progress.wood = max(0, progress.wood - lostWood);
          service.manualSave();
        };
        service.addLog('Fire: Lost $lostMetal metal, $lostWood wood.');
        break;

      case 6:
        int blightPercent = 0;
        if (_die1 == 5) blightPercent = 90;
        else if (_die1 == 4) blightPercent = 75;
        else if (_die1 == 3) blightPercent = 60;
        else if (_die1 == 2) blightPercent = 45;
        else if (_die1 == 1) blightPercent = 30;

        final lostFood = (progress.food * (blightPercent / 100.0)).toInt();
        if (lostFood > 0) {
          _diceOutcomeMessage = "ROLLED A 6! Crop Blight!\nLost $lostFood Food.";
          _diceOutcomeAction = () {
            progress.food = max(0, progress.food - lostFood);
            service.manualSave();
          };
          service.addLog('Blight: Lost $lostFood food.');
        } else {
          _diceOutcomeMessage = "ROLLED A 6! Crop Blight!\nNo food was lost.";
          _diceOutcomeAction = null;
        }
        break;

      case 7:
        final index = progress.cardUpgrades['next_encounter_index'] ?? 0;
        final encountersList = [
          'gnomes_artillery',
          'freemasons_tribute',
          'alchemist_transmutation',
          'templar_levy',
          'carbonari_strike',
          'golden_dawn_seance',
          'fenian_gunrunning',
          'french_cavalry',
          'adrenochrome_syndicate',
          'bank_audit',
          'mystic_herbs',
          'irish_mutiny',
          'monarchist_ball',
          'masonic_toll',
          'alchemical_explosion',
          'secret_treaty',
          'carbonari_press',
          'golden_dawn_relic',
          'forester_woodcutters',
          'swiss_banker_loan',
          'grenadier_sabotage',
        ];

        if (progress.villageHealth <= 0) {
          encountersList.addAll([
            'glarus_refugees_resettle',
            'glarus_caravan_stay',
            'glarus_missionaries_buy',
            'glarus_farmers_grant',
          ]);
        }

        final deckSize = encountersList.length;
        // Initialize shuffled deck if not already done
        if (progress.cardUpgrades['encounter_deck_initialized'] != 1) {
          final indices = List<int>.generate(deckSize, (i) => i)..shuffle();
          for (int i = 0; i < deckSize; i++) {
            progress.cardUpgrades['encounter_deck_pos_$i'] = indices[i];
          }
          progress.cardUpgrades['encounter_deck_initialized'] = 1;
          progress.cardUpgrades['next_encounter_index'] = 0;
        }

        // Retrieve next unresolved encounter using the shuffled deck
        String? nextEncounterId;
        int foundPointer = index;

        for (int i = 0; i < deckSize; i++) {
          final checkPointer = (index + i) % deckSize;
          final shuffledIdx = progress.cardUpgrades['encounter_deck_pos_$checkPointer'] ?? checkPointer;
          final finalIdx = shuffledIdx.clamp(0, deckSize - 1);
          final encId = encountersList[finalIdx];

          if (progress.cardUpgrades['encounter_${encId}_resolved'] != 1) {
            nextEncounterId = encId;
            foundPointer = checkPointer;
            break;
          }
        }

        // Recycle and reshuffle if all are resolved
        if (nextEncounterId == null) {
          for (final encId in encountersList) {
            progress.cardUpgrades.remove('encounter_${encId}_resolved');
          }
          final indices = List<int>.generate(deckSize, (i) => i)..shuffle();
          for (int i = 0; i < deckSize; i++) {
            progress.cardUpgrades['encounter_deck_pos_$i'] = indices[i];
          }
          progress.cardUpgrades['encounter_deck_initialized'] = 1;
          progress.cardUpgrades['next_encounter_index'] = 0;

          for (int i = 0; i < deckSize; i++) {
            final checkPointer = i;
            final shuffledIdx = progress.cardUpgrades['encounter_deck_pos_$checkPointer'] ?? checkPointer;
            final finalIdx = shuffledIdx.clamp(0, deckSize - 1);
            final encId = encountersList[finalIdx];
            if (progress.cardUpgrades['encounter_${encId}_resolved'] != 1) {
              nextEncounterId = encId;
              foundPointer = checkPointer;
              break;
            }
          }
        }

        if (nextEncounterId != null) {
          progress.cardUpgrades['next_encounter_index'] = (foundPointer + 1) % deckSize;
          _diceOutcomeMessage = "ROLLED A 7!\nTravel Encounter: ${nextEncounterId.replaceAll('_', ' ').toUpperCase()}";
          _diceOutcomeAction = () {
            _showNarrativeEncounter(
              context,
              nextEncounterId!,
              progress,
              service,
              state,
            );
          };
        } else {
          _diceOutcomeMessage = "ROLLED A 7!\nHowever, all travel encounters have already been resolved.";
          _diceOutcomeAction = null;
        }
        break;

      case 8:
        final discountPercent = _die1 * 10;
        _diceOutcomeMessage = "ROLLED AN 8! Sale!\nTraveling merchants discount all Market purchases by $discountPercent% this turn.";
        _diceOutcomeAction = () {
          progress.cardUpgrades['market_temp_discount'] = discountPercent;
          service.manualSave();
        };
        service.addLog('Sale: Unlocked $discountPercent% temporary market discount.');
        break;

      case 9:
        _diceOutcomeMessage = "ROLLED A 9! Bounty!\nDouble all estate facility production this turn!";
        _diceOutcomeAction = () {
          progress.cardUpgrades['double_estate_production'] = 1;
          service.manualSave();
        };
        service.addLog('Bounty: Double estate production activated.');
        break;

      case 10:
        _diceOutcomeMessage =
            "ROLLED A 10! Rest!\nBarracks rest: Start the next combat with +2 starting AP.";
        _diceOutcomeAction = () {
          progress.cardUpgrades['next_combat_ap_modifier'] = (progress.cardUpgrades['next_combat_ap_modifier'] ?? 0) + 2;
          service.manualSave();
        };
        service.addLog('Rest: +2 AP starting next combat.');
        break;

      case 11:
        final possibleVolunteers = [
          'peasant',
          'goon',
          'militia',
          'samurai',
          'musketeers',
          'commandos',
          'werewolf',
          'flesh_golem',
          'chimera',
          'undead_rats',
          'cannoneer',
          'cavalry',
          'wooden_tank',
          'marksmen',
        ];
        final candidates = possibleVolunteers.where((t) => !progress.playerDeckIds.contains(t)).toList();
        if (candidates.isEmpty) {
          _diceOutcomeMessage = "ROLLED AN 11! Volunteer!\nHowever, all possible unit types are already present in your army.";
          _diceOutcomeAction = null;
        } else {
          final candidate = candidates[Random().nextInt(candidates.length)];
          int totalLevels = 0;
          for (var cardId in progress.playerDeckIds) {
            totalLevels += progress.getUnitLevel(cardId);
          }
          final meanLevel = progress.playerDeckIds.isNotEmpty ? (totalLevels ~/ progress.playerDeckIds.length).clamp(1, 6) : 1;

          if (progress.playerDeckIds.length < 12) {
            _diceOutcomeMessage = "ROLLED AN 11! Volunteer joins!\nA Level $meanLevel ${candidate.replaceAll('_', ' ').toUpperCase()} offers their blade to your army!";
            _diceOutcomeAction = () {
              progress.playerDeckIds.add(candidate);
              progress.cardUpgrades['level_$candidate'] = meanLevel;
              progress.unitExp[candidate] = 0.0;
              service.manualSave();
            };
            service.addLog('Volunteer: Level $meanLevel $candidate joined deck.');
          } else {
            _diceOutcomeMessage = "ROLLED AN 11! Volunteer request!\nA Level $meanLevel ${candidate.replaceAll('_', ' ').toUpperCase()} wants to volunteer, but your army is full (12/12).";
            _diceOutcomeAction = () {
              _showVolunteerCapacityDialog(candidate, meanLevel, progress, service);
            };
          }
        }
        break;

      case 12:
        final List<Map<String, dynamic>> eligibleDiscoveries = [];

        // Glarus Ruins Scavenge (Conditional Discovery when Glarus is destroyed)
        if (progress.villageHealth <= 0) {
          eligibleDiscoveries.add({
            'id': 'glarus_ruins_scavenge',
            'title': 'GLARUS RUINS SCAVENGE',
            'description': 'Scavengers searching the abandoned ruins of Glarus village have recovered a hidden stash of supplies! We obtained +400 CHF, +100 wood, and +100 iron!',
            'run': () {
              progress.cash += 400;
              progress.wood += 100;
              progress.iron += 100;
            }
          });
        }

        final royalistStanding = progress.factionStandings['Army'] ?? 0;
        if (royalistStanding > 10) {
          eligibleDiscoveries.add({
            'id': 'geneva_diplomatic_gift',
            'title': 'GENEVA DIPLOMATIC GIFT',
            'description': 'Due to our strong reputation with the Royalists, Geneva has sent us a diplomatic gift containing +500 CHF and 10 food rations!',
            'run': () {
              progress.cash += 500;
              progress.food += 10;
            }
          });
        }

        final carbStanding = progress.factionStandings['Carbonari'] ?? 0;
        if (carbStanding > 10) {
          eligibleDiscoveries.add({
            'id': 'carbonari_cache',
            'title': 'CARBONARI CACHE',
            'description': 'The Carbonari have shared coordinates to a hidden rebel weapons cache. We obtained +100 metal and +50 wood!',
            'run': () {
              progress.iron += 100;
              progress.wood += 50;
            }
          });
        }

        if (royalistStanding > 10) {
          eligibleDiscoveries.add({
            'id': 'army_reserve_supplies',
            'title': 'ARMY RESERVE SUPPLIES',
            'description': 'The Federal Army has delivered emergency logistics support, granting us +200 food and +50 metal!',
            'run': () {
              progress.food += 200;
              progress.iron += 50;
            }
          });
        }

        if (progress.buildings.any((b) => b.type == SurvivalBuildingType.mine)) {
          eligibleDiscoveries.add({
            'id': 'deep_vein_silver',
            'title': 'DEEP VEIN SILVER OUTCROP',
            'description': 'Miners have struck a rich silver vein! We obtained +400 CHF and +50 metal.',
            'run': () {
              progress.cash += 400;
              progress.iron += 50;
            }
          });
        }

        if (progress.buildings.any((b) => b.type == SurvivalBuildingType.farm)) {
          eligibleDiscoveries.add({
            'id': 'greenhouse_thermal_synergy',
            'title': 'GREENHOUSE THERMAL SYNERGY',
            'description': 'Farming optimizations have resulted in a record crop harvest, adding +200 food!',
            'run': () {
              progress.food += 200;
            }
          });
        }

        if (progress.buildings.any((b) => b.type == SurvivalBuildingType.lumberMill)) {
          eligibleDiscoveries.add({
            'id': 'workshop_lathe_calibration',
            'title': 'WORKSHOP LATHE CALIBRATION',
            'description': 'Lumber Mill adjustments have significantly optimized wood output, yielding +200 wood!',
            'run': () {
              progress.wood += 200;
            }
          });
        }

        if (progress.buildings.any((b) => b.type == SurvivalBuildingType.munitionsFactory)) {
          eligibleDiscoveries.add({
            'id': 'munitions_quality_control',
            'title': 'MUNITIONS QUALITY CONTROL',
            'description': 'Superb testing yields +100 metal and grants +25 XP to all munitions workers!',
            'run': () {
              progress.iron += 100;
              final factory = progress.buildings.firstWhereOrNull((b) => b.type == SurvivalBuildingType.munitionsFactory);
              if (factory != null) {
                for (var cardType in factory.assignedUnitIds) {
                  progress.unitExp[cardType] = (progress.unitExp[cardType] ?? 0.0) + 25.0;
                }
              }
            }
          });
        }

        if (progress.buildings.any((b) => b.type == SurvivalBuildingType.arsenal)) {
          eligibleDiscoveries.add({
            'id': 'distillery_reserve_vintage',
            'title': 'DISTILLERY RESERVE VINTAGE',
            'description': 'Refined tactical training improves tower efficiency, boosting all watchtower attack power by 10% permanently!',
            'run': () {
              progress.cardUpgrades['tower_damage_multiplier'] = (progress.cardUpgrades['tower_damage_multiplier'] ?? 100) + 10;
            }
          });
        }

        if (progress.buildings.any((b) => b.type == SurvivalBuildingType.farm)) {
          eligibleDiscoveries.add({
            'id': 'kitchen_culinary_mastery',
            'title': 'KITCHEN CULINARY MASTERY',
            'description': 'A wonderful harvest feast has restored our soldiers! Cured 1 turn of starvation for all units in the deck.',
            'run': () {
              for (var t in progress.starvationInfractions.keys) {
                progress.starvationInfractions[t] = max(0, (progress.starvationInfractions[t] ?? 0) - 1);
              }
            }
          });
        }

        if (royalistStanding > 10) {
          eligibleDiscoveries.add({
            'id': 'library_cataloguing_method',
            'title': 'LIBRARY CATALOGUING METHOD',
            'description': 'Intellectual trade records optimize our resource acquisition, reducing all market upgrade costs by 15%.',
            'run': () {
              progress.cardUpgrades['market_discount_percent'] = (progress.cardUpgrades['market_discount_percent'] ?? 0) + 15;
            }
          });
        }

        if (progress.buildings.any((b) => b.type == SurvivalBuildingType.farm) && progress.currentTurn >= 10) {
          eligibleDiscoveries.add({
            'id': 'double_chick_hatching',
            'title': 'DOUBLE CHICK HATCHING',
            'description': 'Superb poultry breeding yields a bumper harvest of food reserves (+150 food).',
            'run': () {
              progress.food += 150;
            }
          });
        }

        if (progress.buildings.any((b) => b.type == SurvivalBuildingType.mine)) {
          eligibleDiscoveries.add({
            'id': 'excavation_fossil',
            'title': 'EXCAVATION FOSSIL SPECIMEN',
            'description': 'Mine workers unearthed a valuable fossil specimen and sold it to the Geneva Museum for +350 CHF!',
            'run': () {
              progress.cash += 350;
            }
          });
        }

        if (progress.buildings.any((b) => b.type == SurvivalBuildingType.farm) && progress.food > 100) {
          eligibleDiscoveries.add({
            'id': 'smoker_perfect_cure',
            'title': 'SMOKER PERFECT CURE',
            'description': 'A master wood-smoke cure has increased the preservation value of our larder (+100 food).',
            'run': () {
              progress.food += 100;
            }
          });
        }

        if (royalistStanding > 15) {
          eligibleDiscoveries.add({
            'id': 'infirmary_sanitation_methods',
            'title': 'INFIRMARY SANITATION METHODS',
            'description': 'Advanced hygiene methods successfully remove all illness and combat debuffs from all units in the deck.',
            'run': () {
              progress.bondageDebuffCount.clear();
            }
          });
        }

        if (progress.buildings.any((b) => b.type == SurvivalBuildingType.farm)) {
          eligibleDiscoveries.add({
            'id': 'well_filtration_system',
            'title': 'WELL FILTRATION SYSTEM',
            'description': 'A charcoal filter installation permanently increases watchtower maximum health by 10%!',
            'run': () {
              progress.cardUpgrades['tower_health_multiplier'] = (progress.cardUpgrades['tower_health_multiplier'] ?? 100) + 10;
            }
          });
        }

        final glarusPrizeStanding = progress.factionStandings['Glarus'] ?? 0;
        if (glarusPrizeStanding > 15) {
          eligibleDiscoveries.add({
            'id': 'brewery_canton_prize',
            'title': 'BREWERY CANTON PRIZE',
            'description': 'Our craft ales won the Canton prize, awarding us +300 CHF and +50 food!',
            'run': () {
              progress.cash += 300;
              progress.food += 50;
            }
          });
        }

        if (progress.buildings.any((b) => b.type == SurvivalBuildingType.arsenal) && progress.playerDeckIds.contains('artillery_barrage')) {
          eligibleDiscoveries.add({
            'id': 'artillery_alignment',
            'title': 'ARTILLERY ALIGNMENT',
            'description': 'Advanced optical scopes increase the base damage of the Artillery Barrage support card by 30% permanently.',
            'run': () {
              progress.cardUpgrades['artillery_damage_multiplier'] = (progress.cardUpgrades['artillery_damage_multiplier'] ?? 100) + 30;
            }
          });
        }

        if (progress.buildings.any((b) => b.type == SurvivalBuildingType.farm)) {
          eligibleDiscoveries.add({
            'id': 'faba_nitrogen_absorption',
            'title': 'FABA NITROGEN ABSORPTION',
            'description': 'Crop rotation fixes nitrogen in the soil, adding +100 food and +50 wood to our reserves.',
            'run': () {
              progress.food += 100;
              progress.wood += 50;
            }
          });
        }

        if (progress.buildings.any((b) => b.type == SurvivalBuildingType.mine)) {
          eligibleDiscoveries.add({
            'id': 'basement_fungal_growth',
            'title': 'BASEMENT FUNGAL GROWTH',
            'description': 'Fungi thrive in the damp subterranean mine shafts, yielding +100 food.',
            'run': () {
              progress.food += 100;
            }
          });
        }

        if (progress.buildings.any((b) => b.type == SurvivalBuildingType.munitionsFactory)) {
          eligibleDiscoveries.add({
            'id': 'forge_blast_furnace',
            'title': 'FORGE BLAST FURNACE TECHNIQUE',
            'description': 'Technique improvements reduce smelting loss, adding +150 metal to our reserves.',
            'run': () {
              progress.iron += 150;
            }
          });
        }

        final List<Map<String, dynamic>> genericDiscoveries = [
          {
            'id': 'lost_cashbox',
            'title': 'THE LOST GENEVAN TREASURE',
            'description':
                'Unearth a vintage iron-bound chest containing a lost Genevan treasure! Grants +500 CHF and 1 level promotion to the most experienced unit in your deck!',
            'run': () {
              progress.cash += 500;
              if (progress.playerDeckIds.isNotEmpty) {
                String? bestCard;
                double maxExp = -1;
                for (final t in progress.playerDeckIds) {
                  final xp = progress.unitExp[t] ?? 0.0;
                  if (xp > maxExp) {
                    maxExp = xp;
                    bestCard = t;
                  }
                }
                if (bestCard != null) {
                  progress.addXpToUnit(
                    bestCard,
                    SurvivalProgress.getRequiredXpForLevel(
                      progress.getUnitLevel(bestCard) + 1,
                    ).toDouble(),
                  );
                }
              }
            },
          },
          {
            'id': 'ammunition_crate',
            'title': 'SURPLUS ARMY MUNITIONS CRATE',
            'description':
                'A heavy, sealed military supply wagon is recovered! Yields +100 food, +150 metal, and all squad/melee units in your deck gain +1 base melee damage permanently from high-quality steel sharpening kits!',
            'run': () {
              progress.food += 100;
              progress.iron += 150;
              for (final t in progress.playerDeckIds) {
                final npc = CombatUnitService.createUnit(t);
                final isMelee =
                    npc.combatStats != null &&
                    npc.combatStats!.distance < 3.0 &&
                    !SurvivalService.isConstruct(npc);
                if (isMelee) {
                  final current =
                      progress.cardUpgrades['${t}_stat_meleeDamage_bonus'] ?? 0;
                  progress.cardUpgrades['${t}_stat_meleeDamage_bonus'] =
                      current + 1;
                }
              }
            },
          },
          {
            'id': 'abandoned_construction',
            'title': 'ABANDONED CONSTRUCTION PILE',
            'description': 'Planks and metal fixtures are scavenged from an abandoned site, yielding +150 wood and +50 metal.',
            'run': () {
              progress.wood += 150;
              progress.iron += 50;
            },
          },
          {
            'id': 'weather_window',
            'title': 'IDEAL WEATHER WINDOW',
            'description':
                'Clear, perfect weather boosts general collection, yielding +200 food, +200 wood, and all units in your current deck gain +0.5 movement speed permanently from marching drills!',
            'run': () {
              progress.food += 200;
              progress.wood += 200;
              for (final t in progress.playerDeckIds) {
                final current =
                    progress.cardUpgrades['${t}_stat_movement_bonus'] ?? 0;
                progress.cardUpgrades['${t}_stat_movement_bonus'] =
                    current + 50;
              }
            },
          },
          {
            'id': 'wild_crop_seedlings',
            'title': 'WILD CROP BUMPER SEEDLINGS',
            'description':
                'Find wild edible tubers and alchemical herbs growing along the riverside, adding +150 food and permanently increasing the max health of all non-construct cards in your current deck by +5 Max Health!',
            'run': () {
              progress.food += 150;
              for (final t in progress.playerDeckIds) {
                final npc = CombatUnitService.createUnit(t);
                if (!SurvivalService.isConstruct(npc)) {
                  final current =
                      progress.cardUpgrades['${t}_stat_maxHealth_bonus'] ?? 0;
                  progress.cardUpgrades['${t}_stat_maxHealth_bonus'] =
                      current + 5;
                }
              }
            },
          },
          {
            'id': 'draft_horse_recruit',
            'title': 'DRAFT HORSE RECRUIT',
            'description': 'A lost draft horse wanders into our camp! Its labor permanently reduces the wood cost of future facility construction by 10%.',
            'run': () {
              progress.cardUpgrades['wood_construction_discount_percent'] = (progress.cardUpgrades['wood_construction_discount_percent'] ?? 0) + 10;
            },
          },
          {
            'id': 'iron_ore_deposit',
            'title': 'RICH SURFACE IRON VEIN',
            'description':
                'Find a shallow surface outcrop of high-grade iron ore! Yields +150 metal and permanently increases the max health of all constructs/machines in your current deck by +15 Max Health due to steel armor reinforcements!',
            'run': () {
              progress.iron += 150;
              for (final t in progress.playerDeckIds) {
                final npc = CombatUnitService.createUnit(t);
                if (SurvivalService.isConstruct(npc)) {
                  final current =
                      progress.cardUpgrades['${t}_stat_maxHealth_bonus'] ?? 0;
                  progress.cardUpgrades['${t}_stat_maxHealth_bonus'] =
                      current + 15;
                }
              }
            },
          },
          {
            'id': 'military_logbook',
            'title': 'MILITARY LOGBOOK',
            'description': 'Unearth a tactical command manual. A random combat card in your army gains +100 XP.',
            'run': () {
              if (progress.playerDeckIds.isNotEmpty) {
                final randomUnit = progress.playerDeckIds[Random().nextInt(progress.playerDeckIds.length)];
                progress.unitExp[randomUnit] = (progress.unitExp[randomUnit] ?? 0.0) + 100.0;
              }
            },
          },
          {
            'id': 'glarus_trade_voucher',
            'title': 'GLARUS INDUSTRIAL TRADE VOUCHER',
            'description':
                'Recover a high-value merchant bank order and trade voucher! Adds +300 CHF, and permanently reduces all Weapon Market upgrade and hiring costs by 10%!',
            'run': () {
              progress.cash += 300;
              progress.cardUpgrades['market_discount_percent'] =
                  (progress.cardUpgrades['market_discount_percent'] ?? 0) + 10;
            },
          },
          {
            'id': 'aethelgards_ring',
            'title': 'AETHELGARD\'S RING',
            'description': 'Discover a lost royalist ring. Returning it boosts Glarus Canton standing by +10.',
            'run': () {
              progress.factionStandings['Glarus'] = (progress.factionStandings['Glarus'] ?? 0) + 10;
            },
          },
          {
            'id': 'fresh_water_spring',
            'title': 'FRESH WATER SPRING',
            'description': 'A clean spring bubble reduces crop dependency, saving food consumption for all units next turn.',
            'run': () {
              progress.cardUpgrades['next_turn_food_reduction'] = 20;
            },
          },
          {
            'id': 'merchants_lost_ledger',
            'title': 'MERCHANT\'S LOST LEDGER',
            'description': 'Recover a merchant\'s missing trade index. Unlocks a permanent 10% discount on all upgrades in the Weapon Market.',
            'run': () {
              progress.cardUpgrades['market_discount_percent'] = (progress.cardUpgrades['market_discount_percent'] ?? 0) + 10;
            },
          },
          {
            'id': 'forgotten_gunpowder_stash',
            'title': 'FORGOTTEN BLACK POWDER ARSENAL',
            'description':
                'Uncover a massive, sealed crate of vintage black powder! Yields +100 wood, +100 iron, and all ranged cards in your current deck gain +1 base ranged damage permanently!',
            'run': () {
              progress.iron += 100;
              progress.wood += 100;
              for (final t in progress.playerDeckIds) {
                final npc = CombatUnitService.createUnit(t);
                final isRanged =
                    npc.combatStats != null && npc.combatStats!.distance >= 3.0;
                if (isRanged) {
                  final current =
                      progress.cardUpgrades['${t}_stat_rangedDamage_bonus'] ??
                      0;
                  progress.cardUpgrades['${t}_stat_rangedDamage_bonus'] =
                      current + 1;
                }
              }
            },
          },
          {
            'id': 'migrating_waterfowl',
            'title': 'MIGRATING WATERFOWL TARGET PRACTICE',
            'description':
                'A massive flock of wild ducks lands in the marsh! Our army uses them for hunting target practice, harvesting +120 food. Furthermore, all cards in your current deck with a ranged attack gain +0.1 attack range permanently!',
            'run': () {
              progress.food += 120;
              for (final t in progress.playerDeckIds) {
                final npc = CombatUnitService.createUnit(t);
                final isRanged =
                    npc.combatStats != null && npc.combatStats!.distance >= 3.0;
                if (isRanged) {
                  final current =
                      progress.cardUpgrades['${t}_stat_rangedRange_bonus'] ?? 0;
                  progress.cardUpgrades['${t}_stat_rangedRange_bonus'] =
                      current + 10;
                }
              }
            },
          },
          {
            'id': 'forge_upgrades_crate',
            'title': 'FORGE UPGRADES CRATE',
            'description': 'Casting fixtures are salvaged, reducing the metal cost of our next watchtower upgrade by 25%.',
            'run': () {
              progress.cardUpgrades['next_tower_metal_discount_percent'] = 25;
            },
          },
          {
            'id': 'surplus_medical_crate',
            'title': 'SURPLUS MEDICAL CRATE',
            'description': 'Recover a pack of clean field bandages, removing all negative status debuffs from all units in our army.',
            'run': () => progress.bondageDebuffCount.clear(),
          },
          {
            'id': 'inspiring_mountain_vista',
            'title': 'MAJESTIC ALPINE RESOLVE',
            'description':
                'Stunning alpine sunrise resolves our troops! All cards start the next combat with +2 AP, and all cards in your current deck gain +0.5 movement speed permanently!',
            'run': () {
              progress.cardUpgrades['next_combat_ap_modifier'] =
                  (progress.cardUpgrades['next_combat_ap_modifier'] ?? 0) + 2;
              for (final t in progress.playerDeckIds) {
                final current =
                    progress.cardUpgrades['${t}_stat_movement_bonus'] ?? 0;
                progress.cardUpgrades['${t}_stat_movement_bonus'] =
                    current + 50;
              }
            },
          },
          {
            'id': 'iron_pickaxe_crate',
            'title': 'PIONEER STEEL PICKAXE CRATE',
            'description':
                'Find a collection of heavy steel mining picks, yielding +150 metal and permanently increasing all Watchtower maximum health by 10%!',
            'run': () {
              progress.iron += 150;
              progress.cardUpgrades['tower_health_multiplier'] =
                  (progress.cardUpgrades['tower_health_multiplier'] ?? 100) +
                  10;
            },
          },
          {
            'id': 'calming_herbage',
            'title': 'CALMING HERBAGE',
            'description': 'Soothing wild chamomile immediately cures the starvation stats of one random unit in your deck.',
            'run': () {
              if (progress.starvationInfractions.isNotEmpty) {
                final randomUnit = progress.starvationInfractions.keys.toList()[Random().nextInt(progress.starvationInfractions.length)];
                progress.starvationInfractions[randomUnit] = 0;
              }
            },
          },
          {
            'id': 'subterranean_cave_node',
            'title': 'SUBTERRANEAN CAVE NODE',
            'description': 'Excavators reveal a safe cave system. Adds 1 extra building plot to our estate.',
            'run': () {
              final nextPlotId = 'plot_${String.fromCharCode(97 + progress.purchasedPlots.length)}';
              progress.purchasedPlots.add(nextPlotId);
            },
          }
        ];

        final List<Map<String, dynamic>> discoveryPool = [];
        discoveryPool.addAll(genericDiscoveries);
        discoveryPool.addAll(eligibleDiscoveries);

        final selected = discoveryPool[Random().nextInt(discoveryPool.length)];
        final discoveryId = selected['id'] as String;
        final isAlreadyUnlocked = progress.cardUpgrades['discovery_${discoveryId}_unlocked'] == 1;

        if (isAlreadyUnlocked) {
          _diceOutcomeMessage = "ROLLED A 12!\nScientific Discovery: Drew already unlocked $discoveryId. You discover nothing this turn.";
          _diceOutcomeAction = null;
          service.addLog('Discovery: Drew already unlocked $discoveryId. Nothing discovered.');
        } else {
          progress.cardUpgrades['discovery_${discoveryId}_unlocked'] = 1;
          _diceOutcomeMessage = "ROLLED A 12!\nScientific Discovery: ${selected['title']}\n${selected['description']}";
          _diceOutcomeAction = () {
            selected['run']();
            service.manualSave();
          };
          service.addLog('Discovery: Unlocked ${selected['title']}.');
        }
        break;

      default:
        _diceOutcomeMessage = "ROLLED A $total.\nNothing happens this turn.";
        _diceOutcomeAction = null;
        break;
    }

    setState(() {});
  }

  void _showDisasterOutcome(
    SurvivalProgress progress,
    SurvivalService service,
  ) {
    final List<Map<String, dynamic>> eligibleDisasters = [];

    // Glarus Fallow Outlaw Raiders (Conditional Disaster when Glarus is destroyed)
    if (progress.villageHealth <= 0) {
      eligibleDisasters.add({
        'id': 'glarus_fallow_outlaw_raiders',
        'title': 'GLARUS FALLOW OUTLAW RAIDERS',
        'description': 'Glarus village lies in ruins, attracting lawless bandits to nest there. Raiders stormed our estate, stealing 300 CHF and 150 food reserves!',
        'run': () {
          progress.cash = max(0, progress.cash - 300);
          progress.food = max(0, progress.food - 150);
          service.addLog('Disaster Glarus Outlaw Raiders: Stole 300 CHF and 150 Food.');
        }
      });
    }

    // Munitions Factory Blowout
    if (progress.buildings.any((b) => b.type == SurvivalBuildingType.munitionsFactory)) {
      eligibleDisasters.add({
        'id': 'munitions_factory_blowout',
        'title': 'MUNITIONS FACTORY BLOWOUT',
        'description': 'A massive chemical accident has occurred in the Munitions Factory! The factory is destroyed and a worker assigned to it has been killed.',
        'run': () {
          final factory = progress.buildings.firstWhereOrNull((b) => b.type == SurvivalBuildingType.munitionsFactory);
          if (factory != null) {
            progress.buildings.remove(factory);
            if (factory.assignedUnitIds.isNotEmpty) {
              final killedType = factory.assignedUnitIds.first;
              progress.playerDeckIds.remove(killedType);
              service.addLog('Disaster Munitions Factory blowout: Destroyed facility, and killed $killedType.');
            } else {
              service.addLog('Disaster Munitions Factory blowout: Destroyed facility.');
            }
          }
        }
      });
    }

    // Zoonotic Farm Outbreak
    if (progress.buildings.any((b) => b.type == SurvivalBuildingType.farm)) {
      eligibleDisasters.add({
        'id': 'zoonotic_farm_outbreak',
        'title': 'ZOONOTIC FARM OUTBREAK',
        'description': 'A severe infection has broken out on the farm! The crop workers have had their XP progress reset to 0 and will start the next combat with a 50% health penalty.',
        'run': () {
          final farm = progress.buildings.firstWhereOrNull((b) => b.type == SurvivalBuildingType.farm);
          if (farm != null) {
            final hasVectors =
                globalGameState?.unlockedDiscoveries.contains(
                  'immunological_vectors',
                ) ??
                false;
            for (var cardType in farm.assignedUnitIds) {
              if (hasVectors) {
                service.addLog(
                  'Immunological Vectors protected $cardType from the Zoonotic Outbreak!',
                );
                continue;
              }
              progress.unitExp[cardType] = 0.0;
              progress.bondageDebuffCount[cardType] = (progress.bondageDebuffCount[cardType] ?? 0) + 1;
              service.addLog('Disaster Zoonotic Farm Outbreak: Reset XP and applied sick debuff to $cardType.');
            }
          }
        }
      });
    }

    // Glarus Peasant Border Raid
    final glarusStanding = progress.factionStandings['Glarus'] ?? 0;
    if (glarusStanding < -10) {
      eligibleDisasters.add({
        'id': 'glarus_peasant_raid',
        'title': 'GLARUS PEASANT BORDER RAID',
        'description': 'Angry Glarus rebels have raided our borders! We lost 50% of our cash, and Tower 1 has been destroyed.',
        'run': () {
          progress.cash = (progress.cash * 0.5).toInt();
          progress.towerDamaged['tower_1'] = 1.0;
          service.addLog('Disaster Glarus Peasant Raid: Lost 50% cash and destroyed Tower 1.');
        }
      });
    }

    // Royalist Trade Blockade
    final armyStanding = progress.factionStandings['Army'] ?? 0;
    if (armyStanding < -10) {
      eligibleDisasters.add({
        'id': 'royalist_trade_blockade',
        'title': 'ROYALIST TRADE BLOCKADE',
        'description': 'The Royalists have blockaded trade paths. We cannot purchase card upgrades or hire cards from the market for 2 turns.',
        'run': () {
          progress.cardUpgrades['market_blockaded_turns'] = 2;
          service.addLog('Disaster Royalist Trade Blockade: Market blocked for 2 turns.');
        }
      });
    }

    // Carbonari Sabotage
    final carbonariStanding = progress.factionStandings['Carbonari'] ?? 0;
    if (carbonariStanding < -10) {
      eligibleDisasters.add({
        'id': 'carbonari_sabotage',
        'title': 'CARBONARI SABOTAGE',
        'description': 'Carbonari saboteurs blew up one of our constructed facilities!',
        'run': () {
          if (progress.buildings.isNotEmpty) {
            final target = progress.buildings[Random().nextInt(progress.buildings.length)];
            progress.buildings.remove(target);
            service.addLog('Disaster Carbonari Sabotage: Destroyed ${target.type.name}.');
          } else {
            service.addLog('Disaster Carbonari Sabotage: No facilities available to destroy.');
          }
        }
      });
    }

    // Mine Shaft Collapse
    if (progress.buildings.any((b) => b.type == SurvivalBuildingType.mine)) {
      eligibleDisasters.add({
        'id': 'mine_shaft_collapse',
        'title': 'MINE SHAFT COLLAPSE',
        'description': 'A mine shaft collapsed, trapping mining workers! They are trapped and cannot participate or work for the next 2 turns.',
        'run': () {
          final mine = progress.buildings.firstWhereOrNull((b) => b.type == SurvivalBuildingType.mine);
          if (mine != null) {
            for (var cardType in mine.assignedUnitIds) {
              progress.bondageDebuffCount[cardType] = (progress.bondageDebuffCount[cardType] ?? 0) + 2;
              service.addLog('Disaster Mine Shaft Collapse: Trapped $cardType for 2 turns.');
            }
          }
        }
      });
    }

    // Lumber Mill Boiler Fire
    if (progress.buildings.any((b) => b.type == SurvivalBuildingType.lumberMill)) {
      eligibleDisasters.add({
        'id': 'lumber_mill_boiler_fire',
        'title': 'LUMBER MILL BOILER FIRE',
        'description': 'A fire in the Lumber Mill boiler destroyed the facility and ruined 50% of currently stored wood.',
        'run': () {
          final lumber = progress.buildings.firstWhereOrNull((b) => b.type == SurvivalBuildingType.lumberMill);
          if (lumber != null) {
            progress.buildings.remove(lumber);
          }
          progress.wood = (progress.wood * 0.5).toInt();
          service.addLog('Disaster Lumber Mill Boiler Fire: Destroyed Lumber Mill and lost 50% wood.');
        }
      });
    }

    // Arsenal Sabotage
    if (progress.buildings.any((b) => b.type == SurvivalBuildingType.arsenal)) {
      eligibleDisasters.add({
        'id': 'arsenal_sabotage',
        'title': 'ARSENAL SABOTAGE',
        'description': 'Arsenal fire destroyed the facility and damaged the weapons of all units assigned to it.',
        'run': () {
          final arsenal = progress.buildings.firstWhereOrNull((b) => b.type == SurvivalBuildingType.arsenal);
          if (arsenal != null) {
            progress.buildings.remove(arsenal);
            for (var cardType in arsenal.assignedUnitIds) {
              progress.bondageDebuffCount[cardType] = (progress.bondageDebuffCount[cardType] ?? 0) + 1;
            }
          }
          service.addLog('Disaster Arsenal Sabotage: Destroyed Arsenal and damaged weapons.');
        }
      });
    }

    // Garage Structural Damage
    if (progress.buildings.any((b) => b.type == SurvivalBuildingType.garage)) {
      eligibleDisasters.add({
        'id': 'garage_structural_damage',
        'title': 'GARAGE STRUCTURAL DAMAGE',
        'description': 'A major structural collapse damaged the Garage, reducing its level by 1 and disabling vehicle support for 2 turns.',
        'run': () {
          final garage = progress.buildings.firstWhereOrNull((b) => b.type == SurvivalBuildingType.garage);
          if (garage != null) {
            if (garage.level > 1) {
              garage.level -= 1;
            } else {
              progress.buildings.remove(garage);
            }
          }
          progress.cardUpgrades['garage_disabled_turns'] = 2;
          service.addLog('Disaster Garage Structural Damage: Reduced Garage level and disabled vehicles for 2 turns.');
        }
      });
    }

    // Crop Blight
    if (progress.buildings.any((b) => b.type == SurvivalBuildingType.farm)) {
      eligibleDisasters.add({
        'id': 'crop_blight',
        'title': 'CROP BLIGHT',
        'description': 'Fungal crop blight has destroyed our harvests! We lost 80% of our food reserves, and farm food output is halted for 2 turns.',
        'run': () {
          progress.food = (progress.food * 0.2).toInt();
          progress.cardUpgrades['farm_halted_turns'] = 2;
          service.addLog('Disaster Crop Blight: Lost 80% food reserves and halted farm output for 2 turns.');
        }
      });
    }

    // Starvation Insubordination
    final hasStarving = progress.starvationInfractions.entries.any((e) => e.value >= 2);
    if (hasStarving) {
      eligibleDisasters.add({
        'id': 'starvation_insubordination',
        'title': 'STARVATION INSUBORDINATION',
        'description': 'Starving units mutinied! They refuse to work next turn and stole 200 CHF to purchase food.',
        'run': () {
          progress.cash = max(0, progress.cash - 200);
          progress.cardUpgrades['units_mutinied'] = 1;
          service.addLog('Disaster Starvation Insubordination: Mutinied units stole 200 CHF and refused work.');
        }
      });
    }

    // Mine Water Seepage
    if (progress.buildings.any((b) => b.type == SurvivalBuildingType.mine)) {
      eligibleDisasters.add({
        'id': 'mine_water_seepage',
        'title': 'MINE WATER SEEPAGE',
        'description': 'Flooding in the mine has halted work. The mine will produce 0 iron for 3 turns, and mining workers suffer a permanent 20% health penalty.',
        'run': () {
          progress.cardUpgrades['mine_flooded_turns'] = 3;
          final mine = progress.buildings.firstWhereOrNull((b) => b.type == SurvivalBuildingType.mine);
          if (mine != null) {
            for (var cardType in mine.assignedUnitIds) {
              progress.bondageDebuffCount[cardType] = (progress.bondageDebuffCount[cardType] ?? 0) + 1;
            }
          }
          service.addLog('Disaster Mine Water Seepage: Mine flooded for 3 turns, workers health penalized.');
        }
      });
    }

    // Wild Beast Raid
    final hasNoWalls = !progress.buildings.any((b) => b.type == SurvivalBuildingType.garage);
    if (hasNoWalls) {
      eligibleDisasters.add({
        'id': 'wild_beast_raid',
        'title': 'WILD BEAST RAID',
        'description': 'Wild beasts raided the estate, killing a low-level worker card!',
        'run': () {
          String? targetCard;
          for (var t in progress.playerDeckIds) {
            final lvl = progress.getUnitLevel(t);
            if (lvl <= 2 && t != progress.selectedLeaderId) {
              targetCard = t;
              break;
            }
          }
          if (targetCard != null) {
            progress.playerDeckIds.remove(targetCard);
            service.addLog('Disaster Wild Beast Raid: Killed low-level unit $targetCard.');
          } else {
            service.addLog('Disaster Wild Beast Raid: No low-level units available.');
          }
        }
      });
    }

    // Artillery Ammo Dampness
    final hasArtillery = progress.playerDeckIds.contains('artillery_barrage');
    if (hasArtillery && progress.buildings.any((b) => b.type == SurvivalBuildingType.arsenal)) {
      eligibleDisasters.add({
        'id': 'artillery_ammo_dampness',
        'title': 'ARTILLERY AMMO DAMPNESS',
        'description': 'Moisture has ruined the heavy artillery shells. The Artillery Barrage support card cannot be used in combat for the next 3 encounters.',
        'run': () {
          progress.cardUpgrades['artillery_disabled_encounters'] = 3;
          service.addLog('Disaster Artillery Ammo Dampness: Disabled Artillery Barrage for 3 encounters.');
        }
      });
    }

    // Training Accident
    if (progress.trainingUnitIds.isNotEmpty) {
      eligibleDisasters.add({
        'id': 'training_accident',
        'title': 'TRAINING ACCIDENT',
        'description': 'A live-fire accident injured a training unit. Their training is cancelled, and they will start the next combat with 10% health.',
        'run': () {
          final target = progress.trainingUnitIds.first;
          progress.trainingUnitIds.remove(target);
          progress.bondageDebuffCount[target] = (progress.bondageDebuffCount[target] ?? 0) + 1;
          service.addLog('Disaster Training Accident: Cancelled training for $target and reduced health.');
        }
      });
    }

    // Lumber Mill Machine Failure
    if (progress.buildings.any((b) => b.type == SurvivalBuildingType.lumberMill)) {
      eligibleDisasters.add({
        'id': 'lumber_mill_machine_failure',
        'title': 'LUMBER MILL MACHINE FAILURE',
        'description': 'Main gears broke! Lumber Mill wood production is reduced by 50% for the next 4 turns.',
        'run': () {
          progress.cardUpgrades['lumber_mill_fail_turns'] = 4;
          service.addLog('Disaster Lumber Mill Machine Failure: Production reduced by 50% for 4 turns.');
        }
      });
    }

    // Tool Shed Theft
    if (progress.cash > 500) {
      eligibleDisasters.add({
        'id': 'tool_shed_theft',
        'title': 'TOOL SHED THEFT',
        'description': 'Thieves stole our high-grade repair tools! Tower repair and building construction cash costs are increased by 50% for the next 3 turns.',
        'run': () {
          progress.cardUpgrades['repair_cost_multiplier_turns'] = 3;
          service.addLog('Disaster Tool Shed Theft: Costs increased by 50% for 3 turns.');
        }
      });
    }

    // Farmhand Exhaustion
    final farmWorkersCount = progress.buildings
        .firstWhereOrNull((b) => b.type == SurvivalBuildingType.farm)
        ?.assignedUnitIds
        .length ?? 0;
    if (farmWorkersCount >= 2) {
      eligibleDisasters.add({
        'id': 'farmhand_exhaustion',
        'title': 'FARMHAND EXHAUSTION',
        'description': 'Severe physical fatigue among crop workers! Farm workers contract muscle strain debuffs.',
        'run': () {
          final farm = progress.buildings.firstWhereOrNull((b) => b.type == SurvivalBuildingType.farm);
          if (farm != null) {
            for (var cardType in farm.assignedUnitIds) {
              progress.bondageDebuffCount[cardType] = (progress.bondageDebuffCount[cardType] ?? 0) + 1;
            }
          }
          service.addLog('Disaster Farmhand Exhaustion: Applied muscle strain debuffs to farm workers.');
        }
      });
    }

    // Munitions Backfire
    if (progress.buildings.any((b) => b.type == SurvivalBuildingType.munitionsFactory)) {
      eligibleDisasters.add({
        'id': 'munitions_backfire',
        'title': 'MUNITIONS BACKFIRE',
        'description': 'Nitroglycerin backfire! All watchtowers take 50% structural damage.',
        'run': () {
          progress.towerDamaged['tower_1'] = min(1.0, (progress.towerDamaged['tower_1'] ?? 0.0) + 0.5);
          progress.towerDamaged['tower_2'] = min(1.0, (progress.towerDamaged['tower_2'] ?? 0.0) + 0.5);
          progress.towerDamaged['tower_3'] = min(1.0, (progress.towerDamaged['tower_3'] ?? 0.0) + 0.5);
          service.addLog('Disaster Munitions Backfire: All towers took 50% damage.');
        }
      });
    }

    // Canton Tax Levy
    final glarusTaxStanding = progress.factionStandings['Glarus'] ?? 0;
    if (glarusTaxStanding < 0) {
      eligibleDisasters.add({
        'id': 'canton_tax_levy',
        'title': 'CANTON TAX LEVY',
        'description': 'Canton authorities levied a forced war tax, deducting 400 CHF (or all current funds if less).',
        'run': () {
          progress.cash = max(0, progress.cash - 400);
          service.addLog('Disaster Canton Tax Levy: Deducted cash for war taxes.');
        }
      });
    }

    final List<Map<String, dynamic>> genericDisasters = [
      {
        'id': 'faultline_rupture',
        'title': 'FAULTLINE RUPTURE',
        'description': 'An earthquake strikes Glarus! One of our purchased plots has been lost, and any facility built on it has been destroyed.',
        'run': () {
          if (progress.purchasedPlots.isNotEmpty) {
            final randomPlot = progress.purchasedPlots[Random().nextInt(progress.purchasedPlots.length)];
            progress.purchasedPlots.remove(randomPlot);
            final b = progress.buildings.firstWhereOrNull((build) => build.id == randomPlot);
            if (b != null) {
              progress.buildings.remove(b);
              service.addLog('Disaster Faultline Rupture: Lost plot $randomPlot and destroyed facility ${b.type.name}.');
            } else {
              service.addLog('Disaster Faultline Rupture: Lost plot $randomPlot.');
            }
          }
        }
      },
      {
        'id': 'structural_conflagration',
        'title': 'STRUCTURAL CONFLAGRATION',
        'description': 'Lightning strike! A fire breaks out and completely destroys one of our defensive watchtowers.',
        'run': () {
          final towers = ['tower_1', 'tower_2', 'tower_3'];
          final randomTower = towers[Random().nextInt(towers.length)];
          progress.towerDamaged[randomTower] = 1.0;
          service.addLog('Disaster Structural Conflagration: Destroyed $randomTower.');
        }
      },
      {
        'id': 'wasting_influenza',
        'title': 'WASTING INFLUENZA',
        'description': 'Illness sweeps through the barracks. All combat cards have had their experience progress toward the next level reset to 0.',
        'run': () {
          for (var t in progress.unitExp.keys) {
            progress.unitExp[t] = 0.0;
          }
          service.addLog('Disaster Wasting Influenza: Reset XP progress for all combat units to 0.');
        }
      },
      {
        'id': 'corrosive_damp',
        'title': 'CORROSIVE DAMP',
        'description': 'Moisture penetrates the estate storage yards, rotting and completely destroying 100% of our stored wood resources.',
        'run': () {
          progress.wood = 0;
          service.addLog('Disaster Corrosive Damp: Destroyed all stored wood.');
        }
      },
      {
        'id': 'acid_rain',
        'title': 'ACID RAIN',
        'description': 'Corrosive acidic rainfall damages the watchtower structures. All three defensive towers will start the next combat with only 70% durability.',
        'run': () {
          progress.cardUpgrades['next_combat_towers_hp_percent'] = 70;
          service.addLog('Disaster Acid Rain: Tower HP starting next combat reduced to 70%.');
        }
      },
      {
        'id': 'rat_infestation',
        'title': 'RAT INFESTATION',
        'description': 'Rats raid the storage bunkers! We have lost 50% of our stored food, and all units suffer low morale (20% reduced speed next combat).',
        'run': () {
          progress.food = (progress.food * 0.5).toInt();
          progress.cardUpgrades['next_combat_speed_reduction'] = 20;
          service.addLog('Disaster Rat Infestation: Lost 50% food and low morale speed reduction applied.');
        }
      },
      {
        'id': 'supply_cost_spike',
        'title': 'SUPPLY COST SPIKE',
        'description': 'Inflation hits canton trade networks. Building construction, upgrade, and tower repair cash costs are doubled for the next 2 turns.',
        'run': () {
          progress.cardUpgrades['double_construction_costs_turns'] = 2;
          service.addLog('Disaster Supply Cost Spike: Construction costs doubled for 2 turns.');
        }
      },
      {
        'id': 'broken_weapons',
        'title': 'BROKEN WEAPONS',
        'description': 'Wear and tear takes a toll on weaponry. A random combat unit has their primary weapon broken, reducing their damage by 30% for 3 battles.',
        'run': () {
          if (progress.playerDeckIds.isNotEmpty) {
            final randomUnit = progress.playerDeckIds[Random().nextInt(progress.playerDeckIds.length)];
            progress.cardUpgrades['broken_weapon_$randomUnit'] = 3;
            service.addLog('Disaster Broken Weapons: Damaged weapon for $randomUnit for 3 battles.');
          }
        }
      },
      {
        'id': 'mental_melancholy',
        'title': 'MENTAL MELANCHOLY',
        'description': 'Freezing fog drains the soldiers\' resolve. All combat units will start the next combat with -2 AP.',
        'run': () {
          progress.cardUpgrades['next_combat_ap_modifier'] = (progress.cardUpgrades['next_combat_ap_modifier'] ?? 0) - 2;
          service.addLog('Disaster Mental Melancholy: -2 AP starting next combat.');
        }
      },
      {
        'id': 'alchemical_leak',
        'title': 'ALCHEMICAL LEAK',
        'description': 'A toxic gas leak spreads across the barracks training grounds! All units currently in training take 50% damage and are expelled.',
        'run': () {
          for (var t in progress.trainingUnitIds) {
            progress.bondageDebuffCount[t] = (progress.bondageDebuffCount[t] ?? 0) + 1;
          }
          progress.trainingUnitIds.clear();
          service.addLog('Disaster Alchemical Leak: Expelled training units due to injury.');
        }
      }
    ];

    final List<Map<String, dynamic>> disasterPool = [];
    disasterPool.addAll(genericDisasters);
    disasterPool.addAll(eligibleDisasters);

    final selected = disasterPool[Random().nextInt(disasterPool.length)];
    selected['run']();
    service.manualSave();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A15),
              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DISASTER STRIKES!',
                  style: GoogleFonts.oswald(
                    color: Colors.redAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  selected['title'] as String,
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  selected['description'] as String,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white70,
                    fontSize: 13.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC4B89B),
                      foregroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(),
                    ),
                    onPressed: () => Navigator.pop(dlgContext),
                    child: Text(
                      'ACKNOWLEDGE',
                      style: GoogleFonts.playfairDisplay(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showVolunteerCapacityDialog(
    String volunteerType,
    int meanLevel,
    SurvivalProgress progress,
    SurvivalService service,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgContext) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1A15),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ARMY AT FULL CAPACITY',
                      style: GoogleFonts.oswald(
                        color: const Color(0xFFD4AF37),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'A level $meanLevel ${volunteerType.replaceAll('_', ' ').toUpperCase()} wants to volunteer. Select an existing card to discard to make room, or refuse the volunteer.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.oldStandardTt(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: progress.playerDeckIds.length,
                        itemBuilder: (context, idx) {
                          final cardId = progress.playerDeckIds[idx];
                          final npc = CombatUnitService.createUnit(cardId);
                          final lvl = progress.getUnitLevel(cardId);
                          final isLeader = cardId == progress.selectedLeaderId;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(6),
                            color: const Color(0xFF15100B),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "${npc.name.toUpperCase()} (LVL $lvl)${isLeader ? ' [LEADER]' : ''}",
                                    style: GoogleFonts.playfairDisplay(
                                      color: isLeader ? Colors.white30 : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (!isLeader)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                                      foregroundColor: Colors.white,
                                      shape: const RoundedRectangleBorder(),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    ),
                                    onPressed: () {
                                      progress.playerDeckIds.remove(cardId);
                                      progress.playerDeckIds.add(volunteerType);
                                      progress.cardUpgrades['level_$volunteerType'] = meanLevel;
                                      progress.unitExp[volunteerType] = 0.0;
                                      service.addLog('Volunteer: Discarded $cardId and added level $meanLevel $volunteerType.');
                                      service.manualSave();
                                      Navigator.pop(dlgContext);
                                    },
                                    child: const Text('DISCARD', style: TextStyle(fontSize: 10)),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC4B89B),
                          foregroundColor: Colors.black,
                          shape: const RoundedRectangleBorder(),
                        ),
                        onPressed: () {
                          service.addLog('Volunteer: Refused the volunteer $volunteerType.');
                          Navigator.pop(dlgContext);
                        },
                        child: Text(
                          'REFUSE VOLUNTEER',
                          style: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void setDiceForTest(int die1, int die2) {
    _die1 = die1;
    _die2 = die2;
  }

  void evaluateDiceOutcomeForTest(int total, SurvivalProgress progress, SurvivalService service) {
    _evaluateDiceOutcome(total, progress, service);
  }

  VoidCallback? getDiceOutcomeActionForTest() {
    return _diceOutcomeAction;
  }

  String getDiceOutcomeMessageForTest() {
    return _diceOutcomeMessage;
  }
 
  void triggerRippleEffectsForTest(BuildContext context) {
    _checkAndTriggerRippleEffects(context);
  }

  void resolveRippleEffectForTest(
    BuildContext context,
    String encounterId,
    String? choice,
    SurvivalProgress progress,
    SurvivalService service,
    GameState state,
  ) {
    _resolveRippleEffect(
      context,
      encounterId,
      choice,
      progress,
      service,
      state,
    );
  }

  Widget _buildDiceRollOverlay(
    SurvivalProgress progress,
    SurvivalService service,
    GameState state,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final total = _die1 + _die2;

    return Container(
      width: screenWidth,
      height: screenHeight,
      color: Colors.black.withValues(alpha: 0.35),
      child: Stack(
        children: [


          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _build3DCube(_die1, _isDiceRolling, 0.2),
                const SizedBox(width: 48),
                _build3DCube(_die2, _isDiceRolling, -0.15),
              ],
            ),
          ),

          if (!_isDiceRolling)
            Positioned(
              bottom: 50,
              left: (screenWidth - 420) / 2,
              width: 420,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1A15).withValues(alpha: 0.9),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "ROLLED A $total",
                      style: GoogleFonts.oswald(
                        color: const Color(0xFFE5D5B0),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _diceOutcomeMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.oldStandardTt(
                        color: Colors.white,
                        fontSize: 14.0,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC4B89B),
                          foregroundColor: Colors.black,
                          shape: const RoundedRectangleBorder(),
                        ),
                        onPressed: () {
                          setState(() {
                            _showDiceOverlay = false;
                          });
                          if (_diceOutcomeAction != null) {
                            _diceOutcomeAction!();
                          }
                          final isDialogEvent =
                              _lastDiceTotal == 7 || _lastDiceTotal == 2;
                          if (!isDialogEvent) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _checkAndTriggerRippleEffects(context);
                            });
                          }
                        },
                        child: Text(
                          'CONTINUE',
                          style: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _build3DCube(int topValue, bool rolling, double baseAngle) {
    final int top = topValue;
    final int bottom = 7 - top;
    
    int front = 2;
    int back = 5;
    int left = 3;
    int right = 4;
    
    if (top == 2) {
      front = 1; back = 6; left = 3; right = 4;
    } else if (top == 3) {
      front = 1; back = 6; left = 2; right = 5;
    } else if (top == 4) {
      front = 1; back = 6; left = 5; right = 2;
    } else if (top == 5) {
      front = 6; back = 1; left = 3; right = 4;
    } else if (top == 6) {
      front = 2; back = 5; left = 4; right = 3;
    }

    final double randAngleY = rolling ? (Random().nextDouble() - 0.5) * 5.0 : baseAngle;
    final double randAngleX = rolling ? (Random().nextDouble() - 0.5) * 5.0 : 0.65;
    final double randAngleZ = rolling ? (Random().nextDouble() - 0.5) * 3.0 : 0.15;

    final double scale = rolling ? 1.0 + (Random().nextDouble() * 0.15) : 1.0;
    
    final size = 80.0;
    final halfSize = size / 2;

    Widget buildFace(int val, Matrix4 transform, String debugLabel) {
      return Transform(
        transform: transform,
        alignment: Alignment.center,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFF4ECD8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
            gradient: const RadialGradient(
              colors: [
                Color(0xFFFFF9EC),
                Color(0xFFEADFCA),
              ],
              center: Alignment(-0.2, -0.2),
              radius: 1.0,
            ),
          ),
          child: Center(
            child: _buildDieDots(val),
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..translate(rolling ? 12.0 : 6.0, rolling ? 24.0 : 16.0, -halfSize)
            ..rotateX(1.2)
            ..scale(rolling ? 1.15 : 0.95),
          alignment: Alignment.center,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: rolling ? 0.2 : 0.35),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: rolling ? 16 : 6,
                  spreadRadius: rolling ? 3 : 1,
                ),
              ],
            ),
          ),
        ),

        Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..scale(scale)
            ..rotateX(randAngleX)
            ..rotateY(randAngleY)
            ..rotateZ(randAngleZ),
          alignment: Alignment.center,
          child: Container(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                buildFace(bottom, Matrix4.identity()..translate(0.0, 0.0, -halfSize)..rotateY(pi), 'bottom'),
                buildFace(back, Matrix4.identity()..translate(0.0, -halfSize, 0.0)..rotateX(pi / 2), 'back'),
                buildFace(left, Matrix4.identity()..translate(-halfSize, 0.0, 0.0)..rotateY(-pi / 2), 'left'),
                buildFace(right, Matrix4.identity()..translate(halfSize, 0.0, 0.0)..rotateY(pi / 2), 'right'),
                buildFace(front, Matrix4.identity()..translate(0.0, halfSize, 0.0)..rotateX(-pi / 2), 'front'),
                buildFace(top, Matrix4.identity()..translate(0.0, 0.0, halfSize), 'top'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDieDots(int value) {
    final dots = <Positioned>[];
    
    void addDot(double x, double y) {
      dots.add(
        Positioned(
          left: x,
          top: y,
          child: Container(
            width: 11,
            height: 11,
            decoration: const BoxDecoration(
              color: Color(0xFF1E1A15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 1,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (value == 1) {
      addDot(34, 34);
    } else if (value == 2) {
      addDot(14, 14);
      addDot(54, 54);
    } else if (value == 3) {
      addDot(14, 14);
      addDot(34, 34);
      addDot(54, 54);
    } else if (value == 4) {
      addDot(14, 14);
      addDot(54, 14);
      addDot(14, 54);
      addDot(54, 54);
    } else if (value == 5) {
      addDot(14, 14);
      addDot(54, 14);
      addDot(34, 34);
      addDot(14, 54);
      addDot(54, 54);
    } else if (value == 6) {
      addDot(14, 14);
      addDot(54, 14);
      addDot(14, 34);
      addDot(54, 34);
      addDot(14, 54);
      addDot(54, 54);
    }

    return Stack(
      children: dots,
    );
  }
}



// CUSTOM PAINTER FOR ORGANIC BACKGROUND DIVIDER LINES
class MapDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Horizontal dividing tracks
    canvas.drawLine(
      Offset(0, size.height * 0.33),
      Offset(size.width, size.height * 0.33),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.66),
      Offset(size.width, size.height * 0.66),
      paint,
    );

    // Vertical dividing tracks
    canvas.drawLine(
      Offset(size.width * 0.33, 0),
      Offset(size.width * 0.33, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.66, 0),
      Offset(size.width * 0.66, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
