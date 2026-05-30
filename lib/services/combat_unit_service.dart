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
      case 'cannoneer':
        return CombatUnitFactory.createCannoneer();
      case 'musketeers':
        return CombatUnitFactory.createMusketeers();
      case 'cavalry':
        return CombatUnitFactory.createCavalry();
      case 'bicycle_gang':
        return CombatUnitFactory.createBicycleGang();
      case 'motorcycle_gang':
        return CombatUnitFactory.createMotorcycleGang();
      case 'armored_car':
        return CombatUnitFactory.createArmoredCar();
      case 'wooden_tank':
        return CombatUnitFactory.createWoodenTank();
      case 'undead_rats':
        return CombatUnitFactory.createUndeadRats();
      case 'brown_rats':
        return CombatUnitFactory.createBrownRats();
      case 'werewolf':
        return CombatUnitFactory.createWerewolf();
      case 'chimera':
        return CombatUnitFactory.createChimera();
      case 'flesh_golem':
        return CombatUnitFactory.createFleshGolem();
      case 'villager_mob':
        return CombatUnitFactory.createVillagerMob();
      case 'samurai':
        return CombatUnitFactory.createSamurai();
      case 'mercenaries':
        return CombatUnitFactory.createMercenaries();
      case 'commandos':
        return CombatUnitFactory.createCommandos();
      case 'sniper':
        return CombatUnitFactory.createSniper();
      case 'wild_foxes':
        return CombatUnitFactory.createWildFoxes();
      case 'wild_wolves':
        return CombatUnitFactory.createWildWolves();
      case 'wild_bears':
        return CombatUnitFactory.createWildBears();
      case 'bandits':
        return CombatUnitFactory.createBandits();
      case 'thugs':
        return CombatUnitFactory.createThugs();
      case 'deserters':
        return CombatUnitFactory.createDeserters();
      case 'halberdiers':
        return CombatUnitFactory.createHalberdiers();
      case 'pikemen':
        return CombatUnitFactory.createPikemen();
      case 'policemen':
        return CombatUnitFactory.createPolicemen();
      case 'marksmen':
        return CombatUnitFactory.createMarksmen();
      case 'artillery_barrage':
        return CombatUnitFactory.createArtilleryBarrage();
      case 'tear_gas_grenade':
        return CombatUnitFactory.createTearGasGrenade();
      case 'caltrops':
        return CombatUnitFactory.createCaltrops();
      case 'vampiric_totem':
        return CombatUnitFactory.createVampiricTotem();
      default:
        return CombatUnitFactory.createVillagerMob();
    }
  }

}
