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
import '../../models/active_business.dart';
import '../../models/graduate_school_state.dart';
import '../../services/academic_exam_service.dart';

class CheatCodesDialog extends StatelessWidget {
  const CheatCodesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1612),
      shape: const RoundedRectangleBorder(),
      child: Consumer<GameState>(
        builder: (context, state, child) {
          return Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC4B89B), width: 1.5),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "CHEAT CODES & DEBUG",
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFFE5D5B0), size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 24),

                  // Quick Resources Cheats
                  Text(
                    "QUICK DATA MODIFIERS",
                    style: GoogleFonts.oswald(
                      color: const Color(0xFFC4B89B),
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            state.cheatAddFunds();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Added 1,000 CHF to manor holdings.")),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF241F1A),
                            foregroundColor: const Color(0xFFE5D5B0),
                            side: const BorderSide(color: Color(0xFFC4B89B)),
                            shape: const RoundedRectangleBorder(),
                          ),
                          icon: const Icon(Icons.payments, size: 14),
                          label: Text("ADD 1,000 CHF", style: GoogleFonts.oswald(fontSize: 10)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            state.cheatAddShepherdsPies();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Added 20 Shepherd's Pies to pantry.")),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF241F1A),
                            foregroundColor: const Color(0xFFE5D5B0),
                            side: const BorderSide(color: Color(0xFFC4B89B)),
                            shape: const RoundedRectangleBorder(),
                          ),
                          icon: const Icon(Icons.restaurant, size: 14),
                          label: Text("ADD 20 PIES", style: GoogleFonts.oswald(fontSize: 10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        state.cheatTriggerVisitor();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Visitor event triggered in the entryway!")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF241F1A),
                        foregroundColor: const Color(0xFFE5D5B0),
                        side: const BorderSide(color: Color(0xFFC4B89B)),
                        shape: const RoundedRectangleBorder(),
                      ),
                      icon: const Icon(Icons.person_add, size: 14),
                      label: Text("TRIGGER VISITOR EVENT", style: GoogleFonts.oswald(fontSize: 10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        state.cheatSendSuperMerchant();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Super Merchant Silas has arrived in the entryway!")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF241F1A),
                        foregroundColor: const Color(0xFFE5D5B0),
                        side: const BorderSide(color: Color(0xFFC4B89B)),
                        shape: const RoundedRectangleBorder(),
                      ),
                      icon: const Icon(Icons.storefront, size: 14),
                      label: Text("SEND SUPER MERCHANT", style: GoogleFonts.oswald(fontSize: 10)),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),

                  // Instant Adaptation Cheats
                  Text(
                    "INSTANT BUSINESS ADAPTATIONS",
                    style: GoogleFonts.oswald(
                      color: const Color(0xFFC4B89B),
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "INSTANTLY ESTABLISH A COMPLETED, OPERATIONAL BUSINESS VENTURE AT GLARUS:",
                    style: GoogleFonts.oldStandardTt(
                      color: Colors.white38,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: BusinessType.values.map((type) {
                      return SizedBox(
                        width: 210,
                        child: ElevatedButton(
                          onPressed: () {
                            state.cheatInstantVenture(type);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Instantly established completed ${type.displayName}!")),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black38,
                            foregroundColor: const Color(0xFFE5D5B0),
                            side: const BorderSide(color: Colors.white10),
                            shape: const RoundedRectangleBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            type.displayName.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),

                  // Academic exam debug selector
                  Text(
                    "LAUNCH ACADEMIC EXAM DEBUGGER",
                    style: GoogleFonts.oswald(
                      color: const Color(0xFFC4B89B),
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "SIT FOR ANY ADMISSIONS, SEMESTER, OR PROFESSIONAL BAR/BOARD QUALIFICATION EXAM INSTANTLY:",
                    style: GoogleFonts.oldStandardTt(
                      color: Colors.white38,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFC4B89B)),
                      color: Colors.black26,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        hint: Text(
                          "CHOOSE DISCIPLINE TEST TO START",
                          style: GoogleFonts.oldStandardTt(color: const Color(0xFFE5D5B0), fontSize: 11),
                        ),
                        dropdownColor: const Color(0xFF1A1612),
                        onChanged: (val) {
                          if (val != null) {
                            Navigator.pop(context);
                            _launchSpecificTest(context, state, val);
                          }
                        },
                        items: const [
                          DropdownMenuItem(value: 'law_0', child: Text("ADMISSIONS EXAM - FACULTY OF LAW")),
                          DropdownMenuItem(value: 'law_1', child: Text("PRACTICAL EXAM - FACULTY OF LAW")),
                          DropdownMenuItem(value: 'law_4', child: Text("BOARD/BAR EXAM - FACULTY OF LAW")),
                          DropdownMenuItem(value: 'pharmacy_0', child: Text("ADMISSIONS EXAM - PHARMACY SCHOOL")),
                          DropdownMenuItem(value: 'pharmacy_1', child: Text("PRACTICAL EXAM - PHARMACY SCHOOL")),
                          DropdownMenuItem(value: 'pharmacy_4', child: Text("BOARD EXAM - PHARMACY SCHOOL")),
                          DropdownMenuItem(value: 'medicine_0', child: Text("ADMISSIONS EXAM - MEDICAL SCHOOL")),
                          DropdownMenuItem(value: 'medicine_1', child: Text("PRACTICAL EXAM - MEDICAL SCHOOL")),
                          DropdownMenuItem(value: 'medicine_4', child: Text("BOARD EXAM - MEDICAL SCHOOL")),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),

                  // Specific Graduate Degrees Conferred cheat switches
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "LAW DEGREE CONFERRED:",
                        style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 10),
                      ),
                      Switch(
                        value: state.hasGraduateDegree(AcademicSchoolType.law),
                        activeThumbColor: const Color(0xFFC4B89B),
                        onChanged: (val) => state.toggleGraduateDegree(AcademicSchoolType.law, val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "MEDICAL DEGREE CONFERRED:",
                        style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 10),
                      ),
                      Switch(
                        value: state.hasGraduateDegree(AcademicSchoolType.medicine),
                        activeThumbColor: const Color(0xFFC4B89B),
                        onChanged: (val) => state.toggleGraduateDegree(AcademicSchoolType.medicine, val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "PHARMACEUTICAL DEGREE CONFERRED:",
                        style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 10),
                      ),
                      Switch(
                        value: state.hasGraduateDegree(AcademicSchoolType.pharmacy),
                        activeThumbColor: const Color(0xFFC4B89B),
                        onChanged: (val) => state.toggleGraduateDegree(AcademicSchoolType.pharmacy, val),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _launchSpecificTest(BuildContext context, GameState state, String key) {
    final parts = key.split('_');
    final disciplineStr = parts[0];
    final int semesterVal = int.parse(parts[1]);

    final AcademicSchoolType schoolType = disciplineStr == 'law'
        ? AcademicSchoolType.law
        : (disciplineStr == 'pharmacy' ? AcademicSchoolType.pharmacy : AcademicSchoolType.medicine);

    final questions = AcademicExamService.getExamQuestions(
      type: schoolType,
      stage: semesterVal,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        int score = 0;
        int currentQ = 0;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final q = questions[currentQ];

            return AlertDialog(
              backgroundColor: const Color(0xFF1E1A15),
              title: Text(
                "ACADEMIC EXAM - DEBUG PREVIEW [Q ${currentQ + 1}/${questions.length}]",
                style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 13, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.question,
                    style: GoogleFonts.oldStandardTt(color: Colors.white, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(q.choices.length, (cIdx) {
                    final choice = q.choices[cIdx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          if (cIdx == q.correct) {
                            score++;
                          }

                          if (currentQ + 1 < questions.length) {
                            setModalState(() {
                              currentQ++;
                            });
                          } else {
                            Navigator.pop(context); // close test

                            final isBoard = semesterVal == 4;
                            final int threshold = isBoard ? 5 : 3;
                            final bool passed = score >= threshold;

                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF1E1A15),
                                title: Text(
                                  passed ? "EXAM PASSED!" : "EXAM FAILED!",
                                  style: GoogleFonts.playfairDisplay(color: passed ? Colors.green : Colors.redAccent),
                                ),
                                content: Text(
                                  isBoard 
                                      ? (passed 
                                          ? "BOARD DECREE: CONGRATULATIONS! Passed the professional Board Qualification."
                                          : "BOARD DECREE: FAILED. Did not meet the strict passing standards of the Board.")
                                      : "Score: $score/4. Passed: $passed. (Debug preview completed).",
                                  style: GoogleFonts.oldStandardTt(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("CLOSE", style: GoogleFonts.oldStandardTt(color: const Color(0xFFE5D5B0))),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFC4B89B)),
                          shape: const RoundedRectangleBorder(),
                          padding: const EdgeInsets.all(12),
                        ),
                        child: Text(
                          choice.toUpperCase(),
                          style: GoogleFonts.oldStandardTt(color: const Color(0xFFE5D5B0), fontSize: 10),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
