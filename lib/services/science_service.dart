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

import 'task_service.dart';

class ScienceActivity {
  final String id;
  final String name;
  final TaskType type;
  final Map<String, num> ingredients;
  final int baseDurationMinutes;
  final String discipline;
  final double moralCost; // 0.0 to 1.0 (Guilt increase)
  final String outcomeDescription;

  ScienceActivity({
    required this.id,
    required this.name,
    required this.type,
    required this.ingredients,
    required this.baseDurationMinutes,
    required this.discipline,
    this.moralCost = 0.0,
    required this.outcomeDescription,
  });
}

class ScienceService {
  static List<ScienceActivity> getAvailableActivities() {
    return [
      ScienceActivity(
        id: 'generic_research',
        name: 'Fundamental Research',
        type: TaskType.research,
        ingredients: {'research_notes': 1},
        baseDurationMinutes: 15, // Adjusted per item if possible
        discipline: 'General',
        outcomeDescription:
            'Produces research notes and advances personal knowledge.',
      ),
      ScienceActivity(
        id: 'small_dissection',
        name: 'Small Specimen Anatomical Study',
        type: TaskType.dissect,
        ingredients: {'specimen': 1},
        baseDurationMinutes: 20,
        discipline: 'Anatomy',
        outcomeDescription:
            'Produces 1-15 pages of life science knowledge and poor quality meat.',
      ),
      ScienceActivity(
        id: 'large_dissection',
        name: 'Large Specimen Anatomical Study',
        type: TaskType.dissect,
        ingredients: {'large_specimen': 1},
        baseDurationMinutes: 90,
        discipline: 'Anatomy',
        outcomeDescription:
            'Produces significant life science knowledge and meat.',
      ),
      ScienceActivity(
        id: 'small_vivisection',
        name: 'Small Specimen Vivisection',
        type: TaskType.vivisection,
        ingredients: {'specimen': 1},
        baseDurationMinutes: 45,
        discipline: 'Anatomy',
        moralCost: 0.2,
        outcomeDescription:
            'Produces 5-20 pages of life science knowledge and mediocre meat. Highly corrupting.',
      ),
      ScienceActivity(
        id: 'large_vivisection',
        name: 'Large Specimen Vivisection',
        type: TaskType.vivisection,
        ingredients: {'large_specimen': 1},
        baseDurationMinutes: 150,
        discipline: 'Anatomy',
        moralCost: 0.5,
        outcomeDescription:
            'Produces vast life science knowledge and meat. Extremely corrupting.',
      ),
      ScienceActivity(
        id: 'puzzle_study',
        name: 'Cognitive Puzzle Study',
        type: TaskType.puzzleStudy,
        ingredients: {'specimen': 5, 'meals': 1},
        baseDurationMinutes: 960, // 16 hours
        discipline: 'Psychology',
        outcomeDescription:
            'Produces psychology notes and some anatomy knowledge.',
      ),
      ScienceActivity(
        id: 'deprivation_study',
        name: 'Occult Studies',
        type: TaskType.deprivationStudy,
        ingredients: {'specimen': 5},
        baseDurationMinutes: 2400, // 40 hours
        discipline: 'Zoology',
        moralCost: 0.4,
        outcomeDescription:
            'Produces zoology notes. High mortality rate for subjects.',
      ),
      ScienceActivity(
        id: 'clinical_trial',
        name: 'General Clinical Trial',
        type: TaskType.clinicalTrial,
        ingredients: {'specimen': 10, 'herb_reagent': 1, 'meals': 5},
        baseDurationMinutes: 7200, // 120 hours
        discipline: 'Medicine',
        moralCost: 0.1,
        outcomeDescription:
            'Produces notes in the medicine discipline and zoology.',
      ),
    ];
  }

  static ScienceActivity? getActivityById(String id) {
    try {
      return getAvailableActivities().firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
