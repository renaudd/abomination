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

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import '../../models/active_business.dart';

class DiningRoomScreen extends StatelessWidget {
  const DiningRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181410),
      appBar: AppBar(
        title: Text(
          'GLARUS DINING HALL',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            fontSize: 18,
            color: const Color(0xFFE5D5B0),
          ),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE5D5B0)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<GameState>(
        builder: (context, state, child) {
          final bistroActive = state.activeBusinesses.any(
            (b) => b.type == BusinessType.bistro && b.status == 'active',
          );

          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/Carl_Spitzweg_-_Der_Maler_im_Garten.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.92),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Row(
              children: [
                // Left panel: Creative tycoon settings
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: const Color(0xFFC4B89B).withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('CREATIVE DESIGN DECREES'),
                          const SizedBox(height: 20),
                          _buildAmbianceSelector(context, state),
                          const Divider(color: Colors.white10, height: 40),
                          _buildEntertainmentSelector(context, state),
                          const Divider(color: Colors.white10, height: 40),
                          _buildBusinessSummary(state),
                        ],
                      ),
                    ),
                  ),
                ),

                // Right panel: Real-time Seating & Performance
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle('REAL-TIME DINING ROOM OBSERVATIONS'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFC4B89B)),
                                color: Colors.black26,
                              ),
                              child: Text(
                                bistroActive ? "RESTAURANT OPEN" : "RESTAURANT CLOSED TODAY",
                                style: GoogleFonts.oswald(
                                  color: bistroActive ? Colors.green : Colors.redAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: _buildTablesObservationGrid(context, state),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        color: const Color(0xFFE5D5B0),
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildAmbianceSelector(BuildContext context, GameState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "AMBIANCE STYLE",
          style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 12, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        Text(
          "The visual aesthetic and physical decor style dictates guest satisfaction multipliers.",
          style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10),
        ),
        const SizedBox(height: 12),
        ...[
          {'id': 'rustic', 'title': 'COZY RUSTIC', 'cost': '0 CHF', 'desc': 'Low cost, modest tips. Appeals to canton locals.', 'setup': 0},
          {'id': 'gothic', 'title': 'GOTHIC GRANDEUR', 'cost': '300 CHF', 'desc': '+40% Checkout Multiplier, noble class interest.', 'setup': 300},
          {'id': 'alchemical', 'title': 'ALCHEMICAL MODERNISM', 'cost': '200 CHF', 'desc': '+20% Checkout Multiplier, grants +2 research points per seated checkout.', 'setup': 200},
        ].map((style) {
          final isSelected = state.restaurantAmbiance == style['id'];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2C241E) : Colors.black12,
              border: Border.all(color: isSelected ? const Color(0xFFC4B89B) : Colors.white10),
            ),
            child: ListTile(
              dense: true,
              onTap: () {
                final setup = style['setup'] as int;
                if (state.resources['funds']! >= setup) {
                  state.updateResource('funds', -setup);
                  state.updateRestaurantAmbiance(style['id'] as String);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("INSUFFICIENT GLARUS FUNDS FOR RENOVATION.")),
                  );
                }
              },
              title: Text(
                "${style['title']} (${style['cost']})",
                style: GoogleFonts.playfairDisplay(
                  color: isSelected ? const Color(0xFFE5D5B0) : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                style['desc'] as String,
                style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 9),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEntertainmentSelector(BuildContext context, GameState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "STAGE MUSIC & ENTERTAINMENT",
          style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 12, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        Text(
          "Live performances dramatically improve client willingness to spend gold.",
          style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10),
        ),
        const SizedBox(height: 12),
        ...[
          {'id': 'none', 'title': 'SILENT HEARTH', 'cost': '0 CHF/week', 'desc': 'Average restaurant appeal.', 'weekly': 0},
          {'id': 'lutist', 'title': 'CANTONAL LUTIST', 'cost': '15 CHF/week', 'desc': '+10% checkouts, increases citizen satisfaction.', 'weekly': 15},
          {'id': 'opera', 'title': 'IMPERIAL OPERA SOLOIST', 'cost': '50 CHF/week', 'desc': '+25% checkouts, triggers elite diner groups.', 'weekly': 50},
        ].map((ent) {
          final isSelected = state.restaurantEntertainment == ent['id'];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2C241E) : Colors.black12,
              border: Border.all(color: isSelected ? const Color(0xFFC4B89B) : Colors.white10),
            ),
            child: ListTile(
              dense: true,
              onTap: () {
                state.updateRestaurantEntertainment(ent['id'] as String);
              },
              title: Text(
                "${ent['title']} (${ent['cost']})",
                style: GoogleFonts.playfairDisplay(
                  color: isSelected ? const Color(0xFFE5D5B0) : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                ent['desc'] as String,
                style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 9),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBusinessSummary(GameState state) {
    double estWeeklyExpenses = (state.restaurantEmployeeCount * state.restaurantEmployeeWages) +
        (state.restaurantSupplierContract == 'premium' ? 250.0 : 100.0);
    if (state.restaurantEntertainment == 'lutist') estWeeklyExpenses += 15;
    if (state.restaurantEntertainment == 'opera') estWeeklyExpenses += 50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "FINANCIAL FORECAST",
          style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 12, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.black38,
          child: Table(
            children: [
              TableRow(
                children: [
                  Text("EST. WEEKLY OVERHEAD:", style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10)),
                  Text("${estWeeklyExpenses.round()} CHF", style: GoogleFonts.oswald(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              TableRow(
                children: [
                  Text("BISTRO POPULARITY:", style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10)),
                  Text("${(state.bistroProfitModifier * 100).round()}% BUZZ", style: GoogleFonts.oswald(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTablesObservationGrid(BuildContext context, GameState state) {
    final maxTables = state.restaurantExtendedHoursActive ? 9 : 3;
    final activeCount = state.restaurantActiveTables;

    return GridView.builder(
      itemCount: maxTables,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final isOccupied = index < activeCount;

        if (!isOccupied) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.black26,
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.table_bar, color: Colors.white24, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    "TABLE ${index + 1}\nVACANT",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.oswald(color: Colors.white24, fontSize: 10, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          );
        }

        // Generate random diner names/descriptions for premium UI experience
        final random = Random(state.currentDate.totalMinutes + index);
        final guestProfiles = [
          {"name": "Count Lullin & Partner", "type": "Noble Elites"},
          {"name": "Geneva Merchants Guild", "type": "Middle Class"},
          {"name": "Cantonal Guard Soldiers", "type": "Locals"},
          {"name": "Academic Apothecaries", "type": "Scholars"},
          {"name": "Rolfe Union Officers", "type": "Middle Class"},
        ];
        final profile = guestProfiles[random.nextInt(guestProfiles.length)];

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF211C18),
            border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "TABLE ${index + 1}",
                    style: GoogleFonts.oswald(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    color: Colors.green.withValues(alpha: 0.2),
                    child: Text(
                      profile['type']!.toUpperCase(),
                      style: GoogleFonts.oswald(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                profile['name']!,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "ORDER: GOURMET PLATTER FOR 2",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 9),
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.zero,
                child: LinearProgressIndicator(
                  value: 0.65, // static visual indicator since finish minutes are enqueued
                  backgroundColor: Colors.white10,
                  color: const Color(0xFFC4B89B),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 24,
                child: ElevatedButton(
                  onPressed: () {
                    if (state.resources['funds']! >= 5) {
                      state.updateResource('funds', -5);
                      state.addResearchPoints(1);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("SERVED COMPLIMENTARY APERITIF (+10% TIP CHANCE)")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("INSUFFICIENT FUNDS.")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF382E25),
                    foregroundColor: const Color(0xFFE5D5B0),
                    padding: EdgeInsets.zero,
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: Text(
                    "OFFER APERITIF (-5 CHF)",
                    style: GoogleFonts.playfairDisplay(fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
