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

import '../models/game_item.dart';
import '../models/npc.dart';
import 'recipe_catalogue.dart';

class Recipe {
  final String id;
  final String name;
  final Map<String, num> ingredients;
  final double sophistication;
  final int yield;
  final double baseQuality;
  final int durationMinutes;
  final bool isExperimental;

  final int minKnifeSkills;
  final int minFireSkills;

  Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    this.sophistication = 1.0,
    this.yield = 1,
    this.baseQuality = 1.0,
    required this.durationMinutes,
    this.isExperimental = false,
    this.minKnifeSkills = 0,
    this.minFireSkills = 0,
  });
}

class KitchenService {
  static List<Recipe> getAvailableRecipes() {
    return RecipeCatalogue.allRecipes;
  }

  static int _getTraitModifier(int traitValue) {
    switch (traitValue) {
      case 0: return -10;
      case 1: return -6;
      case 2: return -4;
      case 3: return -2;
      case 4: return -1;
      case 5: return 0;
      case 6: return 1;
      case 7: return 2;
      case 8: return 3;
      case 9: return 4;
      case 10: return 5;
      default: return traitValue > 10 ? 5 : -10;
    }
  }

  static int _getQualityModifier(ItemQuality quality) {
    switch (quality) {
      case ItemQuality.awful: return -8;
      case ItemQuality.weak: return -5;
      case ItemQuality.substandard: return -3;
      case ItemQuality.fair: return -1;
      case ItemQuality.common: return 0;
      case ItemQuality.quality: return 1;
      case ItemQuality.precious: return 2;
      case ItemQuality.excellent: return 3;
      case ItemQuality.supreme: return 5;
    }
  }

  static int calculateExperimentScore(NPC npc, List<GameItem> usedIngredients, int d100Roll) {
    int perceptionMod = _getTraitModifier(npc.stats['perception'] ?? 5);
    int judgmentMod = _getTraitModifier(npc.stats['judgment'] ?? 5);
    int dexterityMod = _getTraitModifier(npc.stats['dexterity'] ?? 5);

    int qualitySum = 0;
    for (var item in usedIngredients) {
      qualitySum += _getQualityModifier(item.displayQuality);
    }
    // If they use fewer ingredients, should average instead? RecipeDiscovery allows 2-4.
    // Let's use average rounded to integer so that penalities don't multiply just from having more ingredients.
    int qualityMod = usedIngredients.isNotEmpty ? (qualitySum / usedIngredients.length).round() : 0;

    int score = d100Roll + perceptionMod + judgmentMod + dexterityMod + qualityMod;
    return score.clamp(0, 100);
  }

  static Recipe? performRecipeDiscovery(List<GameItem> usedIngredients, int score) {
    if (score < 26) { return null; } // Failure

    double minSophistication = 0.0;
    double maxSophistication = 2.0;
    if (score >= 98) {
      minSophistication = 4.01; maxSophistication = 5.0; // Exquisite
    } else if (score >= 76) {
      minSophistication = 3.01; maxSophistication = 4.0; // High
    } else if (score >= 51) {
      minSophistication = 2.01; maxSophistication = 3.0; // Standard
    }

    Set<String> inputDict = usedIngredients.map((i) => i.type).toSet();

    List<Recipe> matchingRecipes = getAvailableRecipes().where((r) {
      if (r.id == 'butcher_generic') { return false; }
      if (r.sophistication < minSophistication || r.sophistication > maxSophistication) { return false; }

      // Ensure at least 2 ingredients in common
      int commonCount = 0;
      int extraCount = 0;
      for (var expectedType in r.ingredients.keys) {
        if (expectedType == 'meat' && (inputDict.contains('meat_chicken') || inputDict.contains('meat_beef') || inputDict.contains('meat_pork'))) {
            // loose matching
            commonCount++;
        } else if (inputDict.contains(expectedType)) {
          commonCount++;
        } else {
          extraCount++;
        }
      }
      return commonCount >= 2 && extraCount <= 2;
    }).toList();

    if (matchingRecipes.isEmpty) { return null; } // Failed to find any match, wasted

    // Calculate match weights, preferring closer overlap
    List<MapEntry<Recipe, int>> weightedCandidates = [];
    int totalWeight = 0;

    for (var r in matchingRecipes) {
      int commonCount = 0;
      for (var k in r.ingredients.keys) {
        if (inputDict.contains(k) || (k == 'meat' && inputDict.any((type) => type.startsWith('meat')))) {
          commonCount++;
        }
      }
      // Weight increases dramatically with overlap
      int weight = commonCount * commonCount; 
      weightedCandidates.add(MapEntry(r, weight));
      totalWeight += weight;
    }

    weightedCandidates.sort((a, b) => b.value.compareTo(a.value));

    // Determine the lower and upper bounds of this tier's score
    int tierMin = 26; int tierMax = 50;
    if (score >= 98) { tierMin = 98; tierMax = 100; }
    else if (score >= 76) { tierMin = 76; tierMax = 97; }
    else if (score >= 51) { tierMin = 51; tierMax = 75; }

    int rangeSize = (tierMax - tierMin) + 1;
    
    // Distribute score segments based on weight proportion
    int currentLimit = tierMin;
    for (int i = 0; i < weightedCandidates.length; i++) {
        var entry = weightedCandidates[i];
        if (i == weightedCandidates.length - 1) {
            // Last one gets the rest
            if (score <= tierMax) { return entry.key; }
        } else {
            int proportion = ((entry.value / totalWeight) * rangeSize).round();
            if (proportion < 1) { proportion = 1; } // Minimum width of 1 segment
            currentLimit += proportion;
            if (score < currentLimit) { return entry.key; }
        }
    }

    return weightedCandidates.last.key;
  }
}
