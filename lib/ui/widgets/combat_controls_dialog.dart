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

class CombatControlsDialog extends StatelessWidget {
  const CombatControlsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);

    return Dialog(
      backgroundColor: const Color(0xFF1A1612),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: Color(0xFFC4B89B), width: 1.5),
      ),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'COMBAT CONTROLS',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFFE5D5B0),
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('MOBILE MOVEMENT CONTROL'),
                    const SizedBox(height: 8),
                    _buildRadioOption<String>(
                      context: context,
                      title: 'Directional Pad (Virtual Joystick in Combat Screen)',
                      value: 'pad',
                      groupValue: state.combatControlMode,
                      onChanged: (val) => state.setCombatControlMode(val!),
                    ),
                    _buildRadioOption<String>(
                      context: context,
                      title: 'Waypoint Click (Tap Screen to Set Destination)',
                      value: 'click',
                      groupValue: state.combatControlMode,
                      onChanged: (val) => state.setCombatControlMode(val!),
                    ),
                    const Divider(color: Colors.white10, height: 32),
                    _sectionTitle('DESKTOP KEY ASSIGNMENTS'),
                    const SizedBox(height: 8),
                    _buildKeyAssignmentRow('Move Left', 'A / ArrowLeft'),
                    _buildKeyAssignmentRow('Move Up', 'W / ArrowUp'),
                    _buildKeyAssignmentRow('Move Right', 'D / ArrowRight'),
                    _buildKeyAssignmentRow('Move Down', 'S / ArrowDown'),
                    _buildKeyAssignmentRow('1st Special Action', 'R'),
                    _buildKeyAssignmentRow('2nd Special Action', 'F'),
                    _buildKeyAssignmentRow('Select Hand Card 1', '1'),
                    _buildKeyAssignmentRow('Select Hand Card 2', '2'),
                    _buildKeyAssignmentRow('Select Hand Card 3', '3'),
                    _buildKeyAssignmentRow('Select Hand Card 4', '4'),
                    _buildKeyAssignmentRow('Select Hand Card 5', '5'),
                    const Divider(color: Colors.white10, height: 32),
                    _sectionTitle('DESKTOP HOTKEYS'),
                    const SizedBox(height: 8),
                    _buildKeyAssignmentRow('Pause', '0'),
                    _buildKeyAssignmentRow('Slow Speed', '1'),
                    _buildKeyAssignmentRow('Normal Speed', '2'),
                    _buildKeyAssignmentRow('Fast Speed', '3'),
                    _buildKeyAssignmentRow('Lightning Speed', '4'),
                    _buildKeyAssignmentRow('Manor View', 'U'),
                    _buildKeyAssignmentRow('Manor Holdings', 'I'),
                    _buildKeyAssignmentRow('Chronicle Records', 'O'),
                    _buildKeyAssignmentRow('Survey Estate Map', 'P'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE5D5B0),
                  side: const BorderSide(color: Color(0xFFC4B89B)),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'CLOSE AND APPLY',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.playfairDisplay(
        color: const Color(0xFFE5D5B0),
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildRadioOption<T>({
    required BuildContext context,
    required String title,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFFE5D5B0) : Colors.white24,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.oldStandardTt(
                  color: isSelected ? const Color(0xFFE5D5B0) : Colors.white54,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyAssignmentRow(String action, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            action,
            style: GoogleFonts.oldStandardTt(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF241F1A),
              border: Border.all(
                color: const Color(0xFFC4B89B).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '[$key]',
              style: GoogleFonts.oswald(
                color: const Color(0xFFE5D5B0),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
