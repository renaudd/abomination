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
import 'package:frankensteinoss/state/game_state.dart';
import 'package:frankensteinoss/models/experiment.dart';

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
}
