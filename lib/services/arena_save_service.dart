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

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/arena_progress.dart';

class ArenaSaveService {
  static const int maxSlots = 3;

  static String _getFileName(int slot) => 'arena_save_slot_$slot.json';

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> _localFile(int slot) async {
    final path = await _localPath;
    return File('$path/${_getFileName(slot)}');
  }

  static Future<void> saveProgress(ArenaProgress progress) async {
    try {
      final file = await _localFile(progress.slot);
      progress.saveTime = DateTime.now();
      final data = progress.toJson();
      final jsonString = jsonEncode(data);
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Error saving arena progress (slot ${progress.slot}): $e');
    }
  }

  static Future<ArenaProgress?> loadProgress(int slot) async {
    try {
      final file = await _localFile(slot);
      if (!await file.exists()) return null;

      final contents = await file.readAsString();
      final data = jsonDecode(contents) as Map<String, dynamic>;
      return ArenaProgress.fromJson(data);
    } catch (e) {
      debugPrint('Error loading arena progress (slot $slot): $e');
      return null;
    }
  }

  static Future<bool> hasSave(int slot) async {
    try {
      final file = await _localFile(slot);
      return file.exists();
    } catch (e) {
      return false;
    }
  }

  static Future<void> deleteSave(int slot) async {
    try {
      final file = await _localFile(slot);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting arena save (slot $slot): $e');
    }
  }
}
