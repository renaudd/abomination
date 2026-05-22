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
      width: 240.0,
      height: 120.0,
      laneCenters: [25.0, 95.0],
      walls: [
        Rect.fromLTRB(60.0, 35.0, 80.0, 85.0),
        Rect.fromLTRB(120.0, 35.0, 140.0, 85.0),
        Rect.fromLTRB(180.0, 35.0, 200.0, 85.0),
      ],
      cauldronPositions: [
        Offset(15.0, 42.5),
        Offset(15.0, 77.5),
        Offset(225.0, 42.5),
        Offset(225.0, 77.5),
      ],
      playerCornerTowerX: 25.0,
      playerCentralTowerX: 10.0,
      enemyCornerTowerX: 215.0,
      enemyCentralTowerX: 230.0,
    ),
    const CombatMap(
      name: 'Via Mala Abyss',
      width: 400.0,
      height: 200.0,
      laneCenters: [35.0, 100.0, 165.0],
      walls: [
        Rect.fromLTRB(100.0, 50.0, 120.0, 85.0),
        Rect.fromLTRB(100.0, 115.0, 120.0, 150.0),
        Rect.fromLTRB(200.0, 50.0, 220.0, 85.0),
        Rect.fromLTRB(200.0, 115.0, 220.0, 150.0),
        Rect.fromLTRB(300.0, 50.0, 320.0, 85.0),
        Rect.fromLTRB(300.0, 115.0, 320.0, 150.0),
      ],
      cauldronPositions: [
        Offset(25.0, 67.5),
        Offset(25.0, 132.5),
        Offset(375.0, 67.5),
        Offset(375.0, 132.5),
      ],
      playerCornerTowerX: 45.0,
      playerCentralTowerX: 15.0,
      enemyCornerTowerX: 355.0,
      enemyCentralTowerX: 385.0,
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
