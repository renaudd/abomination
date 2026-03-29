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
import 'dish.dart';

const List<String> _possibleFavorites = [
  'Beef & Root Stew',
  'Spelt Bread',
  'raw green_beans',
  'raw faba_beans',
  'raw carrots',
  'raw cabbage',
];

class NPCDiet {
  final Map<DishType, int> dailyRequirements;
  final DishQuality minimumQuality;
  final List<String> favoriteFoods;

  NPCDiet({
    required this.dailyRequirements,
    this.minimumQuality = DishQuality.decent,
    this.favoriteFoods = const [],
  });

  factory NPCDiet.defaultDiet() {
    final random = Random();
    final favCount = 1 + random.nextInt(2);
    final shuffled = List<String>.from(_possibleFavorites)..shuffle(random);

    return NPCDiet(
      dailyRequirements: {
        DishType.cereal: 1,
        DishType.protein: 1,
        DishType.vegetable: 1,
      },
      minimumQuality: DishQuality.decent,
      favoriteFoods: shuffled.take(favCount).toList(),
    );
  }

  factory NPCDiet.scientistDiet() {
    final random = Random();
    final favCount = 1 + random.nextInt(2);
    final shuffled = List<String>.from(_possibleFavorites)..shuffle(random);

    return NPCDiet(
      dailyRequirements: {
        DishType.cereal: 1,
        DishType.protein: 2,
        DishType.vegetable: 1,
        DishType.treat: 1,
      },
      minimumQuality: DishQuality.fine,
      favoriteFoods: shuffled.take(favCount).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'dailyRequirements': dailyRequirements.map(
      (k, v) => MapEntry(k.index.toString(), v),
    ),
    'minimumQuality': minimumQuality.index,
    'favoriteFoods': favoriteFoods,
  };

  factory NPCDiet.fromJson(Map<String, dynamic> json) => NPCDiet(
    dailyRequirements: (json['dailyRequirements'] as Map).map(
      (k, v) => MapEntry(DishType.values[int.parse(k)], v as int),
    ),
    minimumQuality: DishQuality.values[json['minimumQuality'] as int],
    favoriteFoods: (json['favoriteFoods'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
  );
}
