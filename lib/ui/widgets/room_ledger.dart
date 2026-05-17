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
import '../../models/room.dart';
import '../../models/game_item.dart';
import '../../models/dish.dart';
import '../../state/game_state.dart';
import '../../util/name_formatter.dart';

class LedgerItem {
  final IconData icon;
  final String name;
  final String age;
  final String quality;
  final int quantity;
  final double weight;
  final String details;
  final int value;

  LedgerItem({
    required this.icon,
    required this.name,
    required this.age,
    required this.quality,
    required this.quantity,
    required this.weight,
    required this.details,
    required this.value,
  });
}

class RoomLedger extends StatelessWidget {
  final Room room;
  final GameState state;

  const RoomLedger({
    super.key,
    required this.room,
    required this.state,
  });

  List<LedgerItem> getLedgerItems() {
    final List<LedgerItem> items = [];

    // 1. GameItems from room inventory
    for (var item in room.inventory) {
      items.add(LedgerItem(
        icon: _getIconForItem(item),
        name: NameFormatter.formatItemName(item.name),
        age: item.getDisplayAge(state.currentDate),
        quality: item.displayQuality.name.toUpperCase(),
        quantity: item.quantity,
        weight: item.weight,
        details: item.metadata['details'] ?? item.category.name.toUpperCase(),
        value: item.value,
      ));
    }

    // 2. Room-specific specialized items
    if (room.type == RoomType.kitchen) {
      // Aggregate dishes in pantry
      final Map<String, List<Dish>> groupedDishes = {};
      for (var dish in state.pantry) {
        groupedDishes.putIfAbsent(dish.name, () => []).add(dish);
      }

      for (var entry in groupedDishes.entries) {
        final first = entry.value.first;
        items.add(LedgerItem(
          icon: Icons.restaurant,
          name: NameFormatter.formatItemName(entry.key),
          age: first.getDisplayAge(state.currentDate),
          quality: first.quality.name.toUpperCase(),
          quantity: entry.value.length,
          weight: first.weight,
          details: first.type.name.toUpperCase(),
          value: first.value,
        ));
      }
    }

    if (room.id == 'chicken_coop') {
      for (var chicken in state.chickens) {
        items.add(LedgerItem(
          icon: chicken.isMale ? Icons.pest_control : Icons.egg,
          name: chicken.breed.name,
          age: chicken.getDisplayAge(state.currentDate),
          quality: 'COMMON',
          quantity: 1,
          weight: chicken.weight,
          details: '${chicken.isMale ? "MALE" : "FEMALE"}, ${chicken.isMature(state.currentDate) ? "MATURE" : "YOUNG"}',
          value: chicken.value(state.currentDate),
        ));
      }
    }

    return items;
  }

  IconData _getIconForItem(GameItem item) {
    switch (item.category) {
      case ItemCategory.food:
        return Icons.restaurant;
      case ItemCategory.specimen:
        return Icons.science;
      case ItemCategory.knowledge:
        return Icons.menu_book;
      case ItemCategory.material:
        return Icons.category;
      default:
        return Icons.inventory;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = getLedgerItems();

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'THE LEDGER IS EMPTY.',
            style: GoogleFonts.oldStandardTt(
              color: const Color(0xFFC4B89B).withValues(alpha: 0.3),
              letterSpacing: 2,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
               _headerCell('', flex: 1), // Icon
               _headerCell('ITEM', flex: 3),
               _headerCell('AGE', flex: 1),
               _headerCell('QLTY', flex: 2),
               _headerCell('QTY', flex: 1),
               _headerCell('WGT', flex: 1),
               _headerCell('DETAILS', flex: 3),
               _headerCell('VAL', flex: 1),
            ],
          ),
        ),
        const Divider(color: Colors.white10),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                   _dataCellIcon(item.icon, flex: 1),
                   _dataCell(item.name.toUpperCase(), flex: 3, isBold: true),
                   _dataCell(item.age, flex: 1),
                   _dataCell(item.quality, flex: 2),
                   _dataCell(item.quantity.toString(), flex: 1),
                   _dataCell('${item.weight.toStringAsFixed(1)}KG', flex: 1),
                   _dataCell(item.details, flex: 3),
                   _dataCell('${item.value}F', flex: 1),
                ],
              ),
            )),
      ],
    );
  }

  Widget _headerCell(String label, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: GoogleFonts.playfairDisplay(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.5),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _dataCell(String label, {required int flex, bool isBold = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: isBold 
          ? GoogleFonts.oswald(
              color: const Color(0xFFE5D5B0),
              fontSize: 14,
            )
          : GoogleFonts.oldStandardTt(
              color: const Color(0xFFC4B89B),
              fontSize: 13,
            ),
      ),
    );
  }

  Widget _dataCellIcon(IconData icon, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Icon(icon, size: 14, color: const Color(0xFFC4B89B)),
    );
  }
}
