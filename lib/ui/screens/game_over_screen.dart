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
import '../../models/survival_state.dart';
import '../widgets/save_load_dialogs.dart';

class GameOverScreen extends StatelessWidget {
  final String reason;
  final SurvivalDifficulty? difficulty;
  final int? turnsSurvived;

  const GameOverScreen({
    super.key,
    required this.reason,
    this.difficulty,
    this.turnsSurvived,
  });

  String? getMedal(int turns) {
    if (turns >= 1000) return 'PLATINUM MEDAL';
    if (turns >= 500) return 'GOLD MEDAL';
    if (turns >= 200) return 'SILVER MEDAL';
    if (turns >= 50) return 'BRONZE MEDAL';
    return null;
  }

  Color getMedalColor(String medal) {
    if (medal.startsWith('PLATINUM')) return const Color(0xFFE5E4E2);
    if (medal.startsWith('GOLD')) return const Color(0xFFFFD700);
    if (medal.startsWith('SILVER')) return const Color(0xFFC0C0C0);
    return const Color(0xFFCD7F32);
  }

  @override
  Widget build(BuildContext context) {
    final isArcade = difficulty == SurvivalDifficulty.arcade;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isArcade ? 'ARCADE DEFEAT' : 'EXPERIMENT TERMINATED',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.redAccent,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                height: 2,
                color: Colors.redAccent.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 32),
              Text(
                reason.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.oldStandardTt(
                  color: const Color(0xFFC4B89B),
                  fontSize: 16,
                  height: 1.6,
                  letterSpacing: 1.5,
                ),
              ),
              if (isArcade && turnsSurvived != null) ...[
                const SizedBox(height: 32),
                Text(
                  'TURNS SURVIVED: $turnsSurvived',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                () {
                  final medal = getMedal(turnsSurvived!);
                  if (medal == null) {
                    return Text(
                      'NO MEDAL EARNED (REQUIRE 50+ TURNS)',
                      style: GoogleFonts.outfit(
                        color: Colors.white24,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    );
                  }
                  final color = getMedalColor(medal);
                  return Column(
                    children: [
                      Icon(Icons.emoji_events, color: color, size: 54),
                      const SizedBox(height: 8),
                      Text(
                        medal,
                        style: GoogleFonts.playfairDisplay(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  );
                }(),
              ],
              const SizedBox(height: 64),
              if (!isArcade) ...[
                _buildActionButton(context, 'RESTORE PREVIOUS DOCUMENTATION', () {
                  showDialog(
                    context: context,
                    builder: (context) => LoadGameDialog(
                      onSlotSelected: (slot) {
                        // Selection handled by dialog
                      },
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
              _buildActionButton(context, 'START ANONYMOUS NEW LIFE', () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFC4B89B)),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text(
          label,
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFE5D5B0),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
