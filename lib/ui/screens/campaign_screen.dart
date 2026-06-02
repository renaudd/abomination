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
import '../../models/arena_progress.dart';
import '../../models/npc.dart';
import '../../services/arena_save_service.dart';
import '../../services/combat_unit_service.dart';
import '../../services/combat_unit_factory.dart';
import 'combat_screen.dart';
import '../widgets/character_blob_renderer.dart';

class CampaignScreen extends StatefulWidget {
  final ArenaProgress progress;
  final VoidCallback onUpdate;

  const CampaignScreen({
    super.key,
    required this.progress,
    required this.onUpdate,
  });

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen> {
  late CampaignProgress _campaign;
  String _selectedTab = 'PROGRESS'; // 'PROGRESS', 'DECK', 'SHOP'
  int _selectedDeckIndex = 0;

  @override
  void initState() {
    super.initState();
    _campaign = widget.progress.campaign!;
  }

  /// Generates the player's custom upgraded deck for combat.
  List<NPC> _generatePlayerDeck() {
    return _campaign.playerDeckIds.map((id) {
      final npc = CombatUnitService.createUnit(id);
      final stats = npc.combatStats;
      if (stats != null) {
        // Apply upgrades dynamically!
        final hpLvl = _campaign.cardUpgrades['${id}_hp'] ?? 0;
        final atkLvl = _campaign.cardUpgrades['${id}_atk'] ?? 0;
        final spdLvl = _campaign.cardUpgrades['${id}_spd'] ?? 0;

        final newMaxHp = stats.maxHealth * (1.0 + hpLvl * 0.15); // +15% HP per level
        final newAtk = stats.attack * (1.0 + atkLvl * 0.15);     // +15% ATK per level
        final newSpeed = stats.speed * (1.0 + spdLvl * 0.05);     // +5% Attack Speed per level

        return npc.copyWith(
          combatStats: stats.copyWith(
            maxHealth: newMaxHp,
            health: newMaxHp,
            attack: newAtk,
            speed: newSpeed,
            meleeDamage: stats.meleeDamage * (1.0 + atkLvl * 0.15),
            rangedDamage: stats.rangedDamage * (1.0 + atkLvl * 0.15),
          ),
        );
      }
      return npc;
    }).toList();
  }

  NPC _getPlayerLeader() {
    final String leaderId = _campaign.playerLeaderId;
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

    final stats = leader.combatStats;
    if (stats != null) {
      final hpLvl = _campaign.cardUpgrades['leader_hp'] ?? 0;
      final atkLvl = _campaign.cardUpgrades['leader_atk'] ?? 0;
      final spdLvl = _campaign.cardUpgrades['leader_spd'] ?? 0;

      final newMaxHp = stats.maxHealth * (1.0 + hpLvl * 0.15); // +15% HP per level
      final newAtk = stats.attack * (1.0 + atkLvl * 0.15);     // +15% ATK per level
      final newSpeed = stats.speed * (1.0 + spdLvl * 0.05);     // +5% Speed per level

      return leader.copyWith(
        combatStats: stats.copyWith(
          maxHealth: newMaxHp,
          health: newMaxHp,
          attack: newAtk,
          speed: newSpeed,
          meleeDamage: stats.meleeDamage * (1.0 + atkLvl * 0.15),
          rangedDamage: stats.rangedDamage * (1.0 + atkLvl * 0.15),
        ),
      );
    }
    return leader;
  }

  /// Progressive Opponent Deck generator
  List<NPC> _generateAiDeck() {
    final List<String> opponentDeckIds = _getCampaignOpponentDeck(_campaign.campaignId, _campaign.currentStage);
    return opponentDeckIds.map((id) {
      final troop = CombatUnitService.createUnit(id);
      final stats = troop.combatStats;
      if (stats != null) {
        // Scale troop stats: +4% health and +4% attack per stage
        final stageMultiplier = 1.0 + _campaign.currentStage * 0.04;
        return troop.copyWith(
          combatStats: stats.copyWith(
            maxHealth: stats.maxHealth * stageMultiplier,
            health: stats.maxHealth * stageMultiplier,
            attack: stats.attack * stageMultiplier,
            meleeDamage: stats.meleeDamage * stageMultiplier,
            rangedDamage: stats.rangedDamage * stageMultiplier,
          ),
        );
      }
      return troop;
    }).toList();
  }

  /// Progressive Opponent Deck card IDs
  static List<String> _getCampaignOpponentDeck(String campaignId, int stage) {
    final List<String> deck = [];
    final int unitCount = 4 + (stage ~/ 4); // Progressive deck size (4 to 8 cards)
    
    if (campaignId == 'alpine_uprising') {
      for (int i = 0; i < unitCount; i++) {
        if (stage < 5) {
          deck.add(i % 2 == 0 ? 'thugs' : 'militia');
        } else if (stage < 10) {
          deck.add(i % 3 == 0 ? 'pikemen' : (i % 3 == 1 ? 'militia' : 'marksmen'));
        } else if (stage < 15) {
          deck.add(i % 3 == 0 ? 'cavalry' : (i % 3 == 1 ? 'pikemen' : 'musketeers'));
        } else {
          deck.add(i % 4 == 0 ? 'cavalry' : (i % 4 == 1 ? 'cannoneer' : (i % 4 == 2 ? 'musketeers' : 'pikemen')));
        }
      }
    } else if (campaignId == 'clockwork_siege') {
      for (int i = 0; i < unitCount; i++) {
        if (stage < 5) {
          deck.add(i % 2 == 0 ? 'bicycle_gang' : 'musketeers');
        } else if (stage < 10) {
          deck.add(i % 3 == 0 ? 'motorcycle_gang' : (i % 3 == 1 ? 'musketeers' : 'cannoneer'));
        } else if (stage < 15) {
          deck.add(i % 3 == 0 ? 'armored_car' : (i % 3 == 1 ? 'motorcycle_gang' : 'cannoneer'));
        } else {
          deck.add(i % 4 == 0 ? 'wooden_tank' : (i % 4 == 1 ? 'armored_car' : (i % 4 == 2 ? 'cannoneer' : 'motorcycle_gang')));
        }
      }
    } else if (campaignId == 'necropolis_crypt') {
      for (int i = 0; i < unitCount; i++) {
        if (stage < 5) {
          deck.add(i % 2 == 0 ? 'rats_unit' : 'bats_unit');
        } else if (stage < 10) {
          deck.add(i % 3 == 0 ? 'undead_rats' : (i % 3 == 1 ? 'bats_unit' : 'werewolf'));
        } else if (stage < 15) {
          deck.add(i % 3 == 0 ? 'werewolf' : (i % 3 == 1 ? 'undead_rats' : 'flesh_golem'));
        } else {
          deck.add(i % 4 == 0 ? 'flesh_golem' : (i % 4 == 1 ? 'chimera' : (i % 4 == 2 ? 'werewolf' : 'undead_rats')));
        }
      }
    } else { // deep_woods_hunt
      for (int i = 0; i < unitCount; i++) {
        if (stage < 5) {
          deck.add(i % 2 == 0 ? 'wild_wolves' : 'wild_foxes');
        } else if (stage < 10) {
          deck.add(i % 3 == 0 ? 'wild_bears' : (i % 3 == 1 ? 'wild_wolves' : 'wild_foxes'));
        } else if (stage < 15) {
          deck.add(i % 3 == 0 ? 'wild_bears' : (i % 3 == 1 ? 'werewolf' : 'wild_wolves'));
        } else {
          deck.add(i % 4 == 0 ? 'chimera' : (i % 4 == 1 ? 'wild_bears' : (i % 4 == 2 ? 'werewolf' : 'wild_wolves')));
        }
      }
    }
    return deck;
  }

  /// Progressive Opponent names
  String _getOpponentName() {
    if (_campaign.currentStage == 19) {
      if (_campaign.campaignId == 'alpine_uprising') return 'General Rudolf (BOSS)';
      if (_campaign.campaignId == 'clockwork_siege') return 'Baron von Gearbox (BOSS)';
      if (_campaign.campaignId == 'necropolis_crypt') return 'Lady Elizabeth (BOSS)';
      return 'Keeper Thorne (BOSS)';
    }

    final List<String> names = [
      'Rebel Outpost Scout', 'Alpine Patrol Squad', 'Garrison Sentry Pack', 'Village Militia Vanguard',
      'Border Line Enforcers', 'Garrison Lieutenant Guard', 'Iron-Clad Archers', 'Heavy Pike Vanguard',
      'Baron\'s Commando Squad', 'Fortress Gatekeepers', 'Castle Royal Archers', 'Heavy Dragoons Division',
      'Platoon Shock Troopers', 'Sector Defense Division', 'Vanguard Heavy Phalanx', 'Baron\'s Personal Guards',
      'Elite High-Tier Squad', 'Fortress Main Siege Crew', 'Lord Commander\'s Vanguard', 'The Lord Commander\'s Guard'
    ];
    return names[_campaign.currentStage];
  }

  NPC _getOpponentBoss() {
    if (_campaign.campaignId == 'alpine_uprising') return CombatUnitFactory.createBossRudolf();
    if (_campaign.campaignId == 'clockwork_siege') return CombatUnitFactory.createBossGearbox();
    if (_campaign.campaignId == 'necropolis_crypt') return CombatUnitFactory.createBossElizabeth();
    return CombatUnitFactory.createBossThorne();
  }

  void _launchBattle() {
    final playerDeck = _generatePlayerDeck();
    final aiDeck = _generateAiDeck();
    final opponentName = _getOpponentName();
    
    NPC? bossEnemy;
    if (_campaign.currentStage == 19) {
      bossEnemy = _getOpponentBoss();
    } else {
      final baseLeader = CombatUnitFactory.createBossRudolf();
      final baseStats = baseLeader.combatStats!;

      // Scale leader stats progressively: +6% health and attack per stage
      final stageMultiplier = 1.0 + _campaign.currentStage * 0.06;
      final scaledStats = baseStats.copyWith(
        maxHealth: baseStats.maxHealth * stageMultiplier,
        health: baseStats.maxHealth * stageMultiplier,
        attack: baseStats.attack * stageMultiplier,
        meleeDamage: baseStats.meleeDamage * stageMultiplier,
        rangedDamage: baseStats.rangedDamage * stageMultiplier,
      );

      bossEnemy = baseLeader.copyWith(
        name: opponentName,
        id: 'campaign_opponent_leader',
        combatStats: scaledStats,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CombatScreen(
          customPlayerDeck: playerDeck,
          customAiDeck: aiDeck,
          customEnemyHero: bossEnemy,
          customPlayerHero: _getPlayerLeader(),
          cardUpgrades: _campaign.cardUpgrades,
          onVictory: () async {
            // Victory Callback!
            final goldReward = 150 + _campaign.currentStage * 15; // Increasing rewards
            _campaign.campaignCoins += goldReward;

            if (_campaign.currentStage == 19) {
              // Campaign Completed!
              _showVictoryPopup(isCompletion: true);
            } else {
              _campaign.currentStage++;
              await ArenaSaveService.saveProgress(widget.progress);
              _showVictoryPopup(isCompletion: false, reward: goldReward);
            }
          },
          onDefeat: () {
            // Defeat Callback (Retry allowed, no penalty)
            _showDefeatPopup();
          },
        ),
      ),
    );
  }

  void _showVictoryPopup({required bool isCompletion, int reward = 0}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1712),
          shape: Border.all(color: Colors.yellow.shade800, width: 2),
          title: Text(
            isCompletion ? 'CAMPAIGN COMPLETED!' : 'STAGE VICTORIOUS',
            style: GoogleFonts.playfairDisplay(color: const Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCompletion
                    ? 'Incredible! You have conquered the final boss and completed the entire campaign setting! You are a master strategist.'
                    : 'You have vanquished the opposing forces. The road is clear for the next progression stage.',
                style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 12, height: 1.5),
                textAlign: TextAlign.center,
              ),
              if (!isCompletion) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monetization_on, color: Colors.yellow.shade800, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '+$reward COINS REWARDED',
                      style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            Center(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.yellow.shade800),
                  shape: const RoundedRectangleBorder(),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  if (isCompletion) {
                    // Delete campaign upon completion
                    ArenaSaveService.deleteSave(widget.progress.slot);
                    widget.onUpdate();
                    Navigator.pop(context); // Exit Campaign
                  } else {
                    setState(() {});
                    widget.onUpdate();
                  }
                },
                child: Text(
                  isCompletion ? 'COMPLETE CAMPAIGN' : 'COLLECT & CONTINUE',
                  style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 11),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDefeatPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D1712),
          shape: const RoundedRectangleBorder(side: BorderSide(color: Colors.redAccent)),
          title: Text(
            'DEFEAT',
            style: GoogleFonts.playfairDisplay(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Your hero fell in battle. Retrench your forces, purchase upgrades, adjust your deck composition, and try again!',
            style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 12, height: 1.5),
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: const RoundedRectangleBorder(),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('RETURN TO CAMP', style: GoogleFonts.playfairDisplay(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF15100B),
        title: Text(
          _campaign.campaignId.replaceAll('_', ' ').toUpperCase(),
          style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 15, letterSpacing: 2),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFC4B89B)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.yellow.shade800, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${_campaign.campaignCoins} COINS',
                  style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFF1D1712), // Deep mahogany
        child: Column(
          children: [
            // Tabs selector (Progress, DECK, Card Shop)
            Container(
              color: const Color(0xFF15100B),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['PROGRESS', 'LEADER', 'DECK', 'TOWERS', 'SHOP'].map((tab) {
                  final isSelected = _selectedTab == tab;
                  return InkWell(
                    onTap: () => setState(() => _selectedTab = tab),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected ? const Color(0xFFC4B89B) : Colors.transparent,
                            width: 2.0,
                          ),
                        ),
                      ),
                      child: Text(
                        tab,
                        style: GoogleFonts.playfairDisplay(
                          color: isSelected ? const Color(0xFFE5D5B0) : Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Tab Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildTabContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'LEADER':
        return _buildLeaderTab();
      case 'DECK':
        return _buildDeckTab();
      case 'TOWERS':
        return _buildTowersTab();
      case 'SHOP':
        return _buildShopTab();
      default:
        return _buildProgressTab();
    }
  }

  /// 1. Tab - Visual progressive stage maps
  Widget _buildProgressTab() {
    final opponentName = _getOpponentName();
    final isFinalBoss = _campaign.currentStage == 19;

    return Column(
      children: [
        // Opponent Card Details
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.black26,
            border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.25), width: 1),
          ),
          child: Row(
            children: [
              Icon(
                isFinalBoss ? Icons.gavel : Icons.security,
                color: isFinalBoss ? Colors.redAccent : const Color(0xFFC4B89B),
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STAGE ${_campaign.currentStage + 1} OF 20',
                      style: GoogleFonts.playfairDisplay(color: const Color(0xFFC4B89B), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opponentName.toUpperCase(),
                      style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isFinalBoss
                          ? 'This is the final battle. Conquering this legendary general completes the campaign setting.'
                          : 'A progressive adversary blockades the road ahead. Upgrade card stats to ensure victory.',
                      style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isFinalBoss ? Colors.redAccent : const Color(0xFFC4B89B)),
                  backgroundColor: Colors.black26,
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                onPressed: _launchBattle,
                child: Text(
                  isFinalBoss ? 'FIGHT BOSS' : 'LAUNCH BATTLE',
                  style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 20-Stage Progression Path timeline
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.black12,
              border: Border.all(color: Colors.white12, width: 1),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 20,
              itemBuilder: (context, index) {
                final isCurrent = _campaign.currentStage == index;
                final isCleared = _campaign.currentStage > index;
                return Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCurrent
                                  ? const Color(0xFFC4B89B).withValues(alpha: 0.2)
                                  : (isCleared ? Colors.black45 : Colors.transparent),
                              border: Border.all(
                                color: isCurrent
                                    ? const Color(0xFFC4B89B)
                                    : (isCleared ? Colors.green.shade800 : Colors.white24),
                                width: isCurrent ? 2.5 : 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.playfairDisplay(
                                  color: isCurrent
                                      ? Colors.white
                                      : (isCleared ? Colors.green.shade100 : Colors.white24),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            index == 19 ? 'BOSS' : 'STAGE',
                            style: GoogleFonts.playfairDisplay(
                              color: isCurrent ? const Color(0xFFC4B89B) : Colors.white24,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (index < 19)
                        Container(
                          width: 24,
                          height: 1.5,
                          color: isCleared ? Colors.green.shade800 : Colors.white12,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 2. Tab - Upgrade Card Stat Tiers
  Widget _buildDeckTab() {
    final deck = _campaign.playerDeckIds;
    
    return Column(
      children: [
        // Twelve spots grid
        SizedBox(
          height: 110,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.5,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final isOccupied = index < deck.length;
              final isSelected = _selectedDeckIndex == index;
              
              if (isOccupied) {
                final cardId = deck[index];
                final npc = CombatUnitService.createUnit(cardId);
                
                return InkWell(
                  onTap: () => setState(() => _selectedDeckIndex = index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF3E2C1E) : const Color(0xFF211B15),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFFC4B89B).withValues(alpha: 0.25),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CharacterBlobRenderer(npc: npc, size: 20, isCombat: true),
                        const SizedBox(height: 2),
                        Text(
                          npc.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.oldStandardTt(color: const Color(0xFFE5D5B0), fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return InkWell(
                  onTap: () => setState(() => _selectedDeckIndex = index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF15100B),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFD4AF37) : Colors.white12,
                        style: BorderStyle.solid,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'EMPTY SLOT',
                        style: GoogleFonts.oldStandardTt(color: Colors.white24, fontSize: 8),
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        const Divider(color: Color(0xFF352B24)),
        const SizedBox(height: 6),
        
        // Selected card detailed info and upgrades panel
        Expanded(
          child: _selectedDeckIndex < deck.length
              ? _buildSelectedDeckCardDetails(deck[_selectedDeckIndex])
              : Center(
                  child: Text(
                    'Empty Deck Slot. Recruit new units from the Card Shop to expand your deck.',
                    style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSelectedDeckCardDetails(String cardId) {
    final npc = CombatUnitService.createUnit(cardId);
    final stats = npc.combatStats!;
    
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.black26,
          border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  npc.name.toUpperCase(),
                  style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  npc.specimenType.toUpperCase(),
                  style: GoogleFonts.oldStandardTt(color: const Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Combat stats & training details. Upgrade attributes using campaign coins.',
              style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10),
            ),
            const SizedBox(height: 12),
            
            // Stats Table
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  children: [
                    _buildStatDetailCell('HEALTH (HP)', stats.health.toInt().toString()),
                    _buildStatDetailCell('ATTACK POWER', stats.attack.toInt().toString()),
                    _buildStatDetailCell('SPEED', '${stats.speed.toStringAsFixed(1)}x'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Upgrade buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildUpgradeButton(cardId, 'hp', 'HP (+15%)', Icons.favorite),
                _buildUpgradeButton(cardId, 'atk', 'ATK (+15%)', Icons.flash_on),
                _buildUpgradeButton(cardId, 'spd', 'SPD (+5%)', Icons.speed),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDetailCell(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.oldStandardTt(color: Colors.white30, fontSize: 8)),
          const SizedBox(height: 2),
          Text(val, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton(String cardId, String stat, String label, IconData icon) {
    final key = '${cardId}_$stat';
    final currentLvl = _campaign.cardUpgrades[key] ?? 0;
    final cost = 40 + currentLvl * 20; // Increasing upgrade costs
    final canAfford = _campaign.campaignCoins >= cost;

    return Column(
      children: [
        Text(
          'Lvl $currentLvl',
          style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 140,
          height: 32,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: canAfford ? const Color(0xFFC4B89B) : Colors.white10),
              backgroundColor: canAfford ? Colors.black26 : Colors.transparent,
              padding: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(),
            ),
            onPressed: canAfford
                ? () async {
                    _campaign.campaignCoins -= cost;
                    _campaign.cardUpgrades[key] = currentLvl + 1;
                    await ArenaSaveService.saveProgress(widget.progress);
                    setState(() {});
                    widget.onUpdate();
                  }
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 10, color: canAfford ? const Color(0xFFE5D5B0) : Colors.white24),
                const SizedBox(width: 4),
                Text(
                  '$label: $cost c',
                  style: GoogleFonts.playfairDisplay(
                    color: canAfford ? const Color(0xFFE5D5B0) : Colors.white24,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 3. Tab - Card Purchase Shop
  Widget _buildShopTab() {
    // Defined card pools to buy from
    final List<String> purchasePool = [
      'pikemen', 'marksmen', 'cavalry', 'cannoneer', 'musketeers', 'armored_car', 'gravedigger', 'caltrops'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PURCHASE ADDITIONAL CARDS',
          style: GoogleFonts.playfairDisplay(color: const Color(0xFFC4B89B), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: purchasePool.length,
            itemBuilder: (context, index) {
              final id = purchasePool[index];
              final sample = CombatUnitService.createUnit(id);
              final stats = sample.combatStats;
              final cost = 50 + (stats?.cost ?? 2) * 10; // Buy cost is proportional to AP cost
              final canAfford = _campaign.campaignCoins >= cost;

              return Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.style, color: Colors.yellow.shade800, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            sample.name.toUpperCase(),
                            style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cost: $cost coins',
                            style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 9.5),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: canAfford ? const Color(0xFFC4B89B) : Colors.white10),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: const RoundedRectangleBorder(),
                      ),
                      onPressed: canAfford
                          ? () async {
                              _campaign.campaignCoins -= cost;
                              _campaign.playerDeckIds.add(id);
                              await ArenaSaveService.saveProgress(widget.progress);
                              setState(() {});
                              widget.onUpdate();
                            }
                          : null,
                      child: Text(
                        'BUY',
                        style: GoogleFonts.playfairDisplay(
                          color: canAfford ? const Color(0xFFE5D5B0) : Colors.white24,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderTab() {
    final leader = _getPlayerLeader();
    
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                leader.name.toUpperCase(),
                style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              Text(
                leader.role.toUpperCase(),
                style: GoogleFonts.oldStandardTt(color: const Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Your chosen commander on the battlefield. Upgrade stats dynamically by spending campaign coins.",
            style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLeaderUpgradeButton('hp', 'HP (+15%)', Icons.favorite),
              _buildLeaderUpgradeButton('atk', 'ATK (+15%)', Icons.flash_on),
              _buildLeaderUpgradeButton('spd', 'SPD (+5%)', Icons.speed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderUpgradeButton(String stat, String label, IconData icon) {
    final key = 'leader_$stat';
    final currentLvl = _campaign.cardUpgrades[key] ?? 0;
    final cost = 50 + currentLvl * 25; // Slightly more expensive baseline for leader upgrades
    final canAfford = _campaign.campaignCoins >= cost;

    return Column(
      children: [
        Text(
          'Lvl $currentLvl',
          style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 140,
          height: 32,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: canAfford ? const Color(0xFFC4B89B) : Colors.white10),
              backgroundColor: canAfford ? Colors.black26 : Colors.transparent,
              padding: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(),
            ),
            onPressed: canAfford
                ? () async {
                    _campaign.campaignCoins -= cost;
                    _campaign.cardUpgrades[key] = currentLvl + 1;
                    await ArenaSaveService.saveProgress(widget.progress);
                    setState(() {});
                    widget.onUpdate();
                  }
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 10, color: canAfford ? const Color(0xFFE5D5B0) : Colors.white24),
                const SizedBox(width: 4),
                Text(
                  '$label: $cost c',
                  style: GoogleFonts.playfairDisplay(
                    color: canAfford ? const Color(0xFFE5D5B0) : Colors.white24,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTowersTab() {
    final hpLvl = _campaign.cardUpgrades['tower_hp'] ?? 0;
    final atkLvl = _campaign.cardUpgrades['tower_atk'] ?? 0;

    final rangeUnlocked = hpLvl >= 3 && atkLvl >= 3;
    final speedUnlocked = hpLvl >= 6 && atkLvl >= 6;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DEFENSIVE TOWERS',
            style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 6),
          Text(
            "Upgrade your covered wagons' defensive capabilities. High-tier modifications (Range, Rate of Fire) require standard reinforcing upgrades first.",
            style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTowerUpgradeButton('hp', 'HEALTH (+15%)', Icons.shield, 40, 20, true, ""),
              _buildTowerUpgradeButton('atk', 'DAMAGE (+15%)', Icons.local_fire_department, 40, 20, true, ""),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTowerUpgradeButton(
                'range', 
                'RANGE (+2.5)', 
                Icons.gps_fixed, 
                120, 
                50, 
                rangeUnlocked, 
                "Req: Health & Damage Lvl 3",
              ),
              _buildTowerUpgradeButton(
                'speed', 
                'RATE OF FIRE (+10%)', 
                Icons.flash_on, 
                200, 
                80, 
                speedUnlocked, 
                "Req: Health & Damage Lvl 6",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTowerUpgradeButton(
    String stat, 
    String label, 
    IconData icon, 
    int baseCost, 
    int costMultiplier, 
    bool isUnlocked, 
    String reqMessage,
  ) {
    final key = 'tower_$stat';
    final currentLvl = _campaign.cardUpgrades[key] ?? 0;
    final cost = baseCost + currentLvl * costMultiplier;
    final canAfford = _campaign.campaignCoins >= cost && isUnlocked;

    return Column(
      children: [
        Text(
          'Lvl $currentLvl',
          style: GoogleFonts.oldStandardTt(
            color: isUnlocked ? Colors.white70 : Colors.white24,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 175,
          height: 36,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: canAfford 
                    ? const Color(0xFFC4B89B) 
                    : (isUnlocked ? Colors.white10 : Colors.redAccent.withValues(alpha: 0.15)),
              ),
              backgroundColor: canAfford ? Colors.black26 : Colors.transparent,
              padding: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(),
            ),
            onPressed: canAfford
                ? () async {
                    _campaign.campaignCoins -= cost;
                    _campaign.cardUpgrades[key] = currentLvl + 1;
                    await ArenaSaveService.saveProgress(widget.progress);
                    setState(() {});
                    widget.onUpdate();
                  }
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 10, color: canAfford ? const Color(0xFFE5D5B0) : Colors.white24),
                    const SizedBox(width: 4),
                    Text(
                      isUnlocked ? '$label: $cost c' : 'LOCKED',
                      style: GoogleFonts.playfairDisplay(
                        color: canAfford ? const Color(0xFFE5D5B0) : Colors.white24,
                        fontSize: 9.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (!isUnlocked) ...[
                  const SizedBox(height: 2),
                  Text(
                    reqMessage,
                    style: GoogleFonts.oldStandardTt(
                      color: Colors.redAccent.withValues(alpha: 0.8),
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
