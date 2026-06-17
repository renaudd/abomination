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
import 'package:collection/collection.dart';
import '../../state/game_state.dart';
import '../../models/graduate_school_state.dart';
import '../widgets/location_tile.dart';
import '../widgets/time_speed_controls.dart';

class RegionalMapScreen extends StatelessWidget {
  const RegionalMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      appBar: AppBar(
        title: Text(
          'CANTON DE VAUD',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            fontSize: 18,
            color: const Color(0xFFE5D5B0),
          ),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE5D5B0)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF241F1A),
          image: DecorationImage(
            image: const AssetImage(
              'assets/images/Carl_Spitzweg_-_Der_Maler_im_Garten.jpg',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.9),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE5D5B0).withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
            ),

            Center(
              child: AspectRatio(
                aspectRatio: 0.8,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 220,
                        left: 140,
                        child: LocationTile(
                          name: 'ROLLE',
                          icon: Icons.castle,
                          description:
                              'The lakeside town where your manor sits.',
                          isCurrent: true,
                          onTap: () => Navigator.pop(context),
                        ),
                      ),
                      const Positioned(
                        top: 320,
                        left: 200,
                        child: LocationTile(
                          name: 'LAUSANNE',
                          icon: Icons.location_city,
                          description: 'A major city to the East.',
                        ),
                      ),
                      const Positioned(
                        bottom: 80,
                        right: 40,
                        child: LocationTile(
                          name: 'ÉVIAN-LES-BAINS',
                          icon: Icons.beach_access,
                          description: 'French spa town across the Lac Léman.',
                        ),
                      ),
                      
                      // INTERACTIVE GENEVA GRADUATE SCHOOL
                      Consumer<GameState>(
                        builder: (context, state, child) {
                          final player = state.npcs.firstWhereOrNull((n) => n.id == 'player');
                          final bool isAtSchool = player?.worldDestinationId == 'graduate_school';
                          final bool hasGraduated = state.playerHasGraduateDegree;
                          
                          return Positioned(
                            bottom: 40,
                            left: 100,
                            child: LocationTile(
                              name: 'GENEVA ACADEMY',
                              icon: Icons.school,
                              description: hasGraduated 
                                  ? 'Academic degree completed (Advanced Practice License).'
                                  : (isAtSchool 
                                      ? 'Currently attending degree classes...' 
                                      : 'The grand Swiss university. Study law or medicine.'),
                              isCurrent: isAtSchool,
                              onTap: () {
                                _showGraduateSchoolDialog(context, state);
                              },
                            ),
                          );
                        }
                      ),

                      const Positioned(
                        top: 40,
                        left: 40,
                        child: LocationTile(
                          name: 'LA DÔLE',
                          icon: Icons.terrain,
                          description: 'A prominent peak in the Jura.',
                        ),
                      ),
                      const Positioned(
                        top: 100,
                        left: 10,
                        child: LocationTile(
                          name: 'LE NOIRMONT',
                          icon: Icons.terrain,
                          description: 'A rugged mountain pass.',
                        ),
                      ),
                      const Positioned(
                        top: 20,
                        right: 80,
                        child: LocationTile(
                          name: 'MONT TENDRE',
                          icon: Icons.terrain,
                          description: 'The highest peak of the Swiss Jura.',
                        ),
                      ),
                      const Positioned(
                        top: 180,
                        right: 120,
                        child: LocationTile(
                          name: 'VUFFLENS CASTLE',
                          icon: Icons.castle,
                          description: 'A magnificent medieval fortress.',
                        ),
                      ),
                      const Positioned(
                        bottom: 120,
                        left: 160,
                        child: LocationTile(
                          name: 'YVOIRE',
                          icon: Icons.water,
                          description: 'Walled medieval village in France.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
                  ),
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: Column(
                  children: [
                    const TimeSpeedControls(),
                    const Divider(color: Colors.white10),
                    Text(
                      'CANTON DE VAUD, NEUTRAL SWITZERLAND - 1818',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFFC4B89B),
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGraduateSchoolDialog(BuildContext context, GameState state) {
    final player = state.npcs.firstWhereOrNull((n) => n.id == 'player');
    final bool isAtSchool = player?.worldDestinationId == 'graduate_school';
    final double schoolProgress = player?.worldTravelProgress ?? 0.0;
    final bool hasGraduated = state.playerHasGraduateDegree;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1A15),
          shape: const RoundedRectangleBorder(),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC4B89B)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "GENEVA ACADEMIC UNION",
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "SWISS IMPERIAL GRADUATE SCHOOL OF LAW & MEDICINE",
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFC4B89B).withValues(alpha: 0.7),
                    fontSize: 9,
                    letterSpacing: 1.5,
                  ),
                ),
                const Divider(color: Colors.white10, height: 24),
                Text(
                  "Attaining an advanced practice degree unlocks the capability to set up intricate practices like Gothic Law Chambers or Private Medical Clinics at the manor estate.",
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                if (hasGraduated) ...[
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "DIPLOMA ATTAINED: MASTER OF LAWS & MEDICINE",
                        style: GoogleFonts.oswald(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ] else if (isAtSchool) ...[
                  Text(
                    "STUDY STATUS: ${(schoolProgress * 100).toInt()}% ACADEMIC COMPLETION",
                    style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: schoolProgress,
                    color: const Color(0xFFC4B89B),
                    backgroundColor: Colors.white10,
                  ),
                  const SizedBox(height: 24),
                  if (schoolProgress >= 1.0)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          state.completeGraduation();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Degree program complete! Advanced practice license attained."),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC4B89B),
                          foregroundColor: Colors.black,
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: Text(
                          "GRADUATE AND CONFER LICENSE",
                          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else
                    Text(
                      "Let time pass at faster speeds for Alphonse to complete his degree research program.",
                      style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic),
                    ),
                ] else ...[
                  Text(
                    "GENEVA REGISTRATION FEES: 150 CHF\nFACULTY PROGRAM TERM: 3 SEMESTERS & BOARD EXAMS",
                    style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 11, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "CHOOSE FACULTY OF DISCIPLINE:",
                    style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...AcademicSchoolType.values.map((type) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (state.resources['funds'] ?? 0) < 150
                            ? null
                            : () {
                                state.updateResource('funds', -150);
                                state.enrollInGraduateSchool(type);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Alphonse enrolled at ${type.displayName}!"),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF241F1A),
                          foregroundColor: const Color(0xFFE5D5B0),
                          side: const BorderSide(color: Color(0xFFC4B89B)),
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: Text(type.displayName.toUpperCase(), style: GoogleFonts.playfairDisplay(fontSize: 10)),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("CLOSE", style: GoogleFonts.oldStandardTt(color: Colors.white24)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
