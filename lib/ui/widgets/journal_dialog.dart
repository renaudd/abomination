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
import '../../models/objective.dart';

class JournalContent extends StatefulWidget {
  const JournalContent({super.key});

  @override
  State<JournalContent> createState() => _JournalContentState();
}

class _JournalContentState extends State<JournalContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GameState>().clearUnreadObjectives();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Objectives
                      Expanded(
                        flex: 1,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader('ACTIVE OBJECTIVES'),
                              const SizedBox(height: 16),
                              ...state.objectives
                                  .where((o) => !o.isCompleted)
                                  .map((o) => _buildObjectiveItem(o)),
                              const SizedBox(height: 24),
                              _buildSectionHeader('COMPLETED GOALS'),
                              const SizedBox(height: 16),
                              ...state.objectives
                                  .where((o) => o.isCompleted)
                                  .map(
                                      (o) =>
                                        _buildObjectiveItem(o, isDone: true),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildObjectiveItem(Objective obj, {bool isDone = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDone
            ? Colors.transparent
            : Colors.black.withValues(alpha: 0.2),
        border: Border.all(
          color: isDone
              ? Colors.white10
              : const Color(0xFFC4B89B).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDone ? Icons.check_circle_outline : Icons.bookmark_border,
                size: 16,
                color: isDone ? Colors.white24 : const Color(0xFFE5D5B0),
              ),
              const SizedBox(width: 8),
              Text(
                obj.title.toUpperCase(),
                style: GoogleFonts.playfairDisplay(
                  color: isDone ? Colors.white24 : const Color(0xFFE5D5B0),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
          if (!isDone) ...[
            const SizedBox(height: 8),
            Text(
              obj.description,
              style: GoogleFonts.oldStandardTt(
                color: const Color(0xFFC4B89B),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
