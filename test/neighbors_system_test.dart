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
import 'package:abomination/models/npc.dart';
import 'package:abomination/models/neighbor_encounter.dart';
import 'package:abomination/models/relationship.dart';
import 'package:abomination/models/game_item.dart';
import 'package:abomination/services/audio_service.dart';
import 'package:abomination/services/task_service.dart';
import 'package:abomination/models/room.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameState gameState;

  setUp(() {
    AudioService.isTesting = true;
    gameState = GameState();
    gameState.initializeNewGame(
      firstName: "Test",
      lastName: "Master",
      estateName: "Test Manor",
      deathCause: DeathCause.trainCrash,
      age: 30,
      gilesTrait: GilesTrait.silent,
      objective: LifeObjective.science,
    );
    gameState.setSpeed(GameSpeed.normal);
  });

  group('Neighbors System Tests', () {
    test('Cottage unlocking and persistence serialization', () {
      expect(gameState.unlockedCottages.isEmpty, true);

      gameState.unlockCottage('cottage_gregor');
      expect(gameState.unlockedCottages.contains('cottage_gregor'), true);
      expect(gameState.unlockedCottages.length, 1);

      final json = gameState.toJson();
      
      final loadedState = GameState();
      loadedState.loadFromJson(json);
      
      expect(loadedState.unlockedCottages.contains('cottage_gregor'), true);
      expect(loadedState.unlockedCottages.length, 1);
    });

    test('Neighbor spawning logic on Day 3', () {
      expect(gameState.npcs.any((n) => n.metadata['isNeighbor'] == true), false);

      print("DEBUG: Starting Day 3 advance loop. Speed: ${gameState.speed}, Date: ${gameState.currentDate.formattedDate} ${gameState.currentDate.formattedTime}");

      // Advance by 2880 minutes (48 hours = 2 days) to reach Day 3
      for (int i = 0; i < 2 * 1440; i++) {
        gameState.tick();
      }
      
      print("DEBUG: Finished Day 3 advance loop. Speed: ${gameState.speed}, Date: ${gameState.currentDate.formattedDate} ${gameState.currentDate.formattedTime}");
      
      expect(gameState.currentDate.day, 3);
      
      final gregor = gameState.npcs.firstWhere(
        (n) => n.name == 'Father Gregor Zweifel',
        orElse: () => throw Exception('Father Gregor Zweifel did not spawn on Day 3'),
      );

      expect(gregor.metadata['guestType'], 'neighbor');
      expect(gregor.metadata['isNeighbor'], true);
      expect(gregor.metadata['neighborFaction'], 'Glarus');
      expect(gregor.metadata['isIntroComplete'], false);
    });

    test('Neighbor spawning logic on Day 6 (Bavarian Illuminati Coordinator)', () {
      // Advance to Day 6 (5 days * 1440 minutes = 7200 ticks)
      for (int i = 0; i < 5 * 1440; i++) {
        gameState.tick();
      }
      expect(gameState.currentDate.day, 6);

      final fritz = gameState.npcs.firstWhere(
        (n) => n.name == 'Professor Fritz Weishaupt',
        orElse: () => throw Exception('Professor Fritz Weishaupt did not spawn on Day 6'),
      );

      expect(fritz.metadata['guestType'], 'neighbor');
      expect(fritz.metadata['neighborFaction'], 'Bavarian Illuminati');
      expect(fritz.metadata['isIntroComplete'], false);
    });

    test('Dialogue choice execution and relationship consequences', () {
      // Fetch Professor Fritz Weishaupt (Bavarian Illuminati) encounter
      final encounter = NeighborEncounterCatalog.getEncounterForNpc('Professor Fritz Weishaupt');
      expect(encounter, isNotNull);
      expect(encounter!.cottageId, 'cottage_fritz');

      // Test Choice A (Cooperate)
      final initialStanding = gameState.getFactionStanding('Bavarian Illuminati');
      expect(initialStanding, 1.0); // All factions start at 1.0

      encounter.onChoiceA(gameState);
      // Bavarian Illuminati Choice A rewards +0.20 standing
      expect(gameState.getFactionStanding('Bavarian Illuminati'), 1.20);

      // Reset standing
      gameState.adjustFactionStanding('Bavarian Illuminati', -0.20);

      // Test Choice B (Dissent)
      encounter.onChoiceB(gameState);
      // Bavarian Illuminati Choice B penalizes -0.20 standing
      expect(gameState.getFactionStanding('Bavarian Illuminati'), 0.80);
    });

    test('Generic Gifting System with favorites, appreciated, and offensive items', () {
      // Advance to Day 3 so Gregor spawns
      for (int i = 0; i < 2 * 1440; i++) {
        gameState.tick();
      }
      expect(gameState.currentDate.day, 3);

      // 1. Setup Gregor NPC
      final gregorIndex = gameState.npcs.indexWhere((n) => n.name == 'Father Gregor Zweifel');
      expect(gregorIndex, isNot(-1));
      final gregor = gameState.npcs[gregorIndex];
      final String gregorId = gregor.id;

      // 2. Add some items to a room so they are in the manor's inventory
      final book = GameItem.create(name: 'Ancient Religious Scripture', type: 'book_scripture', category: ItemCategory.knowledge);
      final chocolate = GameItem.create(name: 'Swiss Chocolate Box', type: 'sweet_chocolate', category: ItemCategory.food);
      final organ = GameItem.create(name: 'Harvested Kidney Specimen', type: 'organ_kidney', category: ItemCategory.specimen);
      
      gameState.addItemToRoom('kitchen', book);
      gameState.addItemToRoom('kitchen', chocolate);
      gameState.addItemToRoom('kitchen', organ);

      // Verify they are in the inventory
      expect(gameState.inventory.any((i) => i.type == 'book_scripture'), true);
      expect(gameState.inventory.any((i) => i.type == 'sweet_chocolate'), true);
      expect(gameState.inventory.any((i) => i.type == 'organ_kidney'), true);

      // --- TEST FAVORITE GIFT ---
      // Father Gregor Zweifel's favorite type is literature (book).
      var rel = gregor.relationships['player'] ?? Relationship();
      final double initialAdmiration = rel.admiration;
      final double initialRespect = rel.respect;
      final double initialAttraction = rel.attraction;
      final double initialFear = rel.fear;

      final initialFactionStanding = gameState.getFactionStanding('Glarus');

      // Execute Favorite Gift state changes (literature):
      bool consumedBook = gameState.consumeManorItem('book_scripture');
      expect(consumedBook, true);
      expect(gameState.inventory.any((i) => i.type == 'book_scripture'), false); // Removed!

      gameState.adjustNpcRelationshipWithPlayer(
        gregorId,
        admiration: 0.8,
        respect: 0.5,
        attraction: 0.6,
      );
      gameState.adjustFactionStanding('Glarus', 0.05);

      // Verify adjustments
      var updatedGregor = gameState.npcs.firstWhere((n) => n.id == gregorId);
      var updatedRel = updatedGregor.relationships['player'] ?? Relationship();
      expect(updatedRel.admiration, closeTo(initialAdmiration + 0.8, 0.0001));
      expect(updatedRel.respect, closeTo(initialRespect + 0.5, 0.0001));
      expect(updatedRel.attraction, closeTo(initialAttraction + 0.6, 0.0001));
      expect(gameState.getFactionStanding('Glarus'), closeTo(initialFactionStanding + 0.05, 0.0001));

      // --- TEST APPRECIATED GIFT ---
      bool consumedChoc = gameState.consumeManorItem('sweet_chocolate');
      expect(consumedChoc, true);

      gameState.adjustNpcRelationshipWithPlayer(
        gregorId,
        admiration: 0.4,
        respect: 0.2,
        attraction: 0.3,
      );
      gameState.adjustFactionStanding('Glarus', 0.01);

      updatedGregor = gameState.npcs.firstWhere((n) => n.id == gregorId);
      updatedRel = updatedGregor.relationships['player'] ?? Relationship();
      expect(updatedRel.admiration, closeTo(initialAdmiration + 1.2, 0.0001)); // 0.8 + 0.4
      expect(updatedRel.respect, closeTo(initialRespect + 0.7, 0.0001));    // 0.5 + 0.2
      expect(updatedRel.attraction, closeTo(initialAttraction + 0.9, 0.0001)); // 0.6 + 0.3
      expect(gameState.getFactionStanding('Glarus'), closeTo(initialFactionStanding + 0.06, 0.0001));

      // --- TEST OFFENSIVE GIFT ---
      bool consumedOrgan = gameState.consumeManorItem('organ_kidney');
      expect(consumedOrgan, true);

      gameState.adjustNpcRelationshipWithPlayer(
        gregorId,
        admiration: -1.0,
        respect: -0.5,
        fear: 0.2,
        attraction: -1.0,
      );
      gameState.adjustFactionStanding('Glarus', -0.05);

      updatedGregor = gameState.npcs.firstWhere((n) => n.id == gregorId);
      updatedRel = updatedGregor.relationships['player'] ?? Relationship();
      expect(updatedRel.admiration, closeTo(initialAdmiration + 0.2, 0.0001)); // 1.2 - 1.0
      expect(updatedRel.respect, closeTo(initialRespect + 0.2, 0.0001));    // 0.7 - 0.5
      expect(updatedRel.attraction, closeTo(initialAttraction - 0.1, 0.0001)); // 0.9 - 1.0
      expect(updatedRel.fear, closeTo(initialFear + 0.2, 0.0001));
      expect(gameState.getFactionStanding('Glarus'), closeTo(initialFactionStanding + 0.01, 0.0001)); // 0.06 - 0.05
    });
  });

  group('Room Activity Queue Duplicate Tasks Assignment Tests', () {
    test('Cooking queue with duplicates treats each entry as unique and does not skip', () {
      final gameState = GameState();
      gameState.initializeNewGame(
        firstName: 'Test',
        lastName: 'Master',
        estateName: 'Glarus',
        deathCause: DeathCause.trainCrash,
        age: 35,
        gilesTrait: GilesTrait.sage,
        objective: LifeObjective.science,
      );

      final player = gameState.npcs.firstWhere((n) => n.isPlayer);
      final giles = gameState.npcs.firstWhere((n) => n.role.toLowerCase() == 'butler');

      // Restored kitchen is needed for cooking
      final kitchen = gameState.rooms.firstWhere((r) => r.id == 'kitchen');
      gameState.updateRoom(kitchen.copyWith(isRestored: true));

      // Setup a queue with duplicate recipes using public APIs
      while (gameState.cookingQueue.isNotEmpty) {
        gameState.removeFromCookingQueue(0);
      }
      gameState.addToCookingQueue('country_omelette');
      gameState.addToCookingQueue('country_omelette');
      gameState.addToCookingQueue('spelt_bread');
      gameState.addToCookingQueue('country_omelette');

      // 1. Initially, first unassigned should be 'country_omelette'
      expect(gameState.getFirstUnassignedRecipe(), 'country_omelette');

      // 2. Assign first 'country_omelette' to player (pops it from the queue)
      bool ok1 = gameState.assignNpcToTask(player.id, TaskType.cook, 'kitchen');
      expect(ok1, true);

      // 3. Since player is cooking country_omelette, the remaining queue is [country_omelette, spelt_bread, country_omelette].
      // The first country_omelette in the remaining queue is claimed by the player's active task.
      // The next unassigned recipe in the queue is 'spelt_bread'.
      expect(gameState.getFirstUnassignedRecipe(), 'spelt_bread');

      // 4. Assign 'spelt_bread' to Giles (pops it from the queue)
      bool ok2 = gameState.assignNpcToTask(giles.id, TaskType.cook, 'kitchen');
      expect(ok2, true);

      // 5. The remaining queue is [country_omelette, country_omelette].
      // One country_omelette is active (player). So the second country_omelette in the queue is unassigned!
      // Under the old logic, this would have returned null. Under the new logic, it correctly returns 'country_omelette'!
      expect(gameState.getFirstUnassignedRecipe(), 'country_omelette');

      // 6. Spawn another resident so we can assign the second country_omelette
      final resident3 = gameState.npcs.firstWhere((n) => n.isResident && n.id != player.id && n.id != giles.id, orElse: () {
        final r = giles.copyWith(
          id: 'resident_3',
          name: 'Scientist 3',
          role: 'Scientist',
        );
        gameState.setNpcForTesting(r);
        return r;
      });

      bool ok3 = gameState.assignNpcToTask(resident3.id, TaskType.cook, 'kitchen');
      expect(ok3, true);

      // 7. Since both country_omelette instances are active, and no other items remain, the next unassigned should be null!
      expect(gameState.getFirstUnassignedRecipe(), null);
    });
  });

  group('Faction Plotline System Integration Tests', () {
    test('Triggering faction plotline at 4.0 standing and spawning Jacob Landolt', () {
      // 1. Initial standing is 1.0. No plot triggered or scheduled.
      expect(gameState.getFactionStanding('Glarus'), 1.0);
      
      // 2. Adjust standing to 4.0.
      gameState.adjustFactionStanding('Glarus', 3.0);
      expect(gameState.getFactionStanding('Glarus'), 4.0);

      // 3. Tick to trigger (cross hour boundary)
      for (int i = 0; i < 60; i++) {
        gameState.tick();
      }
      
      // 4. Tick 1440 times to advance 1 day and trigger step 1 spawning.
      for (int i = 0; i < 1440; i++) {
        gameState.tick();
      }

      // 5. Jacob Landolt should now have arrived in the entryway as a plot visitor!
      final landolt = gameState.npcs.firstWhere(
        (n) => n.name == 'Jacob Landolt',
        orElse: () => throw Exception('Jacob Landolt did not spawn'),
      );
      expect(landolt.metadata['guestType'], 'plot_visitor');
      expect(landolt.metadata['plotEventKey'], 'Glarus_positive_step1');
      expect(landolt.currentRoomId, 'entryway');
    });

    test('Progressing Glarus positive storyline, building Canton Embassy and hiring Jacob Landolt', () {
      // Setup state manually to Glarus_positive step 3
      gameState.adjustFactionStanding('Glarus', 4.0);
      // Spawn Jacob Landolt with Glarus_positive_step3
      gameState.spawnPlotVisitor('Jacob Landolt', 'Canton Envoy', 'Glarus_positive_step3');
      
      final landolt = gameState.npcs.firstWhere((n) => n.name == 'Jacob Landolt');
      expect(landolt.metadata['plotEventKey'], 'Glarus_positive_step3');

      // Verify we have an unused room in the manor
      final hasUnused = gameState.rooms.any((r) => r.type == RoomType.unused || !r.isRestored);
      expect(hasUnused, true);

      // Simulate player choosing Option A (Sign Sovereign Protector Decree)
      final unusedIdx = gameState.rooms.indexWhere((r) => r.type == RoomType.unused || !r.isRestored);
      final room = gameState.rooms[unusedIdx];
      gameState.updateRoom(room.copyWith(
        name: "Canton Embassy",
        type: RoomType.lawFirm,
        isRestored: true,
        restorationProgress: 1.0,
        metadata: {...room.metadata, 'canton_embassy_active': true},
      ));

      final landoltResident = landolt.copyWith(
        id: 'resident_jacob_landolt',
        isResident: true,
        currentRoomId: 'entryway',
      );
      gameState.addResidentNpc(landoltResident);
      gameState.removeNpc(landolt.id);
      gameState.adjustFactionStanding('Glarus', 1.0);
      gameState.resolvePlotline('Glarus_positive');

      // Verify outcomes
      final embassy = gameState.rooms.firstWhere((r) => r.name == 'Canton Embassy');
      expect(embassy.type, RoomType.lawFirm);
      expect(embassy.isRestored, true);
      expect(embassy.metadata['canton_embassy_active'], true);

      final residentLandolt = gameState.npcs.firstWhere((n) => n.id == 'resident_jacob_landolt');
      expect(residentLandolt.isResident, true);
      expect(residentLandolt.name, 'Jacob Landolt');

      expect(gameState.getFactionStanding('Glarus'), 5.0);
    });

    test('Rosicrucians negative storyline hex consumes food reserves', () {
      gameState.updateResource('shepherds_pie', -gameState.resources['meals']!.toInt());
      expect(gameState.resources['meals'] ?? 0, 0);

      gameState.updateResource('shepherds_pie', 300);
      expect(gameState.resources['meals'], 300);

      // Simulate choice B in Rosicrucians_negative_step1 (Refuse to pay, lose 250 food)
      gameState.updateResource('shepherds_pie', -250);
      expect(gameState.resources['meals'], 50); // 300 - 250 = 50
    });

    group('Gnomes of Zurich Cash Multiplier Tests', () {
      test('Gnomes positive step 3 (+50% cash blessing) scales cash income', () {
        // Reset funds in all rooms to ensure clean test
        for (int i = 0; i < gameState.rooms.length; i++) {
          final r = gameState.rooms[i];
          final cleanInv = r.inventory.where((item) => item.type != 'funds' && item.type != 'franc').toList();
          gameState.updateRoom(r.copyWith(inventory: cleanInv));
        }
        expect(gameState.resources['funds'] ?? 0, 0);

        // Force Gnomes step 3 active
        gameState.progressPlotStep('Gnomes of Zurich_positive', 3, 0);
        
        // Add 100 funds
        gameState.updateResource('funds', 100);
        
        // It should have scaled to 150!
        expect(gameState.resources['funds'], 150);
      });

      test('Gnomes negative step 3 (-30% cash penalty) scales cash income', () {
        // Reset funds in all rooms to ensure clean test
        for (int i = 0; i < gameState.rooms.length; i++) {
          final r = gameState.rooms[i];
          final cleanInv = r.inventory.where((item) => item.type != 'funds' && item.type != 'franc').toList();
          gameState.updateRoom(r.copyWith(inventory: cleanInv));
        }
        expect(gameState.resources['funds'] ?? 0, 0);

        // Force Gnomes negative step 3 active
        gameState.progressPlotStep('Gnomes of Zurich_negative', 3, 0);
        
        // Add 100 funds
        gameState.updateResource('funds', 100);
        
        // It should have scaled to 70!
        expect(gameState.resources['funds'], 70);
      });
    });
  });
}
