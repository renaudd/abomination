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
import 'dart:math' as math;
import '../../models/npc.dart';

class CharacterBlobRenderer extends StatelessWidget {
  final NPC npc;
  final double size;
  final bool isWalking;
  final bool isIdle;
  final double bubbleOffset;
  final bool showSpeechBubble;
  final double? attackCooldown; // Optional parameter for dynamic combat firing sequences

  final bool isCombat;

  const CharacterBlobRenderer({
    super.key,
    required this.npc,
    this.size = 40,
    this.isWalking = false,
    this.isIdle = true,
    this.bubbleOffset = 0,
    this.showSpeechBubble = true,
    this.attackCooldown,
    this.isCombat = false,
  });

  @override
  Widget build(BuildContext context) {
    final appearance = npc.appearance;

    return SizedBox(
      width: size,
      height: size,
      child: Transform.rotate(
        angle: npc.status == NPCStatus.fainted ? math.pi / 2 : 0,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if ((npc.combatStats?.swarmSize ?? 0) > 0)
              _buildSwarm(npc, size)
            else if (npc.specimenType == 'Rat' ||
                npc.specimenType == 'Bat' ||
                npc.specimenType == 'FlyingRat')
              _buildAnimal(npc.specimenType, size)
            else if (npc.specimenType == 'Hound')
              _buildHound(size)
            else if (npc.specimenType == 'Fox')
              _buildFox(size)
            else if (npc.specimenType == 'Wolf')
              _buildWolf(size)
            else if (npc.specimenType == 'Bear')
              _buildBear(size)
            else if (npc.specimenType == 'Beast' && npc.name.toLowerCase().contains('werewolf'))
              _buildWerewolf(size)
            else if (npc.specimenType == 'Beast' && npc.name.toLowerCase().contains('chimera'))
              _buildChimera(size)
            else if (npc.specimenType == 'Machine' && npc.name.toLowerCase().contains('car'))
              _buildArmoredCar(size)
            else if (npc.specimenType == 'Machine' && npc.name.toLowerCase().contains('tank'))
              _buildWoodenTank(size)
            else if (npc.name.toLowerCase().contains('bicycle'))
              _buildBicycle(size)
            else if (npc.name.toLowerCase().contains('motorcycle'))
              _buildMotorcycle(size)
            else if (npc.role.toLowerCase() == 'artillery' || npc.name.toLowerCase().contains('cannoneer'))
              _buildCannoneer(size, context)
            else if (npc.name.toLowerCase().contains('grenade') || npc.name.toLowerCase().contains('gas'))
              _buildGasGrenadeIcon(size)
            else if (npc.name.toLowerCase().contains('barrage') || npc.name.toLowerCase().contains('artillery'))
              _buildArtilleryBarrageIcon(size)
            else if (npc.name.toLowerCase().contains('totem') || npc.name.toLowerCase().contains('vampiric'))
              _buildVampiricTotemIcon(size)
            else if (npc.name.toLowerCase().contains('cavalry'))
              _buildCavalry(size)
            else ...[
              // Shadow
              Positioned(
                bottom: 2,
                child: Container(
                  width: size * 0.6,
                  height: size * 0.15,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(size * 0.3, size * 0.07),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getAuraColor(npc).withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // Body (Rounded Rect)
              _buildAnimatedContainer(
                child: Container(
                  width: _getBodyWidth(appearance.bodyType, size),
                  height: _getBodyHeight(appearance.bodyType, size),
                  decoration: BoxDecoration(
                    color: appearance.outfitColor,
                    borderRadius: BorderRadius.circular(_getBodyRadius(appearance.bodyType, size)),
                    border: Border.all(color: Colors.black12, width: 0.5),
                  ),
                ),
                offset: Offset(0, size * 0.1),
              ),

              // Head (Circle)
              _buildAnimatedContainer(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Hair (Back)
                    if (appearance.hairStyle != HairStyle.none &&
                        appearance.hairStyle != HairStyle.bald)
                      _buildHair(appearance, size, isBack: true),

                    // Skin
                    Container(
                      width: size * (npc.role == 'Bruiser' ? 0.45 : 0.4),
                      height: size * (npc.role == 'Sharpshooter' ? 0.45 : 0.4),
                      decoration: BoxDecoration(
                        color: appearance.bodyColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12, width: 0.5),
                      ),
                    ),

                    // Eyes
                    Positioned(
                      top: size * 0.18,
                      left: size * 0.1,
                      child: _buildEye(
                        npc.status == NPCStatus.broken
                            ? Colors.red
                            : appearance.eyeColor,
                        size,
                      ),
                    ),
                    Positioned(
                      top: size * 0.18,
                      right: size * 0.1,
                      child: _buildEye(
                        npc.status == NPCStatus.broken
                            ? Colors.red
                            : appearance.eyeColor,
                        size,
                      ),
                    ),

                    // Facial Hair
                    if (appearance.facialHairStyle != FacialHairStyle.none)
                      _buildFacialHair(appearance, size),

                    // Hair (Front)
                    if (appearance.hairStyle != HairStyle.none &&
                        appearance.hairStyle != HairStyle.bald)
                      _buildHair(appearance, size, isBack: false),

                    // Samurai Kabuto Helmet
                    if (npc.name.toLowerCase().contains('samurai'))
                      _buildSamuraiHelmet(size),
                  ],
                ),
                offset: Offset(0, -size * 0.15),
                delayFactor: 0.5,
              ),

              // Gear / Items
              if (npc.specimenType == 'Human')
                ...npc.equippedVisuals.map(
                  (item) => _buildItemBlob(item, size),
                ),

              // Pole Weapons (Halberdier, Pikeman, Mob/Villager)
              if (isCombat &&
                  (npc.name.toLowerCase().contains('halberd') ||
                      npc.name.toLowerCase().contains('pike') ||
                      npc.name.toLowerCase().contains('mob') ||
                      npc.name.toLowerCase().contains('villager')))
                _buildPoleWeaponOverlay(size),

              // Ranged Infantry Muskets
              if (isCombat &&
                  npc.combatStats != null &&
                  npc.combatStats!.rangedDamage > 0 &&
                  !npc.isPlayer)
                _buildMusketOverlay(size),
            ],

            // Speech Bubble
            if (showSpeechBubble && npc.currentThought != null && npc.currentThought!.isNotEmpty)
              _buildSpeechBubble(npc.currentThought!, size),
          ],
        ),
      ),
    );
  }

  double _getBodyWidth(BodyType type, double size) {
    switch (type) {
      case BodyType.slim: return size * 0.4;
      case BodyType.heavy: return size * 0.65;
      case BodyType.muscular: return size * 0.6;
      case BodyType.average: return size * 0.5;
    }
  }

  double _getBodyHeight(BodyType type, double size) {
    switch (type) {
      case BodyType.muscular: return size * 0.4;
      case BodyType.slim: return size * 0.45;
      case BodyType.heavy: return size * 0.45;
      case BodyType.average: return size * 0.45;
    }
  }

  double _getBodyRadius(BodyType type, double size) {
    switch (type) {
      case BodyType.muscular: return size * 0.05; // more square
      case BodyType.heavy: return size * 0.2; // more round
      case BodyType.slim: return size * 0.15;
      case BodyType.average: return size * 0.15;
    }
  }

  Widget _buildSwarm(NPC npc, double size) {
    final swarmMax = npc.combatStats?.swarmSize ?? 0;
    final healthRatio =
        (npc.combatStats?.health ?? 0) / (npc.combatStats?.maxHealth ?? 1);
    final currentlyAlive = (healthRatio * swarmMax).ceil();

    return Stack(
      alignment: Alignment.center,
      children: List.generate(currentlyAlive, (index) {
        // Offset each member of the swarm
        final double offsetX = (index % 2 == 0 ? -1.0 : 1.0) * (size * 0.2);
        final double offsetY = (index < 2 ? -1.0 : 1.0) * (size * 0.2);

        return Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: _buildAnimal(npc.specimenType, size * 0.5),
        );
      }),
    );
  }

  Widget _buildHound(double size) {
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0.1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tail
          Positioned(
            right: 0,
            bottom: size * 0.4,
            child: Transform.rotate(
              angle: 0.5,
              child: Container(
                width: size * 0.4,
                height: 4,
                decoration: BoxDecoration(
                  color: npc.appearance.bodyColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Body
          Container(
            width: size * 0.8,
            height: size * 0.45,
            decoration: BoxDecoration(
              color: npc.appearance.bodyColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(size * 0.1),
                topRight: Radius.circular(size * 0.3),
                bottomLeft: Radius.circular(size * 0.2),
                bottomRight: Radius.circular(size * 0.2),
              ),
            ),
          ),
          // Neck/Chest
          Positioned(
            left: size * 0.1,
            top: size * 0.1,
            child: Container(
              width: size * 0.3,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: npc.appearance.bodyColor,
                borderRadius: BorderRadius.circular(size * 0.1),
              ),
            ),
          ),
          // Head
          Positioned(
            left: -size * 0.05,
            top: 0,
            child: Container(
              width: size * 0.35,
              height: size * 0.35,
              decoration: BoxDecoration(
                color: npc.appearance.bodyColor,
                borderRadius: BorderRadius.circular(size * 0.1),
              ),
            ),
          ),
          // Snout
          Positioned(
            left: -size * 0.2,
            top: size * 0.1,
            child: Container(
              width: size * 0.3,
              height: size * 0.15,
              decoration: BoxDecoration(
                color: npc.appearance.bodyColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Ears
          Positioned(
            left: size * 0.15,
            top: -size * 0.1,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 10,
                  color: npc.appearance.bodyColor,
                ),
                const SizedBox(width: 6),
                Container(
                  width: 4,
                  height: 10,
                  color: npc.appearance.bodyColor,
                ),
              ],
            ),
          ),
          // Glowing Eyes
          Positioned(
            left: 0,
            top: size * 0.1,
            child: Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAuraColor(NPC npc) {
    if (npc.role == 'Butler' || npc.isPlayer) return Colors.black;
    for (final ability in npc.abilities) {
      if (ability.id.contains('freeze')) return Colors.cyanAccent;
      if (ability.id.contains('plague') || ability.id.contains('poison')) {
        return Colors.lightGreenAccent;
      }
      if (ability.id.contains('steal') || ability.id.contains('vampire')) {
        return Colors.purpleAccent;
      }
      if (ability.id.contains('horn')) return Colors.blueAccent;
      if (ability.id.contains('execute')) return Colors.redAccent;
    }
    return Colors.black;
  }

  Widget _buildAnimal(String type, double size) {
    if (type == 'Bat') return _buildBat(size);
    if (type == 'Rat') return _buildRat(size);
    if (type == 'FlyingRat') return _buildFlyingRat(size);
    // Fallback blob
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildRat(double size) {
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tail
          Positioned(
            right: 0,
            bottom: size * 0.2,
            child: Container(
              width: size * 0.6,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.pink.shade100,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          // Body (Tear Drop Shape, facing left)
          Container(
            width: size * 0.72,
            height: size * 0.42,
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(size * 0.04), // Pointed front snout
                bottomLeft: Radius.circular(size * 0.04),
                topRight: Radius.circular(size * 0.28), // Rounded back
                bottomRight: Radius.circular(size * 0.28),
              ),
            ),
          ),
          // Ears
          Positioned(
            left: size * 0.1,
            top: size * 0.2,
            child: Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: Colors.pink.shade100,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Eyes
          Positioned(
            left: size * 0.15,
            top: size * 0.35,
            child: Container(
              width: 2,
              height: 2,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBat(double size) {
    return __buildBatLike(size, Colors.brown.shade900, Colors.black87);
  }

  Widget _buildFlyingRat(double size) {
    return __buildBatLike(
      size * 1.3,
      Colors.blueGrey.shade900,
      Colors.black,
      isStrange: true,
    );
  }

  Widget __buildBatLike(
    double size,
    Color bodyColor,
    Color wingColor, {
    bool isStrange = false,
  }) {
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wings (Segmented for strange creatures)
          if (isStrange)
            for (int i = 0; i < 3; i++)
              Transform.rotate(
                angle: (i - 1) * 0.2,
                child: Container(
                  width: size * (1.1 - i * 0.1),
                  height: size * 0.35,
                  decoration: BoxDecoration(
                    color: wingColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(size * 0.15),
                  ),
                ),
              )
          else
            Container(
              width: size,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: wingColor,
                borderRadius: BorderRadius.circular(size * 0.1),
              ),
            ),
          // Body
          Container(
            width: isStrange ? size * 0.4 : size * 0.3,
            height: isStrange ? size * 0.6 : size * 0.5,
            decoration: BoxDecoration(
              color: bodyColor,
              borderRadius: BorderRadius.circular(size * 0.15),
            ),
          ),
          // Head / Ears
          Positioned(
            top: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEarPiece(bodyColor, isStrange),
                SizedBox(width: isStrange ? 8 : 4),
                _buildEarPiece(bodyColor, isStrange),
              ],
            ),
          ),
          // Eyes (Glowing)
          Positioned(
            top: size * (isStrange ? 0.15 : 0.2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isStrange ? 4 : 2,
                  height: isStrange ? 4 : 2,
                  decoration: BoxDecoration(
                    color: isStrange ? Colors.purpleAccent : Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: isStrange ? 8 : 4),
                Container(
                  width: isStrange ? 4 : 2,
                  height: isStrange ? 4 : 2,
                  decoration: BoxDecoration(
                    color: isStrange ? Colors.purpleAccent : Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          if (isStrange)
            // Extra strange glow/appendage
            Positioned(
              bottom: 0,
              child: Container(
                width: size * 0.15,
                height: size * 0.3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bodyColor, Colors.purple.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEarPiece(Color color, bool isStrange) {
    return Container(
      width: isStrange ? 6 : 4,
      height: isStrange ? 12 : 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isStrange ? 4 : 2),
        ),
      ),
    );
  }

  Widget _buildSpeechBubble(String thought, double size) {
    return Positioned(
      bottom: size * 0.9 + bubbleOffset, // Float above the head
      child: _BobbingAnimation(
        isWalking: isWalking,
        isIdle: isIdle,
        delayFactor: 0.2, // Match head bob roughly
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          constraints: BoxConstraints(maxWidth: size * 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                thought,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              Transform.translate(
                offset: const Offset(0, 2),
                child: CustomPaint(
                  size: const Size(6, 4),
                  painter: _BubbleTailPainter(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedContainer({
    required Widget child,
    required Offset offset,
    double delayFactor = 0,
  }) {
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      isBroken: npc.status == NPCStatus.broken,
      delayFactor: delayFactor,
      child: Transform.translate(offset: offset, child: child),
    );
  }

  Widget _buildEye(Color color, double size) {
    return Container(
      width: size * 0.06,
      height: size * 0.06,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildHair(
    NPCAppearance appearance,
    double size, {
    required bool isBack,
  }) {
    if (isBack &&
        appearance.hairStyle != HairStyle.long &&
        appearance.hairStyle != HairStyle.bob &&
        appearance.hairStyle != HairStyle.ponytail &&
        appearance.hairStyle != HairStyle.curly) {
      return const SizedBox.shrink();
    }

    double width = size * 0.42;
    double height = size * 0.15;
    double top = -size * 0.02;
    BorderRadius borderRadius = BorderRadius.vertical(
      top: Radius.circular(size * 0.2),
    );

    switch (appearance.hairStyle) {
      case HairStyle.short:
        height = size * 0.12;
        break;
      case HairStyle.long:
        if (isBack) {
          height = size * 0.45;
          top = size * 0.05;
          borderRadius = BorderRadius.all(Radius.circular(size * 0.1));
        }
        break;
      case HairStyle.bob:
        if (isBack) {
          height = size * 0.35;
          top = size * 0.05;
          width = size * 0.48;
          borderRadius = BorderRadius.vertical(
            top: Radius.circular(size * 0.1),
            bottom: Radius.circular(size * 0.15),
          );
        }
        break;
      case HairStyle.messy:
        height = size * 0.18;
        top = -size * 0.05;
        width = size * 0.45;
        break;
      case HairStyle.curly:
        if (isBack) {
          height = size * 0.3;
          top = 0;
          width = size * 0.55;
          borderRadius = BorderRadius.circular(size * 0.15);
        } else {
          height = size * 0.2;
          width = size * 0.5;
          top = -size * 0.05;
          borderRadius = BorderRadius.circular(size * 0.1);
        }
        break;
      case HairStyle.ponytail:
        if (isBack) {
          height = size * 0.35;
          width = size * 0.15;
          top = size * 0.05;
          borderRadius = BorderRadius.circular(size * 0.05);
        } else {
          height = size * 0.15;
        }
        break;
      default:
        break;
    }

    return Positioned(
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: appearance.hairColor,
          borderRadius: borderRadius,
        ),
      ),
    );
  }

  Widget _buildFacialHair(NPCAppearance appearance, double size) {
    double width = size * 0.25;
    double height = size * 0.05;
    double bottom = size * 0.05;
    BorderRadius borderRadius = BorderRadius.circular(size * 0.02);

    switch (appearance.facialHairStyle) {
      case FacialHairStyle.beard:
        height = size * 0.18;
        width = size * 0.32;
        borderRadius = BorderRadius.vertical(
          bottom: Radius.circular(size * 0.15),
        );
        break;
      case FacialHairStyle.mustache:
        width = size * 0.28;
        height = size * 0.04;
        bottom = size * 0.08;
        break;
      case FacialHairStyle.goatee:
        width = size * 0.12;
        height = size * 0.1;
        break;
      default:
        break;
    }

    return Positioned(
      bottom: bottom,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: appearance.hairColor,
          borderRadius: borderRadius,
        ),
      ),
    );
  }

  Widget _buildFox(double size) {
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Long, Fluffy sweeping tail
          Positioned(
            right: -size * 0.16,
            bottom: size * 0.08,
            child: Transform.rotate(
              angle: -0.35,
              child: Container(
                width: size * 0.68,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: const Color(0xFFE65C00),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(size * 0.12),
                    topRight: Radius.circular(size * 0.24),
                    bottomRight: Radius.circular(size * 0.24),
                    bottomLeft: Radius.circular(size * 0.05),
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: size * 0.22,
                    height: size * 0.22,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Body
          Container(
            width: size * 0.7,
            height: size * 0.4,
            decoration: BoxDecoration(
              color: const Color(0xFFE65C00),
              borderRadius: BorderRadius.circular(size * 0.18),
            ),
          ),
          // Chest (White fluffy)
          Positioned(
            left: size * 0.1,
            bottom: size * 0.32,
            child: Container(
              width: size * 0.3,
              height: size * 0.18,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Head
          Positioned(
            left: size * 0.05,
            top: size * 0.08,
            child: Container(
              width: size * 0.38,
              height: size * 0.38,
              decoration: BoxDecoration(
                color: const Color(0xFFE65C00),
                borderRadius: BorderRadius.circular(size * 0.15),
              ),
            ),
          ),
          // Ears
          Positioned(
            left: size * 0.15,
            top: -size * 0.06,
            child: Row(
              children: [
                Transform.rotate(
                  angle: -0.2,
                  child: Container(
                    width: size * 0.09,
                    height: size * 0.18,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2F2F2F), // Black tipped
                      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Transform.rotate(
                  angle: 0.2,
                  child: Container(
                    width: size * 0.09,
                    height: size * 0.18,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2F2F2F),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Glowing Eyes
          Positioned(
            left: size * 0.14,
            top: size * 0.2,
            child: Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWolf(double size) {
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0.1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tail
          Positioned(
            right: -size * 0.08,
            bottom: size * 0.15,
            child: Transform.rotate(
              angle: 0.3,
              child: Container(
                width: size * 0.45,
                height: size * 0.18,
                decoration: BoxDecoration(
                  color: const Color(0xFF3D434A),
                  borderRadius: BorderRadius.circular(size * 0.08),
                ),
              ),
            ),
          ),
          // Body
          Container(
            width: size * 0.75,
            height: size * 0.42,
            decoration: BoxDecoration(
              color: const Color(0xFF4F565E),
              borderRadius: BorderRadius.circular(size * 0.12),
            ),
          ),
          // Chest Fur
          Positioned(
            left: size * 0.05,
            bottom: size * 0.28,
            child: Container(
              width: size * 0.35,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: const Color(0xFF828B94),
                borderRadius: BorderRadius.circular(size * 0.1),
              ),
            ),
          ),
          // Head
          Positioned(
            left: -size * 0.05,
            top: size * 0.05,
            child: Container(
              width: size * 0.4,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: const Color(0xFF4F565E),
                borderRadius: BorderRadius.circular(size * 0.12),
              ),
            ),
          ),
          // Snout
          Positioned(
            left: -size * 0.18,
            top: size * 0.2,
            child: Container(
              width: size * 0.24,
              height: size * 0.14,
              decoration: BoxDecoration(
                color: const Color(0xFF3D434A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Ears
          Positioned(
            left: size * 0.1,
            top: -size * 0.08,
            child: Row(
              children: [
                Container(
                  width: size * 0.08,
                  height: size * 0.2,
                  color: const Color(0xFF4F565E),
                ),
                const SizedBox(width: 8),
                Container(
                  width: size * 0.08,
                  height: size * 0.2,
                  color: const Color(0xFF4F565E),
                ),
              ],
            ),
          ),
          // Fierce Glowing Yellow Eyes
          Positioned(
            left: size * 0.02,
            top: size * 0.16,
            child: Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: Colors.amberAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBear(double size) {
    double progress = 0.0;
    if (attackCooldown != null) {
      final maxCooldown = (npc.combatStats?.speed ?? 1.3) * 1.2;
      progress = (attackCooldown! / maxCooldown).clamp(0.0, 1.0);
    }
    final bool isClawing = progress > 0.7;

    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0.15,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Body
          Container(
            width: size * 0.85,
            height: size * 0.6,
            decoration: BoxDecoration(
              color: const Color(0xFF5C4033),
              borderRadius: BorderRadius.circular(size * 0.25),
            ),
          ),
          // Muscle Hump
          Positioned(
            left: size * 0.1,
            top: -size * 0.05,
            child: Container(
              width: size * 0.45,
              height: size * 0.25,
              decoration: const BoxDecoration(
                color: Color(0xFF5C4033),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Head
          Positioned(
            left: -size * 0.08,
            top: size * 0.1,
            child: Container(
              width: size * 0.45,
              height: size * 0.45,
              decoration: const BoxDecoration(
                color: Color(0xFF4E3629),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Large muzzle
          Positioned(
            left: -size * 0.22,
            top: size * 0.25,
            child: Container(
              width: size * 0.26,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: const Color(0xFF3B281E),
                borderRadius: BorderRadius.circular(size * 0.05),
              ),
            ),
          ),
          // Fluffy Bear Ears sitting perfectly on top of head
          Positioned(
            left: -size * 0.12,
            top: size * 0.02,
            child: Row(
              children: [
                // Left ear
                Container(
                  width: size * 0.18,
                  height: size * 0.18,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4E3629),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: size * 0.08,
                      height: size * 0.08,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD2B48C), // Tan inner ear
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Right ear
                Container(
                  width: size * 0.18,
                  height: size * 0.18,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4E3629),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: size * 0.08,
                      height: size * 0.08,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD2B48C),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dynamic 3-tine claw attack overlay!
          if (isClawing)
            Positioned(
              left: -size * 0.48,
              top: size * 0.08,
              child: CustomPaint(
                size: Size(size * 0.55, size * 0.45),
                painter: _ClawSlashPainter(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWerewolf(double size) {
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      isBroken: npc.status == NPCStatus.broken,
      delayFactor: 0.1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Wolf Tail
          Positioned(
            right: -size * 0.1,
            bottom: size * 0.1,
            child: Transform.rotate(
              angle: 0.5,
              child: Container(
                width: size * 0.4,
                height: size * 0.15,
                decoration: BoxDecoration(
                  color: const Color(0xFF25262B),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          // Muscular Torso
          Container(
            width: size * 0.6,
            height: size * 0.75,
            decoration: BoxDecoration(
              color: const Color(0xFF2E3035),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(size * 0.2),
                topRight: Radius.circular(size * 0.2),
                bottomLeft: Radius.circular(size * 0.1),
                bottomRight: Radius.circular(size * 0.1),
              ),
            ),
          ),
          // Sharp Shoulders / Spikes
          Positioned(
            top: size * 0.1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1E),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: size * 0.5),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1E),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          // Beast Head
          Positioned(
            top: -size * 0.05,
            child: Container(
              width: size * 0.4,
              height: size * 0.4,
              decoration: const BoxDecoration(
                color: Color(0xFF25262B),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Wolf Snout
          Positioned(
            top: size * 0.1,
            left: size * 0.15,
            child: Container(
              width: size * 0.3,
              height: size * 0.15,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1E),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Glowing Crimson Eyes
          Positioned(
            top: size * 0.06,
            left: size * 0.22,
            child: Row(
              children: [
                Container(width: 3, height: 3, color: Colors.redAccent),
                const SizedBox(width: 8),
                Container(width: 3, height: 3, color: Colors.redAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChimera(double size) {
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0.1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Coiled green snake tail
          Positioned(
            right: -size * 0.15,
            bottom: size * 0.2,
            child: Container(
              width: size * 0.4,
              height: size * 0.4,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.shade800, width: 3),
                shape: BoxShape.circle,
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: Colors.lightGreenAccent, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
          // Main Lion Body
          Container(
            width: size * 0.8,
            height: size * 0.5,
            decoration: BoxDecoration(
              color: const Color(0xFFD4A373),
              borderRadius: BorderRadius.circular(size * 0.15),
            ),
          ),
          // Massive Lion Mane
          Positioned(
            left: -size * 0.05,
            top: size * 0.02,
            child: Container(
              width: size * 0.46,
              height: size * 0.46,
              decoration: const BoxDecoration(
                color: Color(0xFF8B5A2B),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Head with small goat horns
          Positioned(
            left: size * 0.02,
            top: size * 0.06,
            child: Container(
              width: size * 0.32,
              height: size * 0.32,
              decoration: const BoxDecoration(
                color: Color(0xFFD4A373),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Dark Horns
          Positioned(
            left: size * 0.1,
            top: -size * 0.08,
            child: Row(
              children: [
                Transform.rotate(
                  angle: -0.4,
                  child: Container(width: 3, height: 10, color: const Color(0xFF2F2F2F)),
                ),
                const SizedBox(width: 10),
                Transform.rotate(
                  angle: 0.4,
                  child: Container(width: 3, height: 10, color: const Color(0xFF2F2F2F)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArmoredCar(double size) {
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0.05,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Heavy Chassis
          Container(
            width: size * 0.9,
            height: size * 0.5,
            decoration: BoxDecoration(
              color: const Color(0xFF4A5258),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF2E3236), width: 2),
            ),
          ),
          // Turret
          Positioned(
            top: -size * 0.1,
            left: size * 0.2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: size * 0.4,
                  height: size * 0.25,
                  decoration: BoxDecoration(
                    color: const Color(0xFF363C40),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Gun barrel
                Container(
                  width: size * 0.25,
                  height: 5,
                  color: const Color(0xFF1A1D1E),
                ),
              ],
            ),
          ),
          // Golden Headlight Beam Glow
          Positioned(
            left: -size * 0.25,
            top: size * 0.15,
            child: Container(
              width: size * 0.3,
              height: size * 0.2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Colors.yellow.withValues(alpha: 0.3), Colors.yellow.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          // Heavy Tires
          Positioned(
            bottom: -size * 0.08,
            left: size * 0.1,
            right: size * 0.1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: size * 0.22,
                  height: size * 0.22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1D1E),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: size * 0.1,
                      height: size * 0.1,
                      decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
                    ),
                  ),
                ),
                Container(
                  width: size * 0.22,
                  height: size * 0.22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1D1E),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: size * 0.1,
                      height: size * 0.1,
                      decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWoodenTank(double size) {
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0.08,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Da Vinci Turtle Dome Shell
          Container(
            width: size * 0.95,
            height: size * 0.7,
            decoration: BoxDecoration(
              color: const Color(0xFF704734),
              borderRadius: BorderRadius.all(Radius.elliptical(size * 0.47, size * 0.35)),
              border: Border.all(color: const Color(0xFF3B2318), width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 6, spreadRadius: 1)
              ],
            ),
            child: Stack(
              children: [
                // Horizontal wood plank ridges
                for (int i = 1; i < 4; i++)
                  Positioned(
                    top: size * 0.15 * i,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1.5,
                      color: const Color(0xFF3B2318).withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          // Front cannon port snout
          Positioned(
            left: -size * 0.12,
            top: size * 0.25,
            child: Container(
              width: size * 0.2,
              height: size * 0.18,
              decoration: const BoxDecoration(
                color: Color(0xFF2A1810),
                borderRadius: BorderRadius.horizontal(left: Radius.circular(6)),
              ),
              child: Center(
                // Brass mortar barrel
                child: Container(
                  width: size * 0.1,
                  height: size * 0.1,
                  color: const Color(0xFFD4AF37),
                ),
              ),
            ),
          ),
          // Heavy Spiked wood wheels underneath
          Positioned(
            bottom: -size * 0.05,
            left: size * 0.15,
            right: size * 0.15,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: size * 0.25,
                  height: size * 0.15,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3C2015),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Container(
                  width: size * 0.25,
                  height: size * 0.15,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3C2015),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBicycle(double size) {
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0.1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Big wheel (Penny farthing look)
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white70, width: 2),
              ),
            ),
          ),
          // Small rear wheel
          Positioned(
            right: size * 0.1,
            bottom: 0,
            child: Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white70, width: 1.5),
              ),
            ),
          ),
          // Rider silhouette
          Positioned(
            left: size * 0.15,
            top: size * 0.1,
            child: Container(
              width: size * 0.3,
              height: size * 0.5,
              decoration: const BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotorcycle(double size) {
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0.05,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Copper engine frame
          Container(
            width: size * 0.85,
            height: size * 0.35,
            decoration: BoxDecoration(
              color: const Color(0xFF8A4F3B),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Dual Exhaust & Engine details
          Positioned(
            bottom: 2,
            left: size * 0.2,
            child: Container(
              width: size * 0.4,
              height: 6,
              color: Colors.grey.shade400,
            ),
          ),
          // Wheels
          Positioned(
            left: 0,
            bottom: -4,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black87, width: 3),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: -4,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black87, width: 3),
              ),
            ),
          ),
          // Rider
          Positioned(
            left: size * 0.2,
            top: -size * 0.05,
            child: Container(
              width: size * 0.35,
              height: size * 0.35,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCannoneer(double size, BuildContext context) {
    // Firing sequence states
    bool isRecoil = false;
    bool isLoading = false;
    bool isAiming = false;
    double? progress;

    if (attackCooldown != null) {
      final maxCooldown = (npc.combatStats?.speed ?? 2.0) * 1.2;
      progress = (attackCooldown! / maxCooldown).clamp(0.0, 1.0);
      if (progress > 0.75) {
        isRecoil = true;
      } else if (progress > 0.25) {
        isLoading = true;
      } else if (progress > 0.0) {
        isAiming = true;
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // 1. Heavy Wooden Carriage
        Positioned(
          bottom: 4,
          child: Container(
            width: size * 0.7,
            height: size * 0.25,
            decoration: BoxDecoration(
              color: const Color(0xFF5A3D28),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF301C0E), width: 1.5),
            ),
          ),
        ),

        // 2. Carriage Wheels
        Positioned(
          left: size * 0.05,
          bottom: 0,
          child: Container(
            width: size * 0.28,
            height: size * 0.28,
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF5A3D28), width: 3),
            ),
          ),
        ),

        // 3. Brass Cannon Barrel
        AnimatedPositioned(
          duration: const Duration(milliseconds: 80),
          left: isRecoil ? size * 0.22 : size * 0.12, // Recoil shifts barrel back!
          bottom: size * 0.15,
          child: Transform.rotate(
            angle: isAiming ? -0.35 : -0.2, // Aiming tilts barrel higher!
            child: Row(
              children: [
                Container(
                  width: size * 0.58,
                  height: size * 0.16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37), // Golden brass
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                    border: Border.all(color: const Color(0xFF8A6D1C), width: 1.5),
                  ),
                ),
                // Barrel opening
                Container(
                  width: 3,
                  height: size * 0.16,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),

        // 4. Operator Humanoid standing behind
        Positioned(
          right: -size * 0.12,
          bottom: size * 0.15,
          child: Column(
            children: [
              // Head
              Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: const BoxDecoration(
                  color: Color(0xFFD2B48C),
                  shape: BoxShape.circle,
                ),
              ),
              // Body/Outfit
              Container(
                width: size * 0.32,
                height: size * 0.32,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E3E62), // Blue uniform
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
            ],
          ),
        ),

        // 5. Dynamic Effects
        if (isRecoil) ...[
          // Billowing Muzzle Flash & Gray Smoke!
          Positioned(
            left: -size * 0.35,
            bottom: size * 0.22,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Orange starburst muzzle flash
                Container(
                  width: size * 0.32,
                  height: size * 0.32,
                  decoration: const BoxDecoration(
                    color: Colors.orangeAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                // Billowing grey smoke clouds drifting forward
                Positioned(
                  left: -12,
                  top: -8,
                  child: Container(
                    width: size * 0.25,
                    height: size * 0.25,
                    decoration: BoxDecoration(
                      color: Colors.white70.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: -20,
                  top: 4,
                  child: Container(
                    width: size * 0.2,
                    height: size * 0.2,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (isLoading) ...[
          // Operator pushes Ramrod into barrel
          Positioned(
            left: size * 0.05,
            bottom: size * 0.25,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                width: size * 0.45,
                height: 3,
                color: const Color(0xFF8B5A2B), // Wooden ramrod stick
              ),
            ),
          ),
          // Tiny visual loader bar above cannon!
          Positioned(
            top: -size * 0.1,
            child: Container(
              width: size * 0.7,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 1.0 - (progress ?? 0.0),
                child: Container(
                  color: Colors.yellowAccent,
                ),
              ),
            ),
          ),
        ],

        if (isAiming) ...[
          // Glowing orange/yellow fuse
          Positioned(
            right: size * 0.28,
            bottom: size * 0.32,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 2,
                  height: 8,
                  color: Colors.grey,
                ),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.yellow, blurRadius: 4, spreadRadius: 1)
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildItemBlob(String item, double size) {
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0.8, // Distinct orbit
      child: Transform.translate(
        offset: Offset(size * 0.35, size * 0.1),
        child: Container(
          width: size * 0.25,
          height: size * 0.25,
          decoration: BoxDecoration(
            color: Colors.blueGrey,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 4,
                offset: Offset(1, 1),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.inventory_2, size: 6, color: Colors.white70),
          ),
        ),
      ),
    );
  }

  Widget _buildGasGrenadeIcon(double size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Green mist aura
        Container(
          width: size * 0.85,
          height: size * 0.85,
          decoration: BoxDecoration(
            color: const Color(0xFF689F38).withValues(alpha: 0.15),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: const Color(0xFF8BC34A).withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 2)
            ],
          ),
        ),
        // Grenade metallic body (Canister)
        Container(
          width: size * 0.36,
          height: size * 0.65,
          decoration: BoxDecoration(
            color: const Color(0xFF4A4A4A), // Charcoal metal
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF2D2D2D), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Lime green chemical warning band
              Container(height: 4, color: const Color(0xFF8BC34A)),
              Container(height: 4, color: const Color(0xFF8BC34A)),
            ],
          ),
        ),
        // Canister metal cap/fuse
        Positioned(
          top: size * 0.1,
          child: Container(
            width: size * 0.2,
            height: size * 0.1,
            decoration: BoxDecoration(
              color: const Color(0xFF8B7E66), // Dull bronze cap
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Safety Ring/Pin
        Positioned(
          top: size * 0.02,
          left: size * 0.26,
          child: Container(
            width: size * 0.18,
            height: size * 0.18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB0BEC5), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArtilleryBarrageIcon(double size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Dotted red targeting crosshair ring
        Container(
          width: size * 0.95,
          height: size * 0.95,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFD32F2F).withValues(alpha: 0.4),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: Container(
              width: size * 0.45,
              height: size * 0.45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD32F2F).withValues(alpha: 0.3), width: 1),
              ),
            ),
          ),
        ),
        // Horizontal & vertical hair lines of crosshair
        Container(width: size * 0.95, height: 1, color: const Color(0xFFD32F2F).withValues(alpha: 0.2)),
        Container(height: size * 0.95, width: 1, color: const Color(0xFFD32F2F).withValues(alpha: 0.2)),
        // Three stacked heavy round black iron cannonballs
        Stack(
          children: [
            // Bottom-left ball
            Positioned(
              left: size * 0.2,
              bottom: size * 0.18,
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                decoration: BoxDecoration(
                  color: const Color(0xFF26282A),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black87, width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 2, offset: Offset(1, 1))],
                ),
              ),
            ),
            // Bottom-right ball
            Positioned(
              right: size * 0.2,
              bottom: size * 0.18,
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                decoration: BoxDecoration(
                  color: const Color(0xFF26282A),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black87, width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 2, offset: Offset(1, 1))],
                ),
              ),
            ),
            // Top center ball
            Positioned(
              left: size * 0.33,
              bottom: size * 0.38,
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                decoration: BoxDecoration(
                  color: const Color(0xFF373A3C),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black87, width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 3, offset: Offset(0, 2))],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSamuraiHelmet(double size) {
    return Positioned(
      top: -size * 0.22, // Sits on top of the head circle
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Red neck flared protection flaps (Shikoro)
          Positioned(
            bottom: -size * 0.05,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Transform.rotate(
                  angle: -0.3,
                  child: Container(
                    width: size * 0.14,
                    height: size * 0.26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB71C1C), // Crimson red
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 1),
                    ),
                  ),
                ),
                SizedBox(width: size * 0.36),
                Transform.rotate(
                  angle: 0.3,
                  child: Container(
                    width: size * 0.14,
                    height: size * 0.26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB71C1C),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main Curved Kabuto Dome Shell
          Container(
            width: size * 0.52,
            height: size * 0.36,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2022), // Dark steel iron
              borderRadius: BorderRadius.vertical(top: Radius.circular(size * 0.26)),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
          ),
          // Gold Crescent moon front crest (Maedate)
          Positioned(
            top: -size * 0.16,
            child: CustomPaint(
              size: Size(size * 0.34, size * 0.22),
              painter: _CrescentCrestPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVampiricTotemIcon(double size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Menacing Red/Vampiric aura shadow rings rising up
        for (int i = 0; i < 4; i++)
          _BobbingAnimation(
            isWalking: false,
            isIdle: true,
            delayFactor: i * 0.2,
            child: Transform.translate(
              offset: Offset((i % 2 == 0 ? 2.0 : -2.0) * 3.0, -size * 0.15 * i),
              child: Container(
                width: size * (0.6 - i * 0.1),
                height: size * 0.1,
                decoration: BoxDecoration(
                  color: const Color(0xFFB71C1C).withValues(alpha: 0.14),
                  borderRadius: const BorderRadius.all(Radius.elliptical(16, 4)),
                ),
              ),
            ),
          ),
        // 2. Tall Wooden Totem Pole
        Container(
          width: size * 0.18,
          height: size * 1.2,
          decoration: BoxDecoration(
            color: const Color(0xFF4E3629), // Dark stained wood
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFF2A1B10), width: 1.5),
          ),
        ),
        // Horizontal warning notches/rivets along the wood
        for (int i = 1; i < 6; i++)
          Positioned(
            top: size * 0.2 * i,
            child: Container(
              width: size * 0.22,
              height: 2,
              color: const Color(0xFF2A1B10),
            ),
          ),
        // 3. Demonic/Menacing Face Mask on top
        Positioned(
          top: -size * 0.1,
          child: Container(
            width: size * 0.48,
            height: size * 0.48,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2022), // Iron gray demon face
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB71C1C), width: 2),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Menacing Red Glowing Eyes
                Positioned(
                  top: size * 0.16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: size * 0.08,
                        height: size * 0.08,
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: size * 0.08,
                        height: size * 0.08,
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Sharp iron side spikes
        Positioned(
          top: size * 0.4,
          child: Row(
            children: [
              Transform.rotate(
                angle: -0.5,
                child: Container(width: size * 0.15, height: 3, color: Colors.grey),
              ),
              SizedBox(width: size * 0.22),
              Transform.rotate(
                angle: 0.5,
                child: Container(width: size * 0.15, height: 3, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPoleWeaponOverlay(double size) {
    double progress = 0.0;
    if (attackCooldown != null) {
      final maxCooldown = (npc.combatStats?.speed ?? 1.2) * 1.2;
      progress = (attackCooldown! / maxCooldown).clamp(0.0, 1.0);
    }

    final bool isAttacking = progress > 0.7;

    // Shaft & Tip definition
    final String nameLower = npc.name.toLowerCase();
    String type = 'pike';
    if (nameLower.contains('halberd')) {
      type = 'halberd';
    } else if (nameLower.contains('mob') || nameLower.contains('villager')) {
      type = 'pitchfork';
    }

    final double thrustDx = isAttacking ? -size * 0.25 : size * 0.28;
    final double thrustDy = isAttacking ? size * 0.18 : -size * 0.15;
    final double thrustAngle = isAttacking ? -1.3 : -0.15;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 70),
      left: thrustDx,
      top: thrustDy,
      child: Transform.rotate(
        angle: thrustAngle,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            // 1. Wooden Shaft (Pole)
            Container(
              width: 2.2,
              height: size * 1.1,
              color: const Color(0xFF5C4033),
            ),
            // 2. Specialized Tip
            Positioned(
              top: -size * 0.25,
              child: _buildPoleTip(type, size),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoleTip(String type, double size) {
    final steelPaint = const Color(0xFF90A4AE);
    final darkOutline = const Color(0xFF37474F);

    if (type == 'halberd') {
      // Halberd head
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Main Spear spike
          Container(
            width: 3.5,
            height: size * 0.25,
            decoration: BoxDecoration(
              color: steelPaint,
              border: Border.all(color: darkOutline, width: 0.5),
            ),
          ),
          // Axe blade on the left
          Positioned(
            left: -size * 0.15,
            bottom: size * 0.05,
            child: Container(
              width: size * 0.15,
              height: size * 0.14,
              decoration: BoxDecoration(
                color: steelPaint,
                border: Border.all(color: darkOutline, width: 0.5),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              ),
            ),
          ),
          // Back hook on the right
          Positioned(
            right: -size * 0.08,
            bottom: size * 0.08,
            child: Transform.rotate(
              angle: 0.5,
              child: Container(
                width: size * 0.08,
                height: 3,
                color: darkOutline,
              ),
            ),
          ),
        ],
      );
    } else if (type == 'pitchfork') {
      // Pitchfork head
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Crossbar
          Container(
            width: size * 0.26,
            height: 2.5,
            color: darkOutline,
          ),
          // Left tine
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: 1.5,
              height: size * 0.16,
              color: steelPaint,
            ),
          ),
          // Middle tine
          Positioned(
            left: size * 0.12,
            bottom: 0,
            child: Container(
              width: 1.5,
              height: size * 0.18,
              color: steelPaint,
            ),
          ),
          // Right tine
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 1.5,
              height: size * 0.16,
              color: steelPaint,
            ),
          ),
        ],
      );
    } else {
      // Straight Pike tip
      return Container(
        width: 4.0,
        height: size * 0.28,
        decoration: BoxDecoration(
          color: steelPaint,
          border: Border.all(color: darkOutline, width: 0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      );
    }
  }

  Widget _buildMusketOverlay(double size) {
    double progress = 0.0;
    if (attackCooldown != null) {
      final maxCooldown = (npc.combatStats?.speed ?? 1.2) * 1.2;
      progress = (attackCooldown! / maxCooldown).clamp(0.0, 1.0);
    }

    final bool isFiring = progress > 0.75;
    final double musketRecoilX = isFiring ? 4.0 : 0.0;

    return Positioned(
      bottom: size * 0.12,
      left: -size * 0.18 + musketRecoilX, // Kickback recoil
      child: Transform.rotate(
        angle: -0.1,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Curved Wood Stock
                    Container(
                      width: size * 0.22,
                      height: 4.5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4E3629), // Darker walnut wood
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(1.5),
                          bottomLeft: Radius.circular(3.5),
                        ),
                      ),
                    ),
                    // Long Steel rifled barrel
                    Container(
                      width: size * 0.44,
                      height: 2.0,
                      color: const Color(0xFF78909C),
                    ),
                  ],
                ),
                // Lockplate mechanism (Flintlock Hammer & Pan)
                Positioned(
                  left: size * 0.18,
                  top: -2.0,
                  child: Container(
                    width: 4.5,
                    height: 3.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF37474F),
                      border: Border.all(color: Colors.black87, width: 0.5),
                      borderRadius: BorderRadius.circular(0.5),
                    ),
                  ),
                ),
                // Brass Trigger guard loop underneath
                Positioned(
                  left: size * 0.14,
                  bottom: -3.0,
                  child: Container(
                    width: 5.0,
                    height: 3.0,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD4AF37), width: 0.8),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2.0)),
                    ),
                  ),
                ),
              ],
            ),
            // Muzzle flash starburst during attack trigger
            if (isFiring)
              Positioned(
                left: -16.0,
                top: -6.0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.amberAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.orangeAccent, blurRadius: 4, spreadRadius: 2)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

  Widget _buildCavalry(double size) {
    double progress = 0.0;
    if (attackCooldown != null) {
      final maxCooldown = (npc.combatStats?.speed ?? 1.0) * 1.2;
      progress = (attackCooldown! / maxCooldown).clamp(0.0, 1.0);
    }
    final bool isAttacking = progress > 0.7;

    final double slashAngle = isAttacking ? 0.8 : -0.15;
    final double slashTranslateX = isAttacking ? -6.0 : 0.0;

    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0.1,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Horse Legs
          Positioned(
            bottom: -size * 0.08,
            left: size * 0.15,
            right: size * 0.15,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 3, height: size * 0.24, color: Colors.black),
                Container(width: 3, height: size * 0.24, color: Colors.black),
                Container(width: 3, height: size * 0.24, color: Colors.black),
                Container(width: 3, height: size * 0.24, color: Colors.black),
              ],
            ),
          ),
          // 2. Horse Tail
          Positioned(
            right: -size * 0.1,
            bottom: size * 0.08,
            child: Transform.rotate(
              angle: 0.3,
              child: Container(
                width: size * 0.12,
                height: size * 0.36,
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
                ),
              ),
            ),
          ),
          // 3. Horse Body
          Container(
            width: size * 0.76,
            height: size * 0.36,
            decoration: BoxDecoration(
              color: const Color(0xFF704214), // Bay brown horse
              borderRadius: BorderRadius.circular(size * 0.1),
            ),
          ),
          // 4. Horse Neck & Head
          Positioned(
            left: -size * 0.08,
            top: -size * 0.16,
            child: Transform.rotate(
              angle: -0.4,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Neck
                  Container(
                    width: size * 0.18,
                    height: size * 0.35,
                    color: const Color(0xFF704214),
                  ),
                  // Mane (Black hair)
                  Positioned(
                    right: 0,
                    top: 2,
                    child: Container(width: 4, height: size * 0.25, color: Colors.black87),
                  ),
                  // Head
                  Positioned(
                    top: -size * 0.08,
                    left: -size * 0.05,
                    child: Container(
                      width: size * 0.24,
                      height: size * 0.16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5C3410),
                        borderRadius: BorderRadius.circular(size * 0.04),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 5. Humanoid Rider sitting on top
          Positioned(
            top: -size * 0.38,
            left: size * 0.15,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Rider Uniform Torso
                Container(
                  width: size * 0.38,
                  height: size * 0.38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D47A1), // Prussian blue coat
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFFD54F), width: 1), // Gold trim
                  ),
                ),
                // Rider Head
                Positioned(
                  top: -size * 0.26,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Head skin
                      Container(
                        width: size * 0.25,
                        height: size * 0.25,
                        decoration: const BoxDecoration(color: Color(0xFFE0C097), shape: BoxShape.circle),
                      ),
                      // Dragoon Helmet
                      Positioned(
                        top: -size * 0.06,
                        child: Container(
                          width: size * 0.28,
                          height: size * 0.16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF90A4AE), // Steel dragoon helm
                            borderRadius: BorderRadius.vertical(top: Radius.circular(size * 0.1)),
                          ),
                        ),
                      ),
                      // Red Helmet plume plume
                      Positioned(
                        top: -size * 0.16,
                        child: Container(
                          width: 6,
                          height: size * 0.14,
                          color: const Color(0xFFB71C1C),
                        ),
                      ),
                    ],
                  ),
                ),
                // Gleaming Steel Saber weapon in hand!
                if (isCombat)
                  Positioned(
                    left: -size * 0.24 + slashTranslateX,
                    top: size * 0.05,
                    child: Transform.rotate(
                      angle: slashAngle, // Dynamic slashing rotation
                      child: Row(
                        children: [
                          // Gold Hilt
                          Container(width: 3, height: 6, color: const Color(0xFFD4AF37)),
                          // Saber Blade
                          Container(
                            width: size * 0.36,
                            height: 2.2,
                            color: const Color(0xFFCFD8DC),
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
    );
  }
}

class _CrescentCrestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37) // Polished gold
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF5C4308)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(size.width / 2.0, size.height * 1.1, size.width, 0);
    path.quadraticBezierTo(size.width / 2.0, size.height * 0.3, 0, 0);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _BobbingAnimation extends StatefulWidget {
  final Widget child;
  final bool isWalking;
  final bool isIdle;
  final bool isBroken;
  final double delayFactor;

  const _BobbingAnimation({
    required this.child,
    required this.isWalking,
    required this.isIdle,
    this.isBroken = false,
    required this.delayFactor,
  });

  @override
  State<_BobbingAnimation> createState() => _BobbingAnimationState();
}

class _BobbingAnimationState extends State<_BobbingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double bobValue = math.sin(
          (_controller.value + widget.delayFactor) * math.pi * 2,
        );

        double verticalOffset = 0;
        double rotation = 0;

        if (widget.isWalking) {
          verticalOffset = bobValue * 2;
          rotation = bobValue * 0.05;
        } else if (widget.isIdle) {
          verticalOffset = bobValue * 0.5;
        }

        if (widget.isBroken) {
          // Add jitter
          verticalOffset += (math.Random().nextDouble() - 0.5) * 2;
          rotation += (math.Random().nextDouble() - 0.5) * 0.1;
        }

        return Transform.translate(
          offset: Offset(0, verticalOffset),
          child: Transform.rotate(angle: rotation, child: widget.child),
        );
      },
      child: widget.child,
    );
  }
}

class _ClawSlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0).withValues(alpha: 0.85) // Silver-white claw
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    final glowPaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (int i = 0; i < 3; i++) {
      final Path path = Path();
      final double yOffset = i * 8.0;
      path.moveTo(size.width, yOffset);
      path.quadraticBezierTo(size.width * 0.3, size.height * 0.4 + yOffset, 0, size.height * 0.7 + yOffset);

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
