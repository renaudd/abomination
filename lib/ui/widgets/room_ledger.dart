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

class RoomLedger extends StatefulWidget {
  final Room room;
  final GameState state;
  final bool isCompact;

  const RoomLedger({
    super.key,
    required this.room,
    required this.state,
    this.isCompact = false,
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
  State<RoomLedger> createState() => _RoomLedgerState();
}

class _RoomLedgerState extends State<RoomLedger> {
  int _sortColumnIndex = -1; // -1 means unsorted (default)
  bool _sortAscending = true;

  double _parseAgeToMinutes(String ageStr) {
    if (ageStr == '-' || ageStr.isEmpty) return 999999999.0;
    
    final RegExp reg = RegExp(r'^([0-9.]+)([a-zA-Z.]+)$');
    final match = reg.firstMatch(ageStr.trim());
    if (match == null) return 0.0;
    
    final double? numVal = double.tryParse(match.group(1) ?? '');
    final String unit = match.group(2) ?? '';
    if (numVal == null) return 0.0;
    
    if (unit.startsWith('m')) {
      return numVal;
    } else if (unit.startsWith('h')) {
      return numVal * 60.0;
    } else if (unit.startsWith('d')) {
      return numVal * 24.0 * 60.0;
    } else if (unit.startsWith('y')) {
      return numVal * 365.0 * 24.0 * 60.0;
    }
    return numVal;
  }

  int _getQualityIndex(String q) {
    switch (q.toUpperCase()) {
      case 'AWFUL': return 0;
      case 'WEAK': return 1;
      case 'SUBSTANDARD': return 2;
      case 'FAIR': return 3;
      case 'COMMON': return 4;
      case 'QUALITY': return 5;
      case 'PRECIOUS': return 6;
      case 'EXCELLENT': return 7;
      case 'SUPREME': return 8;
      default: return 4; // default to common
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.getLedgerItems();

    if (_sortColumnIndex != -1) {
      items.sort((a, b) {
        int cmp = 0;
        switch (_sortColumnIndex) {
          case 0:
            cmp = a.icon.codePoint.compareTo(b.icon.codePoint);
            break;
          case 1:
            cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
            break;
          case 2:
            cmp = _parseAgeToMinutes(a.age).compareTo(_parseAgeToMinutes(b.age));
            break;
          case 3:
            cmp = _getQualityIndex(a.quality).compareTo(_getQualityIndex(b.quality));
            break;
          case 4:
            cmp = a.quantity.compareTo(b.quantity);
            break;
          case 5:
            cmp = a.weight.compareTo(b.weight);
            break;
          case 6:
            cmp = a.details.toLowerCase().compareTo(b.details.toLowerCase());
            break;
          case 7:
            cmp = a.value.compareTo(b.value);
            break;
        }
        if (cmp == 0) {
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        return _sortAscending ? cmp : -cmp;
      });
    }

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
          padding: EdgeInsets.symmetric(vertical: widget.isCompact ? 2.0 : 4.0),
          child: Row(
            children: [
               _headerCell(widget.isCompact ? 'T' : 'TYPE', 0, flex: 1),
               _headerCell('ITEM', 1, flex: 3),
               if (!widget.isCompact) ...[
                 _headerCell('AGE', 2, flex: 1),
                 _headerCell('QLTY', 3, flex: 2),
                 _headerCell('QTY', 4, flex: 1),
                 _headerCell('WGT', 5, flex: 1),
                 _headerCell('DETAILS', 6, flex: 3),
                 _headerCell('VAL', 7, flex: 1),
               ] else ...[
                 _headerCell('QLTY', 3, flex: 2),
                 _headerCell('QTY', 4, flex: 1),
                 _headerCell('VAL', 7, flex: 1),
               ],
            ],
          ),
        ),
        const Divider(color: Colors.white10),
        ...items.map((item) => Padding(
              padding: EdgeInsets.symmetric(vertical: widget.isCompact ? 2.0 : 4.0),
              child: Row(
                children: [
                   _dataCellIcon(item.icon, flex: 1),
                   _dataCell(item.name.toUpperCase(), flex: 3, isBold: true),
                   if (!widget.isCompact) ...[
                     _dataCell(item.age, flex: 1),
                     _dataCell(item.quality, flex: 2),
                     _dataCell(item.quantity.toString(), flex: 1),
                     _dataCell('${item.weight.toStringAsFixed(1)}KG', flex: 1),
                     _dataCell(item.details, flex: 3),
                     _dataCell('${item.value}F', flex: 1),
                   ] else ...[
                     _dataCell(item.quality, flex: 2),
                     _dataCell(item.quantity.toString(), flex: 1),
                     _dataCell('${item.value}F', flex: 1),
                   ],
                ],
              ),
            )),
      ],
    );
  }

  Widget _headerCell(String label, int columnIndex, {required int flex}) {
    final bool isSorted = _sortColumnIndex == columnIndex;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () {
          setState(() {
            if (_sortColumnIndex == columnIndex) {
              _sortAscending = !_sortAscending;
            } else {
              _sortColumnIndex = columnIndex;
              _sortAscending = true;
            }
          });
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.playfairDisplay(
                  color: isSorted
                      ? const Color(0xFFE5D5B0)
                      : const Color(0xFFC4B89B).withValues(alpha: 0.5),
                  fontSize: widget.isCompact ? 8.5 : 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: widget.isCompact ? 0.5 : 1,
                ),
              ),
            ),
            if (isSorted) ...[
              const SizedBox(width: 4),
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: widget.isCompact ? 9 : 12,
                color: const Color(0xFFE5D5B0),
              ),
            ],
          ],
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
              fontSize: widget.isCompact ? 9.5 : 14,
            )
          : GoogleFonts.oldStandardTt(
              color: const Color(0xFFC4B89B),
              fontSize: widget.isCompact ? 8.5 : 13,
            ),
      ),
    );
  }

  Widget _dataCellIcon(IconData icon, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Icon(icon, size: widget.isCompact ? 9 : 14, color: const Color(0xFFC4B89B)),
    );
  }
}
