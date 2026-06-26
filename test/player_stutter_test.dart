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

void main() {
  group('Player Task Stutter Debugging', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
      gameState.initializeNewGame(
        firstName: "Victor",
        lastName: "Frankenstein",
        estateName: "Frankenstein Estate",
        deathCause: DeathCause.disease,
        age: 30,
        gilesTrait: GilesTrait.sage,
        objective: LifeObjective.science,
      );
      gameState.setSpeed(GameSpeed.normal);
    });

    test('Player manual task assignment and progression over ticks', () {
      final player = gameState.npcs.firstWhere((n) => n.isPlayer);
      
      // Clear the study research queue so we can do a simple clean room or research task
      final study = gameState.rooms.firstWhere((r) => r.id == 'study');
      expect(study, isNotNull);

      // Let's manually assign the player to clean the study (which is restored but might be dirty)
      // Or let's assign them to research. First, make sure they have a topic to research.
      gameState.tryScheduleNpcTask(
        player.id,
        TaskType.cleanRoom,
        'study',
      );

      print("--- DIAGNOSTICS ---");
      var updatedPlayer = gameState.npcs.firstWhere((n) => n.id == player.id);
      print("Player initial room: ${updatedPlayer.currentRoomId}");
      print("Player initial target room: ${updatedPlayer.targetRoomId}");
      print("Player intent queue length: ${updatedPlayer.intentQueue.length}");
      for (var intent in updatedPlayer.intentQueue) {
        print("Intent in queue: id=${intent.id}, action=${intent.action}, target=${intent.targetRoomId}, priority=${intent.priority}, isManual=${intent.isManual}");
      }

      // Now tick the game once to let the behavior tree assign and start the task
      gameState.tick();

      // Refresh player
      updatedPlayer = gameState.npcs.firstWhere((n) => n.id == player.id);
      print("After 1 tick:");
      print("Player active task ID: ${updatedPlayer.activeTaskId}");
      print("Player status: ${updatedPlayer.status}");
      print("Player current room: ${updatedPlayer.currentRoomId}");
      print("Player target room: ${updatedPlayer.targetRoomId}");
      print("Player intent queue length: ${updatedPlayer.intentQueue.length}");
      for (var intent in updatedPlayer.intentQueue) {
        print("Intent in queue: id=${intent.id}, action=${intent.action}, target=${intent.targetRoomId}, priority=${intent.priority}");
      }
      print("Active tasks in state: ${gameState.activeTasks.map((t) => 'id=${t.id}, npc=${t.npcId}, type=${t.type}, target=${t.targetId}').toList()}");
      print("--- END DIAGNOSTICS ---");

      expect(updatedPlayer.activeTaskId, isNotNull, reason: "Player activeTaskId is null after first tick!");
      final firstTaskId = updatedPlayer.activeTaskId!;
      print("Assigned task ID: $firstTaskId");

      final task = gameState.activeTasks.firstWhere((t) => t.id == firstTaskId);
      final initialMinutes = task.minutesRemaining;
      print("Initial minutes remaining: $initialMinutes");

      // Now tick the game again to make progress
      gameState.tick();

      // Refresh player
      updatedPlayer = gameState.npcs.firstWhere((n) => n.id == player.id);
      print("After 2nd tick, active task ID: ${updatedPlayer.activeTaskId}");

      // The task ID should NOT change, and the task should NOT be cancelled
      expect(updatedPlayer.activeTaskId, equals(firstTaskId), reason: "Task ID changed or got cancelled on the second tick!");

      final taskAfterTick = gameState.activeTasks.firstWhere((t) => t.id == firstTaskId);
      print("After 2nd tick, minutes remaining: ${taskAfterTick.minutesRemaining}");
      expect(taskAfterTick.minutesRemaining, lessThan(initialMinutes), reason: "Task did not make progress!");

      // Tick multiple times to see if it continues to be stable across hour boundaries
      for (int i = 0; i < 40; i++) {
        gameState.tick();
        updatedPlayer = gameState.npcs.firstWhere((n) => n.id == player.id);
        expect(updatedPlayer.activeTaskId, equals(firstTaskId), reason: "Task ID changed or got cancelled at tick $i (Hour: ${gameState.currentDate.hour}, Minute: ${gameState.currentDate.minute})!");
      }
    });

    test('Double task assignment on same room causes stuttering', () {
      final player = gameState.npcs.firstWhere((n) => n.isPlayer);

      // Make sure field_2 is not already tilled
      final field = gameState.rooms.firstWhere((r) => r.id == 'field_2');
      gameState.updateRoom(field.copyWith(isRestored: true, tilledAmount: 0.0, fertilizedAmount: 0.0));

      // 1. First assignment (simulates drag & drop)
      gameState.tryScheduleNpcTask(
        player.id,
        TaskType.tillSoil,
        'field_2',
      );

      // 2. Second assignment (simulates clicking the button on the same room for the same task)
      gameState.tryScheduleNpcTask(
        player.id,
        TaskType.tillSoil,
        'field_2',
      );

      print("--- DOUBLE ASSIGNMENT DIAGNOSTICS ---");
      var updatedPlayer = gameState.npcs.firstWhere((n) => n.id == player.id);
      print("Player intent queue length: ${updatedPlayer.intentQueue.length}");
      for (var intent in updatedPlayer.intentQueue) {
        print("Intent: id=${intent.id}, action=${intent.action}, target=${intent.targetRoomId}, isManual=${intent.isManual}");
      }

      // Tick 1: Starts the first task
      gameState.tick();
      updatedPlayer = gameState.npcs.firstWhere((n) => n.id == player.id);
      final activeTaskId1 = updatedPlayer.activeTaskId;
      print("Tick 1 activeTask: $activeTaskId1, status: ${updatedPlayer.status.name}");

      // Tick 2: Second manual intent is processed. Does it cancel the first and start a new one?
      gameState.tick();
      updatedPlayer = gameState.npcs.firstWhere((n) => n.id == player.id);
      final activeTaskId2 = updatedPlayer.activeTaskId;
      print("Tick 2 activeTask: $activeTaskId2, status: ${updatedPlayer.status.name}");

      // Tick 3: Arrives and starts working
      gameState.tick();
      updatedPlayer = gameState.npcs.firstWhere((n) => n.id == player.id);
      final activeTaskId3 = updatedPlayer.activeTaskId;
      print("Tick 3 activeTask: $activeTaskId3, status: ${updatedPlayer.status.name}");

      // Tick multiple times to see if it continues to be stable during active work
      for (int i = 4; i <= 25; i++) {
        gameState.tick();
        updatedPlayer = gameState.npcs.firstWhere((n) => n.id == player.id);
        print("Tick $i activeTask: ${updatedPlayer.activeTaskId}, status: ${updatedPlayer.status.name}");
        expect(updatedPlayer.activeTaskId, equals(activeTaskId1), reason: "Task was cancelled/restarted at tick $i due to double assignment!");
      }

      print("--- END DOUBLE ASSIGNMENT DIAGNOSTICS ---");
    });

    test('Failed manual task is removed from queue instead of clogging', () {
      final player = gameState.npcs.firstWhere((n) => n.isPlayer);

      // Make sure field_2 is not already tilled
      final field = gameState.rooms.firstWhere((r) => r.id == 'field_2');
      gameState.updateRoom(field.copyWith(isRestored: true, tilledAmount: 0.5, fertilizedAmount: 0.0));

      // 1. First assignment (simulates drag & drop)
      gameState.tryScheduleNpcTask(
        player.id,
        TaskType.tillSoil,
        'field_2',
      );

      // 2. Second assignment (simulates clicking the button on the same room for the same task)
      gameState.tryScheduleNpcTask(
        player.id,
        TaskType.tillSoil,
        'field_2',
      );

      var updatedPlayer = gameState.npcs.firstWhere((n) => n.id == player.id);
      expect(updatedPlayer.intentQueue.length, equals(2));

      // Tick once to start the first task
      gameState.tick();
      updatedPlayer = gameState.npcs.firstWhere((n) => n.id == player.id);
      final activeTaskId = updatedPlayer.activeTaskId;
      expect(activeTaskId, isNotNull);

      final task = gameState.activeTasks.firstWhere((t) => t.id == activeTaskId);
      gameState.handleTaskCompletionForTesting(task);

      // Verify the field is now tilled and the first task is done
      final updatedField = gameState.rooms.firstWhere((r) => r.id == 'field_2');
      expect(updatedField.tilledAmount >= 1.0, isTrue);

      // Refresh player
      updatedPlayer = gameState.npcs.firstWhere((n) => n.id == player.id);
      
      // Tick one more time to let the behavior tree evaluate the second till task.
      // It should fail validation because the field is already tilled,
      // and it should be removed from the queue!
      gameState.tick();

      updatedPlayer = gameState.npcs.firstWhere((n) => n.id == player.id);

      updatedPlayer = gameState.npcs.firstWhere((n) => n.id == player.id);
      // The second manual till task should NOT be in the queue anymore!
      final hasManualTillTask = updatedPlayer.intentQueue.any((intent) => intent.action == TaskType.tillSoil && intent.isManual);
      expect(hasManualTillTask, isFalse, reason: "Failed manual task was not removed from the queue!");
    });
  });
}
