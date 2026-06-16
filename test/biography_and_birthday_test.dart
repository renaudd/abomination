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
import 'package:abomination/models/game_date.dart';
import 'package:abomination/services/npc_generator.dart';
import 'package:abomination/state/game_state.dart';

void main() {
  group('Character Biography Tests', () {
    test('Biographies are successfully and formulaically generated with all age details', () {
      final currentDate = GameDate(minute: 0, hour: 12, day: 15, month: 5, year: 1818);

      // Young master (inheritor of Swiss estate)
      final youngMasterRes = NPCGenerator.generateBiographyForCharacter(
        role: 'Master',
        age: 25,
        currentDate: currentDate,
        gender: 'Male',
      );

      expect(youngMasterRes.biography.characterClass, 'Noble');
      expect(youngMasterRes.biography.placeOfBirth, anyOf('Geneva', 'Lausanne', 'Neuchâtel', 'Vevey'));
      expect(youngMasterRes.biography.fatherClass, 'Noble');
      expect(youngMasterRes.biography.parentsMaritalStatus, 'in wedlock');
      expect(youngMasterRes.biography.childhoodEvent, isNotNull);
      expect(youngMasterRes.biography.educationOrApprenticeship, isNotNull);
      expect(youngMasterRes.biography.profession, 'Estate Master');
      expect(youngMasterRes.biography.relationshipStatus, isNotNull);
      expect(youngMasterRes.biography.tragicEvent, isNull); // younger than 30
      expect(youngMasterRes.biography.discoveredPassion, isNull); // younger than 40
      expect(youngMasterRes.biography.healthIssue, isNull); // younger than 50

      // Middle aged master
      final midMasterRes = NPCGenerator.generateBiographyForCharacter(
        role: 'Master',
        age: 45,
        currentDate: currentDate,
        gender: 'Male',
      );
      expect(midMasterRes.biography.tragicEvent, isNotNull);
      expect(midMasterRes.biography.discoveredPassion, isNotNull);
      expect(midMasterRes.biography.healthIssue, isNull);

      // Old master
      final oldMasterRes = NPCGenerator.generateBiographyForCharacter(
        role: 'Master',
        age: 55,
        currentDate: currentDate,
        gender: 'Male',
      );
      expect(oldMasterRes.biography.healthIssue, isNotNull);

      // Butler caretaker constraints
      final butlerRes = NPCGenerator.generateBiographyForCharacter(
        role: 'Butler',
        age: 55,
        currentDate: currentDate,
        gender: 'Male',
      );
      expect(butlerRes.biography.characterClass, 'Servant');
      expect(butlerRes.biography.fatherClass, 'Servant');
      expect(butlerRes.biography.fatherProfession, anyOf('Butler', 'Valet', 'Clerk', 'Head Gardener'));

      // Bio paragraphs can be successfully generated
      final paragraph = youngMasterRes.biography.toParagraph();
      expect(paragraph, contains('Born on'));
      expect(paragraph, contains('Father:'));
      expect(paragraph, contains('Mother:'));
    });

    test('Religion matching and conversion biographical descriptions are generated correctly', () {
      final currentDate = GameDate(minute: 0, hour: 12, day: 15, month: 5, year: 1818);

      int conversionCount = 0;
      for (int i = 0; i < 50; i++) {
        final res = NPCGenerator.generateBiographyForCharacter(
          role: 'Refugee',
          age: 30,
          currentDate: currentDate,
          gender: 'Female',
        );
        final bio = res.biography;
        if (res.childReligion != bio.fatherReligion) {
          conversionCount++;
          expect(bio.religiousConversionEvent, isNotNull);
          expect(bio.toParagraph(), contains(bio.religiousConversionEvent!));
        } else {
          expect(bio.religiousConversionEvent, isNull);
        }
      }
      expect(conversionCount, greaterThan(0));
      expect(conversionCount, lessThan(50));
    });

    test('Frankenstein (Master) and Giles (Butler) are unmarried at start, and spouses are generated for married NPCs', () {
      final state = GameState();
      state.initializeNewGame(
        firstName: "Victor",
        lastName: "Frankenstein",
        estateName: "Geneva Manor",
        deathCause: DeathCause.trainCrash,
        age: 35,
        gilesTrait: GilesTrait.silent,
        objective: LifeObjective.science,
      );

      final master = state.npcs.firstWhere((n) => n.isPlayer);
      final butler = state.npcs.firstWhere((n) => n.role == 'Butler');

      expect(master.biography?.relationshipStatus, isNot('married'));
      expect(butler.biography?.relationshipStatus, isNot('married'));

      int marriedCount = 0;
      for (int i = 0; i < 20; i++) {
        final originalCount = state.npcs.length;
        state.spawnRefugee();
        final latest = state.npcs[originalCount];
        if (latest.biography?.relationshipStatus == 'married') {
          marriedCount++;
          final spouseId = "spouse_${latest.id}";
          final spouse = state.npcs.firstWhere((n) => n.id == spouseId);
          expect(spouse, isNotNull);
          expect(spouse.isResident, isFalse);
          expect(spouse.currentRoomId, isNull);
          expect(spouse.relationships.containsKey(latest.id), isTrue);
          expect(latest.relationships.containsKey(spouse.id), isTrue);
        }
      }
      expect(marriedCount, greaterThan(0));
    });
  });

  group('Birthday Celebration & Custom Payout Tests', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
      gameState.initializeNewGame(
        firstName: "Alphonse",
        lastName: "Frankenstein",
        estateName: "Vaud Manor",
        deathCause: DeathCause.trainCrash,
        age: 30,
        gilesTrait: GilesTrait.silent,
        objective: LifeObjective.science,
      );
    });

    test('Birthday celebrations trigger dining hall gatherings and boost satisfaction/relationships', () {
      // Let's locate the player
      final playerIdx = gameState.npcs.indexWhere((n) => n.isPlayer);
      expect(playerIdx, isNot(-1));
      final player = gameState.npcs[playerIdx];


      
      final updatedPlayer = player.copyWith(
        birthDate: GameDate(minute: 0, hour: 12, day: 1, month: 3, year: 1788), // born 1788, 30yo
      );
      gameState.updateNpcForTesting(updatedPlayer);

      // Reload game state from JSON to trigger once-a-day birthday check for today
      gameState.loadFromJson(gameState.toJson());
      gameState.setSpeed(GameSpeed.normal);

      // Advance time to 18:00
      gameState.tick(); // current hour ticks to 9... let's set hour to 18
      
      // We can just call the internal birthday celebration trigger manually for test validation
      // Since _checkAndProcessBirthdays is private, we can verify by setting _currentDate to 18:00 and calling tick()!
      // Let's see how to set current date, or just let it run till 18:00.
      // But wait! initializeNewGame sets initial date to hour 8.
      // Let's tick 10 times (10 hours) to reach hour 18!
      for (int h = 0; h < 10; h++) {
        // 60 ticks per hour
        for (int m = 0; m < 60; m++) {
          gameState.tick();
        }
      }

      // Confirm it is now hour 18
      expect(gameState.currentDate.hour, 18);

      // The player should now have had their birthday celebration!
      final freshPlayer = gameState.npcs.firstWhere((n) => n.isPlayer);
      expect(freshPlayer.currentRoomId, 'dining_hall');
      expect(freshPlayer.currentThought, contains('birthday'));
      
      // Verify satisfaction boost
      expect(freshPlayer.satisfaction, greaterThan(30.0));
    });
  });
}
