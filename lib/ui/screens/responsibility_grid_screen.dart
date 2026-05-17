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
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../state/game_state.dart';
import '../../models/responsibility.dart';
import '../../models/npc.dart';
import 'responsibility_detail_screen.dart';

class ResponsibilityGridScreen extends StatelessWidget {
  final bool isTab;
  const ResponsibilityGridScreen({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        final npcs = state.npcs.where((n) => n.isResident).toList();
        final categories = ResponsibilityCategory.values;

        final content = Row(
          children: [
            // Character Column (Fixed)
            _buildCharacterHeader(npcs),
            // Category Grid (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    _buildGridHeader(context, categories),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Table(
                          defaultColumnWidth: const FixedColumnWidth(120),
                          children: npcs
                              .map(
                                (npc) => _buildRow(
                                  context,
                                  state,
                                  npc,
                                  categories,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

        if (isTab) return content;

        return Scaffold(
          backgroundColor: const Color(0xFF1A1612),
          appBar: AppBar(
            backgroundColor: Colors.black45,
            title: Text(
              'RESPONSIBILITY ASSIGNMENT',
              style: GoogleFonts.oswald(
                letterSpacing: 2,
                color: const Color(0xFFE5D5B0),
              ),
            ),
          ),
          body: content,
        );
      },
    );
  }

  Widget _buildCharacterHeader(List<NPC> npcs) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: const Border(right: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          Container(
            height: 50,
            alignment: Alignment.center,
            child: Text(
              'CHARACTER',
              style: GoogleFonts.oswald(fontSize: 12, color: Colors.white30),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: npcs.length,
              itemBuilder: (context, index) => Container(
                height: 44,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white10)),
                ),
                child: Text(
                  npcs[index].name,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridHeader(
    BuildContext context,
    List<ResponsibilityCategory> categories,
  ) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: categories
            .map(
              (cat) => GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ResponsibilityDetailScreen(category: cat),
                    ),
                  );
                },
                child: Container(
                  width: 120,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cat.displayName.toUpperCase(),
                        style: GoogleFonts.oswald(
                          fontSize: 12,
                          color: const Color(0xFFC4B89B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.settings,
                        size: 12,
                        color: Colors.white24,
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  TableRow _buildRow(
    BuildContext context,
    GameState state,
    NPC npc,
    List<ResponsibilityCategory> categories,
  ) {
    return TableRow(
      children: categories.map((cat) {
        final stars = npc.responsibilities[cat] ?? 0;
        return TableCell(
          child: Container(
            height: 44,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white10),
                right: BorderSide(color: Colors.white10),
              ),
            ),
            child: InkWell(
              onTap: () => _showValuePicker(context, state, npc, cat, stars),
              child: Center(
                child: Text(
                  '$stars',
                  style: GoogleFonts.oswald(
                    fontSize: 20,
                    color: stars == 0 ? Colors.white30 : const Color(0xFFE5D5B0),
                    fontWeight: stars > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showValuePicker(
      BuildContext context, GameState state, NPC npc, ResponsibilityCategory cat, int currentVal) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1612),
          title: Text(
            'ASSIGN ${cat.displayName.toUpperCase()}',
            style: GoogleFonts.oswald(color: const Color(0xFFE5D5B0), letterSpacing: 1),
            textAlign: TextAlign.center,
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              final isSelected = index == currentVal;
              return InkWell(
                onTap: () {
                  final newResp = Map<ResponsibilityCategory, int>.from(npc.responsibilities);
                  newResp[cat] = index;
                  state.updateNpc(npc.copyWith(responsibilities: newResp));
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE5D5B0).withValues(alpha: 0.2) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFFE5D5B0) : Colors.white24,
                    ),
                  ),
                  child: Text(
                    '$index',
                    style: GoogleFonts.oswald(
                      fontSize: isSelected ? 24 : 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFFE5D5B0) : Colors.white54,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
