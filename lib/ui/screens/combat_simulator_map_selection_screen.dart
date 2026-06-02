import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import '../../models/combat_map.dart';
import '../../services/combat_unit_service.dart';
import 'combat_screen.dart';
import 'combat_simulator_leader_selection_screen.dart';

class CombatSimulatorMapSelectionScreen extends StatefulWidget {
  final List<String> playerDeckTypes;
  final List<String> aiDeckTypes;

  const CombatSimulatorMapSelectionScreen({
    super.key,
    required this.playerDeckTypes,
    required this.aiDeckTypes,
  });

  @override
  State<CombatSimulatorMapSelectionScreen> createState() =>
      _CombatSimulatorMapSelectionScreenState();
}

class _CombatSimulatorMapSelectionScreenState
    extends State<CombatSimulatorMapSelectionScreen> {
  void _startSimulation(GameState state) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CombatSimulatorLeaderSelectionScreen(
          playerDeckTypes: widget.playerDeckTypes,
          aiDeckTypes: widget.aiDeckTypes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      appBar: AppBar(
        title: Text(
          'SELECT BATTLEFIELD MAP',
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
      body: Consumer<GameState>(
        builder: (context, state, child) {
          final smallMaps = CombatMap.allMaps.where((m) => m.sizeCategory == CombatMapSize.small).toList();
          final mediumMaps = CombatMap.allMaps.where((m) => m.sizeCategory == CombatMapSize.medium).toList();
          final colossalMaps = CombatMap.allMaps.where((m) => m.sizeCategory == CombatMapSize.colossal).toList();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    _buildSectionHeader("SMALL SKIRMISH BATTLEFIELDS (1.0x Area Baseline)"),
                    const SizedBox(height: 8),
                    ...smallMaps.map((map) => _buildMapItem(context, state, map)),
                    const SizedBox(height: 16),
                    _buildSectionHeader("MEDIUM TACTICAL BATTLEFIELDS (approx. 2.5x - 3.5x Area Scale)"),
                    const SizedBox(height: 8),
                    ...mediumMaps.map((map) => _buildMapItem(context, state, map)),
                    const SizedBox(height: 16),
                    _buildSectionHeader("COLOSSAL GRAND BATTLEFIELDS (approx. 9.0x Area Scale)"),
                    const SizedBox(height: 8),
                    ...colossalMaps.map((map) => _buildMapItem(context, state, map)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.black.withValues(alpha: 0.5),
                child: ElevatedButton(
                  onPressed: () => _startSimulation(state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC4B89B),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  child: Text(
                    "SELECT LEADERS",
                    style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFE5D5B0),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        const Divider(color: Colors.white24, height: 1),
      ],
    );
  }

  Widget _buildMapItem(BuildContext context, GameState state, CombatMap map) {
    final isSelected = state.selectedCombatMap == map;
    final area = map.width * map.height;

    return GestureDetector(
      onTap: () {
        state.setSelectedCombatMap(map);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black38,
          border: Border.all(
            color: isSelected
                ? const Color(0xFFC4B89B)
                : const Color(0xFFC4B89B).withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.map,
              color: isSelected
                  ? const Color(0xFFC4B89B)
                  : Colors.white54,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    map.name.toUpperCase(),
                    style: GoogleFonts.oldStandardTt(
                      color: isSelected
                          ? const Color(0xFFE5D5B0)
                          : Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "DIMENSIONS: ${map.width.toInt()} x ${map.height.toInt()} | AREA: ${area.toInt()} SQ. UNITS",
                    style: GoogleFonts.oswald(
                      color: isSelected
                          ? const Color(0xFFC4B89B).withValues(alpha: 0.8)
                          : Colors.white38,
                      fontSize: 9.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFC4B89B),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

