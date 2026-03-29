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

import '../models/room.dart';

class ConstructionBlueprint {
  final String id;
  final String name;
  final RoomType type;
  final Floor floor;
  final double width;
  final Map<String, num> cost;
  final int durationMinutes;
  final String description;

  ConstructionBlueprint({
    required this.id,
    required this.name,
    required this.type,
    required this.floor,
    required this.width,
    required this.cost,
    required this.durationMinutes,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'floor': floor.index,
    'width': width,
    'cost': cost,
    'durationMinutes': durationMinutes,
    'description': description,
  };

  factory ConstructionBlueprint.fromJson(Map<String, dynamic> json) =>
      ConstructionBlueprint(
        id: json['id'],
        name: json['name'],
        type: RoomType.values[json['type']],
        floor: Floor.values[json['floor']],
        width: (json['width'] as num).toDouble(),
        cost: Map<String, num>.from(json['cost']),
        durationMinutes: json['durationMinutes'],
        description: json['description'],
      );
}

class ConstructionProject {
  final String id;
  final ConstructionBlueprint blueprint;
  int minutesRemaining;
  double progress; // 0.0 to 1.0
  bool isStarted;

  ConstructionProject({
    required this.id,
    required this.blueprint,
    required this.minutesRemaining,
    this.progress = 0.0,
    this.isStarted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'blueprint': blueprint.toJson(),
    'minutesRemaining': minutesRemaining,
    'progress': progress,
    'isStarted': isStarted,
  };

  factory ConstructionProject.fromJson(Map<String, dynamic> json) =>
      ConstructionProject(
        id: json['id'] as String,
        blueprint: ConstructionBlueprint.fromJson(json['blueprint']),
        minutesRemaining: json['minutesRemaining'],
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
        isStarted: json['isStarted'] as bool? ?? false,
      );

  ConstructionProject copyWith({
    String? id,
    ConstructionBlueprint? blueprint,
    int? minutesRemaining,
    double? progress,
    bool? isStarted,
  }) {
    return ConstructionProject(
      id: id ?? this.id,
      blueprint: blueprint ?? this.blueprint,
      minutesRemaining: minutesRemaining ?? this.minutesRemaining,
      progress: progress ?? this.progress,
      isStarted: isStarted ?? this.isStarted,
    );
  }
}

class ConstructionService {
  static List<ConstructionBlueprint> getAvailableBlueprints() {
    return [
      ConstructionBlueprint(
        id: 'greenhouse',
        name: 'Greenhouse',
        type: RoomType.unused, // We can add specialized types later
        floor: Floor.ground,
        width: 1.5,
        cost: {'funds': 500, 'wood': 100},
        durationMinutes: 48 * 60,
        description: "A glass-walled room for rare botanical experiments.",
      ),
      ConstructionBlueprint(
        id: 'tenement',
        name: 'NPC Tenement',
        type: RoomType.bedroom,
        floor: Floor.ground,
        width: 2.0,
        cost: {'funds': 300, 'wood': 200},
        durationMinutes: 72 * 60,
        description: "Large-scale housing for many refugees.",
      ),
      ConstructionBlueprint(
        id: 'reinforced_lab',
        name: 'Reinforced Lab',
        type: RoomType.study,
        floor: Floor.basement,
        width: 2.0,
        cost: {'funds': 1000, 'wood': 50},
        durationMinutes: 96 * 60,
        description: "A secure, iron-lined laboratory for dangerous research.",
      ),
    ];
  }
}
