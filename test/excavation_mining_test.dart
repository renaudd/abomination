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
import 'package:abomination/state/game_state.dart';
import 'package:abomination/services/task_service.dart';
import 'package:abomination/models/game_item.dart';

void main() {
  late GameState gameState;

  setUp(() {
    gameState = GameState();
    gameState.initializeNewGame(
      firstName: "Alfonso",
      lastName: "Frankenstein",
      estateName: "Frankenstein Manor",
      deathCause: DeathCause.trainCrash,
      age: 30,
      gilesTrait: GilesTrait.sage,
      objective: LifeObjective.science,
    );
    gameState.setSpeed(GameSpeed.normal);
  });

  group('Excavation & Mining Mechanics', () {
    test('Initial Seams Setup Verification', () {
      // Verify oil well site at basement_e
      final roomE = gameState.rooms.firstWhere((r) => r.id == 'basement_e');
      expect(roomE.metadata['resourceType'], 'oil_well_site');
      expect(roomE.metadata['canAccommodateOilWell'], true);

      // Verify coal at basement_f
      final roomF = gameState.rooms.firstWhere((r) => r.id == 'basement_f');
      expect(roomF.metadata['resourceType'], 'coal');
      expect(roomF.metadata['isResourceBlocked'], true);

      // Verify oil at basement_j and basement_o
      final roomJ = gameState.rooms.firstWhere((r) => r.id == 'basement_j');
      expect(roomJ.metadata['resourceType'], 'oil');
      expect(roomJ.metadata['isResourceBlocked'], true);

      final roomO = gameState.rooms.firstWhere((r) => r.id == 'basement_o');
      expect(roomO.metadata['resourceType'], 'oil');
      expect(roomO.metadata['isResourceBlocked'], true);
    });

    test('Excavation Accessibility Constraints', () {
      // Floor -1 rooms are accessible initially
      expect(gameState.isRoomAccessibleForExcavation('basement_1'), isTrue);
      expect(gameState.isRoomAccessibleForExcavation('basement_2'), isTrue);

      // Floor -2 rooms are NOT accessible initially (blocked/unrestored neighbors)
      expect(gameState.isRoomAccessibleForExcavation('basement_e'), isFalse);
      expect(gameState.isRoomAccessibleForExcavation('basement_f'), isFalse);
    });

    test('Progressive Excavation Tools, Expertise, and Costs', () {
      final player = gameState.npcs.firstWhere((n) => n.id == 'player');

      // Ensure player is in resident state
      expect(player.isResident, isTrue);

      // 1. Excavation at Depth 1 (Floor -1: e.g. basement_1)
      // Should fail without Shovel
      bool success = gameState.assignNpcToTask(player.id, TaskType.excavate, 'basement_1');
      expect(success, isFalse);

      // Add Simple Shovel
      gameState.addItemToRoom('master_bedroom', GameItem.create(
        name: 'Simple Shovel',
        type: 'simple_shovel',
        category: ItemCategory.utility,
        quantity: 1,
      ));

      // Should fail due to insufficient resources (2000 Funds, 500 Wood, 200 Stone)
      gameState.setResource('funds', 0);
      success = gameState.assignNpcToTask(player.id, TaskType.excavate, 'basement_1');
      expect(success, isFalse);

      // Set resources
      gameState.setResource('funds', 5000);
      gameState.setResource('wood', 1000);
      gameState.setResource('bricks', 500);

      // Should now succeed
      success = gameState.assignNpcToTask(player.id, TaskType.excavate, 'basement_1');
      expect(success, isTrue);

      final task = gameState.activeTasks.firstWhere((t) => t.npcId == player.id);
      gameState.cancelTask(task.id);

      // 2. Excavation at Depth 2 (Floor -2: e.g. basement_f)
      // First restore the neighbor (basement_1) to make basement_f accessible
      final room1 = gameState.rooms.firstWhere((r) => r.id == 'basement_1');
      gameState.updateRoom(room1.copyWith(isRestored: true));

      // Check accessibility
      expect(gameState.isRoomAccessibleForExcavation('basement_f'), isTrue);

      // Should fail without Iron Pickaxe
      success = gameState.assignNpcToTask(player.id, TaskType.excavate, 'basement_f');
      expect(success, isFalse);

      // Add Iron Pickaxe
      gameState.addItemToRoom('master_bedroom', GameItem.create(
        name: 'Iron Pickaxe',
        type: 'iron_pickaxe',
        category: ItemCategory.utility,
        quantity: 1,
      ));

      // Should fail without Mining expertise (Level 2 required)
      {
        final meta = Map<String, dynamic>.from(player.metadata);
        meta['proficiency_level_Mining'] = 1;
        gameState.updateNpc(player.copyWith(metadata: meta));
      }
      success = gameState.assignNpcToTask(player.id, TaskType.excavate, 'basement_f');
      expect(success, isFalse);

      // Set Mining expertise to 2
      {
        final meta = Map<String, dynamic>.from(gameState.npcs.first.metadata);
        meta['proficiency_level_Mining'] = 2;
        gameState.updateNpc(gameState.npcs.first.copyWith(metadata: meta));
      }

      // Should fail due to resources (Need 4000 Funds, 1000 Wood, 500 Stone, 100 Iron Ore)
      gameState.setResource('funds', 1000);
      success = gameState.assignNpcToTask(player.id, TaskType.excavate, 'basement_f');
      expect(success, isFalse);

      // Add required resources
      gameState.setResource('funds', 5000);
      gameState.setResource('wood', 2000);
      gameState.setResource('bricks', 1000);
      gameState.setResource('iron_ore', 200);

      // Should succeed
      success = gameState.assignNpcToTask(player.id, TaskType.excavate, 'basement_f');
      expect(success, isTrue);
    });

    test('Oil Well Pumping and 2/3 Depletion Hollowing', () {
      final player = gameState.npcs.firstWhere((n) => n.id == 'player');

      // Setup basement_e directly as an active oil well
      final roomE = gameState.rooms.firstWhere((r) => r.id == 'basement_e');
      gameState.updateRoom(roomE.copyWith(
        type: RoomType.oilWell,
        isRestored: true,
        name: 'OIL WELL',
      ));

      // Ensure we start with 6000 total oil
      expect(gameState.manorOilReserve, 6000.0);

      // Operating the oil well uses TaskType.mining
      // Pumping loop
      gameState.setResource('crude_oil', 0.0);

      int loops = 0;
      while (gameState.manorOilReserve > 2000 && loops < 30) {
        loops++;
        final success = gameState.assignNpcToTask(player.id, TaskType.mining, 'basement_e');
        expect(success, isTrue, reason: "Loop $loops failed to assign mining task");

        final task = gameState.activeTasks.firstWhere((t) => t.npcId == player.id);
        gameState.completeTaskManually(player.id, task);
      }

      // Verify reserve has depleted below or equal to 2000 (2/3 depleted)
      expect(gameState.manorOilReserve, lessThanOrEqualTo(2000.0));
      expect(gameState.resources['crude_oil'], greaterThanOrEqualTo(4000.0));

      // Assert that both nodes underneath the well (basement_j and basement_o) are now hollowed out (accessible, no longer blocked)
      final roomJ = gameState.rooms.firstWhere((r) => r.id == 'basement_j');
      expect(roomJ.metadata['isResourceBlocked'], isFalse);
      expect(roomJ.type, RoomType.unused);
      expect(roomJ.isRestored, isTrue);

      final roomO = gameState.rooms.firstWhere((r) => r.id == 'basement_o');
      expect(roomO.metadata['isResourceBlocked'], isFalse);
      expect(roomO.type, RoomType.unused);
      expect(roomO.isRestored, isTrue);

      // Continue pumping until completely dry (runs dry)
      loops = 0;
      while (gameState.manorOilReserve > 0 && loops < 30) {
        loops++;
        final success = gameState.assignNpcToTask(player.id, TaskType.mining, 'basement_e');
        expect(success, isTrue);

        final task = gameState.activeTasks.firstWhere((t) => t.npcId == player.id);
        gameState.completeTaskManually(player.id, task);
      }

      expect(gameState.manorOilReserve, 0.0);

      // Operating well when dry should fail
      final success = gameState.assignNpcToTask(player.id, TaskType.mining, 'basement_e');
      expect(success, isFalse);

      // Decommission oil well
      gameState.decommissionOilWell('basement_e');
      final roomEAfter = gameState.rooms.firstWhere((r) => r.id == 'basement_e');
      expect(roomEAfter.type, RoomType.unused);
      expect(roomEAfter.isRestored, isTrue);
    });

    test('Super Merchant Cheat Spawning & Transaction pricing', () {
      // Spawn Super Merchant
      gameState.cheatSendSuperMerchant();

      // Verify Super Merchant exists in the NPCS list
      final superMerchant = gameState.npcs.firstWhere((n) => n.id == 'super_merchant');
      expect(superMerchant.name, 'Super Merchant Silas');
      expect(superMerchant.role, 'Super Merchant');

      // Verify Super Merchant has simple_shovel in stock
      final stock = superMerchant.metadata['merchantStock'] as Map<String, dynamic>;
      expect(stock['simple_shovel'], 999999);

      // Check base buy price for simple_shovel
      expect(gameState.marketService.getBuyPrice('simple_shovel'), 160);

      // Try purchasing simple_shovel from Super Merchant
      gameState.setResource('funds', 500);
      gameState.setResource('simple_shovel', 0);

      gameState.buyFromVisitingMerchant('super_merchant', 'simple_shovel', 1);

      // Verify funds were deducted and simple_shovel was added
      expect(gameState.resources['funds'], 340.0);
      expect(gameState.resources['simple_shovel'], 1.0);

      // Verify Super Merchant stock is UNLIMITED (remains 999999)
      final superMerchantAfter = gameState.npcs.firstWhere((n) => n.id == 'super_merchant');
      final stockAfter = superMerchantAfter.metadata['merchantStock'] as Map<String, dynamic>;
      expect(stockAfter['simple_shovel'], 999999);
    });
  });
}
