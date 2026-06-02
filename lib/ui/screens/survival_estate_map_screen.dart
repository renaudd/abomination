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
import '../../services/survival_service.dart';
import '../../services/combat_unit_service.dart';
import '../../services/combat_unit_factory.dart';
import '../widgets/character_blob_renderer.dart';
import 'combat_screen.dart';

class SurvivalEstateMapScreen extends StatefulWidget {
  const SurvivalEstateMapScreen({super.key});

  @override
  State<SurvivalEstateMapScreen> createState() => _SurvivalEstateMapScreenState();
}

class _SurvivalEstateMapScreenState extends State<SurvivalEstateMapScreen> {
  bool _isDrafting = true;
  final List<String> _selectedCart = [];
  int _selectedSurvivalDeckIndex = 0;

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

    return Scaffold(
      backgroundColor: const Color(0xFF15100B),
      body: Stack(
        children: [
          // 1. MAIN VIEWPORT (Interactive Map & HUD)
          Column(
            children: [
              // Top HUD Header
              _buildHUD(progress, service, state),
              // Main Interactive Map Board
              Expanded(
                child: Row(
                  children: [
                    // Left: Estate Board (Organic 2D map)
                    Expanded(
                      flex: 3,
                      child: _buildEstateBoard(progress, service),
                    ),
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
                ),
              ),
              // Bottom Control & Logs Footer
              _buildFooter(progress, service, state),
            ],
          ),

          // 2. DRAFT EMBARK SHOP OVERLAY
          if (_isDrafting) _buildDraftOverlay(progress, service),
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
              _buildNavButton('DECK', () => _showDeckOverlay(progress, service)),
              _buildNavButton('LEADER', () => _showLeaderOverlay(progress, service)),
              _buildNavButton('TOWERS', () => _showTowersOverlay(progress, service)),
              _buildNavButton('MARKET', () => _showMarketOverlay(progress, service)),
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
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/parchment_tile.png'), // fallback tile or organic color background
          fit: BoxFit.cover,
          opacity: 0.03,
        ),
        color: Color(0xFF18120D),
      ),
      child: Stack(
        children: [
          // Grid guidelines (decorative gothic line borders)
          Positioned.fill(
            child: CustomPaint(
              painter: MapDividerPainter(),
            ),
          ),

          // --- TOWERS: Clustered in the bottom left corner ---
          _buildTowerElement(progress, service, 'tower_1', 40, 240),
          _buildTowerElement(progress, service, 'tower_2', 100, 290),
          _buildTowerElement(progress, service, 'tower_3', 160, 240),

          // --- MANOR HOUSE: Northeast of towers near center ---
          _buildManorHouse(progress, 250, 150),

          // --- STARTING FARM: Right of manor ---
          _buildFacilityPlot(progress, service, 'start_farm', 360, 150),

          // --- AVAILABLE EMPTY PLOTS (4 plots: middle, upper right, lower right) ---
          _buildEmptyPlot(progress, service, 'plot_a', 480, 150), // Middle right
          _buildEmptyPlot(progress, service, 'plot_b', 300, 260), // Middle lower center
          _buildEmptyPlot(progress, service, 'plot_c', 440, 260), // Middle lower right
          _buildEmptyPlot(progress, service, 'plot_d', 580, 260), // Lower right

          // --- LOCKED PURCHASEABLE PLOTS (3 slots: upper left area) ---
          _buildLockedPlot(progress, service, 'plot_e', 80, 30, 10000), // Advanced Plot (10k CHF)
          _buildLockedPlot(progress, service, 'plot_f', 220, 30, 5000),  // Basic Plot (5k CHF)
          _buildLockedPlot(progress, service, 'plot_g', 360, 30, 10000), // Basic Plot (10k CHF)

          // --- TRAINING YARD: Absolute upper right plot ---
          _buildTrainingYard(progress, service, 540, 30),
        ],
      ),
    );
  }

