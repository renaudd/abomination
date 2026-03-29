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

import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isMuted = false;
  double _bgmVolume = 0.5;
  final double _sfxVolume = 0.7;

  Future<void> initialize() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> playBGM(String url, {bool isAsset = true}) async {
    if (_isMuted) return;
    Source source = isAsset ? AssetSource(url) : UrlSource(url);
    await _bgmPlayer.play(source, volume: _bgmVolume);
  }

  Future<void> playSFX(String url, {bool isAsset = true}) async {
    if (_isMuted) return;
    Source source = isAsset ? AssetSource(url) : UrlSource(url);
    await _sfxPlayer.play(source, volume: _sfxVolume);
  }

  void stopBGM() {
    _bgmPlayer.stop();
  }

  void setVolume(double volume) {
    _bgmVolume = volume;
    _bgmPlayer.setVolume(volume);
  }

  void mute() {
    _isMuted = true;
    _bgmPlayer.setVolume(0);
    _sfxPlayer.setVolume(0);
  }

  void unmute() {
    _isMuted = false;
    _bgmPlayer.setVolume(_bgmVolume);
    _sfxPlayer.setVolume(_sfxVolume);
  }
}
