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

enum AcademicSchoolType { law, pharmacy, medicine }

extension AcademicSchoolTypeExtension on AcademicSchoolType {
  String get displayName {
    switch (this) {
      case AcademicSchoolType.law:
        return 'Swiss Imperial Faculty of Law';
      case AcademicSchoolType.pharmacy:
        return 'Geneva Imperial Pharmacy School';
      case AcademicSchoolType.medicine:
        return 'Geneva Medical Faculty & Clinic';
    }
  }
}

class GraduateSchoolState {
  final AcademicSchoolType type;
  final int currentSemester; // 0 = Entrance Exam, 1 = Semester 1, 2 = Semester 2, 3 = Semester 3, 4 = Final Board Exam
  final bool tuitionPaid;
  final bool hasCompletedAssignment;
  final double studyProgress; // 0.0 to 1.0
  final List<String> academicLogs;
  final Map<String, dynamic> currentComplication; // metadata of active complication
  final String? specialization;
  final List<int> semesterScores;

  GraduateSchoolState({
    required this.type,
    required this.currentSemester,
    this.tuitionPaid = false,
    this.hasCompletedAssignment = false,
    this.studyProgress = 0.0,
    this.academicLogs = const [],
    this.currentComplication = const {},
    this.specialization,
    this.semesterScores = const [],
  });

  GraduateSchoolState copyWith({
    AcademicSchoolType? type,
    int? currentSemester,
    bool? tuitionPaid,
    bool? hasCompletedAssignment,
    double? studyProgress,
    List<String>? academicLogs,
    Map<String, dynamic>? currentComplication,
    String? specialization,
    List<int>? semesterScores,
  }) {
    return GraduateSchoolState(
      type: type ?? this.type,
      currentSemester: currentSemester ?? this.currentSemester,
      tuitionPaid: tuitionPaid ?? this.tuitionPaid,
      hasCompletedAssignment: hasCompletedAssignment ?? this.hasCompletedAssignment,
      studyProgress: studyProgress ?? this.studyProgress,
      academicLogs: academicLogs ?? List<String>.from(this.academicLogs),
      currentComplication: currentComplication ?? Map<String, dynamic>.from(this.currentComplication),
      specialization: specialization ?? this.specialization,
      semesterScores: semesterScores ?? List<int>.from(this.semesterScores),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'currentSemester': currentSemester,
        'tuitionPaid': tuitionPaid,
        'hasCompletedAssignment': hasCompletedAssignment,
        'studyProgress': studyProgress,
        'academicLogs': academicLogs,
        'currentComplication': currentComplication,
        'specialization': specialization,
        'semesterScores': semesterScores,
      };

  factory GraduateSchoolState.fromJson(Map<String, dynamic> json) => GraduateSchoolState(
        type: AcademicSchoolType.values[json['type'] as int? ?? 0],
        currentSemester: json['currentSemester'] as int? ?? 0,
        tuitionPaid: json['tuitionPaid'] as bool? ?? false,
        hasCompletedAssignment: json['hasCompletedAssignment'] as bool? ?? false,
        studyProgress: (json['studyProgress'] as num? ?? 0.0).toDouble(),
        academicLogs: List<String>.from(json['academicLogs'] as List? ?? []),
        currentComplication: Map<String, dynamic>.from(json['currentComplication'] as Map? ?? {}),
        specialization: json['specialization'] as String?,
        semesterScores: List<int>.from(json['semesterScores'] as List? ?? []),
      );
}
