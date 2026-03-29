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

class Recipe {
  final String id;
  final String name;
  final Map<String, num> inputs;
  final Map<String, num> outputs;
  final int requiredLevel;
  final String description;

  Recipe({
    required this.id,
    required this.name,
    required this.inputs,
    required this.outputs,
    this.requiredLevel = 1,
    required this.description,
  });

  static List<Recipe> getBrewingRecipes() {
    return [
      Recipe(
        id: 'small_beer',
        name: 'Small Beer',
        inputs: {'grain': 2},
        outputs: {'ale': 1},
        requiredLevel: 1,
        description: "A weak but safe beer for daily consumption.",
      ),
      Recipe(
        id: 'golden_ale',
        name: 'Golden Mountain Ale',
        inputs: {'grain': 4},
        outputs: {'ale': 3},
        requiredLevel: 3,
        description: "A rich, flavorful ale favored by the local cantons.",
      ),
    ];
  }

  static List<Recipe> getDistillingRecipes() {
    return [
      Recipe(
        id: 'clear_spirits',
        name: 'Clear Spirits',
        inputs: {'ale': 2},
        outputs: {'spirits': 1},
        requiredLevel: 1,
        description: "Rough spirits distilled from common ale.",
      ),
      Recipe(
        id: 'barrel_aged_brandy',
        name: 'Barrel-Aged Brandy',
        inputs: {'ale': 3, 'timber': 1},
        outputs: {'spirits': 2},
        requiredLevel: 5,
        description: "Potent brandy aged with refined timber.",
      ),
    ];
  }
}
