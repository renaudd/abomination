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
import 'package:uuid/uuid.dart';
import '../models/npc.dart';
import '../models/game_date.dart';
import '../models/body_part.dart';
import '../models/schedule.dart';
import '../models/diet.dart';
import '../models/combat_stats.dart';

class NPCGenerator {
  static final _random = Random();
  static final _uuid = Uuid();

  static NPC generateRefugee({GameDate? currentDate}) {
    final gender = _random.nextBool() ? 'Male' : 'Female';
    final age = _generateAge();
    final name = _generateName(gender);
    final group = _generateOrgGroup();
    final nationality = _pickOne(
      ['Swiss', 'French', 'German', 'Italian', 'Austrian'],
      weights: [50, 20, 15, 10, 5],
    );
    final religion = _pickOne(
      ['Protestant', 'Catholic', 'Jewish', 'Atheist', 'Agnostic', 'Calvinist'],
      weights: [40, 30, 5, 10, 10, 5],
    );

    final bioDate = currentDate ?? GameDate.initial();
    final biographyRes = generateBiographyForCharacter(
      role: 'Refugee',
      age: age,
      currentDate: bioDate,
      gender: gender,
    );

    final background = biographyRes.biography.characterClass;

    var stats = _generateStats(age);
    for (var entry in biographyRes.statModifiers.entries) {
      if (stats.containsKey(entry.key)) {
        stats[entry.key] = (stats[entry.key]! + entry.value).clamp(0, 10);
      }
    }

    var traits = _generateTraits(age);
    traits.addAll(biographyRes.traitsToAdd);

    final bodyParts = _generateBodyParts();
    final profession = _generateProfession(gender, age);
    final appearance = _generateAppearance(gender, age);
    final orientation = _generateOrientation(gender);

    var proficiencies = _generateProficiencies(age, background, profession);
    for (var entry in biographyRes.proficienciesToAdd.entries) {
      proficiencies[entry.key] = (proficiencies[entry.key] ?? 0.0) + entry.value;
    }

      // Base compensation structure
      int fee = 5 + _random.nextInt(15);
      // Base monthly salary is 10 for unskilled. The range will be around 8 to 15.
      int salary = 8 + _random.nextInt(4); // 8-11 base

      if (profession == 'Doctor' || profession == 'Psychologist' || profession == 'Engineer') {
        fee += 10;
        salary += 4; // 12-15
      } else if (profession == 'Laborer' || profession == 'Thief') {
        fee -= 2;
        salary -= 1; // 7-10
      }
      if (age > 40) {
        fee += 5;
        salary += 1;
      }

      return NPC(
        id: _uuid.v4(),
        name: name,
        role: profession,
        age: age,
        specimenType: 'Human',
        gender: gender,
        group: group,
        hiringFee: fee.clamp(5, 50),
        monthlySalary: salary.clamp(5, 20),
      nationality: nationality,
      religion: religion,
      stats: stats,
      traits: traits,
      bodyParts: bodyParts,
      schedule: NPCSchedule.defaultButler(),
      diet: NPCDiet.defaultDiet(),
      status: NPCStatus.idle,
      disposition: NPCDisposition.voluntary,
      sexualOrientation: orientation,
      appearance: appearance,
      isResident: true,
      proficiencies: proficiencies,
      chefStats: ChefSkills(
        knifeSkills: 10 + _random.nextInt(40),
        fireSkills: 10 + _random.nextInt(40),
        sanitation: 10 + _random.nextInt(40),
        nose: 10 + _random.nextInt(40),
      ),
      bio: biographyRes.biography.toParagraph(),
      biography: biographyRes.biography,
      birthDate: biographyRes.biography.birthDate,
      hometown: biographyRes.biography.placeOfBirth,
      background: background,
      combatStats: _generateCombatStats(profession, age),
      abilities: _generateRefugeeAbilities(profession),
    );
  }

