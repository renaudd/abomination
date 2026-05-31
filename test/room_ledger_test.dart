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
import 'package:abomination/models/room.dart';
import 'package:abomination/models/game_item.dart';
import 'package:abomination/state/game_state.dart';
import 'package:abomination/ui/widgets/room_ledger.dart';

void main() {
  testWidgets('RoomLedger should sort items properly by item name and value when columns are clicked', (WidgetTester tester) async {
    final gameState = GameState();
    final room = Room(
      id: 'kitchen',
      name: 'Kitchen',
      type: RoomType.kitchen,
      isRestored: true,
      floor: Floor.ground,
      description: 'A cozy cooking area.',
      inventory: [
        GameItem.create(
          name: 'Carrot',
          type: 'carrot',
          category: ItemCategory.food,
          value: 10,
          weight: 0.2,
        ),
        GameItem.create(
          name: 'Apple',
          type: 'apple',
          category: ItemCategory.food,
          value: 5,
          weight: 0.1,
        ),
        GameItem.create(
          name: 'Beef',
          type: 'beef',
          category: ItemCategory.food,
          value: 20,
          weight: 1.5,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomLedger(
            room: room,
            state: gameState,
          ),
        ),
      ),
    );

    // Initially unsorted. Let's verify items are rendered.
    expect(find.text('CARROT'), findsOneWidget);
    expect(find.text('APPLE'), findsOneWidget);
    expect(find.text('BEEF'), findsOneWidget);

    // Let's click the 'ITEM' (Name) column to sort alphabetically
    await tester.tap(find.text('ITEM'));
    await tester.pumpAndSettle();

    // Verify visual arrow for sorting is displayed
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

    // Let's click the 'VAL' (Value) column to sort by value ascending (5F, 10F, 20F)
    await tester.tap(find.text('VAL'));
    await tester.pumpAndSettle();
    
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

    // Click 'VAL' again to toggle descending (20F, 10F, 5F)
    await tester.tap(find.text('VAL'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
  });
}
