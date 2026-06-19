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

import '../models/game_item.dart';
import '../models/npc_intent.dart';

enum TaskType {
  cleanRoom,
  collectEggs,
  deliverEggs,
  harvestCabbage,
  hunt,
  research,
  dissect,
  cook,
  transcribeNotes,
  observeExperiment,
  guardCoop,
  archiveResearch,
  greetGuest,
  rest,
  eat,
  idle,
  brew,
  distill,
  processTimber,
  harvestGrain,
  setupBrewery,
  setupDistillery,
  setupWorkshop,
  setupGranary,
  collectIngredients,
  spyOnNeighbor,
  deprivationStudy,
  clinicalTrial,
  puzzleStudy,
  vivisection,
  breedingAttempt,
  surgicalOperation,
  // New tasks from MECE refinement
  surgery,
  careForInjured,
  careForSick,
  stopBleeding,
  diagnoseIllness,
  treatIllness,
  checkBedridden,
  prepareMeals,
  butcherAnimals,
  refineFood,
  plantCrops,
  waterCrops,
  tillSoil,
  fertilizeSoil,
  careForCrops,
  harvestCrops,
  refinePlantFungus,
  hauling,
  construction,
  mining,
  strengthLabor,
  restoreRoom,
  excavate,
  blacksmithing,
  manufacturing,
  refineNonLiving,
  discardSpoiledFood,
  discardTrash,
  invention,
  refineLifeForm,
  cleanDish,
  useToilet,
  extinguishFire,
  recombineSpecimen,
  defendManor,
  trainCreature,
  surgicalCombination,
  wash, // Legacy/Generic
  washHands,
  bathe,
  readBook,
  goForWalk,
  cardio,
  weights,
  paint,
  sculpt,
  interactAnimals,
  writePoetry,
  writeNovel,
  study,
  experiment,
  operation,
  relax,
  collectPayment,
  dentalWork,
  pharmaceuticalCrafting,
  legalServices,
  clearField,
}