  static NPCAppearance _generateAppearance(String gender, int age) {
    final skinTones = [
      const Color(0xFFFFDBAC),
      const Color(0xFFF1C27D),
      const Color(0xFFE0AC69),
      const Color(0xFF8D5524),
      const Color(0xFFC68642),
    ];

    final hairColors = [
      const Color(0xFF4B3621), // Brown
      const Color(0xFF090806), // Black
      const Color(0xFFE6BE8A), // Blonde
      const Color(0xFFA52A2A), // Red
      const Color(0xFFE8E8E8), // Grey
    ];

    final eyeColors = [
      Colors.brown,
      Colors.blue,
      Colors.blueGrey,
      Colors.green,
    ];

    final outfitColors = [
      Colors.brown.shade800,
      Colors.blueGrey.shade700,
      Colors.green.shade900,
      Colors.grey.shade800,
      const Color(0xFF4A4E69),
    ];

    HairStyle hairStyle = HairStyle.short;
    if (age > 60) {
      hairStyle = _pickOne([HairStyle.bald, HairStyle.short, HairStyle.messy]);
    } else {
      hairStyle = _pickOne(
        HairStyle.values.where((s) => s != HairStyle.none).toList(),
      );
    }

    FacialHairStyle facialHairStyle = FacialHairStyle.none;
    if (gender == 'Male' && age > 18) {
      facialHairStyle = _pickOne(
        FacialHairStyle.values,
        weights: [50, 15, 15, 10, 10],
      );
    }

    Color hairColor = _pickOne(hairColors);
    if (age > 55) hairColor = const Color(0xFFE8E8E8); // Go grey

    return NPCAppearance(
      hairStyle: hairStyle,
      facialHairStyle: facialHairStyle,
      bodyType: _pickOne(BodyType.values),
      bodyColor: _pickOne(skinTones),
      hairColor: hairColor,
      outfitColor: _pickOne(outfitColors),
      eyeColor: _pickOne(eyeColors),
    );
  }

  static int _generateAge() {
    double r = _random.nextDouble();
    if (r < 0.1) return 10 + _random.nextInt(6); // 10-15
    if (r < 0.5) return 16 + _random.nextInt(15); // 16-30
    if (r < 0.9) return 31 + _random.nextInt(30); // 31-60
    return 61 + _random.nextInt(20); // 61-80
  }

  static NPCOrgGroup _generateOrgGroup() {
    return _pickOne(
      [NPCOrgGroup.A, NPCOrgGroup.B, NPCOrgGroup.C, NPCOrgGroup.D],
      weights: [20, 30, 40, 10],
    );
  }

  static Map<String, int> _generateStats(int age) {
    int strength = 3 + _random.nextInt(5);
    int endurance = 3 + _random.nextInt(5);
    int adaptability = 3 + _random.nextInt(5);
    int dexterity = 3 + _random.nextInt(5);
    int intellect = 3 + _random.nextInt(5);
    int perception = 3 + _random.nextInt(5);
    int judgment = 3 + _random.nextInt(5);
    int temperament = 3 + _random.nextInt(5);
    int leadership = 2 + _random.nextInt(5);
    int courage = 3 + _random.nextInt(5);
    int hygiene = 4 + _random.nextInt(5);
    int beauty = 2 + _random.nextInt(6);
    int morality = 3 + _random.nextInt(5);

    if (age < 16) {
      strength -= 2;
      endurance += 1;
    } else if (age > 60) {
      intellect += 2;
      strength -= 2;
      endurance -= 2;
    }

    return {
      'strength': strength.clamp(0, 10),
      'endurance': endurance.clamp(0, 10),
      'adaptability': adaptability.clamp(0, 10),
      'dexterity': dexterity.clamp(0, 10),
      'intellect': intellect.clamp(0, 10),
      'perception': perception.clamp(0, 10),
      'judgment': judgment.clamp(0, 10),
      'temperament': temperament.clamp(0, 10),
      'leadership': leadership.clamp(0, 10),
      'courage': courage.clamp(0, 10),
      'hygiene': hygiene.clamp(0, 10),
      'beauty': beauty.clamp(0, 10),
      'morality': morality.clamp(0, 10),
      'walkSpeed': 2,
    };
  }

  static SexualOrientation _generateOrientation(String gender) {
    if (gender == 'Male') {
      return _pickOne(
        [
          SexualOrientation.straight,
          SexualOrientation.gay,
          SexualOrientation.bisexual,
          SexualOrientation.asexual,
        ],
        weights: [85, 5, 5, 5],
      );
    } else {
      return _pickOne(
        [
          SexualOrientation.straight,
          SexualOrientation.lesbian,
          SexualOrientation.bisexual,
          SexualOrientation.asexual,
        ],
        weights: [85, 5, 5, 5],
      );
    }
  }

