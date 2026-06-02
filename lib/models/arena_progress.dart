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
import '../services/combat_unit_service.dart';
import '../models/npc.dart';
import 'survival_state.dart';

class CampaignProgress {
  final String campaignId;
  int currentStage; // 0 to 19 (20 progressive opponents)
  List<String> playerDeckIds; // card types in player's campaign deck
  Map<String, int> cardUpgrades; // HP, ATK, SPD levels per card type, e.g. {'cavalry_hp': 2}
  int campaignCoins;
  String playerLeaderId; // Selected player leader character, defaults to 'alphonse'

  CampaignProgress({
    required this.campaignId,
    this.currentStage = 0,
    required this.playerDeckIds,
    required this.cardUpgrades,
    this.campaignCoins = 0,
    this.playerLeaderId = 'alphonse',
  });

  Map<String, dynamic> toJson() => {
        'campaignId': campaignId,
        'currentStage': currentStage,
        'playerDeckIds': playerDeckIds,
        'cardUpgrades': cardUpgrades,
        'campaignCoins': campaignCoins,
        'playerLeaderId': playerLeaderId,
      };

  factory CampaignProgress.fromJson(Map<String, dynamic> json) => CampaignProgress(
        campaignId: json['campaignId'] as String,
        currentStage: json['currentStage'] as int? ?? 0,
        playerDeckIds: List<String>.from(json['playerDeckIds'] as List),
        cardUpgrades: Map<String, int>.from(json['cardUpgrades'] as Map),
        campaignCoins: json['campaignCoins'] as int? ?? 0,
        playerLeaderId: json['playerLeaderId'] as String? ?? 'alphonse',
      );
}

class TournamentMatch {
  final int round; // 1 to 5
  final String p1;
  final String p2;
  String? winner;

  TournamentMatch({
    required this.round,
    required this.p1,
    required this.p2,
    this.winner,
  });

  Map<String, dynamic> toJson() => {
        'round': round,
        'p1': p1,
        'p2': p2,
        'winner': winner,
      };

  factory TournamentMatch.fromJson(Map<String, dynamic> json) => TournamentMatch(
        round: json['round'] as int,
        p1: json['p1'] as String,
        p2: json['p2'] as String,
        winner: json['winner'] as String?,
      );
}

class TournamentProgress {
  List<String> playerDeckIds;
  int currentRound; // 1 (Round of 32) to 5 (Finals)
  List<String> participants; // 32 names (Index 0 is always 'Player')
  Map<String, List<String>> participantDecks; // Deck card types for each participant
  List<TournamentMatch> matches; // Complete history of matches in all rounds
  bool isEliminated;
  String playerLeaderId; // Selected player leader character, defaults to 'alphonse'

  TournamentProgress({
    required this.playerDeckIds,
    this.currentRound = 1,
    required this.participants,
    required this.participantDecks,
    required this.matches,
    this.isEliminated = false,
    this.playerLeaderId = 'alphonse',
  });

  Map<String, dynamic> toJson() => {
        'playerDeckIds': playerDeckIds,
        'currentRound': currentRound,
        'participants': participants,
        'participantDecks': participantDecks,
        'matches': matches.map((m) => m.toJson()).toList(),
        'isEliminated': isEliminated,
        'playerLeaderId': playerLeaderId,
      };

  factory TournamentProgress.fromJson(Map<String, dynamic> json) => TournamentProgress(
        playerDeckIds: List<String>.from(json['playerDeckIds'] as List),
        currentRound: json['currentRound'] as int? ?? 1,
        participants: List<String>.from(json['participants'] as List),
        participantDecks: (json['participantDecks'] as Map).map(
          (key, value) => MapEntry(key as String, List<String>.from(value as List)),
        ),
        matches: (json['matches'] as List)
            .map((m) => TournamentMatch.fromJson(m as Map<String, dynamic>))
            .toList(),
        isEliminated: json['isEliminated'] as bool? ?? false,
        playerLeaderId: json['playerLeaderId'] as String? ?? 'alphonse',
      );

