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
import '../../models/active_business.dart';
import '../../models/patron.dart';
import '../../services/recipe_catalogue.dart';
import '../../services/kitchen_service.dart';

class BusinessRecordsContent extends StatefulWidget {
  final ActiveBusiness business;

  const BusinessRecordsContent({super.key, required this.business});

  @override
  State<BusinessRecordsContent> createState() => _BusinessRecordsContentState();
}

class _BusinessRecordsContentState extends State<BusinessRecordsContent> {
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);
    final isFoodService = widget.business.type.isFoodOrDrinkService;

    return Container(
      color: const Color(0xFF241F1A),
      child: DefaultTabController(
        length: isFoodService ? 8 : 5,
        child: Column(
          children: [
            // Business Header Panel
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.black38,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.business.name.toUpperCase(),
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "TYPE: ${widget.business.type.displayName.toUpperCase()} | STATUS: OPERATIONAL",
                        style: GoogleFonts.oldStandardTt(
                          color: const Color(0xFFC4B89B),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF1E1A15),
                          title: Text(
                            "LIQUIDATE BUSINESS?",
                            style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0)),
                          ),
                          content: Text(
                            "This will shut down ${widget.business.name} permanently, fire employees, and revert dedicated rooms to unused spaces. Are you absolutely sure?",
                            style: GoogleFonts.oldStandardTt(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("CANCEL", style: GoogleFonts.oldStandardTt(color: Colors.white24)),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                state.shutDownBusiness(widget.business.id);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                              child: Text("SHUT DOWN", style: GoogleFonts.playfairDisplay(color: Colors.black)),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                      foregroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(),
                    ),
                    icon: const Icon(Icons.output, size: 14),
                    label: Text(
                      "SHUT DOWN VENTURE",
                      style: GoogleFonts.playfairDisplay(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Inner Sub Tab Bar
            TabBar(
              indicatorColor: const Color(0xFFC4B89B),
              labelColor: const Color(0xFFE5D5B0),
              unselectedLabelColor: Colors.white24,
              labelStyle: GoogleFonts.playfairDisplay(fontSize: 11, fontWeight: FontWeight.bold),
              tabs: [
                const Tab(text: "HOLDINGS"),
                const Tab(text: "AGREEMENTS"),
                const Tab(text: "EMPLOYEES"),
                if (isFoodService) const Tab(text: "ACTIVE PATRONS"),
                if (isFoodService) const Tab(text: "MENU & PRICING"),
                if (isFoodService) const Tab(text: "BAR & CELLAR"),
                const Tab(text: "CHRONICLE LOG"),
                const Tab(text: "LEDGER"),
              ],
            ),

            // Tab View Content
            Expanded(
              child: TabBarView(
                children: [
                  _buildHoldingsTab(context, state),
                  _buildAgreementsTab(context),
                  _buildEmployeesTab(context, state),
                  if (isFoodService) _buildActivePatronsTab(context, state),
                  if (isFoodService) _buildBistroManagementTab(context, state),
                  if (isFoodService) _buildBarCellarTab(context, state),
                  _buildLogsTab(context),
                  _buildLedgerTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePatronsTab(BuildContext context, GameState state) {
    final patrons = state.activePatrons;
    if (patrons.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.group_off, color: Color(0xFFC4B89B), size: 48),
              const SizedBox(height: 16),
              Text(
                "NO ACTIVE CLIENTELE IN THE FOYER OR DINING ROOM.",
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Establishment is either closed or awaiting arrivals. Check operating hours and marketing covenants.",
                textAlign: TextAlign.center,
                style: GoogleFonts.oldStandardTt(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final waiting = patrons.where((p) => !p.isSeated && !p.isUnderOperation).toList();
    final seated = patrons.where((p) => p.isSeated && !p.isUnderOperation).toList();
    final underOperation = patrons.where((p) => p.isUnderOperation).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "FOYER LOBBY (WAITING SERVICE)",
                style: GoogleFonts.oswald(
                  color: const Color(0xFFC4B89B),
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                color: Colors.black38,
                child: Text(
                  "${waiting.length} QUEUED",
                  style: GoogleFonts.oswald(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (waiting.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black12,
                border: Border.all(color: Colors.white10),
              ),
              child: Center(
                child: Text(
                  "NO CUSTOMERS CURRENTLY WAITING IN THE FOYER.",
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white24,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            )
          else
            ...waiting.map((patron) => _buildPatronCard(context, state, patron)),

          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "DINING HALL (ACTIVE DINERS)",
                style: GoogleFonts.oswald(
                  color: const Color(0xFFC4B89B),
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                color: Colors.black38,
                child: Text(
                  "${seated.length} / 4 TABLES OCCUPIED",
                  style: GoogleFonts.oswald(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (seated.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black12,
                border: Border.all(color: Colors.white10),
              ),
              child: Center(
                child: Text(
                  "NO CUSTOMERS SEATED AT THE DINING TABLES.",
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white24,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            )
          else
            ...seated.map((patron) => _buildPatronCard(context, state, patron)),

          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "BASEMENT OPERATING THEATER (SURGERY)",
                style: GoogleFonts.oswald(
                  color: const Color(0xFFC4B89B),
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                color: Colors.black38,
                child: Text(
                  "${underOperation.length} SUBJECTS",
                  style: GoogleFonts.oswald(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (underOperation.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black12,
                border: Border.all(color: Colors.white10),
              ),
              child: Center(
                child: Text(
                  "NO SUBJECTS CURRENTLY ON THE OPERATING TABLE.",
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white24,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            )
          else
            ...underOperation.map((patron) => _buildPatronCard(context, state, patron)),
        ],
      ),
    );
  }

  Widget _buildPatronCard(BuildContext context, GameState state, Patron patron) {
    final isSeated = patron.isSeated;
    final isUnderOperation = patron.isUnderOperation;
    final isCollapsed = patron.isCollapsed;
    final isDrugged = patron.isDrugged;
    final hint = _getBehaviorHint(patron.faction);

    Color cardBgColor = Colors.black12;
    Color borderColor = Colors.white10;
    if (isUnderOperation) {
      cardBgColor = const Color(0xFF1D291F);
      borderColor = const Color(0xFF4C6B4F).withValues(alpha: 0.5);
    } else if (isCollapsed) {
      cardBgColor = const Color(0xFF2C1F1F);
      borderColor = const Color(0xFF8C2D19).withValues(alpha: 0.5);
    } else if (isSeated) {
      cardBgColor = const Color(0xFF2C241E);
      borderColor = const Color(0xFFC4B89B).withValues(alpha: 0.3);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      patron.name.toUpperCase(),
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFFE5D5B0),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isUnderOperation)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: const Color(0xFF4C6B4F).withValues(alpha: 0.1),
                        child: Text(
                          "OPERATING TABLE",
                          style: GoogleFonts.oswald(color: const Color(0xFFF5D5B0), fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      )
                    else if (isCollapsed)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: const Color(0xFF8C2D19).withValues(alpha: 0.1),
                        child: Text(
                          "UNCONSCIOUS",
                          style: GoogleFonts.oswald(color: const Color(0xFFFFA8A8), fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      )
                    else if (isSeated)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        color: const Color(0xFFC4B89B).withValues(alpha: 0.1),
                        child: Text(
                          patron.seatedTableId ?? "SEATED",
                          style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "OBSERVED ACTION: $hint",
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFC4B89B).withValues(alpha: 0.7),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: patron.traits.map((trait) {
                    final isPositive = _isPositiveTrait(trait);
                    final color = isPositive ? const Color(0xFF4C6B4F) : const Color(0xFF8C2D19);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        border: Border.all(color: color, width: 1),
                      ),
                      child: Text(
                        trait.displayName.toUpperCase(),
                        style: GoogleFonts.oswald(
                          color: isPositive ? const Color(0xFFA8DDAA) : const Color(0xFFFFA8A8),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                if (isUnderOperation)
                  Text(
                    "SUBJECT STATE: Lying completely limp. Respiration is steady but shallow. Perfect for extraction.",
                    style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 10),
                  )
                else if (isCollapsed)
                  Text(
                    "SUBJECT STATE: Collapsed at ${patron.seatedTableId ?? 'their table'}. Completely unresponsive to shaking.",
                    style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 10),
                  )
                else if (isDrugged)
                  Text(
                    "STATUS: DRUGGED & DROWSY (Laced meal consumed; collapse imminent...)",
                    style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 9, fontWeight: FontWeight.bold),
                  )
                else if (!isSeated)
                  Row(
                    children: [
                      Text("PATIENCE: ", style: GoogleFonts.oswald(color: Colors.white38, fontSize: 9, letterSpacing: 1.0)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(1),
                          child: LinearProgressIndicator(
                            value: patron.patience,
                            backgroundColor: Colors.white10,
                            color: _getProgressColor(patron.patience),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text("${(patron.patience * 100).round()}%", style: GoogleFonts.oswald(color: _getProgressColor(patron.patience), fontSize: 9)),
                    ],
                  )
                else
                  Row(
                    children: [
                      Text("SATISFACTION: ", style: GoogleFonts.oswald(color: Colors.white38, fontSize: 9, letterSpacing: 1.0)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(1),
                          child: LinearProgressIndicator(
                            value: patron.satisfaction / 100.0,
                            backgroundColor: Colors.white10,
                            color: _getProgressColor(patron.satisfaction / 100.0),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text("${patron.satisfaction.round()}%", style: GoogleFonts.oswald(color: _getProgressColor(patron.satisfaction / 100.0), fontSize: 9)),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              if (isUnderOperation)
                ElevatedButton(
                  onPressed: () {
                    _showSurgicalHarvestDialogue(context, state, patron);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C6B4F),
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    "EXTRACT ORGANS",
                    style: GoogleFonts.playfairDisplay(fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                )
              else if (isCollapsed)
                ElevatedButton(
                  onPressed: () {
                    state.carryPatronToOperatingRoom(patron.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC4B89B),
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    "CARRY TO BASEMENT",
                    style: GoogleFonts.playfairDisplay(fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                )
              else if (isDrugged)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  color: Colors.white10,
                  child: Text(
                    "DROWSY...",
                    style: GoogleFonts.playfairDisplay(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                )
              else if (!isSeated)
                ElevatedButton(
                  onPressed: () {
                    state.refusePatron(patron.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A1E15),
                    foregroundColor: const Color(0xFFFFA8A8),
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    "REFUSE ENTRY",
                    style: GoogleFonts.playfairDisplay(fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                )
              else ...[
                ElevatedButton(
                  onPressed: () {
                    _showSpikeOrderDialogue(context, state, patron);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC4B89B),
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    "SPIKE MEAL",
                    style: GoogleFonts.playfairDisplay(fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1E1A15),
                        title: Text(
                          "EXPEL ${patron.name.toUpperCase()}?",
                          style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0)),
                        ),
                        content: Text(
                          "This will forcibly eject this customer from Glarus Manor. Doing so will create a dramatic scene, reducing the satisfaction of all other seated diners by 15.0%. Proceed?",
                          style: GoogleFonts.oldStandardTt(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("CANCEL", style: GoogleFonts.oldStandardTt(color: Colors.white24)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              state.expelPatron(patron.id);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8C2D19)),
                            child: Text("EXPEL FORCIBLY", style: GoogleFonts.playfairDisplay(color: Colors.black)),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8C2D19),
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    "EXPEL GUEST",
                    style: GoogleFonts.playfairDisplay(fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  void _showSpikeOrderDialogue(BuildContext context, GameState state, Patron patron) {
    final sedatives = state.inventory.where((item) =>
      item.type == 'soporific_draft' ||
      item.type == 'liquid_belladonna' ||
      item.type == 'sleeping_nightshade'
    ).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1A15),
        title: Text(
          "SPIKE ${patron.name.toUpperCase()}'S ORDER",
          style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select an alchemical sedative to slip into their dinner. Once consumed, the subject will grow drowsy and collapse shortly.",
              style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 16),
            if (sedatives.isEmpty) ...[
              Text(
                "NO ALCHEMICAL SEDATIVES FOUND IN MANOR ROOM INVENTORIES.",
                style: GoogleFonts.oswald(color: const Color(0xFF8C2D19), fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Brew Soporific Draft, Liquid Belladonna, or Sleeping Nightshade in the laboratory or greenhouse first.",
                style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10),
              ),
            ] else
              ...sedatives.map((item) {
                final disp = _getSedativeNameLabel(item.type);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.black26,
                  child: ListTile(
                    title: Text(disp.toUpperCase(), style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 12, fontWeight: FontWeight.bold)),
                    subtitle: Text("Available: ${item.quantity} units", style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 9)),
                    trailing: ElevatedButton(
                      onPressed: () {
                        state.spikePatronOrder(patron.id, item.type);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF2C241E),
                            content: Text("Laced meal served to ${patron.name}.", style: GoogleFonts.oldStandardTt(color: const Color(0xFFE5D5B0))),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC4B89B)),
                      child: Text("INFUSE", style: GoogleFonts.playfairDisplay(color: Colors.black, fontSize: 10)),
                    ),
                  ),
                );
              }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CLOSE", style: GoogleFonts.oldStandardTt(color: Colors.white24)),
          ),
        ],
      ),
    );
  }

  String _getSedativeNameLabel(String type) {
    if (type == 'soporific_draft') return "Soporific Draft";
    if (type == 'liquid_belladonna') return "Liquid Belladonna";
    if (type == 'sleeping_nightshade') return "Sleeping Nightshade";
    return "Alchemical Sedative";
  }

  void _showSurgicalHarvestDialogue(BuildContext context, GameState state, Patron patron) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1A15),
        title: Text(
          "SURGICAL HARVEST: ${patron.name.toUpperCase()}",
          style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select the biological specimen or organ to extract from the unconscious subject. The operation is fatal and the remains will be cleanly dissolved in alchemical acid.",
              style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 16),
            
            _buildHarvestOption(
              context,
              title: "HARVEST BLACK-MARKET ORGANS (KIDNEY/LIVER)",
              description: "Extract high-demand organs to sell to Zürich contacts (+250 CHF).",
              onTap: () {
                state.performSurgicalHarvest(patron.id, harvestedOrgan: 'kidney');
                Navigator.pop(context);
              },
            ),
            _buildHarvestOption(
              context,
              title: "HARVEST GOLEMIC HEART (SPECIMEN)",
              description: "Extract a beating heart required for advanced Golem assembly.",
              onTap: () {
                state.performSurgicalHarvest(patron.id, harvestedOrgan: 'heart');
                Navigator.pop(context);
              },
            ),
            _buildHarvestOption(
              context,
              title: "HARVEST GOLEMIC BRAIN (SPECIMEN)",
              description: "Extract the neural center required for advanced Golem assembly.",
              onTap: () {
                state.performSurgicalHarvest(patron.id, harvestedOrgan: 'brain');
                Navigator.pop(context);
              },
            ),
            _buildHarvestOption(
              context,
              title: "HARVEST RAW MUSCLE & FLESH",
              description: "Extract muscles and limbs to stitch together patchwork servants (+3 Flesh).",
              onTap: () {
                state.performSurgicalHarvest(patron.id, harvestedOrgan: 'flesh');
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ABANDON OPERATION", style: GoogleFonts.oldStandardTt(color: Colors.white24)),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestOption(BuildContext context, {required String title, required String description, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isPositiveTrait(PatronTrait trait) {
    return trait == PatronTrait.easyRegular ||
        trait == PatronTrait.bigTipper ||
        trait == PatronTrait.promoter ||
        trait == PatronTrait.generousPatron ||
        trait == PatronTrait.glutton;
  }

  Color _getProgressColor(double val) {
    if (val > 0.6) return const Color(0xFF4C6B4F);
    if (val > 0.3) return const Color(0xFFC4B89B);
    return const Color(0xFF8C2D19);
  }

  String _getBehaviorHint(String faction) {
    if (faction == 'Gnomes of Zurich') return "Inquires about coinage purity and vault keys.";
    if (faction == 'Carbonari') return "Smells faintly of coal dust and speaks of liberation.";
    if (faction == 'Rosicrucians') return "Wears a rose emblem and asks about botany labs.";
    if (faction == 'Chevaliers de la foi') return "Exhibits highly formal aristocratic etiquette.";
    if (faction == 'Freemasons') return "Uses precise geometric terminology and handshakes.";
    if (faction == 'Ancient Order of Foresters') return "Wears rustic forest green wool.";
    if (faction == 'Knights Templar') return "Highly militant stance; talks about holy relics.";
    if (faction == 'Golden Dawn') return "Speaks of cosmic hierarchies and astral planes.";
    if (faction == 'Fenian Brotherhood') return "Whispers of night raids and rebellions.";
    if (faction == 'Glarus') return "Mentions local municipal codes and Canton taxes.";
    if (faction == 'Army') return "Loud, demanding military soldier wearing canton insignia.";
    return "Quiet, observant traveler.";
  }

  Widget _buildBistroManagementTab(BuildContext context, GameState state) {
    final List<Recipe> recipes = RecipeCatalogue.allRecipes
        .where((r) => state.knownRecipes.contains(r.id))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          // Pricing scale
          Text(
            "BISTRO GENERAL PRICING INDEX",
            style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 12, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: state.bistroPriceLevel,
                  min: 0.5,
                  max: 2.5,
                  divisions: 20,
                  activeColor: const Color(0xFFC4B89B),
                  inactiveColor: Colors.white10,
                  label: "${(state.bistroPriceLevel * 100).round()}%",
                  onChanged: (val) {
                    state.updateBistroPriceLevel(val);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Text(
                "${(state.bistroPriceLevel * 100).round()}% OF BASE",
                style: GoogleFonts.oswald(color: const Color(0xFFE5D5B0), fontSize: 12),
              ),
            ],
          ),
          Text(
            "Adjust Glarus pricing index. Extreme price indices may alter customer interest.",
            style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10),
          ),
          const Divider(color: Colors.white10, height: 32),

          // Supplier contracts
          Text(
            "INGREDIENT SUPPLIER COVENANTS (HORIZONTAL CAROUSEL)",
            style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 12, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['standard', 'premium', 'bulk', 'package'].map((type) {
                  final isSelected = state.restaurantSupplierContract == type;
                  String title = "STANDARD COVENANT";
                  String sub = "Imperial Supply";
                  IconData sealIcon = Icons.verified;
                  Color sealColor = Colors.amber;

                  if (type == 'premium') {
                    title = "PREMIUM DELICACIES";
                    sub = "Alchemical Imports";
                    sealIcon = Icons.stars;
                    sealColor = Colors.redAccent;
                  } else if (type == 'bulk') {
                    title = "GLARUS BULK COVENANT";
                    sub = "Massive Wholesale";
                    sealIcon = Icons.gavel;
                    sealColor = Colors.blueAccent;
                  } else if (type == 'package') {
                    title = "COLLECTIVE LOT";
                    sub = "Package Deal";
                    sealIcon = Icons.backpack;
                    sealColor = Colors.purpleAccent;
                  }

                  return GestureDetector(
                    onTap: () {
                      _showEvaluateContractDialog(context, state, type);
                    },
                    child: Container(
                      width: 190,
                      margin: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EFEB), // Off-white/paper aesthetic
                        border: Border.all(
                          color: isSelected ? const Color(0xFF8C2D19) : Colors.black38,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(sealIcon, color: sealColor, size: 24),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  color: const Color(0xFF8C2D19),
                                  child: Text("ACTIVE", style: GoogleFonts.oswald(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            title.toUpperCase(),
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFF2A2520),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            sub.toUpperCase(),
                            style: GoogleFonts.oldStandardTt(
                              color: Colors.black54,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "CLICK TO EVALUATE COVENANT",
                            style: GoogleFonts.oswald(color: const Color(0xFF8C2D19), fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(color: Colors.white10, height: 32),

          // Roster & Operating Hours
          Text(
            "STAFFING AND OPERATING CHARTER",
            style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 12, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              _showOperatingHoursCalendarDialog(context, state);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black12,
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Color(0xFFE5D5B0), size: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("CLICK TO EDIT 7-DAY WEEK CALENDAR CHARTER", style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          "Modify unique daily hour ranges by dragging bounds. Mark specific days closed.",
                          style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Color(0xFFC4B89B), size: 14),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white10, height: 32),

          // Menu Setup
          Text(
            "GLARUS MANOR MENU BUILDER",
            style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 12, letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          ...recipes.map((recipe) {
            final isOnMenu = state.restaurantMenuIds.contains(recipe.id);
            final prepareable = state.getPrepareableCopies(recipe);

            Color statusColor = Colors.redAccent;
            if (prepareable >= 10) {
              statusColor = Colors.green;
            } else if (prepareable > 0) {
              statusColor = Colors.amber;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOnMenu ? const Color(0xFF2C241E) : Colors.black12,
                border: Border.all(color: isOnMenu ? const Color(0xFFC4B89B) : Colors.white10),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: isOnMenu,
                    activeColor: const Color(0xFFC4B89B),
                    onChanged: (val) {
                      final List<String> newIds = List.from(state.restaurantMenuIds);
                      final Map<String, double> newPrices = Map.from(state.restaurantMenuPrices);
                      if (val == true) {
                        newIds.add(recipe.id);
                        newPrices[recipe.id] = recipe.sophistication * 30.0; // default price
                      } else {
                        newIds.remove(recipe.id);
                      }
                      state.updateRestaurantMenu(newIds, newPrices);
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              recipe.name.toUpperCase(),
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFE5D5B0),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(
                                "$prepareable PREPAREABLE",
                                style: GoogleFonts.oswald(color: statusColor, fontSize: 8),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "SOPHISTICATION: ${recipe.sophistication.toStringAsFixed(1)}",
                          style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  if (isOnMenu)
                    Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        color: Colors.black26,
                      ),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.oldStandardTt(color: const Color(0xFFE5D5B0), fontSize: 12),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          suffixText: " CHF",
                          suffixStyle: TextStyle(color: Colors.white24),
                        ),
                        controller: TextEditingController(
                          text: (state.restaurantMenuPrices[recipe.id] ?? (recipe.sophistication * 30.0)).round().toString(),
                        ),
                        onSubmitted: (val) {
                          final double? p = double.tryParse(val);
                          if (p != null) {
                            final Map<String, double> newPrices = Map.from(state.restaurantMenuPrices);
                            newPrices[recipe.id] = p;
                            state.updateRestaurantMenu(state.restaurantMenuIds, newPrices);
                          }
                        },
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHoldingsTab(BuildContext context, GameState state) {
    final rooms = state.rooms.where((r) => widget.business.holdings.contains(r.id)).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          Text(
            "DEDICATED SPACES",
            style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 12, letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          if (rooms.isEmpty)
            Text(
              "NO PHYSICAL HOLDINGS CURRENTLY REGISTERED TO THE VENTURE.",
              style: GoogleFonts.oldStandardTt(color: Colors.white24, fontSize: 11),
            )
          else
            ...rooms.map((r) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name.toUpperCase(),
                          style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontWeight: FontWeight.bold),
                        ),
                        Text(
                          r.description,
                          style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                    Text(
                      r.isRestored ? "OPERATIONAL" : "REQUIRES CLEANING",
                      style: GoogleFonts.oswald(
                        color: r.isRestored ? Colors.green : Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAgreementsTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          Text(
            "CONTRACTS AND COVENANTS",
            style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 12, letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          if (widget.business.agreements.isEmpty)
            Text(
              "NO FORMAL ACCORDS SIGNED UNDER THIS BUSINESS.",
              style: GoogleFonts.oldStandardTt(color: Colors.white24, fontSize: 11),
            )
          else
            ...widget.business.agreements.map((agree) {
              return ListTile(
                leading: const Icon(Icons.gavel, color: Color(0xFFC4B89B), size: 16),
                title: Text(
                  agree.toUpperCase(),
                  style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Binding charter. Reverts on venture liquidation.",
                  style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 9),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmployeesTab(BuildContext context, GameState state) {
    final employees = state.npcs.where((n) => widget.business.employeeIds.contains(n.id)).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "REGISTERED EMPLOYEE ROSTER",
            style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 12, letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: employees.isEmpty
                ? Text(
                    "NO FORMAL STAFF RECRUITED TO THIS SPECIFIC WING.",
                    style: GoogleFonts.oldStandardTt(color: Colors.white24, fontSize: 11),
                  )
                : ListView.builder(
                    itemCount: employees.length,
                    itemBuilder: (context, index) {
                      final emp = employees[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  emp.name.toUpperCase(),
                                  style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "WAGES: ${emp.monthlySalary} CHF / MONTH | DISPOSITION: ACTIVE",
                                  style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () {
                                state.fireBusinessProposer(widget.business.id);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                                side: const BorderSide(color: Colors.redAccent),
                                shape: const RoundedRectangleBorder(),
                              ),
                              child: Text(
                                "TERMINATE CONTRACT",
                                style: GoogleFonts.playfairDisplay(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          Text(
            "HISTORICAL LEDGER LOG",
            style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 12, letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          if (widget.business.logs.isEmpty)
            Text(
              "Chronicle logs are vacant.",
              style: GoogleFonts.oldStandardTt(color: Colors.white24, fontSize: 11),
            )
          else
            ...widget.business.logs.map((log) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  log.toUpperCase(),
                  style: GoogleFonts.oldStandardTt(color: const Color(0xFFC4B89B), fontSize: 11),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLedgerTab(BuildContext context) {
    double netProfit = 0;
    for (var entry in widget.business.ledger) {
      netProfit += entry.amount;
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ACCOUNTING BALANCE SHEET",
                style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 12, letterSpacing: 1.5),
              ),
              Text(
                "NET ACCUMULATED VALUE: ${netProfit.round()} CHF",
                style: GoogleFonts.oswald(
                  color: netProfit >= 0 ? Colors.green : Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: widget.business.ledger.isEmpty
                ? Center(
                    child: Text(
                      "Ledger is currently vacant of transactions.",
                      style: GoogleFonts.oldStandardTt(color: Colors.white24),
                    ),
                  )
                : SingleChildScrollView(
                    child: Table(
                      border: TableBorder.symmetric(inside: const BorderSide(color: Colors.white10)),
                      columnWidths: const {
                        0: FlexColumnWidth(1.5),
                        1: FlexColumnWidth(3.0),
                        2: FlexColumnWidth(1.5),
                      },
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(color: Colors.black12),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("DATE", style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 10)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("TRANSACTION DETAILS", style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 10)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("AMOUNT", style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 10)),
                            ),
                          ],
                        ),
                        ...widget.business.ledger.map((entry) {
                          final isIncome = entry.amount >= 0;
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(entry.date, style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 10)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(entry.description.toUpperCase(), style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 10)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "${isIncome ? '+' : ''}${entry.amount.round()} CHF",
                                  style: GoogleFonts.oswald(
                                    color: isIncome ? Colors.green : Colors.redAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarCellarTab(BuildContext context, GameState state) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          Text(
            "BAR AND LIQUID WING MANAGEMENT",
            style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 12, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            "Stock the bar from your estate's brewery and cellar assets. Set appropriate prices and target optimal profit margins.",
            style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(height: 20),
          ...[
            {'id': 'small_beer', 'title': 'SMALL ESTATE BEER', 'base': 10.0, 'desc': 'Simple standard weak beer produced in the manor brewery.', 'res': 'ale'},
            {'id': 'golden_ale', 'title': 'GOLDEN MOUNTAIN ALE', 'base': 25.0, 'desc': 'Premium rich cantonal ale brewed in the manor brewery.', 'res': 'ale'},
            {'id': 'clear_spirits', 'title': 'CLEAR WOOD SPIRITS', 'base': 20.0, 'desc': 'Distilled clear spirits produced in Glarus stills.', 'res': 'spirits'},
            {'id': 'barrel_aged_brandy', 'title': 'BARREL-AGED BRANDY', 'base': 50.0, 'desc': 'Exceptional double-aged brandy aged with timber.', 'res': 'spirits'},
          ].map((drink) {
            final id = drink['id'] as String;
            final isStocked = state.barStockedDrinks.contains(id);
            final currentPrice = state.barDrinkPrices[id] ?? drink['base'] as double;
            final availableStock = state.resources[drink['res']] ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isStocked ? const Color(0xFF2C241E) : Colors.black12,
                border: Border.all(color: isStocked ? const Color(0xFFC4B89B) : Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: isStocked,
                        activeColor: const Color(0xFFC4B89B),
                        onChanged: (val) {
                          final List<String> newStock = List.from(state.barStockedDrinks);
                          if (val == true) {
                            newStock.add(id);
                          } else {
                            newStock.remove(id);
                          }
                          state.updateBarStockedDrinks(newStock, state.barDrinkPrices);
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              drink['title'] as String,
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFE5D5B0),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              drink['desc'] as String,
                              style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: Colors.black26,
                        child: Text(
                          "${availableStock.round()} AVAILABLE",
                          style: GoogleFonts.oswald(color: availableStock > 5 ? Colors.green : Colors.amber, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (isStocked) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: currentPrice,
                            min: (drink['base'] as double) * 0.5,
                            max: (drink['base'] as double) * 2.5,
                            divisions: 20,
                            activeColor: const Color(0xFFC4B89B),
                            inactiveColor: Colors.white10,
                            label: "${currentPrice.round()} CHF",
                            onChanged: (val) {
                              final Map<String, double> newPrices = Map.from(state.barDrinkPrices);
                              newPrices[id] = val;
                              state.updateBarStockedDrinks(state.barStockedDrinks, newPrices);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "${currentPrice.round()} CHF",
                          style: GoogleFonts.oswald(color: const Color(0xFFE5D5B0), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showEvaluateContractDialog(BuildContext context, GameState state, String type) {
    String title = "";
    String sub = "";
    String lotDetails = "";
    String delivery = "";
    String loan = "None Offered";
    String commitments = "Open-ended (Cancel anytime)";
    bool isLot = false;
    List<Widget> extraActions = [];

    if (type == 'standard') {
      title = "STANDARD IMPERIAL COVENANT";
      sub = "Imperial Agricultural Supply";
      delivery = "Every Monday at 08:00";
      lotDetails = "Volume Tier Pricing:\n"
          "• 1-10 units: 4.0 CHF / vegetable\n"
          "• 11-100 units: 2.0 CHF / vegetable\n"
          "• 100+ units: 1.0 CHF / vegetable";
    } else if (type == 'premium') {
      title = "PREMIUM ALCHEMICAL DELICACIES";
      sub = "Geneva Importing Board";
      delivery = "Every Friday at 12:00";
      commitments = "4-Week Binding Charter";
      loan = "Financing available at 8.5% per annum";
      lotDetails = "Tier Pricing:\n"
          "• 1-10 units: 12.0 CHF / alchemical herb\n"
          "• 11-100 units: 6.0 CHF / alchemical herb\n"
          "• 100+ units: 3.0 CHF / alchemical herb";
    } else if (type == 'bulk') {
      title = "GLARUS BULK PURCHASE";
      sub = "Wholesale Cantonal Logistics";
      delivery = "Every Wednesday at 06:00";
      commitments = "6-Week Binding Charter";
      loan = "Financing available at 5.0% per annum";
      lotDetails = "High-Volume Discounts:\n"
          "• 1-10 units: 3.5 CHF / raw unit\n"
          "• 11-100 units: 1.0 CHF / raw unit\n"
          "• 1000+ units: 0.25 CHF / raw unit (Save 75%!)";
    } else if (type == 'package') {
      title = "COLLECTIVE PACKAGE LOT";
      sub = "Liquidated Custom Lots";
      delivery = "One-time immediate delivery";
      isLot = true;
      commitments = "One-off Lot buyout agreement";
      lotDetails = "Preset Items Included:\n"
          "• 80 Standard Vegetables\n"
          "• 120 Standard Grains\n"
          "• 15 Alchemical Herbs\n"
          "• 10 Eldritch Meat units\n\n"
          "Total Lot Buyout Price: 600 CHF";

      // Haggling actions!
      extraActions = [
        ElevatedButton(
          onPressed: () {
            final success = Random().nextDouble() < 0.60; // 60% Success rate
            if (success) {
              // Haggle price to 450 CHF!
              state.updateResource('funds', -450);
              state.setResource('cabbage', (state.resources['cabbage'] ?? 0) + 80);
              state.setResource('grain', (state.resources['grain'] ?? 0) + 120);
              state.setResource('herbs', (state.resources['herbs'] ?? 0) + 15);
              state.setResource('meat_beef', (state.resources['meat_beef'] ?? 0) + 10);
              state.updateRestaurantSupplier('package');
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1A15),
                  title: Text("HAGGLING SUCCESS!", style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0))),
                  content: Text("You successfully haggled the vendor down! Acquired the collective package lot for only 450 CHF (Save 150 CHF!). Resources loaded into the pantry.", style: GoogleFonts.oldStandardTt(color: Colors.white70)),
                  actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("EXCELLENT"))],
                ),
              );
            } else {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1A15),
                  title: Text("HAGGLING FAILED", style: GoogleFonts.playfairDisplay(color: Colors.redAccent)),
                  content: Text("The custom merchant got highly offended by your lowball offer and refused to compromise! Price remains 600 CHF.", style: GoogleFonts.oldStandardTt(color: Colors.white70)),
                  actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("ALAS"))],
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
          child: Text("HAGGLE PRICE (60% CHANCE)", style: GoogleFonts.playfairDisplay(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            if (state.resources['funds']! >= 600) {
              state.updateResource('funds', -600);
              state.setResource('cabbage', (state.resources['cabbage'] ?? 0) + 80);
              state.setResource('grain', (state.resources['grain'] ?? 0) + 120);
              state.setResource('herbs', (state.resources['herbs'] ?? 0) + 15);
              state.setResource('meat_beef', (state.resources['meat_beef'] ?? 0) + 10);
              state.updateRestaurantSupplier('package');
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1A15),
                  title: Text("LOT PURCHASED", style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0))),
                  content: Text("Acquired the collective lot for 600 CHF. Preset quantities added to the estate pantry.", style: GoogleFonts.oldStandardTt(color: Colors.white70)),
                  actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("EXCELLENT"))],
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("INSUFFICIENT FUNDS.")));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: Text("BUY LOT FULL PRICE", style: GoogleFonts.playfairDisplay(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
        ),
      ];
    }

    showDialog(
      context: context,
      builder: (context) {
        final isSelected = state.restaurantSupplierContract == type;
        return Dialog(
          backgroundColor: const Color(0xFFF7F4EE), // Off-white parchment aesthetic
          shape: const RoundedRectangleBorder(),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF8C2D19), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFF2F2A24),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          sub.toUpperCase(),
                          style: GoogleFonts.oldStandardTt(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Icon(Icons.history_edu, color: Color(0xFF8C2D19), size: 32),
                  ],
                ),
                const Divider(color: Colors.black12, height: 24),
                const SizedBox(height: 8),
                Text(
                  "COVENANT SPECIFICATION SHEET",
                  style: GoogleFonts.oswald(color: const Color(0xFF8C2D19), fontSize: 11, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                Table(
                  children: [
                    TableRow(
                      children: [
                        Text("DELIVERY FREQUENCY:", style: GoogleFonts.oldStandardTt(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.bold)),
                        Text(delivery, style: GoogleFonts.oldStandardTt(color: Colors.black87, fontSize: 10)),
                      ],
                    ),
                    TableRow(
                      children: [
                        Text("CHARTER COMMITMENT:", style: GoogleFonts.oldStandardTt(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.bold)),
                        Text(commitments, style: GoogleFonts.oldStandardTt(color: Colors.black87, fontSize: 10)),
                      ],
                    ),
                    TableRow(
                      children: [
                        Text("FINANCING LOAN INT:", style: GoogleFonts.oldStandardTt(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.bold)),
                        Text(loan, style: GoogleFonts.oldStandardTt(color: Colors.black87, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.black.withValues(alpha: 0.05),
                  child: Text(
                    lotDetails,
                    style: GoogleFonts.oldStandardTt(color: Colors.black87, fontSize: 11, height: 1.4),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("CLOSE SHEET", style: GoogleFonts.playfairDisplay(color: Colors.black54, fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    if (!isLot)
                      ElevatedButton(
                        onPressed: () {
                          state.updateRestaurantSupplier(type);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8C2D19),
                        ),
                        child: Text(
                          isSelected ? "ALREADY ACTIVE" : "SIGN COVENANT DECREE",
                          style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      ...extraActions,
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOperatingHoursCalendarDialog(BuildContext context, GameState state) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFF1E1A15),
              shape: const RoundedRectangleBorder(),
              child: Container(
                width: 580,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFC4B89B))),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "RESTAURANT OPERATING HOURS WEEKLY CALENDAR",
                      style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Each day defaults to 17:00 to 22:00. Use sliders to reassign daily bounds or mark days closed.",
                      style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 9),
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    ...List.generate(7, (index) {
                      final day = index + 1;
                      final String dayName = ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"][index];
                      final isOpen = state.restaurantOperatingDays.contains(day);
                      final startHour = state.restaurantStartHours[day] ?? 17;
                      final endHour = state.restaurantEndHours[day] ?? 22;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 110,
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isOpen,
                                    activeColor: const Color(0xFFC4B89B),
                                    onChanged: (val) {
                                      state.toggleRestaurantDayClosed(day, val == false);
                                      setState(() {});
                                    },
                                  ),
                                  Expanded(
                                    child: Text(
                                      dayName,
                                      style: GoogleFonts.oswald(color: isOpen ? const Color(0xFFE5D5B0) : Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: isOpen
                                  ? SizedBox(
                                      height: 36,
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final cellWidth = constraints.maxWidth / 24;
                                          final leftOffset = startHour * cellWidth;
                                          final width = (endHour - startHour) * cellWidth;

                                          return Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              // Grid cells background
                                              Row(
                                                children: List.generate(24, (i) => Expanded(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                                                      color: Colors.black26,
                                                    ),
                                                  ),
                                                )),
                                              ),
                                              // Selected active hour block
                                              Positioned(
                                                left: leftOffset,
                                                width: width,
                                                top: 2,
                                                bottom: 2,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFC4B89B).withValues(alpha: 0.3),
                                                    border: Border.all(color: const Color(0xFFC4B89B)),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      "$startHour:00 - $endHour:00",
                                                      style: GoogleFonts.oswald(fontSize: 8, color: const Color(0xFFE5D5B0), fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Left drag handle
                                              Positioned(
                                                left: leftOffset - 8,
                                                width: 16,
                                                top: 0,
                                                bottom: 0,
                                                child: GestureDetector(
                                                  behavior: HitTestBehavior.translucent,
                                                  onHorizontalDragUpdate: (details) {
                                                    double newX = leftOffset + details.delta.dx;
                                                    int newStart = (newX / cellWidth).round().clamp(0, endHour - 1);
                                                    if (newStart != startHour) {
                                                      state.updateRestaurantDayHours(day, newStart, endHour);
                                                      setState(() {});
                                                    }
                                                  },
                                                  child: const Center(child: Icon(Icons.drag_handle, size: 10, color: Color(0xFFE5D5B0))),
                                                ),
                                              ),
                                              // Right drag handle
                                              Positioned(
                                                left: leftOffset + width - 8,
                                                width: 16,
                                                top: 0,
                                                bottom: 0,
                                                child: GestureDetector(
                                                  behavior: HitTestBehavior.translucent,
                                                  onHorizontalDragUpdate: (details) {
                                                    double newX = leftOffset + width + details.delta.dx;
                                                    int newEnd = (newX / cellWidth).round().clamp(startHour + 1, 24);
                                                    if (newEnd != endHour) {
                                                      state.updateRestaurantDayHours(day, startHour, newEnd);
                                                      setState(() {});
                                                    }
                                                  },
                                                  child: const Center(child: Icon(Icons.drag_handle, size: 10, color: Color(0xFFE5D5B0))),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    )
                                  : Container(
                                      height: 36,
                                      color: Colors.black12,
                                      child: Center(
                                        child: Text("BUSINESS CLOSED ON THIS DAY", style: GoogleFonts.oswald(color: Colors.white12, fontSize: 9)),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(color: Colors.white10, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC4B89B)),
                          child: Text("SAVE AND APPLY", style: GoogleFonts.playfairDisplay(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ],
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
}
