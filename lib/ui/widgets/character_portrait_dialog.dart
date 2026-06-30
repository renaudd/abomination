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
import '../../models/npc.dart';
import '../../models/npc_intent.dart';
import '../../models/relationship.dart';
import '../../services/social_service.dart';
import '../../state/game_state.dart';
import 'character_blob_renderer.dart';
import '../../services/task_service.dart';
import '../../models/responsibility.dart';

class CharacterPortraitDialog extends StatelessWidget {
  final NPC npc;

  const CharacterPortraitDialog({super.key, required this.npc});

  String _getMoodDescription(NPC liveNpc) {
    if (liveNpc.satisfaction < 30) return "ANGRY";
    if (liveNpc.satisfaction < 60) return "DISCONTENT";
    if (liveNpc.energy < 30) return "EXHAUSTED";
    if (liveNpc.hunger >= 90) return "FAMISHED";
    return "CONTENT";
  }

  Color _getMoodColor(NPC liveNpc) {
    final mood = _getMoodDescription(liveNpc);
    if (mood == "ANGRY" || mood == "FAMISHED") return Colors.redAccent;
    if (mood == "DISCONTENT" || mood == "EXHAUSTED") return Colors.orangeAccent;
    return const Color(0xFFC4B89B);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        final liveNpc = state.npcs.firstWhere((n) => n.id == npc.id, orElse: () => npc);
        final mood = _getMoodDescription(liveNpc);
        final moodColor = _getMoodColor(liveNpc);

        if (state.gilesTutorialStep == GilesTutorialStep.inspectResident) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            state.advanceGilesTutorial(GilesTutorialStep.summary);
          });
        }

        return GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.opaque,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            alignment: const Alignment(
              0,
              -0.6,
            ), // Move the widget up on the screen
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ), // More vertical space
            child: GestureDetector(
              onTap: () {}, // Prevent tap from closing when touching the content area
              child: DefaultTabController(
                length: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Protruding Tabs
                    Container(
                      height: 32, // Shorter tabs
                      decoration: const BoxDecoration(
                        color: Color(
                          0xFF120F0C,
                        ), // Opaque background for unselected tab
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      child: TabBar(
                        isScrollable: true,
                        dividerColor: Colors.transparent,
                        indicator: const BoxDecoration(
                          color: Color(
                            0xFF1E1A15,
                          ), // Selected tab matches main container background
                        ),
                        labelColor: const Color(0xFFE5D5B0),
                        unselectedLabelColor: const Color(
                          0xFFC4B89B,
                        ).withOpacity(0.5), // Opaque unselected text
                        tabAlignment: TabAlignment.center,
                        labelStyle: GoogleFonts.playfairDisplay(
                          fontSize: 11, // Increased from 10
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: [
                          Tab(
                            height: 32,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Color(0xFFC4B89B)),
                                  left: BorderSide(color: Color(0xFFC4B89B)),
                                  right: BorderSide(color: Color(0xFFC4B89B)),
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                              child: const Text("STATUS"),
                            ),
                          ),
                          Tab(
                            height: 32,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Color(0xFFC4B89B)),
                                  left: BorderSide(color: Color(0xFFC4B89B)),
                                  right: BorderSide(color: Color(0xFFC4B89B)),
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                              child: const Text("SOCIAL"),
                            ),
                          ),
                          Tab(
                            height: 32,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Color(0xFFC4B89B)),
                                  left: BorderSide(color: Color(0xFFC4B89B)),
                                  right: BorderSide(color: Color(0xFFC4B89B)),
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                              child: const Text("DOSSIER"),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: 600, // 50% more horizontal space
                        maxHeight:
                            MediaQuery.of(context).size.height *
                            0.85, // Taller height to show more content
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1A15),
                        border: Border.all(color: const Color(0xFFC4B89B), width: 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Compressed Header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, // Reduced padding
                              vertical: 6, // Reduced padding
                            ),
                            child: Row(
                              children: [
                                // Smaller Portrait
                                Container(
                                  width: 60,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFC4B89B).withValues(alpha: 0.5),
                                    ),
                                    color: Colors.black26,
                                  ),
                                  child: Center(
                                    child: CharacterBlobRenderer(
                                      npc: liveNpc,
                                      size: 50,
                                      isIdle: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Name and Info on one line
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          liveNpc.name.toUpperCase(),
                                          style: GoogleFonts.playfairDisplay(
                                            color: const Color(0xFFE5D5B0),
                                            fontSize: 19, // Increased from 18
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 8,
                                        children: [
                                          Text(
                                            liveNpc.status == NPCStatus.zombie
                                                ? "${liveNpc.role} (REANIMATED)".toUpperCase()
                                                : liveNpc.role.toUpperCase(),
                                            style: GoogleFonts.oldStandardTt(
                                              color: liveNpc.status == NPCStatus.zombie
                                                  ? const Color(0xFF7A9E7E)
                                                  : const Color(0xFFC4B89B).withValues(alpha: 0.7),
                                              fontSize: 11, // Increased from 10
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: moodColor.withValues(alpha: 0.3)),
                                              color: moodColor.withValues(alpha: 0.1),
                                            ),
                                            child: Text(
                                              mood,
                                              style: GoogleFonts.outfit(
                                                color: moodColor,
                                                fontSize: 9, // Increased from 8
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Colors.white10),
                          // Content
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ), // Reduced padding
                              child: TabBarView(
                                children: [
                                  _buildStatusTab(context, liveNpc, state),
                                  _buildSocialTab(context, liveNpc, state),
                                  _buildDossierTab(context, liveNpc, state),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12), // Reduced padding
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusTab(BuildContext context, NPC liveNpc, GameState state) {
    return ListView(
      children: [
        _buildStatBar(
          "ENERGY / EXHAUSTION",
          liveNpc.energy / 100,
          Colors.blueAccent,
        ),
        const SizedBox(height: 8),
        _buildStatBar(
          "DIGESTION",
          liveNpc.digestion / 100,
          Colors.deepOrangeAccent,
        ),
        const SizedBox(height: 8),
        _buildStatBar(
          "FULLNESS",
          (100 - liveNpc.hunger) / 100,
          Colors.greenAccent,
        ),
        const SizedBox(height: 8),
        _buildStatBar(
          "SATISFACTION",
          liveNpc.satisfaction / 100,
          Colors.amberAccent,
        ),
        const SizedBox(height: 8),
        _buildStatBar(
          "CLEANLINESS",
          liveNpc.cleanliness / 100,
          Colors.cyanAccent,
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: _getMoodColor(liveNpc).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _getMoodDescription(liveNpc),
              style: GoogleFonts.playfairDisplay(
                color: _getMoodColor(liveNpc),
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildActivitySection(context, liveNpc, state),
        const SizedBox(height: 24),
        _buildUpcomingSection(liveNpc, state),
        const SizedBox(height: 24),
        _buildHousingSection(context, liveNpc, state),
        const SizedBox(height: 24),
        _buildProficienciesSection(liveNpc, state),
      ],
    );
  }

  Widget _buildProficienciesSection(NPC liveNpc, GameState state) {
    final proficiencies = liveNpc.proficiencies.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Sort by XP descending

    if (proficiencies.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader("PROFICIENCIES"),
          const SizedBox(height: 12),
          Text(
            "NO DEVELOPED PROFICIENCIES",
            style: GoogleFonts.oldStandardTt(
              color: const Color(0xFFC4B89B).withValues(alpha: 0.5),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("PROFICIENCIES"),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: proficiencies.map((e) {
            final level = liveNpc.metadata['proficiency_level_${e.key}'] as int? ?? 0;
            String levelText = "NOVICE";
            if (level >= 8) {
              levelText = "EXPERT";
            } else if (level >= 5) {
              levelText = "PROFESSIONAL";
            } else if (level >= 2) {
              levelText = "ADEPT";
            }
            final requiredXp = state.getRequiredXP(level);
            final currentXp = e.value;
            final progress = (currentXp / requiredXp).clamp(0.0, 1.0);

            return Container(
              width: 140, // Fixed width for better grid layout
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFC4B89B).withValues(alpha: 0.05),
                border: Border.all(
                  color: const Color(0xFFC4B89B).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.key.toUpperCase(),
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        level > 0 ? "LVL $level $levelText" : levelText,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFC4B89B).withValues(alpha: 0.7),
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (level < 10)
                        Text(
                          "${currentXp.toInt()} / ${requiredXp.toInt()} XP",
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFC4B89B).withValues(alpha: 0.5),
                            fontSize: 9,
                          ),
                        ),
                    ],
                  ),
                  if (level < 10) ...[
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white12,
                      color: const Color(0xFFC4B89B),
                      minHeight: 2,
                    ),
                  ]
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }



  Widget _buildSocialTab(BuildContext context, NPC liveNpc, GameState state) {
    if (liveNpc.isPlayer) {
      return Center(
        child: Text(
          "YOU ARE MASTER OF THIS DOMAIN.",
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFC4B89B),
            fontSize: 15, // Increased from 14
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      );
    }

    return ListView(
      children: [
        _sectionHeader("RELATIONSHIP WITH YOU"),
        const SizedBox(height: 16),
        _buildInteractionSection(context, liveNpc, state),
        const SizedBox(height: 24),
        _sectionHeader("OTHER BONDS"),
        const SizedBox(height: 12),
        ...state.npcs.where((n) => n.id != liveNpc.id && !n.isPlayer).map((n) {
          final rel = SocialService.getRelationshipBetween(liveNpc, n);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.name.toUpperCase(),
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 12, // Increased from 11
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMiniRelStat(
                      "ADMIRATION",
                      rel.admiration,
                      Colors.pinkAccent,
                    ),
                    const SizedBox(width: 8),
                    _buildMiniRelStat(
                      "RESPECT",
                      rel.respect,
                      Colors.cyanAccent,
                    ),
                    const SizedBox(width: 8),
                    _buildMiniRelStat("FEAR", rel.fear, Colors.deepPurpleAccent),
                    const SizedBox(width: 8),
                    _buildMiniRelStat(
                      "ATTRACTION",
                      rel.attraction,
                      Colors.redAccent,
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDossierTab(BuildContext context, NPC liveNpc, GameState state) {
    final familyMembers = state.npcs.where((n) {
      if (n.id == liveNpc.id) return false;
      final isSpouseOfLiveNpc = n.id == "spouse_${liveNpc.id}";
      final isLiveNpcSpouseOfN = liveNpc.id == "spouse_${n.id}";
      return isSpouseOfLiveNpc || isLiveNpcSpouseOfN;
    }).toList();

    return ListView(
      children: [
        _sectionHeader("BIOGRAPHICAL DOSSIER"),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            border: Border.all(
              color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            liveNpc.bio.isNotEmpty
                ? liveNpc.bio
                : "No detailed biography available.",
            style: GoogleFonts.oldStandardTt(
              color: const Color(0xFFE5D5B0),
              fontSize: 12,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _sectionHeader("RESIDENCE"),
        const SizedBox(height: 8),
        Text(
          liveNpc.isResident
              ? "RESIDES PERMANENTLY AT THE MANOR."
              : "RESIDES IN NYON REGION (VISITOR / OFF-SITE).",
          style: GoogleFonts.oldStandardTt(
            color: const Color(0xFFE5D5B0),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _sectionHeader("ATTRIBUTES"),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildAttributeBar(
                    "STRENGTH",
                    liveNpc.effectiveStats['strength'] ?? 5,
                  ),
                  const SizedBox(height: 12),
                  _buildAttributeBar(
                    "ENDURANCE",
                    liveNpc.effectiveStats['endurance'] ?? 5,
                  ),
                  const SizedBox(height: 12),
                  _buildAttributeBar(
                    "DEXTERITY",
                    liveNpc.effectiveStats['dexterity'] ?? 5,
                  ),
                  const SizedBox(height: 12),
                  _buildAttributeBar(
                    "INTELLECT",
                    liveNpc.effectiveStats['intellect'] ?? 5,
                  ),
                  const SizedBox(height: 12),
                  _buildAttributeBar(
                    "PERCEPTION",
                    liveNpc.effectiveStats['perception'] ?? 5,
                  ),
                  const SizedBox(height: 12),
                  _buildAttributeBar(
                    "TEMPERAMENT",
                    liveNpc.effectiveStats['temperament'] ?? 5,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                children: [
                  _buildAttributeBar(
                    "JUDGMENT",
                    liveNpc.effectiveStats['judgment'] ?? 5,
                  ),
                  const SizedBox(height: 12),
                  _buildAttributeBar(
                    "CONFIDENCE",
                    liveNpc.effectiveStats['confidence'] ?? 5,
                  ),
                  const SizedBox(height: 12),
                  _buildAttributeBar(
                    "BEAUTY",
                    liveNpc.effectiveStats['beauty'] ?? 5,
                  ),
                  const SizedBox(height: 12),
                  _buildAttributeBar(
                    "HYGIENE",
                    liveNpc.effectiveStats['hygiene'] ?? 5,
                  ),
                  const SizedBox(height: 12),
                  _buildAttributeBar(
                    "MORALITY",
                    liveNpc.effectiveStats['morality'] ?? 5,
                  ),
                  const SizedBox(height: 12),
                  _buildAttributeBar(
                    "WILLPOWER",
                    liveNpc.effectiveStats['willpower'] ?? 5,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _sectionHeader("FAMILY IN NYON REGION"),
        const SizedBox(height: 12),
        if (familyMembers.isEmpty)
          Text(
            "NO FAMILY MEMBERS DETECTED IN NYON REGION.",
            style: GoogleFonts.oldStandardTt(
              color: const Color(0xFFC4B89B).withValues(alpha: 0.5),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...familyMembers.map((fm) {
            final relationType = "SPOUSE";
            final residencyStr = fm.isResident ? "RESIDENT" : "OFF-SITE";
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                border: Border.all(
                  color: const Color(0xFFC4B89B).withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        fm.name.toUpperCase(),
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "$relationType ($residencyStr)",
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFC4B89B),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "STR: ${fm.effectiveStats['strength'] ?? 5} | END: ${fm.effectiveStats['endurance'] ?? 5} | DEX: ${fm.effectiveStats['dexterity'] ?? 5} | INT: ${fm.effectiveStats['intellect'] ?? 5} | PER: ${fm.effectiveStats['perception'] ?? 5} | TEM: ${fm.effectiveStats['temperament'] ?? 5} | JUD: ${fm.effectiveStats['judgment'] ?? 5} | CON: ${fm.effectiveStats['confidence'] ?? 5} | BEA: ${fm.effectiveStats['beauty'] ?? 5} | HYG: ${fm.effectiveStats['hygiene'] ?? 5} | MOR: ${fm.effectiveStats['morality'] ?? 5} | WIL: ${fm.effectiveStats['willpower'] ?? 5}",
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFC4B89B),
                      fontSize: 9.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAttributeBar(String label, int value) {
    final progress = value / 10.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: const Color(0xFFC4B89B),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              "$value/10",
              style: GoogleFonts.oldStandardTt(
                color: const Color(0xFFC4B89B),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC4B89B)),
          minHeight: 2,
        ),
      ],
    );
  }

  Widget _buildInteractionSection(
    BuildContext context,
    NPC liveNpc,
    GameState state,
  ) {
    final player = state.npcs.firstWhere((n) => n.isPlayer);
    final rel = SocialService.getRelationshipBetween(liveNpc, player);

    // Only allow interaction if they are in the same room
    final bool canInteract = player.currentRoomId == liveNpc.currentRoomId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "BOND STAGE",
              style: GoogleFonts.outfit(
                color: const Color(0xFFC4B89B),
                fontSize: 11, // Increased from 10
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            Text(
              rel.stage.name.toUpperCase().replaceAll('VOLATILEDEVOTION', 'VOLATILE DEVOTION').replaceAll('COERCEDCOHABITATION', 'COERCED COHABITATION'),
              style: GoogleFonts.outfit(
                color: rel.stage == RelationshipStage.marriage 
                    ? Colors.amber 
                    : const Color(0xFFC4B89B).withValues(alpha: 0.7),
                fontSize: 10, // Increased from 9
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildMiniRelStat("ADMIRATION", rel.admiration, Colors.pinkAccent),
            const SizedBox(width: 8),
            _buildMiniRelStat("RESPECT", rel.respect, Colors.cyanAccent),
            const SizedBox(width: 8),
            _buildMiniRelStat("FEAR", rel.fear, Colors.deepPurpleAccent),
            const SizedBox(width: 8),
            _buildMiniRelStat("ATTRACTION", rel.attraction, Colors.redAccent),
          ],
        ),
        const SizedBox(height: 24),
        if (canInteract)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildInteractButton(state, liveNpc, InteractionType.chat, Icons.chat_bubble_outline),
              _buildInteractButton(state, liveNpc, InteractionType.praise, Icons.thumb_up_outlined),
              _buildInteractButton(state, liveNpc, InteractionType.argument, Icons.gavel_outlined),
              _buildInteractButton(state, liveNpc, InteractionType.threaten, Icons.security),
              _buildInteractButton(state, liveNpc, InteractionType.workTogether, Icons.handshake_outlined),
              if (player.inventory.isNotEmpty)
                _buildGiftButton(context, state, liveNpc, player),
              if (rel.stage == RelationshipStage.devotion || rel.stage == RelationshipStage.volatileDevotion)
                _buildActionButton(
                  "COHABIT",
                  () => state.proposeCohabitationToNpc(liveNpc.id),
                  Icons.home_outlined,
                ),
              if (rel.stage == RelationshipStage.cohabitation || rel.stage == RelationshipStage.coercedCohabitation)
                _buildActionButton(
                  "MARRY",
                  () => state.proposeMarriageToNpc(liveNpc.id),
                  Icons.favorite_outline,
                ),
            ],
          )
        else
          Text(
            "YOU MUST BE IN THE SAME ROOM TO INTERACT.",
            style: GoogleFonts.oldStandardTt(
              color: Colors.white24,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildGiftButton(
    BuildContext context,
    GameState state,
    NPC liveNpc,
    NPC player,
  ) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1A1D),
              title: Text(
                "SELECT A GIFT FOR ${liveNpc.name.toUpperCase()}",
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFC4B89B),
                  fontSize: 13,
                ),
              ),
              content: SizedBox(
                width: 300,
                height: 200,
                child: ListView(
                  children: player.inventory.map((item) {
                    return ListTile(
                      title: Text(
                        item.name.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Text(
                        "${item.quantity}",
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFC4B89B),
                          fontSize: 11,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        state.giveGiftToNpc(liveNpc.id, item);
                      },
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 18),
            const SizedBox(height: 4),
            Text(
              "GIVE GIFT",
              style: GoogleFonts.outfit(fontSize: 9, color: Colors.pinkAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    VoidCallback onTap,
    IconData icon,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.amber, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 9, color: Colors.amber),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractButton(
    GameState state,
    NPC liveNpc,
    InteractionType type,
    IconData icon,
  ) {
    return InkWell(
      onTap: () => state.interactWithNpc(liveNpc.id, type),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFC4B89B), size: 18),
            const SizedBox(height: 4),
            Text(
              type.name.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 9,
                color: const Color(0xFFC4B89B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection(BuildContext context, NPC liveNpc, GameState state) {
    final activeTask = liveNpc.activeTaskId != null 
        ? state.activeTasks.firstWhereOrNull((t) => t.id == liveNpc.activeTaskId) 
        : null;
    final targetRoom = state.rooms.firstWhereOrNull((r) => r.id == liveNpc.targetRoomId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("CURRENT ACTIVITY"),
        const SizedBox(height: 12),
        if (activeTask != null)
          _buildTaskTile(state, activeTask, liveNpc)
        else
          Text(
            "NO ACTIVE ASSIGNMENT",
            style: GoogleFonts.oldStandardTt(
              color: const Color(0xFFC4B89B).withValues(alpha: 0.5),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        if (targetRoom != null && liveNpc.currentRoomId != liveNpc.targetRoomId)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.map_outlined,
                  size: 14,
                  color: Color(0xFFC4B89B),
                ),
                const SizedBox(width: 8),
                Text(
                  "EN ROUTE TO ${targetRoom.name.toUpperCase()}",
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFC4B89B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  bool _isLeisure(NPCIntent i) =>
      i.id.startsWith('sched_leisure') ||
      i.id.startsWith('artwork') ||
      (TaskCategoryMapping.getCategory(i.action) == null && i.priority == IntentPriority.low);

  Widget _buildUpcomingSection(NPC liveNpc, GameState state) {
    final activeTask = liveNpc.activeTaskId != null 
        ? state.activeTasks.firstWhereOrNull((t) => t.id == liveNpc.activeTaskId) 
        : null;
    final activeIntentId = activeTask?.intentId;
    
    // Upcoming assignments (excluding active task)
    final allUpcoming = liveNpc.intentQueue.where((i) => i.id != liveNpc.activeTaskId && i.id != activeIntentId).toList();
    
    final emergencies = allUpcoming.where((i) => i.priority == IntentPriority.emergency).toList();
    final high = allUpcoming.where((i) => i.priority == IntentPriority.high || i.priority == IntentPriority.urgent).toList();
    final normal = allUpcoming.where((i) => i.priority == IntentPriority.normal).toList();
    final low = allUpcoming.where((i) => i.priority == IntentPriority.low && !_isLeisure(i)).toList();
    final leisure = allUpcoming.where((i) => i.priority == IntentPriority.low && _isLeisure(i)).toList();

    List<Map<String, dynamic>> elements = [];

    void addHeader(String title) {
      elements.add({'type': 'header', 'title': title, 'id': 'hdr_$title'});
    }

    if (emergencies.isNotEmpty) {
      addHeader("EMERGENCIES");
      elements.addAll(emergencies.map((e) => {'type': 'intent', 'intent': e, 'id': e.id}));
    }
    
    if (high.isNotEmpty) {
      addHeader("HIGH PRIORITY");
      elements.addAll(high.map((e) => {'type': 'intent', 'intent': e, 'id': e.id}));
    }
    
    addHeader("NORMAL PRIORITY");
    if (normal.isEmpty) {
      elements.add({'type': 'empty', 'title': 'WAITING FOR ORDERS', 'id': 'emp_normal'});
    } else {
      elements.addAll(normal.map((e) => {'type': 'intent', 'intent': e, 'id': e.id}));
    }

    addHeader("LOW PRIORITY WORK");
    elements.addAll(low.map((e) => {'type': 'intent', 'intent': e, 'id': e.id}));

    addHeader("LEISURE TASKS");
    elements.addAll(leisure.map((e) => {'type': 'intent', 'intent': e, 'id': e.id}));

    void handleReorder(int oldIndex, int newIndex) {
      if (oldIndex < newIndex) newIndex -= 1;
      final item = elements[oldIndex];
      // Only intents can be reordered
      if (item['type'] != 'intent') return;
      
      final draggedIntent = item['intent'] as NPCIntent;
      
      // Find destination bucket
      IntentPriority destPriority = draggedIntent.priority;
      bool isDestLeisure = false;
      
      for (int i = newIndex; i >= 0; i--) {
        if (elements[i]['type'] == 'header') {
          final t = elements[i]['title'];
          if (t == "EMERGENCIES") {
            destPriority = IntentPriority.emergency;
          } else if (t == "HIGH PRIORITY") {
            destPriority = IntentPriority.high;
          } else if (t == "NORMAL PRIORITY") {
            destPriority = IntentPriority.normal;
          } else if (t == "LOW PRIORITY WORK") {
            destPriority = IntentPriority.low;
          } else if (t == "LEISURE TASKS") {
            destPriority = IntentPriority.low;
            isDestLeisure = true;
          }
          break;
        }
      }

      // Constraints
      if (draggedIntent.priority == IntentPriority.emergency && destPriority != IntentPriority.emergency) return;
      if (_isLeisure(draggedIntent) && !isDestLeisure) return; // Leisure can't go to non-leisure
      if (isDestLeisure && !_isLeisure(draggedIntent)) return; // Work can't go to leisure
      
      // We are allowed to move it! Construct the new sequence.
      elements.removeAt(oldIndex);
      elements.insert(newIndex, item);
      
      // Rebuild the final intentQueue
      List<NPCIntent> newQueue = [];
      
      for (var el in elements) {
        if (el['type'] == 'intent') {
          NPCIntent i = el['intent'] as NPCIntent;
          if (i.id == draggedIntent.id) {
             // Upgraded/Downgraded Priority!
             i = i.copyWith(priority: destPriority);
          }
          newQueue.add(i);
        }
      }
      
      // Read the missing intents (active tasks) from liveNpc.intentQueue and put them at the TOP of the new queue
      final missingIntents = liveNpc.intentQueue.where((i) => i.id == liveNpc.activeTaskId || i.id == activeIntentId).toList();
      newQueue.insertAll(0, missingIntents);
      
      state.updateIntentQueue(liveNpc.id, newQueue);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("TASK QUEUE"),
        const SizedBox(height: 12),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: elements.length,
          itemBuilder: (context, index) {
            final el = elements[index];
            if (el['type'] == 'header') {
              return Container(
                key: ValueKey(el['id']),
                width: double.infinity,
                padding: const EdgeInsets.only(top: 8, bottom: 4, left: 2),
                child: Text(
                  el['title'],
                  style: GoogleFonts.oswald(
                    color: const Color(0xFFC4B89B).withValues(alpha: 0.8),
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            } else if (el['type'] == 'empty') {
              return Container(
                key: ValueKey(el['id']),
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 16,
                ),
                child: Text(
                  el['title'],
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFC4B89B).withValues(alpha: 0.5),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            } else {
              final intent = el['intent'] as NPCIntent;
              final bool canDrag =
                  intent.priority != IntentPriority.emergency &&
                  !_isLeisure(intent);
              return _buildIntentTile(
                intent,
                state,
                liveNpc.id,
                index,
                isManual: canDrag,
              );
            }
          },
          onReorder: handleReorder,
        ),
      ],
    );
  }

  Widget _buildIntentTile(NPCIntent intent, GameState state, String npcId, int index, {required bool isManual}) {
    final room = state.rooms.firstWhereOrNull((r) => r.id == intent.targetRoomId);
    final roomName = room?.name ?? "Mansion";
    
    String actionName = intent.action.displayName;
    if (intent.action == TaskType.cook && intent.recipeId != null) {
      actionName = "COOK ${intent.recipeId!.replaceAll('_', ' ')}";
    } else if (intent.action == TaskType.butcherAnimals && intent.targetName != null) {
      actionName = "BUTCHER ${intent.targetName}";
    } else if (intent.action == TaskType.eat && intent.targetName != null) {
      actionName = "EAT ${intent.targetName}";
    }

    String displayDesc = (intent.action == TaskType.restoreRoom)
      ? "RESTORE $roomName".toUpperCase()
      : (intent.action == TaskType.eat || intent.action == TaskType.cook)
          ? actionName.toUpperCase()
          : "$actionName IN $roomName".toUpperCase();

    return Padding(
      key: ValueKey(intent.id),
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isManual ? const Color(0xFFC4B89B).withValues(alpha: 0.05) : Colors.black26,
          border: Border.all(
            color: isManual 
              ? const Color(0xFFC4B89B).withValues(alpha: 0.3)
              : const Color(0xFFC4B89B).withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Text(
              "${index + 1}.",
              style: GoogleFonts.oswald(
                color: const Color(0xFFC4B89B).withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              intent.priority.index >= IntentPriority.urgent.index
                  ? Icons.priority_high
                  : Icons.calendar_today,
              size: 14,
              color: intent.priority.index >= IntentPriority.urgent.index
                  ? Colors.redAccent
                  : const Color(0xFFC4B89B),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayDesc,
                style: GoogleFonts.oldStandardTt(
                  fontSize: 12,
                  color: const Color(0xFFE5D5B0),
                ),
              ),
            ),
            if (isManual)
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.drag_handle, color: Colors.white10, size: 18),
                ),
              ),
            IconButton(
              onPressed: () => state.cancelEnqueuedIntent(npcId, intent.id),
              icon: const Icon(Icons.close, color: Colors.redAccent, size: 14),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'CANCEL ASSIGNMENT',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTile(GameState state, GameTask task, NPC liveNpc) {
    final room = state.rooms.firstWhereOrNull((r) => r.id == task.targetId);
    final roomName = room?.name ?? "Mansion";
    
    String actionName = task.type.displayName;
    if (task.type == TaskType.eat && task.targetName != null) {
      actionName = "EAT ${task.targetName}";
    } else if (task.type == TaskType.cook && task.recipeId != null) {
      actionName = "COOK ${task.recipeId!.replaceAll('_', ' ')}";
    }
    
    final description = (task.type == TaskType.restoreRoom)
      ? "RESTORE $roomName".toUpperCase()
      : (task.type == TaskType.eat || task.type == TaskType.cook)
          ? actionName.toUpperCase()
          : "$actionName IN $roomName".toUpperCase();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFC4B89B).withValues(alpha: 0.05),
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC4B89B)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: GoogleFonts.oldStandardTt(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: const Color(0xFFE5D5B0),
                  ),
                ),
                Text(
                  task.type == TaskType.rest ? "UNTIL WAKEFUL" : "${task.minutesRemaining} MINUTES REMAINING",
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: const Color(0xFFC4B89B).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHousingSection(BuildContext context, NPC liveNpc, GameState state) {
    final assignedRoom = state.rooms.where((r) => r.id == liveNpc.assignedRoomId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("DOMICILE"),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.king_bed_outlined,
              size: 16,
              color: Color(0xFFC4B89B),
            ),
            const SizedBox(width: 12),
            Text(
              assignedRoom?.name.toUpperCase() ?? "NO ASSIGNED QUARTERS",
              style: GoogleFonts.oldStandardTt(
                color: const Color(0xFFE5D5B0),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        color: const Color(0xFFC4B89B),
        fontSize: 9, // Increased from 8
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildStatBar(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: const Color(0xFFC4B89B),
                fontSize: 9, // Increased from 8
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              "${(progress * 100).toInt()}%",
              style: GoogleFonts.oldStandardTt(
                color: const Color(0xFFC4B89B),
                fontSize: 11, // Increased from 10
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 2,
        ),
      ],
    );
  }

  Widget _buildMiniRelStat(String label, double value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: color.withValues(alpha: 0.6),
              fontSize: 8, // Increased from 7
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          LinearProgressIndicator(
            value: value / 5.0,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 2,
          ),
        ],
      ),
    );
  }
}
