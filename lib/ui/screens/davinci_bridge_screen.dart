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
import 'destination_screen.dart';

class PlacedLog {
  final String id;
  final int x;
  final int y;
  final bool isHorizontal;
  final String type;
  final Map<String, bool> overlaps;

  PlacedLog({
    required this.id,
    required this.x,
    required this.y,
    required this.isHorizontal,
    required this.type,
    this.overlaps = const {},
  });
}

class DaVinciBridgeScreen extends StatefulWidget {
  const DaVinciBridgeScreen({super.key});

  @override
  State<DaVinciBridgeScreen> createState() => _DaVinciBridgeScreenState();
}

class _DaVinciBridgeScreenState extends State<DaVinciBridgeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GameState>().setSpeed(GameSpeed.paused);
      }
    });
  }

  final List<PlacedLog> _placedLogs = [];
  bool _isSuccess = false;
  String? _highlightedLogId;
  int _missteps = 0;

  // Grid dimensions: 160 wide by 40 tall
  static const int gridWidth = 160;
  static const int gridHeight = 40;
  static const double cellSize = 20.0;

  // Placement preview state
  int _previewX = 0;
  int _previewY = 18;
  bool _isPreviewHorizontal = true;

  bool _intersects(PlacedLog a, PlacedLog b) {
    if (a.isHorizontal == b.isHorizontal) {
      return false;
    }
    final hLog = a.isHorizontal ? a : b;
    final vLog = a.isHorizontal ? b : a;

    final hMinX = hLog.x;
    final hMaxX = hLog.x + 19;
    final hY = hLog.y;

    final vX = vLog.x;
    final vMinY = vLog.y;
    final vMaxY = vLog.y + 19;

    return vX >= hMinX && vX <= hMaxX && hY >= vMinY && hY <= vMaxY;
  }

  Future<bool?> _showOverUnderDialog(PlacedLog existingLog) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF241F1A),
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Color(0xFFC4B89B), width: 1),
          ),
          title: Text(
            "TIMBER LAYERING",
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFE5D5B0),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Should the log being placed go OVER or UNDER the highlighted ${existingLog.isHorizontal ? 'Horizontal' : 'Vertical'} log at [${existingLog.x}, ${existingLog.y}]?",
            style: GoogleFonts.oldStandardTt(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                "UNDER",
                style: GoogleFonts.playfairDisplay(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC4B89B),
                foregroundColor: Colors.black,
                shape: const RoundedRectangleBorder(),
              ),
              child: Text(
                "OVER",
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _placeLog(GameState state) async {
    if (_isSuccess) return;

    if (_placedLogs.length >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No logs remaining! You have used all 20 logs."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Prevent placing a log at the exact same coordinate and orientation
    final isDuplicate = _placedLogs.any((log) =>
        log.x == _previewX &&
        log.y == _previewY &&
        log.isHorizontal == _isPreviewHorizontal);
    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("A log has already been placed at this exact position."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final tempLogId = 'log_${_placedLogs.length}';
    final newLog = PlacedLog(
      id: tempLogId,
      x: _previewX,
      y: _previewY,
      isHorizontal: _isPreviewHorizontal,
      type: _isPreviewHorizontal ? 'longitudinal' : 'cross',
      overlaps: {},
    );

    final overlappingLogs = <PlacedLog>[];
    for (var log in _placedLogs) {
      if (_intersects(newLog, log)) {
        overlappingLogs.add(log);
      }
    }

    final Map<String, bool> promptOverlaps = {};
    for (var existingLog in overlappingLogs) {
      setState(() {
        _highlightedLogId = existingLog.id;
      });

      final isOver = await _showOverUnderDialog(existingLog);
      if (isOver == null) {
        setState(() {
          _highlightedLogId = null;
        });
        return;
      }
      promptOverlaps[existingLog.id] = isOver;

      // Verify if this over/under choice is mathematically correct based on alternating weave logic
      final hLog = newLog.isHorizontal ? newLog : existingLog;
      final vLog = newLog.isHorizontal ? existingLog : newLog;
      final userChoseOverForHorizontal = newLog.isHorizontal ? isOver : !isOver;

      final bool isTopLog = hLog.y < 20;
      final int vColIndex = (vLog.x / 10.0).round(); // Estimates vertical index
      final bool isEvenCol = vColIndex % 2 == 0;

      final bool shouldBeOver = isTopLog ? isEvenCol : !isEvenCol;
      if (userChoseOverForHorizontal != shouldBeOver) {
        _missteps++;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("WARNING: Structural weakness detected in timber layering! (Missteps: $_missteps/3)"),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    setState(() {
      _highlightedLogId = null;
    });

    if (_missteps >= 3) {
      // Collapse the bridge!
      setState(() {
        _placedLogs.clear();
        _missteps = 0;
        _highlightedLogId = null;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2A1612),
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          title: Text(
            "THE BRIDGE COLLAPSED!",
            style: GoogleFonts.playfairDisplay(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "The frame structures slipped and collapsed under their own weight because of too many layering missteps! Start building again from the beginning.",
            style: GoogleFonts.oldStandardTt(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("TRY AGAIN", style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0))),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      final finalLog = PlacedLog(
        id: tempLogId,
        x: _previewX,
        y: _previewY,
        isHorizontal: _isPreviewHorizontal,
        type: _isPreviewHorizontal ? 'longitudinal' : 'cross',
        overlaps: promptOverlaps,
      );

      _placedLogs.add(finalLog);

      final isBridgeValid = _checkDaVinciBridgeCompletion();
      if (isBridgeValid) {
        _isSuccess = true;
        for (int i = 0; i < 120; i++) {
          state.tick();
        }
      } else {
        // Shift horizontally to aid construction flow
        _previewX = (_previewX + 8).clamp(0, gridWidth - 1);
      }
    });
  }

  bool _checkDaVinciBridgeCompletion() {
    final verts = _placedLogs.where((l) => !l.isHorizontal).toList();
    final horizs = _placedLogs.where((l) => l.isHorizontal).toList();

    if (verts.length != 5 || horizs.length != 10) {
      return false;
    }

    verts.sort((a, b) => a.x.compareTo(b.x));
    final v1 = verts[0];
    final v2 = verts[1];
    final v3 = verts[2];
    final v4 = verts[3];
    final v5 = verts[4];

    final dx1 = v2.x - v1.x;
    final dx2 = v3.x - v2.x;
    final dx3 = v4.x - v3.x;
    final dx4 = v5.x - v4.x;

    if (dx1 < 8 || dx1 > 10) return false;
    if (dx2 < 8 || dx2 > 10) return false;
    if (dx3 < 8 || dx3 > 10) return false;
    if (dx4 < 8 || dx4 > 10) return false;

    final yMin = [v1.y, v2.y, v3.y, v4.y, v5.y].reduce((a, b) => a < b ? a : b);
    final yMax = [v1.y, v2.y, v3.y, v4.y, v5.y].reduce((a, b) => a > b ? a : b);
    if (yMax - yMin > 1) return false;
    final yRef = v1.y;

    horizs.sort((a, b) => a.x.compareTo(b.x));

    final List<List<PlacedLog>> pairs = [];
    for (int i = 0; i < 5; i++) {
      pairs.add([horizs[i * 2], horizs[i * 2 + 1]]);
    }

    for (int i = 0; i < 5; i++) {
      final hA = pairs[i][0];
      final hB = pairs[i][1];
      if ((hA.x - hB.x).abs() > 1) return false;
    }

    final List<PlacedLog> topLogs = [];
    final List<PlacedLog> bottomLogs = [];
    for (int i = 0; i < 5; i++) {
      final hA = pairs[i][0];
      final hB = pairs[i][1];
      final topLog = hA.y < hB.y ? hA : hB;
      final bottomLog = hA.y < hB.y ? hB : hA;

      if (topLog.y < yRef - 1 || topLog.y > yRef + 2) return false;
      if (bottomLog.y < yRef + 17 || bottomLog.y > yRef + 20) return false;

      topLogs.add(topLog);
      bottomLogs.add(bottomLog);
    }

    final x1 = (topLogs[0].x + bottomLogs[0].x) / 2.0;
    final rightExcess1 = (x1 + 19) - v2.x;
    if (rightExcess1 < 0 || rightExcess1 > 2) return false;

    final x2 = (topLogs[1].x + bottomLogs[1].x) / 2.0;
    final leftExcess2 = v1.x - x2;
    final rightExcess2 = (x2 + 19) - v3.x;
    if (leftExcess2 < 0 || leftExcess2 > 2) return false;
    if (rightExcess2 < 0 || rightExcess2 > 2) return false;

    final x3 = (topLogs[2].x + bottomLogs[2].x) / 2.0;
    final leftExcess3 = v2.x - x3;
    final rightExcess3 = (x3 + 19) - v4.x;
    if (leftExcess3 < 0 || leftExcess3 > 2) return false;
    if (rightExcess3 < 0 || rightExcess3 > 2) return false;

    final x4 = (topLogs[3].x + bottomLogs[3].x) / 2.0;
    final leftExcess4 = v3.x - x4;
    final rightExcess4 = (x4 + 19) - v5.x;
    if (leftExcess4 < 0 || leftExcess4 > 2) return false;
    if (rightExcess4 < 0 || rightExcess4 > 2) return false;

    final x5 = (topLogs[4].x + bottomLogs[4].x) / 2.0;
    final leftExcess5 = v4.x - x5;
    if (leftExcess5 < 0 || leftExcess5 > 2) return false;

    bool isOver(PlacedLog h, PlacedLog v) {
      if (h.overlaps.containsKey(v.id)) {
        return h.overlaps[v.id] == true;
      }
      if (v.overlaps.containsKey(h.id)) {
        return v.overlaps[h.id] == false;
      }
      return false;
    }

    if (isOver(topLogs[0], v1) || isOver(bottomLogs[0], v1)) return false;
    if (!isOver(topLogs[0], v2) || !isOver(bottomLogs[0], v2)) return false;

    if (!isOver(topLogs[1], v1) || !isOver(bottomLogs[1], v1)) return false;
    if (isOver(topLogs[1], v2) || isOver(bottomLogs[1], v2)) return false;
    if (!isOver(topLogs[1], v3) || !isOver(bottomLogs[1], v3)) return false;

    if (!isOver(topLogs[2], v2) || !isOver(bottomLogs[2], v2)) return false;
    if (isOver(topLogs[2], v3) || isOver(bottomLogs[2], v3)) return false;
    if (!isOver(topLogs[2], v4) || !isOver(bottomLogs[2], v4)) return false;

    if (!isOver(topLogs[3], v3) || !isOver(bottomLogs[3], v3)) return false;
    if (isOver(topLogs[3], v4) || isOver(bottomLogs[3], v4)) return false;
    if (!isOver(topLogs[3], v5) || !isOver(bottomLogs[3], v5)) return false;

    if (!isOver(topLogs[4], v4) || !isOver(bottomLogs[4], v4)) return false;
    if (isOver(topLogs[4], v5) || isOver(bottomLogs[4], v5)) return false;

    return true;
  }

  void _undoLast() {
    if (_placedLogs.isEmpty || _isSuccess) return;
    setState(() {
      _placedLogs.removeLast();
    });
  }

  void _resetAttempt() {
    setState(() {
      _placedLogs.clear();
      _isSuccess = false;
      _highlightedLogId = null;
      _previewX = 0;
      _previewY = 18;
      _isPreviewHorizontal = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        state.returnToManor('player');
        state.setSpeed(GameSpeed.normal); // Resume clock speed when exiting
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1612),
        body: SafeArea(
          child: Stack(
            children: [
              Row(
                children: [
                  // 1. Left 75%: High-Performance Scrollable CustomPainter Grid
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        border: const Border(right: BorderSide(color: Colors.white10, width: 1)),
                      ),
                      child: ClipRect(
                        child: InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 2.0,
                          constrained: false, // Allows unrestricted horizontal/vertical scrolling!
                          child: GestureDetector(
                            onTapUp: (details) {
                              setState(() {
                                _previewX = (details.localPosition.dx ~/ cellSize).clamp(0, gridWidth - 1);
                                _previewY = (details.localPosition.dy ~/ cellSize).clamp(0, gridHeight - 1);
                              });
                            },
                            child: CustomPaint(
                              size: const Size(gridWidth * cellSize, gridHeight * cellSize),
                              painter: _BridgeGridPainter(
                                placedLogs: _placedLogs,
                                previewX: _previewX,
                                previewY: _previewY,
                                isPreviewHorizontal: _isPreviewHorizontal,
                                cellSize: cellSize,
                                gridWidth: gridWidth,
                                gridHeight: gridHeight,
                                highlightedLogId: _highlightedLogId,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Right 25%: Blueprint Info & gothic Action Controls Column
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: const Color(0xFF241F1A),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "DA VINCI BRIDGING BLUEPRINT",
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFE5D5B0),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Grid: 160 x 40 ft. Pan/scroll horizontally to build across the wide river span. Beams may extend outside the visible viewport.",
                            style: GoogleFonts.oldStandardTt(
                              color: const Color(0xFFC4B89B).withValues(alpha: 0.7),
                              fontSize: 10,
                              height: 1.3,
                            ),
                          ),
                          const Divider(color: Colors.white10, height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "LOGS PLACED: ${_placedLogs.length} / 20",
                                style: GoogleFonts.oswald(color: const Color(0xFFE5D5B0), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "GRID SELECTION: ($_previewX, $_previewY)",
                            style: GoogleFonts.oswald(color: const Color(0xFFC4B89B).withValues(alpha: 0.5), fontSize: 9),
                          ),
                          const SizedBox(height: 16),

                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isPreviewHorizontal = !_isPreviewHorizontal;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC4B89B),
                              foregroundColor: Colors.black,
                              shape: const RoundedRectangleBorder(),
                              minimumSize: const Size(double.infinity, 38),
                            ),
                            icon: const Icon(Icons.rotate_90_degrees_ccw, size: 14),
                            label: Text("FLIP ORIENTATION", style: GoogleFonts.playfairDisplay(fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 12),

                          ElevatedButton(
                            onPressed: () => _placeLog(state),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC4B89B),
                              foregroundColor: Colors.black,
                              shape: const RoundedRectangleBorder(),
                              minimumSize: const Size(double.infinity, 42),
                            ),
                            child: Text("PLACE LOG", style: GoogleFonts.playfairDisplay(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 12),

                          OutlinedButton.icon(
                            onPressed: _placedLogs.isNotEmpty ? _undoLast : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: BorderSide(color: _placedLogs.isNotEmpty ? Colors.redAccent : Colors.white10),
                              shape: const RoundedRectangleBorder(),
                              minimumSize: const Size(double.infinity, 38),
                            ),
                            icon: const Icon(Icons.undo, size: 14),
                            label: Text("REMOVE LAST", style: GoogleFonts.playfairDisplay(fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                          const Spacer(),

                          Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.black12,
                            width: double.infinity,
                            child: Text(
                              "DIRECTIONS:\n• Pan the grid horizontally to track your spans.\n• Lay exactly 15 logs (5 vertical, 10 horizontal pairs).\n• When placing overlapping logs, decide whether they go OVER or UNDER.\n• Assemble the self-supporting Da Vinci bridge sequence anywhere on the grid!",
                              style: GoogleFonts.oldStandardTt(color: const Color(0xFFC4B89B).withValues(alpha: 0.4), fontSize: 9, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Success Overlay
              if (_isSuccess)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.95),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFFC4B89B), size: 64),
                        const SizedBox(height: 20),
                        Text(
                          "DA VINCI BRIDGE SPAN COMPLETE!",
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFFE5D5B0),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "THE LOCKING FRAME WEDGE COMPRESSES INTO AN EARNEST, SELF-SUPPORTING ARCH. THE OTHER SIDE OF THE RIVER IS UNLOCKED!",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () {
                            state.buildRiverBridge();
                            state.setSpeed(GameSpeed.normal); // Resume speed
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DestinationScreen(destinationId: 'river'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC4B89B),
                            foregroundColor: Colors.black,
                            shape: const RoundedRectangleBorder(),
                          ),
                          child: Text("CROSS TO THE FAR SIDE", style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// High-performance custom painter grid visualizer
class _BridgeGridPainter extends CustomPainter {
  final List<PlacedLog> placedLogs;
  final int previewX;
  final int previewY;
  final bool isPreviewHorizontal;
  final double cellSize;
  final int gridWidth;
  final int gridHeight;
  final String? highlightedLogId;

  _BridgeGridPainter({
    required this.placedLogs,
    required this.previewX,
    required this.previewY,
    required this.isPreviewHorizontal,
    required this.cellSize,
    required this.gridWidth,
    required this.gridHeight,
    this.highlightedLogId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background
    final bgPaint = Paint()..color = const Color(0xFF1E1A15);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Grid lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 0.5;

    for (double x = 0; x <= size.width; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y <= size.height; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // 3. Placed Logs
    final woodPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.fill;
    final woodBorder = Paint()
      ..color = const Color(0xFFC4B89B).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var log in placedLogs) {
      final isHighlighted = log.id == highlightedLogId;
      final logWoodPaint = Paint()
        ..color = isHighlighted ? const Color(0xFFD4AF37) : const Color(0xFF8B4513)
        ..style = PaintingStyle.fill;
      final logWoodBorder = Paint()
        ..color = isHighlighted ? const Color(0xFFFFFDD0) : const Color(0xFFC4B89B).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHighlighted ? 2.5 : 1.0;

      double w = log.isHorizontal ? 20 * cellSize : cellSize;
      double h = log.isHorizontal ? cellSize : 20 * cellSize;
      final rect = Rect.fromLTWH(log.x * cellSize, log.y * cellSize, w, h);
      canvas.drawRect(rect, logWoodPaint);
      canvas.drawRect(rect, logWoodBorder);
    }

    // 3.5 Redraw intersections to respect custom overlap layers
    for (int i = 0; i < placedLogs.length; i++) {
      for (int j = i + 1; j < placedLogs.length; j++) {
        final logA = placedLogs[i];
        final logB = placedLogs[j];
        if (_intersects(logA, logB)) {
          final hLog = logA.isHorizontal ? logA : logB;
          final vLog = logA.isHorizontal ? logB : logA;
          final overLog = _isLogOver(hLog, vLog) ? hLog : vLog;

          final isHighlighted = overLog.id == highlightedLogId;
          final logWoodPaint = Paint()
            ..color = isHighlighted ? const Color(0xFFD4AF37) : const Color(0xFF8B4513)
            ..style = PaintingStyle.fill;
          final logWoodBorder = Paint()
            ..color = isHighlighted ? const Color(0xFFFFFDD0) : const Color(0xFFC4B89B).withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = isHighlighted ? 2.5 : 1.0;

          final double cellLeft = vLog.x * cellSize;
          final double cellTop = hLog.y * cellSize;

          // Fill the intersection cell
          canvas.drawRect(
            Rect.fromLTWH(cellLeft, cellTop, cellSize, cellSize),
            logWoodPaint,
          );

          // Draw borders for the OVER log only, avoiding inner lines
          if (overLog.isHorizontal) {
            canvas.drawLine(
              Offset(cellLeft, cellTop),
              Offset(cellLeft + cellSize, cellTop),
              logWoodBorder,
            );
            canvas.drawLine(
              Offset(cellLeft, cellTop + cellSize),
              Offset(cellLeft + cellSize, cellTop + cellSize),
              logWoodBorder,
            );
          } else {
            canvas.drawLine(
              Offset(cellLeft, cellTop),
              Offset(cellLeft, cellTop + cellSize),
              logWoodBorder,
            );
            canvas.drawLine(
              Offset(cellLeft + cellSize, cellTop),
              Offset(cellLeft + cellSize, cellTop + cellSize),
              logWoodBorder,
            );
          }
        }
      }
    }

    // 4. Active Preview Log
    final previewPaint = Paint()
      ..color = const Color(0xFFC4B89B).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    final previewBorder = Paint()
      ..color = const Color(0xFFE5D5B0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    double pw = isPreviewHorizontal ? 20 * cellSize : cellSize;
    double ph = isPreviewHorizontal ? cellSize : 20 * cellSize;
    final preRect = Rect.fromLTWH(previewX * cellSize, previewY * cellSize, pw, ph);
    canvas.drawRect(preRect, previewPaint);
    canvas.drawRect(preRect, previewBorder);
  }

  bool _intersects(PlacedLog a, PlacedLog b) {
    if (a.isHorizontal == b.isHorizontal) {
      return false;
    }
    final hLog = a.isHorizontal ? a : b;
    final vLog = a.isHorizontal ? b : a;

    final hMinX = hLog.x;
    final hMaxX = hLog.x + 19;
    final hY = hLog.y;

    final vX = vLog.x;
    final vMinY = vLog.y;
    final vMaxY = vLog.y + 19;

    return vX >= hMinX && vX <= hMaxX && hY >= vMinY && hY <= vMaxY;
  }

  bool _isLogOver(PlacedLog h, PlacedLog v) {
    if (h.overlaps.containsKey(v.id)) {
      return h.overlaps[v.id] == true;
    }
    if (v.overlaps.containsKey(h.id)) {
      return v.overlaps[h.id] == false;
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant _BridgeGridPainter oldDelegate) {
    return oldDelegate.placedLogs.length != placedLogs.length ||
        oldDelegate.previewX != previewX ||
        oldDelegate.previewY != previewY ||
        oldDelegate.isPreviewHorizontal != isPreviewHorizontal ||
        oldDelegate.highlightedLogId != highlightedLogId;
  }
}