  static List<NPCTrait> _generateTraits(int age) {
    final traits = <NPCTrait>[];
    traits.addAll(
      _pickTraits('character', _randomSelection([0, 1, 2, 3], [15, 55, 25, 5])),
    );
    traits.addAll(
      _pickTraits(
        'association',
        age < 16
            ? _randomSelection([0, 1], [65, 35])
            : _randomSelection([0, 1, 2], [30, 40, 30]),
      ),
    );
    traits.addAll(
      _pickTraits(
        'skill',
        age < 16
            ? _randomSelection([0, 1], [60, 40])
            : _randomSelection([1, 2, 3], [40, 50, 10]),
      ),
    );
    return traits;
  }

  static String _generateProfession(String gender, int age) {
    if (age < 16) return 'Child';
    return _pickOne([
      'Jeweler',
      'Blacksmith',
      'Surgeon',
      'Clockmaker',
      'Banker',
      'Horticulturalist',
      'Farmer',
      'Brewer',
      'Distiller',
      'Carpenter',
      'Cook',
      'Merchant',
      'Inventor',
      'Journalist',
      'Psychologist',
      'Doctor',
      'Florist',
    ]);
  }

  static Map<String, double> _generateProficiencies(int age, String background, String profession) {
    final proficiencies = <String, double>{};
    
    // Base amount of total experience points based on age
    int totalXpToDistribute = 0;
    if (age > 15) totalXpToDistribute += (age - 15) * 10;
    if (totalXpToDistribute > 400) totalXpToDistribute = 400; // Cap at max age benefit
    
    void addXp(String prof, double xp) {
      proficiencies[prof] = (proficiencies[prof] ?? 0.0) + xp;
    }
    
    // Background bonuses
    switch (background) {
      case 'Noble':
      case 'Merchant':
        addXp('Research', 40.0);
        addXp('Writing', 20.0);
        break;
      case 'Peasant':
        addXp('Farming', 40.0);
        addXp('Cooking', 20.0);
        addXp('Cleaning', 20.0);
        break;
      case 'Scholar':
        addXp('Research', 80.0);
        addXp('Medicine', 20.0);
        break;
      case 'Soldier':
      case 'Criminal':
        addXp('Hunting', 40.0);
        addXp('Surgery', 10.0);
        break;
    }
    
    // Profession specific
    String? primaryProficiency;
    switch (profession) {
      case 'Surgeon':
      case 'Doctor':
        primaryProficiency = 'Surgery';
        addXp('Medicine', 40.0);
        break;
      case 'Farmer':
      case 'Horticulturalist':
      case 'Florist':
        primaryProficiency = 'Farming';
        break;
      case 'Brewer':
      case 'Distiller':
        primaryProficiency = 'Brewing';
        break;
      case 'Carpenter':
      case 'Blacksmith':
      case 'Clockmaker':
      case 'Jeweler':
      case 'Inventor':
        primaryProficiency = 'Construction';
        addXp('Manufacturing', 40.0);
        break;
      case 'Cook':
        primaryProficiency = 'Cooking';
        break;
      case 'Journalist':
        primaryProficiency = 'Writing';
        break;
      case 'Psychologist':
        primaryProficiency = 'Research';
        addXp('Therapy', 40.0);
        break;
    }

    if (primaryProficiency != null) {
        addXp(primaryProficiency, totalXpToDistribute * 0.7);
        totalXpToDistribute = (totalXpToDistribute * 0.3).toInt();
    }
    
    // Distribute remaining points randomly among a few common proficiencies
    final common = ['Cooking', 'Cleaning', 'Farming', 'Hunting', 'Construction'];
    while (totalXpToDistribute > 0) {
       int amount = min(20, totalXpToDistribute);
       addXp(_pickOne(common), amount.toDouble());
       totalXpToDistribute -= amount;
    }

    return proficiencies;
  }

  static List<BodyPart> _generateBodyParts() {
    return [
      BodyPart(type: BodyPartType.head, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.torso, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.rightArm, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.leftArm, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.rightLeg, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.leftLeg, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.rightEye, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.leftEye, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.rightEar, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.leftEar, health: 100, maxHealth: 100),
    ];
  }

