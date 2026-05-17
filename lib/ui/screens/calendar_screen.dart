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
import '../../models/room.dart';
import '../../state/game_state.dart';
import '../widgets/horizontal_schedule_editor.dart';

class CalendarScreen extends StatefulWidget {
  final bool isTab;
  const CalendarScreen({super.key, this.isTab = false});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    // Start on the day that corresponds to the current game date
    final state = context.read<GameState>();
    _selectedDayIndex = (state.currentDate.day - 1) % 7;
  }

  @override
  Widget build(BuildContext context) {
    final content = Consumer<GameState>(
      builder: (context, state, child) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "ESTATE SCHEDULES",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: const Color(0xFFC4B89B).withValues(alpha: 0.6),
                      ),
                    ),
                    _buildDayPicker(),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.npcs.length,
                    itemBuilder: (context, index) {
                      final npc = state.npcs[index];
                      final isCoopRestored = state.rooms.any(
                        (r) => r.type == RoomType.chickenCoop && r.isRestored,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: HorizontalScheduleEditor(
                          npc: npc,
                          showHeader: index == 0,
                          showLegend: index == state.npcs.length - 1,
                          showName: true,
                          isCoopRestored: isCoopRestored,
                          dayIndex: _selectedDayIndex,
                          onScheduleChanged: (newSchedule) {
                            state.updateNpc(
                              npc.copyWith(schedule: newSchedule),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (widget.isTab) return content;
      
      return Scaffold(
        backgroundColor: const Color(0xFF1E1A15),
        appBar: AppBar(
          title: Text(
            'CHRONICLE OF TIME',
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFE5D5B0),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: content,
      );
  }

  Widget _buildDayPicker() {
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return Row(
      children: List.generate(7, (index) {
        final isSelected = index == _selectedDayIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: InkWell(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFC4B89B) : Colors.black26,
                border: Border.all(
                  color: isSelected ? Colors.white24 : Colors.transparent,
                ),
              ),
              child: Text(
                days[index],
                style: GoogleFonts.oldStandardTt(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black87 : Colors.white38,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
