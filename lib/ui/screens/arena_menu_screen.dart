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
import '../../models/arena_progress.dart';
import '../../models/npc.dart';
import '../../services/arena_save_service.dart';
import '../../services/combat_unit_factory.dart';
import '../widgets/character_blob_renderer.dart';
import '../widgets/combat_card_detail_modal.dart';
import '../../services/combat_unit_service.dart';
import 'combat_simulator_screen.dart';
import 'campaign_screen.dart';
import 'tournament_screen.dart';
import '../../services/survival_service.dart';
import 'survival_estate_map_screen.dart';
import 'package:provider/provider.dart';
import '../../models/survival_state.dart';

class ArenaMenuScreen extends StatefulWidget {
  const ArenaMenuScreen({super.key});

  @override
  State<ArenaMenuScreen> createState() => _ArenaMenuScreenState();
}

class _ArenaMenuScreenState extends State<ArenaMenuScreen> {
  int _activeSlot = 1;
  ArenaProgress? _loadedProgress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveSlot();
  }

  Future<void> _loadActiveSlot() async {
    setState(() => _isLoading = true);
    final progress = await ArenaSaveService.loadProgress(_activeSlot);
    setState(() {
      _loadedProgress = progress;
      _isLoading = false;
    });
  }

  Future<void> _changeSlot(int slot) async {
    setState(() {
      _activeSlot = slot;
    });
    await _loadActiveSlot();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Elegant dark gothic mahogany wood background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Color(0xFF2E2218), // Rich mahogany center
                    Color(0xFF15100B), // Black ebony shadow edge
                  ],
                ),
              ),
            ),
          ),

          // Diagonal subtle brass ornament overlays
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(
                painter: _BrassGeometricPainter(),
              ),
            ),
          ),

          // Central Menu Panel
          Center(
            child: Container(
              width: 600,
              height: 400,
              decoration: BoxDecoration(
                color: const Color(0xFF1D1712), // Deep mahogany box
                border: Border.all(
                  color: const Color(0xFFC4B89B).withValues(alpha: 0.35),
                  width: 2.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black87,
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 1. Sidebar details (Parcment Slot Info)
                  Container(
                    width: 220,
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Color(0xFF2C241E), width: 2.0),
                      ),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTIVE SLOT',
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFFC4B89B),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [1, 2, 3].map((slotNum) {
                            final isActive = _activeSlot == slotNum;
                            return SizedBox(
                              width: 54,
                              height: 28,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: isActive
                                      ? const Color(0xFFC4B89B).withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  side: BorderSide(
                                    color: isActive
                                        ? const Color(0xFFC4B89B)
                                        : const Color(0xFFC4B89B).withValues(alpha: 0.3),
                                    width: isActive ? 1.5 : 1.0,
                                  ),
                                  shape: const RoundedRectangleBorder(),
                                ),
                                onPressed: () => _changeSlot(slotNum),
                                child: Text(
                                  '#$slotNum',
                                  style: GoogleFonts.playfairDisplay(
                                    color: isActive ? Colors.white : Colors.white60,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Color(0xFF352B24)),
                        const SizedBox(height: 16),
                        Text(
                          'SLOT STATUS',
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFFC4B89B).withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 24.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFC4B89B),
                                ),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: _loadedProgress == null
                                ? Text(
                                    'EMPTY SLOT\n\nReady to begin a new Campaign or enter the Tournament.',
                                    style: GoogleFonts.oldStandardTt(
                                      color: Colors.white38,
                                      fontSize: 11,
                                      height: 1.5,
                                    ),
                                  )
                                : _loadedProgress!.campaign != null
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'CAMPAIGN ACTIVE',
                                            style: GoogleFonts.playfairDisplay(
                                              color: Colors.yellow.shade800,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _loadedProgress!.campaign!.campaignId
                                                .replaceAll('_', ' ')
                                                .toUpperCase(),
                                            style: GoogleFonts.playfairDisplay(
                                              color: const Color(0xFFE5D5B0),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                            Text(
                                              'Stage: ${_loadedProgress!.campaign!.currentStage + 1} / 20\nCoins: ${_loadedProgress!.campaign!.campaignCoins}\nDeck Size: ${_loadedProgress!.campaign!.playerDeckIds.length} cards',
                                              style: GoogleFonts.oldStandardTt(
                                                color: Colors.white70,
                                                fontSize: 11,
                                                height: 1.6,
                                              ),
                                            ),
                                        ],
                                      )
                                    : _loadedProgress!.survival != null
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'SURVIVAL ACTIVE',
                                                style: GoogleFonts.playfairDisplay(
                                                  color: const Color(0xFFC4B89B),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'TURN ${_loadedProgress!.survival!.currentTurn}',
                                                style: GoogleFonts.playfairDisplay(
                                                  color: const Color(0xFFE5D5B0),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Cash: ${_loadedProgress!.survival!.cash} CHF\n'
                                                'Food: ${_loadedProgress!.survival!.food} FOOD\n'
                                                'Wood: ${_loadedProgress!.survival!.wood} WOOD\n'
                                                'Iron: ${_loadedProgress!.survival!.iron} IRON\n'
                                                'Deck Size: ${_loadedProgress!.survival!.playerDeckIds.length} cards',
                                                style: GoogleFonts.oldStandardTt(
                                                  color: Colors.white70,
                                                  fontSize: 11,
                                                  height: 1.6,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'TOURNAMENT ACTIVE',
                                                style: GoogleFonts.playfairDisplay(
                                                  color: Colors.cyanAccent,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                _loadedProgress!.tournament!.isEliminated
                                                    ? 'ELIMINATED'
                                                    : _loadedProgress!.tournament!.currentRound == 5
                                                        ? 'FINALS'
                                                        : 'ROUND OF ${32 ~/ (1 << (_loadedProgress!.tournament!.currentRound - 1))}',
                                                style: GoogleFonts.playfairDisplay(
                                                  color: const Color(0xFFE5D5B0),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                _loadedProgress!.tournament!.isEliminated
                                                    ? 'Tournament Run ended.\n\nYou can clear/delete this slot to restart.'
                                                    : 'Round: ${_loadedProgress!.tournament!.currentRound} / 5\nRemaining: ${_loadedProgress!.tournament!.participants.length} players\nDeck: ${_loadedProgress!.tournament!.playerDeckIds.length} cards',
                                                style: GoogleFonts.oldStandardTt(
                                                  color: Colors.white70,
                                                  fontSize: 11,
                                                  height: 1.6,
                                                ),
                                              ),
                                            ],
                                          ),
                          ),
                      ],
                    ),
                  ),

                  // 2. Right sidebar Hub menu options
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ARENA HUB',
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFE5D5B0),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4.0,
                            ),
                          ),
                          Text(
                            'choose your path to glory',
                            style: GoogleFonts.oldStandardTt(
                              color: const Color(0xFFC4B89B),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 14),

                          _buildHubButton('SURVIVAL MODE', () {
                            if (_loadedProgress?.survival != null) {
                              _enterSurvival(_loadedProgress!.survival!);
                            } else {
                              _showSurvivalSetup();
                            }
                          }),
                          const SizedBox(height: 6),

                          _buildHubButton('SKIRMISH (SIMULATOR)', () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CombatSimulatorScreen(),
                              ),
                            );
                          }),
                          const SizedBox(height: 6),

                          _buildHubButton('CAMPAIGN PROGRESS', () {
                            if (_loadedProgress?.campaign != null) {
                              _enterCampaign(_loadedProgress!.campaign!);
                            } else {
                              _showCampaignSelection();
                            }
                          }),
                          const SizedBox(height: 6),

                          _buildHubButton('TOURNAMENT RUN', () {
                            if (_loadedProgress?.tournament != null) {
                              _enterTournament(_loadedProgress!.tournament!);
                            } else {
                              _showTournamentSetup();
                            }
                          }),
                          const SizedBox(height: 6),

                          _buildHubButton('CLEAR SAVE DATA', _loadedProgress == null ? null : () => _clearSlotConfirm()),
                          const SizedBox(height: 8),
                          const Divider(color: Color(0xFF352B24)),
                          const SizedBox(height: 6),

                          _buildHubButton('RETURN TO MAIN MENU', () {
                            Navigator.pop(context);
                          }, isAccent: true),
                        ],
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

  Widget _buildHubButton(String label, VoidCallback? onPressed, {bool isAccent = false}) {
    return SizedBox(
      width: double.infinity,
      height: 29,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: onPressed == null
                ? Colors.white10
                : (isAccent ? Colors.red.shade800 : const Color(0xFFC4B89B).withValues(alpha: 0.4)),
            width: 1.0,
          ),
          backgroundColor: onPressed == null ? Colors.transparent : Colors.black26,
          shape: const RoundedRectangleBorder(),
        ),
        child: Text(
          label,
          style: GoogleFonts.playfairDisplay(
            color: onPressed == null
                ? Colors.white24
                : (isAccent ? Colors.redAccent.shade100 : const Color(0xFFE5D5B0)),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }

  /// Pushes the Campaign screen
  void _enterCampaign(CampaignProgress campaign, {ArenaProgress? explicitProgress}) {
    final progressObj = explicitProgress ?? _loadedProgress;
    if (progressObj == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CampaignScreen(
          progress: progressObj,
          onUpdate: _loadActiveSlot,
        ),
      ),
    ).then((_) => _loadActiveSlot());
  }

  /// Pushes the Tournament screen
  void _enterTournament(TournamentProgress tournament, {ArenaProgress? explicitProgress}) {
    final progressObj = explicitProgress ?? _loadedProgress;
    if (progressObj == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentScreen(
          progress: progressObj,
          onUpdate: _loadActiveSlot,
        ),
      ),
    ).then((_) => _loadActiveSlot());
  }

  /// Pushes the Survival screen
  void _enterSurvival(SurvivalProgress survival, {ArenaProgress? explicitProgress}) {
    final progressObj = explicitProgress ?? _loadedProgress;
    if (progressObj == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider<SurvivalService>(
          create: (context) => SurvivalService(_activeSlot, survival),
          child: const SurvivalEstateMapScreen(),
        ),
      ),
    ).then((_) => _loadActiveSlot());
  }

  /// Shows setup for a new Survival game
  void _showSurvivalSetup() {
    _showLeaderSelection(
      onLeaderSelected: (leaderId) async {
        _showDifficultySelection(
          onDifficultySelected: (difficulty) async {
            final service = SurvivalService(_activeSlot);
            service.initializeNewSurvivalGame(leaderId, difficulty);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider<SurvivalService>.value(
                  value: service,
                  child: const SurvivalEstateMapScreen(),
                ),
              ),
            ).then((_) => _loadActiveSlot());
          },
        );
      },
    );
  }

  void _showDifficultySelection({
    required Function(SurvivalDifficulty difficulty) onDifficultySelected,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1712),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: const Color(0xFFC4B89B).withValues(alpha: 0.4), width: 1.5),
          ),
          title: Text(
            'SELECT DIFFICULTY',
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFE5D5B0),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDifficultySelectCard(
                  title: 'ELEMENTARY',
                  desc: 'Losing all three watchtowers does not end the game. Multiple save slots are supported, and turn-by-turn auto-save can be disabled.',
                  difficulty: SurvivalDifficulty.elementary,
                  onSelect: onDifficultySelected,
                ),
                const SizedBox(height: 12),
                _buildDifficultySelectCard(
                  title: 'CLASSIC',
                  desc: 'Auto-saves every turn on a single slot. Manual save/load is disabled. Upon defeat, you may reload your most recent save.',
                  difficulty: SurvivalDifficulty.classic,
                  onSelect: onDifficultySelected,
                ),
                const SizedBox(height: 12),
                _buildDifficultySelectCard(
                  title: 'ARCADE',
                  desc: 'Auto-saves every turn on a single slot. The game ends permanently when defeated, recording your turns and medals.',
                  difficulty: SurvivalDifficulty.arcade,
                  onSelect: onDifficultySelected,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDifficultySelectCard({
    required String title,
    required String desc,
    required SurvivalDifficulty difficulty,
    required Function(SurvivalDifficulty) onSelect,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // Close dialog
        onSelect(difficulty);
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.black26,
          border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.25), width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFE5D5B0),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 10.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the modal selector to choose and start a Campaign
  void _showCampaignSelection() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1712),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: const Color(0xFFC4B89B).withValues(alpha: 0.4), width: 1.5),
          ),
          title: Text(
            'SELECT CAMPAIGN',
            style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCampaignSelectCard(
                  title: 'THE ALPINE UPRISING',
                  desc: 'Lead the Swiss peasants against the Archduke\'s plated guard. Starting Deck: Peasant spearmen, hunters, and pikemen.',
                  deck: ['militia', 'militia', 'pikemen', 'marksmen'],
                  id: 'alpine_uprising',
                ),
                const SizedBox(height: 8),
                _buildCampaignSelectCard(
                  title: 'THE CLOCKWORK SIEGE',
                  desc: 'Command Steampunk automatons against a fortress of heavy defenses. Starting Deck: Clockwork bicycle drones and cannoneers.',
                  deck: ['bicycle_gang', 'bicycle_gang', 'musketeers', 'cannoneer'],
                  id: 'clockwork_siege',
                ),
                const SizedBox(height: 8),
                _buildCampaignSelectCard(
                  title: 'THE NECROPOLIS CRYPT',
                  desc: 'Control a swarm of plague-ridden rats and undead bodies inside the catacombs. Starting Deck: Bat units and giant rats.',
                  deck: ['brown_rats', 'brown_rats', 'bats_unit', 'undead_rats'],
                  id: 'necropolis_crypt',
                ),
                const SizedBox(height: 8),
                _buildCampaignSelectCard(
                  title: 'THE DEEP WOODS HUNT',
                  desc: 'Lead feral beasts and tracker packs against forest intruders. Starting Deck: Feral wolves, foxes, and woodland bears.',
                  deck: ['wild_wolves', 'wild_wolves', 'wild_foxes', 'wild_bears'],
                  id: 'deep_woods_hunt',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCampaignSelectCard({
    required String title,
    required String desc,
    required List<String> deck,
    required String id,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // Close dialog
        _showLeaderSelection(
          onLeaderSelected: (leaderId) async {
            final newCampaign = CampaignProgress(
              campaignId: id,
              currentStage: 0,
              playerDeckIds: deck,
              cardUpgrades: {},
              campaignCoins: 100, // Initial coins to spend
              playerLeaderId: leaderId,
            );
            final progress = ArenaProgress(
              slot: _activeSlot,
              saveTime: DateTime.now(),
              campaign: newCampaign,
            );
            await ArenaSaveService.saveProgress(progress);
            await _loadActiveSlot();
            _enterCampaign(progress.campaign!, explicitProgress: progress);
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Colors.black26,
          border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.2), width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFE5D5B0),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: GoogleFonts.oldStandardTt(
                color: Colors.white60,
                fontSize: 10,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: deck.map((cardId) {
                final unit = CombatUnitService.createUnit(cardId);
                return Expanded(
                  child: InkWell(
                    onTap: () => CombatCardDetailModal.show(context, cardId),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          CharacterBlobRenderer(
                            npc: unit,
                            size: 24,
                            isCombat: true,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            unit.name.toUpperCase(),
                            style: GoogleFonts.oswald(
                              fontSize: 8,
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the modal selector to select starting deck and enter a Tournament
  void _showTournamentSetup() {
    showDialog(
      context: context,
      builder: (context) {
        return TournamentDeckBuilderDialog(
          onDeckSelected: (deck) {
            _showLeaderSelection(
              onLeaderSelected: (leaderId) async {
                // Generate 31 Opponent Names
                final List<String> opponentNames = [
                  'Baron von Richter',
                  'Gladiator Titus',
                  'Inquisitor Sarah',
                  'Vagrant Jack',
                  'Lady Isabella',
                  'Commander Krieger',
                  'Outlaw Jesse',
                  'Sniper Vance',
                  'Warlord Marcus',
                  'Engineer Geller',
                  'Mercenary Hawke',
                  'Necromancer Silas',
                  'Dragoons Captain',
                  'Priestess Sophia',
                  'Feral Houndmaster',
                  'Keeper Bran',
                  'Bandit King Silas',
                  'Royal Guard Justin',
                  'Cultist Brother Paul',
                  'Alchemist Victor',
                  'Forest Warden Cedric',
                  'Steam Mechanic Hans',
                  'Saber Master Ray',
                  'Highwayman Rex',
                  'Bounty Hunter Clint',
                  'Plague Carrier Sean',
                  'Dread Golem Master',
                  'Squire Dennis',
                  'Swiss Scout Lukas',
                  'Knight Commander Gerald',
                  'Wild Wolf Alfa',
                ];

                // 32 participants (Player at index 0 + 31 generated)
                final List<String> allParticipants = [
                  'Player',
                  ...opponentNames,
                ];

                // Generate decks for all 32 participants
                final Map<String, List<String>> participantDecks = {
                  'Player': deck,
                };

                final List<List<String>> deckPools = [
                  [
                    'militia',
                    'goons',
                    'pikemen',
                    'marksmen',
                    'valkyrie',
                    'minotaur',
                    'steampunk_mech',
                    'warlock',
                    'witch',
                    'gatling_gun',
                    'phoenix',
                    'necromancer',
                  ],
                  [
                    'bicycle_gang',
                    'motorcycle_gang',
                    'musketeers',
                    'cannoneer',
                    'armored_car',
                    'wooden_tank',
                    'werewolf',
                    'chimera',
                    'flesh_golem',
                    'samurai',
                    'mercenaries',
                    'commandos',
                  ],
                  [
                    'bats',
                    'undead_rats',
                    'brown_rats',
                    'wild_wolves',
                    'wild_foxes',
                    'wild_bears',
                    'bandits',
                    'thugs',
                    'deserters',
                    'halberdiers',
                    'policemen',
                  ],
                  [
                    'cavalry',
                    'stampede',
                    'brewers',
                    'hag',
                    'battering_ram',
                    'poison_gas',
                    'lightning_storm',
                    'airdrop',
                    'divine_shield',
                    'napalm_strike',
                    'sniper',
                    'artillery_barrage',
                  ],
                  [
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
                  ],
                ];

                for (var oppName in opponentNames) {
                  participantDecks[oppName] =
                      deckPools[Random().nextInt(deckPools.length)];
                }

                final newTournament = TournamentProgress(
                  playerDeckIds: deck,
                  currentRound: 1,
                  participants: allParticipants,
                  participantDecks: participantDecks,
                  matches: [],
                  isEliminated: false,
                  playerLeaderId: leaderId,
                );

                // Populate the bracket matches for Round 1 (16 pairings)
                for (int i = 0; i < 16; i++) {
                  newTournament.matches.add(
                    TournamentMatch(
                      round: 1,
                      p1: allParticipants[i * 2],
                      p2: allParticipants[i * 2 + 1],
                    ),
                  );
                }

                final progress = ArenaProgress(
                  slot: _activeSlot,
                  saveTime: DateTime.now(),
                  tournament: newTournament,
                );

                await ArenaSaveService.saveProgress(progress);
                await _loadActiveSlot();
                _enterTournament(
                  progress.tournament!,
                  explicitProgress: progress,
                );
              },
            );
          },
        );
      },
    );
  }

  void _showLeaderSelection({
    required Function(String leaderId) onLeaderSelected,
  }) {
    final List<NPC> leaders = [
      CombatUnitFactory.createAlphonse(),
      CombatUnitFactory.createBossRudolf().copyWith(id: 'boss_rudolf', isPlayer: true),
      CombatUnitFactory.createBossGearbox().copyWith(id: 'boss_gearbox', isPlayer: true),
      CombatUnitFactory.createBossElizabeth().copyWith(id: 'boss_elizabeth', isPlayer: true),
      CombatUnitFactory.createBossThorne().copyWith(id: 'boss_thorne', isPlayer: true),
      CombatUnitFactory.createHiramAbiff().copyWith(id: 'hiram_abiff', isPlayer: true),
      CombatUnitFactory.createChristianRosenkreuz().copyWith(id: 'christian_rosenkreuz', isPlayer: true),
      CombatUnitFactory.createJacquesDeMolay().copyWith(id: 'jacques_de_molay', isPlayer: true),
      CombatUnitFactory.createBankerRothschild().copyWith(id: 'banker_rothschild', isPlayer: true),
      CombatUnitFactory.createAltaVendita().copyWith(id: 'alta_vendita', isPlayer: true),
      CombatUnitFactory.createAleisterCrowley().copyWith(id: 'aleister_crowley', isPlayer: true),
      CombatUnitFactory.createJamesStephens().copyWith(id: 'james_stephens', isPlayer: true),
      CombatUnitFactory.createFerdinandDeBertier().copyWith(id: 'ferdinand_de_bertier', isPlayer: true),
      CombatUnitFactory.createChiefRangerRobin().copyWith(id: 'chief_ranger_robin', isPlayer: true),
      CombatUnitFactory.createAdamWeishaupt().copyWith(id: 'adam_weishaupt', isPlayer: true),
    ];

    int currentIndex = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final currentLeader = leaders[currentIndex];
            final stats = currentLeader.combatStats!;
            
            return AlertDialog(
              backgroundColor: const Color(0xFF1D1712),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: const Color(0xFFC4B89B).withValues(alpha: 0.4), width: 1.5),
              ),
              title: Text(
                'CHOOSE YOUR LEADER',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0), 
                  fontSize: 15, 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              content: SizedBox(
                width: 420,
                height: 310, // Optimized compact height ensures excellent legibility on iPhone screens
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. LOCKED TOP CAROUSEL HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Color(0xFFC4B89B),
                            size: 28,
                          ),
                          onPressed: () {
                            setState(() {
                              currentIndex =
                                  (currentIndex - 1 + leaders.length) %
                                  leaders.length;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Container(
                          width: 68, // Smaller portrait container for iPhone landscape
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            border: Border.all(
                              color: const Color(0xFFC4B89B).withValues(
                                alpha: 0.2,
                              ),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: CharacterBlobRenderer(
                              npc: currentLeader,
                              size: 54, // Proportional animated portrait
                              isIdle: true,
                              showSpeechBubble: false,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_right,
                            color: Color(0xFFC4B89B),
                            size: 28,
                          ),
                          onPressed: () {
                            setState(() {
                              currentIndex =
                                  (currentIndex + 1) % leaders.length;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // LOCKED LEADER NAME & ROLE
                    Text(
                      currentLeader.name.toUpperCase(),
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFFE5D5B0),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      currentLeader.role.toUpperCase(),
                      style: GoogleFonts.oldStandardTt(
                        color: const Color(0xFFD4AF37),
                        fontSize: 9.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Divider(color: Colors.white10, height: 8),

                    // 2. SCROLLABLE STATS & ABILITIES (Between Header and Bottom Button)
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            // Stats Grid
                            Container(
                              padding: const EdgeInsets.all(6.0),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                border: Border.all(
                                  color: const Color(0xFFC4B89B).withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                              ),
                              child: Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(1),
                                  1: FlexColumnWidth(1),
                                },
                                children: [
                                  TableRow(
                                    children: [
                                      _buildStatRow(
                                        'HP / Max HP',
                                        '${stats.health.toInt()} / ${stats.maxHealth.toInt()}',
                                      ),
                                      _buildStatRow(
                                        'Attack Power',
                                        '${stats.attack.toInt()}',
                                      ),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      _buildStatRow(
                                        'Attack Range',
                                        '${stats.distance.toStringAsFixed(1)} ft',
                                      ),
                                      _buildStatRow(
                                        'Speed Factor',
                                        '${stats.speed.toStringAsFixed(1)}x',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Special Abilities Section
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'SPECIAL ABILITIES',
                                style: GoogleFonts.playfairDisplay(
                                  color: const Color(0xFFC4B89B),
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),

                            if (currentLeader.abilities.isEmpty)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'No active special abilities.',
                                  style: GoogleFonts.oldStandardTt(
                                    color: Colors.white38,
                                    fontSize: 9.0,
                                  ),
                                ),
                              )
                            else
                              Column(
                                children:
                                    currentLeader.abilities.map((ability) {
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 6.0,
                                        ),
                                        padding: const EdgeInsets.all(6.0),
                                        decoration: BoxDecoration(
                                          color: Colors.black38,
                                          border: Border.all(
                                            color: Colors.white10,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  ability.name,
                                                  style: GoogleFonts
                                                      .playfairDisplay(
                                                        color: const Color(
                                                          0xFFE5D5B0,
                                                        ),
                                                        fontSize: 10.5,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                Text(
                                                  'Charge: ${ability.chargeTime?.toInt() ?? 0}s',
                                                  style: GoogleFonts
                                                      .oldStandardTt(
                                                        color: const Color(
                                                          0xFFD4AF37,
                                                        ),
                                                        fontSize: 8.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              ability.description,
                                              style: GoogleFonts.oldStandardTt(
                                                color: Colors.white70,
                                                fontSize: 9.0,
                                                height: 1.25,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const Divider(color: Colors.white10, height: 8),

                    // 3. ANCHORED "SELECT THIS LEADER" BUTTON AT THE BOTTOM
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFC4B89B),
                            width: 1.5,
                          ),
                          backgroundColor: const Color(0xFF15100B),
                          shape: const RoundedRectangleBorder(),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          onLeaderSelected(currentLeader.id);
                        },
                        child: Text(
                          'SELECT THIS LEADER',
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
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

  Widget _buildStatRow(String name, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.toUpperCase(),
            style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 7.5, letterSpacing: 0.5),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 10.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Deletes and clears the active slot
  void _clearSlotConfirm() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1712),
          shape: const RoundedRectangleBorder(side: BorderSide(color: Colors.redAccent, width: 1.5)),
          title: Text(
            'CLEAR SLOT SAVE DATA?',
            style: GoogleFonts.playfairDisplay(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'This action is permanent and will completely erase all active campaign or tournament progress on save slot #$_activeSlot. Are you sure?',
            style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 12, height: 1.5),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: GoogleFonts.playfairDisplay(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await ArenaSaveService.deleteSave(_activeSlot);
                await _loadActiveSlot();
              },
              child: Text('ERASE DATA', style: GoogleFonts.playfairDisplay(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }
}

class _BrassGeometricPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC4B89B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    // Top-left design
    path.moveTo(30, 0);
    path.lineTo(0, 30);
    path.moveTo(40, 0);
    path.lineTo(0, 40);

    // Bottom-right design
    path.moveTo(size.width - 30, size.height);
    path.lineTo(size.width, size.height - 30);
    path.moveTo(size.width - 40, size.height);
    path.lineTo(size.width, size.height - 40);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class TournamentDeckBuilderDialog extends StatefulWidget {
  final Function(List<String>) onDeckSelected;

  const TournamentDeckBuilderDialog({super.key, required this.onDeckSelected});

  @override
  State<TournamentDeckBuilderDialog> createState() => _TournamentDeckBuilderDialogState();
}

class _TournamentDeckBuilderDialogState extends State<TournamentDeckBuilderDialog> {
  final List<String> _selectedDeck = [];

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
    'poison_gas',
    'lightning_storm',
    'airdrop',
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

  void _addCard(String type) {
    setState(() {
      if (_selectedDeck.length < 12 && !_selectedDeck.contains(type)) {
        _selectedDeck.add(type);
      }
    });
  }

  void _removeCard(int index) {
    setState(() {
      _selectedDeck.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isCompact = size.width < 600;

    return Dialog(
      backgroundColor: const Color(0xFF1A1612),
      shape: Border.all(color: const Color(0xFFC4B89B), width: 1.5),
      insetPadding: EdgeInsets.all(isCompact ? 8 : 24),
      child: SizedBox(
        width: isCompact ? size.width * 0.95 : 850,
        height: isCompact ? size.height * 0.9 : 650,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black45,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'BUILD CUSTOM TOURNAMENT DECK',
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontSize: isCompact ? 13 : 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFC4B89B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content (Row on desktop/tablet, Column on phone)
            Expanded(
              child: isCompact
                  ? Column(
                      children: [
                        Expanded(flex: 3, child: _buildAvailableCards()),
                        const Divider(color: Colors.white10, height: 1),
                        Expanded(flex: 2, child: _buildSelectedDeck()),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(flex: 5, child: _buildAvailableCards()),
                        const VerticalDivider(color: Colors.white10, width: 1),
                        Expanded(flex: 4, child: _buildSelectedDeck()),
                      ],
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.black54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CARDS SELECTED: ${_selectedDeck.length} / 12',
                    style: GoogleFonts.oswald(
                      color: _selectedDeck.length == 12
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: const RoundedRectangleBorder(),
                    ),
                    onPressed: _selectedDeck.length == 12
                        ? () {
                            Navigator.pop(context);
                            widget.onDeckSelected(_selectedDeck);
                          }
                        : null,
                    child: Text(
                      'CONFIRM DECK & SELECT COMMANDER',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
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

  Widget _buildAvailableCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            'AVAILABLE CARDS (TAP TO ADD)',
            style: GoogleFonts.oswald(
              color: const Color(0xFFC4B89B),
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _availableTypes.length,
            itemBuilder: (context, index) {
              final type = _availableTypes[index];
              final sample = CombatUnitService.createUnit(type);
              final stats = sample.combatStats!;

              return Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  leading: CharacterBlobRenderer(npc: sample, size: 30, isCombat: true),
                  title: Text(
                    type.toUpperCase().replaceAll('_', ' '),
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'HP:${stats.maxHealth.toInt()} | ATK:${stats.attack.toInt()} | Cost:${stats.cost} AP',
                    style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 10),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFFD4AF37)),
                    onPressed: () => _addCard(type),
                  ),
                  onTap: () => CombatCardDetailModal.show(context, type),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDeck() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            'YOUR TOURNAMENT DECK (TAP SLOT TO REMOVE)',
            style: GoogleFonts.oswald(
              color: const Color(0xFFC4B89B),
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final bool hasUnit = index < _selectedDeck.length;
                if (!hasUnit) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Center(
                      child: Icon(Icons.add, color: Colors.white12, size: 24),
                    ),
                  );
                }

                final cardId = _selectedDeck[index];
                final unit = CombatUnitService.createUnit(cardId);

                return InkWell(
                  onTap: () => _removeCard(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CharacterBlobRenderer(npc: unit, size: 26, isCombat: true),
                        const SizedBox(height: 4),
                        Text(
                          unit.name.toUpperCase(),
                          style: GoogleFonts.oswald(color: Colors.white70, fontSize: 8.5),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${unit.combatStats!.cost} AP',
                          style: GoogleFonts.oswald(color: Colors.cyanAccent, fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