  // MANOR HOUSE COMPONENT
  Widget _buildManorHouse(SurvivalProgress progress, double left, double top) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 80,
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFF211B15),
          border: Border.all(color: const Color(0xFFC4B89B), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.castle, color: Color(0xFFE5D5B0), size: 32),
            const SizedBox(height: 4),
            Text(
              'FRANKENSTEIN\nMANOR',
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFE5D5B0),
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // DEFENSIVE TOWER ELEMENT (Damaged state features pulsing fire & locked labor slots)
  Widget _buildTowerElement(SurvivalProgress progress, SurvivalService service, String towerId, double left, double top) {
    final isDestroyed = (progress.towerDamaged[towerId] ?? 0.0) >= 1.0;
    final lvl = progress.towerLevels['health'] ?? 1;

    return Positioned(
      left: left,
      top: top,
      child: Tooltip(
        message: isDestroyed ? "TOWER DESTROYED! Requires repairs immediately." : "Defensive Tower Lvl $lvl (Active)",
        child: Container(
          width: 76,
          height: 84,
          decoration: BoxDecoration(
            color: isDestroyed ? const Color(0xFF3E1A1A) : const Color(0xFF28231D),
            border: Border.all(
              color: isDestroyed ? Colors.red : const Color(0xFFC4B89B),
              width: isDestroyed ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isDestroyed)
                    const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 14)
                  else
                    const Icon(Icons.security, color: Colors.white54, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    towerId.toUpperCase().replaceAll("_", " "),
                    style: GoogleFonts.oldStandardTt(
                      color: isDestroyed ? Colors.redAccent : Colors.white70,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (isDestroyed) ...[
                // Labor / Material Option Buttons
                Text(
                  'DESTROYED!',
                  style: GoogleFonts.playfairDisplay(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                // Quick buttons
                GestureDetector(
                  onTap: () {
                    _showRepairDialog(context, service, towerId);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC4B89B),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      'REPAIR',
                      style: GoogleFonts.oswald(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ] else ...[
                const Icon(Icons.lens, size: 14, color: Colors.blueGrey),
                const SizedBox(height: 2),
                Text(
                  'HEALTH: 100%',
                  style: GoogleFonts.oswald(color: Colors.green, fontSize: 8),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ACTIVE FACILITY / PLOT GRID
  Widget _buildFacilityPlot(SurvivalProgress progress, SurvivalService service, String id, double left, double top) {
    final b = progress.buildings.firstWhere((x) => x.id == id);
    final caps = b.getWorkerCap();

    return Positioned(
      left: left,
      top: top,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) => b.assignedUnitIds.length < caps,
        onAcceptWithDetails: (details) {
          service.assignWorker(id, details.data);
        },
        builder: (context, candidateData, rejectedData) {
          final isOver = candidateData.isNotEmpty;
          return Container(
            width: 90,
            height: 96,
            decoration: BoxDecoration(
              color: isOver ? const Color(0xFF2A241C) : const Color(0xFF211B15),
              border: Border.all(color: const Color(0xFFC4B89B), width: isOver ? 2 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  b.type.name.replaceAll("lumberMill", "Mill").toUpperCase(),
                  style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 9, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Lvl ${b.level}',
                  style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 8),
                ),
                const SizedBox(height: 4),
                // Worker Slots Grid
                Wrap(
                  spacing: 3,
                  runSpacing: 3,
                  children: List.generate(caps, (idx) {
                    final hasWorker = idx < b.assignedUnitIds.length;
                    return Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: hasWorker ? Colors.brown : Colors.black38,
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: hasWorker
                          ? Draggable<String>(
                              data: b.assignedUnitIds[idx],
                              feedback: Material(
                                color: Colors.transparent,
                                child: Opacity(
                                  opacity: 0.8,
                                  child: CharacterBlobRenderer(
                                    npc: CombatUnitService.createUnit(b.assignedUnitIds[idx]),
                                    size: 16,
                                    isCombat: true,
                                  ),
                                ),
                              ),
                              onDragCompleted: () {
                                setState(() {});
                              },
                              child: CharacterBlobRenderer(
                                npc: CombatUnitService.createUnit(b.assignedUnitIds[idx]),
                                size: 14,
                                isCombat: true,
                              ),
                            )
                          : const Center(child: Icon(Icons.add, size: 8, color: Colors.white12)),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                // Upgrade button
                GestureDetector(
                  onTap: () => _showFacilityUpgradeMenu(context, service, b),
                  child: const Icon(Icons.arrow_circle_up, size: 12, color: Colors.white54),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // TRAINING YARD
  Widget _buildTrainingYard(SurvivalProgress progress, SurvivalService service, double left, double top) {
    return Positioned(
      left: left,
      top: top,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) => true,
        onAcceptWithDetails: (details) {
          service.assignTraining(details.data);
        },
        builder: (context, candidateData, rejectedData) {
          final isOver = candidateData.isNotEmpty;
          return Container(
            width: 90,
            height: 96,
            decoration: BoxDecoration(
              color: isOver ? const Color(0xFF2E201B) : const Color(0xFF261E1A),
              border: Border.all(color: const Color(0xFFC4B89B), width: isOver ? 2 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fitness_center, size: 16, color: Color(0xFFC4B89B)),
                const SizedBox(height: 2),
                Text(
                  'TRAINING YARD',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFC4B89B),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Trainees slots list
                Wrap(
                  spacing: 3,
                  runSpacing: 3,
                  children: List.generate(max(4, progress.trainingUnitIds.length + 1), (idx) {
                    final hasTrainee = idx < progress.trainingUnitIds.length;
                    return Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: hasTrainee ? const Color(0xFF4E342E) : Colors.black26,
                        border: Border.all(color: Colors.white12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: hasTrainee
                          ? Draggable<String>(
                              data: progress.trainingUnitIds[idx],
                              feedback: Material(
                                color: Colors.transparent,
                                child: CharacterBlobRenderer(
                                  npc: CombatUnitService.createUnit(progress.trainingUnitIds[idx]),
                                  size: 16,
                                  isCombat: true,
                                ),
                              ),
                              child: CharacterBlobRenderer(
                                npc: CombatUnitService.createUnit(progress.trainingUnitIds[idx]),
                                size: 14,
                                isCombat: true,
                              ),
                            )
                          : const Icon(Icons.arrow_downward, size: 8, color: Colors.white12),
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

  // UNBUILT AVAILABLE PLOT
  Widget _buildEmptyPlot(SurvivalProgress progress, SurvivalService service, String plotKey, double left, double top) {
    final isBuilt = progress.buildings.any((x) => x.id == plotKey);
    if (isBuilt) {
      return _buildFacilityPlot(progress, service, plotKey, left, top);
    }

    final isAdvanced = _isAdvancedPlot(plotKey);

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          _showBuildMenu(context, service, plotKey);
        },
        child: Container(
          width: 90,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.black26,
            border: Border.all(
              color: isAdvanced
                  ? const Color(0xFFD4AF37).withValues(alpha: 0.4)
                  : const Color(0xFFC4B89B).withValues(alpha: 0.3),
              style: BorderStyle.solid,
              width: isAdvanced ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_box,
                color: isAdvanced ? const Color(0xFFD4AF37).withValues(alpha: 0.7) : Colors.white24,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                isAdvanced ? 'ADVANCED PLOT' : 'BASIC PLOT',
                style: GoogleFonts.playfairDisplay(
                  color: isAdvanced ? const Color(0xFFE5D5B0) : Colors.white38,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // LOCKED PURCHASEABLE PLOTS
  Widget _buildLockedPlot(SurvivalProgress progress, SurvivalService service, String plotKey, double left, double top, int ghcCost) {
    final isPurchased = progress.purchasedPlots.contains(plotKey);
    if (isPurchased) {
      return _buildEmptyPlot(progress, service, plotKey, left, top);
    }

    final isAdvanced = _isAdvancedPlot(plotKey);

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          _showPurchasePlotConfirmation(context, service, plotKey, ghcCost);
        },
        child: Container(
          width: 90,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.black54,
            border: Border.all(
              color: isAdvanced
                  ? const Color(0xFFD4AF37).withValues(alpha: 0.3)
                  : Colors.red.withValues(alpha: 0.2),
              width: isAdvanced ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                color: isAdvanced ? const Color(0xFFD4AF37).withValues(alpha: 0.5) : Colors.white24,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                isAdvanced ? 'ADVANCED PLOT' : 'BASIC PLOT',
                style: GoogleFonts.playfairDisplay(
                  color: isAdvanced ? const Color(0xFFE5D5B0) : Colors.red.shade200,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$ghcCost CHF',
                style: GoogleFonts.oswald(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // DRAWERS & FOOTERS
  Widget _buildSideDeckDrawer(SurvivalProgress progress, SurvivalService service) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          width: double.infinity,
          color: Colors.black38,
          child: Text(
            'YOUR SURVIVAL DECK',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(color: const Color(0xFFC4B89B), fontSize: 10.5, fontWeight: FontWeight.bold),
          ),
        ),
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
              if (progress.trainingUnitIds.contains(type)) isAssigned = true;

              final exp = progress.unitExp[type] ?? 0.0;
              final lvl = SurvivalProgress.getLevelFromXp(exp);

              return Draggable<String>(
                data: type,
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
                        border: Border.all(color: const Color(0xFFC4B89B), width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 4, spreadRadius: 1),
                        ],
                      ),
                      child: Center(
                        child: CharacterBlobRenderer(npc: npc, size: 28, isCombat: true),
                      ),
                    ),
                  ),
                ),
                onDragStarted: () {},
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAssigned ? const Color(0xFF19130F) : const Color(0xFF2A2118),
                    border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      CharacterBlobRenderer(npc: npc, size: 22, isCombat: true),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              npc.name.toUpperCase(),
                              style: GoogleFonts.oldStandardTt(
                                color: isAssigned ? Colors.white38 : const Color(0xFFE5D5B0),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Lvl $lvl | Food cost: ${SurvivalService.getFoodCost(npc)}',
                              style: GoogleFonts.oswald(color: Colors.white38, fontSize: 8),
                            ),
                          ],
                        ),
                      ),
                      if (isAssigned)
                        const Icon(Icons.work, size: 10, color: Colors.amber)
                      else
                        const Icon(Icons.drag_indicator, size: 12, color: Colors.white24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
                // Trigger turn resolution
                service.endTurn();
                
                // Route straight to Combat stage!
                final playerUnits = progress.playerDeckIds
                    .map((t) => CombatUnitService.createUnit(t))
                    .toList();
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
                    ),
                  ),
                );
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

  bool _isAdvancedPlot(String plotKey) {
    return plotKey == 'plot_d' || plotKey == 'plot_e';
  }

  void _showBuildMenu(BuildContext context, SurvivalService service, String plotKey) {
    final isAdvanced = _isAdvancedPlot(plotKey);
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: const Color(0xFF2E1A0A),
          title: Text(
            isAdvanced ? 'CONSTRUCT ADVANCED FACILITY' : 'CONSTRUCT BASIC FACILITY',
            style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0)),
          ),
          children: isAdvanced
              ? [
                  _buildBuildOption(service, plotKey, SurvivalBuildingType.weaponsmith, 100, 30, 300),
                  _buildBuildOption(service, plotKey, SurvivalBuildingType.garage, 120, 40, 400),
                  _buildBuildOption(service, plotKey, SurvivalBuildingType.munitionsFactory, 150, 50, 500),
                ]
              : [
                  _buildBuildOption(service, plotKey, SurvivalBuildingType.farm, 40, 0, 100),
                  _buildBuildOption(service, plotKey, SurvivalBuildingType.lumberMill, 60, 5, 150),
                  _buildBuildOption(service, plotKey, SurvivalBuildingType.mine, 80, 15, 200),
                ],
        );
      },
    );
  }

  Widget _buildBuildOption(SurvivalService service, String plotKey, SurvivalBuildingType type, int wood, int iron, int cash) {
    return SimpleDialogOption(
      onPressed: () {
        if (service.buildFacility(plotKey, type, wood, iron, cash)) {
          Navigator.pop(context);
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

  void _showFacilityUpgradeMenu(BuildContext context, SurvivalService service, SurvivalBuilding building) {
    final costWood = 30 * building.level;
    final costIron = 10 * building.level;
    final costCash = 100 * building.level;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E1A0A),
          title: Text('UPGRADE FACILITY', style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0))),
          content: Text(
            'Do you want to upgrade ${building.type.name.toUpperCase()} to Level ${building.level + 1}?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                if (service.upgradeBuilding(building.id, costWood, costIron, costCash)) {
                  Navigator.pop(context);
                }
              },
              child: Text('UPGRADE ($costWood W | $costIron I | $costCash CHF)'),
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

  void _showDeckOverlay(SurvivalProgress progress, SurvivalService service) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final deck = progress.playerDeckIds;
            
            return AlertDialog(
              backgroundColor: const Color(0xFF1D1712),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: const Color(0xFFC4B89B).withValues(alpha: 0.4), width: 1.5),
              ),
              title: Text(
                'ESTATE DECK OVERVIEW',
                style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: SizedBox(
                width: 460,
                height: 290,
                child: Column(
                  children: [
                    // 12 Slots Grid
                    SizedBox(
                      height: 80,
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final isOccupied = index < deck.length;
                          final isSelected = _selectedSurvivalDeckIndex == index;
                          
                          if (isOccupied) {
                            final cardId = deck[index];
                            final npc = CombatUnitService.createUnit(cardId);
                            
                            return InkWell(
                              onTap: () {
                                setDialogState(() {
                                  _selectedSurvivalDeckIndex = index;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF3E2C1E) : const Color(0xFF211B15),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFFC4B89B).withValues(alpha: 0.25),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CharacterBlobRenderer(npc: npc, size: 18, isCombat: true),
                                    const SizedBox(height: 2),
                                    Text(
                                      npc.name.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.oldStandardTt(color: const Color(0xFFE5D5B0), fontSize: 7.5, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            return InkWell(
                              onTap: () {
                                setDialogState(() {
                                  _selectedSurvivalDeckIndex = index;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF15100B),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFD4AF37) : Colors.white10,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'EMPTY',
                                    style: GoogleFonts.oldStandardTt(color: Colors.white24, fontSize: 7.5),
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: Color(0xFF352B24)),
                    const SizedBox(height: 8),
                    
                    // Lower selected slot details
                    Expanded(
                      child: _selectedSurvivalDeckIndex < deck.length
                          ? _buildSelectedSurvivalCardDetails(progress, service, deck[_selectedSurvivalDeckIndex], setDialogState)
                          : Center(
                              child: Text(
                                'Empty Slot. Go to the Market to hire new units.',
                                style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10.5, fontStyle: FontStyle.italic),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('CLOSE', style: GoogleFonts.playfairDisplay(color: const Color(0xFFC4B89B))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSelectedSurvivalCardDetails(SurvivalProgress progress, SurvivalService service, String cardId, StateSetter setDialogState) {
    final npc = CombatUnitService.createUnit(cardId);
    final stats = npc.combatStats!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              npc.name.toUpperCase(),
              style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              npc.specimenType.toUpperCase(),
              style: GoogleFonts.oldStandardTt(color: const Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              children: [
                _buildStatDetailCell('HP', stats.health.toInt().toString()),
                _buildStatDetailCell('ATK', stats.attack.toInt().toString()),
                _buildStatDetailCell('SPD', '${stats.speed.toStringAsFixed(1)}x'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // Action upgrades
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSurvivalUpgradeBtn(progress, service, cardId, 'hp', 'HP (+15%)', Icons.favorite, setDialogState),
            _buildSurvivalUpgradeBtn(progress, service, cardId, 'atk', 'ATK (+15%)', Icons.flash_on, setDialogState),
            _buildSurvivalUpgradeBtn(progress, service, cardId, 'spd', 'SPD (+5%)', Icons.speed, setDialogState),
          ],
        ),
      ],
    );
  }

  Widget _buildStatDetailCell(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.oldStandardTt(color: Colors.white30, fontSize: 8)),
          const SizedBox(height: 2),
          Text(val, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSurvivalUpgradeBtn(SurvivalProgress progress, SurvivalService service, String cardId, String stat, String label, IconData icon, StateSetter setDialogState) {
    final key = '${cardId}_$stat';
    final currentLvl = progress.cardUpgrades[key] ?? 0;
    final cost = 40 + currentLvl * 20;
    final canAfford = progress.cash >= cost;
    
    return SizedBox(
      height: 26,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: canAfford ? const Color(0xFFC4B89B) : Colors.white10),
          backgroundColor: canAfford ? Colors.black26 : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: const RoundedRectangleBorder(),
        ),
        onPressed: canAfford
            ? () {
                if (service.upgradeCard(cardId, stat, cost)) {
                  setDialogState(() {});
                  setState(() {});
                }
              }
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 9, color: canAfford ? const Color(0xFFE5D5B0) : Colors.white24),
            const SizedBox(width: 4),
            Text(
              '$label (Lvl $currentLvl): $cost CHF',
              style: GoogleFonts.playfairDisplay(
                color: canAfford ? const Color(0xFFE5D5B0) : Colors.white24,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaderOverlay(SurvivalProgress progress, SurvivalService service) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final leader = CombatUnitService.createUnit(progress.selectedLeaderId);
            
            return AlertDialog(
              backgroundColor: const Color(0xFF1D1712),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: const Color(0xFFC4B89B).withValues(alpha: 0.4), width: 1.5),
              ),
              title: Text(
                'COMMANDER PROFILE',
                style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: SizedBox(
                width: 400,
                height: 230,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          leader.name.toUpperCase(),
                          style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          leader.role.toUpperCase(),
                          style: GoogleFonts.oldStandardTt(color: const Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Commander stats and passive siegeworks bonuses. Pay to reinforce attributes dynamically.',
                      style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 9.5),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildLeaderStatUpgradeBtn(progress, service, 'hp', 'HP (+15%)', Icons.favorite, setDialogState),
                        _buildLeaderStatUpgradeBtn(progress, service, 'atk', 'ATK (+15%)', Icons.flash_on, setDialogState),
                        _buildLeaderStatUpgradeBtn(progress, service, 'spd', 'SPD (+5%)', Icons.speed, setDialogState),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('CLOSE', style: GoogleFonts.playfairDisplay(color: const Color(0xFFC4B89B))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLeaderStatUpgradeBtn(SurvivalProgress progress, SurvivalService service, String stat, String label, IconData icon, StateSetter setDialogState) {
    final key = 'leader_$stat';
    final currentLvl = progress.cardUpgrades[key] ?? 0;
    final cost = 50 + currentLvl * 25;
    final canAfford = progress.cash >= cost;
    
    return Column(
      children: [
        Text('Lvl $currentLvl', style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 9)),
        const SizedBox(height: 4),
        SizedBox(
          height: 28,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: canAfford ? const Color(0xFFC4B89B) : Colors.white10),
              backgroundColor: canAfford ? Colors.black26 : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: const RoundedRectangleBorder(),
            ),
            onPressed: canAfford
                ? () {
                    if (service.upgradeLeader(stat, cost)) {
                      setDialogState(() {});
                      setState(() {});
                    }
                  }
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 9, color: canAfford ? const Color(0xFFE5D5B0) : Colors.white24),
                const SizedBox(width: 4),
                Text(
                  '$label: $cost CHF',
                  style: GoogleFonts.playfairDisplay(
                    color: canAfford ? const Color(0xFFE5D5B0) : Colors.white24,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showTowersOverlay(SurvivalProgress progress, SurvivalService service) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hpLvl = progress.cardUpgrades['tower_hp'] ?? 0;
            final atkLvl = progress.cardUpgrades['tower_atk'] ?? 0;
            final rangeUnlocked = hpLvl >= 3 && atkLvl >= 3;
            final speedUnlocked = hpLvl >= 6 && atkLvl >= 6;
            
            return AlertDialog(
              backgroundColor: const Color(0xFF1D1712),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: const Color(0xFFC4B89B).withValues(alpha: 0.4), width: 1.5),
              ),
              title: Text(
                'DEFENSIVE SIEGE TOWERS',
                style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: SizedBox(
                width: 420,
                height: 240,
                child: Column(
                  children: [
                    Text(
                      'Reinforce structural defenses and tactical range. Highly advanced modifications (Range, Speed) require first reinforcing baseline structural qualities.',
                      style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 9.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTowerStatUpgradeBtn(progress, service, 'hp', 'HEALTH (+15%)', Icons.shield, 40, 20, true, "", setDialogState),
                        _buildTowerStatUpgradeBtn(progress, service, 'atk', 'DAMAGE (+15%)', Icons.local_fire_department, 40, 20, true, "", setDialogState),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTowerStatUpgradeBtn(progress, service, 'range', 'RANGE (+2.5 ft)', Icons.gps_fixed, 120, 50, rangeUnlocked, "Req: Health & Atk Lvl 3", setDialogState),
                        _buildTowerStatUpgradeBtn(progress, service, 'speed', 'FIRE RATE (+10%)', Icons.flash_on, 200, 80, speedUnlocked, "Req: Health & Atk Lvl 6", setDialogState),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('CLOSE', style: GoogleFonts.playfairDisplay(color: const Color(0xFFC4B89B))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTowerStatUpgradeBtn(
    SurvivalProgress progress, 
    SurvivalService service, 
    String stat, 
    String label, 
    IconData icon, 
    int baseCost, 
    int costMultiplier, 
    bool isUnlocked, 
    String reqMsg,
    StateSetter setDialogState,
  ) {
    final key = 'tower_$stat';
    final currentLvl = progress.cardUpgrades[key] ?? 0;
    final cost = baseCost + currentLvl * costMultiplier;
    final canAfford = progress.cash >= cost && isUnlocked;
    
    return Column(
      children: [
        Text(
          isUnlocked ? 'Lvl $currentLvl' : 'LOCKED', 
          style: GoogleFonts.oldStandardTt(color: isUnlocked ? Colors.white54 : Colors.red.shade300, fontSize: 8.5),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 180,
          height: 28,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: canAfford ? const Color(0xFFC4B89B) : Colors.white10),
              backgroundColor: canAfford ? Colors.black26 : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              shape: const RoundedRectangleBorder(),
            ),
            onPressed: canAfford
                ? () {
                    if (service.upgradeTower(stat, cost)) {
                      setDialogState(() {});
                      setState(() {});
                    }
                  }
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 9, color: canAfford ? const Color(0xFFE5D5B0) : Colors.white24),
                const SizedBox(width: 4),
                Text(
                  isUnlocked ? '$label: $cost CHF' : reqMsg,
                  style: GoogleFonts.playfairDisplay(
                    color: canAfford ? const Color(0xFFE5D5B0) : Colors.white24,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showMarketOverlay(SurvivalProgress progress, SurvivalService service) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final factor = 1.0 + (progress.currentTurn - 1) * 0.2;
            final foodPackCost = (40 * factor).toInt();
            final woodTimberCost = (60 * factor).toInt();
            final ironCrateCost = (85 * factor).toInt();
            
            final List<Map<String, dynamic>> availableHires = [];
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
            
            return AlertDialog(
              backgroundColor: const Color(0xFF1D1712),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: const Color(0xFFC4B89B).withValues(alpha: 0.4), width: 1.5),
              ),
              title: Text(
                'MANOR BLACK MARKET',
                style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: SizedBox(
                width: 460,
                height: 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purchase critical resources or hire professional combat forces to defend the walls.',
                      style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 9.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    
                    // Resource shop
                    Text('ACQUIRE RAW RESOURCES', style: GoogleFonts.playfairDisplay(color: const Color(0xFFC4B89B), fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMarketResourceBtn(progress, service, 'food', 30, foodPackCost, Icons.restaurant, setDialogState),
                        _buildMarketResourceBtn(progress, service, 'wood', 50, woodTimberCost, Icons.forest, setDialogState),
                        _buildMarketResourceBtn(progress, service, 'iron', 15, ironCrateCost, Icons.construction, setDialogState),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Combat hires
                    Text('HIRE SPECIAL SQUADS', style: GoogleFonts.playfairDisplay(color: const Color(0xFFC4B89B), fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: availableHires.map((hire) {
                        final type = hire['type'] as String;
                        final cost = hire['cost'] as int;
                        final npc = CombatUnitService.createUnit(type);
                        final canAfford = progress.cash >= cost && progress.playerDeckIds.length < 12;
                        
                        return Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              CharacterBlobRenderer(npc: npc, size: 20, isCombat: true),
                              const SizedBox(width: 4),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(npc.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                  Text('$cost CHF', style: const TextStyle(color: Colors.amber, fontSize: 7.5)),
                                ],
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: Icon(Icons.add_circle, color: canAfford ? const Color(0xFFC4B89B) : Colors.white10, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: canAfford ? () {
                                  if (service.buyCombatCard(type, cost)) {
                                    setDialogState(() {});
                                    setState(() {});
                                  }
                                } : null,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('CLOSE', style: GoogleFonts.playfairDisplay(color: const Color(0xFFC4B89B))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMarketResourceBtn(SurvivalProgress progress, SurvivalService service, String res, int amount, int cost, IconData icon, StateSetter setDialogState) {
    final canAfford = progress.cash >= cost;
    return SizedBox(
      height: 28,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: canAfford ? const Color(0xFFC4B89B) : Colors.white10),
          backgroundColor: canAfford ? Colors.black26 : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: const RoundedRectangleBorder(),
        ),
        onPressed: canAfford ? () {
          if (service.buyResource(res, amount, cost)) {
            setDialogState(() {});
            setState(() {});
          }
        } : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 9, color: canAfford ? const Color(0xFFE5D5B0) : Colors.white24),
            const SizedBox(width: 4),
            Text('+$amount ${res.toUpperCase()}: $cost CHF', style: const TextStyle(fontSize: 8)),
          ],
        ),
      ),
    );
  }

  void _showMenuOverlay(SurvivalProgress progress, SurvivalService service, GameState state) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1712),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: const Color(0xFFC4B89B).withValues(alpha: 0.4), width: 1.5),
          ),
          title: Text(
            'COMMAND MENU',
            style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 15, fontWeight: FontWeight.bold),
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
                        'Assign squads to Training Yard to increase their combat tiers. Ensure you have enough food to feed basic/elite units each turn, otherwise they starve and desert!'
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
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
                    const SnackBar(content: Text('Survival progress reloaded successfully!')),
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

  Widget _buildMenuOptionBtn(String label, VoidCallback onTap, {bool isDanger = false}) {
    return SizedBox(
      width: double.infinity,
      height: 28,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: isDanger ? Colors.red.shade800 : const Color(0xFFC4B89B).withValues(alpha: 0.4)),
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

// The existing dialogs
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
