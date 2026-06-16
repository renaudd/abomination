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
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'state/game_state.dart';
import 'services/audio_service.dart';
import 'services/game_engine.dart';
import 'ui/screens/loading_screen.dart';
import 'ui/screens/records_screen.dart';
import 'ui/screens/world_map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint("CRITICAL FLUTTER ERROR: ${details.exception}\n${details.stack}");
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint("CRITICAL PLATFORM ERROR: $error\n$stack");
    return true;
  };

  GoogleFonts.config.allowRuntimeFetching = false;

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final audioService = AudioService();
  if (!kIsWeb) {
    await audioService.initialize();
  }

  final gameState = GameState();
  globalGameState = gameState;
  final gameEngine = GameEngine(gameState);

  // Play placeholder bleak music (user can replace URL)
  // audioService.playBGM('https://example.com/sorcerers_apprentice.mp3', isAsset: false);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: gameState),
        Provider.value(value: gameEngine),
      ],
      child: const AbominationApp(),
    ),
  );
}

VoidCallback? onGameLoadingComplete;

GameState? globalGameState;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AbominationApp extends StatefulWidget {
  const AbominationApp({super.key});

  @override
  State<AbominationApp> createState() => _AbominationAppState();
}

class _AbominationAppState extends State<AbominationApp> {
  late final FocusNode _globalFocusNode;
  bool _isFullyLoaded = false;

  @override
  void initState() {
    super.initState();
    _globalFocusNode = FocusNode();
    onGameLoadingComplete = () {
      if (globalGameState != null) {
        AudioService().applySettings(globalGameState!);
      }
      AudioService().playBGM('audio/vivaldi_winter.m4a', isAsset: true);
      if (mounted) {
        setState(() {
          _isFullyLoaded = true;
        });
      }
    };
  }

  @override
  void dispose() {
    _globalFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Abomination',
      builder: (ctx, child) {
        return KeyboardListener(
          focusNode: _globalFocusNode,
          autofocus: true,
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              final key = event.physicalKey;

              // Skip hotkeys if typing in a text field
              final primaryFocus = FocusManager.instance.primaryFocus;
              if (primaryFocus != null && primaryFocus.context != null) {
                final hasTextFocus = primaryFocus.context!.findAncestorWidgetOfExactType<EditableText>() != null;
                if (hasTextFocus) return;
              }

              final state = globalGameState;
              if (state == null) return;

              if (state.isReassigningHotkey) return;

              // If player is not initialized yet (e.g. game setup screen) or if we are in active combat/combat simulator,
              // do not handle global keys!
              final player = state.npcs.firstWhereOrNull((n) => n.isPlayer);
              if (player == null || state.simulationPlayerDeck != null) {
                return;
              }

              // Skip speed adjustments and global navigations if a dialogue or decision-based encounter is active!
              final bool isEncounterActive = state.pendingCombatEncounter || state.pendingEncounterData != null;
              if (isEncounterActive) {
                return;
              }

              final keyLabel = event.logicalKey.keyLabel.toUpperCase();

              // Numeric speed keys are only active when the clock is not paused.
              // During combat, encounters, dialogue, or menus, the clock is paused so numbers won't affect it!
              if (state.speed != GameSpeed.paused) {
                if (key == PhysicalKeyboardKey.digit0 || key == PhysicalKeyboardKey.numpad0 || keyLabel == state.hotkeys['Pause']) {
                  state.setSpeed(GameSpeed.paused);
                } else if (key == PhysicalKeyboardKey.digit1 || key == PhysicalKeyboardKey.numpad1 || keyLabel == state.hotkeys['Slow Speed']) {
                  state.setSpeed(GameSpeed.slow);
                } else if (key == PhysicalKeyboardKey.digit2 || key == PhysicalKeyboardKey.numpad2 || keyLabel == state.hotkeys['Normal Speed']) {
                  state.setSpeed(GameSpeed.normal);
                } else if (key == PhysicalKeyboardKey.digit3 || key == PhysicalKeyboardKey.numpad3 || keyLabel == state.hotkeys['Fast Speed']) {
                  state.setSpeed(GameSpeed.fast);
                } else if (key == PhysicalKeyboardKey.digit4 || key == PhysicalKeyboardKey.numpad4 || keyLabel == state.hotkeys['Lightning Speed']) {
                  state.setSpeed(GameSpeed.lightning);
                }
              }

              final bool isAtManor = (player.worldTravelProgress == 0.0 || player.worldTravelProgress >= 1.0);

              if (isAtManor) {
                if (key == PhysicalKeyboardKey.keyU || keyLabel == state.hotkeys['Manor View']) {
                  navigatorKey.currentState?.popUntil((route) => route.isFirst);
                } else if (key == PhysicalKeyboardKey.keyO || keyLabel == state.hotkeys['Chronicle Records']) {
                  navigatorKey.currentState?.popUntil((route) => route.isFirst);
                  navigatorKey.currentState?.push(
                    MaterialPageRoute(builder: (context) => const RecordsScreen()),
                  );
                } else if (key == PhysicalKeyboardKey.keyP || keyLabel == state.hotkeys['Survey Estate Map']) {
                  navigatorKey.currentState?.popUntil((route) => route.isFirst);
                  navigatorKey.currentState?.push(
                    MaterialPageRoute(builder: (context) => const WorldMapScreen()),
                  );
                } else if (key == PhysicalKeyboardKey.keyI || keyLabel == state.hotkeys['Manor Holdings']) {
                  navigatorKey.currentState?.popUntil((route) => route.isFirst);
                  navigatorKey.currentState?.push(
                    MaterialPageRoute(builder: (context) => const RecordsScreen()),
                  );
                }
              }
            }
          },
          child: child!,
        );
      },
      theme: _isFullyLoaded
          ? ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF1A1612), // Deep wood shadow
              textTheme: GoogleFonts.playfairDisplayTextTheme(
                ThemeData.dark().textTheme,
              ).copyWith(
                bodyMedium: GoogleFonts.oldStandardTt(
                  color: const Color(0xFFC4B89B),
                ),
              ),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF3B2F21), // Mahogany
                brightness: Brightness.dark,
                surface: const Color(0xFF241F1A),
                primary: const Color(0xFFC4B89B), // Brass/Parchment
              ),
              useMaterial3: true,
            )
          : ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF1A1612),
            ),
      home: LoadingScreen(onCompleted: onGameLoadingComplete),
    );
  }
}
