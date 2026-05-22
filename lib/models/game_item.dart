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

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'game_date.dart';

enum ItemCategory {
  food,
  material,
  specimen,
  reagent,
  medical,
  utility,
  knowledge,
  resource,
  corpse,
}

enum ItemQuality {
  awful,
  weak,
  substandard,
  fair,
  common,
  quality,
  precious,
  excellent,
  supreme,
}

enum FreshnessState {
  minutes,
  hours,
  days,
  years,
  none,
}

enum ItemShape { circle, square, triangle, diamond, hexagon, pill }

class GameItem {
  final String id;
  final String name;
  final String type; // e.g., 'egg', 'rat', 'cabbage'
  final ItemCategory category;
  final int quantity;
  final double quality; // 0.0 to 2.0
  final ItemShape shape;
  final Color color;
  final double weight; // in kilograms
  final int value; // base value in funds
  final Map<String, dynamic> metadata;
  final GameDate? creationDate;
  bool get isReserved => metadata['isReserved'] == true;

  ItemQuality get displayQuality {
    if (quality < 0.22) return ItemQuality.awful;
    if (quality < 0.44) return ItemQuality.weak;
    if (quality < 0.66) return ItemQuality.substandard;
    if (quality < 0.88) return ItemQuality.fair;
    if (quality < 1.1) return ItemQuality.common;
    if (quality < 1.32) return ItemQuality.quality;
    if (quality < 1.54) return ItemQuality.precious;
    if (quality < 1.76) return ItemQuality.excellent;
    return ItemQuality.supreme;
  }

  FreshnessState getFreshnessState(GameDate currentTime) {
    if (category != ItemCategory.food && category != ItemCategory.specimen) {
      return FreshnessState.none;
    }
    if (creationDate == null) return FreshnessState.none;
    
    final diffMins = currentTime.differenceInMinutes(creationDate!);
    if (diffMins < 360) return FreshnessState.minutes;
    final diffHours = diffMins / 60;
    if (diffHours <= 48) return FreshnessState.hours;
    final diffDays = diffHours / 24;
    if (diffDays <= 180) return FreshnessState.days;
    return FreshnessState.years;
  }

  String getDisplayAge(GameDate currentTime) {
    if (category != ItemCategory.food && category != ItemCategory.specimen) {
      return '-';
    }
    if (creationDate == null) return '-';
    
    final diffMins = currentTime.differenceInMinutes(creationDate!);
    if (diffMins < 360) return '${diffMins}m.'; // < 6 hours
    final diffHours = diffMins / 60;
    if (diffHours < 48) return '${diffHours.floor()}h.'; // 6 to 48 hours
    final diffDays = diffHours / 24;
    if (diffDays <= 180) return '${diffDays.floor()}d.'; // 2 days to 6 months
    final diffYears = diffDays / 360.0; // Approx Year
    return '${diffYears.toStringAsFixed(1)}y.';
  }

  GameItem({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    this.quantity = 1,
    this.quality = 1.0,
    required this.shape,
    this.color = Colors.grey,
    this.weight = 0.1,
    this.value = 1,
    this.metadata = const {},
    this.creationDate,
  });

  factory GameItem.create({
    required String name,
    required String type,
    required ItemCategory category,
    int quantity = 1,
    double quality = 1.0,
    double? weight,
    int? value,
    ItemShape? shape,
    Color? color,
    Map<String, dynamic> metadata = const {},
    GameDate? creationDate,
  }) {
    // Determine default shape and color based on type if not provided
    final (ItemShape defShape, Color defColor) = _getVisualsForType(
      type,
      category,
    );

    return GameItem(
      id: const Uuid().v4(),
      name: name,
      type: type,
      category: category,
      quantity: quantity,
      quality: quality,
      shape: shape ?? defShape,
      color: color ?? defColor,
      weight: weight ?? _getDefaultWeightForType(type, category),
      value: value ?? _getDefaultValueForType(type, category),
      metadata: metadata,
      creationDate: creationDate,
    );
  }

  static double _getDefaultWeightForType(String type, ItemCategory category) {
    if (type.contains('egg')) return 0.05;
    if (type.contains('rat')) return 0.3;
    if (type.contains('cabbage')) return 0.5;
    if (type.contains('meat')) return 1.0;
    if (type.contains('grain')) return 0.1;
    if (type.contains('timber')) return 5.0;
    if (type.contains('franc') || type.contains('funds')) return 0.01;
    if (type.contains('cannabis')) return 0.2;
    if (type.contains('tobacco')) return 0.5;
    if (type.contains('mushroom')) return 0.3;
    if (type.contains('hemp')) return 1.0;
    if (type.contains('kompromat')) return 0.1;
    return 0.1;
  }

