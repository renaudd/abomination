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
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../../services/combat_manager.dart';
import '../../models/npc.dart';
import '../../models/game_item.dart';
import '../../services/combat_unit_factory.dart';
import '../../services/survival_service.dart';
import '../../state/game_state.dart';
import '../../models/combat_map.dart';
import '../widgets/character_blob_renderer.dart';
import '../../models/combat_stats.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../services/save_service.dart';
import '../widgets/options_dialog.dart';

class CombatScreen extends StatefulWidget {
  final List<NPC>? customPlayerDeck;
  final List<NPC>? customAiDeck;
  final NPC? customEnemyHero;
  final NPC? customPlayerHero;
  final Map<String, int>? cardUpgrades;
  final VoidCallback? onVictory;
  final VoidCallback? onDefeat;
  final VoidCallback? onDraw;
  final void Function(
    int destroyedTowersCount,
    List<NPC> enemyDeck,
    int spoilsFood,
    int spoilsCash,
    int spoilsIron,
    int spoilsWood,
    Map<String, double> playerTowerHealth,
    BuildContext context,
  )? onSurvivalVictory;
  final void Function(int destroyedTowersCount, List<NPC> enemyDeck, Map<String, double> playerTowerHealth, BuildContext context)? onSurvivalDefeat;
  final void Function(int destroyedTowersCount, List<NPC> enemyDeck, Map<String, double> playerTowerHealth, BuildContext context)? onSurvivalDraw;
  final int? survivalTurn;

  const CombatScreen({
    super.key,
    this.customPlayerDeck,
    this.customAiDeck,
    this.customEnemyHero,
    this.customPlayerHero,
    this.cardUpgrades,
    this.onVictory,
    this.onDefeat,
    this.onDraw,
    this.onSurvivalVictory,
    this.onSurvivalDefeat,
    this.onSurvivalDraw,
    this.survivalTurn,
  });

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _tickController;
  late CombatManager _combatManager;
  late final GameState _gameState;
  GameSpeed? _previousSpeed;
  int? _selectedCardIndex;
  DateTime? _lastTickTime;
  Size? _screenSize;

  bool _survivalSpoilsCalculated = false;
  int _spoilsFood = 0;
  int _spoilsCash = 0;
  int _spoilsIron = 0;
  int _spoilsWood = 0;

  // Real-Time Drag & Placement Preview State
  NPC? _previewNpc;
  Offset? _previewLocalPosition;

