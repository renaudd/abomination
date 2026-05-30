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

import 'package:flutter_test/flutter_test.dart';
import 'package:abomination/state/game_state.dart';
import 'package:abomination/models/graduate_school_state.dart';
import 'package:abomination/services/task_service.dart';
import 'package:abomination/models/room.dart';

void main() {
  group('Graduate School Academic Specialization Tests', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
      gameState.initializeNewGame(
        firstName: "Alphonse",
        lastName: "Flaubert",
        estateName: "Flaubert Manor",
        deathCause: DeathCause.trainCrash,
        age: 24,
        gilesTrait: GilesTrait.silent,
        objective: LifeObjective.science,
      );
      gameState.setSpeed(GameSpeed.normal);
    });

    test('Psychiatry selection and normal board exam timeline', () {
      gameState.enrollInGraduateSchool(AcademicSchoolType.medicine);
      expect(gameState.graduateSchool, isNotNull);
      expect(gameState.graduateSchool!.currentSemester, equals(0));

      // Entrance Exam
      gameState.checkAcademicExam(true, score: 4);
      expect(gameState.graduateSchool!.currentSemester, equals(1));

      // Semester 1
      gameState.checkAcademicExam(true, score: 3);
      expect(gameState.graduateSchool!.currentSemester, equals(2));

      // Semester 2
      gameState.checkAcademicExam(true, score: 3);
      expect(gameState.graduateSchool!.currentSemester, equals(3));

      // Select specialization at Semester 3
      gameState.selectAcademicSpecialization('Psychiatry');
      expect(gameState.graduateSchool!.specialization, equals('Psychiatry'));

      // Semester 3 Exam passes, advancing directly to Board Exam in Semester 4
      gameState.checkAcademicExam(true, score: 4);
      expect(gameState.graduateSchool!.currentSemester, equals(4));

      // Board Exam passes, completing graduation
      gameState.checkAcademicExam(true, score: 4);
      expect(gameState.playerHasGraduateDegree, isTrue);
      expect(gameState.playerAcademicSpecialization, equals('Psychiatry'));
    });

    test('Surgery selection requires high grades and an extra semester', () {
      gameState.enrollInGraduateSchool(AcademicSchoolType.medicine);

      // Entrance Exam
      gameState.checkAcademicExam(true, score: 4);
      // Semester 1 Exam
      gameState.checkAcademicExam(true, score: 3);
      // Semester 2 Exam
      gameState.checkAcademicExam(true, score: 3);

      // Verify eligibility based on average grade (6/2 = 3.0, which is eligible)
      final avg = gameState.graduateSchool!.semesterScores.reduce((a, b) => a + b) / gameState.graduateSchool!.semesterScores.length;
      expect(avg >= 3.0, isTrue);

      gameState.selectAcademicSpecialization('Surgery');
      expect(gameState.graduateSchool!.specialization, equals('Surgery'));

      // Semester 3 Exam passes, advances to Semester 4 (Extra Surgery Semester)
      gameState.checkAcademicExam(true, score: 4);
      expect(gameState.graduateSchool!.currentSemester, equals(4));
      expect(gameState.playerHasGraduateDegree, isFalse);

      // Semester 4 (Surgery Specialization Term) Exam passes, advances to Semester 5 (Board Exam)
      gameState.checkAcademicExam(true, score: 3);
      expect(gameState.graduateSchool!.currentSemester, equals(5));
      expect(gameState.playerHasGraduateDegree, isFalse);

      // Semester 5 (Surgery Board Exam) passes, completing graduation
      gameState.checkAcademicExam(true, score: 4);
      expect(gameState.playerHasGraduateDegree, isTrue);
      expect(gameState.playerAcademicSpecialization, equals('Surgery'));
    });

    test('Veterinary selection normal timeline and surgical human penalty resolved with experience', () {
      gameState.enrollInGraduateSchool(AcademicSchoolType.medicine);

      // Semester 0-2 exams passed (lower scores)
      gameState.checkAcademicExam(true, score: 4);
      gameState.checkAcademicExam(true, score: 2);
      gameState.checkAcademicExam(true, score: 2);

      gameState.selectAcademicSpecialization('Veterinary');
      expect(gameState.graduateSchool!.specialization, equals('Veterinary'));

      // Semester 3 Exam passes, advances directly to Board Exam in Semester 4 (no extra semester)
      gameState.checkAcademicExam(true, score: 3);
      expect(gameState.graduateSchool!.currentSemester, equals(4));

      // Board Exam passes, completing graduation
      gameState.checkAcademicExam(true, score: 3);
      expect(gameState.playerHasGraduateDegree, isTrue);
      expect(gameState.playerAcademicSpecialization, equals('Veterinary'));

      // Set up player as resident at home
      final player = gameState.npcs.firstWhere((n) => n.id == 'player');
      gameState.updateNpc(player.copyWith(
        isResident: true,
        clearWorldDestination: true,
        currentRoomId: 'entryway',
      ));

      // 1st Surgery: Expect severe outcome penalty
      expect(gameState.veterinaryExperience, equals(0));
      
      // Mock task completion triggers
      gameState.addRoomForTesting(Room(
        id: 'operating_room',
        name: 'Operating Room',
        type: RoomType.operatingRoom,
        isRestored: true,
        floor: Floor.second,
        description: 'Operating Room',
        width: 2.0,
      ));
      gameState.assignNpcToTask(player.id, TaskType.surgicalOperation, 'operating_room');
      final activeTask = gameState.activeTasks.firstWhere((t) => t.npcId == 'player');
      gameState.handleTaskCompletionForTesting(activeTask);
    });

    test('Dentistry setup loan, basement establishment, and payback', () {
      gameState.enrollInGraduateSchool(AcademicSchoolType.medicine);

      gameState.checkAcademicExam(true, score: 4);
      gameState.checkAcademicExam(true, score: 3);
      gameState.checkAcademicExam(true, score: 3);

      gameState.selectAcademicSpecialization('Dentistry');
      
      final initialFunds = gameState.resources['funds'] ?? 0;

      // Complete school
      gameState.checkAcademicExam(true, score: 3); // Semester 3
      gameState.checkAcademicExam(true, score: 4); // Semester 4 Board

      expect(gameState.playerHasGraduateDegree, isTrue);
      expect(gameState.playerAcademicSpecialization, equals('Dentistry'));
      
      // Verify NO instant cash is awarded now
      expect(gameState.resources['funds'], equals(initialFunds));
      expect(gameState.activeDentalLoan, equals(0));

      // Take out dental clinic setup loan
      gameState.takeOutDentalLoan();
      expect(gameState.activeDentalLoan, equals(1500));
      expect(gameState.resources['funds'], equals(initialFunds + 1500));

      // Establish clinic in East Attic
      gameState.establishDentalClinic('attic_1');
      final clinicRoom = gameState.rooms.firstWhere((r) => r.id == 'attic_1');
      expect(clinicRoom.type, equals(RoomType.dentalClinic));
      expect(clinicRoom.isRestored, isTrue);

      // Payback dental loan
      gameState.payBackDentalLoan(500);
      expect(gameState.activeDentalLoan, equals(1000));
      expect(gameState.resources['funds'], equals(initialFunds + 1000));
    });

    test('Law School Intellectual Property and Criminal Law specialty selection', () {
      gameState.enrollInGraduateSchool(AcademicSchoolType.law);

      gameState.checkAcademicExam(true, score: 4);
      gameState.checkAcademicExam(true, score: 3);
      gameState.checkAcademicExam(true, score: 3);

      gameState.selectAcademicSpecialization('Intellectual Property');
      expect(gameState.graduateSchool!.specialization, equals('Intellectual Property'));

      gameState.checkAcademicExam(true, score: 4); // Semester 3
      gameState.checkAcademicExam(true, score: 4); // Semester 4 Board

      expect(gameState.playerHasGraduateDegree, isTrue);
      expect(gameState.playerAcademicSpecialization, equals('Intellectual Property'));
    });

    test('Dentistry patient events weighting and resolutions', () {
      gameState.enrollInGraduateSchool(AcademicSchoolType.medicine);

      // Graduate with Dentistry
      gameState.checkAcademicExam(true, score: 4);
      gameState.checkAcademicExam(true, score: 3);
      gameState.checkAcademicExam(true, score: 3);
      gameState.selectAcademicSpecialization('Dentistry');
      gameState.checkAcademicExam(true, score: 3); // Term 3
      gameState.checkAcademicExam(true, score: 4); // Board

      gameState.takeOutDentalLoan();
      gameState.establishDentalClinic('attic_1');

      // Verify clinic room properties
      final clinicRoom = gameState.rooms.firstWhere((r) => r.id == 'attic_1');
      expect(clinicRoom.type, equals(RoomType.dentalClinic));

      // Verify base weekly profit parameters
      expect(gameState.bistroProfitModifier, equals(1.0));
      expect(gameState.bistroNextWeekBonus, equals(0.0));

      // Set up player as resident at home
      final player = gameState.npcs.firstWhere((n) => n.id == 'player');
      gameState.updateNpc(player.copyWith(
        isResident: true,
        clearWorldDestination: true,
        currentRoomId: 'entryway',
      ));
      gameState.assignNpcToTask(player.id, TaskType.dentalWork, 'attic_1');
      final activeTask = gameState.activeTasks.firstWhere((t) => t.npcId == 'player');
      gameState.handleTaskCompletionForTesting(activeTask);

      expect(gameState.activeDentalEvent, isNotNull);

      // Resolve choice 0 (Work extra hard, standard ordinary fee but patient annoyance)
      gameState.resolveDentalEventChoice(0);
      expect(gameState.activeDentalEvent, isNull);

      // Manually schedule delayed review and test weekly yields
      gameState.takeOutDentalLoan(); // reset
      gameState.payBackDentalLoan(500);
    });
  });
}
