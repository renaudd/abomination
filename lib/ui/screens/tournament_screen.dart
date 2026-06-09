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
import '../widgets/character_blob_renderer.dart';
import '../widgets/combat_card_detail_modal.dart';
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

  /// Formulaic resolution for all remaining unplayed NPC vs NPC matches in the current round.
  void _resolveRemainingNpcMatches() async {
    final activeRoundMatches = _tournament.matches
        .where((m) => m.round == _tournament.currentRound)
        .toList();
    for (var match in activeRoundMatches) {
      if (match.winner != null) continue;
      if (match.p1 == 'Player' || match.p2 == 'Player') continue;

      final winner = _tournament.resolveNpcMatch(match.p1, match.p2);
      match.winner = winner;
    }

    _checkRoundCompletion();
    await ArenaSaveService.saveProgress(widget.progress);
    setState(() {});
  }

  void _checkRoundCompletion() async {
    final activeRoundMatches = _tournament.matches
        .where((m) => m.round == _tournament.currentRound)
        .toList();

    if (activeRoundMatches.every((m) => m.winner != null)) {
      if (_tournament.currentRound == 5) {
        if (!_tournament.isEliminated && activeRoundMatches.any((m) => m.winner == 'Player')) {
          _showTournamentEndPopup(isVictory: true);
        }
      } else {
        _setupNextRound();
        if (!_tournament.isEliminated && activeRoundMatches.any((m) => (m.p1 == 'Player' || m.p2 == 'Player') && m.winner == 'Player')) {
          _showTournamentEndPopup(isVictory: false);
        }
      }
      await ArenaSaveService.saveProgress(widget.progress);
      setState(() {});
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

  NPC _getNpcHero(String name) {
    return CombatUnitFactory.createBossRudolf().copyWith(
      id: 'tournament_npc_${name.replaceAll(' ', '_')}',
      name: name,
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

    final bossEnemy = _getNpcHero(opponentName);

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
            _checkRoundCompletion();

            await ArenaSaveService.saveProgress(widget.progress);
            if (_tournament.currentRound == 5 && playerMatch.winner == 'Player') {
              _showTournamentEndPopup(isVictory: true);
            }
          },
          onDefeat: () async {
            // Player lost and is eliminated!
            playerMatch.winner = opponentName;
            _tournament.isEliminated = true;
            _checkRoundCompletion();
            await ArenaSaveService.saveProgress(widget.progress);
            _showTournamentEndPopup(isVictory: false, isElimination: true);
          },
        ),
      ),
    );
  }

  void _launchSimulationMatch(TournamentMatch match) {
    final p1DeckIds = _tournament.participantDecks[match.p1] ?? ['militia', 'goons'];
    final p2DeckIds = _tournament.participantDecks[match.p2] ?? ['militia', 'goons'];

    final p1Deck = p1DeckIds.map((id) => CombatUnitService.createUnit(id)).toList();
    final p2Deck = p2DeckIds.map((id) => CombatUnitService.createUnit(id)).toList();

    final hero1 = _getNpcHero(match.p1).copyWith(isPlayer: true);
    final hero2 = _getNpcHero(match.p2);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CombatScreen(
          customPlayerDeck: p1Deck,
          customAiDeck: p2Deck,
          customEnemyHero: hero2,
          customPlayerHero: hero1,
          isSimulationOnly: true,
          onVictory: () async {
            match.winner = match.p1;
            _checkRoundCompletion();
            await ArenaSaveService.saveProgress(widget.progress);
            setState(() {});
          },
          onDefeat: () async {
            match.winner = match.p2;
            _checkRoundCompletion();
            await ArenaSaveService.saveProgress(widget.progress);
            setState(() {});
          },
        ),
      ),
    );
  }

  void _showDeckDialog(String ownerName, List<String> deckIds) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1612),
          shape: Border.all(color: const Color(0xFFC4B89B), width: 1.5),
          child: SizedBox(
            width: 650,
            height: 550,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.black45,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${ownerName.toUpperCase()}'S DECK",
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFFC4B89B)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: deckIds.length,
                      itemBuilder: (context, idx) {
                        final cardId = deckIds[idx];
                        final unit = CombatUnitService.createUnit(cardId);
                        return InkWell(
                          onTap: () => CombatCardDetailModal.show(context, cardId),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CharacterBlobRenderer(npc: unit, size: 28, isCombat: true),
                                const SizedBox(height: 4),
                                Text(
                                  unit.name.toUpperCase(),
                                  style: GoogleFonts.oswald(color: Colors.white70, fontSize: 9),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${unit.combatStats!.cost} AP",
                                  style: GoogleFonts.oswald(color: Colors.cyanAccent, fontSize: 8.5),
                                ),
                              ],
                            ),
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
      },
    );
  }

  void _showMatchDetailsDialog(TournamentMatch m) {
    final bool isCurrentRound = _tournament.currentRound == m.round;
    final bool canPlayOrSimulate = isCurrentRound && m.winner == null;
    final bool isPlayerMatch = m.p1 == 'Player' || m.p2 == 'Player';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1712),
          shape: Border.all(color: const Color(0xFFC4B89B), width: 1.5),
          title: Text(
            'MATCHUP DETAILS (ROUND ${m.round})',
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFE5D5B0),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${m.p1.toUpperCase()} vs ${m.p2.toUpperCase()}',
                style: GoogleFonts.oswald(
                  color: const Color(0xFFD4AF37),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (m.winner != null) ...[
                const SizedBox(height: 6),
                Text(
                  'WINNER: ${m.winner!.toUpperCase()}',
                  style: GoogleFonts.oswald(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.style, color: Color(0xFFC4B89B), size: 16),
                    label: Text(
                      "EXAMINE ${m.p1.toUpperCase()}'S DECK",
                      style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 10.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFC4B89B)),
                    ),
                    onPressed: () {
                      final deckIds = m.p1 == 'Player' ? _tournament.playerDeckIds : (_tournament.participantDecks[m.p1] ?? []);
                      _showDeckDialog(m.p1, deckIds);
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.style, color: Color(0xFFC4B89B), size: 16),
                    label: Text(
                      "EXAMINE ${m.p2.toUpperCase()}'S DECK",
                      style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 10.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFC4B89B)),
                    ),
                    onPressed: () {
                      final deckIds = m.p2 == 'Player' ? _tournament.playerDeckIds : (_tournament.participantDecks[m.p2] ?? []);
                      _showDeckDialog(m.p2, deckIds);
                    },
                  ),
                ],
              ),
              if (canPlayOrSimulate && !_tournament.isEliminated) ...[
                const SizedBox(height: 24),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),
                if (isPlayerMatch)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.sports_esports, color: Colors.black, size: 18),
                    label: Text(
                      'ENTER BATTLE (PLAY)',
                      style: GoogleFonts.playfairDisplay(color: Colors.black, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _launchBattle();
                    },
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.visibility, color: Color(0xFFE5D5B0), size: 18),
                        label: Text(
                          'WATCH BATTLE (SIMULATION)',
                          style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 11),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFC4B89B)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _launchSimulationMatch(m);
                        },
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.flash_on, color: Colors.black, size: 18),
                        label: Text(
                          'INSTANT RESOLVE (RESULTS)',
                          style: GoogleFonts.playfairDisplay(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          m.winner = _tournament.resolveNpcMatch(m.p1, m.p2);
                          _checkRoundCompletion();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
              ],
            ],
          ),
        );
      },
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
    final Size size = MediaQuery.of(context).size;
    final bool isCompact = size.width < 600;

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

    final activeMatches = _tournament.matches.where((m) => m.round == _tournament.currentRound).toList();
    final bool hasUnresolvedMatches = activeMatches.any((m) => m.winner == null);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF15100B),
        title: Text(
          'GRAND TOURNAMENT',
          style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: isCompact ? 14 : 16, letterSpacing: 2),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFC4B89B)),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.remove_red_eye, color: Color(0xFFD4AF37), size: 18),
            label: Text(
              'VIEW MY DECK',
              style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _showDeckDialog('Player', _tournament.playerDeckIds),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Container(
        color: const Color(0xFF1D1712), // Deep mahogany
        padding: EdgeInsets.all(isCompact ? 10.0 : 16.0),
        child: Column(
          children: [
            // Current Round & Match Header Panel
            Container(
              padding: EdgeInsets.all(isCompact ? 10.0 : 14.0),
              decoration: BoxDecoration(
                color: Colors.black26,
                border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.25), width: 1),
              ),
              child: isCompact
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              _tournament.isEliminated ? Icons.cancel : Icons.emoji_events,
                              color: _tournament.isEliminated ? Colors.redAccent : Colors.yellow.shade800,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    roundTitle.toUpperCase(),
                                    style: GoogleFonts.playfairDisplay(
                                      color: const Color(0xFFC4B89B),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _tournament.isEliminated
                                        ? 'ELIMINATED FROM THE BRACKET'
                                        : 'MATCHUP: PLAYER vs $opponentName',
                                    style: GoogleFonts.playfairDisplay(
                                      color: const Color(0xFFE5D5B0),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            if (!_tournament.isEliminated && playerMatch != null && playerMatch.winner == null)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4AF37),
                                  foregroundColor: Colors.black,
                                  shape: const RoundedRectangleBorder(),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                onPressed: _launchBattle,
                                child: Text(
                                  'ENTER MATCH',
                                  style: GoogleFonts.playfairDisplay(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            if (!_tournament.isEliminated && hasUnresolvedMatches)
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFC4B89B)),
                                  shape: const RoundedRectangleBorder(),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                onPressed: _resolveRemainingNpcMatches,
                                child: Text(
                                  'QUICK RESOLVE ROUND',
                                  style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 10),
                                ),
                              ),
                          ],
                        ),
                      ],
                    )
                  : Row(
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
                        const SizedBox(width: 12),
                        if (!_tournament.isEliminated && playerMatch != null && playerMatch.winner == null)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: Colors.black,
                              shape: const RoundedRectangleBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: _launchBattle,
                            child: Text(
                              'ENTER MATCH',
                              style: GoogleFonts.playfairDisplay(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (!_tournament.isEliminated && hasUnresolvedMatches)
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFC4B89B)),
                              shape: const RoundedRectangleBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onPressed: _resolveRemainingNpcMatches,
                            child: Text(
                              'QUICK RESOLVE ROUND',
                              style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 10),
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),

            // Bracket Tree visual representation header
            Text(
              'TOURNAMENT BRACKET PROGRESSION (TAP MATCH TO VIEW)',
              style: GoogleFonts.playfairDisplay(color: const Color(0xFFC4B89B), fontSize: isCompact ? 10 : 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Scrollable Bracket view
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black12,
                  border: Border.all(color: Colors.white12),
                ),
                padding: EdgeInsets.all(isCompact ? 8.0 : 16.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5, // 5 rounds total
                  itemBuilder: (context, index) {
                    final int roundNum = index + 1;
                    final roundMatches = _tournament.matches.where((m) => m.round == roundNum).toList();
                    final isCurrentRound = _tournament.currentRound == roundNum;

                    return Container(
                      width: isCompact ? 150 : 180,
                      margin: const EdgeInsets.only(right: 16.0),
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
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              roundNum == 5 ? 'FINALS' : 'ROUND ${1 << (5 - roundNum)}',
                              style: GoogleFonts.playfairDisplay(
                                color: isCurrentRound ? const Color(0xFFE5D5B0) : Colors.white30,
                                fontSize: isCompact ? 10.5 : 11,
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

                                return InkWell(
                                  onTap: () => _showMatchDetailsDialog(m),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8.0),
                                    padding: const EdgeInsets.all(6.0),
                                    decoration: BoxDecoration(
                                      color: isCurrentRound ? Colors.black38 : Colors.black12,
                                      border: Border.all(
                                        color: isCurrentRound ? const Color(0xFFC4B89B).withValues(alpha: 0.4) : Colors.white12,
                                        width: isCurrentRound ? 1.5 : 0.5,
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
