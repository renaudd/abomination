import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/npc.dart';
import '../../services/combat_unit_service.dart';
import 'character_blob_renderer.dart';

class CombatCardDetailModal {
  static void show(BuildContext context, dynamic cardOrNpc, {int level = 1}) {
    final NPC npc = cardOrNpc is NPC
        ? cardOrNpc
        : CombatUnitService.createUnit(cardOrNpc as String);
    final stats = npc.combatStats!;
    final double mult = cardOrNpc is NPC ? 1.0 : (1.0 + (level - 1) * 0.1);
    final int squadSize = stats.unitCount > 0 ? stats.unitCount : 1;
    final bool isMeleeOnly = stats.rangedDamage == 0.0;

    final double baseMelee =
        stats.meleeDamage > 0 ? stats.meleeDamage : stats.attack;
    final double meleeHit = baseMelee * mult;
    final double meleeSpd =
        stats.meleeAttackSpeed > 0 ? stats.meleeAttackSpeed : stats.speed;
    final double meleeDps = meleeSpd > 0 ? (meleeHit / meleeSpd) : meleeHit;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF18120D),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: const Color(0xFFC4B89B).withValues(alpha: 0.4),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            width: 460,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'COMBAT CARD DETAIL',
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFC4B89B),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white54,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 16),

                  // Portrait
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF241C15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD4AF37),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: ClipOval(
                        child: CharacterBlobRenderer(
                          npc: npc,
                          size: 72,
                          isCombat: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    npc.name.toUpperCase(),
                    style: GoogleFonts.oswald(
                      color: const Color(0xFFD4AF37),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    '${npc.role.toUpperCase()} • LEVEL $level',
                    style: GoogleFonts.oldStandardTt(
                      color: Colors.white54,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Table
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF120C08),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _statRow(
                          'Action Point (AP) Cost',
                          '${stats.cost} AP',
                          isGold: true,
                        ),
                        _statRow('Squad Troop Count', 'x$squadSize'),
                        _statRow(
                          'Structural Vitality (HP)',
                          '${(stats.health * mult).toInt()} HP',
                        ),
                        _statRow(
                          'Tactical Move Speed',
                          '${stats.movement.toStringAsFixed(1)} m/s',
                        ),
                        const Divider(color: Colors.white10, height: 16),

                        Text(
                          'MELEE ATTACK PROFILE',
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFFD4AF37),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _statRow(
                          'Melee Damage per Attack',
                          '${meleeHit.toStringAsFixed(1)} Dmg',
                        ),
                        _statRow(
                          'Melee Damage per Second (DPS)',
                          '${meleeDps.toStringAsFixed(1)} DPS',
                        ),
                        _statRow(
                          'Melee Strike Cooldown',
                          '${stats.meleeAttackSpeed.toStringAsFixed(1)}s',
                        ),
                        _statRow(
                          'Melee Engage Reach',
                          '${stats.meleeRange.toStringAsFixed(1)} ft',
                        ),

                        if (!isMeleeOnly) ...[
                          const Divider(color: Colors.white10, height: 16),
                          Text(
                            'RANGED ATTACK PROFILE',
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFD4AF37),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Builder(
                            builder: (context) {
                              final double rangedHit =
                                  stats.rangedDamage * mult;
                              final double rangedSpd =
                                  stats.rangedAttackSpeed > 0
                                      ? stats.rangedAttackSpeed
                                      : stats.speed;
                              final double rangedDps = rangedSpd > 0
                                  ? (rangedHit / rangedSpd)
                                  : rangedHit;
                              return Column(
                                children: [
                                  _statRow(
                                    'Ranged Damage per Attack',
                                    '${rangedHit.toStringAsFixed(1)} Dmg',
                                  ),
                                  _statRow(
                                    'Ranged Damage per Second (DPS)',
                                    '${rangedDps.toStringAsFixed(1)} DPS',
                                  ),
                                ],
                              );
                            },
                          ),
                          _statRow(
                            'Ranged Cooldown Rate',
                            '${stats.rangedAttackSpeed.toStringAsFixed(1)}s',
                          ),
                          _statRow(
                            'Ranged Effective Distance',
                            '${stats.rangedRange.toStringAsFixed(1)} ft',
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (npc.abilities.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'SPECIAL ABILITIES',
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFC4B89B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...npc.abilities.map(
                      (a) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          border: Border.all(color: Colors.white10),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.name.toUpperCase(),
                              style: GoogleFonts.oswald(
                                color: const Color(0xFFE5D5B0),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              a.description,
                              style: GoogleFonts.oldStandardTt(
                                color: Colors.white70,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _statRow(String label, String val, {bool isGold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.oldStandardTt(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
          Text(
            val,
            style: GoogleFonts.oswald(
              color: isGold ? Colors.cyanAccent : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