extension TaskTypeExtensions on TaskType {
  String get displayName {
    switch (this) {
      case TaskType.washHands:
        return 'Wash Hands';
      case TaskType.bathe:
        return 'Bathe';
      case TaskType.wash:
        return 'Wash';
      case TaskType.cleanRoom:
        return 'Clean Room';
      case TaskType.collectEggs:
        return 'Collect Eggs';
      case TaskType.deliverEggs:
        return 'Deliver Eggs';
      case TaskType.harvestCabbage:
        return 'Harvest Cabbage';
      case TaskType.hunt:
        return 'Hunt';
      case TaskType.research:
        return 'Research';
      case TaskType.dissect:
        return 'Dissect';
      case TaskType.cook:
        return 'Cook';
      case TaskType.transcribeNotes:
        return 'Transcribe';
      case TaskType.observeExperiment:
        return 'Observe Experiment';
      case TaskType.guardCoop:
        return 'Guard Coop';
      case TaskType.archiveResearch:
        return 'Archive Research';
      case TaskType.greetGuest:
        return 'Greet Guest';
      case TaskType.rest:
        return 'Rest';
      case TaskType.eat:
        return 'Eat';
      case TaskType.idle:
        return 'Idle';
      case TaskType.brew:
        return 'Brew';
      case TaskType.distill:
        return 'Distill';
      case TaskType.processTimber:
        return 'Process Timber';
      case TaskType.harvestGrain:
        return 'Harvest Grain';
      case TaskType.setupBrewery:
        return 'Setup Brewery';
      case TaskType.setupDistillery:
        return 'Setup Distillery';
      case TaskType.setupWorkshop:
        return 'Setup Workshop';
      case TaskType.setupGranary:
        return 'Setup Granary';
      case TaskType.collectIngredients:
        return 'Collect Ingredients';
      case TaskType.spyOnNeighbor:
        return 'Spy on Neighbor';
      case TaskType.deprivationStudy:
        return 'Deprivation Study';
      case TaskType.clinicalTrial:
        return 'Clinical Trial';
      case TaskType.puzzleStudy:
        return 'Puzzle Study';
      case TaskType.vivisection:
        return 'Vivisection';
      case TaskType.breedingAttempt:
        return 'Breed Attempt';
      case TaskType.surgicalOperation:
        return 'Surgical Operation';
      case TaskType.surgery:
        return 'Surgery';
      case TaskType.careForInjured:
        return 'Care For Injured';
      case TaskType.careForSick:
        return 'Care For Sick';
      case TaskType.stopBleeding:
        return 'Stop Bleeding';
      case TaskType.diagnoseIllness:
        return 'Diagnose Illness';
      case TaskType.treatIllness:
        return 'Treat Illness';
      case TaskType.checkBedridden:
        return 'Check Bedridden';
      case TaskType.prepareMeals:
        return 'Prepare Meals';
      case TaskType.butcherAnimals:
        return 'Butcher Animal';
      case TaskType.refineFood:
        return 'Refine Food';
      case TaskType.plantCrops:
        return 'Plant Crops';
      case TaskType.waterCrops:
        return 'Water Crops';
      case TaskType.tillSoil:
        return 'Till Soil';
      case TaskType.fertilizeSoil:
        return 'Fertilize Soil';
      case TaskType.careForCrops:
        return 'Care For Crops';
      case TaskType.harvestCrops:
        return 'Harvest Crops';
      case TaskType.refinePlantFungus:
        return 'Refine Plant/Fungus';
      case TaskType.hauling:
        return 'Haul';
      case TaskType.construction:
        return 'Construct';
      case TaskType.mining:
        return 'Mine';
      case TaskType.strengthLabor:
        return 'Heavy Labor';
      case TaskType.restoreRoom:
        return 'Restore Room';
      case TaskType.excavate:
        return 'Excavate Room';
      case TaskType.blacksmithing:
        return 'Blacksmith';
      case TaskType.manufacturing:
        return 'Manufacture';
      case TaskType.refineNonLiving:
        return 'Refining Non-Living';
      case TaskType.discardSpoiledFood:
        return 'Discard Spoiled Food';
      case TaskType.discardTrash:
        return 'Discard Trash';
      case TaskType.invention:
        return 'Invent';
      case TaskType.refineLifeForm:
        return 'Refine Life Form';
      case TaskType.cleanDish:
        return 'Clean Dish';
      case TaskType.useToilet:
        return 'Use Washroom';
      case TaskType.extinguishFire:
        return 'Extinguish Fire';
      case TaskType.recombineSpecimen:
        return 'Recombine Specimen';
      case TaskType.defendManor:
        return 'Defend Manor';
      case TaskType.trainCreature:
        return 'Train Creature';
      case TaskType.surgicalCombination:
        return 'Surgical Combination';
      case TaskType.study:
        return 'Fundamental Research';
      case TaskType.readBook:
        return 'Reading';
      case TaskType.goForWalk:
        return 'Taking a Walk';
      case TaskType.cardio:
        return 'Cardio';
      case TaskType.weights:
        return 'Lifting Weights';
      case TaskType.paint:
        return 'Painting';
      case TaskType.sculpt:
        return 'Sculpting';
      case TaskType.interactAnimals:
        return 'Spending Time with Animals';
      case TaskType.writePoetry:
        return 'Writing Poetry';
      case TaskType.writeNovel:
        return 'Writing a Novel';
      case TaskType.experiment:
        return 'Experiment';
      case TaskType.operation:
        return 'Operation';
      case TaskType.relax:
        return 'Relax';
      case TaskType.collectPayment:
        return 'Collect Wages';
      case TaskType.dentalWork:
        return 'Dental Work';
      case TaskType.pharmaceuticalCrafting:
        return 'Pharmaceutical Crafting';
      case TaskType.legalServices:
        return 'Legal Services';
      case TaskType.clearField:
        return 'Clear Field';
    }
  }
}

class TaskResult {
  final String message;
  final Map<String, num> resourcesGained; // {'wood': 2, 'eggs': 4}
  final List<GameItem> itemsFound;
  final double quality; // 0.0 to 2.0 (standard 1.0)

  TaskResult({
    required this.message,
    this.resourcesGained = const {},
    this.itemsFound = const [],
    this.quality = 1.0,
  });
}

class GameTask {
  final String id;
  final String? intentId; // Links back to the AI intent that created this task
  final String npcId;
  final IntentPriority priority;
  final TaskType type;
  final String? targetId; // roomId, etc.
  final String? targetName;
  final String? recipeId;
  final List<String> reservedEntityIds;
  double progressAccumulator = 0.0;
  final int totalMinutes;
  int minutesRemaining;
  bool isCompleted;

  GameTask({
    required this.id,
    this.intentId,
    required this.npcId,
    required this.priority,
    required this.type,
    this.targetId,
    this.targetName,
    this.recipeId,
    this.reservedEntityIds = const [],
    required this.minutesRemaining,
    this.totalMinutes = 0,
    this.isCompleted = false,
  });
}

class TaskMetadata {
  final String explanation;
  final String typicalDuration;
  final List<String> relevantAttributes;
  final List<String> possibleOutcomes;
  final Map<String, num> requirements;

