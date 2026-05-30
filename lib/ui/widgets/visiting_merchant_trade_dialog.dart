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
import '../../models/npc.dart';

class VisitingMerchantTradeDialog extends StatefulWidget {
  final NPC merchant;

  const VisitingMerchantTradeDialog({super.key, required this.merchant});

  @override
  State<VisitingMerchantTradeDialog> createState() => _VisitingMerchantTradeDialogState();
}

class _VisitingMerchantTradeDialogState extends State<VisitingMerchantTradeDialog> {
  // Cart quantities
  final Map<String, int> _itemsToBuy = {};
  final Map<String, int> _itemsToSell = {};

  // Text Controllers for quantity input to avoid losing focus
  final Map<String, TextEditingController> _buyControllers = {};
  final Map<String, TextEditingController> _sellControllers = {};

  // Sorting states
  String _sortBuyField = 'name';
  bool _isBuyAscending = true;
  String _sortSellField = 'name';
  bool _isSellAscending = true;

  // Haggling states
  String? _haggleMessage;
  String? _haggleOutcome; // 'success', 'failure', 'upset_refused', 'loan_offer', 'critical_success'
  double _haggleDiscount = 0.0;
  int? _offeredLoanAmount;
  double _offeredLoanInterest = 0.25;

  @override
  void dispose() {
    for (var c in _buyControllers.values) {
      c.dispose();
    }
    for (var c in _sellControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getBuyController(String id, int initialVal) {
    return _buyControllers.putIfAbsent(id, () {
      final controller = TextEditingController(text: initialVal > 0 ? initialVal.toString() : "");
      controller.addListener(() {
        final val = int.tryParse(controller.text) ?? 0;
        if (_itemsToBuy[id] != val) {
          setState(() {
            _itemsToBuy[id] = val;
          });
        }
      });
      return controller;
    });
  }

  TextEditingController _getSellController(String id, int initialVal) {
    return _sellControllers.putIfAbsent(id, () {
      final controller = TextEditingController(text: initialVal > 0 ? initialVal.toString() : "");
      controller.addListener(() {
        final val = int.tryParse(controller.text) ?? 0;
        if (_itemsToSell[id] != val) {
          setState(() {
            _itemsToSell[id] = val;
          });
        }
      });
      return controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        final liveMerchant = state.npcs.firstWhere(
          (n) => n.id == widget.merchant.id,
          orElse: () => widget.merchant,
        );

        final isSuperMerchant = liveMerchant.id == 'super_merchant' || liveMerchant.role == 'Super Merchant';
        final stock = liveMerchant.metadata['merchantStock'] as Map<String, dynamic>? ?? {};
        final funds = state.resources['funds'] ?? 0;

        // Merchant parameters
        final respect = liveMerchant.metadata['merchantRespect'] as int? ?? 50;
        final double markupFactor = liveMerchant.metadata['markupFactor'] as double? ??
            (liveMerchant.role == 'Staple Food Merchant' ? 0.5 : 1.25);
        final double currentMarkup = (markupFactor - _haggleDiscount).clamp(0.5, 2.0);
        final bool hasHaggled = liveMerchant.metadata['hasHaggled'] == true;
        final bool refusedBusiness = liveMerchant.metadata['refusedBusiness'] == true;

        // Vault items that can be sold
        final sellableItems = [
          'wood',
          'timber',
          'meat',
          'eggs',
          'cabbage',
          'grain',
          'ale',
          'spirits',
          'rooster',
          'fertilizer',
          'salt',
          'potato',
          'carrots',
          'beets',
          'seeds_cabbage',
          'seeds_potato',
          'seeds_carrot',
          'mushroom_spores',
          'gold_ore',
        ];

        // Prepare data catalogs
        final List<MapEntry<String, int>> buyCatalog = stock.entries
            .where((entry) => (entry.value as num) > 0)
            .map((entry) => MapEntry(entry.key, entry.value as int))
            .toList();

        final List<MapEntry<String, int>> sellCatalog = sellableItems
            .where((item) => (state.resources[item] ?? 0) > 0)
            .map((item) => MapEntry(item, (state.resources[item] ?? 0).toInt()))
            .toList();

        // Sort Buy Catalog
        final sortedBuy = sortItems<MapEntry<String, int>>(
          buyCatalog,
          field: _sortBuyField,
          ascending: _isBuyAscending,
          getPrice: (e) => (state.marketService.getBuyPrice(e.key) * currentMarkup).round().clamp(1, 9999),
          getId: (e) => e.key,
        );

        // Sort Sell Catalog
        final sortedSell = sortItems<MapEntry<String, int>>(
          sellCatalog,
          field: _sortSellField,
          ascending: _isSellAscending,
          getPrice: (e) => state.marketService.getSellPrice(e.key),
          getId: (e) => e.key,
        );

        // Calculate Cart totals
        int totalBuyCost = 0;
        double totalBuyWeight = 0.0;
        int totalBuyItemsCount = 0;

        _itemsToBuy.forEach((id, qty) {
          if (qty <= 0) return;
          final available = isSuperMerchant ? 999999 : (stock[id] as int? ?? 0);
          final actualQty = qty.clamp(0, available);
          int price = (state.marketService.getBuyPrice(id) * currentMarkup).round().clamp(1, 9999);
          totalBuyCost += price * actualQty;
          totalBuyWeight += getItemInfo(id).weight * actualQty;
          totalBuyItemsCount += actualQty;
        });

        int totalSellGain = 0;
        double totalSellWeight = 0.0;
        int totalSellItemsCount = 0;

        _itemsToSell.forEach((id, qty) {
          if (qty <= 0) return;
          final available = (state.resources[id] ?? 0).toInt();
          final actualQty = qty.clamp(0, available);
          int price = state.marketService.getSellPrice(id);
          totalSellGain += price * actualQty;
          totalSellWeight += getItemInfo(id).weight * actualQty;
          totalSellItemsCount += actualQty;
        });

        final int netCost = totalBuyCost - totalSellGain;

        // Refused further business screen override
        if (refusedBusiness) {
          return Dialog(
            backgroundColor: const Color(0xFF1E1A15),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: Container(
              width: 600,
              height: 380,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFC4B89B), width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.gavel, color: Color(0xFFCF6679), size: 48),
                  const SizedBox(height: 16),
                  Text(
                    "BUSINESS REFUSED",
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFCF6679),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "${liveMerchant.name} has been highly offended by your trading conduct and haggling. They flatly refuse to show Glarus Manor any of their stock or buy any manor resources.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFC4B89B)),
                      shape: const RoundedRectangleBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: Text(
                      "DEPART ENTRYWAY",
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFFE5D5B0),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Dialog(
          backgroundColor: const Color(0xFF1E1A15),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: Container(
            width: 950,
            height: 680,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC4B89B), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          liveMerchant.name.toUpperCase(),
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFFE5D5B0),
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${liveMerchant.role} • RESPECT: $respect%".toUpperCase(),
                          style: GoogleFonts.oldStandardTt(
                            color: const Color(0xFFC4B89B).withValues(alpha: 0.8),
                            fontSize: 9.5,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Respect Visual Bar
                    if (!isSuperMerchant)
                      Container(
                        width: 180,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          border: Border.all(color: const Color(0xFFC4B89B), width: 0.5),
                        ),
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              widthFactor: respect / 100.0,
                              child: Container(
                                color: respect >= 50 ? const Color(0xFF8D996C) : const Color(0xFFCF6679),
                              ),
                            ),
                          ],
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFFE5D5B0), size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 20),

                // Financial Summary Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "MANOR VAULT BALANCE: ${funds.round()} CHF",
                      style: GoogleFonts.oswald(
                        color: const Color(0xFFE5D5B0),
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (state.activeMerchantLoan > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        color: const Color(0xFFCF6679).withValues(alpha: 0.2),
                        child: Row(
                          children: [
                            Text(
                              "OUTSTANDING DEBT: ${state.activeMerchantLoan} CHF",
                              style: GoogleFonts.oswald(
                                color: const Color(0xFFCF6679),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: funds >= 50
                                  ? () {
                                      final payAmount = min(funds.toInt(), state.activeMerchantLoan);
                                      state.payMerchantLoan(payAmount);
                                    }
                                  : null,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFCF6679)),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                shape: const RoundedRectangleBorder(),
                              ),
                              child: Text(
                                "PAY BACK",
                                style: GoogleFonts.oldStandardTt(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Double Catalog Layout
                Expanded(
                  child: Row(
                    children: [
                      // Left Column: Merchant's Inventory (BUY)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.18),
                            border: Border.all(color: Colors.white10),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "MERCHANT STOCK (TO BUY)",
                                style: GoogleFonts.oswald(
                                  color: const Color(0xFFC4B89B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Buy Sorting Row
                              Row(
                                children: [
                                  _buildSortHeaderCell(
                                    label: "NAME",
                                    field: 'name',
                                    activeField: _sortBuyField,
                                    isAscending: _isBuyAscending,
                                    onTap: () => _setBuySort('name'),
                                    flex: 3,
                                  ),
                                  _buildSortHeaderCell(
                                    label: "TYPE",
                                    field: 'type',
                                    activeField: _sortBuyField,
                                    isAscending: _isBuyAscending,
                                    onTap: () => _setBuySort('type'),
                                    flex: 2,
                                  ),
                                  _buildSortHeaderCell(
                                    label: "PRICE",
                                    field: 'price',
                                    activeField: _sortBuyField,
                                    isAscending: _isBuyAscending,
                                    onTap: () => _setBuySort('price'),
                                    flex: 2,
                                  ),
                                  _buildSortHeaderCell(
                                    label: "WT",
                                    field: 'weight',
                                    activeField: _sortBuyField,
                                    isAscending: _isBuyAscending,
                                    onTap: () => _setBuySort('weight'),
                                    flex: 2,
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      "ORDER QTY",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.oswald(color: Colors.white38, fontSize: 8.5),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white10),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: sortedBuy.length,
                                  itemBuilder: (context, index) {
                                    final entry = sortedBuy[index];
                                    final id = entry.key;
                                    final stockQty = entry.value;
                                    final price = (state.marketService.getBuyPrice(id) * currentMarkup).round().clamp(1, 9999);
                                    final info = getItemInfo(id);
                                    final cartQty = _itemsToBuy[id] ?? 0;

                                    return Container(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      decoration: const BoxDecoration(
                                        border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
                                      ),
                                      child: Row(
                                        children: [
                                          // Name
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  info.name,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.playfairDisplay(
                                                    color: const Color(0xFFE5D5B0),
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  isSuperMerchant ? "Stock: ∞" : "Stock: $stockQty",
                                                  style: GoogleFonts.oldStandardTt(
                                                    color: Colors.white30,
                                                    fontSize: 8,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Type (Icon)
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              children: [
                                                Icon(info.icon, color: const Color(0xFFC4B89B), size: 11),
                                                const SizedBox(width: 4),
                                                Text(
                                                  info.type.toUpperCase(),
                                                  style: GoogleFonts.oldStandardTt(
                                                    color: Colors.white54,
                                                    fontSize: 8,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Price
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              "$price CHF",
                                              style: GoogleFonts.oswald(color: Colors.white70, fontSize: 9.5),
                                            ),
                                          ),
                                          // Weight
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              "${info.weight} kg",
                                              style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 9),
                                            ),
                                          ),
                                          // Qty Input
                                          Expanded(
                                            flex: 3,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove, color: Colors.white54, size: 12),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  onPressed: cartQty > 0
                                                      ? () {
                                                          final newVal = cartQty - 1;
                                                          _getBuyController(id, newVal).text = newVal > 0 ? newVal.toString() : "";
                                                          setState(() {
                                                            _itemsToBuy[id] = newVal;
                                                          });
                                                        }
                                                      : null,
                                                ),
                                                Container(
                                                  width: 35,
                                                  height: 22,
                                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                                  child: TextField(
                                                    controller: _getBuyController(id, cartQty),
                                                    keyboardType: TextInputType.number,
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.oswald(color: const Color(0xFFE5D5B0), fontSize: 10.5),
                                                    decoration: InputDecoration(
                                                      contentPadding: EdgeInsets.zero,
                                                      filled: true,
                                                      fillColor: Colors.black38,
                                                      enabledBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: cartQty > 0 ? const Color(0xFFC4B89B) : Colors.white10,
                                                        ),
                                                        borderRadius: BorderRadius.zero,
                                                      ),
                                                      focusedBorder: const OutlineInputBorder(
                                                        borderSide: BorderSide(color: Color(0xFFE5D5B0)),
                                                        borderRadius: BorderRadius.zero,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.add, color: Colors.white54, size: 12),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  onPressed: isSuperMerchant || cartQty < stockQty
                                                      ? () {
                                                          final newVal = cartQty + 1;
                                                          _getBuyController(id, newVal).text = newVal.toString();
                                                          setState(() {
                                                            _itemsToBuy[id] = newVal;
                                                          });
                                                        }
                                                      : null,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Right Column: Manor's Inventory (SELL)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.18),
                            border: Border.all(color: Colors.white10),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "MANOR VAULT (TO SELL)",
                                style: GoogleFonts.oswald(
                                  color: const Color(0xFFC4B89B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Sell Sorting Row
                              Row(
                                children: [
                                  _buildSortHeaderCell(
                                    label: "NAME",
                                    field: 'name',
                                    activeField: _sortSellField,
                                    isAscending: _isSellAscending,
                                    onTap: () => _setSellSort('name'),
                                    flex: 3,
                                  ),
                                  _buildSortHeaderCell(
                                    label: "TYPE",
                                    field: 'type',
                                    activeField: _sortSellField,
                                    isAscending: _isSellAscending,
                                    onTap: () => _setSellSort('type'),
                                    flex: 2,
                                  ),
                                  _buildSortHeaderCell(
                                    label: "VALUE",
                                    field: 'price',
                                    activeField: _sortSellField,
                                    isAscending: _isSellAscending,
                                    onTap: () => _setSellSort('price'),
                                    flex: 2,
                                  ),
                                  _buildSortHeaderCell(
                                    label: "WT",
                                    field: 'weight',
                                    activeField: _sortSellField,
                                    isAscending: _isSellAscending,
                                    onTap: () => _setSellSort('weight'),
                                    flex: 2,
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      "OFFER QTY",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.oswald(color: Colors.white38, fontSize: 8.5),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white10),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: sortedSell.length,
                                  itemBuilder: (context, index) {
                                    final entry = sortedSell[index];
                                    final id = entry.key;
                                    final vaultQty = entry.value;
                                    final price = state.marketService.getSellPrice(id);
                                    final info = getItemInfo(id);
                                    final cartQty = _itemsToSell[id] ?? 0;

                                    return Container(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      decoration: const BoxDecoration(
                                        border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
                                      ),
                                      child: Row(
                                        children: [
                                          // Name
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  info.name,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.playfairDisplay(
                                                    color: const Color(0xFFE5D5B0),
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  "In Vault: $vaultQty",
                                                  style: GoogleFonts.oldStandardTt(
                                                    color: Colors.white30,
                                                    fontSize: 8,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Type
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              children: [
                                                Icon(info.icon, color: const Color(0xFFC4B89B), size: 11),
                                                const SizedBox(width: 4),
                                                Text(
                                                  info.type.toUpperCase(),
                                                  style: GoogleFonts.oldStandardTt(
                                                    color: Colors.white54,
                                                    fontSize: 8,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Sell Price
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              "$price CHF",
                                              style: GoogleFonts.oswald(color: Colors.white70, fontSize: 9.5),
                                            ),
                                          ),
                                          // Weight
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              "${info.weight} kg",
                                              style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 9),
                                            ),
                                          ),
                                          // Qty Offer
                                          Expanded(
                                            flex: 3,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove, color: Colors.white54, size: 12),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  onPressed: cartQty > 0
                                                      ? () {
                                                          final newVal = cartQty - 1;
                                                          _getSellController(id, newVal).text = newVal > 0 ? newVal.toString() : "";
                                                          setState(() {
                                                            _itemsToSell[id] = newVal;
                                                          });
                                                        }
                                                      : null,
                                                ),
                                                Container(
                                                  width: 35,
                                                  height: 22,
                                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                                  child: TextField(
                                                    controller: _getSellController(id, cartQty),
                                                    keyboardType: TextInputType.number,
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.oswald(color: const Color(0xFFE5D5B0), fontSize: 10.5),
                                                    decoration: InputDecoration(
                                                      contentPadding: EdgeInsets.zero,
                                                      filled: true,
                                                      fillColor: Colors.black38,
                                                      enabledBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: cartQty > 0 ? const Color(0xFFC4B89B) : Colors.white10,
                                                        ),
                                                        borderRadius: BorderRadius.zero,
                                                      ),
                                                      focusedBorder: const OutlineInputBorder(
                                                        borderSide: BorderSide(color: Color(0xFFE5D5B0)),
                                                        borderRadius: BorderRadius.zero,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.add, color: Colors.white54, size: 12),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  onPressed: cartQty < vaultQty
                                                      ? () {
                                                          final newVal = cartQty + 1;
                                                          _getSellController(id, newVal).text = newVal.toString();
                                                          setState(() {
                                                            _itemsToSell[id] = newVal;
                                                          });
                                                        }
                                                      : null,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Haggling feedback alert
                if (_haggleMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: _getOutcomeColor().withValues(alpha: 0.15),
                      border: Border.all(color: _getOutcomeColor(), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _haggleOutcome == 'critical_success' || _haggleOutcome == 'success'
                              ? Icons.check_circle
                              : _haggleOutcome == 'failure'
                                  ? Icons.info
                                  : Icons.warning,
                          color: _getOutcomeColor(),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _haggleMessage!,
                            style: GoogleFonts.oldStandardTt(
                              color: const Color(0xFFE5D5B0),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Bottom Transaction Panel
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    border: Border.all(color: const Color(0xFFC4B89B), width: 0.8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left details
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ITEMS QUEUED: $totalBuyItemsCount TO BUY / $totalSellItemsCount TO SELL",
                                style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 10, letterSpacing: 1),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "TOTAL WEIGHT CHANGE: +${(totalBuyWeight - totalSellWeight).toStringAsFixed(1)} kg",
                                style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 9),
                              ),
                            ],
                          ),

                          // Middle details
                          Row(
                            children: [
                              Text(
                                netCost >= 0 ? "TOTAL COST: " : "TOTAL GAIN: ",
                                style: GoogleFonts.oswald(
                                  color: const Color(0xFFE5D5B0),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${netCost.abs()} CHF",
                                style: GoogleFonts.oswald(
                                  color: netCost >= 0
                                      ? (funds >= netCost ? const Color(0xFFE5D5B0) : const Color(0xFFCF6679))
                                      : const Color(0xFF8D996C),
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Action Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Haggling Button
                          if (!isSuperMerchant) ...[
                            OutlinedButton(
                              onPressed: !hasHaggled && totalBuyItemsCount > 0
                                  ? () {
                                      // Calculate base intrinsics
                                      double baseIntrinsics = 0.0;
                                      _itemsToBuy.forEach((id, qty) {
                                        baseIntrinsics += state.marketService.getBuyPrice(id) * qty;
                                      });

                                      // Trigger haggle in state
                                      final result = state.haggleWithMerchant(
                                        merchantId: liveMerchant.id,
                                        baseIntrinsicsCost: baseIntrinsics,
                                        currentOfferedCost: totalBuyCost.toDouble(),
                                      );

                                      setState(() {
                                        _haggleOutcome = result['outcome'];
                                        _haggleMessage = result['message'];
                                        if (result['discount'] != null) {
                                          _haggleDiscount += result['discount'] as double;
                                        }
                                        if (result['outcome'] == 'loan_offer') {
                                          _offeredLoanAmount = netCost;
                                          _offeredLoanInterest = 0.25;
                                        }
                                      });
                                    }
                                  : null,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: !hasHaggled && totalBuyItemsCount > 0
                                      ? const Color(0xFFC4B89B)
                                      : Colors.white10,
                                ),
                                shape: const RoundedRectangleBorder(),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              ),
                              child: Text(
                                hasHaggled ? "ALREADY HAGGLED" : "HAGGLE WITH VENDOR",
                                style: GoogleFonts.playfairDisplay(
                                  color: !hasHaggled && totalBuyItemsCount > 0
                                      ? const Color(0xFFE5D5B0)
                                      : Colors.white24,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],

                          // Loan Acceptance Button
                          if (_haggleOutcome == 'loan_offer' && _offeredLoanAmount != null && _offeredLoanAmount! > 0) ...[
                            OutlinedButton(
                              onPressed: () {
                                state.commitMerchantTransaction(
                                  merchantId: liveMerchant.id,
                                  itemsToBuy: _itemsToBuy,
                                  itemsToSell: _itemsToSell,
                                  netCost: netCost,
                                  loanProvider: liveMerchant.name,
                                  loanAmount: _offeredLoanAmount,
                                  loanInterestRate: _offeredLoanInterest,
                                );
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFCF6679)),
                                backgroundColor: const Color(0xFFCF6679).withValues(alpha: 0.15),
                                shape: const RoundedRectangleBorder(),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              ),
                              child: Text(
                                "ACCEPT DEBT LOAN & BUY",
                                style: GoogleFonts.playfairDisplay(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],

                          // Regular checkout button
                          OutlinedButton(
                            onPressed: (totalBuyItemsCount > 0 || totalSellItemsCount > 0) &&
                                    (netCost <= funds || (_haggleOutcome == 'loan_offer' && _offeredLoanAmount != null))
                                ? () {
                                    // Regular execution (or financed partially)
                                    state.commitMerchantTransaction(
                                      merchantId: liveMerchant.id,
                                      itemsToBuy: _itemsToBuy,
                                      itemsToSell: _itemsToSell,
                                      netCost: netCost,
                                    );
                                    Navigator.pop(context);
                                  }
                                : null,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: (totalBuyItemsCount > 0 || totalSellItemsCount > 0) && (netCost <= funds)
                                    ? const Color(0xFF8D996C)
                                    : Colors.white10,
                              ),
                              shape: const RoundedRectangleBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                            ),
                            child: Text(
                              netCost > funds ? "INSUFFICIENT FUNDS" : "CONFIRM TRANSACTION",
                              style: GoogleFonts.playfairDisplay(
                                color: (totalBuyItemsCount > 0 || totalSellItemsCount > 0) && (netCost <= funds)
                                    ? const Color(0xFFE5D5B0)
                                    : Colors.white24,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortHeaderCell({
    required String label,
    required String field,
    required String activeField,
    required bool isAscending,
    required VoidCallback onTap,
    required int flex,
  }) {
    final bool isActive = field == activeField;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.oswald(
                  color: isActive ? const Color(0xFFE5D5B0) : Colors.white38,
                  fontSize: 8.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 2),
                Icon(
                  isAscending ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: const Color(0xFFE5D5B0),
                  size: 12,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _setBuySort(String field) {
    setState(() {
      if (_sortBuyField == field) {
        _isBuyAscending = !_isBuyAscending;
      } else {
        _sortBuyField = field;
        _isBuyAscending = true;
      }
    });
  }

  void _setSellSort(String field) {
    setState(() {
      if (_sortSellField == field) {
        _isSellAscending = !_isSellAscending;
      } else {
        _sortSellField = field;
        _isSellAscending = true;
      }
    });
  }

  Color _getOutcomeColor() {
    switch (_haggleOutcome) {
      case 'critical_success':
      case 'success':
        return const Color(0xFF8D996C);
      case 'failure':
        return const Color(0xFFC4B89B);
      case 'upset_refused':
      case 'loan_offer':
        return const Color(0xFFCF6679);
      default:
        return Colors.white54;
    }
  }

  // Core helper to register item metadata
  TradeItemInfo getItemInfo(String id) {
    final name = _getPrettyResourceName(id);
    double weight = 1.0;
    String type = 'resource';
    IconData icon = Icons.layers;

    if (id == 'wood' || id == 'timber') {
      weight = id == 'wood' ? 1.0 : 3.0;
      type = 'material';
      icon = Icons.forest;
    } else if (id == 'meat' || id == 'eggs' || id == 'cabbage' || id == 'grain' || id == 'ale' || id == 'spirits' || id == 'potato' || id == 'carrots' || id == 'beets' || id == 'shepherds_pie' || id == 'boiled_cabbage' || id == 'scrambled_eggs' || id == 'protein_mistery_stew') {
      weight = 0.5;
      type = 'food';
      icon = Icons.restaurant;
    } else if (id == 'seeds_cabbage' || id == 'seeds_potato' || id == 'seeds_carrot' || id == 'seeds_cannabis' || id == 'seeds_tobacco' || id == 'mushroom_spores' || id == 'fertilizer') {
      weight = 0.2;
      type = 'seeds';
      icon = Icons.grass;
    } else if (id == 'salt') {
      weight = 0.1;
      type = 'food';
      icon = Icons.rice_bowl;
    } else if (id.contains('pickaxe') || id.contains('shovel') || id.contains('drill')) {
      weight = id == 'simple_shovel' ? 2.5 : id == 'iron_pickaxe' ? 4.0 : id == 'steel_pickaxe' ? 4.5 : 12.0;
      type = 'tool';
      icon = Icons.build;
    } else if (id == 'gold_ore' || id == 'silver_ore' || id == 'copper_ore' || id == 'iron_ore' || id == 'coal' || id == 'cobalt_ore' || id == 'nickel_ore' || id == 'lithium_ore' || id == 'titanium_ore' || id == 'rough_diamonds' || id == 'uranium_ore' || id == 'jadeite_ore') {
      weight = 2.0;
      type = 'ore';
      icon = Icons.monetization_on;
    } else if (id == 'stone' || id == 'bricks') {
      weight = 1.5;
      type = 'material';
      icon = Icons.layers;
    } else if (id == 'poem' || id == 'novel' || id == 'unreviewed_document' || id == 'old_notes' || id == 'research_notes') {
      weight = 0.3;
      type = 'luxury';
      icon = Icons.book;
    } else if (id == 'rat' || id == 'bat' || id == 'chicken' || id == 'rooster') {
      weight = 1.0;
      type = 'livestock';
      icon = Icons.pets;
    } else if (id == 'herb_reagent' || id == 'cannabis_buds' || id == 'tobacco_leaves' || id == 'hallucinogenic_mushrooms' || id == 'hemp_fiber') {
      weight = 0.5;
      type = 'alchemy';
      icon = Icons.medical_services;
    }

    return TradeItemInfo(id: id, name: name, weight: weight, type: type, icon: icon);
  }

  List<T> sortItems<T>(
    List<T> items, {
    required String field,
    required bool ascending,
    required int Function(T a) getPrice,
    required String Function(T a) getId,
  }) {
    final List<T> sorted = List.from(items);
    sorted.sort((a, b) {
      final idA = getId(a);
      final idB = getId(b);
      final infoA = getItemInfo(idA);
      final infoB = getItemInfo(idB);

      int comparison = 0;
      switch (field) {
        case 'name':
          comparison = infoA.name.compareTo(infoB.name);
          break;
        case 'price':
          comparison = getPrice(a).compareTo(getPrice(b));
          break;
        case 'weight':
          comparison = infoA.weight.compareTo(infoB.weight);
          break;
        case 'type':
          comparison = infoA.type.compareTo(infoB.type);
          break;
      }

      return ascending ? comparison : -comparison;
    });
    return sorted;
  }

  String _getPrettyResourceName(String res) {
    if (res == 'shepherds_pie') return "SHEPHERD'S PIE";
    if (res == 'seeds_cabbage') return 'CABBAGE SEEDS';
    if (res == 'seeds_potato') return 'POTATO SEEDS';
    if (res == 'seeds_carrot') return 'CARROT SEEDS';
    if (res == 'seeds_cannabis') return 'CANNABIS SEEDS';
    if (res == 'seeds_tobacco') return 'TOBACCO SEEDS';
    if (res == 'mushroom_spores') return 'MUSHROOM SPORES';
    if (res == 'salt') return 'SALT';
    if (res == 'wood') return 'WOOD';
    if (res == 'grain') return 'GRAIN';
    if (res == 'gold_ore') return 'GOLD ORE';
    return res.replaceAll('_', ' ').toUpperCase();
  }
}

class TradeItemInfo {
  final String id;
  final String name;
  final double weight;
  final String type;
  final IconData icon;

  TradeItemInfo({
    required this.id,
    required this.name,
    required this.weight,
    required this.type,
    required this.icon,
  });
}
