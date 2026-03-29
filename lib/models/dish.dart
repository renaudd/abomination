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

import 'game_date.dart';

enum DishQuality {
  exquisite,
  delectable,
  sophisticated,
  fine,
  decent,
  alright,
  notBad,
  notGreat,
  mediocre,
  weak,
  awful,
  disgusting,
}

enum DishType { cereal, protein, vegetable, treat }

class Dish {
  final String id;
  final String name;
  final DishType type;
  final DishQuality quality;
  final GameDate cookedAt;
  final int shelfLifeHours;
  final double illnessRisk; // 0.0 to 1.0
  final double weight; // in kilograms
  final int value; // base value in funds

  int get expirationMinutes => cookedAt.totalMinutes + (shelfLifeHours * 60);

  Dish({
    required this.id,
    required this.name,
    required this.type,
    required this.quality,
    required this.cookedAt,
    this.shelfLifeHours = 168,
    this.illnessRisk = 0.0,
    this.weight = 0.5,
    this.value = 5,
  });

  bool isSpoiled(GameDate currentTime) {
    return currentTime.differenceInHours(cookedAt) > shelfLifeHours;
  }

  String getDisplayAge(GameDate currentTime) {
    final diffMins = currentTime.differenceInMinutes(cookedAt);
    if (diffMins < 360) return '${diffMins}m.'; // < 6 hours
    final diffHours = diffMins / 60;
    if (diffHours < 48) return '${diffHours.floor()}h.'; // 6 to 48 hours
    final diffDays = diffHours / 24;
    if (diffDays <= 180) return '${diffDays.floor()}d.'; // 2 days to 6 months
    final diffYears = diffDays / 360.0; // Approx Year
    return '${diffYears.toStringAsFixed(1)}y.';
  }

  double getCurrentIllnessRisk(GameDate currentTime) {
    if (!isSpoiled(currentTime)) return illnessRisk;
    // Risk increases dramatically after spoilage
    final hoursPast = currentTime.differenceInHours(cookedAt) - shelfLifeHours;
    return (illnessRisk + (hoursPast * 0.05)).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'quality': quality.index,
    'cookedAt': cookedAt.toJson(),
    'shelfLifeHours': shelfLifeHours,
    'illnessRisk': illnessRisk,
    'weight': weight,
    'value': value,
  };

  factory Dish.fromJson(Map<String, dynamic> json) => Dish(
    id: json['id'],
    name: json['name'],
    type: DishType.values[json['type']],
    quality: DishQuality.values[json['quality']],
    cookedAt: GameDate.fromJson(json['cookedAt'] as Map<String, dynamic>),
    shelfLifeHours: json['shelfLifeHours'],
    illnessRisk: (json['illnessRisk'] as num?)?.toDouble() ?? 0.0,
    weight: (json['weight'] as num?)?.toDouble() ?? 0.5,
    value: json['value'] as int? ?? 5,
  );
}
