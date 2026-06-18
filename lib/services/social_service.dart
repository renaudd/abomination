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
    Relationship actorToTarget = getRelationshipBetween(actor, target);
    Relationship targetToActor = getRelationshipBetween(target, actor);

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

    actorToTarget = evolveRelationshipStage(actorToTarget);
    targetToActor = evolveRelationshipStage(targetToActor);

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

  static Relationship evolveRelationshipStage(Relationship rel, {bool didGiveGift = false}) {
    RelationshipStage current = rel.stage;
    RelationshipStage next = current;

    final attraction = rel.attraction;
    final admiration = rel.admiration;
    final respect = rel.respect;

    switch (current) {
      case RelationshipStage.acquaintance:
        if (didGiveGift || attraction > 2.8 || admiration > 3.0) {
          next = RelationshipStage.intrigue;
        }
        break;
      case RelationshipStage.intrigue:
        if (attraction > 3.5) {
          if (respect < 2.0) {
            next = RelationshipStage.volatileDevotion;
          } else if (admiration > 3.5) {
            next = RelationshipStage.devotion;
          }
        }
        break;
      case RelationshipStage.devotion:
        break;
      case RelationshipStage.volatileDevotion:
        break;
      case RelationshipStage.cohabitation:
      case RelationshipStage.coercedCohabitation:
      case RelationshipStage.marriage:
        break;
    }

    return rel.copyWith(stage: next);
  }

  static Relationship getRelationshipBetween(NPC actor, NPC target) {
    final existing = actor.relationships[target.id];
    if (existing != null) return existing;
    return Relationship(
      attraction: calculateInitialAttraction(actor, target),
      admiration: calculateInitialAdmiration(actor, target),
      fear: calculateInitialFear(actor, target),
      respect: calculateInitialRespect(actor, target),
    );
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

    int beauty = target.stats['beauty'] ?? 5;
    int vitality = target.stats['vitality'] ?? 5;

    base += (beauty / 10.0) * 1.5;
    base += (vitality / 10.0) * 0.2;

    // 3. Age Factor
    double ageScore = 1.0;
    if (observer.gender.toLowerCase() == 'male') {
      int distFrom20 = (target.age - 20).abs();
      ageScore = (1.0 - (distFrom20 / 40.0)).clamp(0.0, 1.0);
    } else {
      int distFrom40 = (target.age - 40).abs();
      ageScore = (1.0 - (distFrom40 / 40.0)).clamp(0.0, 1.0);
    }
    base += ageScore * 0.8;

    // 4. Physical Condition & Medical Fetish Check
    int missingParts = target.bodyParts.where((bp) => !bp.isAttached).length;
    final bool hasMedicalFetish = observer.traits.any((t) => t.id == 'medical_fetish');
    if (hasMedicalFetish) {
      base += missingParts * 0.4; // Attraction to physical anomalies/golems
    } else {
      base -= missingParts * 0.25;
    }

    // 5. Observer Personality Prefs (Sapiosexual, Confidence-Seeker, Well-Mannered, Free-Spirit, Dark Attraction)
    if (observer.traits.any((t) => t.id == 'sapiosexual')) {
      final tIntellect = target.stats['intellect'] ?? 5;
      final tJudgment = target.stats['judgment'] ?? 5;
      base += (tIntellect / 10.0) * 2.0 + (tJudgment / 10.0) * 1.0;
    }
    if (observer.traits.any((t) => t.id == 'confidence_seeker')) {
      final tConfidence = target.stats['confidence'] ?? 5;
      base += (tConfidence / 10.0) * 3.0;
    }
    if (observer.traits.any((t) => t.id == 'well_mannered_pref')) {
      final tTemperament = target.stats['temperament'] ?? 5;
      base += (tTemperament / 10.0) * 3.0;
    }
    if (observer.traits.any((t) => t.id == 'free_spirit_pref')) {
      final tJudgment = target.stats['judgment'] ?? 5;
      base += (1.0 - (tJudgment / 10.0)) * 3.0;
    }
    if (observer.traits.any((t) => t.id == 'dark_attraction')) {
      // Inherent Fear of target directly boosts attraction
      final initialFear = calculateInitialFear(observer, target);
      base += (initialFear / 5.0) * 3.0;
    }

    // 6. Random Variance
    base += (_random.nextDouble() * 0.2) - 0.1;

    return base.clamp(0.0, 5.0);
  }

  static double calculateInitialAdmiration(NPC observer, NPC target) {
    double base = 2.5;

    // Class Standing
    final oClass = observer.biography?.characterClass ?? observer.background;
    final tClass = target.biography?.characterClass ?? target.background;
    if (oClass == tClass && oClass != null) {
      base += 0.5;
    } else if (oClass == 'Noble' && tClass == 'Peasant') {
      base -= 1.0;
    } else if (oClass == 'Peasant' && tClass == 'Noble') {
      base -= 0.5;
    }

    // Association / Faction Identity
    final oAssocs = observer.traits.where((t) => t.group == 'association').map((t) => t.id).toSet();
    final tAssocs = target.traits.where((t) => t.group == 'association').map((t) => t.id).toSet();

    if (oAssocs.intersection(tAssocs).isNotEmpty) {
      base += 1.0;
    }
    if ((oAssocs.contains('communist') && tAssocs.contains('conservative')) ||
        (oAssocs.contains('conservative') && tAssocs.contains('communist'))) {
      base -= 1.5;
    }
    if ((oAssocs.contains('liberal') && tAssocs.contains('conservative')) ||
        (oAssocs.contains('conservative') && tAssocs.contains('liberal'))) {
      base -= 0.8;
    }

    return base.clamp(0.0, 5.0);
  }

  static double calculateInitialFear(NPC observer, NPC target) {
    double fearVal = 2.5;

    final oStr = observer.stats['strength'] ?? 5;
    final oEnd = observer.stats['endurance'] ?? 5;
    final oMor = observer.stats['morality'] ?? 5;
    final oBty = observer.stats['beauty'] ?? 5;

    final tStr = target.stats['strength'] ?? 5;
    final tMor = target.stats['morality'] ?? 5;
    final tBty = target.stats['beauty'] ?? 5;
    final tInt = target.stats['intellect'] ?? 5;
    final tTem = target.stats['temperament'] ?? 5;

    double increase = 0.0;

    // 1. Fear of the Grotesque
    final bool isSensitive = observer.traits.any((t) => t.id == 'sensitive' || t.id == 'artistic');
    if ((isSensitive || oBty > 7) && tBty < 3) {
      increase += (3 - tBty) * 0.5;
    }

    // 2. Fear of the Intimidating (Physical Asymmetry)
    if (oStr < 4 || oEnd < 4) {
      if (tStr > 7) {
        increase += (tStr - oStr) * 0.25;
      }
    }

    // 3. Fear of the Depraved
    if (oMor > 7 && tMor < 3) {
      increase += (oMor - tMor) * 0.25;
    }

    // Low Temperament Multiplier
    if (tTem < 4) {
      increase *= 1.5;
    }

    // Cold Scheming (High Intellect + Low Morality)
    if (tInt > 7 && tMor < 3) {
      increase += 1.0;
    }

    fearVal += increase;
    return fearVal.clamp(0.0, 5.0);
  }

  static double calculateInitialRespect(NPC observer, NPC target) {
    double respectVal = 2.5;

    final oMor = observer.stats['morality'] ?? 5;
    final tJud = target.stats['judgment'] ?? 5;

    if (tJud > 7) respectVal += 0.5;
    if (oMor > 7) respectVal += 0.5;
    if (oMor < 3) respectVal -= 0.5;

    return respectVal.clamp(0.0, 5.0);
  }

  static InteractionType getRandomInteraction() {
    return InteractionType.values[_random.nextInt(
      InteractionType.values.length,
    )];
  }
}
