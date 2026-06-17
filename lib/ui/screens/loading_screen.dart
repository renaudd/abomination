import 'package:flutter/material.dart';
import 'dart:async';
import 'main_menu_screen.dart';

class LoadingScreen extends StatefulWidget {
  final VoidCallback? onCompleted;
  const LoadingScreen({super.key, this.onCompleted});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  double _progress = 0.0;
  String _currentLog = "";
  int _logIndex = 0;
  Timer? _timer;

  final List<String> _logs = [
    "Waking the master...",
    "Loading Asset Manifest...",
    "Emptying vats.",
    "Initializing Game State.",
    "Exhuming corpses.",
    "Starting Audio Service.",
    "Studying entrails.",
    "Synthesizing Manor Layout.",
    "Sharpening scalpels.",
    "Populating Resident Archives.",
    "Distilling vitae.",
    "Reciting incantations.",
    "Stitching ligaments.",
    "Calibrating galvanic coils.",
    "Feeding the specimens.",
    "Cleaning the laboratory.",
    "Finalizing preparation...",
    "Ready for the experiment."
  ];

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startLoading() {
    const totalDuration = Duration(milliseconds: 5000); // 5 seconds loading
    const interval = Duration(milliseconds: 100);
    final totalSteps = totalDuration.inMilliseconds ~/ interval.inMilliseconds;
    int currentStep = 0;

    _timer = Timer.periodic(interval, (timer) {
      currentStep++;
      if (mounted) {
        setState(() {
          _progress = currentStep / totalSteps;
          // Rotate logs based on progress
          int newLogIndex = (_progress * (_logs.length - 1)).floor();
          if (newLogIndex != _logIndex) {
            _logIndex = newLogIndex;
            _currentLog = _logs[_logIndex];
          }
        });
      }

      if (currentStep >= totalSteps) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _progress = 1.0;
            _currentLog = "Ready for the experiment.";
          });
        }
      }
    });
    
    // Set initial log
    _currentLog = _logs[0];
  }

  bool _isNavigating = false;

  void _completeLoading() {
    if (_isNavigating) return;
    _isNavigating = true;
    widget.onCompleted?.call();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainMenuScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/images/survey_estate_rolle.jpeg',
            fit: BoxFit.cover,
          ),
          // Dark Overlay for legibility
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Log Text
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _currentLog.toUpperCase(),
                    key: ValueKey(_currentLog),
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      color: Color(0xFFE5D5B0),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                // Progress Bar
                Container(
                  width: 400,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.3), width: 0.5),
                  ),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: 400 * _progress,
                        height: double.infinity,
                        color: const Color(0xFFC4B89B),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Progress Percentage
                Text(
                  "${(_progress * 100).toInt()}%",
                  style: TextStyle(
                    fontFamily: 'Courier',
                    color: const Color(0xFFC4B89B).withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                if (_progress >= 1.0) ...[
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: _completeLoading,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC4B89B),
                        border: Border.all(color: const Color(0xFFE5D5B0), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC4B89B).withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Text(
                        'AWAKEN',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          color: Color(0xFF1A1612),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Title/Branding
          Positioned(
            top: 64,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'ABOMINATION',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: Color(0xFFE5D5B0),
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 12,
                    shadows: [
                      Shadow(blurRadius: 20, color: Colors.black),
                    ],
                  ),
                ),
                const Text(
                  'AN EXPERIMENT IN GALVANISM',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: Color(0xFFC4B89B),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