  void updateDragPreview(NPC npc, Offset globalPosition) {
    if (globalPosition == Offset.zero) {
      setState(() {
        _previewNpc = npc;
        _previewLocalPosition = null;
      });
      return;
    }
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPos = renderBox.globalToLocal(globalPosition);
      setState(() {
        _previewNpc = npc;
        _previewLocalPosition = localPos;
      });
    }
  }

  void clearDragPreview() {
    setState(() {
      _previewNpc = null;
      _previewLocalPosition = null;
    });
  }

  void _calculateSurvivalSpoils() {
    if (_survivalSpoilsCalculated) return;

    final rand = Random();
    final currentTurn = widget.survivalTurn ?? 1;

    int wildAnimals = 0;
    int humans = 0;
    int vehicles = 0;

    final opponentDeck = widget.customAiDeck ?? [];
    for (var npc in opponentDeck) {
      if (SurvivalService.isWildAnimal(npc)) {
        wildAnimals++;
      } else if (npc.combatStats?.unitType == UnitType.vehicle || npc.specimenType == 'Machine') {
        vehicles++;
      } else {
        humans++;
      }
    }

    final enemyTowers = _combatManager.combatants.where((c) => c.isTower && c.side == CombatSide.enemy);
    final destroyedEnemyTowers = enemyTowers.where((t) => t.isDead).length;

    // Calculate Dynamic Spoils based on Opponent Deck and Destroyed Towers!
    // 1) Food: 2-3 per animal card + 10 baseline
    _spoilsFood = 10 + wildAnimals * (2 + rand.nextInt(2));
    // 2) Cash: 10-15 chf per human card + 100 + turn * 20 baseline
    _spoilsCash = 100 + currentTurn * 20 + humans * (10 + rand.nextInt(6));
    // 3) Iron: 4-6 per vehicle card
    _spoilsIron = vehicles * (4 + rand.nextInt(3));
    // 4) Wood: 10 wood per enemy tower level destroyed (tower level = currentTurn) + 30 baseline
    _spoilsWood = 30 + destroyedEnemyTowers * 10 * currentTurn;

    _survivalSpoilsCalculated = true;
  }

  Map<String, double> _getPlayerTowerHealthMap() {
    final Map<String, double> healths = {};
    for (int i = 1; i <= 3; i++) {
      final towerId = 'tower_$i';
      final npcId = 'player_tower_${i == 2 ? 2 : (i == 3 ? 1 : 0)}';
      final c = _combatManager.combatants.firstWhereOrNull((c) => c.npc.id == npcId);
      if (c == null || c.isDead) {
        healths[towerId] = 0.0;
      } else {
        healths[towerId] = 1.0;
      }
    }
    return healths;
  }

  // Custom Top-Right Notifications State
  final List<_CombatNotification> _activeNotifications = [];

  void _showNotification(String message, Color bgColor, {Duration duration = const Duration(seconds: 2)}) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final notif = _CombatNotification(
      id: id,
      message: message,
      backgroundColor: bgColor,
      duration: duration,
    );
    setState(() {
      _activeNotifications.add(notif);
    });
    Future.delayed(duration, () {
      if (mounted) {
        setState(() {
          _activeNotifications.removeWhere((n) => n.id == id);
        });
      }
    });
  }
  
  // Keyboard Navigation State
  late final FocusNode _keyboardFocusNode;
  final Set<PhysicalKeyboardKey> _pressedKeys = {};
  double _dragStartZoom = 1.0;
  Offset? _touchpadPanStartOffset;

  void _updateKeyboardMovement() {
    double dx = 0.0;
    double dy = 0.0;

    if (_pressedKeys.contains(PhysicalKeyboardKey.keyW) ||
        _pressedKeys.contains(PhysicalKeyboardKey.arrowUp)) {
      dy -= 1.0;
    }
    if (_pressedKeys.contains(PhysicalKeyboardKey.keyS) ||
        _pressedKeys.contains(PhysicalKeyboardKey.arrowDown)) {
      dy += 1.0;
    }
    if (_pressedKeys.contains(PhysicalKeyboardKey.keyA) ||
        _pressedKeys.contains(PhysicalKeyboardKey.arrowLeft)) {
      dx -= 1.0;
    }
    if (_pressedKeys.contains(PhysicalKeyboardKey.keyD) ||
        _pressedKeys.contains(PhysicalKeyboardKey.arrowRight)) {
      dx += 1.0;
    }

    final len = sqrt(dx * dx + dy * dy);
    final moveDirX = len > 0.0 ? dx / len : 0.0;
    final moveDirY = len > 0.0 ? dy / len : 0.0;

    final alphonse = _combatManager.combatants.firstWhereOrNull(
      (c) => c.npc.isPlayer && !c.isDead,
    );
    if (alphonse != null) {
      alphonse.moveDirX = moveDirX;
      alphonse.moveDirY = moveDirY;
      if (moveDirX != 0 || moveDirY != 0) {
        alphonse.waypointX = null;
        alphonse.waypointY = null;
        alphonse.detourX = null;
        alphonse.detourY = null;
      }
    }
  }

  void _showCardSelectedMessage(int index) {
    final name = _combatManager.hand[index].name;
    _showNotification(
      'CARD SELECT: ${name.toUpperCase()} (SLOT ${index + 1}) - CLICK ON BATTLEFIELD TO DEPLOY',
      Colors.blue.shade900,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void initState() {
    super.initState();
    
    _gameState = Provider.of<GameState>(context, listen: false);
    final state = _gameState;
    _previousSpeed = _gameState.speed;
    _gameState.setSpeedSilent(GameSpeed.paused); // Pause background Manor updates synchronously and silently to prevent thread/state concurrency issues!
    
    _combatManager = CombatManager()
      ..map = state.selectedCombatMap
      ..combatControlMode = state.combatControlMode
      ..upgrades = widget.cardUpgrades ?? {};

    _keyboardFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });

    final isCustomCombat = widget.customPlayerDeck != null;
    final isSimulation = state.simulationPlayerDeck != null || isCustomCombat;

    if (isCustomCombat) {
      _combatManager.setupSimulation(
        widget.customPlayerDeck!,
        widget.customAiDeck ?? [],
      );
    } else if (isSimulation) {
      _combatManager.setupSimulation(
        state.simulationPlayerDeck!,
        state.simulationAiDeck!,
      );
    } else {
      final player = state.npcs.firstWhere((n) => n.isPlayer);
      final travelingCompanions = state.npcs.where((n) => 
        !n.isPlayer && 
        n.worldDestinationId == player.worldDestinationId &&
        n.worldDepartureId == player.worldDepartureId &&
        n.worldTravelProgress < 1.0
      ).toList();

      _combatManager.prepareDeck(travelingCompanions);
    }

    // Dynamic context-driven tower setup
    final encounterTitle = state.pendingEncounterData?.title ?? "Road Skirmish";
    _combatManager.setupTowersForEncounter(encounterTitle);

    // Register callbacks to bridge Combat events with global GameState
    _combatManager.onPlayerDeath = () {
      final gameState = Provider.of<GameState>(context, listen: false);
      // Companion mood loss (15)
      for (var npc in gameState.npcs) {
        if (!npc.isPlayer) {
          final updated = npc.copyWith(
            satisfaction: max(0.0, npc.satisfaction - 15.0),
            currentThought: "Alphonse fell! Can we survive this?",
          );
          gameState.updateNpc(updated);
        }
      }
      // Damage random companion equipment in their inventory
      final residents = gameState.npcs.where((n) => n.isResident).toList();
      if (residents.isNotEmpty) {
        final targetResident = residents[Random().nextInt(residents.length)];
        if (targetResident.inventory.isNotEmpty) {
          final updatedInventory = List<GameItem>.from(targetResident.inventory);
          final item = updatedInventory.first;
          final newMetadata = Map<String, dynamic>.from(item.metadata);
          newMetadata['durability'] = max(0, (newMetadata['durability'] ?? 100) - 25);
          updatedInventory[0] = item.copyWith(metadata: newMetadata);
          final updatedNpc = targetResident.copyWith(
            inventory: updatedInventory,
            currentThought: "Ouch! My ${item.name} took damage in the commotion.",
          );
          gameState.updateNpc(updatedNpc);
        }
      }
      gameState.triggerUpdate();
    };

    _combatManager.onEnemyKill = (enemy) {
      final gameState = Provider.of<GameState>(context, listen: false);
      // Minor squad mood boost (+5)
      for (var npc in gameState.npcs) {
        if (!npc.isPlayer) {
          final updated = npc.copyWith(
            satisfaction: min(100.0, npc.satisfaction + 5.0),
          );
          gameState.updateNpc(updated);
        }
      }
      gameState.triggerUpdate();
    };

    _combatManager.onEnemyHeroDeath = (hero) {
      final gameState = Provider.of<GameState>(context, listen: false);
      // Squad mood boost (+20) and vitality boost
      for (var npc in gameState.npcs) {
        if (!npc.isPlayer) {
          final updated = npc.copyWith(
            satisfaction: min(100.0, npc.satisfaction + 20.0),
            currentThought: "Their leader has fallen! Victory is close!",
          );
          gameState.updateNpc(updated);
        } else {
          // Alphonse gets vitality boost
          final stats = npc.combatStats!;
          final updated = npc.copyWith(
            combatStats: stats.copyWith(
              health: min(stats.maxHealth, stats.health + stats.maxHealth * 0.2),
            ),
          );
          gameState.updateNpc(updated);
        }
      }
      gameState.triggerUpdate();
    };

    // Spawn Mobile Player Hero
    _combatManager.spawnUnit(
      widget.customPlayerHero ?? CombatUnitFactory.createAlphonse(),
      CombatSide.player,
      x: 30.0,
      y: _combatManager.map.height / 2,
    );

    // Spawn Mobile AI Leader
    final enemyHero = widget.customEnemyHero ?? CombatUnitFactory.createAlphonse().copyWith(
      id: 'ai_mirror',
      name: 'Bandit Captain',
      isPlayer: false,
    );
    _combatManager.spawnUnit(
      enemyHero.copyWith(isPlayer: false),
      CombatSide.enemy,
      x: _combatManager.map.width - 30.0,
      y: _combatManager.map.height / 2,
      isAiLeader: true,
    );

    if (!isSimulation) {
      if (state.pendingEncounterEnemies != null && state.pendingEncounterEnemies!.isNotEmpty) {
        // Initialize AI deck/hand with all pending enemies
        _combatManager.setupAIDeck(state.pendingEncounterEnemies!);

        // Spawn the first 2 units instantly so battle starts with immediate threats in top and bottom lanes
        final spawnYs = [_combatManager.map.laneCenters.first, _combatManager.map.laneCenters.last];
        final initialSpawns = state.pendingEncounterEnemies!.take(2).toList();
        int idx = 0;
        for (var enemy in initialSpawns) {
          _combatManager.spawnUnit(
            enemy,
            CombatSide.enemy,
            x: _combatManager.map.width - 50.0,
            y: spawnYs[idx % 2],
          );
          idx++;
        }
      } else {
        // Fallback variety deck
        final fallbackDeck = [
          CombatUnitFactory.createGoon(),
          CombatUnitFactory.createGoon(),
          CombatUnitFactory.createMilitia(),
          CombatUnitFactory.createMilitia(),
        ];
        _combatManager.setupAIDeck(fallbackDeck);
        _combatManager.spawnUnit(
          fallbackDeck[0],
          CombatSide.enemy,
          x: _combatManager.map.width - 50.0,
          y: _combatManager.map.laneCenters.first,
        );
      }
    }

    _combatManager.startCombat();

    _tickController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(() {
            final now = DateTime.now();
            double dt = 0.016;
            if (_lastTickTime != null) {
              dt = now.difference(_lastTickTime!).inMicroseconds / 1000000.0;
            }
            _lastTickTime = now;
            _combatManager.update(dt.clamp(0.0, 0.1));

            // Check if player hero enters on-camera area to resume follow
            final gameState = Provider.of<GameState>(context, listen: false);
            if (gameState.combatControlMode == 'click' && 
                !_combatManager.cameraFollowPlayer && 
                _combatManager.cameraResumeFollowDelay <= 0.0 &&
                _screenSize != null) {
              final alphonse = _combatManager.combatants.firstWhereOrNull((c) => c.npc.isPlayer && !c.isDead);
              if (alphonse != null) {
                final screenSize = _screenSize!;
                final projection = _CombatProjection(
                  viewSize: screenSize,
                  fieldScroll: _combatManager.fieldScroll,
                  yFieldScroll: _combatManager.yFieldScroll,
                  zoomFactor: _combatManager.zoomFactor,
                );
                final posOnScreen = projection.project(alphonse.x, alphonse.y);
                final bool isInside = posOnScreen.dx >= 0 &&
                                     posOnScreen.dx <= screenSize.width &&
                                     posOnScreen.dy >= 0 &&
                                     posOnScreen.dy <= (screenSize.height - 120.0);
                if (isInside) {
                  _combatManager.cameraFollowPlayer = true;
                }
              }
            }

            if (mounted) setState(() {});
          });
    _tickController.repeat();
  }

  @override
  void dispose() {
    if (_previousSpeed != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _gameState.setSpeed(_previousSpeed!);
      });
    }
    _keyboardFocusNode.dispose();
    _tickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    _screenSize = MediaQuery.of(context).size;
    final screenSizeVal = _screenSize!;
    if (_combatManager.combatControlMode != gameState.combatControlMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _combatManager.combatControlMode = gameState.combatControlMode;
      });
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final defaultWidth = screenWidth * 0.4;
    final handLeft = screenWidth - 566;
    final maxWidth = handLeft - 16;
    final navPadWidth = maxWidth > 0 ? (defaultWidth < maxWidth ? defaultWidth : maxWidth) : 0.0;

    return ChangeNotifierProvider.value(
      value: _combatManager,
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: (event) {
          // Skip hotkeys if typing in a text field
          final primaryFocus = FocusManager.instance.primaryFocus;
          if (primaryFocus != null && primaryFocus.context != null) {
            final hasTextFocus = primaryFocus.context!.findAncestorWidgetOfExactType<EditableText>() != null;
            if (hasTextFocus) return;
          }

          final key = event.physicalKey;
          if (event is KeyDownEvent) {
            _pressedKeys.add(key);
            if (key == PhysicalKeyboardKey.keyR) {
              _combatManager.executeSpecial('alphonse');
            } else if (key == PhysicalKeyboardKey.keyF) {
              _combatManager.executeSpecial2('alphonse');
            } else if (_combatManager.isCombatActive && !_combatManager.isVictory && !_combatManager.isDefeat && !_combatManager.isDraw) {
              // Hotkeys to select cards 1-5 from hand
              if (key == PhysicalKeyboardKey.digit1 || key == PhysicalKeyboardKey.numpad1) {
                if (_combatManager.hand.isNotEmpty) {
                  if (_selectedCardIndex == 0) {
                    setState(() {
                      _selectedCardIndex = null;
                      _previewNpc = null;
                      _previewLocalPosition = null;
                    });
                    _showNotification('SELECTION CANCELLED', Colors.blueGrey.shade800);
                  } else {
                    _selectedCardIndex = 0;
                    _showCardSelectedMessage(0);
                  }
                }
              } else if (key == PhysicalKeyboardKey.digit2 || key == PhysicalKeyboardKey.numpad2) {
                if (_combatManager.hand.length > 1) {
                  if (_selectedCardIndex == 1) {
                    setState(() {
                      _selectedCardIndex = null;
                      _previewNpc = null;
                      _previewLocalPosition = null;
                    });
                    _showNotification('SELECTION CANCELLED', Colors.blueGrey.shade800);
                  } else {
                    _selectedCardIndex = 1;
                    _showCardSelectedMessage(1);
                  }
                }
              } else if (key == PhysicalKeyboardKey.digit3 || key == PhysicalKeyboardKey.numpad3) {
                if (_combatManager.hand.length > 2) {
                  if (_selectedCardIndex == 2) {
                    setState(() {
                      _selectedCardIndex = null;
                      _previewNpc = null;
                      _previewLocalPosition = null;
                    });
                    _showNotification('SELECTION CANCELLED', Colors.blueGrey.shade800);
                  } else {
                    _selectedCardIndex = 2;
                    _showCardSelectedMessage(2);
                  }
                }
              } else if (key == PhysicalKeyboardKey.digit4 || key == PhysicalKeyboardKey.numpad4) {
                if (_combatManager.hand.length > 3) {
                  if (_selectedCardIndex == 3) {
                    setState(() {
                      _selectedCardIndex = null;
                      _previewNpc = null;
                      _previewLocalPosition = null;
                    });
                    _showNotification('SELECTION CANCELLED', Colors.blueGrey.shade800);
                  } else {
                    _selectedCardIndex = 3;
                    _showCardSelectedMessage(3);
                  }
                }
              } else if (key == PhysicalKeyboardKey.digit5 || key == PhysicalKeyboardKey.numpad5) {
                if (_combatManager.hand.length > 4) {
                  if (_selectedCardIndex == 4) {
                    setState(() {
                      _selectedCardIndex = null;
                      _previewNpc = null;
                      _previewLocalPosition = null;
                    });
                    _showNotification('SELECTION CANCELLED', Colors.blueGrey.shade800);
                  } else {
                    _selectedCardIndex = 4;
                    _showCardSelectedMessage(4);
                  }
                }
              } else if (key == PhysicalKeyboardKey.escape) {
                setState(() {
                  _selectedCardIndex = null;
                  _previewNpc = null;
                  _previewLocalPosition = null;
                });
                _showNotification('SELECTION CANCELLED', Colors.blueGrey.shade800);
              }
            } else {
              // Game Over Hotkeys
              if (key == PhysicalKeyboardKey.digit1 || key == PhysicalKeyboardKey.numpad1) {
                if (_combatManager.isVictory) {
                  final state = Provider.of<GameState>(context, listen: false);
                  state.addResources(_combatManager.accumulatedLoot);
                  state.clearEncounterState();
                  Navigator.pop(context);
                } else if (_combatManager.isDefeat || _combatManager.isDraw) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const CombatScreen()),
                  );
                }
              } else if (key == PhysicalKeyboardKey.digit2 || key == PhysicalKeyboardKey.numpad2) {
                if (_combatManager.isDefeat) {
                  final state = Provider.of<GameState>(context, listen: false);
                  state.clearEncounterState();
                  Navigator.pop(context);
                } else if (_combatManager.isDraw) {
                  final state = Provider.of<GameState>(context, listen: false);
                  state.clearEncounterState();
                  Navigator.pop(context);
                }
              } else if (key == PhysicalKeyboardKey.digit3 || key == PhysicalKeyboardKey.numpad3) {
                if (_combatManager.isDefeat) {
                  final state = Provider.of<GameState>(context, listen: false);
                  state.clearEncounterState();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
            }
          } else if (event is KeyUpEvent) {
            _pressedKeys.remove(key);
          }
          _updateKeyboardMovement();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: MouseRegion(
                  onHover: (event) {
                    if (_selectedCardIndex != null && _selectedCardIndex! < _combatManager.hand.length) {
                      setState(() {
                        _previewNpc = _combatManager.hand[_selectedCardIndex!];
                        _previewLocalPosition = event.localPosition;
                      });
                    } else if (_previewNpc != null && _selectedCardIndex == null) {
                      setState(() {
                        _previewNpc = null;
                        _previewLocalPosition = null;
                      });
                    }
                  },
                  child: GestureDetector(
                    onSecondaryTapUp: (details) {
                      if (_selectedCardIndex != null) {
                        setState(() {
                          _selectedCardIndex = null;
                          _previewNpc = null;
                          _previewLocalPosition = null;
                        });
                        _showNotification('SELECTION CANCELLED', Colors.blueGrey.shade800);
                      }
                    },
                    onScaleStart: (details) {
                      _keyboardFocusNode.requestFocus();
                      _dragStartZoom = _combatManager.zoomFactor;
                    },
                    onScaleUpdate: (details) {
                      if (details.scale != 1.0) {
                        _combatManager.zoomFactor = _dragStartZoom * details.scale;
                      }
                      final gameState = Provider.of<GameState>(context, listen: false);
                      if (gameState.combatControlMode != 'click') {
                        final screenSize = screenSizeVal;
                        final dx = -details.focalPointDelta.dx * (100.0 / screenSize.width) / _combatManager.zoomFactor;
                        final dy = -details.focalPointDelta.dy * (75.0 / screenSize.height) / _combatManager.zoomFactor;
                        _combatManager.scrollField(dx, dy);
                      }
                    },
                     onTapUp: (details) {
                      _keyboardFocusNode.requestFocus();
                      final gameState = Provider.of<GameState>(context, listen: false);
                      final localPosition = details.localPosition;
                      final screenSize = screenSizeVal;
                      final projection = _CombatProjection(
                        viewSize: screenSize,
                        fieldScroll: _combatManager.fieldScroll,
                        yFieldScroll: _combatManager.yFieldScroll,
                        zoomFactor: _combatManager.zoomFactor,
                      );
                      final targetWorldOffset = projection.unproject(localPosition);

                      // 1. Attempt to spawn a card selected via hotkey
                      if (_selectedCardIndex != null && _selectedCardIndex! < _combatManager.hand.length) {
                        final double clampedY = targetWorldOffset.dy.clamp(0.0, _combatManager.map.height);
                        final npc = _combatManager.hand[_selectedCardIndex!];
                        final success = _combatManager.spawnUnit(
                          npc,
                          CombatSide.player,
                          x: targetWorldOffset.dx,
                          y: clampedY,
                        );
                        
                        if (success) {
                          _showNotification('${npc.name} deployed!', Colors.blue.shade800, duration: const Duration(seconds: 1));
                          _selectedCardIndex = null; // Clear selection
                          _previewNpc = null; // Clear preview
                          _previewLocalPosition = null;
                        } else {
                          _showNotification(
                            'Deployment failed! Must be in home zone (20%) or behind an allied unit on a lane.',
                            Colors.red.shade900,
                            duration: const Duration(seconds: 2),
                          );
                          _selectedCardIndex = null; // Clear selection
                          _previewNpc = null; // Clear preview
                          _previewLocalPosition = null;
                        }
                        return; // Intercept click
                      }

                      // 2. Otherwise, regular waypoint click player movement
                      if (gameState.combatControlMode == 'click') {
                        _combatManager.movePlayer(targetWorldOffset.dx, targetWorldOffset.dy);
                      }
                    },
                    child: _BattlefieldViewport(
                      zoomFactor: _combatManager.zoomFactor,
                      previewNpc: _previewNpc,
                      previewLocalPosition: _previewLocalPosition,
                    ),
                  ),
                ),
              ),
              const _CombatTimerWidget(),
              const _SplitLogOverlay(),
              
              // Minimap positioned top-left
              const Positioned(
                top: 16,
                left: 16,
                child: _TacticalMinimap(),
              ),

              // Circular Menu Button in top-right
              Positioned(
                top: 16,
                right: 20,
                child: _CombatMenuButton(
                  showMenuDialog: () => _showCombatMenuDialog(context),
                ),
              ),
              
              // Transparent unmarked movement pad in bottom-left
              // Bracketed movement pad in bottom-left
              Positioned(
                bottom: 16,
                left: 16,
                width: navPadWidth,
                height: 160,
                child: Consumer<CombatManager>(
                  builder: (context, manager, child) {
                    final gameState = Provider.of<GameState>(context, listen: false);
                    if (gameState.combatControlMode != 'pad') {
                      return const SizedBox.shrink();
                    }
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) {
                        _keyboardFocusNode.requestFocus();
                        _touchpadPanStartOffset = details.localPosition;
                        final alphonse = manager.combatants.firstWhereOrNull(
                          (c) => c.npc.isPlayer,
                        );
                        if (alphonse != null) {
                          alphonse.waypointX = null;
                          alphonse.waypointY = null;
                          alphonse.detourX = null;
                          alphonse.detourY = null;
                        }
                      },
                      onPanUpdate: (details) {
                        if (_touchpadPanStartOffset != null) {
                          final delta = details.localPosition - _touchpadPanStartOffset!;
                          final double len = sqrt(delta.dx * delta.dx + delta.dy * delta.dy);
                          final alphonse = manager.combatants.firstWhereOrNull(
                            (c) => c.npc.isPlayer && !c.isDead,
                          );
                          if (alphonse != null) {
                            if (len > 5.0) {
                              alphonse.moveDirX = (delta.dx / len).clamp(-1.0, 1.0);
                              alphonse.moveDirY = (delta.dy / len).clamp(-1.0, 1.0);
                            } else {
                              alphonse.moveDirX = 0.0;
                              alphonse.moveDirY = 0.0;
                            }
                          }
                        }
                      },
                      onPanEnd: (_) {
                        _touchpadPanStartOffset = null;
                        final alphonse = manager.combatants.firstWhereOrNull(
                          (c) => c.npc.isPlayer,
                        );
                        if (alphonse != null) {
                          alphonse.moveDirX = 0.0;
                          alphonse.moveDirY = 0.0;
                        }
                      },
                      child: CustomPaint(
                        painter: _TrackpadBracketPainter(),
                        child: const SizedBox.expand(),
                      ),
                    );
                  },
                ),
              ),

              // Floating cards hand & stacked buttons positioned bottom-right (floated elegantly)
              Positioned(
                bottom: 12,
                right: 20,
                child: const _CombatBottomBar(),
              ),
              
              // Player respawn countdown overlay
              ...(() {
                final alphonse = _combatManager.combatants.firstWhereOrNull((c) => c.npc.isPlayer);
                if (alphonse != null && alphonse.isDead && alphonse.respawnTimer != null) {
                  return [
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.35,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'RESPAWNING IN ${alphonse.respawnTimer!.toStringAsFixed(0)}S',
                            style: GoogleFonts.oldStandardTt(
                              color: const Color(0xFFD4AF37),
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ),
                    )
                  ];
                }
                return <Widget>[];
              })(),

              // Top-right Cascading Notification Banners
              Positioned(
                top: 85,
                right: 20,
                width: 280,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: _activeNotifications
                      .map((n) => _CombatNotificationWidget(notification: n))
                      .toList(),
                ),
              ),

              if (_combatManager.isVictory || _combatManager.isDefeat || _combatManager.isDraw)
                Positioned.fill(child: Container(color: Colors.black54)),
            if (_combatManager.isVictory) _buildVictoryOverlay(context),
            if (_combatManager.isDefeat) _buildDefeatOverlay(context),
            if (_combatManager.isDraw) _buildDrawOverlay(context),
          ],
        ),
      ),
    ),
   );
  }

  Widget _buildVictoryOverlay(BuildContext context) {
    if (widget.onSurvivalVictory != null) {
      _calculateSurvivalSpoils();
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'VICTORY',
              style: GoogleFonts.oldStandardTt(
                color: const Color(0xFFD4AF37), // Muted Gold
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'THE ROAD IS LITTERED WITH THEIR DEFEAT.',
              style: GoogleFonts.oldStandardTt(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.yellow.withValues(alpha: 0.3)),
                color: Colors.white.withValues(alpha: 0.05),
              ),
              child: Column(
                children: [
                  Text(
                    'SPOILS OF WAR',
                    style: GoogleFonts.oldStandardTt(
                      color: Colors.yellow,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.onSurvivalVictory != null) ...[
                    if (_spoilsCash > 0)
                      _buildSpoilRow(Icons.monetization_on, '$_spoilsCash CHF', color: Colors.amber.shade700),
                    if (_spoilsFood > 0)
                      _buildSpoilRow(Icons.restaurant, '$_spoilsFood FOOD', color: Colors.green.shade700),
                    if (_spoilsWood > 0)
                      _buildSpoilRow(Icons.forest, '$_spoilsWood WOOD', color: Colors.brown.shade700),
                    if (_spoilsIron > 0)
                      _buildSpoilRow(Icons.construction, '$_spoilsIron IRON', color: Colors.blueGrey.shade600),
                  ] else ...[
                    ..._combatManager.accumulatedLoot.entries
                        .where((e) => e.value > 0)
                        .map((e) {
                          final icon = e.key == 'funds'
                              ? Icons.monetization_on
                              : Icons.restaurant;
                          return _buildSpoilRow(
                            icon,
                            '${e.value} ${e.key.toUpperCase()}',
                          );
                        }),
                  ],
                  if (_combatManager.killedEnemies.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'ENEMIES VANQUISHED: ${_combatManager.killedEnemies.length}',
                      style: GoogleFonts.oldStandardTt(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow.shade800,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 64,
                  vertical: 20,
                ),
                shape: const RoundedRectangleBorder(),
              ),
              onPressed: () {
                if (widget.onSurvivalVictory != null) {
                  final enemyTowers = _combatManager.combatants.where((c) => c.isTower && c.side == CombatSide.enemy);
                  final destroyedTowersCount = enemyTowers.where((t) => t.isDead).length;
                  final playerTowerHealth = _getPlayerTowerHealthMap();
                  widget.onSurvivalVictory!(
                    destroyedTowersCount,
                    widget.customAiDeck ?? [],
                    _spoilsFood,
                    _spoilsCash,
                    _spoilsIron,
                    _spoilsWood,
                    playerTowerHealth,
                    context,
                  );
                } else if (widget.onVictory != null) {
                  Navigator.pop(context);
                  widget.onVictory!();
                } else {
                  final state = Provider.of<GameState>(context, listen: false);
                  state.addResources(_combatManager.accumulatedLoot);
                  state.clearEncounterState();
                  Navigator.pop(context);
                }
              },
              child: Text(
                'COLLECT & CONTINUE',
                style: GoogleFonts.oldStandardTt(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpoilRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color ?? Colors.yellow, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.oldStandardTt(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDefeatOverlay(BuildContext context) {
    return Container(
      color: const Color(0xFF4A0E0E).withValues(alpha: 0.95), // Dried blood red
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DEFEAT',
              style: GoogleFonts.oldStandardTt(
                color: Colors.white,
                fontSize: 84,
                fontWeight: FontWeight.bold,
                letterSpacing: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'THE EXPERIMENT HAS ENDED IN FAILURE.',
              style: GoogleFonts.oldStandardTt(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 64),
            if (widget.onSurvivalDefeat != null) ...[
              _DefeatButton(
                label: 'CONTINUE',
                onPressed: () {
                  final enemyTowers = _combatManager.combatants.where((c) => c.isTower && c.side == CombatSide.enemy);
                  final destroyedTowersCount = enemyTowers.where((t) => t.isDead).length;
                  final playerTowerHealth = _getPlayerTowerHealthMap();
                  widget.onSurvivalDefeat!(destroyedTowersCount, widget.customAiDeck ?? [], playerTowerHealth, context);
                },
                primary: true,
              ),
            ] else if (widget.onDefeat != null) ...[
              _DefeatButton(
                label: 'CONTINUE',
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDefeat!();
                },
                primary: true,
              ),
            ] else ...[
              _DefeatButton(
                label: 'TRY BATTLE AGAIN',
                onPressed: () {
                  // Reset combat manager and restart
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const CombatScreen()),
                  );
                },
                primary: true,
              ),
              const SizedBox(height: 16),
              _DefeatButton(
                label: 'LOAD LAST SAVE',
                onPressed: () {
                  // Load save logic would go here
                  final state = Provider.of<GameState>(context, listen: false);
                  state.clearEncounterState();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              _DefeatButton(
                label: 'ACCEPT FATE (QUIT)',
                onPressed: () {
                  final state = Provider.of<GameState>(context, listen: false);
                  state.clearEncounterState();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDrawOverlay(BuildContext context) {
    return Container(
      color: const Color(0xFF2C2E3B).withValues(alpha: 0.95), // Slate/Ash Gray
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'STANDOFF',
              style: GoogleFonts.oldStandardTt(
                color: Colors.white,
                fontSize: 84,
                fontWeight: FontWeight.bold,
                letterSpacing: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'NEITHER SIDE PREVAILED. THE STANDOFF CONTINUES.',
              style: GoogleFonts.oldStandardTt(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 64),
            if (widget.onSurvivalDraw != null) ...[
              _DefeatButton(
                label: 'CONTINUE',
                onPressed: () {
                  final enemyTowers = _combatManager.combatants.where((c) => c.isTower && c.side == CombatSide.enemy);
                  final destroyedTowersCount = enemyTowers.where((t) => t.isDead).length;
                  final playerTowerHealth = _getPlayerTowerHealthMap();
                  widget.onSurvivalDraw!(destroyedTowersCount, widget.customAiDeck ?? [], playerTowerHealth, context);
                },
                primary: true,
              ),
            ] else if (widget.onDraw != null || widget.onDefeat != null) ...[
              _DefeatButton(
                label: 'CONTINUE',
                onPressed: () {
                  Navigator.pop(context);
                  if (widget.onDraw != null) {
                    widget.onDraw!();
                  } else {
                    widget.onDefeat!();
                  }
                },
                primary: true,
              ),
            ] else ...[
              _DefeatButton(
                label: 'TRY BATTLE AGAIN',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const CombatScreen()),
                  );
                },
                primary: true,
              ),
              const SizedBox(height: 16),
              _DefeatButton(
                label: 'RETREAT TO SAFETY',
                onPressed: () {
                  final state = Provider.of<GameState>(context, listen: false);
                  state.clearEncounterState();
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DefeatButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  const _DefeatButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: primary ? Colors.white : Colors.transparent,
          foregroundColor: primary ? Colors.red.shade900 : Colors.white,
          side: const BorderSide(color: Colors.white, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: GoogleFonts.oldStandardTt(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _BattlefieldViewport extends StatelessWidget {
  final double zoomFactor;
  final NPC? previewNpc;
  final Offset? previewLocalPosition;

  const _BattlefieldViewport({
    required this.zoomFactor,
    this.previewNpc,
    this.previewLocalPosition,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CombatManager>(
      builder: (context, manager, child) {
        final screenSize = MediaQuery.of(context).size;
        final projection = _CombatProjection(
          viewSize: screenSize,
          fieldScroll: manager.fieldScroll,
          yFieldScroll: manager.yFieldScroll,
          zoomFactor: zoomFactor,
        );

        return Container(
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(
            color: Colors.blue, // Sky fallback
          ),
          child: Stack(
            children: [
              // Environment/Background
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _SwissCountrysidePainter(
                      fieldScroll: manager.fieldScroll,
                      yFieldScroll: manager.yFieldScroll,
                    ),
                  ),
                ),
              ),
              // 2a. Battlefield Background Art
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _BattlefieldArtPainter(
                      projection: projection,
                      fieldScroll: manager.fieldScroll,
                      yFieldScroll: manager.yFieldScroll,
                      map: manager.map,
                    ),
                  ),
                ),
              ),

              // 2c. Ability Target Highlight
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _AbilityHighlightPainter(
                      manager: manager,
                      projection: projection,
                    ),
                  ),
                ),
              ),

              // Real-Time Drag & Placement Preview Indicator Overlay
              if (previewNpc != null && previewLocalPosition != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PlacementIndicatorPainter(
                      npc: previewNpc!,
                      screenPos: previewLocalPosition!,
                      projection: projection,
                      manager: manager,
                    ),
                  ),
                ),

              // Waypoint Destination Confirm Marker Overlay
              if (manager.combatants.isNotEmpty) ...(() {
                final alphonse = manager.combatants.firstWhereOrNull((c) => c.npc.isPlayer && !c.isDead);
                if (alphonse != null && alphonse.waypointX != null && alphonse.waypointY != null) {
                  final pos = projection.project(alphonse.waypointX!, alphonse.waypointY!);
                  final ms = DateTime.now().millisecondsSinceEpoch;
                  final pulsePercent = (ms % 1000) / 1000.0;
                  return [
                    Positioned(
                      left: pos.dx - 16,
                      top: pos.dy - 16,
                      width: 32,
                      height: 32,
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _WaypointMarkerPainter(pulsePercent: pulsePercent),
                        ),
                      ),
                    ),
                  ];
                }
                return const <Widget>[];
              })(),

                // Units, Cauldrons, Walls & Special Buttons (Depth-Sorted)
                ...(() {
                  final List<dynamic> renderables = [];

                  final visibleCombatants = manager.combatants.toList();
                  renderables.addAll(visibleCombatants);

                  final visibleCauldrons = manager.cauldrons.toList();
                  renderables.addAll(visibleCauldrons);

                  // Add the centerline walls of the current map dynamically!
                  int wIdx = 1;
                  for (final rect in manager.map.walls) {
                    renderables.add(CombatWall(id: 'wall$wIdx', rect: rect));
                    wIdx++;
                  }

                  renderables.sort((a, b) {
                    final ay = a is Combatant
                        ? a.y
                        : (a is HealingCauldron ? a.y : (a as CombatWall).y);
                    final by = b is Combatant
                        ? b.y
                        : (b is HealingCauldron ? b.y : (b as CombatWall).y);
                    return ay.compareTo(by);
                  });

                  final bodies = renderables.map((item) {
                    if (item is Combatant) {
                      if (item.npc.combatStats?.unitType == UnitType.support) {
                        final npc = item.npc;
                        if (npc.name.contains('Barrage') || npc.name.contains('Artillery')) {
                          return Positioned.fill(
                            key: ValueKey('support_${item.npc.id}'),
                            child: _ArtilleryVisual(
                              combatant: item,
                              projection: projection,
                            ),
                          );
                        } else if (npc.name.contains('Gas') || npc.name.contains('Tear')) {
                          return Positioned.fill(
                            key: ValueKey('support_${item.npc.id}'),
                            child: _TearGasVisual(
                              combatant: item,
                              projection: projection,
                            ),
                          );
                        } else if (npc.name.contains('Caltrops')) {
                          return Positioned.fill(
                            key: ValueKey('support_${item.npc.id}'),
                            child: _CaltropsVisual(
                              combatant: item,
                              projection: projection,
                            ),
                          );
                        } else {
                          final pCenter = projection.project(item.x, item.y);
                          return Positioned(
                            key: ValueKey('support_${item.npc.id}'),
                            left: pCenter.dx - 22.5,
                            top: pCenter.dy - 45.0,
                            width: 45.0,
                            height: 67.5,
                            child: CharacterBlobRenderer(
                              npc: item.npc,
                              size: 45.0,
                              isWalking: false,
                              showSpeechBubble: false,
                              isCombat: true,
                            ),
                          );
                        }
                      } else {
                        final stats = item.npc.combatStats!;
                        final double baseSize = 40.0 * ((stats.radius) / 1.5).clamp(0.5, 2.2);
                        final double boxWidth = baseSize * 1.5;
                        final double boxHeight = baseSize * 2.25;
                        final screenPos = projection.project(item.x, item.y);

                        return Positioned(
                          key: ValueKey('sprite_${item.npc.id}'),
                          left: screenPos.dx - boxWidth / 2,
                          top: screenPos.dy - boxHeight * 0.91,
                          width: boxWidth,
                          height: boxHeight,
                          child: _CombatantSprite(
                            combatant: item,
                            projection: projection,
                            baseSize: baseSize,
                            boxWidth: boxWidth,
                            boxHeight: boxHeight,
                          ),
                        );
                      }
                    } else if (item is HealingCauldron) {
                      final screenPos = projection.project(item.x, item.y);
                      return Positioned(
                        key: ValueKey('cauldron_${item.id}'),
                        left: screenPos.dx - 30,
                        top: screenPos.dy - 75,
                        width: 60,
                        height: 80,
                        child: _CauldronSprite(
                          cauldron: item,
                        ),
                      );
                    } else {
                      final wall = item as CombatWall;
                      return Positioned.fill(
                        key: ValueKey('wall_${wall.id}'),
                        child: _WallRenderer(
                          rect: wall.rect,
                          projection: projection,
                          zoomFactor: zoomFactor,
                        ),
                      );
                    }
                  }).toList();

                  // 2. Special Buttons (Rendered on top of all visible units, excluding player hero)
                  final specialUnits = visibleCombatants
                      .where(
                        (c) =>
                            c.npc.specialCharge >= 1.0 &&
                            c.side == CombatSide.player &&
                            !c.isDead &&
                            !c.npc.isPlayer,
                      )
                      .toList();

                  specialUnits.sort((a, b) => a.y.compareTo(b.y));

                  final specialButtons = specialUnits.map((c) {
                    final pos = projection.project(c.x, c.y);
                    return Positioned(
                      left: pos.dx - 24, // Centered on X (width is 48)
                      top: pos.dy - 62,  // Centered vertically on character body
                      child: _SpecialReadyButton(combatant: c),
                    );
                  });

                  return [...bodies, ...specialButtons];
                })(),

                // Projectiles
                ...manager.projectiles.map((p) {
                  final pos = projection.project(p.x, p.y);
                  return Positioned(
                    left: pos.dx,
                    top: pos.dy,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: p.side == CombatSide.player
                            ? Colors.teal.shade200
                            : Colors.deepOrange.shade200,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: p.side == CombatSide.player
                                ? Colors.teal.withValues(alpha: 0.5)
                                : Colors.deepOrange.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // 4. Atmosphere: Dark Vignette
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.5, // Increased radius
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5), // Lighter
                            Colors.black.withValues(alpha: 0.7), // Lighter
                          ],
                          stops: const [
                            0.2,
                            0.8,
                            1.0,
                          ], // More central visibility
                        ),
                      ),
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

class _CombatantSprite extends StatelessWidget {
  final Combatant combatant;
  final _CombatProjection projection;
  final double baseSize;
  final double boxWidth;
  final double boxHeight;

  const _CombatantSprite({
    required this.combatant,
    required this.projection,
    required this.baseSize,
    required this.boxWidth,
    required this.boxHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (combatant.isDead && !combatant.isTower) {
      if (combatant.npc.isPlayer || combatant.npc.id == 'ai_mirror') {
        // Keep rendering fainted heroes
      } else {
        return const SizedBox.shrink();
      }
    }
    final stats = combatant.npc.combatStats!;
    final healthPercent = (stats.health / stats.maxHealth).clamp(0.0, 1.0);
    final double opacity = combatant.isDead ? 0.3 : 1.0;
    // Scale based on Y depth
    final double scale =
        (0.8 + (combatant.y / CombatManager.fieldWidth) * 0.4) * 0.9;

    final manager = Provider.of<CombatManager>(context, listen: false);
    final isHighlighted = manager.highlightedTargetIds.contains(combatant.npc.id);
    final isFlashing = combatant.flashTimer > 0.0;

    // Character Widget construction
    final Widget characterWidget = Stack(
      alignment: Alignment.center,
      children: [
        combatant.isTower
            ? _TowerRenderer(combatant: combatant)
            : (combatant.isDead
                ? Transform.rotate(
                    angle: pi / 2,
                    child: CharacterBlobRenderer(
                      npc: combatant.npc,
                      size: baseSize,
                      isWalking: false,
                      showSpeechBubble: false,
                      isCombat: true,
                    ),
                  )
                : CharacterBlobRenderer(
                    npc: combatant.npc,
                    size: baseSize,
                    isWalking: combatant.attackCooldown <= 0,
                    showSpeechBubble: false,
                    attackCooldown: combatant.attackCooldown,
                    isCombat: true,
                  )),

        // Staggered recent damage numerical overlay
        if (isFlashing && combatant.recentDamage > 0)
          Center(
            child: Text(
              '-${combatant.recentDamage.toInt()}',
              style: GoogleFonts.oswald(
                color: const Color(0xFFD32F2F),
                fontSize: 8,
                fontWeight: FontWeight.bold,
                height: 1.0,
                shadows: const [
                  Shadow(
                    color: Colors.black87,
                    blurRadius: 1,
                    offset: Offset(0.5, 0.5),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    final Widget visualRepresentation = isFlashing
        ? ColorFiltered(
            colorFilter: ColorFilter.mode(
              combatant.side == CombatSide.player
                  ? Colors.red.withValues(alpha: 0.5)
                  : Colors.red.withValues(alpha: 0.7),
              BlendMode.srcATop,
            ),
            child: characterWidget,
          )
        : characterWidget;

    // Determine horizontal facing direction (Default assets face LEFT)
    bool faceRight = combatant.side == CombatSide.player; // Players face right by default
    if (combatant.targetId != null) {
      final targetCombatant = manager.combatants.firstWhereOrNull(
        (c) => c.npc.id == combatant.targetId && !c.isDead,
      );
      if (targetCombatant != null) {
        faceRight = targetCombatant.x > combatant.x;
      }
    } else if (combatant.moveDirX != 0) {
      faceRight = combatant.moveDirX > 0;
    }

    final Widget flippedVisual = Transform(
      transform: Matrix4.diagonal3Values(faceRight ? -1.0 : 1.0, 1.0, 1.0),
      alignment: Alignment.center,
      child: visualRepresentation,
    );

    return IgnorePointer(
      ignoring: combatant.isDead,
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: SizedBox(
              width: boxWidth,
              height: boxHeight, // Total height to include floating text & hit-test bounds
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Base Ring (Shadow)
                  if (!combatant.isDead)
                    Positioned(
                      bottom: 4,
                      child: Container(
                        width: baseSize * 0.6,
                        height: baseSize * 0.18,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.elliptical(12, 3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: combatant.side == CombatSide.player
                                  ? Colors.blue.withValues(alpha: 0.4)
                                  : Colors.red.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(
                            color: combatant.side == CombatSide.player
                                ? Colors.blue.withValues(alpha: 0.8)
                                : Colors.red.withValues(alpha: 0.8),
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                  // Main Body (Character + Health)
                  // Bottom edge should sit above/centered on shadow
                  Positioned(
                    bottom: 10,
                    child: GestureDetector(
                      onTap: () {
                        if (combatant.side == CombatSide.enemy) {
                          manager.setPlayerTarget(combatant.npc.id);
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Speech Bubble (if active)
                          if (combatant.npc.currentThought != null &&
                              combatant.npc.currentThought!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: Colors.black54, width: 1),
                              ),
                              child: Text(
                                combatant.npc.currentThought!,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                          // Floating text message overlay (staggered)
                          SizedBox(
                            width: 80,
                            height: 20,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: combatant.floatingMessages.map((msg) {
                                return Positioned(
                                  bottom: 45 + msg.offsetY, // Staggered height
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 100),
                                    opacity: min(1.0, msg.lifetime * 2),
                                    child: Text(
                                      msg.text,
                                      style: GoogleFonts.oswald(
                                        color: msg.color,
                                        fontSize: 6,
                                        fontWeight: FontWeight.bold,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black,
                                            blurRadius: 2,
                                            offset: Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          // Highlight target indicator (drawn below health bar)
                          if (isHighlighted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              margin: const EdgeInsets.only(bottom: 2),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(2)),
                              ),
                              child: Text(
                                'TARGET',
                                style: GoogleFonts.oswald(
                                  color: Colors.white,
                                  fontSize: 5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                          // Health Bar (allies: green, enemies: red)
                          if (!combatant.isDead) ...[
                            Container(
                              width: (stats.maxHealth * 0.24).clamp(12.0, 72.0),
                              height: 3,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1612),
                                border: Border.all(color: const Color(0xFFC4B89B), width: 1),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: healthPercent,
                                child: Container(
                                  color: combatant.side == CombatSide.player
                                      ? Colors.green.shade400
                                      : Colors.red.shade400,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],

                          // Unit visual representation
                          flippedVisual,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}

class _SpecialReadyButton extends StatelessWidget {
  final Combatant combatant;

  const _SpecialReadyButton({required this.combatant});

  @override
  Widget build(BuildContext context) {
    return Consumer<CombatManager>(
      builder: (context, manager, child) {
        final canUse = manager.canExecuteSpecial(combatant.npc.id);
        final special = combatant.npc.abilities.firstWhereOrNull((a) => a.type == AbilityType.special);
        if (special == null) return const SizedBox.shrink();

        return Tooltip(
          message: "${special.name}: ${special.description}",
          textStyle: GoogleFonts.oldStandardTt(color: Colors.white, fontSize: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1B1B),
            border: Border.all(color: const Color(0xFFC4B89B), width: 1.0),
            borderRadius: BorderRadius.circular(4),
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: canUse ? () {
                final screenState = context.findAncestorStateOfType<_CombatScreenState>();
                manager.executeSpecial(combatant.npc.id); // Call executeSpecial for normal special abilities!
                screenState?._showNotification(
                  '${combatant.npc.name} used ${special.name}!',
                  const Color(0xFFC4B89B),
                  duration: const Duration(seconds: 1),
                );
              } : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: canUse ? 1.0 : 0.4,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: canUse ? const Color(0xFFC4B89B) : Colors.grey.shade800,
                    border: Border.all(color: const Color(0xFF2A1B1B), width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 6.0,
                        spreadRadius: 1.0,
                        offset: Offset(0.0, 3.0),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.bolt,
                    color: Colors.black,
                    size: 14.0,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}



class _CombatTimerWidget extends StatelessWidget {
  const _CombatTimerWidget();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      right: 20,
      child: Consumer<CombatManager>(
        builder: (context, manager, child) {
          final minutes = (manager.combatTimeRemaining / 60).floor();
          final seconds = (manager.combatTimeRemaining % 60).floor();
          final timeStr =
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
          final isLastMinute = manager.isLastMinute;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isLastMinute ? 'ENERGY OVERDRIVE (2X)' : 'COMBAT STATUS',
                style: GoogleFonts.oldStandardTt(
                  color: isLastMinute ? const Color(0xFFD4AF37) : Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Available Energy (Action Points)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt,
                        color: Color(0xFFD4AF37),
                        size: 13,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        manager.actionPoints.toStringAsFixed(1),
                        style: GoogleFonts.oldStandardTt(
                          color: const Color(0xFFD4AF37),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' / 10',
                        style: GoogleFonts.oldStandardTt(
                          color: Colors.white54,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  // Remaining Time Clock
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_bottom,
                        color: isLastMinute ? const Color(0xFFD4AF37) : Colors.white70,
                        size: 12,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: GoogleFonts.oldStandardTt(
                          color: isLastMinute ? const Color(0xFFD4AF37) : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SplitLogOverlay extends StatelessWidget {
  const _SplitLogOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Consumer<CombatManager>(
        builder: (context, manager, child) {
          final playerLogs = manager.logs
              .where((l) => l.side == CombatSide.player)
              .take(3)
              .toList();
          final enemyLogs = manager.logs
              .where((l) => l.side == CombatSide.enemy)
              .take(3)
              .toList();

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Player Logs (Left)
              SizedBox(
                width: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: playerLogs
                      .map((l) => _buildLogText(l.message, Colors.cyanAccent))
                      .toList(),
                ),
              ),
              const SizedBox(width: 20),
              // Enemy Logs (Right)
              SizedBox(
                width: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: enemyLogs
                      .map((l) => _buildLogText(l.message, Colors.orangeAccent))
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogText(String message, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(
        message.toUpperCase(),
        style: GoogleFonts.oldStandardTt(
          color: color.withValues(alpha: 0.8),
          fontSize: 8,
          fontWeight: FontWeight.bold,
          shadows: [const Shadow(color: Colors.black, blurRadius: 2)],
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _CombatBottomBar extends StatelessWidget {
  const _CombatBottomBar();

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<CombatManager>(context);
    return GestureDetector(
      onTap: () {}, // Absorbs gestures to block underlying map panning/zooming!
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. Floating Cards Hand Bar with thin AP progress bar on top
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AP Progress Bar sitting on top
              Consumer<CombatManager>(
                builder: (context, manager, child) {
                  final double apVal = (manager.actionPoints / 10.0).clamp(0.0, 1.0);
                  final double minCost = manager.hand.isEmpty
                      ? 0.0
                      : manager.hand.map((n) => n.combatStats?.cost ?? 0).reduce(min).toDouble();
                  final bool hasEnough = manager.actionPoints >= minCost;
                  final progressColor = hasEnough ? const Color(0xFFD4AF37) : Colors.redAccent;

                  return Container(
                    width: 492,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: apVal,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: progressColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Translucent floating card hand box (solid premium dark box backing)
              Container(
                width: 492,
                height: 74,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.3), width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  itemCount: manager.hand.length,
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  itemBuilder: (context, index) {
                    final npc = manager.hand[index];
                    return _UnitCard(key: ValueKey(npc.id), npc: npc);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // 2. Vertically stacked special action buttons (R and F) on the right
          Padding(
            padding: const EdgeInsets.only(bottom: 0.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: "MASTER'S COMMAND - TAP TO TRIGGER: Nearby allies gain +50% Attack Speed for 8 seconds.",
                  textStyle: GoogleFonts.oldStandardTt(color: Colors.white, fontSize: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1B1B),
                    border: Border.all(color: const Color(0xFFC4B89B), width: 1.0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _SpecialAbilityButton(
                    label: '',
                    icon: Icons.gavel,
                    isCharged: manager.combatants.firstWhereOrNull((c) => c.npc.isPlayer)?.npc.specialCharge == 1.0,
                    onPressed: () {
                      manager.executeSpecial('alphonse');
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Tooltip(
                  message: "LIGHTNING STRIKE - TAP TO TRIGGER: Strike the nearest enemy for 150 dmg and stun them for 4s.",
                  textStyle: GoogleFonts.oldStandardTt(color: Colors.white, fontSize: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1B1B),
                    border: Border.all(color: const Color(0xFFC4B89B), width: 1.0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _SpecialAbilityButton(
                    label: '',
                    icon: Icons.flash_on,
                    isCharged: (manager.combatants.firstWhereOrNull((c) => c.npc.isPlayer)?.specialCharge2 ?? 0.0) >= 1.0,
                    onPressed: () {
                      manager.executeSpecial2('alphonse');
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitCard extends StatefulWidget {
  final NPC npc;
  const _UnitCard({super.key, required this.npc});

  @override
  State<_UnitCard> createState() => _UnitCardState();
}

class _UnitCardState extends State<_UnitCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<CombatManager>(context, listen: false);
    final cost = widget.npc.combatStats?.cost ?? 0;
    final canAfford = manager.actionPoints >= cost;
    final screenSizeVal = MediaQuery.of(context).size;

    return Draggable<NPC>(
          data: widget.npc,
          feedback: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: 0.8,
              child: CharacterBlobRenderer(npc: widget.npc, size: 20, showSpeechBubble: false, isCombat: true),
            ),
          ),
          onDragStarted: () {
            setState(() => _isExpanded = false);
            final screenState = context.findAncestorStateOfType<_CombatScreenState>();
            screenState?.updateDragPreview(widget.npc, Offset.zero);
          },
          onDragUpdate: (details) {
            final screenState = context.findAncestorStateOfType<_CombatScreenState>();
            screenState?.updateDragPreview(widget.npc, details.globalPosition);
          },
          onDragEnd: (details) {
            final screenState = context.findAncestorStateOfType<_CombatScreenState>();
            screenState?.clearDragPreview();

            final screenSize = screenSizeVal;
            final projection = _CombatProjection(
              viewSize: screenSize,
              fieldScroll: manager.fieldScroll,
              yFieldScroll: manager.yFieldScroll,
              zoomFactor: manager.zoomFactor,
            );
            
            // Allow dropping anywhere that projects to valid world Y
            if (details.offset.dy < projection.yNear) {
              // Compensate for the drag anchor (CharacterBlob is 50x50, anchor is center)
              // We want the feet (bottom of blob) to match world position.
              final dragFeetOffset =
                  details.offset + const Offset(25, 50);
              final worldPos = projection.unproject(dragFeetOffset);
              final dropX = worldPos.dx;
              final dropY = worldPos.dy;

              final clampedY = dropY.clamp(
                0.0,
                manager.map.height,
              );
              final success = manager.spawnUnit(
                widget.npc,
                CombatSide.player,
                x: dropX,
                y: clampedY,
              );
              if (success) {
                screenState?._showNotification(
                  '${widget.npc.name} deployed!',
                  Colors.blue.shade800,
                  duration: const Duration(seconds: 1),
                );
              } else {
                final isSupport = widget.npc.name.contains('Barrage') ||
                    widget.npc.name.contains('Artillery') ||
                    widget.npc.name.contains('Gas') ||
                    widget.npc.name.contains('Tear') ||
                    widget.npc.name.contains('Caltrops') ||
                    widget.npc.name.contains('Totem') ||
                    (widget.npc.combatStats?.unitType == UnitType.support);
                screenState?._showNotification(
                  isSupport
                      ? 'Deployment failed! Out of range or invalid support target.'
                      : 'Deployment failed! Must be in home zone (20%) or behind an allied unit on a lane.',
                  Colors.red.shade900,
                  duration: const Duration(seconds: 2),
                );
              }
            }
          },
          child: GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 88,
              height: 56,
              margin: const EdgeInsets.only(right: 12),
              transform: Matrix4.translationValues(0, _isExpanded ? -10 : 0, 0),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF5E6), // Old Lace/Parchment
                border: Border.all(
                  color: _isExpanded
                      ? const Color(0xFF8B4513) // Saddle Brown
                      : (canAfford
                            ? const Color(0xFF5D4037) // Muted Brown
                            : const Color(0xFFD32F2F).withValues(alpha: 0.5)),
                  width: _isExpanded ? 3 : 2,
                ),
                boxShadow: _isExpanded
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(4, 4),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Stats & Name (Left)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 54,
                                  height: 10,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      widget.npc.name.toUpperCase(),
                                      style: GoogleFonts.oldStandardTt(
                                        color: const Color(0xFF2E1A0A), // Dark Ink
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.npc.combatStats?.isFlying == true)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 2.0),
                                        child: Icon(Icons.flutter_dash, size: 8.0, color: Color(0xFF4E342E)),
                                      ),
                                    if (widget.npc.combatStats?.trait == CombatTrait.magicImmune)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 2.0),
                                        child: Icon(Icons.block, size: 8.0, color: Color(0xFFC62828)),
                                      ),
                                    if (widget.npc.combatStats?.unitType == UnitType.support)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 2.0),
                                        child: Icon(Icons.local_fire_department, size: 8.0, color: Color(0xFFE64A19)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Damage & Health (Right)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 4.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (widget.npc.combatStats!.meleeDamage > 0 && widget.npc.combatStats!.rangedDamage > 0)
                                _buildCombinedCardStat(
                                  DaggerIcon(color: Colors.deepOrange.shade800, size: 6.5),
                                  '${widget.npc.combatStats!.meleeDamage.toInt()}',
                                  Icon(Icons.gps_fixed, size: 6.5, color: Colors.deepOrange.shade800),
                                  '${widget.npc.combatStats!.rangedDamage.toInt()}',
                                  Colors.deepOrange.shade800,
                                )
                              else ...[
                                if (widget.npc.combatStats!.meleeDamage > 0 || widget.npc.combatStats!.rangedDamage == 0)
                                  _buildCardStat(
                                    DaggerIcon(color: Colors.deepOrange.shade800, size: 7.0),
                                    '${widget.npc.combatStats!.meleeDamage.toInt() > 0 ? widget.npc.combatStats!.meleeDamage.toInt() : widget.npc.combatStats!.attack.toInt()}',
                                    Colors.deepOrange.shade800,
                                  ),
                                if (widget.npc.combatStats!.rangedDamage > 0) ...[
                                  if (widget.npc.combatStats!.meleeDamage > 0 || widget.npc.combatStats!.rangedDamage == 0)
                                    const SizedBox(height: 1.0),
                                  _buildCardStat(
                                    Icon(Icons.gps_fixed, size: 7.0, color: Colors.deepOrange.shade800),
                                    '${widget.npc.combatStats!.rangedDamage.toInt()}',
                                    Colors.deepOrange.shade800,
                                  ),
                                ],
                              ],
                              const SizedBox(height: 1.0),
                              _buildCardStat(
                                Icon(Icons.favorite, size: 7.0, color: Colors.green.shade900),
                                '${widget.npc.combatStats?.maxHealth.toInt() ?? 0}',
                                Colors.green.shade900,
                              ),
                              const SizedBox(height: 1.0),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.group,
                                    size: 7.5,
                                    color: Color(0xFF4E342E),
                                  ),
                                  const SizedBox(width: 1.5),
                                  Text(
                                    '${widget.npc.combatStats?.unitCount ?? 1}',
                                    style: GoogleFonts.oldStandardTt(
                                      color: const Color(0xFF4E342E),
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: canAfford ? const Color(0xFF3E2723) : const Color(0xFFB71C1C),
                        border: Border.all(color: const Color(0xFFC4B89B), width: 0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        '$cost',
                        style: GoogleFonts.oldStandardTt(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Expanded Detail Panel (Lifted up above the main card)
                  if (_isExpanded)
                    Positioned(
                      bottom: 58,
                      left: -20,
                      right: -20,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Center(
                              child: CharacterBlobRenderer(
                                npc: widget.npc,
                                size: 40,
                                showSpeechBubble: false,
                                isCombat: true,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'COST: $cost AP',
                              style: GoogleFonts.oldStandardTt(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyanAccent,
                              ),
                            ),
                            const Divider(color: Colors.white24, height: 8),
                            Text(
                              'DRAG ONTO BATTLEFIELD TO DEPLOY',
                              style: GoogleFonts.oldStandardTt(
                                fontSize: 7.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const Divider(color: Colors.white24, height: 8),
                            _buildDetailRow(
                              'Speed',
                              widget.npc.combatStats?.speed.toStringAsFixed(1) ??
                                  '0',
                            ),
                            _buildDetailRow(
                              'Range',
                              widget.npc.combatStats?.distance.toStringAsFixed(
                                    1,
                                  ) ??
                                  '0',
                            ),
                            const Divider(color: Colors.white24, height: 8),
                            Text(
                              'ABILITIES',
                              style: GoogleFonts.oldStandardTt(
                                fontSize: 8,
                                color: Colors.blue[300],
                              ),
                            ),
                            ...widget.npc.abilities
                                .take(2)
                                .map(
                                  (a) => Text(
                                    '• ${a.name}',
                                    style: GoogleFonts.oldStandardTt(
                                      fontSize: 8,
                                      color: Colors.white70,
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
          ),
        );
  }

  Widget _buildCardStat(Widget icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 1.0),
          Text(
            value,
            style: GoogleFonts.oldStandardTt(
              color: color,
              fontSize: 7.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedCardStat(Widget icon1, String value1, Widget icon2, String value2, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 0.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon1,
          const SizedBox(width: 0.5),
          Text(
            value1,
            style: GoogleFonts.oldStandardTt(
              color: color,
              fontSize: 7.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.5),
            child: Text(
              '/',
              style: GoogleFonts.oldStandardTt(
                color: color.withValues(alpha: 0.4),
                fontSize: 6.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          icon2,
          const SizedBox(width: 0.5),
          Text(
            value2,
            style: GoogleFonts.oldStandardTt(
              color: color,
              fontSize: 7.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 8),
        ),
        Text(
          value,
          style: GoogleFonts.oldStandardTt(color: Colors.white, fontSize: 8),
        ),
      ],
    );
  }
}

class DaggerPainter extends CustomPainter {
  final Color color;
  DaggerPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;
    
    // Blade pointing up
    path.moveTo(w * 0.5, 0); // Tip
    path.lineTo(w * 0.75, h * 0.55);
    path.lineTo(w * 0.25, h * 0.55);
    path.close();
    
    // Crossguard
    path.moveTo(w * 0.1, h * 0.55);
    path.lineTo(w * 0.9, h * 0.55);
    path.lineTo(w * 0.9, h * 0.68);
    path.lineTo(w * 0.1, h * 0.68);
    path.close();

    // Grip / Handle
    path.moveTo(w * 0.38, h * 0.68);
    path.lineTo(w * 0.62, h * 0.68);
    path.lineTo(w * 0.62, h * 0.95);
    path.lineTo(w * 0.38, h * 0.95);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DaggerIcon extends StatelessWidget {
  final Color color;
  final double size;
  const DaggerIcon({super.key, required this.color, this.size = 8});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.7, size),
      painter: DaggerPainter(color),
    );
  }
}

class CombatWall {
  final String id;
  final Rect rect;
  double get y => rect.bottom;

  CombatWall({required this.id, required this.rect});
}

class _WallRenderer extends StatelessWidget {
  final Rect rect;
  final _CombatProjection projection;
  final double zoomFactor;

  const _WallRenderer({
    required this.rect,
    required this.projection,
    required this.zoomFactor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SingleWall3DPainter(
        rect: rect,
        projection: projection,
        zoomFactor: zoomFactor,
      ),
    );
  }
}

class _SingleWall3DPainter extends CustomPainter {
  final Rect rect;
  final _CombatProjection projection;
  final double zoomFactor;

  _SingleWall3DPainter({
    required this.rect,
    required this.projection,
    required this.zoomFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(rect.left.toInt() ^ rect.top.toInt());

    final wallPaintSide = Paint()
      ..color = const Color(0xFF454B50) // Darker slate granite for cliff sides
      ..style = PaintingStyle.fill;
    final wallPaintTop = Paint()
      ..color = const Color(0xFF646D75) // Lighter slate granite for cliff top
      ..style = PaintingStyle.fill;
    final mossPaint = Paint()
      ..color = const Color(0xFF4A624E).withValues(alpha: 0.8) // Green organic moss patches
      ..style = PaintingStyle.fill;
    final wallStroke = Paint()
      ..color = const Color(0xFF1F2224)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final double h3d = 26.0 * zoomFactor; // 3D extrusion height

    // Project the four corners
    final pTL = projection.project(rect.left, rect.top);
    final pTR = projection.project(rect.right, rect.top);
    final pBR = projection.project(rect.right, rect.bottom);
    final pBL = projection.project(rect.left, rect.bottom);

    // Create organic jagged offsets for vertices to look like real rock cliffs instead of blocks
    Offset jitter(Offset p) {
      final dx = (random.nextDouble() - 0.5) * 4.0 * zoomFactor;
      final dy = (random.nextDouble() - 0.5) * 2.0 * zoomFactor;
      return Offset(p.dx + dx, p.dy + dy);
    }

    final jpTL = jitter(pTL);
    final jpTR = jitter(pTR);
    final jpBR = jitter(pBR);
    final jpBL = jitter(pBL);

    // Extruded top face vertices
    final jtTL = Offset(jpTL.dx, jpTL.dy - h3d);
    final jtTR = Offset(jpTR.dx, jpTR.dy - h3d);
    final jtBR = Offset(jpBR.dx, jpBR.dy - h3d);
    final jtBL = Offset(jpBL.dx, jpBL.dy - h3d);

    // 1. Draw Front-Left Side shadow faces (Jagged side face)
    final pathSide = Path()
      ..moveTo(jpBL.dx, jpBL.dy)
      ..lineTo(jpBR.dx, jpBR.dy)
      ..lineTo(jtBR.dx, jtBR.dy)
      ..lineTo(jtBL.dx, jtBL.dy)
      ..close();
    canvas.drawPath(pathSide, wallPaintSide);
    canvas.drawPath(pathSide, wallStroke);

    // 2. Draw Top face
    final pathTop = Path()
      ..moveTo(jtTL.dx, jtTL.dy)
      ..lineTo(jtTR.dx, jtTR.dy)
      ..lineTo(jtBR.dx, jtBR.dy)
      ..lineTo(jtBL.dx, jtBL.dy)
      ..close();
    canvas.drawPath(pathTop, wallPaintTop);
    canvas.drawPath(pathTop, wallStroke);

    // 3. Draw Moss Overlay patches on top of the rock
    final mossPath = Path()
      ..moveTo(jtTL.dx + (jtTR.dx - jtTL.dx) * 0.1, jtTL.dy + (jtBL.dy - jtTL.dy) * 0.1)
      ..lineTo(jtTR.dx - (jtTR.dx - jtTL.dx) * 0.3, jtTR.dy + (jtBR.dy - jtTR.dy) * 0.15)
      ..lineTo(jtBR.dx - (jtBR.dx - jtBL.dx) * 0.15, jtBR.dy - (jtBR.dy - jtTR.dy) * 0.2)
      ..lineTo(jtBL.dx + (jtBR.dx - jtBL.dx) * 0.2, jtBL.dy - (jtBL.dy - jtTL.dy) * 0.3)
      ..close();
    canvas.drawPath(mossPath, mossPaint);

    // 4. Draw fine fissures & rocky cracks on the cliff sides
    final crackPaint = Paint()
      ..color = const Color(0xFF282C2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    
    for (int i = 0; i < 3; i++) {
      final double startRatio = 0.2 + i * 0.3;
      final double startX = jpBL.dx + (jpBR.dx - jpBL.dx) * startRatio;
      final double startY = jpBL.dy + (jpBR.dy - jpBL.dy) * startRatio;
      
      final Path crackPath = Path()
        ..moveTo(startX, startY)
        ..lineTo(startX + (random.nextDouble() - 0.5) * 6.0, startY - h3d * 0.4)
        ..lineTo(startX + (random.nextDouble() - 0.5) * 8.0, startY - h3d * 0.8);
      canvas.drawPath(crackPath, crackPaint);
    }

    // 5. Draw Bedrock Blending Boulders (circles) around the base of the cliff
    final boulderPaint = Paint()
      ..color = const Color(0xFF454B50)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 4; i++) {
      final double ratio = 0.15 + i * 0.25;
      final double bx = jpBL.dx + (jpBR.dx - jpBL.dx) * ratio;
      final double by = jpBL.dy + (jpBR.dy - jpBL.dy) * ratio;
      final double r = (4.0 + random.nextDouble() * 4.0) * zoomFactor;

      canvas.drawCircle(Offset(bx, by + 2.0), r, boulderPaint);
      canvas.drawCircle(Offset(bx, by + 2.0), r, wallStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _SingleWall3DPainter oldDelegate) =>
      oldDelegate.zoomFactor != zoomFactor ||
      oldDelegate.rect != rect;
}

class _BattlefieldArtPainter extends CustomPainter {
  final _CombatProjection projection;
  final double fieldScroll;
  final double yFieldScroll;
  final CombatMap map;

  _BattlefieldArtPainter({
    required this.projection,
    required this.fieldScroll,
    required this.yFieldScroll,
    required this.map,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final meadowPaint = Paint()..color = const Color(0xFF1F3322); // Lush alpine forest green base
    final random = Random(1337);

    // 1. Fill background with lush meadow green
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), meadowPaint);

    // Project outer arena bounds to clip detailed landscaping elegantly within map borders
    final pTL = projection.project(0.0, 0.0);
    final pTR = projection.project(map.width, 0.0);
    final pBR = projection.project(map.width, map.height);
    final pBL = projection.project(0.0, map.height);

    final arenaPath = Path()
      ..moveTo(pBL.dx, pBL.dy)
      ..lineTo(pTL.dx, pTL.dy)
      ..lineTo(pTR.dx, pTR.dy)
      ..lineTo(pBR.dx, pBR.dy)
      ..close();

    canvas.save();
    canvas.clipPath(arenaPath);

    // 2. Draw organic ground variations (darker/lighter mossy patches) in meadow
    final mossPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 35; i++) {
      final mx = random.nextDouble() * map.width;
      final my = random.nextDouble() * map.height;
      final radius = 12.0 + random.nextDouble() * 24.0;
      final c1 = projection.project(mx, my);
      
      mossPaint.color = random.nextBool() 
          ? const Color(0xFF17271B).withValues(alpha: 0.5) 
          : const Color(0xFF28402B).withValues(alpha: 0.4);
      canvas.drawCircle(c1, radius, mossPaint);
    }

    // 3. Draw the horizontal Cobblestone & Gravel lane paths
    final pathPaint = Paint()..color = const Color(0xFF8B8070); // Base weathered gravel
    final stonePaint = Paint()..color = const Color(0xFF5C5449); // Dark grey cobblestones
    final stoneHighlightPaint = Paint()..color = const Color(0xFFAD9E8C);

    for (final ly in map.laneCenters) {
      // Draw a horizontal textured pathway centered on ly (approx 26ft wide = 13ft each side)
      final double laneHalfWidth = 13.0;
      final double yTop = ly - laneHalfWidth;
      final double yBottom = ly + laneHalfWidth;

      // Build horizontal path polygon
      final Path lanePath = Path();
      final lTL = projection.project(0.0, yTop);
      final lTR = projection.project(map.width, yTop);
      final lBR = projection.project(map.width, yBottom);
      final lBL = projection.project(0.0, yBottom);

      lanePath.moveTo(lBL.dx, lBL.dy);
      lanePath.lineTo(lTL.dx, lTL.dy);
      lanePath.lineTo(lTR.dx, lTR.dy);
      lanePath.lineTo(lBR.dx, lBR.dy);
      lanePath.close();

      canvas.drawPath(lanePath, pathPaint);

      // Draw Cobblestones inside this path
      for (double x = 4.0; x < map.width; x += 15.0) {
        final double offsetOffset = (x.toInt() % 2 == 0) ? 4.0 : -4.0;
        for (double y = yTop + 3.0; y < yBottom - 2.0; y += 6.0) {
          final px = x + random.nextDouble() * 6.0;
          final py = y + offsetOffset + random.nextDouble() * 2.0;
          if (py >= yTop && py <= yBottom) {
            final stonePos = projection.project(px, py);
            final stoneW = 4.0 + random.nextDouble() * 4.0;
            final stoneH = 2.0 + random.nextDouble() * 2.0;

            // Draw a rounded cobblestone paver
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromCenter(center: stonePos, width: stoneW, height: stoneH),
                const Radius.circular(1.5),
              ),
              stonePaint,
            );

            // Subtle highlight edge for 3D touch
            if (random.nextBool()) {
              canvas.drawLine(
                Offset(stonePos.dx - stoneW / 2, stonePos.dy - stoneH / 2),
                Offset(stonePos.dx + stoneW / 2, stonePos.dy - stoneH / 2),
                stoneHighlightPaint,
              );
            }
          }
        }
      }

      // Draw soft grass growing over the edges of the pathways (blending borders)
      final grassBlendPaint = Paint()..color = const Color(0xFF1F3322)..style = PaintingStyle.stroke..strokeWidth = 2.5;
      for (double x = 0; x < map.width; x += 8) {
        final grassTop = projection.project(x, yTop + random.nextDouble() * 2.0);
        final grassBottom = projection.project(x, yBottom - random.nextDouble() * 2.0);

        canvas.drawCircle(grassTop, 2.0, grassBlendPaint);
        canvas.drawCircle(grassBottom, 2.0, grassBlendPaint);
      }
    }

    // 4. Draw Grass Tufts & Wildflowers across the meadow
    final tuftPaint = Paint()
      ..color = const Color(0xFF375E3D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    
    final flowerYellow = Paint()..color = const Color(0xFFECC844);
    final flowerWhite = Paint()..color = Colors.white70;

    for (int i = 0; i < 150; i++) {
      final tx = random.nextDouble() * map.width;
      final ty = random.nextDouble() * map.height;

      // Avoid drawing grass tufts directly in the middle of paths
      bool inPath = false;
      for (final ly in map.laneCenters) {
        if ((ty - ly).abs() < 12.0) {
          inPath = true;
          break;
        }
      }
      if (inPath) continue;

      final pos = projection.project(tx, ty);

      // Grass Blade lines
      canvas.drawLine(pos, Offset(pos.dx - 1.5, pos.dy - 4.0), tuftPaint);
      canvas.drawLine(pos, Offset(pos.dx + 1.5, pos.dy - 4.5), tuftPaint);
      canvas.drawLine(pos, Offset(pos.dx + 0.5, pos.dy - 2.5), tuftPaint);

      // Tiny wildflowers
      if (random.nextDouble() > 0.6) {
        final fPos = Offset(pos.dx + (random.nextDouble() - 0.5) * 8.0, pos.dy + (random.nextDouble() - 0.5) * 4.0);
        canvas.drawCircle(fPos, 0.9, random.nextBool() ? flowerYellow : flowerWhite);
      }
    }

    canvas.restore();

    // Border weathered boundary paths
    final boundaryPaint = Paint()
      ..color = const Color(0xFF4E3D30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawLine(pTL, pTR, boundaryPaint);
    canvas.drawLine(pBL, pBR, boundaryPaint);
    canvas.drawLine(pTL, pBL, boundaryPaint);
    canvas.drawLine(pTR, pBR, boundaryPaint);
  }

  @override
  bool shouldRepaint(covariant _BattlefieldArtPainter oldDelegate) =>
      oldDelegate.fieldScroll != fieldScroll || oldDelegate.map != map;
}



class _CombatProjection {
  final Size viewSize;
  final double fieldScroll;
  final double yFieldScroll;
  final double zoomFactor;

  _CombatProjection({
    required this.viewSize,
    required this.fieldScroll,
    required this.yFieldScroll,
    this.zoomFactor = 1.0,
  });

  double get yNear => viewSize.height - 120.0;

  Offset project(double worldX, double worldY) {
    final double W = viewSize.width;
    final double H = yNear;

    final double cx = W / 2;
    final double cy = H / 2;

    // Scale factors derived from unified proportions (exact match to minimap):
    final double aScale = (W / 160.0) * zoomFactor;
    final double bScale = (W / 248.0) * zoomFactor;
    final double dScale = -(H / 180.0) * zoomFactor;
    final double eScale = (H / 93.3) * zoomFactor;

    // Centered coordinates (fieldScroll, yFieldScroll is camera center)
    final double rx = worldX - fieldScroll;
    final double ry = worldY - yFieldScroll;

    final double screenX = cx + rx * aScale + ry * bScale;
    final double screenY = cy + rx * dScale + ry * eScale;

    return Offset(screenX, screenY);
  }

  Offset unproject(Offset screenPos) {
    final double W = viewSize.width;
    final double H = yNear;

    final double cx = W / 2;
    final double cy = H / 2;

    final double dx = screenPos.dx - cx;
    final double dy = screenPos.dy - cy;

    final double aScale = (W / 160.0) * zoomFactor;
    final double bScale = (W / 248.0) * zoomFactor;
    final double dScale = -(H / 180.0) * zoomFactor;
    final double eScale = (H / 93.3) * zoomFactor;

    final double det = aScale * eScale - bScale * dScale;
    if (det.abs() < 0.00001) return Offset(fieldScroll, yFieldScroll);

    final double rx = (dx * eScale - dy * bScale) / det;
    final double ry = (-dx * dScale + dy * aScale) / det;

    final double worldX = rx + fieldScroll;
    final double worldY = ry + yFieldScroll;

    return Offset(worldX, worldY);
  }
}
class _SwissCountrysidePainter extends CustomPainter {
  final double fieldScroll;
  final double yFieldScroll;

  _SwissCountrysidePainter({required this.fieldScroll, required this.yFieldScroll});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Sky Gradient (Slate Blue to Dusk Warm Copper-Orange)
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF141B24),
          const Color(0xFF2E2B3A),
          const Color(0xFF5A3B35),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.35));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // 2. Layered Distant Tonal Shapes (Mountains)
    // Layer A: Far away dark purple mountains
    final farMountainPaint = Paint()..color = const Color(0xFF221E26);
    final random = Random(42);
    for (int i = 0; i < 6; i++) {
      final mWidth = size.width * 0.5;
      final mHeight = size.height * 0.22;
      final mX = (i * size.width * 0.25) - (fieldScroll * 0.2 % (size.width * 0.25));
      final mY = size.height * 0.35;

      final path = Path()
        ..moveTo(mX - mWidth * 0.2, mY)
        ..lineTo(mX + mWidth * 0.3, mY - mHeight)
        ..lineTo(mX + mWidth * 0.5, mY - mHeight * 0.8)
        ..lineTo(mX + mWidth * 0.7, mY - mHeight * 1.1)
        ..lineTo(mX + mWidth, mY)
        ..close();
      canvas.drawPath(path, farMountainPaint);
    }

    // Layer B: Closer snow-capped slate peaks
    final midMountainPaint = Paint()..color = const Color(0xFF2B323C);
    final snowPaint = Paint()..color = const Color(0xFFEAEFF2);
    for (int i = 0; i < 8; i++) {
      final mWidth = size.width * 0.35;
      final mHeight = size.height * 0.18;
      final mX = (i * size.width * 0.18) - (fieldScroll * 0.4 % (size.width * 0.18));
      final mY = size.height * 0.35;

      final peakX = mX + mWidth / 2;
      final peakY = mY - mHeight;

      final path = Path()
        ..moveTo(mX, mY)
        ..lineTo(peakX, peakY)
        ..lineTo(mX + mWidth, mY)
        ..close();
      canvas.drawPath(path, midMountainPaint);

      // Draw Snowy cap
      final snowPath = Path()
        ..moveTo(peakX - size.width * 0.02, peakY + mHeight * 0.15)
        ..lineTo(peakX, peakY)
        ..lineTo(peakX + size.width * 0.02, peakY + mHeight * 0.15)
        ..lineTo(peakX + size.width * 0.008, peakY + mHeight * 0.25)
        ..lineTo(peakX, peakY + mHeight * 0.18)
        ..lineTo(peakX - size.width * 0.008, peakY + mHeight * 0.25)
        ..close();
      canvas.drawPath(snowPath, snowPaint);
    }

    // 3. Horizon Pine Tree Silhouettes base
    final treePaint = Paint()..color = const Color(0xFF14181C);
    for (double tx = -50; tx < size.width + 50; tx += 14) {
      final double scrollOffset = fieldScroll * 0.6 % 14;
      final x = tx - scrollOffset;
      final y = size.height * 0.35;
      final tH = 12.0 + random.nextDouble() * 8.0;

      final path = Path()
        ..moveTo(x - 5, y)
        ..lineTo(x, y - tH)
        ..lineTo(x + 5, y)
        ..close();
      canvas.drawPath(path, treePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SwissCountrysidePainter oldDelegate) =>
      oldDelegate.fieldScroll != fieldScroll;
}

class _AbilityHighlightPainter extends CustomPainter {
  final CombatManager manager;
  final _CombatProjection projection;

  _AbilityHighlightPainter({required this.manager, required this.projection});

  @override
  void paint(Canvas canvas, Size size) {
    if (manager.highlightedTargetIds.isEmpty) return;

    final paint = Paint()
      ..color = Colors.yellowAccent.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final glowPaint = Paint()
      ..color = Colors.yellowAccent.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    for (final id in manager.highlightedTargetIds) {
      final c = manager.combatants.firstWhereOrNull((c) => c.npc.id == id);
      if (c == null || c.isDead) continue;

      final pos = projection.project(c.x, c.y);
      final radius =
          (c.npc.combatStats?.radius ?? 1.5) *
          8.0; // Scale radius for visual highlight

      canvas.drawCircle(pos, radius, glowPaint);
      canvas.drawCircle(pos, radius, paint);

      // Draw a subtle line connecting targets if applicable (e.g. Arc)
      // (Skipping for now to keep it clean)
    }
  }

  @override
  bool shouldRepaint(covariant _AbilityHighlightPainter oldDelegate) => true;
}

class _WaypointMarkerPainter extends CustomPainter {
  final double pulsePercent;

  _WaypointMarkerPainter({required this.pulsePercent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Expanding pulsing ring
    final double maxRadius = size.width / 2;
    final double outerRadius = 4.0 + (maxRadius - 4.0) * pulsePercent;
    final double opacity = (1.0 - pulsePercent).clamp(0.0, 1.0);

    paint.color = Colors.tealAccent.withValues(alpha: opacity * 0.85);
    canvas.drawCircle(center, outerRadius, paint);

    // Inner core glow
    final corePaint = Paint()
      ..color = Colors.tealAccent.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4.0, corePaint);

    // Crosshair ticks
    paint.color = Colors.tealAccent.withValues(alpha: 0.9);
    paint.strokeWidth = 1.5;
    canvas.drawLine(Offset(center.dx - 8, center.dy), Offset(center.dx - 4, center.dy), paint);
    canvas.drawLine(Offset(center.dx + 4, center.dy), Offset(center.dx + 8, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - 8), Offset(center.dx, center.dy - 4), paint);
    canvas.drawLine(Offset(center.dx, center.dy + 4), Offset(center.dx, center.dy + 8), paint);
  }

  @override
  bool shouldRepaint(covariant _WaypointMarkerPainter oldDelegate) =>
      oldDelegate.pulsePercent != pulsePercent;
}

class _TacticalMinimap extends StatelessWidget {
  const _TacticalMinimap();

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    return Consumer<CombatManager>(
      builder: (context, manager, child) {
        final screenSize = MediaQuery.of(context).size;
        final projection = _CombatProjection(
          viewSize: screenSize,
          fieldScroll: manager.fieldScroll,
          yFieldScroll: manager.yFieldScroll,
          zoomFactor: manager.zoomFactor,
        );

        final pTL = projection.unproject(Offset(0, 0));
        final pTR = projection.unproject(Offset(screenSize.width, 0));
        final pBR = projection.unproject(Offset(screenSize.width, screenSize.height - 120.0));
        final pBL = projection.unproject(Offset(0, screenSize.height - 120.0));
        final viewportBounds = [pTL, pTR, pBR, pBL];

        Widget minimap = SizedBox(
          width: 80,
          height: 53,
          child: CustomPaint(
            painter: _MinimapPainter(
              combatants: manager.combatants,
              map: manager.map,
              viewportBounds: viewportBounds,
            ),
          ),
        );

        if (gameState.combatControlMode == 'click') {
          minimap = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final localPos = details.localPosition;
              const double W = 80.0;
              const double H = 53.0;
              final double cx = W / 2;
              final double cy = H / 2;

              final map = manager.map;

              // Scale factors derived from unified proportions (exact match to painter):
              final double aScale = W / (map.width * 1.33);
              final double bScale = W / (map.width * 1.24);
              final double dScale = -H / (map.height * 3.2);
              final double eScale = H / map.height;

              final double dx = localPos.dx - cx;
              final double dy = localPos.dy - cy;

              final double det = aScale * eScale - bScale * dScale;
              if (det.abs() >= 0.00001) {
                final double rx = (dx * eScale - dy * bScale) / det;
                final double ry = (-dx * dScale + dy * aScale) / det;

                final double worldX = rx + (map.width / 2);
                final double worldY = ry + (map.height / 2);

                // Now, let's handle navigation and follow rules
                final alphonse = manager.combatants.firstWhereOrNull((c) => c.npc.isPlayer);
                if (alphonse != null) {
                  // Check distance between target (worldX, worldY) and alphonse (alphonse.x, alphonse.y)
                  final dist = sqrt(pow(worldX - alphonse.x, 2) + pow(worldY - alphonse.y, 2));
                  if (dist < 25.0) {
                    // Close enough to the player character, resume follow immediately
                    manager.cameraFollowPlayer = true;
                    manager.cameraResumeFollowDelay = 0.0;
                  } else {
                    // Move camera to target, stop following, and set a significant follow delay
                    manager.moveCameraTo(worldX, worldY);
                    manager.cameraResumeFollowDelay = 3.0;
                  }
                } else {
                  manager.moveCameraTo(worldX, worldY);
                }
              }
            },
            child: minimap,
          );
        }

        return minimap;
      },
    );
  }
}

class _MinimapPainter extends CustomPainter {
  final List<Combatant> combatants;
  final CombatMap map;
  final List<Offset>? viewportBounds;

  _MinimapPainter({
    required this.combatants,
    required this.map,
    this.viewportBounds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double W = size.width;
    final double H = size.height;

    final double cx = W / 2;
    final double cy = H / 2;

    // Scale factors derived from unified proportions (exact match to battlefield viewport):
    final double aScale = W / (map.width * 1.33);
    final double bScale = W / (map.width * 1.24);
    final double dScale = -H / (map.height * 3.2);
    final double eScale = H / map.height;

    Offset project(double wx, double wy) {
      final double rx = wx - (map.width / 2);
      final double ry = wy - (map.height / 2);
      final double mx = cx + (rx * aScale + ry * bScale);
      final double my = cy + (rx * dScale + ry * eScale);
      return Offset(mx, my);
    }

    // 1. Draw diagonal track background on minimap
    final bgPaint = Paint()..color = const Color(0xFFE8DFD0)..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF8B7E66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final pTL = project(0.0, 0.0);
    final pTR = project(map.width, 0.0);
    final pBR = project(map.width, map.height);
    final pBL = project(0.0, map.height);

    final trackPath = Path()
      ..moveTo(pBL.dx, pBL.dy)
      ..lineTo(pTL.dx, pTL.dy)
      ..lineTo(pTR.dx, pTR.dy)
      ..lineTo(pBR.dx, pBR.dy)
      ..close();

    canvas.drawPath(trackPath, bgPaint);
    canvas.drawPath(trackPath, borderPaint);

    // 2. Draw centerline walls of terrain dynamically
    final wallPaint = Paint()..color = const Color(0xFF3C302A)..style = PaintingStyle.fill;

    for (final rect in map.walls) {
      final wTL = project(rect.left, rect.top);
      final wTR = project(rect.right, rect.top);
      final wBR = project(rect.right, rect.bottom);
      final wBL = project(rect.left, rect.bottom);

      final wallPath = Path()
        ..moveTo(wTL.dx, wTL.dy)
        ..lineTo(wTR.dx, wTR.dy)
        ..lineTo(wBR.dx, wBR.dy)
        ..lineTo(wBL.dx, wBL.dy)
        ..close();
      canvas.drawPath(wallPath, wallPaint);
    }

    // 3. Draw green cauldron locations dynamically
    final cauldronPaint = Paint()..color = Colors.green.shade700..style = PaintingStyle.fill;
    for (final pos in map.cauldronPositions) {
      final mPos = project(pos.dx, pos.dy);
      canvas.drawCircle(mPos, 2.0, cauldronPaint);
    }

    // 4. Draw combatants
    for (var c in combatants) {
      if (c.isDead && !c.isTower) continue;

      final mPos = project(c.x, c.y);

      Color dotColor;
      double dotRadius = 1.8;

      if (c.isTower) {
        if (c.isDead) {
          dotColor = Colors.grey.shade700;
          dotRadius = 2.8;
        } else {
          dotColor = c.side == CombatSide.player ? const Color(0xFF388E3C) : const Color(0xFFD32F2F);
          dotRadius = 3.8;
        }
      } else if (c.npc.isPlayer) {
        dotColor = Colors.tealAccent.shade700;
        dotRadius = 3.2;
      } else if (c.npc.id == 'ai_mirror') {
        dotColor = Colors.deepOrangeAccent.shade700;
        dotRadius = 3.2;
      } else {
        dotColor = c.side == CombatSide.player ? Colors.teal : Colors.orange;
      }

      canvas.drawCircle(mPos, dotRadius, Paint()..color = dotColor);
    }

    // 5. Draw camera viewport box on minimap
    if (viewportBounds != null && viewportBounds!.length == 4) {
      final vmTL = project(viewportBounds![0].dx, viewportBounds![0].dy);
      final vmTR = project(viewportBounds![1].dx, viewportBounds![1].dy);
      final vmBR = project(viewportBounds![2].dx, viewportBounds![2].dy);
      final vmBL = project(viewportBounds![3].dx, viewportBounds![3].dy);

      final viewportPath = Path()
        ..moveTo(vmBL.dx, vmBL.dy)
        ..lineTo(vmTL.dx, vmTL.dy)
        ..lineTo(vmTR.dx, vmTR.dy)
        ..lineTo(vmBR.dx, vmBR.dy)
        ..close();

      final viewportPaint = Paint()
        ..color = Colors.tealAccent.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawPath(viewportPath, viewportPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter oldDelegate) => true;
}

class _TowerRenderer extends StatelessWidget {
  final Combatant combatant;

  const _TowerRenderer({required this.combatant});

  @override
  Widget build(BuildContext context) {
    const double size = 36.0;
    return SizedBox(
      width: size,
      height: size * 1.2,
      child: CustomPaint(
        painter: _TowerShapePainter(
          towerType: combatant.towerType ?? 'wagon',
          isDead: combatant.isDead,
          side: combatant.side,
        ),
      ),
    );
  }
}

class _TowerShapePainter extends CustomPainter {
  final String towerType;
  final bool isDead;
  final CombatSide side;

  _TowerShapePainter({
    required this.towerType,
    required this.isDead,
    required this.side,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDead
          ? const Color(0xFF4A4E52) // Ruined grey
          : (side == CombatSide.player ? const Color(0xFF3C5A6F) : const Color(0xFF6B3C3C))
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF2A1B1B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (towerType.contains('wagon')) {
      // 1. Sketched Ground Shadow (crosshatched lines)
      final shadowPaint = Paint()
        ..color = const Color(0xFF1F201D).withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromLTWH(size.width * 0.02, size.height * 0.85, size.width * 0.96, size.height * 0.08),
        shadowPaint,
      );

      // Fine hatch lines for ground shading
      final hatchPaint = Paint()
        ..color = const Color(0xFF1E1F1C).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      for (double hx = size.width * 0.1; hx < size.width * 0.9; hx += 6.0) {
        canvas.drawLine(
          Offset(hx, size.height * 0.87),
          Offset(hx - 4.0, size.height * 0.91),
          hatchPaint,
        );
      }

      // 2. Menacing Sketched Front Ram (Gothic iron arrowhead spikes)
      final ironColor = isDead ? const Color(0xFF3D3E3D) : const Color(0xFF464D52);
      final metalPaint = Paint()..color = ironColor..style = PaintingStyle.fill;
      
      final isPlayer = side == CombatSide.player;
      final ramXStart = isPlayer ? size.width * 0.84 : size.width * 0.16;
      final ramXEnd = isPlayer ? size.width * 1.15 : -size.width * 0.15;
      
      final ramPath = Path();
      ramPath.moveTo(ramXStart, size.height * 0.55);
      ramPath.lineTo(ramXEnd, size.height * 0.68);
      ramPath.lineTo(ramXStart, size.height * 0.8);
      ramPath.quadraticBezierTo(isPlayer ? size.width * 0.9 : size.width * 0.1, size.height * 0.68, ramXStart, size.height * 0.55);
      ramPath.close();
      
      canvas.drawPath(ramPath, metalPaint);
      canvas.drawPath(ramPath, borderPaint..strokeWidth = 2.5);
      
      for (double sy = size.height * 0.6; sy < size.height * 0.75; sy += 4.0) {
        canvas.drawLine(
          Offset(ramXStart, sy),
          Offset(isPlayer ? ramXStart + 12 : ramXStart - 12, sy + 2.0),
          hatchPaint,
        );
      }

      // 3. Planked Carriage Body (19th-Century Wood Hatching)
      final woodColor = isDead ? const Color(0xFF2E302E) : const Color(0xFF6D5C47);
      final baseRect = Rect.fromLTWH(size.width * 0.1, size.height * 0.48, size.width * 0.8, size.height * 0.38);
      canvas.drawRect(baseRect, paint..color = woodColor);

      final grainPaint = Paint()
        ..color = const Color(0xFF1E1F1C).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      for (double py = size.height * 0.52; py < size.height * 0.84; py += 8.0) {
        canvas.drawLine(
          Offset(size.width * 0.12, py),
          Offset(size.width * 0.88, py + (py.toInt() % 3 - 1.5)),
          grainPaint,
        );
      }

      final plankPaint = Paint()
        ..color = const Color(0xFF1E1F1C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      for (double px = size.width * 0.22; px < size.width * 0.88; px += size.width * 0.13) {
        canvas.drawLine(Offset(px, size.height * 0.48), Offset(px, size.height * 0.86), plankPaint);
      }

      canvas.drawRect(Rect.fromLTWH(size.width * 0.09, size.height * 0.48, size.width * 0.07, size.height * 0.38), metalPaint);
      canvas.drawRect(Rect.fromLTWH(size.width * 0.84, size.height * 0.48, size.width * 0.07, size.height * 0.38), metalPaint);
      canvas.drawRect(Rect.fromLTWH(size.width * 0.09, size.height * 0.48, size.width * 0.07, size.height * 0.38), borderPaint..strokeWidth = 2.5);
      canvas.drawRect(Rect.fromLTWH(size.width * 0.84, size.height * 0.48, size.width * 0.07, size.height * 0.38), borderPaint..strokeWidth = 2.5);

      canvas.drawRect(Rect.fromLTWH(size.width * 0.1, size.height * 0.74, size.width * 0.8, size.height * 0.07), metalPaint);
      canvas.drawRect(Rect.fromLTWH(size.width * 0.1, size.height * 0.74, size.width * 0.8, size.height * 0.07), borderPaint..strokeWidth = 2.5);

      final rivetPaint = Paint()..color = const Color(0xFF1E1F1C)..style = PaintingStyle.fill;
      for (double rx = size.width * 0.18; rx < size.width * 0.86; rx += size.width * 0.13) {
        canvas.drawCircle(Offset(rx, size.height * 0.775), 2.0, rivetPaint);
      }

      canvas.drawRect(baseRect, borderPaint..strokeWidth = 3.0);

      // 4. Gothic Canvas Canopy (Vintage Parchment Cover)
      final canopyColor = isDead ? const Color(0xFF222422) : const Color(0xFFDFD7C8);
      final canopyPath = Path()
        ..moveTo(size.width * 0.07, size.height * 0.5)
        ..quadraticBezierTo(size.width * 0.5, -size.height * 0.02, size.width * 0.93, size.height * 0.5)
        ..close();
      canvas.drawPath(canopyPath, paint..color = canopyColor);

      final ribPaint = Paint()
        ..color = const Color(0xFF1E1F1C).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      for (double rx = size.width * 0.18; rx < size.width * 0.9; rx += size.width * 0.18) {
        final ribPath = Path()
          ..moveTo(rx, size.height * 0.5)
          ..quadraticBezierTo(size.width * 0.5, size.height * 0.04, rx, size.height * 0.5);
        canvas.drawPath(ribPath, ribPaint);
      }

      for (double rx = size.width * 0.15; rx < size.width * 0.85; rx += 8.0) {
        final ry = size.height * 0.32;
        canvas.drawLine(Offset(rx, ry), Offset(rx - 3.0, ry + 6.0), hatchPaint);
      }

      canvas.drawPath(canopyPath, borderPaint..strokeWidth = 3.0);

      // 5. Heavy Gothic Cannon/Iron Barrel & Port Opening
      if (!isDead) {
        final portRect = Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.62),
          width: size.width * 0.22,
          height: size.height * 0.15,
        );
        canvas.drawRect(portRect, Paint()..color = const Color(0xFF1A1A1A));
        canvas.drawRect(portRect, borderPaint..strokeWidth = 2.0);

        canvas.drawRect(portRect, Paint()..color = Colors.transparent..style = PaintingStyle.stroke..strokeWidth = 4.0);

        final double gunY = size.height * 0.62;
        final double gunStartX = size.width * 0.5;
        final double gunEndX = isPlayer ? size.width * 1.22 : -size.width * 0.22;
        
        final gunPaint = Paint()..color = const Color(0xFF2B2E30)..style = PaintingStyle.fill;
        final gunRect = Rect.fromLTRB(
          isPlayer ? gunStartX : gunEndX,
          gunY - 4.0,
          isPlayer ? gunEndX : gunStartX,
          gunY + 4.0,
        );
        canvas.drawRect(gunRect, gunPaint);
        canvas.drawRect(gunRect, borderPaint..strokeWidth = 2.5);

        final muzzleRect = Rect.fromLTRB(
          isPlayer ? gunEndX - 5 : gunEndX,
          gunY - 6.0,
          isPlayer ? gunEndX : gunEndX + 5,
          gunY + 6.0,
        );
        canvas.drawRect(muzzleRect, gunPaint);
        canvas.drawRect(muzzleRect, borderPaint..strokeWidth = 2.5);
        
        canvas.drawLine(
          Offset(isPlayer ? gunStartX + 12 : gunStartX - 12, gunY - 2),
          Offset(isPlayer ? gunEndX - 8 : gunEndX + 8, gunY - 2),
          hatchPaint,
        );
      }

      // 6. Intricate Multi-Spoke Spiked Wheels
      final wheelWoodColor = isDead ? const Color(0xFF1F201D) : const Color(0xFF4A3D2E);
      final wheelIronColor = isDead ? const Color(0xFF1A1B1A) : const Color(0xFF34495E);

      void drawSketchedWheel(double cx, double cy, double radius) {
        canvas.drawCircle(Offset(cx, cy), radius, paint..color = wheelWoodColor);
        
        final spokePaint = Paint()
          ..color = const Color(0xFF1E1F1C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8;
        for (int i = 0; i < 12; i++) {
          final angle = i * pi / 6;
          canvas.drawLine(
            Offset(cx, cy),
            Offset(cx + radius * cos(angle), cy + radius * sin(angle)),
            spokePaint,
          );
        }

        canvas.drawCircle(Offset(cx, cy), radius, borderPaint..strokeWidth = 4.0);
        canvas.drawCircle(
          Offset(cx, cy),
          radius,
          Paint()
            ..color = wheelIronColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );

        canvas.drawCircle(Offset(cx, cy), radius * 0.35, Paint()..color = wheelIronColor..style = PaintingStyle.fill);
        canvas.drawCircle(Offset(cx, cy), radius * 0.35, borderPaint..strokeWidth = 2.0);

        final wheelHatch = Paint()
          ..color = const Color(0xFF1E1F1C).withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(Offset(cx, cy), radius * 0.7, wheelHatch);

        for (int i = 0; i < 4; i++) {
          final angle = i * pi / 2 + pi / 4;
          final spikePath = Path();
          final sx = cx + radius * cos(angle);
          final sy = cy + radius * sin(angle);
          spikePath.moveTo(sx, sy);
          spikePath.lineTo(cx + (radius + 5) * cos(angle - 0.1), cy + (radius + 5) * sin(angle - 0.1));
          spikePath.lineTo(cx + (radius + 5) * cos(angle + 0.1), cy + (radius + 5) * sin(angle + 0.1));
          spikePath.close();
          canvas.drawPath(spikePath, Paint()..color = isDead ? Colors.grey.shade800 : const Color(0xFF7F8C8D));
          canvas.drawPath(spikePath, borderPaint..strokeWidth = 1.5);
        }
      }

      drawSketchedWheel(size.width * 0.25, size.height * 0.82, 14.5);
      drawSketchedWheel(size.width * 0.75, size.height * 0.82, 14.5);
    } else if (towerType.contains('den')) {
      // Nest/Den: organic dome
      final denPath = Path()
        ..moveTo(0.0, size.height * 0.9)
        ..quadraticBezierTo(size.width * 0.5, size.height * 0.1, size.width, size.height * 0.9)
        ..close();
      canvas.drawPath(denPath, paint..color = isDead ? const Color(0xFF2B201A) : const Color(0xFF5D4037));
      canvas.drawPath(denPath, borderPaint);

      // Den opening
      canvas.drawOval(
        Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.75), width: size.width * 0.3, height: size.height * 0.2),
        Paint()..color = Colors.black87,
      );
    } else if (towerType.contains('tower_house')) {
      // Tall rectangular Tower House with crenellations
      final towerRect = Rect.fromLTWH(size.width * 0.15, size.height * 0.1, size.width * 0.7, size.height * 0.8);
      canvas.drawRect(towerRect, paint);
      canvas.drawRect(towerRect, borderPaint);

      // Windows
      final windowPaint = Paint()..color = Colors.black87..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(size.width * 0.35, size.height * 0.3, 8, 14), windowPaint);
      canvas.drawRect(Rect.fromLTWH(size.width * 0.55, size.height * 0.3, 8, 14), windowPaint);
    } else {
      // Fortification / Castle Keep
      final keepPath = Path()
        ..moveTo(0.0, size.height * 0.9)
        ..lineTo(0.0, size.height * 0.2)
        ..lineTo(size.width * 0.2, size.height * 0.2)
        ..lineTo(size.width * 0.2, size.height * 0.3)
        ..lineTo(size.width * 0.4, size.height * 0.3)
        ..lineTo(size.width * 0.4, size.height * 0.2)
        ..lineTo(size.width * 0.6, size.height * 0.2)
        ..lineTo(size.width * 0.6, size.height * 0.3)
        ..lineTo(size.width * 0.8, size.height * 0.3)
        ..lineTo(size.width * 0.8, size.height * 0.2)
        ..lineTo(size.width, size.height * 0.2)
        ..lineTo(size.width, size.height * 0.9)
        ..close();
      canvas.drawPath(keepPath, paint);
      canvas.drawPath(keepPath, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TowerShapePainter oldDelegate) => true;
}

class _ImpliedJoystick extends StatefulWidget {
  final Function(double dx, double dy) onJoystickUpdate;

  const _ImpliedJoystick({required this.onJoystickUpdate});

  @override
  State<_ImpliedJoystick> createState() => _ImpliedJoystickState();
}

class _ImpliedJoystickState extends State<_ImpliedJoystick> {
  Offset _touchStart = Offset.zero;
  static const double maxDragDistance = 35.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _touchStart = details.localPosition;
        });
      },
      onPanUpdate: (details) {
        final localPos = details.localPosition - _touchStart;
        final distance = localPos.distance;
        final dragOffset = distance <= maxDragDistance
            ? localPos
            : Offset.fromDirection(localPos.direction, maxDragDistance);

        final normalizedX = dragOffset.dx / maxDragDistance;
        final normalizedY = dragOffset.dy / maxDragDistance;
        widget.onJoystickUpdate(normalizedX, normalizedY);
      },
      onPanEnd: (_) {
        widget.onJoystickUpdate(0.0, 0.0);
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: const Color(0x115D4037), width: 1.0),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            'MOVE',
            style: GoogleFonts.oldStandardTt(
              color: Colors.white24,
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecialAbilityButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isCharged;
  final VoidCallback onPressed;

  const _SpecialAbilityButton({
    required this.label,
    required this.icon,
    required this.isCharged,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isCharged ? const Color(0xFFD4AF37) : const Color(0xFF5D4037);
    
    return GestureDetector(
      onTap: isCharged ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isCharged ? Colors.black.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.3),
          border: Border.all(color: activeColor, width: isCharged ? 3.5 : 1.5),
          boxShadow: isCharged
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            icon,
            color: isCharged ? const Color(0xFFD4AF37) : Colors.white30,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _CauldronSprite extends StatelessWidget {
  final HealingCauldron cauldron;

  const _CauldronSprite({
    required this.cauldron,
  });

  @override
  Widget build(BuildContext context) {
    final double scale = (0.8 + (cauldron.y / CombatManager.fieldWidth) * 0.4) * 1.3;

    return Transform.scale(
      scale: scale,
      child: SizedBox(
        width: 60,
        height: 80,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 0,
              child: Container(
                width: 36,
                height: 10,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.elliptical(18, 5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              child: CustomPaint(
                size: const Size(40, 36),
                painter: _CauldronPainter(),
              ),
            ),
            Positioned(
              top: 6,
              child: _HeartIcon(
                isAvailable: cauldron.isAvailable,
                progress: cauldron.rechargeProgress,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CauldronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFF2A1B1B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final bodyPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.fill;

    final soupPaint = Paint()
      ..color = const Color(0xFFD84315)
      ..style = PaintingStyle.fill;

    canvas.drawLine(Offset(size.width * 0.25, size.height * 0.7), Offset(size.width * 0.15, size.height), borderPaint..strokeWidth = 3.0);
    canvas.drawLine(Offset(size.width * 0.75, size.height * 0.7), Offset(size.width * 0.85, size.height), borderPaint..strokeWidth = 3.0);

    final potRect = Rect.fromLTWH(0, size.height * 0.15, size.width, size.height * 0.65);
    canvas.drawOval(potRect, bodyPaint);
    canvas.drawOval(potRect, borderPaint..strokeWidth = 2.0);

    final rimRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.2),
      width: size.width * 1.05,
      height: size.height * 0.12,
    );
    canvas.drawOval(rimRect, Paint()..color = const Color(0xFF2D1B18));
    canvas.drawOval(rimRect, borderPaint..strokeWidth = 2.0);

    final soupRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.2),
      width: size.width * 0.95,
      height: size.height * 0.08,
    );
    canvas.drawOval(soupRect, soupPaint);

    final bubblePaint = Paint()..color = const Color(0xFFFFAB91)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.2), 2.0, bubblePaint);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.19), 1.5, bubblePaint);
    canvas.drawCircle(Offset(size.width * 0.48, size.height * 0.21), 2.5, bubblePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _HeartIcon extends StatelessWidget {
  final bool isAvailable;
  final double progress;

  const _HeartIcon({required this.isAvailable, required this.progress});

  @override
  Widget build(BuildContext context) {
    if (isAvailable) {
      return const Icon(
        Icons.favorite,
        color: Colors.red,
        size: 24,
      );
    } else {
      final double currentScale = 0.3 + (progress * 0.6);
      return Transform.scale(
        scale: currentScale,
        child: const Icon(
          Icons.favorite,
          color: Colors.amber,
          size: 24,
        ),
      );
    }
  }
}

class _CombatNotification {
  final String id;
  final String message;
  final Color backgroundColor;
  final Duration duration;

  _CombatNotification({
    required this.id,
    required this.message,
    required this.backgroundColor,
    required this.duration,
  });
}

class _CombatNotificationWidget extends StatelessWidget {
  final _CombatNotification notification;
  const _CombatNotificationWidget({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: notification.backgroundColor.withValues(alpha: 0.9),
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.8),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Text(
        notification.message,
        style: GoogleFonts.oldStandardTt(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _TrackpadBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const double cornerLength = 16.0;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, 0)
        ..lineTo(cornerLength, 0),
      paint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width, cornerLength)
        ..lineTo(size.width, 0)
        ..lineTo(size.width - cornerLength, 0),
      paint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLength)
        ..lineTo(0, size.height)
        ..lineTo(cornerLength, size.height),
      paint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - cornerLength)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width - cornerLength, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlacementIndicatorPainter extends CustomPainter {
  final NPC npc;
  final Offset screenPos;
  final _CombatProjection projection;
  final CombatManager manager;

  _PlacementIndicatorPainter({
    required this.npc,
    required this.screenPos,
    required this.projection,
    required this.manager,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stats = npc.combatStats;
    if (stats == null) return;

    final worldPos = projection.unproject(screenPos);
    final double worldX = worldPos.dx;
    final double worldY = worldPos.dy.clamp(0.0, manager.map.height);

    // Determine validation state
    final bool isValid = manager.isValidPlacement(npc, worldX, worldY);
    final isSupport = npc.name.contains('Barrage') || npc.name.contains('Artillery') || npc.name.contains('Gas') || npc.name.contains('Tear') || npc.name.contains('Caltrops') || npc.name.contains('Totem') || stats.unitType == UnitType.support;

    final paint = Paint()
      ..color = isValid ? Colors.green.withValues(alpha: 0.35) : Colors.red.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = isValid ? Colors.green : Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    if (isSupport) {
      // Render support area of effect shape
      if (npc.name.contains('Barrage') || npc.name.contains('Artillery')) {
        // Reduced footprint rectangle (reduced width and length by half)
        final rectWidth = manager.map.width * 0.375;
        final rectHeight = (manager.map.height / manager.map.laneCenters.length) * 0.5;
        
        final double leftX = (worldX - rectWidth / 2.0).clamp(0.0, manager.map.width);
        final double rightX = (worldX + rectWidth / 2.0).clamp(0.0, manager.map.width);
        
        // Center the rectangle vertically on the closest lane to make it perfectly aligned to the lane
        double closestLaneY = manager.map.laneCenters.first;
        double minDist = 99999.0;
        for (final ly in manager.map.laneCenters) {
          final dist = (worldY - ly).abs();
          if (dist < minDist) {
            minDist = dist;
            closestLaneY = ly;
          }
        }
        final double topY = (closestLaneY - rectHeight / 2.0).clamp(0.0, manager.map.height);
        final double bottomY = (closestLaneY + rectHeight / 2.0).clamp(0.0, manager.map.height);

        final pTL = projection.project(leftX, topY);
        final pTR = projection.project(rightX, topY);
        final pBR = projection.project(rightX, bottomY);
        final pBL = projection.project(leftX, bottomY);

        final path = Path()
          ..moveTo(pTL.dx, pTL.dy)
          ..lineTo(pTR.dx, pTR.dy)
          ..lineTo(pBR.dx, pBR.dy)
          ..lineTo(pBL.dx, pBL.dy)
          ..close();

        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
      } else if (npc.name.contains('Gas') || npc.name.contains('Tear')) {
        final path = Path();
        const double radius = 15.0;
        for (int i = 0; i < 32; i++) {
          final double angle = i * (2.0 * pi / 32.0);
          final double wx = worldX + cos(angle) * radius;
          final double wy = worldY + sin(angle) * radius;
          final p = projection.project(wx, wy);
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
      } else if (npc.name.contains('Caltrops')) {
        const double halfSize = 15.0; // 30.0 feet total side length (slightly larger)
        final p1 = projection.project(worldX - halfSize, worldY - halfSize);
        final p2 = projection.project(worldX + halfSize, worldY - halfSize);
        final p3 = projection.project(worldX + halfSize, worldY + halfSize);
        final p4 = projection.project(worldX - halfSize, worldY + halfSize);

        final path = Path()
          ..moveTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..lineTo(p3.dx, p3.dy)
          ..lineTo(p4.dx, p4.dy)
          ..close();

        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
      } else {
        // Default circular support shape (Totems, etc.)
        final center = projection.project(worldX, worldY);
        final radius = 15.0 * projection.zoomFactor;
        canvas.drawCircle(center, radius, paint);
        canvas.drawCircle(center, radius, strokePaint);
      }
    } else {
      // Render troop squad bases
      final double myRadius = stats.radius * projection.zoomFactor;
      
      // 1. Leader base
      final leaderCenter = projection.project(worldX, worldY);
      canvas.drawCircle(leaderCenter, myRadius, paint);
      canvas.drawCircle(leaderCenter, myRadius, strokePaint);

      // 2. Followers bases
      if (stats.unitCount > 1) {
        final followersCount = stats.unitCount - 1;
        for (int i = 0; i < followersCount; i++) {
          final offset = _getFormationOffsetHelper(i);
          final followerWorldX = worldX + offset.dx;
          final followerWorldY = (worldY + offset.dy).clamp(2.0, manager.map.height - 2.0);
          final followerCenter = projection.project(followerWorldX, followerWorldY);
          canvas.drawCircle(followerCenter, myRadius, paint);
          canvas.drawCircle(followerCenter, myRadius, strokePaint);
        }
      }
    }
  }

  Offset _getFormationOffsetHelper(int index) {
    switch (index) {
      case 0: return const Offset(-2.5, -2.5);
      case 1: return const Offset(-2.5, 2.5);
      case 2: return const Offset(-5.0, -5.0);
      case 3: return const Offset(-5.0, 5.0);
      case 4: return const Offset(-7.5, 0.0);
      case 5: return const Offset(-7.5, -2.5);
      case 6: return const Offset(-7.5, 2.5);
      case 7: return const Offset(-10.0, 0.0);
      default: return Offset(-2.5 * (index ~/ 2 + 1).toDouble(), (index % 2 == 0 ? -2.5 : 2.5));
    }
  }

  @override
  bool shouldRepaint(covariant _PlacementIndicatorPainter oldDelegate) {
    return oldDelegate.npc.id != npc.id || oldDelegate.screenPos != screenPos;
  }
}

class _CombatMenuButton extends StatelessWidget {
  final VoidCallback showMenuDialog;

  const _CombatMenuButton({required this.showMenuDialog});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: showMenuDialog,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            border: Border.all(
              color: const Color(0xFFC4B89B).withValues(alpha: 0.5),
              width: 1.5,
            ),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: const Icon(
            Icons.settings,
            color: Color(0xFFE5D5B0),
            size: 16,
          ),
        ),
      ),
    );
  }
}

void _showCombatMenuDialog(BuildContext context) {
  final gameState = Provider.of<GameState>(context, listen: false);
  final screenState = context.findAncestorStateOfType<_CombatScreenState>();
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: const Color(0xFF1A1612),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Color(0xFFC4B89B), width: 1.5),
        ),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'COMBAT MENU',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Divider(color: Colors.white10, height: 20),
              _buildMenuButton(
                context,
                'LOAD GAME',
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final data = await SaveService.loadGame(slot: 1);
                  if (data != null) {
                    gameState.loadFromJson(data);
                    navigator.pop(); // close dialog
                    navigator.pop(); // close combat screen
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildMenuButton(
                context,
                'ATTEMPT TO FLEE',
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  final success = Random().nextDouble() < 0.5;
                  if (success) {
                    gameState.clearEncounterState();
                    Navigator.of(context).pop(); // close combat screen
                    screenState?._showNotification('FLEED TO SAFETY', Colors.green.shade800);
                  } else {
                    screenState?._showNotification('FLEE ATTEMPT FAILED! THE ENEMY PURSUES!', Colors.red.shade900);
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildMenuButton(
                context,
                'GAME OPTIONS',
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  showDialog(
                    context: context,
                    builder: (context) => const OptionsDialog(),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildMenuButton(
                context,
                'QUIT TO MAIN MENU',
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  gameState.clearEncounterState();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildMenuButton(BuildContext context, String label, {required VoidCallback onPressed}) {
  return SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFE5D5B0),
        side: const BorderSide(color: Color(0xFFC4B89B)),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          fontSize: 12,
        ),
      ),
    ),
  );
}



class _CaltropsVisual extends StatelessWidget {
  final Combatant combatant;
  final _CombatProjection projection;

  const _CaltropsVisual({
    required this.combatant,
    required this.projection,
  });

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<CombatManager>(context, listen: false);
    final map = manager.map;
    final isDeploying = combatant.activeDeploymentTimer > 0.0;

    if (isDeploying) {
      return CustomPaint(
        painter: _SupportDeployPainter(
          isCircle: false,
          progress: 1.0 - (combatant.activeDeploymentTimer / 3.0),
          label: 'PREPARING CALTROPS',
          combatant: combatant,
          projection: projection,
          map: map,
        ),
        child: Center(
          child: Text(
            'PREPARING: ${combatant.activeDeploymentTimer.toStringAsFixed(1)}s',
            style: GoogleFonts.oswald(
              color: const Color(0xFFFFB300),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
            ),
          ),
        ),
      );
    }

    return CustomPaint(
      painter: _CaltropsPainter(
        combatant: combatant,
        projection: projection,
      ),
    );
  }
}

class _CaltropsPainter extends CustomPainter {
  final Combatant combatant;
  final _CombatProjection projection;

  _CaltropsPainter({
    required this.combatant,
    required this.projection,
  });

  double seededRandom(int seed) {
    return (sin(seed * 12.9898 + 78.233) * 43758.5453).abs() % 1.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double halfSize = 15.0; // 30.0 feet total side length (slightly larger)

    // Corner projection
    final p1 = projection.project(combatant.x - halfSize, combatant.y - halfSize);
    final p2 = projection.project(combatant.x + halfSize, combatant.y - halfSize);
    final p3 = projection.project(combatant.x + halfSize, combatant.y + halfSize);
    final p4 = projection.project(combatant.x - halfSize, combatant.y + halfSize);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    // Rusted ground overlay
    final basePaint = Paint()
      ..color = const Color(0xFF795548).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, basePaint);

    // Draw sharp scattered spikes inside the projected polygon
    final spikePaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    for (int i = 0; i < 24; i++) {
      final rx = seededRandom(i * 41);
      final ry = seededRandom(i * 73);

      // Map deterministic random factor inside the world square
      final wx = combatant.x - halfSize + rx * 30.0;
      final wy = combatant.y - halfSize + ry * 30.0;

      // Project spike center to screen
      final pCenter = projection.project(wx, wy);
      final cx = pCenter.dx;
      final cy = pCenter.dy;

      const double spikeLen = 4.0;
      canvas.drawLine(Offset(cx - spikeLen, cy), Offset(cx + spikeLen, cy), spikePaint);
      canvas.drawLine(Offset(cx, cy - spikeLen), Offset(cx, cy + spikeLen), spikePaint);
      canvas.drawLine(Offset(cx - spikeLen/2.0, cy - spikeLen/2.0), Offset(cx + spikeLen/2.0, cy + spikeLen/2.0), spikePaint);
    }

    // Weak pulsing dashed warning outline around the projected path
    final borderPaint = Paint()
      ..color = const Color(0xFFFF8F00).withValues(alpha: 0.25 + 0.1 * sin(DateTime.now().millisecondsSinceEpoch * 0.005))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CaltropsPainter oldDelegate) => true;
}

class _ArtilleryVisual extends StatelessWidget {
  final Combatant combatant;
  final _CombatProjection projection;

  const _ArtilleryVisual({
    required this.combatant,
    required this.projection,
  });

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<CombatManager>(context, listen: false);
    final map = manager.map;
    final isDeploying = combatant.activeDeploymentTimer > 0.0;

    if (isDeploying) {
      return CustomPaint(
        painter: _SupportDeployPainter(
          isCircle: false,
          progress: 1.0 - (combatant.activeDeploymentTimer / 3.0),
          label: 'INCOMING BARRAGE',
          combatant: combatant,
          projection: projection,
          map: map,
        ),
        child: Center(
          child: Text(
            'INCOMING: ${combatant.activeDeploymentTimer.toStringAsFixed(1)}s',
            style: GoogleFonts.oswald(
              color: const Color(0xFFFF3D00),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
            ),
          ),
        ),
      );
    }

    return CustomPaint(
      painter: _ArtilleryBarragePainter(
        combatant: combatant,
        projection: projection,
        map: map,
      ),
    );
  }
}

class _TearGasVisual extends StatelessWidget {
  final Combatant combatant;
  final _CombatProjection projection;

  const _TearGasVisual({
    required this.combatant,
    required this.projection,
  });

  @override
  Widget build(BuildContext context) {
    final manager = Provider.of<CombatManager>(context, listen: false);
    final map = manager.map;
    final isDeploying = combatant.activeDeploymentTimer > 0.0;

    if (isDeploying) {
      final maxDeployTime = combatant.npc.combatStats?.deploymentTime ?? 1.5;
      return CustomPaint(
        painter: _SupportDeployPainter(
          isCircle: true,
          progress: (1.0 - (combatant.activeDeploymentTimer / maxDeployTime)).clamp(0.0, 1.0),
          label: 'INCOMING TEAR GAS',
          combatant: combatant,
          projection: projection,
          map: map,
        ),
        child: Center(
          child: Text(
            'INCOMING: ${combatant.activeDeploymentTimer.toStringAsFixed(1)}s',
            style: GoogleFonts.oswald(
              color: const Color(0xFF8BC34A),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
            ),
          ),
        ),
      );
    }

    return CustomPaint(
      painter: _TearGasPainter(
        combatant: combatant,
        projection: projection,
      ),
    );
  }
}

class _SupportDeployPainter extends CustomPainter {
  final bool isCircle;
  final double progress;
  final String label;
  final Combatant combatant;
  final _CombatProjection projection;
  final CombatMap map;

  _SupportDeployPainter({
    required this.isCircle,
    required this.progress,
    required this.label,
    required this.combatant,
    required this.projection,
    required this.map,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF3D00).withValues(alpha: 0.15 + 0.05 * sin(DateTime.now().millisecondsSinceEpoch * 0.01))
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFFF3D00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    if (isCircle) {
      final pCenter = projection.project(combatant.x, combatant.y);
      final screenRadius = 15.0 * projection.zoomFactor;

      canvas.drawCircle(pCenter, screenRadius, paint);
      canvas.drawCircle(pCenter, screenRadius, borderPaint);

      final progressPaint = Paint()
        ..color = Colors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawArc(
        Rect.fromCircle(center: pCenter, radius: screenRadius - 2),
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );
    } else {
      final bool isCaltrops = combatant.npc.name.contains('Caltrops');
      
      double rectWidth = 0.0;
      double rectHeight = 0.0;

      if (isCaltrops) {
        rectWidth = 30.0;
        rectHeight = 30.0;
      } else {
        rectWidth = map.width * 0.375;
        rectHeight = (map.height / map.laneCenters.length) * 0.5;
      }

      final double halfW = rectWidth / 2.0;
      final double halfH = rectHeight / 2.0;

      final p1 = projection.project(combatant.x - halfW, combatant.y - halfH);
      final p2 = projection.project(combatant.x + halfW, combatant.y - halfH);
      final p3 = projection.project(combatant.x + halfW, combatant.y + halfH);
      final p4 = projection.project(combatant.x - halfW, combatant.y + halfH);

      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..lineTo(p4.dx, p4.dy)
        ..close();

      canvas.drawPath(path, paint);
      canvas.drawPath(path, borderPaint);

      final progressPaint = Paint()
        ..color = Colors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      final Offset progressEnd = Offset(
        p4.dx + (p3.dx - p4.dx) * progress,
        p4.dy + (p3.dy - p4.dy) * progress,
      );

      canvas.drawLine(p4, progressEnd, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SupportDeployPainter oldDelegate) => true;
}

class _ArtilleryBarragePainter extends CustomPainter {
  final Combatant combatant;
  final _CombatProjection projection;
  final CombatMap map;

  _ArtilleryBarragePainter({
    required this.combatant,
    required this.projection,
    required this.map,
  });

  double seededRandom(int seed) {
    return (sin(seed * 12.9898 + 78.233) * 43758.5453).abs() % 1.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double elapsed = 3.0 - combatant.supportDurationRemaining;

    final rectWidth = map.width * 0.375;
    final rectHeight = (map.height / map.laneCenters.length) * 0.5;

    final double halfW = rectWidth / 2.0;
    final double halfH = rectHeight / 2.0;

    final p1 = projection.project(combatant.x - halfW, combatant.y - halfH);
    final p2 = projection.project(combatant.x + halfW, combatant.y - halfH);
    final p3 = projection.project(combatant.x + halfW, combatant.y + halfH);
    final p4 = projection.project(combatant.x - halfW, combatant.y + halfH);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    // 1. Draw scorched earth background
    final scorchPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, scorchPaint);

    // Draw soft charcoal spots inside the projected bounds
    for (int i = 0; i < 8; i++) {
      final rx = seededRandom(i * 17);
      final ry = seededRandom(i * 29);
      final rRadius = (12.0 + rx * 20.0) * projection.zoomFactor;

      final wx = combatant.x - halfW + rx * rectWidth;
      final wy = combatant.y - halfH + ry * rectHeight;
      final pSpot = projection.project(wx, wy);

      final spotPaint = Paint()
        ..color = const Color(0xFF111111).withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(pSpot, rRadius, spotPaint);
    }

    // 2. Draw dynamic explosion waves
    for (int i = 0; i < 14; i++) {
      final double birthTime = i * 0.18;
      if (elapsed < birthTime) continue;

      final double age = elapsed - birthTime;
      const double duration = 0.45;

      final int cycle = (age / duration).floor();
      final double cycleAge = age % duration;

      // Position seed based on index and cycle
      final rx = seededRandom(i * 53 + cycle * 19);
      final ry = seededRandom(i * 67 + cycle * 31);

      final wx = combatant.x - halfW + rx * rectWidth;
      final wy = combatant.y - halfH + ry * rectHeight;
      final pExplosion = projection.project(wx, wy);

      _drawSingleExplosion(canvas, pExplosion.dx, pExplosion.dy, rx, cycleAge / duration);
    }
  }

  void _drawSingleExplosion(Canvas canvas, double cx, double cy, double rx, double t) {
    final double maxRadius = (15.0 + rx * 18.0) * projection.zoomFactor;
    final double currentRadius = t < 0.25 ? maxRadius * (t / 0.25) : maxRadius + (t - 0.25) * 5.0;

    // 1. Shockwave ring
    if (t > 0.05 && t < 0.8) {
      final shockPaint = Paint()
        ..color = Colors.white.withValues(alpha: (1.0 - t) * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(cx, cy), maxRadius * 1.4 * t, shockPaint);
    }

    // 2. Fireball layers
    if (t < 0.35) {
      // Core expansion phase: bright yellow/white hot core
      final corePaint = Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(cx, cy), currentRadius * 0.4, corePaint);

      final midPaint = Paint()
        ..color = const Color(0xFFFFEB3B) // Bright Yellow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(cx, cy), currentRadius * 0.75, midPaint);

      final outerPaint = Paint()
        ..color = const Color(0xFFFF3D00) // Deep Orange
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(cx, cy), currentRadius, outerPaint);
    } else {
      // Dissipation and smoke phase: transitions to dark orange/red and then charcoal gray
      final double smokeT = (t - 0.35) / 0.65;
      final Color smokeColor = Color.lerp(
        const Color(0xFFFF5722), // Orange-Red
        const Color(0xFF2E2E2E), // Dark grey smoke
        smokeT,
      )!.withValues(alpha: (1.0 - smokeT) * 0.85);

      final smokePaint = Paint()
        ..color = smokeColor
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 + smokeT * 6.0);
      canvas.drawCircle(Offset(cx, cy), currentRadius * (1.0 + smokeT * 0.25), smokePaint);

      // Little leftover glowing ember core
      if (smokeT < 0.5) {
        final emberPaint = Paint()
          ..color = const Color(0xFFFFC107).withValues(alpha: (1.0 - smokeT * 2.0) * 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(Offset(cx, cy), currentRadius * 0.25, emberPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ArtilleryBarragePainter oldDelegate) {
    return oldDelegate.combatant.supportDurationRemaining != combatant.supportDurationRemaining;
  }
}

class _TearGasPainter extends CustomPainter {
  final Combatant combatant;
  final _CombatProjection projection;

  _TearGasPainter({
    required this.combatant,
    required this.projection,
  });

  double seededRandom(int seed) {
    return (sin(seed * 12.9898 + 78.233) * 43758.5453).abs() % 1.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const double radius = 15.0; // 15.0 feet world radius matching placement area

    // 1. Draw visible circle of effect area - beautiful semi-transparent green circular dome
    final basePaint = Paint()
      ..color = const Color(0xFF689F38).withValues(alpha: 0.18) // Vibrant green dome overlay
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    final basePath = Path();
    for (int i = 0; i < 32; i++) {
      final double angle = i * (2.0 * pi / 32.0);
      final double wx = combatant.x + cos(angle) * radius;
      final double wy = combatant.y + sin(angle) * radius;
      final p = projection.project(wx, wy);
      if (i == 0) {
        basePath.moveTo(p.dx, p.dy);
      } else {
        basePath.lineTo(p.dx, p.dy);
      }
    }
    basePath.close();
    canvas.drawPath(basePath, basePaint);

    // 2. Elapsed duration (6.0 seconds total)
    final double elapsed = 6.0 - combatant.supportDurationRemaining;

    // 3. Render 32 dynamic dense rolling green smoke puffs to fill the dome area
    for (int i = 0; i < 32; i++) {
      final rx = seededRandom(i * 37);
      final ry = seededRandom(i * 47);

      // Angled path emanating from center in world space
      final double angle = i * (2.0 * pi / 32.0) + rx * 0.3;
      
      // Compute expansion progress (0.0 near center to 1.0 at radius)
      final double speed = 0.2 + ry * 0.25;
      final double offset = rx;
      final double dist = ((elapsed * speed) + offset) % 1.0;

      // Calculate coordinates flowing outward within the world radius
      final double wx = combatant.x + cos(angle) * (dist * radius);
      final double wy = combatant.y + sin(angle) * (dist * radius);

      // Project puff center to screen coordinates
      final pPuff = projection.project(wx, wy);
      final cx = pPuff.dx;
      final cy = pPuff.dy;

      // Puff radius grows as it rolls outward
      final double puffRadius = (radius * (0.2 + dist * 0.4)) * projection.zoomFactor;

      // Opacity fades out near boundary
      final double opacity = (1.0 - dist) * 0.28;

      final puffPaint = Paint()
        ..color = Color.lerp(
          const Color(0xFF4CAF50), // Herbal vibrant green smoke
          const Color(0xFFCDDC39), // Lime yellow-green chemical mist
          rx,
        )!.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0 + dist * 5.0);

      canvas.drawCircle(Offset(cx, cy), puffRadius, puffPaint);
    }

    // 4. Draw circular boundary border indicator ring - distinct glowing neon green line
    final borderPulse = 0.4 + 0.2 * sin(DateTime.now().millisecondsSinceEpoch * 0.006);
    final borderPaint = Paint()
      ..color = const Color(0xFFCDDC39).withValues(alpha: borderPulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final borderPath = Path();
    for (int i = 0; i < 32; i++) {
      final double angle = i * (2.0 * pi / 32.0);
      final double wx = combatant.x + cos(angle) * radius;
      final double wy = combatant.y + sin(angle) * radius;
      final p = projection.project(wx, wy);
      if (i == 0) {
        borderPath.moveTo(p.dx, p.dy);
      } else {
        borderPath.lineTo(p.dx, p.dy);
      }
    }
    borderPath.close();
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _TearGasPainter oldDelegate) => true;
}
