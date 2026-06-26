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

enum DisciplineBranch { physical, biology, occult, metaphysical }

class ScienceDiscipline {
  final String id;
  final String name;
  final DisciplineBranch branch;
  final String description;
  final Map<String, int> gatewayDependencies; // disciplineId -> requiredLevel
  final Map<String, double> synergyBoosts;    // disciplineId -> speedMultiplier

  const ScienceDiscipline({
    required this.id,
    required this.name,
    required this.branch,
    required this.description,
    this.gatewayDependencies = const {},
    this.synergyBoosts = const {},
  });

  String get branchDisplayName {
    switch (branch) {
      case DisciplineBranch.physical:
        return 'PHYSICAL';
      case DisciplineBranch.biology:
        return 'BIOLOGY';
      case DisciplineBranch.occult:
        return 'OCCULT';
      case DisciplineBranch.metaphysical:
        return 'METAPHYSICAL';
    }
  }
}

class ScienceRegistry {
  static const Map<String, ScienceDiscipline> disciplines = {
    // PHYSICAL BRANCH
    'physics': ScienceDiscipline(
      id: 'physics',
      name: 'Physics',
      branch: DisciplineBranch.physical,
      description: 'Theoretical foundations of kinetics, force, and space.',
    ),
    'engineering': ScienceDiscipline(
      id: 'engineering',
      name: 'Engineering',
      branch: DisciplineBranch.physical,
      description: 'Structural design and complex mechanical clockwork assemblies.',
    ),
    'structural_engineering': ScienceDiscipline(
      id: 'structural_engineering',
      name: 'Structural Engineering',
      branch: DisciplineBranch.physical,
      description: 'Foundations of architecture, load-bearing frames, and gothic masonry.',
    ),
    'electrical_engineering': ScienceDiscipline(
      id: 'electrical_engineering',
      name: 'Electrical Engineering',
      branch: DisciplineBranch.physical,
      description: 'Galvanic currents, lighting rods, and high-voltage systems.',
      gatewayDependencies: {'physics': 2},
    ),
    'software_engineering': ScienceDiscipline(
      id: 'software_engineering',
      name: 'Software Engineering',
      branch: DisciplineBranch.physical,
      description: 'Analytical punch-card engines and logical clockwork automation.',
      gatewayDependencies: {'electrical_engineering': 2},
    ),
    'biotechnology': ScienceDiscipline(
      id: 'biotechnology',
      name: 'Biotechnology',
      branch: DisciplineBranch.physical,
      description: 'Biomechanics, mechanical prosthetics, and organic-synthetic grafting.',
      gatewayDependencies: {'engineering': 3, 'anatomy': 3},
    ),
    'metals': ScienceDiscipline(
      id: 'metals',
      name: 'Metals',
      branch: DisciplineBranch.physical,
      description: 'Blacksmithing, advanced metallurgy, and durable alloy forging.',
    ),
    'chemistry': ScienceDiscipline(
      id: 'chemistry',
      name: 'Chemistry',
      branch: DisciplineBranch.physical,
      description: 'Purifying compound reagents, acids, and explosive mixtures.',
    ),
    'polymers': ScienceDiscipline(
      id: 'polymers',
      name: 'Polymers',
      branch: DisciplineBranch.physical,
      description: 'Synthetic rubberized sealants and vulcanized insulation.',
      gatewayDependencies: {'chemistry': 2},
    ),
    'ceramics': ScienceDiscipline(
      id: 'ceramics',
      name: 'Ceramics',
      branch: DisciplineBranch.physical,
      description: 'Refractory kilns, high-heat shielding, and alchemical crucibles.',
      gatewayDependencies: {'chemistry': 1},
    ),
    'semiconductors': ScienceDiscipline(
      id: 'semiconductors',
      name: 'Semiconductors',
      branch: DisciplineBranch.physical,
      description: 'Galena crystal resonators and logical current gates.',
      gatewayDependencies: {'electrical_engineering': 3},
    ),
    'composites': ScienceDiscipline(
      id: 'composites',
      name: 'Composites',
      branch: DisciplineBranch.physical,
      description: 'Reinforced carbon-bone structures and tactical armored plating.',
      gatewayDependencies: {'metals': 3, 'polymers': 2},
    ),
    'astronomy': ScienceDiscipline(
      id: 'astronomy',
      name: 'Astronomy',
      branch: DisciplineBranch.physical,
      description: 'Study of celestial bodies, star charts, and cosmic movements.',
    ),
    'meteorology': ScienceDiscipline(
      id: 'meteorology',
      name: 'Meteorology',
      branch: DisciplineBranch.physical,
      description: 'Atmospheric patterns, barometric shifts, and storm prediction.',
      gatewayDependencies: {'physics': 1},
    ),

    // BIOLOGY BRANCH
    'anatomy': ScienceDiscipline(
      id: 'anatomy',
      name: 'Anatomy',
      branch: DisciplineBranch.biology,
      description: 'Structural mapping and dissection of organic lifeforms.',
    ),
    'surgery': ScienceDiscipline(
      id: 'surgery',
      name: 'Surgery',
      branch: DisciplineBranch.biology,
      description: 'Invasive physical operations, skin-grafting, and organ transplants.',
      gatewayDependencies: {'anatomy': 4},
    ),
    'zoology_fish': ScienceDiscipline(
      id: 'zoology_fish',
      name: 'Zoology: Fish',
      branch: DisciplineBranch.biology,
      description: 'Taxonomy, behavior, and breeding of aquatic life.',
    ),
    'zoology_mammals': ScienceDiscipline(
      id: 'zoology_mammals',
      name: 'Zoology: Mammals',
      branch: DisciplineBranch.biology,
      description: 'Taxonomy, behavior, and breeding of mammalian beasts.',
    ),
    'zoology_reptiles': ScienceDiscipline(
      id: 'zoology_reptiles',
      name: 'Zoology: Reptiles',
      branch: DisciplineBranch.biology,
      description: 'Taxonomy, behavior, and breeding of scaled reptiles.',
    ),
    'zoology_amphibians': ScienceDiscipline(
      id: 'zoology_amphibians',
      name: 'Zoology: Amphibians',
      branch: DisciplineBranch.biology,
      description: 'Taxonomy, behavior, and breeding of dual-habitat amphibians.',
    ),
    'zoology_birds': ScienceDiscipline(
      id: 'zoology_birds',
      name: 'Zoology: Birds',
      branch: DisciplineBranch.biology,
      description: 'Taxonomy, behavior, and breeding of avian specimens.',
    ),
    'zoology_insects': ScienceDiscipline(
      id: 'zoology_insects',
      name: 'Zoology: Insects',
      branch: DisciplineBranch.biology,
      description: 'Taxonomy, behavior, and breeding of multi-legged insects.',
    ),
    'botany': ScienceDiscipline(
      id: 'botany',
      name: 'Botany',
      branch: DisciplineBranch.biology,
      description: 'Agricultural growth, cross-pollination, and soil cultivation.',
    ),
    'mycology': ScienceDiscipline(
      id: 'mycology',
      name: 'Mycology',
      branch: DisciplineBranch.biology,
      description: 'Fungal spores, toxic mushrooms, and dark cellar cultivation.',
      gatewayDependencies: {'botany': 1},
    ),
    'microbiology': ScienceDiscipline(
      id: 'microbiology',
      name: 'Microbiology',
      branch: DisciplineBranch.biology,
      description: 'Fermentation, bacterial cultures, and single-cell yeast purification.',
      gatewayDependencies: {'botany': 2},
    ),
    'pathology': ScienceDiscipline(
      id: 'pathology',
      name: 'Pathology',
      branch: DisciplineBranch.biology,
      description: 'Disease progression, vectors, viral mutagens, and contagion cures.',
      gatewayDependencies: {'microbiology': 2},
    ),
    'psychology': ScienceDiscipline(
      id: 'psychology',
      name: 'Psychology',
      branch: DisciplineBranch.biology,
      description: 'Mental fortitude, stress decay, and cognitive optimization.',
    ),
    'pharmacology': ScienceDiscipline(
      id: 'pharmacology',
      name: 'Pharmacology',
      branch: DisciplineBranch.biology,
      description: 'Chemical compounds, plant-extract drug synthesis, and biological toxicity.',
      gatewayDependencies: {'chemistry': 2},
    ),

    // OCCULT BRANCH
    'alchemy': ScienceDiscipline(
      id: 'alchemy',
      name: 'Alchemy',
      branch: DisciplineBranch.occult,
      description: 'Elemental transmutation, quicksilver stabilization, and spiritual distillation.',
    ),
    'psionics': ScienceDiscipline(
      id: 'psionics',
      name: 'Psionics',
      branch: DisciplineBranch.occult,
      description: 'Conversion and focusing of latent cerebral energy.',
      gatewayDependencies: {'psychology': 3},
    ),
    'telekinesis': ScienceDiscipline(
      id: 'telekinesis',
      name: 'Telekinesis',
      branch: DisciplineBranch.occult,
      description: 'Physical manipulation and kinetic force projected by willpower.',
      gatewayDependencies: {'psionics': 2},
    ),
    'telepathy': ScienceDiscipline(
      id: 'telepathy',
      name: 'Telepathy',
      branch: DisciplineBranch.occult,
      description: 'Mind-to-mind cognitive synchronization and mental logs.',
      gatewayDependencies: {'psionics': 2},
    ),
    'voodoo': ScienceDiscipline(
      id: 'voodoo',
      name: 'Voodoo',
      branch: DisciplineBranch.occult,
      description: 'Sympathetic magic, doll bindings, and spiritual link carving.',
      gatewayDependencies: {'psychology': 2},
    ),
    'enchantment': ScienceDiscipline(
      id: 'enchantment',
      name: 'Enchantment',
      branch: DisciplineBranch.occult,
      description: 'Imbuing physical weaponry with static magical/supernatural charges.',
      gatewayDependencies: {'alchemy': 3},
    ),
    'nigromancy': ScienceDiscipline(
      id: 'nigromancy',
      name: 'Nigromancy',
      branch: DisciplineBranch.occult,
      description: 'Dark pacts and diplomatic standing with occult Secret Societies.',
      gatewayDependencies: {'alchemy': 2},
    ),
    'divination': ScienceDiscipline(
      id: 'divination',
      name: 'Divination',
      branch: DisciplineBranch.occult,
      description: 'Fate-rolling manipulation, precognition, and tarot mapping.',
    ),
    'necromancy': ScienceDiscipline(
      id: 'necromancy',
      name: 'Necromancy',
      branch: DisciplineBranch.occult,
      description: 'Reanimating dead tissue, galvanic spark binding, and raising the undead.',
      gatewayDependencies: {'anatomy': 5, 'alchemy': 3},
    ),

    // METAPHYSICAL BRANCH
    'sociology': ScienceDiscipline(
      id: 'sociology',
      name: 'Sociology',
      branch: DisciplineBranch.metaphysical,
      description: 'Group dynamics, staff hierarchies, and guest lodger relations.',
      gatewayDependencies: {'psychology': 3},
      synergyBoosts: {'psychology': 0.15},
    ),
    'philosophy': ScienceDiscipline(
      id: 'philosophy',
      name: 'Philosophy',
      branch: DisciplineBranch.metaphysical,
      description: 'Existential ethics and rationalization of horrific experiments (guilt mitigation).',
      gatewayDependencies: {'psychology': 2},
    ),
    'ontology': ScienceDiscipline(
      id: 'ontology',
      name: 'Ontology',
      branch: DisciplineBranch.metaphysical,
      description: 'The nature of existence and spiritual chimerical soul-binding.',
      gatewayDependencies: {'philosophy': 3},
    ),
    'political': ScienceDiscipline(
      id: 'political',
      name: 'Political',
      branch: DisciplineBranch.metaphysical,
      description: 'Canton lobbying, secret society negotiations, and public standing.',
      gatewayDependencies: {'sociology': 2},
    ),
    'jurisprudence': ScienceDiscipline(
      id: 'jurisprudence',
      name: 'Jurisprudence',
      branch: DisciplineBranch.metaphysical,
      description: 'Legal frameworks, blackmail contract protection, and courtroom safety.',
      gatewayDependencies: {'political': 2},
    ),
    'administration': ScienceDiscipline(
      id: 'administration',
      name: 'Administration',
      branch: DisciplineBranch.metaphysical,
      description: 'Manor logistical optimization and supply chain scheduling efficiency.',
    ),
    'marketing': ScienceDiscipline(
      id: 'marketing',
      name: 'Marketing',
      branch: DisciplineBranch.metaphysical,
      description: 'Pricing psychology, hotel appeals, and restaurant menus branding.',
      gatewayDependencies: {'sociology': 2},
    ),
    'mathematics': ScienceDiscipline(
      id: 'mathematics',
      name: 'Mathematics',
      branch: DisciplineBranch.metaphysical,
      description: 'Advanced algebra, geometry, calculus, and abstract numerical frameworks.',
    ),
  };
}
