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

class RestaurantTycoonDialog extends StatelessWidget {
  const RestaurantTycoonDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);
    final event = state.activeRestaurantTycoonEvent;

    if (event == null) return const SizedBox.shrink();

    final choices = event['choices'] as List;

    return Dialog(
      backgroundColor: const Color(0xFF1E1A15),
      shape: const RoundedRectangleBorder(),
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC4B89B), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant_menu, color: Color(0xFFC4B89B), size: 20),
                const SizedBox(width: 8),
                Text(
                  event['title'].toString().toUpperCase(),
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            Text(
              "GLARUS CULINARY OPERATION REPORT",
              style: GoogleFonts.oswald(
                color: const Color(0xFFC4B89B),
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
            const Divider(color: Colors.white10, height: 24),
            Text(
              event['description'].toString(),
              style: GoogleFonts.oldStandardTt(
                color: Colors.white,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "SELECT ACTION PLAN:",
              style: GoogleFonts.oswald(
                color: const Color(0xFFC4B89B),
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(choices.length, (idx) {
              final choice = choices[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    state.resolveRestaurantTycoonChoice(idx);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFC4B89B)),
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.white.withValues(alpha: 0.01),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        choice['title'].toString().toUpperCase(),
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        choice['description'].toString(),
                        style: GoogleFonts.oldStandardTt(
                          color: Colors.white70,
                          fontSize: 10.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
