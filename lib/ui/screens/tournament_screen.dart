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
import 'package:collection/collection.dart';
import '../../models/arena_progress.dart';
import '../../models/npc.dart';
import '../../models/combat_stats.dart';
import '../../services/arena_save_service.dart';
import '../../services/combat_unit_service.dart';
import '../../services/combat_unit_factory.dart';
import 'combat_screen.dart';

class TournamentScreen extends StatefulWidget {
  final ArenaProgress progress;
  final VoidCallback onUpdate;

  const TournamentScreen({
    super.key,
    required this.progress,
    required this.onUpdate,
  });

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  late TournamentProgress _tournament;

  @override
  void initState() {
    super.initState();
    _tournament = widget.progress.tournament!;
  }

  /// Formulas resolution for all NPC vs NPC matches in the current round.
  void _resolveNpcMatches() {
    final activeRoundMatches = _tournament.matches.where((m) => m.round == _tournament.currentRound).toList();
    for (var match in activeRoundMatches) {
      if (match.winner != null) continue; // Skip Player's match if already resolved
      
      // Resolve NPC vs NPC formulaically
      final winner = _tournament.resolveNpcMatch(match.p1, match.p2);
      match.winner = winner;
    }
  }

  /// Sets up and pairs the next round matches based on the current round's winners.
  void _setupNextRound() {
    if (_tournament.currentRound >= 5) return; // Finals done!

    final activeRoundWinners = _tournament.matches
        .where((m) => m.round == _tournament.currentRound)
        .map((m) => m.winner!)
        .toList();

    _tournament.currentRound++;

    // Pair winners sequentially
    for (int i = 0; i < activeRoundWinners.length ~/ 2; i++) {
      _tournament.matches.add(TournamentMatch(
        round: _tournament.currentRound,
        p1: activeRoundWinners[i * 2],
        p2: activeRoundWinners[i * 2 + 1],
      ));
    }
  }

  NPC _getPlayerLeader() {
    final String leaderId = _tournament.playerLeaderId;
    final NPC leader;
    if (leaderId == 'alphonse') {
      leader = CombatUnitFactory.createAlphonse();
    } else if (leaderId == 'boss_rudolf') {
      leader = CombatUnitFactory.createBossRudolf().copyWith(id: 'boss_rudolf', isPlayer: true);
    } else if (leaderId == 'boss_gearbox') {
      leader = CombatUnitFactory.createBossGearbox().copyWith(id: 'boss_gearbox', isPlayer: true);
    } else if (leaderId == 'boss_elizabeth') {
      leader = CombatUnitFactory.createBossElizabeth().copyWith(id: 'boss_elizabeth', isPlayer: true);
    } else { // boss_thorne
      leader = CombatUnitFactory.createBossThorne().copyWith(id: 'boss_thorne', isPlayer: true);
    }
    return leader;
  }

  void _launchBattle() {
    // Find the player's active match
    final playerMatch = _tournament.matches.firstWhereOrNull(
      (m) => m.round == _tournament.currentRound && (m.p1 == 'Player' || m.p2 == 'Player'),
    );

    if (playerMatch == null || playerMatch.winner != null) return;

    final opponentName = playerMatch.p1 == 'Player' ? playerMatch.p2 : playerMatch.p1;
    final opponentDeckIds = _tournament.participantDecks[opponentName] ?? [];

    final playerDeck = _tournament.playerDeckIds.map((id) => CombatUnitService.createUnit(id)).toList();
    final aiDeck = opponentDeckIds.map((id) => CombatUnitService.createUnit(id)).toList();

    // Create a custom opponent General with basic stats
    final bossEnemy = CombatUnitFactory.createBossRudolf().copyWith(
      id: 'tournament_opponent_leader',
      name: opponentName,
      combatStats: const CombatStats(
        attack: 30,
        health: 260,
        maxHealth: 260,
        speed: 1.0,
        movement: 1.0,
        distance: 1.5,
        defense: 1,
        accuracy: 0.85,
        cost: 0,
        unitCount: 1,
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CombatScreen(
          customPlayerDeck: playerDeck,
          customAiDeck: aiDeck,
          customEnemyHero: bossEnemy,
          customPlayerHero: _getPlayerLeader(),
          onVictory: () async {
            // Player won!
            playerMatch.winner = 'Player';
            _resolveNpcMatches(); // Formulaically resolve all other NPC matches

            if (_tournament.currentRound == 5) {
              // Tournament Won!
              await ArenaSaveService.saveProgress(widget.progress);
              _showTournamentEndPopup(isVictory: true);
            } else {
              _setupNextRound();
              await ArenaSaveService.saveProgress(widget.progress);
              _showTournamentEndPopup(isVictory: false);
            }
          },
          onDefeat: () async {
            // Player lost and is eliminated!
            playerMatch.winner = opponentName;
            _tournament.isEliminated = true;
            _resolveNpcMatches(); // Resolve remaining matches for completeness
            await ArenaSaveService.saveProgress(widget.progress);
            _showTournamentEndPopup(isVictory: false, isElimination: true);
          },
        ),
      ),
    );
  }

