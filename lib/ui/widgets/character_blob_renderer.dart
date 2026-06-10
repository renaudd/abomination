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
  final bool isLiveBattlefield;

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
    this.isLiveBattlefield = false,
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
            else if (npc.name.toLowerCase().contains('ram'))
              _buildBatteringRam(size)
            else if (npc.specimenType == 'Bat' ||
                npc.name.toLowerCase().contains('bat'))
              _buildBat(size)
            else if (npc.specimenType == 'Rat' ||
                npc.specimenType == 'FlyingRat')
              _buildAnimal(npc.specimenType, size, isUndead: npc.name.toLowerCase().contains('undead'))
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
            else if (npc.name.toLowerCase().contains('caltrop'))
              _buildCaltropsIcon(size)
            else if (npc.name.toLowerCase().contains('stampede'))
              _buildStampedeIcon(size)
            else if (npc.name.toLowerCase().contains('gatling'))
              _buildGatlingGun(size)
            else if (npc.name.toLowerCase().contains('zeppelin'))
              _buildZeppelin(size)
            else if (npc.name.toLowerCase().contains('valkyrie'))
              _buildValkyrie(size)
            else if (npc.name.toLowerCase().contains('minotaur'))
              _buildMinotaur(size)
            else if (npc.name.toLowerCase().contains('phoenix'))
              _buildPhoenix(size)
            else if (npc.name.toLowerCase().contains('necromancer'))
              _buildNecromancer(size)
            else if (npc.name.toLowerCase().contains('robot'))
              _buildSteampunkRobot(size)
            else if (npc.name.toLowerCase().contains('mech'))
              _buildHumanPilotedMech(size)
            else if (npc.name.toLowerCase().contains('lightning'))
              _buildLightningStormIcon(size)
            else if (npc.name.toLowerCase().contains('airdrop'))
              _buildAirdropIcon(size)
            else if (npc.name.toLowerCase().contains('divine') || npc.name.toLowerCase().contains('shield'))
              _buildDivineShieldIcon(size)
            else if (npc.name.toLowerCase().contains('napalm'))
              _buildNapalmStrikeIcon(size)
            else if (npc.name.toLowerCase().contains('geometry'))
              _buildSacredGeometryIcon(size)
            else if (npc.name.toLowerCase().contains('behemoth'))
              _buildHomunculusBehemothIcon(size)
            else if (npc.name.toLowerCase().contains('elixir') || npc.name.toLowerCase().contains('vitality'))
              _buildElixirOfVitalityIcon(size)
            else if (npc.name.toLowerCase().contains('greek fire') || npc.name.toLowerCase().contains('grail'))
              _buildGreekFireFlaskIcon(size)
            else if (npc.name.toLowerCase().contains('hypnosis') || npc.name.toLowerCase().contains('pendulum'))
              _buildAstralHypnosisIcon(size)
            else if (npc.name.toLowerCase().contains('cuirassier'))
              _buildRoyalistCuirassierIcon(size)
            else if (npc.name.toLowerCase().contains('beastmaster'))
              _buildForesterBeastmasterIcon(size)
            else if (npc.name.toLowerCase().contains('insurgent'))
              _buildInsurgentCellIcon(size)
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
                    color: _getCustomOutfitColor(npc),
                    borderRadius: BorderRadius.circular(
                      _getBodyRadius(appearance.bodyType, size),
                    ),
                    border: Border.all(color: Colors.black12, width: 0.5),
                  ),
                ),
                offset: Offset(
                  0,
                  size *
                      ((npc.role == 'Coven' ||
                              npc.equippedVisuals.contains('WitchHat') ||
                              npc.equippedVisuals.contains('PlumHat'))
                          ? 0.3
                          : 0.1),
                ),
              ),

              // Head (Circle)
              _buildAnimatedContainer(
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
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
                        color: _getCustomSkinColor(npc),
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
                      _buildSamuraiHelmet(size)
                    else if (npc.name.toLowerCase().contains('sapper'))
                      Container(width: size * 0.35, height: size * 0.15, decoration: BoxDecoration(color: const Color(0xFF37474F), borderRadius: BorderRadius.circular(2)), child: const Icon(Icons.remove_red_eye, color: Colors.amberAccent, size: 8))
                    else if (npc.name.toLowerCase().contains('pyre'))
                      Container(width: size * 0.35, height: size * 0.35, decoration: BoxDecoration(color: const Color(0xFFCFD8DC), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.amber)))
                    else if (npc.name.toLowerCase().contains('thug'))
                      Container(width: size * 0.35, height: size * 0.18, decoration: const BoxDecoration(color: Color(0xFF3E2723), borderRadius: BorderRadius.vertical(top: Radius.circular(8))))
                    else if (npc.name.toLowerCase().contains('captain'))
                      Container(width: size * 0.45, height: size * 0.15, decoration: const BoxDecoration(color: Color(0xFFB71C1C), border: Border(bottom: BorderSide(color: Colors.amber, width: 2))))
                    else if (npc.name.toLowerCase().contains('martyr'))
                      Container(width: size * 0.28, height: size * 0.25, decoration: const BoxDecoration(color: Color(0xFFD32F2F), borderRadius: BorderRadius.only(topLeft: Radius.circular(12))))
                    else if (npc.name.toLowerCase().contains('raider'))
                      Container(width: size * 0.35, height: size * 0.35, decoration: const BoxDecoration(color: Color(0xFF004D40), shape: BoxShape.circle))
                    else if (npc.name.toLowerCase().contains('assassin'))
                      Container(width: size * 0.4, height: size * 0.12, color: Colors.black87)
                    else if (npc.role == 'Coven' ||
                        npc.equippedVisuals.contains('WitchHat') ||
                        npc.equippedVisuals.contains('PlumHat') ||
                        npc.name.toLowerCase().contains('mesmerist'))
                      _buildWitchHat(size, _getHatColor(npc)),
                  ],
                ),
                offset: Offset(
                  0,
                  size *
                      ((npc.role == 'Coven' ||
                              npc.equippedVisuals.contains('WitchHat') ||
                              npc.equippedVisuals.contains('PlumHat'))
                          ? 0.05
                          : -0.15),
                ),
                delayFactor: 0.5,
              ),

              // Gear / Items
              if (npc.specimenType == 'Human')
                ...npc.equippedVisuals.map(
                  (item) => _buildItemBlob(item, size),
                ),

              // Healing Energy Waves Aura (ONLY on live battlefield, NOT on card portraits!)
              if (isLiveBattlefield &&
                  (npc.name.toLowerCase().contains('brewer') ||
                      npc.name.toLowerCase().contains('hag')))
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HealingWavesPainter(
                      progress:
                          (DateTime.now().millisecondsSinceEpoch % 1500) /
                          1500.0,
                    ),
                  ),
                ),

              // Staff Sling (Witch)
              if (isCombat &&
                  (npc.name.toLowerCase().contains('witch') ||
                      npc.equippedVisuals.contains('Sling')))
                _buildStaffSlingOverlay(size),

              // Crossbow (Warlock)
              if (isCombat &&
                  ((npc.name.toLowerCase().contains('warlock') && !npc.name.toLowerCase().contains('mesmerist')) ||
                      npc.equippedVisuals.contains('Crossbow')))
                _buildCrossbowOverlay(size),

              // Pole Weapons (Halberdier, Pikeman, Mob/Villager, Broomstick)
              if (isCombat &&
                  (npc.name.toLowerCase().contains('halberd') ||
                      npc.name.toLowerCase().contains('pike') ||
                      npc.name.toLowerCase().contains('mob') ||
                      npc.name.toLowerCase().contains('villager') ||
                      npc.equippedVisuals.contains('Broom') ||
                      npc.name.toLowerCase().contains('brewer') ||
                      npc.name.toLowerCase().contains('hag')))
                _buildPoleWeaponOverlay(size),

              // Ranged Infantry Muskets / Firearm users
              if (isCombat && _isUsingFirearm(npc))
                _buildMusketOverlay(size),

              // Custom Victorian & Esoteric Weapon Overlays
              if (isCombat && npc.name.toLowerCase().contains('mesmerist'))
                Positioned(top: -size * 0.1, child: Icon(Icons.waves, color: Colors.amberAccent, size: size * 0.5)),
              if (isCombat && npc.name.toLowerCase().contains('sapper'))
                Positioned(left: -size * 0.2, top: size * 0.05, child: Row(children: [Container(width: size * 0.25, height: 8, color: Colors.red), Container(width: 4, height: 4, color: Colors.orange)])),
              if (isCombat && npc.name.toLowerCase().contains('pyre'))
                Positioned(left: -size * 0.25, top: 2, child: Transform.rotate(angle: -0.4, child: Container(width: size * 0.45, height: 6, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.white, Colors.orange, Colors.red]))))),
              if (isCombat && npc.name.toLowerCase().contains('collector'))
                Positioned(left: -size * 0.2, top: size * 0.05, child: Transform.rotate(angle: -0.2, child: Container(width: size * 0.35, height: size * 0.15, color: const Color(0xFF1B5E20)))),
              if (isCombat && npc.name.toLowerCase().contains('arsonist'))
                Positioned(left: -size * 0.25, top: 0, child: Row(children: [Container(width: size * 0.3, height: 3, color: Colors.grey), const Icon(Icons.whatshot, color: Colors.deepOrangeAccent, size: 14)])),
              if (isCombat && npc.name.toLowerCase().contains('raider'))
                Positioned(left: -size * 0.2, top: size * 0.1, child: Row(children: [Container(width: size * 0.2, height: 3, color: Colors.greenAccent), const SizedBox(width: 4), Container(width: size * 0.2, height: 3, color: Colors.greenAccent)])),
              if (isCombat && npc.name.toLowerCase().contains('standard bearer'))
                Positioned(left: -size * 0.25, top: -size * 0.3, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 3, height: size * 0.8, color: Colors.amber), Container(width: size * 0.35, height: size * 0.25, color: Colors.blue.shade900)])),
              if (isCombat && npc.name.toLowerCase().contains('herbalist'))
                Positioned(right: -2, top: size * 0.1, child: Container(width: size * 0.2, height: size * 0.2, decoration: BoxDecoration(color: Colors.lightGreen, borderRadius: BorderRadius.circular(4)))),
              if (isCombat && npc.name.toLowerCase().contains('thug'))
                Positioned(left: -size * 0.2, top: size * 0.05, child: Transform.rotate(angle: -0.3, child: Container(width: size * 0.35, height: 5, color: const Color(0xFF3E2723)))),
              if (isCombat && npc.name.toLowerCase().contains('captain'))
                Positioned(left: -size * 0.25, top: size * 0.05, child: Row(children: [Container(width: 4, height: 8, color: Colors.amber), Container(width: size * 0.35, height: 2.5, color: Colors.white)])),
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
          child: _buildAnimal(npc.specimenType, size * 0.5, isUndead: npc.name.toLowerCase().contains('undead')),
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

  Widget _buildAnimal(String type, double size, {bool isUndead = false}) {
    if (type == 'Bat') return _buildBat(size);
    if (type == 'Rat') return _buildRat(size, isUndead: isUndead);
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

  Widget _buildRat(double size, {bool isUndead = false}) {
    final bColor = isUndead ? const Color(0xFF6A1B9A) : const Color(0xFF4E342E);
    final accColor = isUndead ? const Color(0xFFC6FF00) : const Color(0xFFF8BBD0);
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0.0,
      child: CustomPaint(
        size: Size(size * 1.2, size * 0.8),
        painter: _RatPainter(bodyColor: bColor, accentColor: accColor),
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
            CustomPaint(
              size: Size(size * 1.2, size * 0.6),
              painter: _PortraitBatWingPainter(color: wingColor),
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

  Color _getHatColor(NPC npc) {
    final nameLower = npc.name.toLowerCase();
    if (nameLower.contains('hag')) return const Color(0xFF5A1827);
    if (nameLower.contains('witch')) return const Color(0xFF616161);
    if (nameLower.contains('warlock') ||
        npc.equippedVisuals.contains('PlumHat')) {
      return const Color(0xFF3B1735);
    }
    return const Color(0xFF111111);
  }

  Widget _buildWitchHat(double size, Color hatColor) {
    return Positioned(
      top: -size * 0.35,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: Size(size * 0.35, size * 0.4),
            painter: _WitchHatConePainter(color: hatColor),
          ),
          Container(
            width: size * 0.7,
            height: size * 0.08,
            decoration: BoxDecoration(
              color: hatColor,
              borderRadius: BorderRadius.all(
                Radius.elliptical(size * 0.35, size * 0.04),
              ),
              border: Border.all(color: Colors.black26, width: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemBlob(String item, double size) {
    if (item == 'WitchHat' ||
        item == 'PlumHat' ||
        item == 'Broom' ||
        item == 'Sling' ||
        item == 'Crossbow') {
      return const SizedBox.shrink();
    }

    IconData iconData = Icons.inventory_2;
    Color itemColor = Colors.blueGrey;
    if (item == 'Broom') {
      iconData = Icons.cleaning_services;
      itemColor = Colors.amber.shade800;
    } else if (item == 'Sling') {
      iconData = Icons.adjust;
      itemColor = Colors.grey.shade600;
    } else if (item == 'Crossbow') {
      iconData = Icons.crisis_alert;
      itemColor = Colors.brown.shade700;
    } else if (item == 'GatlingGun') {
      iconData = Icons.build;
      itemColor = Colors.blueGrey.shade900;
    }

    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0.8, // Distinct orbit
      child: Transform.translate(
        offset: Offset(size * 0.35, size * 0.1),
        child: Container(
          width: size * 0.3,
          height: size * 0.3,
          decoration: BoxDecoration(
            color: itemColor,
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
          child: Center(
            child: Icon(iconData, size: size * 0.18, color: Colors.white70),
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
    double progress = 0.0;
    if (attackCooldown != null) {
      final maxCooldown = (npc.combatStats?.speed ?? 0.8) * 1.2;
      progress = (attackCooldown! / maxCooldown).clamp(0.0, 1.0);
    }
    final bool isSlashing = progress > 0.65;

    return Positioned(
      top: -size * 0.22,
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
                      color: const Color(0xFFB71C1C),
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: const Color(0xFFD4AF37),
                        width: 1,
                      ),
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
                      border: Border.all(
                        color: const Color(0xFFD4AF37),
                        width: 1,
                      ),
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
              color: const Color(0xFF1F2022),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(size * 0.26),
              ),
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
          if (isSlashing)
            Positioned(
              left: -size * 0.6,
              top: size * 0.2,
              child: CustomPaint(
                size: Size(size * 0.7, size * 0.6),
                painter: _SamuraiSlashPainter(),
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
    } else if (nameLower.contains('brewer') ||
        nameLower.contains('hag') ||
        npc.equippedVisuals.contains('Broom')) {
      type = 'broomstick';
    }

    final double thrustDx = isAttacking
        ? -size * 0.25
        : size * (type == 'broomstick' ? 0.22 : 0.28);
    final double thrustDy = isAttacking
        ? size * 0.18
        : -size * (type == 'broomstick' ? 0.05 : 0.15);
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
              height: size * (type == 'broomstick' ? 0.75 : 1.1),
              color: const Color(0xFF5C4033),
            ),
            // 2. Specialized Tip
            Positioned(
              top: -size * (type == 'broomstick' ? 0.15 : 0.25),
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
    } else if (type == 'broomstick') {
      // Broomstick straw bristles head
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Wooden binding collar
          Container(
            width: size * 0.16,
            height: 3.5,
            color: const Color(0xFF3E2723),
          ),
          // Flared Straw Bristles
          Positioned(
            bottom: 3.5,
            child: CustomPaint(
              size: Size(size * 0.28, size * 0.35),
              painter: _BroomBristlesPainter(color: Colors.amber.shade700),
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

  bool _isUsingFirearm(NPC npc) {
    if (npc.name.toLowerCase().contains('witch') ||
        npc.name.toLowerCase().contains('warlock')) {
      return false;
    }
    if (npc.equippedVisuals.contains('Sling') ||
        npc.equippedVisuals.contains('Crossbow')) {
      return false;
    }
    if (npc.combatStats == null) return false;
    if (npc.combatStats!.rangedDamage > 0) return true;
    if (npc.isPlayer &&
        (npc.name.toLowerCase().contains('frankenstein') ||
            npc.id == 'alphonse')) {
      return true;
    }
    return false;
  }

  Widget _buildStaffSlingOverlay(double size) {
    double progress = 0.0;
    if (attackCooldown != null) {
      final maxCooldown = (npc.combatStats?.speed ?? 1.2) * 1.2;
      progress = (attackCooldown! / maxCooldown).clamp(0.0, 1.0);
    }
    final bool isAttacking = progress > 0.7;
    final double thrustDx = isAttacking ? -size * 0.3 : -size * 0.2;
    final double thrustDy = isAttacking ? size * 0.15 : -size * 0.05;
    final double thrustAngle = isAttacking ? -1.0 : -0.15;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 70),
      left: thrustDx,
      top: thrustDy,
      child: Transform.rotate(
        angle: thrustAngle,
        child: CustomPaint(
          size: Size(size * 0.5, size * 1.0),
          painter: _StaffSlingPainter(),
        ),
      ),
    );
  }

  Widget _buildCrossbowOverlay(double size) {
    double progress = 0.0;
    if (attackCooldown != null) {
      final maxCooldown = (npc.combatStats?.speed ?? 1.2) * 1.2;
      progress = (attackCooldown! / maxCooldown).clamp(0.0, 1.0);
    }
    final bool isFiring = progress > 0.75;

    final double posX = isFiring ? -size * 0.35 : -size * 0.17;
    final double posY = isFiring ? size * 0.2 : size * 0.35;
    final double rotAngle = isFiring ? -0.1 : -1.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 70),
      left: posX,
      top: posY,
      child: Transform.rotate(
        angle: rotAngle,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            CustomPaint(
              size: Size(size * 0.7, size * 0.7),
              painter: _CrossbowPainter(),
            ),
            if (isFiring)
              Positioned(
                left: -size * 0.6,
                top: size * 0.32,
                child: Container(
                  width: size * 0.5,
                  height: 3.0,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Colors.amberAccent,
                        Colors.white,
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.amber,
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusketOverlay(double size) {
    double progress = 0.0;
    if (attackCooldown != null) {
      final maxCooldown = (npc.combatStats?.speed ?? 1.2) * 1.2;
      progress = (attackCooldown! / maxCooldown).clamp(0.0, 1.0);
    }

    final bool isFiring = progress > 0.75;
    final double musketRecoilX = isFiring ? 4.0 : 0.0;

    if (isFiring) {
      // Firing State: lateral (horizontal), barrel pointing to the left (away), stock to the right
      return Positioned(
        bottom: size * 0.16,
        left: -size * 0.42 + musketRecoilX,
        child: Transform.rotate(
          angle: -0.05,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerRight,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Long Steel rifled barrel (pointing away / left)
                  Container(
                    width: size * 0.44,
                    height: 2.0,
                    color: const Color(0xFF78909C),
                  ),
                  // Curved Wood Stock (butt)
                  Container(
                    width: size * 0.22,
                    height: 4.5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4E3629),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(1.5),
                        bottomRight: Radius.circular(3.5),
                      ),
                    ),
                  ),
                ],
              ),
              // Lockplate mechanism
              Positioned(
                right: size * 0.12,
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
              // Brass Trigger guard loop
              Positioned(
                right: size * 0.16,
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
              // Muzzle flash starburst
              Positioned(
                left: -6.0,
                top: -5.0,
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
    } else {
      // Rest State: default upright, butt pointing down, barrel pointing to the sky
      return Positioned(
        bottom: size * 0.08,
        left: size * 0.15,
        child: Transform.rotate(
          angle: -0.05, // slightly angled for natural look
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Long Steel rifled barrel pointing UP
              Container(
                width: 2.0,
                height: size * 0.44,
                color: const Color(0xFF78909C),
              ),
              // Wood Stock (butt) pointing down
              Container(
                width: 4.5,
                height: size * 0.22,
                decoration: const BoxDecoration(
                  color: Color(0xFF4E3629),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(1.5),
                    bottomRight: Radius.circular(3.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
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
                Container(width: size * 0.08, height: size * 0.24, color: Colors.black),
                Container(width: size * 0.08, height: size * 0.24, color: Colors.black),
                Container(width: size * 0.08, height: size * 0.24, color: Colors.black),
                Container(width: size * 0.08, height: size * 0.24, color: Colors.black),
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

  Widget _buildCaltropsIcon(double size) {
    return _BobbingAnimation(
      isWalking: false,
      isIdle: isIdle,
      delayFactor: 0.1,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildSingleCaltrop(size * 0.45, Colors.blueGrey.shade700),
            Positioned(
              left: size * 0.1,
              bottom: size * 0.15,
              child: Transform.rotate(
                angle: -0.4,
                child: _buildSingleCaltrop(size * 0.35, Colors.blueGrey.shade900),
              ),
            ),
            Positioned(
              right: size * 0.12,
              top: size * 0.15,
              child: Transform.rotate(
                angle: 0.5,
                child: _buildSingleCaltrop(size * 0.38, const Color(0xFF455A64)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleCaltrop(double s, Color color) {
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: s * 0.18, height: s * 0.9, color: color),
          Transform.rotate(
            angle: 1.047,
            child: Container(width: s * 0.18, height: s * 0.9, color: color),
          ),
          Transform.rotate(
            angle: -1.047,
            child: Container(width: s * 0.18, height: s * 0.9, color: color),
          ),
          Container(
            width: s * 0.3,
            height: s * 0.3,
            decoration: const BoxDecoration(
              color: Colors.white60,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStampedeIcon(double size) {
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0.05,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -size * 0.15,
              top: -size * 0.05,
              child: Transform.scale(
                scale: 0.8,
                child: _buildSingleHorse(size * 0.8, const Color(0xFF4A2810)),
              ),
            ),
            Positioned(
              left: size * 0.05,
              top: size * 0.05,
              child: _buildSingleHorse(size * 0.9, const Color(0xFF8B5A2B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleHorse(double s, Color color) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          bottom: -s * 0.08,
          left: s * 0.15,
          right: s * 0.15,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: s * 0.08, height: s * 0.24, color: Colors.black),
              Container(width: s * 0.08, height: s * 0.24, color: Colors.black),
              Container(width: s * 0.08, height: s * 0.24, color: Colors.black),
              Container(width: s * 0.08, height: s * 0.24, color: Colors.black),
            ],
          ),
        ),
        Positioned(
          right: -s * 0.1,
          bottom: s * 0.08,
          child: Transform.rotate(
            angle: 0.3,
            child: Container(
              width: s * 0.12,
              height: s * 0.36,
              decoration: const BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
            ),
          ),
        ),
        Container(
          width: s * 0.76,
          height: s * 0.36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(s * 0.1),
          ),
        ),
        Positioned(
          left: -s * 0.08,
          top: -s * 0.16,
          child: Transform.rotate(
            angle: -0.4,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(width: s * 0.18, height: s * 0.35, color: color),
                Positioned(right: 0, top: 2, child: Container(width: 4, height: s * 0.25, color: Colors.black87)),
                Positioned(
                  top: -s * 0.08,
                  left: -s * 0.05,
                  child: Container(
                    width: s * 0.24,
                    height: s * 0.16,
                    decoration: BoxDecoration(color: const Color(0xFF3D2008), borderRadius: BorderRadius.circular(s * 0.04)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGatlingGun(double size) {
    return Transform.scale(
      scale: 0.68,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: size * 1.15,
          height: size * 1.15,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size * 0.6,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: const Color(0xFF5D4037),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF3E2723), width: 1.5),
                ),
              ),
            Positioned(
              left: -size * 0.25,
              top: size * 0.28,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: size * 0.45, height: size * 0.05, color: const Color(0xFFB0BEC5)),
                  const SizedBox(height: 2),
                  Container(width: size * 0.5, height: size * 0.06, color: const Color(0xFFCFD8DC)),
                  const SizedBox(height: 2),
                  Container(width: size * 0.45, height: size * 0.05, color: const Color(0xFF90A4AE)),
                ],
              ),
            ),
            Positioned(
              top: size * 0.1,
              child: Container(
                width: size * 0.25,
                height: size * 0.25,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4AF37),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ),
            ),
            Positioned(
              bottom: size * 0.1,
              child: Container(
                width: size * 0.45,
                height: size * 0.45,
                decoration: BoxDecoration(
                  color: const Color(0xFF3E2723),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF8D6E63), width: 4),
                ),
                child: const Center(
                  child: Icon(Icons.radio_button_checked, color: Color(0xFFD7CCC8), size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildZeppelin(double size) {
    return _BobbingAnimation(
      isWalking: false,
      isIdle: isIdle,
      delayFactor: 0.15,
      child: Transform.scale(
        scale: 0.58,
        child: SizedBox(
          width: size,
          height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: size * 0.04,
              child: Container(
                width: size * 0.2,
                height: size * 0.4,
                decoration: const BoxDecoration(
                  color: Color(0xFF455A64),
                  borderRadius: BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                ),
              ),
            ),
            Container(
              width: size * 0.75,
              height: size * 0.45,
              decoration: BoxDecoration(
                color: const Color(0xFFD7CCC8),
                borderRadius: const BorderRadius.all(Radius.elliptical(45, 25)),
                border: Border.all(color: const Color(0xFF5D4037), width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 4)),
                ],
              ),
            ),
            Positioned(
              bottom: size * 0.1,
              child: Container(
                width: size * 0.4,
                height: size * 0.15,
                decoration: BoxDecoration(
                  color: const Color(0xFF3E2723),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF8D6E63), width: 1),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Icon(Icons.circle, color: Colors.amberAccent, size: 4),
                    Icon(Icons.circle, color: Colors.amberAccent, size: 4),
                    Icon(Icons.circle, color: Colors.amberAccent, size: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildValkyrie(double size) {
    return _BobbingAnimation(
      isWalking: false,
      isIdle: isIdle,
      delayFactor: 0.1,
      child: Transform.scale(
        scale: 0.58,
        child: SizedBox(
          width: size,
          height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: size * 0.04,
              child: Transform.rotate(
                angle: -0.4,
                child: Container(
                  width: size * 0.35,
                  height: size * 0.6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(8)),
                  ),
                ),
              ),
            ),
            Positioned(
              right: size * 0.04,
              child: Transform.rotate(
                angle: 0.4,
                child: Container(
                  width: size * 0.35,
                  height: size * 0.6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(8)),
                  ),
                ),
              ),
            ),
            Container(
              width: size * 0.45,
              height: size * 0.6,
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFB7950B), width: 1.5),
              ),
            ),
            Positioned(
              top: size * 0.05,
              child: Container(
                width: size * 0.3,
                height: size * 0.25,
                decoration: const BoxDecoration(
                  color: Color(0xFFBDC3C7),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: size * 0.05,
              child: Container(width: 3, height: size * 0.8, color: const Color(0xFFECF0F1)),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildMinotaur(double size) {
    return Transform.scale(
      scale: 0.58,
      child: SizedBox(
        width: size,
        height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size * 0.65,
            height: size * 0.75,
            decoration: BoxDecoration(
              color: const Color(0xFF3E2723),
              borderRadius: BorderRadius.circular(size * 0.2),
              border: Border.all(color: const Color(0xFF212121), width: 2),
            ),
          ),
          Positioned(
            top: -size * 0.05,
            left: size * 0.08,
            child: Transform.rotate(
              angle: -0.6,
              child: Container(
                width: size * 0.15,
                height: size * 0.35,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12)),
                ),
              ),
            ),
          ),
          Positioned(
            top: -size * 0.05,
            right: size * 0.08,
            child: Transform.rotate(
              angle: 0.6,
              child: Container(
                width: size * 0.15,
                height: size * 0.35,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.only(topRight: Radius.circular(12)),
                ),
              ),
            ),
          ),
          Positioned(
            top: size * 0.15,
            child: Container(
              width: size * 0.35,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: const Color(0xFF4E342E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.circle, color: Colors.redAccent, size: 6),
                  Icon(Icons.circle, color: Colors.redAccent, size: 6),
                ],
              ),
            ),
          ),
          Positioned(
            right: size * 0.05,
            child: Container(width: 6, height: size * 0.85, color: const Color(0xFF757575)),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildPhoenix(double size) {
    return _BobbingAnimation(
      isWalking: false,
      isIdle: isIdle,
      delayFactor: 0.05,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size * 0.95,
              height: size * 0.65,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0xFFFFFF00), Color(0xFFFF3D00), Color(0xFFD50000)],
                ),
                borderRadius: BorderRadius.all(Radius.elliptical(45, 20)),
                boxShadow: [
                  BoxShadow(color: Colors.deepOrangeAccent, blurRadius: 10, spreadRadius: 4),
                ],
              ),
            ),
            const Positioned(
              top: -4,
              child: Icon(Icons.local_fire_department, color: Colors.amberAccent, size: 36),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNecromancer(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size * 0.55,
            height: size * 0.75,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1120),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.shade900, width: 1.5),
            ),
          ),
          Positioned(
            top: size * 0.15,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.greenAccent, size: 5),
                SizedBox(width: 8),
                Icon(Icons.circle, color: Colors.greenAccent, size: 5),
              ],
            ),
          ),
          Positioned(
            left: -size * 0.1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.greenAccent, size: 18),
                Container(width: 3, height: size * 0.75, color: const Color(0xFFD7CCC8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteringRam(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size * 0.85,
            height: size * 0.55,
            decoration: BoxDecoration(
              color: const Color(0xFF4E342E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF212121), width: 2),
            ),
          ),
          Positioned(
            left: -size * 0.15,
            top: size * 0.25,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: size * 0.25,
                  height: size * 0.18,
                  decoration: const BoxDecoration(
                    color: Color(0xFF37474F),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                  ),
                ),
                Container(width: size * 0.65, height: size * 0.14, color: const Color(0xFF795548)),
              ],
            ),
          ),
          Positioned(
            bottom: size * 0.05,
            left: size * 0.1,
            child: const Icon(Icons.radio_button_checked, color: Colors.black87, size: 20),
          ),
          Positioned(
            bottom: size * 0.05,
            right: size * 0.1,
            child: const Icon(Icons.radio_button_checked, color: Colors.black87, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSteampunkRobot(double size) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: size * 1.15,
        height: size * 1.15,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -size * 0.15,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: size * 0.2, color: const Color(0xFFD84315)),
                  const SizedBox(width: 12),
                  Container(width: 8, height: size * 0.2, color: const Color(0xFFD84315)),
                ],
              ),
            ),
            Container(
              width: size * 0.75,
              height: size * 0.8,
              decoration: BoxDecoration(
                color: const Color(0xFF37474F),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFB0BEC5), width: 2),
              ),
            ),
            Positioned(
              top: size * 0.25,
              child: Container(
                width: size * 0.4,
                height: size * 0.25,
                decoration: BoxDecoration(
                  color: Colors.deepOrangeAccent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black87, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.grid_on, color: Colors.black87, size: 16),
                ),
              ),
            ),
            Positioned(
              left: -size * 0.1,
              top: size * 0.3,
              child: Container(width: size * 0.2, height: size * 0.25, color: const Color(0xFF455A64)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHumanPilotedMech(double size) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: size * 1.15,
        height: size * 1.15,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: size * 0.15, height: size * 0.45, color: const Color(0xFF455A64)),
                  SizedBox(width: size * 0.25),
                  Container(width: size * 0.15, height: size * 0.45, color: const Color(0xFF37474F)),
                ],
              ),
            ),
            Positioned(
              bottom: size * 0.35,
              child: Container(
                width: size * 0.75,
                height: size * 0.45,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF5D4037), width: 2),
                ),
              ),
            ),
            Positioned(
              top: size * 0.05,
              child: Container(
                width: size * 0.35,
                height: size * 0.45,
                decoration: BoxDecoration(
                  color: const Color(0xFF8D6E63),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Container(
                      width: size * 0.22,
                      height: size * 0.22,
                      decoration: const BoxDecoration(color: Color(0xFFFFCCBC), shape: BoxShape.circle),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: size * 0.1,
              top: size * 0.3,
              child: Transform.rotate(
                angle: -0.4,
                child: Container(width: 4, height: size * 0.35, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLightningStormIcon(double size) {
    return _BobbingAnimation(
      isWalking: false,
      isIdle: isIdle,
      delayFactor: 0.1,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size * 0.9,
              height: size * 0.6,
              decoration: BoxDecoration(
                color: const Color(0xFF263238),
                borderRadius: BorderRadius.circular(size * 0.3),
                border: Border.all(color: Colors.blueGrey.shade700, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.cyanAccent, blurRadius: 10, spreadRadius: 2),
                ],
              ),
            ),
            Positioned(
              bottom: -size * 0.2,
              child: const Icon(Icons.bolt, color: Colors.yellowAccent, size: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAirdropIcon(double size) {
    return _BobbingAnimation(
      isWalking: false,
      isIdle: isIdle,
      delayFactor: 0.2,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -size * 0.1,
              child: Container(
                width: size * 0.8,
                height: size * 0.35,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5DC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
              ),
            ),
            Container(width: 1.5, height: size * 0.4, color: Colors.white70),
            Positioned(
              bottom: size * 0.05,
              child: Container(
                width: size * 0.5,
                height: size * 0.4,
                decoration: BoxDecoration(
                  color: const Color(0xFF5D4037),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF3E2723), width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.add, color: Colors.redAccent, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivineShieldIcon(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.95,
            height: size * 0.95,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber.withValues(alpha: 0.35),
              border: Border.all(color: Colors.yellowAccent, width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.amberAccent, blurRadius: 12, spreadRadius: 4),
              ],
            ),
          ),
          const Icon(Icons.shield, color: Colors.white, size: 28),
        ],
      ),
    );
  }

  Widget _buildNapalmStrikeIcon(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size * 0.9,
            height: size * 0.75,
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFFF6D00), Color(0xFFB71C1C), Color(0xFF212121)],
              ),
              borderRadius: BorderRadius.circular(size * 0.35),
              boxShadow: const [
                BoxShadow(color: Colors.redAccent, blurRadius: 15, spreadRadius: 6),
              ],
            ),
          ),
          const Icon(Icons.whatshot, color: Colors.amberAccent, size: 36),
        ],
      ),
    );
  }

  // ============================================================================
  // DISTINCT REALISTIC GRAPHICAL MODELS & CUSTOM UNIFORM HELPERS
  // ============================================================================

  Color _getCustomOutfitColor(NPC npc) {
    final lower = npc.name.toLowerCase();
    if (lower.contains('mesmerist')) return const Color(0xFF4A148C); // Deep royal mystical purple
    if (lower.contains('sapper')) return const Color(0xFF546E7A); // Demolition stone grey
    if (lower.contains('pyre')) return const Color(0xFFB71C1C); // Templar pyre crimson
    if (lower.contains('assassin')) return const Color(0xFF1E1E1E); // Sleek midnight black
    if (lower.contains('collector')) return const Color(0xFF3E2723); // Pinstripe banker brown
    if (lower.contains('arsonist')) return const Color(0xFF212121); // Charcoal blackened leather
    if (lower.contains('martyr')) return const Color(0xFFD32F2F); // Revolutionary bright crimson
    if (lower.contains('raider')) return const Color(0xFF004D40); // Emerald raider green
    if (lower.contains('standard bearer')) return const Color(0xFFF5F5F5); // Royal ceremonial white
    if (lower.contains('herbalist')) return const Color(0xFF33691E); // Moss druidic green
    if (lower.contains('thug')) return const Color(0xFF5D4037); // Plaid suit vest brown
    if (lower.contains('captain')) return const Color(0xFFC62828); // Flamboyant officer red
    return npc.appearance.outfitColor;
  }

  Color _getCustomSkinColor(NPC npc) {
    if (npc.name.toLowerCase().contains('behemoth')) return const Color(0xFFC8E6C9); // Sickly toxic pale green
    return npc.appearance.bodyColor;
  }

  // Pure non-humanoid or mounted/beast specialized high-fidelity renderers:

  Widget _buildRoyalistCuirassierIcon(double size) {
    // Custom gleaming white horse with polished silver Cuirass armor and royal blue plumes!
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0.1,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // White Horse Legs
          Positioned(
            bottom: -size * 0.08, left: size * 0.15, right: size * 0.15,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: size * 0.08, height: size * 0.24, color: const Color(0xFFB0BEC5)),
                Container(width: size * 0.08, height: size * 0.24, color: const Color(0xFFB0BEC5)),
                Container(width: size * 0.08, height: size * 0.24, color: const Color(0xFFB0BEC5)),
                Container(width: size * 0.08, height: size * 0.24, color: const Color(0xFFB0BEC5)),
              ],
            ),
          ),
          // White Horse Tail
          Positioned(
            right: -size * 0.1, bottom: size * 0.08,
            child: Transform.rotate(angle: 0.3, child: Container(width: size * 0.12, height: size * 0.36, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(4))))),
          ),
          // White Horse Body
          Container(width: size * 0.76, height: size * 0.36, decoration: BoxDecoration(color: const Color(0xFFECEFF1), borderRadius: BorderRadius.circular(size * 0.1), border: Border.all(color: const Color(0xFFCFD8DC)))),
          // Horse Neck & Head
          Positioned(
            left: -size * 0.08, top: -size * 0.16,
            child: Transform.rotate(
              angle: -0.4,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(width: size * 0.18, height: size * 0.35, color: const Color(0xFFECEFF1)),
                  Positioned(right: 0, top: 2, child: Container(width: 4, height: size * 0.25, color: Colors.white70)),
                  Positioned(top: -size * 0.08, left: -size * 0.05, child: Container(width: size * 0.24, height: size * 0.16, decoration: BoxDecoration(color: const Color(0xFFCFD8DC), borderRadius: BorderRadius.circular(size * 0.04)))),
                ],
              ),
            ),
          ),
          // Cuirassier Rider in Gleaming Silver Breastplate
          Positioned(
            top: -size * 0.38, left: size * 0.15,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Silver Cuirass Torso
                Container(width: size * 0.38, height: size * 0.38, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFB0BEC5)]), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFFFD54F), width: 1.5))),
                // Rider Head with Golden Helm & Royal Blue Plume
                Positioned(
                  top: -size * 0.26,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(width: size * 0.25, height: size * 0.25, decoration: const BoxDecoration(color: Color(0xFFE0C097), shape: BoxShape.circle)),
                      Positioned(top: -size * 0.06, child: Container(width: size * 0.28, height: size * 0.16, decoration: const BoxDecoration(color: Color(0xFFFFD54F), borderRadius: BorderRadius.vertical(top: Radius.circular(8))))),
                      Positioned(top: -size * 0.16, child: Container(width: 6, height: size * 0.14, color: const Color(0xFF0D47A1))),
                    ],
                  ),
                ),
                // Heavy Straight Cavalry Sabre
                if (isCombat) Positioned(left: -size * 0.24, top: size * 0.05, child: Row(children: [Container(width: 4, height: 8, color: const Color(0xFFFFD54F)), Container(width: size * 0.4, height: 2.5, color: Colors.white)])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForesterBeastmasterIcon(double size) {
    // Companion bear walking side-by-side with a fur-cloaked warden
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0.15,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Grizzly Bear Companion
          Container(
            width: size * 0.5, height: size * 0.4,
            decoration: BoxDecoration(color: const Color(0xFF3E2723), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF1B5E20))),
            child: Align(alignment: Alignment.bottomRight, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle))),
          ),
          const SizedBox(width: 2),
          // Warden
          Container(
            width: size * 0.35, height: size * 0.65,
            decoration: BoxDecoration(color: const Color(0xFF1B5E20), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF8D6E63), width: 1.5)),
            child: Align(alignment: Alignment.topCenter, child: Container(width: size * 0.2, height: size * 0.2, decoration: const BoxDecoration(color: Color(0xFFD7CCC8), shape: BoxShape.circle))),
          ),
        ],
      ),
    );
  }

  Widget _buildInsurgentCellIcon(double size) {
    // Trio of marching guerillas in tweed coats beneath an Irish flag
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0.2,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(width: size * 0.25, height: size * 0.5, decoration: BoxDecoration(color: const Color(0xFF4E342E), borderRadius: BorderRadius.circular(2))), const SizedBox(width: 2),
              Container(width: size * 0.25, height: size * 0.55, decoration: BoxDecoration(color: const Color(0xFF3E2723), borderRadius: BorderRadius.circular(2))), const SizedBox(width: 2),
              Container(width: size * 0.25, height: size * 0.48, decoration: BoxDecoration(color: const Color(0xFF5D4037), borderRadius: BorderRadius.circular(2))),
            ],
          ),
          Positioned(
            top: -size * 0.3, left: size * 0.1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 2, height: size * 0.8, color: const Color(0xFFD7CCC8)),
                Container(width: size * 0.4, height: size * 0.25, decoration: BoxDecoration(color: const Color(0xFF00C853), border: Border.all(color: const Color(0xFFFFD54F)))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomunculusBehemothIcon(double size) {
    // Colossal animated flesh titan with purple iron cross-staples and toxic green vapors
    return _BobbingAnimation(
      isWalking: isWalking,
      isIdle: isIdle,
      delayFactor: 0.3,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Bloated Green Torso
          Container(
            width: size * 0.85, height: size * 0.85,
            decoration: BoxDecoration(color: const Color(0xFFC8E6C9), borderRadius: BorderRadius.circular(size * 0.3), border: Border.all(color: const Color(0xFF1B5E20), width: 2), boxShadow: const [BoxShadow(color: Colors.greenAccent, blurRadius: 8)]),
          ),
          // Massive Dark Iron Cross-Staples
          Positioned(top: size * 0.25, child: Container(width: size * 0.65, height: 4, color: const Color(0xFF311B92))),
          Positioned(top: size * 0.5, child: Container(width: size * 0.65, height: 4, color: const Color(0xFF311B92))),
          Positioned(left: size * 0.25, child: Container(width: 4, height: size * 0.65, color: const Color(0xFF311B92))),
          // Titan Tiny Pale Head
          Positioned(top: -size * 0.15, child: Container(width: size * 0.3, height: size * 0.3, decoration: BoxDecoration(color: const Color(0xFFA5D6A7), shape: BoxShape.circle, border: Border.all(color: Colors.black)))),
        ],
      ),
    );
  }

  Widget _buildSacredGeometryIcon(double size) => SizedBox(
    width: size, height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(decoration: BoxDecoration(color: const Color(0xFF00332C), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF00E676)))),
        // Grid lines
        Positioned.fill(child: Opacity(opacity: 0.2, child: CustomPaint(painter: _GridPainter()))),
        // Glowing Square & Compass
        Transform.rotate(angle: math.pi / 4, child: Container(width: size * 0.55, height: size * 0.55, decoration: BoxDecoration(border: Border.all(color: const Color(0xFFFFD54F), width: 2.5), boxShadow: const [BoxShadow(color: Colors.amberAccent, blurRadius: 6)]))),
      ],
    ),
  );

  Widget _buildElixirOfVitalityIcon(double size) => SizedBox(
    width: size, height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(bottom: 2, child: Container(width: size * 0.7, height: 6, color: const Color(0xFFD4AF37))),
        Container(
          width: size * 0.65, height: size * 0.75,
          decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFF00C853), Color(0xFFB9F6CA)]), borderRadius: BorderRadius.circular(size * 0.3), border: Border.all(color: const Color(0xFF81C784), width: 2), boxShadow: const [BoxShadow(color: Colors.greenAccent, blurRadius: 10, spreadRadius: 2)]),
        ),
      ],
    ),
  );

  Widget _buildGreekFireFlaskIcon(double size) => SizedBox(
    width: size, height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        // Bronze Amphora
        Container(width: size * 0.55, height: size * 0.75, decoration: BoxDecoration(color: const Color(0xFF8D6E63), borderRadius: BorderRadius.circular(size * 0.25), border: Border.all(color: const Color(0xFF3E2723), width: 2))),
        // Unquenchable Liquid Fire engulfing the base
        Positioned(bottom: -4, child: Container(width: size * 0.85, height: size * 0.4, decoration: const BoxDecoration(gradient: RadialGradient(colors: [Color(0xFFFF6D00), Color(0xFFDD2C00)]), borderRadius: BorderRadius.all(Radius.circular(8)), boxShadow: [BoxShadow(color: Colors.deepOrange, blurRadius: 8)]))),
      ],
    ),
  );

  Widget _buildAstralHypnosisIcon(double size) => _BobbingAnimation(
    isWalking: false, isIdle: false, delayFactor: 0.1,
    child: SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFAA00FF), width: 2), boxShadow: const [BoxShadow(color: Colors.purpleAccent, blurRadius: 12)])),
          // Swinging Violet Pendulum Bob
          Container(width: size * 0.45, height: size * 0.45, decoration: const BoxDecoration(gradient: RadialGradient(colors: [Colors.white, Color(0xFFD500F9)]), shape: BoxShape.circle)),
        ],
      ),
    ),
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.cyanAccent..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 6) canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += 6) canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
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

