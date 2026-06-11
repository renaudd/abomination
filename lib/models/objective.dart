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

enum ObjectiveType { tutorial, story, science, combat, venture, manor }

class Objective {
  final String id;
  final String title;
  final String description;
  final ObjectiveType type;
  bool isCompleted;
  final Map<String, dynamic> requirements;
  final String? nextObjectiveId;

  Objective({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.isCompleted = false,
    this.requirements = const {},
    this.nextObjectiveId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.index,
    'isCompleted': isCompleted,
    'requirements': requirements,
    'nextObjectiveId': nextObjectiveId,
  };

  factory Objective.fromJson(Map<String, dynamic> json) => Objective(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    type: ObjectiveType.values[json['type'] as int],
    isCompleted: json['isCompleted'] as bool,
    requirements: json['requirements'] as Map<String, dynamic>? ?? {},
    nextObjectiveId: json['nextObjectiveId'] as String?,
  );
}
