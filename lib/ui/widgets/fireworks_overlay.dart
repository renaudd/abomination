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

class FireworksOverlay extends StatefulWidget {
  const FireworksOverlay({super.key});

  @override
  State<FireworksOverlay> createState() => _FireworksOverlayState();
}

class _FireworksOverlayState extends State<FireworksOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_FireworkParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _spawnParticles();
  }

  void _spawnParticles() {
    final rand = Random();
    _particles.clear();
    for (int i = 0; i < 100; i++) {
      final angle = rand.nextDouble() * pi * 2;
      final speed = 2.0 + rand.nextDouble() * 7.0;
      final color = HSVColor.fromAHSV(
        1.0,
        rand.nextDouble() * 360,
        0.8,
        0.9,
      ).toColor();
      _particles.add(
        _FireworkParticle(angle: angle, speed: speed, color: color),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.value < 0.05) {
          _spawnParticles();
        }
        return CustomPaint(
          painter: _FireworksPainter(_controller.value, _particles),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _FireworkParticle {
  final double angle;
  final double speed;
  final Color color;

  _FireworkParticle({
    required this.angle,
    required this.speed,
    required this.color,
  });
}

class _FireworksPainter extends CustomPainter {
  final double progress;
  final List<_FireworkParticle> particles;

  _FireworksPainter(this.progress, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.4);
    final paint = Paint()..strokeCap = StrokeCap.round;

    for (final p in particles) {
      final dist = p.speed * progress * 160.0;
      final gravity = progress * progress * 45.0;
      final target =
          center + Offset(cos(p.angle) * dist, sin(p.angle) * dist + gravity);

      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: opacity);
      paint.strokeWidth = 3.5 * (1.0 - progress);

      canvas.drawLine(
        target - Offset(cos(p.angle) * 7.0, sin(p.angle) * 7.0),
        target,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
