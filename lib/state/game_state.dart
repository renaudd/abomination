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

import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'dart:math';
import 'dart:collection';
import 'package:uuid/uuid.dart';

import '../models/manor_crisis.dart';
import '../models/npc.dart';
import '../models/plant.dart';
import '../models/room.dart';
import '../models/schedule.dart';
import '../models/npc_intent.dart';
import '../models/game_item.dart';
import '../models/crop.dart';
import '../models/game_date.dart';
import '../models/experiment.dart';
import '../models/responsibility.dart';
import '../models/body_part.dart';
import '../models/chicken.dart';
import '../models/discovery.dart';
import '../models/dish.dart';
import '../models/fox.dart';
import '../models/objective.dart';
import '../models/relationship.dart';
import '../models/status_effect.dart';
import '../models/diet.dart';
import '../models/combat_stats.dart';
import '../models/combat_map.dart';
import '../models/contract.dart';
import '../models/manor_venture.dart';
import '../models/active_business.dart';
import '../models/graduate_school_state.dart';
import '../models/visitor_quest.dart';

import '../services/task_service.dart';
import '../services/social_service.dart';
import '../data/leisure_books_library.dart';
import '../services/kitchen_service.dart';
import '../services/science_service.dart';
import '../services/market_service.dart';
import '../services/construction_service.dart';
import '../services/task_result_generator.dart';
import '../services/npc_generator.dart';

import '../services/experimentation_service.dart';
import '../services/combat_unit_factory.dart';
import '../util/manor_layout.dart';
import '../models/encounter_data.dart';
import '../services/arena_save_service.dart';

enum GameSpeed { paused, slow, normal, fast, lightning }

enum DeathCause { disease, trainCrash, murderSuicide, misunderstanding }

enum LifeObjective { women, money, fame, science }

enum GilesTrait { sage, endsMeet, silent, shuffle }

enum GilesTutorialStep {
  inactive,
  intro,
  selectKitchen,
  enterKitchen,
  commencePrep,
  assignResident,
  playClock,
  selectCoop,
  directAssign,
  inspectResident,
  summary,
}

enum ButlerDisposition { stern, kind, neutral }

class GameState extends ChangeNotifier {
  GameState() {
    _initializeResponsibilityDefaults();
  }

  void _initializeResponsibilityDefaults() {
    for (var cat in ResponsibilityCategory.values) {
      final tasks = TaskCategoryMapping.getTasksForCategory(cat);
      _categoryPriorities[cat] = tasks;
      _categoryDividers[cat] = (tasks.length / 2).floor(); // Default middle
    }
  }

  GameDate _currentDate = GameDate.initial();
  GameSpeed _speed = GameSpeed.paused;

  final List<NPC> _npcs = [];
  final List<NPC> _availableHamletNpcs = [];
  final List<Room> _rooms = [];
  // Resources and Inventory are now dynamically computed from Rooms.

  final TaskService _taskService = TaskService();
  final MarketService _marketService = MarketService();
  String? _butlerRoomId;
  final List<ConstructionProject> _activeConstruction = [];
  final List<Experiment> _activeExperiments = [];
  String? _lastAnnouncement;
  late final List<String> _announcementHistory = AnnouncementList(this);
  final List<Objective> _objectives = [];
  final List<Contract> _contracts = [];
  final Set<TaskType> _completedTaskTypes = {};
  final Map<TaskType, int> _taskCompletionCounts = {};

  final List<String> _unlockedDiscoveries = [];
  final List<String> _performedExperiments = [];
  String? _pendingNavigationTarget;
  final List<Dish> _pantry = [];
  final List<String> _cookingQueue = [];
  final List<String> _researchQueue = [];
  int _unreadObjectiveCount = 0;
  bool _pendingCombatEncounter = false;
  double _playerDistanceSinceEncounter = 0.0;
  bool _riverBridgeBuilt = false;
  String? _activeBirthdayNpcId;
  EncounterData? _pendingEncounterData;
  List<NPC>? _pendingEncounterEnemies;
  final Map<String, int> _taskStagnationCounters = {};

  final List<Chicken> _chickens = [];
  final Map<String, String> _lastProductionText = {};
  final Map<String, int> _npcDialogueCooldown = {};
  
  ManorVenture _manorVenture = ManorVenture.standard;
  ManorVenture get manorVenture => _manorVenture;

  final List<ActiveBusiness> _activeBusinesses = [];
  List<ActiveBusiness> get activeBusinesses =>
      List.unmodifiable(_activeBusinesses);

  bool _playerHasGraduateDegree = false;
  bool get playerHasGraduateDegree => _playerHasGraduateDegree;

  String? _playerAcademicSpecialization;
  String? get playerAcademicSpecialization => _playerAcademicSpecialization;

  int _veterinaryExperience = 0;
  int get veterinaryExperience => _veterinaryExperience;

  int _trainedBatsCount = 0;
  int get trainedBatsCount => _trainedBatsCount;
  List<String> _unlockedCombatCards = [];
  List<String> get unlockedCombatCards => _unlockedCombatCards;

  int _dissectionsPerformed = 0;
  int get dissectionsPerformed => _dissectionsPerformed;

  int _vivisectionsPerformed = 0;
  int get vivisectionsPerformed => _vivisectionsPerformed;

  int _puzzleStudiesPerformed = 0;
  int get puzzleStudiesPerformed => _puzzleStudiesPerformed;

  int _labExperimentsPerformed = 0;
  int get labExperimentsPerformed => _labExperimentsPerformed;

  Set<String> _unlockedLabActivities = {'small_dissection', 'large_dissection'};
  Set<String> get unlockedLabActivities => _unlockedLabActivities;

  Map<String, String>? _pendingMobileNotification;
  Map<String, String>? get pendingMobileNotification => _pendingMobileNotification;

  void clearPendingMobileNotification() {
    _pendingMobileNotification = null;
    notifyListeners();
  }

  void _triggerMobileFireworksNotification(String title, String message) {
    if (_pendingMobileNotification != null) return;
    _pendingMobileNotification = {
      'title': title,
      'message': message,
    };
    notifyListeners();
  }

  void incrementVeterinaryExperience() {
    _veterinaryExperience++;
    notifyListeners();
  }

  int _activeDentalLoan = 0;
  int get activeDentalLoan => _activeDentalLoan;

  int _activeMerchantLoan = 0;
  int get activeMerchantLoan => _activeMerchantLoan;

  double _merchantLoanInterestRate = 0.05;
  double get merchantLoanInterestRate => _merchantLoanInterestRate;

  int _merchantLoanDaysUnpaid = 0;
  int get merchantLoanDaysUnpaid => _merchantLoanDaysUnpaid;

  String? _merchantLoanProvider;
  String? get merchantLoanProvider => _merchantLoanProvider;

  String? _dentalCriticReviewState;
  String? get dentalCriticReviewState => _dentalCriticReviewState;

  int _dentalCriticReviewTriggerTime = 0;
  int get dentalCriticReviewTriggerTime => _dentalCriticReviewTriggerTime;

  bool _dentalMalpracticePending = false;
  bool get dentalMalpracticePending => _dentalMalpracticePending;

  int _dentalMalpracticeTriggerTime = 0;
  int get dentalMalpracticeTriggerTime => _dentalMalpracticeTriggerTime;

  double _bistroProfitModifier = 1.0;
  double get bistroProfitModifier => _bistroProfitModifier;

  double _bistroNextWeekBonus = 0.0;
  double get bistroNextWeekBonus => _bistroNextWeekBonus;

  int _restaurantTablesServedTonight = 0;
  int get restaurantTablesServedTonight => _restaurantTablesServedTonight;

  int _restaurantQueueCount = 0;
  int get restaurantQueueCount => _restaurantQueueCount;

  int _restaurantActiveTables = 0;
  int get restaurantActiveTables => _restaurantActiveTables;

  List<int> _restaurantTableFinishMinutes = [];
  List<int> get restaurantTableFinishMinutes => _restaurantTableFinishMinutes;

  bool _restaurantExtendedHoursActive = false;
  bool get restaurantExtendedHoursActive => _restaurantExtendedHoursActive;

  bool _restaurantPricePromptTriggered = false;
  bool get restaurantPricePromptTriggered => _restaurantPricePromptTriggered;

  double _bistroPriceLevel = 1.0;
  double get bistroPriceLevel => _bistroPriceLevel;

  List<String> _restaurantMenuIds = [
    'protein_mistery_stew',
    'boiled_cabbage',
    'scrambled_eggs',
  ];
  List<String> get restaurantMenuIds => _restaurantMenuIds;

  Map<String, double> _restaurantMenuPrices = {
    'protein_mistery_stew': 35.0,
    'boiled_cabbage': 15.0,
    'scrambled_eggs': 20.0,
  };
  Map<String, double> get restaurantMenuPrices => _restaurantMenuPrices;

  List<int> _restaurantOperatingDays = [5, 6, 7]; // Friday, Saturday, Sunday
  List<int> get restaurantOperatingDays => _restaurantOperatingDays;

  int _restaurantOperatingHourStart = 17;
  int get restaurantOperatingHourStart => _restaurantOperatingHourStart;

  int _restaurantOperatingHourEnd = 22;
  int get restaurantOperatingHourEnd => _restaurantOperatingHourEnd;

  int _restaurantEmployeeCount = 2;
  int get restaurantEmployeeCount => _restaurantEmployeeCount;

  double _restaurantEmployeeWages = 50.0;
  double get restaurantEmployeeWages => _restaurantEmployeeWages;

  String _restaurantSupplierContract = 'standard';
  String get restaurantSupplierContract => _restaurantSupplierContract;

  void updateRestaurantMenu(List<String> ids, Map<String, double> prices) {
    _restaurantMenuIds = ids;
    _restaurantMenuPrices = prices;
    notifyListeners();
  }

  void updateRestaurantHours(List<int> days, int start, int end) {
    _restaurantOperatingDays = days;
    _restaurantOperatingHourStart = start;
    _restaurantOperatingHourEnd = end;
    notifyListeners();
  }

  void updateRestaurantStaff(int count, double wages) {
    _restaurantEmployeeCount = count;
    _restaurantEmployeeWages = wages;
    notifyListeners();
  }

  void updateRestaurantSupplier(String contract) {
    _restaurantSupplierContract = contract;
    notifyListeners();
  }

  void updateBistroPriceLevel(double scale) {
    _bistroPriceLevel = scale;
    notifyListeners();
  }

  // Smoker operations
  void loadSmoker(String itemId, int duration) {
    // Consume ingredients from resources
    if (itemId == 'smoked_meat') {
      updateResource('meat', -1);
    } else if (itemId == 'smoked_sausage') {
      updateResource('meat_pork', -2);
    } else if (itemId == 'cured_salmon') {
      updateResource('fish', -1);
    }
    _smokerItem = itemId;
    _smokerMinutesRemaining = duration;
    _smokerProgress = 0.0;
    _announcementHistory.insert(
      0,
      "[KITCHEN SMOKER] Commenced slow cooking of ${itemId.toUpperCase().replaceAll('_', ' ')}.",
    );
    notifyListeners();
  }

  void unloadSmoker() {
    if (_smokerItem == null) return;
    String finishedItem = 'meat'; // fallback
    if (_smokerItem == 'smoked_meat') {
      finishedItem = 'meat_beef'; // high quality beef outcome!
    }
    if (_smokerItem == 'smoked_sausage') {
      finishedItem = 'meat_pork'; // high quality pork outcome!
    }
    if (_smokerItem == 'cured_salmon') finishedItem = 'fish';

    // Add high quality output items
    setResource(finishedItem, (resources[finishedItem] ?? 0) + 3);

    _announcementHistory.insert(
      0,
      "[KITCHEN SMOKER] Smoker slow cook cycle finished! Harvested 3 units of refined ${finishedItem.toUpperCase()} from the smoker chamber.",
    );

    _smokerItem = null;
    _smokerMinutesRemaining = 0;
    _smokerProgress = 0.0;
    notifyListeners();
  }

  void updateRestaurantDayHours(int day, int start, int end) {
    _restaurantStartHours[day] = start;
    _restaurantEndHours[day] = end;
    notifyListeners();
  }

  void toggleRestaurantDayClosed(int day, bool isClosed) {
    if (isClosed) {
      _restaurantOperatingDays.remove(day);
    } else {
      if (!_restaurantOperatingDays.contains(day)) {
        _restaurantOperatingDays.add(day);
      }
    }
    notifyListeners();
  }

  void updateRestaurantAmbiance(String ambiance) {
    _restaurantAmbiance = ambiance;
    notifyListeners();
  }

  void updateRestaurantEntertainment(String entertainment) {
    _restaurantEntertainment = entertainment;
    notifyListeners();
  }

  void updateBarStockedDrinks(List<String> drinks, Map<String, double> prices) {
    _barStockedDrinks = drinks;
    _barDrinkPrices = prices;
    notifyListeners();
  }

  int getPrepareableCopies(Recipe recipe) {
    int minCopies = 999;
    recipe.ingredients.forEach((ing, req) {
      final count = resources[ing] ?? 0;
      final possible = count ~/ req;
      if (possible < minCopies) {
        minCopies = possible;
      }
    });
    return minCopies == 999 ? 0 : minCopies;
  }

  void takeOutDentalLoan() {
    _activeDentalLoan = 1500;
    updateResource('funds', 1500);
    _lastAnnouncement =
        "LOAN: Conferred Imperial Dental Setup Loan of 1,500 CHF.";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] LOAN: $_lastAnnouncement",
    );
    notifyListeners();
  }

  void payBackDentalLoan(int amount) {
    _activeDentalLoan = max(0, _activeDentalLoan - amount);
    updateResource('funds', -amount);
    _lastAnnouncement =
        "LOAN: Paid back $amount CHF of Dental Setup Loan. Remaining balance: $_activeDentalLoan CHF.";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] LOAN: $_lastAnnouncement",
    );
    notifyListeners();
  }

  void establishDentalClinic(String roomId) {
    final roomIdx = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIdx == -1) return;
    final r = _rooms[roomIdx];
    if (r.floor != Floor.attic && r.floor != Floor.basement) return;
    _rooms[roomIdx] = r.copyWith(
      type: RoomType.dentalClinic,
      isRestored: true,
      restorationProgress: 1.0,
      description:
          "A spotless Glarus Dental Clinic established by Alphonse Giles.",
    );
    _lastAnnouncement =
        "CLINIC: Restored and established a Dental Clinic in ${r.name}!";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] CLINIC: $_lastAnnouncement",
    );
    notifyListeners();
  }

  void selectAcademicSpecialization(String spec) {
    if (_graduateSchool == null) return;
    _graduateSchool = _graduateSchool!.copyWith(
      specialization: spec,
      academicLogs: [
        ..._graduateSchool!.academicLogs,
        "[${_currentDate.formattedTime}] Selected academic specialization: ${spec.toUpperCase()}.",
      ],
    );
    notifyListeners();
  }

  GraduateSchoolState? _graduateSchool;
  GraduateSchoolState? get graduateSchool => _graduateSchool;

  Map<String, dynamic>? _activeFlaubertEvent;
  Map<String, dynamic>? get activeFlaubertEvent => _activeFlaubertEvent;

  bool _rebelConstructsActive = false;
  bool get rebelConstructsActive => _rebelConstructsActive;

  bool _newRegionUnlocked = false;
  bool get newRegionUnlocked => _newRegionUnlocked;

  bool _newPropertyConstructed = false;
  bool get newPropertyConstructed => _newPropertyConstructed;

  bool _cheatCodesEnabled = false;
  bool get cheatCodesEnabled => _cheatCodesEnabled;

  void setCheatCodesEnabled(bool enabled) {
    _cheatCodesEnabled = enabled;
    notifyListeners();
  }

  int _reanimatedRatsCount = 0;
  int _reanimatedBatsCount = 0;
  int _reanimatedHumanCount = 0;
  int _exploredHexesCount = 0;
  int _activeChapter = 1;
  bool _showChapter2Modal = false;
  
  int get reanimatedRatsCount => _reanimatedRatsCount;
  int get reanimatedBatsCount => _reanimatedBatsCount;
  int get reanimatedHumanCount => _reanimatedHumanCount;
  int get exploredHexesCount => _exploredHexesCount;
  int get activeChapter => _activeChapter;
  bool get showChapter2Modal => _showChapter2Modal;
  
  void dismissChapter2Modal() {
    _showChapter2Modal = false;
    notifyListeners();
  }

  GilesTutorialStep _gilesTutorialStep = GilesTutorialStep.inactive;
  GilesTutorialStep get gilesTutorialStep => _gilesTutorialStep;

  void advanceGilesTutorial(GilesTutorialStep nextStep) {
    if (_gilesTutorialStep != GilesTutorialStep.inactive) {
      _gilesTutorialStep = nextStep;
      notifyListeners();
    }
  }

  void dismissGilesTutorial() {
    _gilesTutorialStep = GilesTutorialStep.inactive;
    notifyListeners();
  }

  void exploreMapHex() {
    _exploredHexesCount++;
    _checkObjectives();
    notifyListeners();
  }

  void setRebelConstructs(bool active) {
    _rebelConstructsActive = active;
    notifyListeners();
  }

  void setNewRegionUnlocked(bool active) {
    _newRegionUnlocked = active;
    notifyListeners();
  }

  void setNewPropertyConstructed(bool active) {
    _newPropertyConstructed = active;
    notifyListeners();
  }

  void clearFlaubertEvent() {
    _activeFlaubertEvent = null;
    if (_speedBeforePause != null) {
      setSpeed(_speedBeforePause!);
      _speedBeforePause = null;
    }
    notifyListeners();
  }

  void setManorVenture(ManorVenture venture) {
    _manorVenture = venture;
    _lastAnnouncement =
        "MANOR VENTURE SET TO ${venture.displayName.toUpperCase()}";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] VENTURE: $_lastAnnouncement",
    );
    notifyListeners();
  }
  final Map<String, DateTime> _lastProductionTime = {};
  
  String? getLastProductionText(String roomId) => _lastProductionText[roomId];
  DateTime? getLastProductionTime(String roomId) => _lastProductionTime[roomId];

  void notifyRoomProduction(String roomId, String text) {
    _lastProductionText[roomId] = text;
    _lastProductionTime[roomId] = DateTime.now();
    notifyListeners();
  }

  void triggerUpdate() {
    notifyListeners();
  }
  final List<Crop> _crops = [];
  final List<Plant> _gardenPlants = [];
  ButlerDisposition _butlerDisposition = ButlerDisposition.neutral;

  bool _isGameOver = false;
  String? _gameOverReason;
  bool get isGameOver => _isGameOver;
  String? get gameOverReason => _gameOverReason;
  final List<ManorCrisis> _crises = [];
  Set<String> _knownRecipes = {
    'staple_bread',
    'bean_stew',
    'omelette',
    'roast_chicken',
    'beef_root_stew',
    'protein_mistery_stew',
    'fried_generic_meat',
  };
  final List<Discovery> _discoveries = [];
  final Map<String, double> _researchPoints = {};
  final Map<String, int> _customTaskCounts = {};

  // --- NEW BISTRO TYCOON STATE FIELDS ---
  String? _smokerItem;
  int _smokerMinutesRemaining = 0;
  double _smokerProgress = 0.0;

  Map<int, int> _restaurantStartHours = {
    1: 17,
    2: 17,
    3: 17,
    4: 17,
    5: 17,
    6: 17,
    7: 17,
  };
  Map<int, int> _restaurantEndHours = {
    1: 22,
    2: 22,
    3: 22,
    4: 22,
    5: 22,
    6: 22,
    7: 22,
  };

  int _restaurantNewRecipeAttempts = 0;
  String _restaurantAmbiance = 'rustic'; // 'rustic', 'gothic', 'alchemical'
  String _restaurantEntertainment = 'none'; // 'none', 'lutist', 'opera'

  List<String> _barStockedDrinks = ['small_beer'];
  Map<String, double> _barDrinkPrices = {
    'small_beer': 10.0,
    'golden_ale': 25.0,
    'clear_spirits': 20.0,
    'barrel_aged_brandy': 50.0,
  };

  // Getters
  String? get smokerItem => _smokerItem;
  int get smokerMinutesRemaining => _smokerMinutesRemaining;
  double get smokerProgress => _smokerProgress;

  Map<int, int> get restaurantStartHours => _restaurantStartHours;
  Map<int, int> get restaurantEndHours => _restaurantEndHours;

  int get restaurantNewRecipeAttempts => _restaurantNewRecipeAttempts;
  String get restaurantAmbiance => _restaurantAmbiance;
  String get restaurantEntertainment => _restaurantEntertainment;

  List<String> get barStockedDrinks => _barStockedDrinks;
  Map<String, double> get barDrinkPrices => _barDrinkPrices;

  bool _hasFoodDropTriggered = false;
  int? _foodDropTriggerTime;
  int _lastMerchantSpawnMinutes = 0;
  final List<String> _pendingNpcRemovals = [];

  bool _pendingGuestConversation = false;
  NPC? _conversationGreeter;
  NPC? _conversationGuest;
  GameSpeed? _speedBeforePause;

  bool get pendingGuestConversation => _pendingGuestConversation;
  NPC? get conversationGreeter => _conversationGreeter;
  NPC? get conversationGuest => _conversationGuest;

  void clearGuestConversation() {
    _pendingGuestConversation = false;
    _conversationGreeter = null;
    _conversationGuest = null;
    if (_speedBeforePause != null) {
      setSpeed(_speedBeforePause!);
      _speedBeforePause = null;
    }
    notifyListeners();
  }

  VisitorQuest getVisitorQuestForNpc(NPC guest) {
    final quests = VisitorQuestCatalog.allQuests;
    final hash = guest.name.hashCode.abs();
    return quests[hash % quests.length];
  }

  void acceptVisitorQuest(VisitorQuest quest, String guestName) {
    if (!_objectives.any((o) => o.id == quest.objective.id)) {
      _objectives.add(quest.objective);
    }
    if (quest.agreement != null) {
      final customizedAgreement = quest.agreement!.copyWith(
        npcId: guestName,
      );
      if (!_contracts.any((c) => c.id == customizedAgreement.id)) {
        _contracts.add(customizedAgreement);
      }
    }
    _lastAnnouncement = "${guestName.toUpperCase()}: ${quest.acceptMessage}";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] QUEST: ${quest.objective.title}",
    );
    notifyListeners();
  }

  void dismissGuest(String guestId) {
    _npcs.removeWhere((n) => n.id == guestId);
    _lastAnnouncement = "The guest has departed Glarus entryway.";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] DEPARTURE: Guest left Glarus.",
    );
    notifyListeners();
  }

  void adjustNpcSatisfaction(String npcId, double amount) {
    final index = _npcs.indexWhere((n) => n.id == npcId);
    if (index != -1) {
      final npc = _npcs[index];
      _npcs[index] = npc.copyWith(
        satisfaction: (npc.satisfaction + amount).clamp(0.0, 100.0),
      );
      notifyListeners();
    }
  }

  void _handleNpcDeath(int index) {
    if (index < 0 || index >= _npcs.length) return;
    final deadNpc = _npcs[index];

    // Create Corpse Item
    final corpse = GameItem.create(
      name: "Corpse of ${deadNpc.name}",
      type: "corpse_${deadNpc.specimenType.toLowerCase()}",
      category: ItemCategory.corpse,
      weight: deadNpc.stats['weightGrams']?.toDouble() ?? 70.0,
      metadata: {
        'npc_data': deadNpc.toJson(),
        'specimenType': deadNpc.specimenType,
        'deathDate': _currentDate.formattedDate,
      },
    );

    _addPhysicalItem(corpse);
    _npcs.removeAt(index);

    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] DEATH: ${deadNpc.name} has perished. A corpse remains.",
    );
    notifyListeners();
  }

  final Map<ResponsibilityCategory, List<TaskType>> _categoryPriorities = {};
  final Map<ResponsibilityCategory, int> _categoryDividers = {};

  // Options Section
  String _combatControlMode = 'pad'; // 'pad' or 'click'
  String _emergencyBehavior =
      'slow'; // 'slow' (default), 'pause', 'normal', 'nothing'
  String _residentsAsleepBehavior =
      'lightning'; // 'lightning' (default), 'fast', 'nothing'

  // New Game Choices
  String _playerFirstName = "The";
  String _playerLastName = "Master";
  String _estateName = "Manor";
  DeathCause? _deathCause;
  int _playerAge = 30;
  GilesTrait _gilesTrait = GilesTrait.silent;
  LifeObjective _mainObjective = LifeObjective.science;

  Map<String, dynamic> toJson() => {
    'dissectionsPerformed': _dissectionsPerformed,
    'vivisectionsPerformed': _vivisectionsPerformed,
    'puzzleStudiesPerformed': _puzzleStudiesPerformed,
    'labExperimentsPerformed': _labExperimentsPerformed,
    'unlockedLabActivities': _unlockedLabActivities.toList(),
    'trainedBatsCount': _trainedBatsCount,
    'unlockedCombatCards': _unlockedCombatCards,
    'currentDate': _currentDate.toJson(),
    'speed': _speed.index,
    'npcs': _npcs.map((n) => n.toJson()).toList(),
    'availableHamletNpcs': _availableHamletNpcs.map((n) => n.toJson()).toList(),
    'rooms': _rooms.map((r) => r.toJson()).toList(),
    'butlerRoomId': _butlerRoomId,
    'activeConstruction': _activeConstruction.map((c) => c.toJson()).toList(),
    'activeExperiments': _activeExperiments.map((e) => e.toJson()).toList(),
    'lastAnnouncement': _lastAnnouncement,
    'announcementHistory': _announcementHistory,
    'objectives': _objectives.map((o) => o.toJson()).toList(),
    'contracts': _contracts.map((c) => c.toJson()).toList(),
    'completedTaskTypes': _completedTaskTypes.map((t) => t.index).toList(),
    'unlockedDiscoveries': _unlockedDiscoveries,
    'performedExperiments': _performedExperiments,
    'pendingNavigationTarget': _pendingNavigationTarget,
    'pantry': _pantry.map((d) => d.toJson()).toList(),
    'cookingQueue': _cookingQueue,
    'knownRecipes': _knownRecipes.toList(),
    'discoveries': _discoveries.map((d) => d.toJson()).toList(),
    'researchQueue': _researchQueue,
    'unreadObjectiveCount': _unreadObjectiveCount,
    'chickens': _chickens.map((c) => c.toJson()).toList(),
    'crops': _crops.map((c) => c.toJson()).toList(),
    'gardenPlants': _gardenPlants.map((p) => p.toJson()).toList(),
    'customTaskCounts': _customTaskCounts,
    'butlerDisposition': _butlerDisposition.index,
    'crises': _crises.map((c) => c.toJson()).toList(),
    'pendingCombatEncounter': _pendingCombatEncounter,
    'playerDistanceSinceEncounter': _playerDistanceSinceEncounter,
    'pendingEncounterData': _pendingEncounterData?.toJson(),
    'pendingEncounterEnemies': _pendingEncounterEnemies?.map((e) => e.toJson()).toList(),
    'categoryPriorities': _categoryPriorities.map(
      (k, v) => MapEntry(k.index.toString(), v.map((t) => t.index).toList()),
    ),
    'categoryDividers': _categoryDividers.map(
      (k, v) => MapEntry(k.index.toString(), v),
    ),
    'playerFirstName': _playerFirstName,
    'playerLastName': _playerLastName,
    'estateName': _estateName,
    'deathCause': _deathCause?.index,
    'playerAge': _playerAge,
    'gilesTrait': _gilesTrait.index,
    'mainObjective': _mainObjective.index,
    'researchPoints': _researchPoints,
    'manorVenture': _manorVenture.index,
    'combatControlMode': _combatControlMode,
    'emergencyBehavior': _emergencyBehavior,
    'residentsAsleepBehavior': _residentsAsleepBehavior,
    'hasFoodDropTriggered': _hasFoodDropTriggered,
    'foodDropTriggerTime': _foodDropTriggerTime,
    'lastMerchantSpawnMinutes': _lastMerchantSpawnMinutes,
    'activeBusinesses': _activeBusinesses.map((b) => b.toJson()).toList(),
    'playerHasGraduateDegree': _playerHasGraduateDegree,
    'playerAcademicSpecialization': _playerAcademicSpecialization,
    'veterinaryExperience': _veterinaryExperience,
    'activeDentalLoan': _activeDentalLoan,
    'dentalCriticReviewState': _dentalCriticReviewState,
    'dentalCriticReviewTriggerTime': _dentalCriticReviewTriggerTime,
    'dentalMalpracticePending': _dentalMalpracticePending,
    'dentalMalpracticeTriggerTime': _dentalMalpracticeTriggerTime,
    'bistroProfitModifier': _bistroProfitModifier,
    'bistroNextWeekBonus': _bistroNextWeekBonus,
    'restaurantTablesServedTonight': _restaurantTablesServedTonight,
    'restaurantQueueCount': _restaurantQueueCount,
    'restaurantActiveTables': _restaurantActiveTables,
    'restaurantTableFinishMinutes': _restaurantTableFinishMinutes,
    'restaurantExtendedHoursActive': _restaurantExtendedHoursActive,
    'restaurantPricePromptTriggered': _restaurantPricePromptTriggered,
    'bistroPriceLevel': _bistroPriceLevel,
    'restaurantMenuIds': _restaurantMenuIds,
    'restaurantMenuPrices': _restaurantMenuPrices,
    'restaurantOperatingDays': _restaurantOperatingDays,
    'restaurantOperatingHourStart': _restaurantOperatingHourStart,
    'restaurantOperatingHourEnd': _restaurantOperatingHourEnd,
    'restaurantEmployeeCount': _restaurantEmployeeCount,
    'restaurantEmployeeWages': _restaurantEmployeeWages,
    'restaurantSupplierContract': _restaurantSupplierContract,
    'smokerItem': _smokerItem,
    'smokerMinutesRemaining': _smokerMinutesRemaining,
    'smokerProgress': _smokerProgress,
    'restaurantStartHours': _restaurantStartHours,
    'restaurantEndHours': _restaurantEndHours,
    'restaurantNewRecipeAttempts': _restaurantNewRecipeAttempts,
    'restaurantAmbiance': _restaurantAmbiance,
    'restaurantEntertainment': _restaurantEntertainment,
    'barStockedDrinks': _barStockedDrinks,
    'barDrinkPrices': _barDrinkPrices,
    'graduateSchool': _graduateSchool?.toJson(),
    'rebelConstructsActive': _rebelConstructsActive,
    'newRegionUnlocked': _newRegionUnlocked,
    'newPropertyConstructed': _newPropertyConstructed,
    'cheatCodesEnabled': _cheatCodesEnabled,
  };

  void loadFromJson(Map<String, dynamic> json) {
    _simulationPlayerDeck = null;
    _simulationAiDeck = null;
    _currentDate = GameDate.fromJson(json['currentDate']);
    _speed = GameSpeed.values[json['speed'] as int? ?? GameSpeed.paused.index];
    _combatControlMode = json['combatControlMode'] as String? ?? 'pad';
    _emergencyBehavior = json['emergencyBehavior'] as String? ?? 'slow';
    _residentsAsleepBehavior =
        json['residentsAsleepBehavior'] as String? ?? 'lightning';
    _hasFoodDropTriggered = json['hasFoodDropTriggered'] as bool? ?? false;
    _foodDropTriggerTime = json['foodDropTriggerTime'] as int?;
    _lastMerchantSpawnMinutes = json['lastMerchantSpawnMinutes'] as int? ?? 0;
    _trainedBatsCount = json['trainedBatsCount'] as int? ?? 0;
    _dissectionsPerformed = json['dissectionsPerformed'] as int? ?? 0;
    _vivisectionsPerformed = json['vivisectionsPerformed'] as int? ?? 0;
    _puzzleStudiesPerformed = json['puzzleStudiesPerformed'] as int? ?? 0;
    _labExperimentsPerformed = json['labExperimentsPerformed'] as int? ?? 0;
    _unlockedLabActivities = Set<String>.from(json['unlockedLabActivities'] as List? ?? ['small_dissection', 'large_dissection']);
    _unlockedCombatCards = List<String>.from(json['unlockedCombatCards'] as List? ?? []);

    _npcs.clear();
    _npcs.addAll((json['npcs'] as List).map((n) => NPC.fromJson(n)).toList());

    _availableHamletNpcs.clear();
    _availableHamletNpcs.addAll(
      (json['availableHamletNpcs'] as List)
          .map((n) => NPC.fromJson(n))
          .toList(),
    );

    _rooms.clear();
    _rooms.addAll(
      (json['rooms'] as List).map((r) => Room.fromJson(r)).toList(),
    );

    // Legacy resources and inventory were removed. They are now computed from _rooms and implicitly part of room save data.

    _butlerRoomId = json['butlerRoomId'] as String?;

    _activeConstruction.clear();
    _activeConstruction.addAll(
      (json['activeConstruction'] as List)
          .map((c) => ConstructionProject.fromJson(c))
          .toList(),
    );

    _activeExperiments.clear();
    _activeExperiments.addAll(
      (json['activeExperiments'] as List)
          .map((e) => Experiment.fromJson(e))
          .toList(),
    );

    _lastAnnouncement = json['lastAnnouncement'] as String?;
    _announcementHistory.clear();
    _announcementHistory.addAll(List<String>.from(json['announcementHistory']));

    _objectives.clear();
    _objectives.addAll(
      (json['objectives'] as List).map((o) => Objective.fromJson(o)).toList(),
    );

    _contracts.clear();
    if (json['contracts'] != null) {
      _contracts.addAll(
        (json['contracts'] as List).map((c) => Contract.fromJson(c)).toList(),
      );
    }

    _completedTaskTypes.clear();
    _completedTaskTypes.addAll(
      (json['completedTaskTypes'] as List)
          .map((t) => TaskType.values[t as int])
          .toSet(),
    );

    _unlockedDiscoveries.clear();
    _unlockedDiscoveries.addAll(List<String>.from(json['unlockedDiscoveries']));

    _performedExperiments.clear();
    _performedExperiments.addAll(
      List<String>.from(json['performedExperiments']),
    );

    _pendingNavigationTarget = json['pendingNavigationTarget'] as String?;

    _pantry.clear();
    _pantry.addAll(
      (json['pantry'] as List).map((d) => Dish.fromJson(d)).toList(),
    );

    _researchQueue.clear();
    _researchQueue.addAll(List<String>.from(json['researchQueue']));

    _researchPoints.clear();
    final resPoints = json['researchPoints'] as Map<String, dynamic>? ?? {};
    resPoints.forEach((k, v) => _researchPoints[k] = (v as num).toDouble());

    _unreadObjectiveCount = json['unreadObjectiveCount'] as int? ?? 0;
    _manorVenture = ManorVenture
        .values[json['manorVenture'] as int? ?? ManorVenture.standard.index];

    _activeBusinesses.clear();
    if (json['activeBusinesses'] != null) {
      _activeBusinesses.addAll(
        (json['activeBusinesses'] as List)
            .map((b) => ActiveBusiness.fromJson(b as Map<String, dynamic>))
            .toList(),
      );
    }
    _playerHasGraduateDegree =
        json['playerHasGraduateDegree'] as bool? ?? false;
    _playerAcademicSpecialization =
        json['playerAcademicSpecialization'] as String?;
    _veterinaryExperience = json['veterinaryExperience'] as int? ?? 0;
    _activeDentalLoan = json['activeDentalLoan'] as int? ?? 0;
    _dentalCriticReviewState = json['dentalCriticReviewState'] as String?;
    _dentalCriticReviewTriggerTime =
        json['dentalCriticReviewTriggerTime'] as int? ?? 0;
    _dentalMalpracticePending =
        json['dentalMalpracticePending'] as bool? ?? false;
    _dentalMalpracticeTriggerTime =
        json['dentalMalpracticeTriggerTime'] as int? ?? 0;
    _bistroProfitModifier = (json['bistroProfitModifier'] as num? ?? 1.0)
        .toDouble();
    _bistroNextWeekBonus = (json['bistroNextWeekBonus'] as num? ?? 0.0)
        .toDouble();
    _restaurantTablesServedTonight =
        json['restaurantTablesServedTonight'] as int? ?? 0;
    _restaurantQueueCount = json['restaurantQueueCount'] as int? ?? 0;
    _restaurantActiveTables = json['restaurantActiveTables'] as int? ?? 0;
    _restaurantTableFinishMinutes = List<int>.from(
      json['restaurantTableFinishMinutes'] as List? ?? [],
    );
    _restaurantExtendedHoursActive =
        json['restaurantExtendedHoursActive'] as bool? ?? false;
    _restaurantPricePromptTriggered =
        json['restaurantPricePromptTriggered'] as bool? ?? false;
    _bistroPriceLevel = (json['bistroPriceLevel'] as num? ?? 1.0).toDouble();
    _restaurantMenuIds = List<String>.from(
      json['restaurantMenuIds'] as List? ??
          ['protein_mistery_stew', 'boiled_cabbage', 'scrambled_eggs'],
    );

    _restaurantMenuPrices.clear();
    final mPrices = json['restaurantMenuPrices'] as Map<String, dynamic>? ?? {};
    mPrices.forEach((k, v) => _restaurantMenuPrices[k] = (v as num).toDouble());

    _restaurantOperatingDays = List<int>.from(
      json['restaurantOperatingDays'] as List? ?? [5, 6, 7],
    );
    _restaurantOperatingHourStart =
        json['restaurantOperatingHourStart'] as int? ?? 17;
    _restaurantOperatingHourEnd =
        json['restaurantOperatingHourEnd'] as int? ?? 22;
    _restaurantEmployeeCount = json['restaurantEmployeeCount'] as int? ?? 2;
    _restaurantEmployeeWages = (json['restaurantEmployeeWages'] as num? ?? 50.0)
        .toDouble();
    _restaurantSupplierContract =
        json['restaurantSupplierContract'] as String? ?? 'standard';

    _smokerItem = json['smokerItem'] as String?;
    _smokerMinutesRemaining = json['smokerMinutesRemaining'] as int? ?? 0;
    _smokerProgress = (json['smokerProgress'] as num? ?? 0.0).toDouble();

    _restaurantStartHours = Map<int, int>.from(
      (json['restaurantStartHours'] as Map?)?.map(
            (k, v) => MapEntry(int.parse(k.toString()), v as int),
          ) ??
          {1: 17, 2: 17, 3: 17, 4: 17, 5: 17, 6: 17, 7: 17},
    );
    _restaurantEndHours = Map<int, int>.from(
      (json['restaurantEndHours'] as Map?)?.map(
            (k, v) => MapEntry(int.parse(k.toString()), v as int),
          ) ??
          {1: 22, 2: 22, 3: 22, 4: 22, 5: 22, 6: 22, 7: 22},
    );

    _restaurantNewRecipeAttempts =
        json['restaurantNewRecipeAttempts'] as int? ?? 0;
    _restaurantAmbiance = json['restaurantAmbiance'] as String? ?? 'rustic';
    _restaurantEntertainment =
        json['restaurantEntertainment'] as String? ?? 'none';

    _barStockedDrinks = List<String>.from(
      json['barStockedDrinks'] as List? ?? ['small_beer'],
    );

    _barDrinkPrices.clear();
    final bPrices = json['barDrinkPrices'] as Map? ?? {};
    bPrices.forEach(
      (k, v) => _barDrinkPrices[k.toString()] = (v as num).toDouble(),
    );

    _graduateSchool = json['graduateSchool'] != null
        ? GraduateSchoolState.fromJson(
            json['graduateSchool'] as Map<String, dynamic>,
          )
        : null;
    _rebelConstructsActive = json['rebelConstructsActive'] as bool? ?? false;
    _newRegionUnlocked = json['newRegionUnlocked'] as bool? ?? false;
    _newPropertyConstructed = json['newPropertyConstructed'] as bool? ?? false;
    _cheatCodesEnabled = json['cheatCodesEnabled'] as bool? ?? false;

    _customTaskCounts.clear();
    final customTaskC = json['customTaskCounts'] as Map<String, dynamic>? ?? {};
    customTaskC.forEach((k, v) => _customTaskCounts[k] = (v as num).toInt());

    _chickens.clear();
    _chickens.addAll(
      (json['chickens'] as List).map((c) => Chicken.fromJson(c)).toList(),
    );

    _crops.clear();
    _crops.addAll(
      (json['crops'] as List).map((c) => Crop.fromJson(c)).toList(),
    );

    _gardenPlants.clear();
    _gardenPlants.addAll(
      (json['gardenPlants'] as List? ?? [])
          .map((p) => Plant.fromJson(p))
          .toList(),
    );

    _butlerDisposition =
        ButlerDisposition.values[json['butlerDisposition'] as int? ?? 2];

    _crises.clear();
    if (json['crises'] != null) {
      _crises.addAll(
        (json['crises'] as List).map((c) => ManorCrisis.fromJson(c)),
      );
    }

    if (json['knownRecipes'] != null) {
      _knownRecipes = Set<String>.from(json['knownRecipes']);
    }

    if (json['discoveries'] != null) {
      _discoveries.clear();
      _discoveries.addAll(
        (json['discoveries'] as List).map((d) => Discovery.fromJson(d)),
      );
    }

    _categoryPriorities.clear();
    if (json['categoryPriorities'] != null) {
      (json['categoryPriorities'] as Map).forEach((k, v) {
        _categoryPriorities[ResponsibilityCategory.values[int.parse(k)]] =
            (v as List).map((t) => TaskType.values[t as int]).toList();
      });
    }

    _categoryDividers.clear();
    if (json['categoryDividers'] != null) {
      (json['categoryDividers'] as Map).forEach((k, v) {
        _categoryDividers[ResponsibilityCategory.values[int.parse(k)]] =
            v as int;
      });
    }

    _playerFirstName = json['playerFirstName'] as String? ?? 'The';
    _playerLastName = json['playerLastName'] as String? ?? 'Master';
    _estateName = json['estateName'] as String? ?? 'Manor';
    _deathCause = json['deathCause'] != null
        ? DeathCause.values[json['deathCause']]
        : null;
    _playerAge = json['playerAge'] as int? ?? 3;
    _gilesTrait = GilesTrait.values[json['gilesTrait'] as int? ?? 2];
    _mainObjective = LifeObjective.values[json['mainObjective'] as int? ?? 3];
    _pendingCombatEncounter = json['pendingCombatEncounter'] as bool? ?? false;
    _playerDistanceSinceEncounter = json['playerDistanceSinceEncounter'] as double? ?? 0.0;
    if (json['pendingEncounterData'] != null) {
      _pendingEncounterData = EncounterData.fromJson(json['pendingEncounterData'] as Map<String, dynamic>);
    }
    if (json['pendingEncounterEnemies'] != null) {
      _pendingEncounterEnemies = (json['pendingEncounterEnemies'] as List)
          .map((e) => NPC.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    _checkForTodayBirthday();
    notifyListeners();
  }

  List<Map<String, dynamic>> getAvailableSpecimenTargets(String type) {
    final List<Map<String, dynamic>> targets = [];

    if (type == 'research_notes') {
      for (var item in inventory.where(
        (i) =>
            i.category == ItemCategory.knowledge &&
            i.type == 'research_notes' &&
            !i.isReserved,
      )) {
        targets.add({'id': item.id, 'name': item.name, 'type': 'item'});
      }
    } else if (type == 'specimen') {
      for (var item in inventory.where(
        (i) => i.category == ItemCategory.specimen && !i.isReserved,
      )) {
        targets.add({'id': item.id, 'name': item.name, 'type': 'item'});
      }
      for (var npc in _npcs.where(
        (n) => n.specimenType.isNotEmpty && !n.isPlayer && !n.isReserved,
      )) {
        targets.add({'id': npc.id, 'name': npc.name, 'type': 'npc'});
      }
    } else {
      for (var item in inventory.where(
        (i) =>
            i.category == ItemCategory.specimen &&
            i.type == type &&
            !i.isReserved,
      )) {
        targets.add({'id': item.id, 'name': item.name, 'type': 'item'});
      }
      final npcType = type == 'large_specimen' ? 'Human' : type;
      for (var npc in _npcs.where(
        (n) => n.specimenType == npcType && !n.isPlayer && !n.isReserved,
      )) {
        targets.add({'id': npc.id, 'name': npc.name, 'type': 'npc'});
      }
    }

    return targets;
  }

  List<NPC> get npcs => List.unmodifiable(_npcs);

  List<Map<String, dynamic>> get butcheryTargets {
    final List<Map<String, dynamic>> targets = [];

    // 1. Chickens (Individual)
    for (var c in _chickens.where((c) => !c.isReserved)) {
      targets.add({
        'id': c.id,
        'name':
            "${c.breed.name} Chicken (${c.isMature(_currentDate) ? 'Mature' : 'Young'}) #${c.id.substring(0, 4)}",
      });
    }

    // 2. Specimens from inventory (individual, as they have unique stats)
    for (var item in inventory.where(
      (i) => i.category == ItemCategory.specimen && !i.isReserved,
    )) {
      targets.add({'id': item.id, 'name': item.name});
    }

    // 3. NPCs (Resident or specialized creatures)
    for (var npc in _npcs.where(
      (n) =>
          !n.isPlayer &&
          (n.isResident || n.status == NPCStatus.zombie) &&
          !n.isReserved,
    )) {
      targets.add({'id': npc.id, 'name': npc.name});
    }

    return targets;
  }

  /// Dynamically derives the task queue for a room from all NPCs' intent queues.
  List<EnqueuedTask> getRoomTaskQueue(String roomId) {
    final List<EnqueuedTask> queue = [];
    for (var npc in _npcs) {
      final activeTask = _taskService.activeTasks.firstWhereOrNull(
        (t) => t.npcId == npc.id,
      );

      // Include enqueued intents
      for (var intent in npc.intentQueue) {
        // Skip the intent if it's currently the active task being performed
        if (activeTask != null && intent.id == activeTask.intentId) continue;

        if (intent.targetRoomId == roomId) {
          queue.add(
            EnqueuedTask(
              npcId: npc.id,
              intentId: intent.id,
              description: "${intent.action.displayName} (${npc.name})",
            ),
          );
        }
      }
    }
    return queue;
  }

  List<NPC> get availableHamletNpcs => List.unmodifiable(_availableHamletNpcs);
  List<Room> get rooms => List.unmodifiable(_rooms);
  void addRoomForTesting(Room room) {
    _rooms.add(room);
    notifyListeners();
  }
  Map<String, num> get resources {
    final Map<String, num> totals = {};
    for (var room in _rooms) {
      for (var item in room.inventory) {
        if (item.type == 'franc' || item.type == 'funds') {
          totals['funds'] = (totals['funds'] ?? 0) + item.quantity;
        } else {
          totals[item.type] = (totals[item.type] ?? 0) + item.quantity;
        }
      }
    }
    // Removed legacy _uncollectedEggs from totals
    totals['meals'] = _pantry.length;
    return totals;
  }

  static bool isIndivisibleResource(String key) {
    return const [
      'funds',
      'eggs',
      'meals',
      'wood',
      'meat',
      'cabbage',
      'timber',
      'fertilizer',
    ].contains(key);
  }

  List<GameItem> get inventory {
    final List<GameItem> allItems = [];
    for (var room in _rooms) {
      allItems.addAll(room.inventory);
    }
    return List.unmodifiable(allItems);
  }

  Map<ResponsibilityCategory, List<TaskType>> get categoryPriorities =>
      Map.unmodifiable(_categoryPriorities);
  Map<ResponsibilityCategory, int> get categoryDividers =>
      Map.unmodifiable(_categoryDividers);

  MarketService get marketService => _marketService;
  TaskService get taskService => _taskService;
  List<GameTask> get activeTasks => _taskService.activeTasks;

  double getKnowledgeLevel(String discipline) {
    return _rooms.fold(
      0.0,
      (sum, room) => sum + room.calculateDisciplineKnowledge(discipline),
    );
  }

  List<ConstructionProject> get activeConstruction =>
      List.unmodifiable(_activeConstruction);
  List<Experiment> get activeExperiments =>
      List.unmodifiable(_activeExperiments);
  String? get butlerRoomId => _butlerRoomId;
  String? get lastAnnouncement => _lastAnnouncement;
  List<String> get announcementHistory =>
      List.unmodifiable(_announcementHistory);
  GameDate get currentDate => _currentDate;
  List<ManorCrisis> get crises => List.unmodifiable(_crises);
  List<Crop> get crops => List.unmodifiable(_crops);
  List<Plant> get gardenPlants => List.unmodifiable(_gardenPlants);
  GameSpeed get speed {
    if (_speed != GameSpeed.paused && areAllResidentsAsleep()) {
      if (_residentsAsleepBehavior == 'lightning') return GameSpeed.lightning;
      if (_residentsAsleepBehavior == 'fast') return GameSpeed.fast;
    }
    return _speed;
  }

  String get combatControlMode => _combatControlMode;
  String get emergencyBehavior => _emergencyBehavior;
  String get residentsAsleepBehavior => _residentsAsleepBehavior;

  void setCombatControlMode(String val) {
    _combatControlMode = val;
    notifyListeners();
  }

  void setEmergencyBehavior(String val) {
    _emergencyBehavior = val;
    notifyListeners();
  }

  void setResidentsAsleepBehavior(String val) {
    _residentsAsleepBehavior = val;
    notifyListeners();
  }
  String get playerFirstName => _playerFirstName;
  String get playerLastName => _playerLastName;
  String get estateName => _estateName;
  GilesTrait get gilesTrait => _gilesTrait;
  List<Chicken> get chickens => List.unmodifiable(_chickens);
  DeathCause? get deathCause => _deathCause;
  List<String> get cookingQueue => List.unmodifiable(_cookingQueue);
  Set<String> get knownRecipes => Set.unmodifiable(_knownRecipes);

  void addKnownRecipe(String recipeId) {
    if (!_knownRecipes.contains(recipeId)) {
      _knownRecipes.add(recipeId);
      notifyListeners();
    }
  }

  List<String> get researchQueue => List.unmodifiable(_researchQueue);

  String? getFirstUnassignedRecipe() {
    for (var rId in _cookingQueue) {
      bool active = _taskService.activeTasks.any(
        (t) => t.type == TaskType.cook && t.recipeId == rId,
      );
      bool enqueued = _npcs.any(
        (n) => n.intentQueue.any(
          (i) => i.action == TaskType.cook && i.recipeId == rId,
        ),
      );
      if (!active && !enqueued) return rId;
    }
    return _cookingQueue.isEmpty ? null : _cookingQueue.first;
  }

  String? getFirstUnassignedResearch() {
    for (var qId in _researchQueue) {
      final researchId = qId.startsWith('activity:')
          ? qId.replaceFirst('activity:', '')
          : qId;
      bool active = _taskService.activeTasks.any(
        (t) =>
            (t.type == TaskType.research ||
                t.type == TaskType.study ||
                t.type == TaskType.experiment) &&
            (t.recipeId == researchId || t.recipeId == qId),
      );
      bool enqueued = _npcs.any(
        (n) => n.intentQueue.any(
          (i) =>
              (i.action == TaskType.research ||
                  i.action == TaskType.study ||
                  i.action == TaskType.experiment) &&
              (i.recipeId == researchId || i.recipeId == qId),
        ),
      );
      if (!active && !enqueued) return qId;
    }
    return _researchQueue.isEmpty ? null : _researchQueue.first;
  }

  String? getFirstUnassignedResearchForRoom(String roomId) {
    for (var qId in _researchQueue) {
      final researchId = qId.startsWith('activity:') ? qId.replaceFirst('activity:', '') : qId;
      bool isLab = researchId.startsWith('reanimation') || researchId.contains('vivisection') || researchId.contains('dissection') || researchId.contains('transmutation') || researchId.contains('lobotomy');
      bool isLibrary = researchId.contains('archive') || researchId.contains('catalog') || researchId.contains('transcribe');
      bool isStudy = !isLab && !isLibrary;

      if (roomId == 'laboratory' && !isLab) continue;
      if (roomId == 'library' && !isLibrary) continue;
      if (roomId == 'study' && !isStudy) continue;

      bool active = _taskService.activeTasks.any(
        (t) =>
            (t.type == TaskType.research ||
                t.type == TaskType.study ||
                t.type == TaskType.experiment) &&
            (t.recipeId == researchId || t.recipeId == qId),
      );
      bool enqueued = _npcs.any(
        (n) => n.intentQueue.any(
          (i) =>
              (i.action == TaskType.research ||
                  i.action == TaskType.study ||
                  i.action == TaskType.experiment) &&
              (i.recipeId == researchId || i.recipeId == qId),
        ),
      );
      if (!active && !enqueued) return qId;
    }
    return null;
  }

  void recordCombatVictory() {
    _customTaskCounts['combats_won'] = (_customTaskCounts['combats_won'] ?? 0) + 1;
    _checkObjectives();
    notifyListeners();
  }

  void interactWithSecretSociety(String factionName) {
    _customTaskCounts['secret_society_interactions'] = (_customTaskCounts['secret_society_interactions'] ?? 0) + 1;
    _lastAnnouncement = "Held formal diplomatic correspondence with the ${factionName.toUpperCase()}.";
    _announcementHistory.insert(0, "[${_currentDate.formattedTime}] DIPLOMACY: $_lastAnnouncement");
    _checkObjectives();
    notifyListeners();
  }

  List<Objective> get objectives => List.unmodifiable(_objectives);
  List<Contract> get contracts => List.unmodifiable(_contracts);
  List<String> get unlockedDiscoveries =>
      List.unmodifiable(_unlockedDiscoveries);
  LifeObjective get mainObjective => _mainObjective;
  String? get pendingNavigationTarget => _pendingNavigationTarget;
  bool get riverBridgeBuilt => _riverBridgeBuilt;

  void buildRiverBridge() {
    _riverBridgeBuilt = true;
    notifyListeners();
  }
  List<Dish> get pantry => List.unmodifiable(_pantry);
  int get unreadObjectiveCount => _unreadObjectiveCount;

  void addDishToPantry(Dish dish) {
    _pantry.add(dish);
    notifyListeners();
  }

  void addNpcForTesting(NPC npc) {
    _npcs.add(npc);
    notifyListeners();
  }

  void updateNpcForTesting(NPC npc) {
    final idx = _npcs.indexWhere((n) => n.id == npc.id);
    if (idx != -1) {
      _npcs[idx] = npc;
      notifyListeners();
    }
  }

  void forceSpawnDiner() {
    _spawnDiner();
  }

  void forceSpawnHotelGuest() {
    _spawnHotelGuest();
  }

  void clearUnreadObjectives() {
    if (_unreadObjectiveCount > 0) {
      _unreadObjectiveCount = 0;
      notifyListeners();
    }
  }

  ButlerDisposition get butlerDisposition => _butlerDisposition;
  bool get pendingCombatEncounter => _pendingCombatEncounter;
  EncounterData? get pendingEncounterData => _pendingEncounterData;
  List<NPC>? get pendingEncounterEnemies => _pendingEncounterEnemies;

  bool canPayEncounterDemands(Map<String, int> demands) {
    final player = _npcs.firstWhereOrNull((n) => n.isPlayer);
    if (player == null) return false;

    final travelingCompanions = _npcs.where((n) =>
        !n.isPlayer &&
        n.worldDestinationId == player.worldDestinationId &&
        n.worldDepartureId == player.worldDepartureId &&
        n.worldTravelProgress < 1.0).toList();

    for (var entry in demands.entries) {
      final resource = entry.key;
      int amountNeeded = entry.value;

      int playerHas = (player.journeyInventory[resource] ?? 0).round();
      amountNeeded -= playerHas;

      for (var companion in travelingCompanions) {
        if (amountNeeded <= 0) break;
        int compHas = (companion.journeyInventory[resource] ?? 0).round();
        amountNeeded -= compHas;
      }

      if (amountNeeded > 0) return false;
    }
    return true;
  }

  void resolveEncounterPayDemand(Map<String, int> demands) {
    // Find the traveling player party
    final player = _npcs.firstWhereOrNull((n) => n.isPlayer);
    if (player != null) {
      final travelingCompanions = _npcs.where((n) =>
          !n.isPlayer &&
          n.worldDestinationId == player.worldDestinationId &&
          n.worldDepartureId == player.worldDepartureId &&
          n.worldTravelProgress < 1.0).toList();

      for (var entry in demands.entries) {
        final resource = entry.key;
        int amountNeeded = entry.value;

        // Take from player first
        if (player.journeyInventory.containsKey(resource)) {
          int playerHas = (player.journeyInventory[resource] ?? 0).round();
          int take = min(playerHas, amountNeeded);
          player.journeyInventory[resource] = playerHas - take;
          amountNeeded -= take;
        }

        // Take from companions
        for (var companion in travelingCompanions) {
          if (amountNeeded <= 0) break;
          if (companion.journeyInventory.containsKey(resource)) {
            int compHas = (companion.journeyInventory[resource] ?? 0).round();
            int take = min(compHas, amountNeeded);
            companion.journeyInventory[resource] = compHas - take;
            amountNeeded -= take;
          }
        }
      }
    }
    clearEncounterState();
    _lastAnnouncement = "You successfully paid off the encounter.";
    _speed = GameSpeed.normal;
    notifyListeners();
  }

  bool resolveEncounterFlee() {
    // 50% chance to succeed
    if (Random().nextDouble() < 0.5) {
      clearEncounterState();
      _lastAnnouncement = "You narrowly escaped the encounter!";
      _speed = GameSpeed.normal;
      notifyListeners();
      return true;
    } else {
      _lastAnnouncement = "You failed to escape! They are attacking!";
      notifyListeners();
      return false;
    }
  }

  void clearEncounterState() {
    _pendingCombatEncounter = false;
    _pendingEncounterData = null;
    _pendingEncounterEnemies = null;
    _playerDistanceSinceEncounter = 0.0;
    _simulationPlayerDeck = null;
    _simulationAiDeck = null;
    _speed = GameSpeed.normal;
    notifyListeners();
  }

  void startCombatEncounter() {
    _pendingCombatEncounter = false;
    _simulationPlayerDeck = null;
    _simulationAiDeck = null;
    notifyListeners();
  }

  set pendingCombatEncounter(bool value) {
    _pendingCombatEncounter = value;
    if (value) {
      _speed = GameSpeed.paused; // Pause clock during combat encounter
    } else {
      // Resume speed when combat is over
      _speed = GameSpeed.normal;
    }
    notifyListeners();
  }

  set butlerDisposition(ButlerDisposition value) {
    _butlerDisposition = value;
    notifyListeners();
  }

  void _consumeScienceIngredients(Map<String, num> ingredients) {
    ingredients.forEach((ing, count) {
      for (int i = 0; i < count; i++) {
        _consumeSingleItem(ing);
      }
    });
  }

  bool _consumeSingleItem(String typeOrCategory) {
    for (int rIndex = 0; rIndex < _rooms.length; rIndex++) {
      var room = _rooms[rIndex];
      final itemIdx = room.inventory.indexWhere((item) {
        if (typeOrCategory == 'meat') return item.type.contains('meat');
        if (typeOrCategory == 'specimen') {
          return item.category == ItemCategory.specimen;
        }
        return item.type == typeOrCategory ||
            (typeOrCategory == 'funds' && item.type == 'franc');
      });
      if (itemIdx != -1) {
        final List<GameItem> newInv = List.from(room.inventory);
        if (newInv[itemIdx].quantity > 1) {
          newInv[itemIdx] = newInv[itemIdx].copyWith(
            quantity: newInv[itemIdx].quantity - 1,
          );
        } else {
          newInv.removeAt(itemIdx);
        }
        _rooms[rIndex] = room.copyWith(inventory: newInv);
        return true;
      }
    }
    return false;
  }

  void updateCategoryPriority(
    ResponsibilityCategory category,
    List<TaskType> tasks,
  ) {
    _categoryPriorities[category] = tasks;
    notifyListeners();
  }

  void updateCategoryDivider(ResponsibilityCategory category, int divider) {
    _categoryDividers[category] = divider;
    notifyListeners();
  }

  void clearPendingNavigation() {
    _pendingNavigationTarget = null;
    notifyListeners();
  }

  void setReservation(String id, bool reserved) {
    // Check NPCs
    final npcIdx = _npcs.indexWhere((n) => n.id == id);
    if (npcIdx != -1) {
      _npcs[npcIdx] = _npcs[npcIdx].copyWith(isReserved: reserved);
      notifyListeners();
      return;
    }

    // Check Chickens
    final chickenIdx = _chickens.indexWhere((c) => c.id == id);
    if (chickenIdx != -1) {
      _chickens[chickenIdx] = _chickens[chickenIdx].copyWith(
        isReserved: reserved,
      );
      notifyListeners();
      return;
    }

    // Check Inventory Items
    for (int rIndex = 0; rIndex < _rooms.length; rIndex++) {
      var room = _rooms[rIndex];
      final itemIdx = room.inventory.indexWhere((i) => i.id == id);
      if (itemIdx != -1) {
        final List<GameItem> newInv = List.from(room.inventory);
        final meta = Map<String, dynamic>.from(newInv[itemIdx].metadata);
        meta['isReserved'] = reserved;
        newInv[itemIdx] = newInv[itemIdx].copyWith(metadata: meta);
        _rooms[rIndex] = room.copyWith(inventory: newInv);
        notifyListeners();
        return;
      }
    }
  }

  void addToCookingQueue(
    String recipeId, {
    String? targetId,
    String? targetName,
  }) {
    String entry = recipeId;
    if (targetId != null) {
      entry = '$recipeId:$targetId:$targetName';
      setReservation(targetId, true);
    }
    _cookingQueue.add(entry);
    if (_gilesTutorialStep == GilesTutorialStep.commencePrep) {
      advanceGilesTutorial(GilesTutorialStep.assignResident);
    }
    notifyListeners();
  }

  void removeFromCookingQueue(int index) {
    if (index >= 0 && index < _cookingQueue.length) {
      final entry = _cookingQueue.removeAt(index);
      if (entry.contains(':')) {
        final parts = entry.split(':');
        setReservation(parts[1], false);
      }
      notifyListeners();
    }
  }

  void addResearchToQueue(String itemId, {List<String>? reservedEntityIds}) {
    String entry = itemId;
    if (reservedEntityIds != null && reservedEntityIds.isNotEmpty) {
      entry = '$itemId:${reservedEntityIds.join(",")}';
      for (var id in reservedEntityIds) {
        setReservation(id, true);
      }
    } else if (inventory.any((i) => i.id == itemId)) {
      // Auto-reserve if it's a specific item from inventory
      setReservation(itemId, true);
    }

    if (!_researchQueue.contains(entry)) {
      _researchQueue.add(entry);
      final item = inventory.firstWhereOrNull((i) => i.id == itemId);
      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] Enqueued ${item?.name.toUpperCase() ?? itemId.toUpperCase()} for research.",
      );
      notifyListeners();
    }
  }

  void addScienceActivityToQueue(
    String activityId, {
    List<String>? reservedEntityIds,
  }) {
    String entry = 'activity:$activityId';
    if (reservedEntityIds != null && reservedEntityIds.isNotEmpty) {
      entry = '$entry:${reservedEntityIds.join(",")}';
      for (var id in reservedEntityIds) {
        setReservation(id, true);
      }
    }

    if (!_researchQueue.contains(entry)) {
      _researchQueue.add(entry);
      final activity = ScienceService.getActivityById(activityId);
      if (activity != null) {
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] Enqueued ${activity.name.toUpperCase()} for study.",
        );
      }
      notifyListeners();
    }
  }

  void addExperimentalRecipeToQueue(
    String recipeId, {
    List<String>? reservedEntityIds,
  }) {
    String entry = 'recipe:$recipeId';
    if (reservedEntityIds != null && reservedEntityIds.isNotEmpty) {
      entry = '$entry:${reservedEntityIds.join(",")}';
      for (var id in reservedEntityIds) {
        setReservation(id, true);
      }
    }

    if (!_researchQueue.contains(entry)) {
      _researchQueue.add(entry);
      final recipes = KitchenService.getAvailableRecipes();
      final recipe = recipes.cast<Recipe?>().firstWhere(
        (r) => r?.id == recipeId,
        orElse: () => null,
      );
      if (recipe != null) {
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] Enqueued ${recipe.name.toUpperCase()} for examination.",
        );
      }
      notifyListeners();
    }
  }

  void removeResearchFromQueue(int index) {
    if (index >= 0 && index < _researchQueue.length) {
      final entry = _researchQueue.removeAt(index);
      if (entry.contains(':')) {
        final parts = entry.split(':');
        // If it starts with 'activity:' or 'recipe:', IDs are in parts[2]
        if (parts[0] == 'activity' || parts[0] == 'recipe') {
          if (parts.length > 2) {
            final ids = parts[2].split(',');
            for (var id in ids) {
              setReservation(id, false);
            }
          }
        } else {
          // Fallback legacy format or other type: Parts[1] is ID
          setReservation(parts[1], false);
        }
      } else {
        // Simple item ID
        setReservation(entry, false);
      }
      notifyListeners();
    }
  }

  void updateResource(String resource, num amount) {
    if (resource == 'shepherds_pie') {
      if (amount > 0) {
        for (int i = 0; i < amount; i++) {
          _pantry.add(
            Dish(
              id: const Uuid().v4(),
              name: "Shepherd's Pie",
              type: DishType.protein,
              quality: DishQuality.decent,
              cookedAt: _currentDate.copy(),
              shelfLifeHours: 240, // 10 days
            ),
          );
        }
      } else {
        int count = (-amount).toInt();
        for (int i = 0; i < count; i++) {
          if (_pantry.isNotEmpty) {
            _pantry.removeAt(0);
          }
        }
      }
      notifyListeners();
      return;
    }

    if (amount > 0) {
      _addPhysicalResource(resource, amount.toInt());
    } else {
      int count = (-amount).toInt();
      for (int i = 0; i < count; i++) {
        _consumeSingleItem(resource);
      }
    }
    notifyListeners();
  }

  void _clearResource(String resource) {
    for (int rIndex = 0; rIndex < _rooms.length; rIndex++) {
      var room = _rooms[rIndex];
      final List<GameItem> newInv = room.inventory
          .where(
            (item) =>
                item.type != resource &&
                (resource != 'funds' || item.type != 'franc'),
          )
          .toList();
      if (newInv.length != room.inventory.length) {
        _rooms[rIndex] = room.copyWith(inventory: newInv);
      }
    }
  }

  void _removePhysicalItem(String itemId) {
    for (int r = 0; r < _rooms.length; r++) {
      var idx = _rooms[r].inventory.indexWhere((i) => i.id == itemId);
      if (idx != -1) {
        final newInv = List<GameItem>.from(_rooms[r].inventory);
        newInv.removeAt(idx);
        _rooms[r] = _rooms[r].copyWith(inventory: newInv);
        notifyListeners();
        return;
      }
    }
  }

  void _addPhysicalItem(GameItem item) {
    String roomId = 'workshop';
    if (item.category == ItemCategory.food ||
        item.type.contains('meat') ||
        item.type.contains('egg')) {
      roomId = 'kitchen';
    } else if (item.category == ItemCategory.knowledge) {
      roomId = 'library';
    } else if (item.category == ItemCategory.resource || item.type == 'franc') {
      roomId = 'study';
    }

    if (_rooms.indexWhere((r) => r.id == roomId) == -1) return;
    addItemToRoom(roomId, item);
  }

  void _addPhysicalResource(String type, int amount) {
    String roomId = 'toolshed';
    ItemCategory cat = ItemCategory.material;
    String name = type.toUpperCase();

    if (type == 'funds' || type == 'franc') {
      roomId = 'study';
      cat = ItemCategory.resource;
      name = 'Franc';
      type = 'franc';
    } else if (type.contains('meat') ||
        type == 'cabbage' ||
        type.contains('flour') ||
        type == 'rice' ||
        type.contains('beans') ||
        type == 'milk' ||
        type == 'salt' ||
        type == 'pepper' ||
        type == 'potato' ||
        type == 'carrots' ||
        type == 'beets' ||
        type == 'yeast' ||
        type == 'sugar' ||
        type == 'chocolate' ||
        type == 'coffee' ||
        type == 'eggs') {
      roomId = 'kitchen';
      cat = ItemCategory.food;
    } else if (type.contains('seeds')) {
      roomId = 'toolshed';
    }

    if (_rooms.indexWhere((r) => r.id == roomId) == -1) return;

    // Based on user feedback: currency and commodities act as quantitative stacks, not individual instantiated memory objects!
    addItemToRoom(
      roomId,
      GameItem.create(
        name: name,
        type: type,
        category: cat,
        quantity: amount,
        creationDate: _currentDate.copy(),
        metadata: {
          'addedAt': DateTime.now().toIso8601String(),
          'shelfLifeDays': type.contains('egg') ? 30 : 10,
        },
      ),
    );
  }

  void addResources(Map<String, num> resources) {
    resources.forEach((key, value) {
      updateResource(key, value);
    });
  }

  void addItemToRoom(String roomId, GameItem item) {
    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index != -1) {
      final List<GameItem> newInv = List.from(_rooms[index].inventory);

      final bool isCommodity =
          item.category == ItemCategory.material ||
          item.category == ItemCategory.resource ||
          item.category == ItemCategory.food ||
          item.category == ItemCategory.medical ||
          item.category == ItemCategory.specimen;

      if (isCommodity) {
        final FreshnessState incomingFreshness = item.getFreshnessState(
          _currentDate,
        );

        final int existingIndex = newInv.indexWhere((i) {
          if (i.type != item.type || i.displayQuality != item.displayQuality) {
            return false;
          }
          final existingFreshness = i.getFreshnessState(_currentDate);
          return existingFreshness == incomingFreshness;
        });

        if (existingIndex >= 0) {
          final existingItem = newInv[existingIndex];
          GameDate? olderDate = existingItem.creationDate;

          if (item.creationDate != null) {
            if (olderDate == null ||
                item.creationDate!.totalMinutes < olderDate.totalMinutes) {
              olderDate = item.creationDate;
            }
          }

          newInv[existingIndex] = newInv[existingIndex].copyWith(
            quantity: newInv[existingIndex].quantity + item.quantity,
            creationDate: olderDate,
            metadata: Map<String, dynamic>.from(existingItem.metadata)
              ..addAll(item.metadata),
          );
        } else {
          newInv.add(item);
        }
      } else {
        newInv.add(item);
      }

      _rooms[index] = _rooms[index].copyWith(inventory: newInv);
      notifyListeners();
    }
  }

  void completeTaskManually(String npcId, GameTask task) {
    final index = _npcs.indexWhere((n) => n.id == npcId);
    if (index != -1) {
      _handleTaskCompletion(task);
    }
  }

  void updateNpc(NPC updatedNpc) {
    final index = _npcs.indexWhere((n) => n.id == updatedNpc.id);
    if (index != -1) {
      _npcs[index] = updatedNpc;
      notifyListeners();
    }
  }

  void updateRoom(Room updatedRoom) {
    final index = _rooms.indexWhere((r) => r.id == updatedRoom.id);
    if (index != -1) {
      _rooms[index] = updatedRoom;
      notifyListeners();
    }
  }

  void updateCrop(Crop updatedCrop) {
    final index = _crops.indexWhere((c) => c.id == updatedCrop.id);
    if (index != -1) {
      _crops[index] = updatedCrop;
      notifyListeners();
    }
  }

  void setResource(String id, num amount) {
    _clearResource(id);
    if (amount > 0) {
      _addPhysicalResource(id, amount.toInt());
    }
    notifyListeners();
  }

  void markObjectivesRead() {
    _unreadObjectiveCount = 0;
    notifyListeners();
  }

  void initializeNewGame({
    required String firstName,
    required String lastName,
    required String estateName,
    required DeathCause deathCause,
    required int age,
    required GilesTrait gilesTrait,
    required LifeObjective objective,
  }) {
    _playerFirstName = firstName;
    _playerLastName = lastName;
    _estateName = estateName;
    _deathCause = deathCause;
    _playerAge = age;
    _gilesTrait = gilesTrait;
    _mainObjective = objective;
    if (gilesTrait == GilesTrait.sage) {
      _gilesTutorialStep = GilesTutorialStep.intro;
    } else {
      _gilesTutorialStep = GilesTutorialStep.inactive;
    }
    _completedTaskTypes.clear();
    _speed = GameSpeed.paused;

    _rooms.clear();
    _npcs.clear();
    _activeExperiments.clear();
    _activeConstruction.clear();
    _researchPoints.clear();
    final Map<String, num> initialResources = {
      'funds': 100,
      'wood': 50,
      'meat': 5,
      'cabbage': 5,
      'eggs': 10,
      'dirty_dishes': 0,
      'flour_spelt': 15,
      'flour_durum': 15,
      'rice': 10,
      'green_beans': 10,
      'faba_beans': 10,
      'cattle_carcass': 1,
      'meat_beef': 15,
      'meat_chicken': 15,
      'milk': 5,
      'salt': 100,
      'pepper': 30,
      'potato': 10,
      'carrots': 10,
      'beets': 10,
      'yeast': 5,
      'sugar': 5,
      'chocolate': 2,
      'coffee': 2,
      'seeds_cabbage': 10,
      'seeds_potato': 10,
      'seeds_carrot': 10,
      'grain': 30,
    };

    // 5 days of prepared meals for Giles and Frankenstein (30 meals total)
    // Spoil in 4 days (96 hours)
    _pantry.clear();
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      _pantry.add(
        Dish(
          id: const Uuid().v4(),
          name: i % 2 == 0 ? 'Beef & Root Stew' : 'Spelt Bread',
          type: i % 2 == 0 ? DishType.protein : DishType.cereal,
          quality: DishQuality.decent,
          cookedAt: _currentDate.copy(),
          shelfLifeHours: i % 2 == 0 ? 168 : 336, // 7 days vs 14 days
        ),
      );
    }

    // 2 weeks of raw materials for both to survive
    // Spoil in 10 days
    final List<Map<String, dynamic>> rawMaterials = [
      {'name': 'Beef Meat', 'type': 'meat_beef', 'qty': 20},
      {'name': 'Chicken Meat', 'type': 'meat_chicken', 'qty': 20},
      {'name': 'Fresh Vegetables', 'type': 'vegetables', 'qty': 40},
      {'name': 'Grains', 'type': 'grain', 'qty': 30},
    ];

    _initializeManor();

    // Now that rooms are created, distribute starting physical items.
    addResources(initialResources);
    for (var mat in rawMaterials) {
      if (_rooms.indexWhere((r) => r.id == 'kitchen') != -1) {
        addItemToRoom(
          'kitchen',
          GameItem.create(
            name: mat['name'],
            type: mat['type'],
            category: ItemCategory.food,
            quantity: mat['qty'],
            metadata: {'addedAt': now.toIso8601String(), 'shelfLifeDays': 10},
          ),
        );
      }
    }

    _initializeStartingCharacters();
    _initializeObjectives();
    notifyListeners();
  }

  void _initializeManor() {
    // 1. Transit & Fields
    _rooms.add(
      Room(
        id: 'road',
        name: 'Road',
        type: RoomType.unused,
        isRestored: true,
        floor: Floor.ground,
        description: 'The approach to the house.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'vegetable_garden',
        name: 'Garden',
        type: RoomType.garden,
        isRestored: true,
        floor: Floor.ground,
        description: 'A well-maintained garden for vegetables.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'field_2',
        name: 'Field A',
        type: RoomType.field,
        isRestored: true,
        floor: Floor.ground,
        description: 'A quiet stretch of arable land, ready for the plow.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'field_3',
        name: 'Field B',
        type: RoomType.field,
        isRestored: true,
        floor: Floor.ground,
        description: 'A quiet stretch of arable land, ready for the plow.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'field_4',
        name: 'Field C',
        type: RoomType.field,
        isRestored: true,
        floor: Floor.ground,
        description: 'A quiet stretch of arable land, ready for the plow.',
        width: 2.0,
      ),
    );

    // 2. Main Floor (Floor 0)
    _rooms.add(
      Room(
        id: 'entryway',
        name: 'Entry',
        type: RoomType.entryway,
        isRestored: true,
        floor: Floor.ground,
        description: 'The main entrance to the manor.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'kitchen',
        name: 'Kitchen',
        type: RoomType.kitchen,
        isRestored: true,
        floor: Floor.ground,
        description: 'The heart of the manor.',
        width: 3.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'dining_hall',
        name: 'Dining',
        type: RoomType.diningRoom,
        isRestored: true,
        floor: Floor.ground,
        description: 'A grand space for meals.',
        width: 3.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'bathroom_down',
        name: 'Toilet',
        type: RoomType.toilet,
        isRestored: true,
        floor: Floor.ground,
        description: 'A small, clean washroom.',
        width: 1.5,
      ),
    );
    _rooms.add(
      Room(
        id: 'unused_1f',
        name: 'Unused',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.ground,
        description: 'A dusty, forgotten section.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'butler_quarters',
        name: "Butler",
        type: RoomType.butlerQuarters,
        isRestored: true,
        floor: Floor.ground, // Placed on ground per ManorLayout
        description: 'Private quarters for the butler.',
        width: 2.0,
        beds: [
          Bed(type: BedType.twin, assignedNpcIds: ['butler']),
        ],
      ),
    );

    // 3. 2nd Story (Floor 1)
    _rooms.add(
      Room(
        id: 'master_bedroom',
        name: 'Master Bedroom',
        type: RoomType.bedroom,
        isRestored: true,
        floor: Floor.second,
        description: 'The opulent quarters of the manor\'s master.',
        width: 1.0,
        beds: [
          Bed(type: BedType.king, assignedNpcIds: ['player', null]),
        ],
      ),
    );
    _rooms.add(
      Room(
        id: 'bedroom_2',
        name: 'Junior Bedroom',
        type: RoomType.bedroom,
        isRestored: true,
        floor: Floor.second,
        description: 'A comfortable room for family or high-status guests.',
        width: 1.0,
        beds: [
          Bed(type: BedType.queen, assignedNpcIds: [null, null]),
        ],
      ),
    );
    _rooms.add(
      Room(
        id: 'bedroom_3',
        name: 'Guest Room',
        type: RoomType.bedroom,
        isRestored: true,
        floor: Floor.second,
        description: 'A simple room with two twin beds.',
        width: 1.0,
        beds: [
          Bed(type: BedType.twin, assignedNpcIds: [null]),
          Bed(type: BedType.twin, assignedNpcIds: [null]),
        ],
      ),
    );
    _rooms.add(
      Room(
        id: 'bathroom_up',
        name: 'Washroom',
        type: RoomType.toilet,
        isRestored: true,
        floor: Floor.second,
        description: 'A pristine upstairs washroom.',
        width: 1.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'study',
        name: 'Study',
        type: RoomType.study,
        isRestored: true,
        floor: Floor.second,
        description: 'A quiet place for work.',
        width: 1.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'library',
        name: 'Library',
        type: RoomType.library,
        isRestored: false,
        floor: Floor.second,
        description: 'A vast, dusty collection of books.',
        width: 1.0,
      ),
    );

    // 4. Attic (Floor 2)
    _rooms.add(
      Room(
        id: 'attic_1',
        name: 'East Attic',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.attic,
        description: 'Empty space for future installations.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'attic_2',
        name: 'West Attic',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.attic,
        description: 'Empty space for future installations.',
        width: 2.0,
      ),
    );

    // 5. Basement (Floor -1 to -4)
    _rooms.add(
      Room(
        id: 'basement_1',
        name: 'Basement A',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'Subterranean storage.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'basement_2',
        name: 'Basement B',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'Cold storage in the dark.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'basement_3',
        name: 'Basement C',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'Quiet subterranean vaults.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'basement_d',
        name: 'Excavation Node',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'A remote forgotten vault.',
        width: 2.0,
      ),
    );

    // Level -2
    _rooms.add(
      Room(
        id: 'basement_e',
        name: 'Excavation Node',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'Deep earthen enclosure.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'basement_f',
        name: 'Excavation Node',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'Deep earthen enclosure.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'basement_g',
        name: 'Excavation Node',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'Deep earthen enclosure.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'basement_h',
        name: 'Excavation Node',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'Deep earthen enclosure.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'basement_i',
        name: 'Excavation Node',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'Deep earthen enclosure.',
        width: 2.0,
      ),
    );

    // Level -3
    _rooms.add(
      Room(
        id: 'basement_j',
        name: 'Excavation Node',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'Silted forgotten tunnel.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'basement_k',
        name: 'Excavation Node',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'Silted forgotten tunnel.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'basement_l',
        name: 'Excavation Node',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'Silted forgotten tunnel.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'basement_m',
        name: 'Excavation Node',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'Silted forgotten tunnel.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'basement_n',
        name: 'Excavation Node',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'Silted forgotten tunnel.',
        width: 2.0,
      ),
    );

    // Level -4
    _rooms.add(
      Room(
        id: 'basement_o',
        name: 'Excavation Node',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'Ancient rocky cavity.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'basement_p',
        name: 'Excavation Node',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'Ancient rocky cavity.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'basement_q',
        name: 'Excavation Node',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'Ancient rocky cavity.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'basement_r',
        name: 'Excavation Node',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'Ancient rocky cavity.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'basement_s',
        name: 'Excavation Node',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'Ancient rocky cavity.',
        width: 2.0,
      ),
    );

    // 6. External
    _rooms.add(
      Room(
        id: 'chicken_coop',
        name: 'Chicken Coop',
        type: RoomType.chickenCoop,
        isRestored: false,
        floor: Floor.ground,
        description: 'Dilapidated poultry housing.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'toolshed',
        name: 'Tool Shed',
        type: RoomType.unused,
        isRestored: true,
        floor: Floor.ground,
        description: 'A small outbuilding for equipment.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'lot_garden',
        name: 'Garden Lot',
        type: RoomType.unused,
        isRestored: true,
        floor: Floor.ground,
        description: 'External space for planting.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'lot_building_1',
        name: 'Empty Lot',
        type: RoomType.unused,
        isRestored: true,
        floor: Floor.ground,
        description: 'Space for an external building.',
        width: 2.0,
      ),
    );
    _initializeBasementResources();
  }

  void _initializeStartingCharacters() {
    final playerBioRes = NPCGenerator.generateBiographyForCharacter(
      role: 'Master',
      age: _playerAge,
      currentDate: _currentDate,
      gender: 'Male',
    );

    final Map<String, int> basePlayerStats = {
      'strength': 3,
      'endurance': 3,
      'adaptability': 3,
      'dexterity': 3,
      'intellect': 5,
      'perception': 4,
      'judgment': 3,
      'temperament': 3,
      'leadership': 3,
      'courage': 3,
      'hygiene': 4,
      'beauty': 2,
      'morality': 4,
      'walkSpeed': 30,
    };

    for (var entry in playerBioRes.statModifiers.entries) {
      if (basePlayerStats.containsKey(entry.key)) {
        basePlayerStats[entry.key] = (basePlayerStats[entry.key]! + entry.value)
            .clamp(0, 10);
      }
    }

    final playerTraits = [
      NPCTrait(id: 'loyal', name: 'Loyal', group: 'character'),
    ];
    playerTraits.addAll(playerBioRes.traitsToAdd);

    final playerProficiencies = {'Research': 10.0, 'Accounting': 10.0};
    for (var entry in playerBioRes.proficienciesToAdd.entries) {
      playerProficiencies[entry.key] =
          (playerProficiencies[entry.key] ?? 0.0) + entry.value;
    }

    final player = NPC(
      id: 'player',
      name: '$_playerFirstName $_playerLastName',
      specimenType: 'Human',
      role: 'Master',
      isPlayer: true,
      age: _playerAge,
      birthDate: playerBioRes.biography.birthDate,
      gender: 'Male',
      group: NPCOrgGroup.A,
      stats: basePlayerStats,
      traits: playerTraits,
      proficiencies: playerProficiencies,
      biography: playerBioRes.biography,
      bio: playerBioRes.biography.toParagraph(),
      hometown: playerBioRes.biography.placeOfBirth,
      background: playerBioRes.biography.characterClass,
      bodyParts: [
        BodyPart(type: BodyPartType.head, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.torso, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.rightArm, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.leftArm, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.rightLeg, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.leftLeg, health: 100, maxHealth: 100),
      ],
      schedule: NPCSchedule.defaultButler(),
      diet: NPCDiet.defaultDiet(),
      currentRoomId: 'entryway',
      assignedRoomId: 'master_bedroom',
      appearance: NPCAppearance.defaultMaster(),
      responsibilities: {
        ResponsibilityCategory.medical: 1,
        ResponsibilityCategory.cooking: 1,
        ResponsibilityCategory.farming: 2,
        ResponsibilityCategory.crafting: 2,
        ResponsibilityCategory.research: 2,
      },
      relationships: {
        'butler': Relationship(
          admiration: 3.5,
          respect: 1.5,
          fear: 2.0,
          attraction: 1.2,
        ),
      },
    );

    final butlerBioRes = NPCGenerator.generateBiographyForCharacter(
      role: 'Butler',
      age: 55,
      currentDate: _currentDate,
      gender: 'Male',
    );

    final Map<String, int> baseButlerStats = {
      'strength': 4,
      'endurance': 5,
      'adaptability': 3,
      'dexterity': 3,
      'intellect': 3,
      'perception': 3,
      'judgment': 3,
      'temperament': 5,
      'leadership': 3,
      'courage': 4,
      'hygiene': 5,
      'beauty': 1,
      'morality': 6,
      'walkSpeed': 25,
    };

    for (var entry in butlerBioRes.statModifiers.entries) {
      if (baseButlerStats.containsKey(entry.key)) {
        baseButlerStats[entry.key] = (baseButlerStats[entry.key]! + entry.value)
            .clamp(0, 10);
      }
    }

    final butlerTraits = [
      NPCTrait(id: 'loyal', name: 'Loyal', group: 'character'),
      NPCTrait(id: 'hardworking', name: 'Hardworking', group: 'character'),
      NPCTrait(
        id: 'proficiency_Cleaning_2',
        name: 'Adept Cleaning',
        group: 'skill',
      ),
      NPCTrait(
        id: 'proficiency_Cooking_1',
        name: 'Novice Cooking',
        group: 'skill',
      ),
    ];
    butlerTraits.addAll(butlerBioRes.traitsToAdd);

    final butlerProficiencies = {
      'Cleaning': 20.0,
      'Cooking': 0.0,
      'Accounting': 20.0,
    };
    for (var entry in butlerBioRes.proficienciesToAdd.entries) {
      butlerProficiencies[entry.key] =
          (butlerProficiencies[entry.key] ?? 0.0) + entry.value;
    }

    final butler = CombatUnitFactory.createFlaubert().copyWith(
      stats: baseButlerStats,
      traits: butlerTraits,
      proficiencies: butlerProficiencies,
      biography: butlerBioRes.biography,
      bio: butlerBioRes.biography.toParagraph(),
      birthDate: butlerBioRes.biography.birthDate,
      hometown: butlerBioRes.biography.placeOfBirth,
      background: butlerBioRes.biography.characterClass,
      appearance: NPCAppearance.defaultButler(),
      responsibilities: {
        ResponsibilityCategory.cleaning: 3,
        ResponsibilityCategory.cooking: 2,
        ResponsibilityCategory.labor: 2,
      },
      relationships: {
        'player': Relationship(
          admiration: 3.0,
          respect: 3.0,
          fear: 3.5,
          attraction: 2.0,
        ),
      },
    );

    _npcs.add(player);
    _npcs.add(butler);

    // Initialize 5 individual Foxes
    for (int i = 0; i < 5; i++) {
      final fox = FoxGenerator.createFox(
        "fox_${i}_${DateTime.now().millisecondsSinceEpoch}",
        _currentDate,
      );
      _npcs.add(fox.copyWith(isResident: false));
    }

    // Initial Garden Plants
    for (int i = 0; i < 4; i++) {
      _gardenPlants.add(
        Plant.create(
          PlantType.fabaBean,
          'vegetable_garden',
          _currentDate.month,
          _currentDate.year,
          i,
        ),
      );
    }
    for (int i = 0; i < 6; i++) {
      _gardenPlants.add(
        Plant.create(
          PlantType.greenBean,
          'vegetable_garden',
          _currentDate.month,
          _currentDate.year,
          i + 4,
        ),
      );
    }

    // Initial Combat Unit Pool - Giles is already added as the butler.
    // If we add more units to the initial deck later, we should filter out duplicates here.
    _butlerRoomId = 'butler_quarters';
    _checkForTodayBirthday();
  }

  bool _isTicking = false;

  void tick() {
    if (_isTicking || _speed == GameSpeed.paused) return;
    _isTicking = true;

    try {
      // _processDishes();
      _processSpoilage();

      _processDiscreteSocialEvents();
      _processStatusEffectsTick();
      _processRealtimeRestaurant();

      // Tick the alchemical smoker
      if (_smokerItem != null) {
        _smokerMinutesRemaining--;
        if (_smokerMinutesRemaining <= 0) {
          unloadSmoker();
        } else {
          double totalDuration = _smokerItem == 'smoked_meat'
              ? 120.0
              : (_smokerItem == 'smoked_sausage' ? 180.0 : 90.0);
          _smokerProgress = (1.0 - (_smokerMinutesRemaining / totalDuration))
              .clamp(0.0, 1.0);
        }
      }

      if (_dentalCriticReviewState != null &&
          _currentDate.totalMinutes >= _dentalCriticReviewTriggerTime) {
        _triggerDentalCriticReviewAnnouncement();
      }

      if (_dentalMalpracticePending &&
          _currentDate.totalMinutes >= _dentalMalpracticeTriggerTime) {
        _triggerDentalMalpracticeEvent();
      }

      if (_currentDate.hour == 23 &&
          _currentDate.minute == 59 &&
          (_currentDate.day % 7 == 0)) {
        _processWeeklyBusinessProfits();
      }

      if (_currentDate.minute == 0) {
        _processHourlyRelationshipEvolution();
      }

      if (_currentDate.day == 1 && _currentDate.hour == 8 && _currentDate.minute == 0) {
        // Monthly Salary Collection for Employees
        for (var contract in _contracts) {
          if (contract.isActive && contract.type == ContractType.employment) {
            final npcIdx = _npcs.indexWhere((n) => n.id == contract.npcId && n.isResident && n.worldDestinationId == null);
            if (npcIdx != -1) {
              final npc = _npcs[npcIdx];
              var mutableQueue = List<NPCIntent>.from(npc.intentQueue);
              if (!mutableQueue.any((i) => i.id == 'salary_collection_${npc.id}')) {
                mutableQueue.add(
                  NPCIntent(
                    id: 'salary_collection_${npc.id}',
                    action: TaskType.collectPayment,
                    targetRoomId: 'study', // Collecting wages in the Study
                    priority: IntentPriority.high,
                    expectedDurationMin: 2,
                  ),
                );
                _npcs[npcIdx] = npc.copyWith(intentQueue: mutableQueue);
              }
            }
          }
        }
      }

      // History and Byproduct Logic (once per day or hour)
      if (_currentDate.hour == 23 && _currentDate.minute == 59) {
        // Daily Random Events (e.g., Twice a year lightning/candle fire)
        if (Random().nextDouble() < (2.0 / 365.0)) {
          // roughly twice a year
          // Pick a random room
          final possibleRooms = _rooms.where((r) => r.isRestored).toList();
          if (possibleRooms.isNotEmpty) {
            _triggerManorFire(
              possibleRooms[Random().nextInt(possibleRooms.length)].id,
            );
          }
        }

        _processNuisanceRelativeDrain();
        _processLineageQuests();
        _checkForTodayBirthday();



        // End of day: update chicken histories
        for (int i = 0; i < _chickens.length; i++) {
          final chicken = _chickens[i];
          final List<int> newHistory = List.from(chicken.eggProductionHistory);
          newHistory.add(chicken.eggsLaid);
          _chickens[i] = chicken.copyWith(eggProductionHistory: newHistory);
        }

        // Daily Egg Production
        bool hasRooster = _chickens.any(
          (c) => c.isMale && c.isMature(_currentDate),
        );

        int totalEggsLaid = 0;
        for (int i = _chickens.length - 1; i >= 0; i--) {
          var chicken = _chickens[i];
          if (chicken.isMale || !chicken.isMature(_currentDate)) continue;

          bool isWarmSeason =
              _currentDate.month >= 3 && _currentDate.month <= 8;
          int eggsLaidToday = 0;
          double roll = Random().nextDouble();

          if (isWarmSeason) {
            if (roll < 0.20) {
              eggsLaidToday = 0;
            } else if (roll < 0.50) {
              eggsLaidToday = 1;
            } else {
              eggsLaidToday = 2;
            }
          } else {
            if (roll < 0.30) {
              eggsLaidToday = 0;
            } else if (roll < 0.90) {
              eggsLaidToday = 1;
            } else {
              eggsLaidToday = 2;
            }
          }

          if (eggsLaidToday > 0) {
            totalEggsLaid += eggsLaidToday;
            for (int j = 0; j < eggsLaidToday; j++) {
              bool eggIsFertilized = hasRooster && Random().nextDouble() < 0.10;
              final egg = GameItem.create(
                name: eggIsFertilized ? 'Fertilized Egg' : 'Egg',
                type: eggIsFertilized ? 'fertilized_egg' : 'eggs',
                category: eggIsFertilized
                    ? ItemCategory.specimen
                    : ItemCategory.food,
                creationDate: _currentDate.copy(),
              );
              addItemToRoom('chicken_coop', egg);
            }

            chicken = chicken.copyWith(
              eggsLaid: chicken.eggsLaid + eggsLaidToday,
              lastEggDate: _currentDate,
            );
          }
          _chickens[i] = chicken;
        }

        if (totalEggsLaid > 0) {
          notifyRoomProduction('chicken_coop', '+$totalEggsLaid');
        }
      }

      if (_currentDate.minute == 0) {
        // Hourly byproduct check
        _processLivestockByproducts();
        _checkAndProcessBirthdays();
        if (_currentDate.hour == 0) {
          _processMerchantLoanDailyTick();
        }
      }

      _currentDate = _currentDate.addMinute();

      // Identify NPCs that are either not moving or are already at their task's target room
      final readyNpcIds = _npcs
          .where((n) {
            // If they have a target and haven't arrived, they are definitely not ready
            if (n.targetRoomId != null && n.targetRoomId != n.currentRoomId) {
              return false;
            }
            if (n.movementProgress < 1.0 && n.targetRoomId != n.currentRoomId) {
              return false;
            }

            // Check if NPC is in the correct room for their current active task
            if (n.activeTaskId != null) {
              GameTask? task;
              for (var t in _taskService.activeTasks) {
                if (t.id == n.activeTaskId) {
                  task = t;
                  break;
                }
              }

              if (task != null &&
                  task.targetId != null) {
                final String targetId = task.targetId!;
                if (_rooms.any((r) => r.id == targetId) &&
                    targetId != n.currentRoomId) {
                  return false;
                }
              }
            }
            return true;
          })
          .map((n) => n.id)
          .toList();
      // Identify active task IDs for filtering in TaskService
      final activeTaskIds = _npcs
          .where((n) => n.activeTaskId != null)
          .map((n) => n.activeTaskId!)
          .toSet();

      // Process Tasks only for arrived NPCs and their active task
      final completedTasks = _taskService.processTick(
        readyNpcIds,
        activeTaskIds,
        (npcId) {
          final npc = _npcs.firstWhere((n) => n.id == npcId);
          return npc.stats;
        },
      );

      // [FIX] Consolidate Sync: Update NPCs with latest Task Progress FIRST
      for (int i = 0; i < _npcs.length; i++) {
        var npc = _npcs[i];
        if (npc.activeTaskId != null) {
          final task = _taskService.activeTasks.firstWhereOrNull(
            (t) => t.id == npc.activeTaskId,
          );
          if (task != null) {
            // Sync to NPC Intent
            final intentIndex = npc.intentQueue.indexWhere(
              (it) => it.id == task.intentId,
            );
            if (intentIndex != -1) {
              final updatedIntent = npc.intentQueue[intentIndex].copyWith(
                minutesRemaining: task.minutesRemaining,
              );
              List<NPCIntent> newQueue = List.from(npc.intentQueue);
              newQueue[intentIndex] = updatedIntent;
              _npcs[i] = npc.copyWith(intentQueue: newQueue);
              npc = _npcs[i];

              // Experience is granted upon task completion in _handleTaskCompletion
              if (readyNpcIds.contains(npc.id)) {
                final proficiencyName = TaskService.getProficiency(task.type);

                if (TaskService.isPhysicallyStrenuous(task.type)) {

                  // Workplace injury check
                  final npcRef = _npcs[i];
                  final profLevel =
                      npcRef.metadata['proficiency_level_$proficiencyName']
                          as int? ??
                      0;
                  final str = npcRef.stats['strength'] ?? 3;
                  final end = npcRef.stats['endurance'] ?? 3;

                  // Base chance per minute 0.1%. Decreases with stats and proficiency.
                  // At proficiency level 5 and str/end 5, chance is near 0.
                  final risk =
                      0.001 *
                      (1.0 - (profLevel / 10.0)).clamp(0.1, 1.0) *
                      (1.0 - ((str + end) / 20.0)).clamp(0.1, 1.0);

                  if (risk > 0 && Random().nextDouble() < risk) {
                    // INJURY
                    _announcementHistory.insert(
                      0,
                      "[${_currentDate.formattedTime}] INJURY: ${npcRef.name} suffered a workplace injury during strenuous labor!",
                    );
                    final effects = List<StatusEffect>.from(
                      npcRef.statusEffects,
                    );
                    effects.add(
                      StatusEffect(
                        id: 'workplace_injury_${_currentDate.totalMinutes}',
                        name: 'Workplace Injury',
                        description: 'Painful injury sustained on the job.',
                        attributeModifiers: {
                          'strength': -2,
                          'endurance': -2,
                          'dexterity': -1,
                        },
                        durationMinutes: 60 * 24 * 3, // 3 days
                        type: StatusEffectType.disease,
                        startTimestamp: _currentDate.totalMinutes,
                      ),
                    );
                    _npcs[i] = npcRef.copyWith(statusEffects: effects);
                  }
                }

                npc = _npcs[i]; // refresh reference after modifying _npcs[i]
              }

              // STAGNATION TRACKING: If progress (minutesRemaining) hasn't changed, increment counter
              final String stagnateKey = npc.id;
              final int lastRemaining =
                  _taskStagnationCounters[stagnateKey] ?? -1;

              bool isStagnationExempt =
                  npc.movementPath.isNotEmpty ||
                  npc.targetRoomId != null ||
                  npc.status == NPCStatus.sleeping ||
                  npc.status == NPCStatus.fainted ||
                  npc.status == NPCStatus.broken;

              if (lastRemaining == task.minutesRemaining) {
                if (isStagnationExempt) {
                  _taskStagnationCounters["${stagnateKey}_count"] = 0;
                } else {
                  final currentCount =
                      _taskStagnationCounters["${stagnateKey}_count"] ?? 0;
                  _taskStagnationCounters["${stagnateKey}_count"] =
                      currentCount + 1;

                  if (currentCount > 15) {
                    // FORCE STALL: NPC has been on this task for 15 mins without progress
                    debugPrint(
                      "NPC_STAGNATION_TIMEOUT: ${npc.name} stuck on ${task.type.name}. Forcing Stall.",
                    );
                    _taskService.removeTask(task.id);
                    _clearRoomOccupancyForNpc(npc.id);
                    _npcs[i] = npc.copyWith(activeTaskId: null);
                    _taskStagnationCounters["${stagnateKey}_count"] = 0;

                    // Also stall the intent in the queue so they don't pick it right back up
                    final newStalledQueue = List<NPCIntent>.from(
                      _npcs[i].intentQueue,
                    );
                    final stallIdx = newStalledQueue.indexWhere(
                      (it) => it.id == task.id,
                    );
                    if (stallIdx != -1) {
                      final stalled = newStalledQueue.removeAt(stallIdx);
                      newStalledQueue.add(
                        stalled.copyWith(
                          startTimeMin: _currentDate.totalMinutes + 30,
                        ),
                      );
                      _npcs[i] = _npcs[i].copyWith(
                        intentQueue: newStalledQueue,
                      );
                    }
                  }
                }
              } else {
                _taskStagnationCounters[stagnateKey] = task.minutesRemaining;
                _taskStagnationCounters["${stagnateKey}_count"] = 0;
              }
            }

            // Sync to Room Physical Project
            final targetId = task.targetId;
            if (targetId != null) {
              final roomIndex = _rooms.indexWhere((r) => r.id == targetId);
              if (roomIndex != -1) {
                final room = _rooms[roomIndex];
                if (room.activeProjects.containsKey(task.id)) {
                  final totalMin = task.totalMinutes > 0
                      ? task.totalMinutes
                      : 60;
                  final progress =
                      1.0 - (task.minutesRemaining / totalMin).clamp(0.0, 1.0);
                  final updatedProjects = Map<String, PhysicalProject>.from(
                    room.activeProjects,
                  );
                  updatedProjects[task.id] = updatedProjects[task.id]!.copyWith(
                    progress: progress,
                  );
                  _rooms[roomIndex] = room.copyWith(
                    activeProjects: updatedProjects,
                  );
                }
              }
            }
          }
        }
      }

      final allCompleted = [...completedTasks];

      for (var task in allCompleted) {
        _handleTaskCompletion(task);
      }

      _updateNpcs();
      _processConstruction();
      _processExperiments();
      _processChickens();
      _processGarden();
      _processCrops();
      _processHygiene();
      _processCrises();
      _processPredators();
      _processVisitors();
      _processDigestion();
      _processAutonomousCooking();
      _checkObjectives();
      checkBusinessAssignments();
      _processGraduateSchool();
      _checkDiscoveries();
      _consolidateUndeadUnits();
      _processFoxGestation();
      notifyListeners();
    } finally {
      _isTicking = false;
    }
  }

  void _processFoxGestation() {
    for (int i = 0; i < _npcs.length; i++) {
      final npc = _npcs[i];
      if (npc.specimenType.toLowerCase() == 'fox' &&
          (npc.metadata['isPregnant'] == true)) {
        final startTime = npc.metadata['gestationStartTime'] as int? ?? 0;
        final elapsed = _currentDate.totalMinutes - startTime;
        if (elapsed >= 14400) {
          // 10 days
          // Birth a fox kit
          final kit = FoxGenerator.createFox(const Uuid().v4(), _currentDate);
          _npcs.add(
            kit.copyWith(
              name: "${npc.name}'s Kit",
              currentThought: "A new arrival in the wild pack.",
            ),
          );
          _npcs[i] = npc.copyWith(
            metadata: {
              ...npc.metadata,
              'isPregnant': false,
              'gestationStartTime': null,
            },
          );
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] WILDLIFE: A new fox kit has been born in the estate grounds.",
          );
        }
      }
    }
  }

  void _processVisitors() {
    final totalMinutes = _currentDate.totalMinutes;

    // 1. Low Food Staples Merchant Trigger
    final currentMeals = _pantry.length;
    if (currentMeals <= 10 && !_hasFoodDropTriggered) {
      _hasFoodDropTriggered = true;
      _foodDropTriggerTime = totalMinutes;
    }

    if (_hasFoodDropTriggered &&
        _foodDropTriggerTime != null &&
        totalMinutes >= _foodDropTriggerTime! + 1440) {
      _foodDropTriggerTime = null; // reset trigger so it only runs once
      _spawnFoodStapleMerchant();
    }

    // 2. Weekly Visiting Merchant Spawn (once every 7 days = 10080 minutes)
    if (_lastMerchantSpawnMinutes == 0) {
      _lastMerchantSpawnMinutes = totalMinutes;
    }
    if (totalMinutes - _lastMerchantSpawnMinutes >= 10080) {
      _lastMerchantSpawnMinutes = totalMinutes;
      _spawnVisitingMerchant();
    }

    // 3. Regular Visitor Chance (2% chance per hour / ~0.03% per minute)
    if (Random().nextDouble() < 0.0003) {
      _triggerVisitorArrival();
    }

    // 4. Visitor Timeouts (2 hours = 120 minutes ungreeted, 4 hours = 240 minutes greeted)
    for (int i = _npcs.length - 1; i >= 0; i--) {
      final npc = _npcs[i];
      if (!npc.isResident && npc.currentRoomId == 'entryway') {
        final arrivalTime = npc.metadata['arrivalTime'] as int? ?? 0;
        final elapsed = totalMinutes - arrivalTime;
        final isGreeted = npc.metadata['isGreeted'] == true;
        final timeout = isGreeted ? 240 : 120;

        if (elapsed >= timeout) {
          _npcs.removeAt(i);
          if (isGreeted) {
            _lastAnnouncement =
                "${npc.name} has packed up their wares and departed.";
          } else {
            _lastAnnouncement =
                "A guest, ${npc.name}, grew tired of waiting and left.";
          }
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] DEPARTURE: ${npc.name} left the entryway.",
          );
          notifyListeners();
        }
      }
    }

    // Restaurant Diner Spawning & Timeouts
    if (_manorVenture == ManorVenture.restaurant) {
      final currentDiners = _npcs
          .where((n) => n.metadata['isDiner'] == true)
          .length;
      if (currentDiners < 4 && Random().nextDouble() < 0.01) {
        _spawnDiner();
      }

      final diners = _npcs.where((n) => n.metadata['isDiner'] == true).toList();
      for (var diner in diners) {
        final elapsed =
            _currentDate.totalMinutes -
            (diner.metadata['arrivalTime'] as int? ?? 0);
        if (elapsed > 180) {
          _npcs.removeWhere((n) => n.id == diner.id);
          _lastAnnouncement =
              "${diner.name} grew tired of waiting for service and left unsatisfied.";
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] DINING: $_lastAnnouncement",
          );
          notifyListeners();
        }
      }
    }

    // Hotel Guest Spawning & Checkout
    if (_manorVenture == ManorVenture.kompromatHotel) {
      final currentGuests = _npcs
          .where((n) => n.metadata['isHotelGuest'] == true)
          .toList();
      if (currentGuests.length < 3 && Random().nextDouble() < 0.01) {
        _spawnHotelGuest();
      }

      for (var guest in currentGuests) {
        final elapsed =
            _currentDate.totalMinutes -
            (guest.metadata['checkInTime'] as int? ?? 0);
        if (elapsed > 4320) {
          // 3 days
          final payout = 60;
          updateResource('funds', payout);

          final roomId = guest.metadata['roomId'] as String?;
          if (roomId != null) {
            final roomIdx = _rooms.indexWhere((r) => r.id == roomId);
            if (roomIdx != -1) {
              _rooms[roomIdx] = _rooms[roomIdx].copyWith(clearOccupancy: true);
            }
          }

          _npcs.removeWhere((n) => n.id == guest.id);
          _lastAnnouncement =
              "${guest.name} checked out and paid $payout CHF for lodging.";
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] HOTEL: $_lastAnnouncement",
          );
          notifyListeners();
        }
      }
    }
  }

  void _spawnHotelGuest() {
    final availableRoom = _rooms.firstWhereOrNull(
      (r) =>
          r.isRestored &&
          (r.type == RoomType.bedroom || r.type == RoomType.tenement) &&
          r.occupyingNpcId == null,
    );
    if (availableRoom == null) return;

    final randomNames = [
      'Lord Byron',
      'Colonel Mustard',
      'Lady Genevieve',
      'Archduke Franz',
      'Duchess Sophia',
    ];
    final name = randomNames[Random().nextInt(randomNames.length)];
    final id = 'guest_${const Uuid().v4()}';

    final npc = NPC(
      id: id,
      name: name,
      role: 'Hotel Guest',
      age: 25 + Random().nextInt(40),
      gender: Random().nextBool() ? 'Male' : 'Female',
      specimenType: 'Human',
      bodyParts: const [],
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random(),
      currentRoomId: availableRoom.id,
      targetRoomId: availableRoom.id,
      movementProgress: 1.0,
      status: NPCStatus.idle,
      isResident: false,
      metadata: {
        'isHotelGuest': true,
        'checkInTime': _currentDate.totalMinutes,
        'roomId': availableRoom.id,
      },
    );

    if (_npcs.any((n) => n.name == npc.name)) return;

    // Mark room occupied
    final roomIdx = _rooms.indexOf(availableRoom);
    _rooms[roomIdx] = availableRoom.copyWith(occupyingNpcId: id);

    _npcs.add(npc);

    _lastAnnouncement =
        "A high-profile guest, ${npc.name}, checked into room ${availableRoom.name.toUpperCase()}.";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] HOTEL: $_lastAnnouncement",
    );
    notifyListeners();
  }

  bool startSpyingOnGuest(String residentId, String guestId) {
    final resident = _npcs.firstWhereOrNull((n) => n.id == residentId);
    final guest = _npcs.firstWhereOrNull((n) => n.id == guestId);
    if (resident == null || guest == null) return false;

    final task = GameTask(
      id: 'spy_${resident.id}_${DateTime.now().millisecondsSinceEpoch}',
      npcId: resident.id,
      priority: IntentPriority.high,
      type: TaskType.spyOnNeighbor,
      targetId: guest.id,
      targetName: guest.name,
      minutesRemaining: 120,
      totalMinutes: 120,
    );

    _taskService.addTask(task);

    final idx = _npcs.indexOf(resident);
    _npcs[idx] = resident.copyWith(
      activeTaskId: task.id,
      status: NPCStatus.working,
    );

    _lastAnnouncement =
        "${resident.name} is now spying on guest ${guest.name}.";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] SPYING: $_lastAnnouncement",
    );
    notifyListeners();
    return true;
  }

  bool blackmailGuest(String guestId, String folderId) {
    final guestIdx = _npcs.indexWhere((n) => n.id == guestId);
    if (guestIdx == -1) return false;
    final guest = _npcs[guestIdx];

    // Remove Kompromat Folder item from Study
    final studyIndex = _rooms.indexWhere((r) => r.id == 'study');
    if (studyIndex != -1) {
      final study = _rooms[studyIndex];
      final newInv = List<GameItem>.from(study.inventory);
      newInv.removeWhere((i) => i.id == folderId);
      _rooms[studyIndex] = study.copyWith(inventory: newInv);
    }

    // Remove guest & clear occupancy
    final roomId = guest.metadata['roomId'] as String?;
    if (roomId != null) {
      final roomIdx = _rooms.indexWhere((r) => r.id == roomId);
      if (roomIdx != -1) {
        _rooms[roomIdx] = _rooms[roomIdx].copyWith(clearOccupancy: true);
      }
    }

    _npcs.removeAt(guestIdx);

    // Payout
    final blackmailRansom = 250;
    updateResource('funds', blackmailRansom);

    _lastAnnouncement =
        "Blackmailed ${guest.name}. Extorted $blackmailRansom CHF!";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] INTRIGUE: $_lastAnnouncement",
    );
    notifyListeners();
    return true;
  }

  void _spawnDiner() {
    final randomNames = [
      'Monsieur Dupont',
      'Madame Leclerc',
      'Baron von Roth',
      'Countess Anna',
      'Squire Higgins',
    ];
    final name = randomNames[Random().nextInt(randomNames.length)];
    final id = 'diner_${const Uuid().v4()}';

    final npc = NPC(
      id: id,
      name: name,
      role: 'Hungry Diner',
      age: 30 + Random().nextInt(30),
      gender: Random().nextBool() ? 'Male' : 'Female',
      specimenType: 'Human',
      bodyParts: const [],
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random(),
      currentRoomId: 'dining_room',
      targetRoomId: 'dining_room',
      movementProgress: 1.0,
      status: NPCStatus.idle,
      isResident: false,
      metadata: {
        'isDiner': true,
        'arrivalTime': _currentDate.totalMinutes,
        'orderedDishType':
            DishType.values[Random().nextInt(DishType.values.length)].name,
      },
    );

    if (_npcs.any((n) => n.name == npc.name)) return;

    _npcs.add(npc);

    _lastAnnouncement =
        "A Diner, ${npc.name}, has arrived and is seated in the dining room.";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] DINING: $_lastAnnouncement",
    );
    notifyListeners();
  }

  bool serveDiner(String dinerId, String dishId) {
    final dinerIdx = _npcs.indexWhere((n) => n.id == dinerId);
    if (dinerIdx == -1) return false;
    final diner = _npcs[dinerIdx];

    final dishIdx = _pantry.indexWhere((d) => d.id == dishId);
    if (dishIdx == -1) return false;
    final dish = _pantry.removeAt(dishIdx);

    double qualityFactor = 1.0;
    switch (dish.quality) {
      case DishQuality.exquisite:
        qualityFactor = 3.0;
        break;
      case DishQuality.delectable:
        qualityFactor = 2.5;
        break;
      case DishQuality.sophisticated:
        qualityFactor = 2.0;
        break;
      case DishQuality.fine:
        qualityFactor = 1.8;
        break;
      case DishQuality.decent:
        qualityFactor = 1.4;
        break;
      default:
        qualityFactor = 1.0;
    }

    NPC? primaryCook;
    double maxCookProf = -1;
    for (var npc in _npcs) {
      if (npc.isResident && npc.proficiencies.containsKey('Cooking')) {
        final prof = npc.proficiencies['Cooking']!;
        if (prof > maxCookProf) {
          maxCookProf = prof;
          primaryCook = npc;
        }
      }
    }
    primaryCook ??=
        _npcs.firstWhereOrNull((n) => n.id == 'butler') ??
        _npcs.firstWhereOrNull((n) => n.isPlayer);

    NPC? fohServer;
    int maxCleaningResp = -1;
    for (var npc in _npcs) {
      if (npc.isResident &&
          npc.status != NPCStatus.dead &&
          npc.worldDestinationId == null) {
        if (npc.currentRoomId == 'dining_hall') {
          fohServer = npc;
          break;
        }
        final resp = npc.responsibilities[ResponsibilityCategory.cleaning] ?? 0;
        if (resp > maxCleaningResp) {
          maxCleaningResp = resp;
          fohServer = npc;
        }
      }
    }
    fohServer ??=
        _npcs.firstWhereOrNull((n) => n.id == 'butler') ??
        _npcs.firstWhereOrNull((n) => n.isPlayer);

    double fohBiasFactor = 1.0;
    double cookBiasFactor = 1.0;
    final List<String> biases = [];

    if (fohServer != null) {
      final fohClass =
          fohServer.biography?.characterClass ?? fohServer.background;
      final fohReligion = fohServer.religion;
      final dinerClass = diner.biography?.characterClass ?? diner.background;
      final dinerReligion = diner.religion;

      if (dinerClass == 'Noble' && fohClass == 'Peasant') {
        fohBiasFactor = 0.7;
        biases.add("disdains Peasant waiter ${fohServer.name}");
      } else if (dinerClass == 'Noble' && fohClass == 'Noble') {
        fohBiasFactor = 1.3;
        biases.add("appreciates Noble waiter ${fohServer.name}");
      } else if (dinerReligion == fohReligion) {
        fohBiasFactor = 1.15;
        biases.add("shared waiter faith with ${fohServer.name}");
      } else if ((dinerReligion == 'Protestant' ||
              dinerReligion == 'Calvinist') &&
          fohReligion == 'Catholic') {
        fohBiasFactor = 0.8;
        biases.add("sectarian tension with Catholic waiter ${fohServer.name}");
      }
    }

    if (primaryCook != null) {
      final cookClass =
          primaryCook.biography?.characterClass ?? primaryCook.background;
      final cookReligion = primaryCook.religion;
      final dinerClass = diner.biography?.characterClass ?? diner.background;
      final dinerReligion = diner.religion;

      if (dinerClass == 'Noble' && cookClass == 'Peasant') {
        cookBiasFactor = 0.9;
        biases.add("dislikes Peasant chef ${primaryCook.name}");
      } else if (dinerClass == 'Noble' && cookClass == 'Noble') {
        cookBiasFactor = 1.1;
        biases.add("respects Noble chef ${primaryCook.name}");
      } else if (dinerReligion == cookReligion) {
        cookBiasFactor = 1.05;
        biases.add("shared chef faith");
      } else if ((dinerReligion == 'Protestant' ||
              dinerReligion == 'Calvinist') &&
          cookReligion == 'Catholic') {
        cookBiasFactor = 0.95;
        biases.add("minor sectarian chef tension");
      }
    }

    final lineageBiasFactor = fohBiasFactor * cookBiasFactor;
    String biasReason = "";
    if (biases.isNotEmpty) {
      biasReason = " (${biases.join(', ')})";
    }

    final payment = (dish.value * 2.5 * qualityFactor * lineageBiasFactor)
        .round();
    updateResource('funds', payment);

    _npcs.removeAt(dinerIdx);

    _lastAnnouncement =
        "Served ${diner.name} ${dish.name}. Paid $payment CHF$biasReason.";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] DINING: $_lastAnnouncement",
    );
    notifyListeners();
    return true;
  }

  void _processDiscreteSocialEvents() {
    // 1% chance per minute to trigger an interaction if people are in the same room
    if (Random().nextDouble() > 0.01) return;

    // Group NPCs by room
    final roomGroups = <String, List<NPC>>{};
    for (var npc in _npcs.where(
      (n) => n.isResident && n.status != NPCStatus.zombie,
    )) {
      if (npc.currentRoomId != null) {
        roomGroups.putIfAbsent(npc.currentRoomId!, () => []).add(npc);
      }
    }

    // Pick a random room with at least 2 people
    final validRooms = roomGroups.entries
        .where((e) => e.value.length >= 2)
        .toList();
    if (validRooms.isEmpty) return;

    final roomEntry = validRooms[Random().nextInt(validRooms.length)];
    final candidates = roomEntry.value;

    // Pick two distinct NPCs
    final idx1 = Random().nextInt(candidates.length);
    int idx2 = Random().nextInt(candidates.length);
    while (idx2 == idx1) {
      idx2 = Random().nextInt(candidates.length);
    }

    final npc1 = candidates[idx1];
    final npc2 = candidates[idx2];

    final type = SocialService.getRandomInteraction();
    final result = SocialService.performInteraction(npc1, npc2, type);

    // Apply changes
    final n1Idx = _npcs.indexWhere((n) => n.id == npc1.id);
    final n2Idx = _npcs.indexWhere((n) => n.id == npc2.id);

    if (n1Idx != -1 && n2Idx != -1) {
      final newRels1 = Map<String, Relationship>.from(
        _npcs[n1Idx].relationships,
      );
      newRels1[npc2.id] = result['actorRelationship'] as Relationship;

      final newRels2 = Map<String, Relationship>.from(
        _npcs[n2Idx].relationships,
      );
      newRels2[npc1.id] = result['targetRelationship'] as Relationship;

      _npcs[n1Idx] = _npcs[n1Idx].copyWith(relationships: newRels1);
      _npcs[n2Idx] = _npcs[n2Idx].copyWith(relationships: newRels2);

      final log = result['log'] as String;
      _lastAnnouncement = log;
      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] SOCIAL: $log",
      );
      if (_announcementHistory.length > 50) _announcementHistory.removeLast();

      notifyListeners();
    }
  }

  void _triggerVisitorArrival() {
    final guests = [
      {
        'name': 'Inspector Kael',
        'role': 'Inquisitive Visitor',
        'type': 'visitor',
      },
      {'name': 'Lost Traveler', 'role': 'Weary Guest', 'type': 'visitor'},
      {
        'name': 'Chef Pierre',
        'role': 'Cordon Bleu Cook',
        'type': 'cook_proposer',
      },
      {
        'name': 'Dr. Faustus',
        'role': 'Rogue Alchemist',
        'type': 'chemist_proposer',
      },
      {
        'name': 'Advocate Cagliostro',
        'role': 'Gothic Attorney',
        'type': 'lawyer_proposer',
      },
      {
        'name': 'Dr. Frankenstein',
        'role': 'Private Physician',
        'type': 'doctor_proposer',
      },
      {
        'name': 'Lord Garrick',
        'role': 'Thespian Virtuoso',
        'type': 'actor_proposer',
      },
    ];
    final guest = guests[Random().nextInt(guests.length)];

    // Create physical NPC
    final npc = NPCGenerator.generateRefugee(currentDate: _currentDate)
        .copyWith(
          id: 'visitor_${const Uuid().v4()}',
      name: guest['name']!,
      role: guest['role']!,
          currentRoomId: 'entryway',
          targetRoomId: 'entryway',
      movementProgress: 1.0,
      status: NPCStatus.idle,
      assignedRoomId: null, // Guests don't have rooms
      isResident: false, // Visitors are transient
          metadata: {
            'guestType': guest['type']!,
            'arrivalTime': _currentDate.totalMinutes,
            'isGreeted': false,
          },
    );

    // Check for uniqueness
    if (_npcs.any((n) => n.name == npc.name)) {
      return; // Already here
    }

    _npcs.add(npc);

    _lastAnnouncement =
        "A ${guest['role']}, ${guest['name']}, has arrived in the entryway.";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] GUEST ARRIVAL: ${guest['name']}",
    );
    notifyListeners();
  }

  void _processChickens() {
    for (int i = _chickens.length - 1; i >= 0; i--) {
      // Passive hunger logic can go here
    }
  }

  void _processAutonomousCooking() {
    // Threshold increased to 10 meals (Resource + Pantry) to avoid redundant cooking
    final currentMeals = (resources['meals'] ?? 0) + _pantry.length;
    if (currentMeals >= 10 || _cookingQueue.length >= 3) return;

    // Try to queue the most basic meal first (Mystery Stew)
    // Ingredients: 1 meat, 1 potato, 1 salt
    final hasMeat = (resources['meat'] ?? 0) >= 1;
    final hasPotato = (resources['potato'] ?? 0) >= 1;
    final hasSalt = (resources['salt'] ?? 0) >= 1;

    if (hasMeat && hasPotato && hasSalt) {
      _cookingQueue.add('protein_mistery_stew');
      return;
    }

    // Fallback: Bread (1 flour_spelt, 1 salt)
    final hasFlour = (resources['flour_spelt'] ?? 0) >= 1;
    if (hasFlour && hasSalt) {
      _cookingQueue.add('staple_bread');
      return;
    }

    // Fallback: Generic Meat Fry (1 meat, 1 pepper)
    final hasPepper = (resources['pepper'] ?? 0) >= 1;
    if (hasMeat && hasPepper) {
      _cookingQueue.add('fried_generic_meat');
    }
  }

  void _processLivestockByproducts() {
    // Check for rooms that could produce fertilizer (Pig Pen, Cattle Pasture)
    bool hasLivestockRoom = _rooms.any(
      (r) =>
          r.isRestored &&
          (r.type == RoomType.pigPen || r.type == RoomType.cattlePasture),
    );

    // Low chance per hour per room
    if (hasLivestockRoom && Random().nextDouble() < 0.3) {
      updateResource('fertilizer', 1);
    }

    // Even if no specific room yet, chickens produce a tiny bit
    if (_chickens.isNotEmpty && Random().nextDouble() < 0.1) {
      setResource('fertilizer', ((resources['fertilizer'] ?? 0) + 0.5).round());
    }
  }

  void _checkForTodayBirthday() {
    _activeBirthdayNpcId = null;
    for (var npc in _npcs) {
      if (npc.isResident &&
          npc.birthDate != null &&
          npc.status != NPCStatus.dead) {
        if (npc.birthDate!.day == _currentDate.day &&
            npc.birthDate!.month == _currentDate.month) {
          _activeBirthdayNpcId = npc.id;
          break;
        }
      }
    }
  }

  void _checkAndProcessBirthdays() {
    if (_currentDate.hour != 18) return;
    if (_activeBirthdayNpcId == null) return;

    final birthdayNpcIdx = _npcs.indexWhere(
      (n) => n.id == _activeBirthdayNpcId,
    );
    if (birthdayNpcIdx == -1) return;
    final birthdayNpc = _npcs[birthdayNpcIdx];
    if (birthdayNpc.status == NPCStatus.dead || !birthdayNpc.isResident) {
      _activeBirthdayNpcId = null;
      return;
    }

    final attendees = <int>[];
    for (int i = 0; i < _npcs.length; i++) {
      final npc = _npcs[i];
      if (npc.id != birthdayNpc.id &&
          npc.isResident &&
          npc.status != NPCStatus.dead &&
          npc.status != NPCStatus.imprisoned &&
          npc.worldDestinationId == null) {
        attendees.add(i);
      }
    }

    if (attendees.isEmpty) {
      _activeBirthdayNpcId = null;
      return;
    }

    _npcs[birthdayNpcIdx] = _npcs[birthdayNpcIdx].copyWith(
      currentRoomId: 'dining_hall',
      targetRoomId: 'dining_hall',
      movementProgress: 1.0,
      status: NPCStatus.idle,
      satisfaction: (_npcs[birthdayNpcIdx].satisfaction + 40.0).clamp(
        0.0,
        100.0,
      ),
      currentThought:
          "Celebrating my birthday in the dining hall with my friends!",
    );

    final giftsList = <String>[];
    for (int idx in attendees) {
      final attendee = _npcs[idx];

      String giftName = "a homemade card";
      if (attendee.background == 'Noble') {
        giftName = "a fine silver pocket watch";
      } else if (attendee.background == 'Merchant') {
        giftName = "a rare imported bottle of wine";
      } else if (attendee.background == 'Scholar') {
        giftName = "a beautifully bound leather journal";
      } else if (attendee.background == 'Peasant' ||
          attendee.background == 'Servant') {
        giftName = "a hand-carved wooden figurine";
      }
      giftsList.add("${attendee.name} presented $giftName");

      var updatedAttendee = attendee.copyWith(
        currentRoomId: 'dining_hall',
        targetRoomId: 'dining_hall',
        movementProgress: 1.0,
        status: NPCStatus.idle,
        satisfaction: (attendee.satisfaction + 10.0).clamp(0.0, 100.0),
        currentThought: "Wishing a very happy birthday to ${birthdayNpc.name}!",
      );

      final newRelsAttendee = Map<String, Relationship>.from(
        updatedAttendee.relationships,
      );
      final relToBirthday = newRelsAttendee[birthdayNpc.id] ?? Relationship();
      newRelsAttendee[birthdayNpc.id] = relToBirthday.copyWith(
        admiration: (relToBirthday.admiration + 0.5).clamp(0.0, 5.0),
        respect: (relToBirthday.respect + 0.3).clamp(0.0, 5.0),
      );
      updatedAttendee = updatedAttendee.copyWith(
        relationships: newRelsAttendee,
      );
      _npcs[idx] = updatedAttendee;

      final birthdayRef = _npcs[birthdayNpcIdx];
      final newRelsBirthday = Map<String, Relationship>.from(
        birthdayRef.relationships,
      );
      final relToAttendee = newRelsBirthday[attendee.id] ?? Relationship();
      newRelsBirthday[attendee.id] = relToAttendee.copyWith(
        admiration: (relToAttendee.admiration + 1.0).clamp(0.0, 5.0),
      );
      _npcs[birthdayNpcIdx] = birthdayRef.copyWith(
        relationships: newRelsBirthday,
      );
    }

    final giftsString = giftsList.join(", ");
    _lastAnnouncement =
        "Today is ${birthdayNpc.name}'s birthday! Everyone gathered in the dining room to celebrate. Gifts: $giftsString.";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] CELEBRATION: $_lastAnnouncement",
    );
    if (_announcementHistory.length > 50) _announcementHistory.removeLast();
    _activeBirthdayNpcId = null;
    notifyListeners();
  }

  void _processCrops() {
    for (int i = 0; i < _crops.length; i++) {
      var crop = _crops[i];
      if (!crop.isHarvestable) {
        final room = _rooms.firstWhereOrNull((r) => r.id == crop.roomId);
        final isGreenhouse = room?.type == RoomType.greenhouse;
        final isDarkRoom =
            room?.type == RoomType.basement ||
            room?.type == RoomType.laboratory ||
            room?.type == RoomType.attic;

        // 1. Moisture Decay
        double moistureDecay = 0.0002; // Base decay
        if (isGreenhouse) {
          moistureDecay = 0.0001; // Conserves moisture
        } else if (isDarkRoom) {
          moistureDecay = 0.00006; // Humid and dark
        }

        // 2. Base Growth Rate (Cabbage/Potato/Carrot/Beet/Cannabis/Tobacco are 60 days)
        // 60 days = 86400 mins. Grain/Mushroom are 30 days = 43200 mins.
        double growthRate = 1.0 / 86400.0;

        if (crop.type == CropType.grain || crop.type == CropType.mushroom) {
          growthRate = 1.0 / 43200.0;
        }

        // Moisture modifier
        if (crop.moistureLevel > 0.1) {
          growthRate *= 2.0;
        } else {
          growthRate *= 0.1; // Stunted
        }

        // 3. Real-life Parameters & Special Modifiers
        double growMultiplier = 1.0;

        // Dark-room Mushroom Cultivation
        if (crop.type == CropType.mushroom) {
          if (!isDarkRoom && !isGreenhouse) {
            growMultiplier *= 0.01; // Stunted in dry/bright fields
          }
        }

        // Seasonal Parameters for field crops (Cannabis & Tobacco)
        if (crop.type == CropType.cannabis || crop.type == CropType.tobacco) {
          final isWarmMonth =
              _currentDate.month >= 4 && _currentDate.month <= 8;
          if (isGreenhouse) {
            growMultiplier *= 1.2; // Permanent greenhouse boost
          } else {
            if (isWarmMonth) {
              growMultiplier *= 1.5; // Warm Spring/Summer boost
            } else {
              growMultiplier *= 0.1; // Freezing/unsuitable season
            }
          }
        }

        // Fertilizer Modifier
        if (room != null && room.isFertilized) {
          growMultiplier *= 1.3;
        }

        final finalGrowthRate = growthRate * growMultiplier;

        _crops[i] = crop.copyWith(
          growthProgress: (crop.growthProgress + finalGrowthRate).clamp(
            0.0,
            1.0,
          ),
          moistureLevel: (crop.moistureLevel - moistureDecay).clamp(0.0, 1.0),
        );
      }
    }
  }

  void _processGarden() {
    for (int i = _gardenPlants.length - 1; i >= 0; i--) {
      var plant = _gardenPlants[i];

      if (!plant.isAlive(_currentDate.month)) {
        _gardenPlants.removeAt(i);
        continue;
      }

      double yieldChance = 0.0;
      if (plant.isPeakSeason(_currentDate.month)) {
        yieldChance = 1.0 / 1440.0; // Peak chance (~1/day)
      } else {
        yieldChance = 1.0 / 8640.0; // Off-peak chance (~1/week)
      }

      if (plant.health > 0.5 && Random().nextDouble() < yieldChance) {
        _gardenPlants[i] = plant.copyWith(yieldAmount: plant.yieldAmount + 1);
      }
    }
  }

  void manualRemoveGardenBed(int bedIndex) {
    _gardenPlants.removeWhere(
      (p) => p.roomId == 'vegetable_garden' && p.bedIndex == bedIndex,
    );
    _lastAnnouncement = "Cleared a plot in the vegetable garden.";
    notifyListeners();
  }

  void manualPlantGardenBed(int bedIndex, PlantType type) {
    _gardenPlants.add(
      Plant.create(
        type,
        'vegetable_garden',
        _currentDate.month,
        _currentDate.year,
        bedIndex,
      ),
    );
    _lastAnnouncement = "Planted ${type.name} in the garden.";
    notifyListeners();
  }

  bool plantCrops(CropType type, String roomId, {int? bedIndex}) {
    if (roomId == 'vegetable_garden') {
      return false; // Prevent traditional crop planting in garden
    }

    final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex == -1) return false;
    final room = _rooms[roomIndex];

    bool isSuitable =
        room.type == RoomType.field ||
        room.type == RoomType.garden ||
        room.type == RoomType.greenhouse;
    if (type == CropType.mushroom) {
      if (room.type == RoomType.basement ||
          room.type == RoomType.laboratory ||
          room.type == RoomType.attic) {
        isSuitable = true;
      }
    }

    if (!isSuitable) {
      _lastAnnouncement =
          "${room.name} is not suitable for growing ${type.name.toUpperCase()}.";
      notifyListeners();
      return false;
    }

    if (room.tilledAmount < 0.5) {
      _lastAnnouncement =
          "The soil in ${room.name} must be at least 50% tilled before planting.";
      notifyListeners();
      return false;
    }

    if (_crops.any((c) => c.roomId == roomId)) {
      _lastAnnouncement = "${room.name} already has crops planted.";
      notifyListeners();
      return false;
    }

    String seedId;
    if (type == CropType.grain) {
      seedId = 'grain';
    } else if (type == CropType.mushroom) {
      seedId = 'mushroom_spores';
    } else {
      seedId = 'seeds_${type.name}';
    }
    final isFullTilled = room.tilledAmount >= 0.9;
    double seedConsumption = isFullTilled ? 10.0 : 5.0;

    if ((resources[seedId] ?? 0) < seedConsumption) {
      final seedLabel = seedId == 'grain'
          ? 'Grain'
          : (seedId == 'mushroom_spores'
                ? 'Mushroom Spores'
                : '${type.name.toUpperCase()} Seeds');
      _lastAnnouncement =
          "Need ${seedConsumption.toInt()} $seedLabel to plant in ${room.name}.";
      notifyListeners();
      return false;
    }

    setResource(
      seedId,
      ((resources[seedId] ?? 0) - seedConsumption).round().toDouble(),
    );

    // Yield based on preparation: full preparation = 4, partial = 2 (plus fertilizer bonuses)
    final baseYield = isFullTilled ? 4 : 2;
    final fertBonus = room.isFertilized ? (isFullTilled ? 2 : 1) : 0;
    final totalYield = (baseYield + fertBonus).toInt();

    _crops.add(
      Crop(
        id: const Uuid().v4(),
        type: type,
        plantedAt: DateTime.now(),
        isTilled: isFullTilled,
        isWatered: true,
        moistureLevel: 1.0,
        roomId: roomId,
        yield: totalYield,
      ),
    );

    // Exhaust tilled state after planting
    _rooms[roomIndex] = room.copyWith(tilledAmount: 0.0, fertilizedAmount: 0.0);

    _lastAnnouncement = "Planted ${type.name} in ${room.name}.";
    notifyListeners();
    return true;
  }

  void tillSoil(String roomId) {
    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index != -1) {
      final room = _rooms[index];
      if (room.tilledAmount >= 1.0) {
        _lastAnnouncement = "The soil in ${room.name} was already tilled.";
        return;
      }
      final newAmount = (room.tilledAmount + 0.5).clamp(0.0, 1.0);
      bool rewardGranted = false;

      // Award wood for first-time tilling of fields A, B, and C
      if (!room.hasBeenTilledForReward && newAmount >= 1.0) {
        if (roomId == 'field_2' || roomId == 'field_3' || roomId == 'field_4') {
          updateResource('wood', 50);
          rewardGranted = true;
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] PROGRESS: Tilling ${room.name} unearths 50 units of usable timber from old stumps and roots!",
          );
        }
      }

      _rooms[index] = room.copyWith(
        tilledAmount: newAmount,
        hasBeenTilledForReward: rewardGranted || room.hasBeenTilledForReward,
      );
      notifyListeners();
    }
  }

  void fertilizeSoil(String roomId) {
    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index != -1) {
      final room = _rooms[index];
      if (room.fertilizedAmount >= 1.0) {
        _lastAnnouncement = "The soil in ${room.name} was already fertilized.";
        return;
      }
      _rooms[index] = room.copyWith(
        fertilizedAmount: (room.fertilizedAmount + 0.5).clamp(0.0, 1.0),
      );
      notifyListeners();
    }
  }

  void waterCrops(String roomId) {
    if (roomId == 'vegetable_garden') {
      for (int i = 0; i < _gardenPlants.length; i++) {
        _gardenPlants[i] = _gardenPlants[i].copyWith(
          health: (_gardenPlants[i].health + 0.2).clamp(0.0, 1.0),
        );
      }
      _lastAnnouncement = "The garden has been watered.";
      notifyListeners();
      return;
    }

    // For now, water all crops globally or we could filter if we had roomId on Crop
    for (int i = 0; i < _crops.length; i++) {
      _crops[i] = _crops[i].copyWith(isWatered: true, moistureLevel: 1.0);
    }
    _lastAnnouncement = "The crops have been watered.";
    notifyListeners();
  }

  void careForCrops(String roomId) {
    if (roomId == 'vegetable_garden') {
      for (int i = 0; i < _gardenPlants.length; i++) {
        _gardenPlants[i] = _gardenPlants[i].copyWith(health: 1.0);
      }
      _lastAnnouncement = "The garden plants were pruned and tended.";
      notifyListeners();
      return;
    }

    for (int i = 0; i < _crops.length; i++) {
      _crops[i] = _crops[i].copyWith(lastCaredForAt: DateTime.now());
    }
    _lastAnnouncement = "The crops have been tended to.";
    notifyListeners();
  }

  bool areAllResidentsAsleep() {
    final residents = _npcs
        .where((n) => n.isResident && n.status != NPCStatus.dead)
        .toList();
    if (residents.isEmpty) return false;

    for (final npc in residents) {
      final activeTask = npc.activeTaskId != null
          ? _taskService.activeTasks.firstWhereOrNull(
              (t) => t.id == npc.activeTaskId,
            )
          : null;

      final isResting = activeTask?.type == TaskType.rest;
      final hourIndex = _currentDate.hourIndex;
      final isScheduledToSleep =
          npc.schedule.getActivityForHour(hourIndex) == ScheduleActivity.sleep;
      final isFainted = npc.status == NPCStatus.fainted;

      if (!isResting && !isScheduledToSleep && !isFainted) {
        return false;
      }
    }
    return true;
  }

  void _handleEmergency() {
    if (_emergencyBehavior == 'pause') {
      _speed = GameSpeed.paused;
    } else if (_emergencyBehavior == 'slow') {
      _speed = GameSpeed.slow;
    } else if (_emergencyBehavior == 'normal') {
      _speed = GameSpeed.normal;
    }
    notifyListeners();
  }

  void _processPredators() {
    // Only check at night (e.g., 22:00 to 04:00)
    final hour = _currentDate.hour;
    if (hour < 22 && hour > 4) return;

    final foxCount = _npcs
        .where((n) => n.specimenType.toLowerCase() == 'fox')
        .length;

    if (foxCount == 0) {
      // Reintroduction logic: Small chance per minute to migrate back
      if (Random().nextDouble() < 0.0001) {
        for (int i = 0; i < 3; i++) {
          _npcs.add(
            FoxGenerator.createFox(
              "fox_${_currentDate.totalMinutes}_$i",
              _currentDate,
            ),
          );
        }
        // Silence this for now to avoid cluttering the Chronicle at start
        // _lastAnnouncement = "A pack of wild foxes has migrated onto the estate.";
      }
      return;
    }

    // Fox visits: each fox visits approximately once every 30 days
    // 1 day = 1440 mins. 30 days = 43200 mins.
    final coop = _rooms.firstWhereOrNull((r) => r.type == RoomType.chickenCoop);
    int coopEggs = 0;
    if (coop != null) {
      coopEggs = coop.inventory.where((i) => i.type == 'eggs' || i.name.toLowerCase().contains('egg')).fold(0, (a, b) => a + b.quantity);
    }

    double prob = foxCount / 43200.0;
    if (coopEggs > 9) {
      prob += 0.035; // High number of eggs acts as delicious fox bait!
    }

    if (Random().nextDouble() < prob) {
      _triggerFoxRaid();
    }
  }

  void _triggerFoxRaid() {
    // Check for guards (either manual task or scheduled activity)
    final hour = _currentDate.hour;
    final guards = _npcs.where((n) {
      final isScheduled =
          n.schedule.getActivityForHour(hour) == ScheduleActivity.guardCoop;
      final hasManualTask =
          n.activeTaskId != null &&
          _taskService.activeTasks.any(
            (t) => t.npcId == n.id && t.type == TaskType.guardCoop,
          );

      // Effectiveness check (Endurance and Hunger impact)
      final endurance = n.stats['endurance'] ?? 5;
      bool isEffective = endurance >= 1 && n.hunger < 80;

      return (isScheduled || hasManualTask) && isEffective;
    }).toList();

    final foxEntry = _npcs
        .where((n) => n.specimenType.toLowerCase() == 'fox')
        .firstOrNull;

    if (guards.isNotEmpty) {
      // Success! Capturing or killing a fox (High chance 90%)
      if (foxEntry != null && Random().nextDouble() < 0.90) {
        final foxIndex = _npcs.indexOf(foxEntry);
        _handleNpcDeath(foxIndex);
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] DEFENSE: A wild fox was intercepted by your guard and successfully recovered as a specimen!",
        );
        addItemToRoom(
          'chicken_coop',
          GameItem.create(
            name: 'Fox Specimen',
            type: 'fox_specimen',
            category: ItemCategory.specimen,
            quantity: 1,
          ),
        );
      }
    } else {
      // Fox wins - Roll for events
      final roll = Random().nextDouble();

      final coop = _rooms.firstWhereOrNull((r) => r.id == 'chicken_coop');
      if (roll < 0.3 &&
          coop != null &&
          coop.inventory.any(
            (i) => i.type == 'eggs' || i.type == 'fertilized_egg',
          )) {
        // Steal 1 egg
        final eggIndex = coop.inventory.indexWhere(
          (i) => i.type == 'eggs' || i.type == 'fertilized_egg',
        );
        final newInv = List<GameItem>.from(coop.inventory);
        newInv.removeAt(eggIndex);
        _rooms[_rooms.indexOf(coop)] = coop.copyWith(inventory: newInv);
        // Silence theft - no announcement
      } else if (roll < 0.1 && _chickens.isNotEmpty) {
        // Kill 1 chicken
        _chickens.removeAt(Random().nextInt(_chickens.length));
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] WILDLIFE: A fox has raided the coop. One chicken is lost.",
        );

        // Trigger "Intruder" crisis at the chicken coop
        final intruder = ManorCrisis(
          type: ManorCrisisType.intruder,
          roomId: 'chicken_coop',
          discoveryDate: _currentDate.toDateTime(),
          severity: 0.2,
          isDiscovered: true,
        );
        _crises.add(intruder);
      }
    }
    notifyListeners();
  }

  void _processHygiene() {
    // Rooms get dirty based on occupancy
    final roomNpcs = <String, int>{};
    for (var npc in _npcs.where((n) => n.currentRoomId != null)) {
      roomNpcs[npc.currentRoomId!] = (roomNpcs[npc.currentRoomId!] ?? 0) + 1;
    }

    for (int i = 0; i < _rooms.length; i++) {
      final room = _rooms[i];
      if (!room.isRestored || !room.isInsideManor) continue;

      int occupants = roomNpcs[room.id] ?? 0;
      double accumulation = 0.0001; // Base dust
      accumulation += occupants * 0.0005; // 0.03 per hour per person approx

      if (accumulation > 0) {
        _rooms[i] = room.copyWith(
          dirtiness: (room.dirtiness + accumulation).clamp(0.0, 1.0),
        );
      }
    }
  }

  void _processCrises() {
    // 1. Spontaneous crisis triggers
    bool newCrisisDetected = false;

    // Fire Triggers
    // Any restored room can catch fire, but it's very rare.
    // Kitchen and Laboratory have higher chances if active.
    for (int i = 0; i < _rooms.length; i++) {
      final room = _rooms[i];
      if (!room.isRestored) continue;
      if (_crises.any(
        (c) => c.type == ManorCrisisType.fire && c.roomId == room.id,
      )) {
        continue;
      }

      // 1. Spontaneous Fire Chance (Rare: ~once/month per room in aggregate)
      double fireChance = 0.0000002;
      // Extremely rare base chance per minute (~once a month total across ~10-15 rooms)

      if (room.type == RoomType.kitchen) {
        if (room.dirtiness > 0.5) fireChance *= 2;
        final isCooking = _taskService.activeTasks.any(
          (t) => t.type == TaskType.cook && t.targetId == room.id,
        );
        if (isCooking) fireChance *= 5;
      } else if (room.type == RoomType.laboratory ||
          room.type == RoomType.operatingRoom) {
        final isExperimenting = _taskService.activeTasks.any(
          (t) =>
              (t.type == TaskType.experiment ||
                  t.type == TaskType.dissect ||
                  t.type == TaskType.vivisection) &&
              t.targetId == room.id,
        );
        if (isExperimenting) fireChance *= 3;
      }

      if (Random().nextDouble() < fireChance) {
        final fire = ManorCrisis(
          type: ManorCrisisType.fire,
          roomId: room.id,
          discoveryDate: _currentDate.toDateTime(),
          severity: 0.1,
          isDiscovered:
              true, // For now, we discover them immediately for gameplay
        );
        _crises.add(fire);
        newCrisisDetected = true;
        final rIdx = _rooms.indexWhere((r) => r.id == room.id);
        if (rIdx != -1) {
          _rooms[rIdx] = _rooms[rIdx].copyWith(dirtiness: 1.0);
        }
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] EMERGENCY: A fire has broken out in the ${room.name}!",
        );
      }
    }

    // Golem Tantrum Triggers
    for (int i = 0; i < _npcs.length; i++) {
      final npc = _npcs[i];
      if (npc.metadata['isFleshGolem'] == true && npc.currentRoomId != null) {
        if (_crises.any((c) => c.type == ManorCrisisType.golemTantrum && c.roomId == npc.currentRoomId)) {
          continue;
        }
        
        bool shownCompassion = npc.metadata['shownCompassion'] == true;
        double baseTantrumChance = shownCompassion ? 0.000001 : 0.000005; // 5x higher risk if treated cruelly
        if (npc.satisfaction < 30) baseTantrumChance *= 4;
        if (npc.hunger > 70) baseTantrumChance *= 3;

        if (Random().nextDouble() < baseTantrumChance) {
          final tantrum = ManorCrisis(
            type: ManorCrisisType.golemTantrum,
            roomId: npc.currentRoomId!,
            discoveryDate: _currentDate.toDateTime(),
            severity: 0.2,
            isDiscovered: true,
          );
          _crises.add(tantrum);
          newCrisisDetected = true;
          final rIdx = _rooms.indexWhere((r) => r.id == npc.currentRoomId);
          if (rIdx != -1) {
            _rooms[rIdx] = _rooms[rIdx].copyWith(dirtiness: 1.0);
          }
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] EMERGENCY: ${npc.name} is throwing a violent Temper Tantrum in the ${_rooms.firstWhereOrNull((r) => r.id == npc.currentRoomId)?.name ?? 'Manor'}!",
          );
        }
      }
    }

    // 2. Crisis Progression & Spreading
    for (int i = _crises.length - 1; i >= 0; i--) {
      var crisis = _crises[i];
      double progression = 0.001; // Increase severity by 0.1% per minute

      if (crisis.type == ManorCrisisType.fire) {
        final roomIndex = _rooms.indexWhere((r) => r.id == crisis.roomId);
        if (roomIndex != -1) {
          progression += _rooms[roomIndex].dirtiness * 0.002;
          // Keep setting the room dirty as the fire burns
          _rooms[roomIndex] = _rooms[roomIndex].copyWith(dirtiness: 1.0);
        }

        // Fire progression speed check based on enqueued fighters
        final fighters = _taskService.activeTasks
            .where(
              (t) =>
                  t.type == TaskType.extinguishFire &&
                  t.targetId == crisis.roomId,
            )
            .length;
        if (fighters == 0) {
          // Unattended fire progression is 3x faster!
          progression *= 3.0;
        }

        // Fire Spreading logic: If fire is severe, it can jump to a neighbor
        if (crisis.severity > 0.4 &&
            Random().nextDouble() < (0.01 * crisis.severity)) {
          final neighborId = _getRandomAdjacentRoom(crisis.roomId);
          if (neighborId != null &&
              !_crises.any(
                (c) => c.roomId == neighborId && c.type == ManorCrisisType.fire,
              )) {
            final neighborFire = ManorCrisis(
              type: ManorCrisisType.fire,
              roomId: neighborId,
              discoveryDate: _currentDate.toDateTime(),
              severity: 0.05,
              isDiscovered: true,
            );
            _crises.add(neighborFire);
            newCrisisDetected = true;

            // Spread room immediately becomes dirty
            final neighborRoomIdx = _rooms.indexWhere(
              (r) => r.id == neighborId,
            );
            if (neighborRoomIdx != -1) {
              _rooms[neighborRoomIdx] = _rooms[neighborRoomIdx].copyWith(
                dirtiness: 1.0,
              );
            }

            final neighborRoom = _rooms.firstWhere((r) => r.id == neighborId);
            _announcementHistory.insert(
              0,
              "[${_currentDate.formattedTime}] WARNING: The fire in the manor is spreading to the ${neighborRoom.name}!",
            );
          }
        }
      }

      crisis = crisis.copyWith(
        severity: (crisis.severity + progression).clamp(0.0, 1.0),
      );
      _crises[i] = crisis;
    }

    // Configurable speed reduction when a new crisis is detected
    if (newCrisisDetected) {
      _handleEmergency();
    }

    // 3. Disaster Conditions
    // A fire is only fatal if it consumes too much of the manor.
    final totalFireSeverity = _crises
        .where((c) => c.type == ManorCrisisType.fire)
        .fold<double>(0, (sum, c) => sum + c.severity);

    final roomsEngulfed = _crises
        .where((c) => c.type == ManorCrisisType.fire && c.severity >= 1.0)
        .length;

    if (roomsEngulfed >= 4 || totalFireSeverity >= 3.0) {
      _triggerGameOver(
        "THE MANOR HAS BEEN UTTERLY CONSUMED BY AN UNSTOPPABLE CONFLAGRATION.",
      );
    } else if (roomsEngulfed >= 1) {
      // If a room is engulfed, it might damage people or resources, but not end game yet.
      // For now, we'll just announce it as a major loss.
    }

    if (_checkTotalFailure()) {
      _triggerGameOver(
        "THE RESIDENTS ARE CAPITULATED. NONE REMAIN TO STOP THE CONSUMING FLAME.",
      );
    }
  }

  String? _getRandomAdjacentRoom(String roomId) {
    // Simple logic: pick a random other restored room for now
    // In a more complex layout, we'd check actual adjacency
    final otherRooms = _rooms
        .where((r) => r.id != roomId && r.isRestored && r.isInsideManor)
        .toList();
    if (otherRooms.isEmpty) return null;
    return otherRooms[Random().nextInt(otherRooms.length)].id;
  }

  void _triggerGameOver(String reason) {
    if (_isGameOver) return;
    _isGameOver = true;
    _gameOverReason = reason;
    _speed = GameSpeed.paused;
    notifyListeners();
  }

  bool _checkTotalFailure() {
    // Only check for failure if there is a serious fire
    final seriousFire = _crises.any(
      (c) => c.type == ManorCrisisType.fire && c.severity > 0.4,
    );
    if (!seriousFire) return false;

    // A capable resident is one who is not dead, fainted, or broken
    final capable = _npcs.where(
      (n) =>
          n.status != NPCStatus.dead &&
          n.status != NPCStatus.fainted &&
          n.status != NPCStatus.broken &&
          n.energy > 5,
    );

    return capable.isEmpty && _npcs.isNotEmpty;
  }

  void buyChicken(ChickenBreedType type) {
    final breed = ChickenBreed.getByTyped(type);
    if ((resources['funds'] ?? 0) >= breed.basePrice) {
      updateResource('funds', -(breed.basePrice));
      _chickens.add(
        Chicken.create(
          type,
          _currentDate,
          isMale: type == ChickenBreedType.rooster,
          weight: type == ChickenBreedType.rooster ? 2.5 : 1.5,
        ),
      );
      notifyListeners();
    }
  }

  void buildGreenhouse(String roomId) {
    const costFunds = 200.0;
    const costWood = 100.0;
    if ((resources['funds'] ?? 0) >= costFunds &&
        (resources['wood'] ?? 0) >= costWood) {
      updateResource('funds', -(costFunds));
      updateResource('wood', -(costWood));

      final index = _rooms.indexWhere((r) => r.id == roomId);
      if (index != -1) {
        _rooms[index] = _rooms[index].copyWith(
          type: RoomType.greenhouse,
          name: 'Greenhouse',
          description:
              'A glass-walled sanctuary for delicate plants and research.',
        );
      }
      _lastAnnouncement = "Construction of the Greenhouse is complete!";
      notifyListeners();
    } else {
      _lastAnnouncement =
          "Insufficient resources to build Greenhouse (Need 200 Funds, 100 Wood).";
      notifyListeners();
    }
  }

  void buildTenement(String roomId) {
    const costFunds = 400.0;
    const costWood = 200.0;
    if ((resources['funds'] ?? 0) >= costFunds &&
        (resources['wood'] ?? 0) >= costWood) {
      updateResource('funds', -(costFunds));
      updateResource('wood', -(costWood));

      final index = _rooms.indexWhere((r) => r.id == roomId);
      if (index != -1) {
        _rooms[index] = _rooms[index].copyWith(
          type: RoomType.tenement,
          name: 'Tenement',
          description: 'A large housing block for multiple residents.',
          beds: [
            Bed(type: BedType.twin, assignedNpcIds: [null]),
            Bed(type: BedType.twin, assignedNpcIds: [null]),
            Bed(type: BedType.twin, assignedNpcIds: [null]),
            Bed(type: BedType.twin, assignedNpcIds: [null]),
          ],
        );
      }
      _lastAnnouncement = "Construction of the Tenement is complete!";
      notifyListeners();
    } else {
      _lastAnnouncement =
          "Insufficient resources to build Tenement (Need 400 Funds, 200 Wood).";
      notifyListeners();
    }
  }

  void convertRoomToLaboratory(String roomId) {
    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index == -1) return;
    final r = _rooms[index];

    if (!r.isRestored) {
      _lastAnnouncement =
          "The room must be restored before it can be converted.";
      notifyListeners();
      return;
    }

    // Restriction: Only Attic or Basement
    if (r.floor != Floor.attic && r.floor != Floor.basement) {
      _lastAnnouncement =
          "A Laboratory must be secluded. Only attic or basement rooms are suitable.";
      notifyListeners();
      return;
    }

    const costFunds = 1000.0;
    const costWood = 50.0;
    if ((resources['funds'] ?? 0) >= costFunds &&
        (resources['wood'] ?? 0) >= costWood) {
      updateResource('funds', -(costFunds));
      updateResource('wood', -(costWood));

      _rooms[index] = r.copyWith(
        isUnderConstruction: true,
        constructionTarget: 'laboratory',
      );
      _lastAnnouncement = "Laboratory construction project started!";
      notifyListeners();
    } else {
      _lastAnnouncement =
          "Insufficient resources for Laboratory conversion (Need 1000 Funds, 50 Wood).";
      notifyListeners();
    }
  }

  void convertRoomToMine(String roomId) {
    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index == -1) return;
    final r = _rooms[index];

    final resType = r.metadata['resourceType'] as String?;
    if (resType == null || resType == 'oil_well_site') return;

    final costMap = getMineConstructionCost(resType, ManorLayout.grid[r.id]?.$2.abs().toInt() ?? 2);
    final costFunds = costMap['funds'] as double;
    final costWood = costMap['wood'] as double;

    if ((resources['funds'] ?? 0) >= costFunds &&
        (resources['wood'] ?? 0) >= costWood) {
      updateResource('funds', -costFunds);
      updateResource('wood', -costWood);

      _rooms[index] = r.copyWith(
        isUnderConstruction: true,
        constructionTarget: 'mine',
      );
      _lastAnnouncement = "Mine construction project started!";
      notifyListeners();
    } else {
      _lastAnnouncement =
          "Insufficient resources to establish mine (Need ${costFunds.toInt()} Funds, ${costWood.toInt()} Wood).";
      notifyListeners();
    }
  }

  void convertRoomToOilWell(String roomId) {
    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index == -1) return;
    final r = _rooms[index];

    if (r.id != 'basement_e') {
      _lastAnnouncement = "An Oil Well can only be constructed at the specific well-site chamber (Basement Level 2, Col 1).";
      notifyListeners();
      return;
    }

    const costFunds = 1500.0;
    const costWood = 300.0;

    if ((resources['funds'] ?? 0) >= costFunds &&
        (resources['wood'] ?? 0) >= costWood) {
      updateResource('funds', -costFunds);
      updateResource('wood', -costWood);

      _rooms[index] = r.copyWith(
        isUnderConstruction: true,
        constructionTarget: 'oil_well',
      );
      _lastAnnouncement = "Oil Well construction project started!";
      notifyListeners();
    } else {
      _lastAnnouncement =
          "Insufficient resources to establish Oil Well (Need 1500 Funds, 300 Wood).";
      notifyListeners();
    }
  }

  void decommissionOilWell(String roomId) {
    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index == -1) return;
    final r = _rooms[index];

    if (r.type != RoomType.oilWell) return;

    _rooms[index] = r.copyWith(
      name: 'Subterranean Vault',
      type: RoomType.unused,
      isRestored: true,
      description: 'An ordinary basement chamber.',
    );
    _lastAnnouncement = "Successfully decommissioned the Oil Well.";
    notifyListeners();
  }

  Map<String, dynamic> getMineConstructionCost(String resourceType, int floor) {
    double funds = 2000;
    double wood = 300;
    int durationMinutes = 360;
    final depthFactor = floor.abs(); // 2, 3, 4

    switch (resourceType) {
      case 'coal':
        funds = 1000.0 * depthFactor;
        wood = 200.0 * depthFactor;
        durationMinutes = 180 * depthFactor;
        break;
      case 'copper':
      case 'iron':
        funds = 1500.0 * depthFactor;
        wood = 300.0 * depthFactor;
        durationMinutes = 200 * depthFactor;
        break;
      case 'silver':
      case 'cobalt':
      case 'nickel':
      case 'lithium':
        funds = 2000.0 * depthFactor;
        wood = 400.0 * depthFactor;
        durationMinutes = 240 * depthFactor;
        break;
      case 'gold':
      case 'titanium':
      case 'jadeite':
        funds = 3000.0 * depthFactor;
        wood = 500.0 * depthFactor;
        durationMinutes = 300 * depthFactor;
        break;
      case 'diamonds':
      case 'uranium':
        funds = 5000.0 * depthFactor;
        wood = 800.0 * depthFactor;
        durationMinutes = 360 * depthFactor;
        break;
      default:
        break;
    }

    return {
      'funds': funds,
      'wood': wood,
      'duration': durationMinutes,
    };
  }

  void cancelRoomConversion(String roomId) {
    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index == -1) return;
    final r = _rooms[index];
    if (!r.isUnderConstruction) return;

    // Find any active construction task for this room
    final activeTask = _taskService.activeTasks.firstWhereOrNull(
      (t) => t.targetId == roomId && t.type == TaskType.construction,
    );

    double refundRatio = 1.0; // default 100% refund

    if (activeTask != null) {
      final total = activeTask.totalMinutes;
      final remaining = activeTask.minutesRemaining;
      if (remaining < total) {
        refundRatio = 0.5; // some work has been done! Only 50% refund.
      }
      // Cancel active construction task
      cancelTask(activeTask.id);
    }

    // Also search enqueued intent queue for any npcs enqueued to construct
    for (int i = 0; i < _npcs.length; i++) {
      _npcs[i].intentQueue.removeWhere(
        (intent) =>
            intent.action == TaskType.construction &&
            intent.targetRoomId == roomId,
      );
    }

    // Recover costs
    double refundFunds = 0.0;
    double refundWood = 0.0;

    if (r.constructionTarget == 'laboratory') {
      refundFunds = 1000.0 * refundRatio;
      refundWood = 50.0 * refundRatio;
    } else if (r.constructionTarget == 'mine') {
      final resType = r.metadata['resourceType'] as String?;
      final costMap = getMineConstructionCost(resType ?? 'coal', ManorLayout.grid[r.id]?.$2.abs().toInt() ?? 2);
      refundFunds = (costMap['funds'] as double) * refundRatio;
      refundWood = (costMap['wood'] as double) * refundRatio;
    } else if (r.constructionTarget == 'oil_well') {
      refundFunds = 1500.0 * refundRatio;
      refundWood = 300.0 * refundRatio;
    }

    updateResource('funds', refundFunds);
    updateResource('wood', refundWood);

    // Revert room status
    _rooms[index] = r.copyWith(
      isUnderConstruction: false,
      constructionTarget: null,
    );

    _lastAnnouncement =
        "Room conversion project canceled! Recovered ${(refundRatio * 100).round()}% of setup costs (${refundFunds.round()} CHF, ${refundWood.round()} Wood).";
    notifyListeners();
  }

  void convertUnusedToBedroom(String roomId) {
    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index == -1) return;
    final r = _rooms[index];

    if (!r.isRestored) {
      _lastAnnouncement =
          "The room must be restored before it can be converted.";
      notifyListeners();
      return;
    }

    if (r.type != RoomType.unused || r.floor != Floor.ground) {
      _lastAnnouncement =
          "Only the ground floor unused wing can be converted into a bedroom.";
      notifyListeners();
      return;
    }

    const costFunds = 500.0;
    const costWood = 250.0;
    if ((resources['funds'] ?? 0) >= costFunds &&
        (resources['wood'] ?? 0) >= costWood) {
      updateResource('funds', -(costFunds));
      updateResource('wood', -(costWood));

      _rooms[index] = r.copyWith(
        isUnderConstruction: true,
        constructionTarget: 'bedroom',
      );
      _lastAnnouncement = "Bedroom construction project started!";
      notifyListeners();
    } else {
      _lastAnnouncement =
          "Insufficient resources to convert to Bedroom (Need 500 Funds, 250 Wood).";
      notifyListeners();
    }
  }

  void _processConstruction() {
    // Construction progress is now labor-driven (handled in _handleTaskCompletion)
    // We only check for completion here if a project was somehow marked as done
    for (int i = _activeConstruction.length - 1; i >= 0; i--) {
      final project = _activeConstruction[i];
      if (project.progress >= 1.0) {
        _completeConstruction(project);
        _activeConstruction.removeAt(i);
      }
    }
  }

  void _completeConstruction(ConstructionProject project) {
    final bp = project.blueprint;
    final newRoom = Room.initial(
      "${bp.id}_${DateTime.now().millisecondsSinceEpoch}",
      bp.name,
      bp.type,
      bp.floor,
      width: bp.width,
      description: bp.description,
    );
    _rooms.add(newRoom);
    _lastAnnouncement = "${bp.name} construction is complete!";
    notifyListeners();
  }

  void _processExperiments() {
    for (int i = _activeExperiments.length - 1; i >= 0; i--) {
      final experiment = _activeExperiments[i];
      experiment.minutesRemaining--;

      if (experiment.minutesRemaining <= 0) {
        experiment.isComplete = true;
        _completeExperiment(experiment);
        _activeExperiments.removeAt(i);
      }
    }
  }

  void _completeExperiment(Experiment experiment) {
    final subjectIndex = _npcs.indexWhere((n) => n.id == experiment.subjectId);
    if (subjectIndex != -1) {
      final subject = _npcs[subjectIndex];
      final result = ExperimentationService.processCompletion(
        experiment,
        subject,
      );

      _npcs[subjectIndex] = result['subject'] as NPC;

      final Map<String, num> gains = result['resources'] as Map<String, num>;
      gains.forEach((key, value) {
        updateResource(key, value);
      });

      final List<String> logs = result['logs'] as List<String>;
      if (logs.isNotEmpty) {
        _lastAnnouncement = logs.first;
      }

      final typeStr = experiment.type.name;
      if (!_performedExperiments.contains(typeStr)) {
        _performedExperiments.add(typeStr);
      }
      _checkObjectives();
    }
    notifyListeners();
  }

  List<Objective> _getChapter2Objectives() {
    return [
      Objective(
        id: 'chap2_explore_map',
        title: 'Chapter 2: The Expanding Domain',
        description: 'Explore the grand strategic World Map and uncover at least 8 Hex Coordinates.',
        type: ObjectiveType.tutorial,
        requirements: {'map_hexes_explored': 8},
      ),
      Objective(
        id: 'chap2_grow_population',
        title: 'Chapter 2: Sovereign Household',
        description: 'Upgrade residential Sleeping Quarters and recruit resident staff to grow Manor population to at least 12.',
        type: ObjectiveType.tutorial,
        requirements: {'manor_population': 12},
      ),
      Objective(
        id: 'chap2_raise_army',
        title: 'Chapter 2: The Standing Battalion',
        description: 'Muster an active military standing army containing at least 6 distinct tactical squads.',
        type: ObjectiveType.tutorial,
        requirements: {'standing_army_size': 6},
      ),
      Objective(
        id: 'chap2_win_combats',
        title: 'Chapter 2: Colosseum Triumphs',
        description: 'Deploy your army into the Arena Colosseum to achieve victory in at least 3 combats.',
        type: ObjectiveType.tutorial,
        requirements: {'combats_won': 3},
      ),
      Objective(
        id: 'chap2_make_money',
        title: 'Chapter 2: Industrial Capital',
        description: 'Amass a liquid sovereign treasury of at least 1,500 CHF cash reserves.',
        type: ObjectiveType.tutorial,
        requirements: {'treasury_funds': 1500},
      ),
      Objective(
        id: 'chap2_convert_rooms',
        title: 'Chapter 2: Architectural Renaissance',
        description: 'Commission master carpenters and masons to convert and restore at least 6 distinct specialized Manor Wing rooms.',
        type: ObjectiveType.tutorial,
        requirements: {'rooms_restored_count': 6},
      ),
      Objective(
        id: 'chap2_scientific_knowledge',
        title: 'Chapter 2: Scientific Enlightenment',
        description: 'Conduct fundamental research and experimental procedures to achieve Level 2 qualification across at least 3 academic disciplines.',
        type: ObjectiveType.science,
        requirements: {'science_level_count': 3},
      ),
      Objective(
        id: 'chap2_expand_cookbook',
        title: 'Chapter 2: Culinary Experimentation',
        description: 'Hired chefs successfully perform the New Recipe action in the Scullery to develop and unlock at least 4 culinary dishes.',
        type: ObjectiveType.tutorial,
        requirements: {'new_recipes_unlocked': 4},
      ),
      Objective(
        id: 'chap2_grow_plants',
        title: 'Chapter 2: Botanical Mastery',
        description: 'Cultivate the loamy soil of the Manor Garden and Greenhouse to bring at least 15 botanical crops to total harvest maturity.',
        type: ObjectiveType.tutorial,
        requirements: {'garden_harvests': 15},
      ),
      Objective(
        id: 'chap2_secret_societies',
        title: 'Chapter 2: Secret Society Factions',
        description: 'Engage in diplomatic dialogue, philosophical study, or priorate warfare to interact with and achieve formal faction standing with at least 2 distinct Victorian Secret Societies.',
        type: ObjectiveType.tutorial,
        requirements: {'secret_society_interactions': 2},
      ),
    ];
  }

  void _initializeObjectives() {
    _objectives.clear();
    _objectives.add(
      Objective(
        id: 'farming_tutorial_1',
        title: 'Break the Earth',
        description:
            'The fields have lain fallow for too long. Assign an NPC to till the soil in Field A.',
        type: ObjectiveType.tutorial,
        requirements: {
          'tasks_performed': ['tillSoil'],
        },
      ),
    );
    _objectives.add(
      Objective(
        id: 'build_laboratory',
        title: 'Secluded Research',
        description:
            'Establish a Laboratory in the Attic or Basement to begin advanced experiments (50 Wood, 1000 Funds).',
        type: ObjectiveType.science,
        requirements: {'room_type_exists': 'laboratory'},
      ),
    );
    _objectives.add(
      Objective(
        id: 'manor_restoration',
        title: 'The Great Restoration',
        description:
            'Rehabilitate every room within the Manor to bring the estate back to its former glory. (Reward: 1,000 Funds)',
        type: ObjectiveType.tutorial,
        requirements: {
          'rooms_cleaned': [
            'unused_1f',
            'library',
            'attic_1',
            'attic_2',
            'basement_1',
            'basement_2',
            'basement_3',
            'chicken_coop',
          ],
        },
      ),
    );
  }

  void _checkObjectives() {
    bool changed = false;
    final List<Objective> nextObjectives = [];

    for (var objective in _objectives.where((o) => !o.isCompleted).toList()) {
      bool completed = true;
      final reqs = objective.requirements;

      if (reqs.containsKey('rooms_cleaned')) {
        final targetRooms = List<String>.from(reqs['rooms_cleaned']);
        for (var roomId in targetRooms) {
          final room = _rooms.where((r) => r.id == roomId).firstOrNull;
          if (room == null || !room.isRestored) {
            completed = false;
            break;
          }
        }
      }

      if (reqs.containsKey('experiment_performed')) {
        final expType = reqs['experiment_performed'] as String;
        if (!_performedExperiments.contains(expType)) {
          completed = false;
        }
      }

      if (reqs.containsKey('room_type_exists')) {
        final targetType = reqs['room_type_exists'] as String;
        final hasType = _rooms.any(
          (r) => r.type.name == targetType && r.isRestored,
        );
        if (!hasType) {
          completed = false;
        }
      }

      if (reqs.containsKey('tasks_performed')) {
        final targetTasksList = reqs['tasks_performed'] as List<dynamic>;
        for (var t in targetTasksList) {
          final tStr = t.toString();
          final tType = TaskType.values
              .where((type) => type.name == tStr)
              .firstOrNull;
          if (tType == null || !_completedTaskTypes.contains(tType)) {
            completed = false;
            break;
          }
        }
      }

      if (reqs.containsKey('crop_ready')) {
        final readyType = reqs['crop_ready'] as String;
        bool found = false;
        for (var c in _crops) {
          if (c.type.name == readyType && c.isHarvestable) {
            found = true;
            break;
          }
        }
        if (!found) {
          completed = false;
        }
      }

      if (reqs.containsKey('task_counts')) {
        final targetCounts = reqs['task_counts'] as Map<String, dynamic>;
        for (var entry in targetCounts.entries) {
          final tStr = entry.key;
          final count = entry.value as int;
          final tType = TaskType.values
              .where((t) => t.name == tStr)
              .firstOrNull;
          if (tType != null) {
            if ((_taskCompletionCounts[tType] ?? 0) < count) {
              completed = false;
              break;
            }
          } else {
            if ((_customTaskCounts[tStr] ?? 0) < count) {
              completed = false;
              break;
            }
          }
        }
      }

      if (reqs.containsKey('map_hexes_explored')) {
        final count = reqs['map_hexes_explored'] as int;
        if (_exploredHexesCount < count) completed = false;
      }
      if (reqs.containsKey('manor_population')) {
        final count = reqs['manor_population'] as int;
        if (_npcs.where((n) => n.isResident).length < count) completed = false;
      }
      if (reqs.containsKey('standing_army_size')) {
        final count = reqs['standing_army_size'] as int;
        final pIdx = _npcs.indexWhere((n) => n.isPlayer);
        final pArmySize = pIdx != -1 ? _npcs[pIdx].lastEscortIds.length : 0;
        if (pArmySize < count) completed = false;
      }
      if (reqs.containsKey('combats_won')) {
        final count = reqs['combats_won'] as int;
        if ((_customTaskCounts['combats_won'] ?? 0) < count) completed = false;
      }
      if (reqs.containsKey('treasury_funds')) {
        final count = reqs['treasury_funds'] as int;
        if ((resources['funds'] ?? 0) < count) completed = false;
      }
      if (reqs.containsKey('rooms_restored_count')) {
        final count = reqs['rooms_restored_count'] as int;
        if (_rooms.where((r) => r.isRestored).length < count) completed = false;
      }
      if (reqs.containsKey('science_level_count')) {
        final count = reqs['science_level_count'] as int;
        if (_researchPoints.values.where((pts) => pts >= 20.0).length < count) completed = false;
      }
      if (reqs.containsKey('new_recipes_unlocked')) {
        final count = reqs['new_recipes_unlocked'] as int;
        if (_knownRecipes.length < count) completed = false;
      }
      if (reqs.containsKey('garden_harvests')) {
        final count = reqs['garden_harvests'] as int;
        if ((_customTaskCounts['garden_harvests'] ?? 0) < count) completed = false;
      }
      if (reqs.containsKey('secret_society_interactions')) {
        final count = reqs['secret_society_interactions'] as int;
        if ((_customTaskCounts['secret_society_interactions'] ?? 0) < count) completed = false;
      }

      if (completed) {
        objective.isCompleted = true;
        changed = true;
        _unreadObjectiveCount++;
        _lastAnnouncement = "OBJECTIVE COMPLETE: ${objective.title}";
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] QUEST: ${objective.title} COMPLETED",
        );

        // Apply Rewards
        if (objective.id == 'manor_restoration') {
          updateResource('funds', 1000);
          _lastAnnouncement =
              "THE MANOR IS RESTORED. A BOUNTY OF 1000 FUNDS HAS BEEN AWARDED.";
        } else if (objective.id == 'farming_tutorial_5') {
          updateResource('funds', 100);
          updateResource('wood', 100);
          _lastAnnouncement =
              "HARVEST COMPLETE. YOU HAVE BEEN REWARDED WITH 100 FUNDS AND 100 WOOD.";
        } else if (objective.id == 'first_construct_1') {
          _objectives.add(
            Objective(
              id: 'first_construct_2',
              title: 'The First Construct - Step 2',
              description:
                  'Perform Dissection (using a small creature) two times.',
              type: ObjectiveType.science,
              requirements: {
                'task_counts': {'dissect': 2},
              },
              nextObjectiveId: 'first_construct_3',
            ),
          );
        } else if (objective.id == 'first_construct_2') {
          _objectives.add(
            Objective(
              id: 'first_construct_3',
              title: 'The First Construct - Step 3',
              description:
                  'Perform Vivisection (using a small creature) two times.',
              type: ObjectiveType.science,
              requirements: {
                'task_counts': {'vivisection': 2},
              },
              nextObjectiveId: 'first_construct_4',
            ),
          );
        } else if (objective.id == 'first_construct_3') {
          if (!_unlockedLabActivities.contains('reanimation_procedure')) {
            _unlockedLabActivities.add('reanimation_procedure');
            _triggerMobileFireworksNotification("GALVANIC REANIMATION UNLOCKED", "You have discovered the master principles of galvanic life! You can now perform Reanimation procedures in the Laboratory.");
          }
          _objectives.add(
            Objective(
              id: 'first_construct_4',
              title: 'The First Construct - Step 4',
              description:
                  'Perform a Reanimation experiment on a subject in the Laboratory. Move a character there, open the Laboratory view, and start the GALVANIC REANIMATION procedure.',
              type: ObjectiveType.science,
              requirements: {'experiment_performed': 'reanimation'},
            ),
          );
        } else if (objective.id == 'first_construct_4') {
          if (_activeChapter == 1) {
            _activeChapter = 2;
            _showChapter2Modal = true;
            _lastAnnouncement = "CHAPTER 2: THE EXPANDING DOMAIN UNLOCKED!";
            _announcementHistory.insert(
              0,
              "[${_currentDate.formattedTime}] CHAPTER 2: The Modern Prometheus Unlocked.",
            );
            _objectives.addAll(_getChapter2Objectives());
          }
        } else if (objective.id == 'build_laboratory') {
          updateResource('funds', 200);
          _lastAnnouncement =
              "LABORATORY ESTABLISHED. RESEARCH GRANTS OF 200 FUNDS HAVE BEEN DISBURSED.";
        }

        // Handle follow-up objectives
        if (objective.id == 'manor_restoration') {
          nextObjectives.add(
            Objective(
              id: 'zoology_curiosity',
              title: 'Zoological Curiosity',
              description: 'Reach Zoology Level 1 to unlock advanced study.',
              type: ObjectiveType.science,
              requirements: {
                'research_level': {'Zoology': 1},
              },
            ),
          );
        } else if (objective.id == 'zoology_curiosity') {
          nextObjectives.add(
            Objective(
              id: 'the_spark',
              title: 'The Spark',
              description:
                  'Reach Alchemy Level 2 to discover reanimation principles.',
              type: ObjectiveType.science,
              requirements: {
                'research_level': {'Alchemy': 2},
              },
            ),
          );
        } else if (objective.id == 'farming_tutorial_1') {
          nextObjectives.add(
            Objective(
              id: 'farming_tutorial_2',
              title: 'Enrich the Soil',
              description:
                  'The earth needs nutrients. Assign an NPC to fertilize Field A.',
              type: ObjectiveType.tutorial,
              requirements: {
                'tasks_performed': ['fertilizeSoil'],
              },
            ),
          );
        } else if (objective.id == 'farming_tutorial_2') {
          nextObjectives.add(
            Objective(
              id: 'farming_tutorial_3',
              title: 'Sow the Seeds',
              description:
                  'The earth is prepared. Assign an NPC to plant cabbage seeds in Field A.',
              type: ObjectiveType.tutorial,
              requirements: {
                'tasks_performed': ['plantCrops'],
              },
            ),
          );
        } else if (objective.id == 'farming_tutorial_3') {
          nextObjectives.add(
            Objective(
              id: 'farming_tutorial_4',
              title: 'Care for the Young',
              description:
                  'The seeds will wither without water. Ensure the fields are watered.',
              type: ObjectiveType.tutorial,
              requirements: {
                'tasks_performed': ['waterCrops'],
              },
            ),
          );
        } else if (objective.id == 'farming_tutorial_4') {
          nextObjectives.add(
            Objective(
              id: 'farming_tutorial_wait',
              title: 'Patience and Care',
              description:
                  'Wait for the cabbage to be ready for harvest. Keep it watered in the meantime.',
              type: ObjectiveType.tutorial,
              requirements: {'crop_ready': 'cabbage'},
            ),
          );
        } else if (objective.id == 'farming_tutorial_wait') {
          nextObjectives.add(
            Objective(
              id: 'farming_tutorial_5',
              title: 'The First Harvest',
              description:
                  'The cabbage is ready. Assign an NPC to harvest the garden.',
              type: ObjectiveType.tutorial,
              requirements: {
                'tasks_performed': ['harvestCrops'],
              },
            ),
          );
        } else if (objective.id == 'build_laboratory') {
          nextObjectives.add(
            Objective(
              id: 'zoology_curiosity',
              title: 'Zoological Curiosity',
              description: 'Reach Zoology Level 1 to unlock advanced study.',
              type: ObjectiveType.science,
              requirements: {
                'research_level': {'Zoology': 1},
              },
            ),
          );
        }
      }
    }

    if (nextObjectives.isNotEmpty) {
      _objectives.addAll(nextObjectives);
      changed = true;
    }

    if (changed) notifyListeners();
  }

  void _checkDiscoveries() {
    bool changed = false;
    for (var discovery in Discovery.allDiscoveries) {
      if (_unlockedDiscoveries.contains(discovery.id)) continue;

      bool met = false;
      if (discovery.id == 'basic_reanimation') {
        met = (_researchPoints['Small Creature Anatomy'] ?? 0) >= 10.0 || (_researchPoints['Anatomy'] ?? 0) >= 10.0 || (_researchPoints['Alchemy'] ?? 0) >= 10.0;
      } else if (discovery.id == 'freezing_tech') {
        met = (_researchPoints['Alchemy'] ?? 0) >= 30.0; // Gated behind Alchemy
      } else if (discovery.id == 'artificial_muscle') {
        met =
            (_researchPoints['Anatomy'] ?? 0) >= 20.0 &&
            (_researchPoints['Zoology'] ?? 0) >= 20.0;
      }

      if (met) {
        _unlockedDiscoveries.add(discovery.id);
        changed = true;
        _lastAnnouncement = "NEW DISCOVERY: ${discovery.name}!";
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] SCIENCE: ${discovery.name} unlocked.",
        );
      }
    }
    if (changed) notifyListeners();
  }

  void assignNpcToBed(
    String npcId,
    String roomId,
    int bedIndex,
    int spotIndex,
  ) {
    // 1. Unassign from previous bed if any
    for (int i = 0; i < _rooms.length; i++) {
      final room = _rooms[i];
      List<Bed> updatedBeds = [];
      bool changed = false;
      for (var bed in room.beds) {
        if (bed.assignedNpcIds.contains(npcId)) {
          final newSpots = List<String?>.from(bed.assignedNpcIds);
          final idx = newSpots.indexOf(npcId);
          newSpots[idx] = null;
          updatedBeds.add(bed.copyWith(assignedNpcIds: newSpots));
          changed = true;
        } else {
          updatedBeds.add(bed);
        }
      }
      if (changed) {
        _rooms[i] = room.copyWith(beds: updatedBeds);
      }
    }

    // 2. Assign to new bed
    final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex != -1) {
      final room = _rooms[roomIndex];
      if (bedIndex < room.beds.length) {
        final bed = room.beds[bedIndex];
        if (spotIndex < bed.assignedNpcIds.length) {
          final newSpots = List<String?>.from(bed.assignedNpcIds);
          newSpots[spotIndex] = npcId;
          final updatedBeds = List<Bed>.from(room.beds);
          updatedBeds[bedIndex] = bed.copyWith(assignedNpcIds: newSpots);
          _rooms[roomIndex] = room.copyWith(beds: updatedBeds);
        }
      }
    }

    // 3. Update NPC's assignedRoomId
    final npcIndex = _npcs.indexWhere((n) => n.id == npcId);
    if (npcIndex != -1) {
      _npcs[npcIndex] = _npcs[npcIndex].copyWith(assignedRoomId: roomId);
    }

    notifyListeners();
  }

  void unassignNpcFromBed(String npcId) {
    for (int i = 0; i < _rooms.length; i++) {
      final room = _rooms[i];
      List<Bed> updatedBeds = [];
      bool changed = false;
      for (var bed in room.beds) {
        if (bed.assignedNpcIds.contains(npcId)) {
          final newSpots = List<String?>.from(bed.assignedNpcIds);
          final idx = newSpots.indexOf(npcId);
          newSpots[idx] = null;
          updatedBeds.add(bed.copyWith(assignedNpcIds: newSpots));
          changed = true;
        } else {
          updatedBeds.add(bed);
        }
      }
      if (changed) {
        _rooms[i] = room.copyWith(beds: updatedBeds);
      }
    }

    final npcIndex = _npcs.indexWhere((n) => n.id == npcId);
    if (npcIndex != -1) {
      _npcs[npcIndex] = _npcs[npcIndex].copyWith(clearAssignedRoom: true);
    }

    notifyListeners();
  }

  void startExperiment(Experiment experiment) {
    _activeExperiments.add(experiment);
    // Update NPC status
    final index = _npcs.indexWhere((n) => n.id == experiment.subjectId);
    if (index != -1) {
      _npcs[index] = _npcs[index].copyWith(status: NPCStatus.working);
    }
    _lastAnnouncement =
        "Experiment started on ${_npcs.firstWhere((n) => n.id == experiment.subjectId).name}.";
    notifyListeners();
  }

  void startConstruction(ConstructionBlueprint blueprint) {
    num availableFunds = (resources['funds'] ?? 0);
    num neededFunds = (blueprint.cost['funds'] ?? 0);
    num availableWood = (resources['wood'] ?? 0);
    num neededWood = (blueprint.cost['wood'] ?? 0);

    if (availableFunds.round() >= neededFunds.round() &&
        availableWood.round() >= neededWood.round()) {
      setResource('funds', (availableFunds - neededFunds).round());
      setResource('wood', (availableWood - neededWood).round());

      _activeConstruction.add(
        ConstructionProject(
          id: const Uuid().v4(),
          blueprint: blueprint,
          minutesRemaining: blueprint.durationMinutes,
        ),
      );
      _lastAnnouncement = "Construction started on ${blueprint.name}.";
      notifyListeners();
    }
  }

  String? _generateRichVictorianObservation(NPC npc) {
    final random = Random();
    final cat = random.nextInt(3);
    
    switch (cat) {
      case 0: // A) How they're feeling
        if (npc.energy < 30) return "I feel utterly exhausted... I must rest soon.";
        if (npc.hunger > 70) return "My stomach is growling. A rich Victorian meal would be delightful.";
        if (npc.cleanliness < 40) return "I feel quite grimy. A proper wash is in order.";
        if (npc.satisfaction < 30) return "This constant toil feels utterly grim and thankless.";
        
        final otherRes = _npcs.where((n) => n.isResident && n.id != npc.id).toList();
        if (otherRes.isNotEmpty) {
          final target = otherRes[random.nextInt(otherRes.length)];
          final rel = npc.relationships[target.id];
          if (rel != null) {
            if (rel.respect > 50) return "${target.name} has been remarkably steadfast and dutiful lately.";
            if (rel.admiration > 50) return "I find myself admiring ${target.name}'s quiet dedication.";
            if (rel.fear > 50) return "There is something utterly unsettling about ${target.name}'s presence...";
          }
          return "Having ${target.name} share these manor halls brings a curious solace.";
        }
        return "I feel exceptionally focused and hale today, ready for the trials ahead.";

      case 1: // B) What they've been up to
        final profs = npc.proficiencies.keys.toList();
        if (profs.isNotEmpty) {
          final pName = profs[random.nextInt(profs.length)];
          if (random.nextBool()) {
            return "My masterwork in $pName is proceeding magnificently.";
          }
        }
        final statOptions = ['strength', 'endurance', 'dexterity', 'perception', 'intellect'];
        final chosenStat = statOptions[random.nextInt(statOptions.length)];
        return "Through strict Victorian discipline, I think I've increased my $chosenStat.";

      case 2: // C) Occasionally make useful observations
        final obsPool = [];
        
        final totalFood = resources.entries.where((e) => e.key.contains('meal') || e.key.contains('food') || e.key.contains('stew')).fold(0.0, (a, b) => a + b.value);
        if (totalFood < 10) obsPool.add("We're running remarkably low on prepared food.");
        
        final totalIng = resources.entries.where((e) => e.key == 'flour' || e.key == 'eggs' || e.key == 'cheese' || e.key == 'tomato' || e.key == 'meat').fold(0.0, (a, b) => a + b.value);
        if (totalIng < 15) obsPool.add("We're running low on basic ingredients in the pantry.");

        final dryCrops = _crops.where((c) => c.moistureLevel < 0.3).toList();
        if (dryCrops.isNotEmpty) {
          final fieldLetters = ['A', 'B', 'C', 'D'];
          final fieldLetter = fieldLetters[random.nextInt(fieldLetters.length)];
          obsPool.add("Field $fieldLetter is looking remarkably dry. It requires immediate care.");
        }

        final coop = _rooms.firstWhereOrNull((r) => r.type == RoomType.chickenCoop);
        if (coop != null) {
          final eggs = coop.inventory.where((i) => i.type == 'eggs' || i.name.toLowerCase().contains('egg')).fold(0, (a, b) => a + b.quantity);
          if (eggs >= 10) obsPool.add("There's a massive bunch of eggs gathered in the Chicken Coop.");
        }

        final study = _rooms.firstWhereOrNull((r) => r.type == RoomType.study);
        if (study != null) {
          final rats = study.inventory.where((i) => i.id.contains('rat') || i.name.toLowerCase().contains('rat')).fold(0, (a, b) => a + b.quantity);
          if (rats > 0) {
            obsPool.add("You know you've got a bunch of rats nesting in your Study, right?");
            obsPool.add("By the way, I left a few rats scurrying in the Study for your experiments.");
          }
        }
        
        if (obsPool.isNotEmpty) {
          return obsPool[random.nextInt(obsPool.length)] as String;
        }
        return "The structural foundations of this East Wing hum with an unsettling resonance.";
    }
    return null;
  }

  void _updateNpcs() {
    final Set<String> claimedWorkstations = {};
    // Pre-populate with currently active tasks AND enqueued high-priority intents
    for (var n in _npcs) {
      if (n.activeTaskId != null) {
        final task = _taskService.activeTasks.firstWhereOrNull(
          (t) => t.id == n.activeTaskId,
        );
        if (task != null && task.targetId != null) {
          if (!TaskService.isConcurrent(task.type)) {
            claimedWorkstations.add(task.targetId!);
          }
        }
      }
      // Also pre-populate with what others are PLANNING to do immediately
      if (n.intentQueue.isNotEmpty) {
        final next = n.intentQueue.first;
        if (next.targetRoomId != null &&
            !TaskService.isConcurrent(next.action)) {
          claimedWorkstations.add(next.targetRoomId!);
        }
      }
    }

    // Deterministic Resolution Order: Player > Giles > Join Date/Index
    final List<int> sortedIndices = List.generate(_npcs.length, (i) => i);
    sortedIndices.sort((a, b) {
      final npc1 = _npcs[a];
      final npc2 = _npcs[b];

      if (npc1.isPlayer != npc2.isPlayer) {
        return npc1.isPlayer ? -1 : 1;
      }
      if (npc1.role == 'Butler' && npc2.role != 'Butler') {
        return -1;
      }
      if (npc2.role == 'Butler' && npc1.role != 'Butler') {
        return 1;
      }
      return a.compareTo(b); // Arrival order fallback
    });

    final random = Random();

    for (var i in sortedIndices) {
      final initialNpc = _npcs[i];

      _evaluateBehaviorTree(i, claimedWorkstations: claimedWorkstations);
      var currentNpc = _npcs[i]; // Refresh after evaluation

      // Movement Logic
      if (currentNpc.targetRoomId != null ||
          currentNpc.movementPath.isNotEmpty) {
        _processNpcMovement(i);
        currentNpc = _npcs[i]; // Refresh after movement
      }

      // Status Duration Tracking
      final bool statusChanged = initialNpc.status != currentNpc.status;
      final bool taskChanged =
          initialNpc.activeTaskId != currentNpc.activeTaskId;

      if (taskChanged || statusChanged) {
        _npcs[i] = currentNpc.copyWith(currentStateTicks: 0);
        currentNpc = _npcs[i];
      } else if (currentNpc.status != NPCStatus.idle &&
          currentNpc.status != NPCStatus.dead &&
          currentNpc.status != NPCStatus.sleeping &&
          currentNpc.status != NPCStatus.fainted &&
          currentNpc.status != NPCStatus.broken) {
        final newTicks = currentNpc.currentStateTicks + 1;
        // 18 hour timeout (1080 ticks)
        if (newTicks > 1080) {
          final preferredRoom = currentNpc.assignedRoomId ?? _butlerRoomId;
          _npcs[i] = currentNpc.copyWith(
            status: NPCStatus.idle,
            activeTaskId: null,
            targetRoomId: preferredRoom,
            movementProgress: (preferredRoom == currentNpc.currentRoomId)
                ? 1.0
                : 0.0,
            currentStateTicks: 0,
            currentThought: "I've been here too long...",
          );
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] ${currentNpc.name} stalled and reset their activity.",
          );
        } else {
          _npcs[i] = currentNpc.copyWith(currentStateTicks: newTicks);
        }
      }

      // Needs Simulation
      _processNpcNeeds(i);

      // World Travel Simulation
      _processNpcTravel(i);

      // Visitor Departure tracking
      currentNpc = _npcs[i];
      if (!currentNpc.isResident &&
          currentNpc.role != 'Minion' &&
          currentNpc.worldDestinationId == null) {
        final newMinutes = currentNpc.minutesStaying + 1;
        if (newMinutes > 180) {
          // Leave after 3 hours
          _npcs[i] = _npcs[i].copyWith(
            minutesStaying: newMinutes,
            worldDestinationId: 'road',
            worldTravelProgress: 0.0,
            currentThought: "I should head out now.",
            status: NPCStatus.idle,
          );
        } else {
          _npcs[i] = _npcs[i].copyWith(minutesStaying: newMinutes);
        }
      }

      // 2 & 3. Ephemeral Speech Bubbles and Rich Victorian Observations
      currentNpc = _npcs[i];
      if (currentNpc.isResident) {
        int cooldown = _npcDialogueCooldown[currentNpc.id] ?? 0;
        if (cooldown > 0) {
          cooldown--;
          _npcDialogueCooldown[currentNpc.id] = cooldown;
        }

        String? activeThought = currentNpc.currentThought;
        // Let active thoughts stay up for exactly 30 game minutes (or 3 real seconds at lightning speed) so the player can actually read them!
        if (activeThought != null && random.nextDouble() < 0.10) {
          activeThought = null;
        }

        if (activeThought == null && cooldown <= 0) {
          activeThought = _generateRichVictorianObservation(currentNpc);
          
          int targetCooldown = 120;
          if (_speed == GameSpeed.lightning) targetCooldown = 480;
          else if (_speed == GameSpeed.fast) targetCooldown = 240;
          else targetCooldown = 120;
          
          _npcDialogueCooldown[currentNpc.id] = targetCooldown;
        }

        if (activeThought != currentNpc.currentThought) {
          _npcs[i] = currentNpc.copyWith(currentThought: activeThought);
        }
      }
    }

    // Cleanup NPCs that finished traveling away
    _npcs.removeWhere(
      (n) =>
          !n.isResident &&
          n.worldDestinationId == 'road' &&
          n.worldTravelProgress >= 1.0,
    );

    if (_pendingNpcRemovals.isNotEmpty) {
      _npcs.removeWhere((n) => _pendingNpcRemovals.contains(n.id));
      _pendingNpcRemovals.clear();
    }
  }

  void _processNpcTravel(int index) {
    var npc = _npcs[index];
    if (npc.worldDestinationId == null) return;

    // Travel speed: Manor <-> Hamlet takes 4 hours (240 minutes)
    // 1 minute per tick (if 1x speed), so approx 0.004 progress per tick
    const double travelInterval = 1.0 / 240.0;
    double newProgress = (npc.worldTravelProgress + travelInterval).clamp(
      0.0,
      1.0,
    );

    if (newProgress >= 1.0 && npc.worldTravelProgress < 1.0) {
      // Arrival!
      if (npc.worldDestinationId == 'manor') {
        _completeJourneyAtManor(index);
      } else {
        _npcs[index] = npc.copyWith(worldTravelProgress: 1.0);
        _lastAnnouncement =
            "${npc.name} has arrived at ${npc.worldDestinationId!.toUpperCase()}.";
        _pendingNavigationTarget = npc.worldDestinationId;
        setSpeed(GameSpeed.normal);
      }
      notifyListeners();
    } else {
      _npcs[index] = npc.copyWith(worldTravelProgress: newProgress);
    }

    // Distance-Based Encounter Trigger
    if (!_pendingCombatEncounter && npc.isPlayer && newProgress < 1.0) {
      _playerDistanceSinceEncounter += travelInterval;

      // Cooldown: Must travel at least 25% of a full journey
      if (_playerDistanceSinceEncounter > 0.25) {
        // Base chance scales with distance
        final encounterChance = (_playerDistanceSinceEncounter - 0.25) * 0.02;
        if (Random().nextDouble() < encounterChance) {
          _triggerCombatEncounter();
        }
      }
    }
  }

  void _triggerCombatEncounter() {
    _pendingCombatEncounter = true;
    final rand = Random();

    if (_rebelConstructsActive) {
      // Roving splinter construct army!
      _pendingEncounterData = EncounterData(
        title: "Rogue Construct Army",
        description:
            "A massive, terrifying cohort of Glarus's reanimated splinter constructs blocks the valley road. They are completely feral and cannot be reasoned with.",
        demands: {'funds': 9999}, // impossible toll
      );
      _pendingEncounterEnemies = [
        CombatUnitFactory.createFleshHound(),
        CombatUnitFactory.createFleshHound(),
        CombatUnitFactory.createGoon(), // Acting as secondary threat
      ];
    } else if (_newRegionUnlocked) {
      // Geneva Imperial Wardens
      _pendingEncounterData = EncounterData(
        title: "Geneva Imperial Wardens",
        description:
            "You have entered an Imperial patrol zone. Professional wardens block the highway, demanding a strict custom travel tariff.",
        demands: {'funds': 100},
      );
      _pendingEncounterEnemies = [
        CombatUnitFactory.createBanditCaptain(),
        CombatUnitFactory.createBanditCaptain(),
        CombatUnitFactory.createGoon(),
      ];
    } else if (_newPropertyConstructed) {
      // Estate Mercenaries
      _pendingEncounterData = EncounterData(
        title: "Rival Estate Mercenaries",
        description:
            "Your expansion of Rolle properties has angered local baronies. A group of heavily armed estate mercenaries attacks!",
        demands: {'funds': 150},
      );
      _pendingEncounterEnemies = [
        CombatUnitFactory.createGoon(),
        CombatUnitFactory.createGoon(),
        CombatUnitFactory.createGoon(),
      ];
    } else {
      // Standard Fallback
      if (rand.nextDouble() < 0.5) {
        _pendingEncounterData = EncounterData(
          title: "Highwaymen",
          description:
              "A group of opportunistic brigands steps into the road, blocking your path. They demand a toll to let you pass unharmed.",
          demands: {'funds': 20 + rand.nextInt(30)},
        );
        _pendingEncounterEnemies = [
          CombatUnitFactory.createBanditCaptain(),
          CombatUnitFactory.createGoon(),
          CombatUnitFactory.createGoon(),
        ];
      } else {
        _pendingEncounterData = EncounterData(
          title: "Feral Beasts",
          description:
              "A pack of feral animals catches the scent of your party. They look hungry. Tossing them some meat might distract them long enough to escape.",
          demands: {'meat': 1 + rand.nextInt(3)},
        );
        _pendingEncounterEnemies = [
          CombatUnitFactory.createFleshHound(),
          CombatUnitFactory.createBrownRats(),
          CombatUnitFactory.createBrownRats(),
        ];
      }
    }

    _lastAnnouncement = "ENCOUNTER: ${_pendingEncounterData!.title}";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] ENCOUNTER: ${_pendingEncounterData!.title} on the road!",
    );
    _speed = GameSpeed.paused;
    notifyListeners();
  }

  void _processSpoilage() {
    // Every tick (minute), check if anything spoiled
    // To avoid too many DateTime calls, we check every 60 ticks (1 hour)
    if (_currentDate.minute == 0) {
      // Spoil pantry dishes (48h default)
      _pantry.removeWhere((d) {
        if (d.isSpoiled(_currentDate)) {
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] INVENTORY: A prepared dish (${d.name}) has spoiled and was discarded.",
          );
          return true;
        }
        return false;
      });

      // Spoil inventory items across all rooms
      for (int i = 0; i < _rooms.length; i++) {
        final room = _rooms[i];
        final newInv = List<GameItem>.from(room.inventory);
        
        // 1. Check for 48-hour warnings (2 days) before spoilage
        for (int j = 0; j < newInv.length; j++) {
          final item = newInv[j];
          if (item.category == ItemCategory.food ||
              item.category == ItemCategory.resource) {
            if (item.creationDate != null &&
                item.metadata['spoilWarned'] != true) {
              double shelfLifeDays =
                  (item.metadata['shelfLifeDays'] as num? ?? 10).toDouble();
              if (item.type == 'eggs' || item.type == 'fertilized_egg') {
                shelfLifeDays = 30.0;
              }
              final elapsedDays = _currentDate.differenceInDays(
                item.creationDate!,
              );
              final remainingDays = shelfLifeDays - elapsedDays;

              if (remainingDays <= 2.0 && remainingDays > 0.0) {
                final updatedMetadata = Map<String, dynamic>.from(
                  item.metadata,
                );
                updatedMetadata['spoilWarned'] = true;
                newInv[j] = item.copyWith(metadata: updatedMetadata);

                _lastAnnouncement = "${item.name} will spoil in two days.";
                _announcementHistory.insert(
                  0,
                  "[${_currentDate.formattedTime}] INVENTORY: ${item.name} will spoil in two days.",
                );
              }
            }
          }
        }

        // 2. Remove spoiled items and issue logs
        newInv.removeWhere((item) {
          if (item.type == 'fertilized_egg' && room.id == 'chicken_coop') {
            if (item.creationDate != null &&
                _currentDate.differenceInDays(item.creationDate!) >= 21) {
              // Hatch the egg!
              _chickens.add(
                Chicken.create(
                  ChickenBreedType.houdan,
                  _currentDate,
                  isMale: Random().nextDouble() < 0.2,
                ),
              );
              _lastAnnouncement =
                  "[${_currentDate.formattedTime}] LIFE: A new chick has hatched from an egg in the coop!";
              return true; // remove the egg item
            }
          } else if (item.category == ItemCategory.resource ||
              item.category == ItemCategory.food) {
            if (item.creationDate != null) {
              double shelfLifeDays =
                  (item.metadata['shelfLifeDays'] as num? ?? 10).toDouble();
              if (item.type == 'eggs' || item.type == 'fertilized_egg') {
                shelfLifeDays = 30.0;
              }
              if (_currentDate.differenceInDays(item.creationDate!) >=
                  shelfLifeDays) {
                _lastAnnouncement = "${item.name} has spoiled.";
                _announcementHistory.insert(
                  0,
                  "[${_currentDate.formattedTime}] INVENTORY: ${item.name} has spoiled and was discarded.",
                );
                return true; // Item spoiled
              }
            }
          }
          return false;
        });

        if (newInv.length != room.inventory.length) {
          _rooms[i] = room.copyWith(inventory: newInv);
        }
      }
      notifyListeners();
    }
  }

  void _processNpcNeeds(int index) {
    var npcSnapshot = _npcs[index];

    // Don't process needs for dead NPCs
    if (npcSnapshot.status == NPCStatus.dead) return;

    // Base drains
    double dHunger = (3.2 / 60.0); // 3.2 hunger per hour base (slowed down 20%)
    double dEnergy = 0.0;
    double dSatisf = -(2.0 / 60.0); // 2 satisfaction per hour base
    double dDigestion = (100.0 / 1440.0); // ~1 day to full
    double dCleanliness =
        -(1.0 / 60.0); // 1 cleanliness loss per hour base (reduced by 75%)

    final currentTask = _taskService.activeTasks.firstWhereOrNull(
      (t) => t.id == npcSnapshot.activeTaskId,
    );
    final isWorking =
        currentTask != null &&
        currentTask.type != TaskType.rest &&
        currentTask.type != TaskType.eat &&
        currentTask.type != TaskType.relax &&
        currentTask.type != TaskType.useToilet &&
        currentTask.type != TaskType.wash;

    if (isWorking) {
      dHunger *= 2.0;
      dEnergy -= (4.5 / 60.0); // Extra energy drain when working
      if (currentTask.type == TaskType.cook ||
          currentTask.type == TaskType.surgery ||
          currentTask.type == TaskType.cleanRoom) {
        dCleanliness *=
            2.5; // Filthy tasks drain cleanliness significantly faster
      } else {
        dCleanliness *= 1.5;
      }
    }

    // Environmental factors (noise)
    final Random rng = Random("${npcSnapshot.id}_${_currentDate.day}".hashCode);
    final double awakeNoise = 0.8 + (rng.nextDouble() * 0.4);
    final double sleepNoise = 0.5 + (rng.nextDouble() * 1.0);
    final double noise = 0.9 + (rng.nextDouble() * 0.2);

    // --- RECOVERY LOGIC (Sleeping/Fainted) ---
    if (npcSnapshot.status == NPCStatus.sleeping ||
        npcSnapshot.status == NPCStatus.fainted) {
      final room = _rooms.firstWhereOrNull(
        (r) => r.id == npcSnapshot.currentRoomId,
      );
      double recoveryMult = 1.0;
      if (room != null) {
        if (room.type == RoomType.bedroom ||
            room.type == RoomType.butlerQuarters) {
          recoveryMult = 2.5;
        } else if (room.isRestored) {
          recoveryMult = 1.5;
        }
      }

      dEnergy += (12.0 / 60.0) * recoveryMult * sleepNoise * noise;
      dSatisf += (5.0 / 60.0) * recoveryMult;

      // Wake up check for fainting
      if (npcSnapshot.status == NPCStatus.fainted &&
          npcSnapshot.energy > 40.0) {
        _npcs[index] = npcSnapshot = npcSnapshot.copyWith(
          status: NPCStatus.idle,
        );
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] SURVIVAL: ${npcSnapshot.name} has regained consciousness.",
        );
      }
    } else {
      dEnergy -= (1.71 / 60.0) * awakeNoise * noise; // Reduced by 5% from 1.8
    }

    // Starvation check
    if (npcSnapshot.hunger >= 100.0) {
      dSatisf -= (10.0 / 60.0);
      // Health decay or other penalties...
    }

    double newEnergy = (npcSnapshot.energy + dEnergy).clamp(0.0, 100.0);
    double newHunger = (npcSnapshot.hunger + dHunger).clamp(0.0, 100.0);
    double newSatisf = (npcSnapshot.satisfaction + dSatisf).clamp(0.0, 100.0);
    double newDigestion = (npcSnapshot.digestion + dDigestion).clamp(
      0.0,
      105.0,
    );
    double newCleanliness = (npcSnapshot.cleanliness + dCleanliness).clamp(
      0.0,
      100.0,
    );

    // Cleanliness satisfaction penalty
    final hygiene = npcSnapshot.stats["hygiene"] ?? 5;
    if (newCleanliness < 11.0 && hygiene >= 3) {
      double penalty = 0.0;
      bool isSoiled = newCleanliness <= 1.0;
      if (hygiene >= 8) {
        penalty = isSoiled ? (4.0 / 60.0) : (2.0 / 60.0);
      } else if (hygiene >= 6) {
        penalty = isSoiled ? (2.0 / 60.0) : (1.0 / 60.0);
      } else {
        penalty = isSoiled ? (1.0 / 60.0) : (0.5 / 60.0);
      }
      newSatisf = (newSatisf - penalty).clamp(0.0, 100.0);
    }

    // Faint Trigger
    NPCStatus finalStatus = npcSnapshot.status;
    bool shouldClearTask = false;

    if (newEnergy <= 0 &&
        finalStatus != NPCStatus.fainted &&
        finalStatus != NPCStatus.dead) {
      finalStatus = NPCStatus.fainted;
      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] SURVIVAL: ${npcSnapshot.name} has fainted from exhaustion!",
      );

      if (npcSnapshot.activeTaskId != null) {
        _taskService.removeTask(npcSnapshot.activeTaskId!);
        shouldClearTask = true;
      }
    }

    _npcs[index] = npcSnapshot.copyWith(
      energy: newEnergy,
      hunger: newHunger,
      satisfaction: newSatisf,
      digestion: newDigestion,
      cleanliness: newCleanliness,
      status: finalStatus,
      clearActiveTask: shouldClearTask,
    );
  }

  void _processDigestion() {
    for (int i = 0; i < _npcs.length; i++) {
      var latestNpc = _npcs[i];
      if (latestNpc.status == NPCStatus.dead ||
          latestNpc.status == NPCStatus.zombie) {
        continue;
      }

      // 0. Recovery from Breaking Point
      if (latestNpc.status == NPCStatus.broken &&
          latestNpc.breakStartTime != null &&
          latestNpc.breakDuration != null) {
        if (_currentDate.totalMinutes >=
            latestNpc.breakStartTime! + latestNpc.breakDuration!) {
          // Readjust satisfaction to a safe level (50-70% depending on episode history)
          final episodeFactor = (latestNpc.mentalEpisodeCount * 5.0).clamp(
            0.0,
            30.0,
          );
          final newSatisfValue = (70.0 - episodeFactor).clamp(40.0, 80.0);

          _npcs[i] = latestNpc.copyWith(
            status: NPCStatus.idle,
            satisfaction: newSatisfValue,
            currentThought: "I feel... better now. What was I doing?",
          );
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] RECOVERY: ${latestNpc.name} has recovered from their episode.",
          );
          continue; // Skip further processing for this tick
        }
      }

      // 0.5. Spontaneous Baseline Incident Check (Once a year = 1 / 525600 mins)
      double baselineChance = (latestNpc.isPlayer ? 2.0 : 1.0) / 525600.0;
      if (Random().nextDouble() < baselineChance) {
        _triggerBowelMovementIncident(i);
        continue;
      }

      // 1. Breaking Point Tracking
      if (latestNpc.digestion >= 100.0) {
        int newBreakingMinutes = latestNpc.breakingPointMinutes + 1;
        // Accident chance is high: approx 5% chance per minute after holding it at 100% capacity.
        if (Random().nextDouble() < 0.05) {
          _triggerBowelMovementIncident(i);
        } else {
          _npcs[i] = latestNpc.copyWith(
            breakingPointMinutes: newBreakingMinutes,
            currentThought: "I really... need... to go...",
          );
        }
      }

      // 3. Mental Breaking Point Tracking
      final double guilt = (latestNpc.stats['guilt'] ?? 0).toDouble();
      if (guilt >= 90.0 || latestNpc.satisfaction <= 5.0) {
        int newMentalBreaking = latestNpc.mentalBreakingPointMinutes + 1;
        if (newMentalBreaking >= 30) {
          _triggerMentalBreakdownIncident(i);
        } else {
          _npcs[i] = _npcs[i].copyWith(
            mentalBreakingPointMinutes: newMentalBreaking,
            currentThought: "I can't take this anymore...",
          );
        }
      } else {
        if (latestNpc.mentalBreakingPointMinutes > 0) {
          _npcs[i] = _npcs[i].copyWith(mentalBreakingPointMinutes: 0);
        }
      }

      // 2. Desperate Need (90%)
      latestNpc = _npcs[i]; // Refresh reference
      if (latestNpc.digestion >= 90.0) {
        _npcs[i] = latestNpc.copyWith(
          currentThought: "DESPERATE NEED: TOILET.",
        );
      }
    }
  }

  void _triggerMentalBreakdownIncident(int npcIndex) {
    var npc = _npcs[npcIndex];
    final episodeNum = npc.mentalEpisodeCount + 1;

    // Determine if it's an Anger Episode or a Psychotic Break
    // First episode is always Anger. Subsequent have increasing psychotic chance.
    bool isPsychotic = false;
    if (episodeNum > 1) {
      final breakChance = (episodeNum - 1) * 0.3; // 30%, 60%, 90%...
      isPsychotic = Random().nextDouble() < breakChance;
    }

    int duration;
    String incidentName;
    String thought;
    NPCStatus newStatus = NPCStatus.broken;

    if (!isPsychotic) {
      incidentName = "Anger Episode";
      duration = 60; // 1 hour
      thought = "I'm SO ANGRY! I can't think straight!";
      // We'll keep status as broken for now as it clears the queue,
      // but maybe we use panicked or a custom one if needed.
    } else {
      incidentName = "Psychotic Break";
      // Up to 1 day (1440 mins) in early game (first 60 days)
      final earlyGameFactor = _currentDate.day <= 60 ? 1.0 : 2.0;
      duration = (120 + Random().nextInt(1320)).toInt(); // 2h to 24h
      duration = (duration * earlyGameFactor).toInt();
      thought = "I CAN'T TAKE IT! THE VOICES! THE GUILT!";
    }

    _lastAnnouncement = "INCIDENT: ${npc.name} is having an $incidentName!";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] INCIDENT: $incidentName for ${npc.name}.",
    );

    // Character status change
    _npcs[npcIndex] = npc.copyWith(
      status: newStatus,
      activeTaskId: null,
      targetRoomId: null,
      clearTarget: true,
      satisfaction: (npc.satisfaction - 10).clamp(0, 100),
      mentalBreakingPointMinutes: 0,
      mentalEpisodeCount: episodeNum,
      breakStartTime: _currentDate.totalMinutes,
      breakDuration: duration,
      currentThought: thought,
    );

    // Social effects - others might be frightened
    final roomId = npc.currentRoomId;
    if (roomId != null) {
      for (int j = 0; j < _npcs.length; j++) {
        if (j == npcIndex) continue;
        if (_npcs[j].currentRoomId == roomId) {
          final other = _npcs[j];
          final rels = Map<String, Relationship>.from(other.relationships);
          final oldRel = rels[npc.id] ?? Relationship();
          rels[npc.id] = oldRel.copyWith(
            fear: (oldRel.fear + 1.5).clamp(0, 5),
            respect: (oldRel.respect - 0.5).clamp(0, 5),
          );
          _npcs[j] = other.copyWith(
            relationships: rels,
            satisfaction: (other.satisfaction - 15).clamp(0, 100),
            currentThought:
                "Someone help ${npc.name}! They've lost their mind!",
          );
        }
      }
    }
    notifyListeners();
  }

  void _processHourlyRelationshipEvolution() {
    final Map<String, List<int>> rooms = {};

    for (int i = 0; i < _npcs.length; i++) {
      final roomId = _npcs[i].currentRoomId;
      if (roomId != null && _npcs[i].status != NPCStatus.dead) {
        rooms.putIfAbsent(roomId, () => []).add(i);
      }
    }

    final isKind = _butlerDisposition == ButlerDisposition.kind;
    final isStern = _butlerDisposition == ButlerDisposition.stern;

    rooms.forEach((roomId, npcIndices) {
      if (npcIndices.length < 2) return;

      for (int i = 0; i < npcIndices.length; i++) {
        final npcIndexA = npcIndices[i];
        final npcA = _npcs[npcIndexA];

        for (int j = i + 1; j < npcIndices.length; j++) {
          final npcIndexB = npcIndices[j];
          final npcB = _npcs[npcIndexB];

          // Link relationships A -> B and B -> A
          final relsA = Map<String, Relationship>.from(npcA.relationships);
          final relsB = Map<String, Relationship>.from(npcB.relationships);

          final oldRelAB = relsA[npcB.id] ?? Relationship();
          final oldRelBA = relsB[npcA.id] ?? Relationship();

          relsA[npcB.id] = oldRelAB.evolve(
            isKind: isKind,
            isStern: isStern,
            satisfaction: npcA.satisfaction,
          );
          relsB[npcA.id] = oldRelBA.evolve(
            isKind: isKind,
            isStern: isStern,
            satisfaction: npcB.satisfaction,
          );

          _npcs[npcIndexA] = npcA.copyWith(relationships: relsA);
          _npcs[npcIndexB] = npcB.copyWith(relationships: relsB);

          // Random Interaction (10% chance)
          if (Random().nextDouble() < 0.10) {
            final avgSat = (npcA.satisfaction + npcB.satisfaction) / 2.0;
            if (avgSat > 50) {
              _npcs[npcIndexA] = _npcs[npcIndexA].copyWith(
                currentThought: "Having a pleasant exchange with ${npcB.name}.",
                satisfaction: (npcA.satisfaction + 2).clamp(0, 100),
              );
            } else {
              _npcs[npcIndexA] = _npcs[npcIndexA].copyWith(
                currentThought: "Tense disagreement with ${npcB.name}...",
                satisfaction: (npcA.satisfaction - 5).clamp(0, 100),
              );
            }
          }
        }
      }
    });

    // Butler influence on overall satisfaction
    if (isKind) {
      for (int i = 0; i < _npcs.length; i++) {
        _npcs[i] = _npcs[i].copyWith(
          satisfaction: (_npcs[i].satisfaction + 1).clamp(0, 100),
        );
      }
    } else if (isStern) {
      for (int i = 0; i < _npcs.length; i++) {
        _npcs[i] = _npcs[i].copyWith(
          satisfaction: (_npcs[i].satisfaction - 1).clamp(0, 100),
        );
      }
    }
  }

  void _triggerBowelMovementIncident(int npcIndex) {
    var npc = _npcs[npcIndex];
    final roomId = npc.currentRoomId;
    if (roomId == null) return;

    final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex != -1) {
      var room = _rooms[roomIndex];
      _rooms[roomIndex] = room.copyWith(isRestored: false, dirtiness: 1.0);

      _lastAnnouncement =
          "URGENT: ${npc.name} has suffered an unplanned bowel movement incident in ${room.name}!";
      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] INCIDENT: UBMI in ${room.name}.",
      );

      // Character mood drop
      _npcs[npcIndex] = npc.copyWith(
        status: NPCStatus.idle,
        activeTaskId: null,
        satisfaction: (npc.satisfaction - 40).clamp(0, 100),
        digestion: 0.0,
        breakingPointMinutes: 0,
        currentThought: "I am utterly humiliated...",
      );

      // Social effects for others in the room
      for (int j = 0; j < _npcs.length; j++) {
        if (j == npcIndex) continue;
        if (_npcs[j].currentRoomId == roomId) {
          // Rel penalties
          final other = _npcs[j];
          final rels = Map<String, Relationship>.from(other.relationships);
          final oldRel = rels[npc.id] ?? Relationship();
          rels[npc.id] = oldRel.copyWith(
            attraction: (oldRel.attraction - 1.0).clamp(0, 5),
            admiration: (oldRel.admiration - 0.5).clamp(0, 5),
            respect: (oldRel.respect - 0.5).clamp(0, 5),
          );
          _npcs[j] = other.copyWith(
            relationships: rels,
            satisfaction: (other.satisfaction - 10).clamp(0, 100),
            currentThought: "That is absolutely disgusting, ${npc.name}.",
          );
        }
      }
      notifyListeners();
    }
  }

  // Scheduled activities are now managed by Intent Queue

  void _processNpcMovement(int index) {
    var npc = _npcs[index];

    if (npc.status == NPCStatus.dead ||
        npc.status == NPCStatus.fainted ||
        npc.status == NPCStatus.broken) {
      if (npc.targetRoomId != null || npc.movementPath.isNotEmpty) {
        _npcs[index] = npc.copyWith(clearTarget: true, movementPath: []);
      }
      return;
    }

    // If we have a path but no current target, set the next target from path
    if (npc.targetRoomId == null && npc.movementPath.isNotEmpty) {
      final List<String> newPath = List.from(npc.movementPath);
      final String nextTarget = newPath.removeAt(0);
      _npcs[index] = npc = npc.copyWith(
        targetRoomId: nextTarget,
        movementPath: newPath,
        movementProgress: 0.0,
      );
    }

    if (npc.targetRoomId == null || npc.currentRoomId == npc.targetRoomId) {
      _npcs[index] = npc.copyWith(movementProgress: 1.0, clearTarget: true);
      return;
    }

    // walkSpeed is now percentage points per minute (e.g. 15 = 0.15 per minute)
    final double walkSpeed = (npc.stats['walkSpeed'] ?? 10).toDouble();
    final double baseSpeedMultiplier = 5.0; // Boost movement
    final double speedPerMinute = (walkSpeed / 100.0) * baseSpeedMultiplier;

    double newProgress = npc.movementProgress + speedPerMinute;

    if (newProgress >= 1.0) {
      final arrivedRoomId = npc.targetRoomId;
      final arrivedNpc = npc.copyWith(currentRoomId: arrivedRoomId);
      
      final activeTask = arrivedNpc.activeTaskId != null
          ? _taskService.activeTasks.firstWhereOrNull(
              (t) => t.id == arrivedNpc.activeTaskId,
            )
          : null;

      _npcs[index] = arrivedNpc.copyWith(
        status: _determineStatus(
          arrivedNpc,
          activeTask,
        ),
        movementProgress: 1.0,
        targetRoomId: null,
      );

      // Intercept guest greeting on arrival to entryway
      if (activeTask != null &&
          activeTask.type == TaskType.greetGuest &&
          arrivedRoomId == 'entryway') {
        final guestId = activeTask.recipeId; // stored guest NPC ID
        final guest = _npcs.firstWhereOrNull((n) => n.id == guestId);
        if (guest != null) {
          _pendingGuestConversation = true;
          _conversationGreeter = _npcs[index];
          _conversationGuest = guest;

          // Pause game
          _speedBeforePause = _speed;
          setSpeed(GameSpeed.paused);

          // Complete the task immediately to clear working/walking status
          _handleTaskCompletion(activeTask);
        }
      }
    } else {
      _npcs[index] = npc.copyWith(movementProgress: newProgress);
    }
  }

  static const Map<String, List<String>> _roomConnections = {
    // Floor 0: Entryway Hub
    'entryway': [
      'kitchen',
      'dining_hall',
      'bathroom_down',
      'butler_quarters',
      'unused_1f',
      'road',
      'study', // Stairs down to Entryway
      'bathroom_up', // Stairs down to Entryway
    ],
    // Floor 1 Sequential: Master <-> Bed 2 <-> Bed 3 <-> Bath Up <-> Study <-> Library
    'master_bedroom': [
      'bedroom_2',
      'attic_1',
    ], // Stairs to Attic from point between Master/Guest A
    'bedroom_2': ['master_bedroom', 'bedroom_3', 'attic_1'],
    'bedroom_3': ['bedroom_2', 'bathroom_up'],
    'bathroom_up': ['bedroom_3', 'study', 'entryway'],
    'study': ['bathroom_up', 'library', 'entryway'],
    'library': ['study'],

    // Attic Hub: center point connects to both slots
    'attic_1': ['attic_2', 'master_bedroom', 'bedroom_2'],
    'attic_2': ['attic_1', 'master_bedroom', 'bedroom_2'],

    // Basement: Access via Unused Wing to Basement 2, and escalates to deep rooms
    'unused_1f': ['entryway', 'basement_2'],
    'basement_1': ['basement_2', 'basement_f'],
    'basement_2': ['basement_1', 'basement_3', 'unused_1f', 'basement_g'],
    'basement_3': ['basement_2', 'basement_d', 'basement_h'],
    'basement_d': ['basement_3', 'basement_i'],
    'basement_e': ['basement_f', 'basement_j'],
    'basement_f': ['basement_e', 'basement_g', 'basement_1', 'basement_k'],
    'basement_g': ['basement_f', 'basement_h', 'basement_2', 'basement_l'],
    'basement_h': ['basement_g', 'basement_i', 'basement_3', 'basement_m'],
    'basement_i': ['basement_h', 'basement_d', 'basement_n'],
    'basement_j': ['basement_k', 'basement_e', 'basement_o'],
    'basement_k': ['basement_j', 'basement_l', 'basement_f', 'basement_p'],
    'basement_l': ['basement_k', 'basement_m', 'basement_g', 'basement_q'],
    'basement_m': ['basement_l', 'basement_n', 'basement_h', 'basement_r'],
    'basement_n': ['basement_m', 'basement_i', 'basement_s'],
    'basement_o': ['basement_p', 'basement_j'],
    'basement_p': ['basement_o', 'basement_q', 'basement_k'],
    'basement_q': ['basement_p', 'basement_r', 'basement_l'],
    'basement_r': ['basement_q', 'basement_s', 'basement_m'],
    'basement_s': ['basement_r', 'basement_n'],

    // Exterior Hub
    'road': [
      'entryway',
      'vegetable_garden',
      'field_2',
      'field_3',
      'field_4',
      'chicken_coop',
      'toolshed',
      'lot_garden',
      'lot_building_1',
    ],
  };

  List<String> _findPath(String startId, String endId) {
    if (startId == endId) return [];

    // Simple BFS for shortest path in unweighted graph
    final Map<String, String?> parent = {startId: null};
    final List<String> queue = [startId];
    final Set<String> visited = {startId};

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current == endId) break;

      // Get neighbors from _roomConnections
      // Hubs are direct, but rooms only connect to their hubs
      List<String> neighbors = [];
      if (_roomConnections.containsKey(current)) {
        neighbors = _roomConnections[current]!;
      } else {
        // If it's a room, find which hub it belongs to
        _roomConnections.forEach((hub, members) {
          if (members.contains(current)) {
            neighbors.add(hub);
          }
        });
      }

      for (var neighbor in neighbors) {
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          parent[neighbor] = current;
          queue.add(neighbor);
        }
      }
    }

    if (!parent.containsKey(endId)) return [endId]; // Fallback to direct

    final List<String> path = [];
    String? curr = endId;
    while (curr != null && curr != startId) {
      path.insert(0, curr);
      curr = parent[curr];
    }
    return path;
  }

  void assignTask(GameTask task) {
    // 1. Add to Room Queue if it's a room-based task
    if (task.targetId != null) {
      final roomIndex = _rooms.indexWhere((r) => r.id == task.targetId);
      if (roomIndex != -1) {
        final room = _rooms[roomIndex];
        final List<EnqueuedTask> newQueue = List.from(room.taskQueue);

        // Find worker name for description
        final worker = _npcs.firstWhere(
          (n) => n.id == task.npcId,
          orElse: () => _npcs[0],
        );
        final taskName = task.type.displayName;
        final taskDesc = "${worker.name}: $taskName";

        // 1.1 Deduplication: Check if same worker AND same intent already exists in room queue
        final alreadyEnqueued = newQueue.any(
          (e) => e.npcId == task.npcId && e.intentId == task.intentId,
        );
        if (alreadyEnqueued && task.intentId != null) {
          debugPrint(
            "NPC_ASSIGN_SKIP_ROOM: ${task.npcId} already in queue for ${task.type.name} with intent ${task.intentId}",
          );
        } else {
          newQueue.add(
            EnqueuedTask(
              npcId: task.npcId,
              intentId:
                  task.intentId ?? task.id, // Use stable intentId if available
              description: taskDesc,
            ),
          );
        }

        // If no one is occupying and no project is at the workstation, this NPC takes it
        String? newOccupancy = room.occupyingNpcId;
        final Map<String, PhysicalProject> newProjects = Map.from(
          room.activeProjects,
        );

        // 1.2 Duplicate Projects check (ID-based)
        if (!newProjects.containsKey(task.id)) {
          final projectType = Room.getProjectType(task.type);
          newProjects[task.id] = PhysicalProject(
            id: task.id,
            taskId: task.id,
            name: taskName,
            type: projectType,
            progress: 0.0,
            isAtWorkstation: room.occupyingNpcId == null,
          );
        }

        if (room.occupyingNpcId == null) {
          newOccupancy = task.npcId;
        }

        _rooms[roomIndex] = room.copyWith(
          taskQueue: newQueue,
          occupyingNpcId: newOccupancy,
          activeProjects: newProjects,
        );

        // Also add to global task service for tracking
        _taskService.addTask(task);
      }
    } else {
      _taskService.addTask(task);
    }

    // 2. Update NPC status and move them to target room
    final index = _npcs.indexWhere((n) => n.id == task.npcId);
    if (index != -1) {
      var npc = _npcs[index];

      if (task.intentId == null) {
        final intent = NPCIntent(
          id: task.id,
          priority: task.priority,
          action: task.type,
          targetRoomId: task.targetId,
          recipeId: task.recipeId,
          targetName: task.targetName,
          minutesRemaining: task.minutesRemaining,
          expectedDurationMin: task.minutesRemaining,
        );

        _npcs[index] = npc.copyWith(
          intentQueue: [intent.copyWith(isManual: true), ...npc.intentQueue],
        );
        _lastAnnouncement = "Task for ${npc.name} added to assignment queue.";
      }
    }
    notifyListeners();
  }

  void moveProjectFromWorkstation(String roomId, String taskId) {
    final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex == -1) return;

    final room = _rooms[roomIndex];
    if (room.activeProjects.containsKey(taskId)) {
      final Map<String, PhysicalProject> nextProjects = Map.from(
        room.activeProjects,
      );
      nextProjects[taskId] = nextProjects[taskId]!.copyWith(
        isAtWorkstation: false,
      );

      String? nextOccupancy = room.occupyingNpcId;
      // If the NPC owning this project was occupying the room, clear it
      // Find NPC owning this taskId
      try {
        final task = _taskService.activeTasks.firstWhere((t) => t.id == taskId);
        if (room.occupyingNpcId == task.npcId) {
          nextOccupancy = null;
        }
      } catch (e) {
        // Task maybe gone, still clear occupancy if it was the last thing there
        nextOccupancy = null;
      }

      _rooms[roomIndex] = room.copyWith(
        activeProjects: nextProjects,
        occupyingNpcId: nextOccupancy,
        clearOccupancy: nextOccupancy == null,
      );
      notifyListeners();
    }
  }

  void clearRoomOccupancy(String roomId) {
    final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex != -1) {
      _rooms[roomIndex] = _rooms[roomIndex].copyWith(clearOccupancy: true);
      notifyListeners();
    }
  }

  void _clearRoomOccupancyForNpc(String npcId) {
    bool changed = false;
    for (int i = 0; i < _rooms.length; i++) {
      if (_rooms[i].occupyingNpcId == npcId) {
        _rooms[i] = _rooms[i].copyWith(clearOccupancy: true);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void handleTaskCompletionForTesting(GameTask task) {
    _handleTaskCompletion(task);
  }

  void _handleTaskCompletion(GameTask task) {
    final npcIndex = _npcs.indexWhere((n) => n.id == task.npcId);
    if (npcIndex == -1) return;

    // CRITICAL: Robust task removal on first completion attempt
    _taskService.removeTask(task.id);

    var currentNpc = _npcs[npcIndex];
    var worker = currentNpc;
    final List<NPCIntent> newQueue = List.from(currentNpc.intentQueue);
    if (task.intentId != null) {
      newQueue.removeWhere((i) => i.id == task.intentId);
    }

    if (task.type == TaskType.dentalWork) {
      _npcs[npcIndex] = currentNpc.copyWith(
        activeTaskId: null,
        status: NPCStatus.idle,
        intentQueue: newQueue,
      );
      for (var id in task.reservedEntityIds) {
        setReservation(id, false);
      }
      _triggerDentalPatientEvent();
      return;
    }

    // Initialise local status variables for update at end of function
    double newHunger = currentNpc.hunger;
    double newSatisfaction = currentNpc.satisfaction;
    double newDigestion = currentNpc.digestion;
    double newCleanliness = currentNpc.cleanliness;
    int newBreakingPointMinutes = currentNpc.breakingPointMinutes;
    String? newThought = currentNpc.currentThought;
    List<GameItem> newInventory = List.from(currentNpc.inventory);

    final room = task.targetId != null
        ? _rooms.firstWhereOrNull((r) => r.id == task.targetId)
        : null;

    // Clear room occupancy if this was a room task
    if (task.targetId != null) {
      final roomIndex = _rooms.indexWhere((r) => r.id == task.targetId);
      if (roomIndex != -1) {
        final room = _rooms[roomIndex];
        final List<EnqueuedTask> newQueue = List.from(room.taskQueue);
        newQueue.removeWhere(
          (e) => e.intentId == task.intentId || e.intentId == task.id,
        );

        final Map<String, PhysicalProject> newProjects = Map.from(
          room.activeProjects,
        );
        newProjects.remove(task.id);

        _rooms[roomIndex] = room.copyWith(
          taskQueue: newQueue,
          clearOccupancy: room.occupyingNpcId == task.npcId,
          activeProjects: newProjects,
        );
      }
    }

    // Release reserved entities
    for (var id in task.reservedEntityIds) {
      setReservation(id, false);
    }

    TaskResult result = TaskResultGenerator.generate(
      task.type,
      room?.name,
      worker,
      recipeId: task.recipeId,
      targetId: task.targetId,
    );

    if (worker.id == 'player' &&
        _playerAcademicSpecialization == 'Veterinary' &&
        (task.type == TaskType.surgicalOperation ||
            task.type == TaskType.surgicalCombination ||
            task.type == TaskType.surgery)) {
      if (_veterinaryExperience < 5) {
        result = TaskResult(
          message:
              "${result.message}\n\nWARNING: Due to Alfonso's animal veterinary specialty, his unfamiliarity with human anatomy causes clinical complications (-60% surgical precision penalty).",
          quality: result.quality * 0.4,
          resourcesGained: result.resourcesGained,
          itemsFound: result.itemsFound,
        );
      } else {
        result = TaskResult(
          message:
              "${result.message}\n\nAlfonso has overcome his veterinary human-patient unfamiliarity with surgical experience!",
          quality: result.quality,
          resourcesGained: result.resourcesGained,
          itemsFound: result.itemsFound,
        );
      }
      _veterinaryExperience++;
    }

    // Fire Risk Assessment
    final bool isRiskyRoutine =
        task.type == TaskType.cook ||
        task.type == TaskType.experiment ||
        task.type == TaskType.operation ||
        task.type == TaskType.surgicalOperation ||
        task.type == TaskType.surgicalCombination ||
        task.type == TaskType.vivisection;
    if (isRiskyRoutine && result.quality < 0.6) {
      // failed or low performance action -> small chance of fire
      if (Random().nextDouble() < 0.1) {
        _triggerManorFire(task.targetId ?? 'manor_kitchen');
      }
    }

    if (result.quality > 1.5) {
      triggerJoy(worker.id, task.type.name);
      // Re-fetch worker to include new status effect if we use it later
      worker = _npcs[npcIndex];
    }

    _completedTaskTypes.add(task.type);
    _taskCompletionCounts[task.type] =
        (_taskCompletionCounts[task.type] ?? 0) + 1;

    // Process Loot (apply penalties if worker is unsuitable)
    double yieldMultiplier = 1.0;
    if (worker.role == 'Scientist' &&
        (task.type == TaskType.cleanRoom ||
            task.type == TaskType.collectEggs ||
            task.type == TaskType.harvestCabbage)) {
      yieldMultiplier = 0.5; // Master is bad at chores
    } else if (worker.role == 'Butler' &&
        (task.type == TaskType.research || task.type == TaskType.dissect)) {
      yieldMultiplier = 0.5; // Butler is bad at science
      // Waste resources
      updateResource('funds', -(5));
      _lastAnnouncement =
          "${worker.name} wasted materials while attempting ${task.type.name}!";
    }

    if (task.type == TaskType.collectEggs) {
      final coop = _rooms.firstWhereOrNull((r) => r.id == task.targetId);
      if (coop != null) {
        final eggsInCoop = coop.inventory
            .where((i) => i.type == 'eggs')
            .toList();
        if (eggsInCoop.isNotEmpty) {
          final kitchen = _rooms.firstWhereOrNull(
            (r) => r.type == RoomType.kitchen && r.isRestored,
          );
          if (kitchen != null) {
            final newWorkerInv = List<GameItem>.from(worker.inventory)
              ..addAll(eggsInCoop);
            final newCoopInv = coop.inventory
                .where((i) => i.type != 'eggs')
                .toList();

            final roomIndex = _rooms.indexWhere((r) => r.id == coop.id);
            _rooms[roomIndex] = coop.copyWith(inventory: newCoopInv);
            worker = worker.copyWith(inventory: newWorkerInv);

            _lastAnnouncement =
                "${worker.name} collected eggs and is hauling them to the Kitchen.";

            worker.intentQueue.insert(
              0,
              NPCIntent(
                id: 'deliver_eggs_${DateTime.now().millisecondsSinceEpoch}',
                action: TaskType.deliverEggs,
                priority: IntentPriority.high,
                targetRoomId: kitchen.id,
              ),
            );
          } else {
            _lastAnnouncement =
                "The Kitchen was destroyed! ${worker.name} discarded the eggs.";
            final newCoopInv = coop.inventory
                .where((i) => i.type != 'eggs')
                .toList();
            final roomIndex = _rooms.indexWhere((r) => r.id == coop.id);
            _rooms[roomIndex] = coop.copyWith(inventory: newCoopInv);
          }
        } else {
          _lastAnnouncement = "${worker.name} found no eggs in the coop today.";
        }
      }
    } else if (task.type == TaskType.deliverEggs) {
      final eggsInInv = worker.inventory
          .where((i) => i.type == 'eggs')
          .toList();
      if (eggsInInv.isNotEmpty) {
        final kitchenIndex = _rooms.indexWhere((r) => r.id == task.targetId);
        if (kitchenIndex != -1) {
          final kitchen = _rooms[kitchenIndex];
          final newKitchenInv = List<GameItem>.from(kitchen.inventory)
            ..addAll(eggsInInv);
          _rooms[kitchenIndex] = kitchen.copyWith(inventory: newKitchenInv);

          final newWorkerInv = worker.inventory
              .where((i) => i.type != 'eggs')
              .toList();
          worker = worker.copyWith(inventory: newWorkerInv);

          final int inTransit = eggsInInv.fold(0, (sum, i) => sum + i.quantity);
          updateResource('eggs', inTransit);

          _lastAnnouncement =
              "${worker.name} delivered $inTransit eggs to the Kitchen pantry.";
        }
      }
    } else if (task.type == TaskType.hauling) {
      final hauledItems = worker.inventory.toList();
      if (hauledItems.isNotEmpty && task.targetId != null) {
        final roomIdx = _rooms.indexWhere((r) => r.id == task.targetId);
        if (roomIdx != -1) {
          for (var item in hauledItems) {
            addItemToRoom(task.targetId!, item);
          }
          worker = worker.copyWith(inventory: []);
          _lastAnnouncement =
              "${worker.name} deposited hauled items into the ${_rooms[roomIdx].name.toUpperCase()}.";
        }
      }
    } else if (task.type == TaskType.harvestCabbage ||
        task.type == TaskType.harvestCrops) {
      if (task.targetId == 'vegetable_garden') {
        final ready = _gardenPlants.where((p) => p.yieldAmount > 0).toList();
        if (ready.isNotEmpty) {
          int total = 0;
          for (var plant in ready) {
            total += plant.yieldAmount;
            updateResource(plant.yieldItemType, plant.yieldAmount);
            final index = _gardenPlants.indexWhere((p) => p.id == plant.id);
            if (index != -1) {
              _gardenPlants[index] = plant.copyWith(yieldAmount: 0);
            }
          }
          notifyRoomProduction(task.targetId!, '+$total');
          _lastAnnouncement = "${worker.name} harvested crops from the garden.";
        } else {
          _lastAnnouncement =
              "${worker.name} found no garden plants ready for harvest.";
        }
      } else {
        final ready = _crops
            .where(
              (c) =>
                  (c.type == CropType.cabbage ||
                      c.type == CropType.carrot ||
                      c.type == CropType.potato ||
                      c.type == CropType.grain ||
                      c.type == CropType.cannabis ||
                      c.type == CropType.tobacco ||
                      c.type == CropType.mushroom) &&
                  c.isHarvestable,
            )
            .toList();
        if (ready.isNotEmpty) {
          int total = 0;
          for (var crop in ready) {
            final int y = crop.yield.toInt();
            total = total + y;
            _crops.removeWhere((c) => c.id == crop.id);
            if (crop.type == CropType.cannabis) {
              updateResource('cannabis_buds', y);
              updateResource('hemp_fiber', (y * 0.5).round());
            } else if (crop.type == CropType.tobacco) {
              updateResource('tobacco_leaves', y);
            } else if (crop.type == CropType.mushroom) {
              updateResource('hallucinogenic_mushrooms', y);
            } else {
              // Gained specific crop type
              String resId = crop.type.name;
              updateResource(resId, y);
            }
          }
          notifyRoomProduction(task.targetId!, '+$total');
          _lastAnnouncement = "${worker.name} harvested crops from the garden.";
        } else {
          _lastAnnouncement =
              "${worker.name} found no crops ready for harvest.";
        }
      }
    } else if (task.type == TaskType.butcherAnimals) {
      if (task.targetId == 'rat_specimen' || task.targetId == 'bat_specimen') {
        updateResource(task.targetId!, -(1));
        final meat = GameItem.create(
          name: task.targetId == 'rat_specimen' ? "Rat Meat" : "Bat Meat",
          type: 'meat_small',
          category: ItemCategory.food,
          quantity: 1,
          quality: 0.8,
        );
        _addPhysicalItem(meat);
        updateResource('meat_small', 1);

        // Add to room inventory for ledger visibility
        if (task.targetId != null) {
          final roomIndex = _rooms.indexWhere((r) => r.id == 'kitchen');
          if (roomIndex != -1) {
            _rooms[roomIndex] = _rooms[roomIndex].copyWith(
              inventory: [..._rooms[roomIndex].inventory, meat],
            );
          }
        }
        _lastAnnouncement =
            "${worker.name} butchered a ${task.targetId == 'rat_specimen' ? 'rat' : 'bat'} for a small amount of meat.";
      } else if (task.targetId != null) {
        // Check if it's a chicken
        final chickenIndex = _chickens.indexWhere((c) => c.id == task.targetId);
        if (chickenIndex != -1) {
          final chicken = _chickens[chickenIndex];
          final yield = chicken.isMature(_currentDate) ? 4 : 2;
          final poultry = GameItem.create(
            name: "Raw Poultry",
            type: 'meat_chicken',
            category: ItemCategory.food,
            quantity: yield,
            quality: 1.0,
          );
          _addPhysicalItem(poultry);
          updateResource('meat_chicken', yield);
          _chickens.removeAt(chickenIndex);

          // Add to room inventory for ledger visibility
          final roomIndex = _rooms.indexWhere((r) => r.id == 'kitchen');
          if (roomIndex != -1) {
            _rooms[roomIndex] = _rooms[roomIndex].copyWith(
              inventory: [..._rooms[roomIndex].inventory, poultry],
            );
          }
          _lastAnnouncement =
              "${worker.name} butchered the chicken and collected $yield units of poultry.";
        } else {
          // Check if it's an NPC or other item
          final itemIndex = inventory.indexWhere((i) => i.id == task.targetId);
          if (itemIndex != -1) {
            final item = inventory[itemIndex];
            final itemName = item.name;
            _removePhysicalItem(item.id);

            final yield = (item.weight * 0.6).clamp(1.0, 50.0).toInt();
            final resKey =
                item.type.contains('cow') || item.type.contains('cattle')
                ? 'meat_beef'
                : 'meat_generic';
            final meat = GameItem.create(
              name: "Raw Meat ($itemName)",
              type: resKey,
              category: ItemCategory.food,
              quantity: yield,
              quality: 0.9,
            );
            _addPhysicalItem(meat);
            updateResource(resKey, yield);

            // Add to room inventory for ledger visibility
            final roomIndex = _rooms.indexWhere((r) => r.id == 'kitchen');
            if (roomIndex != -1) {
              _rooms[roomIndex] = _rooms[roomIndex].copyWith(
                inventory: [..._rooms[roomIndex].inventory, meat],
              );
            }
            _lastAnnouncement =
                "${worker.name} has finished butchering $itemName, yielding $yield units of meat.";
          } else {
            final npcIndex = _npcs.indexWhere(
              (n) => n.id == task.targetId && !n.isPlayer,
            );
            if (npcIndex != -1) {
              final npc = _npcs[npcIndex];
              final npcName = npc.name;
              _npcs.removeAt(npcIndex);

              final yield = 10;
              final meat = GameItem.create(
                name: "Raw Meat ($npcName)",
                type: 'meat_generic',
                category: ItemCategory.food,
                quantity: yield,
                quality: 0.7,
              );
              _addPhysicalItem(meat);
              updateResource('meat_generic', yield);

              // Add to room inventory for ledger visibility
              final roomIndex = _rooms.indexWhere((r) => r.id == 'kitchen');
              if (roomIndex != -1) {
                _rooms[roomIndex] = _rooms[roomIndex].copyWith(
                  inventory: [..._rooms[roomIndex].inventory, meat],
                );
              }
              _lastAnnouncement =
                  "${worker.name} has finished butchering $npcName.";
            }
          }
        }
      }
    } else if (task.type == TaskType.tillSoil) {
      if (task.targetId != null) tillSoil(task.targetId!);
    } else if (task.type == TaskType.fertilizeSoil) {
      if (task.targetId != null) fertilizeSoil(task.targetId!);
    } else if (task.type == TaskType.eat) {
      // 1. Try to find a dish in the pantry first (high quality satisfaction)
      int? bestDishIndex;
      if (task.targetName != null) {
        for (int j = 0; j < _pantry.length; j++) {
          if (_pantry[j].name.toLowerCase() == task.targetName!.toLowerCase()) {
            bestDishIndex = j;
            break;
          }
        }
      }
      if (bestDishIndex == null) {
        final neededTypes = worker.diet.dailyRequirements.keys.toList();
        for (int j = 0; j < _pantry.length; j++) {
          final dish = _pantry[j];
          if (neededTypes.contains(dish.type)) {
            if (bestDishIndex == null ||
                dish.expirationMinutes <
                    _pantry[bestDishIndex].expirationMinutes) {
              bestDishIndex = j;
            }
          }
        }
      }

      String mealSource = "supplies";
      String mealName = "a simple meal";
      double satBonus = 20.0;
      double hungerRestore = 0.0;
      bool mealConsumed = false;

      if (bestDishIndex != null) {
        final dish = _pantry.removeAt(bestDishIndex);
        mealSource = "the pantry";
        mealName = dish.name;
        satBonus = 30.0; // Pantry food is better
        hungerRestore = 60.0; // 60% fullness for prepared meals
        mealConsumed = true;
      } else {
        // Scavenge raw ingredients: vegetables > eggs > raw meat > flour
        final priorityKeys = [
          'cabbage',
          'potato',
          'carrots',
          'beets',
          'green_beans',
          'faba_beans',
          'eggs',
          'meat_beef',
          'meat_chicken',
          'meat_generic',
          'flour_spelt',
          'flour_durum',
        ];
        String? foundKey;
        for (var key in priorityKeys) {
          if ((resources[key] ?? 0) > 0) {
            foundKey = key;
            break;
          }
        }

        if (foundKey != null) {
          _consumeSingleItem(
            foundKey,
          ); // Deducts it globally across room inventories
          mealSource = "raw ingredients";
          mealName = "raw $foundKey".replaceAll('_', ' ');
          hungerRestore = 30.0;
          mealConsumed = true;
        } else {
          // Nothing to eat!!
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] SURVIVAL: ${worker.name} found nothing to eat in the manor!",
          );
          newThought =
              "There is literally no food left in this manor. We will starve.";
          newSatisfaction = (newSatisfaction - 15.0).clamp(0.0, 100.0);
        }
      }

      List<Map<String, dynamic>>? newLog;
      if (mealConsumed) {
        // Dietary modifiers
        final lowerMealName = mealName.toLowerCase();
        if (worker.diet.favoriteFoods.any(
          (f) => f.toLowerCase() == lowerMealName,
        )) {
          satBonus += 15.0;
        }

        // Repetition penalty
        int repeatCount = worker.consumedDishes
            .where((f) => f.toLowerCase() == lowerMealName)
            .length;
        if (repeatCount >= 2) {
          satBonus -=
              15.0; // Heavily penalize eating the exact same thing continuously
        } else if (repeatCount == 1) {
          satBonus -= 5.0; // Slight penalty for eating it recently
        }

        final logEntry = {
          'itemName': mealName,
          'source': mealSource,
          'timestamp': '[${_currentDate.formattedTime}]',
          'minutes': _currentDate.totalMinutes,
        };
        newLog = List<Map<String, dynamic>>.from(worker.consumptionLog);
        newLog.add(logEntry);
        newLog.removeWhere(
          (e) =>
              (_currentDate.totalMinutes - (e['minutes'] as int? ?? 0)) > 4320,
        );

        newHunger = (newHunger - hungerRestore).clamp(0.0, 100.0);
        newSatisfaction = (newSatisfaction + satBonus).clamp(0.0, 100.0);
        newThought =
            "That $mealName from $mealSource was exactly what I needed.";
        if (hungerRestore > 40.0) {
          addItemToRoom(
            worker.currentRoomId ?? 'dining_hall',
            GameItem.create(
              name: 'Dirty Dish',
              type: 'dirty_dishes',
              category: ItemCategory.resource,
              quantity: 1,
            ),
          );
        }

        _lastAnnouncement =
            "${worker.name} finished consuming $mealName from $mealSource.";
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] NUTRITION: ${worker.name} consumed $mealName from $mealSource.",
        );

        // Optional: Resident cleanup duty
        if (worker.isResident && hungerRestore > 40.0) {
          final cleanupIntent = NPCIntent(
            id: 'cleanish_${worker.id}_${DateTime.now().millisecondsSinceEpoch}',
            priority: IntentPriority.normal,
            action: TaskType.cleanDish,
            targetRoomId: worker.currentRoomId ?? 'dining_hall',
            expectedDurationMin: 15,
          );
          if (!newQueue.any((i) => i.action == TaskType.cleanDish)) {
            newQueue.add(cleanupIntent);
          }
        }
      } else {
        _lastAnnouncement =
            "${worker.name} tried to eat, but found nothing but an empty pantry.";
        final cooldownIntent = NPCIntent(
          id: 'high_priority_hunger_${worker.id}',
          priority: IntentPriority.high,
          action: TaskType.relax,
          targetRoomId: 'entryway',
          startTimeMin:
              _currentDate.totalMinutes +
              60, // Wait 1 hour before trying to eat again
          expectedDurationMin: 1,
        );
        newQueue.removeWhere(
          (i) => i.id == 'high_priority_hunger_${worker.id}',
        );
        newQueue.add(cooldownIntent);
      }

      // Track meal timing to prevent immediate loops (even for starvation)
      final newHistory = List<String>.from(worker.consumedDishes);
      if (mealConsumed) {
        newHistory.insert(0, mealName.toLowerCase());
        if (newHistory.length > 5) {
          newHistory.removeLast();
        }
      }

      _npcs[npcIndex] = _npcs[npcIndex].copyWith(
        lastMealHour: _currentDate.hour,
        hunger: newHunger,
        satisfaction: newSatisfaction,
        consumptionLog: newLog,
        consumedDishes: newHistory,
      );
    } else if (task.type == TaskType.plantCrops) {
      CropType type = CropType.cabbage;
      if (task.recipeId != null) {
        try {
          type = CropType.values.firstWhere((e) => e.name == task.recipeId);
        } catch (_) {}
      }
      plantCrops(type, task.targetId ?? 'vegetable_garden');
    } else if (task.type == TaskType.waterCrops) {
      if (task.targetId != null) waterCrops(task.targetId!);
    } else if (task.type == TaskType.careForCrops) {
      if (task.targetId != null) careForCrops(task.targetId!);
    } else if (task.type == TaskType.refinePlantFungus) {
      if ((resources['cannabis_buds'] ?? 0) >= 2) {
        updateResource('cannabis_buds', -2);
        updateResource('seeds_cannabis', 4);
        _lastAnnouncement =
            "${worker.name} refined Cannabis Buds and extracted 4 Cannabis Seeds.";
      } else if ((resources['tobacco_leaves'] ?? 0) >= 2) {
        updateResource('tobacco_leaves', -2);
        updateResource('seeds_tobacco', 4);
        _lastAnnouncement =
            "${worker.name} refined Tobacco Leaves and extracted 4 Tobacco Seeds.";
      } else if ((resources['hallucinogenic_mushrooms'] ?? 0) >= 2) {
        updateResource('hallucinogenic_mushrooms', -2);
        updateResource('mushroom_spores', 4);
        _lastAnnouncement =
            "${worker.name} refined Hallucinogenic Mushrooms and extracted 4 Mushroom Spores.";
      } else {
        _lastAnnouncement =
            "${worker.name} found no suitable plants or fungi to refine.";
      }
    } else if (task.type == TaskType.useToilet) {
      newDigestion = 0.0;
      _lastAnnouncement = "${worker.name} finished using the washroom.";

      final hygiene = worker.stats["hygiene"] ?? 5;
      if (hygiene >= 4) {
        int washDuration = hygiene >= 9 ? 10 : (hygiene >= 7 ? 8 : 5);
        final washIntent = NPCIntent(
          id: 'wash_hands_post_toilet_${task.id}',
          action: TaskType.washHands,
          targetRoomId: task.targetId ?? 'bathroom_down',
          priority: IntentPriority.high,
          expectedDurationMin: washDuration,
        );
        newQueue.insert(0, washIntent);
      }
    } else if (task.type == TaskType.washHands) {
      newCleanliness = (worker.cleanliness + 30.0).clamp(0.0, 100.0);
      _lastAnnouncement = "${worker.name} washed their hands.";
    } else if (task.type == TaskType.bathe) {
      final hygiene = worker.stats["hygiene"] ?? 5;
      if (hygiene >= 3) {
        newCleanliness = 100.0;
      } else if (hygiene == 2) {
        newCleanliness = (worker.cleanliness > 90.0)
            ? worker.cleanliness
            : 90.0;
      } else {
        newCleanliness = (worker.cleanliness > 80.0)
            ? worker.cleanliness
            : 80.0;
      }
      _lastAnnouncement = "${worker.name} finished bathing.";
    } else if (task.type == TaskType.wash) {
      newCleanliness = 100.0;
      _lastAnnouncement = "${worker.name} finished washing.";
    } else if (task.type == TaskType.rest) {
      _lastAnnouncement = "${worker.name} finished resting.";
    } else if (task.type == TaskType.collectPayment) {
      // Find employment contract and deduct salary
      final contract = _contracts.firstWhereOrNull((c) => c.isActive && c.npcId == worker.id && c.type == ContractType.employment);
      if (contract != null) {
        final salary = contract.terms['salary'] as int? ?? 1;
        updateResource('funds', -salary);
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] WAGES: ${worker.name} collected their monthly salary of $salary CHF.",
        );
      }
    } else if (task.type == TaskType.greetGuest) {
      final guestId = task.recipeId; // We stored guestId in recipeId
      final guestIdx = _npcs.indexWhere((n) => n.id == guestId);
      if (guestIdx != -1) {
        var guest = _npcs[guestIdx];
        final bool isMerchant = guest.metadata['guestType'] == 'merchant';

        // Mark as greeted
        _npcs[guestIdx] = guest = guest.copyWith(
          metadata: {
            ...guest.metadata,
            'isGreeted': true,
            'greetedBy': worker.name,
          },
        );

        if (isMerchant) {
          _lastAnnouncement =
              "${worker.name} welcomed the merchant, ${guest.name}. Trade is now open.";
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] COMMERCE: ${worker.name} welcomed merchant ${guest.name}.",
          );
        } else {
          // Give a visitor gift!
          final gifts = [
            {'resource': 'meat', 'amount': 5, 'name': 'fresh meat'},
            {'resource': 'cabbage', 'amount': 8, 'name': 'cabbages'},
            {'resource': 'funds', 'amount': 50, 'name': '50 CHF'},
            {'resource': 'fertilizer', 'amount': 3, 'name': 'fertilizer bags'},
            {'resource': 'wood', 'amount': 10, 'name': 'bundles of wood'},
          ];
          final gift = gifts[Random().nextInt(gifts.length)];
          final res = gift['resource'] as String;
          final amt = gift['amount'] as int;
          updateResource(res, amt);

          _lastAnnouncement =
              "${worker.name} welcomed ${guest.name}, who gifted the household ${gift['name']} in return.";
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] VISIT: ${worker.name} welcomed ${guest.name}. Received ${gift['name']}.",
          );

          // Regular visitors leave after being greeted
          _pendingNpcRemovals.add(guest.id);
        }
      } else {
        _lastAnnouncement = "${worker.name} greeted a guest.";
      }
    } else if (task.type == TaskType.spyOnNeighbor) {
      final guestId = task.targetId;
      final guest = _npcs.firstWhereOrNull((n) => n.id == guestId);

      final dexterity = (worker.stats['dexterity'] ?? 5) / 10.0;
      final perception = (worker.stats['perception'] ?? 5) / 10.0;
      final successChance = 0.5 + (dexterity + perception) * 0.25;

      if (Random().nextDouble() < successChance) {
        final folder = GameItem.create(
          name: "Kompromat Folder (${task.targetName})",
          type: 'kompromat_folder',
          category: ItemCategory.knowledge,
          quantity: 1,
          quality: 1.0,
          metadata: {'guestId': guestId, 'guestName': task.targetName},
        );

        final studyIndex = _rooms.indexWhere((r) => r.id == 'study');
        if (studyIndex != -1) {
          final study = _rooms[studyIndex];
          _rooms[studyIndex] = study.copyWith(
            inventory: [...study.inventory, folder],
          );
        }

        updateResource('kompromat_folder', 1);
        _lastAnnouncement =
            "${worker.name} successfully compiled a Kompromat Folder on guest ${task.targetName}.";
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] SPYING: $_lastAnnouncement",
        );
      } else {
        _lastAnnouncement =
            "${worker.name} was caught spying! Guest ${task.targetName} checked out in a blind fury.";
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] CAUTION: $_lastAnnouncement",
        );

        final intruder = ManorCrisis(
          type: ManorCrisisType.intruder,
          roomId: guest?.currentRoomId ?? 'entryway',
          discoveryDate: _currentDate.toDateTime(),
          severity: 0.5,
          isDiscovered: true,
        );
        _crises.add(intruder);

        if (guest != null) {
          final roomId = guest.metadata['roomId'] as String?;
          if (roomId != null) {
            final roomIdx = _rooms.indexWhere((r) => r.id == roomId);
            if (roomIdx != -1) {
              _rooms[roomIdx] = _rooms[roomIdx].copyWith(clearOccupancy: true);
            }
          }
          _npcs.removeWhere((n) => n.id == guest.id);
        }
      }
    } else if (task.type == TaskType.readBook) {
      newSatisfaction = (newSatisfaction + 15.0).clamp(0.0, 100.0);

      final book = LeisureBooksLibrary
          .books[Random().nextInt(LeisureBooksLibrary.books.length)];
      _lastAnnouncement = "${worker.name} finished reading '${book.title}'.";

      int randAmt = 1 + Random().nextInt(3);

      switch (book.category) {
        case BookCategory.zoology:
        case BookCategory.medicine:
        case BookCategory.chemistry:
        case BookCategory.psychology:
        case BookCategory.physics:
          String discipline = book.category.name;
          _addPhysicalItem(
            GameItem.create(
              type: 'research_notes',
              name:
                  '${discipline[0].toUpperCase()}${discipline.substring(1)} Notes',
              category: ItemCategory.knowledge,
              metadata: {'pages': randAmt, 'discipline': discipline},
            ),
          );
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] RESEARCH: ${worker.name} gained $randAmt pages of $discipline notes from reading.",
          );
          break;
        case BookCategory.perception:
          _addStatExperience(npcIndex, 'perception', randAmt.toDouble() * 10.0);
          break;
        case BookCategory.judgment:
          _addStatExperience(npcIndex, 'judgment', randAmt.toDouble() * 10.0);
          break;
        case BookCategory.morality:
          _addStatExperience(npcIndex, 'morality', randAmt.toDouble() * 10.0);
          break;
        case BookCategory.courage:
          _addStatExperience(npcIndex, 'courage', randAmt.toDouble() * 10.0);
          break;
        case BookCategory.hygiene:
          _addStatExperience(npcIndex, 'hygiene', randAmt.toDouble() * 10.0);
          break;
        case BookCategory.temperament:
          _addStatExperience(npcIndex, 'temperament', randAmt.toDouble() * 10.0);
          break;
        case BookCategory.trash:
          break;
      }
    } else if (task.type == TaskType.goForWalk) {
      newSatisfaction = (newSatisfaction + 15.0).clamp(0.0, 100.0);
      _lastAnnouncement = "${worker.name} returned from a refreshing walk.";
      worker = _npcs[npcIndex];
    } else if (task.type == TaskType.cardio) {
      newSatisfaction = (newSatisfaction + 10.0).clamp(0.0, 100.0);
      _lastAnnouncement = "${worker.name} finished their cardio routine.";
      worker = _npcs[npcIndex];
    } else if (task.type == TaskType.weights) {
      newSatisfaction = (newSatisfaction + 10.0).clamp(0.0, 100.0);
      _lastAnnouncement =
          "${worker.name} finished their weight lifting session.";
    } else if (task.type == TaskType.interactAnimals) {
      newSatisfaction = (newSatisfaction + 20.0).clamp(0.0, 100.0);
      _lastAnnouncement = "${worker.name} spent time with the animals.";
      if (Random().nextDouble() < 0.3) {
        _addPhysicalItem(
          GameItem.create(
            type: 'research_notes',
            name: 'Zoology Observations',
            category: ItemCategory.knowledge,
            metadata: {'pages': 2, 'discipline': 'Zoology'},
          ),
        );
      }
    } else if (task.type == TaskType.paint) {
      final title = [
        'Landscape',
        'Portrait',
        'Still Life',
        'Abstract',
      ][Random().nextInt(4)];
      _addPhysicalItem(
        GameItem.create(
          type: 'painting',
          name: '$title by ${worker.name}',
          category: ItemCategory.resource,
          value:
              (50 + Random().nextInt(50)) *
              (worker.stats['dexterity'] ?? 1) ~/
              5,
        ),
      );
      _lastAnnouncement = "${worker.name} completed a painting.";
    } else if (task.type == TaskType.sculpt) {
      final mat = ['Clay', 'Marble', 'Wood', 'Bronze'][Random().nextInt(4)];
      _addPhysicalItem(
        GameItem.create(
          type: 'sculpture',
          name: '$mat Sculpture by ${worker.name}',
          category: ItemCategory.resource,
          value:
              (100 + Random().nextInt(100)) *
              (worker.stats['courage'] ?? 1) ~/
              5,
        ),
      );
      _lastAnnouncement = "${worker.name} completed a sculpture.";
    } else if (task.type == TaskType.writePoetry) {
      final desc = [
        'A Melancholy',
        'An Ode',
        'A Sonnet',
        'A Haiku',
      ][Random().nextInt(4)];
      _addPhysicalItem(
        GameItem.create(
          type: 'poem',
          name: '$desc by ${worker.name}',
          category: ItemCategory.knowledge,
          value: 20 * (worker.stats['strength'] ?? 1) ~/ 5,
        ),
      );
      _lastAnnouncement = "${worker.name} completed a poem.";
    } else if (task.type == TaskType.writeNovel) {
      final genre = [
        'Mystery',
        'Romance',
        'Horror',
        'Adventure',
      ][Random().nextInt(4)];
      _addPhysicalItem(
        GameItem.create(
          type: 'novel',
          name: '$genre Novel by ${worker.name}',
          category: ItemCategory.knowledge,
          value: 200 * (worker.stats['perception'] ?? 1) ~/ 5,
        ),
      );
      _lastAnnouncement = "${worker.name} completed a novel.";
    } else if (task.type == TaskType.careForInjured ||
        task.type == TaskType.careForSick) {
      // Nursing completion improves patient health slightly or just provides care
      _lastAnnouncement = "${worker.name} finished providing medical care.";
    } else if (task.type == TaskType.extinguishFire ||
        task.type == TaskType.recombineSpecimen ||
        task.type == TaskType.defendManor) {
      final crisisIndex = _crises.indexWhere(
        (c) =>
            c.roomId == task.targetId &&
            ((c.type == ManorCrisisType.fire &&
                    task.type == TaskType.extinguishFire) ||
                (c.type == ManorCrisisType.specimenEscape &&
                    task.type == TaskType.recombineSpecimen) ||
                (c.type == ManorCrisisType.intruder &&
                    task.type == TaskType.defendManor)),
      );

      if (crisisIndex != -1) {
        var crisis = _crises[crisisIndex];
        // Reduction based on worker stats (e.g. Endurance for fire, Strength for defense)
        double reduction = 0.3; // Base 30% reduction per task
        if (task.type == TaskType.defendManor) {
          reduction += (worker.stats['strength'] ?? 5) / 50.0; // Up to +0.2
        } else if (task.type == TaskType.extinguishFire) {
          reduction = 1.0; // Fire is completely put out in one action
        }

        crisis = crisis.copyWith(
          severity: (crisis.severity - reduction).clamp(0.0, 1.0),
        );

        if (crisis.severity <= 0) {
          _crises.removeAt(crisisIndex);
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] SUCCESS: The ${crisis.name} in the ${room?.name} has been resolved!",
          );
          if (task.type == TaskType.extinguishFire && room != null) {
            final roomIndex = _rooms.indexWhere((r) => r.id == room.id);
            if (roomIndex != -1) {
              _rooms[roomIndex] = room.copyWith(dirtiness: 1.0);
            }
          }
          // Return NPC to normal status if no more crises discovered
          bool stillPanicked = _crises.any(
            (c) =>
                c.isDiscovered &&
                _npcs.any(
                  (n) => n.id == worker.id && n.currentRoomId == c.roomId,
                ),
          );
          if (!stillPanicked) {
            _npcs[npcIndex] = worker.copyWith(status: NPCStatus.idle);
          }
        } else {
          _crises[crisisIndex] = crisis;
          _lastAnnouncement =
              "${worker.name} is making progress against the ${crisis.name}.";
        }
      }

      // Task removal from newQueue is already handled universally at the start of the method.
    } else if (task.type == TaskType.collectIngredients) {
        final cleanRecipeId = task.recipeId!.split(':').first;
        final activity = ScienceService.getActivityById(cleanRecipeId);
        if (activity != null) {
          final missing = _getMissingIngredientsForActivity(npcIndex, activity);
          final List<GameItem> workerInv = List<GameItem>.from(
            worker.inventory,
          );

          for (var entry in missing.entries) {
            String key = entry.key;
            num stillNeeded = entry.value;

            // 1. Take from global inventory
            for (int i = inventory.length - 1; i >= 0 && stillNeeded > 0; i--) {
              final item = inventory[i];
              bool matches = false;
              if (key == 'meat') {
                matches =
                    item.type.contains('meat') ||
                    item.category == ItemCategory.specimen;
              } else if (key == 'specimen' || key == 'rat_specimen') {
                matches =
                    item.category == ItemCategory.specimen ||
                    item.type == 'rat_specimen';
              } else {
                matches = item.type == key;
              }

              if (matches) {
                num toTake = min(item.quantity, stillNeeded);
                workerInv.add(
                  item.copyWith(
                    quantity: toTake.toInt(),
                    id: const Uuid().v4(),
                  ),
                );
                if (item.quantity > toTake) {
                  inventory[i] = item.copyWith(
                    quantity: (item.quantity - toTake).toInt(),
                  );
                } else {
                  inventory.removeAt(i);
                }
                stillNeeded -= toTake;
              }
            }

            // 2. Take from resources
            num toTake = min(resources[key] ?? 0, stillNeeded);
            updateResource(key, -(toTake));
            workerInv.add(
              GameItem.create(
                name: key.toUpperCase(),
                type: key,
                category: ItemCategory.resource,
                quantity: toTake.toInt(),
              ),
            );
            stillNeeded -= toTake;
          }
          _npcs[npcIndex] = _npcs[npcIndex].copyWith(inventory: workerInv);
          _lastAnnouncement =
              "${worker.name} collected materials for ${activity.name}.";
        } else if (room != null) {
        final List<GameItem> roomInv = List<GameItem>.from(
          _rooms[_rooms.indexOf(room)].inventory,
        );
        final List<GameItem> workerInv = List<GameItem>.from(
          _npcs[npcIndex].inventory,
        );
        workerInv.addAll(roomInv);
        _rooms[_rooms.indexOf(room)] = room.copyWith(inventory: []);
        _npcs[npcIndex] = _npcs[npcIndex].copyWith(inventory: workerInv);
        _lastAnnouncement =
            "${worker.name} collected supplies from ${room.name}.";
      }
    } else if (task.type == TaskType.cleanDish) {
      final room = _rooms.firstWhereOrNull((r) => r.id == task.targetId);
      if (room != null) {
        final dishIndex = room.inventory.indexWhere(
          (i) => i.type == 'dirty_dishes',
        );
        if (dishIndex != -1) {
          final dish = room.inventory[dishIndex];
          final List<GameItem> newInv = List.from(room.inventory);
          if (dish.quantity > 1) {
            newInv[dishIndex] = dish.copyWith(quantity: dish.quantity - 1);
          } else {
            newInv.removeAt(dishIndex);
          }
          final roomIdx = _rooms.indexWhere((r) => r.id == room.id);
          if (roomIdx != -1) {
            _rooms[roomIdx] = room.copyWith(inventory: newInv);
            _announcementHistory.insert(
              0,
              "[${_currentDate.formattedTime}] HYGIENE: ${worker.name} washed a dirty dish in the ${room.name}.",
            );
            notifyListeners();
          }
        }
      }
    } else if (task.type == TaskType.cook) {
      final recipes = KitchenService.getAvailableRecipes();

      bool isExperiment = task.recipeId?.startsWith('experiment|') ?? false;
      Map<String, num> experimentIngredients = {};
      if (isExperiment) {
        final parts = task.recipeId!.split('|').skip(1);
        for (var p in parts) {
          experimentIngredients[p] = (experimentIngredients[p] ?? 0) + 1;
        }
      }

      final recipe = isExperiment
          ? Recipe(
              id: task.recipeId!,
              name: 'Culinary Experiment',
              ingredients: experimentIngredients,
              durationMinutes: 120,
              isExperimental: true,
            )
          : task.recipeId != null
          ? recipes.firstWhere(
              (r) => r.id == task.recipeId,
              orElse: () => recipes.first,
            )
          : recipes.first;

      bool hasAll = true;
      final kitchenIndex = _rooms.indexWhere((r) => r.id == task.targetId);
      final List<GameItem> kitchenInv = kitchenIndex != -1
          ? List<GameItem>.from(_rooms[kitchenIndex].inventory)
          : [];
      final List<GameItem> workerInv = List<GameItem>.from(
        _npcs[npcIndex].inventory,
      );

      for (var ingEntry in recipe.ingredients.entries) {
        final ing = ingEntry.key;
        final count = ingEntry.value;

        int availableInRoom = 0;
        int availableInWorker = 0;
        int availableInResources = (resources[ing] ?? 0).toInt();

        if (ing == 'meat') {
          // Special case for generic meat
          availableInRoom = kitchenInv
              .where(
                (i) =>
                    i.type.contains('meat') ||
                    i.category == ItemCategory.specimen,
              )
              .fold(0, (sum, i) => sum + i.quantity);
          availableInWorker = workerInv
              .where(
                (i) =>
                    i.type.contains('meat') ||
                    i.category == ItemCategory.specimen,
              )
              .fold(0, (sum, i) => sum + i.quantity);
          // Generic meat resource is already included in availableInResources
        } else {
          availableInRoom = kitchenInv
              .where((i) => i.type == ing)
              .fold(0, (sum, i) => sum + i.quantity);
          availableInWorker = workerInv
              .where((i) => i.type == ing)
              .fold(0, (sum, i) => sum + i.quantity);
        }

        if (availableInRoom +
                availableInWorker +
                (availableInResources).toInt() <
            count) {
          hasAll = false;
        }
      }

      if (hasAll) {
        List<GameItem> consumedItems = [];
        for (var ingEntry in recipe.ingredients.entries) {
          final ing = ingEntry.key;
          final count = ingEntry.value;
          num remainingToDeduct = count;

          while (remainingToDeduct > 0) {
            final itemIndex = kitchenInv.indexWhere((i) {
              if (ing == 'meat') {
                return i.type.contains('meat') ||
                    i.category == ItemCategory.specimen;
              }
              return i.type == ing;
            });
            if (itemIndex == -1) break;
            final item = kitchenInv[itemIndex];
            final taken = min(item.quantity, remainingToDeduct);
            consumedItems.add(
              item.copyWith(quantity: taken.toInt()),
            ); // Record for calc

            if (item.quantity > taken) {
              kitchenInv[itemIndex] = item.copyWith(
                quantity: (item.quantity - taken).toInt(),
              );
            } else {
              kitchenInv.removeAt(itemIndex);
            }
            remainingToDeduct -= taken;
          }

          while (remainingToDeduct > 0) {
            final itemIndex = workerInv.indexWhere((i) {
              if (ing == 'meat') {
                return i.type.contains('meat') ||
                    i.category == ItemCategory.specimen;
              }
              return i.type == ing;
            });
            if (itemIndex == -1) break;
            final item = workerInv[itemIndex];
            final taken = min(item.quantity, remainingToDeduct);
            consumedItems.add(
              item.copyWith(quantity: taken.toInt()),
            ); // Record for calc

            if (item.quantity > taken) {
              workerInv[itemIndex] = item.copyWith(
                quantity: (item.quantity - taken).toInt(),
              );
            } else {
              workerInv.removeAt(itemIndex);
            }
            remainingToDeduct -= taken;
          }
          if (remainingToDeduct > 0) {
            consumedItems.add(
              GameItem.create(
                name: ing.toUpperCase(),
                type: ing,
                category: ItemCategory.resource,
                quantity: remainingToDeduct.toInt(),
              ),
            );
            setResource(
              ing,
              ((resources[ing] ?? 0) - remainingToDeduct).round(),
            );
          }
        }

        if (kitchenIndex != -1) {
          _rooms[kitchenIndex] = _rooms[kitchenIndex].copyWith(
            inventory: kitchenInv,
          );
        }
        _npcs[npcIndex] = _npcs[npcIndex].copyWith(inventory: workerInv);

        final latestWorker = _npcs[npcIndex];
        final knife = latestWorker.chefStats.knifeSkills;
        final sanitation = latestWorker.chefStats.sanitation;
        final nose = latestWorker.chefStats.nose;
        final fire = latestWorker.chefStats.fireSkills;
        final exp = latestWorker.dishExperience[recipe.id] ?? 0.0;

        double quality = recipe.baseQuality;
        quality += (nose / 100.0) * 0.5;
        quality += exp * 0.2;

        final rand = Random();
        if (rand.nextInt(100) > (40 + knife)) {
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] ${latestWorker.name} cut themselves while prepping!",
          );
          _npcs[npcIndex] = _npcs[npcIndex].copyWith(
            satisfaction: (_npcs[npcIndex].satisfaction - 10).clamp(0, 100),
          );
        }

        double yieldLoss = 0.0;
        final isFailure = rand.nextInt(100) > (30 + fire + (nose / 2));
        if (isFailure) {
          yieldLoss = 0.2 + (rand.nextDouble() * 0.3);
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] ${latestWorker.name} scorched the ${recipe.id}!",
          );

          // Fire risk during failures: 20% base chance if scorched, increased by dirtiness
          final kitchen = _rooms.firstWhere((r) => r.id == 'kitchen');
          final fireBaseChance = 0.2 + (kitchen.dirtiness * 0.3);
          if (Random().nextDouble() < fireBaseChance) {
            final fireEvent = ManorCrisis(
              id: const Uuid().v4(),
              type: ManorCrisisType.fire,
              roomId: 'kitchen',
              discoveryDate: _currentDate.toDateTime(),
              severity: 0.15,
              isDiscovered: true,
            );
            if (!_crises.any(
              (c) => c.roomId == 'kitchen' && c.type == ManorCrisisType.fire,
            )) {
              _crises.add(fireEvent);
              final kIdx = _rooms.indexWhere((r) => r.id == 'kitchen');
              if (kIdx != -1) {
                _rooms[kIdx] = _rooms[kIdx].copyWith(dirtiness: 1.0);
              }
              _announcementHistory.insert(
                0,
                "[${_currentDate.formattedTime}] EMERGENCY: A cooking failure has ignited a grease fire!",
              );
              _handleEmergency();
            }
          }
        }

        final kitchen = _rooms.firstWhere((r) => r.id == 'kitchen');
        double healthRisk =
            (1.0 -
                    (sanitation / 100.0) -
                    (nose / 200.0) +
                    (kitchen.dirtiness * 0.5))
                .clamp(0.0, 1.0);

        _rooms[_rooms.indexOf(kitchen)] = kitchen.copyWith(
          dirtiness: (kitchen.dirtiness + 0.1).clamp(0.0, 1.0),
        );

        if (isExperiment) {
          _restaurantNewRecipeAttempts++;
          int d100 = rand.nextInt(100) + 1;
          int score = KitchenService.calculateExperimentScore(
            latestWorker,
            consumedItems,
            d100,
          );
          final discoveredRecipe = KitchenService.performRecipeDiscovery(
            consumedItems,
            score,
          );

          if (discoveredRecipe != null) {
            _announcementHistory.insert(
              0,
              "[${_currentDate.formattedTime}] EXPERIMENT SUCCESS: ${latestWorker.name} invented ${discoveredRecipe.name} (Score: $score)!",
            );
            if (!_knownRecipes.contains(discoveredRecipe.id)) {
              _knownRecipes.add(discoveredRecipe.id);
              // Also notify ui somehow
            }
            // Yield the discovered dish
            int finalYield = discoveredRecipe.yield.clamp(1, 10);
            for (int i = 0; i < finalYield; i++) {
              _pantry.add(
                Dish(
                  id: const Uuid().v4(),
                  name: discoveredRecipe.name,
                  type: _mapToDishType(discoveredRecipe.id),
                  quality: _mapToDishQuality(discoveredRecipe.baseQuality),
                  cookedAt: _currentDate.copy(),
                  illnessRisk: 0.0,
                  shelfLifeHours: discoveredRecipe.id == 'staple_bread'
                      ? 336
                      : 168,
                ),
              );
            }
            notifyRoomProduction('kitchen', '+$finalYield');
          } else {
            _announcementHistory.insert(
              0,
              "[${_currentDate.formattedTime}] EXPERIMENT FAILED: ${latestWorker.name}'s concoction was inedible (Score: $score).",
            );
            _npcs[npcIndex] = _npcs[npcIndex].copyWith(
              satisfaction: (_npcs[npcIndex].satisfaction - 5).clamp(0, 100),
            );
          }
        } else {
          int finalYield = (recipe.yield * (1.0 - yieldLoss)).round().clamp(
            1,
            100,
          );

          for (int i = 0; i < finalYield; i++) {
            _pantry.add(
              Dish(
                id: const Uuid().v4(),
                name: recipe.name,
                type: _mapToDishType(recipe.id),
                quality: _mapToDishQuality(quality),
                cookedAt: _currentDate.copy(),
                illnessRisk: healthRisk,
                shelfLifeHours: recipe.id == 'staple_bread' ? 336 : 168,
              ),
            );
          }
          notifyRoomProduction('kitchen', '+$finalYield');

          Map<String, double> newExp = Map.from(_npcs[npcIndex].dishExperience);
          newExp[recipe.id] = (exp + 0.05).clamp(0.0, 1.0);
          _npcs[npcIndex] = _npcs[npcIndex].copyWith(dishExperience: newExp);
        }
      } else {
        final recipeName = recipe.name;
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] ${worker.name} failed to cook $recipeName: Insufficient ingredients.",
        );
      }
    } else if (task.type == TaskType.research ||
        task.type == TaskType.dissect ||
        task.type == TaskType.vivisection ||
        task.type == TaskType.puzzleStudy ||
        task.type == TaskType.deprivationStudy ||
        task.type == TaskType.clinicalTrial ||
        task.type == TaskType.refineFood) {
      if (task.type == TaskType.refineFood && task.recipeId != null) {
        cookRecipe(task.recipeId!, task.npcId, isPrepared: true);
      } else {
        _handleScienceTaskCompletion(npcIndex, task);
      }
    } else if (task.type == TaskType.archiveResearch ||
        task.type == TaskType.transcribeNotes) {
      final roomIndex = _rooms.indexWhere((r) => r.id == task.targetId);
      if (roomIndex != -1) {
        int processedCount = 0;
        final bool isTranscribe = task.type == TaskType.transcribeNotes;

        if (isTranscribe) {
          // TRANSCRIBE: Refine notes -> studies (Quality focus)
          // Process worker inventory
          final List<GameItem> workerInv = List.from(worker.inventory);
          for (int i = 0; i < workerInv.length; i++) {
            if (workerInv[i].type == 'research_notes') {
              workerInv[i] = workerInv[i].copyWith(
                name: workerInv[i].name.replaceFirst('Notes', 'Study'),
                type: 'research_study',
                quality: (workerInv[i].quality + 0.2).clamp(0.0, 2.0),
              );
              processedCount++;
            }
          }
          worker = worker.copyWith(inventory: workerInv);

          // Process room inventory
          final List<GameItem> roomInv = List.from(_rooms[roomIndex].inventory);
          for (int i = 0; i < roomInv.length; i++) {
            if (roomInv[i].type == 'research_notes') {
              roomInv[i] = roomInv[i].copyWith(
                name: roomInv[i].name.replaceFirst('Notes', 'Study'),
                type: 'research_study',
                quality: (roomInv[i].quality + 0.2).clamp(0.0, 2.0),
              );
              processedCount++;
            }
          }
          _rooms[roomIndex] = _rooms[roomIndex].copyWith(inventory: roomInv);

          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] ${worker.name} refined $processedCount research notes into structured studies.",
          );
        } else {
          // ARCHIVE: Organise items into room (Efficiency focus)
          final List<GameItem> roomInv = List.from(_rooms[roomIndex].inventory);

          // From worker
          final List<GameItem> workerInv = List.from(worker.inventory);
          for (int i = workerInv.length - 1; i >= 0; i--) {
            if (workerInv[i].category == ItemCategory.knowledge) {
              roomInv.add(workerInv.removeAt(i));
              processedCount++;
            }
          }
          worker = worker.copyWith(inventory: workerInv);

          // From global
          if (task.targetId == 'library' || task.targetId == 'study') {
            for (int i = inventory.length - 1; i >= 0; i--) {
              if (inventory[i].category == ItemCategory.knowledge) {
                roomInv.add(inventory.removeAt(i));
                processedCount++;
              }
            }
          }
          _rooms[roomIndex] = _rooms[roomIndex].copyWith(inventory: roomInv);

          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] ${worker.name} organized $processedCount items into the ${_rooms[roomIndex].name} archive.",
          );
        }
        _npcs[npcIndex] = worker;
      }
    }

    if (task.type == TaskType.greetGuest) {
      _lastAnnouncement = "${worker.name} greeted the guest at the door.";
    } else if (task.type == TaskType.trainCreature) {
      // Find the entity being trained (assuming it's in the room or targetId)
      final targetNpcIndex = _npcs.indexWhere((n) => n.id == task.targetId);
      if (targetNpcIndex != -1) {
        _npcs[targetNpcIndex] = _npcs[targetNpcIndex].copyWith(isTrained: true);
        _lastAnnouncement =
            "${worker.name} has finished training ${_npcs[targetNpcIndex].name} for combat.";
      }
    } else if (task.type == TaskType.surgicalCombination) {
      _handleSurgicalCombination(npcIndex, task);
    }

    // 3. Process Resources Gained (Loot)
    for (var entry in result.resourcesGained.entries) {
      final key = entry.key;
      final value = entry.value;
      setResource(
        key,
        ((resources[key] ?? 0) + (value * yieldMultiplier)).round(),
      );
    }

    // Science Research Points
    if (task.type == TaskType.dissect || task.type == TaskType.vivisection) {
      final double points = task.type == TaskType.vivisection ? 5.0 : 2.5;
      _researchPoints['Small Creature Anatomy'] = (_researchPoints['Small Creature Anatomy'] ?? 0) + points;
      _researchPoints['Anatomy'] = (_researchPoints['Anatomy'] ?? 0) + points;
      _researchPoints['Alchemy'] = (_researchPoints['Alchemy'] ?? 0) + points;
      _researchPoints['Zoology'] = (_researchPoints['Zoology'] ?? 0) + points;

      final String actionTitle = task.type == TaskType.vivisection ? "Vivisection" : "Dissection";
      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] RESEARCH: $actionTitle completed. Gained +${points.toInt()} points in Small Creature Anatomy & Alchemy.",
      );
      _checkDiscoveries();
    }

    if (task.type == TaskType.experiment || task.type == TaskType.operation || task.type == TaskType.research || task.type == TaskType.study) {
      final matchId = task.recipeId ?? task.targetName ?? '';
      final firstReservedId = task.reservedEntityIds.firstOrNull;
      final bool isRat = matchId == 'reanimation_rat' || matchId.contains('RAT') || (matchId == 'reanimation_procedure' && firstReservedId == 'specimen_rat');
      final bool isBat = matchId == 'reanimation_bat' || matchId.contains('BAT') || (matchId == 'reanimation_procedure' && firstReservedId == 'specimen_bat');
      final bool isHuman = matchId.startsWith('reanimation_human') || matchId.contains('HUMAN') || (matchId == 'reanimation_procedure' && !isRat && !isBat);

      if (isRat) {
        _reanimatedRatsCount++;
        _announcementHistory.insert(0, "[${_currentDate.formattedTime}] REANIMATION: Galvanic life stirred inside Rat subject ($_reanimatedRatsCount/4).");
        if (_reanimatedRatsCount == 4) {
          _announcementHistory.insert(0, "[${_currentDate.formattedTime}] NECROMANCY: A permanent unit of Undead Rats has joined your standing army!");
          final newSquad = CombatUnitFactory.createUndeadRats();
          _npcs.add(newSquad);
          final pIdx = _npcs.indexWhere((n) => n.isPlayer);
          if (pIdx != -1) {
            final p = _npcs[pIdx];
            _npcs[pIdx] = p.copyWith(lastEscortIds: [...p.lastEscortIds, newSquad.id]);
          }
        }
        if (!_performedExperiments.contains('reanimation')) _performedExperiments.add('reanimation');
        _researchQueue.removeWhere((q) => q == 'reanimation_rat' || q == 'activity:reanimation_rat' || q == 'activity:reanimation_procedure');
        _checkObjectives();
      } else if (isBat) {
        _reanimatedBatsCount++;
        _announcementHistory.insert(0, "[${_currentDate.formattedTime}] REANIMATION: Galvanic life stirred inside Bat subject ($_reanimatedBatsCount/4).");
        if (_reanimatedBatsCount == 4) {
          _announcementHistory.insert(0, "[${_currentDate.formattedTime}] NECROMANCY: A permanent unit of Undead Bats has joined your standing army!");
          final newSquad = CombatUnitFactory.createUndeadBats();
          _npcs.add(newSquad);
          final pIdx = _npcs.indexWhere((n) => n.isPlayer);
          if (pIdx != -1) {
            final p = _npcs[pIdx];
            _npcs[pIdx] = p.copyWith(lastEscortIds: [...p.lastEscortIds, newSquad.id]);
          }
        }
        if (!_performedExperiments.contains('reanimation')) _performedExperiments.add('reanimation');
        _researchQueue.removeWhere((q) => q == 'reanimation_bat' || q == 'activity:reanimation_bat' || q == 'activity:reanimation_procedure');
        _checkObjectives();
      } else if (isHuman) {
        _reanimatedHumanCount++;
        final parts = matchId.split(':');
        final targetHumanId = parts.length > 1 ? parts[1] : firstReservedId;
        final humanIndex = _npcs.indexWhere((n) => n.id == targetHumanId);
        if (humanIndex != -1) {
          final humanNpc = _npcs[humanIndex];
          _announcementHistory.insert(0, "[${_currentDate.formattedTime}] REANIMATION: The modern Prometheus awakes! ${humanNpc.name} transformed into a living Flesh Golem!");
          
          final golemSquad = CombatUnitFactory.createFleshGolem();
          final golemStats = golemSquad.combatStats!;
          final golemAppearance = golemSquad.appearance;
          
          _npcs[humanIndex] = humanNpc.copyWith(
            name: "${humanNpc.name} (Flesh Golem)",
            role: "Flesh Golem",
            specimenType: "Flesh Golem",
            appearance: golemAppearance,
            combatStats: golemStats,
            metadata: Map.from(humanNpc.metadata)..addAll({
              'isFleshGolem': true,
              'temperTantrumRisk': 0.4,
              'shownCompassion': true,
            }),
          );
          
          final pIdx = _npcs.indexWhere((n) => n.isPlayer);
          if (pIdx != -1) {
            final p = _npcs[pIdx];
            if (!p.lastEscortIds.contains(humanNpc.id)) {
              _npcs[pIdx] = p.copyWith(lastEscortIds: [...p.lastEscortIds, humanNpc.id]);
            }
          }
        } else {
          _announcementHistory.insert(0, "[${_currentDate.formattedTime}] REANIMATION: The modern Prometheus awakes! Transformed human subject into a living Flesh Golem!");
          final newSquad = CombatUnitFactory.createFleshGolem();
          _npcs.add(newSquad);
          final pIdx = _npcs.indexWhere((n) => n.isPlayer);
          if (pIdx != -1) {
            final p = _npcs[pIdx];
            _npcs[pIdx] = p.copyWith(lastEscortIds: [...p.lastEscortIds, newSquad.id]);
          }
        }
        if (!_performedExperiments.contains('reanimation')) _performedExperiments.add('reanimation');
        _researchQueue.removeWhere((q) => q.contains('reanimation_human') || q == 'activity:reanimation_procedure');
        _checkObjectives();
      }
    }

    // Character status synchronization
    final hour = _currentDate.hour;
    final preferredRoom = currentNpc.schedule.getPreferredRoomForHour(hour);

    // [FIX] RE-FETCH latest worker to preserve changes from sub-methods (e.g., _handleScienceTaskCompletion)
    final latestWorker = _npcs[npcIndex];

    if (latestWorker.satisfaction != currentNpc.satisfaction && newSatisfaction == currentNpc.satisfaction) {
      newSatisfaction = latestWorker.satisfaction;
    }
    if (latestWorker.hunger != currentNpc.hunger && newHunger == currentNpc.hunger) {
      newHunger = latestWorker.hunger;
    }
    if (latestWorker.cleanliness != currentNpc.cleanliness && newCleanliness == currentNpc.cleanliness) {
      newCleanliness = latestWorker.cleanliness;
    }
    if (latestWorker.digestion != currentNpc.digestion && newDigestion == currentNpc.digestion) {
      newDigestion = latestWorker.digestion;
    }

    // Final Sync: Apply all accumulated changes back to global list
    _npcs[npcIndex] = latestWorker.copyWith(
      status:
          (result.message.contains("waiting instructions") &&
              latestWorker.specimenType.toLowerCase() == 'fox')
          ? NPCStatus.idle
          : NPCStatus.idle,
      activeTaskId: null,
      targetRoomId: preferredRoom,
      clearTarget: preferredRoom == null,
      movementProgress:
          (preferredRoom == currentNpc.currentRoomId || preferredRoom == null)
          ? 1.0
          : 0.0,
      satisfaction: newSatisfaction.clamp(0.0, 100.0),
      digestion: newDigestion,
      cleanliness: newCleanliness,
      hunger: newHunger.clamp(0.0, 100.0),
      breakingPointMinutes: newBreakingPointMinutes,
      currentThought: newThought,
      currentStateTicks: 0,
      intentQueue: newQueue,
      inventory: (latestWorker.inventory.length > newInventory.length)
          ? latestWorker.inventory
          : newInventory,
    );

    // Grant Integer Experience for task completion
    final int duration = task.totalMinutes > 0 ? task.totalMinutes : 60;

    // 1. Proficiency XP (10x scaled, e.g. 60 mins -> 12 xp Cooking)
    final proficiencyName = TaskService.getProficiency(task.type);
    int? gainedProfXp;
    if (proficiencyName != null) {
      gainedProfXp = (duration / 5.0).floor();
      if (gainedProfXp < 1) gainedProfXp = 0;
      if (gainedProfXp > 0) {
        _addProficiencyExperience(
          npcIndex,
          proficiencyName,
          gainedProfXp.toDouble(),
        );
      }
    }

  bool doesTaskDevelopCoreAttributes(TaskType type) {
    switch (type) {
      case TaskType.restoreRoom:
      case TaskType.construction:
      case TaskType.mining:
      case TaskType.excavate:
      case TaskType.dissect:
      case TaskType.vivisection:
      case TaskType.surgery:
      case TaskType.research:
      case TaskType.puzzleStudy:
      case TaskType.deprivationStudy:
      case TaskType.defendManor:
      case TaskType.guardCoop:
      case TaskType.cardio:
      case TaskType.weights:
      case TaskType.trainCreature:
        return true;
      default:
        return false;
    }
  }

  // 2. Attribute XP (10x scaled, e.g. 200 mins -> 10-15 xp Strength)
  final taskMeta = TaskService.getMetadata(task.type);
  final List<String> gainedStats = [];
  int? gainedStatXp;
  if (taskMeta.relevantAttributes.isNotEmpty && doesTaskDevelopCoreAttributes(task.type)) {
    int baseStatXp = (duration / 20.0).floor();
    if (baseStatXp >= 1) {
      final random = Random();
      final chosenStat = taskMeta.relevantAttributes[random.nextInt(taskMeta.relevantAttributes.length)].toLowerCase();
      
      int extra = random.nextInt((baseStatXp * 0.5).floor() + 1);
      gainedStatXp = baseStatXp + extra;
      gainedStats.add(chosenStat);
      _addStatExperience(npcIndex, chosenStat, gainedStatXp.toDouble());
    }
  }

    // Build Gained Integer XP Summary String
    List<String> xpLogParts = [];
    if (gainedProfXp != null && gainedProfXp > 0) {
      xpLogParts.add("$gainedProfXp xp ${proficiencyName!.toUpperCase()}");
    }
    if (gainedStatXp != null && gainedStatXp > 0 && gainedStats.isNotEmpty) {
      for (var statName in gainedStats) {
        xpLogParts.add("$gainedStatXp xp ${statName.toUpperCase()}");
      }
    }

    String xpLogSuffix = "";
    if (xpLogParts.isNotEmpty) {
      xpLogSuffix = " [GAINED: ${xpLogParts.join(' | ')}]";
    }

    // 6. Automatic Ranching Troop Creation
    if (proficiencyName == 'Ranching' || task.type == TaskType.trainCreature || task.type == TaskType.interactAnimals) {
      bool hasRanchingTrainer = _npcs.any((n) => (n.metadata['proficiency_level_Ranching'] as int? ?? 0) >= 2);
      if (hasRanchingTrainer) {
        _trainedBatsCount++;
        if (_trainedBatsCount >= 4) {
          _trainedBatsCount -= 4;
          _unlockedCombatCards.add('wild_bats');
          
          ArenaSaveService.loadProgress(1).then((progress) {
            if (progress != null) {
              if (progress.campaign != null && !progress.campaign!.playerDeckIds.contains('wild_bats')) {
                progress.campaign!.playerDeckIds.add('wild_bats');
              }
              if (progress.survival != null && !progress.survival!.playerDeckIds.contains('wild_bats')) {
                progress.survival!.playerDeckIds.add('wild_bats');
              }
              ArenaSaveService.saveProgress(progress);
            }
          });

          _announcementHistory.insert(0, "[${_currentDate.formattedTime}] RANCHING: Four trained bats have been successfully organized into a dedicated Bats combat unit card available in your deck!");
        }
      }
    }

    // Laboratory Scientific Progression Network
    if (task.type == TaskType.dissect) {
      _dissectionsPerformed++;
      if (_dissectionsPerformed == 1) {
        _unlockedLabActivities.add('small_vivisection');
        _unlockedLabActivities.add('large_vivisection');
        _triggerMobileFireworksNotification("VIVISECTION UNLOCKED", "By dissecting deceased tissue, you have discovered how to perform biological vivisection on living subjects!");
      }
    } else if (task.type == TaskType.vivisection) {
      _vivisectionsPerformed++;
      if (_vivisectionsPerformed == 3) {
        _unlockedLabActivities.add('deprivation_study');
        _triggerMobileFireworksNotification("DEPRIVATION STUDY UNLOCKED", "Your profound vivisection studies have revealed how to conduct rigorous sensory and nutritional deprivation experiments!");
      }
    } else if (task.type == TaskType.puzzleStudy) {
      _puzzleStudiesPerformed++;
      if (_puzzleStudiesPerformed == 2 && !_unlockedLabActivities.contains('behavioral_optimization')) {
        _unlockedLabActivities.add('behavioral_optimization');
        _triggerMobileFireworksNotification("BEHAVIORAL OPTIMIZATION UNLOCKED", "Your extensive cognitive puzzle studies enable master behavioral optimization experiments!");
      }
    } else if (task.type == TaskType.experiment || task.type == TaskType.operation) {
      _labExperimentsPerformed++;
      if (_labExperimentsPerformed == 5 && !_unlockedLabActivities.contains('transmutation')) {
        _unlockedLabActivities.add('transmutation');
        _triggerMobileFireworksNotification("BIOLOGICAL TRANSMUTATION UNLOCKED", "Your consistent galvanic experiments unlock the profound secrets of biological Transmutation!");
      }
    }
    
    // Knowledge Unlocks Check
    if (getKnowledgeLevel('Zoology') >= 15 && !_unlockedLabActivities.contains('puzzle_study')) {
      _unlockedLabActivities.add('puzzle_study');
      _triggerMobileFireworksNotification("COGNITIVE PUZZLE STUDY UNLOCKED", "Your advanced Zoology knowledge (Level 15+) enables complex cognitive puzzle experiments!");
    }
    if (getKnowledgeLevel('Medicine') >= 20 && !_unlockedLabActivities.contains('clinical_trial')) {
      _unlockedLabActivities.add('clinical_trial');
      _triggerMobileFireworksNotification("GENERAL CLINICAL TRIAL UNLOCKED", "Your masterful Medicine knowledge (Level 20+) enables sweeping general clinical trials!");
    }

    final finalLogMessage = "${result.message}$xpLogSuffix";
    if (_lastAnnouncement == result.message) {
      _lastAnnouncement = finalLogMessage;
    } else if (xpLogParts.isNotEmpty) {
      _lastAnnouncement = "$_lastAnnouncement$xpLogSuffix";
    }

    // Filter silence for foxes
    final isFoxWaiting =
        worker.specimenType.toLowerCase() == 'fox' &&
        result.message.contains("waiting instructions");
    if (!isFoxWaiting) {
      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] $finalLogMessage",
      );
      if (_announcementHistory.length > 50) _announcementHistory.removeLast();
    }

    if ((task.type == TaskType.cleanRoom ||
            task.type == TaskType.restoreRoom) &&
        result.itemsFound.isNotEmpty &&
        task.targetId != null) {
      String destRoomId = task.targetId!;
      final study = _rooms.firstWhereOrNull(
        (r) => r.type == RoomType.study && r.isRestored,
      );
      final toolshed = _rooms.firstWhereOrNull(
        (r) => r.id == 'toolshed' && r.isRestored,
      );

      if (study != null) {
        destRoomId = study.id;
      } else if (toolshed != null) {
        destRoomId = toolshed.id;
      }

      if (destRoomId != task.targetId) {
        final itemsToHaul = result.itemsFound
            .map(
              (i) => i.copyWith(creationDate: i.creationDate ?? _currentDate),
            )
            .toList();
        final npcToUpdate = _npcs[npcIndex];
        final newWorkerInv = List<GameItem>.from(npcToUpdate.inventory)
          ..addAll(itemsToHaul);

        final newIntentQueue = List<NPCIntent>.from(npcToUpdate.intentQueue);
        newIntentQueue.insert(
          0,
          NPCIntent(
            id: 'haul_discovery_${DateTime.now().millisecondsSinceEpoch}',
            action: TaskType.hauling,
            priority: IntentPriority.high,
            targetRoomId: destRoomId,
          ),
        );

        _npcs[npcIndex] = npcToUpdate.copyWith(
          inventory: newWorkerInv,
          intentQueue: newIntentQueue,
        );

        final names = itemsToHaul.map((i) => i.name).join(', ');
        _lastAnnouncement =
            "${npcToUpdate.name} found items ($names) and is hauling them to the ${destRoomId.split('_').join(' ').toUpperCase()}.";
      } else {
        for (var i in result.itemsFound) {
          addItemToRoom(
            task.targetId!,
            i.copyWith(creationDate: i.creationDate ?? _currentDate),
          );
        }
        if (result.message.isNotEmpty) _lastAnnouncement = result.message;
      }
    } else {
      for (var i in result.itemsFound) {
        _addPhysicalItem(
          i.copyWith(creationDate: i.creationDate ?? _currentDate),
        );
      }
      if (result.message.isNotEmpty) _lastAnnouncement = result.message;
    }

    // Room Type Conversion for Industrials
    if (task.targetId != null) {
      final roomIdx = _rooms.indexWhere((r) => r.id == task.targetId);
      if (roomIdx != -1) {
        Room r = _rooms[roomIdx];
        if (task.type == TaskType.construction) {
          if (r.isUnderConstruction) {
            RoomType upgradedType = r.type;
            String upgradedName = r.name;
            String upgradeDesc = r.description;
            List<Bed> newBeds = List.from(r.beds);

            if (r.constructionTarget == 'laboratory') {
              upgradedType = RoomType.laboratory;
              upgradedName = 'Laboratory';
              upgradeDesc =
                  'A specialized room for scientific research and experimentation.';
            } else if (r.constructionTarget == 'bedroom') {
              upgradedType = RoomType.bedroom;
              upgradedName = 'Spare Bedroom';
              upgradeDesc =
                  'A clean and quiet bedroom for guests or residents.';
              newBeds.add(
                Bed(type: BedType.queen, assignedNpcIds: [null, null]),
              );
            } else if (r.constructionTarget == 'mine') {
              final resType = r.metadata['resourceType'] as String? ?? 'ore';
              upgradedType = RoomType.mine;
              upgradedName = '${resType.toUpperCase()} MINE';
              upgradeDesc = 'A secure mining facility targeting a rich seam of ${resType.toUpperCase()} ore.';
            } else if (r.constructionTarget == 'oil_well') {
              upgradedType = RoomType.oilWell;
              upgradedName = 'OIL WELL';
              upgradeDesc = 'A sturdy pumping rig designed to extract subterranean oil deposits.';
            }

            r = r.copyWith(
              type: upgradedType,
              name: upgradedName,
              description: upgradeDesc,
              isRestored: true,
              isUnderConstruction: false,
              constructionTarget: null,
              beds: newBeds,
            );
            _rooms[roomIdx] = r;
            result = TaskResult(
              message: "Construction of $upgradedName is complete!",
            );
            _checkForCreatures(worker, r);

            // Unlock Quest Flow
            if (upgradedType == RoomType.laboratory) {
              if (!_objectives.any((o) => o.id == 'first_construct_1')) {
                _objectives.add(
                  Objective(
                    id: 'first_construct_1',
                    title: 'The First Construct - Step 1',
                    description: 'Perform Fundamental Research one time.',
                    type: ObjectiveType.science,
                    requirements: {
                      'task_counts': {'research': 1},
                    },
                    nextObjectiveId: 'first_construct_2',
                  ),
                );
                _unreadObjectiveCount++;
              }
            }
          }
        }

        if (task.type == TaskType.restoreRoom) {
          if (!r.isRestored) {
            RoomType upgradedType = r.type;
            String upgradedName = r.name;
            if (r.id.startsWith('library')) {
              upgradedType = RoomType.library;
              upgradedName = 'Library';
            } else if (r.id.startsWith('study')) {
              upgradedType = RoomType.study;
              upgradedName = 'Study';
            } else if (r.id.startsWith('attic')) {
              upgradedType = RoomType.unused;
              upgradedName = r.name.replaceAll('Unused ', '');
            } else if (r.id.startsWith('chicken_coop')) {
              upgradedType = RoomType.chickenCoop;
              upgradedName = 'Chicken Coop';
            } else if (r.id.startsWith('vegetable_garden')) {
              upgradedType = RoomType.garden;
              upgradedName = 'Vegetable Garden';
            }

            _rooms[roomIdx] = r.copyWith(
              restorationProgress: 1.0,
              isRestored: true,
              type: upgradedType,
              name: upgradedName,
            );
            if (r.id == 'chicken_coop') {
              for (int i = 0; i < 3; i++) {
                _chickens.add(
                  Chicken.create(
                    ChickenBreedType.houdan,
                    _currentDate,
                    isMale: false,
                  ).copyWith(
                    birthDate: _currentDate.copyWith(
                      year: _currentDate.year - 1,
                    ),
                  ),
                ); // 1 year old, immediately mature
              }
            }
            _checkForCreatures(worker, _rooms[roomIdx]);
          }
        } else if (task.type == TaskType.excavate) {
          if (!r.isRestored && r.name == 'Excavation Node') {
            final resType = r.metadata['resourceType'] as String?;
            if (resType != null && resType != 'oil_well_site') {
              _rooms[roomIdx] = r.copyWith(
                name: 'Blocked by ${resType.toUpperCase()} Seam',
                type: RoomType.unused,
                isRestored: true,
              );
              _lastAnnouncement = "${worker.name} successfully excavated the chamber. It is blocked by a rich seam of ${resType.toUpperCase()} ore!";
            } else {
              _rooms[roomIdx] = r.copyWith(
                name: 'Subterranean Vault',
                type: RoomType.unused,
                isRestored: true,
              );
              _lastAnnouncement = "${worker.name} successfully excavated the subterranean vault.";
            }
          }
        } else if (task.type == TaskType.mining) {
          if (r.type == RoomType.oilWell) {
            // Pump oil
            final efficiency = getOilPumpingEfficiency();
            final int baseAmount = 300;
            final int pumped = (baseAmount * efficiency).round();

            int remainingToDrain = pumped;
            
            // Drain basement_j first
            final idxJ = _rooms.indexWhere((rm) => rm.id == 'basement_j');
            if (idxJ != -1 && remainingToDrain > 0) {
              final rmJ = _rooms[idxJ];
              final int currentAmt = rmJ.metadata['resourceAmount'] as int? ?? 0;
              if (currentAmt > 0) {
                final drained = currentAmt < remainingToDrain ? currentAmt : remainingToDrain;
                final newAmt = currentAmt - drained;
                remainingToDrain -= drained;

                final newMeta = Map<String, dynamic>.from(rmJ.metadata);
                newMeta['resourceAmount'] = newAmt;

                if (newAmt <= 0) {
                  newMeta['isResourceBlocked'] = false;
                  _rooms[idxJ] = rmJ.copyWith(
                    name: 'Subterranean Vault',
                    type: RoomType.unused,
                    isRestored: true,
                    description: 'A hollowed out basement space, now cleared of crude oil.',
                    metadata: newMeta,
                  );
                  _announcementHistory.insert(0, "[${_currentDate.formattedTime}] GEOLOGY: Subterranean Vault J has been cleared of oil!");
                } else {
                  _rooms[idxJ] = rmJ.copyWith(metadata: newMeta);
                }
              }
            }

            // Drain basement_o next
            final idxO = _rooms.indexWhere((rm) => rm.id == 'basement_o');
            if (idxO != -1 && remainingToDrain > 0) {
              final rmO = _rooms[idxO];
              final int currentAmt = rmO.metadata['resourceAmount'] as int? ?? 0;
              if (currentAmt > 0) {
                final drained = currentAmt < remainingToDrain ? currentAmt : remainingToDrain;
                final newAmt = currentAmt - drained;
                remainingToDrain -= drained;

                final newMeta = Map<String, dynamic>.from(rmO.metadata);
                newMeta['resourceAmount'] = newAmt;

                if (newAmt <= 0) {
                  newMeta['isResourceBlocked'] = false;
                  _rooms[idxO] = rmO.copyWith(
                    name: 'Subterranean Vault',
                    type: RoomType.unused,
                    isRestored: true,
                    description: 'A hollowed out basement space, now cleared of crude oil.',
                    metadata: newMeta,
                  );
                  _announcementHistory.insert(0, "[${_currentDate.formattedTime}] GEOLOGY: Subterranean Vault O has been cleared of oil!");
                } else {
                  _rooms[idxO] = rmO.copyWith(metadata: newMeta);
                }
              }
            }

            // 2/3 Depletion Hollowing Trigger:
            // If 2/3 of the manor's oil reserve is depleted, both rooms underneath are hollowed out
            final remainingRes = manorOilReserve;
            final maxRes = manorOilReserveMax;
            if (remainingRes <= maxRes / 3.0) {
              final jIndex = _rooms.indexWhere((rm) => rm.id == 'basement_j');
              if (jIndex != -1 && _rooms[jIndex].metadata['isResourceBlocked'] == true) {
                final rmJ = _rooms[jIndex];
                final newMeta = Map<String, dynamic>.from(rmJ.metadata);
                newMeta['isResourceBlocked'] = false;
                _rooms[jIndex] = rmJ.copyWith(
                  name: 'Subterranean Vault',
                  type: RoomType.unused,
                  isRestored: true,
                  description: 'A hollowed out basement space, now cleared of crude oil.',
                  metadata: newMeta,
                );
                _announcementHistory.insert(0, "[${_currentDate.formattedTime}] GEOLOGY: Subterranean Vault J has been hollowed out at 2/3 reserve depletion.");
              }

              final oIndex = _rooms.indexWhere((rm) => rm.id == 'basement_o');
              if (oIndex != -1 && _rooms[oIndex].metadata['isResourceBlocked'] == true) {
                final rmO = _rooms[oIndex];
                final newMeta = Map<String, dynamic>.from(rmO.metadata);
                newMeta['isResourceBlocked'] = false;
                _rooms[oIndex] = rmO.copyWith(
                  name: 'Subterranean Vault',
                  type: RoomType.unused,
                  isRestored: true,
                  description: 'A hollowed out basement space, now cleared of crude oil.',
                  metadata: newMeta,
                );
                _announcementHistory.insert(0, "[${_currentDate.formattedTime}] GEOLOGY: Subterranean Vault O has been hollowed out at 2/3 reserve depletion.");
              }
            }

            updateResource('crude_oil', pumped);
            _lastAnnouncement = "${worker.name} pumped $pumped barrels of crude oil. Pumping efficiency: ${(efficiency * 100).toInt()}%.";
          } else if (r.type == RoomType.mine) {
            final resType = r.metadata['resourceType'] as String?;
            if (resType != null) {
              int baseAmount = 200;
              if (resType == 'silver' || resType == 'cobalt' || resType == 'nickel' || resType == 'lithium') {
                baseAmount = 100;
              } else if (resType == 'gold' || resType == 'titanium' || resType == 'jadeite') {
                baseAmount = 50;
              } else if (resType == 'diamonds' || resType == 'uranium') {
                baseAmount = 20;
              }

              final int currentAmt = r.metadata['resourceAmount'] as int? ?? 0;
              final mined = currentAmt < baseAmount ? currentAmt : baseAmount;
              final newAmt = currentAmt - mined;

              final newMeta = Map<String, dynamic>.from(r.metadata);
              newMeta['resourceAmount'] = newAmt;

              String itemType = resType;
              if (resType == 'diamonds') {
                itemType = 'rough_diamonds';
              } else if (resType != 'coal') {
                itemType = '${resType}_ore';
              }

              updateResource(itemType, mined);

              if (newAmt <= 0) {
                newMeta['isResourceBlocked'] = false;
                _rooms[roomIdx] = r.copyWith(
                  name: 'Subterranean Vault',
                  type: RoomType.unused,
                  isRestored: true,
                  description: 'A hollowed out basement space, now completely mined out.',
                  metadata: newMeta,
                );
                _lastAnnouncement = "${worker.name} mined $mined units of ${resType.toUpperCase()}. The seam is fully DEPLETED!";
              } else {
                _rooms[roomIdx] = r.copyWith(metadata: newMeta);
                _lastAnnouncement = "${worker.name} mined $mined units of ${resType.toUpperCase()}. Remaining in vein: $newAmt.";
              }
            }
          }
        } else if (task.type == TaskType.construction) {
          int pIdx = _activeConstruction.indexWhere(
            (p) => p.blueprint.id == r.id.split('_').first,
          );
          if (pIdx != -1) {
            var project = _activeConstruction[pIdx];
            double nextP = (project.progress + 0.25).clamp(0.0, 1.0);
            _activeConstruction[pIdx] = project.copyWith(
              progress: nextP,
              isStarted: true,
            );
            if (nextP >= 1.0) {
              _completeConstruction(project);
              _activeConstruction.removeAt(pIdx);
            }
          }
        } else if (task.type == TaskType.cleanRoom) {
          _rooms[roomIdx] = r.copyWith(dirtiness: 0.0);
          _checkForCreatures(worker, _rooms[roomIdx]);
        }
      }
    }

  }

  void _checkForCreatures(NPC worker, Room r) {
    final random = Random();
    final roll = random.nextDouble();

    // 1. Chance for Specimens (15%)
    if (roll < 0.15) {
      String? creatureId;
      String? creatureName;

      if (r.floor == Floor.basement) {
        creatureId = 'rat_specimen';
        creatureName = 'a scurrying rat';
      } else if (r.floor == Floor.attic || r.floor == Floor.second) {
        creatureId = 'bat_specimen';
        creatureName = 'a leathery bat';
      }

      if (creatureId != null) {
        final isMale = random.nextBool();
        final ageWks = random.nextInt(20) + 1; // 1-20 weeks
        final weightG = random.nextInt(300) + 50; // 50-350g

        final displayName =
            "${creatureId == 'rat_specimen' ? 'Brown Rat' : 'Leathery Bat'} (${isMale ? 'Male' : 'Female'}, $ageWks wks, ${weightG}g)";

        addItemToRoom(
          r.id,
          GameItem.create(
            name: displayName,
            type: creatureId,
            category: ItemCategory.specimen,
            metadata: {
              'gender': isMale ? 'Male' : 'Female',
              'ageWeeks': ageWks,
              'weightGrams': weightG,
            },
          ),
        );

        _lastAnnouncement =
            "${worker.name} discovered $creatureName and captured it!";
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] DISCOVERY: Captured a specimen in the ${r.name}.",
        );
      }
    }

    // 2. Chance for Notes (10%)
    final noteRoll = random.nextDouble();
    if (noteRoll < 0.10) {
      final disciplines = [
        'Anatomy',
        'Zoology',
        'Medicine',
        'Chemistry',
        'Psychology',
      ];
      final discipline = disciplines[random.nextInt(disciplines.length)];

      final note = GameItem.create(
        name: 'Old Notes ($discipline)',
        type: 'research_notes',
        category: ItemCategory.knowledge,
        quantity: 1,
        quality: 0.5 + (random.nextDouble() * 0.5),
        metadata: {
          'discipline': discipline,
          'description':
              'Faded observations found tucked behind a loose floorboard.',
        },
      );

      _addPhysicalItem(note);
      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] DISCOVERY: Found discarded research notes on $discipline.",
      );
    }
  }

  double getTaskEfficiency(NPC npc, TaskType type) {
    bool isMaster = npc.role == 'Scientist' || npc.role == 'Master';
    bool isButler = npc.role == 'Butler';

    switch (type) {
      case TaskType.cleanRoom:
      case TaskType.restoreRoom:
      case TaskType.collectEggs:
      case TaskType.harvestCabbage:
        return isMaster ? 0.5 : (isButler ? 1.2 : 1.0);
      case TaskType.research:
      case TaskType.dissect:
      case TaskType.transcribeNotes:
      case TaskType.observeExperiment:
        return isMaster ? 1.5 : (isButler ? 0.6 : 0.8);
      case TaskType.hunt:
        return isButler ? 1.3 : 1.0;
      case TaskType.brew:
      case TaskType.setupBrewery:
        return npc.role == 'Brewer' ? 2.0 : 0.5;
      case TaskType.distill:
      case TaskType.setupDistillery:
        return npc.role == 'Distiller' ? 2.0 : 0.3;
      case TaskType.processTimber:
      case TaskType.setupWorkshop:
        return npc.role == 'Carpenter' ? 2.0 : 0.5;
      case TaskType.harvestGrain:
      case TaskType.setupGranary:
        return npc.role == 'Farmer' ? 1.5 : 0.8;
      default:
        return 1.0;
    }
  }

  int getEstimatedTaskMinutes(NPC npc, TaskType type, [String? targetId]) {
    int baseMinutes = 120; // 2 hours default

    if (type == TaskType.extinguishFire) {
      final crisis = _crises.firstWhereOrNull(
        (c) => c.roomId == targetId && c.type == ManorCrisisType.fire,
      );
      final severity = crisis?.severity ?? 0.1;
      final activeFighters = _taskService.activeTasks
          .where(
            (t) => t.type == TaskType.extinguishFire && t.targetId == targetId,
          )
          .length;
      final totalFighters = activeFighters + 1;

      if (totalFighters >= 2) {
        // 20-30 minutes if quick response (low severity), scaling slightly higher if severe
        return (20 + (severity * 40)).round().clamp(20, 70);
      } else {
        // Single character or late response: 60-120 minutes
        return (60 + (severity * 120)).round().clamp(60, 180);
      }
    }

    switch (type) {
      // Quick Actions (10-15 mins)
      case TaskType.useToilet:
      case TaskType.washHands:
      case TaskType.wash:
      case TaskType.collectEggs:
      case TaskType.deliverEggs:
      case TaskType.checkBedridden:
      case TaskType.collectIngredients:
      case TaskType.discardTrash:
      case TaskType.discardSpoiledFood:
        baseMinutes = 15;
        break;

      // Short Actions (20-45 mins)
      case TaskType.cleanRoom:
      case TaskType.cleanDish:
      case TaskType.eat:
      case TaskType.relax:
      case TaskType.harvestCabbage:
      case TaskType.greetGuest:
      case TaskType.stopBleeding:
      case TaskType.hauling:
        baseMinutes = 30;
        break;

      // Medium Actions (60-90 mins)
      case TaskType.bathe:
      case TaskType.cook:
      case TaskType.prepareMeals:
      case TaskType.butcherAnimals:
      case TaskType.diagnoseIllness:
      case TaskType.treatIllness:
      case TaskType.careForInjured:
      case TaskType.careForSick:
        baseMinutes = 60;
        break;

      case TaskType.construction:
        baseMinutes = 720;
        break;

      case TaskType.paint:
        baseMinutes = 360; // 6 Hours
        break;

      case TaskType.writePoetry:
        baseMinutes = 120; // 2 Hours
        break;

      case TaskType.sculpt:
      case TaskType.writeNovel:
        baseMinutes = 720; // 12 Hours
        break;

      case TaskType.readBook:
      case TaskType.goForWalk:
      case TaskType.cardio:
      case TaskType.weights:
      case TaskType.interactAnimals:
        baseMinutes = 60; // 1 Hour
        break;

      case TaskType.excavate:
        baseMinutes = 1200; // 20 Hours
        break;

      // Long Actions (4 Hours/240 mins)
      case TaskType.tillSoil:
      case TaskType.fertilizeSoil:
      case TaskType.plantCrops:
        baseMinutes = 240;
        break;
      case TaskType.waterCrops:
      case TaskType.careForCrops:
        if (targetId != null) {
          final cropsInRoom = _crops.where((c) => c.roomId == targetId).length;
          if (cropsInRoom <= 5) {
            baseMinutes = 60; // Half field
          } else {
            baseMinutes = 120; // Full field
          }
        } else {
          baseMinutes = 120;
        }
      case TaskType.harvestCrops:
      case TaskType.harvestGrain:
      case TaskType.research:
      case TaskType.study:
      case TaskType.experiment:
      case TaskType.dissect:
      case TaskType.vivisection:
      case TaskType.surgicalOperation:
      case TaskType.surgery:
      case TaskType.surgicalCombination:
        baseMinutes = 240;
        break;

      // Major Actions (12-24 Hours)
      case TaskType.mining:
      case TaskType.manufacturing:
      case TaskType.blacksmithing:
      case TaskType.restoreRoom:
        baseMinutes = 240; // 4 Hours
        break;

      case TaskType.rest:
        baseMinutes = 480; // 8 Hours for full sleep
        break;

      default:
        baseMinutes = 120;
        break;

      // The original code had a duplicate default here. Removed it.
    }

    final efficiency = getTaskEfficiency(npc, type);
    int finalMinutes = (baseMinutes / efficiency).round();

    // Clamp room restoration so it doesn't punish poorly suited characters too extremely
    if (type == TaskType.restoreRoom && finalMinutes > 360) {
      finalMinutes = 360; // Max 6 hours
    }

    if (type == TaskType.excavate && targetId != null) {
      final node = ManorLayout.grid[targetId];
      if (node != null && node.$2 < -1) {
        final extraDepthLevels = (-node.$2 - 1).toInt();
        finalMinutes +=
            extraDepthLevels * 1200; // 20 hours extra per depth level
      }
    }

    return finalMinutes;
  }

  bool assignNpcToTask(
    String npcId,
    TaskType type,
    String? targetId, {
    String? recipeId,
    String? targetName,
    String? intentId,
    IntentPriority priority = IntentPriority.normal,
    bool silent = false,
  }) {
    final npcIndex = _npcs.indexWhere((n) => n.id == npcId);
    if (npcIndex == -1) {
      debugPrint("NPC_ASSIGN_FAIL: $npcId not found");
      return false;
    }

    final npc = _npcs[npcIndex];
    debugPrint(
      "NPC_ASSIGN_ATTEMPT: ${npc.name} -> ${type.name} @ ${targetId ?? 'N/A'} (Intent: $intentId)",
    );
    if (!npc.isResident) {
      _lastAnnouncement =
          "${npc.name} is a visitor and cannot be assigned tasks.";
      if (!silent) notifyListeners();
      return false;
    }

    if (npc.activeTaskId != null) {
      try {
        final currentTask = _taskService.activeTasks.firstWhereOrNull(
          (t) => t.id == npc.activeTaskId,
        );
        if (currentTask != null &&
            intentId != null &&
            currentTask.intentId == intentId) {
          return true; // Already doing this specific intent
        }

        if (currentTask != null &&
            currentTask.type == type &&
            currentTask.targetId == targetId) {
          _lastAnnouncement = "${npc.name} is already performing this task.";
          if (!silent) notifyListeners();
          return true;
        }
      } catch (e) {
        // Task not found
      }
    }

    if (type == TaskType.mining && targetId != null) {
      final room = _rooms.firstWhereOrNull((r) => r.id == targetId);
      if (room == null) return false;

      if (room.type != RoomType.mine && room.type != RoomType.oilWell) {
        _lastAnnouncement = "Mining can only be performed in a constructed Mine or Oil Well.";
        if (!silent) notifyListeners();
        return false;
      }

      if (room.type == RoomType.oilWell) {
        if (manorOilReserve <= 0) {
          _lastAnnouncement = "The manor's oil reserve has run completely dry!";
          if (!silent) notifyListeners();
          return false;
        }
      } else {
        final remaining = room.metadata['resourceAmount'] as num? ?? 0;
        if (remaining <= 0) {
          _lastAnnouncement = "This mine has been fully depleted!";
          if (!silent) notifyListeners();
          return false;
        }

        // Tool requirement for operating the mine
        final depth = ManorLayout.grid[room.id]?.$2.abs().toInt() ?? 2; // 2, 3, 4
        String? requiredTool;
        String? toolDisplayName;
        if (depth == 2) { requiredTool = 'iron_pickaxe'; toolDisplayName = 'Iron Pickaxe'; }
        else if (depth == 3) { requiredTool = 'steel_pickaxe'; toolDisplayName = 'Steel Pickaxe'; }
        else if (depth == 4) { requiredTool = 'pneumatic_drill'; toolDisplayName = 'Pneumatic Drill'; }

        if (requiredTool != null && !hasItemInManor(requiredTool)) {
          _lastAnnouncement = "Requires a $toolDisplayName to mine at this depth.";
          if (!silent) notifyListeners();
          return false;
        }
      }
    }

    // RESOURCE CHECK & DEDUCTION
    final metadata = TaskService.getMetadata(type);
    final Map<String, num> combinedRequirements = Map.from(
      metadata.requirements,
    );

    // Progressive cost and validations for excavations
    if (type == TaskType.excavate && targetId != null) {
      // 1. Accessibility check
      if (!isRoomAccessibleForExcavation(targetId)) {
        _lastAnnouncement = "Cannot excavate this node. It must be adjacent to a restored and cleared room.";
        if (!silent) notifyListeners();
        return false;
      }

      final node = ManorLayout.grid[targetId];
      if (node != null) {
        final depth = node.$2.abs(); // 1, 2, 3, 4

        // 2. Tool check
        String? requiredTool;
        String? toolDisplayName;
        if (depth == 1) { requiredTool = 'simple_shovel'; toolDisplayName = 'Simple Shovel'; }
        else if (depth == 2) { requiredTool = 'iron_pickaxe'; toolDisplayName = 'Iron Pickaxe'; }
        else if (depth == 3) { requiredTool = 'steel_pickaxe'; toolDisplayName = 'Steel Pickaxe'; }
        else if (depth == 4) { requiredTool = 'pneumatic_drill'; toolDisplayName = 'Pneumatic Drill'; }

        if (requiredTool != null && !hasItemInManor(requiredTool)) {
          _lastAnnouncement = "Requires a $toolDisplayName to excavate at this depth.";
          if (!silent) notifyListeners();
          return false;
        }

        // 3. Expertise check
        int requiredLevel = 0;
        String levelTitle = "None";
        if (depth == 2) { requiredLevel = 2; levelTitle = "Adept"; }
        else if (depth == 3) { requiredLevel = 5; levelTitle = "Professional"; }
        else if (depth == 4) { requiredLevel = 8; levelTitle = "Expert"; }

        final currentLevel = npc.metadata['proficiency_level_Mining'] as int? ?? 0;
        if (currentLevel < requiredLevel) {
          _lastAnnouncement = "Requires a worker with $levelTitle Mining expertise (Level $requiredLevel) to excavate at this depth.";
          if (!silent) notifyListeners();
          return false;
        }

        // 4. Cost Override
        combinedRequirements.clear();
        if (depth == 1) {
          combinedRequirements['funds'] = 2000;
          combinedRequirements['wood'] = 500;
          combinedRequirements['bricks'] = 200;
        } else if (depth == 2) {
          combinedRequirements['funds'] = 4000;
          combinedRequirements['wood'] = 1000;
          combinedRequirements['bricks'] = 500;
          combinedRequirements['iron_ore'] = 100;
        } else if (depth == 3) {
          combinedRequirements['funds'] = 8000;
          combinedRequirements['wood'] = 2000;
          combinedRequirements['bricks'] = 1000;
          combinedRequirements['iron_ore'] = 300;
        } else if (depth == 4) {
          combinedRequirements['funds'] = 16000;
          combinedRequirements['wood'] = 4000;
          combinedRequirements['bricks'] = 2000;
          combinedRequirements['iron_ore'] = 500;
        }
      }
    }

    if (combinedRequirements.isNotEmpty) {
      for (var req in combinedRequirements.entries) {
        final has = resources[req.key] ?? 0;
        if (has < req.value) {
          _lastAnnouncement =
              "Insufficient ${req.key.toUpperCase()} for ${type.displayName}. Need ${req.value}, have $has.";
          if (!silent) notifyListeners();
          return false;
        }
      }

      for (var req in combinedRequirements.entries) {
        updateResource(req.key, -(req.value));
        debugPrint(
          "NPC_RESOURCE_CONSUME: ${npc.name} used ${req.value} ${req.key}. Remaining: ${resources[req.key]}",
        );
      }
    }

    // OCCUPANCY CHECK
    if (targetId != null) {
      final room = _rooms.firstWhereOrNull((r) => r.id == targetId);
      if (room == null) {
        debugPrint(
          "ERROR: assignNpcToTask called with non-existent room ID: $targetId",
        );
        return false;
      }

      // Occupancy is claimed on arrival in _processNpcMovement
      // so multiple NPCs can plan travel routes toward stations safely flawlessly.
    }

    TaskType assignedType = type;
    String? assignedRecipeId = recipeId;
    String? assignedTargetId = targetId;
    String? assignedTargetName = targetName;
    int duration = 0;

    if (assignedType == TaskType.rest) {
      if (assignedTargetId != null) {
        final room = _rooms.firstWhereOrNull((r) => r.id == assignedTargetId);
        if (room == null ||
            !room.beds.any(
              (b) =>
                  b.assignedNpcIds.contains(npcId) ||
                  b.assignedNpcIds.contains(null),
            )) {
          final fallbackRoom = _rooms.firstWhereOrNull(
            (r) =>
                r.type == RoomType.bedroom &&
                r.isRestored &&
                r.beds.any(
                  (b) =>
                      b.assignedNpcIds.contains(npcId) ||
                      b.assignedNpcIds.contains(null),
                ),
          );
          if (fallbackRoom != null) {
            assignedTargetId = fallbackRoom.id;
          }
        }
      } else {
        final fallbackRoom = _rooms.firstWhereOrNull(
          (r) =>
              r.type == RoomType.bedroom &&
              r.isRestored &&
              r.beds.any(
                (b) =>
                    b.assignedNpcIds.contains(npcId) ||
                    b.assignedNpcIds.contains(null),
              ),
        );
        if (fallbackRoom != null) {
          assignedTargetId = fallbackRoom.id;
        }
      }
    }

    bool shouldPopResearch = false;
    int popResearchIndex = 0;
    bool shouldPopCooking = false;
    int popCookingIndex = 0;

    if (intentId != null) {
      final intent = npc.intentQueue.firstWhereOrNull((i) => i.id == intentId);
      if (intent != null && intent.minutesRemaining != null) {
        duration = intent.minutesRemaining!;
      }
    }

    if (targetId == 'study') {
      if (type == TaskType.research) {
        if (_researchQueue.isNotEmpty) {
          int targetIndex = 0;
          for (int i = 0; i < _researchQueue.length; i++) {
            final qId = _researchQueue[i];
            final rId = qId.startsWith('activity:')
                ? qId.replaceFirst('activity:', '')
                : qId;
            bool active = _taskService.activeTasks.any(
              (t) =>
                  (t.type == TaskType.research ||
                      t.type == TaskType.study ||
                      t.type == TaskType.experiment) &&
                  t.recipeId == rId,
            );
            bool enqueued = _npcs.any(
              (n) => n.intentQueue.any(
                (intent) =>
                    (intent.action == TaskType.research ||
                        intent.action == TaskType.study ||
                        intent.action == TaskType.experiment) &&
                    intent.recipeId == rId,
              ),
            );
            if (!active && !enqueued) {
              targetIndex = i;
              break;
            }
          }
          popResearchIndex = targetIndex;
          final qId = _researchQueue[targetIndex];
          shouldPopResearch = true;
          assignedRecipeId = qId;

          if (qId.startsWith('activity:')) {
            final rawActivityId = qId.replaceFirst('activity:', '');
            final cleanActivityId = rawActivityId.split(':').first;
            final activity = ScienceService.getActivityById(cleanActivityId);
            if (activity != null) {
              assignedType = activity.type;
              assignedRecipeId = rawActivityId;
              duration = activity.baseDurationMinutes;
              _consumeScienceIngredients(activity.ingredients);
            }
          } else if (qId.startsWith('recipe:')) {
            final recipe = KitchenService.getAvailableRecipes().firstWhere(
              (r) => r.id == qId.replaceFirst('recipe:', ''),
            );
            assignedType = TaskType.refineFood;
            assignedRecipeId = recipe.id;
            duration = recipe.durationMinutes;
            for (var entry in recipe.ingredients.entries) {
              updateResource(entry.key, -(entry.value));
            }
          } else {
            assignedType = TaskType.research;
            assignedRecipeId = qId;
            duration = 60;
          }
        } else {
          final room = _rooms.firstWhere((r) => r.id == targetId);
          if (room.isRestored && room.dirtiness > 0.1) {
            assignedType = TaskType.cleanRoom;
          } else {
            _lastAnnouncement =
                "${npc.name} found nothing to research and the ${room.name} is in disrepair.";
            if (!silent) notifyListeners();
            return false;
          }
        }
      }
    } else if (targetId == 'library' &&
        (type == TaskType.archiveResearch ||
            type == TaskType.transcribeNotes)) {
      if (_researchQueue.isNotEmpty) {
        final qId = _researchQueue.first;
        shouldPopResearch = true;
        assignedRecipeId = qId;

        if (qId == 'library_archive') {
          assignedType = TaskType.archiveResearch;
          duration = 45;
        } else if (qId == 'library_transcribe') {
          assignedType = TaskType.transcribeNotes;
          duration = 60;
        } else {
          assignedType = TaskType.archiveResearch;
          duration = 30;
        }
      } else {
        final room = _rooms.firstWhere((r) => r.id == targetId);
        if (room.isRestored && room.dirtiness > 0.1) {
          assignedType = TaskType.cleanRoom;
        } else {
          _lastAnnouncement =
              "${npc.name} found nothing to archive and the ${room.name} is in disrepair.";
          if (!silent) notifyListeners();
          return false;
        }
      }
    } else if (targetId == 'kitchen') {
      if (type == TaskType.cook) {
        if (_cookingQueue.isNotEmpty) {
          int targetIndex = 0;
          for (int i = 0; i < _cookingQueue.length; i++) {
            final qId = _cookingQueue[i];
            bool active = _taskService.activeTasks.any(
              (t) => t.type == TaskType.cook && t.recipeId == qId,
            );
            bool enqueued = _npcs.any(
              (n) => n.intentQueue.any(
                (intent) =>
                    intent.action == TaskType.cook && intent.recipeId == qId,
              ),
            );
            if (!active && !enqueued) {
              targetIndex = i;
              break;
            }
          }
          popCookingIndex = targetIndex;
          final orderStr = _cookingQueue[targetIndex];
          shouldPopCooking = true;

          if (orderStr.startsWith('butcher_generic:')) {
            final parts = orderStr.split(':');
            assignedType = TaskType.butcherAnimals;
            assignedRecipeId = parts[0];
            assignedTargetId = parts[1];
            assignedTargetName = parts[2];
            duration = 45;
          } else {
            assignedType = TaskType.cook;
            assignedRecipeId = orderStr;
            final recipe = KitchenService.getAvailableRecipes().firstWhere(
              (r) => r.id == orderStr,
              orElse: () => Recipe(
                id: orderStr,
                name: orderStr.startsWith('experiment') ? 'Experiment' : 'Meal',
                ingredients: {},
                yield: 1,
                baseQuality: 1.0,
                durationMinutes: orderStr.startsWith('experiment') ? 120 : 60,
              ),
            );
            duration = recipe.durationMinutes;
          }
        } else {
          final kitchen = _rooms.firstWhere((r) => r.id == 'kitchen');
          if (kitchen.isRestored && kitchen.dirtiness > 0.1) {
            assignedType = TaskType.cleanRoom;
          } else {
            // Kitchen is usually restored at start, but for safety:
            return false;
          }
        }
      }
    }

    if (duration == 0) {
      if (assignedType == TaskType.cleanRoom && assignedTargetId != null) {
        final room = _rooms.firstWhere((r) => r.id == assignedTargetId);
        if (room.isRestored) {
          final speed = npc.stats['walkSpeed'] ?? 25;
          duration = (20 * (25 / speed)).round().clamp(10, 45);
        } else if (assignedType == TaskType.rest) {
          duration = getEstimatedTaskMinutes(
            npc,
            assignedType,
            assignedTargetId,
          );
        }
      } else {
        duration = getEstimatedTaskMinutes(npc, assignedType, assignedTargetId);
      }
    }

    if ((assignedType == TaskType.plantCrops ||
            assignedType == TaskType.harvestCrops) &&
        assignedTargetId != null) {
      final room = _rooms.firstWhere((r) => r.id == assignedTargetId);
      if (room.tilledAmount < 1.0) {
        duration = (duration * 0.5).round();
      }
    }

    String taskId =
        "task_${npc.id}_${DateTime.now().microsecondsSinceEpoch}_${assignedType.name}";
    if (assignedType == TaskType.paint ||
        assignedType == TaskType.sculpt ||
        assignedType == TaskType.writePoetry ||
        assignedType == TaskType.writeNovel) {
      taskId = "artwork_${npc.id}_${assignedType.name}";
    }
    int totalMinutes = duration;
    if (intentId != null) {
      final intent = npc.intentQueue.firstWhereOrNull((i) => i.id == intentId);
      if (intent != null) {
        totalMinutes = intent.expectedDurationMin;
      }
    }
    final task = GameTask(
      id: taskId,
      intentId: intentId,
      npcId: npc.id,
      priority: priority,
      type: assignedType,
      targetId: assignedTargetId,
      targetName: assignedTargetName,
      recipeId: assignedRecipeId,
      minutesRemaining: duration,
      totalMinutes: totalMinutes,
    );

    if (shouldPopResearch && _researchQueue.isNotEmpty) {
      _researchQueue.removeAt(popResearchIndex);
    }
    if (shouldPopCooking && _cookingQueue.isNotEmpty) {
      _cookingQueue.removeAt(popCookingIndex);
    }

    assignTask(task);

    final updatedNpc = _npcs[npcIndex];
    List<String> path = [];
    String? firstTarget = task.targetId;

    if (task.targetId != null && task.targetId != updatedNpc.currentRoomId) {
      path = _findPath(updatedNpc.currentRoomId ?? 'entryway', task.targetId!);
      if (path.isNotEmpty) {
        firstTarget = path.removeAt(0);
      }
    }

    double finalProgress = (firstTarget == updatedNpc.currentRoomId)
        ? 1.0
        : 0.0;
    if (firstTarget == updatedNpc.targetRoomId &&
        updatedNpc.movementProgress < 1.0) {
      finalProgress = updatedNpc.movementProgress;
    }

    _npcs[npcIndex] = updatedNpc.copyWith(
      activeTaskId: task.id,
      targetRoomId: firstTarget,
      movementPath: path,
      movementProgress: finalProgress,
      status: _determineStatus(updatedNpc, task),
    );
    return true;
  }

  void assignTaskByRole(
    String role,
    TaskType type,
    String? targetId, {
    String? intentId,
    IntentPriority priority = IntentPriority.normal,
  }) {
    try {
      final npcId = _npcs.firstWhere((n) => n.role == role).id;
      assignNpcToTask(
        npcId,
        type,
        targetId,
        intentId: intentId,
        priority: priority,
      );
    } catch (e) {
      _lastAnnouncement = "No one with the role of $role is available.";
      notifyListeners();
    }
  }

  void assignButlerTask(
    TaskType type,
    String? targetId, {
    String? intentId,
    IntentPriority priority = IntentPriority.normal,
  }) {
    assignTaskByRole(
      'Butler',
      type,
      targetId,
      intentId: intentId,
      priority: priority,
    );
  }

  CombatMap _selectedCombatMap = CombatMap.allMaps.first;
  CombatMap get selectedCombatMap => _selectedCombatMap;

  void setSelectedCombatMap(CombatMap map) {
    _selectedCombatMap = map;
    notifyListeners();
  }

  List<NPC>? _simulationPlayerDeck;
  List<NPC>? _simulationAiDeck;

  void startCombatSimulation(List<NPC> playerDeck, List<NPC> aiDeck) {
    _simulationPlayerDeck = playerDeck;
    _simulationAiDeck = aiDeck;
    notifyListeners();
  }

  List<NPC>? get simulationPlayerDeck => _simulationPlayerDeck;
  List<NPC>? get simulationAiDeck => _simulationAiDeck;

  void clearSimulation() {
    _simulationPlayerDeck = null;
    _simulationAiDeck = null;
    notifyListeners();
  }

  void startJourney(
    String npcId,
    String destinationId,
    Map<String, num> resources,
    List<String> escortIds,
  ) {
    final index = _npcs.indexWhere((n) => n.id == npcId);
    if (index == -1) return;

    var npc = _npcs[index];

    // Deduct from manor, add to NPC
    for (var entry in resources.entries) {
      if ((resources[entry.key] ?? 0) >= entry.value) {
        updateResource(entry.key, -(entry.value));
      }
    }

    _npcs[index] = npc.copyWith(
      worldDestinationId: destinationId,
      worldDepartureId: 'manor',
      worldTravelProgress: 0.0,
      journeyInventory: Map<String, num>.from(resources),
      escortIds: escortIds,
      lastEscortIds: escortIds, // Persist for next time
      status: NPCStatus.idle,
      activeTaskId: null,
      targetRoomId: 'road',
      isResident: false,
    );

    // Sync escort travel status
    for (final fieldId in escortIds) {
      final eIndex = _npcs.indexWhere((n) => n.id == fieldId);
      if (eIndex != -1) {
        _npcs[eIndex] = _npcs[eIndex].copyWith(
          worldDestinationId: destinationId,
          worldDepartureId: 'manor',
          worldTravelProgress: 0.0,
          status: NPCStatus.idle,
          activeTaskId: null,
          targetRoomId: 'road',
          isResident: false,
        );
      }
    }

    _lastAnnouncement = "${npc.name} has departed for $destinationId.";
    notifyListeners();
  }

  void returnToManor(String leaderId) {
    final leaderIndex = _npcs.indexWhere((n) => n.id == leaderId);
    if (leaderIndex == -1) return;

    final leader = _npcs[leaderIndex];
    final departureId = leader.worldDestinationId;

    // All NPCs at the same destination who are controlled by the player
    // (isResident implies they are part of the manor/player group)
    // Actually, any NPC whose worldDestinationId matches the leader's and progress is 1.0
    for (int i = 0; i < _npcs.length; i++) {
      if (_npcs[i].worldDestinationId == departureId &&
          _npcs[i].worldTravelProgress >= 1.0) {
        _npcs[i] = _npcs[i].copyWith(
          worldDepartureId: departureId,
          worldDestinationId: 'manor',
          worldTravelProgress: 0.0,
        );
      }
    }

    setSpeed(GameSpeed.normal);
    _lastAnnouncement = "The expedition is returning home from $departureId.";
    notifyListeners();
  }

  void _completeJourneyAtManor(int index) {
    var npc = _npcs[index];

    // Merge items back
    for (var entry in npc.journeyInventory.entries) {
      updateResource(entry.key, entry.value);
    }

    final hour = _currentDate.hour;
    final preferredRoom = npc.schedule.getPreferredRoomForHour(hour);

    _npcs[index] = npc.copyWith(
      clearWorldDestination: true,
      worldTravelProgress: 0.0,
      journeyInventory: {},
      escortIds: [],
      currentRoomId: 'road',
      targetRoomId: preferredRoom,
      movementProgress: 0.0,
      isResident: true,
    );

    if (npc.isPlayer) {
      _pendingNavigationTarget = 'manor';
    }

    _lastAnnouncement = "${npc.name} has returned and unloaded their goods.";
    notifyListeners();
  }

  void setSpeed(GameSpeed newSpeed) {
    _speed = newSpeed;
    if (_gilesTutorialStep == GilesTutorialStep.playClock && newSpeed != GameSpeed.paused) {
      advanceGilesTutorial(GilesTutorialStep.selectCoop);
    }
    notifyListeners();
  }

  void setSpeedSilent(GameSpeed newSpeed) {
    _speed = newSpeed;
  }

  void cookRecipe(String recipeId, String npcId, {bool isPrepared = false}) {
    final recipe = KitchenService.getAvailableRecipes().firstWhere(
      (r) => r.id == recipeId,
    );
    final npcIndex = _npcs.indexWhere((n) => n.id == npcId);
    if (npcIndex == -1) return;
    final npc = _npcs[npcIndex];

    if (!isPrepared) {
      // Check ingredients
      for (var entry in recipe.ingredients.entries) {
        if ((resources[entry.key] ?? 0) < entry.value) {
          _lastAnnouncement = "NOT ENOUGH ${entry.key.toUpperCase()}!";
          notifyListeners();
          return;
        }
      }

      // Consume ingredients
      for (var entry in recipe.ingredients.entries) {
        updateResource(entry.key, -(entry.value));
      }
    }

    // Create Dishes or handle special results
    if (recipe.id == 'butcher_cattle') {
      updateResource('meat_beef', recipe.yield);
    } else {
      for (int i = 0; i < recipe.yield; i++) {
        _pantry.add(
          Dish(
            id: const Uuid().v4(),
            name: recipe.name,
            type: _getDishTypeForRecipe(recipe.id),
            quality: _calculateCookQuality(npc),
            cookedAt: _currentDate.copy(),
            shelfLifeHours: recipe.id == 'staple_bread' ? 336 : 168,
          ),
        );
      }
    }

    _lastAnnouncement = "${npc.name} PREPARED ${recipe.name.toUpperCase()}!";
    notifyListeners();
  }

  void assignHousing(String npcId, String? roomId) {
    final index = _npcs.indexWhere((n) => n.id == npcId);
    if (index == -1) return;
    _npcs[index] = _npcs[index].copyWith(assignedRoomId: roomId);
    notifyListeners();
  }

  DishType _getDishTypeForRecipe(String id) {
    if (id.contains('bread') || id.contains('pasta')) return DishType.cereal;
    if (id.contains('chicken') || id.contains('beef')) return DishType.protein;
    if (id.contains('bean')) return DishType.vegetable;
    if (id.contains('chocolate') || id.contains('coffee')) {
      return DishType.treat;
    }
    return DishType.cereal;
  }

  DishQuality _calculateCookQuality(NPC npc) {
    final skill = npc.stats['intellect'] ?? 5;
    if (skill > 90) return DishQuality.exquisite;
    if (skill > 80) return DishQuality.delectable;
    if (skill > 70) return DishQuality.sophisticated;
    if (skill > 60) return DishQuality.fine;
    if (skill > 50) return DishQuality.decent;
    if (skill > 40) return DishQuality.alright;
    if (skill > 30) return DishQuality.notBad;
    if (skill > 20) return DishQuality.notGreat;
    return DishQuality.mediocre;
  }

  String getTaskDescription(GameTask task) {
    if (task.type == TaskType.restoreRoom) {
      final room = _rooms.firstWhereOrNull((r) => r.id == task.targetId);
      return "Restore ${room?.name ?? 'Room'}";
    }
    if (task.type == TaskType.cleanRoom) {
      final project = _activeConstruction.firstWhereOrNull(
        (p) =>
            task.targetId != null && task.targetId!.startsWith(p.blueprint.id),
      );
      if (project != null) {
        return "Constructing ${project.blueprint.name}";
      }
    }
    String desc = _taskService.getTaskDescription(task);
    if (task.targetId != null) {
      final room = _rooms.firstWhereOrNull((r) => r.id == task.targetId);
      if (room != null) {
        // Append room name for clarity
        desc = "$desc at ${room.name}";
      }
    }
    return desc;
  }

  void spawnRefugee() {
    final refugee = NPCGenerator.generateRefugee(currentDate: _currentDate);
    _npcs.add(refugee);
    _lastAnnouncement =
        "A new refugee, ${refugee.name}, has arrived at the manor gates.";
    notifyListeners();
  }

  void receiveEntrywayGuest(String guestId, [String? greeterId]) {
    final guest = _npcs.firstWhereOrNull((n) => n.id == guestId);
    if (guest == null) return;

    NPC? greeter;
    if (greeterId != null) {
      greeter = _npcs.firstWhereOrNull((n) => n.id == greeterId);
    } else {
      // Find player character (head of household) first
      greeter = _npcs.firstWhereOrNull(
        (n) => n.isPlayer && n.isResident && n.worldDestinationId == null,
      );
      // Fallback to Butler/Giles
      greeter ??= _npcs.firstWhereOrNull(
        (n) =>
            n.role == 'Butler' && n.isResident && n.worldDestinationId == null,
      );
      // Fallback to any resident
      greeter ??= _npcs.firstWhereOrNull(
        (n) => n.isResident && n.worldDestinationId == null,
      );
    }

    if (greeter == null) {
      _lastAnnouncement = "NO ONE IS AVAILABLE TO GREET THE GUEST!";
      notifyListeners();
      return;
    }

    // Assign high-priority greetGuest task
    final intentId = const Uuid().v4();
    final intent = NPCIntent(
      id: intentId,
      action: TaskType.greetGuest,
      targetRoomId: 'entryway',
      targetName: guest.name,
      recipeId: guest.id, // Store guestId in recipeId
      priority: IntentPriority
          .vital, // vital priority: interrupts everything but emergencies
      expectedDurationMin: 15,
      isManual: true,
    );

    // Preempt current task if not emergency/panic
    final idx = _npcs.indexOf(greeter);
    final currentTask = greeter.activeTaskId != null
        ? _taskService.activeTasks.firstWhereOrNull(
            (t) => t.id == greeter!.activeTaskId,
          )
        : null;

    bool canPreempt = true;
    if (currentTask != null) {
      if (currentTask.priority == IntentPriority.emergency ||
          currentTask.priority == IntentPriority.panic) {
        canPreempt = false;
      }
    }

    if (!canPreempt) {
      _lastAnnouncement =
          "${greeter.name} is responding to an emergency and cannot be interrupted!";
      notifyListeners();
      return;
    }

    if (currentTask != null) {
      _taskService.removeTask(currentTask.id);
      _clearRoomOccupancyForNpc(greeter.id);
      _npcs[idx] = greeter = greeter.copyWith(
        activeTaskId: null,
        status: NPCStatus.idle,
      );
    }

    // Enqueue Greet Guest task
    List<NPCIntent> newQueue = List.from(greeter.intentQueue);
    newQueue.insert(0, intent);
    _npcs[idx] = greeter.copyWith(intentQueue: newQueue);

    // Add to Room task queue for entryway
    final roomIdx = _rooms.indexWhere((r) => r.id == 'entryway');
    if (roomIdx != -1) {
      final room = _rooms[roomIdx];
      List<EnqueuedTask> newRoomQueue = List.from(room.taskQueue);
      newRoomQueue.add(
        EnqueuedTask(
          npcId: greeter.id,
          intentId: intentId,
          description: "${greeter.name}: GREET ${guest.name.toUpperCase()}",
        ),
      );
      _rooms[roomIdx] = room.copyWith(taskQueue: newRoomQueue);
    }

    _lastAnnouncement =
        "${greeter.name} is on their way to receive ${guest.name}.";
    notifyListeners();
  }

  void buyFromVisitingMerchant(String merchantId, String resource, int amount) {
    final merchant = _npcs.firstWhereOrNull((n) => n.id == merchantId);
    if (merchant == null) return;

    final stockMap =
        merchant.metadata['merchantStock'] as Map<String, dynamic>?;
    if (stockMap == null) return;

    final isSuperMerchant = merchant.id == 'super_merchant' || merchant.role == 'Super Merchant';
    final availableStock = isSuperMerchant ? 999999 : (stockMap[resource] as int? ?? 0);
    if (availableStock < amount) return;

    int price = _marketService.getBuyPrice(resource).toInt();
    if (merchant.role == 'Staple Food Merchant') {
      price = (price * 0.5).round().clamp(1, 999);
    }
    final totalCost = price * amount;

    final manorFunds = resources['funds'] ?? 0;
    if (manorFunds >= totalCost) {
      // Deduct funds and add resource to manor
      updateResource('funds', -totalCost);

      final bool isSalt = resource == 'salt';
      final int multiplier = isSalt ? 10 : 1;
      updateResource(resource, amount * multiplier);

      // Deduct stock from merchant if not super merchant
      if (!isSuperMerchant) {
        final updatedStock = Map<String, int>.from(stockMap);
        updatedStock[resource] = availableStock - amount;

        final index = _npcs.indexOf(merchant);
        _npcs[index] = merchant.copyWith(
          metadata: {...merchant.metadata, 'merchantStock': updatedStock},
        );
      }

      final displayResource = isSalt ? "Salt (x10)" : resource;
      _lastAnnouncement =
          "Purchased $amount $displayResource from ${merchant.name}.";
      notifyListeners();
    }
  }

  void sellToVisitingMerchant(String merchantId, String resource, int amount) {
    final merchant = _npcs.firstWhereOrNull((n) => n.id == merchantId);
    if (merchant == null) return;

    final bool isSalt = resource == 'salt';
    final int multiplier = isSalt ? 10 : 1;

    final stockVal = resources[resource] ?? 0;
    if (stockVal < amount * multiplier) return;

    final price = _marketService.getSellPrice(resource);
    final int gain = (price * amount).toInt();

    // Deduct resource and add funds to manor
    updateResource(resource, -(amount * multiplier));
    updateResource('funds', gain);

    final displayResource = isSalt ? "Salt (x10)" : resource;
    _lastAnnouncement = "Sold $amount $displayResource to ${merchant.name}.";
    notifyListeners();
  }

  void commitMerchantTransaction({
    required String merchantId,
    required Map<String, int> itemsToBuy,
    required Map<String, int> itemsToSell,
    required int netCost,
    String? loanProvider,
    int? loanAmount,
    double? loanInterestRate,
  }) {
    final merchant = _npcs.firstWhereOrNull((n) => n.id == merchantId);
    if (merchant == null) return;

    final isSuperMerchant = merchant.id == 'super_merchant' || merchant.role == 'Super Merchant';
    final rawStock = merchant.metadata['merchantStock'];
    final stockMap = rawStock is Map
        ? Map<String, int>.from(rawStock.map((k, v) => MapEntry(k.toString(), v as int)))
        : <String, int>{};

    // Process Items to Buy
    itemsToBuy.forEach((res, amount) {
      if (amount <= 0) return;
      final availableStock = isSuperMerchant ? 999999 : (stockMap[res] ?? 0);
      final finalAmount = amount.clamp(0, availableStock);
      if (finalAmount <= 0) return;

      // Add resource to manor
      final bool isSalt = res == 'salt';
      final int multiplier = isSalt ? 10 : 1;
      updateResource(res, finalAmount * multiplier);

      // Deduct stock from merchant
      if (!isSuperMerchant) {
        stockMap[res] = availableStock - finalAmount;
      }
    });

    // Process Items to Sell
    itemsToSell.forEach((res, amount) {
      if (amount <= 0) return;
      final stockVal = resources[res] ?? 0;
      final bool isSalt = res == 'salt';
      final int multiplier = isSalt ? 10 : 1;
      final finalAmount = amount.clamp(0, (stockVal / multiplier).floor());
      if (finalAmount <= 0) return;

      // Deduct from vault
      updateResource(res, -(finalAmount * multiplier));
    });

    // Update merchant stock in metadata
    if (!isSuperMerchant) {
      final index = _npcs.indexOf(merchant);
      _npcs[index] = merchant.copyWith(
        metadata: {...merchant.metadata, 'merchantStock': stockMap},
      );
    }

    // Handle finance (Funds or Loan)
    if (loanAmount != null && loanAmount > 0 && loanProvider != null) {
      _activeMerchantLoan = loanAmount;
      _merchantLoanProvider = loanProvider;
      _merchantLoanInterestRate = loanInterestRate ?? 0.05;
      _merchantLoanDaysUnpaid = 0;

      // Deduct any offset player could pay
      final playerOffset = netCost - loanAmount;
      if (playerOffset > 0) {
        updateResource('funds', -playerOffset);
      }
      _lastAnnouncement = "Financed transaction with a $loanAmount CHF loan from $loanProvider.";
    } else {
      // Regular payment (positive netCost = player pays, negative netCost = player earns)
      updateResource('funds', -netCost);
      if (netCost > 0) {
        _lastAnnouncement = "Completed transaction: Paid $netCost CHF to ${merchant.name}.";
      } else {
        _lastAnnouncement = "Completed transaction: Earned ${-netCost} CHF from ${merchant.name}.";
      }
    }

    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] TRADE: Transaction complete with ${merchant.name}. Net change: ${-netCost} CHF.",
    );
    notifyListeners();
  }

  Map<String, dynamic> haggleWithMerchant({
    required String merchantId,
    required double baseIntrinsicsCost,
    required double currentOfferedCost,
  }) {
    final merchant = _npcs.firstWhereOrNull((n) => n.id == merchantId);
    if (merchant == null) return {'outcome': 'error', 'message': 'Merchant not found'};

    final isSuperMerchant = merchant.id == 'super_merchant' || merchant.role == 'Super Merchant';
    if (isSuperMerchant) {
      return {
        'outcome': 'neutral',
        'message': 'Silas does not haggle. "My prices are absolute. No exceptions."',
      };
    }

    int respect = merchant.metadata['merchantRespect'] as int? ?? 50;
    double markupFactor = merchant.metadata['markupFactor'] as double? ?? 1.25;

    // Determine pricing ratio
    double ratio = baseIntrinsicsCost > 0 ? (currentOfferedCost / baseIntrinsicsCost) : markupFactor;

    double successChance = 40.0;
    double offenseChance = 20.0;

    if (ratio >= 1.25) {
      // High price relative to value - haggling works better
      successChance = 70.0 + (respect - 50) * 0.5;
      offenseChance = 5.0;
    } else if (ratio < 1.0) {
      // Below intrinsic or low price - highly likely to offend
      successChance = 15.0 + (respect - 50) * 0.5;
      offenseChance = 50.0;
    } else {
      // Fair pricing
      successChance = 40.0 + (respect - 50) * 0.5;
      offenseChance = 20.0;
    }

    successChance = successChance.clamp(5.0, 95.0);
    offenseChance = offenseChance.clamp(5.0, 95.0);

    final roll = Random().nextInt(100);
    String outcome;
    String message;
    double discount = 0.0;
    String? freeItem;

    if (roll < 15) {
      // Critical Success
      outcome = 'critical_success';
      respect = (respect + 15).clamp(0, 100);
      discount = 0.20;
      markupFactor = (markupFactor - 0.20).clamp(0.80, 2.0);

      // Throw in a free item
      final rawStock = merchant.metadata['merchantStock'];
      final stockMap = rawStock is Map ? Map<String, dynamic>.from(rawStock) : <String, dynamic>{};
      final candidates = stockMap.keys.where((k) => !k.contains('pickaxe') && !k.contains('drill')).toList();
      if (candidates.isNotEmpty) {
        freeItem = candidates[Random().nextInt(candidates.length)];
        final bool isSalt = freeItem == 'salt';
        final int multiplier = isSalt ? 10 : 1;
        updateResource(freeItem, multiplier);
        message = "CRITICAL SUCCESS! ${merchant.name} is deeply impressed by Glarus Manor's prestige and lowers their markup by 20%, throwing in a free ${_getPrettyResourceName(freeItem)}!";
      } else {
        message = "CRITICAL SUCCESS! ${merchant.name} is deeply impressed by Glarus Manor's prestige and lowers their markup by 20%!";
      }
    } else if (roll < successChance) {
      // Success
      outcome = 'success';
      respect = (respect + 8).clamp(0, 100);
      discount = 0.12;
      markupFactor = (markupFactor - 0.12).clamp(0.85, 2.0);
      message = "SUCCESS! You haggle a good deal. ${merchant.name} drops their markup by 12%.";
    } else if (roll < (100 - offenseChance)) {
      // Failure
      outcome = 'failure';
      respect = (respect - 10).clamp(0, 100);
      message = "FAILURE! ${merchant.name} flatly refuses your offer: \"My prices are already more than fair!\"";
    } else {
      // Critical Failure / Offended
      respect = (respect - 25).clamp(0, 100);
      
      // Decide if business is refused or high interest loan offered
      final isUpsetRefuse = Random().nextBool();
      if (isUpsetRefuse) {
        outcome = 'upset_refused';
        message = "CRITICAL FAILURE! ${merchant.name} is deeply insulted by your lowball offer and refuses to do any further business with Glarus Manor!";
      } else {
        outcome = 'loan_offer';
        message = "CRITICAL FAILURE! ${merchant.name} is offended. \"You lack Glarus Manor's coin? I can lend you the difference, but it will cost you 25% daily interest!\"";
      }
    }

    // Save back to NPC
    final index = _npcs.indexOf(merchant);
    _npcs[index] = merchant.copyWith(
      metadata: {
        ...merchant.metadata,
        'merchantRespect': respect,
        'markupFactor': markupFactor,
        'hasHaggled': true,
        if (outcome == 'upset_refused') 'refusedBusiness': true,
      },
    );

    notifyListeners();
    return {
      'outcome': outcome,
      'message': message,
      'discount': discount,
      'freeItem': freeItem,
      'respect': respect,
      'markupFactor': markupFactor,
    };
  }

  void payMerchantLoan(int amount) {
    if (_activeMerchantLoan <= 0) return;
    final actualPay = amount.clamp(1, _activeMerchantLoan);
    final availableFunds = (resources['funds'] ?? 0).toInt();
    final finalPay = actualPay.clamp(0, availableFunds);
    if (finalPay <= 0) return;

    updateResource('funds', -finalPay);
    _activeMerchantLoan -= finalPay;
    if (_activeMerchantLoan == 0) {
      _merchantLoanProvider = null;
      _merchantLoanDaysUnpaid = 0;
      _lastAnnouncement = "Paid off the outstanding merchant debt completely.";
    } else {
      _lastAnnouncement = "Paid $finalPay CHF toward merchant debt. Remaining: $_activeMerchantLoan CHF.";
    }
    notifyListeners();
  }

  void _processMerchantLoanDailyTick() {
    if (_activeMerchantLoan <= 0) return;

    int interest = (_activeMerchantLoan * _merchantLoanInterestRate).round();
    if (interest < 1) interest = 1;
    _activeMerchantLoan += interest;
    _merchantLoanDaysUnpaid++;

    _lastAnnouncement = "Your unpaid debt to $_merchantLoanProvider has grown to $_activeMerchantLoan CHF (+$interest CHF daily interest).";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] DEBT TICK: Outstanding loan from $_merchantLoanProvider is now $_activeMerchantLoan CHF (+5% daily interest).",
    );

    if (_merchantLoanDaysUnpaid >= 5) {
      // Arson attempt!
      _merchantLoanDaysUnpaid = 0; // reset counter so they get a reprieve
      
      // Burn some wood, timber, grain
      final int burnedWood = (resources['wood'] ?? 0).clamp(0, 15).toInt();
      final int burnedTimber = (resources['timber'] ?? 0).clamp(0, 5).toInt();
      final int burnedGrain = (resources['grain'] ?? 0).clamp(0, 25).toInt();

      updateResource('wood', -burnedWood);
      updateResource('timber', -burnedTimber);
      updateResource('grain', -burnedGrain);

      // Cleanliness impact on stable/entryway
      final stableIndex = _rooms.indexWhere((r) => r.id == 'stables' || r.id == 'barn');
      if (stableIndex != -1) {
        _rooms[stableIndex] = _rooms[stableIndex].copyWith(
          dirtiness: 1.0,
          isRestored: false,
          restorationProgress: 0.0,
        );
      }

      _lastAnnouncement = "CRITICAL HAZARD: Arsonists hired by $_merchantLoanProvider set fire to Glarus Manor's outbuildings! Wood/grain was burned!";
      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] ARSON ATTACK: Merchant $_merchantLoanProvider sent thugs to burn Glarus Manor's stables! $burnedWood Wood, $burnedTimber Timber, $burnedGrain Grain lost.",
      );
    }
    notifyListeners();
  }

  String _getPrettyResourceName(String res) {
    if (res == 'shepherds_pie') return "SHEPHERD'S PIE";
    if (res == 'seeds_cabbage') return 'CABBAGE SEEDS';
    if (res == 'seeds_potato') return 'POTATO SEEDS';
    if (res == 'seeds_carrot') return 'CARROT SEEDS';
    if (res == 'mushroom_spores') return 'MUSHROOM SPORES';
    return res.replaceAll('_', ' ').toUpperCase();
  }

  void _spawnVisitingMerchant() {
    final names = ['Silas', 'Bartholomew', 'Gideon', 'Tabitha', 'Vesper'];
    final name = "Merchant ${names[Random().nextInt(names.length)]}";

    final merchant = NPCGenerator.generateRefugee(currentDate: _currentDate)
        .copyWith(
          id: 'merchant_${const Uuid().v4()}',
          name: name,
          role: 'Traveling Merchant',
          currentRoomId: 'entryway',
          targetRoomId: 'entryway',
          movementProgress: 1.0,
          status: NPCStatus.idle,
          assignedRoomId: null,
          isResident: false,
          metadata: {
            'guestType': 'merchant',
            'arrivalTime': _currentDate.totalMinutes,
            'isGreeted': false,
            'merchantStock': {
              'wood': 15,
              'timber': 5,
              'fertilizer': 5,
              'seeds_cabbage': 8,
              'seeds_potato': 8,
              'meat': 10,
              'cabbage': 12,
              'salt': 15,
              'simple_shovel': 1,
              'iron_pickaxe': 1,
              'steel_pickaxe': 1,
              'pneumatic_drill': 1,
            },
          },
        );

    _npcs.add(merchant);

    _lastAnnouncement =
        "A traveling merchant, $name, has arrived at the entryway.";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] MERCHANT ARRIVAL: $name",
    );
    notifyListeners();
  }

  void _spawnFoodStapleMerchant() {
    final merchant = NPCGenerator.generateRefugee(currentDate: _currentDate)
        .copyWith(
          id: 'merchant_food_${const Uuid().v4()}',
          name: 'Staples Merchant Eldon',
          role: 'Staple Food Merchant',
          currentRoomId: 'entryway',
          targetRoomId: 'entryway',
          movementProgress: 1.0,
          status: NPCStatus.idle,
          assignedRoomId: null,
          isResident: false,
          metadata: {
            'guestType': 'merchant',
            'arrivalTime': _currentDate.totalMinutes,
            'isGreeted': false,
            'merchantStock': {
              'meat': 30,
              'cabbage': 40,
              'potato': 40,
              'carrots': 40,
              'beets': 40,
              'grain': 50,
              'eggs': 30,
              'salt': 50,
              'shepherds_pie': 20,
            },
          },
        );

    _npcs.add(merchant);

    _lastAnnouncement =
        "Staples Merchant Eldon has arrived with cartloads of food ingredients!";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] MERCHANT ARRIVAL: Eldon (Staple Foods)",
    );
    notifyListeners();
  }

  double get manorOilReserve {
    double total = 0;
    for (var room in _rooms) {
      if (room.metadata['resourceType'] == 'oil') {
        total += (room.metadata['resourceAmount'] as num? ?? 0).toDouble();
      }
    }
    return total;
  }

  double get manorOilReserveMax {
    double total = 0;
    for (var room in _rooms) {
      if (room.metadata['resourceType'] == 'oil') {
        total += (room.metadata['resourceAmountMax'] as num? ?? 0).toDouble();
      }
    }
    return total == 0 ? 6000.0 : total;
  }

  double getOilPumpingEfficiency() {
    final maxRes = manorOilReserveMax;
    if (maxRes <= 0) return 0.2;
    final reserveRatio = manorOilReserve / maxRes;
    return (0.2 + (0.8 * reserveRatio)).clamp(0.2, 1.0);
  }

  bool isRoomAccessibleForExcavation(String roomId) {
    final room = _rooms.firstWhereOrNull((r) => r.id == roomId);
    if (room == null) return false;

    // Floor -1 rooms are always accessible initially
    final node = ManorLayout.grid[roomId];
    if (node != null && node.$2 == -1) {
      return true;
    }

    // Other rooms are accessible if they have a neighbor that is restored AND not blocked
    final neighbors = basementNeighbors[roomId] ?? [];
    for (var neighborId in neighbors) {
      final neighbor = _rooms.firstWhereOrNull((r) => r.id == neighborId);
      if (neighbor != null && neighbor.isRestored) {
        final isBlocked = neighbor.metadata['isResourceBlocked'] == true;
        if (!isBlocked) {
          return true;
        }
      }
    }

    return false;
  }

  bool hasItemInManor(String itemType) {
    return _rooms.any((r) => r.inventory.any((item) => item.type == itemType));
  }

  static const Map<String, List<String>> basementNeighbors = {
    'basement_1': ['basement_2', 'basement_f'],
    'basement_2': ['basement_1', 'basement_3', 'basement_g'],
    'basement_3': ['basement_2', 'basement_d', 'basement_h'],
    'basement_d': ['basement_3', 'basement_i'],
    'basement_e': ['basement_f', 'basement_j'],
    'basement_f': ['basement_e', 'basement_g', 'basement_1', 'basement_k'],
    'basement_g': ['basement_f', 'basement_h', 'basement_2', 'basement_l'],
    'basement_h': ['basement_g', 'basement_i', 'basement_3', 'basement_m'],
    'basement_i': ['basement_h', 'basement_d', 'basement_n'],
    'basement_j': ['basement_k', 'basement_e', 'basement_o'],
    'basement_k': ['basement_j', 'basement_l', 'basement_f', 'basement_p'],
    'basement_l': ['basement_k', 'basement_m', 'basement_g', 'basement_q'],
    'basement_m': ['basement_l', 'basement_n', 'basement_h', 'basement_r'],
    'basement_n': ['basement_m', 'basement_i', 'basement_s'],
    'basement_o': ['basement_p', 'basement_j'],
    'basement_p': ['basement_o', 'basement_q', 'basement_k'],
    'basement_q': ['basement_p', 'basement_r', 'basement_l'],
    'basement_r': ['basement_q', 'basement_s', 'basement_m'],
    'basement_s': ['basement_r', 'basement_n'],
  };

  void _initializeBasementResources() {
    final rand = Random();

    final indexE = _rooms.indexWhere((r) => r.id == 'basement_e');
    if (indexE != -1) {
      _rooms[indexE] = _rooms[indexE].copyWith(
        metadata: {
          'resourceType': 'oil_well_site',
          'canAccommodateOilWell': true,
        },
      );
    }

    final indexF = _rooms.indexWhere((r) => r.id == 'basement_f');
    if (indexF != -1) {
      _rooms[indexF] = _rooms[indexF].copyWith(
        description: 'An unexcavated node. Preliminary survey indicates a rich seam of coal.',
        metadata: {
          'resourceType': 'coal',
          'resourceAmount': 1500,
          'resourceAmountMax': 1500,
          'isResourceBlocked': true,
        },
      );
    }

    final indexJ = _rooms.indexWhere((r) => r.id == 'basement_j');
    if (indexJ != -1) {
      _rooms[indexJ] = _rooms[indexJ].copyWith(
        description: 'Subterranean depth rich in crude oil. Pumping equipment must be established at the well node above to utilize this chamber.',
        metadata: {
          'resourceType': 'oil',
          'resourceAmount': 3000,
          'resourceAmountMax': 3000,
          'isResourceBlocked': true,
        },
      );
    }

    final indexK = _rooms.indexWhere((r) => r.id == 'basement_k');
    if (indexK != -1) {
      _rooms[indexK] = _rooms[indexK].copyWith(
        description: 'A deep earthen tunnel rich in high-grade coal.',
        metadata: {
          'resourceType': 'coal',
          'resourceAmount': 3000,
          'resourceAmountMax': 3000,
          'isResourceBlocked': true,
        },
      );
    }

    final indexO = _rooms.indexWhere((r) => r.id == 'basement_o');
    if (indexO != -1) {
      _rooms[indexO] = _rooms[indexO].copyWith(
        description: 'An ancient rocky cavity rich in crude oil. Pumping equipment must be established at the well node above to utilize this chamber.',
        metadata: {
          'resourceType': 'oil',
          'resourceAmount': 3000,
          'resourceAmountMax': 3000,
          'isResourceBlocked': true,
        },
      );
    }

    // Variable resources
    final list1 = ['iron', 'gold', 'silver', 'copper'];
    
    final indexM = _rooms.indexWhere((r) => r.id == 'basement_m');
    if (indexM != -1) {
      final chosen = list1[rand.nextInt(list1.length)];
      _rooms[indexM] = _rooms[indexM].copyWith(
        description: 'A forgotten chamber containing a rich ore vein.',
        metadata: {
          'resourceType': chosen,
          'resourceAmount': 2500,
          'resourceAmountMax': 2500,
          'isResourceBlocked': true,
        },
      );
    }

    final indexN = _rooms.indexWhere((r) => r.id == 'basement_n');
    if (indexN != -1) {
      final chosen = list1[rand.nextInt(list1.length)];
      _rooms[indexN] = _rooms[indexN].copyWith(
        description: 'A forgotten chamber containing a rich ore vein.',
        metadata: {
          'resourceType': chosen,
          'resourceAmount': 2500,
          'resourceAmountMax': 2500,
          'isResourceBlocked': true,
        },
      );
    }

    final list2 = ['lithium', 'cobalt', 'nickel'];
    final indexQ = _rooms.indexWhere((r) => r.id == 'basement_q');
    if (indexQ != -1) {
      final chosen = list2[rand.nextInt(list2.length)];
      _rooms[indexQ] = _rooms[indexQ].copyWith(
        description: 'Deep subterranean deposits of valuable industrial minerals.',
        metadata: {
          'resourceType': chosen,
          'resourceAmount': 2000,
          'resourceAmountMax': 2000,
          'isResourceBlocked': true,
        },
      );
    }

    final list3 = ['titanium', 'diamonds', 'jadeite'];
    final indexS = _rooms.indexWhere((r) => r.id == 'basement_s');
    if (indexS != -1) {
      final chosen = list3[rand.nextInt(list3.length)];
      _rooms[indexS] = _rooms[indexS].copyWith(
        description: 'Extreme depths holding rare crystalline and heavy metal formations.',
        metadata: {
          'resourceType': chosen,
          'resourceAmount': 1500,
          'resourceAmountMax': 1500,
          'isResourceBlocked': true,
        },
      );
    }

    // Uranium with 50% chance
    final indexP = _rooms.indexWhere((r) => r.id == 'basement_p');
    if (indexP != -1) {
      final hasUranium = rand.nextBool();
      if (hasUranium) {
        _rooms[indexP] = _rooms[indexP].copyWith(
          description: 'A deep cavern containing traces of pitchblende and radioactive isotopes.',
          metadata: {
            'resourceType': 'uranium',
            'resourceAmount': 1000,
            'resourceAmountMax': 1000,
            'isResourceBlocked': true,
          },
        );
      } else {
        _rooms[indexP] = _rooms[indexP].copyWith(
          description: 'An empty rocky chamber, free of resource veins.',
          metadata: {},
        );
      }
    }

    final indexR = _rooms.indexWhere((r) => r.id == 'basement_r');
    if (indexR != -1) {
      final hasUranium = rand.nextBool();
      if (hasUranium) {
        _rooms[indexR] = _rooms[indexR].copyWith(
          description: 'A deep cavern containing traces of pitchblende and radioactive isotopes.',
          metadata: {
            'resourceType': 'uranium',
            'resourceAmount': 1000,
            'resourceAmountMax': 1000,
            'isResourceBlocked': true,
          },
        );
      } else {
        _rooms[indexR] = _rooms[indexR].copyWith(
          description: 'An empty rocky chamber, free of resource veins.',
          metadata: {},
        );
      }
    }
  }

  void resetState() {
    _npcs.clear();
    _rooms.clear();
    _taskStagnationCounters.clear();
    _activeConstruction.clear();
    _activeExperiments.clear();
    _announcementHistory.clear();
    _objectives.clear();
    _unlockedDiscoveries.clear();
    _performedExperiments.clear();
    _pantry.clear();
    _cookingQueue.clear();
    _chickens.clear();
    _crops.clear();
    _lastAnnouncement = null;

    _hasFoodDropTriggered = false;
    _foodDropTriggerTime = null;
    _lastMerchantSpawnMinutes = 0;
    _pendingGuestConversation = false;
    _conversationGreeter = null;
    _conversationGuest = null;
    _pendingNpcRemovals.clear();

    _initializeManor();
    _initializeStartingCharacters();
    _initializeObjectives();
    notifyListeners();
  }

  // Placeholder for new research consumption logic if needed.
  // For now, physical items in room inventory are the source of truth.

  void craftItem(String name, Map<String, num> requirements, String product) {
    bool canCraft = true;
    requirements.forEach((res, amount) {
      if ((resources[res] ?? 0) < amount) canCraft = false;
    });

    if (canCraft) {
      requirements.forEach((res, amount) {
        updateResource(res, -(amount));
      });

      final targetRoom =
          _rooms.firstWhereOrNull(
            (r) => r.type == RoomType.laboratory && r.isRestored,
          ) ??
          _rooms.firstWhereOrNull(
            (r) => r.type == RoomType.workshop && r.isRestored,
          ) ??
          _rooms.first;

      final index = _rooms.indexOf(targetRoom);
      if (index != -1) {
        final List<GameItem> newInv = List.from(_rooms[index].inventory);
        newInv.add(
          GameItem.create(
            name: product,
            type: product.toLowerCase().replaceAll(' ', '_'),
            category: ItemCategory.utility,
          ),
        );
        _rooms[index] = _rooms[index].copyWith(inventory: newInv);
      }
      _lastAnnouncement = "Successfully transmuted $product.";
      notifyListeners();
    }
  }

  void sellResource(String resource, int amount) {
    // Check for someone at Hamlet
    final traveler = _npcs.firstWhere(
      (n) => n.worldDestinationId == 'hamlet' && n.worldTravelProgress >= 1.0,
      orElse: () => throw Exception("No one is at the Hamlet to trade!"),
    );

    final travelerStock = traveler.journeyInventory[resource] ?? 0;
    if (travelerStock.round() >= amount.round()) {
      final price = _marketService.getSellPrice(resource);
      final int gain = (price * amount).toInt();

      final newInv = Map<String, num>.from(traveler.journeyInventory);
      newInv[resource] = travelerStock - amount;
      newInv['funds'] = ((newInv['funds'] ?? 0) + gain).round();

      final index = _npcs.indexOf(traveler);
      _npcs[index] = traveler.copyWith(journeyInventory: newInv);

      _lastAnnouncement = "Sold $amount $resource via ${traveler.name}.";
      notifyListeners();
    }
  }

  void refreshHamletNpcs() {
    const cost = 5;

    // Check manor funds first
    if ((resources['funds'] ?? 0) >= cost) {
      updateResource('funds', -(cost));
      _refreshHamletNpcsLogic();
      return;
    }

    // If manor funds low, check if a traveler AT the hamlet has funds
    try {
      final traveler = _npcs.firstWhere(
        (n) => n.worldDestinationId == 'hamlet' && n.worldTravelProgress >= 1.0,
      );
      final travelerFunds = traveler.journeyInventory['funds'] ?? 0;
      if (travelerFunds >= cost) {
        final newInv = Map<String, num>.from(traveler.journeyInventory);
        newInv['funds'] = travelerFunds - cost;
        final index = _npcs.indexOf(traveler);
        _npcs[index] = traveler.copyWith(journeyInventory: newInv);
        _refreshHamletNpcsLogic();
      } else {
        _lastAnnouncement = "Not enough funds to attract new travelers.";
        notifyListeners();
      }
    } catch (e) {
      _lastAnnouncement = "Not enough funds in the manor to attract travelers.";
      notifyListeners();
    }
  }

  void _refreshHamletNpcsLogic() {
    _availableHamletNpcs.clear();
    final proposerPool = [
      {
        'name': 'Chef Pierre',
        'role': 'Cordon Bleu Cook',
        'type': 'cook_proposer',
      },
      {
        'name': 'Dr. Faustus',
        'role': 'Rogue Alchemist',
        'type': 'chemist_proposer',
      },
      {
        'name': 'Advocate Cagliostro',
        'role': 'Gothic Attorney',
        'type': 'lawyer_proposer',
      },
      {
        'name': 'Dr. Frankenstein',
        'role': 'Private Physician',
        'type': 'doctor_proposer',
      },
      {
        'name': 'Lord Garrick',
        'role': 'Thespian Virtuoso',
        'type': 'actor_proposer',
      },
    ];

    for (int i = 0; i < 3; i++) {
      var refugee = NPCGenerator.generateRefugee(currentDate: _currentDate);
      if (i == 0 && Random().nextDouble() < 0.5) {
        final prop = proposerPool[Random().nextInt(proposerPool.length)];
        refugee = refugee.copyWith(
          name: prop['name']!,
          role: prop['role']!,
          metadata: {...refugee.metadata, 'guestType': prop['type']!},
        );
      }
      _availableHamletNpcs.add(refugee);
    }
    _lastAnnouncement = "A new group of travelers has arrived at the Tavern.";
    notifyListeners();
  }

  void welcomeNpc(String npcId) {
    final index = _npcs.indexWhere((n) => n.id == npcId);
    if (index != -1) {
      _npcs[index] = _npcs[index].copyWith(
        isResident: true,
        disposition: NPCDisposition.voluntary,
        schedule: NPCSchedule.defaultWorker(), // Give them a worker schedule
      );
      _lastAnnouncement = "${_npcs[index].name} has joined the manor staff.";
      _checkObjectives();
      notifyListeners();
    }
  }

  void dismissNpc(String npcId) {
    final index = _npcs.indexWhere((n) => n.id == npcId);
    if (index != -1) {
      _lastAnnouncement = "${_npcs[index].name} has departed the manor.";
      _npcs.removeAt(index);
      notifyListeners();
    }
  }

  void tryScheduleNpcTask(
    String npcId,
    TaskType type,
    String targetId, {
    String? recipeId,
    String? targetName,
  }) {
    enqueueNpcTask(
      npcId,
      type,
      targetId,
      recipeId: recipeId,
      targetName: targetName,
    );
  }

  void createPlayerIntent({
    required TaskType action,
    required String targetRoomId,
    int expectedDurationMin = 30,
  }) {
    final npc =
        _npcs.firstWhereOrNull(
          (n) => n.role == 'Worker' || n.role == 'Butler',
        ) ??
        _npcs.firstWhereOrNull((n) => n.isResident) ??
        _npcs.first;
    enqueueNpcTask(npc.id, action, targetRoomId);
  }

  void enqueueNpcTask(
    String npcId,
    TaskType type,
    String targetId, {
    String? recipeId,
    String? targetName,
  }) {
    final npcIndex = _npcs.indexWhere((n) => n.id == npcId);
    if (npcIndex == -1) return;
    var npc = _npcs[npcIndex];

    final roomIndex = _rooms.indexWhere((r) => r.id == targetId);
    if (roomIndex == -1) return;
    final room = _rooms[roomIndex];

    final durationMin = getEstimatedTaskMinutes(npc, type, targetId);
    final intentId = const Uuid().v4();

    final intent = NPCIntent(
      id: intentId,
      action: type,
      targetRoomId: targetId,
      recipeId: recipeId,
      targetName: targetName,
      priority: IntentPriority.normal,
      minutesRemaining: durationMin,
      expectedDurationMin: durationMin,
      isManual: true,
    );

    // 1. Add to NPC queue
    List<NPCIntent> newNpcQueue = List.from(npc.intentQueue);
    newNpcQueue.add(intent);
    _npcs[npcIndex] = npc.copyWith(intentQueue: newNpcQueue);

    // 2. Add to Room task queue for visibility
    List<EnqueuedTask> newRoomQueue = List.from(room.taskQueue);
    final taskDesc = "${npc.name}: ${getTaskDescriptionForType(type)}";
    
    if (_gilesTutorialStep == GilesTutorialStep.assignResident && targetId == 'kitchen') {
      advanceGilesTutorial(GilesTutorialStep.playClock);
    } else if (_gilesTutorialStep == GilesTutorialStep.directAssign && targetId == 'chicken_coop') {
      advanceGilesTutorial(GilesTutorialStep.inspectResident);
    }
    newRoomQueue.add(
      EnqueuedTask(npcId: npcId, intentId: intentId, description: taskDesc),
    );

    // 3. Create a Physical Project if it involves restoration or science
    Map<String, PhysicalProject> newProjects = Map.from(room.activeProjects);
    if (type == TaskType.restoreRoom ||
        type == TaskType.construction ||
        type == TaskType.experiment ||
        type == TaskType.research) {
      newProjects[intentId] = PhysicalProject(
        id: const Uuid().v4(),
        taskId: intentId,
        name: getTaskDescriptionForType(type),
        type: Room.getProjectType(type),
        progress: 0.0,
      );
    }

    _rooms[roomIndex] = room.copyWith(
      taskQueue: newRoomQueue,
      activeProjects: newProjects,
    );

    _lastAnnouncement =
        "Task '${getTaskDescriptionForType(type)}' has been enqueued for ${npc.name}.";
    notifyListeners();
  }

  String getTaskDescriptionForType(TaskType type) {
    if (type == TaskType.restoreRoom) return "Restoring room";
    return type.displayName.toUpperCase();
  }

  void buyResource(String resource, int amount) {
    // Check for someone at Hamlet
    final traveler = _npcs.firstWhere(
      (n) => n.worldDestinationId == 'hamlet' && n.worldTravelProgress >= 1.0,
      orElse: () => throw Exception("No one is at the Hamlet to trade!"),
    );

    final price = _marketService.getBuyPrice(resource).toInt();
    final totalCost = price * amount;
    final travelerFunds = traveler.journeyInventory['funds'] ?? 0;

    if (travelerFunds.round() >= totalCost.round()) {
      final newInv = Map<String, num>.from(traveler.journeyInventory);
      newInv['funds'] = (travelerFunds - totalCost).round();
      newInv[resource] = (newInv[resource] ?? 0) + amount;

      final index = _npcs.indexOf(traveler);
      _npcs[index] = traveler.copyWith(journeyInventory: newInv);

      _lastAnnouncement = "Purchased $amount $resource via ${traveler.name}.";
      notifyListeners();
    }
  }

  void reorderTaskQueue(String npcId, int oldIndex, int newIndex) {
    final idx = _npcs.indexWhere((n) => n.id == npcId);
    if (idx != -1) {
      final npc = _npcs[idx];
      var queue = List<String>.from(npc.taskQueue);
      if (newIndex > oldIndex) newIndex -= 1;
      final item = queue.removeAt(oldIndex);
      queue.insert(newIndex, item);
      _npcs[idx] = npc.copyWith(taskQueue: queue);
      notifyListeners();
    }
  }

  void updateIntentQueue(String npcId, List<NPCIntent> newQueue) {
    final idx = _npcs.indexWhere((n) => n.id == npcId);
    if (idx != -1) {
      _npcs[idx] = _npcs[idx].copyWith(intentQueue: newQueue);
      notifyListeners();
    }
  }

  void cancelEnqueuedTask(String npcId, String taskId) {
    cancelTask(taskId);
  }

  void cancelTask(String taskId) {
    String? resolvedIntentId = taskId;
    try {
      final t = _taskService.activeTasks.firstWhere((it) => it.id == taskId);
      if (t.intentId != null) resolvedIntentId = t.intentId;
    } catch (_) {}

    // 1. Find NPC using this task
    final npcIndex = _npcs.indexWhere((n) => n.activeTaskId == taskId);
    if (npcIndex != -1) {
      final npc = _npcs[npcIndex];
      _npcs[npcIndex] = npc.copyWith(
        status: NPCStatus.idle,
        activeTaskId: null,
        currentThought: "Assignment cancelled.",
      );
    }

    // 2. Remove from all NPC intent queues
    for (int i = 0; i < _npcs.length; i++) {
      if (_npcs[i].intentQueue.any(
        (it) => it.id == taskId || it.id == resolvedIntentId,
      )) {
        final newIntents = _npcs[i].intentQueue
            .where((it) => it.id != taskId && it.id != resolvedIntentId)
            .toList();
        _npcs[i] = _npcs[i].copyWith(intentQueue: newIntents);
      }
      if (_npcs[i].taskQueue.contains(taskId)) {
        final newTasks = _npcs[i].taskQueue
            .where((id) => id != taskId)
            .toList();
        _npcs[i] = _npcs[i].copyWith(taskQueue: newTasks);
      }
    }

    // 3. Remove from all Room task queues and active projects
    for (int i = 0; i < _rooms.length; i++) {
      bool changed = false;
      List<EnqueuedTask> newQueue = List.from(_rooms[i].taskQueue);
      if (newQueue.any((e) => e.intentId == taskId)) {
        newQueue.removeWhere((e) => e.intentId == taskId);
        changed = true;
      }

      Map<String, PhysicalProject> newProjects = Map.from(
        _rooms[i].activeProjects,
      );
      if (newProjects.containsKey(taskId)) {
        newProjects.remove(taskId);
        changed = true;
      }

      String? newOccupancy = _rooms[i].occupyingNpcId;
      if (newOccupancy != null) {
        // If the NPC was occupying this room for THIS task
        final npc = _npcs.firstWhere(
          (n) => n.id == newOccupancy,
          orElse: () => _npcs[0],
        );
        if (npc.activeTaskId == taskId) {
          newOccupancy = null;
          changed = true;
        }
      }

      if (changed) {
        _rooms[i] = _rooms[i].copyWith(
          taskQueue: newQueue,
          activeProjects: newProjects,
          occupyingNpcId: newOccupancy,
        );
      }
    }

    // 4. Remove from Task Service
    final activeTask = _taskService.activeTasks.firstWhereOrNull(
      (t) => t.id == taskId,
    );
    if (activeTask != null) {
      for (var id in activeTask.reservedEntityIds) {
        setReservation(id, false);
      }
    }

    _taskService.cancelTask(taskId);
    notifyListeners();
  }

  void cancelEnqueuedIntent(String npcId, String intentId) {
    final idx = _npcs.indexWhere((n) => n.id == npcId);
    if (idx != -1) {
      final npc = _npcs[idx];
      var queue = List<NPCIntent>.from(npc.intentQueue);
      queue.removeWhere((i) => i.id == intentId);
      _npcs[idx] = npc.copyWith(intentQueue: queue);
      notifyListeners();
    }
  }

  void hireNpc(NPC npc) {
    // Check for traveler at Hamlet to pay the fee
    final traveler = _npcs.firstWhere(
      (n) => n.worldDestinationId == 'hamlet' && n.worldTravelProgress >= 1.0,
      orElse: () =>
          throw Exception("No one is at the Hamlet to hire recruits!"),
    );

    final hiringFee = npc.hiringFee;
    final travelerFunds = traveler.journeyInventory['funds'] ?? 0;

    if (travelerFunds >= hiringFee) {
      bool removed = false;
      _availableHamletNpcs.removeWhere((n) {
        if (n.id == npc.id) {
          removed = true;
          return true;
        }
        return false;
      });

      if (removed) {
        // Pay the fee
        final newInv = Map<String, num>.from(traveler.journeyInventory);
        newInv['funds'] = (travelerFunds - hiringFee).round();
        final tIndex = _npcs.indexOf(traveler);

        // Update traveler's inventory
        _npcs[tIndex] = traveler.copyWith(journeyInventory: newInv);

        // SYNC: Hired NPC is now at the destination with the recruiter
        final hiredNpc = npc.copyWith(
          worldDestinationId: 'hamlet',
          worldDepartureId: 'manor',
          worldTravelProgress: 1.0,
          currentRoomId: null, // They are outside
          isResident: true, // Now under player control
        );
        _npcs.add(hiredNpc);

        if (hiredNpc.id != 'butler') { // Giles gets no formal contract
          final contract = Contract(
            id: 'contract_${hiredNpc.id}',
            npcId: hiredNpc.id,
            type: ContractType.employment,
            description: 'Employment agreement. The employee will reside and work at the Manor in exchange for monthly wages.',
            terms: {
              'salary': hiredNpc.monthlySalary,
              'interval': 'monthly',
            },
            isActive: true,
          );
          _contracts.add(contract);
        }

        // Add to roster history for player to ensure they join future journeys
        final playerIdx = _npcs.indexWhere((n) => n.id == 'player');
        if (playerIdx != -1) {
          final player = _npcs[playerIdx];
          final List<String> deck = List.from(player.lastEscortIds);
          if (!deck.contains(hiredNpc.id) && deck.length < 12) {
            deck.add(hiredNpc.id);
          }
          _npcs[playerIdx] = player.copyWith(lastEscortIds: deck);
        }

        _lastAnnouncement =
            "${npc.name} has been hired and joined your retinue.";
        notifyListeners();
      }
    } else {
      _lastAnnouncement =
          "Not enough funds carried by ${traveler.name} to hire ${npc.name}.";
      notifyListeners();
    }
  }

  // Cleaned up duplicate addToCookingQueue and removeFromCookingQueue

  DishQuality _mapToDishQuality(double value) {
    if (value > 2.0) return DishQuality.exquisite;
    if (value > 1.8) return DishQuality.delectable;
    if (value > 1.6) return DishQuality.sophisticated;
    if (value > 1.4) return DishQuality.fine;
    if (value > 1.2) return DishQuality.decent;
    if (value > 1.0) return DishQuality.alright;
    if (value > 0.8) return DishQuality.notBad;
    if (value > 0.6) return DishQuality.notGreat;
    if (value > 0.4) return DishQuality.mediocre;
    if (value > 0.2) return DishQuality.weak;
    if (value > 0.0) return DishQuality.awful;
    return DishQuality.disgusting;
  }

  DishType _mapToDishType(String recipeId) {
    if (recipeId.contains('bread') || recipeId.contains('pasta')) {
      return DishType.cereal;
    }
    if (recipeId.contains('chicken') ||
        recipeId.contains('beef') ||
        recipeId.contains('meat')) {
      return DishType.protein;
    }
    if (recipeId.contains('stew') ||
        recipeId.contains('soup') ||
        recipeId.contains('bean')) {
      return DishType.vegetable;
    }
    return DishType.treat;
  }

  void _evaluateBehaviorTree(int index, {Set<String>? claimedWorkstations}) {
    var npc = _npcs[index];
    if (npc.id.contains('agent')) return; // Bypass AI autonomy for test agents

    final totalMin = _currentDate.totalMinutes;
    final int hourIndex = _currentDate.hourIndex;

    // 0. Dead/Fainted/Broken - Stop processing
    if (npc.status == NPCStatus.dead ||
        npc.status == NPCStatus.fainted ||
        npc.status == NPCStatus.broken) {
      return;
    }

    final activeTask = npc.activeTaskId != null
        ? _taskService.activeTasks.firstWhereOrNull(
            (t) => t.id == npc.activeTaskId,
          )
        : null;

    // Clean up resolved tasks
    if (activeTask != null) {
      bool isResolved = false;
      if (activeTask.priority == IntentPriority.emergency) {
        final crisis = _crises.firstWhereOrNull((c) => c.severity > 0.0);
        if (crisis == null) isResolved = true;
      } else if (activeTask.priority == IntentPriority.high ||
          activeTask.priority == IntentPriority.low) {
        if (activeTask.type == TaskType.rest) {
          final activity = npc.schedule.getActivityForHour(hourIndex);
          if (activity != ScheduleActivity.sleep && npc.energy >= 80.0) {
            isResolved = true;
          } else if (npc.energy >= 100.0) {
            isResolved = true;
          }
        } else if (activeTask.type == TaskType.useToilet &&
            npc.digestion <= 10) {
          isResolved = true;
        }
      }
      if (isResolved) {
        _taskService.removeTask(activeTask.id);
        _clearRoomOccupancyForNpc(npc.id);
        final List<NPCIntent> newQueue = List.from(npc.intentQueue);
        if (activeTask.intentId != null) {
          newQueue.removeWhere((i) => i.id == activeTask.intentId);
        }
        _npcs[index] = npc = npc.copyWith(
          activeTaskId: null,
          intentQueue: newQueue,
          status: NPCStatus.idle,
        );
      }
    }

    final currentTask = npc.activeTaskId != null
        ? _taskService.activeTasks.firstWhereOrNull(
            (t) => t.id == npc.activeTaskId,
          )
        : null;

    bool tryAssign(NPCIntent intent) {
      if (currentTask != null && currentTask.intentId == intent.id) {
        return true;
      }
      if (intent.startTimeMin != null && intent.startTimeMin! > totalMin) {
        return false;
      }

      // Hand Washing Intercept
      bool isCooking =
          intent.action == TaskType.cook ||
          intent.action == TaskType.prepareMeals;
      bool isMedical =
          intent.action == TaskType.surgery ||
          intent.action == TaskType.surgicalCombination ||
          intent.action == TaskType.operation ||
          intent.action == TaskType.surgicalOperation ||
          intent.action == TaskType.diagnoseIllness ||
          intent.action == TaskType.treatIllness ||
          intent.action == TaskType.stopBleeding;

      final hygiene = npc.stats["hygiene"] ?? 5;
      bool needsWashHands = false;
      if (isCooking && hygiene >= 5 && npc.cleanliness < 100.0) {
        needsWashHands = true;
      }
      if (isMedical && hygiene >= 6 && npc.cleanliness < 100.0) {
        needsWashHands = true;
      }

      if (needsWashHands) {
        int washDuration = hygiene >= 9 ? 10 : (hygiene >= 7 ? 8 : 5);
        String targetBathroom = 'bathroom_down';
        if (npc.currentRoomId != null) {
          final pathDown = _findPath(npc.currentRoomId!, 'bathroom_down');
          final pathUp = _findPath(npc.currentRoomId!, 'bathroom_up');
          if (pathUp.length < pathDown.length) targetBathroom = 'bathroom_up';
        }
        final washIntent = NPCIntent(
          id: 'wash_hands_pre_${intent.id}',
          action: TaskType.washHands,
          targetRoomId: targetBathroom,
          priority: intent.priority,
          expectedDurationMin: washDuration,
        );

        // Make sure the original intent is still in the queue to be processed later
        if (!npc.intentQueue.any((i) => i.id == intent.id)) {
          final newQ = List<NPCIntent>.from(npc.intentQueue)..insert(0, intent);
          _npcs[index] = npc = npc.copyWith(intentQueue: newQ);
        }

        intent = washIntent;
      }

      if (currentTask != null) {
        bool preempt = intent.priority.index > currentTask.priority.index;
        bool isCurrentIdleOrNormal =
            currentTask.priority.index <= IntentPriority.normal.index ||
            currentTask.type == TaskType.idle ||
            currentTask.type == TaskType.relax;

        if (intent.isManual && isCurrentIdleOrNormal) {
          preempt = true;
        }

        // Idle and Relax should never block the behavior tree from switching to a new activity
        if (currentTask.type == TaskType.idle ||
            currentTask.type == TaskType.relax) {
          preempt = true;
        }

        // Always allow equal or higher priority needs to wake a resting character (except rest itself)
        if (currentTask.type == TaskType.rest &&
            intent.priority.index >= currentTask.priority.index &&
            intent.action != TaskType.rest) {
          preempt = true;
        }

        if (!preempt) return false;

        final oldIdx = npc.intentQueue.indexWhere(
          (i) => i.id == currentTask.intentId,
        );
        if (oldIdx != -1) {
          final mutableQueue = List<NPCIntent>.from(npc.intentQueue);
          mutableQueue[oldIdx] = npc.intentQueue[oldIdx].copyWith(
            minutesRemaining: currentTask.minutesRemaining,
          );
          _npcs[index] = npc = npc.copyWith(intentQueue: mutableQueue);
        }
        _taskService.removeTask(currentTask.id);
        _clearRoomOccupancyForNpc(npc.id);
        _npcs[index] = npc = npc.copyWith(activeTaskId: null);
      }

      final success = assignNpcToTask(
        npc.id,
        intent.action,
        intent.targetRoomId,
        recipeId: intent.recipeId,
        targetName: intent.targetName,
        intentId: intent.id,
        priority: intent.priority,
        silent: true,
      );

      if (success) {
        var freshNpc = _npcs[index];
        if (!freshNpc.intentQueue.any((i) => i.id == intent.id)) {
          final isEmergency =
              intent.priority.index >= IntentPriority.urgent.index;
          _npcs[index] = npc = freshNpc.copyWith(
            intentQueue: isEmergency
                ? [intent, ...freshNpc.intentQueue]
                : [...freshNpc.intentQueue, intent],
            lastScheduledHour: hourIndex,
          );
        } else {
          npc = freshNpc;
        }
        return true;
      } else {
        if (!intent.isManual) {
          final cooled = intent.copyWith(startTimeMin: totalMin + 10);
          var freshNpc = _npcs[index];
          var q = List<NPCIntent>.from(freshNpc.intentQueue);
          q.removeWhere((i) => i.id == intent.id);
          q.add(cooled);
          _npcs[index] = npc = freshNpc.copyWith(
            intentQueue: q,
            lastScheduledHour: hourIndex,
          );
        }
        return false;
      }
    }

    // --- STEP 0: Eating a Meal ---
    if (currentTask != null && currentTask.type == TaskType.eat) return;

    // --- STEP 1 & 2: EMERGENCY OVERRIDES ---
    if (npc.energy <= 0.0) {
      _npcs[index] = npc = npc.copyWith(
        energy: 15.0,
        status: NPCStatus.sleeping,
      );
      return;
    }
    if (npc.digestion >= 100.0) {
      _npcs[index] = npc = npc.copyWith(
        digestion: 0.0,
        energy: max(0.0, npc.energy - 10.0),
      );
      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] EMERGENCY: ${npc.name} had a bowel incident.",
      );
      notifyListeners();
      return;
    }

    final crisis = _crises.firstWhereOrNull((c) => c.severity > 0.0);
    if (crisis != null) {
      TaskType eqTask = TaskType.relax;
      switch (crisis.type) {
        case ManorCrisisType.fire:
          eqTask = TaskType.extinguishFire;
          break;
        case ManorCrisisType.specimenEscape:
          eqTask = TaskType.recombineSpecimen;
          break;
        case ManorCrisisType.intruder:
        case ManorCrisisType.golemTantrum:
          eqTask = TaskType.defendManor;
          break;
      }
      final eIntent = NPCIntent(
        id: 'emergency_${crisis.id}',
        action: eqTask,
        targetRoomId: crisis.roomId,
        priority: IntentPriority.emergency,
        expectedDurationMin: crisis.type == ManorCrisisType.fire ? 15 : 30,
      );
      if (tryAssign(eIntent)) return;
    }

    // --- STEP 3 & 4: HIGH PRIORITY PIPELINE ---
    var mutableQueue = List<NPCIntent>.from(npc.intentQueue);
    bool addedHighPri = false;

    if (npc.hunger > 89 &&
        !mutableQueue.any((i) => i.id == 'high_priority_hunger_${npc.id}')) {
      String? mealName;
      if (_pantry.isNotEmpty) {
        final neededTypes = npc.diet.dailyRequirements.keys.toList();
        int? bestIndex;
        for (int j = 0; j < _pantry.length; j++) {
          if (neededTypes.contains(_pantry[j].type)) {
            if (bestIndex == null ||
                _pantry[bestIndex].quality.index < _pantry[j].quality.index) {
              bestIndex = j;
            }
          }
        }
        mealName = bestIndex != null
            ? _pantry[bestIndex].name
            : _pantry.first.name;
      } else {
        final priorityKeys = [
          'cabbage',
          'potato',
          'carrots',
          'beets',
          'green_beans',
          'faba_beans',
          'eggs',
          'meat_beef',
          'meat_chicken',
          'meat_generic',
          'flour_spelt',
          'flour_durum',
        ];
        String? foundKey;
        for (var key in priorityKeys) {
          if ((resources[key] ?? 0) > 0) {
            foundKey = key;
            break;
          }
        }
        if (foundKey != null) {
          mealName = "raw ${foundKey.replaceAll('_', ' ')}";
        }
      }
      mutableQueue.add(
        NPCIntent(
          id: 'high_priority_hunger_${npc.id}',
          action: TaskType.eat,
          targetRoomId: 'dining_hall',
          priority: IntentPriority.high,
          expectedDurationMin: 60,
          targetName: mealName,
        ),
      );
      addedHighPri = true;
    }
    if (npc.energy < 11 &&
        !mutableQueue.any((i) => i.id == 'high_priority_energy_${npc.id}')) {
      mutableQueue.add(
        NPCIntent(
          id: 'high_priority_energy_${npc.id}',
          action: TaskType.rest,
          targetRoomId: npc.assignedRoomId ?? 'entryway',
          priority: IntentPriority.high,
          expectedDurationMin: 480,
        ),
      );
      addedHighPri = true;
    }
    if (npc.digestion > 84 &&
        !mutableQueue.any((i) => i.id == 'high_priority_toilet_${npc.id}')) {
      String targetBathroom = 'bathroom_down';
      if (npc.currentRoomId != null) {
        final pathDown = _findPath(npc.currentRoomId!, 'bathroom_down');
        final pathUp = _findPath(npc.currentRoomId!, 'bathroom_up');
        bool downOccupied = _taskService.activeTasks.any(
          (t) =>
              t.targetId == 'bathroom_down' &&
              !TaskService.isConcurrent(t.type),
        );
        bool upOccupied = _taskService.activeTasks.any(
          (t) =>
              t.targetId == 'bathroom_up' && !TaskService.isConcurrent(t.type),
        );

        if (upOccupied && !downOccupied) {
          targetBathroom = 'bathroom_down';
        } else if (downOccupied && !upOccupied) {
          targetBathroom = 'bathroom_up';
        } else if (pathUp.length < pathDown.length) {
          targetBathroom = 'bathroom_up';
        } else {
          targetBathroom = 'bathroom_down';
        }
      }
      mutableQueue.add(
        NPCIntent(
          id: 'high_priority_toilet_${npc.id}',
          action: TaskType.useToilet,
          targetRoomId: targetBathroom,
          priority: IntentPriority.high,
          expectedDurationMin: 30,
        ),
      );
      addedHighPri = true;
    }

    if (npc.cleanliness < 11.0 &&
        !mutableQueue.any((i) => i.id == 'high_priority_bathe_${npc.id}')) {
      String targetBathroom = 'bathroom_down';
      if (npc.currentRoomId != null) {
        final pathDown = _findPath(npc.currentRoomId!, 'bathroom_down');
        final pathUp = _findPath(npc.currentRoomId!, 'bathroom_up');
        bool downOccupied = _taskService.activeTasks.any(
          (t) =>
              t.targetId == 'bathroom_down' &&
              !TaskService.isConcurrent(t.type),
        );
        bool upOccupied = _taskService.activeTasks.any(
          (t) =>
              t.targetId == 'bathroom_up' && !TaskService.isConcurrent(t.type),
        );

        if (upOccupied && !downOccupied) {
          targetBathroom = 'bathroom_down';
        } else if (downOccupied && !upOccupied) {
          targetBathroom = 'bathroom_up';
        } else if (pathUp.length < pathDown.length) {
          targetBathroom = 'bathroom_up';
        } else {
          targetBathroom = 'bathroom_down';
        }
      }
      mutableQueue.add(
        NPCIntent(
          id: 'high_priority_bathe_${npc.id}',
          action: TaskType.bathe,
          targetRoomId: targetBathroom,
          priority: IntentPriority.high,
          expectedDurationMin: 30,
        ),
      );
      addedHighPri = true;
    }

    if (addedHighPri) {
      _npcs[index] = npc = npc.copyWith(intentQueue: mutableQueue);
    }

    if (npc.status == NPCStatus.sleeping) {
      final activity = npc.schedule.getActivityForHour(hourIndex);
      final criticalNeeds = npc.digestion >= 85.0;
      final hasWakefulIntent = npc.intentQueue.any(
        (i) =>
            i.priority.index >= IntentPriority.high.index ||
            i.action == TaskType.useToilet ||
            i.isManual,
      );
      if (activity == ScheduleActivity.sleep &&
          !criticalNeeds &&
          !hasWakefulIntent) {
        return;
      }
    }

    final highPriQueue = npc.intentQueue
        .where((i) => i.priority.index >= IntentPriority.high.index)
        .toList();
    highPriQueue.sort((a, b) {
      if (a.action == TaskType.useToilet && b.action != TaskType.useToilet) {
        return -1;
      }
      if (b.action == TaskType.useToilet && a.action != TaskType.useToilet) {
        return 1;
      }
      // Sort emergency above high
      return b.priority.index.compareTo(a.priority.index);
    });

    for (var intent in highPriQueue) {
      if (tryAssign(intent)) return;
    }

    // --- PHASE 2: SCHEDULE BRANCHES ---
    final activity = npc.schedule.getActivityForHour(hourIndex);

    if (activity == ScheduleActivity.sleep) {
      // SLEEP BLOCK
      int checkHour = hourIndex;
      int safetyCap = 0;
      while (npc.schedule.getActivityForHour(checkHour % 168) ==
              ScheduleActivity.sleep &&
          safetyCap < 168) {
        checkHour++;
        safetyCap++;
      }
      int durationHours = checkHour - hourIndex;
      int sleepDurationMin = (durationHours * 60) - _currentDate.minute;
      if (sleepDurationMin <= 0) sleepDurationMin = 60; // Fallback

      final sleepIntent = NPCIntent(
        id: 'sched_sleep_${npc.id}_$hourIndex',
        action: TaskType.rest,
        targetRoomId: npc.assignedRoomId ?? 'entryway',
        priority: IntentPriority.high,
        expectedDurationMin: sleepDurationMin,
      );
      tryAssign(sleepIntent);
      return;
    }

    if (activity == ScheduleActivity.eat) {
      // EAT BLOCK
      if (currentTask != null &&
          (currentTask.type == TaskType.cook ||
              currentTask.type == TaskType.eat ||
              currentTask.type == TaskType.butcherAnimals ||
              currentTask.type == TaskType.collectEggs ||
              currentTask.type == TaskType.harvestCrops)) {
        return;
      }
      if (npc.lastMealHour == _currentDate.hour) {
        return; // Already ate this block
      }
      if (npc.hunger < 15.0) {
        return; // Not really hungry enough to consume a full meal!
      }

      TaskType mappedAction = TaskType.eat; // default
      String targetRoom = 'kitchen';
      int expectedDur = 30;

      String? mealName;
      if (_pantry.isNotEmpty) {
        mappedAction = TaskType.eat;
        expectedDur = 30;
        final neededTypes = npc.diet.dailyRequirements.keys.toList();
        int? bestIndex;
        for (int j = 0; j < _pantry.length; j++) {
          if (neededTypes.contains(_pantry[j].type)) {
            if (bestIndex == null ||
                _pantry[bestIndex].quality.index < _pantry[j].quality.index) {
              bestIndex = j;
            }
          }
        }
        mealName = bestIndex != null
            ? _pantry[bestIndex].name
            : _pantry.first.name;
      } else if (_cookingQueue.isNotEmpty && (resources['meals'] ?? 0) < 10) {
        mappedAction = TaskType.cook;
        expectedDur = 45;
      } else {
        final priorityKeys = [
          'cabbage',
          'potato',
          'carrots',
          'beets',
          'green_beans',
          'faba_beans',
          'eggs',
          'meat_beef',
          'meat_chicken',
          'meat_generic',
          'flour_spelt',
          'flour_durum',
        ];
        String? foundKey;
        for (var key in priorityKeys) {
          if ((resources[key] ?? 0) > 0) {
            foundKey = key;
            break;
          }
        }
        if (foundKey != null) {
          mappedAction = TaskType.eat;
          expectedDur = 15;
          mealName = "raw ${foundKey.replaceAll('_', ' ')}";
        } else {
          final coop = _rooms.firstWhereOrNull((r) => r.id == 'chicken_coop');
          if (coop != null && coop.inventory.any((i) => i.type == 'eggs')) {
            mappedAction = TaskType.collectEggs;
            targetRoom = 'chicken_coop';
            expectedDur = 15;
          } else if (_chickens.isNotEmpty) {
            mappedAction = TaskType.butcherAnimals;
            targetRoom = 'chicken_coop';
            expectedDur = 45;
          } else {
            mappedAction = TaskType.eat;
            expectedDur = 5;
          }
        }
      }

      final eatIntent = NPCIntent(
        id: 'sched_eat_${npc.id}_$hourIndex',
        action: mappedAction,
        targetRoomId: targetRoom,
        priority: IntentPriority.high,
        expectedDurationMin: expectedDur,
        targetName: mealName,
      );
      tryAssign(eatIntent);
      return;
    }

    if (activity == ScheduleActivity.work ||
        activity == ScheduleActivity.cleanRoom ||
        activity == ScheduleActivity.cook ||
        activity == ScheduleActivity.guardCoop ||
        activity == ScheduleActivity.study) {
      // WORK BLOCK
      final normalQueue = npc.intentQueue
          .where((i) => i.priority == IntentPriority.normal)
          .toList();
      bool assignedNormal = false;
      for (var intent in normalQueue) {
        if (tryAssign(intent)) {
          assignedNormal = true;
          break;
        }
      }
      if (assignedNormal) return;

      // Evaluate Low Priority Responsibilities
      final validCategories =
          npc.responsibilities.entries.where((e) => e.value > 0).toList()
            ..sort((a, b) {
              final starCmp = b.value.compareTo(a.value);
              if (starCmp != 0) return starCmp;
              return a.key.index.compareTo(b.key.index);
            });

      TaskType? chosenTask;
      String? chosenTargetId;

      for (final entry in validCategories) {
        final tasks = TaskCategoryMapping.getTasksForCategory(entry.key);
        for (final task in tasks) {
          final targetId = _getAutonomousTargetForTask(task, npc);
          if (targetId != null) {
            chosenTask = task;
            chosenTargetId = targetId;
            break;
          }
        }
        if (chosenTask != null) break;
      }

      if (chosenTask == null) {
        tryAssign(
          NPCIntent(
            id: 'sched_idle_w_${npc.id}',
            action: TaskType.idle,
            targetRoomId:
                _getPersonalityIdleTarget(index, activity) ?? 'entryway',
            priority: IntentPriority.low,
            expectedDurationMin: 60,
          ),
        );
      } else {
        tryAssign(
          NPCIntent(
            id: 'low_pri_${npc.id}_${chosenTask.name}_${chosenTargetId ?? 'none'}',
            action: chosenTask,
            targetRoomId: chosenTargetId ?? npc.assignedRoomId ?? 'entryway',
            priority: IntentPriority.low,
            expectedDurationMin: getEstimatedTaskMinutes(
              npc,
              chosenTask,
              chosenTargetId,
            ),
          ),
        );
      }
      return;
    }

    // LEISURE BLOCK
    final existingLeisureIntentIndex = npc.intentQueue.indexWhere(
      (i) => i.id == 'sched_leisure_${npc.id}',
    );
    if (existingLeisureIntentIndex != -1) {
      if (tryAssign(npc.intentQueue[existingLeisureIntentIndex])) return;
    }

    Map<TaskType, double> weights = {};
    final stats = npc.stats;
    int curCleanliness = npc.cleanliness.toInt();

    final normalWork = npc.intentQueue.firstWhereOrNull(
      (i) =>
          i.priority == IntentPriority.normal && i.id.startsWith('sched_work'),
    );
    if (normalWork != null) {
      weights[normalWork.action] = (stats['morality'] ?? 1).toDouble();
    }

    if (_rooms.any(
      (r) =>
          r.isRestored &&
          (r.type == RoomType.library ||
              r.type == RoomType.bedroom ||
              r.id == 'garden_lot' ||
              r.id == 'vegetable_garden'),
    )) {
      weights[TaskType.readBook] = (stats['intellect'] ?? 1).toDouble();
    }
    weights[TaskType.goForWalk] = (stats['judgment'] ?? 1).toDouble();
    weights[TaskType.cardio] = (stats['beauty'] ?? 1).toDouble();
    weights[TaskType.weights] = (stats['endurance'] ?? 1).toDouble();

    if (_rooms.any((r) => r.isRestored && r.type == RoomType.study)) {
      weights[TaskType.paint] = (stats['dexterity'] ?? 1).toDouble();
    }
    if (_rooms.any((r) => r.isRestored && r.type == RoomType.workshop)) {
      weights[TaskType.sculpt] = (stats['courage'] ?? 1).toDouble();
    }
    if (_chickens.isNotEmpty ||
        npc.inventory.any(
          (i) => i.type.contains('cat') || i.type.contains('dog'),
        )) {
      weights[TaskType.interactAnimals] = (stats['temperament'] ?? 1)
          .toDouble();
    }
    if (_rooms.any((r) => r.isRestored && r.type == RoomType.bedroom)) {
      weights[TaskType.writePoetry] = (stats['strength'] ?? 1).toDouble();
    }
    if (_rooms.any((r) => r.isRestored && r.type == RoomType.library)) {
      weights[TaskType.writeNovel] = (stats['perception'] ?? 1).toDouble();
    }
    if (curCleanliness < 100 &&
        _rooms.any((r) => r.isRestored && r.type == RoomType.toilet)) {
      weights[TaskType.bathe] =
          (stats['hygiene'] ?? 1).toDouble() *
          ((100.0 - curCleanliness) / 100.0);
    }

    final recipes = KitchenService.getAvailableRecipes();
    bool canCookQuick = false;
    for (var r in recipes) {
      if (r.durationMinutes < 46) {
        bool hasIngs = true;
        for (var entry in r.ingredients.entries) {
          String ingKey = entry.key;
          int avail = (resources[ingKey] ?? 0).toInt();
          if (ingKey == 'meat') {
            avail =
                (resources['meat_generic'] ?? 0).toInt() +
                (resources['meat_beef'] ?? 0).toInt() +
                (resources['meat_chicken'] ?? 0).toInt();
          }
          if (avail < entry.value) {
            hasIngs = false;
            break;
          }
        }
        if (hasIngs) {
          canCookQuick = true;
          break;
        }
      }
    }
    if (canCookQuick &&
        _rooms.any((r) => r.isRestored && r.type == RoomType.kitchen)) {
      weights[TaskType.cook] = (stats['satisfaction'] ?? 1).toDouble();
    }

    final String? lastLeisureTask = npc.metadata['lastLeisureTask'] as String?;
    if (lastLeisureTask != null) {
      TaskType? lastType;
      try {
        lastType = TaskType.values.firstWhere((t) => t.name == lastLeisureTask);
      } catch (_) {
        // Ignored if invalid task type is found in metadata
      }

      if (lastType != null && weights.containsKey(lastType)) {
        weights[lastType] = weights[lastType]! * 0.1;
      }
    }

    TaskType chosenTask = TaskType.idle;
    double totalWeight = weights.values.fold(0.0, (sum, w) => sum + w);
    if (totalWeight > 0) {
      double roll = Random().nextDouble() * totalWeight;
      for (var entry in weights.entries) {
        roll -= entry.value;
        if (roll <= 0) {
          chosenTask = entry.key;
          break;
        }
      }
    }

    String targetRoom =
        _getPersonalityIdleTarget(index, activity) ?? 'entryway';
    if (chosenTask == TaskType.readBook) {
      final opts = _rooms
          .where(
            (r) =>
                r.isRestored &&
                (r.type == RoomType.library ||
                    r.type == RoomType.bedroom ||
                    r.id == 'vegetable_garden'),
          )
          .toList();
      targetRoom = opts.isNotEmpty ? opts.first.id : 'entryway';
    } else if (chosenTask == TaskType.goForWalk ||
        chosenTask == TaskType.cardio ||
        chosenTask == TaskType.weights) {
      targetRoom = 'garden_lot';
    } else if (chosenTask == TaskType.paint) {
      final opts = _rooms
          .where((r) => r.isRestored && r.type == RoomType.study)
          .toList();
      targetRoom = opts.isNotEmpty ? opts.first.id : 'entryway';
    } else if (chosenTask == TaskType.sculpt) {
      final opts = _rooms
          .where((r) => r.isRestored && r.type == RoomType.workshop)
          .toList();
      targetRoom = opts.isNotEmpty ? opts.first.id : 'entryway';
    } else if (chosenTask == TaskType.interactAnimals) {
      targetRoom = 'chicken_coop';
    } else if (chosenTask == TaskType.writePoetry) {
      final opts = _rooms
          .where((r) => r.isRestored && r.type == RoomType.bedroom)
          .toList();
      targetRoom = opts.isNotEmpty ? opts.first.id : 'entryway';
    } else if (chosenTask == TaskType.writeNovel) {
      final opts = _rooms
          .where((r) => r.isRestored && r.type == RoomType.library)
          .toList();
      targetRoom = opts.isNotEmpty ? opts.first.id : 'entryway';
    } else if (chosenTask == TaskType.bathe) {
      targetRoom = 'bathroom_down';
      if (npc.currentRoomId != null) {
        final pD = _findPath(npc.currentRoomId!, 'bathroom_down');
        final pU = _findPath(npc.currentRoomId!, 'bathroom_up');
        if (pU.length < pD.length) targetRoom = 'bathroom_up';
      }
    } else if (chosenTask == TaskType.cook) {
      targetRoom = 'kitchen';
    }

    final newMetadata = Map<String, dynamic>.from(npc.metadata);
    newMetadata['lastLeisureTask'] = chosenTask.name;
    _npcs[index] = npc.copyWith(metadata: newMetadata);

    tryAssign(
      NPCIntent(
        id: 'sched_leisure_${npc.id}',
        action: chosenTask,
        targetRoomId: targetRoom,
        priority: IntentPriority.low,
        expectedDurationMin: 180,
      ),
    );
  }

  String? _getAutonomousTargetForTask(TaskType type, NPC npc) {
    switch (type) {
      case TaskType.cleanRoom:
        // Find the dirtiest manor room
        final dirtyRooms = _rooms
            .where((r) => r.isRestored && r.isInsideManor && r.dirtiness > 0.1)
            .toList();
        if (dirtyRooms.isEmpty) return null;
        dirtyRooms.sort((a, b) => b.dirtiness.compareTo(a.dirtiness));
        return dirtyRooms.first.id;
      case TaskType.cleanDish:
        return _rooms.any(
              (r) =>
                  r.isRestored &&
                  r.inventory.any((i) => i.type == 'dirty_dishes'),
            )
            ? 'kitchen'
            : null;
      case TaskType.discardTrash:
      case TaskType.discardSpoiledFood:
        return _pantry.any((i) => i.isSpoiled(_currentDate)) ? 'kitchen' : null;

      case TaskType.diagnoseIllness:
      case TaskType.treatIllness:
      case TaskType.checkBedridden:
      case TaskType.careForSick:
        final sickNpc = _npcs.firstWhereOrNull(
          (n) =>
              n.statusEffects.any((e) => e.type == StatusEffectType.disease) &&
              n.id != npc.id,
        );
        return sickNpc?.currentRoomId;
      case TaskType.careForInjured:
      case TaskType.stopBleeding:
        final injuredNpc = _npcs.firstWhereOrNull(
          (n) =>
              n.id != npc.id &&
              n.bodyParts.any((bp) => bp.health < bp.maxHealth),
        );
        return injuredNpc?.currentRoomId;

      case TaskType.butcherAnimals:
        return _rooms.any(
              (r) =>
                  r.isRestored &&
                  r.inventory.any((i) => i.category == ItemCategory.corpse),
            )
            ? 'kitchen'
            : null;
      case TaskType.prepareMeals:
        final currentMeals = (resources['meals'] ?? 0) + _pantry.length;
        return (currentMeals < 10 && _pantry.isNotEmpty) ? 'kitchen' : null;

      case TaskType.collectEggs:
        final coop = _rooms.firstWhereOrNull((r) => r.id == 'chicken_coop');
        if (coop != null && coop.inventory.any((i) => i.type == 'egg')) {
          return 'chicken_coop';
        }
        return null;
      case TaskType.deliverEggs:
        return npc.inventory.any((i) => i.type == 'egg') ? 'kitchen' : null;
      case TaskType.harvestGrain:
        return _crops.any((c) => c.isHarvestable) ? 'vegetable_garden' : null;

      case TaskType.hauling:
        return _rooms.any(
              (r) =>
                  r.isRestored &&
                  r.inventory.any(
                    (i) =>
                        i.id == 'wood' ||
                        i.id == 'stone' ||
                        i.type == 'raw_meat',
                  ),
            )
            ? 'entryway'
            : null;
      case TaskType.construction:
      case TaskType.restoreRoom:
        final blueprints = _rooms
            .where((r) => !r.isRestored && r.isInsideManor)
            .toList();
        return blueprints.isNotEmpty ? blueprints.first.id : null;
      case TaskType.excavate:
        return _rooms.any((r) => r.type == RoomType.basement && !r.isRestored)
            ? 'basement'
            : null;

      case TaskType.processTimber:
      case TaskType.blacksmithing:
      case TaskType.manufacturing:
      case TaskType.refineNonLiving:
        final ws = _rooms.firstWhereOrNull((r) => r.type == RoomType.workshop);
        return ws?.isRestored == true ? ws!.id : null;
      case TaskType.cook:
        final currentMeals = (resources['meals'] ?? 0) + _pantry.length;
        return (currentMeals < 10 && _cookingQueue.isNotEmpty)
            ? 'kitchen'
            : null;
      case TaskType.tillSoil:
        final untilliedFields = _rooms
            .where(
              (r) =>
                  r.type == RoomType.field &&
                  r.tilledAmount < 0.9 &&
                  !_crops.any((c) => c.roomId == r.id),
            )
            .toList();
        if (untilliedFields.isEmpty) return null;
        untilliedFields.sort(
          (a, b) => a.tilledAmount.compareTo(b.tilledAmount),
        );
        return untilliedFields.first.id;
      case TaskType.fertilizeSoil:
        final unfertilizedFields = _rooms
            .where(
              (r) =>
                  r.type == RoomType.field &&
                  r.isTilled &&
                  r.fertilizedAmount < 0.9 &&
                  !_crops.any((c) => c.roomId == r.id),
            )
            .toList();
        if (unfertilizedFields.isEmpty) return null;
        unfertilizedFields.sort(
          (a, b) => a.fertilizedAmount.compareTo(b.fertilizedAmount),
        );
        return unfertilizedFields.first.id;
      case TaskType.plantCrops:
        // Plant if we have tilled soil and seeds
        final tilledFields = _rooms
            .where(
              (r) =>
                  r.type == RoomType.field &&
                  r.isTilled &&
                  r.isFertilized &&
                  !_crops.any((c) => c.roomId == r.id),
            )
            .toList();
        if (tilledFields.isEmpty) return null;
        // Check for any seeds
        bool hasSeeds = false;
        for (var type in CropType.values) {
          if ((resources['seeds_${type.name}'] ?? 0) > 0) {
            hasSeeds = true;
            break;
          }
        }
        return hasSeeds ? tilledFields.first.id : null;
      case TaskType.waterCrops:
        bool needsWater = _crops.any((c) => c.moistureLevel < 0.40);
        return needsWater
            ? 'vegetable_garden'
            : null; // Default to garden for now
      case TaskType.careForCrops:
        bool needsCare = _crops.any(
          (c) =>
              c.lastCaredForAt == null ||
              DateTime.now().difference(c.lastCaredForAt!).inHours > 12,
        );
        return needsCare ? 'vegetable_garden' : null;
      case TaskType.harvestCabbage:
      case TaskType.harvestCrops:
        final mature = _crops.any((c) => c.isHarvestable);
        return mature ? 'vegetable_garden' : null;
      case TaskType.research:
        return _researchQueue.isNotEmpty ? 'study' : null;
      case TaskType.study:
        return _researchQueue.isNotEmpty ? 'library' : null;
      case TaskType.experiment:
        return _researchQueue.isNotEmpty ? 'laboratory' : null;
      case TaskType.operation:
      case TaskType.surgery:
      case TaskType.surgicalOperation:
        return _researchQueue.isNotEmpty ? 'operating_room' : null;
      case TaskType.dissect:
      case TaskType.vivisection:
      case TaskType.puzzleStudy:
      case TaskType.deprivationStudy:
      case TaskType.clinicalTrial:
      case TaskType.transcribeNotes:
      case TaskType.archiveResearch:
        final hasKnowledgeInGlobal = inventory.any(
          (i) => i.category == ItemCategory.knowledge,
        );
        final hasKnowledgeOnPerson = npc.inventory.any(
          (i) => i.category == ItemCategory.knowledge,
        );

        if (!hasKnowledgeInGlobal && !hasKnowledgeOnPerson) return null;

        final library = _rooms.firstWhere(
          (r) => r.type == RoomType.library && r.isRestored,
          orElse: () => _rooms.firstWhere(
            (r) => r.type == RoomType.study,
            orElse: () => _rooms[0],
          ),
        );
        return library.id;
      case TaskType.guardCoop:
        final coop = _rooms.firstWhereOrNull((r) => r.id == 'chicken_coop');
        return (coop != null && coop.isRestored) ? 'chicken_coop' : null;
      case TaskType.hunt:
        return 'entryway'; // "Outside"
      case TaskType.brew:
      case TaskType.distill:
        final productionRoom = _rooms.firstWhere(
          (r) => r.type == RoomType.unused && r.isRestored,
          orElse: () => _rooms[0],
        );
        return productionRoom.id;
      default:
        return null; // Not autonomously performable yet
    }
  }

  String _getRandomPropertyRoom() {
    // Dynamically select from restored rooms or key property areas
    final restoredRooms = _rooms
        .where((r) => r.isRestored && r.id != 'road')
        .toList();
    if (restoredRooms.isEmpty) return 'entryway';

    final Random random = Random();
    return restoredRooms[random.nextInt(restoredRooms.length)].id;
  }

  String? _getPersonalityIdleTarget(int index, ScheduleActivity activity) {
    final npc = _npcs[index];
    final isGiles = npc.role == 'Butler';
    final isAlphonse = npc.isPlayer;
    final random = Random();

    if (isGiles) {
      // Flaubert Giles' idle state behavior: stand at attention in Entry or idle in chicken coop
      final areas = ['entryway', 'chicken_coop'];
      final reachable = areas.where((id) {
        final r = _rooms.firstWhereOrNull((rm) => rm.id == id);
        return r != null && r.isRestored;
      }).toList();
      if (reachable.isEmpty) return 'entryway';
      return reachable[random.nextInt(reachable.length)];
    } else if (isAlphonse) {
      // Main character's idle state behavior: wander the manor, read in library, or idle in garden.
      final areas = ['library', 'vegetable_garden'];
      final reachable = areas.where((id) {
        final r = _rooms.firstWhereOrNull((rm) => rm.id == id);
        return r != null && r.isRestored;
      }).toList();

      // Wander chance
      if (reachable.isEmpty || random.nextDouble() < 0.33) {
        return _getRandomPropertyRoom();
      }
      return reachable[random.nextInt(reachable.length)];
    }

    return _getRandomPropertyRoom();
  }

  void interactWithNpc(String npcId, InteractionType type) {
    final targetIdx = _npcs.indexWhere((n) => n.id == npcId);
    final playerIdx = _npcs.indexWhere((n) => n.isPlayer);

    if (targetIdx != -1 && playerIdx != -1) {
      final npc1 = _npcs[playerIdx];
      final npc2 = _npcs[targetIdx];

      final result = SocialService.performInteraction(npc1, npc2, type);

      final newRels1 = Map<String, Relationship>.from(
        _npcs[playerIdx].relationships,
      );
      newRels1[npcId] = result['actorRelationship'] as Relationship;

      final newRels2 = Map<String, Relationship>.from(
        _npcs[targetIdx].relationships,
      );
      newRels2[npc1.id] = result['targetRelationship'] as Relationship;

      _npcs[playerIdx] = _npcs[playerIdx].copyWith(relationships: newRels1);
      _npcs[targetIdx] = _npcs[targetIdx].copyWith(relationships: newRels2);

      final log = "YOU: ${result['log']}";
      _lastAnnouncement = log;
      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] SOCIAL: $log",
      );
      if (_announcementHistory.length > 50) _announcementHistory.removeLast();

      notifyListeners();
    }
  }

  void _handleScienceTaskCompletion(int npcIndex, GameTask task) {
    var worker = _npcs[npcIndex];
    final cleanRecipeId = (task.recipeId ?? '').split(':').first;
    final activity = ScienceService.getActivityById(cleanRecipeId);

    if (activity != null) {
      // 1. Handle Projected Science Activity (Dissection, Vivisection, etc.)
      bool hasAll = true;
      final roomIndex = _rooms.indexWhere((r) => r.id == task.targetId);
      final roomInv = roomIndex != -1
          ? _rooms[roomIndex].inventory
          : <GameItem>[];

      for (var entry in activity.ingredients.entries) {
        num avail = 0;
        final key = entry.key;

        bool matches(String type) {
          if (type == key) return true;
          if (key == 'meat' &&
              (type.startsWith('meat_') || type.endsWith('_specimen'))) {
            return true;
          }
          if (key == 'specimen' && type.endsWith('_specimen')) {
            return true;
          }
          return false;
        }

        avail += inventory
            .where((i) => matches(i.type))
            .fold<num>(0, (sum, i) => sum + i.quantity);
        avail += roomInv
            .where((i) => matches(i.type))
            .fold<num>(0, (sum, i) => sum + i.quantity);
        avail += worker.inventory
            .where((i) => matches(i.type))
            .fold<num>(0, (sum, i) => sum + i.quantity);
        avail += (resources[key] ?? 0);

        if (avail < entry.value) {
          hasAll = false;
        }
      }

      if (hasAll) {
        // Deduct ingredients effectively
        for (var entry in activity.ingredients.entries) {
          num remaining = entry.value;
          final key = entry.key;

          bool matches(String type) {
            if (type == key) {
              return true;
            }
            if (key == 'meat' &&
                (type.startsWith('meat_') || type.endsWith('_specimen'))) {
              return true;
            }
            if (key == 'specimen' && type.endsWith('_specimen')) {
              return true;
            }
            return false;
          }

          // Deduct from worker first
          final List<GameItem> updatedWorkerInv = List.from(worker.inventory);
          for (int i = 0; i < updatedWorkerInv.length && remaining > 0; i++) {
            if (matches(updatedWorkerInv[i].type)) {
              num toTake = min(updatedWorkerInv[i].quantity, remaining);
              updatedWorkerInv[i] = updatedWorkerInv[i].copyWith(
                quantity: (updatedWorkerInv[i].quantity - toTake).toInt(),
              );
              remaining -= toTake;
            }
          }
          worker = worker.copyWith(
            inventory: updatedWorkerInv.where((i) => i.quantity > 0).toList(),
          );

          // Deduct from room
          if (remaining > 0 && roomIndex != -1) {
            final List<GameItem> updatedRoomInv = List.from(
              _rooms[roomIndex].inventory,
            );
            for (int i = 0; i < updatedRoomInv.length && remaining > 0; i++) {
              if (matches(updatedRoomInv[i].type)) {
                num toTake = min(updatedRoomInv[i].quantity, remaining);
                updatedRoomInv[i] = updatedRoomInv[i].copyWith(
                  quantity: (updatedRoomInv[i].quantity - toTake).toInt(),
                );
                remaining -= toTake;
              }
            }
            _rooms[roomIndex] = _rooms[roomIndex].copyWith(
              inventory: updatedRoomInv.where((i) => i.quantity > 0).toList(),
            );
          }

          // Deduct from global inventory (stored in rooms)
          if (remaining > 0) {
            for (int rIdx = 0; rIdx < _rooms.length && remaining > 0; rIdx++) {
              final room = _rooms[rIdx];
              final List<GameItem> updatedRoomInv = List.from(room.inventory);
              bool changed = false;

              for (
                int i = updatedRoomInv.length - 1;
                i >= 0 && remaining > 0;
                i--
              ) {
                if (matches(updatedRoomInv[i].type)) {
                  num toTake = min(updatedRoomInv[i].quantity, remaining);
                  num newQty = updatedRoomInv[i].quantity - toTake;
                  if (newQty <= 0) {
                    updatedRoomInv.removeAt(i);
                  } else {
                    updatedRoomInv[i] = updatedRoomInv[i].copyWith(
                      quantity: newQty.toInt(),
                    );
                  }
                  remaining -= toTake;
                  changed = true;
                }
              }

              if (changed) {
                _rooms[rIdx] = room.copyWith(
                  inventory: updatedRoomInv
                      .where((i) => i.quantity > 0)
                      .toList(),
                );
              }
            }
          }

          // Deduct from resources
          if (remaining > 0) {
            updateResource(key, -(remaining.toInt()));
          }
        }

        // Apply outcomes
        double corruption = activity.moralCost;
        // The triggers are called after worker is saved back to _npcs list at the end of this if(hasAll) block or method

        // Generate knowledge item
        final noteCount =
            (Random().nextInt(15) +
            (activity.type == TaskType.vivisection ? 5 : 1));

        String itemType = 'research_notes';
        String itemName = '${activity.name} Notes';
        String discipline = activity.discipline;

        if (discipline == 'General') {
          const disciplines = [
            'Anatomy',
            'Zoology',
            'Medicine',
            'Chemistry',
            'Psychology',
          ];
          discipline = disciplines[Random().nextInt(disciplines.length)];
        }

        if (activity.id == 'generic_research') {
          itemType = 'research_book';
          itemName = 'Research Volume ($discipline)';
        }

        final notes = GameItem.create(
          name: itemName,
          type: itemType,
          category: ItemCategory.knowledge,
          quantity: 1,
          metadata: {'discipline': discipline, 'pages': noteCount},
        );

        // Place in room (Library for research, current room otherwise)
        int targetRoomIndex = roomIndex;
        if (activity.id == 'generic_research') {
          final libIdx = _rooms.indexWhere((r) => r.type == RoomType.library);
          if (libIdx != -1) targetRoomIndex = libIdx;
        }

        if (targetRoomIndex != -1) {
          final List<GameItem> targetRoomInv = List.from(
            _rooms[targetRoomIndex].inventory,
          );
          targetRoomInv.add(notes);
          _rooms[targetRoomIndex] = _rooms[targetRoomIndex].copyWith(
            inventory: targetRoomInv,
          );
        } else {
          _addPhysicalItem(notes); // Fallback
        }

        // Dissection/Vivisection meat yield
        if (activity.type == TaskType.dissect ||
            activity.type == TaskType.vivisection) {
          final meat = GameItem.create(
            name: 'Raw Protein',
            type: 'meat_generic',
            category: ItemCategory.food,
            quantity: 2,
          );
          _addPhysicalItem(meat);
        }

        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] ${worker.name} completed ${activity.name}. ${activity.outcomeDescription}",
        );

        _researchQueue.remove(activity.id);
        _researchQueue.remove('activity:${activity.id}');

        // PERSIST worker before triggers
        final taskKey = activity.type.name;
        _customTaskCounts[taskKey] = (_customTaskCounts[taskKey] ?? 0) + 1;
        if (activity.id == 'generic_research') {
          _customTaskCounts['study'] = (_customTaskCounts['study'] ?? 0) + 1;
        }
        _npcs[npcIndex] = worker;

        if (corruption > 0) {
          triggerGuilt(worker.id, source: activity.name);
          if (corruption >= 0.4) {
            triggerInsanity(
              worker.id,
              corruption >= 0.5 ? 'severe_temporary' : 'mild',
            );
          }
          worker = _npcs[npcIndex];
        }
      } else {
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] ${worker.name} failed ${activity.name}: Insufficient materials.",
        );
      }
    } else if (task.recipeId != null) {
      // 2. Handle Document Research / Item Study
      final itemId = task.recipeId!;

      // Check worker inventory first (since they might have gathered it)
      int workerItemIndex = worker.inventory.indexWhere((i) => i.id == itemId);
      int globalItemIndex = inventory.indexWhere((i) => i.id == itemId);

      GameItem? itemToStudy;
      if (workerItemIndex != -1) {
        itemToStudy = worker.inventory[workerItemIndex];
        final List<GameItem> newInv = List.from(worker.inventory);
        newInv.removeAt(workerItemIndex);
        worker = worker.copyWith(inventory: newInv);
        _npcs[npcIndex] = worker;
      } else if (globalItemIndex != -1) {
        itemToStudy = inventory[globalItemIndex];
        for (int rIdx = 0; rIdx < _rooms.length; rIdx++) {
          final room = _rooms[rIdx];
          final idx = room.inventory.indexWhere((i) => i.id == itemId);
          if (idx != -1) {
            final List<GameItem> updatedRoomInv = List.from(room.inventory);
            updatedRoomInv.removeAt(idx);
            _rooms[rIdx] = room.copyWith(inventory: updatedRoomInv);
            break;
          }
        }
      }

      if (itemToStudy != null) {
        _researchQueue.remove(itemId);
        _researchQueue.remove('activity:$itemId');

        int totalPages = itemToStudy.metadata['pages'] ?? 10;
        int notesGenerated =
            (totalPages * (0.25 + Random().nextDouble() * 0.25)).ceil();

        final study = GameItem.create(
          name: '${itemToStudy.name} Analysis',
          type: 'research_study',
          category: ItemCategory.knowledge,
          metadata: {
            'discipline': itemToStudy.metadata['discipline'] ?? 'Anatomy',
            'source': itemToStudy.name,
            'pages': notesGenerated,
          },
        );
        _addPhysicalItem(study);

        // Move analysis to room inventory immediately
        final roomIndex = _rooms.indexWhere((r) => r.id == task.targetId);
        if (roomIndex != -1) {
          final List<GameItem> roomInv = List.from(_rooms[roomIndex].inventory);
          roomInv.add(study);
          _rooms[roomIndex] = _rooms[roomIndex].copyWith(inventory: roomInv);
          inventory.removeLast();
        }

        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] ${worker.name} finished studying ${itemToStudy.name}, producing an analysis.",
        );
      }
    } else if (task.type == TaskType.research) {
      // 3. Fallback: General Research / Synthetic Insight
      final disciplines = [
        "Anatomy",
        "Chemistry",
        "Botany",
        "Physics",
        "Theology",
      ];
      final discipline = disciplines[Random().nextInt(disciplines.length)];
      final points = (Random().nextInt(4) + 12); // 12-15

      final notes = GameItem.create(
        name: 'Synthetic Insight ($discipline)',
        type: 'research_notes',
        category: ItemCategory.knowledge,
        quantity: points,
        metadata: {'discipline': discipline, 'pages': points * 2},
      );

      // Add to room inventory immediately
      final roomIndex = _rooms.indexWhere((r) => r.id == task.targetId);
      if (roomIndex != -1) {
        final List<GameItem> roomInv = List.from(_rooms[roomIndex].inventory);
        roomInv.add(notes);
        _rooms[roomIndex] = _rooms[roomIndex].copyWith(inventory: roomInv);
      } else {
        _addPhysicalItem(notes);
      }

      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] ${worker.name} synthesized new insights, advancing knowledge in $discipline.",
      );
    }
    _npcs[npcIndex] = worker;
  }

  Map<String, num> _getMissingIngredientsForActivity(
    int npcIndex,
    ScienceActivity activity,
  ) {
    final Map<String, num> missing = {};
    final npc = _npcs[npcIndex];

    for (var entry in activity.ingredients.entries) {
      final key = entry.key;
      final needed = entry.value;

      num avail = npc.inventory
          .where((i) {
            if (key == 'meat') {
              return i.type.contains('meat') ||
                  i.category == ItemCategory.specimen;
            }
            if (key == 'specimen') {
              return i.category == ItemCategory.specimen;
            }
            if (key == 'rat_specimen') {
              return i.type == 'rat' ||
                  i.type == 'bat' ||
                  i.type == 'chicken' ||
                  i.type == 'rat_specimen';
            }
            return i.type == key;
          })
          .fold(0, (sum, i) => sum + i.quantity);

      if (avail < needed) {
        missing[key] = needed - avail;
      }
    }
    return missing;
  }

  void applyStatusEffect(String npcId, StatusEffect effect) {
    final index = _npcs.indexWhere((n) => n.id == npcId);
    if (index == -1) return;

    var npc = _npcs[index];
    final newEffects = List<StatusEffect>.from(npc.statusEffects)..add(effect);
    final newRecords = List<String>.from(npc.records)
      ..add(
        "[${_currentDate.formattedDate}] ${effect.name}: ${effect.description}",
      );

    _npcs[index] = npc.copyWith(statusEffects: newEffects, records: newRecords);
    notifyListeners();
  }

  void triggerGuilt(String npcId, {String? source}) {
    final index = _npcs.indexWhere((n) => n.id == npcId);
    if (index == -1) return;

    final npc = _npcs[index];
    final judgment = npc.effectiveStats['judgment'] ?? 5;

    // Threshold: Below 2 judgment (20% equivalent on 0-10 scale), the character is too cold to feel guilt
    if (judgment < 2) return;

    final penalty = (judgment / 10).round().clamp(1, 10);

    final guiltEffect = StatusEffect(
      id: 'guilt_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Burden of Guilt',
      type: StatusEffectType.guilt,
      description:
          'The weight of recent actions affects temperament and judgment.',
      startTimestamp: _currentDate.totalMinutes,
      durationMinutes: 1440 * 3, // 3 days
      attributeModifiers: {
        'temperament': -penalty,
        'judgment': -(penalty ~/ 2),
      },
      metadata: {'source': source ?? 'Unknown'},
    );

    applyStatusEffect(npcId, guiltEffect);

    // Re-fetch and reduce satisfaction directly when guilt is triggered
    final updatedNpc = _npcs[index];
    _npcs[index] = updatedNpc.copyWith(
      satisfaction: (updatedNpc.satisfaction - 15.0).clamp(0.0, 100.0),
    );
  }

  void triggerInsanity(String npcId, String intensity) {
    final index = _npcs.indexWhere((n) => n.id == npcId);
    if (index == -1) return;

    int percMod = 0;
    int judMod = 0;
    int intMod = 0;
    int duration = 60;
    String name = 'Nervous Tremors';

    switch (intensity) {
      case 'mild':
        percMod = -5;
        duration = 120; // 2 hours
        break;
      case 'severe_temporary':
        percMod = -20;
        judMod = -10;
        duration = 30; // 30 mins
        name = 'Acute Psychosis';
        break;
      case 'permanent':
        percMod = -10;
        judMod = -10;
        intMod = -5;
        duration = 0; // Handled by isPermanent
        name = 'Fractured Mind';
        break;
    }

    final insanityEffect = StatusEffect(
      id: 'insanity_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: StatusEffectType.insanity,
      description:
          'Exposure to forbidden knowledge or horrors has damaged the mind.',
      startTimestamp: _currentDate.totalMinutes,
      durationMinutes: duration > 0 ? duration : null,
      isPermanent: duration == 0,
      attributeModifiers: {
        'perception': percMod,
        'judgment': judMod,
        'intellect': intMod,
      },
    );

    applyStatusEffect(npcId, insanityEffect);
  }

  void triggerDisease(String npcId, String diseaseName) {
    int duration = 1440 * 2; // 2 days
    int endMod = -10;
    int strMod = -10;

    final diseaseEffect = StatusEffect(
      id: 'disease_${diseaseName}_${DateTime.now().millisecondsSinceEpoch}',
      name: diseaseName,
      type: StatusEffectType.disease,
      description:
          'A foul ailment is sapping the character\'s strength and endurance.',
      startTimestamp: _currentDate.totalMinutes,
      durationMinutes: duration,
      attributeModifiers: {'strength': strMod, 'endurance': endMod},
      metadata: {'symptom': 'fever'},
    );

    applyStatusEffect(npcId, diseaseEffect);
  }

  void triggerLove(String npcId, String targetNpcId) {
    final targetIndex = _npcs.indexWhere((n) => n.id == targetNpcId);
    if (targetIndex == -1) return;
    final targetName = _npcs[targetIndex].name;

    final loveEffect = StatusEffect(
      id: 'love_${targetNpcId}_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Enamored with $targetName',
      type: StatusEffectType.love,
      description:
          'The character is captivated by $targetName, affecting their focus and temperament.',
      startTimestamp: _currentDate.totalMinutes,
      isPermanent: true,
      attributeModifiers: {'temperament': 10, 'judgment': -5},
      metadata: {'targetId': targetNpcId},
    );

    applyStatusEffect(npcId, loveEffect);
  }

  void triggerHate(String npcId, String targetNpcId) {
    final targetIndex = _npcs.indexWhere((n) => n.id == targetNpcId);
    if (targetIndex == -1) return;
    final targetName = _npcs[targetIndex].name;

    final hateEffect = StatusEffect(
      id: 'hate_${targetNpcId}_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Resentment: $targetName',
      type: StatusEffectType.hate,
      description:
          'A deep-seated hatred for $targetName bubbles beneath the surface.',
      startTimestamp: _currentDate.totalMinutes,
      isPermanent: true,
      attributeModifiers: {'temperament': -10, 'judgment': -5},
      metadata: {'targetId': targetNpcId},
    );

    applyStatusEffect(npcId, hateEffect);
  }

  void _triggerManorFire(String roomId) {
    if (_crises.any(
      (c) => c.type == ManorCrisisType.fire && c.roomId == roomId,
    )) {
      return;
    }

    final crisis = ManorCrisis(
      type: ManorCrisisType.fire,
      roomId: roomId,
      severity: 0.2, // Starts small // User wanted fires
      discoveryDate: _currentDate.toDateTime(),
    );

    _crises.add(crisis);
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] WARNING: FIRE detected in ${roomId.toUpperCase().replaceAll('_', ' ')}!",
    );
    notifyListeners();
  }

  void triggerJoy(String npcId, String cause) {
    final joyEffect = StatusEffect(
      id: 'joy_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Overjoyed',
      type: StatusEffectType.joy,
      description:
          'A sense of great accomplishment ($cause) uplifts the spirit.',
      startTimestamp: _currentDate.totalMinutes,
      durationMinutes: 1440, // 1 day
      attributeModifiers: {'temperament': 15, 'endurance': 5, 'strength': 5},
    );

    applyStatusEffect(npcId, joyEffect);
  }

  void triggerSadness(String npcId, String cause) {
    final sadnessEffect = StatusEffect(
      id: 'sadness_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Deep Sadness',
      type: StatusEffectType.sadness,
      description: 'A heavy sorrow ($cause) weighs on the mind and body.',
      startTimestamp: _currentDate.totalMinutes,
      durationMinutes: 1440 * 2, // 2 days
      attributeModifiers: {'temperament': -15, 'endurance': -5, 'strength': -5},
    );

    applyStatusEffect(npcId, sadnessEffect);
  }

  void _processStatusEffectsTick() {
    bool changed = false;
    for (int i = 0; i < _npcs.length; i++) {
      final npc = _npcs[i];
      if (npc.statusEffects.isEmpty) continue;

      final currentMinutes = _currentDate.totalMinutes;
      final activeEffects = npc.statusEffects
          .where((e) => !e.isExpired(currentMinutes))
          .toList();

      if (activeEffects.length != npc.statusEffects.length) {
        _npcs[i] = npc.copyWith(statusEffects: activeEffects);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void _handleSurgicalCombination(int workerIndex, GameTask task) {
    // Logic for combining Rat + Bat -> Winged Rat
    final roomId = task.targetId;
    if (roomId == null) return;

    final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex == -1) return;

    final roomInv = List<GameItem>.from(_rooms[roomIndex].inventory);
    final ratIdx = roomInv.indexWhere((i) => i.type == 'rat_specimen');
    final batIdx = roomInv.indexWhere((i) => i.type == 'bat_specimen');

    if (ratIdx != -1 && batIdx != -1) {
      // Success! Create Winged Rat
      final worker = _npcs[workerIndex];

      // Remove specimens (careful with indices)
      roomInv.removeAt(max(ratIdx, batIdx));
      roomInv.removeAt(min(ratIdx, batIdx));

      final wingedRat = GameItem.create(
        name: 'Winged Rat',
        type: 'winged_rat_specimen',
        category: ItemCategory.specimen,
        quantity: 1,
      );
      roomInv.add(wingedRat);

      _rooms[roomIndex] = _rooms[roomIndex].copyWith(inventory: roomInv);
      _lastAnnouncement =
          "${worker.name} successfully combined the specimens into a Winged Rat!";
      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] SURGERY SUCCESS: Winged Rat created.",
      );
    } else {
      _lastAnnouncement =
          "The combination failed: Missing required specimens in the room.";
    }
    notifyListeners();
  }

  void _consolidateUndeadUnits() {
    // Merge individual reanimated rats/bats/chickens into swarms
    final typesToMerge = {'Rat': 4, 'Bat': 3, 'Chicken': 5, 'Fox': 1};

    bool changed = false;
    for (var entry in typesToMerge.entries) {
      final type = entry.key;
      final threshold = entry.value;

      final candidates = _npcs
          .where(
            (n) =>
                n.specimenType == type &&
                n.status == NPCStatus.zombie &&
                !n.name.contains('Swarm') &&
                !n.name.contains('Unit'),
          )
          .toList();

      if (candidates.length >= threshold) {
        // Create Swarm Unit
        final idsToRemove = candidates
            .take(threshold)
            .map((n) => n.id)
            .toList();
        _npcs.removeWhere((n) => idsToRemove.contains(n.id));

        final name = threshold > 1 ? "Undead $type Swarm" : "Undead $type Unit";
        final swarm = NPC(
          id: const Uuid().v4(),
          name: name,
          role: "Combat Unit",
          age: 0,
          gender: "None",
          nationality: "Lab",
          religion: "None",
          specimenType: type,
          isPlayer: false,
          isResident: true,
          status: NPCStatus.zombie,
          disposition: NPCDisposition.voluntary,
          currentRoomId: 'laboratory',
          stats: {'strength': threshold * 5, 'willpower': 100, 'intellect': 5},
          appearance: candidates.first.appearance,
          bodyParts: [
            BodyPart(type: BodyPartType.head, health: 100, maxHealth: 100),
            BodyPart(type: BodyPartType.torso, health: 100, maxHealth: 100),
          ],
          combatStats: CombatStats(
            health: threshold * 20.0,
            maxHealth: threshold * 20.0,
            attack: threshold * 4.0,
            defense: threshold * 2.0,
            speed: 1.0,
            movement: 1.0,
            distance: 1.0,
            accuracy: 0.8,
            cost: threshold,
          ),
          inventory: [],
          schedule: NPCSchedule.visitor(),
          diet: NPCDiet.defaultDiet(),
        );

        _npcs.add(swarm);
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] SCIENCE: $threshold reanimated ${type}s have formed a lethal Swarm!",
        );
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  NPCStatus _determineStatus(NPC npc, GameTask? task) {
    if (npc.status == NPCStatus.fainted || npc.status == NPCStatus.broken) {
      return NPCStatus.sleeping;
    }
    if (task == null) return NPCStatus.idle;

    switch (task.type) {
      case TaskType.rest:
        return (npc.currentRoomId == task.targetId)
            ? NPCStatus.sleeping
            : NPCStatus.idle;
      case TaskType.idle:
        return NPCStatus.idle;
      case TaskType.eat:
        return (npc.currentRoomId == task.targetId)
            ? NPCStatus.working
            : NPCStatus.idle;
      default:
        // Working if at target, otherwise idle (traveling to work)
        return (npc.currentRoomId == task.targetId)
            ? NPCStatus.working
            : NPCStatus.idle;
    }
  }

  double getRequiredXP(int currentLevel) {
    switch (currentLevel) {
      case 0:
        return 400.0;
      case 1:
        return 400.0;
      case 2:
        return 700.0;
      case 3:
        return 1300.0;
      case 4:
        return 2500.0;
      case 5:
        return 4700.0;
      case 6:
        return 9000.0;
      case 7:
        return 17000.0;
      case 8:
        return 32000.0;
      case 9:
        return 60000.0;
      case 10:
        return 120000.0;
      default:
        return double.infinity;
    }
  }

  void _addStatExperience(int npcIndex, String stat, double amount) {
    if (npcIndex < 0 || npcIndex >= _npcs.length) return;
    int intAmount = amount.floor();
    if (intAmount < 1) return;

    var npc = _npcs[npcIndex];
    int currentLevel = npc.stats[stat] ?? 1;
    if (currentLevel >= 10) return;

    final statExperience = Map<String, double>.from(npc.statExperience);
    double xp = ((statExperience[stat] ?? 0.0) + intAmount).floorToDouble();

    double required = getRequiredXP(currentLevel);
    if (xp >= required) {
      xp -= required;
      final newStats = Map<String, int>.from(npc.stats);
      newStats[stat] = currentLevel + 1;

      _lastAnnouncement =
          "${npc.name} has improved their $stat to ${currentLevel + 1}!";
      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] PROGRESSION: $_lastAnnouncement",
      );

      _npcs[npcIndex] = npc.copyWith(
        stats: newStats,
        statExperience: statExperience..[stat] = xp,
      );
    } else {
      _npcs[npcIndex] = npc.copyWith(
        statExperience: statExperience..[stat] = xp,
      );
    }
  }

  void _addProficiencyExperience(
    int npcIndex,
    String proficiency,
    double amount,
  ) {
    if (npcIndex < 0 || npcIndex >= _npcs.length) return;
    int intAmount = amount.floor();
    if (intAmount < 1) return;

    var npc = _npcs[npcIndex];
    String levelKey = 'proficiency_level_$proficiency';
    int currentLevel = npc.metadata[levelKey] as int? ?? 0;
    if (currentLevel >= 10) return;

    final proficiencies = Map<String, double>.from(npc.proficiencies);
    double xp = ((proficiencies[proficiency] ?? 0.0) + intAmount).floorToDouble();

    double required = getRequiredXP(currentLevel);
    if (xp >= required) {
      xp -= required;
      currentLevel += 1;

      final newMetadata = Map<String, dynamic>.from(npc.metadata);
      newMetadata[levelKey] = currentLevel;

      String title = "Novice $proficiency";
      if (currentLevel >= 8) {
        title = "Expert $proficiency";
      } else if (currentLevel >= 5) {
        title = "Professional $proficiency";
      } else if (currentLevel >= 2) {
        title = "Adept $proficiency";
      }
      _lastAnnouncement = "${npc.name} has achieved the rank of $title!";
      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] PROFICIENCY: $_lastAnnouncement",
      );

      final traits = List<NPCTrait>.from(npc.traits);
      traits.removeWhere((t) => t.id.startsWith("proficiency_$proficiency"));
      traits.add(
        NPCTrait(
          id: "proficiency_${proficiency}_$currentLevel",
          name: title,
          group: "skill",
        ),
      );

      _npcs[npcIndex] = npc.copyWith(
        metadata: newMetadata,
        proficiencies: proficiencies..[proficiency] = xp,
        traits: traits,
      );
    } else {
      _npcs[npcIndex] = npc.copyWith(
        proficiencies: proficiencies..[proficiency] = xp,
      );
    }
  }

  void proposeContractModification(
    String contractId,
    Map<String, dynamic> newTerms, {
    bool isFavorable = true,
  }) {
    final idx = _contracts.indexWhere((c) => c.id == contractId);
    if (idx != -1) {
      final contract = _contracts[idx];
      _contracts[idx] = contract.copyWith(terms: newTerms);

      final npcIdx = _npcs.indexWhere((n) => n.id == contract.npcId);
      if (npcIdx != -1) {
        final npc = _npcs[npcIdx];
        final rel = npc.relationships['player'] ?? Relationship();
        final delta = isFavorable ? 0.5 : -0.5;
        final newRel = rel.copyWith(
          admiration: rel.admiration + delta,
          respect: rel.respect + (isFavorable ? 0.2 : -0.2),
          fear: rel.fear + (isFavorable ? -0.2 : 0.5),
        );
        final newRelationships = Map<String, Relationship>.from(
          npc.relationships,
        );
        newRelationships['player'] = newRel;
        _npcs[npcIdx] = npc.copyWith(relationships: newRelationships);
      }
      notifyListeners();
    }
  }

  void terminateContract(String contractId) {
    final idx = _contracts.indexWhere((c) => c.id == contractId);
    if (idx != -1) {
      final contract = _contracts[idx];
      _contracts[idx] = contract.copyWith(isActive: false);

      final npcIdx = _npcs.indexWhere((n) => n.id == contract.npcId);
      if (npcIdx != -1) {
        final npc = _npcs[npcIdx];
        final rel = npc.relationships['player'] ?? Relationship();
        final newRel = rel.copyWith(
          admiration: rel.admiration - 1.0,
          respect: rel.respect - 1.0,
        );
        final newRelationships = Map<String, Relationship>.from(
          npc.relationships,
        );
        newRelationships['player'] = newRel;
        _npcs[npcIdx] = npc.copyWith(relationships: newRelationships);
      }
      notifyListeners();
    }
  }

  void _processNuisanceRelativeDrain() {
    int count = 0;
    for (var npc in _npcs) {
      if (npc.role == 'Nuisance House Guest') {
        count++;
      }
    }
    if (count > 0) {
      final totalFoodDrain = count * 2;
      final totalFundsDrain = count * 5;
      updateResource('funds', -totalFundsDrain);
      _lastAnnouncement =
          "NUISANCE DRAIN: House guests consumed $totalFoodDrain food and drained $totalFundsDrain CHF from estate funds.";
      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] EXPENSE: $_lastAnnouncement",
      );
      notifyListeners();
    }
  }

  void _processLineageQuests() {
    if (Random().nextDouble() > 0.10) return;

    final random = Random();
    final eventType = random.nextInt(5);

    final residents = _npcs
        .where((n) => n.isResident && n.status != NPCStatus.dead)
        .toList();
    if (residents.isEmpty) return;
    final subject = residents[random.nextInt(residents.length)];

    switch (eventType) {
      case 0:
        final payout = 100 + random.nextInt(150);
        final fee = 25 + random.nextInt(25);
        final contractId =
            "inheritance_${subject.id}_${_currentDate.totalMinutes}";

        final contract = Contract(
          id: contractId,
          npcId: subject.id,
          type: ContractType.deliverable,
          description:
              "Inheritance Settlement for ${subject.name}: Pay $fee CHF processing fee to claim a payout of $payout CHF.",
          terms: {'fee': fee, 'payout': payout, 'isInheritance': true},
          isActive: true,
        );
        _contracts.add(contract);

        _lastAnnouncement =
            "INHERITANCE: ${subject.name}'s family lawyer sent notice of unexpected inheritance! Settlement contract added.";
        break;

      case 1:
        final relativeNames = [
          'Cousin Pierre',
          'Half-brother Karl',
          'Aunt Agathe',
          'Uncle Jean',
        ];
        final name = relativeNames[random.nextInt(relativeNames.length)];
        final relative = NPC(
          id: "nuisance_${subject.id}_${_currentDate.totalMinutes}",
          name: name,
          role: 'Nuisance House Guest',
          age: subject.age + (random.nextBool() ? 5 : -5),
          gender: random.nextBool() ? 'Male' : 'Female',
          specimenType: 'Human',
          bodyParts: const [],
          schedule: NPCSchedule.visitor(),
          diet: NPCDiet.defaultDiet(),
          appearance: NPCAppearance.random(),
          currentRoomId: 'dining_hall',
          targetRoomId: 'dining_hall',
          movementProgress: 1.0,
          status: NPCStatus.idle,
          isResident: false,
          metadata: {
            'guestType': 'nuisance',
            'hostId': subject.id,
            'drainFood': 2,
            'drainFunds': 5,
          },
        );
        _npcs.add(relative);

        final contractId = "buyout_${relative.id}";
        final buyoutFee = 80 + random.nextInt(40);
        final contract = Contract(
          id: contractId,
          npcId: relative.id,
          type: ContractType.service,
          description:
              "Pay off ${relative.name} with $buyoutFee CHF to leave the quarters.",
          terms: {
            'fee': buyoutFee,
            'isNuisanceBuyout': true,
            'relativeId': relative.id,
          },
          isActive: true,
        );
        _contracts.add(contract);

        _lastAnnouncement =
            "NUISANCE GUEST: $name, an unexpected spurious relative of ${subject.name}, has arrived to stay uninvited!";
        break;

      case 2:
        final subjectClass =
            subject.biography?.characterClass ?? subject.background;
        if (subjectClass != 'Noble' && subjectClass != 'Merchant') return;

        final suitorNames = subject.gender == 'Male'
            ? ['Lady Beatrice', 'Countess Clara']
            : ['Baron Henri', 'Viscount Louis'];
        final name = suitorNames[random.nextInt(suitorNames.length)];

        final suitor = NPC(
          id: "suitor_${subject.id}_${_currentDate.totalMinutes}",
          name: name,
          role: 'Gilded Suitor',
          age: subject.age + (random.nextBool() ? 2 : -2),
          gender: subject.gender == 'Male' ? 'Female' : 'Male',
          specimenType: 'Human',
          bodyParts: const [],
          schedule: NPCSchedule.visitor(),
          diet: NPCDiet.defaultDiet(),
          appearance: NPCAppearance.random(),
          currentRoomId: 'entryway',
          targetRoomId: 'entryway',
          movementProgress: 1.0,
          status: NPCStatus.idle,
          isResident: false,
          metadata: {'guestType': 'suitor', 'targetId': subject.id},
        );
        _npcs.add(suitor);

        final contractId = "dowry_${suitor.id}";
        final dowry = 120;
        final contract = Contract(
          id: contractId,
          npcId: suitor.id,
          type: ContractType.service,
          description:
              "Allow ${suitor.name} to marry ${subject.name} in exchange for a dowry of $dowry CHF.",
          terms: {
            'dowry': dowry,
            'isSuitorDowry': true,
            'suitorId': suitor.id,
            'targetId': subject.id,
          },
          isActive: true,
        );
        _contracts.add(contract);

        _lastAnnouncement =
            "SUITOR ARRIVAL: $name has arrived seeking to court ${subject.name} for their lineage and estate!";
        break;

      case 3:
        final subjectClass =
            subject.biography?.characterClass ?? subject.background;
        final isSpurious =
            subject.biography?.parentsMaritalStatus == 'spurious' ||
            subject.biography?.parentsMaritalStatus == 'out of wedlock';
        if (subjectClass == 'Noble' && isSpurious) {
          updateResource('funds', -50);
          final subjectIdx = _npcs.indexWhere((n) => n.id == subject.id);
          if (subjectIdx != -1) {
            _npcs[subjectIdx] = _npcs[subjectIdx].copyWith(
              satisfaction: (_npcs[subjectIdx].satisfaction - 35.0).clamp(
                0.0,
                100.0,
              ),
              currentThought:
                  "Exposed as spurious! The public shame is unbearable...",
            );
          }
          _lastAnnouncement =
              "EXPOSED: An investigator proved that ${subject.name}'s nobility claim is spurious! Fined 50 CHF.";
        } else {
          updateResource('funds', -30);
          _lastAnnouncement =
              "TAX AUDIT: Generational tax audit on ${subject.name}'s family estate required direct payment of 30 CHF.";
        }
        break;

      case 4:
        final parentProf = subject.biography?.fatherProfession ?? 'Officer';
        _lastAnnouncement =
            "FAMILY FEUD: Rivals holding generations of enmity towards ${subject.name}'s late father ($parentProf) have launched a small attack at the gates!";

        final bandit = NPC(
          id: "feud_bandit_${_currentDate.totalMinutes}",
          name: "Guild Rival ${random.nextInt(100)}",
          role: 'Rival Attacker',
          age: 30,
          gender: 'Male',
          specimenType: 'Human',
          bodyParts: const [],
          schedule: NPCSchedule.visitor(),
          diet: NPCDiet.defaultDiet(),
          appearance: NPCAppearance.random(),
          currentRoomId: 'toolshed',
          targetRoomId: 'toolshed',
          movementProgress: 1.0,
          status: NPCStatus.idle,
          isResident: false,
          combatStats: const CombatStats(
            attack: 15,
            health: 80,
            maxHealth: 80,
            speed: 1.2,
            movement: 1.0,
            distance: 1.0,
            cost: 2,
          ),
        );
        _npcs.add(bandit);
        break;
    }

    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] PLOT EVENT: $_lastAnnouncement",
    );
    if (_announcementHistory.length > 50) _announcementHistory.removeLast();
    notifyListeners();
  }

  bool executeContract(String contractId) {
    final idx = _contracts.indexWhere((c) => c.id == contractId);
    if (idx == -1) return false;
    final contract = _contracts[idx];
    if (!contract.isActive) return false;

    final terms = contract.terms;
    if (terms.containsKey('isInheritance') && terms['isInheritance'] == true) {
      final fee = terms['fee'] as int;
      final payout = terms['payout'] as int;
      if (resources['funds']! < fee) {
        _lastAnnouncement =
            "Insufficient funds to process inheritance settlement.";
        notifyListeners();
        return false;
      }
      updateResource('funds', -fee);
      updateResource('funds', payout);
      _contracts[idx] = contract.copyWith(isActive: false);
      _lastAnnouncement =
          "Inheritance settled successfully! Paid $fee CHF, received $payout CHF.";
    } else if (terms.containsKey('isNuisanceBuyout') &&
        terms['isNuisanceBuyout'] == true) {
      final fee = terms['fee'] as int;
      final relativeId = terms['relativeId'] as String;
      if (resources['funds']! < fee) {
        _lastAnnouncement = "Insufficient funds to buy out relative.";
        notifyListeners();
        return false;
      }
      updateResource('funds', -fee);
      _contracts[idx] = contract.copyWith(isActive: false);

      final relIdx = _npcs.indexWhere((n) => n.id == relativeId);
      if (relIdx != -1) {
        _npcs.removeAt(relIdx);
      }
      _lastAnnouncement = "Paid relative $fee to depart the estate quarters.";
    } else if (terms.containsKey('isSuitorDowry') &&
        terms['isSuitorDowry'] == true) {
      final dowry = terms['dowry'] as int;
      final suitorId = terms['suitorId'] as String;
      final targetId = terms['targetId'] as String;

      updateResource('funds', dowry);
      _contracts[idx] = contract.copyWith(isActive: false);

      final targetIdx = _npcs.indexWhere((n) => n.id == targetId);
      if (targetIdx != -1) {
        _npcs[targetIdx] = _npcs[targetIdx].copyWith(
          satisfaction: (_npcs[targetIdx].satisfaction - 30.0).clamp(
            0.0,
            100.0,
          ),
          currentThought: "Married off for dowry! What a humiliating deal...",
        );
      }

      final suitorIdx = _npcs.indexWhere((n) => n.id == suitorId);
      if (suitorIdx != -1) {
        _npcs.removeAt(suitorIdx);
      }
      _lastAnnouncement = "Accepted marriage alliance for $dowry CHF dowry.";
    } else {
      _contracts[idx] = contract.copyWith(isActive: false);
      _lastAnnouncement = "Contract executed successfully.";
    }

    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] SUCCESS: $_lastAnnouncement",
    );
    notifyListeners();
    return true;
  }

  // --- BUSINESS VENTURES SYSTEM ---
  void proposeBusiness(
    BusinessType type,
    String proposerId,
    String proposerName,
  ) {
    if (_activeBusinesses.any((b) => b.type == type && b.status != 'shutDown')) {
      return;
    }

    String name = "";
    List<String> assignmentsList = [];
    switch (type) {
      case BusinessType.bistro:
        name = "$proposerName's Manor Bistro";
        assignmentsList = [
          "Restore the Kitchen to functional status",
          "Stock the pantry with 5 meats and 5 vegetables",
          "Perform Kitchen Experimentations 3 times",
          "Discover 2 new recipes through experiments",
          "Hire a dedicated server or kitchen hand",
          "Serve 3 hungry diners in the Dining Room",
        ];
        break;
      case BusinessType.bakery:
        name = "$proposerName's Hearthside Bakery";
        assignmentsList = [
          "Restore the Kitchen to functional status",
          "Restore the Granary to store wheat",
          "Bake 10 loaves of artisanal bread",
          "Sell baked goods at the hamlet market",
        ];
        break;
      case BusinessType.pizzeria:
        name = "$proposerName's Piedmont Pizzeria";
        assignmentsList = [
          "Restore the Kitchen to functional status",
          "Obtain 10 salt and 10 tomatoes/sauce",
          "Manufacture a clay pizza oven in the workshop",
          "Bake 10 fresh Piedmontese pizzas",
        ];
        break;
      case BusinessType.cafe:
        name = "$proposerName's Viennese Cafe";
        assignmentsList = [
          "Restore the Kitchen to functional status",
          "Restore the Dining Room salon",
          "Acquire 10 sugar and 5 refined spirits",
          "Host a grand Viennese coffee reception",
        ];
        break;
      case BusinessType.opiateLab:
        name = "$proposerName's Opiate Laboratory";
        assignmentsList = [
          "Restore the Laboratory to functional status",
          "Plant at least 5 cannabis or crop plots",
          "Harvest 10 hemp fiber or cannabis buds",
          "Manufacture 5 highly refined chemical opiates",
        ];
        break;
      case BusinessType.lawPractice:
        name = "$proposerName's Law Chambers";
        assignmentsList = [
          "Send Alphonse to Geneva Graduate School of Law",
          "Restore the Manor Study room",
          "Acquire 3 old legal journals or treatises",
          "Complete witness intimidation / strategic lawsuit",
        ];
        break;
      case BusinessType.medicalPractice:
        name = "$proposerName's Medical Clinic";
        assignmentsList = [
          "Send Alphonse to Geneva Graduate School of Medicine",
          "Restore the Manor Operating Room",
          "Acquire 10 alchemical bandages or herbs",
          "Successfully complete a surgical operation on a patient",
        ];
        break;
      case BusinessType.theater:
        name = "$proposerName's Grand Theater";
        assignmentsList = [
          "Build or convert a manor wing into a Theater room",
          "Purchase three theatrical scripts from the curator",
          "Write an original script in the Study room",
          "Cast a Lead Actor from your resident roster",
          "Cast a Supporting Actor from your resident roster",
          "Assign crew members for lights and sounds",
          "Build a theatrical set in the Workshop (uses 20 wood)",
          "Schedule the show on the Manor Calendar",
          "Rehearse the production to standard",
          "Promote the play in the local Hamlet",
          "Host the highly anticipated Opening Night!",
        ];
        break;
    }

    final bus = ActiveBusiness(
      id: 'business_${const Uuid().v4()}',
      type: type,
      name: name,
      proposerId: proposerId,
      status: 'proposal',
      currentAssignmentIndex: 0,
      assignments: assignmentsList,
      holdings: [],
      agreements: [],
      employeeIds: [],
      logs: ["[${_currentDate.formattedTime}] Proposed by $proposerName."],
      ledger: [],
      metadata: {},
    );

    _activeBusinesses.add(bus);
    _lastAnnouncement =
        "PROPOSAL: $proposerName wants to open a ${type.displayName.toUpperCase()}!";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] VENTURE: $_lastAnnouncement",
    );
    notifyListeners();
  }

  void acceptBusinessProposal(String businessId) {
    final idx = _activeBusinesses.indexWhere((b) => b.id == businessId);
    if (idx == -1) return;
    final bus = _activeBusinesses[idx];

    _activeBusinesses[idx] = bus.copyWith(
      status: 'inProgress',
      logs: [
        ...bus.logs,
        "[${_currentDate.formattedTime}] Proposal accepted. Setup assignments initiated.",
      ],
    );

    _lastAnnouncement =
        "BUSINESS INITIATED: ${bus.name.toUpperCase()} SETUP IS UNDERWAY.";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] VENTURE: $_lastAnnouncement",
    );
    notifyListeners();
  }

  void fireBusinessProposer(String businessId) {
    final idx = _activeBusinesses.indexWhere((b) => b.id == businessId);
    if (idx == -1) return;
    final bus = _activeBusinesses[idx];

    dismissNpc(bus.proposerId);

    if (bus.status == 'inProgress') {
      _activeBusinesses[idx] = bus.copyWith(
        status: 'shutDown',
        logs: [
          ...bus.logs,
          "[${_currentDate.formattedTime}] Proposer was fired before setup. Assignments canceled.",
        ],
      );
      _lastAnnouncement =
          "VENTURE CANCELED: Proposer was fired before setup was complete.";
    } else {
      _activeBusinesses[idx] = bus.copyWith(
        employeeIds: List.from(bus.employeeIds)..remove(bus.proposerId),
        logs: [
          ...bus.logs,
          "[${_currentDate.formattedTime}] Original manager fired. The business remains active.",
        ],
      );
      _lastAnnouncement =
          "MANAGER FIRED: The business remains active under your direct oversight.";
    }

    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] VENTURE: $_lastAnnouncement",
    );
    notifyListeners();
  }

  void shutDownBusiness(String businessId) {
    final idx = _activeBusinesses.indexWhere((b) => b.id == businessId);
    if (idx == -1) return;
    final bus = _activeBusinesses[idx];

    for (var roomId in bus.holdings) {
      final rIdx = _rooms.indexWhere((r) => r.id == roomId);
      if (rIdx != -1) {
        _rooms[rIdx] = _rooms[rIdx].copyWith(type: RoomType.unused);
      }
    }

    _activeBusinesses[idx] = bus.copyWith(
      status: 'shutDown',
      holdings: [],
      employeeIds: [],
      logs: [
        ...bus.logs,
        "[${_currentDate.formattedTime}] Business permanently shut down and assets liquidated.",
      ],
    );

    _lastAnnouncement =
        "BUSINESS SHUT DOWN: ${bus.name.toUpperCase()} HAS BEEN CLOSED.";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] VENTURE: $_lastAnnouncement",
    );
    notifyListeners();
  }

  void advanceBusinessAssignment(String businessId) {
    final idx = _activeBusinesses.indexWhere((b) => b.id == businessId);
    if (idx == -1) return;
    final bus = _activeBusinesses[idx];

    final nextIndex = bus.currentAssignmentIndex + 1;
    if (nextIndex >= bus.assignments.length) {
      _activeBusinesses[idx] = bus.copyWith(
        currentAssignmentIndex: nextIndex,
        status: 'active',
        logs: [
          ...bus.logs,
          "[${_currentDate.formattedTime}] Assignment ${bus.assignments[bus.currentAssignmentIndex]} completed.",
          "[${_currentDate.formattedTime}] ALL SETUP ASSIGNMENTS COMPLETED! Business is now operational.",
        ],
        holdings: _getDefaultHoldingsForType(bus.type),
        agreements: _getDefaultAgreementsForType(bus.type),
        employeeIds: [bus.proposerId],
      );
      _lastAnnouncement =
          "VENTURE LAUNCHED: ${bus.name.toUpperCase()} IS NOW FULLY OPERATIONAL!";
    } else {
      _activeBusinesses[idx] = bus.copyWith(
        currentAssignmentIndex: nextIndex,
        logs: [
          ...bus.logs,
          "[${_currentDate.formattedTime}] Assignment completed: ${bus.assignments[bus.currentAssignmentIndex]}.",
        ],
      );
      _lastAnnouncement =
          "ASSIGNMENT COMPLETED: ${bus.assignments[bus.currentAssignmentIndex].toUpperCase()}";
    }

    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] VENTURE: $_lastAnnouncement",
    );
    notifyListeners();
  }

  List<String> _getDefaultHoldingsForType(BusinessType type) {
    switch (type) {
      case BusinessType.bistro:
      case BusinessType.bakery:
      case BusinessType.pizzeria:
      case BusinessType.cafe:
        return ['kitchen', 'dining_room'];
      case BusinessType.opiateLab:
        return ['laboratory'];
      case BusinessType.lawPractice:
        return ['study'];
      case BusinessType.medicalPractice:
        return ['operatingRoom'];
      case BusinessType.theater:
        return ['unused'];
    }
  }

  List<String> _getDefaultAgreementsForType(BusinessType type) {
    switch (type) {
      case BusinessType.bistro:
        return ["Municipal Catering Accord", "Culinary Workers Covenant"];
      case BusinessType.bakery:
        return ["Guild Bread Price Accord", "Flour Mill Supply Pact"];
      case BusinessType.pizzeria:
        return ["Piedmont Wood-fired Licensing", "Imported Yeast Protocol"];
      case BusinessType.cafe:
        return ["Viennese Salon Charter", "Imperial Sugar Tariff Waiver"];
      case BusinessType.opiateLab:
        return ["Alchemical Substance Accord", "Black-market Reagent Covenant"];
      case BusinessType.lawPractice:
        return [
          "Glarus Bar Association License",
          "Confidential Informant Compact",
        ];
      case BusinessType.medicalPractice:
        return [
          "Imperial Medical Doctorate Charter",
          "Sanatorium Operations License",
        ];
      case BusinessType.theater:
        return ["Dramatic Patent of rolls", "Writers Guild Copyright Covenant"];
    }
  }

  void addLedgerTransaction(String businessId, String desc, double amount) {
    final idx = _activeBusinesses.indexWhere((b) => b.id == businessId);
    if (idx == -1) return;
    final bus = _activeBusinesses[idx];

    final entry = LedgerEntry(
      date: _currentDate.formattedDate,
      description: desc,
      amount: amount,
    );

    _activeBusinesses[idx] = bus.copyWith(
      ledger: [...bus.ledger, entry],
      logs: [
        ...bus.logs,
        "[${_currentDate.formattedTime}] Ledger transaction: $desc ($amount CHF)",
      ],
    );

    updateResource('funds', amount.round());
    notifyListeners();
  }

  void sendPlayerToGraduateSchool() {
    final playerIdx = _npcs.indexWhere((n) => n.id == 'player');
    if (playerIdx == -1) return;

    _npcs[playerIdx] = _npcs[playerIdx].copyWith(
      worldDepartureId: 'manor',
      worldDestinationId: 'graduate_school',
      worldTravelProgress: 0.0,
      status: NPCStatus.idle,
      activeTaskId: null,
      targetRoomId: 'road',
      isResident: false,
    );

    _lastAnnouncement = "Alphonse has departed for Geneva Graduate School.";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] EDUCATION: $_lastAnnouncement",
    );
    notifyListeners();
  }

  void completeGraduation() {
    final playerIdx = _npcs.indexWhere((n) => n.id == 'player');
    if (playerIdx == -1) return;

    _playerHasGraduateDegree = true;
    _playerAcademicSpecialization = _graduateSchool?.specialization;

    _npcs[playerIdx] = _npcs[playerIdx].copyWith(
      worldDepartureId: 'graduate_school',
      worldDestinationId: 'manor',
      worldTravelProgress: 0.0,
    );

    _lastAnnouncement =
        "GRADUATION: Alphonse has graduated with an Advanced Academic Degree, specializing in ${_playerAcademicSpecialization ?? 'General Studies'}!";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] SUCCESS: $_lastAnnouncement",
    );
    notifyListeners();
  }

  void castTheaterRole(String businessId, String roleKey, String npcId) {
    final idx = _activeBusinesses.indexWhere((b) => b.id == businessId);
    if (idx == -1) return;
    final bus = _activeBusinesses[idx];

    final meta = Map<String, dynamic>.from(bus.metadata);
    meta[roleKey] = npcId;

    final npc = _npcs.firstWhereOrNull((n) => n.id == npcId);
    _activeBusinesses[idx] = bus.copyWith(
      metadata: meta,
      logs: [
        ...bus.logs,
        "[${_currentDate.formattedTime}] Cast ${npc?.name ?? 'Unknown'} as $roleKey.",
      ],
    );

    if (roleKey == 'leadActor' && bus.currentAssignmentIndex == 3) {
      advanceBusinessAssignment(businessId);
    } else if (roleKey == 'supportingActor' &&
        bus.currentAssignmentIndex == 4) {
      advanceBusinessAssignment(businessId);
    } else {
      notifyListeners();
    }
  }

  void assignTheaterCrew(String businessId, String crewId) {
    final idx = _activeBusinesses.indexWhere((b) => b.id == businessId);
    if (idx == -1) return;
    final bus = _activeBusinesses[idx];

    final meta = Map<String, dynamic>.from(bus.metadata);
    meta['crewId'] = crewId;

    _activeBusinesses[idx] = bus.copyWith(
      metadata: meta,
      logs: [
        ...bus.logs,
        "[${_currentDate.formattedTime}] Assigned crew member.",
      ],
    );

    if (bus.currentAssignmentIndex == 5) {
      advanceBusinessAssignment(businessId);
    } else {
      notifyListeners();
    }
  }

  void purchaseTheaterScript(String businessId, String scriptName) {
    final idx = _activeBusinesses.indexWhere((b) => b.id == businessId);
    if (idx == -1) return;
    final bus = _activeBusinesses[idx];

    final meta = Map<String, dynamic>.from(bus.metadata);
    final List<String> scripts = List<String>.from(
      meta['purchasedScripts'] ?? [],
    );
    scripts.add(scriptName);
    meta['purchasedScripts'] = scripts;

    _activeBusinesses[idx] = bus.copyWith(
      metadata: meta,
      logs: [
        ...bus.logs,
        "[${_currentDate.formattedTime}] Purchased script: $scriptName.",
      ],
    );

    updateResource('funds', -10);

    if (scripts.length >= 3 && bus.currentAssignmentIndex == 1) {
      advanceBusinessAssignment(businessId);
    } else {
      notifyListeners();
    }
  }

  void writeOriginalScript(String businessId, String scriptName) {
    final idx = _activeBusinesses.indexWhere((b) => b.id == businessId);
    if (idx == -1) return;
    final bus = _activeBusinesses[idx];

    final meta = Map<String, dynamic>.from(bus.metadata);
    meta['originalScript'] = scriptName;

    _activeBusinesses[idx] = bus.copyWith(
      metadata: meta,
      logs: [
        ...bus.logs,
        "[${_currentDate.formattedTime}] Wrote script: $scriptName in the study.",
      ],
    );

    if (bus.currentAssignmentIndex == 2) {
      advanceBusinessAssignment(businessId);
    } else {
      notifyListeners();
    }
  }

  void buildTheaterSet(String businessId) {
    final idx = _activeBusinesses.indexWhere((b) => b.id == businessId);
    if (idx == -1) return;
    final bus = _activeBusinesses[idx];

    if ((resources['wood'] ?? 0) < 20) {
      _lastAnnouncement = "Need 20 wood to construct the set!";
      notifyListeners();
      return;
    }

    updateResource('wood', -20);

    final meta = Map<String, dynamic>.from(bus.metadata);
    meta['setIsBuilt'] = true;

    _activeBusinesses[idx] = bus.copyWith(
      metadata: meta,
      logs: [
        ...bus.logs,
        "[${_currentDate.formattedTime}] Built set in the workshop.",
      ],
    );

    if (bus.currentAssignmentIndex == 6) {
      advanceBusinessAssignment(businessId);
    } else {
      notifyListeners();
    }
  }

  void scheduleTheaterShow(String businessId) {
    final idx = _activeBusinesses.indexWhere((b) => b.id == businessId);
    if (idx == -1) return;
    final bus = _activeBusinesses[idx];

    final meta = Map<String, dynamic>.from(bus.metadata);
    meta['showScheduledTime'] = _currentDate.totalMinutes + 1440;

    _activeBusinesses[idx] = bus.copyWith(
      metadata: meta,
      logs: [
        ...bus.logs,
        "[${_currentDate.formattedTime}] Scheduled show on the calendar.",
      ],
    );

    if (bus.currentAssignmentIndex == 7) {
      advanceBusinessAssignment(businessId);
    } else {
      notifyListeners();
    }
  }

  void rehearseTheaterShow(String businessId) {
    final idx = _activeBusinesses.indexWhere((b) => b.id == businessId);
    if (idx == -1) return;
    final bus = _activeBusinesses[idx];

    final meta = Map<String, dynamic>.from(bus.metadata);
    double currentRehearsal = (meta['rehearsalLevel'] as num? ?? 0.0)
        .toDouble();
    double newRehearsal = (currentRehearsal + 0.25).clamp(0.0, 1.0);
    meta['rehearsalLevel'] = newRehearsal;

    _activeBusinesses[idx] = bus.copyWith(
      metadata: meta,
      logs: [
        ...bus.logs,
        "[${_currentDate.formattedTime}] Rehearsed production (Progress: ${(newRehearsal * 100).toInt()}%).",
      ],
    );

    if (newRehearsal >= 1.0 && bus.currentAssignmentIndex == 8) {
      advanceBusinessAssignment(businessId);
    } else {
      notifyListeners();
    }
  }

  void promoteTheaterShow(String businessId) {
    final idx = _activeBusinesses.indexWhere((b) => b.id == businessId);
    if (idx == -1) return;
    final bus = _activeBusinesses[idx];

    final meta = Map<String, dynamic>.from(bus.metadata);
    meta['promotedLevel'] =
        (meta['promotedLevel'] as num? ?? 0.0).toDouble() + 0.35;

    _activeBusinesses[idx] = bus.copyWith(
      metadata: meta,
      logs: [
        ...bus.logs,
        "[${_currentDate.formattedTime}] Promoted the play in local hamlet.",
      ],
    );

    if ((meta['promotedLevel'] as double) >= 1.0 &&
        bus.currentAssignmentIndex == 9) {
      advanceBusinessAssignment(bus.id);
    } else {
      notifyListeners();
    }
  }

  void launchTheaterShowProduction(String businessId) {
    final idx = _activeBusinesses.indexWhere((b) => b.id == businessId);
    if (idx == -1) return;
    final bus = _activeBusinesses[idx];

    final meta = Map<String, dynamic>.from(bus.metadata);
    final leadNpc = _npcs.firstWhereOrNull((n) => n.id == meta['leadActor']);
    final suppNpc = _npcs.firstWhereOrNull(
      (n) => n.id == meta['supportingActor'],
    );

    double performanceScore = 0.5;
    if (leadNpc != null) {
      performanceScore += (leadNpc.stats['perception'] ?? 5) * 0.05;
    }
    if (suppNpc != null) {
      performanceScore += (suppNpc.stats['beauty'] ?? 5) * 0.03;
    }

    final scenery = meta['sceneryChoice'] ?? 'minimalist';
    final costumes = meta['costumeChoice'] ?? 'period';
    final music = meta['musicalScore'] ?? 'classical';

    double sceneryBonus = scenery == 'baroque' ? 0.2 : 0.0;
    double costumeBonus = costumes == 'elaborate' ? 0.15 : 0.0;
    double musicBonus = music == 'haunting' ? 0.1 : 0.0;
    performanceScore += sceneryBonus + costumeBonus + musicBonus;

    double promotion = meta['promotedLevel'] as double? ?? 1.0;
    int audience = (50 * performanceScore * promotion).round().clamp(10, 120);
    double profit = audience * 15.0;

    addLedgerTransaction(
      businessId,
      "Opening Night Ticket Sales ($audience guests)",
      profit,
    );

    double wages = 0.0;
    for (var npcId in bus.employeeIds) {
      final emp = _npcs.firstWhereOrNull((n) => n.id == npcId);
      if (emp != null) {
        wages += emp.monthlySalary;
      }
    }
    if (wages > 0) {
      addLedgerTransaction(businessId, "Cast and Crew Monthly Wages", -wages);
    }

    meta['audienceTotal'] = audience;
    meta['performanceQuality'] = performanceScore;
    meta['totalProfitGained'] = profit - wages;

    _activeBusinesses[idx] = bus.copyWith(
      metadata: meta,
      logs: [
        ...bus.logs,
        "[${_currentDate.formattedTime}] Opening night launched successfully to $audience spectators!",
      ],
    );

    if (bus.currentAssignmentIndex == 10) {
      advanceBusinessAssignment(bus.id);
    } else {
      notifyListeners();
    }
  }

  void updateTheaterCreativeChoices(
    String businessId, {
    String? scenery,
    String? costume,
    String? direction,
    String? score,
    String? feedback,
  }) {
    final idx = _activeBusinesses.indexWhere((b) => b.id == businessId);
    if (idx == -1) return;
    final bus = _activeBusinesses[idx];

    final meta = Map<String, dynamic>.from(bus.metadata);
    if (scenery != null) meta['sceneryChoice'] = scenery;
    if (costume != null) meta['costumeChoice'] = costume;
    if (direction != null) meta['directionStyle'] = direction;
    if (score != null) meta['musicalScore'] = score;
    if (feedback != null) meta['directorFeedback'] = feedback;

    _activeBusinesses[idx] = bus.copyWith(
      metadata: meta,
      logs: [
        ...bus.logs,
        "[${_currentDate.formattedTime}] Creative decisions updated.",
      ],
    );
    notifyListeners();
  }

  void checkBusinessAssignments() {
    for (var bus in _activeBusinesses) {
      if (bus.status != 'inProgress') continue;

      final currentIdx = bus.currentAssignmentIndex;
      if (bus.type == BusinessType.bistro) {
        if (currentIdx == 0) {
          final kitchen = _rooms.firstWhereOrNull(
            (r) => r.type == RoomType.kitchen,
          );
          if (kitchen != null && kitchen.isRestored) {
            advanceBusinessAssignment(bus.id);
          }
        } else if (currentIdx == 1) {
          final meats =
              (resources['meat'] ?? 0) +
              (resources['meat_chicken'] ?? 0) +
              (resources['meat_beef'] ?? 0);
          final veg =
              (resources['cabbage'] ?? 0) +
              (resources['potato'] ?? 0) +
              (resources['carrots'] ?? 0);
          if (meats >= 5 && veg >= 5) {
            advanceBusinessAssignment(bus.id);
          }
        } else if (currentIdx == 2) {
          // Perform Kitchen Experimentations 3 times
          if (_restaurantNewRecipeAttempts >= 3) {
            advanceBusinessAssignment(bus.id);
          }
        } else if (currentIdx == 3) {
          // Discover 2 new recipes through experiments (knownRecipes size >= 9, initial has 7)
          if (_knownRecipes.length >= 9) {
            advanceBusinessAssignment(bus.id);
          }
        } else if (currentIdx == 4) {
          // Hire a dedicated server or kitchen hand
          if (bus.employeeIds.isNotEmpty) {
            advanceBusinessAssignment(bus.id);
          }
        } else if (currentIdx == 5) {
          // Serve 3 hungry diners in the Dining Room
          if (_restaurantTablesServedTonight >= 3) {
            advanceBusinessAssignment(bus.id);
          }
        }
      } else if (bus.type == BusinessType.bakery) {
        if (currentIdx == 0) {
          final kitchen = _rooms.firstWhereOrNull(
            (r) => r.type == RoomType.kitchen,
          );
          if (kitchen != null && kitchen.isRestored) {
            advanceBusinessAssignment(bus.id);
          }
        } else if (currentIdx == 1) {
          final granary = _rooms.firstWhereOrNull(
            (r) => r.type == RoomType.granary,
          );
          if (granary != null && granary.isRestored) {
            advanceBusinessAssignment(bus.id);
          }
        }
      } else if (bus.type == BusinessType.opiateLab) {
        if (currentIdx == 0) {
          final lab = _rooms.firstWhereOrNull(
            (r) => r.type == RoomType.laboratory,
          );
          if (lab != null && lab.isRestored) {
            advanceBusinessAssignment(bus.id);
          }
        }
      } else if (bus.type == BusinessType.lawPractice) {
        if (currentIdx == 0 && _playerHasGraduateDegree) {
          advanceBusinessAssignment(bus.id);
        } else if (currentIdx == 1) {
          final study = _rooms.firstWhereOrNull(
            (r) => r.type == RoomType.study,
          );
          if (study != null && study.isRestored) {
            advanceBusinessAssignment(bus.id);
          }
        }
      } else if (bus.type == BusinessType.medicalPractice) {
        if (currentIdx == 0 && _playerHasGraduateDegree) {
          advanceBusinessAssignment(bus.id);
        } else if (currentIdx == 1) {
          final or = _rooms.firstWhereOrNull(
            (r) => r.type == RoomType.operatingRoom,
          );
          if (or != null && or.isRestored) {
            advanceBusinessAssignment(bus.id);
          }
        }
      } else if (bus.type == BusinessType.theater) {
        if (currentIdx == 0) {
          final theater = _rooms.firstWhereOrNull(
            (r) => r.type == RoomType.unused && r.isRestored,
          );
          if (theater != null) {
            advanceBusinessAssignment(bus.id);
          }
        }
      }
    }
  }

  void cheatInstantVenture(BusinessType type) {
    // Create proposer NPC
    final proposerId = "proposer_${type.name}";
    final proposer = NPC(
      id: proposerId,
      name: "Master ${type.name.toUpperCase()} Proposer",
      role: "Specialist",
      age: 35,
      gender: "Male",
      specimenType: "Human",
      isResident: true,
      bodyParts: const [],
      schedule: NPCSchedule.defaultWorker(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random(),
      currentRoomId: 'entryway',
      targetRoomId: 'entryway',
      movementProgress: 1.0,
      status: NPCStatus.idle,
    );
    _npcs.removeWhere((n) => n.id == proposerId);
    _npcs.add(proposer);

    // Propose
    proposeBusiness(type, proposerId, proposer.name);

    // Accept
    final bus = _activeBusinesses.firstWhere((b) => b.type == type);
    acceptBusinessProposal(bus.id);

    // Instantly complete
    final idx = _activeBusinesses.indexWhere((b) => b.id == bus.id);
    if (idx != -1) {
      _activeBusinesses[idx] = _activeBusinesses[idx].copyWith(
        currentAssignmentIndex: _activeBusinesses[idx].assignments.length,
        status: 'active',
        holdings: _getDefaultHoldingsForType(type),
        agreements: _getDefaultAgreementsForType(type),
        employeeIds: [proposerId],
      );
    }

    // Make sure dedicated rooms are restored
    final holdings = _getDefaultHoldingsForType(type);
    for (var rid in holdings) {
      final rIdx = _rooms.indexWhere((r) => r.id == rid);
      if (rIdx != -1) {
        _rooms[rIdx] = _rooms[rIdx].copyWith(
          isRestored: true,
          restorationProgress: 1.0,
        );
      }
    }

    _lastAnnouncement =
        "CHEAT: INSTANTLY ESTABLISHED ${type.displayName.toUpperCase()}!";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] CHEAT: $_lastAnnouncement",
    );
    notifyListeners();
  }

  void cheatAddFunds() {
    updateResource('funds', 1000);
    _lastAnnouncement = "CHEAT: ADDED 1,000 CHF TO HOLDINGS.";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] CHEAT: $_lastAnnouncement",
    );
    notifyListeners();
  }

  void cheatAddShepherdsPies() {
    for (int i = 0; i < 20; i++) {
      _pantry.add(
        Dish(
          id: "shepherds_pie_${const Uuid().v4()}",
          name: "Shepherd's Pie",
          type: DishType.protein,
          quality: DishQuality.exquisite,
          cookedAt: _currentDate,
          value: 40,
        ),
      );
    }
    _lastAnnouncement = "CHEAT: ADDED 20 SHEPHERD'S PIES TO PANTRY.";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] CHEAT: $_lastAnnouncement",
    );
    notifyListeners();
  }

  void cheatTriggerVisitor() {
    _triggerVisitorArrival();
  }

  void cheatSendSuperMerchant() {
    final superMerchant = NPCGenerator.generateRefugee(currentDate: _currentDate)
        .copyWith(
          id: 'super_merchant',
          name: 'Super Merchant Silas',
          role: 'Super Merchant',
          currentRoomId: 'entryway',
          targetRoomId: 'entryway',
          movementProgress: 1.0,
          status: NPCStatus.idle,
          assignedRoomId: null,
          isResident: false,
          metadata: {
            'guestType': 'merchant',
            'arrivalTime': _currentDate.totalMinutes,
            'isGreeted': false,
            'merchantStock': {
              'shepherds_pie': 999999,
              'wood': 999999,
              'meat': 999999,
              'eggs': 999999,
              'cabbage': 999999,
              'grain': 999999,
              'ale': 999999,
              'spirits': 999999,
              'timber': 999999,
              'rooster': 999999,
              'fertilizer': 999999,
              'salt': 999999,
              'potato': 999999,
              'carrots': 999999,
              'beets': 999999,
              'seeds_cabbage': 999999,
              'seeds_potato': 999999,
              'seeds_carrot': 999999,
              'seeds_cannabis': 999999,
              'seeds_tobacco': 999999,
              'mushroom_spores': 999999,
              'poem': 999999,
              'novel': 999999,
              'unreviewed_document': 999999,
              'old_notes': 999999,
              'research_notes': 999999,
              'rat': 999999,
              'bat': 999999,
              'chicken': 999999,
              'rooster_stock': 999999,
              'herb_reagent': 999999,
              'cannabis_buds': 999999,
              'tobacco_leaves': 999999,
              'hallucinogenic_mushrooms': 999999,
              'hemp_fiber': 999999,
              'coal': 999999,
              'iron_ore': 999999,
              'copper_ore': 999999,
              'gold_ore': 999999,
              'silver_ore': 999999,
              'cobalt_ore': 999999,
              'nickel_ore': 999999,
              'lithium_ore': 999999,
              'titanium_ore': 999999,
              'rough_diamonds': 999999,
              'uranium_ore': 999999,
              'jadeite_ore': 999999,
              'crude_oil': 999999,
              'bricks': 999999,
              'stone': 999999,
              'simple_shovel': 999999,
              'iron_pickaxe': 999999,
              'steel_pickaxe': 999999,
              'pneumatic_drill': 999999,
              'boiled_cabbage': 999999,
              'scrambled_eggs': 999999,
              'protein_mistery_stew': 999999,
            },
          },
        );

    _npcs.add(superMerchant);
    _lastAnnouncement = "Super Merchant Silas has arrived at the entryway!";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] MERCHANT ARRIVAL: Super Merchant Silas",
    );
    notifyListeners();
  }

  // --- ADVANCED GRADUATE SCHOOL SYSTEM ---
  void enrollInGraduateSchool(AcademicSchoolType type) {
    if (_playerHasGraduateDegree) return;

    _graduateSchool = GraduateSchoolState(
      type: type,
      currentSemester: 0, // 0 means Entrance Exam
      tuitionPaid: true,
      hasCompletedAssignment: false,
      studyProgress: 0.0,
      academicLogs: [
        "[${_currentDate.formattedTime}] Enrolled at Geneva Graduate Union under ${type.displayName}.",
      ],
      currentComplication: {},
    );

    sendPlayerToGraduateSchool();
  }

  void paySemesterTuition() {
    if (_graduateSchool == null) return;
    const cost = 500; // expensive semesters!
    if ((resources['funds'] ?? 0) < cost) {
      _lastAnnouncement =
          "Insufficient funds to pay semester tuition of $cost CHF!";
      notifyListeners();
      return;
    }

    updateResource('funds', -cost);
    _graduateSchool = _graduateSchool!.copyWith(
      tuitionPaid: true,
      academicLogs: [
        ..._graduateSchool!.academicLogs,
        "[${_currentDate.formattedTime}] Paid tuition fee of $cost CHF for Semester ${_graduateSchool!.currentSemester}.",
      ],
    );
    _lastAnnouncement =
        "Tuition of 500 CHF paid for Semester ${_graduateSchool!.currentSemester}!";
    notifyListeners();
  }

  void resolveSemesterComplication(String choiceKey) {
    if (_graduateSchool == null) return;

    final comp = _graduateSchool!.currentComplication;
    final cost = comp['cost'] as int? ?? 0;

    if (choiceKey == 'pay') {
      if ((resources['funds'] ?? 0) < cost) {
        _lastAnnouncement = "Insufficient funds to resolve complication!";
        notifyListeners();
        return;
      }
      updateResource('funds', -cost);
      _graduateSchool = _graduateSchool!.copyWith(
        hasCompletedAssignment: true,
        currentComplication: {},
        academicLogs: [
          ..._graduateSchool!.academicLogs,
          "[${_currentDate.formattedTime}] Resolved complication by paying $cost CHF.",
        ],
      );
      _lastAnnouncement =
          "Complication resolved. Alfonso remains focused on his studies.";
    } else {
      // Ignore penalty
      final type = _graduateSchool!.type;
      if (type == AcademicSchoolType.law) {
        // Distress causes moral loss
        adjustNpcSatisfaction('player', -30);
      } else if (type == AcademicSchoolType.pharmacy) {
        // Crops fail
        setResource('potato', max(0, (resources['potato'] ?? 0) - 5).toInt());
        setResource('cabbage', max(0, (resources['cabbage'] ?? 0) - 5).toInt());
      } else if (type == AcademicSchoolType.medicine) {
        // Giles overexertion / declinement
        final giles = _npcs.firstWhereOrNull((n) => n.id == 'butler');
        if (giles != null) {
          adjustNpcSatisfaction(giles.id, -40);
        }
      }

      _graduateSchool = _graduateSchool!.copyWith(
        hasCompletedAssignment: true,
        currentComplication: {},
        academicLogs: [
          ..._graduateSchool!.academicLogs,
          "[${_currentDate.formattedTime}] Ignored complication and suffered distress/manor penalty.",
        ],
      );
      _lastAnnouncement = "Ignored complications. Suffer local distress.";
    }
    notifyListeners();
  }

  void resolveFlaubertChoice(int choiceIndex) {
    if (_activeFlaubertEvent == null) return;

    final choices = _activeFlaubertEvent!['choices'] as List;
    final choice = choices[choiceIndex];
    final outcome = choice['impact'] as Function(GameState);
    outcome(this);

    _lastAnnouncement =
        "Flaubert Giles chose: ${choice['title'].toUpperCase()}";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] DECISION: $_lastAnnouncement",
    );

    clearFlaubertEvent();
  }

  void checkAcademicExam(bool passed, {int score = 0}) {
    if (_graduateSchool == null) return;

    final nextSemester = _graduateSchool!.currentSemester + 1;
    final scores = [..._graduateSchool!.semesterScores, score];
    if (passed) {
      final isSurgery = _graduateSchool!.specialization == 'Surgery';
      final finalSemester = isSurgery ? 5 : 4;

      if (nextSemester > finalSemester) {
        // Graduation complete!
        completeGraduation();
        _graduateSchool = _graduateSchool!.copyWith(
          currentSemester: nextSemester,
          studyProgress: 1.0,
          semesterScores: scores,
          academicLogs: [
            ..._graduateSchool!.academicLogs,
            "[${_currentDate.formattedTime}] Passed professional Board/Bar Qualification Exam! Conferred doctorate degree in ${_graduateSchool!.specialization}.",
          ],
        );
      } else {
        _graduateSchool = _graduateSchool!.copyWith(
          currentSemester: nextSemester,
          tuitionPaid: false,
          hasCompletedAssignment: false,
          studyProgress: 0.0,
          semesterScores: scores,
          academicLogs: [
            ..._graduateSchool!.academicLogs,
            "[${_currentDate.formattedTime}] Successfully passed Semester ${_graduateSchool!.currentSemester} practical exam (Score: $score/4). Advanced to Term $nextSemester.",
          ],
        );
        _lastAnnouncement =
            "CONGRATULATIONS: Passed practical test for Term ${_graduateSchool!.currentSemester - 1}!";
      }
    } else {
      _graduateSchool = _graduateSchool!.copyWith(
        studyProgress: 0.8, // reset back slightly to study more
        semesterScores: scores,
        academicLogs: [
          ..._graduateSchool!.academicLogs,
          "[${_currentDate.formattedTime}] Failed semester test with score $score/4. Required to repeat study reviews.",
        ],
      );
      _lastAnnouncement =
          "FAIL: Alfonso did not pass the practical review. Repeat review program!";
    }
    notifyListeners();
  }

  void _processGraduateSchool() {
    if (_graduateSchool == null) return;

    final player = _npcs.firstWhereOrNull((n) => n.id == 'player');
    final bool isAtSchool = player?.worldDestinationId == 'graduate_school';
    if (!isAtSchool) return;

    // If complication is active, pause study progress until resolved
    if (_graduateSchool!.currentComplication.isNotEmpty) return;

    double currentPrg = _graduateSchool!.studyProgress;
    if (currentPrg < 1.0) {
      double studySpeed =
          1.0 / 12.0; // Takes 12 ticks (12 hours) to complete reviews per term
      double newPrg = (currentPrg + studySpeed).clamp(0.0, 1.0);

      _graduateSchool = _graduateSchool!.copyWith(studyProgress: newPrg);

      // 10% chance per hour of triggering Flaubert Manor Events while Alphonse is away
      if (Random().nextDouble() < 0.12 && _activeFlaubertEvent == null) {
        _triggerFlaubertEvent();
      }
    } else if (currentPrg >= 1.0 && !_graduateSchool!.hasCompletedAssignment) {
      // Semester complication arises at 100% study progress!
      _triggerSemesterComplication();
    }
  }

  void _triggerSemesterComplication() {
    if (_graduateSchool == null) return;

    final semester = _graduateSchool!.currentSemester;

    String title = "";
    String desc = "";
    int cost = 0;

    if (semester == 0) {
      // Entrance Exam requires no complication, auto-ready
      _graduateSchool = _graduateSchool!.copyWith(hasCompletedAssignment: true);
      notifyListeners();
      return;
    }

    if (semester == 1) {
      title = "Love Interest Back Home is Sick";
      desc =
          "A letter arrives: Alphonse's romantic partner has contracted Rolle swamp fever and begs him to return to nurse them, or hire private Rolles doctor.";
      cost = 200; // 200 CHF medicine
    } else if (semester == 2) {
      title = "Agricultural Blight";
      desc =
          "Crops back home are suffering from alchemical mold. Buy imported fertilizer immediately to cure it, or suffer severe Glarus crop failure.";
      cost = 150; // 150 CHF fertilizer
    } else if (semester == 3) {
      title = "Construct Outbreak";
      desc =
          "One of Glarus's reanimated constructs escaped Glarus vaults and killed the neighbor's sheep. Pay silence hush money to prevent local outcry.";
      cost = 250;
    }

    _graduateSchool = _graduateSchool!.copyWith(
      currentComplication: {'title': title, 'description': desc, 'cost': cost},
      academicLogs: [
        ..._graduateSchool!.academicLogs,
        "[${_currentDate.formattedTime}] Complication arose: $title.",
      ],
    );

    _lastAnnouncement =
        "ACADEMIC OBSTACLE: $title requires your immediate decision!";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] OBSTACLE: $_lastAnnouncement",
    );

    // Pause speed to alert player
    _speedBeforePause = _speed;
    setSpeed(GameSpeed.paused);
    notifyListeners();
  }

  void _triggerFlaubertEvent() {
    final events = [
      {
        'title': "ORDO OBSCURA INVITATION",
        'description':
            "While studying at the university, Alphonse is approached by an emissary of Rolle's secret society inviting him to join their occult academic order.",
        'choices': [
          {
            'title': "ACCEPT & DONATE (-100 CHF)",
            'description':
                "Join the secret society. Gains 3 alchemical books, but costs 100 CHF.",
            'impact': (GameState s) {
              s.updateResource('funds', -100);
              // Add alchemical documents
              s.setResource('old_notes', (s.resources['old_notes'] ?? 0) + 3);
            },
          },
          {
            'title': "DECLINE & STAY VIGILANT",
            'description':
                "Maintain academic independence and focus (+10 Alphonse Satisfaction).",
            'impact': (GameState s) {
              s.adjustNpcSatisfaction('player', 10);
            },
          },
        ],
      },
      {
        'title': "SECRET: BURYING A BODY",
        'description':
            "A frantic colleague from Rolle's pharmaceutical union arrives with a suspicious heavy iron chest, begging Flaubert to hide it in Glarus cellar.",
        'choices': [
          {
            'title': "COLLUDE & ACCORD (+300 CHF)",
            'description':
                "Hide the chest in the basement. Morale takes a hit (-20 Morale), but earns 300 CHF hush money.",
            'impact': (GameState s) {
              s.updateResource('funds', 300);
              final giles = s.npcs.firstWhereOrNull((n) => n.id == 'butler');
              if (giles != null) {
                s.adjustNpcSatisfaction(giles.id, -20);
              }
            },
          },
          {
            'title': "REFUSE & EXPELL",
            'description':
                "Expell the colleague. Flaubert feels proud of keeping the manor's integrity intact (+15 Giles Satisfaction).",
            'impact': (GameState s) {
              final giles = s.npcs.firstWhereOrNull((n) => n.id == 'butler');
              if (giles != null) {
                s.adjustNpcSatisfaction(giles.id, 15);
              }
            },
          },
        ],
      },
      {
        'title': "ORGANIZATIONAL POLITICKING",
        'description':
            "Curators at Geneva Curio Society offer to lobby Rolle's council to give Glarus tax-exempt status in exchange for alchemical materials.",
        'choices': [
          {
            'title': "LOBBY & TRADE (-2 Wood)",
            'description':
                "Lobby for tax exemption. Costs 2 Wood, but earns 200 CHF.",
            'impact': (GameState s) {
              s.updateResource('wood', -2);
              s.updateResource('funds', 200);
            },
          },
          {
            'title': "MAINTAIN AUTONOMY",
            'description':
                "Decline the lobby pact. Gains Glarus academic prestige (+30 Research points).",
            'impact': (GameState s) {
              s.addResearchPoints(30);
            },
          },
        ],
      },
    ];

    _activeFlaubertEvent = events[Random().nextInt(events.length)];
    _speedBeforePause = _speed;
    setSpeed(GameSpeed.paused);
    notifyListeners();
  }

  void addResearchPoints(int amt) {
    final activeDiscipline = _researchPoints.keys.firstOrNull ?? 'Anatomy';
    _researchPoints[activeDiscipline] =
        (_researchPoints[activeDiscipline] ?? 0.0) + amt;
    notifyListeners();
  }

  Map<String, dynamic>? _activeDentalEvent;
  Map<String, dynamic>? get activeDentalEvent => _activeDentalEvent;

  void clearDentalEvent() {
    _activeDentalEvent = null;
    setSpeed(_speedBeforePause ?? GameSpeed.normal);
    notifyListeners();
  }

  void resolveDentalEventChoice(int choiceIndex) {
    if (_activeDentalEvent == null) return;

    final choices = _activeDentalEvent!['choices'] as List;
    final choice = choices[choiceIndex];
    final outcome = choice['impact'] as Function(GameState);
    outcome(this);

    _lastAnnouncement =
        "DENTISTRY: Treated patient. Outcome: ${choice['title'].toUpperCase()}";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] DENTISTRY: $_lastAnnouncement",
    );

    clearDentalEvent();
  }

  void _triggerDentalPatientEvent() {
    final roll = Random().nextDouble();
    if (roll < 0.55) {
      _activeDentalEvent = _createGenericPatientEvent();
    } else {
      final List<Map<String, dynamic>> events = [];

      // 1. The Gold-Tooth Patient
      events.add({
        'title': "THE MERCHANT'S MOLAR",
        'description':
            "A wealthy Rolle merchant seeks extraction of a sore molar. You notice the tooth adjacent is perfectly healthy, but capped in heavy alchemical gold (worth 350 CHF).",
        'choices': [
          {
            'title': "EXTRACT THE SORE MOLAR ONLY (+80 CHF)",
            'description':
                "Perform an ethical extraction. The merchant is pleased and pays your standard fee. (+80 CHF).",
            'impact': (GameState s) {
              s.updateResource('funds', 80);
              s.payBackDentalLoan(80);
            },
          },
          {
            'title': "STEAL THE GOLD TOOTH (+380 CHF)",
            'description':
                "Insist the gold-capped tooth is severely infected and must be removed. Keep the gold and charge for double extraction. The patient suffers pain, reducing local reputation (-15 Satisfaction).",
            'impact': (GameState s) {
              s.updateResource('funds', 380);
              s.payBackDentalLoan(380);
              s.adjustNpcSatisfaction('player', -15);
            },
          },
        ],
      });

      // 2. The Nemesis Relative
      events.add({
        'title': "THE FEUDING RELATIVE",
        'description':
            "A patient arrives requiring urgent work. You recognize them as Kael's favorite nephew. A negative outcome will trigger Kael's wrath.",
        'choices': [
          {
            'title': "TREAT WITH SUPREME CARE (-50 CHF, +20 Reputation)",
            'description':
                "Use high-grade alchemical anesthetics. The operation is flawless. Kael begrudgingly respects Glarus clinic's integrity (+20 Satisfaction).",
            'impact': (GameState s) {
              s.updateResource('funds', -50);
              s.adjustNpcSatisfaction('player', 20);
            },
          },
          {
            'title': "EXPLOIT AND INFLICT GUM DAMAGE (+250 CHF, nemesis war!)",
            'description':
                "Charge double for unneeded dental work and intentionally nick their gums with a scaler to require a follow-up. Earns 250 CHF, but Kael declares blood feud, triggering manor constructs alert!",
            'impact': (GameState s) {
              s.updateResource('funds', 250);
              s.payBackDentalLoan(250);
              s._rebelConstructsActive =
                  true; // Trigger nemesis/constructs war!
              s.adjustNpcSatisfaction('player', -40);
            },
          },
        ],
      });

      // 3. The Hamlet Gossip
      events.add({
        'title': "THE INN KEEPER'S GOSSIP",
        'description':
            "The local hamlet tavern maid is in the chair. To distract herself from the scrape of your tools, she begins whispering rumors about a diamond transport.",
        'choices': [
          {
            'title': "SCALE AND POLISH ETHICALLY (+60 CHF)",
            'description':
                "Complete standard cleaning. Earns standard fee (+60 CHF).",
            'impact': (GameState s) {
              s.updateResource('funds', 60);
              s.payBackDentalLoan(60);
            },
          },
          {
            'title': "EXPLOIT THE HEARSAY: PLAN A HEIST (+300 CHF)",
            'description':
                "Inflict a minor gum nick so she stays longer, coaxing out the details: 'A shipment of raw diamonds is guarded by just one man at the Inn!' You dispatch Giles to intercept it (+300 CHF).",
            'impact': (GameState s) {
              s.updateResource('funds', 300);
              s.payBackDentalLoan(300);
              s._announcementHistory.insert(
                0,
                "[HEIST SUCCESS] Giles successfully raided the Inn's diamond chest!",
              );
            },
          },
        ],
      });

      // 4. The Influential Noble
      events.add({
        'title': "THE INFLUENTIAL SENATOR",
        'description':
            "Geneva Senator Lullin requires a cosmetic gum scrape. A perfect outcome could gain political protection; cheating him will drag Glarus into political scandals.",
        'choices': [
          {
            'title': "PRACTICE ETHICAL GUM SURGERY (+120 CHF)",
            'description':
                "Perform a flawless cosmetic scale. Senator Lullin leaves exceptionally pleased, providing protection (+30 Research points).",
            'impact': (GameState s) {
              s.updateResource('funds', 120);
              s.payBackDentalLoan(120);
              s.addResearchPoints(30);
            },
          },
          {
            'title': "DEMAND UNNEEDED DENTAL WORK (+450 CHF)",
            'description':
                "Insist he requires structural jaw realignments. He pays a massive premium (+450 CHF), but realizes the fraud later, launching a tax audit (-150 CHF Glarus tax penalty).",
            'impact': (GameState s) {
              s.updateResource('funds', 300); // 450 - 150 penalty = 300 net
              s.payBackDentalLoan(300);
            },
          },
        ],
      });

      // 5. Manor Resident Cognitive Preservation (Late game tracking)
      events.add({
        'title': "COGNITIVE PRESERVATION RESIDENCE",
        'description':
            "Flaubert Giles complains of minor memory lapses. Modern dental treatises suggest a strong causal link between deep periodontal health and staving off cognitive decline.",
        'choices': [
          {
            'title': "PERFORM ANTISEPTIC ROOT SCALING (-100 CHF)",
            'description':
                "Perform thorough deep root cleaning on Flaubert. Restores Flaubert's mental acuity (+40 Giles Satisfaction, staves off sanity decline).",
            'impact': (GameState s) {
              s.updateResource('funds', -100);
              final giles = s.npcs.firstWhereOrNull((n) => n.id == 'butler');
              if (giles != null) {
                s.adjustNpcSatisfaction(giles.id, 40);
              }
            },
          },
          {
            'title': "EXTRACT SORE TEETH TO RETAIN FUNDS (+50 CHF)",
            'description':
                "Avoid expensive antiseptics; simply extract the molars. Cheap, but Flaubert feels aged and experiences mild cognitive fatigue (-10 Giles Satisfaction).",
            'impact': (GameState s) {
              s.updateResource('funds', 50);
              final giles = s.npcs.firstWhereOrNull((n) => n.id == 'butler');
              if (giles != null) {
                s.adjustNpcSatisfaction(giles.id, -10);
              }
            },
          },
        ],
      });

      _activeDentalEvent = events[Random().nextInt(events.length)];
    }

    _speedBeforePause = _speed;
    setSpeed(GameSpeed.paused);
    notifyListeners();
  }

  Map<String, dynamic> _createGenericPatientEvent() {
    final rollVip = Random().nextDouble();
    final bool isFoodCritic = rollVip < 0.10;
    final bool isNemesisRelative = !isFoodCritic && rollVip < 0.15;

    String title = "A GLARUS TENANT PATIENT";
    String desc =
        "A standard tenant worker seeks standard cavity treatment and scaling. A completely routine case. How do you proceed?";

    if (isFoodCritic) {
      title = "A SEEMINGLY ORDINARY PATIENT";
      desc =
          "An unassuming, quiet patient sits in your chair requiring standard dental treatment. They watch your clinic setup carefully and take brief notes in a small book. How do you proceed?";
    } else if (isNemesisRelative) {
      title = "A QUIET LOCAL CLIENT";
      desc =
          "An ordinary-looking local client requires a standard filling. They seem slightly tense but remain completely polite. How do you proceed?";
    }

    return {
      'title': title,
      'description': desc,
      'choices': [
        {
          'title': "WORK EXTRA HARD (-10 Satisfaction, +80 CHF)",
          'description':
              "Spend 90 minutes meticulously scraping. You only collect the standard 80 CHF fee. People hate sitting in the chair for so long (-10 Satisfaction), and if they get cavities later anyway, they'll blame you entirely.",
          'impact': (GameState s) {
            s.updateResource('funds', 80);
            s.payBackDentalLoan(80);
            s.adjustNpcSatisfaction('player', -10);
            s._announcementHistory.insert(
              0,
              "[METICULOUS CARE] Alfonso spent 90 minutes cleaning. Patient left exhausted and annoyed.",
            );

            if (isFoodCritic) {
              s._dentalCriticReviewState = 'positive';
              s._dentalCriticReviewTriggerTime =
                  s.currentDate.totalMinutes + 10080; // 7 days
            } else if (isNemesisRelative) {
              s.adjustNpcSatisfaction('player', 20);
              s._announcementHistory.insert(
                0,
                "[HIDDEN PLOT] The patient was Kael's nephew in disguise! He was highly impressed by your patient care.",
              );
            }
          },
        },
        {
          'title': "GET THE JOB DONE (+80 CHF)",
          'description':
              "Provide ordinary 45 minute care. Bills standard 80 CHF. Alfonso is more likely to fail to diagnose hidden issues, which the customer will attribute to your poor care anyway.",
          'impact': (GameState s) {
            s.updateResource('funds', 80);
            s.payBackDentalLoan(80);
            s._announcementHistory.insert(
              0,
              "[ORDINARY CARE] Alfonso completed the cleaning. Fast and transactional.",
            );

            if (isFoodCritic) {
              s._dentalCriticReviewState = 'positive';
              s._dentalCriticReviewTriggerTime =
                  s.currentDate.totalMinutes + 10080; // 7 days
            } else if (isNemesisRelative) {
              s.adjustNpcSatisfaction('player', 10);
              s._announcementHistory.insert(
                0,
                "[HIDDEN PLOT] The patient was Kael's nephew in disguise! He felt treated fairly.",
              );
            }
          },
        },
        {
          'title': "UPSELL PREVENTATIVE AMALGAMS (+250, +220, or +80 CHF)",
          'description':
              "Press the client to purchase expensive mercury sealants they do not need. Most customers accept it and feel grateful (thinking it saves them from future woes!). Roll on the charts.",
          'impact': (GameState s) {
            final roll = Random().nextDouble();
            if (roll < 0.70) {
              // Accepts & grateful!
              s.updateResource('funds', 250);
              s.payBackDentalLoan(250);
              s.adjustNpcSatisfaction('player', 10);
              s._announcementHistory.insert(
                0,
                "[UPSELL SUCCESS] Patient accepted and felt grateful for your preventative care (+250 CHF).",
              );
            } else if (roll < 0.90) {
              // Rejects!
              s.updateResource('funds', 80);
              s.payBackDentalLoan(80);
              s.adjustNpcSatisfaction('player', -5);
              s._announcementHistory.insert(
                0,
                "[UPSELL REJECTED] Patient rejected the upsell and felt pressured.",
              );
            } else {
              // Realizes exploitation!
              s.updateResource('funds', 220);
              s.payBackDentalLoan(220);
              s.adjustNpcSatisfaction('player', -15);
              s._announcementHistory.insert(
                0,
                "[UPSELL COERCION] Patient bought the sealant but realized they were exploited.",
              );
            }

            if (isFoodCritic) {
              s._dentalCriticReviewState = 'negative';
              s._dentalCriticReviewTriggerTime =
                  s.currentDate.totalMinutes + 10080; // 7 days
            } else if (isNemesisRelative) {
              s._rebelConstructsActive = true; // Nemesis war!
              s.adjustNpcSatisfaction('player', -40);
              s._announcementHistory.insert(
                0,
                "[HIDDEN PLOT OUTCRY] The patient was Kael's nephew! Kael discovers your financial coercion and declares blood feud!",
              );
            }
          },
        },
        {
          'title': "BANG-UP JOB: SABOTAGE REPAIR (+450 CHF, malpractice risk!)",
          'description':
              "Intentionally drill a fissure into a healthy molar to fabricate severe pulp decay. Immediate payment of 450 CHF. However, 15% chance of a delayed lawsuit or medical tribunal summons.",
          'impact': (GameState s) {
            s.updateResource('funds', 450);
            s.payBackDentalLoan(450);

            final rollWounded = Random().nextDouble();
            if (rollWounded < 0.15) {
              final rollAction = Random().nextDouble();
              if (rollAction < 0.67) {
                s._dentalMalpracticePending = true;
                s._dentalMalpracticeTriggerTime =
                    s.currentDate.totalMinutes + 4320; // 3 days
                s._announcementHistory.insert(
                  0,
                  "[SABOTAGE SUMMONS] The patient left Glarus Manor in excruciating pain, threatening disciplinary action.",
                );
              } else {
                s._announcementHistory.insert(
                  0,
                  "[SABOTAGE INJURY] The patient suffered intense pulp discomfort but remains too intimidated to pursue court claims.",
                );
              }
            } else {
              s._announcementHistory.insert(
                0,
                "[SABOTAGE SILENT] Sabotage complete. Molar root silently split.",
              );
            }

            if (isFoodCritic) {
              s._dentalCriticReviewState = 'negative';
              s._dentalCriticReviewTriggerTime =
                  s.currentDate.totalMinutes + 10080; // 7 days
            } else if (isNemesisRelative) {
              s._rebelConstructsActive = true; // Nemesis war!
              s.adjustNpcSatisfaction('player', -50);
              s._announcementHistory.insert(
                0,
                "[HIDDEN PLOT OUTCRY] The patient was Kael's nephew! Kael discovers your medical sabotage and launches a full military assault!",
              );
            }
          },
        },
      ],
    };
  }

  void _triggerDentalCriticReviewAnnouncement() {
    if (_dentalCriticReviewState == null) return;

    final isPositive = _dentalCriticReviewState == 'positive';
    _dentalCriticReviewState = null; // Reset trigger!

    if (isPositive) {
      _bistroProfitModifier += 0.50;
      _bistroNextWeekBonus = 200.0;
      _lastAnnouncement =
          "CRITIC REVIEW: '**** Delectable. I also highly recommend the dental practice that can be found in the same building.' (Glarus Bistro permanent profit trend increased by +50% and +200 CHF next week!)";
    } else {
      _bistroProfitModifier = max(0.1, _bistroProfitModifier - 0.35);
      _bistroNextWeekBonus = -150.0;
      _lastAnnouncement =
          "CRITIC REVIEW: '* I was still numb after having a tooth pulled there earlier in the day. I couldn't taste a thing. Avoid.' (Glarus Bistro permanent profit trend decreased by -35% and -150 CHF next week!)";
    }

    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] CRITIC: $_lastAnnouncement",
    );
    notifyListeners();
  }

  Map<String, dynamic>? _activeRestaurantTycoonEvent;
  Map<String, dynamic>? get activeRestaurantTycoonEvent =>
      _activeRestaurantTycoonEvent;

  void clearRestaurantTycoonEvent() {
    _activeRestaurantTycoonEvent = null;
    setSpeed(_speedBeforePause ?? GameSpeed.normal);
    notifyListeners();
  }

  void resolveRestaurantTycoonChoice(int idx) {
    if (_activeRestaurantTycoonEvent == null) return;
    final choices = _activeRestaurantTycoonEvent!['choices'] as List;
    final choice = choices[idx];
    final outcome = choice['impact'] as Function(GameState);
    outcome(this);
    clearRestaurantTycoonEvent();
  }

  void _triggerExtendHoursDialogue() {
    _activeRestaurantTycoonEvent = {
      'title': "EXTEND RESTAURANT HOURS?",
      'description':
          "A 7th couple is approaching Glarus Manor Dining Room. Your tables are completely full. To accommodate them and continue serving tonight (up to 9 tables), you must extend staff hours spontaneously. Your employees will suffer a significant satisfaction and exhaustion penalty (-25 Satisfaction).",
      'choices': [
        {
          'title': "YES, EXTEND HOURS (Capacity: 9 Tables, -25 Morale)",
          'description':
              "Force the staff to work late to squeeze every drop of Glarus profit.",
          'impact': (GameState s) {
            s._restaurantExtendedHoursActive = true;
            s._restaurantQueueCount++;
            s._lastAnnouncement =
                "STAFF: Forced restaurant hours extension! Staff is exhausted and resentful (-25 Satisfaction).";
            s._announcementHistory.insert(
              0,
              "[${s.currentDate.formattedTime}] EXPLOIT: ${s._lastAnnouncement}",
            );
            for (int i = 0; i < s._npcs.length; i++) {
              if (s._npcs[i].isResident && s._npcs[i].id != 'player') {
                s.adjustNpcSatisfaction(s._npcs[i].id, -25);
              }
            }
          },
        },
        {
          'title': "NO, TURN THEM AWAY",
          'description':
              "Close Glarus Manor doors for the night, maintaining staff morale.",
          'impact': (GameState s) {
            s._lastAnnouncement =
                "STAFF: Closed restaurant on time. Staff is grateful.";
            s._announcementHistory.insert(
              0,
              "[${s.currentDate.formattedTime}] CHEER: ${s._lastAnnouncement}",
            );
          },
        },
      ],
    };

    _speedBeforePause = _speed;
    setSpeed(GameSpeed.paused);
    notifyListeners();
  }

  void _triggerPriceIncreaseDialogue() {
    _activeRestaurantTycoonEvent = {
      'title': "PREMIUM RESTAURANT DEMAND",
      'description':
          "Chef Giles approaches: 'Master, Glarus Bistro is absolutely buzzing! We have successfully served 5 tables tonight. We are leaving massive funds on the table. We should increase our menu prices in Glarus Business Records!'",
      'choices': [
        {
          'title': "ACQUIESCE AND OPEN RECORDS",
          'description':
              "Acquiesce and adjust your premium pricing scale in Glarus Records.",
          'impact': (GameState s) {
            s._lastAnnouncement =
                "RECORDS: Chef suggests price increases in records!";
          },
        },
      ],
    };

    _speedBeforePause = _speed;
    setSpeed(GameSpeed.paused);
    notifyListeners();
  }

  void _processRealtimeRestaurant() {
    final bistro = _activeBusinesses.firstWhereOrNull(
      (b) => b.type == BusinessType.bistro && b.status == 'active',
    );
    if (bistro == null) return;

    if (_currentDate.hour == 0 && _currentDate.minute == 0) {
      _restaurantTablesServedTonight = 0;
      _restaurantExtendedHoursActive = false;
      _restaurantTableFinishMinutes.clear();
      _restaurantActiveTables = 0;
      _restaurantQueueCount = 0;
    }

    final int dayOfWeek = (_currentDate.day - 1) % 7 + 1;
    final bool isOperatingDay = _restaurantOperatingDays.contains(dayOfWeek);
    final int startHour = _restaurantStartHours[dayOfWeek] ?? 17;
    final int endHour = _restaurantEndHours[dayOfWeek] ?? 22;
    final bool isOperatingHour =
        _currentDate.hour >= startHour && _currentDate.hour < endHour;

    if (!isOperatingDay || !isOperatingHour) {
      if (_restaurantActiveTables > 0 && _currentDate.minute % 10 == 0) {
        _restaurantActiveTables = max(0, _restaurantActiveTables - 1);
        _restaurantTableFinishMinutes.clear();
      }
      return;
    }

    final List<int> activeCopy = List.from(_restaurantTableFinishMinutes);
    for (var finishTime in activeCopy) {
      if (_currentDate.totalMinutes >= finishTime) {
        _restaurantTableFinishMinutes.remove(finishTime);
        _restaurantActiveTables = max(0, _restaurantActiveTables - 1);

        double bill = 0.0;
        String orderDesc = "";
        if (_restaurantMenuIds.isEmpty) {
          bill = 60.0 * _bistroPriceLevel;
          orderDesc = "Default Culinary Plate for 2";
        } else {
          final List<String> ordered = [];
          final rand = Random();
          for (int i = 0; i < 2; i++) {
            final id =
                _restaurantMenuIds[rand.nextInt(_restaurantMenuIds.length)];
            ordered.add(id);
            bill += (_restaurantMenuPrices[id] ?? 30.0);
          }
          bill = bill * _bistroPriceLevel;
          orderDesc = ordered
              .map((id) => id.replaceAll('_', ' ').toUpperCase())
              .join(", ");
        }

        // Apply Ambiance Multiplier
        double ambianceMult = 1.0;
        if (_restaurantAmbiance == 'gothic') {
          ambianceMult = 1.4;
        } else if (_restaurantAmbiance == 'alchemical') {
          ambianceMult = 1.2;
          // Grant alchemical bonus
          addResearchPoints(2);
        }
        bill *= ambianceMult;

        // Apply Entertainment Multiplier
        double entMult = 1.0;
        if (_restaurantEntertainment == 'lutist') {
          entMult = 1.10;
        } else if (_restaurantEntertainment == 'opera') {
          entMult = 1.25;
        }
        bill *= entMult;

        // Simulate Bar Drink Purchases
        double drinkRevenue = 0.0;
        String drinkDesc = "";
        if (_barStockedDrinks.isNotEmpty && Random().nextDouble() < 0.55) {
          final rand = Random();
          final drink =
              _barStockedDrinks[rand.nextInt(_barStockedDrinks.length)];
          final unitPrice = _barDrinkPrices[drink] ?? 10.0;
          drinkRevenue = unitPrice * 2; // 2 guests

          // Consume beverage assets from resources
          final resourceName = (drink.contains('beer') || drink.contains('ale'))
              ? 'ale'
              : 'spirits';
          if ((resources[resourceName] ?? 0) >= 2) {
            updateResource(resourceName, -2);
            bill += drinkRevenue;
            drinkDesc = " & Stocked Bar Beverages ($drink)";
          }
        }

        // Real-world customer experience risks
        final double rollExp = Random().nextDouble();
        final double badRisk = _restaurantExtendedHoursActive ? 0.35 : 0.25;
        final double incidentRisk = _restaurantExtendedHoursActive
            ? 0.12
            : 0.05;

        if (rollExp < incidentRisk) {
          bill = 0.0;
          _bistroProfitModifier = max(0.1, _bistroProfitModifier - 0.08);
          _announcementHistory.insert(
            0,
            "[RESTAURANT OUTCRY] A guest found a hair in their gourmet plate and stormed out without paying (zero tip, -8% buzz).",
          );
        } else if (rollExp < badRisk) {
          bill = bill * 0.60;
          _bistroProfitModifier = max(0.1, _bistroProfitModifier - 0.03);
          _announcementHistory.insert(
            0,
            "[RESTAURANT COMPLAINT] Long dining ticket times and drafty corners disappointed a table. Check bill reduced by 40% (-3% buzz).",
          );
        }

        if (bill > 0.0) {
          addLedgerTransaction(
            bistro.id,
            "Seated Table Checkout ($orderDesc$drinkDesc)",
            bill,
          );
        }

        if (_restaurantTablesServedTonight == 5 &&
            !_restaurantPricePromptTriggered) {
          _restaurantPricePromptTriggered = true;
          _triggerPriceIncreaseDialogue();
        }
      }
    }

    if (_currentDate.minute % 15 == 0 &&
        Random().nextDouble() < (0.45 * _bistroProfitModifier)) {
      if (!_restaurantExtendedHoursActive &&
          _restaurantTablesServedTonight >= 6) {
        _triggerExtendHoursDialogue();
      } else if (_restaurantTablesServedTonight <
          (_restaurantExtendedHoursActive ? 9 : 6)) {
        _restaurantQueueCount++;
      }
    }

    while (_restaurantQueueCount > 0 && _restaurantActiveTables < 3) {
      _restaurantQueueCount--;
      _restaurantActiveTables++;
      _restaurantTablesServedTonight++;
      _restaurantTableFinishMinutes.add(
        _currentDate.totalMinutes + 45 + Random().nextInt(45),
      );
    }
  }

  void _triggerDentalMalpracticeEvent() {
    _dentalMalpracticePending = false; // Reset!

    _activeDentalEvent = {
      'title': "IMPERIAL MEDICAL COMPLAINT",
      'description':
          "A formal lawsuit and Board of Discipline complaint has been filed by a Glarus tenant patient claiming Alfonso Giles intentionally damaged their molar root. The plaintiff is seeking steep civil damages.",
      'choices': [
        {
          'title': "BRIBE THE EXAMINING OFFICER (-200 CHF)",
          'description':
              "Offer a quiet bribe of 200 CHF to dismiss all claims. (Costs 200 CHF, no other penalties).",
          'impact': (GameState s) {
            s.updateResource('funds', -200);
            s._announcementHistory.insert(
              0,
              "[BRIBE ACCEPTED] Alfonso paid 200 CHF to the board officer. The file was archived.",
            );
          },
        },
        {
          'title': "FIGHT ETHICALLY IN TRIBUNAL",
          'description':
              "Defend your actions in the medical tribunal. High intellect check (75% success: cleared cleanly; 25% failure: paid 500 CHF fine and lose -30 Satisfaction).",
          'impact': (GameState s) {
            final success = Random().nextDouble() < 0.75;
            if (success) {
              s._announcementHistory.insert(
                0,
                "[TRIBUNAL EXONERATED] Alfonso successfully defended his surgical decisions. Cleared cleanly!",
              );
            } else {
              s.updateResource('funds', -500);
              s.adjustNpcSatisfaction('player', -30);
              s._announcementHistory.insert(
                0,
                "[TRIBUNAL GUILTY] Tribunal failed! Fined 500 CHF by the Medical Board.",
              );
            }
          },
        },
        {
          'title': "HIRE THUGS TO INTIMIDATE (-100 CHF)",
          'description':
              "Hire local street thugs to intimidate the plaintiff into withdrawing their court summons. (Costs 100 CHF).",
          'impact': (GameState s) {
            s.updateResource('funds', -100);
            s._announcementHistory.insert(
              0,
              "[INTIMIDATED] The plaintiff withdrew all civil claims out of sudden terror.",
            );
          },
        },
      ],
    };

    _speedBeforePause = _speed;
    setSpeed(GameSpeed.paused);
    notifyListeners();
  }

  void _processWeeklyBusinessProfits() {
    for (var bus in _activeBusinesses) {
      if (bus.status != 'active') continue;

      double baseProfit = 0.0;
      String desc = "";

      switch (bus.type) {
        case BusinessType.bistro:
          final double totalWages =
              _restaurantEmployeeCount * _restaurantEmployeeWages;
          double supplierCost = 100.0;
          if (_restaurantSupplierContract == 'premium') {
            supplierCost = 250.0;
          } else if (_restaurantSupplierContract == 'bulk') {
            supplierCost = 180.0;
          } else if (_restaurantSupplierContract == 'package') {
            supplierCost = 150.0;
          }
          baseProfit = -totalWages - supplierCost;
          desc =
              "Restaurant Weekly Overhead (Wages: -$totalWages, Supplier: -$supplierCost)";
          break;
        case BusinessType.bakery:
          baseProfit = 200.0;
          desc = "Bakery Weekly Revenue";
          break;
        case BusinessType.pizzeria:
          baseProfit = 250.0;
          desc = "Pizzeria Weekly Revenue";
          break;
        case BusinessType.cafe:
          baseProfit = 180.0;
          desc = "Viennese Cafe Weekly Revenue";
          break;
        case BusinessType.opiateLab:
          baseProfit = 500.0;
          desc = "Opiate Lab Weekly Revenue";
          break;
        case BusinessType.lawPractice:
          baseProfit = 350.0;
          desc = "Law Chambers Weekly Revenue";
          break;
        case BusinessType.medicalPractice:
          baseProfit = 400.0;
          desc = "Medical Clinic Weekly Revenue";
          break;
        default:
          break;
      }

      if (baseProfit != 0.0) {
        addLedgerTransaction(bus.id, desc, baseProfit);
      }
    }
  }

  DragDropResult? resolveDragAndDropAction(NPC npc, Room room) {
    if (!room.isRestored) {
      if (room.name == 'Excavation Node') {
        return DragDropResult(action: TaskType.excavate, targetRoomId: room.id);
      }
      return DragDropResult(action: TaskType.restoreRoom, targetRoomId: room.id);
    }
    if (room.isUnderConstruction) {
      return DragDropResult(action: TaskType.construction, targetRoomId: room.id);
    }

    switch (room.type) {
      case RoomType.toilet:
        if (npc.digestion > 50.0) {
          return DragDropResult(action: TaskType.useToilet, targetRoomId: room.id);
        } else if (room.dirtiness > 0.05) {
          return DragDropResult(action: TaskType.cleanRoom, targetRoomId: room.id);
        } else {
          return DragDropResult(action: TaskType.washHands, targetRoomId: room.id);
        }

      case RoomType.kitchen:
        // 1. Cook next enqueued meal
        if (_cookingQueue.isNotEmpty) {
          return DragDropResult(action: TaskType.cook, targetRoomId: room.id);
        }
        // 2. Clean room if dirty
        if (room.dirtiness > 0.05) {
          return DragDropResult(action: TaskType.cleanRoom, targetRoomId: room.id);
        }
        // 3. Clean dirty dishes in the manor (if any)
        final hasDirtyDishes = (resources['dirty_dishes'] ?? 0) > 0 ||
            _rooms.any((r) => r.isRestored && r.inventory.any((item) => item.type == 'dirty_dishes' || item.id == 'dirty_dish'));
        if (hasDirtyDishes) {
          return DragDropResult(action: TaskType.cleanDish, targetRoomId: room.id);
        }
        // 4. Prepare default meal
        final allRecipes = KitchenService.getAvailableRecipes();
        final nonGenericRecipes = allRecipes.where((r) => r.id != 'protein_mistery_stew' && r.id != 'fried_generic_meat').toList();
        String? foundRecipeId;
        for (var r in nonGenericRecipes) {
          if (getPrepareableCopies(r) > 0) {
            foundRecipeId = r.id;
            break;
          }
        }
        if (foundRecipeId != null) {
          addToCookingQueue(foundRecipeId);
          return DragDropResult(action: TaskType.cook, targetRoomId: room.id);
        }
        // Check if grilled generic protein (fried_generic_meat) can be made
        final genericProtein = allRecipes.firstWhereOrNull((r) => r.id == 'fried_generic_meat');
        if (genericProtein != null && getPrepareableCopies(genericProtein) > 0) {
          addToCookingQueue('fried_generic_meat');
          return DragDropResult(action: TaskType.cook, targetRoomId: room.id);
        }
        // Perform ingredient prep [collect eggs, harvest produce]
        // Collect eggs
        final coop = _rooms.firstWhereOrNull((r) => r.id == 'chicken_coop' && r.isRestored);
        if (coop != null && coop.inventory.any((i) => i.type == 'eggs' || i.type == 'fertilized_egg')) {
          return DragDropResult(action: TaskType.collectEggs, targetRoomId: coop.id);
        }
        // Harvest produce
        final harvestableField = _rooms.firstWhereOrNull((r) =>
            r.isRestored &&
            (r.type == RoomType.field || r.type == RoomType.garden || r.type == RoomType.greenhouse) &&
            _crops.any((c) => c.roomId == r.id && c.isHarvestable));
        if (harvestableField != null) {
          return DragDropResult(action: TaskType.harvestCrops, targetRoomId: harvestableField.id);
        }
        // Butcher a creature/resident rodent > valuable animal > resident
        final rodents = butcheryTargets.where((t) {
          final id = t['id'].toString().toLowerCase();
          final name = t['name'].toString().toLowerCase();
          return id.contains('rat') || id.contains('bat') || id.contains('rodent') ||
                 name.contains('rat') || name.contains('bat') || name.contains('rodent');
        }).toList();
        if (rodents.isNotEmpty) {
          final t = rodents.first;
          addToCookingQueue('butcher_generic', targetId: t['id'], targetName: t['name']);
          return DragDropResult(action: TaskType.cook, targetRoomId: room.id);
        }
        final valuableAnimals = butcheryTargets.where((t) {
          final id = t['id'].toString().toLowerCase();
          final name = t['name'].toString().toLowerCase();
          final isChicken = _chickens.any((c) => c.id == t['id']) || name.contains('chicken');
          final isOtherAnimal = id.contains('cow') || id.contains('pig') || id.contains('cattle') || id.contains('sheep') || id.contains('goat') ||
                                name.contains('cow') || name.contains('pig') || name.contains('cattle') || name.contains('sheep') || name.contains('goat');
          final isSpecimen = inventory.any((item) => item.id == t['id'] && item.category == ItemCategory.specimen);
          return isChicken || isOtherAnimal || isSpecimen;
        }).toList();
        if (valuableAnimals.isNotEmpty) {
          final t = valuableAnimals.first;
          addToCookingQueue('butcher_generic', targetId: t['id'], targetName: t['name']);
          return DragDropResult(action: TaskType.cook, targetRoomId: room.id);
        }
        final residents = butcheryTargets.where((t) {
          final residentNpc = _npcs.firstWhereOrNull((n) => n.id == t['id']);
          return residentNpc != null && residentNpc.isResident && !residentNpc.isPlayer;
        }).toList();
        if (residents.isNotEmpty) {
          final t = residents.first;
          addToCookingQueue('butcher_generic', targetId: t['id'], targetName: t['name']);
          return DragDropResult(action: TaskType.cook, targetRoomId: room.id);
        }
        return null;

      case RoomType.study:
        if (_researchQueue.isNotEmpty) {
          return DragDropResult(action: TaskType.research, targetRoomId: room.id);
        }
        if (room.dirtiness > 0.05) {
          return DragDropResult(action: TaskType.cleanRoom, targetRoomId: room.id);
        }
        if (npc.isResident && npc.status != NPCStatus.zombie && (npc.stats['intellect'] ?? 5) >= 3) {
          return DragDropResult(action: TaskType.research, targetRoomId: room.id);
        }
        return null;

      case RoomType.field:
        final roomCrops = _crops.where((c) => c.roomId == room.id).toList();
        if (roomCrops.any((c) => c.isHarvestable)) {
          return DragDropResult(action: TaskType.harvestCrops, targetRoomId: room.id);
        }
        final isWateringEnqueued = _taskService.activeTasks.any(
          (t) => t.type == TaskType.waterCrops && t.targetId == room.id,
        ) || _npcs.any(
          (n) => n.intentQueue.any(
            (i) => i.action == TaskType.waterCrops && i.targetRoomId == room.id,
          ),
        );
        if (roomCrops.isNotEmpty && roomCrops.first.moistureLevel < 0.70 && !isWateringEnqueued) {
          return DragDropResult(action: TaskType.waterCrops, targetRoomId: room.id);
        }
        if (roomCrops.isNotEmpty) {
          return DragDropResult(action: TaskType.careForCrops, targetRoomId: room.id);
        }
        if (room.tilledAmount < 1.0) {
          return DragDropResult(action: TaskType.tillSoil, targetRoomId: room.id);
        }
        if (room.fertilizedAmount < 1.0) {
          return DragDropResult(action: TaskType.fertilizeSoil, targetRoomId: room.id);
        }
        // plant crops
        final minSeeds = room.tilledAmount >= 0.9 ? 10.0 : 5.0;
        final availableSeedTypes = CropType.values.where((type) {
          String seedId;
          if (type == CropType.grain) {
            seedId = 'grain';
          } else if (type == CropType.mushroom) {
            seedId = 'mushroom_spores';
          } else {
            seedId = 'seeds_${type.name}';
          }
          return (resources[seedId] ?? 0.0) >= minSeeds;
        }).toList();
        if (availableSeedTypes.isNotEmpty) {
          final favoriteCrop = availableSeedTypes.firstWhereOrNull((type) {
            final typeName = type.name.toLowerCase();
            final snakeTypeName = typeName.replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}');
            return npc.diet.favoriteFoods.any((food) {
              final foodLower = food.toLowerCase();
              return foodLower.contains(typeName) || foodLower.contains(snakeTypeName) ||
                     (type == CropType.fabaBean && foodLower.contains('faba')) ||
                     (type == CropType.greenBean && foodLower.contains('green_bean')) ||
                     (type == CropType.grain && foodLower.contains('grain'));
            });
          });
          if (favoriteCrop != null) {
            return DragDropResult(action: TaskType.plantCrops, targetRoomId: room.id, recipeId: favoriteCrop.name);
          }
          final cultivatedTypes = _crops.map((c) => c.type).toSet();
          final uncultivatedTypes = availableSeedTypes.where((type) => !cultivatedTypes.contains(type)).toList();
          if (uncultivatedTypes.isNotEmpty) {
            final selected = (List<CropType>.from(uncultivatedTypes)..shuffle(Random())).first;
            return DragDropResult(action: TaskType.plantCrops, targetRoomId: room.id, recipeId: selected.name);
          }
          final selected = (List<CropType>.from(availableSeedTypes)..shuffle(Random())).first;
          return DragDropResult(action: TaskType.plantCrops, targetRoomId: room.id, recipeId: selected.name);
        }
        return null;

      case RoomType.garden:
      case RoomType.greenhouse:
        final roomCrops = _crops.where((c) => c.roomId == room.id).toList();
        if (roomCrops.any((c) => c.isHarvestable)) {
          return DragDropResult(action: TaskType.harvestCrops, targetRoomId: room.id);
        }
        final isWateringEnqueued = _taskService.activeTasks.any(
          (t) => t.type == TaskType.waterCrops && t.targetId == room.id,
        ) || _npcs.any(
          (n) => n.intentQueue.any(
            (i) => i.action == TaskType.waterCrops && i.targetRoomId == room.id,
          ),
        );
        if (roomCrops.isNotEmpty && roomCrops.first.moistureLevel < 0.70 && !isWateringEnqueued) {
          return DragDropResult(action: TaskType.waterCrops, targetRoomId: room.id);
        }
        if (roomCrops.isNotEmpty) {
          return DragDropResult(action: TaskType.careForCrops, targetRoomId: room.id);
        }
        if (room.dirtiness > 0.05) {
          return DragDropResult(action: TaskType.cleanRoom, targetRoomId: room.id);
        }
        final hasRefineable = (resources['cannabis_buds'] ?? 0) >= 2 ||
                              (resources['tobacco_leaves'] ?? 0) >= 2 ||
                              (resources['hallucinogenic_mushrooms'] ?? 0) >= 2;
        if (hasRefineable) {
          return DragDropResult(action: TaskType.refinePlantFungus, targetRoomId: room.id);
        }
        return null;

      case RoomType.chickenCoop:
        if (room.dirtiness > 0.05) {
          return DragDropResult(action: TaskType.cleanRoom, targetRoomId: room.id);
        }
        if (room.inventory.any((i) => i.type == 'eggs' || i.type == 'fertilized_egg')) {
          return DragDropResult(action: TaskType.collectEggs, targetRoomId: room.id);
        }
        return DragDropResult(action: TaskType.guardCoop, targetRoomId: room.id);

      case RoomType.laboratory:
        if (room.dirtiness > 0.05) {
          return DragDropResult(action: TaskType.cleanRoom, targetRoomId: room.id);
        }
        if (npc.isResident && npc.status != NPCStatus.zombie && (npc.stats['intellect'] ?? 5) >= 3) {
          return DragDropResult(action: TaskType.experiment, targetRoomId: room.id);
        }
        return null;

      case RoomType.operatingRoom:
      case RoomType.dentalClinic:
        if (room.dirtiness > 0.05) {
          return DragDropResult(action: TaskType.cleanRoom, targetRoomId: room.id);
        }
        if (room.type == RoomType.dentalClinic) {
          return DragDropResult(action: TaskType.dentalWork, targetRoomId: room.id);
        }
        return DragDropResult(action: TaskType.operation, targetRoomId: room.id);

      case RoomType.library:
        if (room.dirtiness > 0.05) {
          return DragDropResult(action: TaskType.cleanRoom, targetRoomId: room.id);
        }
        if (npc.isResident && npc.status != NPCStatus.zombie && (npc.stats['intellect'] ?? 5) >= 3) {
          return DragDropResult(action: TaskType.study, targetRoomId: room.id);
        }
        return null;

      case RoomType.brewery:
        if (room.dirtiness > 0.05) {
          return DragDropResult(action: TaskType.cleanRoom, targetRoomId: room.id);
        }
        return DragDropResult(action: TaskType.brew, targetRoomId: room.id);

      case RoomType.distillery:
        if (room.dirtiness > 0.05) {
          return DragDropResult(action: TaskType.cleanRoom, targetRoomId: room.id);
        }
        return DragDropResult(action: TaskType.distill, targetRoomId: room.id);

      case RoomType.workshop:
        if (room.dirtiness > 0.05) {
          return DragDropResult(action: TaskType.cleanRoom, targetRoomId: room.id);
        }
        if ((resources['wood'] ?? 0) >= 10) {
          return DragDropResult(action: TaskType.processTimber, targetRoomId: room.id);
        }
        return DragDropResult(action: TaskType.manufacturing, targetRoomId: room.id);

      case RoomType.granary:
        if (room.dirtiness > 0.05) {
          return DragDropResult(action: TaskType.cleanRoom, targetRoomId: room.id);
        }
        return DragDropResult(action: TaskType.harvestGrain, targetRoomId: room.id);

      case RoomType.bedroom:
      case RoomType.butlerQuarters:
      case RoomType.attic:
      case RoomType.basement:
      case RoomType.tenement:
        if (room.dirtiness > 0.05) {
          return DragDropResult(action: TaskType.cleanRoom, targetRoomId: room.id);
        }
        return DragDropResult(action: TaskType.rest, targetRoomId: room.id);

      case RoomType.diningRoom:
        if (room.dirtiness > 0.05) {
          return DragDropResult(action: TaskType.cleanRoom, targetRoomId: room.id);
        }
        return DragDropResult(action: TaskType.eat, targetRoomId: room.id);

      case RoomType.entryway:
        final guestNpc = _npcs.firstWhereOrNull((n) => !n.isResident && n.currentRoomId == 'entryway' && n.metadata['isGreeted'] != true);
        if (guestNpc != null) {
          return DragDropResult(action: TaskType.greetGuest, targetRoomId: room.id);
        }
        return DragDropResult(action: TaskType.defendManor, targetRoomId: room.id);

      case RoomType.unused:
        if ((resources['funds'] ?? 0) >= 20 && (resources['wood'] ?? 0) >= 15 && (resources['timber'] ?? 0) >= 5) {
          return DragDropResult(action: TaskType.setupBrewery, targetRoomId: room.id);
        }
        if ((resources['funds'] ?? 0) >= 30 && (resources['wood'] ?? 0) >= 10 && (resources['timber'] ?? 0) >= 10) {
          return DragDropResult(action: TaskType.setupDistillery, targetRoomId: room.id);
        }
        if ((resources['funds'] ?? 0) >= 15 && (resources['wood'] ?? 0) >= 20 && (resources['timber'] ?? 0) >= 5) {
          return DragDropResult(action: TaskType.setupWorkshop, targetRoomId: room.id);
        }
        if ((resources['funds'] ?? 0) >= 10 && (resources['wood'] ?? 0) >= 15 && (resources['timber'] ?? 0) >= 10) {
          return DragDropResult(action: TaskType.setupGranary, targetRoomId: room.id);
        }
        return null;

      case RoomType.mine:
      case RoomType.oilWell:
        if (room.dirtiness > 0.05) {
          return DragDropResult(action: TaskType.cleanRoom, targetRoomId: room.id);
        }
        return DragDropResult(action: TaskType.mining, targetRoomId: room.id);

      default:
        if (room.dirtiness > 0.05) {
          return DragDropResult(action: TaskType.cleanRoom, targetRoomId: room.id);
        }
        final defaultAct = room.defaultAction;
        if (defaultAct != null) {
          return DragDropResult(action: defaultAct, targetRoomId: room.id);
        }
        return null;
    }
  }
}

class DragDropResult {
  final TaskType action;
  final String targetRoomId;
  final String? recipeId;
  final String? targetName;

  DragDropResult({
    required this.action,
    required this.targetRoomId,
    this.recipeId,
    this.targetName,
  });
}

class AnnouncementList extends ListBase<String> {
  final List<String> _inner = [];
  final GameState _state;

  AnnouncementList(this._state);

  @override
  int get length => _inner.length;

  @override
  set length(int newLength) {
    _inner.length = newLength;
  }

  @override
  String operator [](int index) => _inner[index];

  @override
  void operator []=(int index, String value) {
    _inner[index] = value;
  }

  @override
  void add(String element) {
    _inner.add(_formatElement(element));
  }

  @override
  void insert(int index, String element) {
    // Instead of inserting at 'index' (which is 0 for new announcements),
    // we add it to the bottom of the list.
    _inner.add(_formatElement(element));
  }

  @override
  void addAll(Iterable<String> iterable) {
    _inner.addAll(iterable.map(_formatElement));
  }

  @override
  String removeLast() {
    // Since new items are appended to the bottom, the oldest items are at index 0.
    // So removeLast removes the oldest item from the top of the list.
    if (_inner.isNotEmpty) {
      return _inner.removeAt(0);
    }
    throw StateError("No elements");
  }

  @override
  void clear() {
    _inner.clear();
  }

  String _formatElement(String element) {
    if (element.startsWith(RegExp(r'^\[[A-Za-z]{3}\s\d{1,2}\s\d{2}:\d{2}\]')) ||
        element.startsWith(RegExp(r'^\[[A-Za-z]{3}\s\d{1,2}\]'))) {
      return element;
    }
    final date = _state.currentDate;
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final monthStr = months[date.month - 1];
    final dayStr = date.day.toString().padLeft(2, '0');
    
    if (element.startsWith('[')) {
      final closeBracketIdx = element.indexOf(']');
      if (closeBracketIdx != -1) {
        final inside = element.substring(1, closeBracketIdx);
        if (RegExp(r'^\d{2}:\d{2}$').hasMatch(inside)) {
          final rest = element.substring(closeBracketIdx + 1).trim();
          return "[$monthStr $dayStr $inside] $rest";
        } else {
          return "[$monthStr $dayStr ${date.formattedTime}] $element";
        }
      }
    }
    
    return "[$monthStr $dayStr ${date.formattedTime}] $element";
  }
}

