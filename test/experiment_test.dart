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
import 'package:abomination/models/experiment.dart';
import 'package:abomination/models/objective.dart';
import 'package:abomination/services/task_service.dart';
import 'package:abomination/models/room.dart';
import 'package:abomination/models/game_item.dart';

void main() {
  test('Experiment progress decrements during GameState tick', () {
    final state = GameState();

    state.initializeNewGame(
      firstName: "Test",
      lastName: "Master",
      estateName: "Test Manor",
      deathCause: DeathCause.trainCrash,
      age: 30,
      gilesTrait: GilesTrait.silent,
      objective: LifeObjective.science,
    );

    // Ensure we have an NPC to experiment on
    final npcId = state.npcs.first.id;
    final experiment = Experiment.create(npcId, ExperimentType.transmutation);
    final initialMinutes = experiment.minutesRemaining;

    state.startExperiment(experiment);
    state.setSpeed(GameSpeed.normal);

    // Perform a tick
    state.tick();

    expect(
      state.activeExperiments.first.minutesRemaining,
      equals(initialMinutes - 1),
    );
    expect(state.activeExperiments.first.progress, greaterThan(0));
  });

  test('Reanimation completion triggers objective verification and performedExperiments addition', () {
    final state = GameState();
    state.initializeNewGame(
      firstName: "Test",
      lastName: "Master",
      estateName: "Test Manor",
      deathCause: DeathCause.trainCrash,
      age: 30,
      gilesTrait: GilesTrait.silent,
      objective: LifeObjective.science,
    );

    // Manually add the first_construct_4 objective
    state.setSpeed(GameSpeed.normal);
    state.clearObjectivesForTesting();
    final objective = Objective(
      id: 'first_construct_4',
      title: 'The First Construct - Step 4',
      description: 'Perform a Reanimation experiment',
      type: ObjectiveType.science,
      requirements: {'experiment_performed': 'reanimation'},
    );
    state.addObjectiveForTesting(objective);

    // Make the first room a restored Laboratory
    final firstRoom = state.rooms.first;
    final labRoom = firstRoom.copyWith(
      type: RoomType.laboratory,
      isRestored: true,
      inventory: [
        GameItem(
          id: 'principles_of_galvanism',
          type: 'principles_of_galvanism',
          name: 'Principles of Galvanism',
          category: ItemCategory.knowledge,
          quantity: 1,
          quality: 1.0,
          shape: ItemShape.pill,
          metadata: {'discipline': 'Alchemy', 'isResearched': true},
        ),
        GameItem(
          id: 'alchemy_textbook',
          type: 'research_book',
          name: 'Alchemy Textbook',
          category: ItemCategory.knowledge,
          quantity: 1,
          quality: 1.0,
          shape: ItemShape.pill,
          metadata: {'discipline': 'Alchemy', 'isResearched': true},
        ),
      ],
    );
    state.updateRoom(labRoom);

    // Reanimate a rat by enqueuing a reanimation activity
    state.addScienceActivityToQueue('reanimation_procedure', reservedEntityIds: ['specimen_rat']);

    // Check that it's enqueued
    expect(state.laboratoryQueue.length, equals(1));

    print("DIAGNOSTICS:");
    print("LAB QUEUE: ${state.laboratoryQueue}");
    print("ACTIVE TASKS: ${state.activeTasks.map((t) => '${t.type} - ${t.recipeId}')}");
    print("ROAD ROOM TYPE: ${state.rooms.firstWhere((r) => r.id == firstRoom.id).type}");
    print("ROAD ROOM RESTORED: ${state.rooms.firstWhere((r) => r.id == firstRoom.id).isRestored}");
    for (var n in state.npcs) {
      if (n.intentQueue.isNotEmpty) {
        print("NPC ${n.name} INTENTS: ${n.intentQueue.map((i) => '${i.action} - ${i.recipeId}')}");
      }
    }

    // Assign worker
    final workerId = state.npcs.firstWhere((n) => n.isResident).id;
    final success = state.assignNpcToTask(
      workerId,
      TaskType.experiment,
      firstRoom.id,
    );
    if (!success) {
      print("ASSIGNMENT FAILED REASON: ${state.lastAnnouncement}");
    }
    expect(success, isTrue);

    // Get the task
    final activeTasks = state.activeTasks;
    expect(activeTasks.length, equals(1));
    final task = activeTasks.first;
    expect(task.recipeId, equals('reanimation_procedure'));
    // Tick time until the task completes (duration is 120 minutes)
    for (int i = 0; i < 250; i++) {
      state.tick();
      if (state.speed == GameSpeed.paused) {
        state.setSpeed(GameSpeed.normal);
      }
    }

    // Verify task completion
    expect(state.performedExperiments.contains('reanimation'), isTrue);
    expect(objective.isCompleted, isTrue);
  });
}
