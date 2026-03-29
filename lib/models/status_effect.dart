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

enum StatusEffectType { guilt, insanity, disease, love, hate, joy, sadness }

class StatusEffect {
  final String id;
  final String name;
  final StatusEffectType type;
  final String description;
  final int startTimestamp; // Game minute
  final int? durationMinutes; // Null if permanent
  final Map<String, int> attributeModifiers;
  final bool isPermanent;
  final String? sourceTaskId;
  final Map<String, dynamic> metadata;

  StatusEffect({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.startTimestamp,
    this.durationMinutes,
    this.attributeModifiers = const {},
    this.isPermanent = false,
    this.sourceTaskId,
    this.metadata = const {},
  });

  bool isExpired(int currentTimestamp) {
    if (isPermanent || durationMinutes == null) return false;
    return currentTimestamp >= (startTimestamp + durationMinutes!);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'description': description,
    'startTimestamp': startTimestamp,
    'durationMinutes': durationMinutes,
    'attributeModifiers': attributeModifiers,
    'isPermanent': isPermanent,
    'sourceTaskId': sourceTaskId,
    'metadata': metadata,
  };

  factory StatusEffect.fromJson(Map<String, dynamic> json) => StatusEffect(
    id: json['id'] as String,
    name: json['name'] as String,
    type: StatusEffectType.values[json['type'] as int],
    description: json['description'] as String,
    startTimestamp: json['startTimestamp'] as int,
    durationMinutes: json['durationMinutes'] as int?,
    attributeModifiers: Map<String, int>.from(json['attributeModifiers'] ?? {}),
    isPermanent: json['isPermanent'] as bool? ?? false,
    sourceTaskId: json['sourceTaskId'] as String?,
    metadata: json['metadata'] as Map<String, dynamic>? ?? {},
  );
}
