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

import '../state/game_state.dart';

class NeighborEncounter {
  final String npcName;
  final String faction;
  final String cottageId;
  final String introDialog;
  final String choiceAText;
  final String choiceBText;
  final String outcomeAText;
  final String outcomeBText;
  final void Function(GameState state) onChoiceA;
  final void Function(GameState state) onChoiceB;

  NeighborEncounter({
    required this.npcName,
    required this.faction,
    required this.cottageId,
    required this.introDialog,
    required this.choiceAText,
    required this.choiceBText,
    required this.outcomeAText,
    required this.outcomeBText,
    required this.onChoiceA,
    required this.onChoiceB,
  });
}

class NeighborEncounterCatalog {
  static NeighborEncounter? getEncounterForNpc(String name) {
    final list = allEncounters.where((e) => e.npcName == name).toList();
    return list.isNotEmpty ? list.first : null;
  }

  static final List<NeighborEncounter> allEncounters = [
    NeighborEncounter(
      npcName: 'Father Gregor Zweifel',
      faction: 'Glarus',
      cottageId: 'cottage_gregor',
      introDialog:
          'My child, the local parishioners are terrified of unholy, glowing lights emanating from the Manor\'s basement. I must ask what profane experiments you are conducting in this holy valley.',
      choiceAText:
          'Reassure him that it is simple, harmless phosphorescent science.',
      choiceBText:
          'Warn him that the secrets of the Manor are not for the eyes of prying priests.',
      outcomeAText:
          'The priest seems mollified by your calm, scientific explanation. (+0.2 Glarus Standing)',
      outcomeBText:
          'The priest shivers and backs away, eyes narrowed in suspicion. (-0.2 Glarus Standing)',
      onChoiceA: (state) => state.adjustFactionStanding('Glarus', 0.2),
      onChoiceB: (state) => state.adjustFactionStanding('Glarus', -0.2),
    ),
    NeighborEncounter(
      npcName: 'Professor Fritz Weishaupt',
      faction: 'Bavarian Illuminati',
      cottageId: 'cottage_fritz',
      introDialog:
          'Greetings. I am Fritz, an initiate under the direction of the Superiors of the Order. We are organizing a secret network of local eyes to perfect human nature and achieve harmony with nature. I demand you pledge to read and think precisely what the Superiors prescribe.',
      choiceAText: 'Sign the pledge and promise obedience to the Superiors.',
      choiceBText:
          'Assert your intellectual independence and refuse to act under another\'s direction.',
      outcomeAText:
          'Fritz nods, satisfied. He hands you a list of mandatory readings. (+0.2 Bavarian Illuminati Standing)',
      outcomeBText:
          'Fritz glares, warning that those who reject the sun of reason shall remain in the dark. (-0.2 Bavarian Illuminati Standing)',
      onChoiceA: (state) =>
          state.adjustFactionStanding('Bavarian Illuminati', 0.2),
      onChoiceB: (state) =>
          state.adjustFactionStanding('Bavarian Illuminati', -0.2),
    ),
    NeighborEncounter(
      npcName: 'Countess Antoinette de Bertier',
      faction: 'Chevaliers de la foi',
      cottageId: 'cottage_antoinette',
      introDialog:
          'Ah, the master of the Manor. I am Countess Antoinette, exiled from my beloved France by the vulgar revolutionary mob. I seek elegant allies to fund a royalist counter-revolution and restore the crown. Will you support our noble cause?',
      choiceAText: 'Pledge that Glarus will always honor noble blood.',
      choiceBText: 'Tell her that the age of kings has passed.',
      outcomeAText:
          'She curtsies elegantly, pleased by your refined demeanor. (+0.2 Chevaliers de la foi Standing)',
      outcomeBText:
          'She gasps, calling you a peasant sympathizer, and sweeps away. (-0.2 Chevaliers de la foi Standing)',
      onChoiceA: (state) =>
          state.adjustFactionStanding('Chevaliers de la foi', 0.2),
      onChoiceB: (state) =>
          state.adjustFactionStanding('Chevaliers de la foi', -0.2),
    ),
    NeighborEncounter(
      npcName: 'Baroness Regina von Stauffacher',
      faction: 'Gnomes of Zurich',
      cottageId: 'cottage_regina',
      introDialog:
          'Business at last. I am Regina, coordinating secret vaults for the Gnomes. Your Manor holds considerable land value, but also significant liabilities. We are offering a lines-of-credit partnership. Shall we agree to secure your assets?',
      choiceAText:
          'Sign the banking partnership to secure your financial future.',
      choiceBText:
          'Reject their credit, declaring that Glarus answers to no banker.',
      outcomeAText:
          'She smiles coldly, registering your signature in her ledger. (+0.2 Gnomes of Zurich Standing)',
      outcomeBText:
          'She closes her ledger, warning that unpaid debts have a habit of accumulating. (-0.2 Gnomes of Zurich Standing)',
      onChoiceA: (state) =>
          state.adjustFactionStanding('Gnomes of Zurich', 0.2),
      onChoiceB: (state) =>
          state.adjustFactionStanding('Gnomes of Zurich', -0.2),
    ),
    NeighborEncounter(
      npcName: 'Johannes the Hermit',
      faction: 'Rosicrucians',
      cottageId: 'cottage_johannes',
      introDialog:
          'Peace be upon this house. I am Johannes, a simple hermit seeking the alchemical transformation of the soul. I have sensed deep spiritual resonances within your laboratory. Will you permit me to study your research notes in pursuit of the Great Work?',
      choiceAText: 'Open your scientific archives to the mystic alchemist.',
      choiceBText: 'Keep your notes secure, warning him against occult prying.',
      outcomeAText:
          'He bows deeply, offering a silent blessing for your generosity. (+0.2 Rosicrucians Standing)',
      outcomeBText:
          'He sighs, noting that the path to true wisdom is often locked by fear. (-0.2 Rosicrucians Standing)',
      onChoiceA: (state) => state.adjustFactionStanding('Rosicrucians', 0.2),
      onChoiceB: (state) => state.adjustFactionStanding('Rosicrucians', -0.2),
    ),
    NeighborEncounter(
      npcName: 'Seamus O\'Connor',
      faction: 'Fenian Brotherhood',
      cottageId: 'cottage_seamus',
      introDialog:
          'Aye, you must be the landlord. I am Seamus, representing the Fenian Brotherhood. We are preparing a grand uprising against the oppressors, and we need iron and powder. Help us arm the rebellion, and we will remember our friends.',
      choiceAText: 'Promise to provide weapons and harbor their fighters.',
      choiceBText: 'Warn them that Glarus will not harbor violent rebels.',
      outcomeAText:
          'He clasps your hand with a fierce grin. "For freedom, then!" (+0.2 Fenian Brotherhood Standing)',
      outcomeBText:
          'He spits on the floor, warning that those who stand with the crown will burn with it. (-0.2 Fenian Brotherhood Standing)',
      onChoiceA: (state) =>
          state.adjustFactionStanding('Fenian Brotherhood', 0.2),
      onChoiceB: (state) =>
          state.adjustFactionStanding('Fenian Brotherhood', -0.2),
    ),
    NeighborEncounter(
      npcName: 'Elspeth Luchsinger',
      faction: 'Ancient Order of Foresters',
      cottageId: 'cottage_elspeth',
      introDialog:
          'Halt, city dweller. I am Elspeth of the Foresters. Your servants have been felling trees and disturbing the ancient spirits of the wood. The grove demands you cease your logging and respect the ancient boundaries of the valley.',
      choiceAText: 'Promise to limit logging and protect the sacred groves.',
      choiceBText: 'Declare that the estate\'s resources belong to the Manor.',
      outcomeAText:
          'She relaxes, her eyes softening as she whistles to her bear companion. (+0.2 Foresters Standing)',
      outcomeBText:
          'She glares, warning that the forest remembers every axe blow. (-0.2 Foresters Standing)',
      onChoiceA: (state) =>
          state.adjustFactionStanding('Ancient Order of Foresters', 0.2),
      onChoiceB: (state) =>
          state.adjustFactionStanding('Ancient Order of Foresters', -0.2),
    ),
    NeighborEncounter(
      npcName: 'Giuseppe Rossi',
      faction: 'Carbonari',
      cottageId: 'cottage_giuseppe',
      introDialog:
          'Salute, comrade. I am Giuseppe. We are the Carbonari, the charcoal burners who spark the flames of liberty! We are organizing the workers of the valley to rise against their masters. Will you stand with the working class, or are you a tyrant?',
      choiceAText: 'Pledge to improve servant wages and support labor unions.',
      choiceBText: 'Warn him that the Manor operates under strict hierarchy.',
      outcomeAText:
          'He raises a fist, shouting a cheer for the revolution! (+0.2 Carbonari Standing)',
      outcomeBText:
          'He scowls, declaring that the aristocracy will be the first to meet the flames. (-0.2 Carbonari Standing)',
      onChoiceA: (state) => state.adjustFactionStanding('Carbonari', 0.2),
      onChoiceB: (state) => state.adjustFactionStanding('Carbonari', -0.2),
    ),
    NeighborEncounter(
      npcName: 'Godfrey de Molay',
      faction: 'Knights Templar',
      cottageId: 'cottage_godfrey',
      introDialog:
          'In the name of the Temple, greetings. I am Godfrey, hunting the occult anomalies that plague this valley. Your scientific endeavors border on the heretical. Will you submit your laboratory for a Templar inspection to ensure purity?',
      choiceAText: 'Open your laboratory doors to the Templar knights.',
      choiceBText: 'Assert that the laboratory is private scientific ground.',
      outcomeAText:
          'He nods grimly, his knights marching in to inspect the rooms. (+0.2 Knights Templar Standing)',
      outcomeBText:
          'He lays a hand on his sword hilt, warning that heresy will be purged. (-0.2 Knights Templar Standing)',
      onChoiceA: (state) => state.adjustFactionStanding('Knights Templar', 0.2),
      onChoiceB: (state) =>
          state.adjustFactionStanding('Knights Templar', -0.2),
    ),
    NeighborEncounter(
      npcName: 'Lilith Crowley',
      faction: 'Golden Dawn',
      cottageId: 'cottage_lilith',
      introDialog:
          'Greetings, traveler. I am Lilith of the Golden Dawn. I have traversed the astral planes to find you. Your soul holds a rare resonance, capable of anchoring great magic. Will you join our hermetic circle and explore the mysteries of the unseen?',
      choiceAText:
          'Express interest in the occult and agree to participate in rituals.',
      choiceBText: 'Assert that Glarus relies on empirical science, not magic.',
      outcomeAText:
          'She smiles mysteriously, her eyes flashing with otherworldly light. (+0.2 Golden Dawn Standing)',
      outcomeBText:
          'She sighs, warning that those who rely only on sight are blind to the universe. (-0.2 Golden Dawn Standing)',
      onChoiceA: (state) => state.adjustFactionStanding('Golden Dawn', 0.2),
      onChoiceB: (state) => state.adjustFactionStanding('Golden Dawn', -0.2),
    ),
    NeighborEncounter(
      npcName: 'Mary Shelley',
      faction: 'Glarus',
      cottageId: 'cottage_mary',
      introDialog:
          'My child, I have heard of the tragedy that befell your family. In times of such deep sorrow, the mind can wander to very dark places. Please tell me you are not letting your grief lead you down a path of obsession.',
      choiceAText:
          'Assure her that your studies are a noble pursuit to understand nature and ease human suffering.',
      choiceBText:
          'Proclaim that you will find a way to conquer mortality and bring back what was lost, at any cost.',
      outcomeAText:
          'Mary sighs softly, touching your arm with her pale hand. "Grief makes monsters of us all. Be careful, creator." (+0.20 Glarus Standing)',
      outcomeBText:
          'Mary draws back, her eyes filled with concern and fear. "To defy the natural order is to invite your own destruction." (-0.20 Glarus Standing)',
      onChoiceA: (state) => state.adjustFactionStanding('Glarus', 0.2),
      onChoiceB: (state) => state.adjustFactionStanding('Glarus', -0.2),
    ),
    NeighborEncounter(
      npcName: 'Percy Bysshe Shelley',
      faction: 'Bavarian Illuminati',
      cottageId: 'cottage_percy',
      introDialog:
          'Ah, creator! Your research into vitalism is magnificent. Galvani\'s frog muscles and Erasmus Darwin\'s spontaneous generation prove that electricity is the vital fluid analogous to the human soul. Let us collaborate and build a Leyden Jar grid to capture the lightning!',
      choiceAText: 'Enthusiastically agree and pledge your laboratory resources to his electrical research.',
      choiceBText:
          'Dismiss his theories as romantic poetry; assert your focus is purely empirical chemistry.',
      outcomeAText:
          'Percy beams with excitement, gesturing to his sketches of atmospheric conductor grids. (+0.20 Bavarian Illuminati Standing)',
      outcomeBText:
          'Percy scowls, calling your science unimaginative and pedantic before pocketing his journals. (-0.20 Bavarian Illuminati Standing)',
      onChoiceA: (state) =>
          state.adjustFactionStanding('Bavarian Illuminati', 0.2),
      onChoiceB: (state) =>
          state.adjustFactionStanding('Bavarian Illuminati', -0.2),
    ),
    NeighborEncounter(
      npcName: 'Lord Byron',
      faction: 'Gnomes of Zurich',
      cottageId: 'cottage_byron',
      introDialog:
          'Business at last. I have run from suffocating debt and societal rumors in London to Diodati. Your estate is fine, but lacks capital. I offer massive venture funding for your unholy marvels, but expect full partnership. Do we strike a deal?',
      choiceAText:
          'Accept his funding, welcoming his aristocratic patronage to double your resources.',
      choiceBText:
          'Refuse his money, stating that Frankenstein Manor is not a toy for bored lords.',
      outcomeAText:
          'Byron laughs heartily, signing a draft for gold reserves in his ledger. (+0.20 Gnomes of Zurich Standing)',
      outcomeBText:
          'Byron sneers, muttering that your pride matches your poverty, and snaps his ledger shut. (-0.20 Gnomes of Zurich Standing)',
      onChoiceA: (state) =>
          state.adjustFactionStanding('Gnomes of Zurich', 0.2),
      onChoiceB: (state) =>
          state.adjustFactionStanding('Gnomes of Zurich', -0.2),
    ),
    NeighborEncounter(
      npcName: 'Claire Clairmont',
      faction: 'Carbonari',
      cottageId: 'cottage_claire',
      introDialog:
          'Greetings. I am Claire. My daughter Allegra is held by Byron\'s cruel command in a remote convent, and local peasants are crushed by local taxes. I coordinate the Carbonari charcoal-burners lodge in the Jura woods. Help me harbor resources, and we will guide your paths through the wild.',
      choiceAText: 'Agree to assist the Carbonari network and provide cover for her operations.',
      choiceBText: 'Decline to get involved in local insurgencies and marital disputes.',
      outcomeAText:
          'Claire raises a clenched hand in solidarity, sharing a map of secret forest passes. (+0.20 Carbonari Standing)',
      outcomeBText:
          'Claire glares at you, warning that those who ignore the Carbonari will find no safety in the woods. (-0.20 Carbonari Standing)',
      onChoiceA: (state) => state.adjustFactionStanding('Carbonari', 0.2),
      onChoiceB: (state) => state.adjustFactionStanding('Carbonari', -0.2),
    ),
    NeighborEncounter(
      npcName: 'Dr. John Polidori',
      faction: 'Rosicrucians',
      cottageId: 'cottage_polidori',
      introDialog:
          'Greetings, colleague. I am Polidori, Byron\'s physician. I study the siphoning of organic tissue—the modern vampire. My medical notebooks contain alchemical and biological repair formulas that can heal your creations. Will you share your research files with me?',
      choiceAText: 'Open your anatomical research files to the cynical physician.',
      choiceBText: 'Keep your notes secure, warning him against occult prying.',
      outcomeAText:
          'Polidori nods grimly, sharing a treatise on blood-siphoning algorithms. (+0.20 Rosicrucians Standing)',
      outcomeBText:
          'Polidori sneers, noting that a plagiarist\'s shadow makes everyone paranoid. (-0.20 Rosicrucians Standing)',
      onChoiceA: (state) => state.adjustFactionStanding('Rosicrucians', 0.2),
      onChoiceB: (state) => state.adjustFactionStanding('Rosicrucians', -0.2),
    ),
  ];
}
