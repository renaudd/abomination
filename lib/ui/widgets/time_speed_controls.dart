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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';

class TimeSpeedControls extends StatelessWidget {
  const TimeSpeedControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _speedButton(context, state, GameSpeed.paused, Icons.pause),
            _speedButton(
              context,
              state,
              GameSpeed.slow,
              Icons.slow_motion_video,
            ),
            _speedButton(context, state, GameSpeed.normal, Icons.play_arrow),
            _speedButton(context, state, GameSpeed.fast, Icons.fast_forward),
            _speedButton(context, state, GameSpeed.superFast, Icons.bolt),
          ],
        );
      },
    );
  }

  Widget _speedButton(
    BuildContext context,
    GameState state,
    GameSpeed speed,
    IconData icon,
  ) {
    final isSelected = state.speed == speed;
    return IconButton(
      icon: Icon(icon),
      iconSize: 20,
      color: isSelected ? const Color(0xFFE5D5B0) : Colors.white10,
      onPressed: () => state.setSpeed(speed),
    );
  }
}
