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
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/arena_progress.dart';
import 'storage_helper.dart';

class ArenaSaveService {
  static const int maxSlots = 3;

  static String _getFileName(int slot) => 'arena_save_slot_$slot.json';

  static Future<void> saveProgress(ArenaProgress progress) async {
    try {
      progress.saveTime = DateTime.now();
      final data = progress.toJson();
      final jsonString = jsonEncode(data);

      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_getFileName(progress.slot), jsonString);
      } else {
        await StorageHelper.instance.saveFile(_getFileName(progress.slot), jsonString);
      }
    } catch (e) {
      debugPrint('Error saving arena progress (slot ${progress.slot}): $e');
    }
  }

  static Future<ArenaProgress?> loadProgress(int slot) async {
    try {
      final String contents;
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final dataStr = prefs.getString(_getFileName(slot));
        if (dataStr == null) return null;
        contents = dataStr;
      } else {
        final dataStr = await StorageHelper.instance.readFile(_getFileName(slot));
        if (dataStr == null) return null;
        contents = dataStr;
      }

      final data = jsonDecode(contents) as Map<String, dynamic>;
      return ArenaProgress.fromJson(data);
    } catch (e) {
      debugPrint('Error loading arena progress (slot $slot): $e');
      return null;
    }
  }

  static Future<bool> hasSave(int slot) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.containsKey(_getFileName(slot));
      } else {
        return await StorageHelper.instance.fileExists(_getFileName(slot));
      }
    } catch (e) {
      return false;
    }
  }

  static Future<void> deleteSave(int slot) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_getFileName(slot));
      } else {
        await StorageHelper.instance.deleteFile(_getFileName(slot));
      }
    } catch (e) {
      debugPrint('Error deleting arena save (slot $slot): $e');
    }
  }
}
