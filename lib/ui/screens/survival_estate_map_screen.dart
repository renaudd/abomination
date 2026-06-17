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
import '../../models/survival_state.dart';
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

  const WeaponUpgradeSpec({
    required this.name,
    required this.cost,
    required this.isRanged,
    required this.damage,
    required this.speed,
    required this.range,
    required this.aoe,
    required this.targetingRule,
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
    cost: 30,
    isRanged: false,
    damage: 11,
    speed: 1.0,
    range: 1.6,
    aoe: 0.0,
    targetingRule: 'Closest',
    tier: 1,
  ),
  const GeneralWeaponSpec(
    name: 'Heavy Spiked Mace',
    cost: 35,
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
    cost: 30,
    isRanged: true,
    damage: 20,
    speed: 2.8,
    range: 8.0,
    aoe: 0.0,
    targetingRule: 'Closest',
    tier: 1,
  ),
  const GeneralWeaponSpec(
    name: 'Flintlock Rifle',
    cost: 40,
    isRanged: true,
    damage: 26,
    speed: 2.4,
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
    cost: 55,
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
    cost: 60,
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
    cost: 65,
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
    cost: 75,
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
    cost: 85,
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
    cost: 95,
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
    cost: 110,
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
    damage: 24,
    speed: 0.9,
    range: 1.2,
    aoe: 0.0,
    targetingRule: 'Closest',
  ),
  const WeaponUpgradeSpec(
    name: 'Demon-Forged Odachi',
    cost: 60,
    isRanged: false,
    damage: 40,
    speed: 0.8,
    range: 1.8,
    aoe: 0.5,
    targetingRule: 'Closest',
  ),
  const WeaponUpgradeSpec(
    name: 'Sacred Dragon Blade',
    cost: 120,
    isRanged: false,
    damage: 60,
    speed: 0.7,
    range: 2.0,
    aoe: 0.6,
    targetingRule: 'Low Health',
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
  final sampleUnit = CombatUnitService.createUnit(cardId);
  final baseCost = sampleUnit.combatStats?.cost ?? 3;
  final baseAtk = sampleUnit.combatStats?.attack ?? 10;
  final baseWep =
      _generalWeaponMarket.where((w) => w.name == weaponName).firstOrNull;
  final bool isAdvanced =
      baseWep != null &&
      (baseWep.tier >= 2 || baseWep.damage >= baseAtk * 1.35);

  if (isAdvanced) {
    if (baseCost <= 3) {
      return 'PERFORMANCE IMPACT: +2 AP Summon Cost & -25% Locomotion Speed (High-Cost Encumbrance)';
    } else {
      return 'ELITE WEAPON SYNERGY: +1 AP Summon Cost (+15% Damage & +1.0ft Range Mastery)';
    }
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
  bool _isTransitioningToCombat = false;

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
    {'type': 'goons', 'cost': 220, 'name': 'Goons'},
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
        centerArea = _buildFullDeckView(progress, service);
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
          return b.assignedUnitIds.length < caps && SurvivalService.isHumanoid(npc);
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

                    final exp = progress.unitExp[type] ?? 0.0;
                    final lvl = SurvivalProgress.getLevelFromXp(exp);

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
                                    onTap: () => CombatCardDetailModal.show(context, type),
                                    child: Text(
                                      npc.name.toUpperCase(),
                                      style: GoogleFonts.oldStandardTt(
                                        color: isAssigned
                                            ? Colors.white38
                                            : const Color(0xFFE5D5B0),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        decorationColor: isAssigned
                                            ? Colors.white38
                                            : const Color(0xFFE5D5B0),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Lvl $lvl | Food cost: ${SurvivalService.getFoodCost(npc)}',
                                    style: GoogleFonts.oswald(
                                      color: Colors.white38,
                                      fontSize: 8,
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
                        fontSize: 8.5,
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
                  final exp = progress.unitExp[t] ?? 0.0;
                  levelsBefore[t] = SurvivalProgress.getLevelFromXp(exp);
                }

                // Trigger turn resolution
                _isTransitioningToCombat = true;
                service.endTurn();

                // Check for level-ups
                final List<Map<String, dynamic>> levelUps = [];
                for (var t in progress.playerDeckIds) {
                  final exp = progress.unitExp[t] ?? 0.0;
                  final currentLvl = SurvivalProgress.getLevelFromXp(exp);
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
                    final exp = progress.unitExp[t] ?? 0.0;
                    final lvl = SurvivalProgress.getLevelFromXp(exp);
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
                      final bool isAdvanced =
                          wepStats.damage >= baseAttack * 1.35 ||
                          (t == 'samurai' && rawWepIdx > 1);

                      baseAttack = wepStats.damage;
                      distance = wepStats.range;
                      rangedRange = wepStats.range;

                      if (isAdvanced) {
                        if (baseCost <= 3) {
                          baseCost += 2;
                          baseSpeed *= 1.2;
                          baseMovement *= 0.75;
                        } else {
                          baseCost += 1;
                          baseAttack *= 1.15;
                          distance += 1.0;
                          rangedRange += 1.0;
                        }
                      }
                    }

                    return npc.copyWith(
                      metadata: {...npc.metadata, 'cardType': t, 'level': lvl},
                      combatStats: npc.combatStats?.copyWith(
                        cost: baseCost,
                        speed: baseSpeed,
                        movement: baseMovement,
                        health: npc.combatStats!.health * mult,
                        maxHealth: npc.combatStats!.maxHealth * mult,
                        attack: baseAttack * mult,
                        meleeDamage: baseAttack * mult,
                        rangedDamage: baseAttack * mult,
                        distance: distance,
                        rangedRange: rangedRange,
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
                      meleeDamage: (baseEnemyHero.combatStats!.meleeDamage ?? baseEnemyHero.combatStats!.attack) * enemyLvlMult * enemyUpgradeMult,
                      rangedDamage: (baseEnemyHero.combatStats!.rangedDamage ?? baseEnemyHero.combatStats!.attack) * enemyLvlMult * enemyUpgradeMult,
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
                // Left column: Chronological Action Logs
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15100B),
                      border: Border.all(
                        color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
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
                        Expanded(
                          child: service.logs.isEmpty
                              ? Center(
                                  child: Text(
                                    'The chronicle is empty. Actions are recorded here as turns progress.',
                                    style: GoogleFonts.oldStandardTt(
                                      color: Colors.white24,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 10,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: service.logs.length,
                                  itemBuilder: (context, index) {
                                    final log = service
                                        .logs[service.logs.length - 1 - index];
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
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Right column: Active Assignments & Land Covenants
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Container(
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
                              Expanded(
                                child: _buildManorAssignmentsList(
                                  progress,
                                  service,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
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
                                    Expanded(
                                      child: progress.currentTurn < 4
                                          ? Center(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                    ),
                                                child: Text(
                                                  'The registry of treaties remains vacant. No formal covenants or agreements ratified.',
                                                  textAlign: TextAlign.center,
                                                  style:
                                                      GoogleFonts.playfairDisplay(
                                                        color:
                                                            const Color(
                                                              0xFFE5D5B0,
                                                            ).withValues(
                                                              alpha: 0.4,
                                                            ),
                                                        fontSize: 9,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        height: 1.15,
                                                      ),
                                                ),
                                              ),
                                            )
                                          : ListView(
                                              children: [
                                                _buildCovenantItem(
                                                  'RAT ERADICATION COVENANT',
                                                  'Exterminate undead vermin threat in eastern cellar. Status: Active.',
                                                ),
                                              ],
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
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
                                      'SECRET SOCIETY STANDINGS',
                                      style: GoogleFonts.playfairDisplay(
                                        color: const Color(0xFFD4AF37),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Divider(color: Colors.white10),
                                    const SizedBox(height: 3),
                                    Expanded(
                                      child: ListView(
                                        children: progress
                                            .factionStandings
                                            .entries
                                            .map((entry) {
                                              final factionName = entry.key ==
                                                      'Army'
                                                  ? 'Your Army'
                                                  : entry.key;
                                              final rating = entry.value;
                                              Color ratingColor =
                                                  Colors.white70;
                                              if (rating > 0) {
                                                ratingColor =
                                                    Colors.greenAccent;
                                              }
                                              if (rating < 0) {
                                                ratingColor = Colors.redAccent;
                                              }
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 3.0,
                                                    ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      factionName,
                                                      style:
                                                          GoogleFonts.playfairDisplay(
                                                            color: const Color(
                                                              0xFFE5D5B0,
                                                            ),
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
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            })
                                            .toList(),
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
                ),
              ],
            ),
          ),
        ],
      ),
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

    return ListView(children: children);
  }

  // --- FULL-SCREEN TAB 2: DECK VIEW OVERHAUL ---
  Widget _buildFullDeckView(
    SurvivalProgress progress,
    SurvivalService service,
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
                    final exp = progress.unitExp[cardId] ?? 0.0;
                    final lvl = SurvivalProgress.getLevelFromXp(exp);

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
                                : leader.id == 'boss_thorne'
                                ? 'Passive Bonuses: Beast companions gain +20% movement speed and wilderness camouflage.'
                                : 'Passive Bonuses: Military units gain +10% critical chance, and defensive towers receive +15% armor when under the direct command of Alphonse.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.oldStandardTt(
                              color: Colors.white70,
                              fontSize: 11.5,
                              height: 1.4,
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
    final factor = 1.0 + (progress.currentTurn - 1) * 0.2;
    final foodPackCost = (40 * factor).toInt();
    final woodTimberCost = (60 * factor).toInt();
    final ironCrateCost = (85 * factor).toInt();

    final List<Map<String, dynamic>> availableHires = [];
    if (progress.villageHealth <= 0) {
      // Village is fallow/destroyed. No human units available, only beasts, chimeras, or constructs
      availableHires.addAll([
        {'type': 'undead_rats', 'cost': 190},
        {'type': 'werewolf', 'cost': 350},
        {'type': 'flesh_golem', 'cost': 320},
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
                            final cost = hire['cost'] as int;
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
    final canAfford = progress.cash >= cost;
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
                  '+$amount $res\n$cost CHF',
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

      final cost = nextWep.cost;
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

    final rawWeps = _getAvailableMarketWeapons(
      progress.currentTurn,
      progress.villageHealth,
    );
    // Compatible, affordable, and unlocked weapons for sale
    final compatibleWeps = rawWeps.where((w) {
      if (_getWeaponCompatibilityError(cardId, w.name) != null) return false;
      if (progress.cash < w.cost * squadSize) return false;
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
    final totalCost = evaluatedWep != null ? evaluatedWep.cost * squadSize : 0;

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
                    '${wep.cost} CHF',
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
          Text(
            label,
            style: GoogleFonts.oldStandardTt(
              color: highlight ? const Color(0xFFC4B89B) : Colors.white38,
              fontSize: 11.0,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Row(
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
    final lvl = SurvivalProgress.getLevelFromXp(exp);
    var stats = npc.combatStats!;
    if (cardId == 'cannoneer' && lvl >= 6) {
      stats = stats.copyWith(
        distance: 23.0,
        rangedRange: 23.0,
      );
    }
    final nextReq = SurvivalProgress.getRequiredXpForLevel(lvl + 1);
    final prevReq = lvl == 1 ? 0 : SurvivalProgress.getRequiredXpForLevel(lvl);
    final range = nextReq - prevReq;
    final pct = range == 0 ? 1.0 : ((exp - prevReq) / range).clamp(0.0, 1.0);

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
                                final canAffordDrills =
                                    (progress.cash >= drillCost &&
                                    !_isDrafting &&
                                    !isUndeadUnit);

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
                                          final oldExp =
                                              progress.unitExp[cardId] ?? 0.0;
                                          final oldLvl =
                                              SurvivalProgress.getLevelFromXp(
                                                oldExp,
                                              );
                                          if (service.buyTrainingPoints(
                                            cardId,
                                            drillXp,
                                            drillCost,
                                          )) {
                                            final newExp =
                                                progress.unitExp[cardId] ?? 0.0;
                                            final newLvl =
                                                SurvivalProgress.getLevelFromXp(
                                                  newExp,
                                                );
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
                                        : (isUndeadUnit
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
                final curXp = progress.unitExp[t] ?? 0.0;
                final curLvl = SurvivalProgress.getLevelFromXp(curXp);
                progress.unitExp[t] = SurvivalProgress.getRequiredXpForLevel(
                  curLvl + 1,
                ).toDouble();
                service.addLog('Promoted $t by 1 level.');
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
              totalLevels += SurvivalProgress.getLevelFromXp(
                progress.unitExp[t] ?? 0.0,
              );
            }
            final calcLvl = (1 + (totalLevels ~/ 6)).clamp(1, 6);
            progress.playerDeckIds.add('artillery_barrage');
            progress.unitExp['artillery_barrage'] =
                SurvivalProgress.getRequiredXpForLevel(calcLvl).toDouble();
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
              totalLevels += SurvivalProgress.getLevelFromXp(
                progress.unitExp[t] ?? 0.0,
              );
            }
            final calcLvl = (1 + (totalLevels ~/ 6)).clamp(1, 6);
            progress.playerDeckIds.add('tear_gas_grenade');
            progress.unitExp['tear_gas_grenade'] =
                SurvivalProgress.getRequiredXpForLevel(calcLvl).toDouble();
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
          'onPress': () {
            progress.wood = max(0, progress.wood - 150 + 100);
            progress.iron = max(0, progress.iron - 50);
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
          'onPress': () {
            progress.cash = max(0, progress.cash - 200);
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
          'onPress': () {
            progress.wood = max(0, progress.wood - 60);
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
          'onPress': () {
            progress.cash = max(0, progress.cash - 100);
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
          'onPress': () {
            progress.cash = max(0, progress.cash - 200);
            progress.iron = max(0, progress.iron - 20);
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
          'onPress': () {
            progress.wood = max(0, progress.wood - 20);
            progress.food += 50;
            progress.factionStandings['Knights Templar'] =
                (progress.factionStandings['Knights Templar'] ?? 0) - 15;
            progress.factionStandings['Rosicrucians'] =
                (progress.factionStandings['Rosicrucians'] ?? 0) + 15;
            service.addLog('Smuggled provisions.');
          },
        });
        options.add({
          'title': 'C) "Offer shelter."',
          'subtitle':
              'Effect: Soldiers assigned to guard duty. (+5 Templar, -10 Rosicrucians)',
          'onPress': () {
            progress.factionStandings['Knights Templar'] =
                (progress.factionStandings['Knights Templar'] ?? 0) + 5;
            progress.factionStandings['Rosicrucians'] =
                (progress.factionStandings['Rosicrucians'] ?? 0) - 10;
            service.addLog('Sheltered Knights Templar.');
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
          'onPress': () {
            progress.food = max(0, progress.food - 40);
            progress.cash = max(0, progress.cash - 100);
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
          'onPress': () {
            progress.cash = max(0, progress.cash - 150);
            progress.factionStandings['Carbonari'] =
                (progress.factionStandings['Carbonari'] ?? 0) + 10;
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) + 5;
            service.addLog('Wages compromised.');
          },
        });
        options.add({
          'title': 'C) "Enforce martial law."',
          'subtitle': 'Effect: Lock production. (+10 Army, -20 Carbonari)',
          'onPress': () {
            progress.factionStandings['Carbonari'] =
                (progress.factionStandings['Carbonari'] ?? 0) - 20;
            progress.factionStandings['Army'] =
                (progress.factionStandings['Army'] ?? 0) + 10;
            service.addLog('Enforced martial law.');
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
          'onPress': () {
            progress.cash = max(0, progress.cash - 200);
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
          'onPress': () {
            progress.cash = max(0, progress.cash - 100);
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
          'title': 'C) "Sell them premium horse feed."',
          'subtitle':
              'Cost: 30 Food. Reward: +200 CHF. (+10 Chevaliers, -5 Glarus)',
          'onPress': () {
            progress.food = max(0, progress.food - 30);
            progress.cash += 200;
            progress.factionStandings['Chevaliers de la foi'] =
                (progress.factionStandings['Chevaliers de la foi'] ?? 0) + 10;
            progress.factionStandings['Glarus'] =
                (progress.factionStandings['Glarus'] ?? 0) - 5;
            service.addLog('Sold feed to Chevaliers.');
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
          'onPress': () {
            progress.cash = max(0, progress.cash - 300);
            progress.factionStandings['Gnomes of Zurich'] =
                (progress.factionStandings['Gnomes of Zurich'] ?? 0) + 15;
            progress.factionStandings['Freemasons'] =
                (progress.factionStandings['Freemasons'] ?? 0) - 10;
            service.addLog('Greased banking gears.');
          },
        });
        options.add({
          'title': 'B) "Lock the estate gates."',
          'subtitle': 'Cost: 20 Food. (-15 Gnomes, -15 Freemasons)',
          'onPress': () {
            progress.food = max(0, progress.food - 20);
            progress.factionStandings['Gnomes of Zurich'] =
                (progress.factionStandings['Gnomes of Zurich'] ?? 0) - 15;
            progress.factionStandings['Freemasons'] =
                (progress.factionStandings['Freemasons'] ?? 0) - 15;
            service.addLog('Locked auditors outside.');
          },
        });
        options.add({
          'title': 'C) "Route funds via Templar vaults."',
          'subtitle': 'Cost: 150 CHF. (+10 Knights Templar, -10 Gnomes)',
          'onPress': () {
            progress.cash = max(0, progress.cash - 150);
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
          'onPress': () {
            progress.cash = max(0, progress.cash - 50);
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
          'onPress': () {
            progress.cash = max(0, progress.cash - 100);
            progress.food = max(0, progress.food - 20);
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
          'onPress': () {
            progress.cash = max(0, progress.cash - 250);
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
          'onPress': () {
            progress.cash = max(0, progress.cash - 50);
            progress.food = max(0, progress.food - 30);
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
          'onPress': () {
            progress.cash = max(0, progress.cash - 150);
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
          'onPress': () {
            progress.wood = max(0, progress.wood - 100);
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
          'onPress': () {
            progress.food = max(0, progress.food - 40);
            progress.iron = max(0, progress.iron - 10);
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
          'onPress': () {
            progress.wood = max(0, progress.wood - 80);
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
          'onPress': () {
            progress.cash = max(0, progress.cash - 50);
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
          'onPress': () {
            progress.cash = max(0, progress.cash - 200);
            progress.wood = max(0, progress.wood - 30);
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
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A1E16),
                            side: const BorderSide(
                              color: Color(0xFFC4B89B),
                              width: 1.0,
                            ),
                            shape: const RoundedRectangleBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onPressed: () {
                            if (titleStr.contains('D)')) {
                              Navigator.pop(context);
                              cb();
                            } else {
                              cb();
                              service.manualSave();
                              Navigator.pop(context);
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                titleStr,
                                style: GoogleFonts.playfairDisplay(
                                  color: const Color(0xFFE5D5B0),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitleStr,
                                style: GoogleFonts.oldStandardTt(
                                  color: Colors.white54,
                                  fontSize: 8.5,
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
      final exp = progress.unitExp[t] ?? 0.0;
      final lvl = SurvivalProgress.getLevelFromXp(exp);
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
        final bool isAdvanced =
            wepStats.damage >= baseAttack * 1.35 ||
            (t == 'samurai' && rawWepIdx > 1);

        baseAttack = wepStats.damage;
        distance = wepStats.range;
        rangedRange = wepStats.range;

        if (isAdvanced) {
          if (baseCost <= 3) {
            baseCost += 2;
            baseSpeed *= 1.2;
            baseMovement *= 0.75;
          } else {
            baseCost += 1;
            baseAttack *= 1.15;
            distance += 1.0;
            rangedRange += 1.0;
          }
        }
      }

      return npc.copyWith(
        metadata: {...npc.metadata, 'cardType': t, 'level': lvl},
        combatStats: npc.combatStats?.copyWith(
          cost: baseCost,
          speed: baseSpeed,
          movement: baseMovement,
          health: npc.combatStats!.health * mult,
          maxHealth: npc.combatStats!.maxHealth * mult,
          attack: baseAttack * mult,
          meleeDamage: baseAttack * mult,
          rangedDamage: baseAttack * mult,
          distance: distance,
          rangedRange: rangedRange,
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
        meleeDamage: (baseEnemyHero.combatStats!.meleeDamage ?? baseEnemyHero.combatStats!.attack) * enemyLvlMult * enemyUpgradeMult,
        rangedDamage: (baseEnemyHero.combatStats!.rangedDamage ?? baseEnemyHero.combatStats!.attack) * enemyLvlMult * enemyUpgradeMult,
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
    int targetDeckSize = 5;
    if (turn >= 9) {
      targetDeckSize = 12;
    } else if (turn >= 6) {
      targetDeckSize = 9;
    } else if (turn >= 3) {
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
    final rand = Random();
    final List<int> cardLevels = [];
    if (turn < 9) {
      final int numLvl2 = turn.clamp(1, targetDeckSize);
      for (int i = 0; i < numLvl2; i++) {
        cardLevels.add(2);
      }
      for (int i = 0; i < targetDeckSize - numLvl2; i++) {
        cardLevels.add(1);
      }
    } else {
      final int numLvl3 = (turn - 8).clamp(0, 12);
      if (numLvl3 >= 12) {
        final double targetMean = (3.0 + (turn - 20) * 0.15).clamp(3.0, 7.0);
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
          meleeDamage: (baseNpc.combatStats!.meleeDamage ?? baseNpc.combatStats!.attack) * mult * upgradeMult,
          rangedDamage: (baseNpc.combatStats!.rangedDamage ?? baseNpc.combatStats!.attack) * mult * upgradeMult,
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

  void _evaluateDiceOutcome(int total, SurvivalProgress progress, SurvivalService service) {
    final state = Provider.of<GameState>(context, listen: false);

    String logDesc = 'Nothing happens.';
    if (total == 7) {
      logDesc = 'Narrative Event triggered.';
    } else if (total == 12) {
      logDesc = 'Scientific Discovery check triggered.';
    } else if (total == 2) {
      logDesc = 'Disaster check triggered.';
    } else if (total == 4) {
      logDesc = 'Bad omen: -1 starting AP next combat.';
    } else if (total == 10) {
      logDesc = 'Good omen: +1 starting AP next combat.';
    }
    service.addLog('FATE\'S ROLL: Rolled $total ($_die1 + $_die2). $logDesc');

    switch (total) {
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

        String? nextEncounterId;
        int foundIndex = index;
        for (int i = 0; i < encountersList.length; i++) {
          final checkIdx = (index + i) % encountersList.length;
          final encId = encountersList[checkIdx];
          if (progress.cardUpgrades['encounter_${encId}_resolved'] != 1) {
            nextEncounterId = encId;
            foundIndex = checkIdx;
            break;
          }
        }

        if (nextEncounterId != null) {
          progress.cardUpgrades['next_encounter_index'] = foundIndex;
          _diceOutcomeMessage = "ROLLED A 7!\nNarrative event triggered: ${nextEncounterId.replaceAll('_', ' ').toUpperCase()}";
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
          _diceOutcomeMessage = "ROLLED A 7!\nHowever, all narrative events in Glarus have been resolved.";
          _diceOutcomeAction = null;
        }
        break;

      case 12:
        final davosBuilding = progress.buildings.firstWhereOrNull((b) => b.id == 'plot_d');
        final davosFarmWorking = davosBuilding != null &&
            davosBuilding.type == SurvivalBuildingType.farm &&
            davosBuilding.assignedUnitIds.isNotEmpty;

        if (progress.cardUpgrades['encounter_davos_smallpox_vaccine_resolved'] != 1 && davosFarmWorking) {
          _diceOutcomeMessage = "ROLLED A 12!\nScientific Discovery: Davos Farm workers discover a Smallpox Vaccine!";
          _diceOutcomeAction = () {
            _showNarrativeEncounter(
              context,
              'davos_smallpox_vaccine',
              progress,
              service,
              state,
            );
          };
        } else {
          _diceOutcomeMessage = "ROLLED A 12!\nNo scientific discoveries are currently available (requires staffed farm on Davos Plot).";
          _diceOutcomeAction = null;
        }
        break;

      case 2:
        if (progress.cardUpgrades['encounter_davos_smallpox_vaccine_resolved'] == 1 &&
            progress.cardUpgrades['encounter_smallpox_outbreak_resolved'] != 1) {
          _diceOutcomeMessage = "ROLLED A 2!\nDisaster: Smallpox Outbreak strikes Glarus!";
          _diceOutcomeAction = () {
            _showNarrativeEncounter(
              context,
              'smallpox_outbreak',
              progress,
              service,
              state,
            );
          };
        } else {
          final factoryBuilding = progress.buildings.firstWhereOrNull(
            (b) => b.type == SurvivalBuildingType.munitionsFactory,
          );
          final factoryWorking = factoryBuilding != null && factoryBuilding.assignedUnitIds.isNotEmpty;

          if (factoryWorking) {
            _diceOutcomeMessage = "ROLLED A 2!\nDisaster: Accident at the Munitions Factory!";
            _diceOutcomeAction = () {
              _showMunitionsFactoryExplosionDisaster(progress, service);
            };
          } else {
            _diceOutcomeMessage = "ROLLED A 2!\nDisaster narrowly avoided (no active high-risk facilities).";
            _diceOutcomeAction = null;
          }
        }
        break;

      case 4:
        _diceOutcomeMessage = "ROLLED A 4!\nBad omen: -1 starting AP in the next combat.";
        _diceOutcomeAction = () {
          progress.cardUpgrades['next_combat_ap_modifier'] = -1;
          service.manualSave();
        };
        break;

      case 10:
        _diceOutcomeMessage = "ROLLED A 10!\nGood omen: +1 starting AP in the next combat.";
        _diceOutcomeAction = () {
          progress.cardUpgrades['next_combat_ap_modifier'] = 1;
          service.manualSave();
        };
        break;

      default:
        _diceOutcomeMessage = "ROLLED A $total.\nNothing happens this turn.";
        _diceOutcomeAction = null;
        break;
    }

    setState(() {});
  }

  void _showMunitionsFactoryExplosionDisaster(
    SurvivalProgress progress,
    SurvivalService service,
  ) {
    final factoryBuilding = progress.buildings.firstWhereOrNull(
      (b) => b.type == SurvivalBuildingType.munitionsFactory,
    );
    if (factoryBuilding != null) {
      if (factoryBuilding.level > 1) {
        factoryBuilding.level -= 1;
      } else {
        progress.buildings.remove(factoryBuilding);
      }
    }
    progress.wood = max(0, progress.wood - 100);
    progress.iron = max(0, progress.iron - 50);
    service.addLog('Disaster: Munitions Factory explosion! Facility damaged, -100 Wood, -50 Iron.');
    service.manualSave();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 340,
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
                  'MUNITIONS FACTORY EXPLOSION',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "A devastating explosion tore through the Munitions Factory today! The facility's level has been reduced by 1, and we have lost 100 Wood and 50 Iron in the ensuing fires.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white70,
                    fontSize: 13.5,
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
