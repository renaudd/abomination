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

  static NPC createUnit(String rawType) {
    String t = rawType.toLowerCase();
    if (t.startsWith('squad_')) {
      t = t.substring(6);
    }
    final parts = t.split('_');
    final validParts = <String>[];
    for (final p in parts) {
      if (p.isEmpty) continue;
      if (p.codeUnitAt(0) >= 48 && p.codeUnitAt(0) <= 57) break;
      if (p == 'follower' || p == 'horse' || p == 'recruit' || p == 'refill' || p == 'cycle') break;
      validParts.add(p);
    }
    final type = validParts.join('_');

    switch (type) {
      case 'alphonse':
        return CombatUnitFactory.createAlphonse();
      case 'lord_garrick':
        return CombatUnitFactory.createLordGarrick();
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
      case 'undead_bats':
        return CombatUnitFactory.createUndeadBats();
      case 'brown_rats':
        return CombatUnitFactory.createBrownRats();
      case 'spectral_wolf':
        return CombatUnitFactory.createSpectralWolf();
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
      case 'wild_bats':
        return CombatUnitFactory.createBatsUnit();
      case 'wild_wolves':
        return CombatUnitFactory.createWildWolves();
      case 'wild_bear':
      case 'wild_bears':
        return CombatUnitFactory.createWildBear();
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
      case 'militia':
        return CombatUnitFactory.createMilitia();
      case 'goon':
      case 'goons':
        return CombatUnitFactory.createGoons();
      case 'footman':
        return CombatUnitFactory.createFootman();
      case 'bandit_captain':
        return CombatUnitFactory.createBanditCaptain();
      case 'boss_rudolf':
        return CombatUnitFactory.createBossRudolf();
      case 'boss_gearbox':
        return CombatUnitFactory.createBossGearbox();
      case 'elizabeth_bat_swarm_support':
      case 'lady_elizabeth_bat_swarm_spell':
        return CombatUnitFactory.createElizabethBatSwarmSupport();
      case 'boss_elizabeth':
        return CombatUnitFactory.createBossElizabeth();
      case 'boss_thorne':
        return CombatUnitFactory.createBossThorne();
      case 'bats':
      case 'bats_unit':
        return CombatUnitFactory.createBats();
      case 'stampede':
      case 'stampede_card':
        return CombatUnitFactory.createStampede();
      case 'brewers':
        return CombatUnitFactory.createBrewers();
      case 'hag':
        return CombatUnitFactory.createHag();
      case 'witch':
        return CombatUnitFactory.createWitch();
      case 'warlock':
        return CombatUnitFactory.createWarlock();
      case 'gatling_gun':
        return CombatUnitFactory.createGatlingGun();
      case 'zeppelin':
        return CombatUnitFactory.createZeppelin();
      case 'valkyrie':
        return CombatUnitFactory.createValkyrie();
      case 'minotaur':
        return CombatUnitFactory.createMinotaur();
      case 'phoenix':
        return CombatUnitFactory.createPhoenix();
      case 'necromancer':
        return CombatUnitFactory.createNecromancer();
      case 'battering_ram':
        return CombatUnitFactory.createBatteringRam();
      case 'steampunk_mech':
        return CombatUnitFactory.createSteampunkMech();
      case 'steampunk_robot':
      case 'robot':
        return CombatUnitFactory.createSteampunkRobot();
      case 'poison_gas':
        return CombatUnitFactory.createPoisonGas();
      case 'lightning_storm':
        return CombatUnitFactory.createLightningStorm();
      case 'airdrop':
        return CombatUnitFactory.createAirdrop();
      case 'divine_shield':
        return CombatUnitFactory.createDivineShield();
      case 'napalm_strike':
        return CombatUnitFactory.createNapalmStrike();
      // Secret Society Faction Commanders & Cards
      case 'hiram_abiff':
        return CombatUnitFactory.createHiramAbiff();
      case 'masonic_sapper':
        return CombatUnitFactory.createMasonicSapper();
      case 'sacred_geometry':
        return CombatUnitFactory.createSacredGeometry();
      case 'christian_rosenkreuz':
        return CombatUnitFactory.createChristianRosenkreuz();
      case 'homunculus_behemoth':
        return CombatUnitFactory.createHomunculusBehemoth();
      case 'elixir_of_vitality':
        return CombatUnitFactory.createElixirOfVitality();
      case 'jacques_de_molay':
        return CombatUnitFactory.createJacquesDeMolay();
      case 'templar_pyre_knight':
        return CombatUnitFactory.createTemplarPyreKnight();
      case 'greek_fire_flask':
        return CombatUnitFactory.createGreekFireFlask();
      case 'banker_rothschild':
        return CombatUnitFactory.createBankerRothschild();
      case 'vault_assassin':
        return CombatUnitFactory.createVaultAssassin();
      case 'zurich_debt_collector':
        return CombatUnitFactory.createZurichDebtCollector();
      case 'alta_vendita':
        return CombatUnitFactory.createAltaVendita();
      case 'carbonari_arsonist':
        return CombatUnitFactory.createCarbonariArsonist();
      case 'revolutionary_martyr':
        return CombatUnitFactory.createRevolutionaryMartyr();
      case 'aleister_crowley':
        return CombatUnitFactory.createAleisterCrowley();
      case 'hermetic_mesmerist':
        return CombatUnitFactory.createHermeticMesmerist();
      case 'astral_hypnosis':
        return CombatUnitFactory.createAstralHypnosis();
      case 'james_stephens':
        return CombatUnitFactory.createJamesStephens();
      case 'fenian_night_raider':
        return CombatUnitFactory.createFenianNightRaider();
      case 'insurgent_cell':
        return CombatUnitFactory.createInsurgentCell();
      case 'ferdinand_de_bertier':
        return CombatUnitFactory.createFerdinandDeBertier();
      case 'royalist_cuirassier':
        return CombatUnitFactory.createRoyalistCuirassier();
      case 'royalist_standard_bearer':
        return CombatUnitFactory.createRoyalistStandardBearer();
      case 'chief_ranger_robin':
        return CombatUnitFactory.createChiefRangerRobin();
      case 'forester_herbalist':
        return CombatUnitFactory.createForesterHerbalist();
      case 'forester_beastmaster':
        return CombatUnitFactory.createForesterBeastmaster();
      // Bavarian Illuminati
      case 'adam_weishaupt':
        return CombatUnitFactory.createAdamWeishaupt();
      case 'illuminati_infiltrator':
        return CombatUnitFactory.createIlluminatiInfiltrator();
      case 'rationalist_propaganda':
        return CombatUnitFactory.createRationalistPropaganda();
      default:
        return CombatUnitFactory.createVillagerMob();
    }
  }

}

