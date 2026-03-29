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

enum PlantType { fabaBean, greenBean }
enum PlantLifecycle { annual, perennial }

class Plant {
  final String id;
  final PlantType type;
  final String roomId;
  final double health; // 0.0 to 1.0
  final bool isWatered;
  final int yieldAmount;
  final int plantedMonth;
  final int plantedYear;
  final int bedIndex;

  Plant({
    required this.id,
    required this.type,
    required this.roomId,
    this.health = 1.0,
    this.isWatered = false,
    this.yieldAmount = 0,
    required this.plantedMonth,
    required this.plantedYear,
    required this.bedIndex,
  });

  String get name {
    switch (type) {
      case PlantType.fabaBean:
        return 'Faba Bean';
      case PlantType.greenBean:
        return 'Green Bean';
    }
  }

  String get yieldItemType {
    switch (type) {
      case PlantType.fabaBean:
        return 'faba_beans';
      case PlantType.greenBean:
        return 'green_beans';
    }
  }

  PlantLifecycle get lifecycle {
    switch (type) {
      case PlantType.fabaBean:
      case PlantType.greenBean:
        return PlantLifecycle.annual;
    }
  }

  /// Months when the plant can grow and eventually yield produce.
  List<int> get peakMonths {
    switch (type) {
      case PlantType.fabaBean:
        return [4, 5, 6]; // Peak April - June
      case PlantType.greenBean:
        return [6, 7, 8, 9]; // Peak June - September
    }
  }

  bool isPeakSeason(int currentMonth) {
    return peakMonths.contains(currentMonth);
  }

  bool isAlive(int currentMonth) {
    if (lifecycle == PlantLifecycle.annual) {
      // Lives from roughly April through October before Frost (Month 11) kills them
      return currentMonth >= 4 && currentMonth <= 10;
    }
    return true; // Perennials always survive
  }

  Plant copyWith({
    double? health,
    bool? isWatered,
    int? yieldAmount,
    int? bedIndex,
  }) {
    return Plant(
      id: id,
      type: type,
      roomId: roomId,
      health: health ?? this.health,
      isWatered: isWatered ?? this.isWatered,
      yieldAmount: yieldAmount ?? this.yieldAmount,
      plantedMonth: plantedMonth,
      plantedYear: plantedYear,
      bedIndex: bedIndex ?? this.bedIndex,
    );
  }

  factory Plant.create(PlantType type, String roomId, int currentMonth, int currentYear, int bedIndex) {
    return Plant(
      id: const Uuid().v4(),
      type: type,
      roomId: roomId,
      plantedMonth: currentMonth,
      plantedYear: currentYear,
      bedIndex: bedIndex,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'roomId': roomId,
    'health': health,
    'isWatered': isWatered,
    'yieldAmount': yieldAmount,
    'plantedMonth': plantedMonth,
    'plantedYear': plantedYear,
    'bedIndex': bedIndex,
  };

  factory Plant.fromJson(Map<String, dynamic> json) => Plant(
    id: json['id'] as String,
    type: PlantType.values[json['type'] as int],
    roomId: json['roomId'] as String,
    health: (json['health'] as num).toDouble(),
    isWatered: json['isWatered'] as bool? ?? false,
    yieldAmount: json['yieldAmount'] as int? ?? 0,
    plantedMonth: json['plantedMonth'] as int,
    plantedYear: json['plantedYear'] as int,
    bedIndex: json['bedIndex'] as int? ?? 0,
  );
}
