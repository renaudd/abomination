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
import 'package:google_fonts/google_fonts.dart';
import '../../services/combat_unit_service.dart';
import '../widgets/character_blob_renderer.dart';
import '../widgets/combat_card_detail_modal.dart';
import '../widgets/combat_controls_dialog.dart';
import 'combat_simulator_map_selection_screen.dart';


class CombatSimulatorScreen extends StatefulWidget {
  const CombatSimulatorScreen({super.key});

  @override
  State<CombatSimulatorScreen> createState() => _CombatSimulatorScreenState();
}

class _CombatSimulatorScreenState extends State<CombatSimulatorScreen> {
  final List<String> _playerDeckTypes = [];
  final List<String> _aiDeckTypes = [];
  bool _isPlayerDeckSelected = true;

  final List<String> _availableTypes = [
    'giles',
    'cannoneer',
    'musketeers',
    'cavalry',
    'bicycle_gang',
    'motorcycle_gang',
    'armored_car',
    'wooden_tank',
    'undead_rats',
    'brown_rats',
    'werewolf',
    'chimera',
    'flesh_golem',
    'villager_mob',
    'samurai',
    'mercenaries',
    'commandos',
    'sniper',
    'wild_foxes',
    'wild_wolves',
    'wild_bears',
    'bandits',
    'thugs',
    'deserters',
    'halberdiers',
    'pikemen',
    'policemen',
    'marksmen',
    'artillery_barrage',
    'tear_gas_grenade',
    'caltrops',
    'vampiric_totem',
    'militia',
    'goons',
    'footman',
    'bandit_captain',
    'bats',
    'stampede',
    'brewers',
    'hag',
    'witch',
    'warlock',
    'gatling_gun',
    'zeppelin',
    'valkyrie',
    'minotaur',
    'phoenix',
    'necromancer',
    'battering_ram',
    'steampunk_mech',
    'steampunk_robot',
    'poison_gas',
    'lightning_storm',
    'divine_shield',
    'napalm_strike',
    'masonic_sapper',
    'sacred_geometry',
    'homunculus_behemoth',
    'elixir_of_vitality',
    'templar_pyre_knight',
    'greek_fire_flask',
    'vault_assassin',
    'zurich_debt_collector',
    'carbonari_arsonist',
    'revolutionary_martyr',
    'hermetic_mesmerist',
    'astral_hypnosis',
    'fenian_night_raider',
    'insurgent_cell',
    'royalist_cuirassier',
    'royalist_standard_bearer',
    'forester_herbalist',
    'forester_beastmaster',
  ];

  @override
  void initState() {
    super.initState();
    _randomizeDecks();
  }

  void _randomizeDecks() {
    final shuffled = _availableTypes.toList()..shuffle();
    _playerDeckTypes.clear();
    _aiDeckTypes.clear();
    _playerDeckTypes.addAll(shuffled.take(12));
    _aiDeckTypes.addAll(shuffled.skip(12).take(12));
  }

  void _addUnit(String type) {
    setState(() {
      final targetDeck = _isPlayerDeckSelected
          ? _playerDeckTypes
          : _aiDeckTypes;
      if (targetDeck.length < 12 && !targetDeck.contains(type)) {
        targetDeck.add(type);
      }
    });
  }

  void _removeUnit(int index) {
    setState(() {
      final targetDeck = _isPlayerDeckSelected
          ? _playerDeckTypes
          : _aiDeckTypes;
      targetDeck.removeAt(index);
    });
  }

