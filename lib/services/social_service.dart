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

import '../models/npc.dart';
import '../models/relationship.dart';
import 'dart:math';

enum InteractionType {
  chat,
  argument,
  praise,
  threaten,
  encourage,
  boast,
  shareSecret,
  workTogether,
}

class SocialService {
  static final Random _random = Random();

  static Map<String, dynamic> performInteraction(
    NPC actor,
    NPC target,
    InteractionType type,
  ) {
    Relationship actorToTarget =
        actor.relationships[target.id] ?? Relationship();
    Relationship targetToActor =
        target.relationships[actor.id] ?? Relationship();

    String log = "";
    String speechQuote = getDialogueQuote(actor, type);

    // Logic for how interactions affect relationship values
    switch (type) {
      case InteractionType.chat:
        log = "${actor.name} and ${target.name} had a pleasant conversation. ${actor.name} remarked, $speechQuote";
        targetToActor = targetToActor.copyWith(
          admiration: targetToActor.admiration + 0.05,
          respect: targetToActor.respect + 0.02,
          attraction: targetToActor.attraction + 0.01,
        );
        break;
      case InteractionType.argument:
        log = "${actor.name} and ${target.name} had a heated argument. ${actor.name} declared, $speechQuote";
        targetToActor = targetToActor.copyWith(
          admiration: targetToActor.admiration - 0.1,
          respect: targetToActor.respect - 0.05,
          attraction: targetToActor.attraction - 0.05,
        );
        actorToTarget = actorToTarget.copyWith(
          admiration: actorToTarget.admiration - 0.1,
          attraction: actorToTarget.attraction - 0.05,
        );
        break;
      case InteractionType.praise:
        log = "${actor.name} praised ${target.name}'s efforts, saying, $speechQuote";
        targetToActor = targetToActor.copyWith(
          admiration: targetToActor.admiration + 0.1,
          respect: targetToActor.respect + 0.05,
        );
        break;
      case InteractionType.threaten:
        log = "${actor.name} threatened ${target.name}, warning: $speechQuote";
        targetToActor = targetToActor.copyWith(
          fear: targetToActor.fear + 0.2,
          admiration: targetToActor.admiration - 0.2,
          attraction: targetToActor.attraction - 0.1,
        );
        break;
      case InteractionType.encourage:
        log = "${actor.name} encouraged ${target.name}, saying, $speechQuote";
        targetToActor = targetToActor.copyWith(
          respect: targetToActor.respect + 0.1,
          admiration: targetToActor.admiration + 0.05,
        );
        break;
      case InteractionType.workTogether:
        log = "${actor.name} and ${target.name} worked together efficiently. ${actor.name} noted, $speechQuote";
        targetToActor = targetToActor.copyWith(
          respect: targetToActor.respect + 0.05,
          admiration: targetToActor.admiration + 0.02,
        );
        actorToTarget = actorToTarget.copyWith(
          respect: actorToTarget.respect + 0.05,
          admiration: actorToTarget.admiration + 0.02,
        );
        break;
      default:
        log = "${actor.name} interacted with ${target.name}.";
    }

    return {
      'actorRelationship': actorToTarget,
      'targetRelationship': targetToActor,
      'log': log,
    };
  }

