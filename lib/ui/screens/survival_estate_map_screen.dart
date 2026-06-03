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
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import '../../models/survival_state.dart';
import '../../models/npc.dart';
import '../../models/combat_stats.dart';
import '../../services/survival_service.dart';
import '../../services/combat_unit_service.dart';
import '../../services/combat_unit_factory.dart';
import '../widgets/character_blob_renderer.dart';
import 'combat_screen.dart';

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
    damage: 34,
    speed: 2.0,
    range: 10.0,
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
    name: 'Straight-Line Laser System',
    cost: 60,
    isRanged: true,
    damage: 28,
    speed: 1.9,
    range: 8.0,
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
  State<SurvivalEstateMapScreen> createState() => _SurvivalEstateMapScreenState();
}

class _SurvivalEstateMapScreenState extends State<SurvivalEstateMapScreen> {
  bool _isDrafting = true;
  final List<String> _selectedCart = [];
  
  String _activeTab =
      'ESTATE'; // 'ESTATE', 'DECK', 'LEADER', 'TOWERS', 'MARKET', 'MANOR_RECORDS'
  final Map<String, GeneralWeaponSpec?> _evaluatedWeaponForCard = {};

  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController(
      Matrix4.identity()..scale(0.35),
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
    final currentWepIdx =
        service.progress!.cardUpgrades['${cardId}_equipped_weapon_idx'] ?? 0;
    final currentWepName = currentWepIdx == 0
        ? _getStartingWeapon(cardId).name
        : _generalWeaponMarket[currentWepIdx - 1].name;
    final currWep = _getEquippedWeaponStats(cardId, currentWepName);
    final currentScore = _scoreWeapon(cardId, currWep);

    final compatibleWeps = availableWeps
        .where((w) => _getWeaponCompatibilityError(cardId, w.name) == null)
        .toList();

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
  String? _selectedWepCardId;
  String? _selectedInspectorCardId;

  final List<Map<String, dynamic>> _draftPool = [
    {'type': 'peasant', 'cost': 150, 'name': 'Peasant'},
    {'type': 'goon', 'cost': 200, 'name': 'Goon'},
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
  ];

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<SurvivalService>(context);
    final state = Provider.of<GameState>(context);
    final progress = service.progress;

    if (progress == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF15100B),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFC4B89B))),
      );
    }

    // Turn off embark shop overlay if player already finished drafting (deck contains cards and we aren't showing drafting)
    if (_isDrafting && progress.playerDeckIds.isNotEmpty && _selectedCart.isEmpty) {
      _isDrafting = false;
    }

    // Auto-trigger Turn 4 narrative dialogue if not resolved
    final turn4Resolved = progress.cardUpgrades['turn4_event_resolved'] == 1;
    if (progress.currentTurn == 4 && !turn4Resolved && !_isDrafting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showEventSelectionDialogue(context, progress, service);
      });
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
        ],
      ),
    );
  }

  // HUD HEADER
  Widget _buildHUD(SurvivalProgress progress, SurvivalService service, GameState state) {
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
              _buildNavButton('MENU', () => _showMenuOverlay(progress, service, state)),
            ],
          ),

          Row(
            children: [
              _buildResourceChip(Icons.monetization_on, '${progress.cash} CHF', Colors.amber.shade700),
              const SizedBox(width: 8),
              _buildResourceChip(Icons.restaurant, '${progress.food} FOOD', Colors.green.shade700),
              const SizedBox(width: 8),
              _buildResourceChip(Icons.forest, '${progress.wood} WOOD', Colors.brown.shade700),
              const SizedBox(width: 8),
              _buildResourceChip(Icons.construction, '${progress.iron} IRON', Colors.blueGrey.shade600),
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
          border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.4)),
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
    String towerLetters = '';
    if ((progress.towerDamaged['tower_1'] ?? 0.0) >= 1.0) towerLetters += 'L';
    if ((progress.towerDamaged['tower_2'] ?? 0.0) >= 1.0) towerLetters += 'M';
    if ((progress.towerDamaged['tower_3'] ?? 0.0) >= 1.0) towerLetters += 'R';
    final hasTowerDamage = towerLetters.isNotEmpty;

    return InteractiveViewer(
      transformationController: _transformationController,
      constrained: false,
      minScale: 0.2,
      maxScale: 3.0,
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
              'LEFT TOWER',
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
              'RIGHT TOWER',
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
              'AROSA PLOT (ADVANCED)',
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
              'BERN PLOT (ADVANCED)',
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
              'DAVOS PLOT (BASIC)',
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
              'ENGELBERG PLOT (BASIC)',
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
              'FRIBOURG PLOT (BASIC)',
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
              'GRINDELWALD PLOT (BASIC)',
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
    final lvl = progress.towerLevels['health'] ?? 1;

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
                    )
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
                              dragAnchorStrategy: pointerDragAnchorStrategy,
                              feedback: Material(
                                color: Colors.transparent,
                                child: CharacterBlobRenderer(
                                  npc: CombatUnitService.createUnit(progress.trainingUnitIds[idx]),
                                  size: 48,
                                  isCombat: true,
                                ),
                              ),
                              onDragCompleted: () {
                                setState(() {});
                              },
                              child: CharacterBlobRenderer(
                                npc: CombatUnitService.createUnit(progress.trainingUnitIds[idx]),
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
        onWillAcceptWithDetails: (details) => b.assignedUnitIds.length < caps,
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
                    b.type.name
                        .replaceAll("lumberMill", "Mill")
                        .replaceAll("arsenal", "Arsenal")
                        .toUpperCase(),
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
                                dragAnchorStrategy: pointerDragAnchorStrategy,
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
  Widget _buildSideDeckDrawer(SurvivalProgress progress, SurvivalService service) {
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
                    if (progress.trainingUnitIds.contains(type))
                      isAssigned = true;

                    final exp = progress.unitExp[type] ?? 0.0;
                    final lvl = SurvivalProgress.getLevelFromXp(exp);

                    return Draggable<String>(
                      data: type,
                      dragAnchorStrategy: pointerDragAnchorStrategy,
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
                                  Text(
                                    npc.name.toUpperCase(),
                                    style: GoogleFonts.oldStandardTt(
                                      color: isAssigned
                                          ? Colors.white38
                                          : const Color(0xFFE5D5B0),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
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

  Widget _buildFooter(SurvivalProgress progress, SurvivalService service, GameState state) {
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
                      style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 8.5),
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
                // Capture levels before turn resolution
                final Map<String, int> levelsBefore = {};
                for (var t in progress.playerDeckIds) {
                  final exp = progress.unitExp[t] ?? 0.0;
                  levelsBefore[t] = SurvivalProgress.getLevelFromXp(exp);
                }

                // Trigger turn resolution
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
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Positioned.fill(child: FireworksOverlay()),
                            Container(
                              width: 320,
                              padding: const EdgeInsets.all(20),
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
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'LEVEL UP!',
                                    style: GoogleFonts.oswald(
                                      color: const Color(0xFFD4AF37),
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  CharacterBlobRenderer(
                                    npc: CombatUnitService.createUnit(
                                      levelUp['cardId'],
                                    ),
                                    size: 80,
                                    isCombat: true,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    CombatUnitService.createUnit(
                                      levelUp['cardId'],
                                    ).name.toUpperCase(),
                                    style: GoogleFonts.playfairDisplay(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Level ${levelUp['oldLvl']} ➔ Level ${levelUp['newLvl']}',
                                    style: GoogleFonts.oswald(
                                      color: const Color(0xFFE5D5B0),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(color: Colors.white10),
                                  const SizedBox(height: 10),
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
                                  const SizedBox(height: 8),
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
                                  const SizedBox(height: 20),
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
                          ],
                        ),
                      ),
                    );
                  }
                }

                processLevelUps().then((_) {
                  // Route straight to Combat stage! Leveled-up stats are dynamically mapped here!
                  final playerUnits = progress.playerDeckIds
                      .map((t) {
                    final npc = CombatUnitService.createUnit(t);
                    final exp = progress.unitExp[t] ?? 0.0;
                    final lvl = SurvivalProgress.getLevelFromXp(exp);
                    final mult = 1.0 + (lvl - 1) * 0.1;
                    return npc.copyWith(
                      combatStats: npc.combatStats?.copyWith(
                        health: npc.combatStats!.health * mult,
                        maxHealth: npc.combatStats!.maxHealth * mult,
                        attack: npc.combatStats!.attack * mult,
                        meleeDamage: npc.combatStats!.meleeDamage * mult,
                        rangedDamage: npc.combatStats!.rangedDamage * mult,
                      ),
                    );
                  }).toList();
                  final aiUnits = [
                    CombatUnitFactory.createGoon(),
                    CombatUnitFactory.createGoon(),
                    CombatUnitFactory.createMilitia(),
                    CombatUnitFactory.createMilitia(),
                  ];

                  state.startCombatSimulation(playerUnits, aiUnits);

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CombatScreen(
                        customPlayerHero: CombatUnitFactory.createAlphonse(),
                        customPlayerDeck: playerUnits,
                        customAiDeck: aiUnits,
                        cardUpgrades: progress.cardUpgrades,
                        survivalTurn: progress.currentTurn,
                        onSurvivalVictory: (destroyedTowersCount, enemyDeck, spoilsFood, spoilsCash, spoilsIron, spoilsWood, playerTowerHealth) {
                          service.processCombatOutcome(
                            true,
                            false,
                            playerTowerHealth,
                            {},
                            opponentDeck: enemyDeck,
                            destroyedEnemyTowers: destroyedTowersCount,
                            customSpoilsFood: spoilsFood,
                            customSpoilsCash: spoilsCash,
                            customSpoilsIron: spoilsIron,
                            customSpoilsWood: spoilsWood,
                          );
                          state.clearEncounterState();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const SurvivalEstateMapScreen()),
                          );
                        },
                        onSurvivalDefeat: (destroyedTowersCount, enemyDeck, playerTowerHealth) {
                          service.processCombatOutcome(
                            false,
                            false,
                            playerTowerHealth,
                            {},
                            opponentDeck: enemyDeck,
                            destroyedEnemyTowers: destroyedTowersCount,
                            customSpoilsFood: 0,
                            customSpoilsCash: 0,
                            customSpoilsIron: 0,
                            customSpoilsWood: 0,
                          );
                          state.clearEncounterState();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const SurvivalEstateMapScreen()),
                          );
                        },
                        onSurvivalDraw: (destroyedTowersCount, enemyDeck, playerTowerHealth) {
                          service.processCombatOutcome(
                            false,
                            true,
                            playerTowerHealth,
                            {},
                            opponentDeck: enemyDeck,
                            destroyedEnemyTowers: destroyedTowersCount,
                            customSpoilsFood: 0,
                            customSpoilsCash: 0,
                            customSpoilsIron: 0,
                            customSpoilsWood: 0,
                          );
                          state.clearEncounterState();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const SurvivalEstateMapScreen()),
                          );
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
                style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 10.5, letterSpacing: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // EMBARK SHOP DRAFT OVERLAY
  Widget _buildDraftOverlay(SurvivalProgress progress, SurvivalService service) {
    int totalCost = 0;
    for (var type in _selectedCart) {
      final match = _draftPool.firstWhere((x) => x['type'] == type);
      totalCost += match['cost'] as int;
    }
    final budgetRemaining = 1000 - totalCost;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          children: [
            Text(
              'RECRUIT YOUR SURVIVAL SQUAD',
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFE5D5B0),
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 3,
              ),
            ),
            Text(
              'Spend your 1000 CHF budget wisely. Select units to add to your cart and deselect them to refund CHF.',
              style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 10.5, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.amber.withValues(alpha: 0.1),
              child: Text(
                'BUDGET REMAINING: $budgetRemaining CHF | SQUAD SIZE: ${_selectedCart.length}/12',
                style: GoogleFonts.oswald(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.0,
                ),
                itemCount: _draftPool.length,
                itemBuilder: (context, index) {
                  final item = _draftPool[index];
                  final type = item['type'] as String;
                  final cost = item['cost'] as int;
                  
                  final unit = CombatUnitService.createUnit(type);
                  final isSelected = _selectedCart.contains(type);

                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF211B15),
                      border: Border.all(color: isSelected ? Colors.green : const Color(0xFFC4B89B), width: isSelected ? 2 : 1),
                    ),
                    child: Row(
                      children: [
                        CharacterBlobRenderer(npc: unit, size: 28, isCombat: true),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                unit.name.toUpperCase(),
                                style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 10, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$cost CHF',
                                style: GoogleFonts.oswald(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: isSelected
                              ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                              : const Icon(Icons.add_circle, color: Color(0xFFC4B89B), size: 20),
                          onPressed: () {
                            setState(() {
                              if (isSelected) {
                                _selectedCart.remove(type);
                              } else {
                                if (totalCost + cost <= 1000 && _selectedCart.length < 12) {
                                  _selectedCart.add(type);
                                } else if (_selectedCart.length >= 12) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Squad limit is 12 units!')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Insufficient CHF budget!')),
                                  );
                                }
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_selectedCart.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Draft at least 1 squad unit to embark!')),
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
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: const RoundedRectangleBorder(),
              ),
              child: Text(
                "EMBARK SURVIVAL OPERATION",
                style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // POP-UPS & CONTEXT MENUS
  void _showRepairDialog(BuildContext context, SurvivalService service, String towerId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E1A0A),
          title: Text('RECONSTRUCT TOWER', style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0))),
          content: Text(
            'Tower was destroyed in battle. Choose repair strategy:',
            style: GoogleFonts.oldStandardTt(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (service.repairTower(towerId, 'wood', 50, 0)) Navigator.pop(context);
              },
              child: Text('WOOD (50 Wood)', style: GoogleFonts.oswald(color: Colors.brown)),
            ),
            TextButton(
              onPressed: () {
                if (service.repairTower(towerId, 'cash', 0, 180)) Navigator.pop(context);
              },
              child: Text('CONTRACT (180 CHF)', style: GoogleFonts.oswald(color: Colors.amber)),
            ),
            TextButton(
              onPressed: () {
                if (service.repairTower(towerId, 'labor', 0, 0)) Navigator.pop(context);
              },
              child: Text('MANUAL LABOR (2 workers)', style: GoogleFonts.oswald(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

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
            final globalRangeLvl = currentProgress.cardUpgrades['tower_range'] ?? 0;
            final globalSpeedLvl = currentProgress.cardUpgrades['tower_speed'] ?? 0;

            // Individual Spire Upgrade levels
            final indHpLvl = currentProgress.cardUpgrades['${towerId}_hp'] ?? 0;
            final indAtkLvl = currentProgress.cardUpgrades['${towerId}_atk'] ?? 0;
            final indRangeLvl = currentProgress.cardUpgrades['${towerId}_range'] ?? 0;
            final indSpeedLvl = currentProgress.cardUpgrades['${towerId}_speed'] ?? 0;

            // Combined Stats
            final currentHealth = 200 + (globalHpLvl * 50) + (indHpLvl * 25);
            final currentDamage = 30 + (globalAtkLvl * 10) + (indAtkLvl * 5);
            final currentRange = 20.0 + (globalRangeLvl * 2.5) + (indRangeLvl * 1.5);
            final currentRateOfFire = (2.0 - (globalSpeedLvl * 0.2) - (indSpeedLvl * 0.1)).clamp(0.4, 2.0);

            final isDestroyed =
                (currentProgress.towerDamaged[towerId] ?? 0.0) >= 1.0;
            final friendlyName = towerId == 'tower_1'
                ? 'LEFT WATCHTOWER'
                : towerId == 'tower_2'
                ? 'MIDDLE WATCHTOWER'
                : 'RIGHT WATCHTOWER';

            const woodRepairCost = 50;
            const cashRepairCost = 180;

            return AlertDialog(
              backgroundColor: const Color(0xFF1E1712),
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
                      fontSize: 18,
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
                        fontSize: 12,
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
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                                  const SizedBox(height: 16),
                                  const Divider(color: Colors.white10),
                                  const SizedBox(height: 8),
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
                                    label: 'MANUAL LABOR (2 Workers)',
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
                                  cost: 20 + indHpLvl * 15,
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
                                  cost: 20 + indAtkLvl * 15,
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
                                  cost: 40 + indRangeLvl * 20,
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
                                  cost: 50 + indSpeedLvl * 25,
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
                        if (service.upgradeIndividualTower(towerId, stat, cost)) {
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

  Widget _buildUpgradeActionRow({
    required String label,
    required String stat,
    required int currentLvl,
    required int maxLvl,
    required int cost,
    required bool unlocked,
    String? unlockReason,
    required SurvivalProgress progress,
    required SurvivalService service,
    required VoidCallback onSuccess,
  }) {
    final completed = currentLvl >= (maxLvl == 0 ? 1 : 5);
    final canAfford = progress.cash >= cost;
    final enabled = unlocked && canAfford && !completed;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        border: Border.all(
          color: completed
              ? Colors.green.withValues(alpha: 0.3)
              : (unlocked
                    ? const Color(0xFFC4B89B).withValues(alpha: 0.15)
                    : Colors.white10),
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
          if (!completed) ...[
            if (!unlocked && unlockReason != null)
              Text(
                unlockReason,
                style: GoogleFonts.oldStandardTt(
                  color: Colors.redAccent.withValues(alpha: 0.8),
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
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
                          if (service.upgradeTower(stat, cost)) {
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
        ],
      ),
    );
  }

  bool _isAdvancedPlot(String plotKey) {
    return plotKey == 'plot_a' || plotKey == 'plot_b';
  }

  void _showBuildMenu(BuildContext context, SurvivalService service, String plotKey) {
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
            isAdvanced ? 'CONSTRUCT ADVANCED FACILITY' : 'CONSTRUCT BASIC FACILITY',
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
                  _buildBuildOption(dialogContext, service, plotKey, SurvivalBuildingType.garage, 120, 40, 400),
                  _buildBuildOption(dialogContext, service, plotKey, SurvivalBuildingType.munitionsFactory, 150, 50, 500),
                ]
              : [
                  _buildBuildOption(dialogContext, service, plotKey, SurvivalBuildingType.farm, 40, 0, 100),
                  _buildBuildOption(dialogContext, service, plotKey, SurvivalBuildingType.lumberMill, 60, 5, 150),
                  _buildBuildOption(dialogContext, service, plotKey, SurvivalBuildingType.mine, 80, 15, 200),
                ],
        );
      },
    );
  }

  Widget _buildBuildOption(BuildContext dialogContext, SurvivalService service, String plotKey, SurvivalBuildingType type, int wood, int iron, int cash) {
    return SimpleDialogOption(
      onPressed: () {
        if (service.buildFacility(plotKey, type, wood, iron, cash)) {
          Navigator.pop(dialogContext);
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(type.name.replaceAll("_", " ").toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11)),
          Text('$wood W | $iron I | $cash CHF', style: const TextStyle(color: Colors.amber, fontSize: 9)),
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
            width: 320,
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
                const SizedBox(height: 12),
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),
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

  void _showPurchasePlotConfirmation(BuildContext context, SurvivalService service, String plotKey, int costGhc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E1A0A),
          title: Text('ACQUIRE ESTATE LAND', style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0))),
          content: Text(
            'Would you like to clear and unlock this plot slot for $costGhc CHF?',
            style: const TextStyle(color: Colors.white70),
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
    showDialog(
      context: context,
      builder: (context) {
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
            width: 320,
            height: 160,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMenuOptionBtn('OPTIONS & CONTROLS', () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF2E1A0A),
                      title: const Text('GAME CONTROLS'),
                      content: const Text(
                        'Assign squad workers to Farms, Lumber Mills, and Mines to produce critical food, wood and iron.\n\n'
                        'Assign squads to Training Yard to increase their combat tiers. Ensure you have enough food to feed basic/elite units each turn, otherwise they starve and desert!',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                _buildMenuOptionBtn('MANUAL SAVE STATE', () {
                  service.manualSave();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('State saved successfully!')),
                  );
                  Navigator.pop(context);
                }),
                const SizedBox(height: 8),
                _buildMenuOptionBtn('LOAD SAVE STATE', () {
                  service.reloadProgress();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Survival progress reloaded successfully!'),
                    ),
                  );
                  Navigator.pop(context);
                }),
                const SizedBox(height: 8),
                _buildMenuOptionBtn('QUIT TO ARENA HUB', () {
                  Navigator.pop(context); // Close Menu
                  Navigator.pop(context); // Quit Survival
                }, isDanger: true),
              ],
            ),
          ),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column: Chronological Action Logs
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.all(12),
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
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 6),
                        Expanded(
                          child: service.logs.isEmpty
                              ? Center(
                                  child: Text(
                                    'The chronicle is empty. Actions are recorded here as turns progress.',
                                    style: GoogleFonts.oldStandardTt(
                                      color: Colors.white24,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 11,
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
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        '• $log',
                                        style: GoogleFonts.oldStandardTt(
                                          color: const Color(
                                            0xFFE5D5B0,
                                          ).withValues(alpha: 0.8),
                                          fontSize: 11.5,
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

                const SizedBox(width: 16),

                // Right column: Active Assignments & Land Covenants
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Container(
                          padding: const EdgeInsets.all(12),
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Divider(color: Colors.white10),
                              const SizedBox(height: 6),
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

                      const SizedBox(height: 16),

                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(12),
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
                                'ACTIVE COVENANTS & TREATIES',
                                style: GoogleFonts.playfairDisplay(
                                  color: const Color(0xFFD4AF37),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Divider(color: Colors.white10),
                              const SizedBox(height: 6),
                              Expanded(
                                child: progress.currentTurn < 4
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Text(
                                            'The registry of treaties remains vacant. No formal covenants or external agreements have been ratified. The ledger awaits the fateful decisions of Turn 4.',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.playfairDisplay(
                                              color: const Color(
                                                0xFFE5D5B0,
                                              ).withValues(alpha: 0.4),
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      )
                                    : ListView(
                                        children: [
                                          _buildCovenantItem(
                                            'RAT ERADICATION COVENANT',
                                            'Exterminate undead vermin threat in eastern cellar. Reward: 500 CHF, +50 Food. Status: Active.',
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

    final deck = progress.playerDeckIds;
    final List<String> idle = [];
    for (final id in deck) {
      bool isAssigned = false;
      for (final b in progress.buildings) {
        if (b.assignedUnitIds.contains(id)) isAssigned = true;
      }
      if (progress.trainingUnitIds.contains(id)) isAssigned = true;
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

    // The grid of 12 cards should take up about 72% of the screen height (making cards slightly larger)
    final double totalGridHeight = size.height * 0.72;
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
        // Deep brown backing
        Positioned.fill(child: Container(color: const Color(0xFF1A130E))),
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF3E2723), // Mahogany Cost Backing
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37), width: 2.0),
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
                fontSize: 22.0,
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
          const SizedBox(height: 3),
          SizedBox(
            height: 18,
            child: Row(
              children: [
                if (stats.isFlying == true)
                  const Padding(
                    padding: EdgeInsets.only(right: 5.0),
                    child: Icon(
                      Icons.flutter_dash,
                      size: 16.0,
                      color: Color(0xFF4E342E),
                    ),
                  ),
                if (stats.trait == CombatTrait.magicImmune)
                  const Padding(
                    padding: EdgeInsets.only(right: 5.0),
                    child: Icon(
                      Icons.block,
                      size: 16.0,
                      color: Color(0xFFC62828),
                    ),
                  ),
                if (stats.unitType == UnitType.support)
                  const Padding(
                    padding: EdgeInsets.only(right: 5.0),
                    child: Icon(
                      Icons.local_fire_department,
                      size: 16.0,
                      color: Color(0xFFE64A19),
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
              // Casting cost in the bottom left corner (JUST the number, considerably larger circular emblem)
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF3E2723), // Mahogany Cost Backing
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD4AF37),
                    width: 2.0,
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
                    fontSize: 22.0, // considerably larger cost number
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
                      DaggerIcon(color: Colors.deepOrange.shade800, size: 18.0),
                      const SizedBox(width: 4),
                      Text(
                        '${stats.meleeDamage.toInt()}',
                        style: GoogleFonts.oswald(
                          color: Colors.deepOrange.shade800,
                          fontSize: 18.0, // considerably larger
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (stats.rangedDamage > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.gps_fixed,
                          size: 17.0,
                          color: Colors.deepOrange.shade800,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${stats.rangedDamage.toInt()}',
                          style: GoogleFonts.oswald(
                            color: Colors.deepOrange.shade800,
                            fontSize: 18.0, // considerably larger
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Health stat row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 17.0,
                        color: Colors.green.shade900,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${stats.maxHealth.toInt()}',
                        style: GoogleFonts.oswald(
                          color: Colors.green.shade900,
                          fontSize: 18.0, // considerably larger
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Squad unit count row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.group,
                        size: 17.0,
                        color: Color(0xFF4E342E),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'x$squadSize',
                        style: GoogleFonts.oldStandardTt(
                          color: const Color(0xFF4E342E),
                          fontSize: 17.0, // considerably larger
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
      padding: const EdgeInsets.all(16),
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD4AF37),
                                width: 2.5,
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
                                size: 90,
                                isCombat: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            leader.name.toUpperCase(),
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFE5D5B0),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            leader.role.toUpperCase(),
                            style: GoogleFonts.oldStandardTt(
                              color: const Color(0xFFD4AF37),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Passive Bonuses: Military units gain +10% critical chance, and defensive towers receive +15% armor when under the direct command of Alphonse.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.oldStandardTt(
                              color: Colors.white70,
                              fontSize: 13.5,
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TACTICAL LEADER PROFILE DETAILS',
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFC4B89B),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

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

                          const Divider(color: Colors.white10, height: 16),

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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COMMANDER REINFORCEMENTS',
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFD4AF37),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reinforce commander attributes. Attributes are dynamically applied during defensive combat matches.',
                            style: GoogleFonts.oldStandardTt(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 16),

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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black12,
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFFD4AF37)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Level $currentLvl Reinforcement',
                      style: GoogleFonts.oldStandardTt(
                        color: Colors.white38,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 28,
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
                  fontSize: 10,
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
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF18120D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'ESTATE DEFENSIVE COVENANT & WATCHTOWERS',
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFE5D5B0),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),

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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'DEFENSIVE TOWERS',
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFC4B89B),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Circular Portrait Frame representing Watchtower Spires
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD4AF37),
                                width: 2.5,
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
                                    _buildGothicSpire(45),
                                    _buildGothicSpire(60),
                                    _buildGothicSpire(45),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'WATCHTOWER COVENANT',
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFE5D5B0),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Defensive watchtowers constructed along the Frankenstein Manor defensive walls. Towers automatically target hostile invaders in the active lanes and supply critical artillery fire support during combat stages.',
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STATS & CORE SUBSYSTEMS',
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFC4B89B),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 16),
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
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
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
                                      size: 18.0,
                                    ),
                                    const SizedBox(height: 12),
                                    ...List.generate(5, (index) {
                                      final targetLvl = index + 2;
                                      final cost = 40 + (targetLvl - 2) * 20;
                                      final isCompleted =
                                          (atkLvl + 1) >= targetLvl;
                                      final isUnlocked =
                                          atkLvl >= targetLvl - 2;

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12.0,
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
                                    const SizedBox(height: 134.0),
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
                                      cost: 120,
                                      isUnlocked:
                                          rangeUnlocked && rangeLvl == 0,
                                      isCompleted: rangeLvl >= 1,
                                      icon: Icons.gps_fixed,
                                      label: 'Ballistics Range',
                                      progress: progress,
                                      service: service,
                                    ),
                                    // Spacing placing reload speed lower than all 5 left/right bubbles
                                    const SizedBox(height: 120.0),
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
                                      cost: 200,
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
                                      size: 18.0,
                                    ),
                                    const SizedBox(height: 12),
                                    ...List.generate(5, (index) {
                                      final targetLvl = index + 2;
                                      final cost = 40 + (targetLvl - 2) * 20;
                                      final isCompleted =
                                          (hpLvl + 1) >= targetLvl;
                                      final isUnlocked = hpLvl >= targetLvl - 2;

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12.0,
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? const Color(0xFF1E2A1C)
                    : isUnlocked
                    ? const Color(0xFF211A12)
                    : const Color(0xFF15100C),
                border: Border.all(
                  color: activeColor,
                  width: isUnlocked ? 2.0 : 1.0,
                ),
                boxShadow: [
                  if (isUnlocked && canAfford)
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Color(0xFF4CAF50),
                      )
                    : isUnlocked
                    ? Icon(icon, size: 16, color: const Color(0xFFD4AF37))
                    : const Icon(
                        Icons.lock_outline,
                        size: 14,
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
      padding: const EdgeInsets.all(16),
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
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
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
                        const SizedBox(height: 24),

                        Text(
                          'HIRE SQUAD MERCENARIES',
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFFC4B89B),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: List.generate(availableHires.length, (
                            index,
                          ) {
                            final hire = availableHires[index];
                            final type = hire['type'] as String;
                            final cost = hire['cost'] as int;
                            final npc = CombatUnitService.createUnit(type);
                            final canAfford =
                                progress.cash >= cost &&
                                progress.playerDeckIds.length < 12;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
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
                                    size: 38,
                                    isCombat: true,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          npc.name.toUpperCase(),
                                          style: GoogleFonts.playfairDisplay(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '$cost CHF | Type: ${npc.specimenType.toUpperCase()}',
                                          style: GoogleFonts.oldStandardTt(
                                            color: Colors.white54,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: canAfford
                                            ? const Color(0xFFC4B89B)
                                            : Colors.white10,
                                      ),
                                      backgroundColor: canAfford
                                          ? const Color(0xFF2E1A0A)
                                          : Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                    ),
                                    onPressed: canAfford
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
                                      'RECRUIT',
                                      style: GoogleFonts.playfairDisplay(
                                        color: canAfford
                                            ? const Color(0xFFE5D5B0)
                                            : Colors.white24,
                                        fontSize: 12,
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

                const SizedBox(width: 20),

                // Right Panel: Scrollable Weapons Engineering requisition Section
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(16),
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Upgrade weapon kits for military forces. Beasts and chimeric specimens cannot equip weapons.',
                            style: GoogleFonts.oldStandardTt(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildWeaponsRequisitionSection(progress, service),
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

  Widget _buildMarketResourceBtnFull(
    SurvivalProgress progress,
    SurvivalService service,
    String res,
    int amount,
    int cost,
    IconData icon,
  ) {
    final canAfford = progress.cash >= cost;
    return SizedBox(
      width: 145,
      height: 45,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: canAfford ? const Color(0xFFC4B89B) : Colors.white10),
          backgroundColor: canAfford ? Colors.black26 : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 6),
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
              size: 16,
              color: canAfford ? const Color(0xFFE5D5B0) : Colors.white24,
            ),
            const SizedBox(width: 6),
            Text(
              '+$amount $res\n$cost CHF',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: canAfford ? const Color(0xFFE5D5B0) : Colors.white24,
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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

    final rawWeps = _getAvailableMarketWeapons(
      progress.currentTurn,
      progress.villageHealth,
    );
    // Compatible weapons for sale
    final compatibleWeps = rawWeps
        .where((w) => _getWeaponCompatibilityError(cardId, w.name) == null)
        .toList();

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
    final squadSize = _getSquadSize(cardId);
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
            fontSize: 13.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'DMG: ${currWep.damage.toStringAsFixed(0)} | SPD: ${currWep.speed.toStringAsFixed(1)}s | RNG: ${currWep.range.toStringAsFixed(1)} ft',
          style: GoogleFonts.oldStandardTt(
            color: Colors.white54,
            fontSize: 11.5,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: Colors.white10, height: 8),
        const SizedBox(height: 10),
        Text(
          'BLACK MARKET WEAPON REQUISITION LIST:',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFC4B89B),
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

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
                  Text(
                    wep.name.toUpperCase() + (isRec ? ' (RECOMMENDED)' : ''),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 12,
                      fontWeight: isRec ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${wep.cost} CHF',
                    style: GoogleFonts.oswald(
                      color: const Color(0xFFD4AF37),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        : 'NO COMPATIBLE WEAPONS FOR SALE',
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Color(0xFFC4B89B)),
              ],
            ),
          ),
        ),

        if (evaluatedWep != null && evaluatedStats != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.black26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UPGRADE STAT EVALUATION:',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
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
            const SizedBox(height: 8),
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
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],

          if (isLockedByArsenal) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.withValues(alpha: 0.1),
              width: double.infinity,
              child: Text(
                'LOCKED: Requires Arsenal Level $reqLvl on the Estate Map!',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford
                    ? const Color(0xFF2E1A0A)
                    : Colors.transparent,
                side: BorderSide(
                  color: canAfford ? const Color(0xFFD4AF37) : Colors.white10,
                ),
                shape: const RoundedRectangleBorder(),
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
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 16),
          Center(
            child: Text(
              'No weapon upgrade currently selected for evaluation.',
              style: GoogleFonts.oldStandardTt(
                color: Colors.white24,
                fontSize: 11.5,
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.oldStandardTt(
              color: highlight ? const Color(0xFFC4B89B) : Colors.white38,
              fontSize: 12.5,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Row(
            children: [
              Text(
                currentVal,
                style: GoogleFonts.oswald(
                  color: Colors.white54,
                  fontSize: 13.0,
                ),
              ),
              if (isChanged) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward,
                  color: Color(0xFFD4AF37),
                  size: 13,
                ),
                const SizedBox(width: 6),
                Text(
                  nextVal,
                  style: GoogleFonts.oswald(
                    color: const Color(0xFFD4AF37),
                    fontSize: 13.0,
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
    final stats = npc.combatStats!;
    final exp = progress.unitExp[cardId] ?? 0.0;
    final lvl = SurvivalProgress.getLevelFromXp(exp);
    final nextReq = SurvivalProgress.getRequiredXpForLevel(lvl + 1);
    final prevReq = lvl == 1 ? 0 : SurvivalProgress.getRequiredXpForLevel(lvl);
    final range = nextReq - prevReq;
    final pct = range == 0 ? 1.0 : ((exp - prevReq) / range).clamp(0.0, 1.0);

    final bool isMeleeOnly = stats.rangedDamage == 0.0;
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SQUAD COVENANT DETAIL INSPECTOR',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFFD4AF37),
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedInspectorCardId = null;
                    });
                  },
                ),
              ],
            ),
            const Divider(color: Color(0xFF3A2F25), height: 12),

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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFD4AF37),
                                  width: 2.5,
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
                                  size: 90,
                                  isCombat: true,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'MILITARY STANDING',
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFC4B89B),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'LEVEL $lvl',
                              style: GoogleFonts.oswald(
                                color: const Color(0xFFD4AF37),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 18,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      minHeight: 18,
                                      backgroundColor: Colors.black54,
                                      color: const Color(0xFFD4AF37),
                                    ),
                                  ),
                                  Text(
                                    '${exp.toInt()} / $nextReq XP',
                                    style: GoogleFonts.oswald(
                                      color: Colors.white,
                                      fontSize: 12,
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
                            const SizedBox(height: 20),
                            Text(
                              'MILITARY TRAINING LEVELING',
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFE5D5B0),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Deploy unit to training ground to earn +8 XP per turn passively, or spend cash budget directly below to purchase tactical drills.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.oldStandardTt(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: progress.cash >= 50
                                    ? const Color(0xFF2E1A0A)
                                    : Colors.transparent,
                                side: BorderSide(
                                  color: progress.cash >= 50
                                      ? const Color(0xFFC4B89B)
                                      : Colors.white10,
                                ),
                                shape: const RoundedRectangleBorder(),
                              ),
                              onPressed: progress.cash >= 50
                                  ? () {
                                      final oldExp =
                                          progress.unitExp[cardId] ?? 0.0;
                                      final oldLvl =
                                          SurvivalProgress.getLevelFromXp(
                                            oldExp,
                                          );
                                      if (service.buyTrainingPoints(
                                        cardId,
                                        10,
                                        50,
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
                                'BUY DRILLS: +10 XP (50 CHF)',
                                style: GoogleFonts.playfairDisplay(
                                  color: progress.cash >= 50
                                      ? const Color(0xFFE5D5B0)
                                      : Colors.white24,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REGIMENTAL ATTRIBUTES & PROFILE',
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFC4B89B),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

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

                            const Divider(color: Colors.white10, height: 16),

                            _buildInspectorStatRow(
                              'Melee Attack Force',
                              '${((stats.meleeDamage.toInt() > 0 ? stats.meleeDamage.toInt() : stats.attack.toInt()) * (1.0 + (lvl - 1) * 0.1)).toInt()} Damage',
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
                              const Divider(color: Colors.white10, height: 16),
                              Text(
                                'AMMUNITION & RANGED SPECIALIZATION',
                                style: GoogleFonts.playfairDisplay(
                                  color: const Color(0xFFD4AF37),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildInspectorStatRow(
                                'Ranged Bullet Damage',
                                '${stats.rangedDamage.toInt()} Damage',
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ARMORY WEAPONS ENGINEERING',
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFC4B89B),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Buy manufactured weapon engineering configurations directly changing all attack properties.',
                              style: GoogleFonts.oldStandardTt(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (!isRightCapable) ...[
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24.0,
                                  ),
                                  child: Text(
                                    'Beasts, undead vermin swarms, and chimeras cannot equip weaponry.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.oldStandardTt(
                                      color: Colors.white24,
                                      fontSize: 12,
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
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.oldStandardTt(
              color: Colors.white38,
              fontSize: 13.5,
            ),
          ),
          Text(
            val,
            style: GoogleFonts.oswald(
              color: Colors.white70,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showEventSelectionDialogue(
    BuildContext context,
    SurvivalProgress progress,
    SurvivalService service,
  ) {
    progress.cardUpgrades['turn4_event_resolved'] = 1;
    service.manualSave();

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
          title: Center(
            child: Text(
              'THE VERMIN PESTILENCE',
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFD4AF37),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'A frantic messenger from the lower vaults bursts into Frankenstein Manor. '
                  'The eastern catacombs are swarming with virulent undead rats spreading green pestilence! '
                  'Alphonse, we must act immediately to protect our food reserves and the estate populace.',
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A1E16),
                    side: const BorderSide(
                      color: Color(0xFFC4B89B),
                      width: 1.0,
                    ),
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () {
                    progress.villageHealth = 100;
                    service.addLog(
                      'Rat Eradication Treaty signed. Glarus Village is protected.',
                    );
                    service.manualSave();
                    Navigator.pop(context);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'OPTION A: SIGN RAT ERADICATION COVENANT',
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reward: +500 CHF, +50 Food. Glarus Village remains healthy.',
                        style: GoogleFonts.oldStandardTt(
                          color: Colors.white54,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF331111),
                    side: const BorderSide(color: Colors.redAccent, width: 1.0),
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () {
                    progress.food = (progress.food >= 20)
                        ? progress.food - 20
                        : 0;
                    progress.iron += 10;
                    progress.villageHealth = 0; // Destroyed!
                    service.addLog(
                      'Quarantined Eastern Vaults. Glarus Village was abandoned & wiped out!',
                    );
                    service.manualSave();
                    Navigator.pop(context);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'OPTION B: SEAL VAULTS & ENFORCE QUARANTINE',
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.redAccent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Penalty: -20 Food, +10 Iron. Glarus Village is abandoned and destroyed (Fallow).',
                        style: GoogleFonts.oldStandardTt(
                          color: Colors.white54,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LEVEL UP!',
                      style: GoogleFonts.oswald(
                        color: const Color(0xFFD4AF37),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CharacterBlobRenderer(npc: npc, size: 80, isCombat: true),
                    const SizedBox(height: 10),
                    Text(
                      npc.name.toUpperCase(),
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Level $oldLvl ➔ Level $newLvl',
                      style: GoogleFonts.oswald(
                        color: const Color(0xFFE5D5B0),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 10),
                    _buildLevelUpStatRow(
                      'MAX HEALTH (HP)',
                      oldHP.toInt().toString(),
                      newHP.toInt().toString(),
                    ),
                    const SizedBox(height: 8),
                    _buildLevelUpStatRow(
                      'ATTACK POWER',
                      oldAtk.toInt().toString(),
                      newAtk.toInt().toString(),
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
    canvas.drawLine(Offset(0, size.height * 0.33), Offset(size.width, size.height * 0.33), paint);
    canvas.drawLine(Offset(0, size.height * 0.66), Offset(size.width, size.height * 0.66), paint);

    // Vertical dividing tracks
    canvas.drawLine(Offset(size.width * 0.33, 0), Offset(size.width * 0.33, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.66, 0), Offset(size.width * 0.66, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// FIREWORKS PARTICLE EFFECT WIDGET
class FireworksOverlay extends StatefulWidget {
  const FireworksOverlay({super.key});

  @override
  State<FireworksOverlay> createState() => _FireworksOverlayState();
}

class _FireworksOverlayState extends State<FireworksOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_FireworkParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _spawnParticles();
  }

  void _spawnParticles() {
    final rand = Random();
    _particles.clear();
    for (int i = 0; i < 80; i++) {
      final angle = rand.nextDouble() * pi * 2;
      final speed = 2.0 + rand.nextDouble() * 6.0;
      final color = HSVColor.fromAHSV(
        1.0,
        rand.nextDouble() * 360,
        0.8,
        0.9,
      ).toColor();
      _particles.add(
        _FireworkParticle(angle: angle, speed: speed, color: color),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.value < 0.05) {
          _spawnParticles();
        }
        return CustomPaint(
          painter: _FireworksPainter(_controller.value, _particles),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _FireworkParticle {
  final double angle;
  final double speed;
  final Color color;

  _FireworkParticle({
    required this.angle,
    required this.speed,
    required this.color,
  });
}

class _FireworksPainter extends CustomPainter {
  final double progress;
  final List<_FireworkParticle> particles;

  _FireworksPainter(this.progress, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.4);
    final paint = Paint()..strokeCap = StrokeCap.round;

    for (final p in particles) {
      final dist = p.speed * progress * 150.0;
      final gravity = progress * progress * 40.0;
      final target =
          center + Offset(cos(p.angle) * dist, sin(p.angle) * dist + gravity);

      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: opacity);
      paint.strokeWidth = 3.0 * (1.0 - progress);

      canvas.drawLine(
        target - Offset(cos(p.angle) * 6.0, sin(p.angle) * 6.0),
        target,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
