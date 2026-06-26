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
import 'package:collection/collection.dart';
import '../../state/game_state.dart';
import '../../models/active_business.dart';
import '../../models/npc.dart';
import '../../models/patron.dart';
import '../../models/game_item.dart';
import '../../services/audio_service.dart';

class DiningRoomScreen extends StatefulWidget {
  const DiningRoomScreen({super.key});

  @override
  State<DiningRoomScreen> createState() => _DiningRoomScreenState();
}

class _DiningRoomScreenState extends State<DiningRoomScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<GameState>(context, listen: false);
      final initialEnt = state.restaurantEntertainment;
      final mode = initialEnt == 'lutist'
          ? BgmMode.bistroLutist
          : (initialEnt == 'opera' ? BgmMode.bistroOpera : BgmMode.manor);
      AudioService().pushBgmMode(mode);
    });
  }

  @override
  void dispose() {
    AudioService().popBgmMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181410),
      appBar: AppBar(
        title: Text(
          'GLARUS DINING HALL',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            fontSize: 18,
            color: const Color(0xFFE5D5B0),
          ),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE5D5B0)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<GameState>(
        builder: (context, state, child) {
          final bistroActive = state.activeBusinesses.any(
            (b) => b.type.isFoodOrDrinkService && b.status == 'active',
          );

          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/Carl_Spitzweg_-_Der_Maler_im_Garten.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.92),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Row(
              children: [
                // Left panel: Creative tycoon settings
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: const Color(0xFFC4B89B).withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('CREATIVE DESIGN DECREES'),
                          const SizedBox(height: 20),
                          _buildAmbianceSelector(context, state),
                          const Divider(color: Colors.white10, height: 40),
                          _buildEntertainmentSelector(context, state),
                          const Divider(color: Colors.white10, height: 40),
                          _buildBusinessSummary(state),
                        ],
                      ),
                    ),
                  ),
                ),

                // Right panel: Real-time Seating & Performance
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle('REAL-TIME DINING ROOM OBSERVATIONS'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFC4B89B)),
                                color: Colors.black26,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Text(
                                bistroActive ? "RESTAURANT OPEN" : "RESTAURANT CLOSED TODAY",
                                style: GoogleFonts.oswald(
                                  color: bistroActive ? Colors.green : Colors.redAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: _buildTablesObservationGrid(context, state),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        color: const Color(0xFFE5D5B0),
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildAmbianceSelector(BuildContext context, GameState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "AMBIANCE STYLE",
          style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 12, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        Text(
          "The visual aesthetic and physical decor style dictates guest satisfaction and patience decay.",
          style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10),
        ),
        const SizedBox(height: 12),
        ...[
          {
            'id': 'rustic',
            'title': 'COZY RUSTIC',
            'cost': '0 CHF',
            'desc': 'Low cost, modest tips. Appeals to canton locals.',
            'setup': 0,
            'isUnlocked': true,
            'lockReason': '',
          },
          {
            'id': 'gothic',
            'title': 'GOTHIC GRANDEUR',
            'cost': '300 CHF',
            'desc': 'Fascinates guests: -25% wait patience decay, +10 comfort satisfaction.',
            'setup': 300,
            'isUnlocked': state.unlockedDiscoveries.contains('marketing_gothic_aesthetic'),
            'lockReason': "Requires 'Gothic Grandeur Marketing' Discovery",
          },
          {
            'id': 'alchemical',
            'title': 'ALCHEMICAL MODERNISM',
            'cost': '200 CHF',
            'desc': '-15% wait patience decay, grants +2 research points per checkout.',
            'setup': 200,
            'isUnlocked': state.unlockedDiscoveries.contains('marketing_alchemical_modernism'),
            'lockReason': "Requires 'Alchemical Modernism Branding' Discovery",
          },
        ].map((style) {
          final isUnlocked = style['isUnlocked'] as bool;
          final isSelected = state.restaurantAmbiance == style['id'];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2C241E)
                  : (isUnlocked ? Colors.black12 : Colors.black.withValues(alpha: 0.4)),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFC4B89B)
                    : (isUnlocked ? Colors.white10 : Colors.red.withValues(alpha: 0.2)),
              ),
            ),
            child: ListTile(
              dense: true,
              enabled: isUnlocked,
              onTap: () {
                if (!isUnlocked) return;
                final setup = style['setup'] as int;
                if (state.resources['funds']! >= setup) {
                  state.updateResource('funds', -setup);
                  state.updateRestaurantAmbiance(style['id'] as String);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("INSUFFICIENT GLARUS FUNDS FOR RENOVATION.")),
                  );
                }
              },
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isUnlocked
                          ? "${style['title']} (${style['cost']})"
                          : "🔒 ${style['title']} (LOCKED)",
                      style: GoogleFonts.playfairDisplay(
                        color: isSelected
                            ? const Color(0xFFE5D5B0)
                            : (isUnlocked ? Colors.white70 : Colors.white30),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                isUnlocked ? (style['desc'] as String) : (style['lockReason'] as String),
                style: GoogleFonts.oldStandardTt(
                  color: isUnlocked ? Colors.white38 : Colors.redAccent.withValues(alpha: 0.6),
                  fontSize: 9,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEntertainmentSelector(BuildContext context, GameState state) {
    // Check if there is a musical resident
    final hasMusician = state.npcs.any((npc) =>
        npc.isResident &&
        npc.status != NPCStatus.dead &&
        (npc.role.toLowerCase().contains('lutist') ||
            npc.role.toLowerCase().contains('musician') ||
            npc.role.toLowerCase().contains('singer') ||
            npc.traits.any((t) => t.id == 'musical' || t.name.toLowerCase().contains('music'))));

    // Check if there is a noble resident or sponsor
    final hasNoble = state.npcs.any((npc) =>
        npc.isResident &&
        npc.status != NPCStatus.dead &&
        npc.biography?.characterClass == 'Noble');

    final isLutistUnlocked = hasMusician;
    final isOperaUnlocked = hasMusician && (state.bistroProfitModifier >= 1.2 || hasNoble);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "STAGE MUSIC & ENTERTAINMENT",
          style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 12, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        Text(
          "Performances delight music lovers (+tip/comfort) but annoy quiet seekers (high decay).",
          style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10),
        ),
        const SizedBox(height: 12),
        ...[
          {
            'id': 'none',
            'title': 'SILENT HEARTH',
            'cost': '0 CHF/week',
            'desc': 'Cozy, quiet dining hall. Preferred by quiet-seeking patrons.',
            'weekly': 0,
            'isUnlocked': true,
            'lockReason': '',
          },
          {
            'id': 'lutist',
            'title': 'CANTONAL LUTIST',
            'cost': '15 CHF/week',
            'desc': 'Live lute music. Supersedes Manor soundtrack with custom BGM.',
            'weekly': 15,
            'isUnlocked': isLutistUnlocked,
            'lockReason': 'Requires a Resident with Musical Talent at the Manor',
          },
          {
            'id': 'opera',
            'title': 'IMPERIAL OPERA SOLOIST',
            'cost': '50 CHF/week',
            'desc': 'Magnificent operatic performance. Supersedes Manor soundtrack with operatic BGM.',
            'weekly': 50,
            'isUnlocked': isOperaUnlocked,
            'lockReason': 'Requires a Musician AND either >120% Buzz or a Noble Sponsor',
          },
        ].map((ent) {
          final isUnlocked = ent['isUnlocked'] as bool;
          final isSelected = state.restaurantEntertainment == ent['id'];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2C241E)
                  : (isUnlocked ? Colors.black12 : Colors.black.withValues(alpha: 0.4)),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFC4B89B)
                    : (isUnlocked ? Colors.white10 : Colors.red.withValues(alpha: 0.2)),
              ),
            ),
            child: ListTile(
              dense: true,
              enabled: isUnlocked,
              onTap: () {
                if (!isUnlocked) return;
                state.updateRestaurantEntertainment(ent['id'] as String);
                // Dynamically update BGM Mode!
                final targetBgm = ent['id'] == 'lutist'
                    ? BgmMode.bistroLutist
                    : (ent['id'] == 'opera' ? BgmMode.bistroOpera : BgmMode.manor);
                AudioService().popBgmMode();
                AudioService().pushBgmMode(targetBgm);
              },
              title: Text(
                isUnlocked
                    ? "${ent['title']} (${ent['cost']})"
                    : "🔒 ${ent['title']} (LOCKED)",
                style: GoogleFonts.playfairDisplay(
                  color: isSelected
                      ? const Color(0xFFE5D5B0)
                      : (isUnlocked ? Colors.white70 : Colors.white30),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                isUnlocked ? (ent['desc'] as String) : (ent['lockReason'] as String),
                style: GoogleFonts.oldStandardTt(
                  color: isUnlocked ? Colors.white38 : Colors.redAccent.withValues(alpha: 0.6),
                  fontSize: 9,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBusinessSummary(GameState state) {
    double estWeeklyExpenses = (state.restaurantEmployeeCount * state.restaurantEmployeeWages) +
        (state.restaurantSupplierContract == 'premium' ? 250.0 : 100.0);
    if (state.restaurantEntertainment == 'lutist') estWeeklyExpenses += 15;
    if (state.restaurantEntertainment == 'opera') estWeeklyExpenses += 50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "FINANCIAL FORECAST",
          style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 12, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.black38,
          child: Table(
            children: [
              TableRow(
                children: [
                  Text("EST. WEEKLY OVERHEAD:", style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10)),
                  Text("${estWeeklyExpenses.round()} CHF", style: GoogleFonts.oswald(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              TableRow(
                children: [
                  Text("BISTRO POPULARITY:", style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10)),
                  Text("${(state.bistroProfitModifier * 100).round()}% BUZZ", style: GoogleFonts.oswald(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTablesObservationGrid(BuildContext context, GameState state) {
    final maxTables = state.restaurantExtendedHoursActive ? 9 : 3;

    return GridView.builder(
      itemCount: maxTables,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final tableId = 'Table ${index + 1}';
        final seatedPatron = state.activePatrons.firstWhereOrNull((p) => p.isSeated && p.seatedTableId == tableId);

        if (seatedPatron == null) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.table_bar, color: Colors.white24, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    "TABLE ${index + 1}\nVACANT",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.oswald(color: Colors.white24, fontSize: 10, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          );
        }

        // Calculate progress
        double progressVal = 0.0;
        if (seatedPatron.diningFinishMinutes != null) {
          final totalDiningMinutes = 45.0; // average base duration
          final remaining = (seatedPatron.diningFinishMinutes! - state.currentDate.totalMinutes).clamp(0.0, totalDiningMinutes);
          progressVal = (1.0 - (remaining / totalDiningMinutes)).clamp(0.0, 1.0);
        }

        final isCollapsed = seatedPatron.isCollapsed;
        final isSedated = seatedPatron.isDrugged && !isCollapsed;
        final isOperating = seatedPatron.isUnderOperation;

        Color statusColor = Colors.green;
        String statusLabel = "DINING";
        if (isCollapsed) {
          statusColor = Colors.redAccent;
          statusLabel = "COLLAPSED";
        } else if (isSedated) {
          statusColor = Colors.purpleAccent;
          statusLabel = "SEDATED";
        } else if (isOperating) {
          statusColor = Colors.blueAccent;
          statusLabel = "OPERATING";
        }

        final orderedRecipeDisplay = seatedPatron.orderedRecipeId?.replaceAll('_', ' ').toUpperCase() ?? "ARTISANAL FEAST";

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF211C18),
            border: Border.all(
              color: isCollapsed
                  ? Colors.redAccent.withValues(alpha: 0.6)
                  : (isSedated ? Colors.purpleAccent.withValues(alpha: 0.6) : const Color(0xFFC4B89B).withValues(alpha: 0.4)),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 8,
                offset: Offset(0, 4),
              )
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "TABLE ${index + 1}",
                    style: GoogleFonts.oswald(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    color: statusColor.withValues(alpha: 0.2),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.oswald(color: statusColor, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                seatedPatron.name,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                seatedPatron.faction.toUpperCase(),
                style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 8, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                "TRAITS: ${seatedPatron.traits.map((t) => t.displayName).join(', ')}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 8),
              ),
              const SizedBox(height: 4),
              Text(
                "ORDER: $orderedRecipeDisplay",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "SATISFACTION: ${seatedPatron.satisfaction.round()}%",
                    style: GoogleFonts.oswald(color: Colors.white38, fontSize: 8),
                  ),
                  if (seatedPatron.diningFinishMinutes != null)
                    Text(
                      "${max(0, seatedPatron.diningFinishMinutes! - state.currentDate.totalMinutes)}m left",
                      style: GoogleFonts.oswald(color: Colors.white38, fontSize: 8),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.zero,
                child: LinearProgressIndicator(
                  value: progressVal,
                  backgroundColor: Colors.white10,
                  color: statusColor,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 8),
              _buildPatronActions(context, state, seatedPatron),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatronActions(BuildContext context, GameState state, Patron patron) {
    if (patron.isUnderOperation) {
      return const SizedBox(
        height: 24,
        child: Center(
          child: Text(
            "PATIENT IN OPERATING THEATRE",
            style: TextStyle(color: Colors.blueAccent, fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (patron.isCollapsed || patron.isDrugged) {
      // Show dark red "ABDUCT & HARVEST" button!
      return SizedBox(
        width: double.infinity,
        height: 24,
        child: ElevatedButton.icon(
          onPressed: () {
            state.carryPatronToOperatingRoom(patron.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF421010),
                content: Text(
                  "ABDUCTED ${patron.name.toUpperCase()}! Teleported to the Operating Theatre for extraction.",
                  style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0)),
                ),
              ),
            );
          },
          icon: const Icon(Icons.biotech, size: 10, color: Color(0xFFE5D5B0)),
          label: Text(
            "ABDUCT & HARVEST SPECIMEN",
            style: GoogleFonts.playfairDisplay(fontSize: 8, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5A1212),
            foregroundColor: const Color(0xFFE5D5B0),
            padding: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(),
          ),
        ),
      );
    }

    // Otherwise, patron is conscious: show Aperitif and Drug options!
    final kitchen = state.rooms.firstWhereOrNull((r) => r.id == 'kitchen');
    int getSedativeQty(String type) {
      final item = kitchen?.inventory.firstWhereOrNull((i) => i.type == type);
      return item?.quantity ?? 0;
    }

    final soporificQty = getSedativeQty('soporific_draft');
    final belladonnaQty = getSedativeQty('liquid_belladonna');
    final nightshadeQty = getSedativeQty('sleeping_nightshade');
    final totalSedatives = soporificQty + belladonnaQty + nightshadeQty;

    return Row(
      children: [
        // Aperitif button
        Expanded(
          child: SizedBox(
            height: 24,
            child: ElevatedButton(
              onPressed: () {
                if (state.resources['funds']! >= 5) {
                  state.updateResource('funds', -5);
                  state.addResearchPoints(1);
                  // Trigger small satisfaction boost:
                  final idx = state.activePatrons.indexWhere((p) => p.id == patron.id);
                  if (idx != -1) {
                    final p = state.activePatrons[idx];
                    state.activePatrons[idx] = p.copyWith(
                      satisfaction: min(100.0, p.satisfaction + 15.0),
                    );
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("SERVED COMPLIMENTARY APERITIF (+15% SATISFACTION)")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("INSUFFICIENT FUNDS.")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF382E25),
                foregroundColor: const Color(0xFFE5D5B0),
                padding: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(),
              ),
              child: Text(
                "APERITIF (-5 CHF)",
                style: GoogleFonts.playfairDisplay(fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Drug dropdown button
        Expanded(
          child: SizedBox(
            height: 24,
            child: ElevatedButton(
              onPressed: totalSedatives == 0
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("NO SEDATIVES IN KITCHEN INVENTORY. CRAFT SOME!")),
                      );
                    }
                  : () {
                      _showDrugSelectionDialog(context, state, patron, soporificQty, belladonnaQty, nightshadeQty);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C1A30),
                foregroundColor: const Color(0xFFE8D0F0),
                padding: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(),
              ),
              child: Text(
                "DRUG DINER ($totalSedatives)",
                style: GoogleFonts.playfairDisplay(fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDrugSelectionDialog(
    BuildContext context,
    GameState state,
    Patron patron,
    int soporificQty,
    int belladonnaQty,
    int nightshadeQty,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C141C),
          title: Text(
            "SELECT SEDATIVE",
            style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (soporificQty > 0)
                ListTile(
                  title: Text("Soporific Draft (Qty: $soporificQty)", style: const TextStyle(color: Colors.white)),
                  subtitle: const Text("Gentle sedative. Slow onset.", style: TextStyle(color: Colors.white30, fontSize: 10)),
                  onTap: () {
                    state.spikePatronOrder(patron.id, 'soporific_draft');
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Slipped Soporific Draft into diner's soup...")),
                    );
                  },
                ),
              if (belladonnaQty > 0)
                ListTile(
                  title: Text("Liquid Belladonna (Qty: $belladonnaQty)", style: const TextStyle(color: Colors.white)),
                  subtitle: const Text("Medium sedative. Confuses senses.", style: TextStyle(color: Colors.white30, fontSize: 10)),
                  onTap: () {
                    state.spikePatronOrder(patron.id, 'liquid_belladonna');
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Slipped Liquid Belladonna into diner's goblet...")),
                    );
                  },
                ),
              if (nightshadeQty > 0)
                ListTile(
                  title: Text("Sleeping Nightshade (Qty: $nightshadeQty)", style: const TextStyle(color: Colors.white)),
                  subtitle: const Text("Heavy sedative. Fast acting.", style: TextStyle(color: Colors.white30, fontSize: 10)),
                  onTap: () {
                    state.spikePatronOrder(patron.id, 'sleeping_nightshade');
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Slipped Sleeping Nightshade into diner's drink...")),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