class _SamuraiSlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    final glowPaint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final Path path = Path();
    path.moveTo(size.width, 12.0);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.4 + 12.0,
      0,
      size.height * 0.7 + 12.0,
    );

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _PortraitBatWingPainter extends CustomPainter {
  final Color color;
  _PortraitBatWingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final ribPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final center = Offset(size.width / 2, size.height / 2);
    final double w = size.width * 0.45;
    final double h = size.height * 0.8;

    canvas.save();
    canvas.translate(center.dx - 2, center.dy);
    final left = Path()
      ..moveTo(0, 0)
      ..lineTo(-w * 0.3, -h * 0.7) // Top claw
      ..lineTo(-w * 0.9, -h * 0.8) // Thumb tip
      ..quadraticBezierTo(-w * 0.7, -h * 0.2, -w, h * 0.6) // Pointy outer rib tip
      ..quadraticBezierTo(-w * 0.7, h * 0.1, -w * 0.6, h * 0.7) // Scallop 1 to Pointy rib 2
      ..quadraticBezierTo(-w * 0.35, h * 0.2, -w * 0.3, h * 0.6) // Scallop 2 to Pointy rib 3
      ..quadraticBezierTo(-w * 0.15, h * 0.2, 0, h * 0.2) // Scallop 3 back to body
      ..close();
    canvas.drawPath(left, paint);
    canvas.drawLine(Offset(-w * 0.3, -h * 0.7), Offset(-w, h * 0.6), ribPaint);
    canvas.drawLine(Offset(-w * 0.3, -h * 0.7), Offset(-w * 0.6, h * 0.7), ribPaint);
    canvas.drawLine(Offset(-w * 0.3, -h * 0.7), Offset(-w * 0.3, h * 0.6), ribPaint);
    canvas.restore();

    canvas.save();
    canvas.translate(center.dx + 2, center.dy);
    final right = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.3, -h * 0.7)
      ..lineTo(w * 0.9, -h * 0.8)
      ..quadraticBezierTo(w * 0.7, -h * 0.2, w, h * 0.6)
      ..quadraticBezierTo(w * 0.7, h * 0.1, w * 0.6, h * 0.7)
      ..quadraticBezierTo(w * 0.35, h * 0.2, w * 0.3, h * 0.6)
      ..quadraticBezierTo(w * 0.15, h * 0.2, 0, h * 0.2)
      ..close();
    canvas.drawPath(right, paint);
    canvas.drawLine(Offset(w * 0.3, -h * 0.7), Offset(w, h * 0.6), ribPaint);
    canvas.drawLine(Offset(w * 0.3, -h * 0.7), Offset(w * 0.6, h * 0.7), ribPaint);
    canvas.drawLine(Offset(w * 0.3, -h * 0.7), Offset(w * 0.3, h * 0.6), ribPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PortraitBatWingPainter oldDelegate) => false;
}