  static T _pickOne<T>(List<T> options, {List<int>? weights}) {
    if (weights == null) return options[_random.nextInt(options.length)];
    int total = weights.reduce((a, b) => a + b);
    int r = _random.nextInt(total);
    int current = 0;
    for (int i = 0; i < weights.length; i++) {
      current += weights[i];
      if (r < current) return options[i];
    }
    return options.first;
  }

  static int _randomSelection(List<int> values, List<int> weights) {
    return _pickOne(values, weights: weights);
  }

  static List<NPCTrait> _pickTraits(String group, int count) {
    final pool = _traitPool[group] ?? [];
    if (pool.isEmpty || count == 0) return [];
    final result = <NPCTrait>[];
    final selectedPool = List<String>.from(pool)..shuffle(_random);
    for (int i = 0; i < min(count, selectedPool.length); i++) {
      String id = selectedPool[i];
      result.add(NPCTrait(id: id, name: _traitNames[id] ?? id, group: group));
    }
    return result;
  }

  static String _generateName(String gender) {
    final first = gender == 'Male'
        ? ['Hans', 'Karl', 'Otto', 'Wilhelm', 'Emil']
        : ['Heidi', 'Clara', 'Martha', 'Greta', 'Anna'];
    final last = ['Müller', 'Schmidt', 'Schneider', 'Fischer', 'Weber'];
    return "${first[_random.nextInt(first.length)]} ${last[_random.nextInt(last.length)]}";
  }

  static const _traitPool = {
    'character': [
      'loyal',
      'mutinous',
      'stoic',
      'hardworking',
      'lazy',
      'honest',
      'dishonest',
      'violent',
      'efficient',
      'genius',
      'idiot',
      'pleasant',
      'unpleasant',
    ],
    'association': [
      'religious',
      'communist',
      'racist',
      'conservative',
      'liberal',
    ],
    'skill': [
      'track_finder',
      'forager',
      'perfect_pitch',
      'greenthumb',
      'lucky',
      'super_vision',
      'leader',
      'teacher',
      'scrivener',
    ],
  };



  static const _traitNames = {
    'loyal': 'Loyal',
    'mutinous': 'Mutinous',
    'stoic': 'Stoic',
    'hardworking': 'Hardworking',
    'lazy': 'Lazy',
    'honest': 'Honest',
    'dishonest': 'Dishonest',
    'violent': 'Violent',
    'efficient': 'Efficient',
    'genius': 'Genius',
    'idiot': 'Idiot',
    'pleasant': 'Pleasant',
    'unpleasant': 'Unpleasant',
    'religious': 'Religious',
    'communist': 'Communist',
    'racist': 'Racist',
    'conservative': 'Conservative',
    'liberal': 'Liberal',
    'track_finder': 'Track Finder',
    'forager': 'Forager',
    'perfect_pitch': 'Perfect Pitch',
    'greenthumb': 'Green Thumb',
    'lucky': 'Lucky',
    'super_vision': 'Super Vision',
    'leader': 'Leader',
    'teacher': 'Teacher',
    'scrivener': 'Scrivener',
  };

  static CombatStats _generateCombatStats(String profession, int age) {
    // Base stats for a human refugee
    double hp = 40.0 + _random.nextInt(20);
    double atk = 5.0 + _random.nextInt(10);
    double def = 0.0 + _random.nextInt(5);
    double acc = 0.6 + (_random.nextDouble() * 0.2);
    double speed = 2.0 + (_random.nextDouble() * 1.5); // seconds per attack
    double move = 2.0 + (_random.nextDouble() * 1.0); // meters per second
    double dist = 1.0; // Melee by default
    int cost = 3;

    // Profession modifiers
    if (profession == 'Soldier' || profession == 'Mercenary') {
      hp += 20;
      atk += 5;
      def += 5;
      acc += 0.1;
      cost = 5;
    } else if (profession == 'Hunter') {
      dist = 15.0; // Ranged
      acc += 0.15;
      hp -= 5;
      cost = 4;
    } else if (profession == 'Surgeon' || profession == 'Doctor') {
      hp += 10;
      cost = 4;
    }

    // Age modifiers
    if (age < 18) {
      hp -= 10;
      atk -= 2;
    } else if (age > 60) {
      hp -= 15;
      speed += 1.0;
    }

    return CombatStats(
      attack: atk,
      health: hp,
      maxHealth: hp,
      speed: speed,
      movement: move,
      distance: dist,
      defense: def,
      accuracy: acc.clamp(0.0, 1.0),
      cost: cost,
    );
  }