  const TaskMetadata({
    required this.explanation,
    required this.typicalDuration,
    required this.relevantAttributes,
    required this.possibleOutcomes,
    this.requirements = const {},
  });
}

class TaskService {
  final List<GameTask> _activeTasks = [];

  List<GameTask> get activeTasks => List.unmodifiable(_activeTasks);

  static bool isConcurrent(TaskType type) {
    return type == TaskType.restoreRoom ||
        type == TaskType.excavate ||
        type == TaskType.construction ||
        type == TaskType.tillSoil ||
        type == TaskType.fertilizeSoil ||
        type == TaskType.waterCrops ||
        type == TaskType.careForCrops ||
        type == TaskType.harvestCrops ||
        type == TaskType.rest ||
        type == TaskType.eat;
  }

  static String? getResolvedCookingProficiency(TaskType type, String? recipeId) {
    if (type == TaskType.brew) return 'Brewing';
    if (type == TaskType.distill) return 'Distilling';
    if (type != TaskType.cook && type != TaskType.prepareMeals && type != TaskType.refineFood) {
      return getProficiency(type);
    }
    
    if (recipeId == null) return 'Cooking';
    
    final rId = recipeId.toLowerCase();
    final bakingIds = [
      'staple_bread', 'hard_hardtack', 'croissant', 'butter_croissant', 
      'brioche_bun', 'glazed_fruit_tart', 'sweet_pastry_twist', 'tea_scones', 
      'apple_strudel', 'pain_au_chocolat', 'pizza_margherita', 'lasagna_al_forno', 
      'lasagna', 'ravioli', 'tortellini', 'shepherds_pie', 'bread_dough', 
      'sweet_pastry_dough', 'pizza_dough', 'cacio_e_pepe', 'spaghetti_gricia',
      'spaghetti_amatriciana', 'classic_tiramisu'
    ];
    final grillingIds = [
      'fried_generic_meat', 'roasted_rat', 'seared_beef', 'gourmet_cheeseburger', 
      'roasted_carrots', 'roasted_squash', 'baked_apple', 'simple_pears'
    ];
    final brewingIds = [
      'wort', 'beer', 'wine', 'cider', 'mash', 'spiced_warm_cider'
    ];
    final distillingIds = [
      'whiskey', 'brandy', 'applejack', 'vodka', 'gin', 'absinthe', 'greek_fire'
    ];
    
    if (bakingIds.contains(rId)) return 'Baking';
    if (grillingIds.contains(rId)) return 'Grilling';
    if (brewingIds.contains(rId)) return 'Brewing';
    if (distillingIds.contains(rId)) return 'Distilling';
    
    return 'Cooking';
  }

  static String? getProficiency(TaskType type) {
    switch (type) {
      case TaskType.prepareMeals:
      case TaskType.cook:
      case TaskType.refineFood:
        return 'Cooking';
      case TaskType.butcherAnimals:
      case TaskType.hunt:
        return 'Hunting';
      case TaskType.plantCrops:
      case TaskType.waterCrops:
      case TaskType.tillSoil:
      case TaskType.fertilizeSoil:
      case TaskType.careForCrops:
      case TaskType.harvestCrops:
      case TaskType.harvestCabbage:
      case TaskType.harvestGrain:
      case TaskType.clearField:
        return 'Farming';
      case TaskType.surgery:
      case TaskType.surgicalOperation:
      case TaskType.surgicalCombination:
      case TaskType.vivisection:
      case TaskType.dissect:
      case TaskType.operation:
        return 'Surgery';
      case TaskType.cleanRoom:
      case TaskType.cleanDish:
      case TaskType.discardTrash:
      case TaskType.discardSpoiledFood:
        return 'Cleaning';
      case TaskType.construction:
      case TaskType.restoreRoom:
      case TaskType.setupWorkshop:
      case TaskType.setupBrewery:
      case TaskType.setupDistillery:
      case TaskType.setupGranary:
        return 'Construction';
      case TaskType.brew:
      case TaskType.distill:
        return 'Brewing';
      case TaskType.research:
      case TaskType.study:
      case TaskType.archiveResearch:
      case TaskType.transcribeNotes:
      case TaskType.deprivationStudy:
      case TaskType.puzzleStudy:
      case TaskType.observeExperiment:
      case TaskType.experiment:
        return 'Research';
      case TaskType.careForInjured:
      case TaskType.careForSick:
      case TaskType.stopBleeding:
      case TaskType.diagnoseIllness:
      case TaskType.treatIllness:
      case TaskType.checkBedridden:
      case TaskType.clinicalTrial:
      case TaskType.dentalWork:
      case TaskType.pharmaceuticalCrafting:
        return 'Medicine';
      case TaskType.legalServices:
        return 'Accounting';
      case TaskType.paint:
        return 'Painting';
      case TaskType.writeNovel:
      case TaskType.writePoetry:
        return 'Writing';
      case TaskType.sculpt:
        return 'Sculpture';
      case TaskType.collectEggs:
      case TaskType.deliverEggs:
      case TaskType.interactAnimals:
      case TaskType.guardCoop:
      case TaskType.breedingAttempt:
        return 'Ranching';
      case TaskType.mining:
      case TaskType.excavate:
        return 'Mining';
      case TaskType.invention:
      case TaskType.manufacturing:
      case TaskType.blacksmithing:
      case TaskType.processTimber:
        return 'Manufacturing';
      case TaskType.refineNonLiving:
      case TaskType.refineLifeForm:
      case TaskType.refinePlantFungus:
      case TaskType.recombineSpecimen:
        return 'Chemistry';
      case TaskType.trainCreature:
        return 'Therapy';
      default:
        return null;
    }
  }

