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

class EncounterData {
  final String title;
  final String description;
  final Map<String, int> demands;

  EncounterData({
    required this.title,
    required this.description,
    required this.demands,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'demands': demands,
  };

  factory EncounterData.fromJson(Map<String, dynamic> json) => EncounterData(
    title: json['title'] as String,
    description: json['description'] as String,
    demands: Map<String, int>.from(json['demands'] as Map),
  );
}
