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
import '../../services/kitchen_service.dart';
import '../../services/task_service.dart';
import '../../models/room.dart';
import '../../models/active_business.dart';
import '../widgets/room_ledger.dart';
import '../widgets/giles_tutorial_overlay.dart';

class KitchenScreen extends StatelessWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      appBar: AppBar(
        toolbarHeight: 40,
        title: Text(
          'THE KITCHEN',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            fontSize: 15,
            color: const Color(0xFFE5D5B0),
          ),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE5D5B0), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<GameState>(
        builder: (context, state, child) {
          final basicRecipes = KitchenService.getAvailableRecipes()
              .where((r) => state.knownRecipes.contains(r.id) || r.id == 'butcher_generic')
              .toList();

          return Stack(
            children: [
              Container(
            decoration: BoxDecoration(
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
            child: Row(
              children: [
                // Left Panel: Pantry & Resources
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: const Color(0xFFC4B89B).withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('KITCHEN LEDGER'),
                              const SizedBox(height: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: RoomLedger(
                                    room: state.rooms.firstWhere((r) => r.type == RoomType.kitchen),
                                    state: state,
                                    isCompact: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(color: Colors.white10, height: 1),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('COOKING QUEUE'),
                              const SizedBox(height: 6),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildCookingQueue(state),
                                      if (state.activeBusinesses.any((b) => b.type == BusinessType.bistro && (b.status == 'active' || b.status == 'inProgress'))) ...[
                                        const SizedBox(height: 12),
                                        _buildDualQueuePanel(state),
                                        const SizedBox(height: 12),
                                        _buildAlchemicalSmoker(context, state),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right Panel: Cooking & Feeding
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle('HOUSEHOLD FEEDING'),
                            OutlinedButton.icon(
                              onPressed: () => _showExperimentDialog(context, state),
                              icon: const Icon(Icons.science, size: 14, color: Color(0xFFE5D5B0)),
                              label: Text(
                                'NEW RECIPE',
                                style: GoogleFonts.playfairDisplay(
                                  color: const Color(0xFFE5D5B0),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE5D5B0)),
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: ListView.builder(
                            itemCount: basicRecipes.length,
                            itemBuilder: (context, index) {
                              final recipe = basicRecipes[index];
                              return _buildRecipeTile(context, state, recipe);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (state.gilesTutorialStep != GilesTutorialStep.inactive)
              const Positioned.fill(
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: GilesTutorialOverlay(),
                    ),
                  ),
                ),
              ),
          ],
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
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildRecipeTile(
    BuildContext context,
    GameState state,
    Recipe recipe,
  ) {
    bool canCraft = true;
    recipe.ingredients.forEach((res, amount) {
      num available = (state.resources[res] ?? 0);
      if (res == 'meat') {
          available += (state.resources['meat_chicken'] ?? 0) + (state.resources['meat_beef'] ?? 0);
      }
      if (available.round() < amount.round()) canCraft = false;
    });

    final metadata = TaskService.getMetadata(TaskType.cook);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
        ),
        color: Colors.black.withValues(alpha: 0.3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    recipe.name.toUpperCase(),
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Text(
                  recipe.id == 'butcher_generic' ? "45 MINUTES" : "${recipe.durationMinutes} MINUTES",
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFC4B89B),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              recipe.id == 'butcher_generic'
                  ? "Select a creature or resident to yield meat and resources."
                  : "A standard culinary preparation requiring focus and hygiene.",
              style: GoogleFonts.oldStandardTt(
                color: const Color(0xFFC4B89B).withValues(alpha: 0.7),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INGREDIENTS',
                        style: GoogleFonts.oswald(
                          fontSize: 9,
                          color: const Color(0xFFE5D5B0).withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: recipe.ingredients.entries.map((e) {
                          num available = (state.resources[e.key] ?? 0);
                          if (e.key == 'meat') {
                              available += (state.resources['meat_chicken'] ?? 0) + (state.resources['meat_beef'] ?? 0);
                          }
                          final has = available.round() >= e.value.round();
                          return Text(
                            '${e.key.toUpperCase()}: ${e.value.round()}',
                            style: GoogleFonts.oldStandardTt(
                              color: has ? const Color(0xFFC4B89B) : Colors.red,
                              fontSize: 10,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EFFICIENCY',
                        style: GoogleFonts.oswald(
                          fontSize: 9,
                          color: const Color(0xFFE5D5B0).withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metadata.relevantAttributes.join(", ").toUpperCase(),
                        style: GoogleFonts.oldStandardTt(
                          fontSize: 10,
                          color: const Color(0xFFC4B89B),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OUTPUT',
                        style: GoogleFonts.oswald(
                          fontSize: 9,
                          color: const Color(0xFFE5D5B0).withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipe.id == 'butcher_generic' ? 'VARIES' : '${recipe.yield} MEALS',
                        style: GoogleFonts.oldStandardTt(
                          fontSize: 10,
                          color: const Color(0xFFC4B89B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: canCraft
                    ? () {
                        if (recipe.id == 'butcher_generic') {
                          _showButcherTargetDialog(context, state);
                        } else {
                          state.addToCookingQueue(recipe.id);
                        }
                      }
                    : null,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: canCraft ? const Color(0xFFC4B89B) : Colors.white10,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(
                  'COMMENCE PREPARATION',
                  style: GoogleFonts.playfairDisplay(
                    color: canCraft ? const Color(0xFFE5D5B0) : Colors.white12,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCookingQueue(GameState state) {
    if (state.cookingQueue.isEmpty) {
      return Text(
        'NO ORDERS.',
        style: GoogleFonts.oldStandardTt(color: Colors.white24, fontSize: 10),
      );
    }

    final recipes = KitchenService.getAvailableRecipes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: state.cookingQueue.asMap().entries.map((entry) {
        final index = entry.key;
        final recipeId = entry.value;
        String displayName;

        if (recipeId.startsWith('butcher_generic:')) {
          final parts = recipeId.split(':');
          displayName = "BUTCHER: ${parts[2].toUpperCase()}";
        } else {
          final baseId = recipeId.split(':').first;
          final isExperiment = recipeId.startsWith('experiment|');
          
          if (isExperiment) {
            displayName = "EXPERIMENT: ${recipeId.split('|').skip(1).join(', ').replaceAll('_', ' ').toUpperCase()}";
          } else {
            final recipe = recipes.firstWhere(
               (r) => r.id == baseId,
              orElse: () => recipes.first,
            );
            displayName = recipe.name.toUpperCase();
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 2.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${index + 1}. $displayName',
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFC4B89B),
                    fontSize: 10.5,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => state.removeFromCookingQueue(index),
                child: const Padding(
                  padding: EdgeInsets.all(2.0),
                  child: Icon(Icons.close, size: 10, color: Colors.white24),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showExperimentDialog(BuildContext context, GameState state) {
    const foodKeys = {
      'flour_spelt', 'flour_durum', 'flour', 'salt', 'pepper', 'sugar',
      'eggs', 'butter', 'milk', 'cream', 'cheese', 'oil',
      'potato', 'carrots', 'beets', 'cabbage', 'onion', 'garlic', 'peppers', 'tomato',
      'faba_beans', 'green_beans', 'mushrooms', 'truffles',
      'meat', 'meat_beef', 'meat_chicken', 'meat_pork', 'meat_duck', 'meat_lamb', 'meat_rat',
      'fish', 'lobster', 'scallops', 'caviar', 'foie_gras',
      'rice', 'almond_flour', 'chocolate', 'berries', 'lemon', 'coffee', 'wine', 'broth',
      'herbs', 'spices', 'mustard', 'breadcrumbs', 'intestine',
    };

    final availableIngredients = state.resources.entries
        .where((e) => foodKeys.contains(e.key) && e.value > 0)
        .toList();

    availableIngredients.sort((a, b) => b.value.compareTo(a.value));

    Map<String, int> selected = {};

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            int totalSelected = selected.values.fold(0, (sum, i) => sum + i);
            bool isValid = totalSelected >= 2 && totalSelected <= 4;

            return AlertDialog(
              backgroundColor: const Color(0xFF1A1612),
              title: Text(
                'EXPERIMENTATION (NEW RECIPE)',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    Text(
                      "Select 2 to 4 ingredients to experiment with. The outcome will depend on the resident's stats, the ingredient qualities, and luck.",
                      style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: availableIngredients.isEmpty
                          ? Center(
                              child: Text(
                                "No valid ingredients found.",
                                style: GoogleFonts.oldStandardTt(color: Colors.white24),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: availableIngredients.length,
                              itemBuilder: (context, index) {
                                final entry = availableIngredients[index];
                                final count = selected[entry.key] ?? 0;
                                return ListTile(
                                  title: Text(
                                    entry.key.toUpperCase().replaceAll('_', ' '),
                                    style: GoogleFonts.oldStandardTt(
                                      color: count > 0 ? const Color(0xFFE5D5B0) : Colors.white70,
                                      fontSize: 14,
                                      fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Available: ${entry.value.round()}',
                                    style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 11),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove, color: Colors.white70, size: 20),
                                        onPressed: count > 0
                                            ? () {
                                                setState(() {
                                                  selected[entry.key] = count - 1;
                                                  if (selected[entry.key] == 0) selected.remove(entry.key);
                                                });
                                              }
                                            : null,
                                      ),
                                      Text(
                                        '$count',
                                        style: GoogleFonts.oldStandardTt(color: Colors.white, fontSize: 14),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, color: Color(0xFFE5D5B0), size: 20),
                                        onPressed: (totalSelected < 4 && count < entry.value.round())
                                            ? () {
                                                setState(() {
                                                  selected[entry.key] = count + 1;
                                                });
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CANCEL',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: isValid
                      ? () {
                          // e.g. 'experiment|potato|potato|butter|salt'
                          final parts = ['experiment'];
                          selected.forEach((key, val) {
                            for (int i = 0; i < val; i++) {
                              parts.add(key);
                            }
                          });
                          state.addToCookingQueue(parts.join('|'));
                          Navigator.pop(context);
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isValid ? const Color(0xFFE5D5B0) : Colors.white10,
                    ),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: Text(
                    'COMMENCE EXPERIMENT',
                    style: GoogleFonts.playfairDisplay(
                      color: isValid ? const Color(0xFFE5D5B0) : Colors.white12,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showButcherTargetDialog(BuildContext context, GameState state) {
    showDialog(
      context: context,
      builder: (context) {
        final targets = state.butcheryTargets;
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1612),
          title: Text(
            'SELECT BUTCHERY TARGET',
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFE5D5B0),
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: targets.isEmpty
                ? Text(
                    'NO VIABLE TARGETS FOUND.',
                    style: GoogleFonts.oldStandardTt(color: Colors.white24),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: targets.length,
                    itemBuilder: (context, index) {
                      final target = targets[index];
                      return ListTile(
                        title: Text(
                          target['name']!.toUpperCase(),
                          style: GoogleFonts.oldStandardTt(
                            color: const Color(0xFFC4B89B),
                            fontSize: 13,
                          ),
                        ),
                        onTap: () {
                          state.addToCookingQueue(
                            'butcher_generic',
                            targetId: target['id'],
                            targetName: target['name'],
                          );
                          Navigator.pop(context);
                        },
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Color(0xFFE5D5B0),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ABANDON',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.red.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDualQueuePanel(GameState state) {
    final activeCooks = state.activeTasks.where((t) => t.type == TaskType.cook).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('DUAL-COOKING PREPARATION SLOTS'),
        const SizedBox(height: 12),
        ...List.generate(2, (index) {
          final hasCook = index < activeCooks.length;
          if (!hasCook) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black12,
                border: Border.all(color: Colors.white10),
              ),
              child: Text("SLOT ${index + 1}: IDLE (SOUS CHEF READY)", style: GoogleFonts.oswald(color: Colors.white24, fontSize: 10)),
            );
          }
          final task = activeCooks[index];
          final npcName = state.npcs.firstWhereOrNull((n) => n.id == task.npcId)?.name ?? "Cook";
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF211C18),
              border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("SLOT ${index + 1}: PREPARING ${task.recipeId?.toUpperCase().replaceAll('_', ' ') ?? 'MEAL'}", style: GoogleFonts.oswald(color: const Color(0xFFE5D5B0), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Cook: ${npcName.toUpperCase()} | Time: ${task.minutesRemaining}m left", style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 9)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAlchemicalSmoker(BuildContext context, GameState state) {
    final isSmokerActive = state.smokerItem != null;
    final progress = state.smokerProgress;
    final remaining = state.smokerMinutesRemaining;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.2)),
        color: Colors.black26,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('ALCHEMICAL FOOD SMOKER'),
              if (isSmokerActive)
                const Icon(Icons.cloud, color: Color(0xFFE5D5B0), size: 16)
              else
                const Icon(Icons.cloud_off, color: Colors.white24, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Slow cook raw ingredients for long periods to yield premium, exceptional delicacies.",
            style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(height: 12),
          if (!isSmokerActive) ...[
            _buildSmokerOptionTile(context, state, 'smoked_meat', 'ELDRITCH SMOKED BEEF', '120 Minutes', 'Requires 1 Meat', () {
              if ((state.resources['meat'] ?? 0) >= 1) {
                state.loadSmoker('smoked_meat', 120);
              } else {
                _showErrorSnackBar(context, "INSUFFICIENT MEAT IN PANTRY.");
              }
            }),
            _buildSmokerOptionTile(context, state, 'smoked_sausage', 'ARTISANAL SMOKED SAUSAGE', '180 Minutes', 'Requires 2 Pork', () {
              if ((state.resources['meat_pork'] ?? 0) >= 2) {
                state.loadSmoker('smoked_sausage', 180);
              } else {
                _showErrorSnackBar(context, "INSUFFICIENT PORK IN PANTRY.");
              }
            }),
            _buildSmokerOptionTile(context, state, 'cured_salmon', 'CURED ALCHEMICAL SALMON', '90 Minutes', 'Requires 1 Fish', () {
              if ((state.resources['fish'] ?? 0) >= 1) {
                state.loadSmoker('cured_salmon', 90);
              } else {
                _showErrorSnackBar(context, "INSUFFICIENT FISH IN PANTRY.");
              }
            }),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C241E),
                border: Border.all(color: const Color(0xFFC4B89B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ACTIVE SMOKING: ${state.smokerItem!.toUpperCase().replaceAll('_', ' ')}",
                    style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "MINUTES REMAINING: $remaining MINS",
                    style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 9),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.zero,
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white10,
                            color: const Color(0xFFC4B89B),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "${(progress * 100).round()}%",
                        style: GoogleFonts.oswald(color: const Color(0xFFE5D5B0), fontSize: 10),
                      ),
                    ],
                  ),
                  if (remaining <= 0) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          state.unloadSmoker();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC4B89B),
                          foregroundColor: Colors.black,
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: Text(
                          "HARVEST DELICACIES",
                          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSmokerOptionTile(
    BuildContext context,
    GameState state,
    String id,
    String title,
    String duration,
    String reqs,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.black12,
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        title: Text(title, style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 10, fontWeight: FontWeight.bold)),
        subtitle: Text("$duration | $reqs", style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 8)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFFC4B89B), size: 10),
        onTap: onTap,
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.oswald(color: Colors.black, fontSize: 11)),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

