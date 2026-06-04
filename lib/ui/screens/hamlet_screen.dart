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
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../../state/game_state.dart';
import '../../models/active_business.dart';
import '../widgets/hamlet_hotspot.dart';
import '../widgets/encounter_dialog.dart';

enum HamletVendor { grocer, curator, alchemist }

class HamletScreen extends StatefulWidget {
  const HamletScreen({super.key});

  @override
  State<HamletScreen> createState() => _HamletScreenState();
}

class _HamletScreenState extends State<HamletScreen> {
  bool _isNavigatingToCombat = false;

  void _checkCombatEncounter(GameState state) {
    if (state.pendingCombatEncounter &&
        !_isNavigatingToCombat &&
        ModalRoute.of(context)?.isCurrent == true) {
      _isNavigatingToCombat = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const EncounterDialog(),
        ).then((_) {
          _isNavigatingToCombat = false;
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GameState>().setSpeed(GameSpeed.paused);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);
    _checkCombatEncounter(state);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          state.setSpeed(GameSpeed.normal); // Resume speed on exit
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      appBar: AppBar(
        title: Text(
          'TOWN OF GLARUS',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            fontSize: 18,
            color: const Color(0xFFE5D5B0),
          ),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE5D5B0)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Consumer<GameState>(
            builder: (context, state, child) {
              final hasTraveler = state.npcs.any(
                (n) =>
                    n.worldDestinationId == 'hamlet' &&
                    n.worldTravelProgress >= 1.0,
              );

              return Stack(
                children: [
                  // Full Background Map
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/hamlet.jpg',
                      fit: BoxFit.cover,
                      color: Colors.black.withValues(
                        alpha: hasTraveler ? 0.3 : 0.6,
                      ),
                      colorBlendMode: BlendMode.darken,
                    ),
                  ),

                  // Interactive Hotspots
                  HamletHotspot(
                    label: 'Crossroads Tavern',
                    subtitle: 'Drink & Recruitment',
                    icon: Icons.nightlife,
                    top: constraints.maxHeight * 0.45,
                    left: constraints.maxWidth * 0.15,
                    width: 140,
                    height: 120,
                    hasTraveler: hasTraveler,
                    onTap: hasTraveler ? () => _showTavern(context) : null,
                  ),

                  HamletHotspot(
                    label: 'The Marketplace',
                    subtitle: 'Commerce & Supplies',
                    icon: Icons.storefront,
                    top: constraints.maxHeight * 0.55,
                    left: constraints.maxWidth * 0.65,
                    width: 180,
                    height: 140,
                    hasTraveler: hasTraveler,
                    onTap: hasTraveler ? () => _showMarket(context) : null,
                  ),

                  HamletHotspot(
                    label: 'Town Square',
                    subtitle: 'Distant Voices',
                    icon: Icons.account_balance,
                    top: constraints.maxHeight * 0.65,
                    left: constraints.maxWidth * 0.42,
                    width: 100,
                    height: 100,
                    hasTraveler: hasTraveler,
                    onTap: hasTraveler ? () => _showTownSquare(context) : null,
                  ),

                  // Top Info Overlay
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildInfoCard(),
                  ),

                  // Bottom Return Overlay
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: _buildReturnSection(context),
                  ),
                ],
              );
            },
          );
        },
      ),
    ),
  );
}

  Widget _buildReturnSection(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        final traveler = state.npcs.firstWhereOrNull(
          (n) =>
              n.worldDestinationId == 'hamlet' && n.worldTravelProgress >= 1.0,
        );
        if (traveler == null) {
          return const SizedBox.shrink();
        }
        return Center(
          child: ElevatedButton.icon(
            onPressed: () {
              state.returnToManor(traveler.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            icon: const Icon(Icons.keyboard_return),
            label: Text(
              "RETURN TO MANOR",
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFC4B89B).withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A sleepy border town, relatively untouched by the war across the border. Many refugees congregate here, seeking passage further south.',
            style: GoogleFonts.oldStandardTt(
              color: const Color(0xFFC4B89B),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _showMarket(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF241F1A),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MARKET OF GLARUS',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'SELECT A LOCAL VENDOR TO START TRADING',
                style: GoogleFonts.oldStandardTt(
                  color: const Color(0xFFC4B89B).withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
              const Divider(color: Colors.white10, height: 24),

              // Vendor 1: Grocer
              ListTile(
                leading: const Icon(Icons.storefront, color: Color(0xFFC4B89B)),
                title: Text(
                  "GROCER & PROVISIONER",
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  "DEALS IN VEGETABLES, SEEDS, GRAINS, SALT AND BASIC PROVISIONS.",
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Color(0xFFC4B89B),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showTradeDialog(
                    context,
                    HamletVendor.grocer,
                    "Grocer & Provisioner",
                    "Deals in vegetables, seeds, grains, salt and basic provisions.",
                    [
                      'cabbage',
                      'potato',
                      'carrots',
                      'beets',
                      'grain',
                      'eggs',
                      'meat',
                      'salt',
                      'fertilizer',
                      'wood',
                      'seeds_cabbage',
                      'seeds_potato',
                      'seeds_carrot',
                      'mushroom_spores',
                    ],
                    [
                      'cabbage',
                      'potato',
                      'carrots',
                      'beets',
                      'grain',
                      'eggs',
                      'meat',
                      'salt',
                      'fertilizer',
                      'wood',
                      'seeds_cabbage',
                      'seeds_potato',
                      'seeds_carrot',
                      'mushroom_spores',
                    ],
                  );
                },
              ),
              const Divider(color: Colors.white10),

              // Vendor 2: Rare Book & Art Curator
              ListTile(
                leading: const Icon(Icons.menu_book, color: Color(0xFFC4B89B)),
                title: Text(
                  "RARE BOOK & GOTHIC ART CURATOR",
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  "BUYS ARTWORK, LITERATURE, POEMS AND NOVELS FOR EXCELLENT WAGES.",
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Color(0xFFC4B89B),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showTradeDialog(
                    context,
                    HamletVendor.curator,
                    "Rare Book & Gothic Art Curator",
                    "Buys artwork, literature, poems and novels for excellent wages.",
                    ['unreviewed_document', 'old_notes', 'research_notes'],
                    [
                      'poem',
                      'novel',
                      'research_notes',
                      'unreviewed_document',
                      'old_notes',
                    ],
                  );
                },
              ),
              const Divider(color: Colors.white10),

              // Vendor 3: Shady Alchemist & Ratcatcher
              ListTile(
                leading: const Icon(Icons.biotech, color: Color(0xFFC4B89B)),
                title: Text(
                  "SHADY ALCHEMIST & RATCATCHER",
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  "DEALS IN SPECIMENS, ALCHEMICAL REAGENTS, CROPS AND ANATOMICAL HARVESTS.",
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Color(0xFFC4B89B),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showTradeDialog(
                    context,
                    HamletVendor.alchemist,
                    "Shady Alchemist & Ratcatcher",
                    "Deals in specimens, alchemical reagents, crops and anatomical harvests.",
                    ['herb_reagent', 'fertilizer'],
                    [
                      'rat',
                      'bat',
                      'chicken',
                      'fertilizer',
                      'herb_reagent',
                      'cannabis_buds',
                      'tobacco_leaves',
                      'hallucinogenic_mushrooms',
                      'hemp_fiber',
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showTradeDialog(
    BuildContext context,
    HamletVendor vendor,
    String vendorName,
    String description,
    List<String> buyableItems,
    List<String> sellableItems,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<GameState>(
          builder: (context, state, child) {
            final traveler = state.npcs.firstWhere(
              (n) =>
                  n.worldDestinationId == 'hamlet' &&
                  n.worldTravelProgress >= 1.0,
            );
            final funds = traveler.journeyInventory['funds'] ?? 0;

            return Dialog(
              backgroundColor: const Color(0xFF1E1A15),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              child: Container(
                width: 700,
                height: 500,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFC4B89B), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vendorName.toUpperCase(),
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFE5D5B0),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description.toUpperCase(),
                              style: GoogleFonts.oldStandardTt(
                                color: const Color(
                                  0xFFC4B89B,
                                ).withValues(alpha: 0.7),
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFFE5D5B0),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 24),

                    // Funds Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "YOUR FUNDS: ${funds.round()} CHF",
                          style: GoogleFonts.oswald(
                            color: const Color(0xFFE5D5B0),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: Row(
                        children: [
                          // Column 1: Player's Travel Bag
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.1),
                                border: Border.all(color: Colors.white10),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "PLAYER'S BAG (SELL TO VENDOR)",
                                    style: GoogleFonts.oswald(
                                      color: const Color(0xFFC4B89B),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Divider(color: Colors.white10),
                                  Expanded(
                                    child: ListView(
                                      children: sellableItems
                                          .where(
                                            (item) =>
                                                (traveler
                                                        .journeyInventory[item] ??
                                                    0) >
                                                0,
                                          )
                                          .map((res) {
                                            final count =
                                                traveler
                                                    .journeyInventory[res] ??
                                                0;
                                            final price = state.marketService
                                                .getSellPrice(res);

                                            return ListTile(
                                              contentPadding: EdgeInsets.zero,
                                               title: Text(
                                                _getPrettyResourceName(res),
                                                style:
                                                    GoogleFonts.playfairDisplay(
                                                      color: const Color(
                                                        0xFFE5D5B0,
                                                      ),
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "CARRIED: ${count.round()}",
                                                    style:
                                                        GoogleFonts.oldStandardTt(
                                                          color: Colors.white38,
                                                          fontSize: 8,
                                                        ),
                                                  ),
                                                  Text(
                                                    "MEASURE: ${_getItemUnitName(res).toUpperCase()}",
                                                    style: GoogleFonts.oswald(
                                                      color: const Color(
                                                        0xFFC4B89B,
                                                      ).withValues(alpha: 0.5),
                                                      fontSize: 7,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    "UNIT WT: ${_getItemWeightLabel(res).toUpperCase()}",
                                                    style: GoogleFonts.oswald(
                                                      color: const Color(
                                                        0xFFC4B89B,
                                                      ).withValues(alpha: 0.5),
                                                      fontSize: 7,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              trailing: OutlinedButton(
                                                onPressed: () =>
                                                    state.sellResource(res, 1),
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(
                                                    color: Color(0xFFC4B89B),
                                                  ),
                                                  shape:
                                                      const RoundedRectangleBorder(),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                      ),
                                                ),
                                                child: Text(
                                                  "SELL ($price)",
                                                  style:
                                                      GoogleFonts.playfairDisplay(
                                                        color: const Color(
                                                          0xFFE5D5B0,
                                                        ),
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ),
                                            );
                                          })
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Column 2: Vendor's Stock
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.1),
                                border: Border.all(color: Colors.white10),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "VENDOR'S STOCK (BUY FROM VENDOR)",
                                    style: GoogleFonts.oswald(
                                      color: const Color(0xFFC4B89B),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Divider(color: Colors.white10),
                                  Expanded(
                                    child: ListView(
                                      children: buyableItems.map((res) {
                                        final count =
                                            traveler.journeyInventory[res] ?? 0;
                                        final price = state.marketService
                                            .getBuyPrice(res);

                                        return ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(
                                            _getPrettyResourceName(res),
                                            style: GoogleFonts.playfairDisplay(
                                              color: const Color(0xFFE5D5B0),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "IN PACK: ${count.round()}",
                                                style:
                                                    GoogleFonts.oldStandardTt(
                                                      color: Colors.white38,
                                                      fontSize: 8,
                                                    ),
                                              ),
                                              Text(
                                                "MEASURE: ${_getItemUnitName(res).toUpperCase()}",
                                                style: GoogleFonts.oswald(
                                                  color: const Color(
                                                    0xFFC4B89B,
                                                  ).withValues(alpha: 0.5),
                                                  fontSize: 7,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                "UNIT WT: ${_getItemWeightLabel(res).toUpperCase()}",
                                                style: GoogleFonts.oswald(
                                                  color: const Color(
                                                    0xFFC4B89B,
                                                  ).withValues(alpha: 0.5),
                                                  fontSize: 7,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: OutlinedButton(
                                            onPressed: funds >= price
                                                ? () =>
                                                      state.buyResource(res, 1)
                                                : null,
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: funds >= price
                                                    ? const Color(0xFFC4B89B)
                                                    : Colors.white10,
                                              ),
                                              shape:
                                                  const RoundedRectangleBorder(),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                            ),
                                            child: Text(
                                              "BUY ($price)",
                                              style:
                                                  GoogleFonts.playfairDisplay(
                                                    color: funds >= price
                                                        ? const Color(
                                                            0xFFE5D5B0,
                                                          )
                                                        : Colors.white12,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getItemUnitName(String type) {
    if (type == 'salt') return 'Decagram (Precious)';
    if (type == 'wood') return 'Kilogram';
    if (type == 'rooster' ||
        type == 'chicken' ||
        type == 'rat' ||
        type == 'bat') {
      return 'Whole Unit (Variable)';
    }
    return 'Whole Unit';
  }

  String _getPrettyResourceName(String res) {
    if (res == 'seeds_cabbage') return 'CABBAGE SEEDS';
    if (res == 'seeds_potato') return 'POTATO SEEDS';
    if (res == 'seeds_carrot') return 'CARROT SEEDS';
    if (res == 'seeds_cannabis') return 'CANNABIS SEEDS';
    if (res == 'seeds_tobacco') return 'TOBACCO SEEDS';
    if (res == 'mushroom_spores') return 'MUSHROOM SPORES';
    if (res == 'salt') return 'SALT';
    if (res == 'wood') return 'WOOD';
    if (res == 'grain') return 'GRAIN';
    return res.replaceAll('_', ' ').toUpperCase();
  }

  String _getItemWeightLabel(String type) {
    final grams = _getItemWeightGrams(type);
    if (type == 'rooster' ||
        type == 'chicken' ||
        type == 'rat' ||
        type == 'bat') {
      return 'Variable (~${_formatWeight(grams)})';
    }
    return _formatWeight(grams);
  }

  int _getItemWeightGrams(String type) {
    switch (type) {
      case 'cabbage':
        return 1200;
      case 'potato':
        return 150;
      case 'carrots':
        return 100;
      case 'beets':
        return 200;
      case 'eggs':
        return 60;
      case 'grain':
        return 500;
      case 'rooster':
        return 2300;
      case 'chicken':
        return 1800;
      case 'rat':
        return 320;
      case 'bat':
        return 150;
      case 'poem':
        return 10;
      case 'novel':
        return 450;
      case 'unreviewed_document':
        return 20;
      case 'old_notes':
        return 150;
      case 'research_notes':
        return 100;
      case 'seeds_cabbage':
        return 5;
      case 'seeds_potato':
        return 5;
      case 'seeds_carrot':
        return 5;
      case 'seeds_cannabis':
        return 10;
      case 'seeds_tobacco':
        return 10;
      case 'mushroom_spores':
        return 5;
      case 'fertilizer':
        return 5000;
      case 'ale':
        return 1000;
      case 'spirits':
        return 750;
      case 'timber':
        return 15000;
      case 'hemp_fiber':
        return 1000;
      case 'cannabis_buds':
        return 50;
      case 'tobacco_leaves':
        return 100;
      case 'hallucinogenic_mushrooms':
        return 20;

      case 'wood':
        return 1000;
      case 'salt':
        return 100; // 1 hectogram = 100g (contains 10 decagrams)
      default:
        return 100;
    }
  }

  String _formatWeight(int grams) {
    if (grams < 1000) {
      return '$grams g';
    }
    final double kg = grams / 1000.0;
    if (kg < 100.0) {
      return '${kg.toStringAsFixed(1)} kg';
    } else {
      return '${kg.toStringAsFixed(0)} kg';
    }
  }

  void _showTavern(BuildContext context) {
    final state = Provider.of<GameState>(context, listen: false);
    if (state.availableHamletNpcs.isEmpty) state.refreshHamletNpcs();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF241F1A),
      isScrollControlled: true,
      builder: (context) {
        return Consumer<GameState>(
          builder: (context, state, child) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CROSSROADS TAVERN',
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'FUNDS: ${state.npcs.firstWhere((n) => n.worldDestinationId == 'hamlet' && n.worldTravelProgress >= 1.0).journeyInventory['funds']?.round()} CHF',
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFC4B89B),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.availableHamletNpcs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                        'The tavern is empty. No one is looking for work right now.',
                        style: GoogleFonts.oldStandardTt(color: Colors.white24),
                      ),
                    )
                  else
                    ...state.availableHamletNpcs.map(
                      (npc) => _buildNpcRecruitTile(context, state, npc),
                    ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => state.refreshHamletNpcs(),
                    child: Text(
                      'WAIT FOR OTHERS (-5 FUNDS)',
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFFC4B89B),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNpcRecruitTile(
    BuildContext context,
    GameState state,
    dynamic npc,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
        ),
        color: Colors.black.withValues(alpha: 0.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: Color(0xFFC4B89B)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  npc.name.toUpperCase(),
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${npc.role.toUpperCase()} | ${npc.age}Y | ${npc.nationality.toUpperCase()}',
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'WAGES: ${npc.monthlySalary} CHF / MONTH',
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFC4B89B),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              state.hireNpc(npc);
              Navigator.pop(context); // Pop tavern sheet

              final String guestType = npc.metadata['guestType'] as String? ?? '';
              if (guestType.endsWith('_proposer')) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showHireProposalDialog(context, state, npc);
                });
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFC4B89B)),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: Text(
              'HIRE (${npc.hiringFee} CHF)',
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFE5D5B0),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHireProposalDialog(BuildContext context, GameState state, dynamic guest) {
    final String guestType = guest.metadata['guestType'] as String? ?? '';
    List<BusinessType> options = [];
    
    if (guestType == 'cook_proposer') {
      options = [BusinessType.bistro, BusinessType.bakery, BusinessType.pizzeria, BusinessType.cafe];
    } else if (guestType == 'chemist_proposer') {
      options = [BusinessType.opiateLab];
    } else if (guestType == 'lawyer_proposer') {
      options = [BusinessType.lawPractice];
    } else if (guestType == 'doctor_proposer') {
      options = [BusinessType.medicalPractice];
    } else if (guestType == 'actor_proposer') {
      options = [BusinessType.theater];
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1A15),
          shape: const RoundedRectangleBorder(),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC4B89B)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SPECIALIST RECRUIT PROPOSAL",
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${guest.name.toUpperCase()} IS A SPECIALIST WHO OFFERS TO RUN A BUSINESS VENTURE AT THE MANOR. CHOOSE A VENTURE TO INITIATE:",
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFC4B89B),
                    fontSize: 9.5,
                    height: 1.3,
                  ),
                ),
                const Divider(color: Colors.white10, height: 24),
                ...options.map((type) {
                  final bool requiresDegree = type == BusinessType.lawPractice || type == BusinessType.medicalPractice || type == BusinessType.opiateLab;
                  final bool locked = requiresDegree && !state.playerHasGraduateDegree;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    title: Text(
                      type.displayName.toUpperCase(),
                      style: GoogleFonts.playfairDisplay(
                        color: locked ? Colors.white24 : const Color(0xFFE5D5B0),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    subtitle: Text(
                      requiresDegree 
                          ? (locked 
                              ? "LOCKED: ALPHONSE LACKS GRADUATE DEGREE. STUDY AT GRADUATE SCHOOL."
                              : "GRADUATE DEGREE ATTAINED (UNLOCKED)")
                          : "STANDARD ASSIGNMENTS SYSTEM INITIATED.",
                      style: GoogleFonts.oldStandardTt(
                        color: locked ? Colors.redAccent : Colors.white38,
                        fontSize: 8.5,
                      ),
                    ),
                    trailing: locked 
                        ? const Icon(Icons.lock_outline, color: Colors.white12, size: 14)
                        : const Icon(Icons.arrow_forward, color: Color(0xFFC4B89B), size: 14),
                    onTap: locked 
                        ? null 
                        : () {
                            state.proposeBusiness(type, guest.id, guest.name);
                            final bus = state.activeBusinesses.firstWhere((b) => b.proposerId == guest.id);
                            state.acceptBusinessProposal(bus.id);
                            
                            Navigator.pop(context); // Pop selection

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("${type.displayName} setup assignments initiated at Glarus!"),
                                backgroundColor: const Color(0xFF241F1A),
                              ),
                            );
                          },
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "DECLINE BUSINESS VENTURE FOR NOW",
                      style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTownSquare(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('The town square is quiet today...')),
    );
  }
}
