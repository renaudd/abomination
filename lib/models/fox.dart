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
import 'package:flutter/material.dart';
import 'npc.dart';
import 'combat_stats.dart';
import 'schedule.dart';
import 'diet.dart';
import 'body_part.dart';
import 'game_date.dart';

class FoxGenerator {
  static NPC createFox(String id, GameDate currentDate) {
    final random = Random();
    final isMale = random.nextBool();
    final weightGrams = 3000 + random.nextInt(4000); // 3-7kg
    final ageWeeks = 50 + random.nextInt(200);
    final ageYears = (ageWeeks / 52).floor();
    final remainingWeeks = ageWeeks % 52;
    final ageMonths = (remainingWeeks / 4).floor();
    
    int newYear = currentDate.year - ageYears;
    int newMonth = currentDate.month - ageMonths;
    if (newMonth <= 0) {
      newMonth += 12;
      newYear--;
    }

    // Approximate birthDate
    final birthDate = currentDate.copyWith(
      year: newYear,
      month: newMonth,
    );

    return NPC(
      id: id,
      name: "Wild Fox",
      role: "Creature",
      age: (ageWeeks / 52).floor(),
      birthDate: birthDate,
      gender: isMale ? "Male" : "Female",
      nationality: "Estate",
      religion: "Nature",
      specimenType: "Fox",
      isPlayer: false,
      isResident: false,
      status: NPCStatus.idle,
      disposition: NPCDisposition.voluntary,
      currentRoomId: null,
      stats: {
        'strength': 15,
        'endurance': 25,
        'intelligence': 30,
        'willpower': 20,
        'agility': 40,
        'weightGrams': weightGrams,
      },
      appearance: NPCAppearance(
        hairStyle: HairStyle.none,
        facialHairStyle: FacialHairStyle.none,
        bodyColor: Colors.orange.shade800,
        hairColor: Colors.white,
        outfitColor: Colors.transparent,
      ),
      bodyParts: [
        BodyPart(type: BodyPartType.head, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.torso, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.rightLeg, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.leftLeg, health: 100, maxHealth: 100),
      ],
      combatStats: const CombatStats(
        health: 40,
        maxHealth: 40,
        attack: 8,
        defense: 5,
        speed: 1.5,
        movement: 1.2,
        distance: 0.5,
        accuracy: 0.8,
        cost: 0,
      ),
      inventory: [],
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
    );
  }
}
