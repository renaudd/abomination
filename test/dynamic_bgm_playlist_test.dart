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

import 'package:flutter_test/flutter_test.dart';
import 'package:abomination/services/audio_service.dart';

void main() {
  group('Dynamic BGM Playlist System Testing', () {
    late AudioService audioService;

    setUp(() {
      audioService = AudioService();
      // Reset BGM stack to default manor state for each test
      while (audioService.currentBgmMode != BgmMode.manor) {
        audioService.popBgmMode();
      }
    });

    test('BGM Stack pushes and pops modes correctly', () async {
      expect(audioService.currentBgmMode, equals(BgmMode.manor));

      // 1. Push Laboratory
      await audioService.pushBgmMode(BgmMode.laboratory);
      expect(audioService.currentBgmMode, equals(BgmMode.laboratory));

      // 2. Push Combat
      await audioService.pushBgmMode(BgmMode.combat);
      expect(audioService.currentBgmMode, equals(BgmMode.combat));

      // 3. Pop back to Laboratory
      await audioService.popBgmMode();
      expect(audioService.currentBgmMode, equals(BgmMode.laboratory));

      // 4. Pop back to Manor
      await audioService.popBgmMode();
      expect(audioService.currentBgmMode, equals(BgmMode.manor));
    });

    test('Nested BGM pushes of same mode maintain active mode without disruption', () async {
      expect(audioService.currentBgmMode, equals(BgmMode.manor));

      // Manor -> Laboratory
      await audioService.pushBgmMode(BgmMode.laboratory);
      expect(audioService.currentBgmMode, equals(BgmMode.laboratory));

      // Laboratory -> Laboratory (sub-screen entry)
      await audioService.pushBgmMode(BgmMode.laboratory);
      expect(audioService.currentBgmMode, equals(BgmMode.laboratory));

      // Exit sub-screen: Pop Laboratory
      await audioService.popBgmMode();
      expect(audioService.currentBgmMode, equals(BgmMode.laboratory));

      // Exit Laboratory: Pop to Manor
      await audioService.popBgmMode();
      expect(audioService.currentBgmMode, equals(BgmMode.manor));
    });
  });
}
