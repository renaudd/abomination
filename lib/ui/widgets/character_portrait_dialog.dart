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
import '../../models/npc.dart';
import '../../models/npc_intent.dart';
import '../../models/relationship.dart';
import '../../services/social_service.dart';
import '../../state/game_state.dart';
import 'character_blob_renderer.dart';
import '../../services/task_service.dart';
import '../../models/responsibility.dart';

class CharacterPortraitDialog extends StatelessWidget {
  final NPC npc;

  const CharacterPortraitDialog({super.key, required this.npc});

  String _getMoodDescription(NPC liveNpc) {
    if (liveNpc.satisfaction < 30) return "ANGRY";
    if (liveNpc.satisfaction < 60) return "DISCONTENT";
    if (liveNpc.energy < 30) return "EXHAUSTED";
    if (liveNpc.hunger >= 90) return "FAMISHED";
    return "CONTENT";
  }

  Color _getMoodColor(NPC liveNpc) {
    final mood = _getMoodDescription(liveNpc);
    if (mood == "ANGRY" || mood == "FAMISHED") return Colors.redAccent;
    if (mood == "DISCONTENT" || mood == "EXHAUSTED") return Colors.orangeAccent;
    return const Color(0xFFC4B89B);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        final liveNpc = state.npcs.firstWhere((n) => n.id == npc.id, orElse: () => npc);
        final mood = _getMoodDescription(liveNpc);
        final moodColor = _getMoodColor(liveNpc);

        return Dialog(
          backgroundColor: const Color(0xFF1E1A15),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: DefaultTabController(
            length: 2,
            child: Container(
              width: 450,
              height: 600,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFC4B89B), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with Portrait and Basic Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFC4B89B).withValues(alpha: 0.5),
                          ),
                          color: Colors.black26,
                        ),
                        child: Center(
                          child: CharacterBlobRenderer(
                            npc: liveNpc,
                            size: 80,
                            isIdle: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              liveNpc.name.toUpperCase(),
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFE5D5B0),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              liveNpc.status == NPCStatus.zombie
                                  ? "${liveNpc.role} (REANIMATED)".toUpperCase()
                                  : liveNpc.role.toUpperCase(),
                              style: GoogleFonts.oldStandardTt(
                                color: liveNpc.status == NPCStatus.zombie
                                    ? const Color(0xFF7A9E7E)
                                    : const Color(
                                        0xFFC4B89B,
                                      ).withValues(alpha: 0.7),
                                fontSize: 12,
                                letterSpacing: 1,
                                fontWeight: liveNpc.status == NPCStatus.zombie
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: moodColor.withValues(alpha: 0.5),
                                ),
                                color: moodColor.withValues(alpha: 0.1),
                              ),
                              child: Text(
                                mood,
                                style: GoogleFonts.outfit(
                                  color: moodColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TabBar(
                    indicatorColor: const Color(0xFFC4B89B),
                    labelColor: const Color(0xFFE5D5B0),
                    unselectedLabelColor: Colors.white24,
                    labelStyle: GoogleFonts.playfairDisplay(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    tabs: const [
                      Tab(text: "STATUS"),
                      Tab(text: "SOCIAL"),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildStatusTab(context, liveNpc, state),
                        _buildSocialTab(context, liveNpc, state),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "CLOSE",
                      style: GoogleFonts.oldStandardTt(
                        color: const Color(0xFFC4B89B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusTab(BuildContext context, NPC liveNpc, GameState state) {
    return ListView(
      children: [
        _buildStatBar(
          "ENERGY / EXHAUSTION",
          liveNpc.energy / 100,
          Colors.blueAccent,
        ),
        const SizedBox(height: 12),
        _buildStatBar(
          "DIGESTION",
          liveNpc.digestion / 100,
          Colors.deepOrangeAccent,
        ),
        const SizedBox(height: 12),
        _buildStatBar(
          "FULLNESS",
          (100 - liveNpc.hunger) / 100,
          Colors.greenAccent,
        ),
        const SizedBox(height: 12),
        _buildStatBar(
          "SATISFACTION",
          liveNpc.satisfaction / 100,
          Colors.amberAccent,
        ),
        const SizedBox(height: 12),
        _buildStatBar(
          "CLEANLINESS",
          liveNpc.cleanliness / 100,
          Colors.cyanAccent,
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: _getMoodColor(liveNpc).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _getMoodDescription(liveNpc),
              style: GoogleFonts.playfairDisplay(
                color: _getMoodColor(liveNpc),
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildActivitySection(context, liveNpc, state),
        const SizedBox(height: 24),
        _buildUpcomingSection(liveNpc, state),
        const SizedBox(height: 24),
        _buildHousingSection(context, liveNpc, state),
      ],
    );
  }



  Widget _buildSocialTab(BuildContext context, NPC liveNpc, GameState state) {
    if (liveNpc.isPlayer) {
      return Center(
        child: Text(
          "YOU ARE MASTER OF THIS DOMAIN.",
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFC4B89B),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      );
    }

    return ListView(
      children: [
        _sectionHeader("RELATIONSHIP WITH YOU"),
        const SizedBox(height: 16),
        _buildInteractionSection(context, liveNpc, state),
        const SizedBox(height: 24),
        _sectionHeader("OTHER BONDS"),
        const SizedBox(height: 12),
        ...state.npcs.where((n) => n.id != liveNpc.id && !n.isPlayer).map((n) {
          final rel = liveNpc.relationships[n.id] ?? Relationship();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.name.toUpperCase(),
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMiniRelStat("ADM", rel.admiration, Colors.pinkAccent),
                    const SizedBox(width: 8),
                    _buildMiniRelStat("RES", rel.respect, Colors.cyanAccent),
                    const SizedBox(width: 8),
                    _buildMiniRelStat("FEAR", rel.fear, Colors.deepPurpleAccent),
                    const SizedBox(width: 8),
                    _buildMiniRelStat("ATTR", rel.attraction, Colors.redAccent),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInteractionSection(
    BuildContext context,
    NPC liveNpc,
    GameState state,
  ) {
    final player = state.npcs.firstWhere((n) => n.isPlayer);
    final rel = liveNpc.relationships[player.id] ?? Relationship();

    // Only allow interaction if they are in the same room
    final bool canInteract = player.currentRoomId == liveNpc.currentRoomId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "RELATIONSHIP: ${(rel.loyalty * 20).toStringAsFixed(0)}% LOYALTY",
          style: GoogleFonts.outfit(
            color: const Color(0xFFC4B89B),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: rel.loyalty / 5.0,
          backgroundColor: Colors.white12,
          color: rel.loyalty >= 2.5 ? Colors.greenAccent : Colors.redAccent,
          minHeight: 4,
        ),
        const SizedBox(height: 24),
        if (canInteract)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildInteractButton(state, liveNpc, InteractionType.chat, Icons.chat_bubble_outline),
              _buildInteractButton(state, liveNpc, InteractionType.praise, Icons.thumb_up_outlined),
              _buildInteractButton(state, liveNpc, InteractionType.argument, Icons.gavel_outlined),
              _buildInteractButton(state, liveNpc, InteractionType.threaten, Icons.security),
              _buildInteractButton(state, liveNpc, InteractionType.workTogether, Icons.handshake_outlined),
            ],
          )
        else
          Text(
            "YOU MUST BE IN THE SAME ROOM TO INTERACT.",
            style: GoogleFonts.oldStandardTt(
              color: Colors.white24,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildInteractButton(
    GameState state,
    NPC liveNpc,
    InteractionType type,
    IconData icon,
  ) {
    return InkWell(
      onTap: () => state.interactWithNpc(liveNpc.id, type),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFC4B89B), size: 18),
            const SizedBox(height: 4),
            Text(
              type.name.toUpperCase(),
              style: GoogleFonts.outfit(fontSize: 8, color: const Color(0xFFC4B89B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection(BuildContext context, NPC liveNpc, GameState state) {
    final activeTask = liveNpc.activeTaskId != null 
        ? state.activeTasks.firstWhereOrNull((t) => t.id == liveNpc.activeTaskId) 
        : null;
    final targetRoom = state.rooms.firstWhereOrNull((r) => r.id == liveNpc.targetRoomId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("CURRENT ACTIVITY"),
        const SizedBox(height: 12),
        if (activeTask != null)
          _buildTaskTile(state, activeTask, liveNpc)
        else
          Text(
            "NO ACTIVE ASSIGNMENT",
            style: GoogleFonts.oldStandardTt(
              color: const Color(0xFFC4B89B).withValues(alpha: 0.5),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        if (targetRoom != null && liveNpc.currentRoomId != liveNpc.targetRoomId)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.map_outlined,
                  size: 14,
                  color: Color(0xFFC4B89B),
                ),
                const SizedBox(width: 8),
                Text(
                  "EN ROUTE TO ${targetRoom.name.toUpperCase()}",
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFC4B89B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  bool _isLeisure(NPCIntent i) =>
      i.id.startsWith('sched_leisure') ||
      i.id.startsWith('artwork') ||
      (TaskCategoryMapping.getCategory(i.action) == null && i.priority == IntentPriority.low);

  Widget _buildUpcomingSection(NPC liveNpc, GameState state) {
    final activeTask = liveNpc.activeTaskId != null 
        ? state.activeTasks.firstWhereOrNull((t) => t.id == liveNpc.activeTaskId) 
        : null;
    final activeIntentId = activeTask?.intentId;
    
    // Upcoming assignments (excluding active task)
    final allUpcoming = liveNpc.intentQueue.where((i) => i.id != liveNpc.activeTaskId && i.id != activeIntentId).toList();
    
    final emergencies = allUpcoming.where((i) => i.priority == IntentPriority.emergency).toList();
    final high = allUpcoming.where((i) => i.priority == IntentPriority.high || i.priority == IntentPriority.urgent).toList();
    final normal = allUpcoming.where((i) => i.priority == IntentPriority.normal).toList();
    final low = allUpcoming.where((i) => i.priority == IntentPriority.low && !_isLeisure(i)).toList();
    final leisure = allUpcoming.where((i) => i.priority == IntentPriority.low && _isLeisure(i)).toList();

    List<Map<String, dynamic>> elements = [];

    void addHeader(String title) {
      elements.add({'type': 'header', 'title': title, 'id': 'hdr_$title'});
    }

    if (emergencies.isNotEmpty) {
      addHeader("EMERGENCIES");
      elements.addAll(emergencies.map((e) => {'type': 'intent', 'intent': e, 'id': e.id}));
    }
    
    if (high.isNotEmpty) {
      addHeader("HIGH PRIORITY");
      elements.addAll(high.map((e) => {'type': 'intent', 'intent': e, 'id': e.id}));
    }
    
    addHeader("NORMAL PRIORITY");
    if (normal.isEmpty) {
      elements.add({'type': 'empty', 'title': 'WAITING FOR ORDERS', 'id': 'emp_normal'});
    } else {
      elements.addAll(normal.map((e) => {'type': 'intent', 'intent': e, 'id': e.id}));
    }

    addHeader("LOW PRIORITY WORK");
    elements.addAll(low.map((e) => {'type': 'intent', 'intent': e, 'id': e.id}));

    addHeader("LEISURE TASKS");
    elements.addAll(leisure.map((e) => {'type': 'intent', 'intent': e, 'id': e.id}));

    void handleReorder(int oldIndex, int newIndex) {
      if (oldIndex < newIndex) newIndex -= 1;
      final item = elements[oldIndex];
      // Only intents can be reordered
      if (item['type'] != 'intent') return;
      
      final draggedIntent = item['intent'] as NPCIntent;
      
      // Find destination bucket
      IntentPriority destPriority = draggedIntent.priority;
      bool isDestLeisure = false;
      
      for (int i = newIndex; i >= 0; i--) {
        if (elements[i]['type'] == 'header') {
          final t = elements[i]['title'];
          if (t == "EMERGENCIES") {
            destPriority = IntentPriority.emergency;
          } else if (t == "HIGH PRIORITY") {
            destPriority = IntentPriority.high;
          } else if (t == "NORMAL PRIORITY") {
            destPriority = IntentPriority.normal;
          } else if (t == "LOW PRIORITY WORK") {
            destPriority = IntentPriority.low;
          } else if (t == "LEISURE TASKS") {
            destPriority = IntentPriority.low;
            isDestLeisure = true;
          }
          break;
        }
      }

      // Constraints
      if (draggedIntent.priority == IntentPriority.emergency && destPriority != IntentPriority.emergency) return;
      if (_isLeisure(draggedIntent) && !isDestLeisure) return; // Leisure can't go to non-leisure
      if (isDestLeisure && !_isLeisure(draggedIntent)) return; // Work can't go to leisure
      
      // We are allowed to move it! Construct the new sequence.
      elements.removeAt(oldIndex);
      elements.insert(newIndex, item);
      
      // Rebuild the final intentQueue
      List<NPCIntent> newQueue = [];
      
      for (var el in elements) {
        if (el['type'] == 'intent') {
          NPCIntent i = el['intent'] as NPCIntent;
          if (i.id == draggedIntent.id) {
             // Upgraded/Downgraded Priority!
             i = i.copyWith(priority: destPriority);
          }
          newQueue.add(i);
        }
      }
      
      // Read the missing intents (active tasks) from liveNpc.intentQueue and put them at the TOP of the new queue
      final missingIntents = liveNpc.intentQueue.where((i) => i.id == liveNpc.activeTaskId || i.id == activeIntentId).toList();
      newQueue.insertAll(0, missingIntents);
      
      state.updateIntentQueue(liveNpc.id, newQueue);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("TASK QUEUE"),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: ReorderableListView.builder(
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            itemCount: elements.length,
            itemBuilder: (context, index) {
              final el = elements[index];
              if (el['type'] == 'header') {
                return Container(
                  key: ValueKey(el['id']),
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 8, bottom: 4, left: 2),
                  child: Text(
                    el['title'],
                    style: GoogleFonts.oswald(color: const Color(0xFFC4B89B).withValues(alpha: 0.8), fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold),
                  ),
                );
              } else if (el['type'] == 'empty') {
                return Container(
                  key: ValueKey(el['id']),
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  child: Text(
                    el['title'],
                    style: GoogleFonts.oldStandardTt(color: const Color(0xFFC4B89B).withValues(alpha: 0.5), fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                );
              } else {
                final intent = el['intent'] as NPCIntent;
                final bool canDrag = intent.priority != IntentPriority.emergency && !_isLeisure(intent);
                return _buildIntentTile(intent, state, liveNpc.id, index, isManual: canDrag);
              }
            },
            onReorder: handleReorder,
          ),
        ),
      ],
    );
  }

  Widget _buildIntentTile(NPCIntent intent, GameState state, String npcId, int index, {required bool isManual}) {
    final room = state.rooms.firstWhereOrNull((r) => r.id == intent.targetRoomId);
    final roomName = room?.name ?? "Mansion";
    
    String actionName = intent.action.displayName;
    if (intent.action == TaskType.cook && intent.recipeId != null) {
      actionName = "COOK ${intent.recipeId!.replaceAll('_', ' ')}";
    } else if (intent.action == TaskType.butcherAnimals && intent.targetName != null) {
      actionName = "BUTCHER ${intent.targetName}";
    } else if (intent.action == TaskType.eat && intent.targetName != null) {
      actionName = "EAT ${intent.targetName}";
    }

    String displayDesc = (intent.action == TaskType.restoreRoom)
      ? "RESTORE $roomName".toUpperCase()
      : (intent.action == TaskType.eat || intent.action == TaskType.cook)
          ? actionName.toUpperCase()
          : "$actionName IN $roomName".toUpperCase();

    return Padding(
      key: ValueKey(intent.id),
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isManual ? const Color(0xFFC4B89B).withValues(alpha: 0.05) : Colors.black26,
          border: Border.all(
            color: isManual 
              ? const Color(0xFFC4B89B).withValues(alpha: 0.3)
              : const Color(0xFFC4B89B).withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Text(
              "${index + 1}.",
              style: GoogleFonts.oswald(
                color: const Color(0xFFC4B89B).withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              intent.priority.index >= IntentPriority.urgent.index
                  ? Icons.priority_high
                  : Icons.calendar_today,
              size: 14,
              color: intent.priority.index >= IntentPriority.urgent.index
                  ? Colors.redAccent
                  : const Color(0xFFC4B89B),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayDesc,
                style: GoogleFonts.oldStandardTt(
                  fontSize: 11,
                  color: const Color(0xFFE5D5B0),
                ),
              ),
            ),
            if (isManual)
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.drag_handle, color: Colors.white10, size: 18),
                ),
              ),
            IconButton(
              onPressed: () => state.cancelEnqueuedIntent(npcId, intent.id),
              icon: const Icon(Icons.close, color: Colors.redAccent, size: 14),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'CANCEL ASSIGNMENT',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTile(GameState state, GameTask task, NPC liveNpc) {
    final room = state.rooms.firstWhereOrNull((r) => r.id == task.targetId);
    final roomName = room?.name ?? "Mansion";
    
    String actionName = task.type.displayName;
    if (task.type == TaskType.eat && task.targetName != null) {
      actionName = "EAT ${task.targetName}";
    } else if (task.type == TaskType.cook && task.recipeId != null) {
      actionName = "COOK ${task.recipeId!.replaceAll('_', ' ')}";
    }
    
    final description = (task.type == TaskType.restoreRoom)
      ? "RESTORE $roomName".toUpperCase()
      : (task.type == TaskType.eat || task.type == TaskType.cook)
          ? actionName.toUpperCase()
          : "$actionName IN $roomName".toUpperCase();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFC4B89B).withValues(alpha: 0.05),
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC4B89B)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: GoogleFonts.oldStandardTt(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: const Color(0xFFE5D5B0),
                  ),
                ),
                Text(
                  task.type == TaskType.rest ? "UNTIL WAKEFUL" : "${task.minutesRemaining} MINUTES REMAINING",
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    color: const Color(0xFFC4B89B).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHousingSection(BuildContext context, NPC liveNpc, GameState state) {
    final assignedRoom = state.rooms.where((r) => r.id == liveNpc.assignedRoomId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("DOMICILE"),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.king_bed_outlined,
              size: 16,
              color: Color(0xFFC4B89B),
            ),
            const SizedBox(width: 12),
            Text(
              assignedRoom?.name.toUpperCase() ?? "NO ASSIGNED QUARTERS",
              style: GoogleFonts.oldStandardTt(
                color: const Color(0xFFE5D5B0),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        color: const Color(0xFFC4B89B),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildStatBar(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: const Color(0xFFC4B89B),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              "${(progress * 100).toInt()}%",
              style: GoogleFonts.oldStandardTt(
                color: const Color(0xFFC4B89B),
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 2,
        ),
      ],
    );
  }

  Widget _buildMiniRelStat(String label, double value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: color.withValues(alpha: 0.6),
              fontSize: 7,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          LinearProgressIndicator(
            value: value / 5.0,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 2,
          ),
        ],
      ),
    );
  }
}
