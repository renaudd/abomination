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
import '../../models/active_business.dart';
import 'visiting_merchant_trade_dialog.dart';

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

        return Dialog(
          backgroundColor: const Color(0xFF1E1A15),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC4B89B), width: 1.5),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                      Text(
                        "AUDIENCE IN THE ENTRYWAY",
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFFE5D5B0), size: 20),
                        onPressed: () {
                          state.clearGuestConversation();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 24),

                  // Narrator Description
                  Text(
                    "${greeter.name.toUpperCase()} has met ${guest.name.toUpperCase()} (${guest.role.toUpperCase()}) at the grand entryway doors.",
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFC4B89B),
                      fontSize: 13,
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    "The visitor looks up, a question hovering over their countenance. How shall Glarus respond to their presence?",
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFE5D5B0).withValues(alpha: 0.8),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Business Venture Proposal Option
                  if (isProposer) ...[
                    _dialogOption(
                      context: context,
                      title: "DISCUSS COMMERCIAL PROPOSAL",
                      description: "Hear ${guest.name.toUpperCase()}'s venture proposal. Set up a specialty business at the manor.",
                      icon: Icons.business_center,
                      onTap: () {
                        _showVentureProposalDetails(context, state, guest);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Option 1: Welcome and Trade
                  _dialogOption(
                    context: context,
                    title: isMerchant ? "DISCUSS MERCHANDISE" : "WELCOME & OFFER COMMERCE",
                    description: isMerchant 
                        ? "Offer the merchant standard hospitality and inspect their wagon wares." 
                        : "Welcome the visitor and ask if they carry any trade stock.",
                    icon: Icons.storefront,
                    onTap: () {
                      guest.metadata['isGreeted'] = true;
                      state.clearGuestConversation();
                      Navigator.pop(context);

                      if (isMerchant) {
                        showDialog(
                          context: context,
                          builder: (context) => VisitingMerchantTradeDialog(merchant: guest),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${guest.name} is not a merchant and has no goods to sell."),
                            backgroundColor: const Color(0xFF241F1A),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Option 2: Quest Opportunity
                  _dialogOption(
                    context: context,
                    title: "DISCUSS LOCAL PROJECTS (QUEST)",
                    description: "Ask if they have any tasks or need assistance. Accept a quest to keep the Study restored and fully clean.",
                    icon: Icons.assignment,
                    onTap: () {
                      state.acceptVisitorQuest(guest.name);
                      state.clearGuestConversation();
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Quest accepted: Keep Glarus Study restored and tidy."),
                          backgroundColor: Color(0xFF241F1A),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Option 3: Social Debate / Spirits
                  _dialogOption(
                    context: context,
                    title: hasSpirits ? "SHARE REFINED SPIRITS & DEBATE" : "DISCUSS PHILOSOPHY & SCIENCE",
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
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(hasSpirits 
                              ? "Refined spirits shared! ${greeter.name} gained +20 Satisfaction."
                              : "Engaged in philosophical discourse. ${greeter.name} gained +10 Satisfaction."),
                          backgroundColor: const Color(0xFF241F1A),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Option 4: Polite Dismissal
                  _dialogOption(
                    context: context,
                    title: "POLITELY DISMISS GUEST",
                    description: "Tell them that Glarus cannot host travelers today. They will immediately pack up and depart.",
                    icon: Icons.exit_to_app,
                    isRed: true,
                    onTap: () {
                      state.dismissGuest(guest.id);
                      state.clearGuestConversation();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dialogOption({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    bool isRed = false,
  }) {
    final Color themeColor = isRed ? Colors.redAccent : const Color(0xFFC4B89B);

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
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.oldStandardTt(
                      color: Colors.white38,
                      fontSize: 9.5,
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

  void _showVentureProposalDetails(BuildContext context, GameState state, dynamic guest) {
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
                  final bool locked = requiresDegree && !state.playerHasGraduateDegree;

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
                              ? "LOCKED: ALPHONSE LACKS GRADUATE DEGREE. STUDY AT GRADUATE SCHOOL."
                              : "GRADUATE DEGREE ATTAINED (UNLOCKED)")
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
                            Navigator.pop(context); // Pop conversation

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
        );
      },
    );
  }
}
