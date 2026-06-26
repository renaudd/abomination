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
import '../../state/game_state.dart';
import '../../models/game_item.dart';
import '../../models/relationship.dart';
import '../../models/npc.dart';
import '../widgets/encounter_dialog.dart';

enum GiftType {
  wine,
  whiskey,
  art,
  jewelry,
  literature,
  pets,
  flowers,
  generalGift,
  offensive,
}

class DestinationScreen extends StatefulWidget {
  final String destinationId;
  const DestinationScreen({super.key, required this.destinationId});

  @override
  State<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends State<DestinationScreen> {
  bool _isNavigatingToCombat = false;

  void _checkCombatEncounter(GameState state) {
    if (state.pendingCombatEncounter && !_isNavigatingToCombat && ModalRoute.of(context)?.isCurrent == true) {
      _isNavigatingToCombat = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const EncounterDialog(),
        ).then((_) {
          if (mounted) {
            setState(() {
              _isNavigatingToCombat = false;
            });
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);
    _checkCombatEncounter(state);

    final name = widget.destinationId.toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      appBar: AppBar(
        title: Text(
          name,
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
                    n.worldDestinationId == widget.destinationId &&
                    n.worldTravelProgress >= 1.0,
              );

              return Stack(
                children: [
                   // Placeholder for background image or stylized background
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: Center(
                        child: Icon(
                          _getDestinationIcon(widget.destinationId),
                          size: 200,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                  ),

                  // Info Card
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      color: Colors.black.withValues(alpha: 0.4),
                      child: Text(
                        _getDestinationDescription(widget.destinationId),
                        style: GoogleFonts.oldStandardTt(
                          color: const Color(0xFFC4B89B),
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),

                  // Interaction Buttons (Generic for now)
                  if (hasTraveler)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.destinationId.startsWith('cottage_')
                            ? _buildCottageInteractionButtons(context, state)
                            : widget.destinationId == 'carbonari'
                                ? [
                                    _buildActionButton(
                                      context,
                                      'REVOLUTIONARY ALCHEMICAL EXCHANGE',
                                      Icons.science,
                                      () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Exchanged revolutionary notes! Received 500 Gold & Alchemical Reagents.')),
                                        );
                                        state.updateResource('funds', 500);
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    _buildActionButton(
                                      context,
                                      'CARBONARI SMUGGLING RUN',
                                      Icons.directions_boat,
                                      () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Completed revolutionary smuggling run for the Carbonari. Gained Faction Standing!')),
                                        );
                                      },
                                    ),
                                  ]
                                : [
                                    _buildActionButton(
                                      context,
                                      'SCAVENGE AREA',
                                      Icons.search,
                                      () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Scavenging takes time and effort...')),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    _buildActionButton(
                                      context,
                                      'REST BY CAMPFIRE',
                                      Icons.fireplace,
                                      () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Resting recovers a bit of energy.')),
                                        );
                                      },
                                    ),
                                  ],
                      ),
                    ),

                  // Return Section
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: _buildReturnSection(context, state),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, VoidCallback? onTap) {
    return SizedBox(
      width: 240,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF241F1A),
          foregroundColor: const Color(0xFFE5D5B0),
          side: const BorderSide(color: Color(0xFFC4B89B)),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildReturnSection(BuildContext context, GameState state) {
    if (state.npcs.isEmpty) return const SizedBox.shrink();
    final traveler = state.npcs.firstWhere(
      (n) => n.worldDestinationId == widget.destinationId && n.worldTravelProgress >= 1.0,
      orElse: () => state.npcs.first, // Fallback
    );

    final hasTraveler = state.npcs.any(
      (n) => n.worldDestinationId == widget.destinationId && n.worldTravelProgress >= 1.0,
    );

    if (!hasTraveler) return const SizedBox.shrink();

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
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
  }

  List<Widget> _buildCottageInteractionButtons(BuildContext context, GameState state) {
    String neighborName = '';
    String factionName = '';
    if (widget.destinationId == 'cottage_gregor') {
      neighborName = 'Father Gregor Zweifel';
      factionName = 'Glarus';
    } else if (widget.destinationId == 'cottage_fritz') {
      neighborName = 'Professor Fritz Weishaupt';
      factionName = 'Bavarian Illuminati';
    } else if (widget.destinationId == 'cottage_antoinette') {
      neighborName = 'Countess Antoinette de Bertier';
      factionName = 'Chevaliers de la foi';
    } else if (widget.destinationId == 'cottage_regina') {
      neighborName = 'Baroness Regina von Stauffacher';
      factionName = 'Gnomes of Zurich';
    } else if (widget.destinationId == 'cottage_johannes') {
      neighborName = 'Johannes the Hermit';
      factionName = 'Rosicrucians';
    } else if (widget.destinationId == 'cottage_seamus') {
      neighborName = 'Seamus O\'Connor';
      factionName = 'Fenian Brotherhood';
    } else if (widget.destinationId == 'cottage_elspeth') {
      neighborName = 'Elspeth Luchsinger';
      factionName = 'Ancient Order of Foresters';
    } else if (widget.destinationId == 'cottage_giuseppe') {
      neighborName = 'Giuseppe Rossi';
      factionName = 'Carbonari';
    } else if (widget.destinationId == 'cottage_godfrey') {
      neighborName = 'Godfrey de Molay';
      factionName = 'Knights Templar';
    } else if (widget.destinationId == 'cottage_lilith') {
      neighborName = 'Lilith Crowley';
      factionName = 'Golden Dawn';
    }

    NPC? neighborNpc;
    try {
      neighborNpc = state.npcs.firstWhere((n) => n.name == neighborName);
    } catch (_) {
      neighborNpc = null;
    }
    final String neighborId = neighborNpc?.id ?? '';

    return [
      _buildActionButton(
        context,
        'CONSULT $neighborName',
        Icons.chat,
        () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: const Color(0xFF1E1A15),
              shape: const RoundedRectangleBorder(),
              child: Container(
                width: 450,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFC4B89B), width: 1.5)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      neighborName.toUpperCase(),
                      style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      factionName.toUpperCase(),
                      style: GoogleFonts.oldStandardTt(color: const Color(0xFFC4B89B), fontSize: 10, letterSpacing: 1),
                    ),
                    const Divider(color: Colors.white10, height: 20),
                    const SizedBox(height: 8),
                    Text(
                      "Greetings, representative of Glarus. The path we walk is long, but together under our mutual standing (${state.getFactionStanding(factionName).toStringAsFixed(1)}), we shall achieve great outcomes for the valley.",
                      style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 13, height: 1.4, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC4B89B)),
                        onPressed: () => Navigator.pop(context),
                        child: Text("DISMISS", style: GoogleFonts.playfairDisplay(color: const Color(0xFF1E1A15), fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 16),
      _buildActionButton(
        context,
        'GIFT AN ITEM',
        Icons.card_giftcard,
        () {
          _showGiftSelectionDialog(context, state, neighborName, factionName, neighborId);
        },
      ),
    ];
  }

  GiftType _getGiftType(GameItem item) {
    final name = item.name.toLowerCase();
    final type = item.type.toLowerCase();
    
    if (item.category == ItemCategory.corpse || item.category == ItemCategory.material) {
      return GiftType.offensive;
    }
    
    if (name.contains('rat') || type.contains('rat') ||
        name.contains('organ') || type.contains('organ') ||
        name.contains('brain') || type.contains('brain') ||
        name.contains('flesh') || type.contains('flesh') ||
        name.contains('blood') || type.contains('blood') ||
        name.contains('bone') || type.contains('bone') ||
        name.contains('seed') || type.contains('seed') ||
        name.contains('timber') || type.contains('timber') ||
        name.contains('raw') || type.contains('raw') ||
        name.contains('onion') || type.contains('onion') ||
        name.contains('cabbage') || type.contains('cabbage') ||
        name.contains('carrot') || type.contains('carrot') ||
        name.contains('potato') || type.contains('potato') ||
        name.contains('grain') || type.contains('grain') ||
        name.contains('flour') || type.contains('flour') ||
        name.contains('salt') || type.contains('salt') ||
        name.contains('pepper') || type.contains('pepper')) {
      return GiftType.offensive;
    }

    if (name.contains('wine') || type.contains('wine') ||
        name.contains('champagne') || type.contains('champagne') ||
        name.contains('bordeaux') || type.contains('bordeaux') ||
        name.contains('vintage') || type.contains('vintage')) {
      return GiftType.wine;
    }
    
    if (name.contains('whiskey') || type.contains('whiskey') ||
        name.contains('whisky') || type.contains('whisky') ||
        name.contains('bourbon') || type.contains('bourbon') ||
        name.contains('scotch') || type.contains('scotch') ||
        name.contains('brandy') || type.contains('brandy') ||
        name.contains('rum') || type.contains('rum') ||
        name.contains('gin') || type.contains('gin') ||
        name.contains('spirits') || type.contains('spirits')) {
      return GiftType.whiskey;
    }

    if (name.contains('art') || type.contains('art') ||
        name.contains('painting') || type.contains('painting') ||
        name.contains('portrait') || type.contains('portrait') ||
        name.contains('sculpture') || type.contains('sculpture') ||
        name.contains('sketch') || type.contains('sketch') ||
        name.contains('canvas') || type.contains('canvas')) {
      return GiftType.art;
    }

    if (name.contains('jewelry') || type.contains('jewelry') ||
        name.contains('necklace') || type.contains('necklace') ||
        name.contains('ring') || type.contains('ring') ||
        name.contains('brooch') || type.contains('brooch') ||
        name.contains('gem') || type.contains('gem') ||
        name.contains('emerald') || type.contains('emerald') ||
        name.contains('ruby') || type.contains('ruby') ||
        name.contains('sapphire') || type.contains('sapphire') ||
        name.contains('diamond') || type.contains('diamond')) {
      return GiftType.jewelry;
    }

    if (name.contains('book') || type.contains('book') ||
        name.contains('novel') || type.contains('novel') ||
        name.contains('volume') || type.contains('volume') ||
        name.contains('tome') || type.contains('tome') ||
        name.contains('manuscript') || type.contains('manuscript') ||
        name.contains('scroll') || type.contains('scroll') ||
        name.contains('poetry') || type.contains('poetry') ||
        name.contains('poem') || type.contains('poem')) {
      return GiftType.literature;
    }

    if (name.contains('pup') || type.contains('pup') ||
        name.contains('dog') || type.contains('dog') ||
        name.contains('puppy') || type.contains('puppy') ||
        name.contains('cat') || type.contains('cat') ||
        name.contains('kitten') || type.contains('kitten') ||
        name.contains('fox') || type.contains('fox')) {
      return GiftType.pets;
    }

    if (name.contains('flower') || type.contains('flower') ||
        name.contains('rose') || type.contains('rose') ||
        name.contains('lily') || type.contains('lily') ||
        name.contains('bouquet') || type.contains('bouquet') ||
        name.contains('blossom') || type.contains('blossom')) {
      return GiftType.flowers;
    }

    if (name.contains('chocolate') || type.contains('chocolate') ||
        name.contains('cheese') || type.contains('cheese') ||
        name.contains('honey') || type.contains('honey') ||
        name.contains('pastry') || type.contains('pastry') ||
        name.contains('cake') || type.contains('cake') ||
        name.contains('candy') || type.contains('candy') ||
        name.contains('cigar') || type.contains('cigar')) {
      return GiftType.generalGift;
    }

    if (item.category == ItemCategory.reagent || item.category == ItemCategory.specimen) {
      return GiftType.offensive;
    }

    return GiftType.generalGift;
  }

  GiftType _getNeighborFavoriteGiftType(String destinationId) {
    switch (destinationId) {
      case 'cottage_gregor':
        return GiftType.literature;
      case 'cottage_fritz':
        return GiftType.jewelry;
      case 'cottage_antoinette':
        return GiftType.wine;
      case 'cottage_regina':
        return GiftType.jewelry;
      case 'cottage_johannes':
        return GiftType.art;
      case 'cottage_seamus':
        return GiftType.whiskey;
      case 'cottage_elspeth':
        return GiftType.pets;
      case 'cottage_giuseppe':
        return GiftType.whiskey;
      case 'cottage_godfrey':
        return GiftType.literature;
      case 'cottage_lilith':
        return GiftType.flowers;
      default:
        return GiftType.generalGift;
    }
  }

  void _showGiftSelectionDialog(
    BuildContext context,
    GameState state,
    String neighborName,
    String factionName,
    String neighborId,
  ) {
    final List<GameItem> items = state.inventory;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1A15),
          shape: const RoundedRectangleBorder(),
          child: Container(
            width: 500,
            height: 450,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC4B89B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SELECT A GIFT FOR $neighborName",
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  "Choose an item from the manor vaults to offer as a gift. Appreciated or favorite items build relationships; offensive items will ruin them.",
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFC4B89B),
                    fontSize: 10.5,
                    height: 1.3,
                  ),
                ),
                const Divider(color: Colors.white10, height: 24),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            "The manor vaults are empty. You have no items to offer.",
                            style: GoogleFonts.oldStandardTt(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final giftType = _getGiftType(item);
                            final favoriteType = _getNeighborFavoriteGiftType(widget.destinationId);
                            final isFav = giftType == favoriteType;
                            final isOff = giftType == GiftType.offensive;

                            Color badgeColor = Colors.grey;
                            String badgeText = "Normal";
                            if (isFav) {
                              badgeColor = Colors.amber;
                              badgeText = "FAVORITE";
                            } else if (isOff) {
                              badgeColor = Colors.redAccent;
                              badgeText = "RISKY / RAW";
                            } else if (giftType != GiftType.generalGift) {
                              badgeColor = Colors.green;
                              badgeText = "GIFT CLASS";
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: item.color.withValues(alpha: 0.2),
                                      shape: item.shape == ItemShape.circle ? BoxShape.circle : BoxShape.rectangle,
                                      border: Border.all(color: item.color.withValues(alpha: 0.4)),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        isOff ? Icons.warning_amber_rounded : Icons.card_giftcard,
                                        size: 14,
                                        color: item.color,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: GoogleFonts.playfairDisplay(
                                            color: const Color(0xFFE5D5B0),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              "Qty: ${item.quantity} | ",
                                              style: GoogleFonts.oldStandardTt(
                                                color: Colors.white38,
                                                fontSize: 10,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: badgeColor.withValues(alpha: 0.15),
                                                border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 0.5),
                                              ),
                                              child: Text(
                                                badgeText,
                                                style: GoogleFonts.oldStandardTt(
                                                  color: badgeColor,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3E352B),
                                      foregroundColor: const Color(0xFFE5D5B0),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: const RoundedRectangleBorder(),
                                      side: const BorderSide(color: Color(0xFFC4B89B), width: 0.8),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _executeGift(context, state, item, neighborName, factionName, neighborId);
                                    },
                                    child: Text(
                                      "GIFT",
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "CLOSE",
                      style: GoogleFonts.playfairDisplay(color: const Color(0xFFC4B89B), fontWeight: FontWeight.bold),
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

  void _executeGift(
    BuildContext context,
    GameState state,
    GameItem item,
    String neighborName,
    String factionName,
    String neighborId,
  ) {
    final bool success = state.consumeManorItem(item.type, quantity: 1);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to find item in manor vaults.')),
      );
      return;
    }

    final giftType = _getGiftType(item);
    final favoriteType = _getNeighborFavoriteGiftType(widget.destinationId);
    
    double admirationDelta = 0.0;
    double respectDelta = 0.0;
    double fearDelta = 0.0;
    double attractionDelta = 0.0;
    double factionStandingDelta = 0.0;
    String reactionText = '';

    if (giftType == GiftType.offensive) {
      admirationDelta = -1.0;
      respectDelta = -0.5;
      fearDelta = 0.2;
      attractionDelta = -1.0;
      factionStandingDelta = -0.05;
      reactionText = 'They look horrified and deeply offended by this offering. "Is this some kind of sick joke, Frankenstein? Take this away at once."';
    } else if (giftType == favoriteType) {
      admirationDelta = 0.8;
      respectDelta = 0.5;
      attractionDelta = 0.6;
      factionStandingDelta = 0.05;
      reactionText = 'Their eyes light up with immense joy as they inspect the gift. "Ah! This is absolutely magnificent! How did you know this was my favorite?"';
    } else {
      admirationDelta = 0.4;
      respectDelta = 0.2;
      attractionDelta = 0.3;
      factionStandingDelta = 0.01;
      reactionText = 'They accept the gift with a warm smile. "Thank you, Frankenstein. This is a very kind gesture, and it is highly appreciated."';
    }

    if (neighborId.isNotEmpty) {
      state.adjustNpcRelationshipWithPlayer(
        neighborId,
        admiration: admirationDelta,
        respect: respectDelta,
        fear: fearDelta,
        attraction: attractionDelta,
      );
    }
    state.adjustFactionStanding(factionName, factionStandingDelta);

    showDialog(
      context: context,
      builder: (context) {
        final rel = (neighborId.isNotEmpty) 
            ? (state.npcs.firstWhere((n) => n.id == neighborId).relationships['player'] ?? Relationship())
            : Relationship();

        return Dialog(
          backgroundColor: const Color(0xFF1E1A15),
          shape: const RoundedRectangleBorder(),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC4B89B), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "GIFT RECIPIENT REACTION",
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  neighborName.toUpperCase(),
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFC4B89B),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const Divider(color: Colors.white10, height: 24),
                Text(
                  reactionText,
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 13.5,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  "RELATIONSHIP IMPACT:",
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFC4B89B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatDeltaRow("Admiration", rel.admiration, admirationDelta),
                const SizedBox(height: 6),
                _buildStatDeltaRow("Respect", rel.respect, respectDelta),
                const SizedBox(height: 6),
                _buildStatDeltaRow("Fear", rel.fear, fearDelta),
                const SizedBox(height: 6),
                _buildStatDeltaRow("Attraction", rel.attraction, attractionDelta),
                const SizedBox(height: 6),
                _buildStandingDeltaRow(factionName, state.getFactionStanding(factionName), factionStandingDelta),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC4B89B),
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "CONCLUDE",
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFF1E1A15),
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildStatDeltaRow(String label, double val, double delta) {
    final String sign = delta >= 0 ? "+" : "";
    final Color deltaColor = delta > 0 
        ? Colors.green 
        : (delta < 0 ? Colors.redAccent : Colors.white38);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 12),
        ),
        Row(
          children: [
            Text(
              val.toStringAsFixed(1),
              style: GoogleFonts.oldStandardTt(color: const Color(0xFFE5D5B0), fontSize: 12, fontWeight: FontWeight.bold),
            ),
            if (delta != 0) ...[
              const SizedBox(width: 8),
              Text(
                "($sign${delta.toStringAsFixed(1)})",
                style: GoogleFonts.oldStandardTt(color: deltaColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStandingDeltaRow(String faction, double val, double delta) {
    final String sign = delta >= 0 ? "+" : "";
    final Color deltaColor = delta > 0 
        ? Colors.green 
        : (delta < 0 ? Colors.redAccent : Colors.white38);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "$faction Standing",
          style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 12),
        ),
        Row(
          children: [
            Text(
              val.toStringAsFixed(2),
              style: GoogleFonts.oldStandardTt(color: const Color(0xFFE5D5B0), fontSize: 12, fontWeight: FontWeight.bold),
            ),
            if (delta != 0) ...[
              const SizedBox(width: 8),
              Text(
                "($sign${delta.toStringAsFixed(2)})",
                style: GoogleFonts.oldStandardTt(color: deltaColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ],
    );
  }

  IconData _getDestinationIcon(String id) {
    switch (id) {
      case 'mountains':
        return Icons.terrain;
      case 'woods':
        return Icons.forest;
      case 'river':
        return Icons.water;
      case 'carbonari':
        return Icons.local_fire_department;
      case 'cottage_gregor':
        return Icons.church;
      case 'cottage_fritz':
        return Icons.watch_later_outlined;
      case 'cottage_antoinette':
        return Icons.gavel;
      case 'cottage_regina':
        return Icons.account_balance;
      case 'cottage_johannes':
        return Icons.brightness_3;
      case 'cottage_seamus':
        return Icons.build;
      case 'cottage_elspeth':
        return Icons.nature_people;
      case 'cottage_giuseppe':
        return Icons.fireplace;
      case 'cottage_godfrey':
        return Icons.shield;
      case 'cottage_lilith':
        return Icons.auto_stories;
      default:
        return Icons.explore;
    }
  }

  String _getDestinationDescription(String id) {
    switch (id) {
      case 'mountains':
        return 'The jagged peaks of the Swiss Alps loom overhead. The air is thin and cold, but rare minerals can be found in the crevices.';
      case 'woods':
        return 'A dense, ancient forest where the sunlight struggles to reach the mossy floor. Ideal for gathering timber and searching for specimens.';
      case 'river':
        return 'The icy waters of the Linth river flow rapidly towards the valley. A good place for fresh water and clay.';
      case 'carbonari':
        return 'A secret alpine hunting lodge serving as a covert meeting site for the revolutionary Carbonari faction.';
      case 'cottage_gregor':
        return 'St. Fridolin\'s Parish — Father Gregor Zweifel\'s cold, drafty parish church where candle wax drips and ancient ledgers whispering of local secrets are stored.';
      case 'cottage_fritz':
        return 'Clockwork Cottage — Professor Fritz Weishaupt\'s eccentric home, filled with ticking pendulum clocks, gears, and cages of forest animals being re-educated.';
      case 'cottage_antoinette':
        return 'Chateau de la Foi — Countess Antoinette\'s fortified vineyard estate, decorated with French royalist flags and cases of fine wine.';
      case 'cottage_regina':
        return 'Neoclassical Vault — A heavily guarded neoclassical chateau containing the private vaults of Baroness Regina and the Gnomes of Zurich.';
      case 'cottage_johannes':
        return 'Alchemical Cave — Johannes the Hermit\'s secluded subterranean sanctuary, glowing with alchemical fires and bubbling elixirs.';
      case 'cottage_seamus':
        return 'Covert Forge — Seamus O\'Connor\'s smoky blacksmith forge, where the sounds of hammers on hot iron mask the preparations for a grand uprising.';
      case 'cottage_elspeth':
        return 'Moss-Grown Grove — Elspeth Luchsinger\'s wild woodland treehouse and sanctuary, surrounded by protective forest animals and ancient trees.';
      case 'cottage_giuseppe':
        return 'Charcoal Pit Hut — Giuseppe Rossi\'s smoky forest camp, a center for Carbonari workers organizing the sparks of liberty.';
      case 'cottage_godfrey':
        return 'Ancient Stone Keep — A weathered medieval keep housing Godfrey de Molay and his devout Knights Templar, standing guard against occult heretical threats.';
      case 'cottage_lilith':
        return 'Gothic Manor — A mysterious, dark chateau where Lilith Crowley and the Golden Dawn conduct Hermetic rituals and study the astral planes.';
      default:
        return 'A remote location on the estate grounds.';
    }
  }
}