  static List<Ability> _generateRefugeeAbilities(String profession) {
    final abilities = <Ability>[];

    // Common refugee traits
    if (_random.nextDouble() < 0.3) {
      abilities.add(
        const Ability(
          id: 'accuracy_boost',
          name: 'STAY FOCUSED',
          type: AbilityType.trait,
          description: 'Increases accuracy by 5% on spawn.',
          effectData: {'on_spawn': true},
        ),
      );
    }

    // Profession specific
    if (profession == 'Surgeon' || profession == 'Doctor') {
      abilities.add(
        const Ability(
          id: 'horn_heal',
          name: 'FIELD MEDIC',
          type: AbilityType.horn,
          description: 'Heals the nearest ally for 10 HP on spawn.',
          effectData: {'heal': 10, 'range': 5.0},
        ),
      );
    } else if (profession == 'Hunter') {
      abilities.add(
        const Ability(
          id: 'accuracy_boost',
          name: 'SNIPER SIGHT',
          type: AbilityType.trait,
          description: 'Passive accuracy boost.',
        ),
      );
    }

    return abilities;
  }

  static GameDate generateBirthDate(int age, GameDate currentDate) {
    final birthYear = currentDate.year - age;
    final birthMonth = 1 + _random.nextInt(12);
    final birthDay = 1 + _random.nextInt(30);
    return GameDate(
      minute: 0,
      hour: 12,
      day: birthDay,
      month: birthMonth,
      year: birthYear,
    );
  }

