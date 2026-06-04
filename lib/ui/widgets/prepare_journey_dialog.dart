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
import '../../state/game_state.dart';
import '../../models/npc.dart';

class PrepareJourneyDialog extends StatefulWidget {
  final String destinationId;

  const PrepareJourneyDialog({super.key, required this.destinationId});

  @override
  State<PrepareJourneyDialog> createState() => _PrepareJourneyDialogState();
}

class _PrepareJourneyDialogState extends State<PrepareJourneyDialog> {
  String? _selectedNpcId;
  final Map<String, num> _selectedResources = {
    'funds': 0,
  };
  final List<String> _escortIds = [];
  bool _isInitialized = false;
  final Map<String, TextEditingController> _controllers = {};

  void _initializeDefaults(List<NPC> npcs) {
    if (_isInitialized) return;
    if (npcs.isEmpty) return;
    _isInitialized = true;

    // Default traveler: Alphonse (player)
    _selectedNpcId = 'player';

    // Load persisted deck from player
    final player = npcs.firstWhere(
      (n) => n.id == 'player',
      orElse: () => npcs.first,
    );
    if (player.lastEscortIds.isNotEmpty) {
      _escortIds.addAll(player.lastEscortIds);
    } else {
      // Fallback: Auto-select initial unit pool as escorts if no history
      for (var npc in npcs) {
        if (npc.role == 'Minion' && _escortIds.length < 12) {
          _escortIds.add(npc.id);
        }
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        final availableNpcs = state.npcs
            .where((n) => n.worldDestinationId == null && n.isResident)
            .toList();
        
        _initializeDefaults(availableNpcs);

        return Dialog(
          backgroundColor: const Color(0xFF1E1A15),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: Container(
            width: 580,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC4B89B), width: 1),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "PREPARE EXPEDITION",
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    "DESTINATION: ${widget.destinationId.toUpperCase()}",
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFC4B89B).withValues(alpha: 0.7),
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // NPC Selector (Locked to Player)
                  _sectionHeader("EXPEDITION LEADER"),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFC4B89B),
                      child: Icon(Icons.stars, color: Colors.black),
                    ),
                    title: Text(
                      "ALPHONSE",
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFFE5D5B0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "MASTER OF THE MANOR",
                      style: GoogleFonts.oldStandardTt(
                        color: const Color(0xFFC4B89B).withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Resource Selector
                  _sectionHeader("PACK SUPPLIES"),
                  _buildResourceLedger(state),

                  const SizedBox(height: 24),

                  // Escort Selector
                  _sectionHeader("ESCORT ROSTER (12 SLOTS)"),
                  _buildEscortGrid(state),

                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "CANCEL",
                          style: GoogleFonts.oldStandardTt(color: Colors.white24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: availableNpcs.isEmpty
                            ? null
                            : () {
                                state.startJourney(
                                  _selectedNpcId!,
                                  widget.destinationId,
                                  _selectedResources,
                                  _escortIds,
                                );
                                Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC4B89B),
                          foregroundColor: Colors.black,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: Text(
                          "DEPART",
                          style: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.oldStandardTt(
          color: const Color(0xFFC4B89B),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildEscortGrid(GameState state) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final bool hasUnit = index < _escortIds.length;
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
            ),
            color: Colors.black26,
          ),
          child: InkWell(
            onTap: () => _showUnitSelection(context, state, index),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (hasUnit)
                  _buildUnitIcon(state, _escortIds[index])
                else
                  const Icon(Icons.add, color: Colors.white10, size: 16),
                if (hasUnit)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(
                      Icons.close,
                      size: 10,
                      color: Colors.redAccent.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnitIcon(GameState state, String id) {
    final npc = state.npcs.firstWhere((n) => n.id == id);
    return Tooltip(
      message: npc.name.toUpperCase(),
      child: Icon(
        npc.role == 'Minion' ? Icons.shield : Icons.person_search,
        color: npc.role == 'Minion'
            ? Colors.amberAccent
            : Colors.lightBlueAccent,
        size: 20,
      ),
    );
  }

  void _showUnitSelection(BuildContext context, GameState state, int index) {
    // If slot is occupied, remove it
    if (index < _escortIds.length) {
      setState(() => _escortIds.removeAt(index));
      return;
    }

    // Otherwise, show list of available units
    final travelerId = _selectedNpcId;
    final available = state.npcs.where((n) {
      return n.worldDestinationId == null &&
          n.isResident &&
          n.id != travelerId &&
          !_escortIds.contains(n.id);
    }).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No further units available.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1A15),
      builder: (context) {
        return ListView.builder(
          itemCount: available.length,
          itemBuilder: (context, i) {
            final npc = available[i];
            return ListTile(
              leading: Icon(
                npc.role == 'Minion' ? Icons.shield : Icons.person,
                color: const Color(0xFFC4B89B),
              ),
              title: Text(
                npc.name.toUpperCase(),
                style: GoogleFonts.oldStandardTt(color: Colors.white),
              ),
              subtitle: Text(
                npc.role.toUpperCase(),
                style: GoogleFonts.oldStandardTt(
                  color: const Color(0xFFC4B89B).withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
              onTap: () {
                setState(() => _escortIds.add(npc.id));
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  String _getItemMeasure(String type) {
    switch (type.toLowerCase()) {
      case 'funds':
        return 'Francs';
      case 'meals':
        return 'Portions';
      case 'eggs':
        return 'Eggs';
      case 'wood':
        return 'Logs';
      case 'meat':
        return 'Cuts';
      case 'cabbage':
        return 'Heads';
      case 'timber':
        return 'Beams';
      case 'fertilizer':
        return 'Sacks';
      default:
        return 'Units';
    }
  }

  double _getItemWeight(String type) {
    switch (type.toLowerCase()) {
      case 'funds':
        return 0.01;
      case 'meals':
        return 0.50;
      case 'eggs':
        return 0.05;
      case 'wood':
        return 2.0;
      case 'meat':
        return 1.0;
      case 'cabbage':
        return 0.50;
      case 'timber':
        return 5.0;
      case 'fertilizer':
        return 3.0;
      default:
        return 0.10;
    }
  }

  Widget _headerCell(String label, {required int flex, Alignment alignment = Alignment.centerLeft}) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: alignment,
        child: Text(
          label,
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFC4B89B).withOpacity(0.5),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _dataCell(String label, {required int flex, bool isBold = false, Alignment alignment = Alignment.centerLeft}) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: alignment,
        child: Text(
          label,
          style: isBold
              ? GoogleFonts.oswald(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 12,
                )
              : GoogleFonts.oldStandardTt(
                  color: const Color(0xFFC4B89B),
                  fontSize: 12,
                ),
        ),
      ),
    );
  }

  Widget _ledgerButton(String label, VoidCallback? onPressed) {
    return SizedBox(
      width: 32,
      height: 26,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: const Color(0xFF2C251E),
          foregroundColor: const Color(0xFFE5D5B0),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: const Color(0xFFC4B89B).withOpacity(0.3)),
          ),
          disabledForegroundColor: const Color(0xFFC4B89B).withOpacity(0.15),
          disabledBackgroundColor: Colors.transparent,
        ),
        child: Text(
          label,
          style: GoogleFonts.oldStandardTt(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildResourceLedger(GameState state) {
    // Dynamically pre-populate all owned items in the selected pack
    for (var key in state.resources.keys) {
      if (key != 'meals') {
        _selectedResources.putIfAbsent(key, () => 0);
        _controllers.putIfAbsent(key, () => TextEditingController(text: (_selectedResources[key] ?? 0).toString()));
      }
    }
    _controllers.putIfAbsent('funds', () => TextEditingController(text: (_selectedResources['funds'] ?? 0).toString()));

    final resourceKeys = _selectedResources.keys
        .where((key) => (state.resources[key] ?? 0) > 0 || key == 'funds')
        .toList();

    if (resourceKeys.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
          "NO SUPPLIES AVAILABLE",
          style: GoogleFonts.oldStandardTt(
            color: const Color(0xFFC4B89B).withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            _headerCell("ITEM", flex: 3),
            _headerCell("MEASURE", flex: 2),
            _headerCell("WGT/UNIT", flex: 2),
            _headerCell("AVAIL", flex: 2, alignment: Alignment.center),
            _headerCell("TO BRING", flex: 6, alignment: Alignment.center),
          ],
        ),
        const SizedBox(height: 4),
        Divider(color: const Color(0xFFC4B89B).withOpacity(0.2), height: 1),
        const SizedBox(height: 8),

        // List
        ...resourceKeys.map((res) {
          final maxAvailable = state.resources[res] ?? 0;
          final selected = _selectedResources[res]?.toInt() ?? 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                _dataCell(res.toUpperCase(), flex: 3, isBold: true),
                _dataCell(_getItemMeasure(res), flex: 2),
                _dataCell("${_getItemWeight(res).toStringAsFixed(2)}kg", flex: 2),
                _dataCell(maxAvailable.round().toString(), flex: 2, alignment: Alignment.center),
                Expanded(
                  flex: 6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Remove All
                      _ledgerButton("<<", selected > 0 ? () {
                        setState(() {
                          _selectedResources[res] = 0;
                          _controllers[res]?.text = "0";
                        });
                      } : null),
                      const SizedBox(width: 4),
                      // Remove 1
                      _ledgerButton("<", selected > 0 ? () {
                        setState(() {
                          final newVal = selected - 1;
                          _selectedResources[res] = newVal;
                          _controllers[res]?.text = newVal.toString();
                        });
                      } : null),
                      const SizedBox(width: 4),
                      // Input field
                      Container(
                        width: 40,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          border: Border.all(
                            color: const Color(0xFFC4B89B).withOpacity(0.3),
                          ),
                        ),
                        child: TextField(
                          controller: _controllers[res],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.oswald(
                            color: const Color(0xFFE5D5B0),
                            fontSize: 12,
                          ),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            border: InputBorder.none,
                          ),
                          onChanged: (val) {
                            if (val.isEmpty) {
                              setState(() {
                                _selectedResources[res] = 0;
                              });
                              return;
                            }
                            final parsed = int.tryParse(val);
                            if (parsed != null) {
                              final clamped = parsed.clamp(0, maxAvailable.toInt());
                              if (clamped != parsed) {
                                _controllers[res]?.text = clamped.toString();
                                _controllers[res]?.selection = TextSelection.fromPosition(
                                  TextPosition(offset: _controllers[res]!.text.length),
                                );
                              }
                              setState(() {
                                _selectedResources[res] = clamped;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Add 1
                      _ledgerButton(">", selected < maxAvailable ? () {
                        setState(() {
                          final newVal = selected + 1;
                          _selectedResources[res] = newVal;
                          _controllers[res]?.text = newVal.toString();
                        });
                      } : null),
                      const SizedBox(width: 4),
                      // Add All
                      _ledgerButton(">>", selected < maxAvailable ? () {
                        setState(() {
                          final newVal = maxAvailable.toInt();
                          _selectedResources[res] = newVal;
                          _controllers[res]?.text = newVal.toString();
                        });
                      } : null),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
