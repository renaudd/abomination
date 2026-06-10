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

class Chapter2AnnouncementDialog extends StatelessWidget {
  const Chapter2AnnouncementDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1A15),
          border: Border.all(color: const Color(0xFFD4AF37), width: 2), // Muted Gold
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Image
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                border: const Border(bottom: BorderSide(color: Color(0xFFD4AF37), width: 1)),
                image: DecorationImage(
                  image: const AssetImage('assets/images/Carl_Spitzweg_-_Der_Alchimist.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.3),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CHAPTER 2',
                        style: GoogleFonts.oldStandardTt(
                          color: const Color(0xFFD4AF37),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'THE MODERN PROMETHEUS',
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Story & Instructions
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The galvanic spark has successfully traversed the biological ether. Where once there was only lifeless clay and dormant alchemical salts, a sovereign intelligence now awakens within your ancestral laboratory.',
                      style: GoogleFonts.oldStandardTt(
                        color: const Color(0xFFE5D5B0),
                        fontSize: 16,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 24),
                    Text(
                      'YOUR HORIZONS HAVE EXPANDED:',
                      style: GoogleFonts.oldStandardTt(
                        color: const Color(0xFFD4AF37),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureBullet(
                      Icons.map,
                      'World Map Expanse',
                      'Dispatch representatives across the grand strategic World Map to uncover distant alpine peaks and commercial wharves.',
                    ),
                    _buildFeatureBullet(
                      Icons.people_alt,
                      'Sovereign Household',
                      'Restore Manor Sleeping Quarters and muster active residential staff to sustain an expanding household.',
                    ),
                    _buildFeatureBullet(
                      Icons.security,
                      'The Standing Battalion',
                      'Recruit and equip specialized military squads to defend your domain against local magistrates and rival priorates.',
                    ),
                    _buildFeatureBullet(
                      Icons.castle,
                      'Architectural Renaissance',
                      'Commission master carpenters and stone masons to convert and fully restore specialized estate wings.',
                    ),
                    _buildFeatureBullet(
                      Icons.science,
                      'Scientific Enlightenment',
                      'Conduct rigorous dissections and alchemical transcriptions to achieve Level 2 qualification across multiple academic disciplines.',
                    ),
                    _buildFeatureBullet(
                      Icons.restaurant,
                      'Culinary Experimentation',
                      'Instruct hired master chefs to perform the New Recipe action in the Scullery, unlocking premium culinary dishes.',
                    ),
                    _buildFeatureBullet(
                      Icons.grass,
                      'Botanical Mastery',
                      'Cultivate the loamy plots of the Manor Garden and Greenhouse, nurturing valuable crops to full harvest maturity.',
                    ),
                    _buildFeatureBullet(
                      Icons.menu_book,
                      'Secret Society Diplomacy',
                      'Engage in formal correspondence and priorate maneuvering to interact with 9 subterranean Victorian factions.',
                    ),
                  ],
                ),
              ),
            ),

            // Dismiss Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                border: const Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: const RoundedRectangleBorder(),
                    ),
                    onPressed: () {
                      Provider.of<GameState>(context, listen: false).dismissChapter2Modal();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'EMBRACE THE PROMETHEAN ERA',
                      style: GoogleFonts.oldStandardTt(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBullet(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFD4AF37), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
