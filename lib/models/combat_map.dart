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

class CombatMap {
  final String name;
  final double width;
  final double height;
  final List<double> laneCenters;
  final List<Rect> walls;
  final List<Offset> cauldronPositions;
  final double playerCornerTowerX;
  final double playerCentralTowerX;
  final double enemyCornerTowerX;
  final double enemyCentralTowerX;

  const CombatMap({
    required this.name,
    required this.width,
    required this.height,
    required this.laneCenters,
    required this.walls,
    required this.cauldronPositions,
    required this.playerCornerTowerX,
    required this.playerCentralTowerX,
    required this.enemyCornerTowerX,
    required this.enemyCentralTowerX,
  });

  CombatMapSize get sizeCategory {
    final area = width * height;
    if (area < 30000) {
      return CombatMapSize.small;
    } else if (area < 65000) {
      return CombatMapSize.medium;
    } else {
      return CombatMapSize.colossal;
    }
  }

  String get sizeDescription {
    switch (sizeCategory) {
      case CombatMapSize.small:
        return 'Small Skirmish (${width.toInt()}x${height.toInt()})';
      case CombatMapSize.medium:
        return 'Medium Tactical (${width.toInt()}x${height.toInt()})';
      case CombatMapSize.colossal:
        return 'Colossal Grand (${width.toInt()}x${height.toInt()})';
    }
  }

  /// Whether this battlefield is particularly short (such as Saint Gotthard Ravine or width under 300).
  bool get isParticularlyShort => width < 300.0 || sizeCategory == CombatMapSize.small;

  /// The percentage ratio defining the home back field (25% on short maps, 20% on normal/large maps).
  double get backFieldRatio => isParticularlyShort ? 0.25 : 0.20;

  /// The player's back field summoning boundary (X coordinate).
  double get playerBackFieldLimit => width * backFieldRatio;

  /// The opponent's back field summoning boundary (X coordinate).
  double get enemyBackFieldLimit => width * (1.0 - backFieldRatio);

  static List<CombatMap> get allMaps => [
    const CombatMap(
      name: 'Alpine Pass (Default)',
      width: 300.0,
      height: 140.0,
      laneCenters: [30.0, 110.0],
      walls: [
        Rect.fromLTRB(70.0, 40.0, 90.0, 100.0),
        Rect.fromLTRB(140.0, 40.0, 160.0, 100.0),
        Rect.fromLTRB(210.0, 40.0, 230.0, 100.0),
      ],
      cauldronPositions: [
        Offset(20.0, 50.0),
        Offset(20.0, 90.0),
        Offset(280.0, 50.0),
        Offset(280.0, 90.0),
      ],
      playerCornerTowerX: 35.0,
      playerCentralTowerX: 10.0,
      enemyCornerTowerX: 265.0,
      enemyCentralTowerX: 290.0,
    ),
    const CombatMap(
      name: 'Saint Gotthard Ravine',
      width: 180.0,
      height: 90.0,
      laneCenters: [20.0, 70.0],
      walls: [
        Rect.fromLTRB(45.0, 25.0, 60.0, 65.0),
        Rect.fromLTRB(90.0, 25.0, 105.0, 65.0),
        Rect.fromLTRB(135.0, 25.0, 150.0, 65.0),
      ],
      cauldronPositions: [
        Offset(10.0, 30.0),
        Offset(10.0, 60.0),
        Offset(170.0, 30.0),
        Offset(170.0, 60.0),
      ],
      playerCornerTowerX: 20.0,
      playerCentralTowerX: 8.0,
      enemyCornerTowerX: 160.0,
      enemyCentralTowerX: 172.0,
    ),
    const CombatMap(
      name: 'Via Mala Abyss',
      width: 540.0,
      height: 270.0,
      laneCenters: [45.0, 135.0, 225.0],
      walls: [
        Rect.fromLTRB(135.0, 65.0, 160.0, 115.0),
        Rect.fromLTRB(135.0, 155.0, 160.0, 205.0),
        Rect.fromLTRB(270.0, 65.0, 295.0, 115.0),
        Rect.fromLTRB(270.0, 155.0, 295.0, 205.0),
        Rect.fromLTRB(405.0, 65.0, 430.0, 115.0),
        Rect.fromLTRB(405.0, 155.0, 430.0, 205.0),
      ],
      cauldronPositions: [
        Offset(35.0, 90.0),
        Offset(35.0, 180.0),
        Offset(505.0, 90.0),
        Offset(505.0, 180.0),
      ],
      playerCornerTowerX: 60.0,
      playerCentralTowerX: 20.0,
      enemyCornerTowerX: 480.0,
      enemyCentralTowerX: 520.0,
    ),
    const CombatMap(
      name: 'Bernina Glacial Valley',
      width: 320.0,
      height: 180.0,
      laneCenters: [30.0, 90.0, 150.0],
      walls: [
        Rect.fromLTRB(80.0, 45.0, 100.0, 75.0),
        Rect.fromLTRB(80.0, 105.0, 100.0, 135.0),
        Rect.fromLTRB(160.0, 45.0, 180.0, 75.0),
        Rect.fromLTRB(160.0, 105.0, 180.0, 135.0),
        Rect.fromLTRB(240.0, 45.0, 260.0, 75.0),
        Rect.fromLTRB(240.0, 105.0, 260.0, 135.0),
      ],
      cauldronPositions: [
        Offset(20.0, 60.0),
        Offset(20.0, 120.0),
        Offset(300.0, 60.0),
        Offset(300.0, 120.0),
      ],
      playerCornerTowerX: 35.0,
      playerCentralTowerX: 10.0,
      enemyCornerTowerX: 285.0,
      enemyCentralTowerX: 310.0,
    ),
    const CombatMap(
      name: 'Splügen Gorge',
      width: 360.0,
      height: 130.0,
      laneCenters: [25.0, 105.0],
      walls: [
        Rect.fromLTRB(90.0, 35.0, 110.0, 95.0),
        Rect.fromLTRB(180.0, 35.0, 200.0, 95.0),
        Rect.fromLTRB(270.0, 35.0, 290.0, 95.0),
      ],
      cauldronPositions: [
        Offset(20.0, 45.0),
        Offset(20.0, 85.0),
        Offset(340.0, 45.0),
        Offset(340.0, 85.0),
      ],
      playerCornerTowerX: 40.0,
      playerCentralTowerX: 12.0,
      enemyCornerTowerX: 320.0,
      enemyCentralTowerX: 348.0,
    ),
    const CombatMap(
      name: 'Rhine Headwaters',
      width: 280.0,
      height: 160.0,
      laneCenters: [25.0, 80.0, 135.0],
      walls: [
        Rect.fromLTRB(70.0, 35.0, 90.0, 70.0),
        Rect.fromLTRB(70.0, 90.0, 90.0, 125.0),
        Rect.fromLTRB(140.0, 35.0, 160.0, 70.0),
        Rect.fromLTRB(140.0, 90.0, 160.0, 125.0),
        Rect.fromLTRB(210.0, 35.0, 230.0, 70.0),
        Rect.fromLTRB(210.0, 90.0, 230.0, 125.0),
      ],
      cauldronPositions: [
        Offset(15.0, 52.5),
        Offset(15.0, 107.5),
        Offset(265.0, 52.5),
        Offset(265.0, 107.5),
      ],
      playerCornerTowerX: 30.0,
      playerCentralTowerX: 8.0,
      enemyCornerTowerX: 250.0,
      enemyCentralTowerX: 272.0,
    ),
  ];
}

enum CombatMapSize {
  small,
  medium,
  colossal,
}

