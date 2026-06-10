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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D1712),
        title: Text(
          'ABOMINATION HELP & GLOSSARY',
          style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 4),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFE5D5B0)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          indicatorWeight: 3.0,
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: const Color(0xFFC4B89B).withValues(alpha: 0.6),
          labelStyle: GoogleFonts.oswald(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          tabs: const [
            Tab(icon: Icon(Icons.shield_outlined), text: 'COMBAT MANUAL & SPECS'),
            Tab(icon: Icon(Icons.menu_book_outlined), text: 'ENCYCLOPEDIC GLOSSARY'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCombatManualTab(),
          _buildGlossaryTab(),
        ],
      ),
    );
  }

  Widget _buildCombatManualTab() {
    return Column(
      children: [
        // Broad Strokes Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF1E1813), border: Border(bottom: BorderSide(color: const Color(0xFFC4B89B).withValues(alpha: 0.2)))),
          child: ExpansionTile(
            collapsedIconColor: const Color(0xFFD4AF37),
            iconColor: const Color(0xFFD4AF37),
            title: Text(
              'HOW COMBAT WORKS (BROAD STROKES OVERVIEW)',
              style: GoogleFonts.playfairDisplay(color: const Color(0xFFD4AF37), fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            subtitle: Text('Autonomous Multi-Lane Locomotion, Elemental Dynamics & AP Economics', style: GoogleFonts.oldStandardTt(color: Colors.white60, fontSize: 13, fontStyle: FontStyle.italic)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _manualPoint(
                      'The Battlefield Expanse',
                      'Combat takes place across an edge-to-edge arena separated by three horizontal lanes (Top, Center, Bottom). Your Commander stands at the rear left base, while the enemy Hero commands the rear right base. Scenery obstacles and defensive walls separate the staging turf from the primary lane channels.',
                    ),
                    _manualPoint(
                      'Action Point (AP) Economics',
                      'Your Action Point pool regenerates continuously during live engagements at a standard rate of +1.5 AP per second (scaling up to 10.0 AP max). Deploying infantry squads, armored vehicles, or alchemical support totems deducts their AP cost instantly from your reserves.',
                    ),
                    _manualPoint(
                      'Autonomous Locomotion & AI Channeling',
                      'Once summoned onto the staging turf, units autonomously seek vertical alignment within the nearest open lane channel. Upon entering the lane, they march straight toward the enemy base. Tapping the minimap or clicking an enemy target allows you to manually issue waypoint overrides to your Commander.',
                    ),
                    _manualPoint(
                      'Esoteric Elemental Warfare',
                      'Advanced combat relies heavily on elemental interactions:\n'
                      '• Incendiary Fire: Greek Fire ordnance and Templar Pyre blades ignite targets with lingering fire damage over time (DOT); burning targets have a chance to spread flames to nearby units.\n'
                      '• Debilitating Toxin: Poison Gas and Fenian dirks inflict internal poison stacking DOT that bypasses ordinary physical armor.\n'
                      '• Total Willpower Subversion: Golden Dawn Mesmerists and Hypnotic pendulums subvert rival willpower, temporarily seizing control of enemy combatants and turning them against their own squad.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Sortable Spreadsheet Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TACTICAL COMBAT CARDS SPREADSHEET (${_allCombatCards.length} UNITS)',
                style: GoogleFonts.oswald(color: const Color(0xFFE5D5B0), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              Text(
                'Tap any column header to sort • Tap any row to inspect specs modal',
                style: GoogleFonts.oldStandardTt(color: const Color(0xFFD4AF37), fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),

        // Spreadsheet Table
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF120C08),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.3)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: DataTable(
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
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
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: const BoxDecoration(color: Color(0xFF2A221C), shape: BoxShape.circle),
                              child: ClipOval(child: Center(child: CharacterBlobRenderer(npc: npc, size: 24, isCombat: true))),
                            ),
                            Text(npc.name, style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        )),
                        DataCell(Text(npc.metadata.containsKey('faction') ? npc.metadata['faction']! : npc.role, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                        DataCell(Text('${stats.cost} AP', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 12))),
                        DataCell(Text('${stats.health} HP', style: const TextStyle(color: Colors.greenAccent, fontSize: 12))),
                        DataCell(Text(stats.attack > 0 ? '${stats.attack}' : '-', style: const TextStyle(color: Colors.white, fontSize: 12))),
                        DataCell(Text(stats.attack > 0 ? dps.toStringAsFixed(1) : '-', style: const TextStyle(color: Colors.orangeAccent, fontSize: 12))),
                        DataCell(Text('${stats.movement} ft/s', style: const TextStyle(color: Colors.cyanAccent, fontSize: 12))),
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
      label: Text(label, style: GoogleFonts.oswald(color: const Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.oswald(color: const Color(0xFFD4AF37), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(desc, style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildGlossaryTab() {
    final List<Map<String, dynamic>> glossaryArticles = [
      // CROPS
      {'title': 'Barley', 'category': 'Crop', 'desc': 'Hardy winter cereal grain. Plant during Autumn or Winter months; requires 3 days until full maturity. Yields raw grain used in the Brewery hall to ferment restorative ales and feed livestock.'},
      {'title': 'Potatoes', 'category': 'Crop', 'desc': 'Versatile subterranean root crop. Plant in Spring; requires precisely 2 days until harvest. Produces exceptionally high caloric food yields per acre, forming the primary dietary basis for formal working residents.'},
      {'title': 'Wheat', 'category': 'Crop', 'desc': 'Golden summer agricultural grain. Plant in Spring or Summer; requires 4 days until harvest. Ground in scullery mills into refined white flour essential for baking lavish pastries and boosting resident prestige.'},

      // DISHES
      {'title': 'Bouillabaisse', 'category': 'Dish / Culinary', 'desc': 'Luxurious Mediterranean seafood stew. Prerequisite: Coastal Trade Wharf wing. Resource Cost: 2 Raw Fish, 1 Vegetable harvest, 1 Herb vial. Produces 4 lavish meals. Maximizes Coven morale and arcane focus.'},
      {'title': 'Coq au Vin', 'category': 'Dish / Culinary', 'desc': 'Aristocratic braised poultry. Resource Cost: 2 Poultry meat, 1 Wine vintage, 2 Vegetables. Produces 6 premium meals. Significantly elevates manor dining reputation and fulfills high-tier resident dietary contracts.'},
      {'title': 'Hearty Stew', 'category': 'Dish / Culinary', 'desc': 'Standard working-class broth. Resource Cost: 1 Raw Meat, 1 Potato, 1 Vegetable. Produces 3 nutritious meals. Fulfills baseline daily caloric expenditure without requiring advanced kitchen scullery additions.'},
      {'title': 'Roast Pheasant', 'category': 'Dish / Culinary', 'desc': 'Deep-woods game bird roast. Resource Cost: 2 Game Fowl meat, 1 Wild Herb. Produces 4 lavish meals. Highly favored by Foresters, Beastmasters, and marksmen infantry.'},

      // RESOURCES
      {'title': 'Cash (CHF)', 'category': 'Resource', 'desc': 'Swiss Francs, the fundamental sovereign currency of the underground economy. Acquired via banking syndicate dividends, debt collector death bounties, tournament victory purses, and surplus agricultural exports.'},
      {'title': 'Food', 'category': 'Resource', 'desc': 'Edible caloric units required every morning at 06:00 to feed manor residents and maintain troop stamina. Harvested from tillable soil fields, garden conservatories, and fishing wharves.'},
      {'title': 'Iron', 'category': 'Resource', 'desc': 'Heavy unrefined metal ingots smelted from subterranean ore veins. Essential for armoring Dragoon cavalry, forging Templar pyre blades, and fortifying structural castle gate barricades.'},
      {'title': 'Wood', 'category': 'Resource', 'desc': 'Sturdy timber planks sawn from lumber wharves. Required for constructing formal room conversions, erecting wooden tanks, and crafting staff sling pole arms.'},

      // ROOMS
      {'title': 'Alchemical Laboratory', 'category': 'Room / Wing', 'desc': 'Advanced experimental chamber. Staffed by hermetic scholars and chemists to synthesize restorative elixirs of vitality, volatile Greek Fire canisters, and animate flesh golem constructs.'},
      {'title': 'Armory', 'category': 'Room / Wing', 'desc': 'Tactical staging warehouse. Upgrades baseline squad melee and firearm damage coefficients while outfitting raw recruits with heavy armor plates prior to Arena tournaments.'},
      {'title': 'Brewery', 'category': 'Room / Wing', 'desc': 'Subterranean fermentation hall hall hall. Transforms raw barley harvests into intoxicating spirits, elevating estate morale and unlocking the recruitment of fearless pub brawlers.'},
      {'title': 'Kitchen & Scullery', 'category': 'Room / Wing', 'desc': 'Culinary preparation hub. Staffed by scullions and head cooks to process raw agricultural harvests into sophisticated resident meals.'},
      {'title': 'Library', 'category': 'Room / Wing', 'desc': 'Scholarly archive. Generates continuous academic research points, unlocking advanced philosophical university doctrines and deep secret society charters.'},
      {'title': 'Sleeping Quarters', 'category': 'Room / Wing', 'desc': 'Formal residential dormitory wings. Houses your hired staff; expanding and upgrading bedsteads increases total maximum estate population capacity.'},

      // SECRET SOCIETIES
      {'title': 'Ancient Order of Foresters', 'category': 'Secret Society', 'desc': 'Woodland druidic brotherhood commanded by Chief Ranger Robin. Specializes in botanical toxin spore warfare and deploying ferocious deep-woods grizzly bears.'},
      {'title': 'Carbonari', 'category': 'Secret Society', 'desc': 'Charcoal-burning revolutionary network directed by Grand Master Alta Vendita. Specializes in long-range pitch arson and deploying self-sacrificing shrapnel blast martyrs.'},
      {'title': 'Chevaliers de la foi', 'category': 'Secret Society', 'desc': 'Ultra-royalist Catholic bannerets commanded by Ferdinand de Bertier. Specializes in impenetrable shock Cuirassier cavalry and attack-speed boosting standard bearers.'},
      {'title': 'Fenian Brotherhood', 'category': 'Secret Society', 'desc': 'Irish republican insurgent brotherhood commanded by Head Centre Stephens. Specializes in rapid guerilla cell reinforcements and venom-tipped dirk raiders.'},
      {'title': 'Freemasons', 'category': 'Secret Society', 'desc': 'Esoteric architectural order commanded by Grand Master Hiram. Specializes in unyielding sacred geometry movement buffs and tower-demolishing sapper squads.'},
      {'title': 'Gnomes of Zurich', 'category': 'Secret Society', 'desc': 'Subterranean financial syndicate commanded by Banker Rothschild. Specializes in wealth-yielding debt collectors and precision headhunter assassins.'},
      {'title': 'Golden Dawn', 'category': 'Secret Society', 'desc': 'Hermetic occult order commanded by Imperator Crowley. Specializes in astral hypnosis overlays that subvert rival free will and flip enemy troop allegiance.'},
      {'title': 'Knights Templar', 'category': 'Secret Society', 'desc': 'Holy military priorate commanded by Jacques de Molay. Specializes in unquenchable spreading Greek Fire canisters and flaming pyre blades.'},
      {'title': 'Rosicrucians', 'category': 'Secret Society', 'desc': 'Mystical alchemical brotherhood commanded by Magus Rosenkreuz. Specializes in vitalizing alchemical mists and lumbering 800-HP homunculus flesh behemoths.'},

      // SCHOOLS
      {'title': 'Bologna School of Law', 'category': 'Graduate School', 'desc': 'Ancient jurisprudence academy. Enrolling scholars here resolves periodic estate tax audits, mitigates legal liability during underground conflicts, and secures banking charters.'},
      {'title': 'Heidelberg School of Philosophy', 'category': 'Graduate School', 'desc': 'Romantic German university faculty. Enrolling thinkers here significantly accelerates global research generation points and elevates sovereign manor reputation.'},
      {'title': 'Paris Faculty of Medicine', 'category': 'Graduate School', 'desc': 'Anatomical surgery institute. Enrolling physicians here unlocks advanced flesh golem stitching and accelerates passive resident wound recovery coefficients.'},

      // LOCATIONS
      {'title': 'Arena Hub (Proving Grounds)', 'category': 'Location', 'desc': 'The subterranean tactical Colosseum. Visit to engage in multi-lane Tournament ladders, custom Skirmish simulations, or endless Survival turf defense against invading hordes.'},
      {'title': 'Hamlet (Village Pub)', 'category': 'Location', 'desc': 'The neighboring rural community settlement. Visit to recruit mercenary brawlers, hire seasonal agricultural hands, or purchase round-of-drinks to gather local intelligence.'},
      {'title': 'Manor Estate Ground', 'category': 'Location', 'desc': 'Your primary sovereign fortress. Manage tillable soil fields, direct kitchen staff, construct advanced research wings, and fortify perimeter defenses.'},
      {'title': 'World Map Expanse', 'category': 'Location', 'desc': 'The grand strategic orientation expanse. Dispatch Aravt armies and companion squads across hex coordinates to secure vital trade wharves and resource nodes.'},

      // WEAPONS
      {'title': 'Greek Fire Flask', 'category': 'Weapon / Ordnance', 'desc': 'Volatile antique incendiary ordnance that ignites targets with persistent fire DOT and spreads across frontline trenches.'},
      {'title': 'Heavy Cavalry Sabre', 'category': 'Weapon / Ordnance', 'desc': 'Curved steel blade offering superior armor-piercing melee DPS on mounted shock Dragoon charges.'},
      {'title': 'Musket & Bayonet', 'category': 'Weapon / Ordnance', 'desc': 'Standard period infantry firearm delivering lethal round-ball volleys at distance and engaging frontlines with fixed steel spear points.'},
      {'title': 'Tear Gas Canister', 'category': 'Weapon / Ordnance', 'desc': 'Chemical riot control canister that unleashes a blinding, unbreathable vapor cloud, halving rival attack speed.'},
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
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF1E1813), border: Border(bottom: BorderSide(color: const Color(0xFFC4B89B).withValues(alpha: 0.2)))),
          child: TextField(
            style: GoogleFonts.oldStandardTt(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search glossary across components, resources, crops, dishes, societies...',
              hintStyle: GoogleFonts.oldStandardTt(color: Colors.white38, fontStyle: FontStyle.italic),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
              suffixIcon: _glossarySearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFFC4B89B)),
                      onPressed: () => setState(() => _glossarySearchQuery = ''),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF120C08),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFC4B89B))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: const Color(0xFFC4B89B).withValues(alpha: 0.3))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
            ),
            onChanged: (val) => setState(() => _glossarySearchQuery = val),
          ),
        ),

        // Article Count Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          color: const Color(0xFF15100B),
          child: Text(
            'SHOWING ${filtered.length} ENCYCLOPEDIC ARTICLES (ALPHABETIZED)',
            style: GoogleFonts.oswald(color: const Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
        ),

        // Articles List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final art = filtered[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1611),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.3)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: ExpansionTile(
                  collapsedIconColor: const Color(0xFFD4AF37),
                  iconColor: const Color(0xFFD4AF37),
                  initiallyExpanded: _glossarySearchQuery.isNotEmpty || index < 2,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        art['title'].toUpperCase(),
                        style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF2A221C), borderRadius: BorderRadius.circular(2), border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5))),
                        child: Text(art['category'].toUpperCase(), style: GoogleFonts.oswald(color: const Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
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
                        style: GoogleFonts.oldStandardTt(color: const Color(0xFFD7CCC8), fontSize: 15, height: 1.5),
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
