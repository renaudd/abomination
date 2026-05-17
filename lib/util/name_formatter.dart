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

class NameFormatter {
  static String formatItemName(String name) {
    if (name.isEmpty) return "";
    
    String formatted = name;
    
    // Handle MEAT_XXX -> XXX MEAT
    if (formatted.startsWith("MEAT_")) {
      final part = formatted.substring(5);
      formatted = "$part MEAT";
    } else if (formatted.startsWith("meat_")) {
      final part = formatted.substring(5);
      formatted = "$part meat";
    }
    
    // Handle FLOUR_XXX -> XXX FLOUR
    if (formatted.startsWith("FLOUR_")) {
      final part = formatted.substring(6);
      formatted = "$part FLOUR";
    } else if (formatted.startsWith("flour_")) {
      final part = formatted.substring(6);
      formatted = "$part flour";
    }
    
    // General cleanup: underscores to spaces
    formatted = formatted.replaceAll("_", " ");
    
    // Capitalize first letter of each word if needed, but the user specifically asked for "CHICKEN MEAT" (uppercase) or natural naming.
    // Given the game's aesthetic, UPPERCASE is often used in the UI.
    
    return formatted.trim();
  }
}
