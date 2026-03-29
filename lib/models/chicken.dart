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

import 'package:uuid/uuid.dart';
import 'game_date.dart';

enum ChickenBreedType { houdan, dorking, scotsDumpie, rooster }

class ChickenBreed {
  final ChickenBreedType type;
  final String name;
  final String description;
  final double eggRate; // Average eggs per week
  final double growthRate; // Minutes to maturity
  final int meatYield; // Kilograms of meat
  final int basePrice;

  const ChickenBreed({
    required this.type,
    required this.name,
    required this.description,
    required this.eggRate,
    required this.growthRate,
    required this.meatYield,
    required this.basePrice,
  });

  static const List<ChickenBreed> breeds = [
    ChickenBreed(
      type: ChickenBreedType.houdan,
      name: 'Houdan',
      description:
          'French heritage breed known for excellent egg production and dual-purpose utility.',
      eggRate: 1.2, // Approx 8-9 eggs a week
      growthRate: 151200, // 15 weeks to maturity
      meatYield: 2,
      basePrice: 15,
    ),
    ChickenBreed(
      type: ChickenBreedType.dorking,
      name: 'Dorking',
      description:
          'Ancient breed prized for its large size and superior meat quality.',
      eggRate: 0.8,
      growthRate: 151200, // 15 weeks
      meatYield: 4,
      basePrice: 20,
    ),
    ChickenBreed(
      type: ChickenBreedType.scotsDumpie,
      name: 'Scots Dumpie',
      description:
          'Hardy, short-legged breed from Scotland. Excellent foragers and mothers.',
      eggRate: 1.0,
      growthRate: 151200, // 15 weeks
      meatYield: 1,
      basePrice: 12,
    ),
    ChickenBreed(
      type: ChickenBreedType.rooster,
      name: 'Rooster',
      description:
          'Necessary for fertilizing eggs and expanding the flock.',
      eggRate: 0.0,
      growthRate: 151200,
      meatYield: 2,
      basePrice: 25,
    ),
  ];

  static ChickenBreed getByTyped(ChickenBreedType type) =>
      breeds.firstWhere((b) => b.type == type);
}

class Chicken {
  final String id;
  final ChickenBreedType breedType;
  final GameDate birthDate;
  final double hunger; // 0-100
  final GameDate lastEggDate;
  final bool isMale;
  final bool isFertilized;
  final double weight; // in kilograms
  final int eggsLaid;
  final List<int> eggProductionHistory; // Daily counts
  final bool isReserved;

  Chicken({
    required this.id,
    required this.breedType,
    required this.birthDate,
    this.hunger = 0,
    required this.lastEggDate,
    this.isMale = false,
    this.isFertilized = false,
    this.weight = 0.5,
    this.eggsLaid = 0,
    this.eggProductionHistory = const [],
    this.isReserved = false,
  });

  bool isMature(GameDate currentDate) => currentDate.differenceInMinutes(birthDate) >= breed.growthRate;
  ChickenBreed get breed => ChickenBreed.getByTyped(breedType);
  int value(GameDate currentDate) => (breed.basePrice * (isMature(currentDate) ? 1.0 : 0.5) * (weight / 0.5)).round();

  String getDisplayAge(GameDate currentTime) {
    final diffMins = currentTime.differenceInMinutes(birthDate);
    if (diffMins < 360) return '${diffMins}m.'; // < 6 hours
    final diffHours = diffMins / 60;
    if (diffHours < 48) return '${diffHours.floor()}h.'; // 6 to 48 hours
    final diffDays = diffHours / 24;
    if (diffDays <= 180) return '${diffDays.floor()}d.'; // 2 days to 6 months
    final diffYears = diffDays / 360.0; // Approx Year
    return '${diffYears.toStringAsFixed(1)}y.';
  }

  Chicken copyWith({
    GameDate? birthDate,
    double? hunger,
    GameDate? lastEggDate,
    bool? isMale,
    bool? isFertilized,
    double? weight,
    int? eggsLaid,
    List<int>? eggProductionHistory,
    bool? isReserved,
  }) {
    return Chicken(
      id: id,
      breedType: breedType,
      birthDate: birthDate ?? this.birthDate,
      hunger: hunger ?? this.hunger,
      lastEggDate: lastEggDate ?? this.lastEggDate,
      isMale: isMale ?? this.isMale,
      isFertilized: isFertilized ?? this.isFertilized,
      weight: weight ?? this.weight,
      eggsLaid: eggsLaid ?? this.eggsLaid,
      eggProductionHistory: eggProductionHistory ?? this.eggProductionHistory,
      isReserved: isReserved ?? this.isReserved,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'breedType': breedType.index,
    'birthDate': birthDate.toJson(),
    'hunger': hunger,
    'lastEggDate': lastEggDate.toJson(),
    'isMale': isMale,
    'isFertilized': isFertilized,
    'weight': weight,
    'eggsLaid': eggsLaid,
    'eggProductionHistory': eggProductionHistory,
    'isReserved': isReserved,
  };

  factory Chicken.fromJson(Map<String, dynamic> json) => Chicken(
    id: json['id'] as String,
    breedType: ChickenBreedType.values[json['breedType'] as int],
    birthDate: GameDate.fromJson(json['birthDate'] as Map<String, dynamic>),
    hunger: (json['hunger'] as num).toDouble(),
    lastEggDate: GameDate.fromJson(json['lastEggDate'] as Map<String, dynamic>),
    isMale: json['isMale'] as bool? ?? false,
    isFertilized: json['isFertilized'] as bool? ?? false,
    weight: (json['weight'] as num? ?? 0.5).toDouble(),
    eggsLaid: json['eggsLaid'] as int? ?? 0,
    eggProductionHistory: List<int>.from(json['eggProductionHistory'] ?? []),
    isReserved: json['isReserved'] as bool? ?? false,
  );

  factory Chicken.create(
    ChickenBreedType type,
    GameDate currentDate, {
    bool isMale = false,
    double weight = 0.5,
  }) => Chicken(
    id: const Uuid().v4(),
    breedType: type,
    birthDate: currentDate,
    lastEggDate: currentDate,
    isMale: isMale,
    weight: weight,
  );
}
