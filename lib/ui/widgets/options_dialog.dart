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
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import '../../services/audio_service.dart';

class OptionsDialog extends StatelessWidget {
  final bool isSurvivalMode;
  const OptionsDialog({super.key, this.isSurvivalMode = false});

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
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Audio Settings Section
                    _sectionTitle('1. AUDIO SETTINGS'),
                    const SizedBox(height: 8),
                    _buildToggleOption(
                      context: context,
                      title: 'SOUND',
                      value: state.soundEnabled,
                      onChanged: (val) => state.setSoundEnabled(val),
                    ),
                    IgnorePointer(
                      ignoring: !state.soundEnabled,
                      child: Opacity(
                        opacity: state.soundEnabled ? 1.0 : 0.3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            _buildToggleOption(
                              context: context,
                              title: 'Music',
                              value: state.musicEnabled,
                              onChanged: (val) => state.setMusicEnabled(val),
                            ),
                            _buildVolumeSlider(
                              context: context,
                              title: 'Music Volume',
                              value: state.musicVolume,
                              onChanged: (val) => state.setMusicVolume(val),
                              disabled: !state.musicEnabled,
                            ),
                            const SizedBox(height: 8),
                            _buildToggleOption(
                              context: context,
                              title: 'Sound Effects',
                              value: state.sfxEnabled,
                              onChanged: (val) => state.setSfxEnabled(val),
                            ),
                            _buildVolumeSlider(
                              context: context,
                              title: 'Sound Effects Volume',
                              value: state.sfxVolume,
                              onChanged: (val) => state.setSfxVolume(val),
                              disabled: !state.sfxEnabled,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 32),

                    // 2. Combat Controls Section
                    _sectionTitle('2. COMBAT CONTROLS'),
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
                    _subSectionTitle('COMBAT KEY ASSIGNMENTS'),
                    _buildKeyAssignmentRow(context, state, 'Move Left', 'A'),
                    _buildKeyAssignmentRow(context, state, 'Move Up', 'W'),
                    _buildKeyAssignmentRow(context, state, 'Move Right', 'D'),
                    _buildKeyAssignmentRow(context, state, 'Move Down', 'S'),
                    _buildKeyAssignmentRow(
                      context,
                      state,
                      '1st Special Action',
                      'R',
                    ),
                    _buildKeyAssignmentRow(
                      context,
                      state,
                      '2nd Special Action',
                      'F',
                    ),
                    _buildKeyAssignmentRow(
                      context,
                      state,
                      'Select Hand Card 1',
                      '1',
                    ),
                    _buildKeyAssignmentRow(
                      context,
                      state,
                      'Select Hand Card 2',
                      '2',
                    ),
                    _buildKeyAssignmentRow(
                      context,
                      state,
                      'Select Hand Card 3',
                      '3',
                    ),
                    _buildKeyAssignmentRow(
                      context,
                      state,
                      'Select Hand Card 4',
                      '4',
                    ),
                    _buildKeyAssignmentRow(
                      context,
                      state,
                      'Select Hand Card 5',
                      '5',
                    ),

                    if (!isSurvivalMode) ...[
                      const SizedBox(height: 12),
                      _subSectionTitle('DESKTOP HOTKEYS'),
                      _buildKeyAssignmentRow(context, state, 'Pause', '0'),
                      _buildKeyAssignmentRow(context, state, 'Slow Speed', '1'),
                      _buildKeyAssignmentRow(
                        context,
                        state,
                        'Normal Speed',
                        '2',
                      ),
                      _buildKeyAssignmentRow(context, state, 'Fast Speed', '3'),
                      _buildKeyAssignmentRow(
                        context,
                        state,
                        'Lightning Speed',
                        '4',
                      ),
                      _buildKeyAssignmentRow(context, state, 'Manor View', 'U'),
                      _buildKeyAssignmentRow(
                        context,
                        state,
                        'Manor Holdings',
                        'I',
                      ),
                      _buildKeyAssignmentRow(
                        context,
                        state,
                        'Chronicle Records',
                        'O',
                      ),
                      _buildKeyAssignmentRow(
                        context,
                        state,
                        'Survey Estate Map',
                        'P',
                      ),
                      const SizedBox(height: 12),
                      _subSectionTitle('DIALOGUE & NARRATIVE HOTKEYS'),
                      _buildKeyAssignmentRow(
                        context,
                        state,
                        'Dialogue Option 1',
                        '1',
                      ),
                      _buildKeyAssignmentRow(
                        context,
                        state,
                        'Dialogue Option 2',
                        '2',
                      ),
                      _buildKeyAssignmentRow(
                        context,
                        state,
                        'Dialogue Option 3',
                        '3',
                      ),
                      _buildKeyAssignmentRow(
                        context,
                        state,
                        'Dialogue Option 4',
                        '4',
                      ),
                      _buildKeyAssignmentRow(
                        context,
                        state,
                        'Dialogue Option 5',
                        '5',
                      ),
                      _buildKeyAssignmentRow(
                        context,
                        state,
                        'Dialogue Option 6',
                        '6',
                      ),
                      _buildKeyAssignmentRow(
                        context,
                        state,
                        'Dialogue Option 7',
                        '7',
                      ),
                      _buildKeyAssignmentRow(
                        context,
                        state,
                        'Next Dialogue / Scene',
                        '9',
                      ),
                      _buildKeyAssignmentRow(
                        context,
                        state,
                        'Back Dialogue / Scene',
                        '8',
                      ),
                      const Divider(color: Colors.white10, height: 32),

                      // 3. Emergency Behavior Section
                      _sectionTitle('3. WHEN AN EMERGENCY OCCURS'),
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

                      // 4. Visitor Arrival Section
                      _sectionTitle('4. WHEN A VISITOR ARRIVES'),
                      const SizedBox(height: 8),
                      _buildRadioOption<String>(
                        context: context,
                        title: 'Pause the game',
                        value: 'pause',
                        groupValue: state.visitorArrivalBehavior,
                        onChanged: (val) => state.setVisitorArrivalBehavior(val!),
                      ),
                      _buildRadioOption<String>(
                        context: context,
                        title: 'Reduce game speed to Slow',
                        value: 'slow',
                        groupValue: state.visitorArrivalBehavior,
                        onChanged: (val) => state.setVisitorArrivalBehavior(val!),
                      ),
                      _buildRadioOption<String>(
                        context: context,
                        title: 'Reduce game speed to Normal',
                        value: 'normal',
                        groupValue: state.visitorArrivalBehavior,
                        onChanged: (val) => state.setVisitorArrivalBehavior(val!),
                      ),
                      _buildRadioOption<String>(
                        context: context,
                        title: 'Do nothing',
                        value: 'nothing',
                        groupValue: state.visitorArrivalBehavior,
                        onChanged: (val) => state.setVisitorArrivalBehavior(val!),
                      ),
                      const Divider(color: Colors.white10, height: 32),

                      // 5. Sleep Acceleration Section
                      _sectionTitle('5. WHEN ALL RESIDENTS ARE ASLEEP'),
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF8B0000,
                  ), // Dark Crimson Red / Factory Warning
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  AudioService().playTap();
                  state.resetToFactorySettings();
                },
                child: Text(
                  'FACTORY SETTINGS',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
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
      onTap: () {
        AudioService().playTap();
        onChanged(value);
      },
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

  Widget _buildKeyAssignmentRow(
    BuildContext context,
    GameState state,
    String action,
    String fallbackKey,
  ) {
    final key = state.hotkeys[action] ?? fallbackKey;
    return InkWell(
      onTap: () {
        AudioService().playTap();
        _showKeyReassignmentDialog(context, action);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              action,
              style: GoogleFonts.oldStandardTt(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF241F1A),
                border: Border.all(
                  color: const Color(0xFFC4B89B).withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(4),
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
      ),
    );
  }

  void _showKeyReassignmentDialog(BuildContext context, String action) {
    final state = Provider.of<GameState>(context, listen: false);
    state.setReassigningHotkey(true);
    final focusNode = FocusNode();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return KeyboardListener(
          focusNode: focusNode,
          autofocus: true,
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              final newKey = event.logicalKey.keyLabel.toUpperCase();
              if (newKey.isNotEmpty && newKey.length <= 12) {
                state.setHotkey(action, newKey);
                AudioService().playTaskAssignment();
                state.setReassigningHotkey(false);
                Navigator.pop(ctx);
              }
            }
          },
          child: Dialog(
            backgroundColor: const Color(0xFF1A1612),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: Color(0xFFC4B89B), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.keyboard_alt_outlined,
                    color: Color(0xFFE5D5B0),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "REASSIGN HOTKEY",
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Press any key on your keyboard to map to:\n$action",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.oldStandardTt(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE5D5B0),
                      side: const BorderSide(color: Color(0xFFC4B89B)),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onPressed: () {
                      state.setReassigningHotkey(false);
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      "CANCEL",
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      focusNode.dispose();
      state.setReassigningHotkey(false);
    });
  }

  Widget _buildToggleOption({
    required BuildContext context,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.oldStandardTt(
              color: const Color(0xFFE5D5B0),
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              _buildToggleButton('ON', value == true, () => onChanged(true)),
              const SizedBox(width: 8),
              _buildToggleButton('OFF', value == false, () => onChanged(false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        AudioService().playTap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC4B89B) : const Color(0xFF241F1A),
          border: Border.all(
            color: isSelected ? const Color(0xFFE5D5B0) : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.oswald(
            color: isSelected ? const Color(0xFF1A1612) : Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeSlider({
    required BuildContext context,
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
    bool disabled = false,
  }) {
    return IgnorePointer(
      ignoring: disabled,
      child: Opacity(
        opacity: disabled ? 0.3 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.oldStandardTt(
                  color: const Color(0xFFC4B89B),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFFE5D5B0),
                  inactiveTrackColor: Colors.white10,
                  thumbColor: const Color(0xFFC4B89B),
                  overlayColor: const Color(0xFFC4B89B).withValues(alpha: 0.2),
                  trackHeight: 2.0,
                ),
                child: Slider(
                  value: value,
                  min: 0.0,
                  max: 1.0,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
