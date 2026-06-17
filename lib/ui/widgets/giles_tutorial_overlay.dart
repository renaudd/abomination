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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import 'character_blob_renderer.dart';

class GilesTutorialOverlay extends StatelessWidget {
  const GilesTutorialOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        final step = state.gilesTutorialStep;
        if (step == GilesTutorialStep.inactive) {
          return const SizedBox.shrink();
        }

        final gilesNpc = state.npcs.firstWhere(
          (n) => n.role == 'Butler',
          orElse: () => state.npcs.isNotEmpty ? state.npcs.first : throw Exception("No characters found"),
        );

        String dialogueText = "";
        String actionLabel = "SKIP STEP";
        VoidCallback? onAction;

        switch (step) {
          case GilesTutorialStep.intro:
            dialogueText = "Ah, Master ${state.playerLastName}. Welcome to your ancestral domain. Let me explain how our estate Wing rooms operate.";
            actionLabel = "NEXT";
            onAction = () => state.advanceGilesTutorial(GilesTutorialStep.selectKitchen);
            break;
          case GilesTutorialStep.selectKitchen:
            dialogueText =
                "First, select the Kitchen by tapping on it in the Manor layout above.";
            onAction = () => state.advanceGilesTutorial(GilesTutorialStep.enterKitchen);
            break;
          case GilesTutorialStep.enterKitchen:
            dialogueText =
                "Now, enter the Kitchen by pressing the ENTER KITCHEN button in the room details panel.";
            onAction = () => state.advanceGilesTutorial(GilesTutorialStep.commencePrep);
            break;
          case GilesTutorialStep.commencePrep:
            dialogueText =
                "Commence preparation of a Faba & Green Bean Stew by enqueuing it in the preparation ledger.";
            onAction = () => state.advanceGilesTutorial(GilesTutorialStep.assignResident);
            break;
          case GilesTutorialStep.assignResident:
            dialogueText =
                "Now, return to the Manor View and drag a resident onto the Kitchen to assign the task. (You should probably let me do it, Master ${state.playerLastName}.)";
            onAction = () => state.advanceGilesTutorial(GilesTutorialStep.playClock);
            break;
          case GilesTutorialStep.playClock:
            dialogueText =
                "Click on the time display in the top right corner of the screen, and press the NORMAL button to start the game clock.";
            onAction = () => state.advanceGilesTutorial(GilesTutorialStep.selectCoop);
            break;
          case GilesTutorialStep.selectCoop:
            dialogueText =
                "Excellent. Time marches forward. Now, select the Chicken Coop over on the right side of the Manor.";
            onAction = () => state.advanceGilesTutorial(GilesTutorialStep.directAssign);
            break;
          case GilesTutorialStep.directAssign:
            dialogueText =
                "You can also assign tasks to residents directly from the Manor interface below. You should have me RESTORE the Chicken Coop. It's dangerous work.";
            onAction = () => state.advanceGilesTutorial(GilesTutorialStep.inspectResident);
            break;
          case GilesTutorialStep.inspectResident:
            dialogueText =
                "You can see what tasks each resident has assigned to them by clicking on the Resident chip within the Manor interface.";
            onAction = () => state.advanceGilesTutorial(GilesTutorialStep.summary);
            break;
          case GilesTutorialStep.summary:
            dialogueText =
                "Please look to the Manor Records icon at the top of the screen. You will find that all active objectives are tracked in the Journal tab there.";
            actionLabel = "UNDERSTOOD, GILES";
            onAction = () => state.dismissGilesTutorial();
            break;
          case GilesTutorialStep.inactive:
            break;
        }

        final mainCard = Container(
          margin: const EdgeInsets.all(8),
          constraints: const BoxConstraints(maxWidth: 550),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1A15).withValues(alpha: 0.95),
            border: Border.all(color: const Color(0xFFD4AF37), width: 2), // Muted Gold
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Giles Portrait
                Container(
                  width: 80,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    border: const Border(right: BorderSide(color: Color(0xFFD4AF37), width: 1)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFC4B89B)),
                          color: Colors.black,
                        ),
                        child: Center(
                          child: CharacterBlobRenderer(
                            npc: gilesNpc,
                            size: 40,
                            isIdle: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "GILES",
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFD4AF37),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Dialogue Box
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dialogueText,
                          style: GoogleFonts.oldStandardTt(
                            color: const Color(0xFFE5D5B0),
                            fontSize: 14,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (onAction != null)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4AF37),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  visualDensity: VisualDensity.compact,
                                  shape: const RoundedRectangleBorder(),
                                ),
                                onPressed: onAction,
                                child: Text(
                                  actionLabel,
                                  style: GoogleFonts.oldStandardTt(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        if (step == GilesTutorialStep.summary) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 24.0, bottom: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Manor Records",
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFFD4AF37),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_upward,
                      color: Color(0xFFD4AF37),
                      size: 16,
                    ),
                  ],
                ),
              ),
              mainCard,
            ],
          );
        }

        return mainCard;
      },
    );
  }
}

