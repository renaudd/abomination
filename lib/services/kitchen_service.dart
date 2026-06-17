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
  final String? unlockFaction;

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
    this.unlockFaction,
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

    final names = usedIngredients.map((i) => i.name.toLowerCase()).toList();
    final types = usedIngredients.map((i) => i.type.toLowerCase()).toList();

    bool has(String term) => names.any((n) => n.contains(term)) || types.any((t) => t.contains(term));

    final recipes = getAvailableRecipes();
    Recipe? find(String id) => recipes.cast<Recipe?>().firstWhere((r) => r?.id == id, orElse: () => null);

    // Pizza Margherita: bread_dough + tomato_sauce + cheese
    if ((has('bread_dough') || has('bread dough') || has('dough')) && (has('tomato_sauce') || has('tomato sauce') || has('tomato')) && has('cheese')) {
      final r = find('pizza_margherita');
      if (r != null) return r;
    }
    
    // Lasagna al Forno: sheet_pasta + tomato_sauce + seared_beef + cheese
    if ((has('sheet_pasta') || has('sheet pasta') || has('pasta')) && (has('tomato_sauce') || has('tomato sauce') || has('tomato')) && (has('seared_beef') || has('beef') || has('meat')) && has('cheese')) {
      final r = find('lasagna_al_forno');
      if (r != null) return r;
    }

    // Pasta Genovese: sheet_pasta + genovese_sauce
    if ((has('sheet_pasta') || has('sheet pasta') || has('pasta')) && (has('genovese_sauce') || has('genovese sauce') || has('ragu') || has('genovese'))) {
      final r = find('pasta_genovese');
      if (r != null) return r;
    }

    // Spaghetti Carbonara: sheet_pasta + pork + eggs + cheese
    if ((has('sheet_pasta') || has('sheet pasta') || has('pasta')) && (has('bacon') || has('pork') || has('guanciale') || has('meat_pork')) && (has('egg') || has('eggs')) && has('cheese')) {
      final r = find('spaghetti_carbonara');
      if (r != null) return r;
    }

    // Spaghetti al Pomodoro: sheet_pasta + tomato_sauce
    if ((has('sheet_pasta') || has('sheet pasta') || has('pasta')) && (has('tomato_sauce') || has('tomato sauce') || has('tomato'))) {
      final r = find('spaghetti_pomodoro');
      if (r != null) return r;
    }

    // Apple Strudel: baked_apple_comp + sweet_pastry_dough
    if ((has('baked_apple_comp') || has('apple')) && (has('sweet_pastry_dough') || has('dough') || has('pastry'))) {
      final r = find('apple_strudel');
      if (r != null) return r;
    }

    // Pain au Chocolat: sweet_pastry_dough + chocolate
    if ((has('sweet_pastry_dough') || has('dough') || has('pastry')) && (has('chocolate') || has('dark_chocolate'))) {
      final r = find('pain_au_chocolat');
      if (r != null) return r;
    }

    // Gourmet Cheeseburger: bread_dough + seared_beef + cheese
    if ((has('bread_dough') || has('dough')) && (has('seared_beef') || has('beef') || has('meat')) && has('cheese')) {
      final r = find('gourmet_cheeseburger');
      if (r != null) return r;
    }

    // Spiced Warm Cider: cider + cinnamon + sugar
    if (has('cider') && (has('cinnamon') || has('spice')) && (has('sugar') || has('honey'))) {
      final r = find('spiced_warm_cider');
      if (r != null) return r;
    }

    final random = Random();

    // 7. Pasta Carbonara Unlock
    // pasta + bacon + eggs + cheese
    if (has('pasta') && (has('bacon') || has('pork') || has('guanciale')) && (has('egg') || has('eggs')) && (has('cheese') || has('pecorino'))) {
      return Recipe(
        id: 'pasta_carbonara',
        name: 'Pasta Carbonara',
        ingredients: {'pasta': 1, 'bacon': 1, 'eggs': 1, 'cheese': 1},
        sophistication: 8.5,
        yield: 4,
        baseQuality: 0.95,
        durationMinutes: 45,
        minKnifeSkills: 15,
        minFireSkills: 20,
        unlockFaction: 'Carbonari',
      );
    }

    // 10. Pasta Sauces
    // Genovese: onion + beef + pork + white wine
    if (has('onion') && has('beef') && has('pork') && (has('wine') || has('white wine'))) {
      return Recipe(
        id: 'sauce_genovese',
        name: 'Genovese Ragu',
        ingredients: {'onion': 1, 'beef': 1, 'pork': 1, 'wine': 1},
        sophistication: 7.0,
        yield: 4,
        baseQuality: 0.9,
        durationMinutes: 120,
        minKnifeSkills: 15,
        minFireSkills: 25,
      );
    }

    // Pesto Genovese: basil + pine nuts + hard cheese + garlic
    if (has('basil') && (has('pine nut') || has('nut')) && has('cheese') && has('garlic')) {
      return Recipe(
        id: 'sauce_pesto',
        name: 'Pesto Genovese',
        ingredients: {'basil': 1, 'pine_nuts': 1, 'cheese': 1, 'garlic': 1},
        sophistication: 6.5,
        yield: 4,
        baseQuality: 0.9,
        durationMinutes: 30,
        minKnifeSkills: 20,
        minFireSkills: 5,
      );
    }

    // Puttanesca: Tomato + Anchovy + Capers + Olives
    if (has('tomato') && (has('anchovy') || has('fish')) && has('caper') && has('olive')) {
      return Recipe(
        id: 'sauce_puttanesca',
        name: 'Sugo alla Puttanesca',
        ingredients: {'tomato': 1, 'anchovy': 1, 'capers': 1, 'olives': 1},
        sophistication: 6.8,
        yield: 4,
        baseQuality: 0.9,
        durationMinutes: 45,
        minKnifeSkills: 15,
        minFireSkills: 20,
      );
    }

    // 9. Sheet Pasta Derived Pastas
    if (has('sheet pasta') || has('sheet_pasta')) {
      // Used to create Advanced Filled Dishes: Lasagna, Ravioli, Tortellini
      // if used together with cheese, spinach, tomato, and/or meat
      if (has('cheese') || has('spinach') || has('tomato') || has('meat') || has('beef') || has('pork')) {
        final filledDishes = [
          Recipe(id: 'lasagna', name: 'Lasagna al Forno', ingredients: {'sheet_pasta': 1, 'meat': 1, 'cheese': 1}, sophistication: 7.5, yield: 6, baseQuality: 0.95, durationMinutes: 90, minKnifeSkills: 15, minFireSkills: 25),
          Recipe(id: 'ravioli', name: 'Spinach & Ricotta Ravioli', ingredients: {'sheet_pasta': 1, 'spinach': 1, 'cheese': 1}, sophistication: 7.8, yield: 4, baseQuality: 0.95, durationMinutes: 60, minKnifeSkills: 20, minFireSkills: 20),
          Recipe(id: 'tortellini', name: 'Tortellini in Brodo', ingredients: {'sheet_pasta': 1, 'meat': 1, 'cheese': 1}, sophistication: 8.2, yield: 4, baseQuality: 0.95, durationMinutes: 75, minKnifeSkills: 25, minFireSkills: 20),
        ];
        return filledDishes[random.nextInt(filledDishes.length)];
      }

      // If sheet pasta is used on its own (or with negligible items),
      // create one of those six pastas with ascending order of rarity:
      // fettuccine, linguine, pappardelle, tagliatelle, mafaldine, farfalle
      final roll = random.nextDouble();
      String pId = 'pasta_fettuccine';
      String pName = 'Fettuccine';
      double soph = 4.0;

      if (roll < 0.25) { pId = 'pasta_fettuccine'; pName = 'Fettuccine'; soph = 4.0; }
      else if (roll < 0.48) { pId = 'pasta_linguine'; pName = 'Linguine'; soph = 4.3; }
      else if (roll < 0.68) { pId = 'pasta_pappardelle'; pName = 'Pappardelle'; soph = 4.6; }
      else if (roll < 0.85) { pId = 'pasta_tagliatelle'; pName = 'Tagliatelle'; soph = 5.0; }
      else if (roll < 0.95) { pId = 'pasta_mafaldine'; pName = 'Mafaldine'; soph = 5.5; }
      else { pId = 'pasta_farfalle'; pName = 'Farfalle'; soph = 6.0; }

      return Recipe(
        id: pId,
        name: pName,
        ingredients: {'sheet_pasta': 1},
        sophistication: soph,
        yield: 4,
        baseQuality: 0.9,
        durationMinutes: 30,
        minKnifeSkills: (soph * 3).round(),
        minFireSkills: 10,
      );
    }

    // 8. Wheat Flour Derived Pasta
    if ((has('flour') || has('wheat')) && usedIngredients.length <= 2) {
      if (random.nextDouble() < 0.75) { // High chance
        return Recipe(
          id: 'sheet_pasta',
          name: 'Sheet Pasta',
          ingredients: {'flour': 1, 'eggs': 1},
          sophistication: 3.5,
          yield: 4,
          baseQuality: 0.9,
          durationMinutes: 40,
          minKnifeSkills: 10,
          minFireSkills: 10,
        );
      }
    }

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
