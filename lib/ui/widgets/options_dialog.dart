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

class OptionsDialog extends StatelessWidget {
  const OptionsDialog({super.key});

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
        width: 520,
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
                  'GAME OPTIONS',
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
                    // 1. Combat Controls Section
                    _sectionTitle('1. COMBAT CONTROLS'),
                    const SizedBox(height: 8),
                    _subSectionTitle('MOBILE MOVEMENT CONTROL'),
                    _buildRadioOption<String>(
                      context: context,
                      title: 'Directional Pad',
                      value: 'pad',
                      groupValue: state.combatControlMode,
                      onChanged: (val) => state.setCombatControlMode(val!),
                    ),
                    _buildRadioOption<String>(
                      context: context,
                      title: 'Waypoint Click',
                      value: 'click',
                      groupValue: state.combatControlMode,
                      onChanged: (val) => state.setCombatControlMode(val!),
                    ),
                    const SizedBox(height: 12),
                    _subSectionTitle('DESKTOP KEY ASSIGNMENTS'),
                    _buildKeyAssignmentRow('Move Left', 'A'),
                    _buildKeyAssignmentRow('Move Up', 'W'),
                    _buildKeyAssignmentRow('Move Right', 'D'),
                    _buildKeyAssignmentRow('Move Down', 'S'),
                    _buildKeyAssignmentRow('1st Special Action', 'R'),
                    _buildKeyAssignmentRow('2nd Special Action', 'F'),
                    _buildKeyAssignmentRow('Select Hand Card 1', '1'),
                    _buildKeyAssignmentRow('Select Hand Card 2', '2'),
                    _buildKeyAssignmentRow('Select Hand Card 3', '3'),
                    _buildKeyAssignmentRow('Select Hand Card 4', '4'),
                    _buildKeyAssignmentRow('Select Hand Card 5', '5'),
                    const SizedBox(height: 12),
                    _subSectionTitle('DESKTOP HOTKEYS'),
                    _buildKeyAssignmentRow('Pause', '0'),
                    _buildKeyAssignmentRow('Slow Speed', '1'),
                    _buildKeyAssignmentRow('Normal Speed', '2'),
                    _buildKeyAssignmentRow('Fast Speed', '3'),
                    _buildKeyAssignmentRow('Lightning Speed', '4'),
                    _buildKeyAssignmentRow('Manor View', 'U'),
                    _buildKeyAssignmentRow('Manor Holdings', 'I'),
                    _buildKeyAssignmentRow('Chronicle Records', 'O'),
                    _buildKeyAssignmentRow('Survey Estate Map', 'P'),
                    const Divider(color: Colors.white10, height: 32),

                    // 2. Emergency Behavior Section
                    _sectionTitle('2. WHEN AN EMERGENCY OCCURS'),
                    const SizedBox(height: 8),
                    _buildRadioOption<String>(
                      context: context,
                      title: 'Reduce game speed to Slow',
                      value: 'slow',
                      groupValue: state.emergencyBehavior,
                      onChanged: (val) => state.setEmergencyBehavior(val!),
                    ),
                    _buildRadioOption<String>(
                      context: context,
                      title: 'Pause the game',
                      value: 'pause',
                      groupValue: state.emergencyBehavior,
                      onChanged: (val) => state.setEmergencyBehavior(val!),
                    ),
                    _buildRadioOption<String>(
                      context: context,
                      title: 'Reduce game speed to Normal',
                      value: 'normal',
                      groupValue: state.emergencyBehavior,
                      onChanged: (val) => state.setEmergencyBehavior(val!),
                    ),
                    _buildRadioOption<String>(
                      context: context,
                      title: 'Do nothing',
                      value: 'nothing',
                      groupValue: state.emergencyBehavior,
                      onChanged: (val) => state.setEmergencyBehavior(val!),
                    ),
                    const Divider(color: Colors.white10, height: 32),

                    // 3. Sleep Acceleration Section
                    _sectionTitle('3. WHEN ALL RESIDENTS ARE ASLEEP'),
                    const SizedBox(height: 8),
                    _buildRadioOption<String>(
                      context: context,
                      title: 'Accelerate game speed to Lightning',
                      value: 'lightning',
                      groupValue: state.residentsAsleepBehavior,
                      onChanged: (val) =>
                          state.setResidentsAsleepBehavior(val!),
                    ),
                    _buildRadioOption<String>(
                      context: context,
                      title: 'Accelerate game speed to Fast',
                      value: 'fast',
                      groupValue: state.residentsAsleepBehavior,
                      onChanged: (val) =>
                          state.setResidentsAsleepBehavior(val!),
                    ),
                    _buildRadioOption<String>(
                      context: context,
                      title: 'Do nothing',
                      value: 'nothing',
                      groupValue: state.residentsAsleepBehavior,
                      onChanged: (val) =>
                          state.setResidentsAsleepBehavior(val!),
                    ),
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
                  'CONFIRM AND APPLY',
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
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _subSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: const Color(0xFFC4B89B),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFFE5D5B0) : Colors.white24,
              size: 16,
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
      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 16.0),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