  static bool isPhysicallyStrenuous(TaskType type) {
    switch (type) {
      case TaskType.mining:
      case TaskType.excavate:
      case TaskType.construction:
      case TaskType.restoreRoom:
      case TaskType.strengthLabor:
      case TaskType.processTimber:
      case TaskType.tillSoil:
      case TaskType.harvestCrops:
      case TaskType.harvestGrain:
      case TaskType.setupBrewery:
      case TaskType.setupDistillery:
      case TaskType.setupGranary:
      case TaskType.setupWorkshop:
      case TaskType.hauling:
      case TaskType.blacksmithing:
      case TaskType.guardCoop:
      case TaskType.defendManor:
        return true;
      default:
        return false;
    }
  }

  static TaskMetadata getMetadata(TaskType type) {
    switch (type) {
      case TaskType.cleanRoom:
      case TaskType.cleanDish:
      case TaskType.discardTrash:
      case TaskType.discardSpoiledFood:
        return const TaskMetadata(
          explanation: "Systematically removing dust and grime from the manor.",
          typicalDuration: "20-40 Minutes",
          relevantAttributes: ['endurance', 'hygiene', 'temperament'],
          possibleOutcomes: [
            "Clean surfaces",
            "Improved hygiene",
            "Better morale",
          ],
        );
      case TaskType.research:
      case TaskType.study:
      case TaskType.archiveResearch:
        return const TaskMetadata(
          explanation:
              "Synthesize insights from your collection. Advances a scientific discipline or deepens understanding.",
          typicalDuration: "4-8 Hours",
          relevantAttributes: ['intellect', 'judgment', 'perception'],
          possibleOutcomes: [
            "Increased Knowledge points",
            "Science level advances",
            "Mental exhaustion",
          ],
        );
      case TaskType.transcribeNotes:
        return const TaskMetadata(
          explanation:
              "Formal Transcription: Convert raw, messy research notes into structured studies, increasing their scientific value by 20%.",
          typicalDuration: "3-5 Hours",
          relevantAttributes: ['intellect', 'dexterity', 'perception'],
          possibleOutcomes: [
            "High-quality research studies",
            "Improved data clarity",
          ],
        );
      case TaskType.readBook:
        return const TaskMetadata(
          explanation: "Read a book to gain satisfaction and potentially uncover random research insights.",
          typicalDuration: "1-2 Hours",
          relevantAttributes: ['intellect'],
          possibleOutcomes: ["Satisfaction increase", "Random research pages"],
        );
      case TaskType.goForWalk:
        return const TaskMetadata(
          explanation: "Take a walk to clear the mind and improve health.",
          typicalDuration: "1 Hour",
          relevantAttributes: ['judgment'],
          possibleOutcomes: ["Satisfaction increase", "Health increase"],
        );
      case TaskType.cardio:
        return const TaskMetadata(
          explanation: "Perform cardiovascular exercises to build endurance.",
          typicalDuration: "1 Hour",
          relevantAttributes: ['beauty'],
          possibleOutcomes: ["Satisfaction increase", "Endurance increase"],
        );
      case TaskType.weights:
        return const TaskMetadata(
          explanation: "Lift heavy objects to build raw strength.",
          typicalDuration: "1 Hour",
          relevantAttributes: ['endurance'],
          possibleOutcomes: ["Satisfaction increase", "Strength increase"],
        );
      case TaskType.paint:
        return const TaskMetadata(
          explanation: "Work on painting a canvas.",
          typicalDuration: "Multi-day (6 hours total)",
          relevantAttributes: ['dexterity'],
          possibleOutcomes: ["Completed Painting item"],
        );
      case TaskType.sculpt:
        return const TaskMetadata(
          explanation: "Work on carving or molding a sculpture.",
          typicalDuration: "Multi-day (12 hours total)",
          relevantAttributes: ['confidence'],
          possibleOutcomes: ["Completed Sculpture item"],
        );
      case TaskType.interactAnimals:
        return const TaskMetadata(
          explanation: "Spend time socializing with the animals.",
          typicalDuration: "1 Hour",
          relevantAttributes: ['temperament'],
          possibleOutcomes: ["Satisfaction increase", "Zoology research pages"],
        );
      case TaskType.writePoetry:
        return const TaskMetadata(
          explanation: "Draft emotional poetry.",
          typicalDuration: "Multi-day (2 hours total)",
          relevantAttributes: ['strength'],
          possibleOutcomes: ["Completed Poem item"],
        );
      case TaskType.writeNovel:
        return const TaskMetadata(
          explanation: "Write an extensive novel.",
          typicalDuration: "Multi-day (12 hours total)",
          relevantAttributes: ['perception'],
          possibleOutcomes: ["Completed Novel item"],
        );
      case TaskType.observeExperiment:
      case TaskType.experiment:
        return const TaskMetadata(
          explanation: "Advanced scientific procedures to understand and manipulate biology.",
          typicalDuration: "4-12 Hours",
          relevantAttributes: ['dexterity', 'judgment', 'intellect'],
          possibleOutcomes: [
            "Biological insights",
            "High quality specimens",
            "Ethical decay",
          ],
        );
      case TaskType.cook:
        return const TaskMetadata(
          explanation: "Preparing nourishing meals in the manor kitchen.",
          typicalDuration: "45-75 Minutes",
          relevantAttributes: [
            'dexterity',
            'intellect',
            'perception',
          ],
          possibleOutcomes: [
            "High-quality food",
            "Culinary experience",
            "Burned meal",
          ],
        );
      case TaskType.prepareMeals:
      case TaskType.refineFood:
      case TaskType.butcherAnimals:
        return const TaskMetadata(
          explanation: "Converting raw ingredients into nourishing sustenence.",
          typicalDuration: "45-90 Minutes",
          relevantAttributes: [
            'hygiene',
            'perception',
            'dexterity',
            'intellect',
          ],
          possibleOutcomes: [
            "High-quality food",
            "Improved health",
            "Culinary skill",
          ],
        );
      case TaskType.dissect:
      case TaskType.vivisection:
      case TaskType.surgicalOperation:
      case TaskType.operation:
      case TaskType.surgery:
      case TaskType.surgicalCombination:
        return const TaskMetadata(
          explanation: "Complex medical or life-science procedures involving anatomical manipulation.",
          typicalDuration: "4-12 Hours",
          relevantAttributes: ['dexterity', 'judgment', 'intellect'],
          possibleOutcomes: [
            "Anatomical data",
            "Biological specimens",
            "Surgical skill",
            "Ethical decay",
          ],
        );
      case TaskType.clinicalTrial:
      case TaskType.puzzleStudy:
      case TaskType.deprivationStudy:
        return const TaskMetadata(
          explanation:
              "Observing the long-term effects of controlled experimental conditions on a subject.",
          typicalDuration: "16-120 Hours",
          relevantAttributes: ['intellect', 'perception', 'judgment'],
          possibleOutcomes: [
            "Experimental data",
            "Scientific breakthroughs",
            "Subject mortality",
          ],
        );
      case TaskType.plantCrops:
      case TaskType.waterCrops:
      case TaskType.tillSoil:
      case TaskType.fertilizeSoil:
      case TaskType.careForCrops:
      case TaskType.harvestCrops:
      case TaskType.harvestCabbage:
      case TaskType.harvestGrain:
        return const TaskMetadata(
          explanation: "Performing essential agricultural labor on the manor's fields to ensure survival.",
          typicalDuration: "4 Hours",
          relevantAttributes: ['strength', 'endurance', 'temperament'],
          possibleOutcomes: ["Food resources", "Seeds", "Physical exhaustion"],
        );
      case TaskType.invention:
      case TaskType.blacksmithing:
      case TaskType.manufacturing:
      case TaskType.processTimber:
        return const TaskMetadata(
          explanation: "Fabricating tools and structural components.",
          typicalDuration: "8-24 Hours",
          relevantAttributes: ['intellect', 'dexterity', 'judgment'],
          possibleOutcomes: [
            "Manor upgrades",
            "New apparatus",
            "Industrial progress",
          ],
        );
      case TaskType.hunt:
        return const TaskMetadata(
          explanation: "Securing fresh protein from the estate grounds.",
          typicalDuration: "4-8 Hours",
          relevantAttributes: ['dexterity', 'perception', 'endurance'],
          possibleOutcomes: ["Meat", "Hides", "Practical experience"],
        );
      case TaskType.guardCoop:
      case TaskType.defendManor:
        return const TaskMetadata(
          explanation: "Maintaining vigilance against external threats.",
          typicalDuration: "8-12 Hours",
          relevantAttributes: ['perception', 'endurance', 'temperament'],
          possibleOutcomes: ["Security", "Resident safety", "Deterrence"],
        );
      case TaskType.brew:
      case TaskType.distill:
        return const TaskMetadata(
          explanation: "The refined art of crafting ales and spirits.",
          typicalDuration: "4-6 Hours",
          relevantAttributes: ['intellect', 'perception', 'dexterity'],
          possibleOutcomes: ["Beverages", "Social morale", "Trade goods"],
        );
      case TaskType.restoreRoom:
        return const TaskMetadata(
          explanation:
              "Renovating a section of the manor to functional status.",
          typicalDuration: "4 Hours",
          relevantAttributes: ['strength', 'endurance', 'dexterity'],
          possibleOutcomes: ["New room access", "Structural integrity"],
        );
      case TaskType.excavate:
        return const TaskMetadata(
          explanation: "Removing tons of stone and earth to hollow out an underground chamber.",
          typicalDuration: "20+ Hours",
          relevantAttributes: ['strength', 'endurance'],
          possibleOutcomes: ["A new subterranean vault is secured."],
          requirements: {'funds': 2000, 'wood': 500},
        );
      case TaskType.setupBrewery:
        return const TaskMetadata(
          explanation:
              "Installing massive copper mash tuns and fermentation vats.",
          typicalDuration: "6-12 Hours",
          relevantAttributes: ['strength', 'endurance', 'dexterity'],
          possibleOutcomes: ["Functional Brewery", "Industrial expansion"],
          requirements: {'funds': 20, 'wood': 15, 'timber': 5},
        );
      case TaskType.setupDistillery:
        return const TaskMetadata(
          explanation:
              "Calibrating a precision spirit still and condenser coils.",
          typicalDuration: "8-16 Hours",
          relevantAttributes: ['intellect', 'perception', 'dexterity'],
          possibleOutcomes: ["Functional Distillery", "Advanced industry"],
          requirements: {'funds': 30, 'wood': 10, 'timber': 10, 'spirits': 1},
        );
      case TaskType.setupWorkshop:
        return const TaskMetadata(
          explanation:
              "Organizing tools and machinery for advanced manufacturing.",
          typicalDuration: "4-8 Hours",
          relevantAttributes: ['dexterity', 'strength', 'intellect'],
          possibleOutcomes: ["Functional Workshop", "Manufacturing hub"],
          requirements: {'funds': 15, 'wood': 20, 'timber': 5},
        );
      case TaskType.setupGranary:
        return const TaskMetadata(
          explanation:
              "Establishing reinforced storage for large-scale harvests.",
          typicalDuration: "6-10 Hours",
          relevantAttributes: ['strength', 'endurance', 'intellect'],
          possibleOutcomes: ["Functional Granary", "Food security"],
          requirements: {'funds': 10, 'wood': 15, 'timber': 10},
        );
      case TaskType.useToilet:
        return const TaskMetadata(
          explanation: "Using the washroom.",
          typicalDuration: "10-20 Minutes",
          relevantAttributes: [],
          possibleOutcomes: ["Emptied bowels"],
        );
      case TaskType.wash:
      case TaskType.washHands:
      case TaskType.bathe:
        return const TaskMetadata(
          explanation: "Personal maintenance and hygiene.",
          typicalDuration: "10-20 Minutes",
          relevantAttributes: ['hygiene'],
          possibleOutcomes: ["Improved hygiene", "Mental clarity"],
        );
      case TaskType.eat:
        return const TaskMetadata(
          explanation: "Restoring energy and fullness through nourishing meals.",
          typicalDuration: "30-45 Minutes",
          relevantAttributes: [],
          possibleOutcomes: ["Restored fullness", "Better morale"],
        );
      case TaskType.relax:
        return const TaskMetadata(
          explanation: "Taking a moment to breathe and clear one's mind.",
          typicalDuration: "30-60 Minutes",
          relevantAttributes: ['temperament'],
          possibleOutcomes: ["Restored focus", "Improved morale"],
        );
      case TaskType.collectPayment:
        return const TaskMetadata(
          explanation: "Collecting daily wages from the Master of the Manor.",
          typicalDuration: "2 Minutes",
          relevantAttributes: [],
          possibleOutcomes: ["Received salary", "Reduced funds"],
        );
      case TaskType.clearField:
        return const TaskMetadata(
          explanation: "Clear dead crops from the field to prepare the soil for replanting.",
          typicalDuration: "40-60 Minutes",
          relevantAttributes: ['endurance', 'temperament'],
          possibleOutcomes: ["Fallow field ready for tilling", "Clean field"],
        );
      // Fallback for others
      default:
        return const TaskMetadata(
          explanation: "A standard manor duty requiring attention and effort.",
          typicalDuration: "2-4 Hours",
          relevantAttributes: [],
          possibleOutcomes: ["Completion", "Experience gain"],
        );
    }
  }