class _WitchHatConePainter extends CustomPainter {
  final Color color;
  _WitchHatConePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0) // Pointy top
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WitchHatConePainter oldDelegate) => false;
}

class _BroomBristlesPainter extends CustomPainter {
  final Color color;
  _BroomBristlesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * 0.35, size.height)
      ..lineTo(size.width * 0.65, size.height)
      ..lineTo(size.width * 1.1, -size.height * 0.2) // Prominently flared sweeping straw brush
      ..quadraticBezierTo(
        size.width * 0.5,
        -size.height * 0.35,
        -size.width * 0.1,
        -size.height * 0.2,
      )
      ..close();
    canvas.drawPath(path, paint);

    // Gorgeous straw texture lines
    final linePaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(size.width * 0.45, size.height),
      Offset(size.width * 0.1, -size.height * 0.1),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height),
      Offset(size.width * 0.5, -size.height * 0.2),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.55, size.height),
      Offset(size.width * 0.9, -size.height * 0.1),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BroomBristlesPainter oldDelegate) => false;
}

class _StaffSlingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Upright polished oak staff
    final staffPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.5, size.height),
      Offset(size.width * 0.5, size.height * 0.2),
      staffPaint,
    );

    // Leather draw cords hanging from staff tip
    final cordPaint = Paint()
      ..color = const Color(0xFFBCAAA4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.3, size.height * 0.25),
        width: size.width * 0.5,
        height: size.height * 0.15,
      ),
      0,
      math.pi,
      false,
      cordPaint,
    );

    // Leather sling pouch
    final pouchPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.3, size.height * 0.32),
        width: size.width * 0.35,
        height: size.height * 0.1,
      ),
      pouchPaint,
    );

    // Loaded glowing stone projectile inside pouch
    final bulletPaint = Paint()..color = const Color(0xFFCFD8DC);
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.3),
      size.width * 0.08,
      bulletPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StaffSlingPainter oldDelegate) => false;
}

