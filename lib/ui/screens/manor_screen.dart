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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../state/game_state.dart';
import '../../models/room.dart';
import '../../util/manor_layout.dart';
import '../../services/task_service.dart';
import '../../services/science_service.dart';
import '../../services/kitchen_service.dart';
import '../../services/save_service.dart';
import '../../models/game_item.dart';
import '../../models/npc.dart';
import '../widgets/manor_renderer.dart';
import '../widgets/character_portrait_dialog.dart';
import '../widgets/room_ledger.dart';
import '../widgets/bed_assignment_widget.dart';
import 'study_screen.dart';
import 'kitchen_screen.dart';
import 'dining_room_screen.dart';
import 'garden_screen.dart';
import 'library_screen.dart';
import 'laboratory_screen.dart';
import 'chicken_coop_screen.dart';
import 'world_map_screen.dart';
import '../widgets/save_load_dialogs.dart';
import '../widgets/visiting_merchant_trade_dialog.dart';
import '../widgets/guest_conversation_dialog.dart';
import '../widgets/encounter_dialog.dart';
import 'game_over_screen.dart';
import 'records_screen.dart';
import 'main_menu_screen.dart';
import '../widgets/options_dialog.dart';
import '../widgets/cheat_codes_dialog.dart';
import 'help_screen.dart';
import '../../models/active_business.dart';
import '../widgets/flaubert_event_dialog.dart';
import '../widgets/dental_event_dialog.dart';
import '../widgets/restaurant_tycoon_dialog.dart';

class ManorScreen extends StatefulWidget {
  const ManorScreen({super.key});

  @override
  State<ManorScreen> createState() => _ManorScreenState();
}

