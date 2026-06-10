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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/npc.dart';
import '../../models/combat_stats.dart';
import '../../services/combat_unit_factory.dart';
import '../widgets/character_blob_renderer.dart';
import '../widgets/combat_card_detail_modal.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  String _glossarySearchQuery = '';

  late final List<NPC> _allCombatCards;

  @override
  void initState() {
    super.initState();
    // Mobile-optimized compact 2-tab layout
    _tabController = TabController(length: 2, vsync: this);

    _allCombatCards = [
      CombatUnitFactory.createFootman(),
      CombatUnitFactory.createGoons(),
      CombatUnitFactory.createMilitia(),
      CombatUnitFactory.createPikemen(),
      CombatUnitFactory.createHalberdiers(),
      CombatUnitFactory.createMarksmen(),
      CombatUnitFactory.createSniper(),
      CombatUnitFactory.createCannoneer(),
      CombatUnitFactory.createCavalry(),
      CombatUnitFactory.createBicycleGang(),
      CombatUnitFactory.createMotorcycleGang(),
      CombatUnitFactory.createArmoredCar(),
      CombatUnitFactory.createWoodenTank(),
      CombatUnitFactory.createBats(),
      CombatUnitFactory.createUndeadRats(),
      CombatUnitFactory.createBrownRats(),
      CombatUnitFactory.createWerewolf(),
      CombatUnitFactory.createChimera(),
      CombatUnitFactory.createFleshGolem(),
      CombatUnitFactory.createMasonicSapper(),
      CombatUnitFactory.createSacredGeometry(),
      CombatUnitFactory.createHomunculusBehemoth(),
      CombatUnitFactory.createElixirOfVitality(),
      CombatUnitFactory.createTemplarPyreKnight(),
      CombatUnitFactory.createGreekFireFlask(),
      CombatUnitFactory.createVaultAssassin(),
      CombatUnitFactory.createZurichDebtCollector(),
      CombatUnitFactory.createCarbonariArsonist(),
      CombatUnitFactory.createRevolutionaryMartyr(),
      CombatUnitFactory.createHermeticMesmerist(),
      CombatUnitFactory.createAstralHypnosis(),
      CombatUnitFactory.createFenianNightRaider(),
      CombatUnitFactory.createInsurgentCell(),
      CombatUnitFactory.createRoyalistCuirassier(),
      CombatUnitFactory.createRoyalistStandardBearer(),
      CombatUnitFactory.createForesterHerbalist(),
      CombatUnitFactory.createForesterBeastmaster(),
    ];

    _sortCards();
  }

  void _sortCards() {
    _allCombatCards.sort((a, b) {
      final sA = a.combatStats ?? const CombatStats(attack: 0, health: 1, maxHealth: 1, speed: 1.0, movement: 0.0, distance: 0.0, cost: 0);
      final sB = b.combatStats ?? const CombatStats(attack: 0, health: 1, maxHealth: 1, speed: 1.0, movement: 0.0, distance: 0.0, cost: 0);
      int cmp = 0;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.name.compareTo(b.name);
          break;
        case 1:
          cmp = a.role.compareTo(b.role);
          break;
        case 2:
          cmp = sA.cost.compareTo(sB.cost);
          break;
        case 3:
          cmp = sA.health.compareTo(sB.health);
          break;
        case 4:
          cmp = sA.attack.compareTo(sB.attack);
          break;
        case 5:
          final dpsA = sA.attack / (sA.speed > 0 ? sA.speed : 1.0);
          final dpsB = sB.attack / (sB.speed > 0 ? sB.speed : 1.0);
          cmp = dpsA.compareTo(dpsB);
          break;
        case 6:
          cmp = sA.movement.compareTo(sB.movement);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });
  }

  String _extractBaseCardKey(NPC npc) {
    if (npc.metadata.containsKey('cardType')) {
      return npc.metadata['cardType']!;
    }
    return npc.name.toLowerCase().replaceAll(' ', '_');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15100B),
      // Ultra-compact mobile-optimized top bar: leading back button + embedded slim tab bar (omitting redundant screen title entirely)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48.0),
        child: AppBar(
          backgroundColor: const Color(0xFF1D1712),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: TabBar(
            controller: _tabController,
            isScrollable: true,
            physics: const BouncingScrollPhysics(),
            indicatorColor: const Color(0xFFD4AF37),
            indicatorWeight: 2.5,
            labelColor: const Color(0xFFD4AF37),
            unselectedLabelColor: const Color(0xFFC4B89B).withValues(alpha: 0.6),
            labelStyle: GoogleFonts.oswald(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            labelPadding: const EdgeInsets.symmetric(horizontal: 14),
            tabs: const [
              Tab(iconMargin: EdgeInsets.zero, child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.shield_outlined, size: 16), SizedBox(width: 6), Text('COMBAT MANUAL & SPECS')])),
              Tab(iconMargin: EdgeInsets.zero, child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.menu_book_outlined, size: 16), SizedBox(width: 6), Text('ENCYCLOPEDIC GLOSSARY')])),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildCombatManualTab(),
            _buildGlossaryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCombatManualTab() {
    return Column(
      children: [
        // Mobile-optimized compact overview banner
        Container(
          decoration: BoxDecoration(color: const Color(0xFF1E1813), border: Border(bottom: BorderSide(color: const Color(0xFFC4B89B).withValues(alpha: 0.2)))),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            collapsedIconColor: const Color(0xFFD4AF37),
            iconColor: const Color(0xFFD4AF37),
            title: Text(
              'HOW COMBAT WORKS (BROAD STROKES OVERVIEW)',
              style: GoogleFonts.playfairDisplay(color: const Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            subtitle: Text('Tap to expand lanes, Action Points (AP) & elemental warfare rules', style: GoogleFonts.oldStandardTt(color: Colors.white60, fontSize: 12, fontStyle: FontStyle.italic)),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _manualPoint(
                    'The Battlefield Expanse & Channeling',
                    'Combat occurs across an edge-to-edge arena split into three horizontal lanes (Top, Center, Bottom). Your Commander commands the rear left base while the enemy Hero commands the rear right. Summoned squads autonomously march down lane centers straight toward the opposing fortress.',
                  ),
                  _manualPoint(
                    'Action Point (AP) Economics',
                    'Your Action Point pool regenerates continuously during live engagements at +1.5 AP per second up to a maximum pool of 10.0 AP. Deploying tactical unit cards instantly deducts their AP cost from your active reserves.',
                  ),
                  _manualPoint(
                    'Esoteric Elemental Dynamics',
                    '• Greek Fire: Incendiary canisters and Templar Pyre blades ignite targets with persistent fire damage over time (DOT); flames have a probability coefficient to spread across frontlines.\n'
                    '• Toxin Spores: Poison Gas and Fenian dirks inflict internal poison stacking DOT that entirely bypasses standard physical armor plates.\n'
                    '• Willpower Subversion: Golden Dawn Mesmerists and Hypnotic pendulums seize control of rival cognitive willpower, temporarily flipping enemy troop allegiance to fight for your squad.',
                  ),
                ],
              ),
            ],
          ),
        ),

        // Mobile-Optimized Spreadsheet Header Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF15100B),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TACTICAL SPREADSHEET (${_allCombatCards.length} UNITS)',
                style: GoogleFonts.oswald(color: const Color(0xFFE5D5B0), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              Text(
                'Tap headers to sort • Tap rows for specs modal',
                style: GoogleFonts.oldStandardTt(color: const Color(0xFFD4AF37), fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),

        // Mobile-Optimized Highly Compact Spreadsheet Table
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            decoration: BoxDecoration(color: const Color(0xFF120C08), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.3))),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: DataTable(
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  // Mobile-optimized tight vertical row cushioning
                  dataRowMinHeight: 30,
                  dataRowMaxHeight: 34,
                  headingRowHeight: 32,
                  columnSpacing: 14,
                  horizontalMargin: 10,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFF241C15)),
                  dataRowColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                    if (states.contains(WidgetState.hovered)) return const Color(0xFF2E241C);
                    return Colors.transparent;
                  }),
                  border: TableBorder.all(color: Colors.white10, width: 0.5),
                  columns: [
                    _dataColumn('CARD NAME', 0),
                    _dataColumn('ROLE / FACTION', 1),
                    _dataColumn('AP COST', 2, isNumeric: true),
                    _dataColumn('HEALTH', 3, isNumeric: true),
                    _dataColumn('DMG / ATK', 4, isNumeric: true),
                    _dataColumn('DPS', 5, isNumeric: true),
                    _dataColumn('SPEED', 6, isNumeric: true),
                  ],
                  rows: _allCombatCards.map((npc) {
                    final stats = npc.combatStats ?? const CombatStats(attack: 0, health: 1, maxHealth: 1, speed: 1.0, movement: 0.0, distance: 0.0, cost: 0);
                    final double dps = stats.attack / (stats.speed > 0 ? stats.speed : 1.0);
                    return DataRow(
                      onSelectChanged: (_) => CombatCardDetailModal.show(context, _extractBaseCardKey(npc)),
                      cells: [
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: const BoxDecoration(color: Color(0xFF2A221C), shape: BoxShape.circle),
                              child: ClipOval(child: Center(child: CharacterBlobRenderer(npc: npc, size: 18, isCombat: true))),
                            ),
                            Text(npc.name, style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        )),
                        DataCell(Text(npc.metadata.containsKey('faction') ? npc.metadata['faction']! : npc.role, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                        DataCell(Text('${stats.cost} AP', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 11))),
                        DataCell(Text('${stats.health} HP', style: const TextStyle(color: Colors.greenAccent, fontSize: 11))),
                        DataCell(Text(stats.attack > 0 ? '${stats.attack}' : '-', style: const TextStyle(color: Colors.white, fontSize: 11))),
                        DataCell(Text(stats.attack > 0 ? dps.toStringAsFixed(1) : '-', style: const TextStyle(color: Colors.orangeAccent, fontSize: 11))),
                        DataCell(Text('${stats.movement} ft/s', style: const TextStyle(color: Colors.cyanAccent, fontSize: 11))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataColumn _dataColumn(String label, int index, {bool isNumeric = false}) {
    return DataColumn(
      label: Text(label, style: GoogleFonts.oswald(color: const Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold)),
      numeric: isNumeric,
      onSort: (colIndex, ascending) {
        setState(() {
          _sortColumnIndex = colIndex;
          _sortAscending = ascending;
          _sortCards();
        });
      },
    );
  }

  Widget _manualPoint(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.oswald(color: const Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(desc, style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 12, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildGlossaryTab() {
    final List<Map<String, dynamic>> glossaryArticles = [
      // ROOMS & WINGS (Exhaustively detailed with precise construction costs, plot locations, and exact production outputs)
      {
        'title': 'Alchemical Laboratory',
        'category': 'Room / Wing',
        'desc': 'Advanced chemical and occult research wing.\n\n'
                '• Construction Cost: Precisely 450 CHF cash reserves plus 25 Wood timber planks and 15 Iron metal ingots. Requires formal Library archive as a structural prerequisite.\n'
                '• Plot Location: Can be converted from any vacant unassigned ground-floor or basement East/West Wing chamber inside the primary Manor Fortress.\n'
                '• Production Outputs: Staffed by hermetic scholars and chemists to synthesize Elixir of Vitality (100 CHF, 10 Herbs; restores 100% squad HP instantly), craft volatile Greek Fire Flask incendiary canisters (85 CHF, 10 Iron), synthesize Tear Gas riot canisters (60 CHF, 5 Herbs), and perform forbidden flesh golem anatomical stitching (Flesh Golem squad card: 200 CHF, 40 Food harvests).'
      },
      {
        'title': 'Armory',
        'category': 'Room / Wing',
        'desc': 'Tactical military outfitting and ordnance staging chamber.\n\n'
                '• Construction Cost: Precisely 350 CHF cash reserves plus 30 Wood planks and 20 Iron metal ingots.\n'
                '• Plot Location: Can be converted from any vacant West Wing ground-floor staging chamber.\n'
                '• Production Outputs: Outfits raw recruit squads with heavy iron breastplates (+20 HP) prior to Arena proving ground deployments and conducts metallurgical weapon honing (+15% physical melee and firearm DPS coefficient per armory upgrade tier).'
      },
      {
        'title': 'Brewery',
        'category': 'Room / Wing',
        'desc': 'Subterranean distillation hall and working-class pub wing.\n\n'
                '• Construction Cost: Precisely 280 CHF cash reserves plus 40 Wood timber planks.\n'
                '• Plot Location: Can be erected inside any subterranean basement brick vault under the Manor.\n'
                '• Production Outputs: Transforms raw agricultural Barley grain harvests into Restorative Ale casks (Cost: 5 Barley per cask; instantly restores +25 Manor morale) and unlocks the recruitment of fearless pub brawler mercenary squads (Recruitment Cost: 25 CHF, 2 Ale casks).'
      },
      {
        'title': 'Kitchen & Scullery',
        'category': 'Room / Wing',
        'desc': 'Culinary food processing and dietary contract fulfillment wing.\n\n'
                '• Construction Cost: Baseline scullery facility costs precisely 150 CHF plus 20 Wood planks.\n'
                '• Plot Location: Erected inside the Manor ground-floor service wing adjacent to dining rooms.\n'
                '• Production Outputs: Staffed by scullions and master chefs to transform raw agricultural harvests (Potatoes, Wheat, Raw Fish, Game Poultry) into standard daily resident sustenance meals (Yields precisely 3 daily caloric meals per raw Food harvest unit) and lavish aristocratic banquet dishes.'
      },
      {
        'title': 'Library',
        'category': 'Room / Wing',
        'desc': 'Scholarly reading room and esoteric archive wing.\n\n'
                '• Construction Cost: Precisely 300 CHF cash reserves plus 50 Wood timber planks for shelving.\n'
                '• Plot Location: Converted inside formal East Wing quiet holding chambers.\n'
                '• Production Outputs: Staffed by hired thinkers to generate a continuous flow of +2.5 Academic Research Points per minute, unlocking Heidelberg philosophy university doctrines and deep secret society priorate charters.'
      },
      {
        'title': 'Sleeping Quarters',
        'category': 'Room / Wing',
        'desc': 'Residential staff dormitory wings.\n\n'
                '• Construction Cost: Precisely 100 CHF cash reserves plus 15 Wood planks per bedstead tier.\n'
                '• Plot Location: Built inside the upper floor dormitory gallery wings.\n'
                '• Production Outputs: Provides formal lodging for hired resident staff; upgrading bedsteads increases total maximum estate population capacity by +4 formal staff members per level.'
      },

      // CROPS
      {
        'title': 'Barley',
        'category': 'Crop',
        'desc': 'Hardy winter cereal grain.\n\n'
                '• Planting & Maturity: Sow tillable plots during Autumn or Winter months; requires precisely 3 days (72 hours) until full agricultural harvest maturity.\n'
                '• Yields & Usage: Yields precisely 12 Raw Barley bushels per acre. Transported directly to the Brewery hall to mash and ferment restorative ales or fed to scullery livestock.'
      },
      {
        'title': 'Potatoes',
        'category': 'Crop',
        'desc': 'Versatile subterranean root tuber.\n\n'
                '• Planting & Maturity: Plant inside loamy soil fields during Spring months; requires precisely 2 days (48 hours) until full harvest extraction.\n'
                '• Yields & Usage: Yields precisely 20 Raw Food caloric units per acre. Forms the essential low-cost dietary staple required every morning at 06:00 to keep basic manor laborers alive and desertion-free.'
      },
      {
        'title': 'Wheat',
        'category': 'Crop',
        'desc': 'Golden summer agricultural cereal grain.\n\n'
                '• Planting & Maturity: Plant in exposed sunlit fields during Spring or Summer months; requires precisely 4 days (96 hours) until harvest reaping.\n'
                '• Yields & Usage: Yields precisely 15 Raw Wheat sheaves per acre. Ground inside scullery windmills into refined white flour, fulfilling advanced pastry baking recipes and elevating global manor prestige.'
      },

      // DISHES
      {
        'title': 'Bouillabaisse',
        'category': 'Dish / Culinary',
        'desc': 'Luxurious Mediterranean seafood saffron stew.\n\n'
                '• Prerequisites: Requires active Kitchen Scullery Level 2 plus Coastal Trade Wharf access.\n'
                '• Resource Costs: precisely 2 Raw Fish harvests, 1 Vegetable unit, 1 Saffron Herb vial.\n'
                '• Dietary Impact: Serves precisely 4 lavish high-tier meals. Consuming this dish maximizes local resident morale and grants a +25% cognitive focus coefficient to Alchemical Lab researchers.'
      },
      {
        'title': 'Coq au Vin',
        'category': 'Dish / Culinary',
        'desc': 'Aristocratic braised poultry and mushroom reduction.\n\n'
                '• Resource Costs: Precisely 2 Poultry meat units, 1 Red Wine vintage bottle, 2 Vegetables.\n'
                '• Dietary Impact: Serves precisely 6 premium meals. Significantly elevates manor dining reputation (+15 sovereign prestige) and satisfies elite resident contractual food mandates.'
      },
      {
        'title': 'Hearty Stew',
        'category': 'Dish / Culinary',
        'desc': 'Standard working-class meat broth.\n\n'
                '• Resource Costs: Precisely 1 Raw Meat unit, 1 Potato tuber, 1 Raw Vegetable harvest.\n'
                '• Dietary Impact: Serves precisely 3 nutritious working meals. Satisfies daily baseline resident caloric expenditure without requiring advanced scullery kitchen conversions.'
      },
      {
        'title': 'Roast Pheasant',
        'category': 'Dish / Culinary',
        'desc': 'Deep-woods wild game bird roast.\n\n'
                '• Resource Costs: Precisely 2 Wild Game Fowl meat units, 1 Wild Woodland Herb vial.\n'
                '• Dietary Impact: Serves precisely 4 lavish meals. Exceptionally favored by hired Foresters, Beastmasters, and marksmen squads, permanently increasing their battlefield movement speed by +5%.'
      },

      // RESOURCES
      {
        'title': 'Cash (CHF)',
        'category': 'Resource',
        'desc': 'Sovereign Swiss Francs, the fundamental economic reserve currency.\n\n'
                '• Acquisition Methods: Accumulated via Zurich banking syndicate interest dividends, underground debt collector bounties, Arena tournament victory purses (up to 1,500 CHF in Tier 5 runs), and surplus agricultural grain exports.\n'
                '• Primary Expenditure: Essential for weekly resident staff payrolls, purchasing heavy iron ordnance, and financing structural room conversions.'
      },
      {
        'title': 'Food',
        'category': 'Resource',
        'desc': 'Edible caloric sustenance units.\n\n'
                '• Acquisition Methods: Harvested from tillable soil crop fields, garden conservatories, and fishing trade wharves.\n'
                '• Primary Expenditure: Automatically consumed every morning at precisely 06:00 (1 meal per active resident). Failure to maintain sufficient food stocks causes resident starvation desertions and troop desertions.'
      },
      {
        'title': 'Iron',
        'category': 'Resource',
        'desc': 'Heavy unrefined metallic ingots.\n\n'
                '• Acquisition Methods: Smelted from subterranean estate ore veins or purchased from visiting industrial iron merchants (Standard Rate: 12 CHF per ingot).\n'
                '• Primary Expenditure: Required for vehicle plating (Armored Cars, Tanks), forging Templar flaming greatswords, and armory reinforcement tiers.'
      },
      {
        'title': 'Wood',
        'category': 'Resource',
        'desc': 'Sturdy timber lumber planks.\n\n'
                '• Acquisition Methods: Sawn from estate lumber mills or purchased from regional timber wharves (Standard Rate: 5 CHF per plank).\n'
                '• Primary Expenditure: Required for room conversions, erecting wooden tanks (Cost: 40 Wood), and building perimeter palisade barricades.'
      },

      // SECRET SOCIETIES
      {
        'title': 'Ancient Order of Foresters',
        'category': 'Secret Society',
        'desc': 'Woodland druidic priorate commanded by Chief Ranger Robin.\n\n'
                '• Tactical Specialty: Specializes in botanical toxin spore warfare, rapid wilderness mobility (+15% forest speed), and summoning 450-HP ferocious grizzly bears onto frontline turf.'
      },
      {
        'title': 'Carbonari',
        'category': 'Secret Society',
        'desc': 'Charcoal-burning revolutionary priorate directed by Grand Master Alta Vendita.\n\n'
                '• Tactical Specialty: Specializes in long-range pitch arson, stacking incendiary ground fire, and deploying self-sacrificing shrapnel blast martyrs that inflict 300 true area damage upon death.'
      },
      {
        'title': 'Chevaliers de la foi',
        'category': 'Secret Society',
        'desc': 'Ultra-royalist Catholic banneret network commanded by Ferdinand de Bertier.\n\n'
                '• Tactical Specialty: Specializes in impenetrable heavy Cuirassier shock cavalry wearing heavy iron breastplates and deploying inspirational standard bearers that boost nearby attack speed by +25%.'
      },
      {
        'title': 'Fenian Brotherhood',
        'category': 'Secret Society',
        'desc': 'Irish republican insurgent brotherhood commanded by Head Centre Stephens.\n\n'
                '• Tactical Specialty: Specializes in rapid guerilla cell spawn refills (+50% deployment speed) and venom-dirk raiders inflicting unhealable internal poison DOT.'
      },
      {
        'title': 'Freemasons',
        'category': 'Secret Society',
        'desc': 'Esoteric architectural priorate commanded by Grand Master Hiram Abiff.\n\n'
                '• Tactical Specialty: Specializes in unyielding sacred geometry tactical movement velocity auras (+40% speed) and stone-grey sapper demolition squads that target enemy defense towers exclusively.'
      },
      {
        'title': 'Gnomes of Zurich',
        'category': 'Secret Society',
        'desc': 'Subterranean banking syndicate commanded by Banker Rothschild.\n\n'
                '• Tactical Specialty: Specializes in compounding financial dividends, deploying wealth-yielding debt collector squads (+15 CHF per kill), and dispatching precision vault assassins.'
      },
      {
        'title': 'Golden Dawn',
        'category': 'Secret Society',
        'desc': 'Hermetic occult magical priorate commanded by Imperator Aleister Crowley.\n\n'
                '• Tactical Specialty: Specializes in esoteric cognitive manipulation, deploying Mesmerist occultists and Hypnotic pendulums that subvert rival free will and flip enemy unit allegiance.'
      },
      {
        'title': 'Knights Templar',
        'category': 'Secret Society',
        'desc': 'Holy military priorate commanded by Jacques de Molay.\n\n'
                '• Tactical Specialty: Specializes in unquenchable spreading Greek Fire canisters, fire-immune Pyre Knights, and heavy greatsword execution volleys.'
      },
      {
        'title': 'Rosicrucians',
        'category': 'Secret Society',
        'desc': 'Mystical alchemical brotherhood commanded by Magus Christian Rosenkreuz.\n\n'
                '• Tactical Specialty: Specializes in vitalizing alchemical healing mists and deploying colossal, lumbering 800-HP homunculus flesh behemoths.'
      },

      // SCHOOLS
      {
        'title': 'Bologna School of Law',
        'category': 'Graduate School',
        'desc': 'Ancient jurisprudence academy.\n\n'
                '• Enrollment Benefits: Enrolling scholars here automates the dismissal of periodic municipal tax audits, entirely eliminates legal liability during subterranean syndicate disputes, and secures preferential interest rates (5% bonus yield) on cash deposits.'
      },
      {
        'title': 'Heidelberg School of Philosophy',
        'category': 'Graduate School',
        'desc': 'Romantic German university faculty.\n\n'
                '• Enrollment Benefits: Enrolling thinkers here grants a permanent +25% coefficient to global library research generation points and elevates sovereign manor reputation across European courts.'
      },
      {
        'title': 'Paris Faculty of Medicine',
        'category': 'Graduate School',
        'desc': 'Anatomical surgery institute.\n\n'
                '• Enrollment Benefits: Enrolling physicians here unlocks advanced flesh golem anatomical stitching in the Alchemical Lab and significantly accelerates passive resident wound recovery coefficients (+50% healing rate).'
      },

      // LOCATIONS
      {
        'title': 'Arena Hub (Proving Grounds)',
        'category': 'Location',
        'desc': 'The subterranean tactical Colosseum.\n\n'
                '• Activities: Visit to enter multi-lane Tournament ladders for massive gold purses, playtest custom deck combinations in Skirmish Simulator mode, or engage endless Survival turf defense against invading monster hordes.'
      },
      {
        'title': 'Hamlet (Village Settlement)',
        'category': 'Location',
        'desc': 'The neighboring rural community pub.\n\n'
                '• Activities: Visit to hire mercenary goon brawlers, recruit seasonal agricultural harvest hands (Cost: 15 CHF/day), or purchase rounds of drinks at the tavern to collect regional rumor intelligence.'
      },
      {
        'title': 'Manor Estate Ground',
        'category': 'Location',
        'desc': 'Your primary sovereign headquarters.\n\n'
                '• Activities: Manage tillable soil fields, assign kitchen cooking contracts, construct formal West Wing research chambers, and upgrade perimeter barricade gate defenses.'
      },
      {
        'title': 'World Map Expanse',
        'category': 'Location',
        'desc': 'The grand strategic orientation expanse.\n\n'
                '• Activities: Dispatch Aravt armies and companion squads across hex coordinates to secure vital regional trade wharves and resource wharves.'
      },

      // WEAPONS
      {
        'title': 'Greek Fire Flask',
        'category': 'Weapon / Ordnance',
        'desc': 'Volatile antique incendiary ordnance.\n\n'
                '• Tactical Specs: Fired at intermediate distance (15 ft range). Ignites frontline targets with an unquenchable fire DOT (15 dmg/sec for 6 seconds) that has a 35% probability coefficient to spread to neighboring units.'
      },
      {
        'title': 'Heavy Cavalry Sabre',
        'category': 'Weapon / Ordnance',
        'desc': 'Curved steel mounted shock blade.\n\n'
                '• Tactical Specs: Wielded by Royalist Cuirassiers and mounted Dragoons. Delivers superior armor-piercing physical melee cuts (45 dmg per strike) on high-velocity shock charges.'
      },
      {
        'title': 'Musket & Bayonet',
        'category': 'Weapon / Ordnance',
        'desc': 'Standard period infantry firearm.\n\n'
                '• Tactical Specs: Firing lead ball volleys at range (25 ft range; 28 dmg per shot) and engaging close-quarters frontline trenches with fixed steel bayonet points (32 melee dmg).'
      },
      {
        'title': 'Tear Gas Canister',
        'category': 'Weapon / Ordnance',
        'desc': 'Chemical riot control canister.\n\n'
                '• Tactical Specs: Synthesized in Alchemical Labs. Creates a dense, blinding 15-ft vapor cloud on impact; enemy combatants caught inside suffer a 50% reduction to attack speed and movement velocity.'
      },
    ];

    // Filter and sort
    final filtered = glossaryArticles.where((art) {
      final q = _glossarySearchQuery.toLowerCase();
      final t = art['title'].toLowerCase();
      final c = art['category'].toLowerCase();
      final d = art['desc'].toLowerCase();
      return t.contains(q) || c.contains(q) || d.contains(q);
    }).toList();

    filtered.sort((a, b) => a['title'].compareTo(b['title']));

    return Column(
      children: [
        // Mobile-Optimized Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFF1E1813), border: Border(bottom: BorderSide(color: const Color(0xFFC4B89B).withValues(alpha: 0.2)))),
          child: TextField(
            style: GoogleFonts.oldStandardTt(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search glossary across rooms, build costs, crops, dishes, societies...',
              hintStyle: GoogleFonts.oldStandardTt(color: Colors.white38, fontStyle: FontStyle.italic),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37), size: 20),
              suffixIcon: _glossarySearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFFC4B89B), size: 18),
                      onPressed: () => setState(() => _glossarySearchQuery = ''),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF120C08),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFC4B89B))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: const Color(0xFFC4B89B).withValues(alpha: 0.3))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
            ),
            onChanged: (val) => setState(() => _glossarySearchQuery = val),
          ),
        ),

        // Mobile-Optimized Article Count Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: const Color(0xFF15100B),
          child: Text(
            'SHOWING ${filtered.length} ENCYCLOPEDIC ARTICLES (ALPHABETIZED)',
            style: GoogleFonts.oswald(color: const Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
        ),

        // Mobile-Optimized Articles List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            physics: const BouncingScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final art = filtered[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1611),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.3)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 3))],
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  collapsedIconColor: const Color(0xFFD4AF37),
                  iconColor: const Color(0xFFD4AF37),
                  initiallyExpanded: _glossarySearchQuery.isNotEmpty || index < 2,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          art['title'].toUpperCase(),
                          style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(color: const Color(0xFF2A221C), borderRadius: BorderRadius.circular(2), border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5))),
                        child: Text(art['category'].toUpperCase(), style: GoogleFonts.oswald(color: const Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF15100B), border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
                      child: Text(
                        art['desc'],
                        style: GoogleFonts.oldStandardTt(color: const Color(0xFFD7CCC8), fontSize: 14, height: 1.45),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