  void _showTournamentEndPopup({required bool isVictory, bool isElimination = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final title = isVictory
            ? 'TOURNAMENT CHAMPION!'
            : (isElimination ? 'ELIMINATED' : 'ROUND VICTORIOUS!');
        final desc = isVictory
            ? 'Stunning! You have conquered the Grand Tournament and emerged as the absolute Champion among 32 competitors!'
            : (isElimination
                ? 'You were defeated in battle and eliminated from the single-elimination tournament. Better luck next run!'
                : 'Congratulations! You won your round match and advanced to the next round of the tournament.');

        return AlertDialog(
          backgroundColor: const Color(0xFF1D1712),
          shape: Border.all(
            color: isVictory
                ? Colors.yellow.shade800
                : (isElimination ? Colors.redAccent : const Color(0xFFC4B89B)),
            width: 2.0,
          ),
          title: Text(
            title,
            style: GoogleFonts.playfairDisplay(
              color: isVictory
                  ? const Color(0xFFD4AF37)
                  : (isElimination ? Colors.redAccent : const Color(0xFFE5D5B0)),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            desc,
            style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 12, height: 1.5),
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isVictory
                        ? Colors.yellow.shade800
                        : (isElimination ? Colors.redAccent : const Color(0xFFC4B89B)),
                  ),
                  shape: const RoundedRectangleBorder(),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  if (isVictory || isElimination) {
                    // Delete run upon completion
                    ArenaSaveService.deleteSave(widget.progress.slot);
                    widget.onUpdate();
                    Navigator.pop(context); // Exit Tournament
                  } else {
                    setState(() {});
                    widget.onUpdate();
                  }
                },
                child: Text(
                  isVictory || isElimination ? 'EXIT TOURNAMENT' : 'CONTINUE RUN',
                  style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 11),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Find the player's active match
    final playerMatch = _tournament.matches.firstWhereOrNull(
      (m) => m.round == _tournament.currentRound && (m.p1 == 'Player' || m.p2 == 'Player'),
    );
    final opponentName = playerMatch != null
        ? (playerMatch.p1 == 'Player' ? playerMatch.p2 : playerMatch.p1)
        : 'N/A';

    final String roundTitle = _tournament.isEliminated
        ? 'ELIMINATED'
        : _tournament.currentRound == 5
            ? 'THE GRAND FINALS'
            : 'ROUND OF ${32 ~/ (1 << (_tournament.currentRound - 1))}';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF15100B),
        title: Text(
          'GRAND TOURNAMENT',
          style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 15, letterSpacing: 2),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFC4B89B)),
      ),
      body: Container(
        color: const Color(0xFF1D1712), // Deep mahogany
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Current Round & Match Header Panel
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: Colors.black26,
                border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.25), width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    _tournament.isEliminated ? Icons.cancel : Icons.emoji_events,
                    color: _tournament.isEliminated ? Colors.redAccent : Colors.yellow.shade800,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roundTitle.toUpperCase(),
                          style: GoogleFonts.playfairDisplay(color: const Color(0xFFC4B89B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _tournament.isEliminated
                              ? 'ELIMINATED FROM THE BRACKET'
                              : 'MATCHUP: PLAYER vs $opponentName',
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFFE5D5B0),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (!_tournament.isEliminated)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.yellow.shade800),
                        backgroundColor: Colors.black26,
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      onPressed: _launchBattle,
                      child: Text(
                        'ENTER MATCH',
                        style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bracket Tree visual representation header
            Text(
              'TOURNAMENT BRACKET PROGRESSION',
              style: GoogleFonts.playfairDisplay(color: const Color(0xFFC4B89B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 12),

            // Scrollable Bracket view
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black12,
                  border: Border.all(color: Colors.white12),
                ),
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5, // 5 rounds total
                  itemBuilder: (context, index) {
                    final int roundNum = index + 1;
                    final roundMatches = _tournament.matches.where((m) => m.round == roundNum).toList();
                    final isCurrentRound = _tournament.currentRound == roundNum;

                    return Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: 20.0),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: isCurrentRound ? const Color(0xFFC4B89B).withValues(alpha: 0.3) : Colors.white12,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Round Title
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Text(
                              roundNum == 5 ? 'FINALS' : 'ROUND ${1 << (5 - roundNum)}',
                              style: GoogleFonts.playfairDisplay(
                                color: isCurrentRound ? const Color(0xFFE5D5B0) : Colors.white30,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),

                          // List of matches in this round
                          Expanded(
                            child: ListView.builder(
                              itemCount: 16 ~/ (1 << index),
                              itemBuilder: (context, matchIndex) {
                                if (matchIndex >= roundMatches.length) {
                                  // Pairings not generated yet
                                  return Container(
                                    height: 38,
                                    margin: const EdgeInsets.only(bottom: 8.0),
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      border: Border.all(color: Colors.white12, width: 0.5),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'TBD',
                                        style: TextStyle(color: Colors.white10, fontSize: 10),
                                      ),
                                    ),
                                  );
                                }

                                final m = roundMatches[matchIndex];
                                final bool p1Won = m.winner == m.p1;
                                final bool p2Won = m.winner == m.p2;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  padding: const EdgeInsets.all(6.0),
                                  decoration: BoxDecoration(
                                    color: isCurrentRound ? Colors.black38 : Colors.black12,
                                    border: Border.all(
                                      color: isCurrentRound ? const Color(0xFFC4B89B).withValues(alpha: 0.2) : Colors.white12,
                                      width: isCurrentRound ? 1.0 : 0.5,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.p1,
                                        style: TextStyle(
                                          color: p1Won
                                              ? Colors.green.shade300
                                              : (p2Won ? Colors.white24 : Colors.white70),
                                          fontSize: 9.5,
                                          fontWeight: p1Won ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        m.p2,
                                        style: TextStyle(
                                          color: p2Won
                                              ? Colors.green.shade300
                                              : (p1Won ? Colors.white24 : Colors.white70),
                                          fontSize: 9.5,
                                          fontWeight: p2Won ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
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
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
