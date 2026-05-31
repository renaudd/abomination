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

import 'package:flutter_test/flutter_test.dart';
import 'package:abomination/models/arena_progress.dart';

void main() {
  group('Arena Mode Progress and Rating Formula Tests', () {
    test('CampaignProgress JSON Serialization/Deserialization', () {
      final campaign = CampaignProgress(
        campaignId: 'alpine_uprising',
        currentStage: 3,
        playerDeckIds: ['militia', 'pikemen'],
        cardUpgrades: {'militia_hp': 2, 'pikemen_atk': 1},
        campaignCoins: 120,
      );

      final json = campaign.toJson();
      expect(json['campaignId'], 'alpine_uprising');
      expect(json['currentStage'], 3);
      expect(json['campaignCoins'], 120);

      final decoded = CampaignProgress.fromJson(json);
      expect(decoded.campaignId, 'alpine_uprising');
      expect(decoded.currentStage, 3);
      expect(decoded.campaignCoins, 120);
      expect(decoded.playerDeckIds, contains('militia'));
      expect(decoded.cardUpgrades['militia_hp'], 2);
    });

    test('TournamentProgress Bracket and NPC vs NPC Match Resolution', () {
      final tournament = TournamentProgress(
        playerDeckIds: ['militia', 'pikemen'],
        currentRound: 1,
        participants: ['Player', 'Opponent A', 'Opponent B'],
        participantDecks: {
          'Player': ['militia', 'pikemen'],
          'Opponent A': ['cavalry', 'musketeers'],
          'Opponent B': ['rats_unit', 'bats_unit'],
        },
        matches: [
          TournamentMatch(round: 1, p1: 'Opponent A', p2: 'Opponent B'),
        ],
      );

      // Resolve the NPC match formulaically
      final match = tournament.matches.first;
      final winner = tournament.resolveNpcMatch(match.p1, match.p2);
      expect(winner == 'Opponent A' || winner == 'Opponent B', isTrue);
      
      match.winner = winner;
      expect(match.winner, isNotNull);
    });

    test('Deck Rating Formula Factors in AP Cost and Ranged-Melee Balance', () {
      // Balanced deck (cavalry is melee, musketeers is ranged)
      final balancedDeck = ['cavalry', 'musketeers', 'pikemen', 'marksmen'];
      // Extremely unbalanced pure melee deck
      final pureMeleeDeck = ['cavalry', 'cavalry', 'samurai', 'samurai'];

      final ratingBalanced = TournamentProgress.calculateDeckRating(balancedDeck);
      final ratingPureMelee = TournamentProgress.calculateDeckRating(pureMeleeDeck);

      // A balanced deck should be rewarded or have fewer penalties than a highly unbalanced pure melee deck
      expect(ratingBalanced, greaterThan(ratingPureMelee));
    });
  });
}