  static int _getDefaultValueForType(String type, ItemCategory category) {
    if (type.contains('egg')) return 1;
    if (type.contains('rat')) return 2;
    if (type.contains('cabbage')) return 3;
    if (type.contains('meat')) return 5;
    if (type.contains('funds')) return 1;
    if (type.contains('timber')) return 8;
    if (type.contains('seeds_cannabis')) return 15;
    if (type.contains('cannabis_buds')) return 40;
    if (type.contains('seeds_tobacco')) return 10;
    if (type.contains('tobacco_leaves')) return 25;
    if (type.contains('seeds_mushroom') || type.contains('mushroom_spores')) return 12;
    if (type.contains('hallucinogenic_mushrooms')) return 35;
    if (type.contains('hemp_fiber')) return 8;
    if (type.contains('cloth')) return 15;
    if (type.contains('cigar')) return 20;
    if (type.contains('kompromat_folder')) return 100;
    return 1;
  }

  static (ItemShape, Color) _getVisualsForType(
    String type,
    ItemCategory category,
  ) {
    if (type.contains('egg')) {
      return (ItemShape.circle, Colors.amber.shade100);
    }
    if (type.contains('rat')) {
      return (ItemShape.triangle, Colors.grey.shade600);
    }
    if (type.contains('cabbage')) {
      return (ItemShape.hexagon, Colors.green.shade400);
    }
    if (type.contains('meat')) {
      return (ItemShape.square, Colors.red.shade400);
    }
    if (type.contains('grain') || type.contains('flour')) {
      return (ItemShape.hexagon, Colors.yellow.shade200);
    }
    if (type.contains('note') || type.contains('document') || type.contains('kompromat')) {
      return (ItemShape.pill, Colors.lightBlue.shade100);
    }
    if (type.contains('medicine')) {
      return (ItemShape.pill, Colors.pink.shade300);
    }
    if (type.contains('corpse')) {
      return (ItemShape.circle, const Color(0xFF4A1A1A)); // Deep dried blood red
    }
    if (type.contains('franc') || type.contains('funds')) {
      return (ItemShape.circle, Colors.amber.shade300); // Gold coin representation
    }
    if (type.contains('cannabis') || type.contains('hemp') || type.contains('tobacco') || type.contains('mushroom')) {
      return (ItemShape.hexagon, Colors.green.shade800);
    }

    // Fallsbacks by category
    switch (category) {
      case ItemCategory.food:
        return (ItemShape.circle, Colors.orange.shade300);
      case ItemCategory.material:
        return (ItemShape.square, Colors.brown.shade400);
      case ItemCategory.knowledge:
        return (ItemShape.pill, Colors.blue.shade200);
      default:
        return (ItemShape.diamond, Colors.grey);
    }
  }

  GameItem copyWith({
    String? id,
    String? name,
    String? type,
    int? quantity,
    double? quality,
    ItemShape? shape,
    Color? color,
    double? weight,
    int? value,
    Map<String, dynamic>? metadata,
    GameDate? creationDate,
  }) {
    return GameItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category,
      quantity: quantity ?? this.quantity,
      quality: quality ?? this.quality,
      shape: shape ?? this.shape,
      color: color ?? this.color,
      weight: weight ?? this.weight,
      value: value ?? this.value,
      metadata: metadata ?? this.metadata,
      creationDate: creationDate ?? this.creationDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'category': category.index,
    'quantity': quantity,
    'quality': quality,
    'shape': shape.index,
    'color': color.toARGB32(),
    'weight': weight,
    'value': value,
    'metadata': metadata,
    'creationDate': creationDate?.toJson(),
  };

  factory GameItem.fromJson(Map<String, dynamic> json) => GameItem(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    category: ItemCategory.values[json['category'] as int],
    quantity: json['quantity'] as int,
    quality: (json['quality'] as num).toDouble(),
    shape: ItemShape.values[json['shape'] as int? ?? 0],
    color: Color(json['color'] as int? ?? Colors.grey.toARGB32()),
    weight: (json['weight'] as num? ?? 0.1).toDouble(),
    value: json['value'] as int? ?? 1,
    metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    creationDate: json['creationDate'] != null ? GameDate.fromJson(json['creationDate'] as Map<String, dynamic>) : null,
  );
}
