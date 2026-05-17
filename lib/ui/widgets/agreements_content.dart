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
import '../../models/contract.dart';
import 'package:collection/collection.dart';

class AgreementsContent extends StatelessWidget {
  const AgreementsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        if (state.contracts.isEmpty) {
          return Center(
            child: Text(
              'No formal agreements established.',
              style: GoogleFonts.oldStandardTt(
                color: Colors.white24,
                fontSize: 16,
              ),
            ),
          );
        }

        final activeContracts = state.contracts.where((c) => c.isActive).toList();
        final terminatedContracts = state.contracts.where((c) => !c.isActive).toList();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (activeContracts.isNotEmpty) ...[
                _buildSectionHeader('ACTIVE AGREEMENTS'),
                const SizedBox(height: 16),
                ...activeContracts.map((c) => _buildContractItem(context, state, c)),
                const SizedBox(height: 32),
              ],
              if (terminatedContracts.isNotEmpty) ...[
                _buildSectionHeader('TERMINATED AGREEMENTS'),
                const SizedBox(height: 16),
                ...terminatedContracts.map((c) => _buildContractItem(context, state, c)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        color: const Color(0xFFC4B89B),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildContractItem(BuildContext context, GameState state, Contract contract) {
    final npc = state.npcs.firstWhereOrNull((n) => n.id == contract.npcId);
    final npcName = npc?.name ?? "Unknown Character";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: contract.isActive ? Colors.black.withValues(alpha: 0.2) : Colors.transparent,
        border: Border.all(
          color: contract.isActive
              ? const Color(0xFFC4B89B).withValues(alpha: 0.3)
              : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                contract.type.displayName.toUpperCase(),
                style: GoogleFonts.playfairDisplay(
                  color: contract.isActive ? const Color(0xFFE5D5B0) : Colors.white24,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Party: ${npcName.toUpperCase()}",
                style: GoogleFonts.oldStandardTt(
                  color: contract.isActive ? const Color(0xFFC4B89B) : Colors.white24,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            contract.description,
            style: GoogleFonts.oldStandardTt(
              color: contract.isActive ? const Color(0xFFE5D5B0) : Colors.white24,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (contract.terms.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: contract.terms.entries.map((e) => _buildTermChip(e.key, e.value, contract.isActive)).toList(),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildTermChip(String key, dynamic value, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border.all(color: isActive ? const Color(0xFFC4B89B).withValues(alpha: 0.2) : Colors.white10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "${key.toUpperCase()}: $value",
        style: GoogleFonts.oswald(
          color: isActive ? const Color(0xFFC4B89B) : Colors.white24,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
