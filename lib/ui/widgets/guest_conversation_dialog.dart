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

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import '../../models/active_business.dart';
import '../../models/npc.dart';
import '../../models/visitor_quest.dart';
import 'visiting_merchant_trade_dialog.dart';
import '../../models/language_encounter.dart';
import '../../models/neighbor_encounter.dart';
import '../../models/room.dart';
import '../../services/npc_generator.dart';
import 'diodati_portrait_widget.dart';
import '../../models/game_item.dart';

class GuestConversationDialog extends StatelessWidget {
  const GuestConversationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        final greeter = state.conversationGreeter;
        final guest = state.conversationGuest;

        if (greeter == null || guest == null) {
          return const SizedBox.shrink();
        }

        final String guestType = guest.metadata['guestType'] as String? ?? '';
        final bool isMerchant = guestType == 'merchant';
        final bool isProposer = guestType.endsWith('_proposer');
        final hasSpirits = (state.resources['spirits'] ?? 0) >= 1;

        final encounter = state.activeLanguageEncounter;
        if (encounter != null) {
          return _buildFloatingDialogueRow(
            guest: guest,
            titleText: encounter.id >= 11 && encounter.id <= 16
                ? "FOREIGN CUSTOMER INQUIRY"
                : "VISITOR LANGUAGE TEST",
            content: _buildLanguageEncounterContent(
              context,
              state,
              greeter,
              guest,
              encounter,
            ),
            onClose: () => state.clearGuestConversation(),
          );
        }

        final String titleText = guest.name.toUpperCase();

        final List<Widget> content = guestType == 'plot_visitor'
            ? _buildPlotVisitorContent(context, state, greeter, guest)
            : (guestType == 'neighbor'
                  ? _buildNeighborOptions(context, state, greeter, guest)
                  : _buildStandardVisitorContent(
                      context,
                      state,
                      greeter,
                      guest,
                      isMerchant,
                      isProposer,
                      hasSpirits,
                    ));

