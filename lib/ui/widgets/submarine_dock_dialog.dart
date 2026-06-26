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

import 'dart:math' show Random;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart' show globalGameState;
import '../../state/game_state.dart';
import '../../models/game_item.dart';
import '../../models/survival_state.dart';
import '../../services/survival_service.dart';

void showSubmarineDockDialog(
  BuildContext context, {
  SurvivalService? survivalService,
}) {
  final bool isSurvival = survivalService != null;
  final progress = isSurvival ? survivalService.progress! : null;
  final state = globalGameState!;

  final bool hasSubTech = state.unlockedDiscoveries.contains('submersible_tech');
  final bool hasAbyssNav = state.unlockedDiscoveries.contains('deep_abyss_navigation');
  final bool hasSonarTech = state.unlockedDiscoveries.contains('deep_sea_sonar');

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final double woodAvailable = isSurvival 
              ? progress!.wood.toDouble() 
              : (state.resources['wood'] ?? 0.0).toDouble();
          final double ironAvailable = isSurvival 
              ? progress!.iron.toDouble() 
              : (state.resources['iron'] ?? 0.0).toDouble();
          final double cashAvailable = isSurvival 
              ? progress!.cash.toDouble() 
              : (state.resources['funds'] ?? 0.0).toDouble();

          final bool hasSub = isSurvival 
              ? progress!.cardUpgrades['has_submarine'] == 1
              : state.submarineState['has_submarine'] == true;

          final int subLvl = isSurvival 
              ? progress!.cardUpgrades['submarine_level'] ?? 1
              : state.submarineState['submarine_level'] ?? 1;

          final bool isDamaged = isSurvival 
              ? progress!.cardUpgrades['submarine_damaged'] == 1
              : state.submarineState['submarine_damaged'] == true;

          final bool hasHull = isSurvival 
              ? progress!.cardUpgrades['sub_gadget_hull'] == 1
              : state.submarineState['sub_gadget_hull'] == true;

          final bool hasSonar = isSurvival 
              ? progress!.cardUpgrades['sub_gadget_sonar'] == 1
              : state.submarineState['sub_gadget_sonar'] == true;

          final bool hasCargo = isSurvival 
              ? progress!.cardUpgrades['sub_gadget_cargo'] == 1
              : state.submarineState['sub_gadget_cargo'] == true;

          final bool canBuild = woodAvailable >= 250 && ironAvailable >= 150 && cashAvailable >= 200;

          void deductResources(int wood, int iron, int cash) {
            if (isSurvival) {
              progress!.wood -= wood;
              progress!.iron -= iron;
              progress!.cash -= cash;
            } else {
              state.updateResource('wood', -wood);
              state.updateResource('iron', -iron);
              state.updateResource('funds', -cash);
            }
          }

          void setVal(String key, dynamic val) {
            if (isSurvival) {
              progress!.cardUpgrades[key] = (val is bool) ? (val ? 1 : 0) : val;
            } else {
              state.updateSubmarineState(key, val);
            }
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF1E1712),
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: const Color(0xFFC4B89B).withOpacity(0.4),
                width: 1.5,
              ),
            ),
            title: Text(
              'MANOR GARAGE & SUBMERSIBLE DOCK',
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFE5D5B0),
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!hasSub) ...[
                      Center(
                        child: Icon(
                          Icons.directions_boat,
                          color: const Color(0xFFC4B89B).withOpacity(0.5),
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No active submersible vessel is currently constructed in the dry dock. A submarine allows deep-water lake exploration to harvest unique specimens and discover sunken alchemical treasures.',
                        style: GoogleFonts.oldStandardTt(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 8),
                      Text(
                        'CONSTRUCTION REQUIREMENTS:',
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildReqRow('Discovery: Submersible Design', hasSubTech),
                      _buildReqRow('Wood: 250 units (Have: ${woodAvailable.toInt()})', woodAvailable >= 250),
                      _buildReqRow('Iron: 150 units (Have: ${ironAvailable.toInt()})', ironAvailable >= 150),
                      _buildReqRow('Capital: 200 CHF (Have: ${cashAvailable.toInt()})', cashAvailable >= 200),
                      const SizedBox(height: 16),
                      if (hasSubTech)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canBuild ? const Color(0xFF2E1A0A) : Colors.transparent,
                              side: BorderSide(
                                color: canBuild ? const Color(0xFFC4B89B) : Colors.white10,
                              ),
                              shape: const RoundedRectangleBorder(),
                            ),
                            onPressed: canBuild
                                ? () {
                                    deductResources(250, 150, 200);
                                    setVal('has_submarine', true);
                                    setVal('submarine_level', 1);
                                    if (isSurvival) {
                                      survivalService.addLog('CONSTRUCTED SUBMARINE: Unlocked deep-lake submersible exploration in the Manor Garage!');
                                      survivalService.manualSave();
                                    } else {
                                      state.addAnnouncement('Constructed Submarine dry dock for Lac Léman exploration!');
                                    }
                                    setDialogState(() {});
                                  }
                                : null,
                            child: Text(
                              'CONSTRUCT SUBMARINE',
                              style: GoogleFonts.playfairDisplay(
                                color: canBuild ? const Color(0xFFE5D5B0) : Colors.white24,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Text(
                            'Requires "Submersible Design" discovery in the Study to unlock construction.',
                            style: GoogleFonts.oldStandardTt(
                              color: Colors.redAccent.withOpacity(0.7),
                              fontSize: 10.5,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ] else ...[
                      _buildRow('Submarine Status', isDamaged ? 'DAMAGED (Requires Repairs)' : 'FUNCTIONAL'),
                      _buildRow('Hull Strength', hasHull ? 'Reinforced (+20% Safety)' : 'Standard'),
                      _buildRow('Acoustic Suite', hasSonar ? 'Bio-Sonar (+40% Treasure)' : 'None'),
                      _buildRow('Cargo Capacity', hasCargo ? 'Specimen Cell (Double Yield)' : 'Standard'),
                      const SizedBox(height: 8),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 8),
                      
                      if (isDamaged) ...[
                        Text(
                          'The submarine hull has sustained severe damage during a deep-sea trench collision and cannot dive.',
                          style: GoogleFonts.oldStandardTt(
                            color: Colors.redAccent.withOpacity(0.8),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ironAvailable >= 100 ? const Color(0xFF2E1A0A) : Colors.transparent,
                              side: BorderSide(
                                color: ironAvailable >= 100 ? const Color(0xFFC4B89B) : Colors.white10,
                              ),
                              shape: const RoundedRectangleBorder(),
                            ),
                            onPressed: ironAvailable >= 100
                                ? () {
                                    if (isSurvival) {
                                      progress!.iron -= 100;
                                      survivalService.addLog('REPAIRED SUBMARINE: Restored hull integrity at the Garage.');
                                      survivalService.manualSave();
                                    } else {
                                      state.updateResource('iron', -100);
                                      state.addAnnouncement('Repaired Submarine hull integrity at the Dock.');
                                    }
                                    setVal('submarine_damaged', false);
                                    setDialogState(() {});
                                  }
                                : null,
                            child: Text(
                              'REPAIR SUBMARINE (Cost: 100 Iron)',
                              style: GoogleFonts.playfairDisplay(
                                color: ironAvailable >= 100 ? const Color(0xFFE5D5B0) : Colors.white24,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'LAUNCH SUBMERSIBLE EXPEDITION',
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFFE5D5B0),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildExpLaunchRow(context, survivalService, setDialogState, 1, 'Shallow Waters (Lvl 1)', isSurvival ? 20 : 25, true),
                        _buildExpLaunchRow(context, survivalService, setDialogState, 2, 'Mid-Depths (Lvl 2)', isSurvival ? 30 : 50, subLvl >= 2 && hasAbyssNav),
                        _buildExpLaunchRow(context, survivalService, setDialogState, 3, 'Abyssal Trenches (Lvl 3)', isSurvival ? 40 : 75, subLvl >= 3 && hasSonarTech),
                      ],
                      const SizedBox(height: 8),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 8),
                      
                      Text(
                        'FACILITY UPGRADES & GADGETS',
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      if (subLvl < 3) ...[
                        _buildLvlUpgradeButton(survivalService, setDialogState, subLvl, hasAbyssNav, hasSonarTech, woodAvailable, ironAvailable, cashAvailable),
                        const SizedBox(height: 8),
                      ],
                      
                      if (!hasHull) ...[
                        _buildGButton(
                          survivalService: survivalService,
                          setDialogState: setDialogState,
                          gadgetKey: 'sub_gadget_hull',
                          name: 'Reinforced Steel Hull',
                          desc: 'Reduces exploration accident rates by 20%.',
                          costWood: 0,
                          costIron: 150,
                          costCash: 200,
                          unlocked: true,
                          woodAvailable: woodAvailable,
                          ironAvailable: ironAvailable,
                          cashAvailable: cashAvailable,
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      if (!hasSonar) ...[
                        _buildGButton(
                          survivalService: survivalService,
                          setDialogState: setDialogState,
                          gadgetKey: 'sub_gadget_sonar',
                          name: 'Abyssal Bio-Sonar',
                          desc: 'Requires "Abyssal Bio-Sonar" discovery. Increases treasure yields +40%.',
                          costWood: 0,
                          costIron: 100,
                          costCash: 300,
                          unlocked: hasSonarTech,
                          woodAvailable: woodAvailable,
                          ironAvailable: ironAvailable,
                          cashAvailable: cashAvailable,
                        ),
                        const SizedBox(height: 8),
                      ],

                      if (!hasCargo) ...[
                        _buildGButton(
                          survivalService: survivalService,
                          setDialogState: setDialogState,
                          gadgetKey: 'sub_gadget_cargo',
                          name: 'Specimen Containment Cell',
                          desc: 'Provides double specimen yields on successful dives.',
                          costWood: 150,
                          costIron: 0,
                          costCash: 100,
                          unlocked: true,
                          woodAvailable: woodAvailable,
                          ironAvailable: ironAvailable,
                          cashAvailable: cashAvailable,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'CLOSE',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _buildReqRow(String text, bool met) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0),
    child: Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.cancel,
          color: met ? Colors.green : Colors.redAccent,
          size: 14,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.oldStandardTt(
              color: met ? Colors.white70 : Colors.white30,
              fontSize: 11,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildRow(String label, String val) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFC4B89B),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          val,
          style: GoogleFonts.oldStandardTt(
            color: Colors.white,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}

Widget _buildExpLaunchRow(
  BuildContext context,
  SurvivalService? survivalService,
  StateSetter setDialogState,
  int depth,
  String depthName,
  int costAmount,
  bool unlocked,
) {
  final bool isSurvival = survivalService != null;
  final progress = isSurvival ? survivalService.progress! : null;
  final state = globalGameState!;

  final bool alreadyRun = isSurvival 
      ? progress!.cardUpgrades['sub_expedition_turn'] == progress.currentTurn
      : state.submarineState['last_expedition_day'] == state.currentDate.day;

  final bool hasCost = isSurvival 
      ? progress!.food >= costAmount
      : (state.resources['funds'] ?? 0.0) >= costAmount;

  final bool canLaunch = unlocked && !alreadyRun && hasCost;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              depthName,
              style: GoogleFonts.oldStandardTt(
                color: unlocked ? Colors.white70 : Colors.white24,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              isSurvival ? 'Cost: $costAmount Food' : 'Cost: $costAmount CHF',
              style: GoogleFonts.oldStandardTt(
                color: unlocked ? Colors.white38 : Colors.white10,
                fontSize: 10,
              ),
            ),
          ],
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: canLaunch ? const Color(0xFF2E1A0A) : Colors.transparent,
            side: BorderSide(
              color: canLaunch ? const Color(0xFFC4B89B) : Colors.white10,
            ),
            shape: const RoundedRectangleBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
          onPressed: canLaunch
              ? () {
                  Navigator.pop(context);
                  _runExpedition(context, survivalService, depth, costAmount);
                }
              : null,
          child: Text(
            alreadyRun ? 'RESTING' : (unlocked ? 'LAUNCH' : 'LOCKED'),
            style: GoogleFonts.playfairDisplay(
              color: canLaunch ? const Color(0xFFE5D5B0) : Colors.white24,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildLvlUpgradeButton(
  SurvivalService? survivalService,
  StateSetter setDialogState,
  int curLvl,
  bool hasAbyssNav,
  bool hasSonarTech,
  double woodAvail,
  double ironAvail,
  double cashAvail,
) {
  final bool isSurvival = survivalService != null;
  final progress = isSurvival ? survivalService.progress! : null;
  final state = globalGameState!;
  final int nextLvl = curLvl + 1;
  
  final int costWood = nextLvl == 2 ? 300 : 400;
  final int costIron = nextLvl == 2 ? 250 : 400;
  final int costCash = nextLvl == 2 ? 400 : 600;

  final bool reqDiscovery = nextLvl == 2 ? hasAbyssNav : hasSonarTech;
  final String discName = nextLvl == 2 ? 'Abyssal Navigation' : 'Abyssal Bio-Sonar';

  final bool canUpgrade = reqDiscovery &&
      woodAvail >= costWood &&
      ironAvail >= costIron &&
      cashAvail >= costCash;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: canUpgrade ? const Color(0xFF2E1A0A) : Colors.transparent,
            side: BorderSide(
              color: canUpgrade ? const Color(0xFFC4B89B) : Colors.white10,
            ),
            shape: const RoundedRectangleBorder(),
          ),
          onPressed: canUpgrade
              ? () {
                  if (isSurvival) {
                    progress!.wood -= costWood;
                    progress.iron -= costIron;
                    progress.cash -= costCash;
                    progress.cardUpgrades['submarine_level'] = nextLvl;
                    survivalService.addLog('UPGRADED SUBMARINE: Promoted vessel to Level $nextLvl!');
                    survivalService.manualSave();
                  } else {
                    state.updateResource('wood', -costWood);
                    state.updateResource('iron', -costIron);
                    state.updateResource('funds', -costCash);
                    state.updateSubmarineState('submarine_level', nextLvl);
                    state.addAnnouncement('Upgraded Submarine to Level $nextLvl!');
                  }
                  setDialogState(() {});
                }
              : null,
          child: Text(
            'UPGRADE SUBMARINE TO LVL $nextLvl',
            style: GoogleFonts.playfairDisplay(
              color: canUpgrade ? const Color(0xFFE5D5B0) : Colors.white24,
              fontWeight: FontWeight.bold,
              fontSize: 10.5,
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 2.0, left: 4.0),
        child: Text(
          'Requires: $discName, $costWood Wood, $costIron Iron, $costCash CHF.',
          style: GoogleFonts.oldStandardTt(
            color: reqDiscovery ? Colors.white38 : Colors.redAccent.withOpacity(0.5),
            fontSize: 9.5,
          ),
        ),
      ),
    ],
  );
}

Widget _buildGButton({
  required SurvivalService? survivalService,
  required StateSetter setDialogState,
  required String gadgetKey,
  required String name,
  required String desc,
  required int costWood,
  required int costIron,
  required int costCash,
  required bool unlocked,
  required double woodAvailable,
  required double ironAvailable,
  required double cashAvailable,
}) {
  final bool isSurvival = survivalService != null;
  final progress = isSurvival ? survivalService.progress! : null;
  final state = globalGameState!;

  final bool canBuy = unlocked &&
      woodAvailable >= costWood &&
      ironAvailable >= costIron &&
      cashAvailable >= costCash;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: canBuy ? const Color(0xFF2E1A0A) : Colors.transparent,
            side: BorderSide(
              color: canBuy ? const Color(0xFFC4B89B) : Colors.white10,
            ),
            shape: const RoundedRectangleBorder(),
          ),
          onPressed: canBuy
              ? () {
                  if (isSurvival) {
                    progress!.wood -= costWood;
                    progress.iron -= costIron;
                    progress.cash -= costCash;
                    progress.cardUpgrades[gadgetKey] = 1;
                    survivalService.addLog('INSTALLED GADGET: Equipped submarine with $name.');
                    survivalService.manualSave();
                  } else {
                    state.updateResource('wood', -costWood);
                    state.updateResource('iron', -costIron);
                    state.updateResource('funds', -costCash);
                    state.updateSubmarineState(gadgetKey, true);
                    state.addAnnouncement('Installed $name on Submarine.');
                  }
                  setDialogState(() {});
                }
              : null,
          child: Text(
            'INSTALL $name',
            style: GoogleFonts.playfairDisplay(
              color: canBuy ? const Color(0xFFE5D5B0) : Colors.white24,
              fontWeight: FontWeight.bold,
              fontSize: 10.5,
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 2.0, left: 4.0),
        child: Text(
          '$desc Cost: ${costWood > 0 ? "$costWood Wood, " : ""}${costIron > 0 ? "$costIron Iron, " : ""}$costCash CHF.',
          style: GoogleFonts.oldStandardTt(
            color: unlocked ? Colors.white38 : Colors.redAccent.withOpacity(0.5),
            fontSize: 9.5,
          ),
        ),
      ),
    ],
  );
}

void _runExpedition(
  BuildContext context,
  SurvivalService? survivalService,
  int depth,
  int costAmount,
) {
  final bool isSurvival = survivalService != null;
  final progress = isSurvival ? survivalService.progress! : null;
  final state = globalGameState!;

  if (isSurvival) {
    progress!.food -= costAmount;
    progress.cardUpgrades['sub_expedition_turn'] = progress.currentTurn;
  } else {
    state.updateResource('funds', -costAmount);
    state.updateSubmarineState('last_expedition_day', state.currentDate.day);
  }

  final bool hasHull = isSurvival 
      ? progress!.cardUpgrades['sub_gadget_hull'] == 1
      : state.submarineState['sub_gadget_hull'] == true;

  final bool hasSonar = isSurvival 
      ? progress!.cardUpgrades['sub_gadget_sonar'] == 1
      : state.submarineState['sub_gadget_sonar'] == true;

  final bool hasCargo = isSurvival 
      ? progress!.cardUpgrades['sub_gadget_cargo'] == 1
      : state.submarineState['sub_gadget_cargo'] == true;

  final double successChance = hasHull ? 0.90 : 0.70;
  final bool isSuccess = Random().nextDouble() < successChance;

  String title = '';
  String story = '';
  String lootDescription = '';

  if (isSuccess) {
    title = 'EXPEDITION SUCCESSFUL';
    final int cargoMultiplier = hasCargo ? 2 : 1;

    if (depth == 1) {
      if (isSurvival) {
        progress!.food += 100;
        progress.wood += 50;
      } else {
        state.updateResource('wood', 50);
      }
      
      final codCount = 1 * cargoMultiplier;
      final specimen = GameItem.create(
        name: 'Shallow Cod Specimen',
        type: 'fish_specimen',
        category: ItemCategory.specimen,
        quantity: codCount,
        quality: 1.0,
        metadata: {'discipline': 'Zoology: Fish', 'isResearched': false},
      );
      state.addItemToRoom('library', specimen);

      story = 'The submersible vessel glided smoothly through the shallow, sun-dappled lake waters, mapping the littoral shelf and harvesting biological specimens.';
      lootDescription = isSurvival 
          ? 'Loot Harvested:\n• +100 Food\n• +50 Wood\n• +$codCount Shallow Cod Specimen (delivered to Manor Study)'
          : 'Loot Harvested:\n• +50 Wood\n• +$codCount Shallow Cod Specimen (delivered to Manor Library)';
      if (isSurvival) {
        survivalService.addLog('Submarine Expedition: Shallow waters dive successful.');
      } else {
        state.addAnnouncement('Submarine Expedition: Shallow waters dive successful. Retreived $codCount specimens.');
      }
    } else if (depth == 2) {
      if (isSurvival) {
        progress!.food += 200;
        progress.iron += 100;
        progress.cash += 150;
      } else {
        state.updateResource('iron', 100);
        state.updateResource('funds', 150);
      }

      final codCount = 2 * cargoMultiplier;
      final specimen = GameItem.create(
        name: 'Benthic Angler Specimen',
        type: 'fish_specimen',
        category: ItemCategory.specimen,
        quantity: codCount,
        quality: 1.2,
        metadata: {'discipline': 'Zoology: Fish', 'isResearched': false},
      );
      state.addItemToRoom('library', specimen);

      story = 'Descending past the photic zone, the crew entered the cold, high-pressure mid-depths. The submarine spotlight pierced the gloom, revealing benthic life and rusted iron debris.';
      lootDescription = 'Loot Harvested:\n• +100 Iron\n• +150 CHF\n• +$codCount Benthic Angler Specimen';
      if (isSurvival) {
        survivalService.addLog('Submarine Expedition: Mid-depths dive successful.');
      } else {
        state.addAnnouncement('Submarine Expedition: Mid-depths dive successful.');
      }
    } else {
      int cashGained = 400;
      if (isSurvival) {
        progress!.iron += 300;
      } else {
        state.updateResource('iron', 300);
      }

      final abyssalCount = 3 * cargoMultiplier;
      final specimen = GameItem.create(
        name: 'Mutated Abyssal Chimera Fish',
        type: 'fish_specimen',
        category: ItemCategory.specimen,
        quantity: abyssalCount,
        quality: 1.8,
        metadata: {'discipline': 'Zoology: Fish', 'isResearched': false},
      );
      state.addItemToRoom('library', specimen);

      String sonarLoot = '';
      if (hasSonar) {
        cashGained += 200;
        sonarLoot = '\n• +200 CHF Sunken Treasure (detected by Bio-Sonar)';
      }
      if (isSurvival) {
        progress!.cash += cashGained;
      } else {
        state.updateResource('funds', cashGained);
      }

      final pearl = GameItem.create(
        name: 'Abyssal Black Pearl',
        type: 'abyssal_pearl',
        category: ItemCategory.material,
        quantity: 1,
        quality: 2.0,
        value: 500,
      );
      state.addItemToRoom('library', pearl);

      story = 'The steel hull groaned as the submarine descended into the ink-black Abyssal Trench. In the freezing pressure, the crew discovered glowing geothermal vents and retrieved ancient, mutated chimerical life!';
      lootDescription = 'Loot Harvested:\n• +$cashGained CHF$sonarLoot\n• +300 Iron\n• +$abyssalCount Mutated Abyssal Chimera Fish\n• 1x Abyssal Black Pearl (delivered to Manor)';
      if (isSurvival) {
        survivalService.addLog('Submarine Expedition: Abyssal Trench dive successful.');
      } else {
        state.addAnnouncement('Submarine Expedition: Abyssal Trench dive successful.');
      }
    }
  } else {
    title = 'EXPEDITION ACCIDENT';
    if (depth == 1) {
      story = 'A sudden pressure valve leak caused minor flooding in the cabin. The crew managed to patch the valve, but the close call shook their nerves.';
      lootDescription = isSurvival 
          ? 'Consequences:\n• Crew loses 10 satisfaction due to panic.'
          : 'Consequences:\n• Crew members shaken.';
      if (isSurvival) {
        final farm = progress!.buildings.firstWhereOrNull((b) => b.type == SurvivalBuildingType.farm);
        if (farm != null && farm.assignedUnitIds.isNotEmpty) {
          final target = farm.assignedUnitIds.first;
          progress.bondageDebuffCount[target] = (progress.bondageDebuffCount[target] ?? 0) + 1;
        }
        survivalService.addLog('Submarine Expedition: Minor cabin flooding in shallow waters.');
      } else {
        state.addAnnouncement('Submarine Expedition: Minor cabin flooding in shallow waters.');
      }
    } else if (depth == 2) {
      if (isSurvival) {
        progress!.cardUpgrades['submarine_damaged'] = 1;
        final farm = progress.buildings.firstWhereOrNull((b) => b.type == SurvivalBuildingType.farm);
        if (farm != null && farm.assignedUnitIds.isNotEmpty) {
          final target = farm.assignedUnitIds.first;
          progress.bondageDebuffCount[target] = (progress.bondageDebuffCount[target] ?? 0) + 1;
        }
        survivalService.addLog('Submarine Expedition: Hull collision in mid-depths; vessel damaged.');
      } else {
        state.updateSubmarineState('submarine_damaged', true);
        state.addAnnouncement('Submarine Expedition: Hull collision in mid-depths; vessel damaged.');
      }
      story = 'A sudden hydrothermal surge slammed the submarine into an underwater reef, fracturing the outer hull plating. The crew made an emergency ascent.';
      lootDescription = 'Consequences:\n• Submarine is DAMAGED and cannot dive until repaired (Cost: 100 Iron).\n• 1 worker suffers pressure sickness.';
    } else {
      if (isSurvival) {
        progress!.cardUpgrades['submarine_damaged'] = 1;
        progress.factionStandings['Glarus'] = (progress.factionStandings['Glarus'] ?? 0) - 15;
        final farm = progress.buildings.firstWhereOrNull((b) => b.type == SurvivalBuildingType.farm);
        if (farm != null && farm.assignedUnitIds.isNotEmpty) {
          final target = farm.assignedUnitIds.first;
          progress.bondageDebuffCount[target] = (progress.bondageDebuffCount[target] ?? 0) + 1;
        }
        survivalService.addLog('Submarine Expedition: Beast attack in abyssal trench; vessel heavily damaged.');
      } else {
        state.updateSubmarineState('submarine_damaged', true);
        state.addAnnouncement('Submarine Expedition: Beast attack in abyssal trench; vessel heavily damaged.');
      }
      story = 'Disaster in the trench! A gargantuan chimerical sea beast, provoked by the submarine\'s spotlight, attacked the vessel, crushing the observation dome. The crew barely escaped with their lives!';
      lootDescription = 'Consequences:\n• Submarine is HEAVILY DAMAGED and cannot dive.\n• 1 worker suffers pressure sickness.\n• Local villagers are terrified (-15 Faction Standing).';
    }
  }

  if (isSurvival) {
    survivalService.manualSave();
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1A130F),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: isSuccess ? const Color(0xFFD4AF37) : Colors.redAccent,
            width: 2.0,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.playfairDisplay(
            color: isSuccess ? const Color(0xFFE5D5B0) : Colors.redAccent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                story,
                style: GoogleFonts.oldStandardTt(
                  color: Colors.white70,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              Text(
                lootDescription,
                style: GoogleFonts.playfairDisplay(
                  color: isSuccess ? const Color(0xFFE5D5B0) : Colors.redAccent.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E1A0A),
              side: const BorderSide(color: Color(0xFFC4B89B)),
              shape: const RoundedRectangleBorder(),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'ACKNOWLEDGE',
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFE5D5B0),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      );
    },
  );
}