class _ManorScreenState extends State<ManorScreen> {
  bool _hudExpanded = true;
  bool _isNavigatingToCombat = false;
  bool _isShowingGuestConversation = false;
  bool _timeControlsExpanded = false;
  bool _isFirstVisit = true;

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback or status listener if needed,
    // but a simpler way is to check in didChangeDependencies or use a listener.
  }

  void _checkCombatEncounter(GameState state) {
    if (state.pendingCombatEncounter && !_isNavigatingToCombat && ModalRoute.of(context)?.isCurrent == true) {
      _isNavigatingToCombat = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const EncounterDialog(),
        ).then((_) {
          if (mounted) {
            setState(() {
              _isNavigatingToCombat = false;
            });
          }
        });
      });
    }
  }

  void _checkGuestConversation(GameState state) {
    if (state.pendingGuestConversation && !_isShowingGuestConversation && ModalRoute.of(context)?.isCurrent == true) {
      _isShowingGuestConversation = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const GuestConversationDialog(),
        ).then((_) {
          if (mounted) {
            setState(() {
              _isShowingGuestConversation = false;
            });
          }
        });
      });
    }
  }

  bool _isShowingFlaubertEvent = false;

  void _checkFlaubertEvent(GameState state) {
    if (state.activeFlaubertEvent != null && !_isShowingFlaubertEvent && ModalRoute.of(context)?.isCurrent == true) {
      _isShowingFlaubertEvent = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const FlaubertEventDialog(),
        ).then((_) {
          if (mounted) {
            setState(() {
              _isShowingFlaubertEvent = false;
            });
          }
        });
      });
    }
  }

  bool _isShowingDentalSetup = false;

  void _checkDentalSetup(GameState state) {
    final isDentist = state.playerAcademicSpecialization == 'Dentistry';
    final hasNoLoan = state.activeDentalLoan == 0;
    final hasNoClinic = !state.rooms.any((r) => r.type == RoomType.dentalClinic);

    if (isDentist && hasNoLoan && hasNoClinic && !_isShowingDentalSetup && ModalRoute.of(context)?.isCurrent == true) {
      _isShowingDentalSetup = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const DentalSetupDialog(),
        ).then((_) {
          if (mounted) {
            setState(() {
              _isShowingDentalSetup = false;
            });
          }
        });
      });
    }
  }

  bool _isShowingDentalEvent = false;

  void _checkDentalEvent(GameState state) {
    if (state.activeDentalEvent != null && !_isShowingDentalEvent && ModalRoute.of(context)?.isCurrent == true) {
      _isShowingDentalEvent = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const DentalEventDialog(),
        ).then((_) {
          if (mounted) {
            setState(() {
              _isShowingDentalEvent = false;
            });
          }
        });
      });
    }
  }

  bool _isShowingRestaurantTycoonEvent = false;

  void _checkRestaurantTycoonEvent(GameState state) {
    if (state.activeRestaurantTycoonEvent != null && !_isShowingRestaurantTycoonEvent && ModalRoute.of(context)?.isCurrent == true) {
      _isShowingRestaurantTycoonEvent = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const RestaurantTycoonDialog(),
        ).then((_) {
          if (mounted) {
            setState(() {
              _isShowingRestaurantTycoonEvent = false;
            });
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);
    _checkCombatEncounter(state);
    _checkGuestConversation(state);
    _checkFlaubertEvent(state);
    _checkDentalSetup(state);
    _checkDentalEvent(state);
    _checkRestaurantTycoonEvent(state);

    if (state.isGameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => GameOverScreen(
              reason: state.gameOverReason ?? "The experiment has ended.",
            ),
          ),
          (route) => false,
        );
      });
    }

    return Scaffold(
        backgroundColor: const Color(0xFF1A1612),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        toolbarHeight: 36,
        titleSpacing: 16,
        title: Row(
          children: [
            // a) Manor Holdings
            Consumer<GameState>(
              builder: (context, state, child) {
                return InkWell(
                  onTap: () => _showManorHoldings(context, state),
                  child: Row(
                    children: [
                      _resourceItem(
                        Icons.payments,
                        (state.resources['funds'] ?? 0).round().toString(),
                      ),
                      const SizedBox(width: 16),
                      _resourceItem(
                        Icons.restaurant,
                        state.pantry.length.toString(),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Spacer(),
            // b) Records
            Consumer<GameState>(
              builder: (context, state, child) {
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.history_edu, color: Color(0xFFC4B89B)),
                      tooltip: 'Records',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RecordsScreen(),
                          ),
                        );
                      },
                    ),
                    if (state.unreadObjectiveCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              '${state.unreadObjectiveCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            // c) Expand logs
            IconButton(
              icon: Icon(
                _hudExpanded ? Icons.expand_less : Icons.expand_more,
                color: const Color(0xFFC4B89B),
              ),
              onPressed: () => setState(() => _hudExpanded = !_hudExpanded),
              tooltip: 'Toggle Logs',
            ),
            // d) Survey Estate
            IconButton(
              icon: const Icon(Icons.map_outlined, color: Color(0xFFC4B89B)),
              tooltip: 'Survey Estate',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorldMapScreen(),
                  ),
                );
              },
            ),
            // e) Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu, color: Color(0xFFC4B89B)),
              tooltip: 'Menu',
              color: const Color(0xFF1A1612),
              onSelected: (value) {
                if (value == 'save') {
                  showDialog(
                    context: context,
                    builder: (context) => const SaveGameDialog(),
                  );
                } else if (value == 'load') {
                  showDialog(
                    context: context,
                    builder: (context) => LoadGameDialog(
                      onSlotSelected: (slot) async {
                        final state = context.read<GameState>();
                        final data = await SaveService.loadGame(slot: slot);
                        if (data != null && context.mounted) {
                          state.loadFromJson(data);
                          Navigator.pop(context);
                        }
                      },
                    ),
                  );
                } else if (value == 'options') {
                  _showOptionsDialog(context);
                } else if (value == 'help') {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen()));
                } else if (value == 'cheat_codes') {
                  _showCheatCodesDialog(context, state);
                } else if (value == 'quit') {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainMenuScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'save',
                  child: Text(
                    'Save Game',
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFE5D5B0),
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'load',
                  child: Text(
                    'Load Game',
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFE5D5B0),
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'options',
                  child: Text(
                    'Options',
                    style: GoogleFonts.oldStandardTt(color: const Color(0xFFE5D5B0)),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'help',
                  child: Text(
                    'Help',
                    style: GoogleFonts.oldStandardTt(color: const Color(0xFFE5D5B0)),
                  ),
                ),
                if (state.cheatCodesEnabled)
                  PopupMenuItem<String>(
                    value: 'cheat_codes',
                    child: Text(
                      'Cheat Codes',
                      style: GoogleFonts.oldStandardTt(
                        color: const Color(0xFFE5D5B0),
                      ),
                    ),
                  ),
                PopupMenuItem<String>(
                  value: 'quit',
                  child: Text(
                    'Quit to Menu',
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFE5D5B0),
                    ),
                  ),
                ),
              ],
            ),
                _buildClockWidget(context),
              ],
            ),
          ),
          body: Stack(
        children: [
          if (_hudExpanded)
            Positioned(
              bottom: 16,
              left: 16,
              child: _buildAbstractedTheaterCard(context, state),
            ),
          Container(
            color: const Color(0xFF0A0C0E),
            child: Column(
              children: [
                // Collapsible Section
                AnimatedCrossFade(
                  firstChild: Column(
                    children: [
                      _buildAnnouncementBanner(context),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.0),
                        child: Divider(color: Colors.white10),
                      ),
                    ],
                  ),
                  secondChild: const SizedBox.shrink(),
                  crossFadeState: _hudExpanded
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 300),
                ),
                Expanded(
                  child: Consumer<GameState>(
                    builder: (context, state, child) {
                      return ManorRenderer(
                        rooms: state.rooms,
                        npcs: state.npcs,
                        crises: state.crises,
                        activeConstruction: state.activeConstruction,
                        onRoomTap: (room) => _showRoomDetails(context, room),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_timeControlsExpanded)
            Positioned(
              top: 0,
              right: 16,
              child: Consumer<GameState>(
                builder: (context, state, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1612).withValues(alpha: 0.9),
                      border: Border.all(
                        color: const Color(0xFFC4B89B).withValues(alpha: 0.3),
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _speedIcon(context, state, GameSpeed.paused, Icons.pause, 'PAUSE'),
                        _speedIcon(context, state, GameSpeed.slow, Icons.play_arrow_outlined, 'SLOW'),
                        _speedIcon(context, state, GameSpeed.normal, Icons.play_arrow, 'NORMAL'),
                        _speedIcon(context, state, GameSpeed.fast, Icons.fast_forward, 'FAST'),
                        _speedIcon(context, state, GameSpeed.superFast, Icons.bolt, 'LIGHTNING'),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // Removed _buildResourceBar

  Widget _resourceItem(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFFC4B89B)),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: const Color(0xFFE5D5B0),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementBanner(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        if (state.announcementHistory.isEmpty) return const SizedBox.shrink();
        return _AnnouncementBanner(history: state.announcementHistory);
      },
    );
  }

  void _showOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const OptionsDialog(),
    );
  }

  void _showManorHoldings(BuildContext context, GameState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1612),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (context) {
        final roomsWithContent = state.rooms.where((r) {
          final ledger = RoomLedger(room: r, state: state);
          return ledger.getLedgerItems().isNotEmpty;
        }).toList();

        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MANOR HOLDINGS',
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFE5D5B0)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 32),
              Expanded(
                child: roomsWithContent.isEmpty
                    ? Center(
                        child: Text(
                          'NO ITEMS POSSESSED.',
                          style: GoogleFonts.oldStandardTt(
                            color: Colors.white24,
                          ),
                        ),
                      )
                    : ListView.separated(
                        separatorBuilder: (context, index) =>
                            const Divider(color: Colors.white10, height: 32),
                        itemCount: roomsWithContent.length,
                        itemBuilder: (context, index) {
                          final room = roomsWithContent[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.name.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFC4B89B),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              RoomLedger(room: room, state: state),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRoomDetails(BuildContext context, Room room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF241F1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (context) {
        return Consumer<GameState>(
          builder: (context, state, child) {
            final liveRoom = state.rooms.firstWhere(
              (r) => r.id == room.id,
              orElse: () => room,
            );
            final roomQueue = state.getRoomTaskQueue(liveRoom.id);
            final activeTasksInRoom = state.activeTasks
                .where((t) => t.targetId == liveRoom.id)
                .toList();

            final displayQueue = roomQueue.where((q) {
              for (var active in activeTasksInRoom) {
                if (q.intentId == active.intentId || q.intentId == active.id) {
                  return false;
                }
              }
              return true;
            }).toList();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      liveRoom.name.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: const Color(0xFFE5D5B0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      liveRoom.isRestored
                          ? 'RESTORED AND FUNCTIONAL.'
                          : 'THIS ROOM IS IN DISREPAIR AND REQUIRES RESTORATION.',
                      style: GoogleFonts.oldStandardTt(
                        fontSize: 11,
                        color: const Color(0xFFC4B89B),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...state.activeTasks.where((t) => t.targetId == liveRoom.id).map((
                      activeTask,
                    ) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(
                              0xFFC4B89B,
                            ).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.hourglass_bottom,
                              color: Color(0xFFE5D5B0),
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${state.npcs.firstWhereOrNull((n) => n.id == activeTask.npcId)?.name.toUpperCase() ?? "WORKER"} IS CURRENTLY ${state.getTaskDescription(activeTask).toUpperCase()}",
                                style: GoogleFonts.oldStandardTt(
                                  color: const Color(0xFFE5D5B0),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              activeTask.type == TaskType.rest
                                  ? "UNTIL WAKEFUL"
                                  : "${(activeTask.minutesRemaining ~/ 60)}H ${activeTask.minutesRemaining % 60}M",
                              style: GoogleFonts.oswald(
                                color: const Color(0xFFC4B89B),
                                fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => state.cancelTask(activeTask.id),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.redAccent,
                                  size: 16,
                                ),
                                tooltip: 'CANCEL TASK',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 6),
                    Text(
                      liveRoom.description,
                      style: GoogleFonts.oldStandardTt(
                        fontSize: 12,
                        color: const Color(0xFFE5D5B0).withValues(alpha: 0.8),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Guest Greeting Section
                    if (liveRoom.type == RoomType.entryway) ...[
                      ...() {
                        final entrywayGuests = state.npcs.where((n) => !n.isResident && n.currentRoomId == 'entryway').toList();
                        if (entrywayGuests.isEmpty) return <Widget>[];
                        return [
                          Text(
                            'VISITORS AT THE DOOR',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFC4B89B),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...entrywayGuests.map((guest) {
                            final isGreeted = guest.metadata['isGreeted'] == true;
                            final isMerchant = guest.metadata['guestType'] == 'merchant';
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
                                ),
                                color: Colors.black26,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${guest.name.toUpperCase()} (${guest.role.toUpperCase()})",
                                        style: GoogleFonts.oldStandardTt(
                                          color: const Color(0xFFE5D5B0),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        isGreeted ? "WELCOMED" : "AWAITING RECEPTION",
                                        style: GoogleFonts.oswald(
                                          color: isGreeted ? Colors.green : const Color(0xFFC4B89B),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (!isGreeted)
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () => _showCharacterSelectionForGreeting(context, state, guest),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Color(0xFFC4B89B)),
                                        ),
                                        child: Text(
                                          "SELECT RESIDENT TO RECEIVE",
                                          style: GoogleFonts.playfairDisplay(
                                            color: const Color(0xFFE5D5B0),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    )
                                  else if (isMerchant)
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          showDialog(
                                            context: context,
                                            builder: (context) => VisitingMerchantTradeDialog(merchant: guest),
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.green),
                                        ),
                                        child: Text(
                                          "OPEN TRADE WINDOW",
                                          style: GoogleFonts.playfairDisplay(
                                            color: Colors.green,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 24),
                        ];
                      }(),
                    ],
                    if (liveRoom.type == RoomType.unused && state.activeBusinesses.any((b) => b.type == BusinessType.theater && b.status == 'active')) ...[
                      _buildTheaterCreativeRoomSection(context, state),
                    ],
                    const SizedBox(height: 10),
                    if (displayQueue.isNotEmpty) ...[
                      Text(
                        'ENQUEUED TASKS',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFC4B89B),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...displayQueue.map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 3.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "• ${task.description.toUpperCase()}",
                                  style: GoogleFonts.oldStandardTt(
                                    fontSize: 11,
                                    color: const Color(
                                      0xFFE5D5B0,
                                    ).withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 24.0),
                                child: IconButton(
                                  onPressed: () => state.cancelEnqueuedIntent(
                                    task.npcId,
                                    task.intentId,
                                  ),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.redAccent,
                                    size: 16,
                                  ),
                                  tooltip: 'CANCEL TASK',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // PROGRESSIVE EXCAVATION & RESOURCE BLOCKS UI
                    if (liveRoom.name == 'Excavation Node' && !liveRoom.isRestored) ...[
                      () {
                        final nodeInfo = ManorLayout.grid[liveRoom.id];
                        final depth = nodeInfo?.$2.abs() ?? 1;

                        String requiredTool = "Simple Shovel";
                        String toolType = "simple_shovel";
                        if (depth == 2) { requiredTool = "Iron Pickaxe"; toolType = "iron_pickaxe"; }
                        else if (depth == 3) { requiredTool = "Steel Pickaxe"; toolType = "steel_pickaxe"; }
                        else if (depth == 4) { requiredTool = "Pneumatic Drill"; toolType = "pneumatic_drill"; }

                        String requiredExpertise = "None";
                        int requiredLevel = 0;
                        if (depth == 2) { requiredExpertise = "Adept Mining (Lvl 2)"; requiredLevel = 2; }
                        else if (depth == 3) { requiredExpertise = "Professional Mining (Lvl 5)"; requiredLevel = 5; }
                        else if (depth == 4) { requiredExpertise = "Expert Mining (Lvl 8)"; requiredLevel = 8; }

                        Map<String, int> costMap = {
                          'funds': 2000,
                          'wood': 500,
                          'bricks': 200,
                        };
                        if (depth == 2) {
                          costMap = {'funds': 4000, 'wood': 1000, 'bricks': 500, 'iron_ore': 100};
                        } else if (depth == 3) {
                          costMap = {'funds': 8000, 'wood': 2000, 'bricks': 1000, 'iron_ore': 300};
                        } else if (depth == 4) {
                          costMap = {'funds': 16000, 'wood': 4000, 'bricks': 2000, 'iron_ore': 500};
                        }

                        final isAccessible = state.isRoomAccessibleForExcavation(liveRoom.id);
                        final hasTool = state.hasItemInManor(toolType);
                        final activeMiner = state.npcs.firstWhereOrNull((n) => n.isResident && (n.metadata['proficiency_level_Mining'] as int? ?? 0) >= requiredLevel);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "EXCAVATION REQUIREMENTS (DEPTH LEVEL $depth)",
                                style: GoogleFonts.playfairDisplay(
                                  color: const Color(0xFFE5D5B0),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("REQUIRED TOOL:", style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 11)),
                                  Text(
                                    requiredTool.toUpperCase(),
                                    style: GoogleFonts.oldStandardTt(
                                      color: hasTool ? Colors.green : Colors.redAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("EXPERTISE:", style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 11)),
                                  Text(
                                    requiredExpertise.toUpperCase(),
                                    style: GoogleFonts.oldStandardTt(
                                      color: activeMiner != null ? Colors.green : Colors.redAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("ACCESSIBILITY:", style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 11)),
                                  Text(
                                    isAccessible ? "READY TO EXCAVATE" : "LOCKED / UNREACHABLE",
                                    style: GoogleFonts.oldStandardTt(
                                      color: isAccessible ? Colors.green : Colors.redAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text("RESOURCES COST:", style: GoogleFonts.playfairDisplay(color: const Color(0xFFC4B89B), fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              ...costMap.entries.map((e) {
                                final has = state.resources[e.key] ?? 0;
                                final meet = has >= e.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(e.key.toUpperCase().replaceAll('_', ' '), style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10)),
                                      Text(
                                        "${has.round()} / ${e.value}",
                                        style: GoogleFonts.oswald(
                                          color: meet ? const Color(0xFFC4B89B) : Colors.redAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }(),
                    ],

                    if (liveRoom.metadata['isResourceBlocked'] == true) ...[
                      () {
                        final resType = liveRoom.metadata['resourceType'] as String? ?? 'ore';
                        final amount = liveRoom.metadata['resourceAmount'] as int? ?? 0;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "RESOURCE BLOCKAGE ENCOUNTERED",
                                style: GoogleFonts.playfairDisplay(
                                  color: const Color(0xFFE5D5B0),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "This chamber is blocked by a rich vein of ${resType.toUpperCase()} containing $amount units. To clear the blockage, you must establish a specialized Mine.",
                                style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 11, height: 1.4),
                              ),
                              const SizedBox(height: 16),
                              if (liveRoom.isUnderConstruction)
                                _buildExpandButton(
                                  context,
                                  'CANCEL MINE CONSTRUCTION',
                                  'Halt current construction project.',
                                  Icons.cancel,
                                  () => state.cancelRoomConversion(liveRoom.id),
                                )
                              else
                                _buildExpandButton(
                                  context,
                                  'ESTABLISH ${resType.toUpperCase()} MINE',
                                  'Cost: ${state.getMineConstructionCost(resType, ManorLayout.grid[liveRoom.id]?.$2.abs().toInt() ?? 2)['funds'].toInt()} CHF, ${state.getMineConstructionCost(resType, ManorLayout.grid[liveRoom.id]?.$2.abs().toInt() ?? 2)['wood'].toInt()} Wood. Commences mine construction.',
                                  Icons.construction,
                                  () => state.convertRoomToMine(liveRoom.id),
                                ),
                            ],
                          ),
                        );
                      }(),
                    ],

                    if (liveRoom.id == 'basement_e' && liveRoom.isRestored && liveRoom.type == RoomType.unused && liveRoom.metadata['isResourceBlocked'] != true) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: liveRoom.isUnderConstruction
                            ? _buildExpandButton(
                                context,
                                'CANCEL RIG CONSTRUCTION',
                                'Halt current oil well construction.',
                                Icons.cancel,
                                () => state.cancelRoomConversion(liveRoom.id),
                              )
                            : Column(
                                children: [
                                  _buildExpandButton(
                                    context,
                                    'ESTABLISH OIL WELL',
                                    'Establish a pumping rig to extract crude oil from the manor\'s reserves.\nCost: 1500 CHF, 300 Wood.',
                                    Icons.oil_barrel,
                                    () => state.convertRoomToOilWell(liveRoom.id),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                      ),
                    ],

                    if (liveRoom.type == RoomType.oilWell && liveRoom.isRestored) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "MANOR OIL RESERVES",
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFE5D5B0),
                                fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("TOTAL REMAINING:", style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 11)),
                                Text(
                                  "${state.manorOilReserve.round()} / ${state.manorOilReserveMax.round()} BARRELS",
                                  style: GoogleFonts.oswald(
                                    color: const Color(0xFFC4B89B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("PUMPING EFFICIENCY:", style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 11)),
                                Text(
                                  "${(state.getOilPumpingEfficiency() * 100).round()}%",
                                  style: GoogleFonts.oswald(
                                    color: state.getOilPumpingEfficiency() > 0.5 ? Colors.green : Colors.amber,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildExpandButton(
                              context,
                              'DECOMMISSION OIL WELL',
                              'Safely dismantle the pumping rig and restore the chamber for normal basement use.',
                              Icons.delete_forever,
                              () => state.decommissionOilWell(liveRoom.id),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (liveRoom.type == RoomType.mine && liveRoom.isRestored) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ORE DEPOSIT STATUS",
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFE5D5B0),
                                fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("REMAINING IN VEIN:", style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 11)),
                                Text(
                                  "${liveRoom.metadata['resourceAmount'] ?? 0} / ${liveRoom.metadata['resourceAmountMax'] ?? 0} UNITS",
                                  style: GoogleFonts.oswald(
                                    color: const Color(0xFFC4B89B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // BUILDING & CONVERSION OPTIONS
                    if (liveRoom.type == RoomType.unused &&
                        liveRoom.isRestored) ...[
                      // Spare Bedroom (Ground Floor Unused)
                      if (liveRoom.floor == Floor.ground &&
                          liveRoom.name == 'Unused')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildExpandButton(
                            context,
                            'CONVERT TO SPARE BEDROOM',
                            'Establish a quiet dwelling for residents (12 Hours, 250 Wood, 500 Funds)',
                            Icons.king_bed,
                            () => state.convertUnusedToBedroom(liveRoom.id),
                          ),
                        ),

                      // Greenhouse (Garden Lot)
                      if (liveRoom.id == 'lot_garden')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildExpandButton(
                            context,
                            'BUILD GREENHOUSE',
                            'Construct a glass enclosure for rare botanicals (12 Hours, 100 Wood, 200 Funds)',
                            Icons.eco,
                            () => state.buildGreenhouse(liveRoom.id),
                          ),
                        ),

                      // Tenement (Empty Lot)
                      if (liveRoom.id == 'empty_lot')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildExpandButton(
                            context,
                            'BUILD TENEMENT',
                            'Communal housing for additional labor (12 Hours, 200 Wood, 400 Funds)',
                            Icons.domain,
                            () => state.buildTenement(liveRoom.id),
                          ),
                        ),

                      // Restored Attic or Basement Room Conversion
                      if (liveRoom.floor == Floor.attic ||
                          liveRoom.floor == Floor.basement)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: liveRoom.isUnderConstruction
                              ? _buildExpandButton(
                                  context,
                                  'CANCEL CONVERSION',
                                  'Halt current construction. Recover 100% if uncommenced, or 50% if underway.',
                                  Icons.cancel,
                                  () => state.cancelRoomConversion(liveRoom.id),
                                )
                              : _buildExpandButton(
                                  context,
                                  'CONVERT ROOM',
                                  'Convert this secluded room into a specialized workshop or facility.',
                                  Icons.construction,
                                  () => _showConversionOptionsDialog(context, state, liveRoom),
                                  popOnPress: false,
                                ),
                        ),
                    ],
                    if (liveRoom.isRestored &&
                        (liveRoom.type == RoomType.study ||
                            liveRoom.type == RoomType.laboratory ||
                            liveRoom.type == RoomType.chickenCoop ||
                            liveRoom.type == RoomType.kitchen ||
                            liveRoom.type == RoomType.garden ||
                            (liveRoom.type == RoomType.diningRoom && state.activeBusinesses.any((b) => b.type == BusinessType.bistro && (b.status == 'active' || b.status == 'inProgress'))) ||
                            liveRoom.type == RoomType.library))
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            if (liveRoom.type == RoomType.study) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StudyScreen(),
                                ),
                              );
                            } else if (liveRoom.type == RoomType.kitchen) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const KitchenScreen(),
                                ),
                              );
                            } else if (liveRoom.type == RoomType.diningRoom) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DiningRoomScreen(),
                                ),
                              );
                            } else if (liveRoom.type == RoomType.laboratory) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      LaboratoryScreen(room: liveRoom),
                                ),
                              );
                            } else if (liveRoom.type == RoomType.chickenCoop) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ChickenCoopScreen(),
                                ),
                              );
                            } else if (liveRoom.type == RoomType.library) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      LibraryScreen(room: liveRoom),
                                ),
                              );
                            } else if (liveRoom.type == RoomType.garden) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GardenScreen(),
                                ),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFC4B89B)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            backgroundColor: const Color(
                              0xFFC4B89B,
                            ).withValues(alpha: 0.1),
                          ),
                          icon: const Icon(
                            Icons.login,
                            color: Color(0xFFE5D5B0),
                            size: 16,
                          ),
                          label: Text(
                            'ENTER ${liveRoom.name.toUpperCase()}',
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFE5D5B0),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    if (liveRoom.type == RoomType.study ||
                        liveRoom.type == RoomType.library ||
                        liveRoom.type == RoomType.chickenCoop) ...[
                      const SizedBox(height: 10),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 10),
                      Text(
                        'ROOM LEDGER',
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      RoomLedger(room: liveRoom, state: state, isCompact: true),
                      const SizedBox(height: 12),
                    ],
                    if (liveRoom.type == RoomType.field)
                      _buildFieldStatus(context, state, liveRoom),
                    ...liveRoom.availableTasks
                        .where((taskType) {
                          // Only show available tasks.
                          bool isAvail = _isTaskAvailable(
                            state,
                            liveRoom,
                            taskType,
                          );
                          return isAvail;
                        })
                        .map((taskType) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: _assignmentButton(
                              context,
                              state,
                              taskType,
                              () => _handleTaskInteraction(
                                context,
                                state,
                                liveRoom,
                                taskType,
                              ),
                            ),
                          );
                        }),
                    if (liveRoom.isRestored &&
                        (liveRoom.type == RoomType.bedroom ||
                            liveRoom.type == RoomType.butlerQuarters ||
                            liveRoom.type == RoomType.attic ||
                            liveRoom.type == RoomType.basement))
                      BedAssignmentWidget(room: liveRoom),
                    const SizedBox(height: 10),
                    if (state.npcs.any(
                      (n) => n.currentRoomId == liveRoom.id,
                    )) ...[
                      Text(
                        "OCCUPANTS:",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFC4B89B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: state.npcs
                            .where((n) => n.currentRoomId == liveRoom.id)
                            .map(
                              (npc) => InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        CharacterPortraitDialog(npc: npc),
                                  );
                                },
                                child: Chip(
                                  label: Text(
                                    npc.name.toUpperCase(),
                                    style: GoogleFonts.oldStandardTt(
                                      fontSize: 9,
                                    ),
                                  ),
                                  avatar: Icon(
                                    npc.isPlayer ? Icons.stars : Icons.person,
                                    size: 11,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: Colors.black26,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCharacterSelectionForGreeting(BuildContext context, GameState state, NPC guest) {
    showDialog(
      context: context,
      builder: (context) {
        final residents = state.npcs.where((n) => n.isResident && n.worldDestinationId == null).toList();
        
        return Dialog(
          backgroundColor: const Color(0xFF1E1A15),
          shape: const RoundedRectangleBorder(),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC4B89B), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SELECT RECIPIENT",
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "CHOOSE WHO WILL GREET ${guest.name.toUpperCase()}",
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFC4B89B).withValues(alpha: 0.7),
                    fontSize: 8,
                  ),
                ),
                const Divider(color: Colors.white10, height: 24),
                if (residents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      "NO RESIDENTS ARE CURRENTLY PRESENT.",
                      style: GoogleFonts.oldStandardTt(color: Colors.white24),
                    ),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: residents.map((res) {
                          return ListTile(
                            title: Text(
                              res.name.toUpperCase(),
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFE5D5B0),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            subtitle: Text(
                              res.role.toUpperCase(),
                              style: GoogleFonts.oldStandardTt(
                                color: Colors.white38,
                                fontSize: 8,
                              ),
                            ),
                            onTap: () {
                              state.receiveEntrywayGuest(guest.id, res.id);
                              Navigator.pop(context); // Pop selection dialog
                              Navigator.pop(context); // Pop room details bottom sheet
                            },
                          );
                        }).toList(),
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

  void _showCheatCodesDialog(BuildContext context, GameState state) {
    showDialog(
      context: context,
      builder: (context) => const CheatCodesDialog(),
    );
  }

  Widget _assignmentButton(
    BuildContext context,
    GameState state,
    TaskType type,
    VoidCallback? onPressed, {
    bool isGreyed = false,
  }) {
    final metadata = TaskService.getMetadata(type);
    String label = type.displayName.toUpperCase();
    String durationLabel = metadata.typicalDuration.toUpperCase();

    // Dynamic labels for Cook and Research
    if (type == TaskType.cook && state.cookingQueue.isNotEmpty) {
      final recipeId = state.getFirstUnassignedRecipe();
      if (recipeId != null) {
        if (recipeId.startsWith('experiment|')) {
          label = "COOK EXPERIMENT";
          durationLabel = "120 MINUTES";
        } else if (recipeId.startsWith('butcher_generic:')) {
          final tgtName = recipeId.split(':').last;
          label = "BUTCHER ${tgtName.toUpperCase()}";
          durationLabel = "45 MINUTES";
        } else {
          final recipe = KitchenService.getAvailableRecipes().firstWhereOrNull(
            (r) => r.id == recipeId,
          );
          if (recipe != null) {
            label = "PREPARE ${recipe.name.replaceAll('_', ' ')}".toUpperCase();
            durationLabel = "${recipe.durationMinutes} MINUTES";
          }
        }
      }
    } else if (type == TaskType.research && state.researchQueue.isNotEmpty) {
      final topic = state.getFirstUnassignedResearch();
      if (topic != null) {
        final parts = topic.split(':');
        if (parts[0] == 'recipe' && parts.length >= 2) {
          final recipeId = parts[1];
          final recipe = KitchenService.getAvailableRecipes().firstWhereOrNull((r) => r.id == recipeId);
          label = "STUDY EXPERIMENTAL ${recipe?.name.toUpperCase() ?? recipeId.toUpperCase()}";
        } else if (parts.length >= 3) {
          final activityId = parts[1];
          final itemId = parts[2];
          final item = state.inventory.firstWhereOrNull((i) => i.id == itemId);
          final itemName = item?.name ?? "Alchemical Artifact";
          if (activityId == 'generic_research') {
            label = "RESEARCH ${itemName.toUpperCase()}";
          } else if (activityId == 'small_dissection') {
            label = "DISSECT ${itemName.toUpperCase()}";
          } else {
            label = "STUDY ${itemName.toUpperCase()}";
          }
        } else if (parts.length == 2) {
          final activityId = parts[1];
          label = "RESEARCH ${activityId.toUpperCase().replaceAll('_', ' ')}";
        } else {
          label = "RESEARCH ${topic.toUpperCase().replaceAll('_', ' ')}";
        }
      }
    }

    final icon = _getTaskIcon(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isGreyed
                ? const Color(0xFFC4B89B).withValues(alpha: 0.2)
                : const Color(0xFFE5D5B0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          backgroundColor: isGreyed ? Colors.transparent : Colors.black12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isGreyed
                      ? const Color(0xFFC4B89B).withValues(alpha: 0.2)
                      : const Color(0xFFE5D5B0),
                  size: 15,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: isGreyed
                        ? const Color(0xFFC4B89B).withValues(alpha: 0.2)
                        : const Color(0xFFE5D5B0),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontSize: 11.5,
                  ),
                ),
                const Spacer(),
                if (!isGreyed)
                  Text(
                    durationLabel,
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFC4B89B),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            if (!isGreyed) ...[
              const SizedBox(height: 4),
              Text(
                metadata.explanation,
                style: GoogleFonts.oldStandardTt(
                  color: const Color(0xFFC4B89B).withValues(alpha: 0.7),
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "REQUIRED SKILLS:",
                          style: GoogleFonts.oswald(
                            fontSize: 9,
                            color: const Color(
                              0xFFE5D5B0,
                            ).withValues(alpha: 0.5),
                          ),
                        ),
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
                          "POTENTIAL OUTCOMES:",
                          style: GoogleFonts.oswald(
                            fontSize: 9,
                            color: const Color(
                              0xFFE5D5B0,
                            ).withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          metadata.possibleOutcomes.join(", ").toUpperCase(),
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
            ],
            if (metadata.requirements.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isGreyed
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.white10,
                  border: Border.all(
                    color: isGreyed
                        ? Colors.red.withValues(alpha: 0.3)
                        : Colors.white24,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 10,
                      color: isGreyed
                          ? Colors.redAccent
                          : const Color(0xFFE5D5B0),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "COST: ${metadata.requirements.entries.map((e) => "${e.value.round()} ${e.key.toUpperCase()}").join(", ")}",
                      style: GoogleFonts.oswald(
                        fontSize: 9,
                        letterSpacing: 1,
                        color: isGreyed
                            ? Colors.redAccent
                            : const Color(0xFFE5D5B0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFieldStatus(BuildContext context, GameState state, Room room) {
    // Current crops in this "room" (field)
    final roomCrops = state.crops.where((c) => c.roomId == room.id).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusRow("SOIL TILLING:", room.tilledAmount),
          const SizedBox(height: 4),
          _statusRow("FERTILIZATION:", room.fertilizedAmount),
          if (roomCrops.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6.0),
              child: Divider(color: Colors.white10),
            ),
            Text(
              "ACTIVE CROPS:",
              style: GoogleFonts.oswald(
                fontSize: 9,
                color: const Color(0xFFC4B89B),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            _statusRow("GROWTH PROGRESS:", roomCrops[0].growthProgress),
            const SizedBox(height: 4),
            _statusRow("MOISTURE LEVEL:", roomCrops[0].moistureLevel),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6.0),
              child: Divider(color: Colors.white10),
            ),
            Text(
              "NO CROPS PLANTED",
              style: GoogleFonts.oswald(
                fontSize: 9,
                color: Colors.white24,
                letterSpacing: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusRow(String label, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 9,
                color: Colors.white30,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${(progress * 100).toInt()}%",
              style: GoogleFonts.oswald(
                fontSize: 10,
                color: const Color(0xFFE5D5B0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white12,
          color: const Color(0xFFC4B89B),
          minHeight: 2,
        ),
      ],
    );
  }

  bool _isTaskAvailable(GameState state, Room room, TaskType type) {
    // Hide manual task buttons from the Garden overlay, as they are managed within GardenScreen
    if (room.type == RoomType.garden) return false;

    final metadata = TaskService.getMetadata(type);
    for (var entry in metadata.requirements.entries) {
      if ((state.resources[entry.key] ?? 0) < entry.value) {
        return false;
      }
    }

    // Avoid double-assignment for non-repeatable room tasks if already active or queued
    final isRepeatable =
        type == TaskType.cook ||
        type == TaskType.research ||
        type == TaskType.archiveResearch ||
        type == TaskType.transcribeNotes;

    if (!isRepeatable) {
      final isAlreadyActiveOrQueued = state.activeTasks.any(
        (t) => t.targetId == room.id && t.type == type,
      );
      if (isAlreadyActiveOrQueued) return false;
    }

    switch (type) {
      case TaskType.cleanRoom:
        return room.dirtiness > 0.1;
      case TaskType.cleanDish:
        return (state.resources['dirty_dishes'] ?? 0) > 0;
      case TaskType.butcherAnimals:
        return (state.resources['cattle_carcass'] ?? 0) > 0;
      case TaskType.cook:
        return state.cookingQueue.isNotEmpty;
      case TaskType.research:
        return state.researchQueue.isNotEmpty;
      case TaskType.plantCrops:
        return room.isTilled;
      case TaskType.waterCrops:
      case TaskType.careForCrops:
      case TaskType.harvestCabbage:
      case TaskType.harvestCrops:
        return state.crops.any((c) => c.roomId == room.id);
      case TaskType.collectEggs:
        if (room.inventory
            .where((i) => i.type == 'eggs' || i.type == 'fertilized_egg')
            .isEmpty) {
          return false;
        }
        final kitchenExists = state.rooms.any(
          (r) => r.type == RoomType.kitchen && r.isRestored,
        );
        return kitchenExists;
      case TaskType.greetGuest:
        return false;
      default:
        return true;
    }
  }

  void _handleTaskInteraction(
    BuildContext context,
    GameState state,
    Room room,
    TaskType type,
  ) {
    switch (type) {
      case TaskType.plantCrops:
        _showSeedSelection(context, state, room);
        break;
      case TaskType.dissect:
      case TaskType.vivisection:
      case TaskType.puzzleStudy:
      case TaskType.deprivationStudy:
        _showSpecimenSelection(context, state, room, type);
        break;
      case TaskType.cook:
        final nextRecipe = state.getFirstUnassignedRecipe();
        _showWorkerSelection(context, state, room, type, recipeId: nextRecipe);
        break;
      case TaskType.research:
        final nextTopic = state.getFirstUnassignedResearch();
        _showWorkerSelection(context, state, room, type, recipeId: nextTopic);
        break;
      default:
        _showWorkerSelection(context, state, room, type);
    }
  }

  void _showSeedSelection(BuildContext context, GameState state, Room room) {
    final seedResources = state.resources.entries
        .where((e) => e.key.startsWith('seeds_') && e.value > 0)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1A15),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECT SEEDS TO PLANT',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              if (seedResources.isEmpty)
                const Center(child: Text("NO SEEDS AVAILABLE")),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: seedResources.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: Colors.white10),
                  itemBuilder: (context, index) {
                    final seed = seedResources[index];
                    final cropTypeName = seed.key.replaceFirst('seeds_', '');
                    return ListTile(
                      onTap: () {
                        Navigator.pop(context); // Close seeds
                        _showWorkerSelection(
                          context,
                          state,
                          room,
                          TaskType.plantCrops,
                          recipeId: cropTypeName,
                        );
                      },
                      leading: const Icon(
                        Icons.grass,
                        color: Color(0xFFC4B89B),
                      ),
                      title: Text(
                        cropTypeName.toUpperCase(),
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 14,
                        ),
                      ),
                      trailing: Text(
                        "${seed.value} AVAILABLE",
                        style: GoogleFonts.oswald(
                          fontSize: 12,
                          color: Colors.white38,
                        ),
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
  }

  void _showSpecimenSelection(
    BuildContext context,
    GameState state,
    Room room,
    TaskType type,
  ) {
    final specimens = room.inventory
        .where(
          (i) =>
              i.category == ItemCategory.specimen ||
              i.id.contains('_specimen') ||
              i.type == 'small_creature',
        )
        .toList();

    final activity = ScienceService.getAvailableActivities().firstWhereOrNull(
      (a) => a.type == type,
    );

    final requiredSpecsNode = activity?.ingredients.entries.firstWhereOrNull(
      (e) => e.key.contains('specimen') || e.key == 'rat_specimen',
    );

    final int requiredCount = requiredSpecsNode?.value.round() ?? 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1A15),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        // Track selection statefully
        Map<String, int> selectedCounts = {};

        return StatefulBuilder(
          builder: (context, setState) {
            int totalSelected = selectedCounts.values.fold(0, (a, b) => a + b);
            bool canConfirm = totalSelected >= requiredCount;

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${activity?.name.toUpperCase() ?? "RESEARCH"} SELECTION",
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "REQUIREMENT: $requiredCount SPECIMEN(S)",
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFC4B89B),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (specimens.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          "NO SPECIMENS IN INVENTORY.",
                          style: TextStyle(color: Colors.white24),
                        ),
                      ),
                    ),
                  if (specimens.isNotEmpty)
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: specimens.length,
                        separatorBuilder: (context, index) =>
                            const Divider(color: Colors.white10),
                        itemBuilder: (context, index) {
                          final item = specimens[index];
                          final count = selectedCounts[item.id] ?? 0;
                          final maxAvail = item.quantity;

                          return ListTile(
                            leading: const Icon(
                              Icons.science,
                              color: Color(0xFFC4B89B),
                            ),
                            title: Text(
                              item.name.toUpperCase(),
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFE5D5B0),
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              "$maxAvail AVAILABLE",
                              style: GoogleFonts.oswald(
                                fontSize: 11,
                                color: Colors.white38,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove,
                                    color: Color(0xFFE5D5B0),
                                    size: 16,
                                  ),
                                  onPressed: count > 0
                                      ? () => setState(
                                          () => selectedCounts[item.id] =
                                              count - 1,
                                        )
                                      : null,
                                ),
                                Text(
                                  "$count",
                                  style: GoogleFonts.oswald(
                                    color: const Color(0xFFE5D5B0),
                                    fontSize: 14,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add,
                                    color: Color(0xFFE5D5B0),
                                    size: 16,
                                  ),
                                  onPressed:
                                      count < maxAvail &&
                                          totalSelected < requiredCount
                                      ? () => setState(
                                          () => selectedCounts[item.id] =
                                              count + 1,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: canConfirm
                          ? () {
                              Navigator.pop(context);

                              String selectedText = selectedCounts.entries
                                  .where((e) => e.value > 0)
                                  .map((e) {
                                    final item = specimens.firstWhere(
                                      (i) => i.id == e.key,
                                    );
                                    return "${item.name} (${e.value})";
                                  })
                                  .join(", ");

                              _showWorkerSelection(
                                context,
                                state,
                                room,
                                type,
                                recipeId: activity?.id,
                                targetName: selectedText,
                              );
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: canConfirm
                              ? const Color(0xFFC4B89B)
                              : Colors.white10,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        "CONFIRM SUBJECTS",
                        style: GoogleFonts.playfairDisplay(
                          color: canConfirm
                              ? const Color(0xFFE5D5B0)
                              : Colors.white24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showWorkerSelection(
    BuildContext context,
    GameState state,
    Room room,
    TaskType? type, {
    bool isHousing = false,
    String? recipeId,
    String? targetName,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1A15),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isHousing ? 'ASSIGN QUARTERS' : 'SELECT WORKER',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.npcs.where((n) => n.isResident).length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: Colors.white10),
                  itemBuilder: (context, index) {
                    final npc = state.npcs
                        .where((n) => n.isResident)
                        .toList()[index];
                    final estMinutes = type != null
                        ? state.getEstimatedTaskMinutes(npc, type)
                        : 0;
                    final efficiency = type != null
                        ? state.getTaskEfficiency(npc, type)
                        : 1.0;

                    String warning = "";
                    Color warningColor = Colors.greenAccent;
                    if (isHousing) {
                      warning = npc.assignedRoomId == room.id
                          ? "Current Quarters"
                          : "Available";
                    } else if (efficiency < 1.0) {
                      warning = "Inefficient";
                      warningColor = Colors.redAccent;
                    } else if (efficiency > 1.0) {
                      warning = "Highly Suitable";
                      warningColor = Colors.amberAccent;
                    }

                    return ListTile(
                      onTap: () {
                        if (isHousing) {
                          state.assignHousing(npc.id, room.id);
                        } else if (type != null) {
                          state.tryScheduleNpcTask(
                            npc.id,
                            type,
                            room.id,
                            recipeId: recipeId,
                            targetName: targetName,
                          );
                        }
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      leading: const Icon(
                        Icons.person,
                        color: Color(0xFFC4B89B),
                      ),
                      title: Text(
                        npc.name.toUpperCase(),
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isHousing)
                            Text(
                              "EST. TIME: ${estMinutes ~/ 60}H ${estMinutes % 60}M",
                              style: GoogleFonts.oldStandardTt(
                                color: const Color(
                                  0xFFC4B89B,
                                ).withValues(alpha: 0.6),
                                fontSize: 10,
                              ),
                            ),
                          if (warning.isNotEmpty)
                            Text(
                              warning.toUpperCase(),
                              style: GoogleFonts.oldStandardTt(
                                color: warningColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white24,
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
  }

  Widget _buildExpandButton(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onPressed, {
    bool popOnPress = true,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          onPressed();
          if (popOnPress) {
            Navigator.pop(context);
          }
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFC4B89B)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          backgroundColor: const Color(0xFFC4B89B).withValues(alpha: 0.1),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFE5D5B0), size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFC4B89B).withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _speedIcon(
    BuildContext context,
    GameState state,
    GameSpeed speed,
    IconData icon,
    String label,
  ) {
    final isSelected = state.speed == speed;
    return Tooltip(
      message: label,
      child: IconButton(
        icon: Icon(
          icon,
          color: isSelected ? const Color(0xFFE5D5B0) : Colors.white24,
          size: 20,
        ),
        onPressed: () {
          state.setSpeed(speed);
          setState(() => _timeControlsExpanded = false);
        },
      ),
    );
  }

  Widget _buildClockWidget(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        Widget buildClock(Color bgColor) {
          return InkWell(
            onTap: () {
              setState(() {
                _timeControlsExpanded = !_timeControlsExpanded;
                _isFirstVisit = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: _isFirstVisit
                  ? BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5D5B0)),
                      color: bgColor,
                    )
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    state.currentDate.formattedDate.toUpperCase(),
                    style: GoogleFonts.playfairDisplay(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                      color: const Color(0xFFE5D5B0),
                    ),
                  ),
                  Text(
                    state.currentDate.formattedTime,
                    style: GoogleFonts.oswald(
                      color: const Color(0xFFC4B89B),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (_isFirstVisit) {
          return TweenAnimationBuilder<Color?>(
            tween: ColorTween(
              begin: Colors.black.withValues(alpha: 0.3),
              end: const Color(0xFFC4B89B).withValues(alpha: 0.4),
            ),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
            builder: (context, color, child) {
              return buildClock(color ?? Colors.black.withValues(alpha: 0.3));
            },
            onEnd: () {
              if (_isFirstVisit) setState(() {});
            },
          );
        }

        return buildClock(Colors.black.withValues(alpha: 0.3));
      },
    );
  }

  IconData _getTaskIcon(TaskType type) {
    switch (type) {
      case TaskType.cleanRoom:
        return Icons.cleaning_services;
      case TaskType.cook:
      case TaskType.prepareMeals:
        return Icons.restaurant;
      case TaskType.research:
        return Icons.menu_book;
      case TaskType.dissect:
      case TaskType.vivisection:
      case TaskType.surgicalOperation:
      case TaskType.surgery:
        return Icons.biotech;
      case TaskType.dentalWork:
        return Icons.medical_services;
      case TaskType.collectEggs:
        return Icons.egg;
      case TaskType.guardCoop:
        return Icons.security;
      case TaskType.archiveResearch:
      case TaskType.transcribeNotes:
        return Icons.inventory_2;
      case TaskType.tillSoil:
      case TaskType.plantCrops:
      case TaskType.waterCrops:
      case TaskType.fertilizeSoil:
      case TaskType.careForCrops:
      case TaskType.harvestCrops:
      case TaskType.harvestCabbage:
      case TaskType.harvestGrain:
        return Icons.agriculture;
      case TaskType.restoreRoom:
        return Icons.build_outlined;
      case TaskType.rest:
        return Icons.hotel;
      case TaskType.processTimber:
      case TaskType.blacksmithing:
      case TaskType.manufacturing:
      case TaskType.invention:
        return Icons.handyman;
      case TaskType.brew:
      case TaskType.distill:
        return Icons.local_bar;
      case TaskType.hauling:
        return Icons.unarchive;
      case TaskType.useToilet:
        return Icons.wc;
      case TaskType.greetGuest:
        return Icons.hail;
      case TaskType.defendManor:
        return Icons.shield;
      default:
        return Icons.assignment;
    }
  }

  Widget _buildAbstractedTheaterCard(BuildContext context, GameState state) {
    final theater = state.activeBusinesses.firstWhereOrNull((b) => b.type == BusinessType.theater && b.status == 'active');
    if (theater == null) return const SizedBox.shrink();

    final meta = theater.metadata;
    final double rehearsal = (meta['rehearsalLevel'] as num? ?? 0.0).toDouble();
    final double promotion = (meta['promotedLevel'] as num? ?? 0.0).toDouble();

    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1612).withValues(alpha: 0.95),
        border: Border.all(color: const Color(0xFFC4B89B), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "THEATER PRODUCTION CONTROL",
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFE5D5B0),
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
          const Divider(color: Colors.white10, height: 16),
          Text(
            "REHEARSAL LEVEL: ${(rehearsal * 100).toInt()}%",
            style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 10),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: rehearsal,
            color: const Color(0xFFC4B89B),
            backgroundColor: Colors.white10,
          ),
          const SizedBox(height: 12),
          Text(
            "PROMOTION LEVEL: ${(promotion * 100).toInt()}%",
            style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 10),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: promotion,
            color: const Color(0xFFC4B89B),
            backgroundColor: Colors.white10,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    state.rehearseTheaterShow(theater.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Cast members called to rehearsal stage.")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF241F1A),
                    foregroundColor: const Color(0xFFE5D5B0),
                    side: const BorderSide(color: Color(0xFFC4B89B)),
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text("REHEARSE", style: GoogleFonts.oswald(fontSize: 9, letterSpacing: 0.5)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    state.promoteTheaterShow(theater.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Promoted the play in local hamlet.")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF241F1A),
                    foregroundColor: const Color(0xFFE5D5B0),
                    side: const BorderSide(color: Color(0xFFC4B89B)),
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text("PROMOTE", style: GoogleFonts.oswald(fontSize: 9, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                state.launchTheaterShowProduction(theater.id);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E1A15),
                    title: Text(
                      "SHOW LAUNCHED!",
                      style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0)),
                    ),
                    content: Text(
                      "The curtains rise! Speeches delivered, music scored, ticket sales completed. Profit logged on Records balance sheet.",
                      style: GoogleFonts.oldStandardTt(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("EXCELLENT", style: GoogleFonts.oldStandardTt(color: const Color(0xFFE5D5B0))),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC4B89B),
                foregroundColor: Colors.black,
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text("LAUNCH PRODUCTION", style: GoogleFonts.oswald(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTheaterCreativeRoomSection(BuildContext context, GameState state) {
    final theater = state.activeBusinesses.firstWhereOrNull((b) => b.type == BusinessType.theater && b.status == 'active');
    if (theater == null) return const SizedBox.shrink();

    final meta = theater.metadata;
    final String scenery = meta['sceneryChoice'] ?? 'minimalist';
    final String costume = meta['costumeChoice'] ?? 'period';
    final String direction = meta['directionStyle'] ?? 'naturalistic';
    final String score = meta['musicalScore'] ?? 'classical';

    final TextEditingController feedbackController = TextEditingController(text: meta['directorFeedback'] ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white24, height: 32),
        Text(
          "THEATER CREATIVE DESIGN",
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFE5D5B0),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "CONFIGURE THE CREATIVE DECISIONS FOR YOUR ACTIVE PLAYS AND THEATRICAL PRODUCTIONS:",
          style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 9),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("SCENERY DESIGN STYLE:", style: GoogleFonts.oldStandardTt(color: const Color(0xFFC4B89B), fontSize: 12)),
            DropdownButton<String>(
              value: scenery,
              dropdownColor: const Color(0xFF1E1A15),
              style: GoogleFonts.oldStandardTt(color: const Color(0xFFE5D5B0)),
              onChanged: (val) {
                if (val != null) {
                  state.updateTheaterCreativeChoices(theater.id, scenery: val);
                }
              },
              items: const [
                DropdownMenuItem(value: 'minimalist', child: Text("MINIMALIST")),
                DropdownMenuItem(value: 'classical', child: Text("CLASSICAL")),
                DropdownMenuItem(value: 'baroque', child: Text("BAROQUE (+20% TICKET BONUS)")),
                DropdownMenuItem(value: 'avant-garde', child: Text("AVANT-GARDE (-10% APPEAL)")),
              ],
            ),
          ],
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("COSTUME DESIGN:", style: GoogleFonts.oldStandardTt(color: const Color(0xFFC4B89B), fontSize: 12)),
            DropdownButton<String>(
              value: costume,
              dropdownColor: const Color(0xFF1E1A15),
              style: GoogleFonts.oldStandardTt(color: const Color(0xFFE5D5B0)),
              onChanged: (val) {
                if (val != null) {
                  state.updateTheaterCreativeChoices(theater.id, costume: val);
                }
              },
              items: const [
                DropdownMenuItem(value: 'period', child: Text("PERIOD STYLE")),
                DropdownMenuItem(value: 'elaborate', child: Text("ELABORATE GOWNS (+15% BONUS)")),
                DropdownMenuItem(value: 'modern', child: Text("MODERN APPAREL")),
                DropdownMenuItem(value: 'gothic', child: Text("GOTHIC PARCHMENT (+5% BONUS)")),
              ],
            ),
          ],
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("ACTING DIRECTION:", style: GoogleFonts.oldStandardTt(color: const Color(0xFFC4B89B), fontSize: 12)),
            DropdownButton<String>(
              value: direction,
              dropdownColor: const Color(0xFF1E1A15),
              style: GoogleFonts.oldStandardTt(color: const Color(0xFFE5D5B0)),
              onChanged: (val) {
                if (val != null) {
                  state.updateTheaterCreativeChoices(theater.id, direction: val);
                }
              },
              items: const [
                DropdownMenuItem(value: 'naturalistic', child: Text("NATURALISTIC STANCE")),
                DropdownMenuItem(value: 'expressionist', child: Text("EXPRESSIONIST SHADOWS")),
                DropdownMenuItem(value: 'melodramatic', child: Text("MELODRAMATIC SIGHS")),
                DropdownMenuItem(value: 'operatic', child: Text("OPERATIC VIBRATO")),
              ],
            ),
          ],
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("MUSICAL SCORING STYLE:", style: GoogleFonts.oldStandardTt(color: const Color(0xFFC4B89B), fontSize: 12)),
            DropdownButton<String>(
              value: score,
              dropdownColor: const Color(0xFF1E1A15),
              style: GoogleFonts.oldStandardTt(color: const Color(0xFFE5D5B0)),
              onChanged: (val) {
                if (val != null) {
                  state.updateTheaterCreativeChoices(theater.id, score: val);
                }
              },
              items: const [
                DropdownMenuItem(value: 'classical', child: Text("CLASSICAL SYMPHONY")),
                DropdownMenuItem(value: 'haunting', child: Text("HAUNTING STRING HARMONIES (+10%)")),
                DropdownMenuItem(value: 'orchestral', child: Text("FULL ORCHESTRAL COMPOSITION (+5%)")),
                DropdownMenuItem(value: 'silent piano', child: Text("SILENT PIANO ACCOMPANIMENT")),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),
        Text("DIRECTOR'S FEEDBACK & CRITIQUE:", style: GoogleFonts.oldStandardTt(color: const Color(0xFFC4B89B), fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: feedbackController,
                style: GoogleFonts.oldStandardTt(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  hintText: "Enter instructions (e.g., Speak louder, project emotion!)...",
                  hintStyle: TextStyle(color: Colors.white10),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC4B89B))),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                state.updateTheaterCreativeChoices(theater.id, feedback: feedbackController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Critique submitted to the cast: '${feedbackController.text}'")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC4B89B),
                foregroundColor: Colors.black,
                shape: const RoundedRectangleBorder(),
              ),
              child: Text("CRITIQUE", style: GoogleFonts.playfairDisplay(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  void _showConversionOptionsDialog(BuildContext context, GameState state, Room room) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1A15),
          shape: const RoundedRectangleBorder(),
          title: Text(
            "SELECT CONVERSION TYPE",
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFE5D5B0),
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
          content: SizedBox(
            width: 360,
            child: ListView(
              shrinkWrap: true,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                      state.convertRoomToLaboratory(room.id);
                    },
                    leading: const Icon(Icons.biotech, color: Color(0xFFC4B89B)),
                    title: Text(
                      "ALCHEMICAL LABORATORY",
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFFE5D5B0),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Outfit this secluded room for experimentation.\nCost: 1000 CHF, 50 Wood.",
                      style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "ABANDON",
                style: GoogleFonts.playfairDisplay(color: Colors.white24, fontSize: 11),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnnouncementBanner extends StatefulWidget {
  final List<String> history;
  const _AnnouncementBanner({required this.history});

  @override
  State<_AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<_AnnouncementBanner> {
  late final ScrollController _scrollController;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _AnnouncementBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.history.length != oldWidget.history.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _resetRecenterTimer() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF241F1A),
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
        ),
      ),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification && notification.dragDetails != null) {
            _resetRecenterTimer();
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          itemCount: widget.history.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            final log = widget.history[index];
            
            String dateStr = "";
            String timeStr = "";
            String contentStr = log;

            final matchFull = RegExp(r'^\[([A-Za-z]{3})\s(\d{1,2})\s(\d{2}:\d{2})\]\s*(.*)$').firstMatch(log);
            if (matchFull != null) {
              final m = matchFull.group(1)!.toUpperCase();
              final d = matchFull.group(2)!.padLeft(2, '0');
              dateStr = "$m $d";
              timeStr = matchFull.group(3)!;
              contentStr = matchFull.group(4)!;
            } else {
              final matchTimeOnly = RegExp(r'^\[(\d{2}:\d{2})\]\s*(.*)$').firstMatch(log);
              if (matchTimeOnly != null) {
                timeStr = matchTimeOnly.group(1)!;
                contentStr = matchTimeOnly.group(2)!;
                dateStr = "LOG";
              } else {
                contentStr = log;
                dateStr = "LOG";
              }
            }

            final leftTag = timeStr.isNotEmpty ? "$dateStr $timeStr" : dateStr;
            final displayText = contentStr;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: [
                  Container(
                    width: 85,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      leftTag,
                      style: GoogleFonts.oswald(
                        color: const Color(0xFFC4B89B),
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayText.toUpperCase(),
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFFE5D5B0),
                        fontSize: 11.0,
                        letterSpacing: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