  static String getDialogueQuote(NPC actor, InteractionType type) {
    final characterClass = actor.biography?.characterClass ?? actor.background;
    final religion = actor.religion;
    final hometown = actor.hometown;

    // 1. Pick base phrase by InteractionType
    String basePhrase = "";
    switch (type) {
      case InteractionType.chat:
        basePhrase = "the weather is quite interesting today";
        break;
      case InteractionType.argument:
        basePhrase = "I strongly disagree with your assessment";
        break;
      case InteractionType.praise:
        basePhrase = "you have done an exceptional job";
        break;
      case InteractionType.threaten:
        basePhrase = "you had better watch your step around here";
        break;
      case InteractionType.encourage:
        basePhrase = "keep pushing forward, you are doing well";
        break;
      case InteractionType.workTogether:
        basePhrase = "we make quite a productive team";
        break;
      default:
        basePhrase = "it is good to see you";
    }

    // 2. Modify/style based on Class (Noble, Peasant, Merchant, Scholar, Servant, etc.)
    String classPrefix = "";
    String classSuffix = "";
    if (characterClass == 'Noble') {
      classPrefix = "Indeed, ";
      classSuffix = ", as one must expect from high standing";
      if (type == InteractionType.argument) {
        basePhrase = "your lack of refinement is showing, and I must object";
      } else if (type == InteractionType.praise) {
        basePhrase = "your efforts are truly commendable and fitting";
      }
    } else if (characterClass == 'Peasant') {
      classPrefix = "Ay, ";
      classSuffix = ", reckon that's just how it is";
      if (type == InteractionType.argument) {
        basePhrase = "that's absolute nonsense, plain and simple";
      } else if (type == InteractionType.praise) {
        basePhrase = "you did a mighty fine job there";
      }
    } else if (characterClass == 'Merchant') {
      classPrefix = "To be frank, ";
      classSuffix = ", it is simply a matter of solid value";
      if (type == InteractionType.argument) {
        basePhrase = "this doesn't add up, the margin for error is too high";
      } else if (type == InteractionType.praise) {
        basePhrase = "your productivity is highly profitable for us all";
      }
    } else if (characterClass == 'Scholar') {
      classPrefix = "Conclusively, ";
      classSuffix = ", based on rational deduction";
      if (type == InteractionType.argument) {
        basePhrase = "your logic is fundamentally flawed and lacks evidence";
      } else if (type == InteractionType.praise) {
        basePhrase = "your execution demonstrates highly intellectual precision";
      }
    } else if (characterClass == 'Servant') {
      classPrefix = "If I may say, ";
      classSuffix = ", as duty demands";
      if (type == InteractionType.argument) {
        basePhrase = "that is quite irregular, and I must advise against it";
      } else if (type == InteractionType.praise) {
        basePhrase = "your service has been exemplary";
      }
    }

    // 3. Religion influence (Protestant, Catholic, Atheist, Jewish, etc.)
    String religionWord = "";
    if (religion == 'Protestant' || religion == 'Calvinist') {
      religionWord = " By God's grace, we must do our duty.";
    } else if (religion == 'Catholic') {
      religionWord = " Blessings of the saints upon us.";
    } else if (religion == 'Jewish') {
      religionWord = " Baruch Hashem, let us find peace.";
    } else if (religion == 'Atheist' || religion == 'Agnostic') {
      religionWord = " Human reason must guide us.";
    }

    // 4. Place of origin influence (French Swiss / Geneva / Lausanne / Zürich / etc.)
    String originWord = "";
    final ht = hometown.toLowerCase();
    if (ht.contains('geneva') || ht.contains('lausanne') || actor.nationality.toLowerCase() == 'french') {
      originWord = "Naturellement!";
    } else if (ht.contains('zürich') || ht.contains('bern') || actor.nationality.toLowerCase() == 'german') {
      originWord = "Ja, precisely.";
    } else if (actor.nationality.toLowerCase() == 'italian') {
      originWord = "Allora!";
    }

    String speech = "$classPrefix$basePhrase$classSuffix.";
    if (religionWord.isNotEmpty && _random.nextDouble() < 0.5) {
      speech += religionWord;
    }
    if (originWord.isNotEmpty && _random.nextDouble() < 0.5) {
      speech = "$originWord $speech";
    }

    return "\"$speech\"";
  }

  static double calculateInitialAttraction(NPC observer, NPC target) {
    // 1. Orientation Check
    bool isAttractedByGender = false;
    final oSex = observer.gender.toLowerCase();
    final tSex = target.gender.toLowerCase();

    switch (observer.sexualOrientation) {
      case SexualOrientation.straight:
        isAttractedByGender = oSex != tSex;
        break;
      case SexualOrientation.gay:
        isAttractedByGender = oSex == 'male' && tSex == 'male';
        break;
      case SexualOrientation.lesbian:
        isAttractedByGender = oSex == 'female' && tSex == 'female';
        break;
      case SexualOrientation.bisexual:
        isAttractedByGender = true;
        break;
      case SexualOrientation.asexual:
        isAttractedByGender = false;
        break;
    }

    if (!isAttractedByGender) {
      return 0.5 + (_random.nextDouble() * 0.5); // Repulsed range (below 1.0)
    }

    // 2. Base Attraction (Stats)
    double base = 2.0;

    int charisma = target.stats['charisma'] ?? 5;
    int vitality = target.stats['vitality'] ?? 5;

    base += (charisma / 100.0) * 1.5;
    base += (vitality / 100.0) * 0.2; // Downgraded to tertiary

    // 3. Age Factor
    double ageScore = 1.0;
    if (observer.gender.toLowerCase() == 'male') {
      int distFrom20 = (target.age - 20).abs();
      ageScore = (1.0 - (distFrom20 / 40.0)).clamp(0.0, 1.0);
    } else {
      int distFrom40 = (target.age - 20).abs();
      ageScore = (1.0 - (distFrom40 / 40.0)).clamp(0.0, 1.0);
    }
    base += ageScore * 0.8;

    // 4. Physical Condition
    int missingParts = target.bodyParts.where((bp) => !bp.isAttached).length;
    base -= missingParts * 0.25;

    // 5. Random Variance (Reduced for test stability)
    base += (_random.nextDouble() * 0.2) - 0.1;

    return base.clamp(0.0, 5.0);
  }

  static InteractionType getRandomInteraction() {
    return InteractionType.values[_random.nextInt(
      InteractionType.values.length,
    )];
  }
}
