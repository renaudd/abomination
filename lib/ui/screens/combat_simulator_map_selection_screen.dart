import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import '../../models/combat_map.dart';
import '../../services/combat_unit_service.dart';
import 'combat_screen.dart';

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
    // Create NPC instances for the decks
    final playerUnits = widget.playerDeckTypes
        .map((t) => CombatUnitService.createUnit(t))
        .toList();
    final aiUnits = widget.aiDeckTypes
        .map((t) => CombatUnitService.createUnit(t))
        .toList();

    // Setup simulator state
    state.startCombatSimulation(playerUnits, aiUnits);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CombatScreen()),
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
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: CombatMap.allMaps.length,
                  itemBuilder: (context, index) {
                    final map = CombatMap.allMaps[index];
                    final isSelected = state.selectedCombatMap == map;

                    return GestureDetector(
                      onTap: () {
                        state.setSelectedCombatMap(map);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
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
                              size: 40,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                map.name.toUpperCase(),
                                style: GoogleFonts.oldStandardTt(
                                  color: isSelected
                                      ? const Color(0xFFE5D5B0)
                                      : Colors.white70,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFFC4B89B),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                color: Colors.black.withValues(alpha: 0.5),
                child: ElevatedButton(
                  onPressed: () => _startSimulation(state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC4B89B),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 20,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    minimumSize: const Size(double.infinity, 60),
                  ),
                  child: Text(
                    "START SIMULATION",
                    style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontSize: 16,
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
}
