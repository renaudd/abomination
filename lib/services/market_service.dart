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
  };

  int getBuyPrice(String resource) => _baseBuyPrices[resource] ?? 999;
  int getSellPrice(String resource) => _baseSellPrices[resource] ?? 0;

  // Future: Dynamic price fluctuations based on war events or canton mood
}