class _CrossbowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Horizontal Mahogany Tiller / Stock
    final stockPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.5),
      Offset(size.width * 0.9, size.height * 0.5),
      stockPaint,
    );

    // Arched Steel Prod mounted horizontally across front
    final prodPaint = Paint()
      ..color = const Color(0xFF90A4AE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    final prodPath = Path()
      ..moveTo(size.width * 0.25, size.height * 0.05)
      ..quadraticBezierTo(
        size.width * 0.05,
        size.height * 0.5,
        size.width * 0.25,
        size.height * 0.95,
      );
    canvas.drawPath(prodPath, prodPaint);

    // Taut Bowstring
    final stringPaint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.05),
      Offset(size.width * 0.55, size.height * 0.5),
      stringPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.95),
      Offset(size.width * 0.55, size.height * 0.5),
      stringPaint,
    );

    // Loaded Silver/Amber Bolt
    final boltPaint = Paint()
      ..color = Colors.amberAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.1, size.height * 0.5),
      boltPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CrossbowPainter oldDelegate) => false;
}

class _HealingWavesPainter extends CustomPainter {
  final double progress;
  _HealingWavesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.9;

    // Primary expanding wave ring
    final paint1 = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: (1.0 - progress) * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, maxRadius * progress, paint1);

    // Secondary inner trailing wave ring
    final progress2 = (progress + 0.5) % 1.0;
    final paint2 = Paint()
      ..color = const Color(0xFFB9F6CA).withValues(alpha: (1.0 - progress2) * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;
    canvas.drawCircle(center, maxRadius * progress2, paint2);
  }

  @override
  bool shouldRepaint(covariant _HealingWavesPainter oldDelegate) => true;
}

