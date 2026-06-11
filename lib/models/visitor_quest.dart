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

import 'objective.dart';
import 'contract.dart';

class VisitorQuest {
  final String id;
  final String title;
  final String teaserQuote;   // Request 4A
  final String detailedDialog; // Request 4B
  final Objective objective;   // Request 4C
  final Contract? agreement;   // Request 4C
  final String acceptMessage;
  final String denyMessage;

  VisitorQuest({
    required this.id,
    required this.title,
    required this.teaserQuote,
    required this.detailedDialog,
    required this.objective,
    this.agreement,
    required this.acceptMessage,
    required this.denyMessage,
  });
}

class VisitorQuestCatalog {
  static List<VisitorQuest> get allQuests => [
    VisitorQuest(
      id: 'quest_theater_venture',
      title: 'THEATER VENTURE PROPOSAL',
      teaserQuote: "I was looking at all the space you have here and I said, this has got to be a new theater!",
      detailedDialog: "Glarus and the surrounding alpine border towns have no grand cultural hub! With your immense inherited spaces and my theatrical direction, we could establish a spectacular Grand Victorian Theater inside your East Wing. We will split ownership 50/50, and you will provide an initial capital grant of 800 Francs and timber materials.",
      objective: Objective(
        id: 'obj_theater',
        title: 'Grand Victorian Theater Venture',
        description: 'Provide 800 Funds to co-establish the East Wing Grand Theater.',
        type: ObjectiveType.venture,
        requirements: {'cash': 800},
      ),
      agreement: Contract(
        id: 'agreement_theater',
        npcId: 'Theater Director',
        type: ContractType.service,
        description: 'Joint Business Venture Agreement: 50/50 Shared Control and Ownership of the East Wing Grand Victorian Theater.',
        terms: const {'shared_ownership': '50%', 'venture': 'Theater'},
      ),
      acceptMessage: "Grand Theater joint venture accepted! Agreement added to Manor Records.",
      denyMessage: "You politely declined the theatrical venture. The visitor nods in disappointment.",
    ),
    VisitorQuest(
      id: 'quest_bakery_venture',
      title: 'BAKERY VENTURE PROPOSAL',
      teaserQuote: "Have you ever considered opening a bakery?",
      detailedDialog: "The traveling merchants and border guards are clamoring for fresh alpine loaves and sweet pastries! If we sign a Joint Supplier & Bakery Agreement, I will deliver fresh flour and yeast every 3 days, and your estate kitchen can operate as a commercial Bakery for massive daily profit.",
      objective: Objective(
        id: 'obj_bakery',
        title: 'Alpine Bakery Venture',
        description: 'Restore the Kitchen and refine 15 Sheet Pastas or sweet loaves.',
        type: ObjectiveType.venture,
        requirements: {'task_counts': {'refineFood': 15}},
      ),
      agreement: Contract(
        id: 'agreement_bakery',
        npcId: 'Commercial Supplier',
        type: ContractType.deliverable,
        description: 'Supplier & Joint Venture Agreement: Guaranteed periodic shipments of flour and shared profits from Alpine Bakery operations.',
        terms: const {'shipment_interval_days': 3, 'venture': 'Bakery'},
      ),
      acceptMessage: "Alpine Bakery joint venture accepted! Agreement added to Manor Records.",
      denyMessage: "You declined the commercial bakery arrangement. The visitor sighs.",
    ),
    VisitorQuest(
      id: 'quest_fugitive_sanctuary',
      title: 'FUGITIVE SANCTUARY OPPORTUNITY',
      teaserQuote: "I'll happily work here for free if you can help me hide from the law.",
      detailedDialog: "I am being hunted by the Royalist standard bearers for revolutionary alchemical distribution! If you provide me with permanent sanctuary, a secluded servant bed, and protect me from the Glarus magistrates, I will serve your laboratory and estate as an indentured servant with zero wages forever.",
      objective: Objective(
        id: 'obj_fugitive',
        title: 'Fugitive Sanctuary',
        description: 'Maintain complete physical sanctuary and laboratory servitude for the revolutionary fugitive.',
        type: ObjectiveType.manor,
        requirements: {'room_restored': 'attic'},
      ),
      agreement: Contract(
        id: 'agreement_fugitive',
        npcId: 'Revolutionary Fugitive',
        type: ContractType.employment,
        description: 'Indentured Sanctuary Agreement: Permanent servitude and laboratory assistance in exchange for complete legal and physical asylum.',
        terms: const {'wages': 0, 'duration': 'Permanent'},
      ),
      acceptMessage: "Fugitive asylum granted! Sanctuary agreement recorded in Manor Records.",
      denyMessage: "You refused sanctuary. The fugitive slips back into the alpine shadows.",
    ),
    VisitorQuest(
      id: 'quest_bandit_bounty',
      title: 'HIGHWAY BANDIT ELIMINATION BOUNTY',
      teaserQuote: "I'll pay you 500 francs to go kill those bandits plaguing the road to Glarus.",
      detailedDialog: "A ruthless cell of Fenian night raiders and highwaymen has barricaded the alpine pass to Glarus! My merchant wagons cannot get through. Deploy your premier combat unit to clean out the bandits, and I will disburse an immediate cash bounty of 500 Francs upon completion.",
      objective: Objective(
        id: 'obj_bandit',
        title: 'Highway Bandit Dispersal',
        description: 'Deploy your forces to achieve tactical combat victory against the highway raiders.',
        type: ObjectiveType.combat,
        requirements: {'combat_victories': 1},
      ),
      agreement: Contract(
        id: 'agreement_bounty',
        npcId: 'Merchant Caravan',
        type: ContractType.service,
        description: 'Security Dispersal Bounty Agreement: Guaranteed payment of 500 Francs disbursed upon verification of bandit elimination along the Glarus alpine road.',
        terms: const {'bounty': 500, 'target': 'Highway Bandits'},
      ),
      acceptMessage: "Bandit elimination bounty accepted! Security agreement added to Manor Records.",
      denyMessage: "You denied the security request. The traveler warns that the highway remains perilous.",
    ),
  ];
}
