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

import '../services/task_service.dart';

enum IntentPriority {
  idle,       // 0: Default fallback
  leisure,    // 1: Lowest priority activities
  low,        // 2: Scheduled autonomous behavior
  normal,     // 3: Player-assigned tasks (Normal Priority)
  assignment, // 4: Specifically assigned tasks (High priority manual)
  high,       // 5: Critical physiological thresholds (High Priority)
  urgent,     // 6: Approaching crisis (4 stars)
  vital,      // 7: Serious crisis (5 stars)
  emergency,  // 8: Crisis response (Emergency Tasks)
  panic,      // 9: Immediate mortal danger (Fire, Escape)
}

class NPCIntent {
  final String id;
  final IntentPriority priority;
  final TaskType action;
  final String? targetRoomId;
  final String? recipeId;
  final String? targetName;
  final int? startTimeMin; // Optional: Wait until this game minute
  final int expectedDurationMin;
  final int? minutesRemaining;
  final bool isManual;
  final int stallCoolingMin; // New: minutes to wait if unperformable

  NPCIntent({
    required this.id,
    required this.priority,
    required this.action,
    this.targetRoomId,
    this.recipeId,
    this.targetName,
    this.startTimeMin,
    this.expectedDurationMin = 240,
    this.minutesRemaining,
    this.isManual = false,
    this.stallCoolingMin = 0,
  });

  NPCIntent copyWith({
    String? id,
    IntentPriority? priority,
    TaskType? action,
    String? targetRoomId,
    String? recipeId,
    String? targetName,
    int? startTimeMin,
    int? expectedDurationMin,
    int? minutesRemaining,
    bool? isManual,
    int? stallCoolingMin,
  }) {
    return NPCIntent(
      id: id ?? this.id,
      priority: priority ?? this.priority,
      action: action ?? this.action,
      targetRoomId: targetRoomId ?? this.targetRoomId,
      recipeId: recipeId ?? this.recipeId,
      targetName: targetName ?? this.targetName,
      startTimeMin: startTimeMin ?? this.startTimeMin,
      expectedDurationMin: expectedDurationMin ?? this.expectedDurationMin,
      minutesRemaining: minutesRemaining ?? this.minutesRemaining,
      isManual: isManual ?? this.isManual,
      stallCoolingMin: stallCoolingMin ?? this.stallCoolingMin,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'priority': priority.index,
    'action': action.index,
    'targetRoomId': targetRoomId,
    'recipeId': recipeId,
    'targetName': targetName,
    'startTimeMin': startTimeMin,
    'expectedDurationMin': expectedDurationMin,
    'minutesRemaining': minutesRemaining,
    'isManual': isManual,
    'stallCoolingMin': stallCoolingMin,
  };

  factory NPCIntent.fromJson(Map<String, dynamic> json) => NPCIntent(
    id: json['id'],
    priority: IntentPriority.values[json['priority']],
    action: TaskType.values[json['action']],
    targetRoomId: json['targetRoomId'],
    recipeId: json['recipeId'],
    targetName: json['targetName'],
    startTimeMin: json['startTimeMin'],
    expectedDurationMin: json['expectedDurationMin'] ?? 240,
    minutesRemaining: json['minutesRemaining'],
    isManual: json['isManual'] ?? false,
    stallCoolingMin: json['stallCoolingMin'] ?? 0,
  );
}
