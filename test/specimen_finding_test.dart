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
import 'package:abomination/models/npc.dart';
import 'package:abomination/services/task_service.dart';
import 'package:abomination/services/task_result_generator.dart';
import 'package:abomination/util/manor_layout.dart';

void main() {
  group('Manor Layout Refinement', () {
    test('Toolshed and Chicken Coop are shifted left', () {
      final coop = ManorLayout.grid['chicken_coop'];
      final shed = ManorLayout.grid['toolshed'];

      expect(coop?.$1, equals(3.8));
      expect(shed?.$1, equals(3.8));
    });
  });

  group('Specimen Finding Logic', () {
    final worker = NPC.initialButler();

    test('Finding Rats in Bedroom (Cleaning)', () {
      int ratsFound = 0;
      for (int i = 0; i < 1000; i++) {
        final result = TaskResultGenerator.generate(
          TaskType.cleanRoom,
          'Master Bedroom',
          worker,
          targetId: 'master_bedroom',
        );
        if (result.itemsFound.any((item) => item.type == 'rat_specimen')) {
          ratsFound++;
        }
      }
      // Chance is 8%, expect around 80
      expect(ratsFound, greaterThan(40));
      expect(ratsFound, lessThan(130));
    });

    test('Finding Bats in Attic (Cleaning)', () {
      int batsFound = 0;
      for (int i = 0; i < 1000; i++) {
        final result = TaskResultGenerator.generate(
          TaskType.cleanRoom,
          'Attic',
          worker,
          targetId: 'attic',
        );
        if (result.itemsFound.any((item) => item.type == 'bat_specimen')) {
          batsFound++;
        }
      }
      // Chance is 4%, expect around 40
      expect(batsFound, greaterThan(15));
      expect(batsFound, lessThan(75));
    });

    test('Restoration has higher chances', () {
      int ratsCleaning = 0;
      int ratsRestoring = 0;
      for (int i = 0; i < 1000; i++) {
        if (TaskResultGenerator.generate(
          TaskType.cleanRoom,
          'Room',
          worker,
          targetId: 'other',
        ).itemsFound.any((item) => item.type == 'rat_specimen')) {
          ratsCleaning++;
        }
        if (TaskResultGenerator.generate(
          TaskType.restoreRoom,
          'Room',
          worker,
          targetId: 'other',
        ).itemsFound.any((item) => item.type == 'rat_specimen')) {
          ratsRestoring++;
        }
      }
      // Cleaning: 25%, Restoring: 40%
      expect(ratsRestoring, greaterThan(ratsCleaning));
    });
  });
}