  /// Formulaic evaluator for deck power based on stats, median casting cost, and melee/ranged balance.
  static double calculateDeckRating(List<String> deckIds) {
    if (deckIds.isEmpty) return 50.0;

    double rating = 50.0;

    // Load actual NPC objects to inspect their stats and roles
    final List<NPC> units = deckIds.map((id) => CombatUnitService.createUnit(id)).toList();

    // 1. Average attack/health/tier power
    double statSum = 0.0;
    for (var u in units) {
      final stats = u.combatStats;
      if (stats != null) {
        statSum += (stats.maxHealth / 10.0) + stats.attack + (stats.meleeDamage + stats.rangedDamage);
      }
    }
    final avgStats = statSum / units.length;
    rating += avgStats * 0.4; // Weight stats

    // 2. Median Card Casting Cost
    final costs = units.map((u) => u.combatStats?.cost ?? 0).toList()..sort();
    double medianCost = 0.0;
    if (costs.isNotEmpty) {
      if (costs.length % 2 == 1) {
        medianCost = costs[costs.length ~/ 2].toDouble();
      } else {
        medianCost = (costs[costs.length ~/ 2 - 1] + costs[costs.length ~/ 2]) / 2.0;
      }
    }
    // Optimal median cost is around 3.5 AP. Let's penalize deviation from 3.5 AP.
    final costDeviation = (medianCost - 3.5).abs();
    rating -= costDeviation * 8.0; // Subtract penalty for poor AP curve

    // 3. Balance of Ranged vs Melee
    int meleeCount = 0;
    int rangedCount = 0;
    for (var u in units) {
      final stats = u.combatStats;
      if (stats != null) {
        final hasMelee = stats.meleeDamage > 5;
        final hasRanged = stats.rangedDamage > 5 && stats.rangedRange > 2.0;
        if (hasRanged) {
          rangedCount++;
        } else if (hasMelee) {
          meleeCount++;
        }
      }
    }
    final totalTyped = meleeCount + rangedCount;
    if (totalTyped > 0) {
      final double meleeRatio = meleeCount / totalTyped;
      // Optimal ratio is around 50% (between 30% and 70% is balanced)
      if (meleeRatio < 0.3 || meleeRatio > 0.7) {
        rating -= 15.0; // Penalty for pure melee or pure ranged decks
      } else {
        rating += 10.0; // Bonus for balanced composition
      }
    }

    return rating.clamp(10.0, 150.0);
  }

  /// Evaluates NPC vs NPC matches formulaically based on rating.
  String resolveNpcMatch(String p1, String p2) {
    final deck1 = participantDecks[p1] ?? [];
    final deck2 = participantDecks[p2] ?? [];

    final rating1 = calculateDeckRating(deck1);
    final rating2 = calculateDeckRating(deck2);

    final prob1 = rating1 / (rating1 + rating2);
    final roll = Random().nextDouble();

    return roll < prob1 ? p1 : p2;
  }
}

class ArenaProgress {
  final int slot;
  DateTime saveTime;
  CampaignProgress? campaign;
  TournamentProgress? tournament;
  SurvivalProgress? survival;

  ArenaProgress({
    required this.slot,
    required this.saveTime,
    this.campaign,
    this.tournament,
    this.survival,
  });

  Map<String, dynamic> toJson() => {
        'slot': slot,
        'saveTime': saveTime.toIso8601String(),
        'campaign': campaign?.toJson(),
        'tournament': tournament?.toJson(),
        'survival': survival?.toJson(),
      };

  factory ArenaProgress.fromJson(Map<String, dynamic> json) => ArenaProgress(
        slot: json['slot'] as int,
        saveTime: DateTime.parse(json['saveTime'] as String),
        campaign: json['campaign'] != null
            ? CampaignProgress.fromJson(json['campaign'] as Map<String, dynamic>)
            : null,
        tournament: json['tournament'] != null
            ? TournamentProgress.fromJson(json['tournament'] as Map<String, dynamic>)
            : null,
        survival: json['survival'] != null
            ? SurvivalProgress.fromJson(json['survival'] as Map<String, dynamic>)
            : null,
      );
}
