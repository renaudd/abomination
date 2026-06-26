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

enum PatronTrait {
  easyRegular,
  bigTipper,
  promoter,
  generousPatron,
  glutton,
  complainer,
  troublemaker,
  businessSaboteur,
  prejudiced,
  musicLover,
  quietSeeker,
}

extension PatronTraitExtension on PatronTrait {
  String get displayName {
    switch (this) {
      case PatronTrait.easyRegular:
        return 'Easy Regular';
      case PatronTrait.bigTipper:
        return 'Big Tipper';
      case PatronTrait.promoter:
        return 'Promoter';
      case PatronTrait.generousPatron:
        return 'Generous Patron';
      case PatronTrait.glutton:
        return 'Glutton';
      case PatronTrait.complainer:
        return 'Complainer';
      case PatronTrait.troublemaker:
        return 'Troublemaker';
      case PatronTrait.businessSaboteur:
        return 'Business Saboteur';
      case PatronTrait.prejudiced:
        return 'Prejudiced';
      case PatronTrait.musicLover:
        return 'Music Lover';
      case PatronTrait.quietSeeker:
        return 'Quiet Seeker';
    }
  }

  String get description {
    switch (this) {
      case PatronTrait.easyRegular:
        return 'Patient and polite. Has low expectations and orders simple dishes.';
      case PatronTrait.bigTipper:
        return 'Pays double (+100% premium) if served quickly and with high quality.';
      case PatronTrait.promoter:
        return 'Serving them a perfect meal significantly boosts the manor\'s reputation.';
      case PatronTrait.generousPatron:
        return 'Occasionally leaves behind valuable items, extra tips, or alchemical materials.';
      case PatronTrait.glutton:
        return 'Orders multiple courses in a single sitting, occupying tables longer.';
      case PatronTrait.complainer:
        return 'Highly sensitive to kitchen dirtiness or minor service delays. Drains local respect.';
      case PatronTrait.troublemaker:
        return 'Prone to starting arguments, offending other patrons, and inciting brawls.';
      case PatronTrait.businessSaboteur:
        return 'A covert threat. Tries to steal alchemical notes or poison food supplies if unmonitored.';
      case PatronTrait.prejudiced:
        return 'Openly hostile to patrons of different nationalities, languages, or factions.';
      case PatronTrait.musicLover:
        return 'Craves live entertainment and music. Generates higher tips when music is active.';
      case PatronTrait.quietSeeker:
        return 'Prefers peace and quiet. Will not visit if loud entertainment is active.';
    }
  }

  bool get isPositive {
    return this == PatronTrait.easyRegular ||
        this == PatronTrait.bigTipper ||
        this == PatronTrait.promoter ||
        this == PatronTrait.generousPatron ||
        this == PatronTrait.glutton ||
        this == PatronTrait.musicLover;
  }
}

class Patron {
  final String id;
  final String name;
  final String faction; // Covert/silent faction affiliation
  final List<PatronTrait> traits;
  
  double patience; // 0.0 to 1.0
  double satisfaction; // 0.0 to 100.0
  bool isSeated;
  String? seatedTableId;
  String? orderedRecipeId;
  bool hasBeenServed;
  int arrivalMinutes;
  int? diningFinishMinutes;
  bool isDrugged;
  bool isCollapsed;
  bool isUnderOperation;
  String? sedativeUsed;
  bool isExpelled;
  int coursesOrdered; // For gluttons who order multiple times

  Patron({
    required this.id,
    required this.name,
    required this.faction,
    required this.traits,
    this.patience = 1.0,
    this.satisfaction = 100.0,
    this.isSeated = false,
    this.seatedTableId,
    this.orderedRecipeId,
    this.hasBeenServed = false,
    this.arrivalMinutes = 0,
    this.diningFinishMinutes,
    this.isDrugged = false,
    this.isCollapsed = false,
    this.isUnderOperation = false,
    this.sedativeUsed,
    this.isExpelled = false,
    this.coursesOrdered = 1,
  });

