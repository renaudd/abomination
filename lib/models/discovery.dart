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

class Discovery {
  final String id;
  final String name;
  final String description;
  final Map<String, int> requiredResearch; // {'Anatomy': 1} (Multiplied by 10.0 in game state checks)
  final List<String> unlocks; // ['reanimation_experiment', 'muscle_graft']

  Discovery({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredResearch,
    this.unlocks = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'requiredResearch': requiredResearch,
    'unlocks': unlocks,
  };

  factory Discovery.fromJson(Map<String, dynamic> json) => Discovery(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    requiredResearch: Map<String, int>.from(json['requiredResearch'] as Map),
    unlocks: List<String>.from(json['unlocks'] as List? ?? []),
  );

  static List<Discovery> get allDiscoveries => [
    Discovery(
      id: 'basic_reanimation',
      name: 'Basic Reanimation',
      description: 'The master principles of restoring life to dead tissue using static galvanism.',
      requiredResearch: {'Anatomy': 1, 'Alchemy': 1},
      unlocks: ['reanimation_experiment'],
    ),
    Discovery(
      id: 'freezing_tech',
      name: 'Cryogenic Suspension',
      description: 'Techniques for preserving organic matter in a sub-zero state, unlocking cold immunity and ice weapons.',
      requiredResearch: {'Alchemy': 3},
      unlocks: ['cold_immunity_trait', 'ice_weapon'],
    ),
    Discovery(
      id: 'artificial_muscle',
      name: 'Artificial Muscle',
      description: 'Synthetic carbon-fiber muscles that mimic and exceed natural strength.',
      requiredResearch: {'Anatomy': 2, 'Zoology: Mammals': 2},
      unlocks: ['strength_augmentation'],
    ),
    Discovery(
      id: 'trade_dress',
      name: 'Trade Dress',
      description: 'Establishes visual branding for the manor\'s ventures, increasing the customer return rate by +15% and unlocking legal trade-dress infringement services.',
      requiredResearch: {'Marketing': 2, 'Jurisprudence': 1},
      unlocks: ['trade_dress_infringement_claim', 'premium_menu_branding'],
    ),
    Discovery(
      id: 'galvanic_steam_engine',
      name: 'Galvanic Steam Engine',
      description: 'A revolutionary hybrid engine combining clockwork steam pistons with static galvanic cells, unlocking heavy steam automatons.',
      requiredResearch: {'Engineering': 3, 'Electrical Engineering': 2},
      unlocks: ['heavy_steam_automaton', 'automated_refinery'],
    ),
    Discovery(
      id: 'fungal_yeast_synthesis',
      name: 'Fungal Yeast Synthesis',
      description: 'Advanced cross-cultivation of cave-cellar spores and microbiological yeasts, boosting winery and brewery yields by +30%.',
      requiredResearch: {'Mycology': 2, 'Microbiology': 2},
      unlocks: ['gothic_port_distilling', 'spore_yeast_yeild_boost'],
    ),
    Discovery(
      id: 'chimerical_soul_binding',
      name: 'Chimerical Soul-Binding',
      description: 'The metaphysical process of binding a subject\'s spiritual essence to a reanimated composite body, reducing graft rejection rates by -50%.',
      requiredResearch: {'Ontology': 3, 'Necromancy': 2},
      unlocks: ['soul_bound_chimera', 'guilt_free_vivisection'],
    ),
    Discovery(
      id: 'submersible_tech',
      name: 'Submersible Design',
      description: 'The structural foundations of underwater vehicles, enabling the construction of a deep-sea exploration Submarine in the Garage.',
      requiredResearch: {'Physics': 3, 'Engineering': 3},
      unlocks: ['garage_submarine', 'lake_abyss_exploration'],
    ),
    Discovery(
      id: 'deep_abyss_navigation',
      name: 'Abyssal Navigation',
      description: 'Advanced ballast and guidance systems for navigating deep trenches and high-pressure underwater currents safely.',
      requiredResearch: {'Physics': 5, 'Meteorology': 3},
      unlocks: ['submarine_trench_depths', 'pressure_ballast_upgrade'],
    ),
    Discovery(
      id: 'celestial_triangulation',
      name: 'Celestial Triangulation',
      description: 'Using stellar positions and advanced geometry to chart regional pathways, reducing world map travel times by 20% and gaining blizzard immunity.',
      requiredResearch: {'Astronomy': 3, 'Mathematics': 3},
      unlocks: ['fast_travel_bonus', 'blizzard_immunity_trait'],
    ),
    Discovery(
      id: 'barometric_artillery',
      name: 'Barometric Targeting',
      description: 'Calculates missile trajectories using atmospheric pressure, increasing watchtower range by +25% during storms.',
      requiredResearch: {'Physics': 2, 'Meteorology': 2},
      unlocks: ['storm_range_boost', 'barometric_fuse'],
    ),
    Discovery(
      id: 'synthetic_ether_anesthetic',
      name: 'Ether Anesthetic',
      description: 'Synthesizes high-potency surgical anesthetics, completely eliminating sanity decay during operating room procedures.',
      requiredResearch: {'Anatomy': 3, 'Pharmacology': 3},
      unlocks: ['zero_sanity_decay_surgery', 'ether_grafting'],
    ),
    Discovery(
      id: 'immunological_vectors',
      name: 'Immunological Vectors',
      description: 'Deploys attenuated microbial vectors to deliver therapeutic compounds, reducing general estate disease contraction rates by 40%.',
      requiredResearch: {'Microbiology': 4, 'Pharmacology': 4},
      unlocks: ['disease_resistance_bonus', 'antibiotic_synthesis'],
    ),
    Discovery(
      id: 'actuarial_probability',
      name: 'Actuarial Probability',
      description: 'Applies rigorous statistical probability to financial markets, unlocking advanced accounting and boosting estate weekly yields by +20% cash.',
      requiredResearch: {'Administration': 3, 'Mathematics': 3},
      unlocks: ['estate_accounting_office', 'market_yield_bonus'],
    ),
    Discovery(
      id: 'clockwork_calculator',
      name: 'Difference Engine Calculation',
      description: 'Enables mechanical calculations that automate complex algebraic studies, increasing research speed by +30% for all manor scholars.',
      requiredResearch: {'Software Engineering': 4, 'Mathematics': 4},
      unlocks: ['difference_engine_calculator', 'study_speed_multiplier'],
    ),
    Discovery(
      id: 'deep_sea_sonar',
      name: 'Abyssal Bio-Sonar',
      description: 'An electro-acoustic sonar modeled on deep-sea biological resonators, allowing the submarine to locate hidden treasures and avoid monsters.',
      requiredResearch: {'Electrical Engineering': 4, 'Zoology: Fish': 3},
      unlocks: ['submarine_sonar_scan', 'abyssal_treasure_hunting'],
    ),
    Discovery(
      id: 'avian_carrier_scouting',
      name: 'Avian Scout Network',
      description: 'Trains carrier raptors to map canton borders and dispatch messages, increasing Canton faction standing gains by +20%.',
      requiredResearch: {'Zoology: Birds': 3, 'Political': 3},
      unlocks: ['carrier_pigeon_dispatches', 'canton_standing_bonus'],
    ),
    Discovery(
      id: 'insectoid_silk_composites',
      name: 'Bio-Composite Insect Silk',
      description: 'Weaves spider-silk composite filaments into light armor plating, unlocking the Arachnid Plate Armor item for combat units.',
      requiredResearch: {'Zoology: Insects': 4, 'Composites': 3},
      unlocks: ['arachnid_plate_armor', 'lightweight_shielding'],
    ),
    Discovery(
      id: 'marketing_gothic_aesthetic',
      name: 'Gothic Grandeur Marketing',
      description: 'Unlock sophisticated Swiss Gothic aesthetic marketing campaigns to attract prestigious and gothic diners (+15% dining tips, gothic decor).',
      requiredResearch: {'Marketing': 1},
    ),
    Discovery(
      id: 'marketing_alchemical_modernism',
      name: 'Alchemical Modernism Branding',
      description: 'Advertise the cutting-edge fusion of culinary science and modern alchemical design (+25% dining tips, alchemical decor).',
      requiredResearch: {'Marketing': 2, 'Alchemy': 1},
    ),
  ];
}