  static BiographyResult generateBiographyForCharacter({
    required String role,
    required int age,
    required GameDate currentDate,
    required String gender,
  }) {
    final birthDate = generateBirthDate(age, currentDate);

    String placeOfBirth = "";
    String fatherProfession = "";
    String fatherClass = "";
    String fatherReligion = "";
    String motherProfession = "";
    String motherClass = "";
    String motherReligion = "";
    String parentsMaritalStatus = "";
    String characterClass = "";

    final statModifiers = <String, int>{};
    final traitsToAdd = <NPCTrait>[];
    final proficienciesToAdd = <String, double>{};

    if (role == 'Master') {
      // Player character constraints: suits inheritor of a large estate in French Switzerland
      placeOfBirth = _pickOne(['Geneva', 'Lausanne', 'Neuchâtel', 'Vevey']);
      fatherClass = 'Noble';
      fatherProfession = _pickOne(['Landowner', 'Banker', 'Diplomat', 'Aristocrat']);
      fatherReligion = _pickOne(['Protestant', 'Calvinist', 'Catholic'], weights: [60, 20, 20]);
      motherClass = _pickOne(['Noble', 'Merchant']);
      motherProfession = _pickOne(['None', 'Socialite']);
      motherReligion = fatherReligion; // Match for high status families
      parentsMaritalStatus = 'in wedlock';
      characterClass = 'Noble';

      // Apply variations based on player's age
      if (age < 30) {
        statModifiers['strength'] = 1;
        statModifiers['endurance'] = 1;
        statModifiers['walkSpeed'] = 5;
        statModifiers['intellect'] = -1;
        statModifiers['judgment'] = -1;
        statModifiers['leadership'] = -1;
        traitsToAdd.add(NPCTrait(id: 'track_finder', name: 'Track Finder', group: 'skill'));
        proficienciesToAdd['Farming'] = 10.0;
      } else if (age >= 30 && age < 46) {
        // Standard/median stats
        proficienciesToAdd['Research'] = 20.0;
        proficienciesToAdd['Accounting'] = 20.0;
      } else {
        // Old player
        statModifiers['intellect'] = 2;
        statModifiers['judgment'] = 2;
        statModifiers['leadership'] = 2;
        statModifiers['strength'] = -2;
        statModifiers['endurance'] = -2;
        statModifiers['walkSpeed'] = -5;
        traitsToAdd.add(NPCTrait(id: 'stoic', name: 'Stoic', group: 'character'));
        proficienciesToAdd['Research'] = 40.0;
        proficienciesToAdd['Accounting'] = 40.0;
        proficienciesToAdd['Writing'] = 20.0;
      }
    } else if (role == 'Butler') {
      // Giles caretaker constraints
      placeOfBirth = _pickOne(['Lausanne', 'Fribourg', 'Sion', 'Vevey']);
      fatherClass = 'Servant';
      fatherProfession = _pickOne(['Butler', 'Valet', 'Clerk', 'Head Gardener']);
      fatherReligion = _pickOne(['Protestant', 'Catholic'], weights: [50, 50]);
      motherClass = 'Servant';
      motherProfession = _pickOne(['None', 'Housekeeper', 'Cook']);
      motherReligion = fatherReligion;
      parentsMaritalStatus = 'in wedlock';
      characterClass = 'Servant';
    } else {
      // Regular refugees
      placeOfBirth = _pickOne([
        'Geneva', 'Lausanne', 'Zürich', 'Bern', 'Basel', 'Lucerne',
        'Paris', 'Lyon', 'Milan', 'Munich', 'Vienna'
      ]);
      fatherClass = _pickOne(['Noble', 'Merchant', 'Scholar', 'Soldier', 'Peasant', 'Criminal'], weights: [5, 15, 10, 15, 50, 5]);
      fatherProfession = _generateRandomProfession(fatherClass);
      fatherReligion = _pickOne(['Protestant', 'Catholic', 'Calvinist', 'Jewish', 'Atheist'], weights: [35, 45, 10, 5, 5]);
      
      motherClass = _pickOne(['Noble', 'Merchant', 'Scholar', 'Peasant', 'Servant'], weights: [5, 15, 5, 60, 15]);
      motherProfession = _random.nextDouble() < 0.6 ? 'None' : _generateRandomProfession(motherClass);
      motherReligion = _pickOne(['Protestant', 'Catholic', 'Calvinist', 'Jewish', 'Atheist'], weights: [35, 45, 10, 5, 5]);
      
      parentsMaritalStatus = _pickOne(['in wedlock', 'out of wedlock', 'spurious'], weights: [80, 15, 5]);
      
      // Determine character class
      if (parentsMaritalStatus == 'in wedlock') {
        characterClass = fatherClass;
      } else if (parentsMaritalStatus == 'out of wedlock') {
        if (fatherClass == 'Noble' || motherClass == 'Noble') {
          characterClass = 'Merchant';
        } else if (fatherClass == 'Merchant' || motherClass == 'Merchant') {
          characterClass = 'Scholar';
        } else {
          characterClass = 'Peasant';
        }
      } else {
        characterClass = _pickOne(['Peasant', 'Criminal'], weights: [80, 20]);
      }
    }

    // Formative childhood event (if >10 years old)
    String? childhoodEvent;
    if (age > 10) {
      final events = [
        "Survived a harsh winter that taught them self-reliance.",
        "Watched their family's workshop burn down, breeding a fear of fire.",
        "Discovered an ancient Roman coin in the fields, sparking a love of history.",
        "Spent summers reading in a grand library.",
        "Suffered a severe illness but recovered miraculously."
      ];
      final idx = _random.nextInt(events.length);
      childhoodEvent = events[idx];
      switch (idx) {
        case 0:
          statModifiers['adaptability'] = (statModifiers['adaptability'] ?? 0) + 1;
          break;
        case 1:
          statModifiers['perception'] = (statModifiers['perception'] ?? 0) + 1;
          break;
        case 2:
          statModifiers['intellect'] = (statModifiers['intellect'] ?? 0) + 1;
          break;
        case 3:
          statModifiers['judgment'] = (statModifiers['judgment'] ?? 0) + 1;
          break;
        case 4:
          statModifiers['endurance'] = (statModifiers['endurance'] ?? 0) + 1;
          break;
      }
    }

    // Education or Apprenticeship (if >15 years old)
    String? educationOrApprenticeship;
    if (age > 15) {
      final educationOptions = [
        "Apprenticed to a local clockmaker.",
        "Studied theology at a Swiss academy.",
        "Trained under a renowned surgeon.",
        "Worked the vines in the Vaud region.",
        "Learned the trade of bookkeeping."
      ];
      final idx = _random.nextInt(educationOptions.length);
      educationOrApprenticeship = educationOptions[idx];
      switch (idx) {
        case 0:
          proficienciesToAdd['Construction'] = (proficienciesToAdd['Construction'] ?? 0.0) + 20.0;
          proficienciesToAdd['Manufacturing'] = (proficienciesToAdd['Manufacturing'] ?? 0.0) + 20.0;
          statModifiers['dexterity'] = (statModifiers['dexterity'] ?? 0) + 1;
          break;
        case 1:
          proficienciesToAdd['Research'] = (proficienciesToAdd['Research'] ?? 0.0) + 20.0;
          proficienciesToAdd['Writing'] = (proficienciesToAdd['Writing'] ?? 0.0) + 10.0;
          statModifiers['morality'] = (statModifiers['morality'] ?? 0) + 1;
          traitsToAdd.add(NPCTrait(id: 'religious', name: 'Religious', group: 'association'));
          break;
        case 2:
          proficienciesToAdd['Surgery'] = (proficienciesToAdd['Surgery'] ?? 0.0) + 20.0;
          proficienciesToAdd['Medicine'] = (proficienciesToAdd['Medicine'] ?? 0.0) + 20.0;
          statModifiers['intellect'] = (statModifiers['intellect'] ?? 0) + 1;
          break;
        case 3:
          proficienciesToAdd['Farming'] = (proficienciesToAdd['Farming'] ?? 0.0) + 30.0;
          statModifiers['endurance'] = (statModifiers['endurance'] ?? 0) + 1;
          break;
        case 4:
          proficienciesToAdd['Accounting'] = (proficienciesToAdd['Accounting'] ?? 0.0) + 30.0;
          statModifiers['judgment'] = (statModifiers['judgment'] ?? 0) + 1;
          break;
      }
    }

    // Profession (if >20 years old)
    String? finalProfession;
    if (age > 20) {
      finalProfession = role == 'Master' ? 'Estate Master' : (role == 'Butler' ? 'Butler' : _generateRandomProfession(characterClass));
    }

    // Relationship status (if >=25 years old)
    String? relationshipStatus;
    if (age >= 25) {
      relationshipStatus = _pickOne(['married', 'widowed', 'spurned', 'engaged', 'bachelor'], weights: [40, 10, 10, 10, 30]);
    }

    // Tragic event (if >30 years old)
    String? tragicEvent;
    if (age > 30) {
      final tragedies = [
        "Lost their spouse to consumption, leaving them melancholic.",
        "Betrayed by a business partner, making them cynical.",
        "Fled their home city due to political turmoil, losing all their possessions.",
        "Surrendered to a brief period of imprisonment for a debt they did not owe."
      ];
      final idx = _random.nextInt(tragedies.length);
      tragicEvent = tragedies[idx];
      switch (idx) {
        case 0:
          statModifiers['temperament'] = (statModifiers['temperament'] ?? 0) - 1;
          traitsToAdd.add(NPCTrait(id: 'unpleasant', name: 'Unpleasant', group: 'character'));
          break;
        case 1:
          statModifiers['morality'] = (statModifiers['morality'] ?? 0) - 1;
          statModifiers['perception'] = (statModifiers['perception'] ?? 0) + 1;
          traitsToAdd.add(NPCTrait(id: 'dishonest', name: 'Dishonest', group: 'character'));
          break;
        case 2:
          statModifiers['adaptability'] = (statModifiers['adaptability'] ?? 0) + 1;
          traitsToAdd.add(NPCTrait(id: 'stoic', name: 'Stoic', group: 'character'));
          break;
        case 3:
          statModifiers['courage'] = (statModifiers['courage'] ?? 0) - 1;
          break;
      }
    }

    // Discovered passion (if >40 years old)
    String? discoveredPassion;
    if (age > 40) {
      final passions = [
        "Developed a deep love for classical piano, spending hours playing.",
        "Began painting pastoral landscapes of the Swiss Alps.",
        "Became obsessed with cataloging rare botanical specimens.",
        "Took up fly fishing in mountain streams."
      ];
      final idx = _random.nextInt(passions.length);
      discoveredPassion = passions[idx];
      switch (idx) {
        case 0:
          statModifiers['beauty'] = (statModifiers['beauty'] ?? 0) + 1;
          traitsToAdd.add(NPCTrait(id: 'perfect_pitch', name: 'Perfect Pitch', group: 'skill'));
          break;
        case 1:
          statModifiers['beauty'] = (statModifiers['beauty'] ?? 0) + 1;
          break;
        case 2:
          statModifiers['perception'] = (statModifiers['perception'] ?? 0) + 1;
          traitsToAdd.add(NPCTrait(id: 'greenthumb', name: 'Green Thumb', group: 'skill'));
          break;
        case 3:
          statModifiers['temperament'] = (statModifiers['temperament'] ?? 0) + 1;
          break;
      }
    }

    // Health issue (if >50 years old)
    String? healthIssue;
    if (age > 50) {
      final healthIssues = [
        "Developed a stiff knee, slowing their movements.",
        "Suffers from chronic asthma, especially on damp mornings.",
        "Slightly failing eyesight, requiring spectacles to read.",
        "Gout in the left foot, causing periodic pain and irritability."
      ];
      final idx = _random.nextInt(healthIssues.length);
      healthIssue = healthIssues[idx];
      switch (idx) {
        case 0:
          statModifiers['walkSpeed'] = (statModifiers['walkSpeed'] ?? 0) - 5;
          statModifiers['strength'] = (statModifiers['strength'] ?? 0) - 1;
          break;
        case 1:
          statModifiers['endurance'] = (statModifiers['endurance'] ?? 0) - 1;
          break;
        case 2:
          statModifiers['perception'] = (statModifiers['perception'] ?? 0) - 1;
          traitsToAdd.add(NPCTrait(id: 'super_vision', name: 'Myopia', group: 'physical'));
          break;
        case 3:
          statModifiers['temperament'] = (statModifiers['temperament'] ?? 0) - 1;
          break;
      }
    }

    final bioObj = CharacterBiography(
      birthDate: birthDate,
      placeOfBirth: placeOfBirth,
      fatherProfession: fatherProfession,
      fatherClass: fatherClass,
      fatherReligion: fatherReligion,
      motherProfession: motherProfession,
      motherClass: motherClass,
      motherReligion: motherReligion,
      parentsMaritalStatus: parentsMaritalStatus,
      characterClass: characterClass,
      childhoodEvent: childhoodEvent,
      educationOrApprenticeship: educationOrApprenticeship,
      profession: finalProfession,
      relationshipStatus: relationshipStatus,
      tragicEvent: tragicEvent,
      discoveredPassion: discoveredPassion,
      healthIssue: healthIssue,
    );

    return BiographyResult(
      biography: bioObj,
      statModifiers: statModifiers,
      traitsToAdd: traitsToAdd,
      proficienciesToAdd: proficienciesToAdd,
      finalClass: characterClass,
    );
  }

