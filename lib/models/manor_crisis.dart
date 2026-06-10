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

enum ManorCrisisType {
  fire,
  specimenEscape,
  intruder,
  golemTantrum,
}

class ManorCrisis {
  final String id;
  final ManorCrisisType type;
  final String roomId;
  final double severity; // 0.0 to 1.0
  final DateTime discoveryDate;
  final bool isDiscovered;

  ManorCrisis({
    String? id,
    required this.type,
    required this.roomId,
    this.severity = 0.1,
    required this.discoveryDate,
    this.isDiscovered = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'roomId': roomId,
    'severity': severity,
    'discoveryDate': discoveryDate.toIso8601String(),
    'isDiscovered': isDiscovered,
  };

  factory ManorCrisis.fromJson(Map<String, dynamic> json) => ManorCrisis(
    id: json['id'] as String,
    type: ManorCrisisType.values[json['type'] as int],
    roomId: json['roomId'] as String,
    severity: (json['severity'] as num).toDouble(),
    discoveryDate: DateTime.parse(json['discoveryDate'] as String),
    isDiscovered: json['isDiscovered'] as bool,
  );

  ManorCrisis copyWith({
    String? id,
    ManorCrisisType? type,
    String? roomId,
    double? severity,
    DateTime? discoveryDate,
    bool? isDiscovered,
  }) {
    return ManorCrisis(
      id: id ?? this.id,
      type: type ?? this.type,
      roomId: roomId ?? this.roomId,
      severity: severity ?? this.severity,
      discoveryDate: discoveryDate ?? this.discoveryDate,
      isDiscovered: isDiscovered ?? this.isDiscovered,
    );
  }

  String get name {
    switch (type) {
      case ManorCrisisType.fire:
        return 'FIRE';
      case ManorCrisisType.specimenEscape:
        return 'SPECIMEN ESCAPE';
      case ManorCrisisType.intruder:
        return 'INTRUDER';
      case ManorCrisisType.golemTantrum:
        return 'TEMPER TANTRUM';
    }
  }

  String get description {
    switch (type) {
      case ManorCrisisType.fire:
        return 'A fire is spreading in this room!';
      case ManorCrisisType.specimenEscape:
        return 'A research subject has escaped containment!';
      case ManorCrisisType.intruder:
        return 'An unauthorized individual has entered the manor.';
      case ManorCrisisType.golemTantrum:
        return 'The Promethean Flesh Golem is throwing a violent temper tantrum!';
    }
  }
}
