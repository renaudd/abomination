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

import '../models/npc.dart';
import 'combat_unit_factory.dart';

class CombatUnitService {
  static List<NPC> getInitialDeck() {
    return [CombatUnitFactory.createFlaubert()];
  }

  static NPC createUnit(String type) {
    switch (type) {
      case 'giles':
        return CombatUnitFactory.createFlaubert();
      case 'militia':
        return CombatUnitFactory.createMilitia();
      case 'captain':
        return CombatUnitFactory.createBanditCaptain();
      case 'peasant':
        return CombatUnitFactory.createPeasant();
      case 'goon':
        return CombatUnitFactory.createGoon();
      case 'rats':
        return CombatUnitFactory.createRatsUnit();
      case 'bats':
        return CombatUnitFactory.createBatsUnit();
      case 'flying_rat':
        return CombatUnitFactory.createWingedRat();
      case 'sniper':
        return CombatUnitFactory.createSniper();
      case 'bully':
        return CombatUnitFactory.createBully();
      case 'stitched_horror':
        return CombatUnitFactory.createStitchedHorror();
      case 'galvanized_corpse':
        return CombatUnitFactory.createGalvanizedCorpse();
      case 'chemical_slinger':
        return CombatUnitFactory.createChemicalSlinger();
      case 'shadow_creeper':
        return CombatUnitFactory.createShadowCreeper();
      case 'gravedigger':
        return CombatUnitFactory.createGravedigger();
      case 'plague_monk':
        return CombatUnitFactory.createPlagueMonk();
      case 'inquisitor':
        return CombatUnitFactory.createInquisitor();
      case 'iron_maiden':
        return CombatUnitFactory.createIronMaiden();
      case 'flesh_hound':
        return CombatUnitFactory.createFleshHound();
      case 'alchemical_golem':
        return CombatUnitFactory.createAlchemicalGolem();
      default:
        return CombatUnitFactory.createGoon();
    }
  }

}