        return _buildFloatingDialogueRow(
          guest: guest,
          titleText: titleText,
          content: content,
          onClose: () => state.clearGuestConversation(),
        );
      },
    );
  }

  Widget _buildFloatingDialogueRow({
    required NPC guest,
    required String titleText,
    required List<Widget> content,
    required VoidCallback onClose,
  }) {
    // 1. Portrait Widget (Free floating, boxless)
    final Widget portraitWidget = DiodatiPortraitWidget(
      npcName: guest.name,
      size: 80.0,
      useBox: false,
    );

    // 2. Dialogue Card Widget
    final Widget dialogueCard = Container(
      constraints: const BoxConstraints(maxWidth: 450),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A15).withOpacity(0.95),
        border: Border.all(
          color: const Color(0xFFD4AF37),
          width: 2,
        ), // Muted Gold
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titleText,
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Color(0xFFE5D5B0),
                  size: 16,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: content,
              ),
            ),
          ),
        ],
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [portraitWidget, const SizedBox(width: 16), dialogueCard],
    );
  }

  List<Widget> _buildStandardVisitorContent(
    BuildContext context,
    GameState state,
    NPC greeter,
    NPC guest,
    bool isMerchant,
    bool isProposer,
    bool hasSpirits,
  ) {
    final List<Widget> optionWidgets = [];

    // Business Venture Proposal Option
    if (isProposer) {
      optionWidgets.add(
        _dialogOption(
          context: context,
          title: "DISCUSS COMMERCIAL PROPOSAL",
          description:
              "Hear ${guest.name.toUpperCase()}'s venture proposal. Set up a specialty business at the manor.",
          icon: Icons.business_center,
          onTap: () {
            _showVentureProposalDetails(context, state, guest);
          },
        ),
      );
    }

    // Option 1: Welcome and Trade
    optionWidgets.add(
      _dialogOption(
        context: context,
        title: isMerchant ? "DISCUSS MERCHANDISE" : "WELCOME & OFFER COMMERCE",
        description: isMerchant
            ? "Offer the merchant hospitality and inspect their wagon wares."
            : "Welcome the visitor and ask if they carry any trade stock.",
        icon: Icons.storefront,
        onTap: () {
          guest.metadata['isGreeted'] = true;
          state.clearGuestConversation();

          if (isMerchant) {
            showDialog(
              context: context,
              builder: (context) =>
                  VisitingMerchantTradeDialog(merchant: guest),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "${guest.name} is not a merchant and has no goods to sell.",
                ),
                backgroundColor: const Color(0xFF241F1A),
              ),
            );
          }
        },
      ),
    );

    // Option 2: Custom Quest / Venture Opportunity
    final quest = state.getVisitorQuestForNpc(guest);
    optionWidgets.add(
      _dialogOption(
        context: context,
        title: quest.title,
        description: '"${quest.teaserQuote}"',
        icon: Icons.assignment,
        onTap: () {
          _showVisitorQuestProposalDetailsDialog(context, state, quest, guest);
        },
      ),
    );

    // Option 3: Social Debate / Spirits
    optionWidgets.add(
      _dialogOption(
        context: context,
        title: hasSpirits
            ? "SHARE REFINED SPIRITS & DEBATE"
            : "DISCUSS PHILOSOPHY & SCIENCE",
        description: hasSpirits
            ? "Crack open Glarus spirits (-1 Spirits). Engage in a high-morale, deeply engaging debate (+20 Greeter Satisfaction)."
            : "Engage in standard intellectual discourse. Greeter satisfaction slightly increases (+10).",
        icon: Icons.local_bar,
        onTap: () {
          if (hasSpirits) {
            state.updateResource('spirits', -1);
            state.adjustNpcSatisfaction(greeter.id, 20);
          } else {
            state.adjustNpcSatisfaction(greeter.id, 10);
          }

          state.clearGuestConversation();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                hasSpirits
                    ? "Refined spirits shared! ${greeter.name} gained +20 Satisfaction."
                    : "Engaged in philosophical discourse. ${greeter.name} gained +10 Satisfaction.",
              ),
              backgroundColor: const Color(0xFF241F1A),
            ),
          );
        },
      ),
    );

    // Option 4: Polite Dismissal
    optionWidgets.add(
      _dialogOption(
        context: context,
        title: "POLITELY DISMISS GUEST",
        description:
            "Tell them that Glarus cannot host travelers today. They will immediately pack up and depart.",
        icon: Icons.exit_to_app,
        isRed: true,
        onTap: () {
          state.dismissGuest(guest.id);
          state.clearGuestConversation();
        },
      ),
    );

    return [
      Text(
        "${greeter.name.toUpperCase()} has met ${guest.name.toUpperCase()} (${guest.role.toUpperCase()}) at the grand entryway doors.",
        style: GoogleFonts.oldStandardTt(
          color: const Color(0xFFC4B89B),
          fontSize: 11.5,
          height: 1.4,
          fontStyle: FontStyle.italic,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        "The visitor looks up, a question hovering over their countenance. How shall Glarus respond to their presence?",
        style: GoogleFonts.oldStandardTt(
          color: const Color(0xFFE5D5B0).withOpacity(0.8),
          fontSize: 12.5,
          height: 1.4,
        ),
      ),
      const SizedBox(height: 16),
      ...optionWidgets.map(
        (opt) =>
            Padding(padding: const EdgeInsets.only(bottom: 8.0), child: opt),
      ),
    ];
  }

  Widget _dialogOption({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    VoidCallback? onTap,
    bool isRed = false,
  }) {
    final bool disabled = onTap == null;
    final Color themeColor = disabled
        ? Colors.white24
        : (isRed ? Colors.redAccent : const Color(0xFFC4B89B));

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          border: Border.all(color: themeColor.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: themeColor, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty) ...[
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.playfairDisplay(
                        color: themeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    description,
                    style: GoogleFonts.oldStandardTt(
                      color: disabled ? Colors.white30 : (title.isEmpty ? Colors.white70 : Colors.white38),
                      fontSize: title.isEmpty ? 11.5 : 9.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(Icons.chevron_right, color: themeColor, size: 16),
          ],
        ),
      ),
    );
  }

  void _showVisitorQuestProposalDetailsDialog(BuildContext context, GameState state, VisitorQuest quest, NPC guest) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1A15),
          shape: const RoundedRectangleBorder(),
          child: Container(
            width: 550,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC4B89B), width: 1.5),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        quest.title.toUpperCase(),
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFFE5D5B0), size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  Text(
                    "PROPOSED BY ${guest.name.toUpperCase()} (${guest.role.toUpperCase()}):",
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFC4B89B),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      '"${quest.detailedDialog}"',
                      style: GoogleFonts.oldStandardTt(
                        color: const Color(0xFFE5D5B0),
                        fontSize: 13,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "ESTATE OBJECTIVE & RECORD OBLIGATION:",
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFC4B89B),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "• Objective: ${quest.objective.title} — ${quest.objective.description}",
                    style: GoogleFonts.oldStandardTt(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  if (quest.agreement != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      "• Formal Agreement: ${quest.agreement!.description}",
                      style: GoogleFonts.oldStandardTt(
                        color: const Color(0xFFC4B89B).withValues(alpha: 0.8),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          side: const BorderSide(color: Colors.redAccent, width: 1),
                        ),
                        onPressed: () {
                          // Request 4B: Denying incurs negative social standing with visitor
                          state.adjustNpcSatisfaction(guest.id, -15);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(quest.denyMessage),
                              backgroundColor: const Color(0xFF241F1A),
                            ),
                          );
                          state.clearGuestConversation();
                          Navigator.pop(context); // close details
                        },
                        child: Text(
                          "DECLINE PROPOSAL",
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC4B89B),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: const RoundedRectangleBorder(),
                        ),
                        onPressed: () {
                          // Request 4C: Accepting adds objective and manor record agreement
                          state.acceptVisitorQuest(quest, guest.name);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(quest.acceptMessage),
                              backgroundColor: const Color(0xFF241F1A),
                            ),
                          );
                          state.clearGuestConversation();
                          Navigator.pop(context); // close details
                        },
                        child: Text(
                          "ACCEPT & SIGN AGREEMENT",
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFF1E1A15),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showVentureProposalDetails(BuildContext context, GameState state, dynamic guest) {
    final String guestType = guest.metadata['guestType'] as String? ?? '';
    List<BusinessType> options = [];
    
    if (guestType == 'cook_proposer') {
      options = [
        BusinessType.bistro,
        BusinessType.bakery,
        BusinessType.pizzeria,
        BusinessType.cafe,
        BusinessType.steakhouse,
        BusinessType.bar,
        BusinessType.nightClub,
      ];
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
            width: min(450.0, MediaQuery.of(context).size.width * 0.95),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC4B89B)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "COMMERCIAL PROPOSAL",
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "CHOOSE WHICH VENTURE TO ESTABLISH WITH ${guest.name.toUpperCase()}:",
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFC4B89B),
                      fontSize: 11,
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  ...options.map((type) {
                    final bool requiresDegree = type == BusinessType.lawPractice || type == BusinessType.medicalPractice || type == BusinessType.opiateLab;
                    final bool locked = requiresDegree && !state.hasRequiredDegreeForBusiness(type);
                    final String degreeName = state.getRequiredDegreeNameForBusiness(type).toUpperCase();

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      title: Text(
                        type.displayName.toUpperCase(),
                        style: GoogleFonts.playfairDisplay(
                          color: locked ? Colors.white24 : const Color(0xFFE5D5B0),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        requiresDegree 
                            ? (locked 
                                ? "LOCKED: ALPHONSE LACKS $degreeName. STUDY AT GRADUATE SCHOOL."
                                : "$degreeName ATTAINED (UNLOCKED)")
                            : "STANDARD ASSIGNMENTS SYSTEM INITIATED.",
                        style: GoogleFonts.oldStandardTt(
                          color: locked ? Colors.redAccent : Colors.white38,
                          fontSize: 9,
                        ),
                      ),
                      trailing: locked 
                          ? const Icon(Icons.lock_outline, color: Colors.white12, size: 16)
                          : const Icon(Icons.arrow_forward, color: Color(0xFFC4B89B), size: 16),
                      onTap: locked 
                          ? null 
                          : () {
                              state.welcomeNpc(guest.id);
                              state.proposeBusiness(type, guest.id, guest.name);
                              final bus = state.activeBusinesses.firstWhere((b) => b.proposerId == guest.id);
                              state.acceptBusinessProposal(bus.id);
                              
                              state.clearGuestConversation();
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildLanguageEncounterContent(
    BuildContext context,
    GameState state,
    NPC greeter,
    NPC guest,
    LanguageEncounter encounter,
  ) {
    final hasTranslator = state.anyResidentSpeaksLanguage(encounter.languageCode);
    final isTranslated = state.isLanguageEncounterTranslated;

    final List<Widget> optionWidgets = [];

    // Shuffled Options A-D
    optionWidgets.addAll(
      List.generate(encounter.options.length, (idx) {
        final option = encounter.options[idx];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _dialogOption(
            context: context,
            title: '',
            description: option.text,
            icon: Icons.chat_bubble_outline,
            onTap: () {
              state.resolveLanguageEncounter(option);
            },
          ),
        );
      }),
    );

    // Option E (Hostile Rebuff) anchored at bottom
    optionWidgets.add(
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: _dialogOption(
          context: context,
          title: '',
          description: encounter.hostileOption.text,
          icon: Icons.gavel,
          isRed: true,
          onTap: () {
            state.resolveLanguageEncounter(encounter.hostileOption);
          },
        ),
      ),
    );

    final rightContent = [
      Text(
        encounter.id >= 11 && encounter.id <= 16
            ? "A foreign customer has approached greeter ${greeter.name}. They do not speak our language fluently, addressing us in ${encounter.languageName}."
            : "A foreign traveler has approached greeter ${greeter.name}. They do not speak our language fluently, addressing us in ${encounter.languageName}.",
        style: GoogleFonts.oldStandardTt(
          color: const Color(0xFFC4B89B),
          fontSize: 11.5,
          height: 1.4,
          fontStyle: FontStyle.italic,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black26,
          border: Border.all(color: const Color(0xFFC4B89B).withOpacity(0.3)),
        ),
        child: Text(
          isTranslated
              ? 'Translated:\n"${encounter.promptEnglish}"'
              : '"${encounter.promptForeign}"',
          style: GoogleFonts.oldStandardTt(
            color: const Color(0xFFE5D5B0),
            fontSize: 13,
            height: 1.4,
            fontWeight: isTranslated ? FontWeight.normal : FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (!isTranslated) ...[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                hasTranslator
                    ? "A resident speaks ${encounter.languageName} and can translate."
                    : "No resident at the Manor speaks ${encounter.languageName}.",
                style: GoogleFonts.oldStandardTt(
                  color: hasTranslator ? Colors.green[300] : Colors.red[300],
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF382F24),
                foregroundColor: const Color(0xFFE5D5B0),
                shape: const RoundedRectangleBorder(),
                side: const BorderSide(color: Color(0xFFC4B89B)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              icon: const Icon(Icons.translate, size: 12),
              label: Text(
                "TRANSLATE (+10 mins)",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: hasTranslator
                  ? () {
                      state.translateActiveEncounter();
                    }
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
      ...optionWidgets,
    ];

    return rightContent;
  }

  List<Widget> _buildNeighborOptions(BuildContext context, GameState state, NPC greeter, NPC guest) {
    final encounter = NeighborEncounterCatalog.getEncounterForNpc(guest.name);
    if (encounter == null) {
      return [];
    }

    final bool isIntroComplete = guest.metadata['isIntroComplete'] == true;

    if (isIntroComplete) {
      return [
        Text(
          "${guest.name} has settled into their home at ${encounter.cottageId.replaceAll('cottage_', '').toUpperCase().replaceAll('_', ' ')}.\n\nYou can now send representatives to visit them or interact with them directly on the Survey Estate map.",
          style: GoogleFonts.oldStandardTt(
            color: const Color(0xFFC4B89B),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _dialogOption(
          context: context,
          title: "BID FAREWELL",
          description: "Conclude the conversation. They will return to their estate cottage.",
          icon: Icons.check_circle_outline,
          onTap: () {
            state.clearGuestConversation();
          },
        ),
      ];
    }

    final optionWidgets = [
      _dialogOption(
        context: context,
        title: "",
        description: encounter.choiceAText,
        icon: Icons.chat_bubble_outline,
        onTap: () {
          encounter.onChoiceA(state);
          final updatedMetadata = Map<String, dynamic>.from(guest.metadata);
          updatedMetadata['isGreeted'] = true;
          updatedMetadata['isIntroComplete'] = true;
          final updatedGuest = guest.copyWith(
            currentRoomId: encounter.cottageId, // Move them to their cottage so they leave the entryway!
            metadata: updatedMetadata,
          );
          state.updateNpc(updatedGuest);
          state.unlockCottage(encounter.cottageId);
          
          state.clearGuestConversation();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(encounter.outcomeAText),
              backgroundColor: const Color(0xFF241F1A),
            ),
          );
        },
      ),
      _dialogOption(
        context: context,
        title: "",
        description: encounter.choiceBText,
        icon: Icons.chat_bubble_outline,
        onTap: () {
          encounter.onChoiceB(state);
          final updatedMetadata = Map<String, dynamic>.from(guest.metadata);
          updatedMetadata['isGreeted'] = true;
          updatedMetadata['isIntroComplete'] = true;
          final updatedGuest = guest.copyWith(
            currentRoomId: encounter.cottageId, // Move them to their cottage so they leave the entryway!
            metadata: updatedMetadata,
          );
          state.updateNpc(updatedGuest);
          state.unlockCottage(encounter.cottageId);

          state.clearGuestConversation();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(encounter.outcomeBText),
              backgroundColor: const Color(0xFF241F1A),
            ),
          );
        },
      ),
    ];

    // Shuffle the response choices deterministically per guest ID to challenge the player to read
    if (guest.id.hashCode % 2 == 0) {
      final temp = optionWidgets[0];
      optionWidgets[0] = optionWidgets[1];
      optionWidgets[1] = temp;
    }

    return [
      Text(
        '"${encounter.introDialog}"',
        style: GoogleFonts.oldStandardTt(
          color: const Color(0xFFE5D5B0),
          fontSize: 14,
          height: 1.5,
          fontStyle: FontStyle.italic,
        ),
      ),
      const SizedBox(height: 32),
      optionWidgets[0],
      const SizedBox(height: 12),
      optionWidgets[1],
    ];
  }

  List<Widget> _buildPlotVisitorContent(
    BuildContext context,
    GameState state,
    NPC greeter,
    NPC guest,
  ) {
    final String plotEventKey = guest.metadata['plotEventKey'] as String? ?? '';
    String storyText = "The representative stands before you, awaiting Glarus's response.";
    final List<Widget> optionWidgets = [];

    // Helper to dismiss the visitor
    void dismissVisitor() {
      state.removeNpc(guest.id);
      state.clearGuestConversation();
    }

    final double standingGlarus = state.getFactionStanding('Glarus');
    final double standingGnomes = state.getFactionStanding('Gnomes of Zurich');
    final double standingIlluminati = state.getFactionStanding('Bavarian Illuminati');
    final double standingRosicrucian = state.getFactionStanding('Rosicrucians');

    final num funds = state.resources['funds'] ?? 0;
    final num wood = state.resources['wood'] ?? 0;
    final num iron = state.resources['iron'] ?? 0;
    final num food = state.resources['meals'] ?? 0;

    switch (plotEventKey) {
      // =======================================================================
      // GLARUS PEASANTS
      // =======================================================================
      case 'Glarus_positive_step1':
        storyText = "Jacob Landolt greets you with high esteem: 'Glarus recognizes your benevolence. We propose a formal Canton Defense Alliance to protect the valley from encroaching forces. However, we need 300 Wood to construct defensive barricades in the mountain passes.'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Pledge alliance and supply 300 Wood",
            description: "Cost: 300 Wood. Gain Canton Alliance status and proceed with storyline.",
            icon: Icons.check_circle,
            onTap: wood >= 300 ? () {
              state.updateResource('wood', -300);
              state.adjustFactionStanding('Glarus', 0.5);
              state.progressPlotStep('Glarus_positive', 2, 2880);
              state.addAnnouncement("Pledged Canton Alliance and supplied 300 Wood.");
              dismissVisitor();
            } : null,
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) Reject the alliance and keep the timber",
            description: "No cost. The Glarus plotline is resolved.",
            icon: Icons.cancel,
            onTap: () {
              state.resolvePlotline('Glarus_positive');
              state.addAnnouncement("Declined Glarus Canton defense alliance.");
              dismissVisitor();
            },
          ),
        );
        break;

      case 'Glarus_positive_step2':
        storyText = "Jacob Landolt returns with urgent news: 'Bandits have blockaded the trade roads, strangling our valley supplies. Glarus begs you to fund our volunteer guards with 500 CHF and 100 Iron to clear the paths.'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Equip Glarus patrols (500 CHF, 100 Iron)",
            description: "Cost: 500 CHF, 100 Iron. Gain Glarus standing and proceed to final step.",
            icon: Icons.security,
            onTap: (funds >= 500 && iron >= 100) ? () {
              state.updateResource('funds', -500);
              state.updateResource('iron', -100);
              state.adjustFactionStanding('Glarus', 0.6);
              state.progressPlotStep('Glarus_positive', 3, 4320);
              state.addAnnouncement("Equipped Glarus patrols to secure trade corridors.");
              dismissVisitor();
            } : null,
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) Decline. Let them handle their own security",
            description: "No cost. Lose Glarus standing and resolve storyline.",
            icon: Icons.cancel,
            onTap: () {
              state.adjustFactionStanding('Glarus', -0.4);
              state.resolvePlotline('Glarus_positive');
              state.addAnnouncement("Refused to fund Glarus patrols.");
              dismissVisitor();
            },
          ),
        );
        break;

      case 'Glarus_positive_step3':
        storyText = "Jacob Landolt arrives in formal robes: 'You are the undisputed savior of Glarus! We formally request to merge our sovereignty under your direct protection. We will construct the Canton Embassy in your Manor, and I will pledge myself to serve you directly.'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Sign Sovereign Protector Decree & Build Embassy",
            description: "Reward: Canton Embassy built (restores an unused room immediately) and Jacob Landolt joins as a legendary resident servant (+100 work speed)!",
            icon: Icons.gavel,
            onTap: () {
              final unusedIdx = state.rooms.indexWhere((r) => r.type == RoomType.unused || !r.isRestored);
              if (unusedIdx != -1) {
                final room = state.rooms[unusedIdx];
                state.updateRoom(room.copyWith(
                  name: "Canton Embassy",
                  type: RoomType.lawFirm,
                  isRestored: true,
                  restorationProgress: 1.0,
                  metadata: {...room.metadata, 'canton_embassy_active': true},
                ));
              }
              final landolt = NPCGenerator.generateRefugee(currentDate: state.currentDate).copyWith(
                id: 'resident_jacob_landolt',
                name: 'Jacob Landolt',
                role: 'Canton High Councilor',
                isResident: true,
                currentRoomId: 'entryway',
                status: NPCStatus.idle,
              );
              state.addResidentNpc(landolt);
              state.adjustFactionStanding('Glarus', 1.0);
              state.resolvePlotline('Glarus_positive');
              state.addAnnouncement("Sovereign Protector Decree signed! Constructed Canton Embassy and welcomed Jacob Landolt as a resident servant.");
              dismissVisitor();
            },
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) Decline protectorate but sign Mutual Trade Treaty",
            description: "Reward: Receive 1500 CHF immediate trade dividends.",
            icon: Icons.handshake,
            onTap: () {
              state.updateResource('funds', 1500);
              state.adjustFactionStanding('Glarus', 0.5);
              state.resolvePlotline('Glarus_positive');
              state.addAnnouncement("Signed Glarus trade treaty. Received 1500 CHF.");
              dismissVisitor();
            },
          ),
        );
        break;

      case 'Glarus_negative_step1':
        storyText = "An Angry Peasant Leader demands an audience: 'Your heartless greed is starving Glarus! Yield 300 Food immediately as a relief tribute to our families, or we will blockade your supply carriages.'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Pay the 300 Food relief tribute",
            description: "Cost: 300 Food. Appeases the peasants, resolving the hostility.",
            icon: Icons.restaurant,
            onTap: food >= 300 ? () {
              state.updateResource('shepherds_pie', -300);
              state.adjustFactionStanding('Glarus', 0.4);
              state.resolvePlotline('Glarus_negative');
              state.addAnnouncement("Appeased Glarus mob with 300 Food.");
              dismissVisitor();
            } : null,
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) Order the guards to drive the mob away!",
            description: "No cost. Escalates hostility and schedules retaliation.",
            icon: Icons.local_fire_department,
            onTap: () {
              state.adjustFactionStanding('Glarus', -0.6);
              state.progressPlotStep('Glarus_negative', 2, 2880);
              state.addAnnouncement("Drove Glarus peasant mob away with force.");
              dismissVisitor();
            },
          ),
        );
        break;

      case 'Glarus_negative_step2':
        storyText = "Jacob Landolt arrives in grim armor: 'Your violence has triggered a total labor strike! The woodcutters refuse to supply you, and saboteurs have set fire to your timber yards. Pay 800 CHF in restitution, or suffer the strike.'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Pay the 800 CHF labor restitution",
            description: "Cost: 800 CHF. Lifts the strike and resolves the hostility.",
            icon: Icons.payment,
            onTap: funds >= 800 ? () {
              state.updateResource('funds', -800);
              state.adjustFactionStanding('Glarus', 0.4);
              state.resolvePlotline('Glarus_negative');
              state.addAnnouncement("Paid Glarus labor restitution.");
              dismissVisitor();
            } : null,
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) We do not yield to extortion. Get out!",
            description: "CONSEQUENCE: Suffer permanent -30% work speed Manor-wide due to labor strike!",
            icon: Icons.cancel,
            onTap: () {
              state.adjustFactionStanding('Glarus', -0.5);
              state.progressPlotStep('Glarus_negative', 3, 4320);
              state.addAnnouncement("Refused Glarus restitution. Peasant labor strike goes active.");
              dismissVisitor();
            },
          ),
        );
        break;

      case 'Glarus_negative_step3':
        storyText = "Jacob Landolt stands with armed guards: 'This is our final stand. We are reclaiming our ancestral lands. Surrender your vegetable gardens and fields, or face a full-scale armed rebellion!'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Surrender the outer fields to save the Manor",
            description: "CONSEQUENCE: Permanent -50% passive food production penalty from all fields!",
            icon: Icons.terrain,
            onTap: () {
              state.resolvePlotline('Glarus_negative');
              state.addAnnouncement("Surrendered outer fields to Glarus rebels. Food production halved.");
              dismissVisitor();
            },
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) Defy them! Glarus will bleed at our gates!",
            description: "CONSEQUENCE: Immediate armed clash at the gates! A random servant takes 80 HP damage.",
            icon: Icons.gavel,
            onTap: () {
              if (state.npcs.isNotEmpty) {
                final target = state.npcs[Random().nextInt(state.npcs.length)];
                final injured = target.copyWith(
                  bodyParts: target.bodyParts.map((bp) => bp.copyWith(health: max(0.0, bp.health - 80))).toList(),
                );
                state.updateNpc(injured);
                state.addAnnouncement("Defied Glarus rebellion. Armed clash at the gates! ${injured.name} was severely wounded.");
              }
              state.adjustFactionStanding('Glarus', -1.0);
              state.resolvePlotline('Glarus_negative');
              dismissVisitor();
            },
          ),
        );
        break;

      // =======================================================================
      // GNOMES OF ZURICH
      // =======================================================================
      case 'Gnomes of Zurich_positive_step1':
        storyText = "Herr Hans Vontobel bows politely: 'Your excellent credit standing has qualified you for a lucrative silver speculative scheme. Invest 600 CHF with us, and we shall return a massive dividend.'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Invest 600 CHF in the silver cargo",
            description: "Cost: 600 CHF. Gain Gnomes standing and proceed to next step.",
            icon: Icons.monetization_on,
            onTap: funds >= 600 ? () {
              state.updateResource('funds', -600);
              state.adjustFactionStanding('Gnomes of Zurich', 0.5);
              state.progressPlotStep('Gnomes of Zurich_positive', 2, 2880);
              state.addAnnouncement("Invested 600 CHF in Zurich silver cargo.");
              dismissVisitor();
            } : null,
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) Decline. We do not gamble with our funds",
            description: "No cost. Zurich plotline is resolved.",
            icon: Icons.cancel,
            onTap: () {
              state.resolvePlotline('Gnomes of Zurich_positive');
              state.addAnnouncement("Declined Zurich silver cargo proposal.");
              dismissVisitor();
            },
          ),
        );
        break;

      case 'Gnomes of Zurich_positive_step2':
        storyText = "Herr Hans Vontobel returns: 'Our silver carriage has been detained at the border. A 400 CHF bribe is required to clear passage, or you must use your high prestige to override them.'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Pay the 400 CHF customs bribe",
            description: "Cost: 400 CHF. Carriage cleared. Proceed to final step.",
            icon: Icons.payment,
            onTap: funds >= 400 ? () {
              state.updateResource('funds', -400);
              state.adjustFactionStanding('Gnomes of Zurich', 0.6);
              state.progressPlotStep('Gnomes of Zurich_positive', 3, 4320);
              state.addAnnouncement("Bribed customs to clear silver carriage.");
              dismissVisitor();
            } : null,
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) Override customs using prestige (Requires Standing >= 4.5)",
            description: "Requires Gnomes Standing >= 4.5. Carriage cleared with zero cost!",
            icon: Icons.workspace_premium,
            onTap: standingGnomes >= 4.5 ? () {
              state.adjustFactionStanding('Gnomes of Zurich', 0.8);
              state.progressPlotStep('Gnomes of Zurich_positive', 3, 4320);
              state.addAnnouncement("Used high credit standing to bypass customs.");
              dismissVisitor();
            } : null,
          ),
        );
        break;

      case 'Gnomes of Zurich_positive_step3':
        storyText = "Regina von Stauffacher arrives in an ornate carriage: 'The silver venture was a colossal triumph! We offer you a permanent seat on the Grand Syndicate. We will construct the Treasury Vault in your Manor, granting you +50% cash income!'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Accept the Syndicate Seat & Build Treasury Vault",
            description: "Reward: Treasury Vault built (converts an unused room) and permanent +50% cash income from all sources!",
            icon: Icons.account_balance,
            onTap: () {
              final unusedIdx = state.rooms.indexWhere((r) => r.type == RoomType.unused || !r.isRestored);
              if (unusedIdx != -1) {
                final room = state.rooms[unusedIdx];
                state.updateRoom(room.copyWith(
                  name: "Treasury Vault",
                  type: RoomType.granary,
                  isRestored: true,
                  restorationProgress: 1.0,
                  metadata: {...room.metadata, 'treasury_vault_active': true},
                ));
              }
              state.adjustFactionStanding('Gnomes of Zurich', 1.0);
              state.resolvePlotline('Gnomes of Zurich_positive');
              state.addAnnouncement("Joined the Grand Syndicate! Constructed Treasury Vault and unlocked permanent +50% cash multiplier.");
              dismissVisitor();
            },
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) Claim a massive bank dividend of 2000 CHF",
            description: "Reward: Gain 2000 CHF cash immediately.",
            icon: Icons.monetization_on,
            onTap: () {
              state.updateResource('funds', 2000);
              state.adjustFactionStanding('Gnomes of Zurich', 0.5);
              state.resolvePlotline('Gnomes of Zurich_positive');
              state.addAnnouncement("Claimed 2000 CHF Zurich bank dividend payout.");
              dismissVisitor();
            },
          ),
        );
        break;

      case 'Gnomes of Zurich_negative_step1':
        storyText = "A stern Zurich Debt Collector stands at the door: 'Your hostile relation has prompted us to freeze your credit lines. Pay 500 CHF interest penalties immediately, or we will seize your caravans.'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Pay the 500 CHF interest penalty",
            description: "Cost: 500 CHF. Restores credit lines and resolves hostility.",
            icon: Icons.check_circle,
            onTap: funds >= 500 ? () {
              state.updateResource('funds', -500);
              state.adjustFactionStanding('Gnomes of Zurich', 0.4);
              state.resolvePlotline('Gnomes of Zurich_negative');
              state.addAnnouncement("Paid Zurich outstanding interest penalty.");
              dismissVisitor();
            } : null,
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) Drive them off! We do not pay extortionists!",
            description: "No cost. Escalates hostility and triggers caravanserai embargo.",
            icon: Icons.gavel,
            onTap: () {
              state.adjustFactionStanding('Gnomes of Zurich', -0.6);
              state.progressPlotStep('Gnomes of Zurich_negative', 2, 2880);
              state.addAnnouncement("Threatened Zurich bank debt collectors.");
              dismissVisitor();
            },
          ),
        );
        break;

      case 'Gnomes of Zurich_negative_step2':
        storyText = "Herr Hans Vontobel arrives with armed mercenaries: 'Your defiance has forced our hand. We have seized all trade caravans. Pay 800 CHF release fee, or suffer a permanent embargo.'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Pay the 800 CHF caravan release fee",
            description: "Cost: 800 CHF. Lifts the embargo and resolves the hostility.",
            icon: Icons.payment,
            onTap: funds >= 800 ? () {
              state.updateResource('funds', -800);
              state.adjustFactionStanding('Gnomes of Zurich', 0.4);
              state.resolvePlotline('Gnomes of Zurich_negative');
              state.addAnnouncement("Paid Gnomes Caravan release penalty.");
              dismissVisitor();
            } : null,
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) We will clear our own trade paths by force!",
            description: "CONSEQUENCE: Suffer permanent -30% cash income penalty from all sources due to embargo!",
            icon: Icons.cancel,
            onTap: () {
              state.adjustFactionStanding('Gnomes of Zurich', -0.5);
              state.progressPlotStep('Gnomes of Zurich_negative', 3, 4320);
              state.addAnnouncement("Refused Gnomes release fee. Embargo active.");
              dismissVisitor();
            },
          ),
        );
        break;

      case 'Gnomes of Zurich_negative_step3':
        storyText = "Regina von Stauffacher stands with a foreclosure decree: 'Your assets are officially foreclosed. We are seizing your grandest Manor room immediately as repayment.'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Submit to foreclosure and yield the room",
            description: "CONSEQUENCE: A random restored room is permanently ruined and locked!",
            icon: Icons.close,
            onTap: () {
              final restoredRooms = state.rooms.where((r) => r.isRestored && r.type != RoomType.entryway).toList();
              if (restoredRooms.isNotEmpty) {
                final target = restoredRooms[Random().nextInt(restoredRooms.length)];
                state.updateRoom(target.copyWith(
                  isRestored: false,
                  restorationProgress: 0.0,
                  metadata: {...target.metadata, 'permanently_ruined_locked': true},
                ));
                state.addAnnouncement("CONSEQUENCE: Submitted to Zurich foreclosure. ${target.name} was permanently ruined.");
              }
              state.resolvePlotline('Gnomes of Zurich_negative');
              dismissVisitor();
            },
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) Fight the foreclosure collectors!",
            description: "CONSEQUENCE: Immediate clash! A random servant takes 90 HP damage.",
            icon: Icons.local_fire_department,
            onTap: () {
              if (state.npcs.isNotEmpty) {
                final target = state.npcs[Random().nextInt(state.npcs.length)];
                final injured = target.copyWith(
                  bodyParts: target.bodyParts.map((bp) => bp.copyWith(health: max(0.0, bp.health - 90))).toList(),
                );
                state.updateNpc(injured);
                state.addAnnouncement("Defied foreclosure. Armed clash with collectors! ${injured.name} was severely wounded.");
              }
              state.adjustFactionStanding('Gnomes of Zurich', -1.0);
              state.resolvePlotline('Gnomes of Zurich_negative');
              dismissVisitor();
            },
          ),
        );
        break;

      // =======================================================================
      // BAVARIAN ILLUMINATI
      // =======================================================================
      case 'Bavarian Illuminati_positive_step1':
        storyText = "Professor Fritz Weishaupt whispers: 'The Illuminati seek to establish a local Lodge of Light in this valley. We request a donation of 200 Wood and 150 Iron to build their research temple.'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Donate resources to the Lodge (200 Wood, 150 Iron)",
            description: "Cost: 200 Wood, 150 Iron. Gain Illuminati standing and proceed.",
            icon: Icons.check_circle,
            onTap: (wood >= 200 && iron >= 150) ? () {
              state.updateResource('wood', -200);
              state.updateResource('iron', -150);
              state.adjustFactionStanding('Bavarian Illuminati', 0.5);
              state.progressPlotStep('Bavarian Illuminati_positive', 2, 2880);
              state.addAnnouncement("Supplied construction materials to the Lodge of Light.");
              dismissVisitor();
            } : null,
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) Occult lodges have no place in Glarus",
            description: "No cost. Illuminati plotline is resolved.",
            icon: Icons.cancel,
            onTap: () {
              state.resolvePlotline('Bavarian Illuminati_positive');
              state.addAnnouncement("Declined Illuminati Lodge proposal.");
              dismissVisitor();
            },
          ),
        );
        break;

      case 'Bavarian Illuminati_positive_step2':
        storyText = "Fritz Weishaupt returns in secrecy: 'A brilliant renegade cybernetic scientist is fleeing Church inquisitors. We beg you to shelter him in your Manor and fund his secret laboratory for 450 CHF.'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Shelter the renegade inventor and pay 450 CHF",
            description: "Cost: 450 CHF. Gain Illuminati standing. Proceed to final step.",
            icon: Icons.psychology,
            onTap: funds >= 450 ? () {
              state.updateResource('funds', -450);
              state.adjustFactionStanding('Bavarian Illuminati', 0.6);
              state.progressPlotStep('Bavarian Illuminati_positive', 3, 4320);
              state.addAnnouncement("Granted sanctuary to cybernetic scientist and funded research.");
              dismissVisitor();
            } : null,
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) Turn him away. Glarus does not harbor heretics",
            description: "No cost. Gain Templar standing, lose Illuminati standing, resolve plotline.",
            icon: Icons.cancel,
            onTap: () {
              state.adjustFactionStanding('Bavarian Illuminati', -0.4);
              state.adjustFactionStanding('Knights Templar', 0.3);
              state.resolvePlotline('Bavarian Illuminati_positive');
              state.addAnnouncement("Refused scientist asylum to appease the Templars.");
              dismissVisitor();
            },
          ),
        );
        break;

      case 'Bavarian Illuminati_positive_step3':
        storyText = "Grand Master Weishaupt congratulates you: 'The research is complete! The Illuminati welcome you to the Inner Circle. We will construct the Great Observatory in your Manor and gift you our tireless cybernetic automaton servant!'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Enter the Inner Circle & Build Observatory",
            description: "Reward: Great Observatory built (converts an unused room) and the legendary 'Illuminati Automaton' servant joins your staff (+150 work speed, never tires)!",
            icon: Icons.visibility,
            onTap: () {
              final unusedIdx = state.rooms.indexWhere((r) => r.type == RoomType.unused || !r.isRestored);
              if (unusedIdx != -1) {
                final room = state.rooms[unusedIdx];
                state.updateRoom(room.copyWith(
                  name: "Great Observatory",
                  type: RoomType.laboratory,
                  isRestored: true,
                  restorationProgress: 1.0,
                  metadata: {...room.metadata, 'great_observatory_active': true},
                ));
              }
              final automaton = NPCGenerator.generateRefugee(currentDate: state.currentDate).copyWith(
                id: 'resident_illuminati_automaton',
                name: 'Illuminati Automaton',
                role: 'Cybernetic Sentinel',
                isResident: true,
                currentRoomId: 'entryway',
                status: NPCStatus.idle,
              );
              state.addResidentNpc(automaton);
              state.adjustFactionStanding('Bavarian Illuminati', 1.0);
              state.resolvePlotline('Bavarian Illuminati_positive');
              state.addAnnouncement("Inducted into the Inner Circle! Built Great Observatory and recruited the Illuminati Automaton.");
              dismissVisitor();
            },
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) Accept a technological grant of 1500 CHF",
            description: "Reward: Gain 1500 CHF cash immediately.",
            icon: Icons.monetization_on,
            onTap: () {
              state.updateResource('funds', 1500);
              state.adjustFactionStanding('Bavarian Illuminati', 0.5);
              state.resolvePlotline('Bavarian Illuminati_positive');
              state.addAnnouncement("Claimed 1500 CHF Illuminati technological grant.");
              dismissVisitor();
            },
          ),
        );
        break;

      case 'Bavarian Illuminati_negative_step1':
        storyText = "A Suspicious Servant is caught copying alchemical papers: 'The Illuminati watch you from the shadows. Release me immediately, or face a shadow war.'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Release the spy to avoid a shadow war",
            description: "No cost. Resolves hostility.",
            icon: Icons.check_circle,
            onTap: () {
              state.adjustFactionStanding('Bavarian Illuminati', 0.4);
              state.resolvePlotline('Bavarian Illuminati_negative');
              state.addAnnouncement("Released caught Illuminati spy.");
              dismissVisitor();
            },
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) Imprison and interrogate him!",
            description: "No cost. Escalates hostility. Blueprint leakage scheduled.",
            icon: Icons.lock,
            onTap: () {
              state.adjustFactionStanding('Bavarian Illuminati', -0.6);
              state.progressPlotStep('Bavarian Illuminati_negative', 2, 2880);
              state.addAnnouncement("Imprisoned and interrogated Illuminati spy.");
              dismissVisitor();
            },
          ),
        );
        break;

      case 'Bavarian Illuminati_negative_step2':
        storyText = "Fritz Weishaupt sneers: 'You have provoked us. We have introduced a chemical toxin into your ventilation. Pay 600 CHF for the alchemical neutralizer, or watch your staff suffer.'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Buy the chemical neutralizer for 600 CHF",
            description: "Cost: 600 CHF. Purges the toxin and resolves hostility.",
            icon: Icons.payment,
            onTap: funds >= 600 ? () {
              state.updateResource('funds', -600);
              state.adjustFactionStanding('Bavarian Illuminati', 0.4);
              state.resolvePlotline('Bavarian Illuminati_negative');
              state.addAnnouncement("Purged Manor toxin using Zurich neutralizers.");
              dismissVisitor();
            } : null,
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) Refuse! We will seal the ventilation!",
            description: "CONSEQUENCE: Permanent -30% work speed penalty to all servants due to contamination!",
            icon: Icons.cancel,
            onTap: () {
              state.adjustFactionStanding('Bavarian Illuminati', -0.5);
              state.progressPlotStep('Bavarian Illuminati_negative', 3, 4320);
              state.addAnnouncement("Refused neutralizer. Contamination active.");
              dismissVisitor();
            },
          ),
        );
        break;

      case 'Bavarian Illuminati_negative_step3':
        storyText = "Grand Master Weishaupt stands with shadow assassins: 'You are too dangerous. We are executing a neural memory wipe to erase your Manor's secrets. Yield, or suffer the wipe!'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Submit to the memory wipe",
            description: "CONSEQUENCE: Your most skilled resident servant's proficiencies are wiped!",
            icon: Icons.close,
            onTap: () {
              if (state.npcs.isNotEmpty) {
                final servants = state.npcs.where((n) => n.isResident && !n.isPlayer).toList();
                if (servants.isNotEmpty) {
                  servants.sort((a, b) {
                    final sumA = a.stats.values.fold<int>(0, (prev, val) => prev + val);
                    final sumB = b.stats.values.fold<int>(0, (prev, val) => prev + val);
                    return sumB.compareTo(sumA);
                  });
                  final target = servants[0];
                  final resetServant = target.copyWith(proficiencies: const {});
                  state.updateNpc(resetServant);
                  state.addAnnouncement("CONSEQUENCE: Neural memory wipe reset all of ${target.name}'s proficiencies to zero.");
                }
              }
              state.resolvePlotline('Bavarian Illuminati_negative');
              dismissVisitor();
            },
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) Fight the shadow assassins!",
            description: "CONSEQUENCE: Immediate clash! A random servant takes 95 HP damage.",
            icon: Icons.local_fire_department,
            onTap: () {
              if (state.npcs.isNotEmpty) {
                final target = state.npcs[Random().nextInt(state.npcs.length)];
                final injured = target.copyWith(
                  bodyParts: target.bodyParts.map((bp) => bp.copyWith(health: max(0.0, bp.health - 95))).toList(),
                );
                state.updateNpc(injured);
                state.addAnnouncement("Defied memory wipe. Armed clash with shadow assassins! ${injured.name} was severely wounded.");
              }
              state.adjustFactionStanding('Bavarian Illuminati', -1.0);
              state.resolvePlotline('Bavarian Illuminati_negative');
              dismissVisitor();
            },
          ),
        );
        break;

      // =======================================================================
      // ROSICRUCIANS
      // =======================================================================
      case 'Rosicrucians_positive_step1':
        storyText = "Johannes the Hermit greets you with high regard: 'Your Manor lies on a cosmic leyline node. We wish to construct a sacred alchemical circle to channel the stars. We request 300 Wood and 150 Food to build it.'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Build the alchemical circle (300 Wood, 150 Food)",
            description: "Cost: 300 Wood, 150 Food. Gain Rosicrucian standing and proceed.",
            icon: Icons.explore,
            onTap: (wood >= 300 && food >= 150) ? () {
              state.updateResource('wood', -300);
              state.updateResource('shepherds_pie', -150);
              state.adjustFactionStanding('Rosicrucians', 0.5);
              state.progressPlotStep('Rosicrucians_positive', 2, 2880);
              state.addAnnouncement("Constructed alchemical circle to tap leyline node.");
              dismissVisitor();
            } : null,
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) We do not engage in pagan circles. Decline",
            description: "No cost. Rosicrucian plotline is resolved.",
            icon: Icons.cancel,
            onTap: () {
              state.resolvePlotline('Rosicrucians_positive');
              state.addAnnouncement("Declined Rosicrucian leyline circle proposal.");
              dismissVisitor();
            },
          ),
        );
        break;

      case 'Rosicrucians_positive_step2':
        storyText = "Johannes returns: 'The alchemical circle is active, but it requires a human anchor to stabilize the leyline. The process will strain their mind, but permanently bind them to the cosmos.'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Volunteer your most skilled servant to anchor the node",
            description: "Reward: Selected servant permanently gains +50 work speed (leyline connection)!",
            icon: Icons.psychology,
            onTap: () {
              if (state.npcs.isNotEmpty) {
                final servants = state.npcs.where((n) => n.isResident && !n.isPlayer).toList();
                if (servants.isNotEmpty) {
                  servants.sort((a, b) {
                    final sumA = a.stats.values.fold<int>(0, (prev, val) => prev + val);
                    final sumB = b.stats.values.fold<int>(0, (prev, val) => prev + val);
                    return sumB.compareTo(sumA);
                  });
                  final target = servants[0];
                  final updatedMetadata = Map<String, dynamic>.from(target.metadata);
                  updatedMetadata['leyline_anchor_active'] = 1;
                  final boosted = target.copyWith(
                    metadata: updatedMetadata,
                  );
                  state.updateNpc(boosted);
                  state.addAnnouncement("${target.name} anchored the alchemical leyline. Spiritual node secured.");
                }
              }
              state.adjustFactionStanding('Rosicrucians', 0.6);
              state.progressPlotStep('Rosicrucians_positive', 3, 4320);
              dismissVisitor();
            },
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) We will not risk our servants' sanity. Decline",
            description: "No cost. Lose Rosicrucian standing and resolve plotline.",
            icon: Icons.cancel,
            onTap: () {
              state.adjustFactionStanding('Rosicrucians', -0.4);
              state.resolvePlotline('Rosicrucians_positive');
              state.addAnnouncement("Cancelled alchemical leyline project.");
              dismissVisitor();
            },
          ),
        );
        break;

      case 'Rosicrucians_positive_step3':
        storyText = "Johannes the Hermit holds out a glowing crimson gemstone: 'The leylines are aligned! We offer the Alchemical Marriage. Drink our Elixir, and receive the Philosopher's Stone to bless your Manor!'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Drink the Elixir & Receive the Philosopher's Stone",
            description: "Reward: Exquisite 'Philosopher's Stone' relic: grants permanent +5 HP/sec alchemical regeneration to all residents, and generates +50 CHF of gold passive daily income!",
            icon: Icons.diamond,
            onTap: () {
              state.adjustFactionStanding('Rosicrucians', 1.0);
              state.resolvePlotline('Rosicrucians_positive');
              
              for (int i = 0; i < state.npcs.length; i++) {
                final n = state.npcs[i];
                if (n.isResident) {
                  final updatedMeta = Map<String, dynamic>.from(n.metadata);
                  updatedMeta['rosicrucian_blessing_active'] = 1;
                  state.updateNpc(n.copyWith(metadata: updatedMeta));
                }
              }

              state.addAnnouncement("Sealed Alchemical Marriage! Received the Philosopher's Stone relic.");
              dismissVisitor();
            },
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) Refuse the marriage but accept alchemical gold",
            description: "Reward: Receive 1500 CHF cash immediately.",
            icon: Icons.monetization_on,
            onTap: () {
              state.updateResource('funds', 1500);
              state.adjustFactionStanding('Rosicrucians', 0.5);
              state.resolvePlotline('Rosicrucians_positive');
              state.addAnnouncement("Refused alchemical marriage. Claimed 1500 CHF alchemical gold.");
              dismissVisitor();
            },
          ),
        );
        break;

      case 'Rosicrucians_negative_step1':
        storyText = "A Veiled Mystic stands at the door, chanting a dark hex: 'You have offended the spirits! A plague of rot is consuming your food. Pay 300 CHF as an offering, or watch your pantry turn to ash.'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Pay the 300 CHF offering to lift the hex",
            description: "Cost: 300 CHF. Lifts the curse and resolves hostility.",
            icon: Icons.check_circle,
            onTap: funds >= 300 ? () {
              state.updateResource('funds', -300);
              state.adjustFactionStanding('Rosicrucians', 0.4);
              state.resolvePlotline('Rosicrucians_negative');
              state.addAnnouncement("Appeased the Rosicrucian mystics. Hex lifted.");
              dismissVisitor();
            } : null,
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) Ignore their silly superstitions! Get out!",
            description: "CONSEQUENCE: Instantly lose 250 Food as it rots into ash!",
            icon: Icons.cancel,
            onTap: () {
              state.updateResource('shepherds_pie', -250);
              state.adjustFactionStanding('Rosicrucians', -0.6);
              state.progressPlotStep('Rosicrucians_negative', 2, 2880);
              state.addAnnouncement("CONSEQUENCE: Refused to lift hex. Food rot consumed 250 food reserves.");
              dismissVisitor();
            },
          ),
        );
        break;

      case 'Rosicrucians_negative_step2':
        storyText = "Johannes the Hermit looks upon you with cold eyes: 'A plague of alchemical vermin has infested your water and soil, ruining your crops. Pay 500 CHF to hire professional pest exorcists.'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Pay 500 CHF to hire exorcists",
            description: "Cost: 500 CHF. Clears the infestation. Resolves hostility.",
            icon: Icons.payment,
            onTap: funds >= 500 ? () {
              state.updateResource('funds', -500);
              state.adjustFactionStanding('Rosicrucians', 0.4);
              state.resolvePlotline('Rosicrucians_negative');
              state.addAnnouncement("Hired alchemical exterminators to clear vermin.");
              dismissVisitor();
            } : null,
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) We will purge the pests ourselves!",
            description: "CONSEQUENCE: Permanent -30% passive food production penalty from all fields due to blight!",
            icon: Icons.cancel,
            onTap: () {
              state.adjustFactionStanding('Rosicrucians', -0.5);
              state.progressPlotStep('Rosicrucians_negative', 3, 4320);
              state.addAnnouncement("Refused exterminators. Vermin plague active.");
              dismissVisitor();
            },
          ),
        );
        break;

      case 'Rosicrucians_negative_step3':
        storyText = "The Rosicrucian Grand Master rises from the mist: 'The final wither has begun. Yield your alchemical research notes, or suffer the Curse of the Withered Soul!'";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "A) Submit to the curse and yield alchemical notes",
            description: "CONSEQUENCE: Most skilled servant maximum health is permanently reduced by -100 HP, and all fields are permanently locked as withered!",
            icon: Icons.close,
            onTap: () {
              if (state.npcs.isNotEmpty) {
                final servants = state.npcs.where((n) => n.isResident && !n.isPlayer).toList();
                if (servants.isNotEmpty) {
                  servants.sort((a, b) {
                    final sumA = a.stats.values.fold<int>(0, (prev, val) => prev + val);
                    final sumB = b.stats.values.fold<int>(0, (prev, val) => prev + val);
                    return sumB.compareTo(sumA);
                  });
                  final target = servants[0];
                  final withered = target.copyWith(
                    bodyParts: target.bodyParts.map((bp) => bp.copyWith(
                      maxHealth: max(10, bp.maxHealth - 100),
                      health: max(1.0, bp.health - 100),
                    )).toList(),
                  );
                  state.updateNpc(withered);
                  state.addAnnouncement("CONSEQUENCE: Submitted to Rosicrucian curse. ${target.name} max HP permanently reduced.");
                }
              }
              state.resolvePlotline('Rosicrucians_negative');
              dismissVisitor();
            },
          ),
        );
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "B) Burn their occult sanctuary!",
            description: "CONSEQUENCE: Immediate magical backlash! A random servant takes 99 HP damage.",
            icon: Icons.local_fire_department,
            onTap: () {
              if (state.npcs.isNotEmpty) {
                final target = state.npcs[Random().nextInt(state.npcs.length)];
                final injured = target.copyWith(
                  bodyParts: target.bodyParts.map((bp) => bp.copyWith(health: max(0.0, bp.health - 99))).toList(),
                );
                state.updateNpc(injured);
                state.addAnnouncement("Defied occult curse. Magical clash! ${injured.name} was severely injured.");
              }
              state.adjustFactionStanding('Rosicrucians', -1.0);
              state.resolvePlotline('Rosicrucians_negative');
              dismissVisitor();
            },
          ),
        );
        break;

      case 'mary_shelley_visit':
        final int step = guest.metadata['plotDialogueStep'] as int? ?? 0;

        // Specific condolences based on deathCause
        String deathCondolence = "";
        switch (state.deathCause) {
          case DeathCause.trainCrash:
            deathCondolence =
                "To have them torn away by that mechanical iron beast... progress has a cruel cost.";
            break;
          case DeathCause.disease:
            deathCondolence =
                "To watch them wither under the slow grip of pestilence... it is a harsh reminder of our fragility.";
            break;
          case DeathCause.murderSuicide:
            deathCondolence =
                "To perish by such sudden, tragic violence... the mind recoils at such desperation.";
            break;
          case DeathCause.misunderstanding:
            deathCondolence =
                "To lose them to such a bizarre misunderstanding... fate can be incredibly cruel.";
            break;
          default:
            deathCondolence = "To lose them so suddenly is a cruel blow.";
            break;
        }

        final bool isFrankenstein =
            state.playerLastName.toLowerCase() == 'frenstein' ||
            state.playerLastName.toLowerCase() == 'frankenstein';

        final player = state.npcs.firstWhere(
          (n) => n.id == 'player',
          orElse: () => state.npcs.first,
        );
        final int beauty = player.stats['beauty'] ?? 5;
        final int temperament = player.stats['temperament'] ?? 5;
        final int intellect = player.stats['intellect'] ?? 5;

        String attributeFlavour = "";
        if (temperament <= 2) {
          attributeFlavour = "\n\nI can see the restless, volatile anger burning within you. Grief is a fire, but we must not let it consume our reason.";
        } else if (intellect >= 7) {
          attributeFlavour = "\n\nFor a mind as sharp and inquisitive as yours, I know the hardest part of tragedy is the search for a logic where none exists.";
        } else if (beauty >= 7) {
          attributeFlavour = "\n\nIt is tragic to see such grief cast a shadow over a face so finely favored by nature.";
        } else if (intellect <= 3) {
          attributeFlavour = "\n\nIn times of such heavy sorrow, we must keep our feet firmly on the earth and not get lost in confusing thoughts.";
        }

        if (step == 0) {
          String dialogue =
              "Monsieur ${state.playerLastName}. Please, accept my deepest condolences for your loss. $deathCondolence$attributeFlavour";
          if (isFrankenstein) {
            dialogue +=
                "\n\nAnd I must apologize. I had no idea my fictional Victor Frankenstein would share your name when I published my book. I hope it has not caused you distress.";
          }

          storyText = '"$dialogue"';

          optionWidgets.add(
            _dialogOption(
              context: context,
              title: "Thank you, Mary. Your condolences are appreciated.",
              description: "",
              icon: Icons.chat_bubble_outline,
              onTap: () {
                guest.metadata['plotDialogueStep'] = 1;
                guest.metadata['chosenPath'] = 'polite';
                state.notifyListeners();
              },
            ),
          );

          optionWidgets.add(
            _dialogOption(
              context: context,
              title: "My family is gone, Mary. Condolences won't bring them back. Nothing will.",
              description: "",
              icon: Icons.sentiment_very_dissatisfied,
              onTap: () {
                guest.metadata['plotDialogueStep'] = 1;
                guest.metadata['chosenPath'] = 'upset';
                state.notifyListeners();
              },
            ),
          );

          final String pressingText = isFrankenstein
              ? "If your fictional Victor can conquer death, why can't I?"
              : "Your book... you wrote of reanimation. Tell me how it is done.";

          optionWidgets.add(
            _dialogOption(
              context: context,
              title: pressingText,
              description: "",
              icon: Icons.psychology,
              onTap: () {
                guest.metadata['plotDialogueStep'] = 1;
                guest.metadata['chosenPath'] = 'curious';
                state.notifyListeners();
              },
            ),
          );
        } else if (step == 1) {
          final String path =
              guest.metadata['chosenPath'] as String? ?? 'polite';

          if (path == 'polite') {
            storyText =
                '"We must all find a way to carry on. I brought these alpine wildflowers for your Study. But please, tell me you are not harboring any morbid obsessions."';

            optionWidgets.add(
              _dialogOption(
                context: context,
                title:
                    "Actually, Mary... your book. You wrote of galvanism. Can the dead truly be reanimated?",
                description: "",
                icon: Icons.bolt,
                onTap: () {
                  guest.metadata['plotDialogueStep'] = 2;
                  guest.metadata['chosenPath'] = 'curious';
                  state.notifyListeners();
                },
              ),
            );
            optionWidgets.add(
              _dialogOption(
                context: context,
                title: "Of course not. I am only interested in keeping these flowers.",
                description: "",
                icon: Icons.done,
                onTap: () {
                  guest.metadata['plotDialogueStep'] = 2;
                  guest.metadata['chosenPath'] = 'flowers_wreckage_hint';
                  state.notifyListeners();
                },
              ),
            );
          } else if (path == 'upset') {
            String upsetResponse = "";
            if (temperament <= 2) {
              upsetResponse = "I see you are eager to lash out at the world, Monsieur. Grief is a storm, but raging against the inevitable will only break you. We must find anchor in what is real.";
            } else if (intellect >= 7) {
              upsetResponse = "Grief is a storm that tempers or shatters us, Monsieur. A mind like yours must know that wishing cannot rewrite the laws of nature. We must find anchor in what is real.";
            } else if (beauty >= 7) {
              upsetResponse = "Grief is a storm that tempers or shatters us, Monsieur. It pains me to see you so utterly consumed by this bitterness. We must find anchor in what is real.";
            } else if (intellect <= 3) {
              upsetResponse = "Grief is a storm that tempers or shatters us, Monsieur. Do not let your sorrow lead you into dark, confusing places. We must find anchor in what is real.";
            } else {
              upsetResponse = "Grief is a storm that tempers or shatters us, Monsieur. I too have known the quiet agony of loss. But we must find anchor in what is real, not in desperate fantasies.";
            }

            storyText = '"$upsetResponse"';

            optionWidgets.add(
              _dialogOption(
                context: context,
                title: "Is it truly a fantasy? Your novel speaks of galvanism—reanimation. Is there no scientific plausibility to it?",
                description: "",
                icon: Icons.bolt,
                onTap: () {
                  guest.metadata['plotDialogueStep'] = 2;
                  guest.metadata['chosenPath'] = 'curious';
                  state.notifyListeners();
                },
              ),
            );
            optionWidgets.add(
              _dialogOption(
                context: context,
                title: "I heard of a carriage carrying galvanic conductors that wrecked in the valley. If it is all fantasy, why was such equipment sent here?",
                description: "",
                icon: Icons.explore,
                onTap: () {
                  guest.metadata['plotDialogueStep'] = 2;
                  guest.metadata['chosenPath'] = 'wreckage';
                  state.notifyListeners();
                },
              ),
            );
            optionWidgets.add(
              _dialogOption(
                context: context,
                title: "Perhaps you are right. I must accept the reality of my loss.",
                description: "",
                icon: Icons.close,
                onTap: () {
                  guest.metadata['plotDialogueStep'] = 2;
                  guest.metadata['chosenPath'] = 'upset_reject_once';
                  state.notifyListeners();
                },
              ),
            );
          } else {
            // Disbelief (is he joking? Is he just grieving?)
            storyText =
                '"Are you jesting, Monsieur? Or has grief temporarily unseated your reason? It was a gothic romance, a ghost story written to pass a rainy summer by the lake. The boundary between life and death is absolute."';

            optionWidgets.add(
              _dialogOption(
                context: context,
                title:
                    "You lost your infant Clara. You wrote of dreaming she was rubbed before the fire. You want to believe it too. There must be a way.",
                description: "",
                icon: Icons.fireplace,
                onTap: () {
                  guest.metadata['plotDialogueStep'] = 2;
                  guest.metadata['chosenPath'] = 'persist';
                  state.notifyListeners();
                },
              ),
            );
            optionWidgets.add(
              _dialogOption(
                context: context,
                title: "Perhaps you are right. It was a foolish thought.",
                description: "",
                icon: Icons.close,
                onTap: () {
                  guest.metadata['plotDialogueStep'] = 2;
                  guest.metadata['chosenPath'] = 'curious_reject_once';
                  state.notifyListeners();
                },
              ),
            );
          }
        } else if (step == 2) {
          final String path =
              guest.metadata['chosenPath'] as String? ?? 'curious';

          if (path == 'curious' || path == 'wreckage') {
            // Disbelief (is he joking? Is he just grieving?)
            storyText =
                '"Are you jesting, Monsieur? Or has grief temporarily unseated your reason? It was a gothic romance, a ghost story written to pass a rainy summer by the lake. The boundary between life and death is absolute."';

            optionWidgets.add(
              _dialogOption(
                context: context,
                title:
                    "You lost your infant Clara. You wrote of dreaming she was rubbed before the fire. You want to believe it too. There must be a way.",
                description: "",
                icon: Icons.fireplace,
                onTap: () {
                  guest.metadata['plotDialogueStep'] = 3;
                  guest.metadata['chosenPath'] = 'persist';
                  state.notifyListeners();
                },
              ),
            );
            optionWidgets.add(
              _dialogOption(
                context: context,
                title: "Perhaps you are right. It was a foolish thought.",
                description: "",
                icon: Icons.close,
                onTap: () {
                  guest.metadata['plotDialogueStep'] = 3;
                  guest.metadata['chosenPath'] = 'curious_reject_once';
                  state.notifyListeners();
                },
              ),
            );
          } else if (path == 'persist') {
            // Condescension (is he dumb enough to think these things are possible?)
            storyText =
                '"You cannot be serious, Monsieur. Do you truly possess so little scientific literacy as to mistake a literary amusement for a textbook on anatomy? Galvanism may twitch a frog\'s leg, but it will not recall a soul from the ether."';

            optionWidgets.add(
              _dialogOption(
                context: context,
                title:
                    "I do not care about the soul. I care about the machinery. There are rumors of a carriage carrying galvanic conductors that wrecked in the valley. Tell me where it is.",
                description: "",
                icon: Icons.explore,
                onTap: () {
                  guest.metadata['plotDialogueStep'] = 3;
                  guest.metadata['chosenPath'] = 'wreckage_persist';
                  state.notifyListeners();
                },
              ),
            );
            optionWidgets.add(
              _dialogOption(
                context: context,
                title: "On second thought, this is madness. I will stick to my flowers.",
                description: "",
                icon: Icons.close,
                onTap: () {
                  guest.metadata['plotDialogueStep'] = 3;
                  guest.metadata['chosenPath'] = 'flowers_only_warned';
                  state.notifyListeners();
                },
              ),
            );
          } else if (path == 'flowers_wreckage_hint') {
            storyText =
                '"I am relieved to hear it, Monsieur. But... I must confess, I saw the shattered carriage wreckage in the valley on my way here. It was carrying some sort of galvanic machinery. I feared a mind like yours might be tempted by such ruins."';

            optionWidgets.add(
              _dialogOption(
                context: context,
                title: "If there is galvanic equipment in that wreckage, I must examine it.",
                description: "",
                icon: Icons.explore,
                onTap: () {
                  state.addItemToRoom(
                    'study',
                    GameItem.create(
                      name: 'Alpine Wildflowers',
                      type: 'wildflowers',
                      category: ItemCategory.specimen,
                      creationDate: state.currentDate.copy(),
                      metadata: const {
                        'discipline': 'botany',
                        'pages': 8,
                      },
                    ),
                  );
                  state.addAnnouncement(
                    "Received Alpine Wildflowers! They have been placed in the Study.",
                  );
                  state.activateWinterDreamsOfClara();
                  dismissVisitor();
                },
              ),
            );

            optionWidgets.add(
              _dialogOption(
                context: context,
                title: "No, Mary. I promise I will not go near the wreckage.",
                description: "",
                icon: Icons.done,
                onTap: () {
                  state.addItemToRoom(
                    'study',
                    GameItem.create(
                      name: 'Alpine Wildflowers',
                      type: 'wildflowers',
                      category: ItemCategory.specimen,
                      creationDate: state.currentDate.copy(),
                      metadata: const {
                        'discipline': 'botany',
                        'pages': 8,
                      },
                    ),
                  );
                  state.addAnnouncement(
                    "Received Alpine Wildflowers! They have been placed in the Study.",
                  );
                  dismissVisitor();
                },
              ),
            );
          } else if (path == 'upset_reject_once') {
            storyText =
                '"I am glad you see reason, Monsieur. Though, I did pass the wreckage of that carriage on my way here. The shattered iron and broken conductors... it looked like a tomb for those foolish scientific dreams. I am glad you have no interest in such things."';

            optionWidgets.add(
              _dialogOption(
                context: context,
                title: "Actually, if the equipment is there, I must retrieve it. Tell me more.",
                description: "",
                icon: Icons.explore,
                onTap: () {
                  state.addItemToRoom(
                    'study',
                    GameItem.create(
                      name: 'Alpine Wildflowers',
                      type: 'wildflowers',
                      category: ItemCategory.specimen,
                      creationDate: state.currentDate.copy(),
                      metadata: const {
                        'discipline': 'botany',
                        'pages': 8,
                      },
                    ),
                  );
                  state.addAnnouncement(
                    "Received Alpine Wildflowers! They have been placed in the Study.",
                  );
                  state.activateWinterDreamsOfClara();
                  dismissVisitor();
                },
              ),
            );

            optionWidgets.add(
              _dialogOption(
                context: context,
                title: "I agree. I will stay here and mourn in peace.",
                description: "",
                icon: Icons.done,
                onTap: () {
                  state.addItemToRoom(
                    'study',
                    GameItem.create(
                      name: 'Alpine Wildflowers',
                      type: 'wildflowers',
                      category: ItemCategory.specimen,
                      creationDate: state.currentDate.copy(),
                      metadata: const {
                        'discipline': 'botany',
                        'pages': 8,
                      },
                    ),
                  );
                  state.addAnnouncement(
                    "Received Alpine Wildflowers! They have been placed in the Study.",
                  );
                  dismissVisitor();
                },
              ),
            );
          } else if (path == 'curious_reject_once') {
            storyText =
                '"It is a comforting fiction, nothing more. Though... the locals say a carriage carrying massive galvanic conductors crashed in the valley. They whispered of it as if it were a sign. But it is just twisted metal. You must not seek it."';

            optionWidgets.add(
              _dialogOption(
                context: context,
                title: "No, I cannot let it go. I must find those conductors.",
                description: "",
                icon: Icons.explore,
                onTap: () {
                  state.addItemToRoom(
                    'study',
                    GameItem.create(
                      name: 'Alpine Wildflowers',
                      type: 'wildflowers',
                      category: ItemCategory.specimen,
                      creationDate: state.currentDate.copy(),
                      metadata: const {
                        'discipline': 'botany',
                        'pages': 8,
                      },
                    ),
                  );
                  state.addAnnouncement(
                    "Received Alpine Wildflowers! They have been placed in the Study.",
                  );
                  state.activateWinterDreamsOfClara();
                  dismissVisitor();
                },
              ),
            );

            optionWidgets.add(
              _dialogOption(
                context: context,
                title: "You are right. I will let it rust.",
                description: "",
                icon: Icons.done,
                onTap: () {
                  state.addItemToRoom(
                    'study',
                    GameItem.create(
                      name: 'Alpine Wildflowers',
                      type: 'wildflowers',
                      category: ItemCategory.specimen,
                      creationDate: state.currentDate.copy(),
                      metadata: const {
                        'discipline': 'botany',
                        'pages': 8,
                      },
                    ),
                  );
                  state.addAnnouncement(
                    "Received Alpine Wildflowers! They have been placed in the Study.",
                  );
                  dismissVisitor();
                },
              ),
            );
          }
        } else if (step == 3) {
          final String path =
              guest.metadata['chosenPath'] as String? ?? 'persist';

          if (path == 'wreckage_persist') {
            // Frightened but polite acquiescence (I think this guy is going to start conducting experiments on corpses)
            storyText =
                '"I... see. Well, if you are determined to pursue this... eccentricity... I suppose I cannot stop you. There was, in fact, a carriage carrying certain galvanic apparatuses that met with a disaster in the valley. The wreckage lies there still. Perhaps if you see the shattered iron, you will return to your senses. Now, if you will excuse me, I must take my leave... Please, take these wildflowers as well."';

            optionWidgets.add(
              _dialogOption(
                context: context,
                title: "I will retrieve those conductors. Thank you, Mary.",
                description: "",
                icon: Icons.explore,
                onTap: () {
                  state.addItemToRoom(
                    'study',
                    GameItem.create(
                      name: 'Alpine Wildflowers',
                      type: 'wildflowers',
                      category: ItemCategory.specimen,
                      creationDate: state.currentDate.copy(),
                      metadata: const {
                        'discipline': 'botany',
                        'pages': 8,
                      },
                    ),
                  );
                  state.addAnnouncement(
                    "Received Alpine Wildflowers! They have been placed in the Study.",
                  );
                  state.activateWinterDreamsOfClara();
                  dismissVisitor();
                },
              ),
            );
            optionWidgets.add(
              _dialogOption(
                context: context,
                title:
                    "Perhaps it is indeed madness. I will leave it alone.",
                description: "",
                icon: Icons.done_all,
                onTap: () {
                  guest.metadata['plotDialogueStep'] = 4;
                  guest.metadata['chosenPath'] = 'final_refusal';
                  state.notifyListeners();
                },
              ),
            );
          } else if (path == 'hesitant_wreckage') {
            storyText =
                '"I can\'t believe you would even consider it! There is that wreckage up the road. But, oh, it would be so vile to search it for those conductors! Promise me you will stay away."';

            optionWidgets.add(
              _dialogOption(
                context: context,
                title: "I cannot promise that. I must go to the wreckage.",
                description: "",
                icon: Icons.explore,
                onTap: () {
                  state.addItemToRoom(
                    'study',
                    GameItem.create(
                      name: 'Alpine Wildflowers',
                      type: 'wildflowers',
                      category: ItemCategory.specimen,
                      creationDate: state.currentDate.copy(),
                      metadata: const {
                        'discipline': 'botany',
                        'pages': 8,
                      },
                    ),
                  );
                  state.addAnnouncement(
                    "Received Alpine Wildflowers! They have been placed in the Study.",
                  );
                  state.activateWinterDreamsOfClara();
                  dismissVisitor();
                },
              ),
            );

            optionWidgets.add(
              _dialogOption(
                context: context,
                title: "I promise, Mary. I will stay away.",
                description: "",
                icon: Icons.done,
                onTap: () {
                  state.addItemToRoom(
                    'study',
                    GameItem.create(
                      name: 'Alpine Wildflowers',
                      type: 'wildflowers',
                      category: ItemCategory.specimen,
                      creationDate: state.currentDate.copy(),
                      metadata: const {
                        'discipline': 'botany',
                        'pages': 8,
                      },
                    ),
                  );
                  state.addAnnouncement(
                    "Received Alpine Wildflowers! They have been placed in the Study.",
                  );
                  dismissVisitor();
                },
              ),
            );
          } else if (path == 'flowers_only_warned') {
            storyText =
                '"I... I forgive you. It is the grief speaking. But please, promise me you won\'t go near the valley wreckage. They say the galvanic equipment is still intact, but it is a cursed thing."';

            optionWidgets.add(
              _dialogOption(
                context: context,
                title: "I cannot make that promise. I must see the wreckage.",
                description: "",
                icon: Icons.explore,
                onTap: () {
                  state.addItemToRoom(
                    'study',
                    GameItem.create(
                      name: 'Alpine Wildflowers',
                      type: 'wildflowers',
                      category: ItemCategory.specimen,
                      creationDate: state.currentDate.copy(),
                      metadata: const {
                        'discipline': 'botany',
                        'pages': 8,
                      },
                    ),
                  );
                  state.addAnnouncement(
                    "Received Alpine Wildflowers! They have been placed in the Study.",
                  );
                  state.activateWinterDreamsOfClara();
                  dismissVisitor();
                },
              ),
            );

            optionWidgets.add(
              _dialogOption(
                context: context,
                title: "I promise. I will not go.",
                description: "",
                icon: Icons.done,
                onTap: () {
                  state.addItemToRoom(
                    'study',
                    GameItem.create(
                      name: 'Alpine Wildflowers',
                      type: 'wildflowers',
                      category: ItemCategory.specimen,
                      creationDate: state.currentDate.copy(),
                      metadata: const {
                        'discipline': 'botany',
                        'pages': 8,
                      },
                    ),
                  );
                  state.addAnnouncement(
                    "Received Alpine Wildflowers! They have been placed in the Study.",
                  );
                  dismissVisitor();
                },
              ),
            );
          }
        } else if (step == 4) {
          storyText =
              '"Indeed, peace is the only cure. I shall leave you to your flowers."';

          optionWidgets.add(
            _dialogOption(
              context: context,
              title: "Wait... no. I must have those conductors. I will go.",
              description: "",
              icon: Icons.explore,
              onTap: () {
                state.addItemToRoom(
                  'study',
                  GameItem.create(
                    name: 'Alpine Wildflowers',
                    type: 'wildflowers',
                    category: ItemCategory.specimen,
                    creationDate: state.currentDate.copy(),
                    metadata: const {
                      'discipline': 'botany',
                      'pages': 8,
                    },
                  ),
                );
                state.addAnnouncement(
                  "Received Alpine Wildflowers! They have been placed in the Study.",
                );
                state.activateWinterDreamsOfClara();
                dismissVisitor();
              },
            ),
          );
          optionWidgets.add(
            _dialogOption(
              context: context,
              title: "Goodbye, Mary.",
              description: "",
              icon: Icons.done_all,
              onTap: () {
                state.addItemToRoom(
                  'study',
                  GameItem.create(
                    name: 'Alpine Wildflowers',
                    type: 'wildflowers',
                    category: ItemCategory.specimen,
                    creationDate: state.currentDate.copy(),
                    metadata: const {
                      'discipline': 'botany',
                      'pages': 8,
                    },
                  ),
                );
                state.addAnnouncement(
                  "Received Alpine Wildflowers! They have been placed in the Study.",
                );
                dismissVisitor();
              },
            ),
          );
        }
        break;

      default:
        storyText = "The representative stands before you, awaiting Glarus's response.";
        optionWidgets.add(
          _dialogOption(
            context: context,
            title: "BID FAREWELL",
            description: "Conclude the conversation.",
            icon: Icons.check_circle_outline,
            onTap: () {
              dismissVisitor();
            },
          ),
        );
    }

    return [
      Text(
        storyText,
        style: GoogleFonts.oldStandardTt(
          color: const Color(0xFFE5D5B0),
          fontSize: 14,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 32),
      ...optionWidgets.map((opt) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: opt,
      )),
    ];
  }
}