class _RatPainter extends CustomPainter {
  final Color bodyColor;
  final Color accentColor;
  _RatPainter({required this.bodyColor, this.accentColor = const Color(0xFFF8BBD0)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = bodyColor
          ..style = PaintingStyle.fill;

    // Arched hunched rat body
    final path =
        Path()
          ..moveTo(size.width * 0.1, size.height * 0.75) // Snout tip
          ..quadraticBezierTo(
            size.width * 0.2,
            size.height * 0.35,
            size.width * 0.55,
            size.height * 0.35,
          ) // Arched back
          ..quadraticBezierTo(
            size.width * 0.85,
            size.height * 0.45,
            size.width * 0.85,
            size.height * 0.8,
          ) // Rump
          ..lineTo(size.width * 0.2, size.height * 0.8) // Belly
          ..close();
    canvas.drawPath(path, paint);

    // Ear
    final earPaint = Paint()..color = accentColor;
    canvas.drawCircle(
      Offset(size.width * 0.32, size.height * 0.38),
      size.width * 0.1,
      earPaint,
    );
    final innerEar = Paint()..color = accentColor == const Color(0xFFF8BBD0) ? const Color(0xFFF06292) : accentColor.withValues(alpha: 0.8);
    canvas.drawCircle(
      Offset(size.width * 0.32, size.height * 0.38),
      size.width * 0.06,
      innerEar,
    );

    // Beady Black Eye & Red Glint
    final eyePaint = Paint()..color = Colors.black;
    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.55),
      size.width * 0.035,
      eyePaint,
    );
    final glint = Paint()..color = Colors.redAccent;
    canvas.drawCircle(
      Offset(size.width * 0.21, size.height * 0.54),
      size.width * 0.015,
      glint,
    );

    // Whiskers
    final whiskerPaint =
        Paint()
          ..color = Colors.black45
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.7),
      Offset(0, size.height * 0.65),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.72),
      Offset(0, size.height * 0.72),
      whiskerPaint,
    );

    // Elegant Wavy Tail
    final tailPaint =
        Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = size.width * 0.05;
    final tailPath =
        Path()
          ..moveTo(size.width * 0.82, size.height * 0.75)
          ..quadraticBezierTo(
            size.width * 1.05,
            size.height * 0.6,
            size.width * 1.15,
            size.height * 0.85,
          );
    canvas.drawPath(tailPath, tailPaint);

    // Little Paws
    final pawPaint = Paint()..color = const Color(0xFFB0BEC5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.3, size.height * 0.82),
        width: size.width * 0.08,
        height: size.height * 0.06,
      ),
      pawPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.7, size.height * 0.82),
        width: size.width * 0.1,
        height: size.height * 0.06,
      ),
      pawPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RatPainter oldDelegate) => false;
}


