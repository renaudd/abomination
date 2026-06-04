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
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../state/game_state.dart';
import '../screens/combat_screen.dart';

class EncounterDialog extends StatelessWidget {
  const EncounterDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<GameState>();
    final encounter = state.pendingEncounterData;

    if (encounter == null) {
      return const SizedBox.shrink();
    }

    final canPay = state.canPayEncounterDemands(encounter.demands);
    
    // Format demands text
    String demandsText = '';
    if (encounter.demands.isNotEmpty) {
      demandsText = encounter.demands.entries
          .map((e) => '${e.value} ${e.key.toUpperCase()}')
          .join(', ');
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false, // Must resolve the encounter
      child: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            // Skip hotkeys if typing in a text field
            final primaryFocus = FocusManager.instance.primaryFocus;
            if (primaryFocus != null && primaryFocus.context != null) {
              final hasTextFocus = primaryFocus.context!.findAncestorWidgetOfExactType<EditableText>() != null;
              if (hasTextFocus) return;
            }

            final key = event.physicalKey;
            final hasDemands = encounter.demands.isNotEmpty;

            if (key == PhysicalKeyboardKey.digit1 || key == PhysicalKeyboardKey.numpad1) {
              if (hasDemands) {
                if (canPay) {
                  state.resolveEncounterPayDemand(encounter.demands);
                  Navigator.of(context).pop();
                }
              } else {
                // Flee
                final escaped = state.resolveEncounterFlee();
                if (!escaped) {
                  state.startCombatEncounter();
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CombatScreen()),
                  );
                } else {
                  Navigator.of(context).pop();
                }
              }
            } else if (key == PhysicalKeyboardKey.digit2 || key == PhysicalKeyboardKey.numpad2) {
              if (hasDemands) {
                // Flee
                final escaped = state.resolveEncounterFlee();
                if (!escaped) {
                  state.startCombatEncounter();
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CombatScreen()),
                  );
                } else {
                  Navigator.of(context).pop();
                }
              } else {
                // Fight
                state.startCombatEncounter();
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CombatScreen()),
                );
              }
            } else if (key == PhysicalKeyboardKey.digit3 || key == PhysicalKeyboardKey.numpad3) {
              if (hasDemands) {
                // Fight
                state.startCombatEncounter();
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CombatScreen()),
                );
              }
            }
          }
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 450,
              maxHeight: screenHeight * 0.95,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1612),
                border: Border.all(color: const Color(0xFFC4B89B), width: 2),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      encounter.title.toUpperCase(),
                      style: GoogleFonts.oldStandardTt(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      encounter.description,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        color: const Color(0xFFE5D5B0),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (encounter.demands.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'DEMANDS',
                              style: GoogleFonts.oldStandardTt(
                                color: Colors.white54,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              demandsText,
                              style: GoogleFonts.oldStandardTt(
                                color: canPay ? Colors.green : Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!canPay)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Insufficient resources in party inventory.',
                                  style: GoogleFonts.oldStandardTt(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Actions
                    if (encounter.demands.isNotEmpty) ...[
                      _DialogButton(
                        label: 'SATISFY DEMANDS',
                        enabled: canPay,
                        onPressed: () {
                          Navigator.of(context).pop();
                          state.resolveEncounterPayDemand(encounter.demands);
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    _DialogButton(
                      label: 'ATTEMPT TO FLEE',
                      enabled: true,
                      onPressed: () {
                        final escaped = state.resolveEncounterFlee();
                        if (!escaped) {
                          state.startCombatEncounter();
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CombatScreen()),
                          );
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _DialogButton(
                      label: 'FIGHT',
                      enabled: true,
                      isPrimary: true,
                      onPressed: () {
                        state.startCombatEncounter();
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CombatScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  final bool isPrimary;

  const _DialogButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: !enabled
            ? Colors.grey[900]
            : isPrimary
                ? const Color(0xFF6B1D1D)
                : Colors.transparent,
        foregroundColor: !enabled
            ? Colors.grey[700]
            : isPrimary
                ? Colors.white
                : const Color(0xFFC4B89B),
        side: BorderSide(
          color: !enabled
              ? Colors.grey[800]!
              : isPrimary
                  ? Colors.redAccent
                  : const Color(0xFFC4B89B),
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      onPressed: enabled ? onPressed : null,
      child: Text(
        label,
        style: GoogleFonts.oldStandardTt(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