  static List<String> getRelevantAttributes(TaskType type) {
    return getMetadata(type).relevantAttributes;
  }

  void addTask(GameTask task) {
    // DUPLICATE GUARD: Strictly reject if this task ID is already tracked.
    if (_activeTasks.any((t) => t.id == task.id)) return;
    _activeTasks.add(task);
  }

  void removeTask(String taskId) {
    _activeTasks.removeWhere((t) => t.id == taskId);
  }

  void cancelTask(String taskId) {
    _activeTasks.removeWhere((t) => t.id == taskId);
  }
  void assignTask({
    required String npcId,
    required TaskType type,
    String? targetId,
    String? recipeId,
    String? intentId,
    IntentPriority priority = IntentPriority.normal,
    required int durationMinutes,
    List<String> reservedEntityIds = const [],
  }) {
    // Generate simulation-safe, unique task ID
    final taskId = "task_${npcId}_${DateTime.now().microsecondsSinceEpoch}_${type.name}";

    _activeTasks.add(
      GameTask(
        id: taskId,
        intentId: intentId,
        npcId: npcId,
        priority: priority,
        type: type,
        targetId: targetId,
        recipeId: recipeId,
        reservedEntityIds: reservedEntityIds,
        minutesRemaining: durationMinutes,
        totalMinutes: durationMinutes,
      ),
    );
  }

