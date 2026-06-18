import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../state/game_state.dart';
import '../services/task_service.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  static bool isTesting = false;

  AudioPlayer? _bgmPlayerLazy;
  AudioPlayer? get _bgmPlayer => _bgmPlayerLazy ??= _createPlayer();

  AudioPlayer? _actionPlayerLazy;
  AudioPlayer? get _actionPlayer => _actionPlayerLazy ??= _createPlayer();

  AudioPlayer? _footstepPlayerLazy;
  AudioPlayer? get _footstepPlayer => _footstepPlayerLazy ??= _createPlayer();

  List<AudioPlayer>? _sfxPoolLazy;
  List<AudioPlayer> get _sfxPool {
    _sfxPoolLazy ??= List.generate(4, (_) => _createPlayer()).whereType<AudioPlayer>().toList();
    return _sfxPoolLazy!;
  }
  int _sfxIndex = 0;

  List<AudioPlayer>? _voicePoolLazy;
  List<AudioPlayer> get _voicePool {
    _voicePoolLazy ??= List.generate(3, (_) => _createPlayer()).whereType<AudioPlayer>().toList();
    return _voicePoolLazy!;
  }
  int _voiceIndex = 0;

  AudioPlayer? _createPlayer() {
    if (isTesting) return null;
    try {
      return AudioPlayer();
    } catch (_) {
      return null;
    }
  }

  final Random _random = Random();

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _bgmVolume = 0.5;
  bool _sfxEnabled = true;
  double _sfxVolume = 0.7;

  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _bgmPlayer?.setReleaseMode(ReleaseMode.loop);
      await _actionPlayer?.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      debugPrint("AudioService initialize error: $e");
    }
  }

  Future<void> initialize() async {
    await ensureInitialized();
  }

  void applySettings(GameState state) {
    _soundEnabled = state.soundEnabled;
    _musicEnabled = state.musicEnabled;
    _bgmVolume = state.musicVolume;
    _sfxEnabled = state.sfxEnabled;
    _sfxVolume = state.sfxVolume;

    try {
      if (!_soundEnabled || !_musicEnabled) {
        _bgmPlayer?.setVolume(0);
      } else {
        _bgmPlayer?.setVolume(_bgmVolume);
        if (_bgmPlayer?.state != PlayerState.playing) {
          playBGM('audio/vivaldi_winter.m4a', isAsset: true);
        }
      }

      if (!_soundEnabled || !_sfxEnabled) {
        for (var p in _sfxPool) { p.setVolume(0); }
        for (var p in _voicePool) { p.setVolume(0); }
        _actionPlayer?.setVolume(0);
        _footstepPlayer?.setVolume(0);
      } else {
        for (var p in _sfxPool) { p.setVolume(_sfxVolume); }
        for (var p in _voicePool) { p.setVolume(_sfxVolume); }
        _actionPlayer?.setVolume(_sfxVolume * 0.5);
        _footstepPlayer?.setVolume(_sfxVolume * 0.4);
      }
    } catch (e) {
      debugPrint("AudioService applySettings error: $e");
    }
  }

  Future<void> playBGM(String url, {bool isAsset = true}) async {
    await ensureInitialized();
    if (!_soundEnabled || !_musicEnabled) return;
    if (_bgmPlayer?.state == PlayerState.playing) return;
    try {
      Source source;
      if (isAsset) {
        final cleanPath = url.startsWith('assets/') ? url.substring(7) : url;
        source = AssetSource(cleanPath);
      } else {
        source = UrlSource(url);
      }
      await _bgmPlayer?.play(source, volume: _bgmVolume);
    } catch (e) {
      debugPrint("AudioService playBGM error: $e");
    }
  }

  Future<void> playSFX(String url, {bool isAsset = true}) async {
    await ensureInitialized();
    if (!_soundEnabled || !_sfxEnabled) return;
    if (_sfxPool.isEmpty) return;
    try {
      Source source;
      if (isAsset) {
        final cleanPath = url.startsWith('assets/') ? url.substring(7) : url;
        source = AssetSource(cleanPath);
      } else {
        source = UrlSource(url);
      }
      final player = _sfxPool[_sfxIndex];
      _sfxIndex = (_sfxIndex + 1) % _sfxPool.length;
      await player.play(source, volume: _sfxVolume);
    } catch (e) {
      debugPrint("AudioService playSFX error: $e");
    }
  }

  Future<void> playVoice(String sfxPath) async {
    await ensureInitialized();
    if (!_soundEnabled || !_sfxEnabled) return;
    if (_voicePool.isEmpty) return;
    try {
      final player = _voicePool[_voiceIndex];
      _voiceIndex = (_voiceIndex + 1) % _voicePool.length;
      await player.play(AssetSource(sfxPath), volume: _sfxVolume);
    } catch (e) {
      debugPrint("AudioService playVoice error: $e");
    }
  }

  // --- Dedicated Foley SFX Methods ---

  Future<void> playTap() async {
    final String sfx = _random.nextBool() ? 'audio/buttonpress1.wav' : 'audio/buttonpress2.wav';
    await playSFX(sfx);
  }

  Future<void> playTaskAssignment() async {
    await playSFX('audio/e.wav');
  }

  Future<void> playAchievement() async => playSFX('audio/sfx_achievement.wav');

  Future<void> playDispleased() async {
    final String sfx = _random.nextBool() ? 'audio/displeased1.wav' : 'audio/displeased2.wav';
    await playVoice(sfx);
  }

  Future<void> playPleased() async {
    final String sfx = _random.nextBool() ? 'audio/pleased1.wav' : 'audio/pleased2.wav';
    await playVoice(sfx);
  }

  Future<void> playEggsProduced() async => playSFX('audio/sfx_eggs.wav');
  Future<void> playMealCompleted() async => playSFX('audio/sfx_meal.wav');
  Future<void> playExperimentCompleted() async => playSFX('audio/sfx_experiment.wav');

  Future<void> playFootsteps() async {
    await ensureInitialized();
    if (!_soundEnabled || !_sfxEnabled) return;
    if (_footstepPlayer?.state == PlayerState.playing) return;
    try {
      await _footstepPlayer?.play(AssetSource('audio/sfx_footsteps.wav'), volume: _sfxVolume * 0.4);
    } catch (e) {
      debugPrint("AudioService playFootsteps error: $e");
    }
  }

  Future<void> playGilesShuffle() async {
    // Giles' shuffle is silenced until timing and sounds are dialed in.
    return;
  }

  TaskType? _currentActionTask;

  Future<void> startActionSound(TaskType task) async {
    await ensureInitialized();
    if (!_soundEnabled || !_sfxEnabled) return;
    if (_currentActionTask == task && _actionPlayer?.state == PlayerState.playing) return;
    try {
      String? sfxPath;
      switch (task) {
        case TaskType.research:
        case TaskType.transcribeNotes:
        case TaskType.archiveResearch:
        case TaskType.invention:
        case TaskType.study:
        case TaskType.readBook:
        case TaskType.writePoetry:
        case TaskType.writeNovel:
          sfxPath = 'audio/sfx_writing.wav';
          break;
        case TaskType.cleanDish:
        case TaskType.wash:
        case TaskType.washHands:
        case TaskType.bathe:
        case TaskType.useToilet:
          sfxPath = 'audio/handwash.wav';
          break;
        case TaskType.idle:
        case TaskType.rest:
        case TaskType.eat:
        case TaskType.relax:
        case TaskType.observeExperiment:
        case TaskType.goForWalk:
          return;
        default:
          // All other work uses eloop.wav for now
          sfxPath = 'audio/eloop.wav';
          break;
      }
      _currentActionTask = task;
      await _actionPlayer?.setReleaseMode(ReleaseMode.loop);
      await _actionPlayer?.play(AssetSource(sfxPath), volume: _sfxVolume * 0.5);
    } catch (e) {
      debugPrint("AudioService startActionSound error: $e");
    }
  }

  Future<void> stopActionSound() async {
    try {
      _currentActionTask = null;
      await _actionPlayer?.stop();
    } catch (e) {
      debugPrint("AudioService stopActionSound error: $e");
    }
  }

  void stopBGM() {
    try {
      _bgmPlayer?.stop();
    } catch (e) {
      debugPrint("AudioService stopBGM error: $e");
    }
  }

  void setVolume(double volume) {
    _bgmVolume = volume;
    try {
      if (_soundEnabled && _musicEnabled) {
        _bgmPlayer?.setVolume(volume);
      }
    } catch (e) {
      debugPrint("AudioService setVolume error: $e");
    }
  }

  void mute() {
    _soundEnabled = false;
    try {
      _bgmPlayer?.setVolume(0);
      for (var p in _sfxPool) { p.setVolume(0); }
      for (var p in _voicePool) { p.setVolume(0); }
      _actionPlayer?.setVolume(0);
      _footstepPlayer?.setVolume(0);
    } catch (e) {
      debugPrint("AudioService mute error: $e");
    }
  }

  void unmute() {
    _soundEnabled = true;
    try {
      if (_musicEnabled) _bgmPlayer?.setVolume(_bgmVolume);
      if (_sfxEnabled) {
        for (var p in _sfxPool) { p.setVolume(_sfxVolume); }
        for (var p in _voicePool) { p.setVolume(_sfxVolume); }
        _actionPlayer?.setVolume(_sfxVolume * 0.5);
        _footstepPlayer?.setVolume(_sfxVolume * 0.4);
      }
    } catch (e) {
      debugPrint("AudioService unmute error: $e");
    }
  }
}
