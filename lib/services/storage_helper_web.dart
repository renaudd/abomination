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

import 'storage_helper.dart';

class WebStorageHelper implements StorageHelper {
  @override
  Future<void> saveFile(String fileName, String content) async {}

  @override
  Future<String?> readFile(String fileName) async => null;

  @override
  Future<bool> fileExists(String fileName) async => false;

  @override
  Future<void> deleteFile(String fileName) async {}
}

StorageHelper getStorageHelper() => WebStorageHelper();