  static String _generateRandomProfession(String className) {
    switch (className) {
      case 'Noble':
        return _pickOne(['Landowner', 'Diplomat', 'Aristocrat', 'Officer']);
      case 'Merchant':
        return _pickOne(['Banker', 'Jeweler', 'Clockmaker', 'Merchant', 'Florist']);
      case 'Scholar':
        return _pickOne(['Surgeon', 'Doctor', 'Psychologist', 'Journalist', 'Inventor']);
      case 'Soldier':
        return _pickOne(['Officer', 'Soldier', 'Guard', 'Mercenary']);
      case 'Peasant':
        return _pickOne(['Farmer', 'Horticulturalist', 'Brewer', 'Cook', 'Carpenter', 'Blacksmith']);
      case 'Criminal':
        return _pickOne(['Thief', 'Smuggler', 'Burglar', 'Con Artist']);
      case 'Servant':
        return _pickOne(['Butler', 'Housekeeper', 'Cook', 'Valet', 'Maid']);
      default:
        return 'Commoner';
    }
  }
}

class BiographyResult {
  final CharacterBiography biography;
  final Map<String, int> statModifiers;
  final List<NPCTrait> traitsToAdd;
  final Map<String, double> proficienciesToAdd;
  final String finalClass;

  BiographyResult({
    required this.biography,
    required this.statModifiers,
    required this.traitsToAdd,
    required this.proficienciesToAdd,
    required this.finalClass,
  });
}