  List<GameTask> processTick(
    List<String> readyNpcIds,
    Set<String> activeTaskIds,
    Map<String, int> Function(String) getStats,
  ) {
    final completed = <GameTask>[];
    for (var task in _activeTasks) {
      if (!task.isCompleted &&
          readyNpcIds.contains(task.npcId) &&
          activeTaskIds.contains(task.id)) {
        // Task duration is already adjusted for character efficiency and role when created in GameState.
        // Decrement exactly 1 task minute for every 1 game minute to keep task speed perfectly synchronized with game clock speed.
        task.minutesRemaining--;
        if (task.minutesRemaining <= 0) {
          task.isCompleted = true;
          completed.add(task);
        }
      }
    }
    _activeTasks.removeWhere((task) => task.isCompleted);
    return completed;
  }

  String getTaskDescription(GameTask task) {
    switch (task.type) {
      case TaskType.cleanRoom:
        return "Clean room";
      case TaskType.collectEggs:
        return "Collect eggs";
      case TaskType.deliverEggs:
        return "Deliver eggs";
      case TaskType.harvestCabbage:
        return "Harvest cabbage";
      case TaskType.hunt:
        return "Hunt";
      case TaskType.research:
        return "Research";
      case TaskType.dissect:
        return "Dissect";
      case TaskType.transcribeNotes:
        return "Transcribe notes";
      case TaskType.observeExperiment:
        return "Observe experiment";
      case TaskType.cook:
        return task.recipeId != null
            ? "Cook ${task.recipeId!.replaceAll('_', ' ')}"
            : "Cook";
      case TaskType.guardCoop:
        return "Guard chicken coop";
      case TaskType.archiveResearch:
        return "Archive forbidden lore";
      case TaskType.greetGuest:
        return "Greet a guest";
      case TaskType.rest:
        return "Rest";
      case TaskType.eat:
        return "Eat";
      case TaskType.idle:
        return "Stay at post";
      case TaskType.brew:
        return "Brew ale";
      case TaskType.distill:
        return "Distill spirits";
      case TaskType.processTimber:
        return "Process timber";
      case TaskType.harvestGrain:
        return "Harvest grain";
      case TaskType.setupBrewery:
        return "Setup brewery equipment";
      case TaskType.setupDistillery:
        return "Calibrate distillery still";
      case TaskType.setupWorkshop:
        return "Organize carpenter's workshop";
      case TaskType.setupGranary:
        return "Prepare granary storage";
      case TaskType.collectIngredients:
        return "Collect supplies";
      case TaskType.spyOnNeighbor:
        return "Spy on neighbor";
      case TaskType.deprivationStudy:
        return "Perform Deprivation Study";
      case TaskType.clinicalTrial:
        return "Administer clinical trials";
      case TaskType.puzzleStudy:
        return "Conduct cognitive puzzle study";
      case TaskType.vivisection:
        return "Perform vivisection procedure";
      case TaskType.breedingAttempt:
        return "Manage breeding attempt";
      case TaskType.surgicalOperation:
        return "Perform surgical operation";
      case TaskType.surgery:
        return "Perform delicate surgery";
      case TaskType.careForInjured:
        return "Care for the injured";
      case TaskType.careForSick:
        return "Tend to the sick";
      case TaskType.stopBleeding:
        return "Stop blood loss";
      case TaskType.diagnoseIllness:
        return "Diagnose a strange illness";
      case TaskType.treatIllness:
        return "Treat a persistent illness";
      case TaskType.checkBedridden:
        return "Check on the bed-ridden";
      case TaskType.prepareMeals:
        return "Prepare a hearty meal";
      case TaskType.butcherAnimals:
        return "Butcher animals for meat";
      case TaskType.refineFood:
        return "Refine ingredients into delicacies";
      case TaskType.plantCrops:
        return "Sow seedlings in the soil";
      case TaskType.waterCrops:
        return "Water thirsty crops";
      case TaskType.tillSoil:
        return "Till the field";
      case TaskType.fertilizeSoil:
        return "Fertilize the field";
      case TaskType.careForCrops:
        return "Tend to growing crops";
      case TaskType.harvestCrops:
        return "Harvest agricultural yield";
      case TaskType.refinePlantFungus:
        return "Refine horticultural specimens";
      case TaskType.hauling:
        return "Haul heavy goods";
      case TaskType.construction:
        return "Work on construction";
      case TaskType.mining:
        return "Mine for minerals";
      case TaskType.strengthLabor:
        return "Perform arduous labor";
      case TaskType.restoreRoom:
        return "Restore a dilapidated room";
      case TaskType.excavate:
        return "Excavate subterranean node";
      case TaskType.blacksmithing:
        return "Toil at the forge";
      case TaskType.manufacturing:
        return "Manufacture goods";
      case TaskType.refineNonLiving:
        return "Refine non-living materials";
      case TaskType.discardSpoiledFood:
        return "Discard spoiled provisions";
      case TaskType.discardTrash:
        return "Clear out accumulated trash";
      case TaskType.invention:
        return "Work on a new invention";
      case TaskType.refineLifeForm:
        return "Refine biological specimens";
      case TaskType.cleanDish:
        return "Clean a dirty dish";
      case TaskType.useToilet:
        return "Use the toilet";
      case TaskType.washHands:
        return "Wash hands";
      case TaskType.bathe:
        return "Take a bath";
      case TaskType.wash:
        return "Wash up";
      case TaskType.extinguishFire:
        return "Fight a blaze";
      case TaskType.recombineSpecimen:
        return "Contain a loose specimen";
      case TaskType.defendManor:
        return "Defend the manor from intruders";
      case TaskType.trainCreature:
        return "Train a creature for combat";
      case TaskType.surgicalCombination:
        return "Combine specimens via specialized surgery";
      case TaskType.study:
        return "Study";
      case TaskType.readBook:
        return "Read a book for satisfaction and potential knowledge";
      case TaskType.goForWalk:
        return "Take a refreshing walk to clear the mind";
      case TaskType.cardio:
        return "Perform cardiovascular exercise";
      case TaskType.weights:
        return "Lift weights to build strength";
      case TaskType.paint:
        return "Paint on a canvas";
      case TaskType.sculpt:
        return "Work on a sculpture";
      case TaskType.interactAnimals:
        return "Spend time interacting with animals";
      case TaskType.writePoetry:
        return "Draft poetry";
      case TaskType.writeNovel:
        return "Write a novel";
      case TaskType.experiment:
        return "Experiment";
      case TaskType.operation:
        return "Perform operation";
      case TaskType.relax:
        return "Relax and restore focus";
      case TaskType.collectPayment:
        return "Collect wages from the Study";
      case TaskType.dentalWork:
        return "Perform dental work";
      case TaskType.pharmaceuticalCrafting:
        return "Craft pharmaceuticals and reagents";
      case TaskType.legalServices:
        return "Perform legal services and draft contracts";
      case TaskType.clearField:
        return "Clear dead crops from the field";
    }
  }
}