  void _goToMapSelection() {
    if (_playerDeckTypes.length < 12 || _aiDeckTypes.length < 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Both decks must have 12 units.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CombatSimulatorMapSelectionScreen(
          playerDeckTypes: _playerDeckTypes,
          aiDeckTypes: _aiDeckTypes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      appBar: AppBar(
        title: Text(
          'COMBAT SIMULATOR',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            fontSize: 18,
            color: const Color(0xFFE5D5B0),
          ),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE5D5B0)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Row(
        children: [
          // Left: Available Units
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.white10)),
              ),
              child: Column(
                children: [
                  _sectionHeader("AVAILABLE CARDS"),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _availableTypes.length,
                      itemBuilder: (context, index) {
                        final type = _availableTypes[index];
                        final sampleUnit = CombatUnitService.createUnit(type);
                        final stats = sampleUnit.combatStats!;

                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: InkWell(
                            onTap: () => CombatCardDetailModal.show(
                              context,
                              type,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: CharacterBlobRenderer(
                                  npc: sampleUnit,
                                  size: 28,
                                  isCombat: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      type.toUpperCase().replaceAll('_', ' '),
                                      style: GoogleFonts.playfairDisplay(
                                        color: const Color(0xFFE5D5B0),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "HP:${stats.maxHealth.toInt()} | ATK:${stats.attack.toInt()} | SPD:${stats.speed} | ACC:${(stats.accuracy * 100).toInt()}%",
                                      style: GoogleFonts.playfairDisplay(
                                        color: Colors.white70,
                                        fontSize: 9.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    ...sampleUnit.abilities.map(
                                      (a) => Padding(
                                        padding: const EdgeInsets.only(bottom: 2),
                                        child: Text(
                                          "• ${a.name}: ${a.description}",
                                          style: GoogleFonts.playfairDisplay(
                                            color: Colors.white38,
                                            fontSize: 8.5,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${stats.cost} AP",
                                    style: GoogleFonts.oswald(
                                      color: Colors.cyanAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 18,
                                      color: Color(0xFFC4B89B),
                                    ),
                                    onPressed: () => _addUnit(type),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
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
            ),
          ),

          // Right: Deck Building
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Row(
                  children: [
                    _deckTab(
                      "PLAYER DECK",
                      _isPlayerDeckSelected,
                      () => setState(() => _isPlayerDeckSelected = true),
                    ),
                    _deckTab(
                      "AI DECK",
                      !_isPlayerDeckSelected,
                      () => setState(() => _isPlayerDeckSelected = false),
                    ),
                  ],
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Expanded(
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                ),
                            itemCount: 12,
                            itemBuilder: (context, index) {
                              final currentDeck = _isPlayerDeckSelected
                                  ? _playerDeckTypes
                                  : _aiDeckTypes;
                              final bool hasUnit = index < currentDeck.length;
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(
                                      0xFFC4B89B,
                                    ).withValues(alpha: 0.3),
                                  ),
                                  color: Colors.black26,
                                ),
                                child: hasUnit
                                    ? InkWell(
                                        onTap: () => CombatCardDetailModal.show(
                                          context,
                                          currentDeck[index],
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              CharacterBlobRenderer(
                                                npc:
                                                    CombatUnitService.createUnit(
                                                      currentDeck[index],
                                                    ),
                                                size: 30,
                                                isCombat: true,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                currentDeck[index]
                                                    .replaceAll('_', ' ')
                                                    .toUpperCase(),
                                                style: GoogleFonts.oswald(
                                                  color: Colors.white70,
                                                  fontSize: 8,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                size: 14,
                                                color: Colors.redAccent,
                                              ),
                                              onPressed: () =>
                                                  _removeUnit(index),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : const Center(
                                        child: Icon(
                                          Icons.add,
                                          color: Colors.white10,
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => const CombatControlsDialog(),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFE5D5B0),
                                side: const BorderSide(color: Color(0xFFC4B89B)),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              child: Text(
                                "CONTROLS",
                                style: GoogleFonts.playfairDisplay(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _goToMapSelection,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC4B89B),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              child: Text(
                                "SELECT MAP",
                                style: GoogleFonts.playfairDisplay(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ],
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

  Widget _sectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      width: double.infinity,
      color: Colors.black26,
      child: Text(
        title,
        style: GoogleFonts.oldStandardTt(
          color: const Color(0xFFC4B89B),
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _deckTab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? const Color(0xFFC4B89B) : Colors.transparent,
                width: 2,
              ),
            ),
            color: active
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.transparent,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: active ? const Color(0xFFE5D5B0) : Colors.white24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
