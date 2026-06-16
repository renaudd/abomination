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
                '• Capabilities: A precise workshop for the pursuit of forbidden science. From simple dissections to complex surgical operations and the creation of new life, this room handles your most ambitious experiments.\n'
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
                '• Capabilities: A specialized industrial facility for the production of ales and beers to maintain house morale and energy.\n'
                '• Construction Cost: Precisely 280 CHF cash reserves plus 40 Wood timber planks.\n'
                '• Plot Location: Can be erected inside any subterranean basement brick vault under the Manor.\n'
                '• Production Outputs: Transforms raw agricultural Barley grain harvests into Restorative Ale casks (Cost: 5 Barley per cask; instantly restores +25 Manor morale) and unlocks the recruitment of fearless pub brawler mercenary squads (Recruitment Cost: 25 CHF, 2 Ale casks).'
      },
      {
        'title': 'Kitchen & Scullery',
        'category': 'Room / Wing',
        'desc': 'Culinary food processing and dietary contract fulfillment wing.\n\n'
                '• Capabilities: It serves as the heart of the estate\'s industry, where meat is butchered, ingredients refined, and hearty meals prepared for the residents.\n'
                '• Construction Cost: Baseline scullery facility costs precisely 150 CHF plus 20 Wood planks.\n'
                '• Plot Location: Erected inside the Manor ground-floor service wing adjacent to dining rooms.\n'
                '• Production Outputs: Staffed by scullions and master chefs to transform raw agricultural harvests (Potatoes, Wheat, Raw Fish, Game Poultry) into standard daily resident sustenance meals (Yields precisely 3 daily caloric meals per raw Food harvest unit) and lavish aristocratic banquet dishes.'
      },
      {
        'title': 'Library',
        'category': 'Room / Wing',
        'desc': 'Scholarly reading room and esoteric archive wing.\n\n'
                '• Capabilities: The repository of all your collected wisdom. Use this space to archive research, transcribe messy notes into permanent records, or simply study the great authors of the past.\n'
                '• Construction Cost: Precisely 300 CHF cash reserves plus 50 Wood timber planks for shelving.\n'
                '• Plot Location: Converted inside formal East Wing quiet holding chambers.\n'
                '• Production Outputs: Staffed by hired thinkers to generate a continuous flow of +2.5 Academic Research Points per minute, unlocking Heidelberg philosophy university doctrines and deep secret society priorate charters.'
      },
      {
        'title': 'Sleeping Quarters',
        'category': 'Room / Wing',
        'desc': 'Residential staff dormitory wings.\n\n'
                '• Capabilities: Residents assigned here will recover energy and satisfaction more effectively than on the bare floor.\n'
                '• Construction Cost: Precisely 100 CHF cash reserves plus 15 Wood planks per bedstead tier.\n'
                '• Plot Location: Built inside the upper floor dormitory gallery wings.\n'
                '• Production Outputs: Provides formal lodging for hired resident staff; upgrading bedsteads increases total maximum estate population capacity by +4 formal staff members per level.'
      },
      {
        'title': 'Study',
        'category': 'Room / Wing',
        'desc': 'Quiet personal research desk.\n\n'
                '• Capabilities: A sanctuary for intellectual labor. Here, your character can research new technologies, write treatises, and develop their scientific understanding.'
      },
      {
        'title': 'Chicken Coop',
        'category': 'Room / Wing',
        'desc': 'A secure, weather-tight poultry shelter.\n\n'
                '• Capabilities: Essential for the manor\'s survival. NPCs can collect eggs, guard the flock from foxes, or butcher poultry for meat.'
      },
      {
        'title': 'Field',
        'category': 'Room / Wing',
        'desc': 'Broad stretches of arable land, clear of stones and weeds.\n\n'
                '• Capabilities: The primary source of sustenance. Workers can till, plant, water, and eventually harvest the crops required to feed the growing household.'
      },
      {
        'title': 'Greenhouse & Garden',
        'category': 'Room / Wing',
        'desc': 'A plot of fertile earth under protective glass.\n\n'
                '• Capabilities: Unlike the open fields, the greenhouse allows for year-round horticultural research and the refinement of rare botanical or fungal samples.'
      },
      {
        'title': 'Distillery',
        'category': 'Room / Wing',
        'desc': 'A complex network of copper and glass pipes and stills.\n\n'
                '• Capabilities: Handles the precision work of distilling fine spirits and concentrated chemical tonics.'
      },
      {
        'title': 'Workshop',
        'category': 'Room / Wing',
        'desc': 'A place of grit and utility with a central heavy-duty workbench.\n\n'
                '• Capabilities: The estate\'s fabrication hub. Here, timber is processed, blacksmithing is performed at the forge, and complex inventions are manufactured.'
      },
      {
        'title': 'Granary',
        'category': 'Room / Wing',
        'desc': 'Dry, cool, and well-ventilated storage bins.\n\n'
                '• Capabilities: Dedicated to the processing and safe storage of harvested grain, protecting it from rot and pests.'
      },
      {
        'title': 'Entryway',
        'category': 'Room / Wing',
        'desc': 'The grand entrance of the manor estate.\n\n'
                '• Capabilities: The public face of the manor. Used for greeting guests and as a primary defensive post if the manor is threatened.'
      },
      {
        'title': 'Butler\'s Quarters',
        'category': 'Room / Wing',
        'desc': 'A modest but perfectly ordered space.\n\n'
                '• Capabilities: The primary residence for your loyal butler and henchman.'
      },
      {
        'title': 'Basement & Attic',
        'category': 'Room / Wing',
        'desc': 'Storage and residential wings.\n\n'
                '• Capabilities: Ideal for additional resident housing or quiet storage of sensitive materials.'
      },
      {
        'title': 'Dining Room',
        'category': 'Room / Wing',
        'desc': 'A formal banquet setting.\n\n'
                '• Capabilities: Used for communal meals and formal dinners to build relationships and status.'
      },
      {
        'title': 'Toilet',
        'category': 'Room / Wing',
        'desc': 'A private washroom.\n\n'
                '• Capabilities: Essential for maintaining the hygiene and comfort of the manor\'s inhabitants.'
      },
      {
        'title': 'Dental Clinic',
        'category': 'Room / Wing',
        'desc': 'A clinical facility featuring advanced oral tools.\n\n'
                '• Capabilities: A dedicated dental facility where Alphonse Giles performs tooth extractions, cleanings, and advanced oral care on Glarus citizens and visiting patients.'
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

      // ASSIGNABLE TASKS & ACTIONS (Exhaustively detailed descriptions of how all assignable actions work mechanically)
      {
        'title': 'Archive Forbidden Scrolls',
        'category': 'Assignable Task',
        'desc': 'Systematic consolidation of occult literature.\n\n'
                '• Assignment Location: Enqueued and assigned within The Library interface.\n'
                '• Driving Attributes: Intellect, Willpower.\n'
                '• Activity Duration: Typical procedure requires precisely 60 minutes.\n'
                '• Required Resources: Precisely 1 Unreviewed Document or Loose Esoteric Scroll from inventory.\n'
                '• Mechanical Outcome: Consolidates esoteric loose scrolls into bound master tomes, generating precisely +10 Research Points in Philosophy & Esoteric Lore and improving library academic standing by +15 points.'
      },
      {
        'title': 'Catalog Specimen Notes',
        'category': 'Assignable Task',
        'desc': 'Systematic indexing of anatomical cross-references.\n\n'
                '• Assignment Location: Enqueued and assigned within The Library or Laboratory interface.\n'
                '• Driving Attributes: Precision, Intellect.\n'
                '• Activity Duration: Typical procedure requires precisely 45 minutes.\n'
                '• Required Resources: Precisely 1 Loose Specimen Record or Rough Anatomy Notes from inventory.\n'
                '• Mechanical Outcome: Systematically organizes biological observations, converting raw records into precisely +8 Small Creature Anatomy points and +5 Zoology points.'
      },
      {
        'title': 'Fundamental Research',
        'category': 'Assignable Task',
        'desc': 'Theoretical reading and primary literature review.\n\n'
                '• Assignment Location: Assigned within The Study or formal Library interface.\n'
                '• Driving Attributes: Intellect.\n'
                '• Activity Duration: Baseline procedure requires precisely 15 minutes.\n'
                '• Required Resources: Hired thinkers utilize available library seating (No consumable reagents required).\n'
                '• Mechanical Outcome: Generates a continuous flow of Universal Research Points, accelerating Discovery unlock thresholds and raising personal academic qualification.'
      },
      {
        'title': 'Small Specimen Dissection',
        'category': 'Assignable Task',
        'desc': 'Careful post-mortem anatomical extraction.\n\n'
                '• Assignment Location: Assigned within The Laboratory or Operating Room interface.\n'
                '• Driving Attributes: Precision, Anatomy.\n'
                '• Activity Duration: Typical procedure requires precisely 20 minutes.\n'
                '• Required Resources: Precisely 1 Deceased Small Specimen (Rat, Bat, Chicken, or Fox).\n'
                '• Mechanical Outcome: Conducts detailed post-mortem dissection. Yields 1-15 pages of Life Science knowledge (+3 Small Creature Anatomy points) and basic organic biological reagents (Meat, Bones).'
      },
      {
        'title': 'Large Specimen Dissection',
        'category': 'Assignable Task',
        'desc': 'Intensive post-mortem biological processing.\n\n'
                '• Assignment Location: Assigned within The Laboratory or Operating Room interface.\n'
                '• Driving Attributes: Precision, Strength.\n'
                '• Activity Duration: Typical procedure requires precisely 90 minutes.\n'
                '• Required Resources: Precisely 1 Large Specimen Carcass (Cattle, Bear, Leviathan, Behemoth).\n'
                '• Mechanical Outcome: Conducts heavy biological extraction. Yields precisely +15 Universal Anatomy points and massive bundles of Industrial Meat and Bone Meal reagents.'
      },
      {
        'title': 'Small Specimen Vivisection',
        'category': 'Assignable Task',
        'desc': 'In-vivo biological exploration of vital organic functions.\n\n'
                '• Assignment Location: Assigned within The Laboratory interface.\n'
                '• Driving Attributes: Willpower, Precision.\n'
                '• Activity Duration: Typical procedure requires precisely 45 minutes.\n'
                '• Required Resources: Precisely 1 Live Small Specimen (Rat, Bat, or Chicken) from inventory.\n'
                '• Mechanical Outcome: In-vivo surgical investigation of biological galvanism. Highly corrupting (+0.2 Moral Guilt to the operating character). Awards precisely +5 Small Creature Anatomy, +5 Alchemy, and +5 Zoology points. Performing two small vivisections fulfills crucial First Construct reanimation experimental milestones.'
      },
      {
        'title': 'Large Specimen Vivisection',
        'category': 'Assignable Task',
        'desc': 'Profoundly harrowing biological and structural experimentation.\n\n'
                '• Assignment Location: Assigned within The Laboratory interface.\n'
                '• Driving Attributes: Willpower, Precision, Strength.\n'
                '• Activity Duration: Typical procedure requires precisely 150 minutes.\n'
                '• Required Resources: Precisely 1 Live Large Specimen from inventory.\n'
                '• Mechanical Outcome: Deep exploration of organic limits. Inflicts +0.5 Moral Guilt upon the operator, but produces tremendous Life Science breakthroughs (+25 Universal Anatomy, +25 Zoology) and synthetic bio-mechanical muscle fibers.'
      },
      {
        'title': 'Cognitive Puzzle Study',
        'category': 'Assignable Task',
        'desc': 'Non-invasive behavioral labyrinth trials.\n\n'
                '• Assignment Location: Enqueued and assigned within The Laboratory or Study interface.\n'
                '• Driving Attributes: Intellect, Judgment, Perception.\n'
                '• Activity Duration: Extended study requires precisely 16 hours (960 minutes).\n'
                '• Required Resources: Precisely 5 Live Specimens and 1 Caloric Meal ration.\n'
                '• Mechanical Outcome: Conducts complex psychological maze solving. Advances fundamental cognitive psychology documents and yields advanced behavioral Labyrinth blueprints.'
      },
      {
        'title': 'Deprivation Study',
        'category': 'Assignable Task',
        'desc': 'Sustained environmental and caloric withholding trials.\n\n'
                '• Assignment Location: Enqueued and assigned within The Laboratory interface.\n'
                '• Driving Attributes: Willpower, Intellect.\n'
                '• Activity Duration: Prolonged trial requires precisely 40 hours (2400 minutes).\n'
                '• Required Resources: Precisely 5 Live Specimens from inventory.\n'
                '• Mechanical Outcome: Tests biological survival mechanisms under severe deprivation. Inflicts +0.4 Moral Guilt and carries high subject mortality, but yields foundational Zoology notes required for synthetic muscle weaving.'
      },
      {
        'title': 'General Clinical Trial',
        'category': 'Assignable Task',
        'desc': 'Extended pharmacological and immunological testing.\n\n'
                '• Assignment Location: Assigned within The Operating Room interface.\n'
                '• Driving Attributes: Medicine, Precision.\n'
                '• Activity Duration: Grand clinical trial requires precisely 120 hours (7200 minutes).\n'
                '• Required Resources: Precisely 10 Live Specimens, 1 Botanical Herb Reagent, and 5 Meal rations.\n'
                '• Mechanical Outcome: Exhaustive medical study. Unlocks premium pharmaceutical formulas, active disease immunity traits, and establishes undisputed regional medical authority.'
      },
      {
        'title': 'Behavioral Optimization (Lobotomy)',
        'category': 'Assignable Task',
        'desc': 'Precise neurological response dampening.\n\n'
                '• Assignment Location: Triggered and assigned within The Laboratory interface.\n'
                '• Driving Attributes: Medicine, Willpower.\n'
                '• Activity Duration: Typical surgical operation requires precisely 180 minutes.\n'
                '• Required Resources: Precisely 1 Resident Staff Occupant present on estate.\n'
                '• Mechanical Outcome: Dampens volatile emotional sub-routines. Halves the subject\'s psychological stress sensitivity and doubles physical manual labor compliance, but decreases independent creative invention capabilities.'
      },
      {
        'title': 'Reanimation Procedure',
        'category': 'Assignable Task',
        'desc': 'Galvanic stirring of the vital organic spark.\n\n'
                '• Assignment Location: Selected and initiated within The Laboratory experimental options.\n'
                '• Driving Attributes: Alchemy, Anatomy.\n'
                '• Activity Duration: Galvanic procedure requires precisely 240 minutes (4 hours).\n'
                '• Required Resources: Precisely 1 Deceased or Prepared Resident Subject and 100 Volts stored Galvanic Charge.\n'
                '• Mechanical Outcome: The pinnacle of life science. Applies concentrated galvanic voltage to dead organic tissue to achieve genuine living reanimation. Successfully completing this procedure transforms the subject into an immortal Construct entity, fulfilling Step 4 of The First Construct mission.'
      },
      {
        'title': 'Biological Transmutation',
        'category': 'Assignable Task',
        'desc': 'Weaving synthetic artificial muscle fibers directly into an organic host.\n\n'
                '• Assignment Location: Selected and initiated within The Laboratory experimental options.\n'
                '• Driving Attributes: Alchemy, Medicine.\n'
                '• Activity Duration: Intensive procedure requires precisely 300 minutes (5 hours).\n'
                '• Required Resources: Precisely 1 Resident Subject and Advanced Bio-Mechanical Reagents.\n'
                '• Mechanical Outcome: Permanently alters the biological foundation of the host, increasing physical Melee Strength by +25 and granting +150 Maximum HP.'
      },
      {
        'title': 'Prepare Sustenance Meals',
        'category': 'Assignable Task',
        'desc': 'Culinary transformation of raw agricultural harvests into edible rations.\n\n'
                '• Assignment Location: Assigned within The Kitchen & Scullery interface.\n'
                '• Driving Attributes: Dexterity, Speed.\n'
                '• Activity Duration: Typical dietary recipe requires precisely 30 to 60 minutes.\n'
                '• Required Resources: Raw Foodstuffs (Potatoes, Wheat Flour, Raw Fish, Fresh Game).\n'
                '• Mechanical Outcome: Fulfills estate dining contracts. Yields precisely 3 edible daily meals per raw Food harvest unit processed, fully preventing resident starvation and restoring +5 Satisfaction per meal eaten.'
      },
      {
        'title': 'Butcher Animal Carcasses',
        'category': 'Assignable Task',
        'desc': 'Quartering and processing raw livestock and game carcasses.\n\n'
                '• Assignment Location: Assigned within The Kitchen & Scullery interface.\n'
                '• Driving Attributes: Strength, Precision.\n'
                '• Activity Duration: Typical quartering requires precisely 45 minutes.\n'
                '• Required Resources: Precisely 1 Cattle Carcass or Large Game Carcass.\n'
                '• Mechanical Outcome: Professionally dresses raw livestock. Converts 1 heavy carcass into precisely 25 Prime Food harvest units and 5 Industrial Bone Reagents.'
      },
      {
        'title': 'Clean Dirty Dishes',
        'category': 'Assignable Task',
        'desc': 'Scullery washing of accumulated dining dinnerware.\n\n'
                '• Assignment Location: Assigned within The Kitchen & Scullery interface.\n'
                '• Driving Attributes: Speed, Dexterity.\n'
                '• Activity Duration: Typical scullery wash requires precisely 15 minutes.\n'
                '• Required Resources: Accumulated Dirty Dishes and clean water.\n'
                '• Mechanical Outcome: Restores scullery hygiene, completely eliminating room pests and foul odors.'
      },
      {
        'title': 'Clean Staging Chamber',
        'category': 'Assignable Task',
        'desc': 'Manual sweeping of accumulated grime and chemical soot.\n\n'
                '• Assignment Location: Assigned across any restored Manor Wing, Laboratory, or Tenement chamber.\n'
                '• Driving Attributes: Speed, Willpower.\n'
                '• Activity Duration: Typical chamber sweep requires precisely 30 minutes.\n'
                '• Required Resources: Standard cleaning bro brooms and scrub brushes.\n'
                '• Mechanical Outcome: Purges chemical dust and dirt, reducing chamber dirtiness level below 0.05 and eliminating resident respiratory illness risks.'
      },
      {
        'title': 'Collect Fresh Eggs',
        'category': 'Assignable Task',
        'desc': 'Gathering fresh eggs from poultry pens.\n\n'
                '• Assignment Location: Assigned within The Chicken Coop interface.\n'
                '• Driving Attributes: Dexterity.\n'
                '• Activity Duration: Typical gathering round requires precisely 20 minutes.\n'
                '• Required Resources: Active, fed laying hens present in coop boxes.\n'
                '• Mechanical Outcome: Harvests freshly laid organic eggs from straw nests, transferring them directly to the Manor Kitchen storage for morning breakfast rations.'
      },
      {
        'title': 'Guard Chicken Coop',
        'category': 'Assignable Task',
        'desc': 'Nighttime sentry watch over poultry pens.\n\n'
                '• Assignment Location: Assigned within The Chicken Coop interface.\n'
                '• Driving Attributes: Strength, Perception.\n'
                '• Activity Duration: Full sentry shift requires precisely 120 minutes (2 hours).\n'
                '• Required Resources: Watchman lantern and stout oak cudgel.\n'
                '• Mechanical Outcome: Secures perimeter fences against devastating nocturnal fox raids and poacher thefts.'
      },
      {
        'title': 'Till Agricultural Soil',
        'category': 'Assignable Task',
        'desc': 'Breaking and turning compact field turf into fertile planting furrows.\n\n'
                '• Assignment Location: Assigned within The Arable Field interface.\n'
                '• Driving Attributes: Strength, Endurance.\n'
                '• Activity Duration: Heavy plowing requires precisely 60 minutes per acre.\n'
                '• Required Resources: Heavy iron plow and draft harness.\n'
                '• Mechanical Outcome: Prepares compact turf fields into loamy, tilled furrows perfectly ready for seasonal agricultural seed sowing.'
      },
      {
        'title': 'Plant Seasonal Crops',
        'category': 'Assignable Task',
        'desc': 'Sowing agricultural seed bags into tilled planting furrows.\n\n'
                '• Assignment Location: Assigned within The Arable Field interface.\n'
                '• Driving Attributes: Dexterity.\n'
                '• Activity Duration: Typical sowing requires precisely 45 minutes.\n'
                '• Required Resources: Precisely 1 Seed Bag (Potatoes, Wheat, or Barley) and tilled soil.\n'
                '• Mechanical Outcome: Sows seeds into open furrows, initiating the multi-day biological agricultural growth cycle.'
      },
      {
        'title': 'Water Arable Crops',
        'category': 'Assignable Task',
        'desc': 'Irrigating seasonal crops to accelerate biological maturation.\n\n'
                '• Assignment Location: Assigned within The Arable Field, Garden, or Greenhouse interface.\n'
                '• Driving Attributes: Endurance, Speed.\n'
                '• Activity Duration: Typical irrigation round requires precisely 30 minutes.\n'
                '• Required Resources: Filled watering cans or active estate irrigation wells.\n'
                '• Mechanical Outcome: Replenishes loamy soil moisture, accelerating daily biological crop maturation velocity by +20%.'
      },
      {
        'title': 'Fertilize Arable Soil',
        'category': 'Assignable Task',
        'desc': 'Enriching nutrient density in planted furrows.\n\n'
                '• Assignment Location: Assigned within The Arable Field interface.\n'
                '• Driving Attributes: Strength, Alchemy.\n'
                '• Activity Duration: Soil enrichment requires precisely 40 minutes.\n'
                '• Required Resources: Precisely 1 Bone Meal Reagent or High-Grade Compost bundle.\n'
                '• Mechanical Outcome: Deeply fortifies root nutrition, permanently increasing eventual final bushel harvest extraction yields by +35%.'
      },
      {
        'title': 'Care For Field Crops',
        'category': 'Assignable Task',
        'desc': 'Pruning blighted leaves and weeding invasive thickets.\n\n'
                '• Assignment Location: Assigned within The Arable Field, Garden, or Greenhouse interface.\n'
                '• Driving Attributes: Precision, Dexterity.\n'
                '• Activity Duration: Agricultural tending requires precisely 45 minutes.\n'
                '• Required Resources: Weeding hooks and botanical pruning shears.\n'
                '• Mechanical Outcome: Removes blighted foliage, reducing botanical crop failure probability to virtually zero.'
      },
      {
        'title': 'Harvest Mature Crops',
        'category': 'Assignable Task',
        'desc': 'Extracting fully ripened agricultural produce from fertile fields.\n\n'
                '• Assignment Location: Assigned within The Arable Field, Garden, or Greenhouse interface.\n'
                '• Driving Attributes: Strength, Dexterity.\n'
                '• Activity Duration: Full harvest round requires precisely 60 minutes.\n'
                '• Required Resources: Agricultural harvest sickles and gathering baskets.\n'
                '• Mechanical Outcome: Extracts fully mature produce, transporting Raw Food bushels and seed parcels directly into Manor granary and kitchen storage.'
      },
      {
        'title': 'Harvest Restorative Grain',
        'category': 'Assignable Task',
        'desc': 'Thrashing and winnowing stored sheaves in the granary.\n\n'
                '• Assignment Location: Assigned within The Granary interface.\n'
                '• Driving Attributes: Speed, Strength.\n'
                '• Activity Duration: Thrashing round requires precisely 45 minutes.\n'
                '• Required Resources: Harvested grain sheaves and thrashing flails.\n'
                '• Mechanical Outcome: Winnows raw cereal chaff to produce refined Wheat Flour bags and premium brewing grains.'
      },
      {
        'title': 'Mash and Brew Restorative Ale',
        'category': 'Assignable Task',
        'desc': 'Fermenting aromatic malts into pub ale casks.\n\n'
                '• Assignment Location: Assigned within The Subterranean Brewery interface.\n'
                '• Driving Attributes: Alchemy, Strength.\n'
                '• Activity Duration: Multi-stage fermentation requires precisely 90 minutes.\n'
                '• Required Resources: Precisely 5 Raw Barley bushels, clean well water, and brewing hops.\n'
                '• Mechanical Outcome: Casks rich pub ales, restoring precisely +25 Universal Manor Morale per cask consumed by the residential staff.'
      },
      {
        'title': 'Distill High-Proof Spirits',
        'category': 'Assignable Task',
        'desc': 'Subterranean distillation of highly concentrated alcohol.\n\n'
                '• Assignment Location: Assigned within The Subterranean Distillery interface.\n'
                '• Driving Attributes: Alchemy, Precision.\n'
                '• Activity Duration: Full distillation requires precisely 120 minutes (2 hours).\n'
                '• Required Resources: Precisely 5 Potato root tubers or Wheat grain bushels plus active yeast.\n'
                '• Mechanical Outcome: Distills potent spirits (Kirschwasser, Absinthe). Used as highly effective surgical anesthesia or sold on the local Glarus black market for 45 CHF profit.'
      },
      {
        'title': 'Process Raw Timber',
        'category': 'Assignable Task',
        'desc': 'Sawing raw forestry timber logs into building planks.\n\n'
                '• Assignment Location: Assigned within The Carpenter\'s Workshop interface.\n'
                '• Driving Attributes: Strength, Endurance.\n'
                '• Activity Duration: Heavy timber processing requires precisely 60 minutes.\n'
                '• Required Resources: Precisely 1 Felled Forestry Timber Log.\n'
                '• Mechanical Outcome: Mills heavy timber logs into precisely 5 Refined Wood Planks used for architectural room restoration and custom weapon stock turning.'
      },
      {
        'title': 'Industrial Blacksmithing',
        'category': 'Assignable Task',
        'desc': 'Smelting and hammer-forging iron ore into solid metal ingots.\n\n'
                '• Assignment Location: Assigned within The Carpenter\'s Workshop interface.\n'
                '• Driving Attributes: Strength, Crafting.\n'
                '• Activity Duration: Furnace smelting requires precisely 90 minutes.\n'
                '• Required Resources: Precisely 2 Raw Iron Ore lumps.\n'
                '• Mechanical Outcome: Forges raw ore into precisely 1 Refined Iron Ingot used for outfitting military armories, crafting analytical laboratory equipment, and assembling steam golems.'
      },
      {
        'title': 'Mechanical Manufacturing',
        'category': 'Assignable Task',
        'desc': 'Precision assembly of specialized mechanical devices.\n\n'
                '• Assignment Location: Assigned within The Carpenter\'s Workshop interface.\n'
                '• Driving Attributes: Precision, Crafting.\n'
                '• Activity Duration: Intricate assembly requires precisely 120 minutes (2 hours).\n'
                '• Required Resources: Refined Iron Ingots, Wood Planks, and complex reagents.\n'
                '• Mechanical Outcome: Manufactures advanced specialized items (Galvanic Batteries, Precision Microscopes) according to unlocked schematic blueprints.'
      },
      {
        'title': 'Engineering Invention',
        'category': 'Assignable Task',
        'desc': 'Iterative engineering design and prototype drafting.\n\n'
                '• Assignment Location: Assigned within The Carpenter\'s Workshop interface.\n'
                '• Driving Attributes: Intellect, Crafting.\n'
                '• Activity Duration: Master prototype drafting requires precisely 180 minutes (3 hours).\n'
                '• Required Resources: Precisely 2 Academic Research Notes and blank architectural parchment drafts.\n'
                '• Mechanical Outcome: Solves complex engineering bottlenecks, yielding cutting-edge technological schematic diagrams (Automated Steam Turrets, Subterranean Excavators).'
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
