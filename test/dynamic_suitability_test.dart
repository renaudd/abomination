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
import 'package:abomination/models/npc.dart';
import 'package:abomination/state/game_state.dart';
import 'package:abomination/services/task_service.dart';

void main() {
  group('Dynamic Work Suitability and Task Efficiency Tests', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
      gameState.initializeNewGame(
        firstName: "Victor",
        lastName: "Frankenstein",
        estateName: "Frankenstein Manor",
        deathCause: DeathCause.trainCrash,
        age: 30,
        gilesTrait: GilesTrait.sage,
        objective: LifeObjective.science,
      );
    });

    test('Research efficiency changes dynamically based on character intellect', () {
      final player = gameState.npcs.firstWhere((n) => n.id == 'player');

      // 1. High Intellect Scenario
      final highIntellectStats = Map<String, int>.from(player.stats);
      highIntellectStats['intellect'] = 10;
      highIntellectStats['perception'] = 5;
      highIntellectStats['judgment'] = 5;
      
      final playerHighIntel = player.copyWith(stats: highIntellectStats);
      final highIntelEfficiency = gameState.getTaskEfficiency(playerHighIntel, TaskType.research);
      
      // 2. Low Intellect Scenario
      final lowIntellectStats = Map<String, int>.from(player.stats);
      lowIntellectStats['intellect'] = 1;
      lowIntellectStats['perception'] = 2;
      lowIntellectStats['judgment'] = 2;

      final playerLowIntel = player.copyWith(stats: lowIntellectStats);
      final lowIntelEfficiency = gameState.getTaskEfficiency(playerLowIntel, TaskType.research);

      // Verify that high intellect yields higher research efficiency than low intellect
      expect(highIntelEfficiency, greaterThan(lowIntelEfficiency));
      
      // Low intellect should result in efficiency < 1.0 (inefficient)
      expect(lowIntelEfficiency, lessThan(1.0));
      
      // High intellect should result in efficiency > 1.0 (highly suitable)
      expect(highIntelEfficiency, greaterThan(1.0));
    });

    test('Efficiency scales with character task-relevant proficiency levels', () {
      final player = gameState.npcs.firstWhere((n) => n.id == 'player');

      // Setup same base attributes to isolate the proficiency effect
      final baseStats = Map<String, int>.from(player.stats);
      baseStats['intellect'] = 5;
      baseStats['perception'] = 5;
      baseStats['judgment'] = 5;

      // 1. Level 0 Research
      final playerLevel0 = player.copyWith(
        stats: baseStats,
        metadata: {'proficiency_level_Research': 0},
      );
      final effLevel0 = gameState.getTaskEfficiency(playerLevel0, TaskType.research);

      // 2. Level 5 Research (should have +25% bonus)
      final playerLevel5 = player.copyWith(
        stats: baseStats,
        metadata: {'proficiency_level_Research': 5},
      );
      final effLevel5 = gameState.getTaskEfficiency(playerLevel5, TaskType.research);

      // 3. Level 10 Research (should have +50% bonus)
      final playerLevel10 = player.copyWith(
        stats: baseStats,
        metadata: {'proficiency_level_Research': 10},
      );
      final effLevel10 = gameState.getTaskEfficiency(playerLevel10, TaskType.research);

      expect(effLevel5, greaterThan(effLevel0));
      expect(effLevel10, greaterThan(effLevel5));

      // Assert precise scaling (+5% per level)
      expect(effLevel5, closeTo(effLevel0 * 1.25, 0.001));
      expect(effLevel10, closeTo(effLevel0 * 1.50, 0.001));
    });
  });
}
