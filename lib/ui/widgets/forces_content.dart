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
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../../state/game_state.dart';
import '../../models/npc.dart';
import '../../models/combat_stats.dart';
import 'character_blob_renderer.dart';

class ForcesContentTab extends StatelessWidget {
  const ForcesContentTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        final player = state.npcs.firstWhereOrNull((n) => n.isPlayer);
        final deckIds = player?.lastEscortIds ?? [];

        // 1. Army Captains: All residents except player
        final captains = state.npcs.where((n) {
          return n.isResident && !n.isPlayer && n.combatStats?.unitType != UnitType.squad;
        }).toList();

        // 2. Unit Components: inchoate bats/rats
        final int batComponents = state.reanimatedBatsCount % 4;
        final int ratComponents = state.reanimatedRatsCount % 4;

        // 3. Active Deck Units (max 12)
        final List<NPC> activeDeck = [];
        for (var id in deckIds) {
          final npc = state.npcs.firstWhereOrNull((n) => n.id == id);
          if (npc != null) {
            activeDeck.add(npc);
          }
        }

        // 4. Combat Units Generally (excluding captains and the main player)
        final generalUnits = state.npcs.where((n) {
          final isCaptainOrPlayer = n.isPlayer || (n.isResident && n.combatStats?.unitType != UnitType.squad);
          final isCombat = n.combatStats?.unitType == UnitType.squad ||
              n.role == 'Minion' ||
              n.status == NPCStatus.zombie ||
              n.id.contains('undead') ||
              n.name.contains('Undead');
          return isCombat && !isCaptainOrPlayer;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Army Captains
              _buildSectionHeader("ARMY CAPTAINS"),
              const SizedBox(height: 12),
              if (captains.isEmpty)
                _buildEmptyText("NO CAPTAINS ACTIVE AT THE MANOR.")
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: captains.length,
                  itemBuilder: (context, index) {
                    final c = captains[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1A15),
                        border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          CharacterBlobRenderer(npc: c, size: 40),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name.toUpperCase(),
                                  style: GoogleFonts.playfairDisplay(
                                    color: const Color(0xFFE5D5B0),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  c.role.toUpperCase(),
                                  style: GoogleFonts.oldStandardTt(
                                    color: const Color(0xFFC4B89B).withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "HEALTH: ${c.combatStats?.health.round() ?? 100}/${c.combatStats?.maxHealth.round() ?? 100}",
                                style: GoogleFonts.oswald(
                                  color: const Color(0xFFE5D5B0),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                "ATTACK: ${c.combatStats?.attack.round() ?? 10}",
                                style: GoogleFonts.oswald(
                                  color: const Color(0xFFC4B89B),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 32),

              // Section 2: Unit Components
              _buildSectionHeader("UNIT COMPONENTS (INCHOATE CREATURES)"),
              const SizedBox(height: 12),
              if (batComponents == 0 && ratComponents == 0)
                _buildEmptyText("NO INCHOATE CREATURE COMPONENTS PRESENT.")
              else
                Row(
                  children: [
                    if (ratComponents > 0)
                      Expanded(
                        child: _buildComponentTile(
                          "Undead Rat",
                          "Rodent components gathered for squad formulation.",
                          ratComponents,
                          "assets/images/undead_rat.png",
                        ),
                      ),
                    if (ratComponents > 0 && batComponents > 0)
                      const SizedBox(width: 16),
                    if (batComponents > 0)
                      Expanded(
                        child: _buildComponentTile(
                          "Undead Bat",
                          "Flying specimens reanimated to form a swarm.",
                          batComponents,
                          "assets/images/undead_bat.png",
                        ),
                      ),
                  ],
                ),

              const SizedBox(height: 32),

              // Section 3: Active Deck (Max 12)
              _buildSectionHeader("ACTIVE DECK (MAX 12 COMBAT CARDS)"),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      if (index < activeDeck.length) {
                        return _buildCard(activeDeck[index], inDeck: true);
                      }
                      return _buildEmptyCardSlot();
                    },
                  );
                },
              ),

              const SizedBox(height: 32),

              // Section 4: Combat Units Generally
              _buildSectionHeader("COMBAT UNITS GENERALLY"),
              const SizedBox(height: 12),
              if (generalUnits.isEmpty)
                _buildEmptyText("NO ADDITIONAL SQUADS OR CONSTRUCTS AVAILABLE.")
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: generalUnits.map((n) {
                    final inDeck = deckIds.contains(n.id);
                    return _buildCard(n, inDeck: inDeck);
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFC4B89B),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        const Divider(color: Colors.white10),
      ],
    );
  }

  Widget _buildEmptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: GoogleFonts.oldStandardTt(
          color: Colors.white12,
          fontSize: 11,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildComponentTile(String title, String desc, int count, String img) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A15),
        border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black38,
              border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              "$count/4",
              style: GoogleFonts.oswald(
                color: const Color(0xFFE5D5B0),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(NPC npc, {bool inDeck = false}) {
    final stats = npc.combatStats;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF211B15),
        border: Border.all(
          color: inDeck ? const Color(0xFFD4AF37) : const Color(0xFFC4B89B).withValues(alpha: 0.4),
          width: inDeck ? 2.0 : 1.2,
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: inDeck
            ? [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                  blurRadius: 6,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: AspectRatio(
        aspectRatio: 0.7,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/card_background.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF1A130E),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFC4B89B).withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Positioned(
              top: 24,
              bottom: 4,
              left: 4,
              right: 4,
              child: Center(
                child: CharacterBlobRenderer(npc: npc, size: 64, isCombat: true),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
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
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF3E2723),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${stats?.cost ?? 1}',
                  style: GoogleFonts.oswald(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCardSlot() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.15),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Center(
        child: Icon(
          Icons.add_circle_outline,
          color: Colors.white10,
          size: 24,
        ),
      ),
    );
  }
}
