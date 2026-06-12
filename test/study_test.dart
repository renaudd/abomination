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
import 'package:abomination/services/task_service.dart';
import 'package:abomination/models/npc_intent.dart';
import 'package:abomination/models/game_item.dart';
import 'package:abomination/models/objective.dart';

void main() {
  group('Study & Science Mechanics', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
      gameState.initializeNewGame(
        firstName: "Science",
        lastName: "Tester",
        estateName: "Lab Estate",
        deathCause: DeathCause.disease,
        age: 40,
        gilesTrait: GilesTrait.sage,
        objective: LifeObjective.science,
      );
    });

    test('Generic meat recipes work in Kitchen', () {
      // Clear kitchen inventory first so only rat meat is there
      final kitchen = gameState.rooms.firstWhere((r) => r.id == 'kitchen');
      gameState.updateRoom(kitchen.copyWith(inventory: []));

      // Add rat meat and generic meat
      final ratMeat = GameItem.create(
        name: 'Rat Meat',
        type: 'meat_rat',
        category: ItemCategory.food,
        quantity: 2,
      );

      gameState.addItemToRoom('kitchen', ratMeat);

      // Ensure we have other ingredients for "Stew of Unknown Protein"
      // Recipe: meat: 1, potato: 1, salt: 1
      gameState.updateResource('potato', 5);
      gameState.updateResource('salt', 5);

      // Cook it
      final cookTask = GameTask(
        id: 'cook_stew',
        npcId: gameState.npcs.first.id,
        priority: IntentPriority.normal,
        type: TaskType.cook,
        targetId: 'kitchen',
        recipeId: 'protein_mistery_stew',
        minutesRemaining: 1,
      );

      gameState.completeTaskManually(gameState.npcs.first.id, cookTask);

      // Verify meat was consumed and meals produced
      final updatedKitchen = gameState.rooms.firstWhere(
        (r) => r.id == 'kitchen',
      );
      expect(
        updatedKitchen.inventory.any(
          (i) => i.type == 'meat_rat' && i.quantity == 1,
        ),
        isTrue,
      );
      // Meals are added to resources or pantry
      expect(gameState.resources['meals']! > 0, isTrue);
    });

    test('Dissection consumes specimen and produces notes and meat', () {
      // Add rat specimen to study
      final ratSpecimen = GameItem.create(
        name: 'Dead Rat',
        type: 'rat_specimen',
        category: ItemCategory.specimen,
        quantity: 1,
      );
      gameState.addItemToRoom('study', ratSpecimen);

      final dissectTask = GameTask(
        id: 'dissect_rat',
        npcId: gameState.npcs.first.id,
        priority: IntentPriority.normal,
        type: TaskType.dissect,
        targetId: 'study',
        recipeId: 'small_dissection',
        minutesRemaining: 1,
      );

      gameState.completeTaskManually(gameState.npcs.first.id, dissectTask);

      // Verify specimen consumed
      final study = gameState.rooms.firstWhere((r) => r.id == 'study');
      expect(study.inventory.any((i) => i.type == 'rat_specimen'), isFalse);

      // Verify notes and meat produced in global inventory
      expect(
        gameState.inventory.any((i) => i.type == 'research_notes'),
        isTrue,
      );
      expect(gameState.inventory.any((i) => i.type == 'meat_generic'), isTrue);
    });

    test('Vivisection corrupts worker', () {
      final rat = GameItem.create(
        name: 'Live Rat',
        type: 'rat_specimen',
        category: ItemCategory.specimen,
        quantity: 1,
      );
      gameState.addItemToRoom('study', rat);

      final worker = gameState.npcs.first;
      final updatedWorker = worker.copyWith(
        stats: Map<String, int>.from(worker.stats)..['judgment'] = 10,
      );
      gameState.updateNpcForTesting(updatedWorker);

      final initialSatisfaction = gameState.npcs.first.satisfaction;

      final vivisectionTask = GameTask(
        id: 'vivisect_rat',
        npcId: worker.id,
        priority: IntentPriority.normal,
        type: TaskType.vivisection,
        targetId: 'study',
        recipeId: 'small_vivisection',
        minutesRemaining: 1,
      );

      gameState.completeTaskManually(worker.id, vivisectionTask);

      expect(gameState.npcs.first.satisfaction < initialSatisfaction, isTrue);
    });

    test('Objectives track dissect and vivisection progress', () {
      gameState.setSpeed(GameSpeed.normal);
      // Set up the first construct Step 2 and Step 3 objectives
      gameState.clearObjectivesForTesting();
      gameState.addObjectiveForTesting(
        Objective(
          id: 'first_construct_2',
          title: 'The First Construct - Step 2',
          description: 'Perform Small Specimen Dissection two times.',
          type: ObjectiveType.science,
          requirements: {
            'task_counts': {'dissect': 2},
          },
          nextObjectiveId: 'first_construct_3',
        ),
      );

      // Complete a dissection
      final dissectTask1 = GameTask(
        id: 'dissect_1',
        npcId: gameState.npcs.first.id,
        priority: IntentPriority.normal,
        type: TaskType.dissect,
        targetId: 'study',
        recipeId: 'small_dissection',
        minutesRemaining: 1,
      );
      // Give a specimen to the study
      gameState.addItemToRoom('study', GameItem.create(
        name: 'Dead Rat',
        type: 'rat_specimen',
        category: ItemCategory.specimen,
        quantity: 1,
      ));
      gameState.completeTaskManually(gameState.npcs.first.id, dissectTask1);
      gameState.tick();

      // Verify the task count is 1
      expect(gameState.taskCompletionCounts[TaskType.dissect], equals(1));
      expect(gameState.objectives.firstWhere((o) => o.id == 'first_construct_2').isCompleted, isFalse);

      // Complete second dissection
      gameState.addItemToRoom('study', GameItem.create(
        name: 'Dead Rat 2',
        type: 'rat_specimen',
        category: ItemCategory.specimen,
        quantity: 1,
      ));
      final dissectTask2 = GameTask(
        id: 'dissect_2',
        npcId: gameState.npcs.first.id,
        priority: IntentPriority.normal,
        type: TaskType.dissect,
        targetId: 'study',
        recipeId: 'small_dissection',
        minutesRemaining: 1,
      );
      gameState.completeTaskManually(gameState.npcs.first.id, dissectTask2);
      gameState.tick();

      // Verify objective 2 completes and objective 3 (vivisection) is unlocked
      expect(gameState.taskCompletionCounts[TaskType.dissect], equals(2));
      expect(gameState.objectives.firstWhere((o) => o.id == 'first_construct_2').isCompleted, isTrue);
      expect(gameState.objectives.any((o) => o.id == 'first_construct_3'), isTrue);

      // Complete vivisections for Step 3
      final obj3 = gameState.objectives.firstWhere((o) => o.id == 'first_construct_3');
      expect(obj3.description, equals('Perform Small Specimen Vivisection two times.'));

      gameState.addItemToRoom('study', GameItem.create(
        name: 'Live Rat 1',
        type: 'rat_specimen',
        category: ItemCategory.specimen,
        quantity: 2,
      ));
      final vivTask1 = GameTask(
        id: 'viv_1',
        npcId: gameState.npcs.first.id,
        priority: IntentPriority.normal,
        type: TaskType.vivisection,
        targetId: 'study',
        recipeId: 'small_vivisection',
        minutesRemaining: 1,
      );
      gameState.completeTaskManually(gameState.npcs.first.id, vivTask1);
      gameState.tick();

      expect(gameState.taskCompletionCounts[TaskType.vivisection], equals(1));
      expect(obj3.isCompleted, isFalse);

      final vivTask2 = GameTask(
        id: 'viv_2',
        npcId: gameState.npcs.first.id,
        priority: IntentPriority.normal,
        type: TaskType.vivisection,
        targetId: 'study',
        recipeId: 'small_vivisection',
        minutesRemaining: 1,
      );
      gameState.completeTaskManually(gameState.npcs.first.id, vivTask2);
      gameState.tick();

      expect(gameState.taskCompletionCounts[TaskType.vivisection], equals(2));
      expect(obj3.isCompleted, isTrue);
    });
  });
}
