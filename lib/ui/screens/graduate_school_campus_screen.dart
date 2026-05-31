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
import 'package:collection/collection.dart';
import '../../state/game_state.dart';
import '../../models/graduate_school_state.dart';
import '../../services/academic_exam_service.dart';

class GraduateSchoolCampusScreen extends StatefulWidget {
  const GraduateSchoolCampusScreen({super.key});

  @override
  State<GraduateSchoolCampusScreen> createState() => _GraduateSchoolCampusScreenState();
}

class _GraduateSchoolCampusScreenState extends State<GraduateSchoolCampusScreen> {
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);
    final grad = state.graduateSchool;

    if (grad == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1612),
        body: Center(
          child: Text("NO ACADEMIC STATE FOUND.", style: GoogleFonts.oldStandardTt(color: Colors.white24)),
        ),
      );
    }

    final player = state.npcs.firstWhereOrNull((n) => n.id == 'player');
    final bool isAtSchool = player?.worldDestinationId == 'graduate_school';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      appBar: AppBar(
        title: Text(
          grad.type.displayName.toUpperCase(),
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 16,
            color: const Color(0xFFE5D5B0),
          ),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE5D5B0)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF241F1A),
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Left Panel: Academic log and status
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(20),
                color: Colors.black12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ACADEMIC CHRONICLE",
                      style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold),
                    ),
                    const Divider(color: Colors.white10, height: 20),
                    Expanded(
                      child: ListView(
                        children: grad.academicLogs.map((log) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              log.toUpperCase(),
                              style: GoogleFonts.oldStandardTt(color: const Color(0xFFC4B89B), fontSize: 11),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 24),

            // Right Panel: Controls and Active Semester Exam / Complication
            Expanded(
              flex: 4,
              child: _buildRightPanel(context, state, grad, isAtSchool),
            ),
          ],
        ),
      ),
    );
  }

  void _startAcademicTest(BuildContext context, GameState state, GraduateSchoolState grad) {
    final questions = AcademicExamService.getExamQuestions(
      type: grad.type,
      stage: grad.currentSemester,
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
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              title: Text(
                "ACADEMIC EXAM - QUESTION ${currentQ + 1}/${questions.length}",
                style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.question.replaceFirst(RegExp(r'^[^:\n]+:\n'), ''),
                        style: GoogleFonts.oldStandardTt(color: Colors.white, fontSize: 11.5, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      
                      // CONSULT LIBRARY BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showReferenceTomesDialog(context);
                          },
                          icon: const Icon(Icons.menu_book, color: Color(0xFFC4B89B), size: 13),
                          label: Text(
                            "CONSULT ACADEMIC TOMES",
                            style: GoogleFonts.oswald(color: const Color(0xFFE5D5B0), fontSize: 9.5, letterSpacing: 1),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...List.generate(q.choices.length, (cIdx) {
                        final choice = q.choices[cIdx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
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
                                Navigator.pop(context); // close test dialog

                                final isSurgery = grad.specialization == 'Surgery';
                                final finalSemester = isSurgery ? 5 : 4;
                                final isBoard = grad.currentSemester == finalSemester;
                                final int threshold = isBoard ? 5 : 3;
                                final bool passed = score >= threshold;
                                
                                state.checkAcademicExam(passed, score: score);

                                if (passed) {
                                  String bonusMsg = "";
                                  if (!isBoard && score == 4) {
                                    // Perfect score bonus!
                                    if (grad.type == AcademicSchoolType.law) {
                                      state.updateResource('funds', 100);
                                      state.adjustNpcSatisfaction('player', 30.0);
                                      bonusMsg = "\n\nHONOR: INDUCTED INTO THE ORDER OF THE COIF! (+30 Satisfaction, +100 CHF).";
                                    } else if (grad.type == AcademicSchoolType.pharmacy) {
                                      state.updateResource('funds', 150);
                                      bonusMsg = "\n\nHONOR: APPOINTED TO A COVETED TEACHING ASSISTANT POSITION! (+150 CHF).";
                                    } else if (grad.type == AcademicSchoolType.medicine) {
                                      state.updateResource('funds', 250);
                                      bonusMsg = "\n\nHONOR: IMPERIAL MEDICAL CASH SCHOLARSHIP CONFERRED! (+250 CHF).";
                                    }
                                  }

                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: const Color(0xFF1E1A15),
                                      title: Text("EXAMINATION PASSED!", style: GoogleFonts.playfairDisplay(color: Colors.green)),
                                      content: Text(
                                        isBoard 
                                            ? "BOARD DECREE: CONGRATULATIONS! Alfonso Giles has successfully met the qualifying standards of the Imperial Board."
                                            : "TERM RESULT: Alfonso passed the practical test with a score of $score/4.$bonusMsg",
                                        style: GoogleFonts.oldStandardTt(color: Colors.white70),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text("EXCELLENT", style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0))),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: const Color(0xFF1E1A15),
                                      title: Text("EXAMINATION FAILED!", style: GoogleFonts.playfairDisplay(color: Colors.redAccent)),
                                      content: Text(
                                        isBoard 
                                            ? "BOARD DECREE: FAILED. Alphonse Giles has failed to meet the strict passing standards of the Imperial Board."
                                            : "TERM RESULT: Alfonso failed the practical test with a score of $score/4. Spend more time studying to prepare a retake.",
                                        style: GoogleFonts.oldStandardTt(color: Colors.white70),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text("UNDERSTOOD", style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0))),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFC4B89B)),
                              shape: const RoundedRectangleBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            ),
                            child: Text(
                              choice.toUpperCase(),
                              style: GoogleFonts.oldStandardTt(color: const Color(0xFFE5D5B0), fontSize: 9.5),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReferenceTomesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1A15),
          shape: const RoundedRectangleBorder(),
          child: Container(
            width: 600,
            height: 500,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC4B89B), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "GENEVA IMPERIAL LIBRARY",
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  "ACADEMIC REFERENCE TREATISES AND COVENANTS:",
                  style: GoogleFonts.oldStandardTt(color: const Color(0xFFC4B89B), fontSize: 10),
                ),
                const Divider(color: Colors.white10, height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: AcademicExamService.referenceTomes.length,
                    itemBuilder: (context, index) {
                      final tome = AcademicExamService.referenceTomes[index];
                      return ExpansionTile(
                        iconColor: const Color(0xFFE5D5B0),
                        collapsedIconColor: const Color(0xFFC4B89B),
                        title: Text(
                          tome.title,
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFFE5D5B0),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.black12,
                            child: Text(
                              tome.content,
                              style: GoogleFonts.oldStandardTt(
                                color: Colors.white70,
                                fontSize: 11.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC4B89B),
                        foregroundColor: Colors.black,
                        shape: const RoundedRectangleBorder(),
                      ),
                      child: Text("CLOSE LIBRARY", style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRightPanel(BuildContext context, GameState state, GraduateSchoolState grad, bool isAtSchool) {
    final bool isSpecializationSelectionRequired =
        (grad.type == AcademicSchoolType.medicine || grad.type == AcademicSchoolType.law) &&
        grad.currentSemester >= 3 &&
        grad.specialization == null;

    if (isSpecializationSelectionRequired) {
      return _buildSpecializationSelection(context, state, grad);
    }

    final isSurgery = grad.specialization == 'Surgery';
    final finalSemester = isSurgery ? 5 : 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Semester Indicator
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.black26,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                grad.currentSemester == 0
                    ? "ENTRANCE EXAMINATIONS"
                    : (grad.currentSemester == finalSemester
                        ? "FINAL BOARD/BAR EXAMINATIONS"
                        : (grad.currentSemester == 4 && isSurgery
                            ? "SURGERY SPECIALIZATION TERM"
                            : "SEMESTER ${grad.currentSemester} TERM")),
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "STUDY PROGRESS: ${(grad.studyProgress * 100).toInt()}%",
                style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: grad.studyProgress,
                color: const Color(0xFFC4B89B),
                backgroundColor: Colors.white10,
              ),
              if (grad.specialization != null) ...[
                const SizedBox(height: 8),
                Text(
                  "SPECIALIZATION: ${grad.specialization!.toUpperCase()}",
                  style: GoogleFonts.oswald(color: const Color(0xFFCDDC39), fontSize: 11, letterSpacing: 1),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Tuition requirements
        if (grad.currentSemester > 0 && !grad.tuitionPaid)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.redAccent),
              color: Colors.redAccent.withValues(alpha: 0.05),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SEMESTER TUITION DUE: 500 CHF",
                  style: GoogleFonts.oswald(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "TUITION MUST BE SETTLED BEFORE ATTENDING LECTURES AND CONFERRING TERM MARKS.",
                  style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    state.paySemesterTuition();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC4B89B),
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: Text("SETTLE TUITION (500 CHF)", style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
          )
        else if (grad.currentComplication.isNotEmpty)
          // Complication Active
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC4B89B)),
              color: Colors.black12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Color(0xFFE5D5B0), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      grad.currentComplication['title'].toString().toUpperCase(),
                      style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 16),
                Text(
                  grad.currentComplication['description'].toString(),
                  style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 11, height: 1.3),
                ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          state.resolveSemesterComplication('school');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC4B89B),
                          foregroundColor: Colors.black,
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: Text(
                          "REMAIN IN SCHOOL (ACCEPT SACRIFICE)",
                          style: GoogleFonts.playfairDisplay(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          state.resolveSemesterComplication('quit');
                          Navigator.pop(context); // return home
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: Text(
                          "QUIT SCHOOL & RETURN HOME (RESET)",
                          style: GoogleFonts.playfairDisplay(fontSize: 10, color: Colors.redAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else if (grad.studyProgress >= 1.0 && grad.hasCompletedAssignment)
          // Ready for Test!
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "READY FOR EXAMINATION",
                  style: GoogleFonts.oswald(color: Colors.green, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  "ALL SEMESTER LECTURES AND COMPLICATIONS COMPLETED. SIT THE PRACTICAL REVIEW BOARD EXAM NOW.",
                  style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 10),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _startAcademicTest(context, state, grad);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC4B89B),
                      foregroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: Text("SIT FOR EXAMINATION", style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "LECTURES IN PROGRESS",
                  style: GoogleFonts.oswald(color: const Color(0xFFC4B89B), letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  "STUDY REVIEWS RUN AUTOMATICALLY ON TRIAL TICKS. LET TIME PASS AT FAST SPEEDS IN THE MANOR OR WORLD MAP TO COMPLETE THE TERM WORK.",
                  style: GoogleFonts.oldStandardTt(color: Colors.white24, fontSize: 10, height: 1.3),
                ),
              ],
            ),
          ),

        const Spacer(),

        // Return option
        if (isAtSchool && grad.currentSemester != 0 && grad.currentSemester != finalSemester)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                state.returnToManor('player');
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFC4B89B)),
                shape: const RoundedRectangleBorder(),
              ),
              icon: const Icon(Icons.keyboard_return, color: Color(0xFFE5D5B0), size: 16),
              label: Text("SUSPEND STUDIES & RETURN HOME", style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0))),
            ),
          ),
      ],
    );
  }

  Widget _buildSpecializationSelection(BuildContext context, GameState state, GraduateSchoolState grad) {
    final double avgScore = grad.semesterScores.isEmpty
        ? 4.0
        : grad.semesterScores.reduce((a, b) => a + b) / grad.semesterScores.length;
    final bool isEligibleForSurgery = avgScore >= 3.0;

    if (grad.type == AcademicSchoolType.medicine) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC4B89B), width: 1.5),
          color: Colors.black12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "CHOOSE YOUR MEDICAL SPECIALIZATION",
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFE5D5B0),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "YOUR ACADEMIC STANDING MUST SUPPORT YOUR PREFERRED SPECIALTY PATHWAY. CHOOSE WISELY.",
              style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 9),
            ),
            const Divider(color: Colors.white10, height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildSpecialtyCard(
                    title: "PSYCHIATRY",
                    description: "Explore the alchemical depths of human sanity and madness. Balanced and traditional study path.",
                    onTap: () => state.selectAcademicSpecialization("Psychiatry"),
                  ),
                  _buildSpecialtyCard(
                    title: "SURGERY",
                    description: "Master advanced invasive clinical anatomy. Requires high academic excellence and an extra semester.",
                    locked: !isEligibleForSurgery,
                    lockMessage: "Requires good grades (average score 3.0+). Your average: ${avgScore.toStringAsFixed(1)}/4.0.",
                    onTap: () => state.selectAcademicSpecialization("Surgery"),
                  ),
                  _buildSpecialtyCard(
                    title: "VETERINARY MEDICINE",
                    description: "Focus on animal specimens (Rats, Hounds). Completed in normal time and requires lower grades, but carries a severe penalty to human surgeries until overcome with clinical experience.",
                    onTap: () => state.selectAcademicSpecialization("Veterinary"),
                  ),
                  _buildSpecialtyCard(
                    title: "INTERNIST",
                    description: "General medical expert. Ability to hire and manage other doctors and specialized staff.",
                    onTap: () => state.selectAcademicSpecialization("Internist"),
                  ),
                  _buildSpecialtyCard(
                    title: "DENTISTRY",
                    description: "Lucrative and straightforward practical dental science. Provides a massive 1,000 CHF graduation bonus, but offers limited research/innovative value.",
                    onTap: () => state.selectAcademicSpecialization("Dentistry"),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Law school specialties
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC4B89B), width: 1.5),
          color: Colors.black12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "CHOOSE YOUR LEGAL SPECIALIZATION",
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFE5D5B0),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "SELECT YOUR LEGAL SPECIALIZATION COVENANT.",
              style: GoogleFonts.oldStandardTt(color: Colors.white38, fontSize: 9),
            ),
            const Divider(color: Colors.white10, height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildSpecialtyCard(
                    title: "CRIMINAL LAW",
                    description: "Litigation, evidence rules, subterfuge, and witness intimidation. Highly tactical.",
                    onTap: () => state.selectAcademicSpecialization("Criminal Law"),
                  ),
                  _buildSpecialtyCard(
                    title: "INTELLECTUAL PROPERTY",
                    description: "Copyright licenses, patents, trademarks, contracts, and negotiations.",
                    onTap: () => state.selectAcademicSpecialization("Intellectual Property"),
                  ),
                  _buildSpecialtyCard(
                    title: "TORTS",
                    description: "Generalist legal chambers handling standard liability, damage recovery, and civil torts.",
                    onTap: () => state.selectAcademicSpecialization("Torts"),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSpecialtyCard({
    required String title,
    required String description,
    required VoidCallback onTap,
    bool locked = false,
    String? lockMessage,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: locked ? Colors.red.withValues(alpha: 0.3) : const Color(0xFFC4B89B).withValues(alpha: 0.5)),
        color: locked ? Colors.redAccent.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.02),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Row(
          children: [
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                color: locked ? Colors.redAccent : const Color(0xFFE5D5B0),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (locked) ...[
              const SizedBox(width: 8),
              const Icon(Icons.lock, color: Colors.redAccent, size: 12),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              description,
              style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 10, height: 1.3),
            ),
            if (locked && lockMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                lockMessage,
                style: GoogleFonts.oswald(color: Colors.redAccent, fontSize: 9),
              ),
            ],
          ],
        ),
        trailing: locked
            ? null
            : IconButton(
                icon: const Icon(Icons.check_circle_outline, color: Color(0xFFC4B89B)),
                onPressed: onTap,
              ),
      ),
    );
  }
}
