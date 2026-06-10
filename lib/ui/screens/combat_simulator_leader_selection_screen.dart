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
import '../../models/npc.dart';
import '../../services/combat_unit_factory.dart';
import '../../services/combat_unit_service.dart';
import '../widgets/character_blob_renderer.dart';
import 'combat_screen.dart';

class CombatSimulatorLeaderSelectionScreen extends StatefulWidget {
  final List<String> playerDeckTypes;
  final List<String> aiDeckTypes;

  const CombatSimulatorLeaderSelectionScreen({
    super.key,
    required this.playerDeckTypes,
    required this.aiDeckTypes,
  });

  @override
  State<CombatSimulatorLeaderSelectionScreen> createState() =>
      _CombatSimulatorLeaderSelectionScreenState();
}

class _CombatSimulatorLeaderSelectionScreenState
    extends State<CombatSimulatorLeaderSelectionScreen> {
  late final List<NPC> _playerLeaders;
  late final List<NPC> _opponentLeaders;

  int _playerIndex = 0;
  int _opponentIndex = 0;

  @override
  void initState() {
    super.initState();
    _playerLeaders = [
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
    ];
    _opponentLeaders = [
      CombatUnitFactory.createAlphonse().copyWith(id: 'enemy_hero', isPlayer: false),
      CombatUnitFactory.createBossRudolf().copyWith(id: 'boss_rudolf', isPlayer: false),
      CombatUnitFactory.createBossGearbox().copyWith(id: 'boss_gearbox', isPlayer: false),
      CombatUnitFactory.createBossElizabeth().copyWith(id: 'boss_elizabeth', isPlayer: false),
      CombatUnitFactory.createBossThorne().copyWith(id: 'boss_thorne', isPlayer: false),
      CombatUnitFactory.createHiramAbiff().copyWith(id: 'hiram_abiff', isPlayer: false),
      CombatUnitFactory.createChristianRosenkreuz().copyWith(id: 'christian_rosenkreuz', isPlayer: false),
      CombatUnitFactory.createJacquesDeMolay().copyWith(id: 'jacques_de_molay', isPlayer: false),
      CombatUnitFactory.createBankerRothschild().copyWith(id: 'banker_rothschild', isPlayer: false),
      CombatUnitFactory.createAltaVendita().copyWith(id: 'alta_vendita', isPlayer: false),
      CombatUnitFactory.createAleisterCrowley().copyWith(id: 'aleister_crowley', isPlayer: false),
      CombatUnitFactory.createJamesStephens().copyWith(id: 'james_stephens', isPlayer: false),
      CombatUnitFactory.createFerdinandDeBertier().copyWith(id: 'ferdinand_de_bertier', isPlayer: false),
      CombatUnitFactory.createChiefRangerRobin().copyWith(id: 'chief_ranger_robin', isPlayer: false),
    ];
  }

  void _randomizePlayerLeader() {
    setState(() {
      _playerIndex = Random().nextInt(_playerLeaders.length);
    });
  }

  void _randomizeOpponentLeader() {
    setState(() {
      _opponentIndex = Random().nextInt(_opponentLeaders.length);
    });
  }

  void _startSimulation(GameState state) {
    final selectedPlayerLeader = _playerLeaders[_playerIndex];
    final selectedOpponentLeader = _opponentLeaders[_opponentIndex];

    // Convert deck types to NPC instances
    final playerUnits = widget.playerDeckTypes
        .map((t) => CombatUnitService.createUnit(t))
        .toList();
    final aiUnits = widget.aiDeckTypes
        .map((t) => CombatUnitService.createUnit(t))
        .toList();
    
    // Call state initialization
    state.startCombatSimulation(playerUnits, aiUnits);

    // We will manually override the units in state using custom player/opponent hero params on CombatScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CombatScreen(
          customPlayerHero: selectedPlayerLeader,
          customEnemyHero: selectedOpponentLeader,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFF15100B),
      appBar: AppBar(
        title: Text(
          'SELECT LEADERS',
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
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Player's Leader Selection
                Expanded(
                  child: _buildLeaderCarouselSection(
                    title: "YOUR LEADER",
                    leaders: _playerLeaders,
                    currentIndex: _playerIndex,
                    onIndexChanged: (idx) => setState(() => _playerIndex = idx),
                    onRandomPressed: _randomizePlayerLeader,
                    isPlayer: true,
                  ),
                ),
                Container(
                  width: 1,
                  color: Colors.white10,
                ),
                // Opponent's Leader Selection
                Expanded(
                  child: _buildLeaderCarouselSection(
                    title: "OPPONENT LEADER",
                    leaders: _opponentLeaders,
                    currentIndex: _opponentIndex,
                    onIndexChanged: (idx) => setState(() => _opponentIndex = idx),
                    onRandomPressed: _randomizeOpponentLeader,
                    isPlayer: false,
                  ),
                ),
              ],
            ),
          ),
          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              border: const Border(top: BorderSide(color: Colors.white10)),
            ),
            child: ElevatedButton(
              onPressed: () => _startSimulation(state),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC4B89B),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(
                "START SIMULATION BATTLE",
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderCarouselSection({
    required String title,
    required List<NPC> leaders,
    required int currentIndex,
    required ValueChanged<int> onIndexChanged,
    required VoidCallback onRandomPressed,
    required bool isPlayer,
  }) {
    final leader = leaders[currentIndex];
    final stats = leader.combatStats!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Section Title
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFC4B89B),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),

          // Large Frame / Animated Portrait Carousel
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Color(0xFFE5D5B0), size: 32),
                  onPressed: () {
                    final next = (currentIndex - 1 + leaders.length) % leaders.length;
                    onIndexChanged(next);
                  },
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF211B15),
                    border: Border.all(color: const Color(0xFFC4B89B), width: 2),
                  ),
                  child: Center(
                    child: CharacterBlobRenderer(
                      npc: leader,
                      size: 80,
                      showSpeechBubble: false,
                      isCombat: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Color(0xFFE5D5B0), size: 32),
                  onPressed: () {
                    final next = (currentIndex + 1) % leaders.length;
                    onIndexChanged(next);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Leader Name & Role
          Text(
            leader.name.toUpperCase(),
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFE5D5B0),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            leader.role.toUpperCase(),
            style: GoogleFonts.oldStandardTt(
              color: Colors.white38,
              fontSize: 10.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // Combat Stats Table
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black26,
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                _buildStatRow("HP (HEALTH)", "${stats.maxHealth.toInt()}"),
                const Divider(color: Colors.white10, height: 8),
                _buildStatRow("ATTACK DAMAGE", "${stats.attack.toInt()}"),
                const Divider(color: Colors.white10, height: 8),
                _buildStatRow("WEAPON RANGE", "${stats.distance.toStringAsFixed(1)} ft"),
                const Divider(color: Colors.white10, height: 8),
                _buildStatRow("MOVEMENT SPEED", "${stats.movement.toStringAsFixed(1)} m/s"),
                if (stats.defense > 0) ...[
                  const Divider(color: Colors.white10, height: 8),
                  _buildStatRow("BASE DEFENSE", "+${stats.defense.toInt()}"),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Special Abilities List
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'SPECIAL ABILITIES',
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFC4B89B),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (leader.abilities.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'No active special abilities.',
                style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10),
              ),
            )
          else
            Column(
              children: leader.abilities.map((ability) {
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
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Charge: ${ability.chargeTime?.toInt() ?? 0}s',
                            style: GoogleFonts.oldStandardTt(
                              color: const Color(0xFFD4AF37),
                              fontSize: 9.0,
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
                          fontSize: 10.0,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),

          OutlinedButton(
            onPressed: onRandomPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC4B89B),
              side: const BorderSide(color: Color(0xFFC4B89B)),
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              "RANDOM SELECT",
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 10),
        ),
        Text(
          val,
          style: GoogleFonts.oldStandardTt(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
