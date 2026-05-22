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

import 'dart:async';
import '../state/game_state.dart';

class GameEngine {
  final GameState state;
  Timer? _timer;

  GameEngine(this.state) {
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    // 16ms = ~60 ticks per second, allowing for smooth animation interp
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _processTick();
    });
  }

  int _tickCounter = 0;

  void _processTick() {
    if (state.speed == GameSpeed.paused) return;

    int minutesPerTick = 0;
    int threshold = 1;

    switch (state.speed) {
      case GameSpeed.slow:
        // 1 min/sec = 1 tick every 60 frames at 60Hz
        threshold = 60;
        minutesPerTick = 1;
        break;
      case GameSpeed.normal:
        // 12 mins/sec = 1 tick every 5 frames at 60Hz
        threshold = 5;
        minutesPerTick = 1;
        break;
      case GameSpeed.fast:
        // 60 mins/sec = 1 tick every frame at 60Hz
        threshold = 1;
        minutesPerTick = 1;
        break;
      case GameSpeed.superFast:
        // 180 mins/sec = 3 mins every frame at 60Hz
        threshold = 1;
        minutesPerTick = 3;
        break;
      case GameSpeed.paused:
        return;
      // We'll treat 'paused' (but logically maybe a 'slow' state) as 1 min/sec
      // Note: We don't have a dedicated 'slow' enum yet, but let's assume
      // there might be a need for it. For now, let's keep the user's 1 min/sec in mind.
    }

    // Auto-accelerate speed if all residents are asleep
    if (state.areAllResidentsAsleep()) {
      if (state.residentsAsleepBehavior == 'lightning') {
        threshold = 1;
        minutesPerTick = 3;
      } else if (state.residentsAsleepBehavior == 'fast') {
        threshold = 1;
        minutesPerTick = 1;
      }
    }

    _tickCounter++;
    if (_tickCounter >= threshold) {
      _tickCounter = 0;
      for (int i = 0; i < (minutesPerTick > 0 ? minutesPerTick : 1); i++) {
        state.tick();
      }
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
