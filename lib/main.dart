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
import 'state/game_state.dart';
import 'services/audio_service.dart';
import 'services/game_engine.dart';
import 'ui/screens/main_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final audioService = AudioService();
  await audioService.initialize();

  final gameState = GameState();
  final gameEngine = GameEngine(gameState);

  // Play placeholder bleak music (user can replace URL)
  // audioService.playBGM('https://example.com/sorcerers_apprentice.mp3', isAsset: false);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: gameState),
        Provider.value(value: gameEngine),
      ],
      child: const FrankensteinOssApp(),
    ),
  );
}

class FrankensteinOssApp extends StatelessWidget {
  const FrankensteinOssApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FrankensteinOSS',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1612), // Deep wood shadow
        textTheme:
            GoogleFonts.playfairDisplayTextTheme(
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
      ),
      home: const MainMenuScreen(),
    );
  }
}
