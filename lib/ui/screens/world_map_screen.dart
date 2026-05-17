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
import '../widgets/location_tile.dart';
import '../widgets/prepare_journey_dialog.dart';
import 'hamlet_screen.dart';
import 'destination_screen.dart';
import 'regional_map_screen.dart';
import '../widgets/encounter_dialog.dart';
import '../../models/npc.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  bool _timeControlsExpanded = false;

  @override
  void initState() {
    super.initState();
    _checkNavigation();
  }

  void _checkNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<GameState>();
      final destination = state.pendingNavigationTarget;

      if (destination != null) {
        state.clearPendingNavigation();
        if (destination == 'manor') {
          if (mounted) Navigator.pop(context);
        } else if (destination == 'hamlet') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HamletScreen()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DestinationScreen(destinationId: destination),
            ),
          );
        }
      } else if (state.pendingCombatEncounter) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const EncounterDialog(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for state changes to trigger navigation
    context.watch<GameState>();
    _checkNavigation();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      appBar: AppBar(
        title: Text(
          'SURVEY ESTATE',
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
        actions: [
          _buildClockWidget(context),
        ],
      ),
      body: Stack(
        children: [
          // Zoomable Map Content
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.1,
              maxScale: 3.0,
              constrained: false,
              child: SizedBox(
                width: 1200,
                height: 800,
                child: Stack(
                  children: [
                    // Background Image
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/rolle_area.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              'MAP IMAGE NOT FOUND',
                              style: GoogleFonts.oldStandardTt(color: Colors.redAccent),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Map Content (Strategic Layout)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Stack(
                          children: [
                            // River (Visual Representation)
                      Positioned(
                        top: 80,
                        right: 0,
                        bottom: 40,
                        width: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: const Color(
                                  0xFFC4B89B,
                                ).withValues(alpha: 0.1),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Locations
                      Positioned(
                        top: 20,
                        left: 140,
                        child: Consumer<GameState>(
                          builder: (context, state, child) {
                            final someoneThere = state.npcs.any(
                              (n) =>
                                  n.worldDestinationId == 'mountains' &&
                                  n.worldTravelProgress >= 1.0,
                            );
                            return LocationTile(
                              name: 'NORTHERN MOUNTAINS',
                              icon: Icons.terrain,
                              description: someoneThere
                                  ? 'Representative surveying the peaks.'
                                  : 'Unexplored peaks and potential mining sites.',
                              isCurrent: someoneThere,
                              onTap: () =>
                                  _showPrepareJourney(context, 'mountains'),
                            );
                          },
                        ),
                      ),

                      Positioned(
                        top: 120,
                        left: 280,
                        child: LocationTile(
                          name: 'THE MANOR',
                          icon: Icons.castle,
                          description: 'Your inherited estate and laboratory.',
                          isCurrent: true,
                          onTap: () => Navigator.pop(context),
                        ),
                      ),

                      Positioned(
                        bottom: 264,
                        left: 650,
                        child: Consumer<GameState>(
                          builder: (context, state, child) {
                            final someoneThere = state.npcs.any(
                              (n) =>
                                  n.worldDestinationId == 'hamlet' &&
                                  n.worldTravelProgress >= 1.0,
                            );
                            return LocationTile(
                              name: 'HAMLET',
                              icon: Icons.location_city,
                              description: someoneThere
                                  ? 'Your representative is in town.'
                                  : 'A sleepy border town. Send someone to trade.',
                              isCurrent: someoneThere,
                              onTap: () {
                                if (someoneThere) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const HamletScreen(),
                                    ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        const PrepareJourneyDialog(
                                          destinationId: 'hamlet',
                                        ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),

                      // Traveling NPC Icons
                      ..._buildTravelingNpcs(context),

                      Positioned(
                        top: 60,
                        right: 60,
                        child: Consumer<GameState>(
                          builder: (context, state, child) {
                            final someoneThere = state.npcs.any(
                              (n) =>
                                  n.worldDestinationId == 'woods' &&
                                  n.worldTravelProgress >= 1.0,
                            );
                            return LocationTile(
                              name: 'ANCIENT WOODS',
                              icon: Icons.forest,
                              description: someoneThere
                                  ? 'Representative gathering intel in the woods.'
                                  : 'Bountiful wood, but scarce game due to the war.',
                              isCurrent: someoneThere,
                              onTap: () =>
                                  _showPrepareJourney(context, 'woods'),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 264,
                        right: 650,
                        child: Consumer<GameState>(
                          builder: (context, state, child) {
                            final someoneThere = state.npcs.any(
                              (n) =>
                                  n.worldDestinationId == 'river' &&
                                  n.worldTravelProgress >= 1.0,
                            );
                            return LocationTile(
                              name: 'RIVER ACCESS',
                              icon: Icons.water,
                              description: someoneThere
                                  ? 'Representative watching the river.'
                                  : 'River access. Leads to the city and beyond.',
                              isCurrent: someoneThere,
                              onTap: () =>
                                  _showPrepareJourney(context, 'river'),
                            );
                          },
                        ),
                      ),

                      Positioned(
                        bottom: 40,
                        left: 40,
                        child: LocationTile(
                          name: 'ROAD TO GENEVA',
                          icon: Icons.map_outlined,
                          description:
                              'Zoom out to view the regional geography.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegionalMapScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                  ],
                ),
              ),
            ),
          ),
      // Time Controls Overlay
          if (_timeControlsExpanded)
            Positioned(
              top: 0,
              right: 16,
              child: Consumer<GameState>(
                builder: (context, state, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1612).withValues(alpha: 0.9),
                      border: Border.all(
                        color: const Color(0xFFC4B89B).withValues(alpha: 0.3),
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _speedIcon(context, state, GameSpeed.paused, Icons.pause, 'PAUSE'),
                        _speedIcon(context, state, GameSpeed.slow, Icons.play_arrow_outlined, 'SLOW'),
                        _speedIcon(context, state, GameSpeed.normal, Icons.play_arrow, 'NORMAL'),
                        _speedIcon(context, state, GameSpeed.fast, Icons.fast_forward, 'FAST'),
                        _speedIcon(context, state, GameSpeed.superFast, Icons.bolt, 'LIGHTNING'),
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

  Widget _speedIcon(
    BuildContext context,
    GameState state,
    GameSpeed speed,
    IconData icon,
    String tooltip,
  ) {
    final isSelected = state.speed == speed;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(
          icon,
          color: isSelected ? const Color(0xFFE5D5B0) : Colors.white24,
          size: 20,
        ),
        onPressed: () {
          state.setSpeed(speed);
          setState(() => _timeControlsExpanded = false);
        },
      ),
    );
  }

  Widget _buildClockWidget(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        return InkWell(
          onTap: () {
            setState(() {
              _timeControlsExpanded = !_timeControlsExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  state.currentDate.formattedDate.toUpperCase(),
                  style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: const Color(0xFFE5D5B0),
                  ),
                ),
                Text(
                  state.currentDate.formattedTime,
                  style: GoogleFonts.oswald(
                    color: const Color(0xFFC4B89B),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPrepareJourney(BuildContext context, String destinationId) {
    showDialog(
      context: context,
      builder: (context) => PrepareJourneyDialog(destinationId: destinationId),
    );
  }

  List<Widget> _buildTravelingNpcs(BuildContext context) {
    final state = Provider.of<GameState>(context);
    final travelingNpcs = state.npcs.where(
          (n) =>
              n.worldDestinationId != null &&
              (n.worldTravelProgress < 1.0 || n.worldDestinationId != 'manor'),
        )
        .toList();

    if (travelingNpcs.isEmpty) return [];

    final size = MediaQuery.of(context).size;
    // Map view height is screen height minus AppBar (kToolbarHeight usually 56) and top padding
    final stackHeight = size.height - kToolbarHeight - MediaQuery.of(context).padding.top;
    final stackWidth = size.width;

    // Center offset for the location tiles (approx 75 width, 40 height)
    const dx = 75.0;
    const dy = 40.0;

    // Map location IDs to screen coordinates to match the Positioned logic in _buildLocations
    final Map<String, Offset> coords = {
      'manor': const Offset(280 + dx, 120 + dy),
      'mountains': const Offset(140 + dx, 20 + dy),
      'hamlet': Offset(650 + dx, stackHeight - 264 - dy),
      'woods': Offset(stackWidth - 60 - dx, 60 + dy),
      'river': Offset(stackWidth - 650 - dx, stackHeight - 264 - dy),
    };

    // Group NPCs into parties based on their travel metadata
    final Map<String, List<NPC>> parties = {};
    for (var npc in travelingNpcs) {
      final key =
          "${npc.worldDestinationId}_${npc.worldDepartureId}_${npc.worldTravelProgress.toStringAsFixed(3)}";
      parties.putIfAbsent(key, () => []).add(npc);
    }

    return parties.entries.map((entry) {
      final party = entry.value;
      final leader = party.firstWhere(
        (n) => n.isPlayer,
        orElse: () => party.first,
      );
      final dest = leader.worldDestinationId!;

      Offset start;
      Offset end;

      if (dest == 'manor') {
        start = coords[leader.worldDepartureId] ?? coords['hamlet']!;
        end = coords['manor']!;
      } else {
        start = coords['manor']!;
        end = coords[dest] ?? coords['hamlet']!;
      }

      final progress = leader.worldTravelProgress.clamp(0.0, 1.0);
      final currentPos = Offset.lerp(start, end, progress)!;

      final bool hasPlayer = party.any((n) => n.isPlayer);
      final String label = party.length > 1
          ? "${leader.name.toUpperCase()} + ${party.length - 1} OTHERS"
          : leader.name.toUpperCase();

      return Positioned(
        top: currentPos.dy,
        left: currentPos.dx,
        child: Column(
          children: [
            Icon(
              hasPlayer ? Icons.stars : Icons.group,
              size: 24,
              color: hasPlayer ? Colors.amberAccent : Colors.white,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              color: Colors.black54,
              child: Text(
                label,
                style: GoogleFonts.oldStandardTt(
                  fontSize: 8,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
