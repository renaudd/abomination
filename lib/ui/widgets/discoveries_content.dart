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
import '../../models/npc.dart';

class DiscoveriesContent extends StatelessWidget {
  const DiscoveriesContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Discoveries & Inventions
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('SCIENTIFIC DISCOVERIES'),
                    const SizedBox(height: 16),
                    if (state.unlockedDiscoveries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'NO SIGNIFICANT BREAKTHROUGHS YET.',
                          style: GoogleFonts.oldStandardTt(
                            color: Colors.white12,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      ...state.unlockedDiscoveries.map(
                        (d) => _buildDiscoveryItem(d),
                      ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('INVENTIONS'),
                    const SizedBox(height: 16),
                    // Placeholder for Inventions
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'NO INVENTIONS CREATED YET.',
                        style: GoogleFonts.oldStandardTt(
                          color: Colors.white12,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const VerticalDivider(color: Colors.white10, width: 48),
            // Right Column: Forces/Constructs & Research Standing
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _buildResearchStanding(state),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        color: const Color(0xFFC4B89B),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildDiscoveryItem(String id) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFE5D5B0), size: 14),
          const SizedBox(width: 12),
          Text(
            id.replaceAll('_', ' ').toUpperCase(),
            style: GoogleFonts.oldStandardTt(
              color: const Color(0xFFE5D5B0),
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResearchStanding(GameState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.black.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESEARCH STANDING:',
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFC4B89B),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          ...[
            'Anatomy',
            'Zoology',
            'Medicine',
            'Chemistry',
          ].map(
            (discipline) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    discipline.toUpperCase(),
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    state.getKnowledgeLevel(discipline).toStringAsFixed(1),
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFC4B89B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