  /// Dynamically generates a patron with 1 to 3 non-exclusive traits.
  factory Patron.generate(Random rand, String faction, String name, int currentMinutes) {
    final List<PatronTrait> generatedTraits = [];
    final allPossibleTraits = PatronTrait.values.toList();
    
    // Determine number of traits: 40% chance of 1, 40% chance of 2, 20% chance of 3
    final roll = rand.nextDouble();
    int traitCount = 1;
    if (roll < 0.20) {
      traitCount = 3;
    } else if (roll < 0.60) {
      traitCount = 2;
    }

    // Shuffle and pick unique traits
    allPossibleTraits.shuffle(rand);
    for (int i = 0; i < traitCount; i++) {
      generatedTraits.add(allPossibleTraits[i]);
    }

    return Patron(
      id: 'patron_${rand.nextInt(999999)}_${DateTime.now().microsecondsSinceEpoch % 1000}',
      name: name,
      faction: faction,
      traits: generatedTraits,
      patience: 1.0,
      satisfaction: 100.0,
      isSeated: false,
      arrivalMinutes: currentMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'faction': faction,
      'traits': traits.map((t) => t.index).toList(),
      'patience': patience,
      'satisfaction': satisfaction,
      'isSeated': isSeated,
      'seatedTableId': seatedTableId,
      'orderedRecipeId': orderedRecipeId,
      'hasBeenServed': hasBeenServed,
      'arrivalMinutes': arrivalMinutes,
      'diningFinishMinutes': diningFinishMinutes,
      'isDrugged': isDrugged,
      'isCollapsed': isCollapsed,
      'isUnderOperation': isUnderOperation,
      'sedativeUsed': sedativeUsed,
      'isExpelled': isExpelled,
      'coursesOrdered': coursesOrdered,
    };
  }

  factory Patron.fromJson(Map<String, dynamic> json) {
    final List<dynamic> traitIndices = json['traits'] as List<dynamic>? ?? [];
    final List<PatronTrait> loadedTraits = traitIndices
        .map((idx) => PatronTrait.values[idx as int])
        .toList();

    return Patron(
      id: json['id'] as String,
      name: json['name'] as String,
      faction: json['faction'] as String,
      traits: loadedTraits,
      patience: (json['patience'] as num? ?? 1.0).toDouble(),
      satisfaction: (json['satisfaction'] as num? ?? 100.0).toDouble(),
      isSeated: json['isSeated'] as bool? ?? false,
      seatedTableId: json['seatedTableId'] as String?,
      orderedRecipeId: json['orderedRecipeId'] as String?,
      hasBeenServed: json['hasBeenServed'] as bool? ?? false,
      arrivalMinutes: json['arrivalMinutes'] as int? ?? 0,
      diningFinishMinutes: json['diningFinishMinutes'] as int?,
      isDrugged: json['isDrugged'] as bool? ?? false,
      isCollapsed: json['isCollapsed'] as bool? ?? false,
      isUnderOperation: json['isUnderOperation'] as bool? ?? false,
      sedativeUsed: json['sedativeUsed'] as String?,
      isExpelled: json['isExpelled'] as bool? ?? false,
      coursesOrdered: json['coursesOrdered'] as int? ?? 1,
    );
  }

  Patron copyWith({
    String? id,
    String? name,
    String? faction,
    List<PatronTrait>? traits,
    double? patience,
    double? satisfaction,
    bool? isSeated,
    String? seatedTableId,
    String? orderedRecipeId,
    bool? hasBeenServed,
    int? arrivalMinutes,
    int? diningFinishMinutes,
    bool? isDrugged,
    bool? isCollapsed,
    bool? isUnderOperation,
    String? sedativeUsed,
    bool? isExpelled,
    int? coursesOrdered,
  }) {
    return Patron(
      id: id ?? this.id,
      name: name ?? this.name,
      faction: faction ?? this.faction,
      traits: traits ?? this.traits,
      patience: patience ?? this.patience,
      satisfaction: satisfaction ?? this.satisfaction,
      isSeated: isSeated ?? this.isSeated,
      seatedTableId: seatedTableId ?? this.seatedTableId,
      orderedRecipeId: orderedRecipeId ?? this.orderedRecipeId,
      hasBeenServed: hasBeenServed ?? this.hasBeenServed,
      arrivalMinutes: arrivalMinutes ?? this.arrivalMinutes,
      diningFinishMinutes: diningFinishMinutes ?? this.diningFinishMinutes,
      isDrugged: isDrugged ?? this.isDrugged,
      isCollapsed: isCollapsed ?? this.isCollapsed,
      isUnderOperation: isUnderOperation ?? this.isUnderOperation,
      sedativeUsed: sedativeUsed ?? this.sedativeUsed,
      isExpelled: isExpelled ?? this.isExpelled,
      coursesOrdered: coursesOrdered ?? this.coursesOrdered,
    );
  }
}
