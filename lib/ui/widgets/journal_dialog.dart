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
import '../../services/task_service.dart';

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
                                  .map((o) => _buildObjectiveItem(o, state)),
                              const SizedBox(height: 24),
                              _buildSectionHeader('COMPLETED GOALS'),
                              const SizedBox(height: 16),
                              ...state.objectives
                                  .where((o) => o.isCompleted)
                                  .map(
                                      (o) =>
                                        _buildObjectiveItem(o, state, isDone: true),
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

  String _getObjectiveProgressSuffix(Objective obj, GameState state) {
    final reqs = obj.requirements;
    List<String> parts = [];

    if (reqs.containsKey('task_counts')) {
      final targetCounts = reqs['task_counts'] as Map<String, dynamic>;
      for (var entry in targetCounts.entries) {
        final tStr = entry.key;
        final target = entry.value as int;
        final tType = TaskType.values.where((t) => t.name == tStr).firstOrNull;
        int current = 0;
        if (tType != null) {
          current = state.taskCompletionCounts[tType] ?? 0;
        } else {
          current = state.customTaskCounts[tStr] ?? 0;
        }
        parts.add('($current/$target)');
      }
    }

    if (reqs.containsKey('map_hexes_explored')) {
      final target = reqs['map_hexes_explored'] as int;
      final current = state.exploredHexesCount;
      parts.add('($current/$target)');
    }

    if (reqs.containsKey('manor_population')) {
      final target = reqs['manor_population'] as int;
      final current = state.npcs.where((n) => n.isResident).length;
      parts.add('($current/$target)');
    }

    if (reqs.containsKey('standing_army_size')) {
      final target = reqs['standing_army_size'] as int;
      final pIdx = state.npcs.indexWhere((n) => n.isPlayer);
      final current = pIdx != -1 ? state.npcs[pIdx].lastEscortIds.length : 0;
      parts.add('($current/$target)');
    }

    if (reqs.containsKey('combats_won')) {
      final target = reqs['combats_won'] as int;
      final current = state.customTaskCounts['combats_won'] ?? 0;
      parts.add('($current/$target)');
    }

    if (reqs.containsKey('treasury_funds')) {
      final target = reqs['treasury_funds'] as int;
      final current = state.resources['funds'] ?? 0;
      parts.add('($current/$target)');
    }

    if (reqs.containsKey('rooms_restored_count')) {
      final target = reqs['rooms_restored_count'] as int;
      final current = state.rooms.where((r) => r.isRestored).length;
      parts.add('($current/$target)');
    }

    if (reqs.containsKey('science_level_count')) {
      final target = reqs['science_level_count'] as int;
      final current = state.researchPoints.values.where((pts) => pts >= 20.0).length;
      parts.add('($current/$target)');
    }

    if (reqs.containsKey('new_recipes_unlocked')) {
      final target = reqs['new_recipes_unlocked'] as int;
      final current = state.knownRecipes.length;
      parts.add('($current/$target)');
    }

    if (reqs.containsKey('garden_harvests')) {
      final target = reqs['garden_harvests'] as int;
      final current = state.customTaskCounts['garden_harvests'] ?? 0;
      parts.add('($current/$target)');
    }

    if (reqs.containsKey('secret_society_interactions')) {
      final target = reqs['secret_society_interactions'] as int;
      final current = state.customTaskCounts['secret_society_interactions'] ?? 0;
      parts.add('($current/$target)');
    }

    if (parts.isNotEmpty) {
      return ' ${parts.join(' ')}';
    }
    return '';
  }

  Widget _buildObjectiveItem(Objective obj, GameState state, {bool isDone = false}) {
    final progressSuffix = isDone ? '' : _getObjectiveProgressSuffix(obj, state);

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
              '${obj.description}$progressSuffix',
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
