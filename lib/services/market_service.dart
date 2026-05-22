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

class MarketService {
  static const Map<String, int> _baseBuyPrices = {
    'wood': 5,
    'meat': 8,
    'eggs': 2,
    'cabbage': 3,
    'grain': 4,
    'ale': 15,
    'spirits': 45,
    'timber': 25,
    'rooster': 50,
    'fertilizer': 10,
    'salt': 2,
    'potato': 3,
    'carrots': 3,
    'beets': 3,
    'seeds_cabbage': 5,
    'seeds_potato': 5,
    'seeds_carrot': 5,
    'seeds_cannabis': 15,
    'seeds_tobacco': 15,
    'mushroom_spores': 15,
    'poem': 60,
    'novel': 500,
    'unreviewed_document': 40,
    'old_notes': 50,
    'research_notes': 60,
    'rat': 10,
    'bat': 12,
    'chicken': 30,
    'herb_reagent': 25,
    'cannabis_buds': 80,
    'tobacco_leaves': 60,
    'hallucinogenic_mushrooms': 100,
    'hemp_fiber': 30,
  };

  static const Map<String, int> _baseSellPrices = {
    'wood': 3,
    'meat': 5,
    'eggs': 1,
    'cabbage': 2,
    'grain': 2,
    'ale': 10,
    'spirits': 30,
    'timber': 15,
    'rooster': 30,
    'fertilizer': 6,
    'salt': 1,
    'potato': 2,
    'carrots': 2,
    'beets': 2,
    'seeds_cabbage': 3,
    'seeds_potato': 3,
    'seeds_carrot': 3,
    'seeds_cannabis': 8,
    'seeds_tobacco': 8,
    'mushroom_spores': 8,
    'poem': 30,
    'novel': 250,
    'unreviewed_document': 20,
    'old_notes': 25,
    'research_notes': 35,
    'rat': 5,
    'bat': 6,
    'chicken': 15,
    'herb_reagent': 12,
    'cannabis_buds': 40,
    'tobacco_leaves': 30,
    'hallucinogenic_mushrooms': 50,
    'hemp_fiber': 15,
  };

  int getBuyPrice(String resource) => _baseBuyPrices[resource] ?? 999;
  int getSellPrice(String resource) => _baseSellPrices[resource] ?? 0;

  // Future: Dynamic price fluctuations based on war events or canton mood
}
