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
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:abomination/state/game_state.dart';
import 'package:abomination/ui/screens/study_screen.dart';
import 'package:abomination/models/game_item.dart';
import 'package:abomination/models/room.dart';

void main() {
  testWidgets('StudyScreen should not have overflow with many items', (
    WidgetTester tester,
  ) async {
    final gameState = GameState();
    final List<GameItem> items = [];

    // Add many items to inventory to force a long list
    for (int i = 0; i < 20; i++) {
      items.add(
        GameItem.create(
          name: 'Notes $i',
          type: 'research_notes',
          category: ItemCategory.knowledge,
          metadata: {'discipline': 'Discipline $i'},
        ),
      );
    }
    gameState.addRoomForTesting(Room.initial(
      'study',
      'Study',
      RoomType.study,
      Floor.ground,
      inventory: items,
    ));

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: gameState,
        child: const MaterialApp(home: StudyScreen()),
      ),
    );

    // Verify no overflow errors were thrown
    expect(tester.takeException(), isNull);

    // Verify we can find some of the items (scrolling might be needed to see all, but here we just check render)
    expect(find.text('DISCIPLINE 1 NOTES'), findsOneWidget);
  });
}
