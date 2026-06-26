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

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:abomination/models/active_business.dart';
import 'package:abomination/models/patron.dart';
import 'package:abomination/models/game_item.dart';
import 'package:abomination/state/game_state.dart';

void main() {
  group('Track 2: Patron Traits & Database Engine Tests', () {
    test('Patron.generate should create a patron with 1 to 3 non-exclusive traits', () {
      final rand = Random(42);
      final patron = Patron.generate(rand, 'Gnomes of Zurich', 'Hans Keller', 120);

      expect(patron.name, 'Hans Keller');
      expect(patron.faction, 'Gnomes of Zurich');
      expect(patron.arrivalMinutes, 120);
      expect(patron.traits, isNotEmpty);
      expect(patron.traits.length, anyOf(1, 2, 3));
      expect(patron.patience, 1.0);
      expect(patron.satisfaction, 100.0);
      expect(patron.isSeated, isFalse);
    });

    test('GameState should support spawning, seating, ticking patience, and checkout of Patrons', () {
      final state = GameState();
      state.setSpeed(GameSpeed.normal);
      
      // 1. Establish a bistro business venture so the restaurant loops process
      state.proposeBusiness(BusinessType.bistro, 'test_cook', 'Chef Pierre');
      final bus = state.activeBusinesses.firstWhere((b) => b.type == BusinessType.bistro);
      state.acceptBusinessProposal(bus.id);
      state.forceActivateBusinessForTesting(bus.id);
      
      // Set to operating hours (e.g., Friday 18:00)
      state.setTimeForTesting(5, 18, 0); // Day 5, 18:00 (operating hours!)

      // Verify business is active
      expect(state.activeBusinesses.first.status, 'active');

      // 2. Manually add custom patrons with specific traits for deterministic testing
      final complainer = Patron(
        id: 'patron_complainer',
        name: 'Gottfried complainer',
        faction: 'Carbonari',
        traits: [PatronTrait.complainer],
        patience: 1.0,
        satisfaction: 100.0,
        arrivalMinutes: state.currentDate.totalMinutes,
      );

      final bigTipper = Patron(
        id: 'patron_tipper',
        name: 'Emma Tipper',
        faction: 'Gnomes of Zurich',
        traits: [PatronTrait.bigTipper],
        patience: 1.0,
        satisfaction: 100.0,
        arrivalMinutes: state.currentDate.totalMinutes,
      );

      // Add to state
      state.addPatronForTesting(complainer);
      state.addPatronForTesting(bigTipper);

      print("ACTIVE PATRONS: ${state.activePatrons.map((p) => '${p.id}: ${p.name}').toList()}");
      expect(state.activePatrons.length, 2);
      expect(state.activePatrons.any((p) => p.isSeated), isFalse);

      // 3. Process one minute tick to trigger seating!
      state.tick();

      // Both should now be seated at Table 1 and Table 2 since tables are empty!
      final seated = state.activePatrons.where((p) => p.isSeated).toList();
      final seatedIds = seated.map((p) => p.id).toSet();
      expect(seatedIds.contains('patron_complainer'), isTrue);
      expect(seatedIds.contains('patron_tipper'), isTrue);
      final compSeated = seated.firstWhere((p) => p.id == 'patron_complainer');
      final tipSeated = seated.firstWhere((p) => p.id == 'patron_tipper');
      expect(compSeated.seatedTableId, isNotNull);
      expect(tipSeated.seatedTableId, isNotNull);
      expect(compSeated.diningFinishMinutes, isNotNull);
      expect(tipSeated.diningFinishMinutes, isNotNull);

      // 4. Verify patience decay for unseated patrons
      // Let's add two more patrons, but occupy all 4 tables so they remain in the foyer!
      final patientOne = Patron(
        id: 'patron_easy',
        name: 'Beat Easy',
        faction: 'Freemasons',
        traits: [PatronTrait.easyRegular],
        patience: 1.0,
        satisfaction: 100.0,
      );

      final complainerTwo = Patron(
        id: 'patron_complainer_2',
        name: 'Martha Complainer',
        faction: 'Rosicrucians',
        traits: [PatronTrait.complainer],
        patience: 1.0,
        satisfaction: 100.0,
      );

      // Seat 2 more to max out capacity (4 tables)
      final dummySeated1 = Patron(
        id: 'dummy_1',
        name: 'Dummy One',
        faction: 'Glarus',
        traits: [PatronTrait.easyRegular],
        isSeated: true,
        seatedTableId: 'Table 3',
        diningFinishMinutes: state.currentDate.totalMinutes + 100,
      );

      final dummySeated2 = Patron(
        id: 'dummy_2',
        name: 'Dummy Two',
        faction: 'Army',
        traits: [PatronTrait.easyRegular],
        isSeated: true,
        seatedTableId: 'Table 4',
        diningFinishMinutes: state.currentDate.totalMinutes + 100,
      );

      state.addPatronForTesting(patientOne);
      state.addPatronForTesting(complainerTwo);
      state.addPatronForTesting(dummySeated1);
      state.addPatronForTesting(dummySeated2);

      // Foyer has patientOne and complainerTwo. Tables are full!
      // Let's tick time by 10 minutes and verify patience decay difference
      for (int i = 0; i < 10; i++) {
        state.tick();
      }

      final pEasy = state.activePatrons.firstWhere((p) => p.id == 'patron_easy');
      final pComplainer = state.activePatrons.firstWhere((p) => p.id == 'patron_complainer_2');

      expect(pEasy.isSeated, isFalse);
      expect(pComplainer.isSeated, isFalse);

      // Complainer patience decay is 0.035/min (10 mins = 0.35 decay -> patience 0.65)
      // Easy Regular patience decay is 0.008/min (10 mins = 0.08 decay -> patience 0.92)
      expect(pComplainer.patience, closeTo(0.65, 0.01));
      expect(pEasy.patience, closeTo(0.92, 0.01));

      // 5. Test Big Tipper bill multiplier on checkout!
      // Let's find the finish time of Emma Tipper (bigTipper)
      final tipperSeated = state.activePatrons.firstWhere((p) => p.id == 'patron_tipper');
      final finishMin = tipperSeated.diningFinishMinutes!;

      // Advance time until she checks out!
      int tickCount = 0;
      while (state.activePatrons.any((p) => p.id == 'patron_tipper') && tickCount < 100) {
        state.tick();
        tickCount++;
      }

      // She should have checked out and left a transaction in the ledger!
      // Let's verify ledger transactions for this business
      final updatedBus = state.activeBusinesses.firstWhere((b) => b.id == bus.id);
      final txs = updatedBus.ledger;
      expect(txs, isNotEmpty);
      
      // The transaction description should note the big tipper premium!
      print("ALL TRANSACTIONS: ${txs.map((tx) => '${tx.description}: ${tx.amount}').toList()}");
      final tipperTx = txs.firstWhere((tx) => tx.description.contains('Emma Tipper'));
      expect(tipperTx.description, contains('[BIG TIPPER PREMIUM]'));
      // Verify that the amount is greater than 0
      expect(tipperTx.amount, greaterThan(0.0));
    });

    test('refusePatron and expelPatron actions should remove patrons and cause correct buzz / scene side effects', () {
      final state = GameState();
      
      // 1. Setup a custom foyer patron
      final foyerPatron = Patron(
        id: 'patron_refuse_me',
        name: 'Gottfried Refusable',
        faction: 'Rosicrucians',
        traits: [PatronTrait.complainer],
        patience: 1.0,
        satisfaction: 100.0,
      );
      state.addPatronForTesting(foyerPatron);

      // 2. Setup seated patrons
      final seatedPatron1 = Patron(
        id: 'seated_1',
        name: 'Seated One',
        faction: 'Carbonari',
        traits: [PatronTrait.easyRegular],
        isSeated: true,
        seatedTableId: 'Table 1',
        satisfaction: 100.0,
      );

      final seatedPatron2 = Patron(
        id: 'seated_2',
        name: 'Seated Two',
        faction: 'Carbonari',
        traits: [PatronTrait.easyRegular],
        isSeated: true,
        seatedTableId: 'Table 2',
        satisfaction: 90.0,
      );
      state.addPatronForTesting(seatedPatron1);
      state.addPatronForTesting(seatedPatron2);

      expect(state.activePatrons.length, 3);
      final double initialBuzz = state.bistroProfitModifier;

      // 3. Refuse foyer patron
      state.refusePatron('patron_refuse_me');

      // Verify foyer patron is removed, and buzz is reduced by exactly 0.02
      expect(state.activePatrons.any((p) => p.id == 'patron_refuse_me'), isFalse);
      expect(state.activePatrons.length, 2);
      expect(state.bistroProfitModifier, closeTo(initialBuzz - 0.02, 0.001));
      
      // Verify refusal is logged in announcement history
      expect(state.announcementHistory.last, contains('Refused service to GOTTFRIED REFUSABLE'));

      // 4. Expel seated patron 1
      state.expelPatron('seated_1');

      // Verify seated patron 1 is removed
      expect(state.activePatrons.any((p) => p.id == 'seated_1'), isFalse);
      expect(state.activePatrons.length, 1);

      // Verify the expulsion caused a "scene", draining the satisfaction of other seated patrons (seated_2) by exactly 15.0!
      final remainingSeated = state.activePatrons.firstWhere((p) => p.id == 'seated_2');
      expect(remainingSeated.satisfaction, closeTo(75.0, 0.001)); // 90.0 - 15.0 = 75.0!

      // Verify expulsion is logged in announcement history
      expect(state.announcementHistory.last, contains('Forcibly expelled SEATED ONE from the dining room'));
    });

    test('Track 4: Alchemical Drugging & Surgical Harvesting loop should work end-to-end', () {
      final state = GameState();
      state.initializeNewGame(
        firstName: "Gideon",
        lastName: "Wealthy",
        estateName: "Glarus Manor",
        deathCause: DeathCause.disease,
        age: 40,
        gilesTrait: GilesTrait.sage,
        objective: LifeObjective.science,
      );

      // Establish a bistro business venture so the restaurant loops process
      state.proposeBusiness(BusinessType.bistro, 'test_cook', 'Chef Pierre');
      final bus = state.activeBusinesses.firstWhere((b) => b.type == BusinessType.bistro);
      state.acceptBusinessProposal(bus.id);
      state.forceActivateBusinessForTesting(bus.id);
      
      // 1. Setup a seated diner target
      final target = Patron(
        id: 'target_patron',
        name: 'Gideon Wealthy',
        faction: 'Gnomes of Zurich',
        traits: [PatronTrait.bigTipper],
        isSeated: true,
        seatedTableId: 'Table 3',
        satisfaction: 100.0,
      );
      state.addPatronForTesting(target);
      
      // 2. Add alchemical sedatives to kitchen room inventory
      final kitchenIdx = state.rooms.indexWhere((r) => r.id == 'kitchen');
      expect(kitchenIdx, isNot(-1));
      
      final sedativeItem = GameItem.create(
        name: 'Soporific Draft',
        type: 'soporific_draft',
        category: ItemCategory.medical,
        quantity: 2,
      );
      state.addItemToRoom(state.rooms[kitchenIdx].id, sedativeItem);
      
      // Verify sedative is in inventory
      expect(state.inventory.any((item) => item.type == 'soporific_draft'), isTrue);
      expect(state.inventory.firstWhere((item) => item.type == 'soporific_draft').quantity, 2);

      // 3. Spike order!
      state.spikePatronOrder('target_patron', 'soporific_draft');

      // Verify sedative was consumed (quantity decreased by 1)
      expect(state.inventory.firstWhere((item) => item.type == 'soporific_draft').quantity, 1);
      
      // Verify target state
      var updatedTarget = state.activePatrons.firstWhere((p) => p.id == 'target_patron');
      expect(updatedTarget.isDrugged, isTrue);
      expect(updatedTarget.sedativeUsed, 'soporific_draft');
      expect(updatedTarget.isCollapsed, isFalse);

      // 4. Tick time until collapse occurs!
      // In _processRealtimeRestaurant, drugged diners have a 35% chance to collapse per tick.
      state.setTimeForTesting(5, 18, 0); // Friday 18:00
      state.setSpeed(GameSpeed.normal);
      
      int ticks = 0;
      while (!state.activePatrons.firstWhere((p) => p.id == 'target_patron').isCollapsed && ticks < 100) {
        state.tick();
        ticks++;
      }
      
      updatedTarget = state.activePatrons.firstWhere((p) => p.id == 'target_patron');
      expect(updatedTarget.isCollapsed, isTrue);
      expect(updatedTarget.diningFinishMinutes, greaterThan(state.currentDate.totalMinutes + 5000)); // locked in restaurant!
      expect(state.announcementHistory.any((a) => a.contains('GIDEON WEALTHY has suddenly collapsed')), isTrue);

      // 5. Carry collapsed diner to basement Operating Room!
      state.carryPatronToOperatingRoom('target_patron');
      
      updatedTarget = state.activePatrons.firstWhere((p) => p.id == 'target_patron');
      expect(updatedTarget.isSeated, isFalse);
      expect(updatedTarget.seatedTableId, isNull);
      expect(updatedTarget.isUnderOperation, isTrue);
      expect(state.announcementHistory.any((a) => a.contains('Quietly carried the unconscious body of GIDEON WEALTHY')), isTrue);

      // 6. Perform surgical harvest! Let's harvest kidneys for funds!
      final int initialFunds = state.resources['funds']?.toInt() ?? 0;
      state.performSurgicalHarvest('target_patron', harvestedOrgan: 'kidney');

      // Verify the target is cleanly removed from active patrons (corpse dissolved/disposed!)
      expect(state.activePatrons.any((p) => p.id == 'target_patron'), isFalse);
      
      // Verify reward is added
      expect(state.resources['funds'], initialFunds + 250);
      
      // Verify surgical logs are written
      expect(state.announcementHistory.last, contains('remains were cleanly dissolved in alchemical acid'));
      expect(state.announcementHistory[state.announcementHistory.length - 2], contains('Successfully harvested a living KIDNEY'));
    });
  });
}
