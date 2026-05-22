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

enum ManorVenture {
  standard,
  restaurant,
  kompromatHotel,
}

extension ManorVentureExtensions on ManorVenture {
  String get displayName {
    switch (this) {
      case ManorVenture.standard:
        return 'Standard Private Manor';
      case ManorVenture.restaurant:
        return 'High-End Dining Restaurant';
      case ManorVenture.kompromatHotel:
        return 'Kompromat Blackmail Hotel';
    }
  }
}
