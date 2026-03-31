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
import '../../models/plant.dart';
import '../../services/task_service.dart';

class GardenScreen extends StatelessWidget {
  final int totalBeds = 15; // 5x3 grid

  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1A15),
      appBar: AppBar(
        title: Text(
          'THE VEGETABLE GARDEN',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: const Color(0xFFE5D5B0),
          ),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
      ),
      body: Consumer<GameState>(
        builder: (context, state, child) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildInfoBanner(state),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final plant = _getPlantAt(state, index);
                      return _buildPlot(context, state, plant, index);
                    },
                    childCount: totalBeds,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildGlobalActions(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Plant? _getPlantAt(GameState state, int index) {
    try {
      return state.gardenPlants.firstWhere(
        (p) => p.roomId == 'vegetable_garden' && p.bedIndex == index,
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildInfoBanner(GameState state) {
    final currentMonth = state.currentDate.month;
    final isFrostApproaching = currentMonth == 9 || currentMonth == 10;
    final isWinter = currentMonth >= 11 || currentMonth <= 3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: isWinter
          ? Colors.blueGrey.withValues(alpha: 0.1)
          : isFrostApproaching
              ? Colors.orange.withValues(alpha: 0.1)
              : Colors.green.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(
            isWinter ? Icons.ac_unit : Icons.wb_sunny,
            color: isWinter ? Colors.blueAccent : Colors.orangeAccent,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWinter 
                      ? "WINTER DORMANCY" 
                      : isFrostApproaching 
                          ? "FROST APPROACHING" 
                          : "GROWING SEASON",
                  style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.bold,
                    color: isWinter 
                        ? Colors.blueAccent 
                        : isFrostApproaching 
                            ? Colors.orangeAccent 
                            : Colors.greenAccent,
                  ),
                ),
                Text(
                  isWinter
                      ? "Annual plants cannot survive these temperatures. Wait until Spring to plant."
                      : "Green beans and Faba beans produce until the first winter frost in November.",
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlot(BuildContext context, GameState state, Plant? plant, int index) {
    final isEmpty = plant == null;

    return Card(
      color: isEmpty ? Colors.black38 : Colors.brown.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isEmpty ? Colors.white10 : const Color(0xFFC4B89B).withValues(alpha: 0.5),
        ),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _handlePlotClick(context, state, plant, index),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isEmpty) ...[
                const Icon(Icons.yard_outlined, color: Colors.white12, size: 32),
                const SizedBox(height: 8),
                Text(
                  "EMPTY\nPLOT",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white24,
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.eco,
                  color: plant.yieldAmount > 0 ? Colors.greenAccent : Colors.yellow.withValues(alpha: 0.7),
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  plant.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE5D5B0),
                  ),
                ),
                const SizedBox(height: 4),
                // Health bar
                Container(
                  height: 4,
                  width: double.infinity,
                  color: Colors.black,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: plant.health.clamp(0.0, 1.0),
                    child: Container(color: Colors.green),
                  ),
                ),
                const SizedBox(height: 4),
                if (plant.yieldAmount > 0)
                  Text(
                    "READY: ${plant.yieldAmount}",
                    style: GoogleFonts.oldStandardTt(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  )
                else
                  Text(
                    "GROWING",
                    style: GoogleFonts.oldStandardTt(
                      fontSize: 9,
                      color: Colors.white54,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handlePlotClick(BuildContext context, GameState state, Plant? plant, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: const Color(0xFF2C2620),
          title: Text(
            plant == null ? 'PLANT A SEED' : 'BED INFO: ${plant.name.toUpperCase()}',
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFE5D5B0),
              fontWeight: FontWeight.bold,
            ),
          ),
          children: [
            if (plant != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Text(
                  "Health: ${(plant.health * 100).toInt()}%\n"
                  "Planted in: Month ${plant.plantedMonth}, Year ${plant.plantedYear}\n"
                  "Peak Season: ${plant.isPeakSeason(state.currentDate.month) ? 'YES' : 'NO'}\n"
                  "Yield Ready: ${plant.yieldAmount}",
                  style: GoogleFonts.oldStandardTt(color: Colors.white70),
                ),
              ),
              const Divider(color: Colors.white10),
              SimpleDialogOption(
                onPressed: () {
                  state.manualRemoveGardenBed(index);
                  Navigator.pop(context);
                },
                child: Text(
                  "CLEAR THIS BED",
                  style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ] else ...[
              SimpleDialogOption(
                onPressed: () {
                  state.manualPlantGardenBed(index, PlantType.greenBean);
                  Navigator.pop(context);
                },
                child: Text(
                  "PLANT GREEN BEANS",
                  style: GoogleFonts.outfit(color: const Color(0xFFE5D5B0)),
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  state.manualPlantGardenBed(index, PlantType.fabaBean);
                  Navigator.pop(context);
                },
                child: Text(
                  "PLANT FABA BEANS",
                  style: GoogleFonts.outfit(color: const Color(0xFFE5D5B0)),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildGlobalActions(BuildContext context, GameState state) {
    final actions = [
      {
        'label': 'WATER ALL BEDS',
        'task': TaskType.waterCrops,
        'icon': Icons.water_drop,
      },
      {
        'label': 'CARE & PRUNE',
        'task': TaskType.careForCrops,
        'icon': Icons.content_cut,
      },
      {
        'label': 'HARVEST ALL',
        'task': TaskType.harvestCrops,
        'icon': Icons.shopping_basket,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "MANUALLY ENQUEUE GLOBAL ACTIONS",
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFC4B89B),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: actions.map((action) {
              final taskType = action['task'] as TaskType;
              final descMatch = state.getTaskDescriptionForType(taskType);
              final isEnqueued = state.getRoomTaskQueue('vegetable_garden').any((t) => t.description.contains(descMatch));

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: OutlinedButton.icon(
                    onPressed: isEnqueued
                        ? null
                        : () {
                            state.createPlayerIntent(
                              action: taskType,
                              targetRoomId: 'vegetable_garden',
                              expectedDurationMin: 30,
                            );
                          },
                    icon: Icon(action['icon'] as IconData, size: 16),
                    label: Text(
                      isEnqueued ? 'ENQUEUED' : action['label'] as String,
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE5D5B0),
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
