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
import '../../models/room.dart';

class DentalSetupDialog extends StatefulWidget {
  const DentalSetupDialog({super.key});

  @override
  State<DentalSetupDialog> createState() => _DentalSetupDialogState();
}

class _DentalSetupDialogState extends State<DentalSetupDialog> {
  String? _selectedRoomId;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);
    final suitableRooms = state.rooms
        .where((r) => r.floor == Floor.attic || r.floor == Floor.basement)
        .toList();

    return Dialog(
      backgroundColor: const Color(0xFF1E1A15),
      shape: const RoundedRectangleBorder(),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC4B89B), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "DENTAL PRACTICE SETUP COVENANT",
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFE5D5B0),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            Text(
              "IMPERIAL OFFICE OF MEDICAL VENTURES",
              style: GoogleFonts.oswald(
                color: const Color(0xFFC4B89B),
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
            const Divider(color: Colors.white10, height: 24),
            Text(
              "As a certified graduate of Dental Science, Alfonso Giles is offered an Imperial Establishment Loan of 1,500 CHF. This loan must be used to configure a dedicated Dental Clinic inside Glarus Manor's Attic or Basement.\n\n"
              "The loan carries no interest, and you can quickly pay it back by performing professional cleanings, filings, and extractions on visiting patients.",
              style: GoogleFonts.oldStandardTt(
                color: Colors.white70,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "SELECT MANOR WING FOR DENTAL CLINIC:",
              style: GoogleFonts.oswald(
                color: const Color(0xFFC4B89B),
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            if (suitableRooms.isEmpty)
              Text(
                "NO ATTIC OR BASEMENT ROOMS CONFIGURED.",
                style: GoogleFonts.oldStandardTt(color: Colors.redAccent, fontSize: 11),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white10),
                  color: Colors.black12,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRoomId ?? suitableRooms.first.id,
                    dropdownColor: const Color(0xFF1E1A15),
                    isExpanded: true,
                    style: GoogleFonts.oldStandardTt(color: const Color(0xFFE5D5B0)),
                    onChanged: (val) {
                      setState(() {
                        _selectedRoomId = val;
                      });
                    },
                    items: suitableRooms.map((r) {
                      return DropdownMenuItem(
                        value: r.id,
                        child: Text("${r.name.toUpperCase()} (${r.floor.name.toUpperCase()})"),
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: Text(
                    "DECLINE LOAN",
                    style: GoogleFonts.playfairDisplay(color: Colors.white38, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selectedRoomId == null && suitableRooms.isEmpty
                      ? null
                      : () {
                          final targetRoom = _selectedRoomId ?? suitableRooms.first.id;
                          state.takeOutDentalLoan();
                          state.establishDentalClinic(targetRoom);
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC4B89B),
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: Text(
                    "ACCEPT LOAN & RESTORE CLINIC",
                    style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DentalEventDialog extends StatelessWidget {
  const DentalEventDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);
    final event = state.activeDentalEvent;

    if (event == null) return const SizedBox.shrink();

    final choices = event['choices'] as List;

    return Dialog(
      backgroundColor: const Color(0xFF1E1A15),
      shape: const RoundedRectangleBorder(),
      child: Container(
        width: 550,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC4B89B), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services_outlined, color: Color(0xFFC4B89B), size: 20),
                const SizedBox(width: 8),
                Text(
                  event['title'].toString().toUpperCase(),
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            Text(
              "GLARUS DENTAL CLINIC PATIENT RECORD",
              style: GoogleFonts.oswald(
                color: const Color(0xFFC4B89B),
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
            const Divider(color: Colors.white10, height: 24),
            Text(
              event['description'].toString(),
              style: GoogleFonts.oldStandardTt(
                color: Colors.white,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "CHOOSE CLINICAL TREATMENT PLAN:",
              style: GoogleFonts.oswald(
                color: const Color(0xFFC4B89B),
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(choices.length, (idx) {
              final choice = choices[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    state.resolveDentalEventChoice(idx);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFC4B89B)),
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.white.withValues(alpha: 0.01),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        choice['title'].toString().toUpperCase(),
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        choice['description'].toString(),
                        style: GoogleFonts.oldStandardTt(
                          color: Colors.white70,
                          fontSize: 10.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
