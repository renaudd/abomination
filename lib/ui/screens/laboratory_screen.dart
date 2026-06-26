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
import '../../models/npc.dart';
import '../../models/experiment.dart';
import '../../models/room.dart';
import '../../services/science_service.dart';
import '../../services/task_service.dart';
import '../../models/game_item.dart';
import '../widgets/fireworks_overlay.dart';
import '../../services/audio_service.dart';

class LaboratoryScreen extends StatefulWidget {
  final Room room;

  const LaboratoryScreen({super.key, required this.room});

  @override
  State<LaboratoryScreen> createState() => _LaboratoryScreenState();
}

class _LaboratoryScreenState extends State<LaboratoryScreen> {
  @override
  void initState() {
    super.initState();
    AudioService().pushBgmMode(BgmMode.laboratory);
  }

  @override
  void dispose() {
    AudioService().popBgmMode();
    super.dispose();
  }

  void _checkMobileNotificationModal(BuildContext context, GameState state) {
    if (state.pendingMobileNotification != null &&
        ModalRoute.of(context)?.isCurrent == true) {
      final notif = state.pendingMobileNotification!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                const Positioned.fill(child: FireworksOverlay()),
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxWidth: 420,
                    maxHeight: MediaQuery.of(context).size.height - 24,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1612),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFC4B89B),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE5D5B0).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFFE5D5B0),
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "VICTORIAN SCIENTIFIC BREAKTHROUGH",
                          style: GoogleFonts.oswald(
                            color: const Color(0xFFC4B89B),
                            fontSize: 11,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notif['title'] ?? '',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (notif['image'] != null &&
                            notif['image']!.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              notif['image']!,
                              height: 150,
                              width: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _buildNotificationMessage(
                            notif['message'] ?? '',
                            GoogleFonts.oldStandardTt(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (notif['title'] == 'Undead Bat' || notif['title'] == 'Undead Rat') ...[
                          const SizedBox(height: 12),
                          _buildUnitCollectionProgress(
                            notif['title'] == 'Undead Bat' ? state.reanimatedBatsCount : state.reanimatedRatsCount,
                            4,
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E1A0A),
                              side: const BorderSide(color: Color(0xFFE5D5B0)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              state.clearPendingMobileNotification();
                              Navigator.pop(context);
                            },
                            child: Text(
                              "EXCELLENT",
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFE5D5B0),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
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
      });
    }
  }

  Widget _buildNotificationMessage(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final RegExp exp = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;
    for (final match in exp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE5D5B0)),
      ));
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: baseStyle,
        children: spans,
      ),
    );
  }

  Widget _buildUnitCollectionProgress(int current, int target) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF251F1A),
        border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "CONSTRUCT CREATION PROGRESS",
                style: GoogleFonts.outfit(
                  color: const Color(0xFFC4B89B),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                "$current / $target COLLECTED",
                style: GoogleFonts.outfit(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(target, (index) {
              final isAchieved = index < current;
              return Expanded(
                child: Container(
                  height: 10,
                  margin: EdgeInsets.symmetric(horizontal: index == 0 || index == target - 1 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: isAchieved ? const Color(0xFFC4B89B) : Colors.black45,
                    border: Border.all(
                      color: isAchieved
                          ? const Color(0xFFE5D5B0)
                          : const Color(0xFFC4B89B).withValues(alpha: 0.2),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isAchieved
                        ? [
                            BoxShadow(
                              color: const Color(0xFFC4B89B).withValues(alpha: 0.5),
                              blurRadius: 4,
                            )
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            current >= target
                ? "Construct Unit Complete! The squadron is ready for battle."
                : "Needs ${target - current} more to form a complete combat unit and unlock the unit card.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white60,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        _checkMobileNotificationModal(context, state);

        final activeExperiments = state.activeExperiments
            .where((e) => state.npcs.any((o) => o.id == e.subjectId))
            .toList();

        return Scaffold(
          backgroundColor: const Color(0xFF1A1612),
          appBar: AppBar(
            title: Text(
              'THE LABORATORY',
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
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent, width: 1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: Text(
                    "DEMOLISH ROOM",
                    style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          backgroundColor: const Color(0xFF1E1A15),
                          shape: const RoundedRectangleBorder(),
                          title: Text(
                            "DEMOLISH ALCHEMICAL LABORATORY?",
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 2,
                            ),
                          ),
                          content: Text(
                            "Are you absolutely sure you want to demolish this Laboratory? All ongoing procedures, active trials, and contained biological specimens will be completely lost, and the room will revert to an empty facility lot.",
                            style: GoogleFonts.oldStandardTt(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                "NO, CANCEL",
                                style: GoogleFonts.playfairDisplay(
                                  color: const Color(0xFFE5D5B0),
                                ),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                state.demolishRoom(widget.room.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Laboratory demolished and reverted.",
                                    ),
                                    backgroundColor: Color(0xFF241F1A),
                                  ),
                                );
                                Navigator.pop(context); // popup
                                Navigator.pop(context); // laboratory screen
                              },
                              child: Text(
                                "YES, DEMOLISH",
                                style: GoogleFonts.playfairDisplay(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          body: Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel: Active Experiments / Construct Reanimations
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('ACTIVE TRIALS'),
                              const SizedBox(height: 12),
                              Expanded(
                                child: activeExperiments.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No ongoing trials or reanimations.',
                                          style: GoogleFonts.oldStandardTt(
                                            color: Colors.white12,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: activeExperiments.length,
                                        itemBuilder: (context, index) {
                                          final exp = activeExperiments[index];
                                          final subject = state.npcs.firstWhere(
                                            (n) => n.id == exp.subjectId,
                                          );
                                          return _buildActiveExperimentTile(
                                            context,
                                            exp,
                                            subject,
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white10, height: 24),
                        _buildSectionTitle('PROCEDURE QUEUE'),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: SingleChildScrollView(
                            child: _buildLaboratoryQueue(context, state),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right Panel: Science Activities Available in the Laboratory
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(
                            'LABORATORY PROCEDURES & EXPERIMENTS',
                          ),
                          const SizedBox(height: 16),
                          _buildScienceActivities(context, state),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        color: const Color(0xFFE5D5B0),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildActiveExperimentTile(
    BuildContext context,
    Experiment exp,
    NPC subject,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exp.type.name.toUpperCase(),
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFE5D5B0),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "SUBJECT: ${subject.name}",
            style: GoogleFonts.oldStandardTt(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: exp.progress,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC4B89B)),
            minHeight: 2,
          ),
          const SizedBox(height: 8),
          Text(
            "${exp.minutesRemaining}M REMAINING",
            style: GoogleFonts.oldStandardTt(
              color: const Color(0xFFC4B89B),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _getPrettyTypeName(String type) {
    if (type == 'rat_specimen' || type == 'rat') return 'SMALL SPECIMEN';
    if (type == 'bat_specimen' || type == 'bat')
      return 'SMALL SPECIMEN (FLYING)';
    if (type == 'chicken') return 'LIVESTOCK (CHICKEN)';
    if (type == 'herb_reagent') return 'HERB REAGENT';
    if (type == 'specimen') return 'BIOLOGICAL SPECIMEN';
    if (type == 'large_specimen') return 'LARGE SPECIMEN';
    return type.replaceAll('_', ' ').toUpperCase();
  }

  Widget _buildLaboratoryQueue(BuildContext context, GameState state) {
    if (state.laboratoryQueue.isEmpty) {
      return Text(
        'NO PROCEDURES.',
        style: GoogleFonts.oldStandardTt(color: Colors.white24, fontSize: 10),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: state.laboratoryQueue.asMap().entries.map((entry) {
        final index = entry.key;
        final queueId = entry.value;
        final parts = queueId.split(':');
        final category = parts[0];
        final activityId = parts.length > 1 ? parts[1] : null;
        final isActivity = category == 'activity';

        String title = queueId.toUpperCase();

        if (isActivity && activityId != null) {
          final cleanActivityId = activityId.split(':').first;
          final activity = ScienceService.getActivityById(cleanActivityId);
          if (activity != null) {
            String actionName = 'procedure';
            if (activity.id.contains('dissection')) {
              actionName = 'dissection';
            } else if (activity.id.contains('vivisection')) {
              actionName = 'vivisection';
            } else if (activity.id.contains('reanimation')) {
              actionName = 'reanimation';
            } else {
              actionName = activity.name.toLowerCase();
            }

            if (parts.length > 2 && parts[2].isNotEmpty) {
              final targetIds = parts[2].split(',');
              final targetNames = targetIds
                  .map((id) {
                    final npc = state.npcs.firstWhereOrNull((n) => n.id == id);
                    if (npc != null) {
                      final species = npc.specimenType.toLowerCase();
                      final gender = npc.gender.toLowerCase();
                      return '$species, $gender';
                    }
                    final chicken = state.chickens.firstWhereOrNull(
                      (c) => c.id == id,
                    );
                    if (chicken != null) {
                      return 'chicken, female';
                    }
                    final item = state.inventory.firstWhereOrNull(
                      (i) => i.id == id,
                    );
                    if (item != null) {
                      return item.name.toLowerCase();
                    }
                    return 'unknown';
                  })
                  .join(', ');
              title = '$actionName ($targetNames)'.toUpperCase();
            } else {
              title = activity.name.toUpperCase();
            }
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 2.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${index + 1}. $title',
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFC4B89B),
                    fontSize: 10.5,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => state.removeLaboratoryFromQueue(index),
                child: const Padding(
                  padding: EdgeInsets.only(right: 12.0, left: 2.0, top: 2.0, bottom: 2.0),
                  child: Icon(Icons.close, size: 10, color: Colors.white24),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScienceActivities(BuildContext context, GameState state) {
    // Tightly filter Science Activities to retain those exclusive to the Laboratory
    // and correctly evaluate their exact unlocking milestones
    final activities = ScienceService.getAvailableActivities().where((a) {
      if (a.id == 'generic_research') return false; // Belongs to Study
      return state.unlockedLabActivities.contains(a.id);
    }).toList();

    if (activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Text(
          'No Laboratory Procedures currently accessible.\nDevelop alchemical notes or clean laboratory spaces to reveal options.',
          style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 14),
        ),
      );
    }

    return Column(
      children: activities.map<Widget>((activity) {
        bool canStart = true;
        activity.ingredients.forEach((ing, count) {
          num available =
              state.inventory
                  .where((i) {
                    if (ing == 'meat') {
                      return i.type.contains('meat') ||
                          i.category == ItemCategory.specimen;
                    }
                    if (ing == 'specimen' || ing == 'rat_specimen') {
                      return i.type == 'rat' ||
                          i.type == 'bat' ||
                          i.type == 'chicken' ||
                          i.category == ItemCategory.specimen;
                    }
                    return i.type == ing;
                  })
                  .fold(0, (sum, i) => sum + i.quantity) +
              ((ing == 'specimen' || ing == 'rat_specimen')
                  ? (state.resources['rat'] ?? 0) +
                        (state.resources['bat'] ?? 0) +
                        (state.resources['chicken'] ?? 0)
                  : (state.resources[ing] ?? 0));
          if (available < count) canStart = false;
        });

        final metadata = TaskService.getMetadata(activity.type);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
            ),
            color: Colors.black.withValues(alpha: 0.3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activity.name.toUpperCase(),
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      "${activity.baseDurationMinutes ~/ 60}H ${activity.baseDurationMinutes % 60}M",
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
                  activity.outcomeDescription,
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
                            'REQUIRED MATERIALS',
                            style: GoogleFonts.oswald(
                              fontSize: 9,
                              color: const Color(
                                0xFFE5D5B0,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children: activity.ingredients.entries.map<Widget>((
                              e,
                            ) {
                              final ing = e.key;
                              final count = e.value;
                              num available =
                                  state.inventory
                                      .where((i) {
                                        if (ing == 'meat') {
                                          return i.type.contains('meat') ||
                                              i.category ==
                                                  ItemCategory.specimen;
                                        }
                                        if (ing == 'specimen' ||
                                            ing == 'rat_specimen') {
                                          return i.type == 'rat' ||
                                              i.type == 'bat' ||
                                              i.type == 'chicken' ||
                                              i.category ==
                                                  ItemCategory.specimen;
                                        }
                                        return i.type == ing;
                                      })
                                      .fold(0, (sum, i) => sum + i.quantity) +
                                  ((ing == 'specimen' || ing == 'rat_specimen')
                                      ? (state.resources['rat'] ?? 0) +
                                            (state.resources['bat'] ?? 0) +
                                            (state.resources['chicken'] ?? 0)
                                      : (state.resources[ing] ?? 0));
                              final hasEnough =
                                  available.round() >= count.round();

                              return Text(
                                '${_getPrettyTypeName(e.key)}: ${e.value.round()}',
                                style: GoogleFonts.oldStandardTt(
                                  color: hasEnough
                                      ? const Color(0xFFC4B89B)
                                      : Colors.redAccent,
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
                            'EFFICIENCY STATS',
                            style: GoogleFonts.oswald(
                              fontSize: 9,
                              color: const Color(
                                0xFFE5D5B0,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            metadata.relevantAttributes
                                .join(", ")
                                .toUpperCase(),
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
                    onPressed: canStart
                        ? () => _showScienceActivityTargetDialog(
                            context,
                            state,
                            activity,
                          )
                        : null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: canStart
                            ? const Color(0xFFC4B89B)
                            : Colors.white10,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'COMMENCE PROCEDURE',
                      style: GoogleFonts.playfairDisplay(
                        color: canStart
                            ? const Color(0xFFE5D5B0)
                            : Colors.white12,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showScienceActivityTargetDialog(
    BuildContext context,
    GameState state,
    ScienceActivity activity,
  ) {
    // Identify specimen requirements
    final specimenRequirements = activity.ingredients.entries
        .where(
          (e) =>
              e.key == 'specimen' ||
              e.key == 'large_specimen' ||
              e.key == 'rat_specimen' ||
              e.key == 'research_notes',
        )
        .toList();

    if (specimenRequirements.isEmpty) {
      state.addScienceActivityToQueue(activity.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PROCEDURE COMMENCED'),
          backgroundColor: Color(0xFFC4B89B),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return;
    }

    final reqType = specimenRequirements.first.key;
    final reqCount = specimenRequirements.first.value;

    final potentialOccupants = state.getAvailableSpecimenTargets(reqType);

    showDialog(
      context: context,
      builder: (context) {
        final List<String> selectedIds = [];
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1612),
              title: Text(
                'ASSIGN EXPERIMENT SUBJECTS (${selectedIds.length}/$reqCount)',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              content: SizedBox(
                width: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PROCEDURE: ${activity.name.toUpperCase()}\nREQUIRED: $reqCount ${reqType.replaceAll('_', ' ').toUpperCase()}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.oldStandardTt(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (potentialOccupants.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No viable biological subjects currently in the Laboratory.',
                          style: GoogleFonts.oldStandardTt(
                            color: Colors.white38,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: potentialOccupants.length,
                          itemBuilder: (context, index) {
                            final subj = potentialOccupants[index];
                            final subjId = subj['id'] as String;
                            final subjName = subj['name'] as String;
                            final subjType = subj['type'] as String;
                            final vitality = subj['vitality'] as num? ?? 100;
                            final isSelected = selectedIds.contains(subjId);
                            return InkWell(
                              onTap: () {
                                setDialogState(() {
                                  if (isSelected) {
                                    selectedIds.remove(subjId);
                                  } else {
                                    if (selectedIds.length < reqCount) {
                                      selectedIds.add(subjId);
                                    }
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF2E1A0A)
                                      : Colors.black26,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFC4B89B)
                                        : Colors.white10,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.biotech,
                                      color: isSelected
                                          ? const Color(0xFFE5D5B0)
                                          : Colors.white24,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            subjName.toUpperCase(),
                                            style: GoogleFonts.playfairDisplay(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Type: ${subjType.toUpperCase()} | Vitality: ${vitality.round()}',
                                            style: GoogleFonts.oldStandardTt(
                                              color: Colors.white54,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFFC4B89B),
                                        size: 16,
                                      ),
                                  ],
                                ),
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
                    style: GoogleFonts.oldStandardTt(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedIds.length >= reqCount
                      ? () {
                          Navigator.pop(context);
                          state.addScienceActivityToQueue(
                            activity.id,
                            reservedEntityIds: selectedIds,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PROCEDURE COMMENCED'),
                              backgroundColor: Color(0xFFC4B89B),
                              duration: Duration(milliseconds: 1500),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E1A0A),
                    side: const BorderSide(color: Color(0xFFC4B89B)),
                  ),
                  child: Text(
                    'START PROCEDURE',
                    style: GoogleFonts.playfairDisplay(
                      color: selectedIds.length >= reqCount
                          ? const Color(0xFFE5D5B0)
                          : Colors.white24,
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
}
