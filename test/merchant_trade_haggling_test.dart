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
import 'package:abomination/models/npc.dart';
import 'package:abomination/models/game_date.dart';
import 'package:abomination/services/npc_generator.dart';

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

  group('Visiting Merchant Trading & Haggling Mechanics', () {
    test('Shopping Cart Offset Transaction', () {
      // Verify baseline values
      gameState.setResource('funds', 500);
      gameState.setResource('wood', 50); // Wood has sell price of 3 CHF each
      gameState.setResource('meat', 0); // Meat has buy price of 8 CHF each

      // Mock traveling merchant Silas using copyWith on generated refugee
      final silas = NPCGenerator.generateRefugee(currentDate: GameDate.initial()).copyWith(
        id: 'test_merchant',
        name: 'Silas',
        role: 'Traveling Merchant',
        currentRoomId: 'entryway',
        targetRoomId: 'entryway',
        movementProgress: 1.0,
        status: NPCStatus.idle,
        assignedRoomId: null,
        isResident: false,
        metadata: {
          'guestType': 'merchant',
          'merchantRespect': 50,
          'markupFactor': 1.0, // Fair pricing
          'merchantStock': {
            'meat': 10,
          },
        },
      );
      gameState.addNpcForTesting(silas);

      // We queue:
      // Buy: 5 meat @ 8 CHF = 40 CHF
      // Sell: 10 wood @ 3 CHF = 30 CHF
      // Net transaction cost: 10 CHF
      final itemsToBuy = {'meat': 5};
      final itemsToSell = {'wood': 10};
      const netCost = 10;

      gameState.commitMerchantTransaction(
        merchantId: 'test_merchant',
        itemsToBuy: itemsToBuy,
        itemsToSell: itemsToSell,
        netCost: netCost,
      );

      // Verify outcomes
      expect(gameState.resources['funds'], 490.0); // 500 - 10
      expect(gameState.resources['meat'], 5.0);   // +5 bought
      expect(gameState.resources['wood'], 40.0);   // 50 - 10 sold

      // Merchant stock should be updated
      final updatedSilas = gameState.npcs.firstWhere((n) => n.id == 'test_merchant');
      final stock = updatedSilas.metadata['merchantStock'] as Map<String, dynamic>;
      expect(stock['meat'], 5);
    });

    test('Haggling Logic respects markup ratio and updates metadata', () {
      final gideon = NPCGenerator.generateRefugee(currentDate: GameDate.initial()).copyWith(
        id: 'test_gideon',
        name: 'Gideon',
        role: 'Traveling Merchant',
        currentRoomId: 'entryway',
        targetRoomId: 'entryway',
        movementProgress: 1.0,
        status: NPCStatus.idle,
        assignedRoomId: null,
        isResident: false,
        metadata: {
          'guestType': 'merchant',
          'merchantRespect': 50,
          'markupFactor': 1.4, // Highly marked up - haggling works better!
          'merchantStock': {
            'wood': 10,
          },
        },
      );
      gameState.addNpcForTesting(gideon);

      // Haggle
      final result = gameState.haggleWithMerchant(
        merchantId: 'test_gideon',
        baseIntrinsicsCost: 100.0,
        currentOfferedCost: 140.0, // 1.4x intrinsic
      );

      expect(result['outcome'], isNotNull);
      expect(result['message'], isNotNull);

      final updatedGideon = gameState.npcs.firstWhere((n) => n.id == 'test_gideon');
      expect(updatedGideon.metadata['hasHaggled'], isTrue);

      // Respect or markup factor should have shifted based on outcome
      final newRespect = updatedGideon.metadata['merchantRespect'] as int;
      final newMarkup = updatedGideon.metadata['markupFactor'] as double;

      if (result['outcome'] == 'success' || result['outcome'] == 'critical_success') {
        expect(newRespect, greaterThan(50));
        expect(newMarkup, lessThan(1.4));
      } else if (result['outcome'] == 'failure' || result['outcome'] == 'upset_refused' || result['outcome'] == 'loan_offer') {
        expect(newRespect, lessThan(50));
      }
    });

    test('Debt daily interest compounding & 5-day Arson Attack', () {
      // Setup outstanding loan
      gameState.setResource('funds', 100);
      gameState.setResource('wood', 20);
      gameState.setResource('grain', 40);

      // Fully restore stables
      final stableIndex = gameState.rooms.indexWhere((r) => r.id == 'stables');
      if (stableIndex != -1) {
        gameState.rooms[stableIndex] = gameState.rooms[stableIndex].copyWith(
          isRestored: true,
          restorationProgress: 1.0,
          dirtiness: 0.0,
        );
      }

      // Setup mock merchant for loan provider
      final angryBartholomew = NPCGenerator.generateRefugee(currentDate: GameDate.initial()).copyWith(
        id: 'test_angry_bartholomew',
        name: 'Angry Merchant Bartholomew',
        role: 'Traveling Merchant',
        currentRoomId: 'entryway',
        targetRoomId: 'entryway',
        movementProgress: 1.0,
        status: NPCStatus.idle,
        assignedRoomId: null,
        isResident: false,
        metadata: {
          'guestType': 'merchant',
          'merchantStock': <String, dynamic>{},
        },
      );
      gameState.addNpcForTesting(angryBartholomew);

      // Force take loan of 200 CHF at 5% interest daily
      gameState.commitMerchantTransaction(
        merchantId: 'test_angry_bartholomew',
        itemsToBuy: <String, int>{},
        itemsToSell: <String, int>{},
        netCost: 200,
        loanProvider: 'Angry Merchant Bartholomew',
        loanAmount: 200,
        loanInterestRate: 0.05,
      );

      expect(gameState.activeMerchantLoan, 200);
      expect(gameState.merchantLoanProvider, 'Angry Merchant Bartholomew');

      // Day 1 to 4 interest ticks (crossing exactly 4 midnights)
      int currentLoan = 200;
      for (int day = 1; day <= 4; day++) {
        for (int min = 0; min < 1440; min++) {
          gameState.tick();
        }
        int interest = (currentLoan * 0.05).round();
        if (interest < 1) interest = 1;
        currentLoan += interest;

        expect(gameState.activeMerchantLoan, currentLoan);
      }

      // Store wood & grain right before the 5th daily tick
      final num woodBefore = gameState.resources['wood'] ?? 0;
      final num grainBefore = gameState.resources['grain'] ?? 0;

      // Tick the 5th day
      for (int min = 0; min < 1440; min++) {
        gameState.tick();
      }

      // Compounding for the 5th day
      int finalInterest = (currentLoan * 0.05).round();
      if (finalInterest < 1) finalInterest = 1;
      currentLoan += finalInterest;

      expect(gameState.activeMerchantLoan, currentLoan);

      // Wood and grain resources must have been burned / reduced compared to their values right before midnight!
      expect(gameState.resources['wood']!, lessThan(woodBefore));
      expect(gameState.resources['grain']!, lessThan(grainBefore));

      // Stables should be damaged (dirtiness 1.0, isRestored false, progress 0.0)
      if (stableIndex != -1) {
        final damagedStables = gameState.rooms.firstWhere((r) => r.id == 'stables');
        expect(damagedStables.dirtiness, 1.0);
        expect(damagedStables.isRestored, isFalse);
        expect(damagedStables.restorationProgress, 0.0);
      }
    });

    test('Loan payback reduces balance', () {
      gameState.setResource('funds', 500);

      // Setup mock merchant for loan provider
      final vesper = NPCGenerator.generateRefugee(currentDate: GameDate.initial()).copyWith(
        id: 'test_vesper',
        name: 'Vesper',
        role: 'Traveling Merchant',
        currentRoomId: 'entryway',
        targetRoomId: 'entryway',
        movementProgress: 1.0,
        status: NPCStatus.idle,
        assignedRoomId: null,
        isResident: false,
        metadata: {
          'guestType': 'merchant',
          'merchantStock': <String, dynamic>{},
        },
      );
      gameState.addNpcForTesting(vesper);
      
      // Direct transaction to take loan
      gameState.commitMerchantTransaction(
        merchantId: 'test_vesper',
        itemsToBuy: <String, int>{},
        itemsToSell: <String, int>{},
        netCost: 300,
        loanProvider: 'Vesper',
        loanAmount: 300,
        loanInterestRate: 0.05,
      );

      expect(gameState.activeMerchantLoan, 300);

      // Pay back half
      gameState.payMerchantLoan(150);
      expect(gameState.activeMerchantLoan, 150);
      expect(gameState.resources['funds'], 350.0); // 500 - 150

      // Pay back remaining (with excess)
      gameState.payMerchantLoan(200);
      expect(gameState.activeMerchantLoan, 0);
      expect(gameState.merchantLoanProvider, isNull);
      expect(gameState.resources['funds'], 200.0); // 350 - 150
    });
  });
}
