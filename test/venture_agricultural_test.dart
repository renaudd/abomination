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
import 'package:abomination/models/room.dart';
import 'package:abomination/models/crop.dart';
import 'package:abomination/models/manor_venture.dart';
import 'package:abomination/models/dish.dart';
import 'package:abomination/services/task_service.dart';
import 'package:abomination/models/npc_intent.dart';
import 'package:abomination/state/game_state.dart';

void main() {
  late GameState gameState;

  setUp(() {
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

  group('Farming & Seasonal Cultivation Parameters', () {
    test('Greenhouse bypasses seasonal growth stunting for Cannabis', () {
      gameState.setResource('funds', 1000);
      gameState.setResource('wood', 1000);
      gameState.buildGreenhouse('lot_garden');

      final greenhouse = gameState.rooms.firstWhere((r) => r.type == RoomType.greenhouse);
      final field = gameState.rooms.firstWhere((r) => r.type == RoomType.field);

      gameState.updateRoom(greenhouse.copyWith(tilledAmount: 1.0, isRestored: true));
      gameState.updateRoom(field.copyWith(tilledAmount: 1.0, isRestored: true));

      gameState.setResource('seeds_cannabis', 50);

      expect(gameState.currentDate.month, 3); // Abomination starts in March

      gameState.plantCrops(CropType.cannabis, field.id);
      gameState.plantCrops(CropType.cannabis, greenhouse.id);

      final fieldCrop = gameState.crops.firstWhere((c) => c.roomId == field.id);
      final greenhouseCrop = gameState.crops.firstWhere((c) => c.roomId == greenhouse.id);

      for (int i = 0; i < 60; i++) {
        gameState.setSpeed(GameSpeed.normal);
        gameState.tick();
      }

      final updatedFieldCrop = gameState.crops.firstWhere((c) => c.id == fieldCrop.id);
      final updatedGreenhouseCrop = gameState.crops.firstWhere((c) => c.id == greenhouseCrop.id);

      expect(updatedGreenhouseCrop.growthProgress, greaterThan(updatedFieldCrop.growthProgress));
    });

    test('Mushrooms are stunted in open fields but grow normally in basement cellar rooms', () {
      // Set basement_1 to restored and type basement!
      final b1 = gameState.rooms.firstWhere((r) => r.id == 'basement_1');
      gameState.updateRoom(b1.copyWith(type: RoomType.basement, isRestored: true, tilledAmount: 1.0));

      final basement = gameState.rooms.firstWhere((r) => r.type == RoomType.basement);
      final field = gameState.rooms.firstWhere((r) => r.type == RoomType.field);

      gameState.updateRoom(basement.copyWith(tilledAmount: 1.0, isRestored: true));
      gameState.updateRoom(field.copyWith(tilledAmount: 1.0, isRestored: true));

      gameState.setResource('mushroom_spores', 50);

      gameState.plantCrops(CropType.mushroom, field.id);
      gameState.plantCrops(CropType.mushroom, basement.id);

      final fieldMushroom = gameState.crops.firstWhere((c) => c.roomId == field.id);
      final basementMushroom = gameState.crops.firstWhere((c) => c.roomId == basement.id);

      for (int i = 0; i < 60; i++) {
        gameState.setSpeed(GameSpeed.normal);
        gameState.tick();
      }

      final updatedFieldMushroom = gameState.crops.firstWhere((c) => c.id == fieldMushroom.id);
      final updatedBasementMushroom = gameState.crops.firstWhere((c) => c.id == basementMushroom.id);

      expect(updatedBasementMushroom.growthProgress, greaterThan(updatedFieldMushroom.growthProgress));
    });
  });

  group('Restaurant Venture & Dining loop', () {
    test('Served dining dishes pay multiplied funds based on quality', () {
      gameState.setManorVenture(ManorVenture.restaurant);
      expect(gameState.manorVenture, ManorVenture.restaurant);

      final initialFunds = gameState.resources['funds'] ?? 0;

      gameState.forceSpawnDiner();

      final diner = gameState.npcs.firstWhere((n) => n.metadata['isDiner'] == true);
      expect(diner, isNotNull);

      final testDish = Dish(
        id: "premium_stew",
        name: "Fine Venison Stew",
        type: DishType.protein,
        quality: DishQuality.exquisite,
        cookedAt: gameState.currentDate,
        value: 10,
      );
      gameState.addDishToPantry(testDish);

      final success = gameState.serveDiner(diner.id, testDish.id);
      expect(success, isTrue);

      final currentFunds = gameState.resources['funds'] ?? 0;
      expect(currentFunds, greaterThan(initialFunds));
      expect(gameState.npcs.where((n) => n.id == diner.id).isEmpty, isTrue);
    });
  });

  group('Kompromat Blackmail Hotel Loop', () {
    test('Lodger checks in, gets spied upon compiling secrets, and blackmailed for hushed ransom', () {
      gameState.setManorVenture(ManorVenture.kompromatHotel);

      gameState.forceSpawnHotelGuest();

      final guest = gameState.npcs.firstWhere((n) => n.metadata['isHotelGuest'] == true);
      expect(guest, isNotNull);

      // Fetch butler (Giles) and customize stats/id to ensure 100% deterministic spying success
      final butler = gameState.npcs.firstWhere((n) => n.id == 'butler');
      final updatedButler = butler.copyWith(
        id: 'spy_butler_agent', // Contains 'agent' to bypass behavior tree overrides!
        stats: {
          ...butler.stats,
          'dexterity': 10,
          'perception': 10,
        },
      );
      gameState.addNpcForTesting(updatedButler);

      final spySuccess = gameState.startSpyingOnGuest(updatedButler.id, guest.id);
      expect(spySuccess, isTrue);

      final updatedResident = gameState.npcs.firstWhere((n) => n.id == updatedButler.id);
      expect(updatedResident.activeTaskId, isNotNull);

      for (int i = 0; i < 121; i++) {
        gameState.setSpeed(GameSpeed.normal);
        gameState.tick();
      }

      expect(gameState.resources['kompromat_folder'] ?? 0, greaterThanOrEqualTo(1));
    });
  });

  group('Refine Plant/Fungus Task', () {
    test('Refining cannabis buds consumes buds and extracts cannabis seeds', () {
      final butler = gameState.npcs.firstWhere((n) => n.id == 'butler');
      final updatedButler = butler.copyWith(
        id: 'refine_butler_agent', // Contains 'agent' to bypass behavior tree overrides!
      );
      gameState.addNpcForTesting(updatedButler);
      
      gameState.setResource('cannabis_buds', 10.0);
      gameState.setResource('seeds_cannabis', 0.0);

      final task = GameTask(
        id: 'refine_123',
        npcId: updatedButler.id,
        priority: IntentPriority.high,
        type: TaskType.refinePlantFungus,
        targetId: 'vegetable_garden',
        minutesRemaining: 60,
        totalMinutes: 60,
      );

      // Set activeTaskId on the resident to ensure processTick ticks the task
      gameState.updateNpc(updatedButler.copyWith(
        activeTaskId: 'refine_123',
        currentRoomId: 'vegetable_garden',
        targetRoomId: 'vegetable_garden',
      ));

      gameState.taskService.addTask(task);

      for (int i = 0; i < 61; i++) {
        gameState.setSpeed(GameSpeed.normal);
        gameState.tick();
      }

      expect(gameState.resources['cannabis_buds'], 8.0);
      expect(gameState.resources['seeds_cannabis'], 4.0);
    });
  });
}
