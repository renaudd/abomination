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
                  deck: ['rats_unit', 'rats_unit', 'bats_unit', 'undead_rats'],
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
              style: GoogleFonts.oldStandardTt(color: Colors.white60, fontSize: 10, height: 1.4),
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
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1712),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: const Color(0xFFC4B89B).withValues(alpha: 0.4), width: 1.5),
          ),
          title: Text(
            'SELECT TOURNAMENT DECK',
            style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose a starting deck. All combatants inside the tournament compete with basic card tiers (no upgrades allowed).',
                  style: GoogleFonts.oldStandardTt(color: Colors.white60, fontSize: 11, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildTournamentSelectCard('PEASANT REBELS DECK', ['militia', 'militia', 'pikemen', 'marksmen']),
                const SizedBox(height: 8),
                _buildTournamentSelectCard('CLOCKWORK DRONES DECK', ['bicycle_gang', 'bicycle_gang', 'musketeers', 'cannoneer']),
                const SizedBox(height: 8),
                _buildTournamentSelectCard('NECROMANTIC CRYPT DECK', ['rats_unit', 'rats_unit', 'bats_unit', 'undead_rats']),
                const SizedBox(height: 8),
                _buildTournamentSelectCard('FOG-FOREST BEASTS DECK', ['wild_wolves', 'wild_wolves', 'wild_foxes', 'wild_bears']),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTournamentSelectCard(String label, List<String> deck) {
    return SizedBox(
      width: double.infinity,
      height: 38,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: const Color(0xFFC4B89B).withValues(alpha: 0.3)),
          shape: const RoundedRectangleBorder(),
        ),
        onPressed: () {
          Navigator.pop(context); // Close dialog
          _showLeaderSelection(
            onLeaderSelected: (leaderId) async {
              // Generate 31 Opponent Names
              final List<String> opponentNames = [
                'Baron von Richter', 'Gladiator Titus', 'Inquisitor Sarah', 'Vagrant Jack',
                'Lady Isabella', 'Commander Krieger', 'Outlaw Jesse', 'Sniper Vance',
                'Warlord Marcus', 'Engineer Geller', 'Mercenary Hawke', 'Necromancer Silas',
                'Dragoons Captain', 'Priestess Sophia', 'Feral Houndmaster', 'Keeper Bran',
                'Bandit King Silas', 'Royal Guard Justin', 'Cultist Brother Paul', 'Alchemist Victor',
                'Forest Warden Cedric', 'Steam Mechanic Hans', 'Saber Master Ray', 'Highwayman Rex',
                'Bounty Hunter Clint', 'Plague Carrier Sean', 'Dread Golem Master', 'Squire Dennis',
                'Swiss Scout Lukas', 'Knight Commander Gerald', 'Wild Wolf Alfa'
              ];

              // 32 participants (Player at index 0 + 31 generated)
              final List<String> allParticipants = ['Player', ...opponentNames];

              // Generate decks for all 32 participants
              final Map<String, List<String>> participantDecks = {'Player': deck};
              
              final List<List<String>> deckPools = [
                ['militia', 'militia', 'pikemen', 'marksmen'],
                ['bicycle_gang', 'bicycle_gang', 'musketeers', 'cannoneer'],
                ['rats_unit', 'rats_unit', 'bats_unit', 'undead_rats'],
                ['wild_wolves', 'wild_wolves', 'wild_foxes', 'wild_bears'],
                ['cavalry', 'cavalry', 'pikemen', 'musketeers'],
                ['wooden_tank', 'armored_car', 'cannoneer', 'motorcycle_gang']
              ];

              for (var oppName in opponentNames) {
                participantDecks[oppName] = deckPools[Random().nextInt(deckPools.length)];
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
                newTournament.matches.add(TournamentMatch(
                  round: 1,
                  p1: allParticipants[i * 2],
                  p2: allParticipants[i * 2 + 1],
                ));
              }

              final progress = ArenaProgress(
                slot: _activeSlot,
                saveTime: DateTime.now(),
                tournament: newTournament,
              );
              
              await ArenaSaveService.saveProgress(progress);
              await _loadActiveSlot();
              _enterTournament(progress.tournament!, explicitProgress: progress);
            },
          );
        },
        child: Text(
          label,
          style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Carousel controls with larger portrait
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: Color(0xFFC4B89B), size: 32),
                            onPressed: () {
                              setState(() {
                                currentIndex = (currentIndex - 1 + leaders.length) % leaders.length;
                              });
                            },
                          ),
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.2), width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: CharacterBlobRenderer(
                                npc: currentLeader,
                                size: 80,
                                isIdle: true,
                                showSpeechBubble: false,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: Color(0xFFC4B89B), size: 32),
                            onPressed: () {
                              setState(() {
                                currentIndex = (currentIndex + 1) % leaders.length;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Leader Name
                      Text(
                        currentLeader.name.toUpperCase(),
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      // Leader Role
                      Text(
                        currentLeader.role.toUpperCase(),
                        style: GoogleFonts.oldStandardTt(
                          color: const Color(0xFFD4AF37),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      
                      // Stats Grid
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.15)),
                        ),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1),
                            1: FlexColumnWidth(1),
                          },
                          children: [
                            TableRow(
                              children: [
                                _buildStatRow('HP / Max HP', '${stats.health.toInt()} / ${stats.maxHealth.toInt()}'),
                                _buildStatRow('Attack Power', '${stats.attack.toInt()}'),
                              ],
                            ),
                            TableRow(
                              children: [
                                _buildStatRow('Attack Range', '${stats.distance.toStringAsFixed(1)} ft'),
                                _buildStatRow('Speed Factor', '${stats.speed.toStringAsFixed(1)}x'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Special Abilities Section
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'SPECIAL ABILITIES',
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFFC4B89B),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      if (currentLeader.abilities.isEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'No active special abilities.',
                            style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 9.5),
                          ),
                        )
                      else
                        Column(
                          children: currentLeader.abilities.map((ability) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        ability.name,
                                        style: GoogleFonts.playfairDisplay(
                                          color: const Color(0xFFE5D5B0),
                                          fontSize: 11.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Charge: ${ability.chargeTime?.toInt() ?? 0}s',
                                        style: GoogleFonts.oldStandardTt(
                                          color: const Color(0xFFD4AF37),
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ability.description,
                                    style: GoogleFonts.oldStandardTt(
                                      color: Colors.white70,
                                      fontSize: 9.5,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 20),
                      
                      // Select Button
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFC4B89B), width: 1.5),
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
                              fontSize: 11.5, 
                              fontWeight: FontWeight.bold, 
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
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
