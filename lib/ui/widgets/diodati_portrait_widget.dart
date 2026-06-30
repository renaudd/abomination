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

class DiodatiPortraitWidget extends StatelessWidget {
  final String npcName;
  final double size;
  final bool useBox;

  const DiodatiPortraitWidget({
    super.key,
    required this.npcName,
    this.size = 120.0,
    this.useBox = true,
  });

  @override
  Widget build(BuildContext context) {
    final String name = npcName.toLowerCase();
    
    Widget portraitContent;
    if (name.contains('mary')) {
      portraitContent = _buildMaryShelley(useBox);
    } else if (name.contains('percy')) {
      portraitContent = _buildPercyShelley(useBox);
    } else if (name.contains('byron')) {
      portraitContent = _buildLordByron(useBox);
    } else if (name.contains('claire')) {
      portraitContent = _buildClaireClairmont(useBox);
    } else if (name.contains('polidori')) {
      portraitContent = _buildJohnPolidori(useBox);
    } else {
      // Default placeholder silhouette
      portraitContent = _buildDefaultSilhouette(useBox);
    }

    final Widget scaledPortrait = FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 120,
        height: 120,
        child: portraitContent,
      ),
    );

    if (!useBox) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipRect(
          child: scaledPortrait,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2017),
        border: Border.all(
          color: const Color(0xFFC4B89B),
          width: 2.0,
        ),
      ),
      child: ClipRect(
        child: scaledPortrait,
      ),
    );
  }

  Widget _buildMaryShelley(bool useBox) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background Subdued Parchment Color
        if (useBox)
          Positioned.fill(
            child: Container(color: const Color(0xFF382C22)),
          ),
        // Hair Buns (Left and Right)
        Positioned(
          left: 20,
          top: 30,
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF1E1715),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: 20,
          top: 30,
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF1E1715),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // High Black Wool Collar/Trapezoid Body
        Positioned(
          bottom: 0,
          child: Container(
            width: 70,
            height: 45,
            decoration: const BoxDecoration(
              color: Color(0xFF121212),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
        ),
        // White collar (under the chin)
        Positioned(
          bottom: 30,
          child: Container(
            width: 24,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
        ),
        // Pale Skin Face (Oval)
        Positioned(
          top: 25,
          child: Container(
            width: 50,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF9EFE2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xFFE8D4BE), width: 1),
            ),
          ),
        ),
        // Parted Hair Top Block
        Positioned(
          top: 22,
          child: Container(
            width: 46,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFF1E1715),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
            ),
          ),
        ),
        ..._buildFaceFeatures(faceTop: 25, faceHeight: 64, faceWidth: 50, isFemale: true),
      ],
    );
  }

  Widget _buildPercyShelley(bool useBox) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (useBox)
          Positioned.fill(
            child: Container(color: const Color(0xFF3B2E24)),
          ),
        // Disheveled hair brown curls background
        Positioned(
          top: 15,
          child: Wrap(
            spacing: -8,
            runSpacing: -8,
            children: List.generate(6, (index) {
              return Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFF4A3427),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
        // Coat
        Positioned(
          bottom: 0,
          child: Container(
            width: 72,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF1B263B),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
          ),
        ),
        // White Cravat base
        Positioned(
          bottom: 12,
          child: Container(
            width: 28,
            height: 25,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
        ),
        // Face
        Positioned(
          top: 24,
          child: Container(
            width: 48,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFBF4EB),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        // Front hair locks
        Positioned(
          top: 20,
          child: Container(
            width: 40,
            height: 12,
            decoration: const BoxDecoration(
              color: Color(0xFF4A3427),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
        ),
        // Flowing white cravat front tie
        Positioned(
          bottom: 0,
          child: Container(
            width: 14,
            height: 20,
            color: const Color(0xFFEDEDED),
          ),
        ),
        ..._buildFaceFeatures(faceTop: 25, faceHeight: 56, faceWidth: 44, isFemale: false),
      ],
    );
  }

  Widget _buildLordByron(bool useBox) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (useBox)
          Positioned.fill(
            child: Container(color: const Color(0xFF362B21)),
          ),
        // Asymmetric prominent sweeping curl block (Left side curl)
        Positioned(
          top: 16,
          left: 32,
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF261D19),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Formal Red-brown aristocratic coat
        Positioned(
          bottom: 0,
          child: Container(
            width: 74,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFF3F1A1A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
          ),
        ),
        // Open collar white shirt
        Positioned(
          bottom: 15,
          child: Container(
            width: 30,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
            ),
          ),
        ),
        // Face block with angled jawline
        Positioned(
          top: 25,
          child: Container(
            width: 48,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFFDF7EF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(24), // Angled jaw asymmetry
              ),
            ),
          ),
        ),
        // Hair top and sweeping curl overlapping the forehead
        Positioned(
          top: 20,
          child: Container(
            width: 45,
            height: 16,
            decoration: const BoxDecoration(
              color: Color(0xFF261D19),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(12), // Sweeps down right side
              ),
            ),
          ),
        ),
        // Shirt open V-neck cutout overlay (Skin colored V)
        Positioned(
          bottom: 18,
          child: Container(
            width: 12,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFFFDF7EF),
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
        ),
        ..._buildFaceFeatures(faceTop: 26, faceHeight: 58, faceWidth: 44, isFemale: false),
      ],
    );
  }

  Widget _buildClaireClairmont(bool useBox) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (useBox)
          Positioned.fill(
            child: Container(color: const Color(0xFF3D2F25)),
          ),
        // Dark braids background circles
        Positioned(
          top: 22,
          left: 28,
          child: Container(
            width: 18,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF191615),
              borderRadius: BorderRadius.all(Radius.circular(9)),
            ),
          ),
        ),
        Positioned(
          top: 22,
          right: 28,
          child: Container(
            width: 18,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF191615),
              borderRadius: BorderRadius.all(Radius.circular(9)),
            ),
          ),
        ),
        // Teal Dress Block
        Positioned(
          bottom: 0,
          child: Container(
            width: 72,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF0C6B70),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
          ),
        ),
        // Face
        Positioned(
          top: 24,
          child: Container(
            width: 46,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFFCEFE0),
              borderRadius: BorderRadius.circular(23),
            ),
          ),
        ),
        // Dark hair parting
        Positioned(
          top: 22,
          child: Container(
            width: 42,
            height: 14,
            decoration: const BoxDecoration(
              color: Color(0xFF191615),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
          ),
        ),
        ..._buildFaceFeatures(faceTop: 24, faceHeight: 58, faceWidth: 46, isFemale: true),
      ],
    );
  }

  Widget _buildJohnPolidori(bool useBox) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background
        if (useBox)
          Positioned.fill(
            child: Container(color: const Color(0xFF342A22)),
          ),
        // Coat
        Positioned(
          bottom: 0,
          child: Container(
            width: 70,
            height: 46,
            decoration: const BoxDecoration(
              color: Color(0xFF222B38),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
          ),
        ),
        // Inner grey vest & high collar shirt
        Positioned(
          bottom: 20,
          child: Container(
            width: 24,
            height: 20,
            color: const Color(0xFFEDEDED),
          ),
        ),
        // Face
        Positioned(
          top: 24,
          child: Container(
            width: 46,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFF9EADA),
              borderRadius: BorderRadius.circular(23),
            ),
          ),
        ),
        // Combed neat black hair
        Positioned(
          top: 20,
          child: Container(
            width: 46,
            height: 14,
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
          ),
        ),
        // Round Spectacles (Left & Right thin wireframes)
        Positioned(
          top: 42,
          left: 42,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
            ),
          ),
        ),
        Positioned(
          top: 42,
          right: 42,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
            ),
          ),
        ),
        // Bridge of specs
        Positioned(
          top: 48,
          child: Container(
            width: 8,
            height: 1.5,
            color: const Color(0xFFD4AF37),
          ),
        ),
        // Coat high-button overlap
        Positioned(
          bottom: 5,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4AF37),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
        ..._buildFaceFeatures(faceTop: 24, faceHeight: 56, faceWidth: 44, isFemale: false),
      ],
    );
  }

  Widget _buildDefaultSilhouette(bool useBox) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (useBox)
          Positioned.fill(
            child: Container(color: const Color(0xFF2D231B)),
          ),
        // Silhouette Head
        Positioned(
          top: 26,
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF1E1712),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Silhouette Torso
        Positioned(
          bottom: 0,
          child: Container(
            width: 74,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF1E1712),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }
  List<Widget> _buildFaceFeatures({
    required double faceTop,
    required double faceHeight,
    required double faceWidth,
    bool isFemale = false,
  }) {
    final double centerX = 60.0; // Canvas is 120 wide, so center is 60
    final double eyesY = faceTop + faceHeight * 0.38;
    final double noseY = faceTop + faceHeight * 0.52;
    final double mouthY = faceTop + faceHeight * 0.72;
    final Color featureColor = const Color(0xFF4A3B32);
    final Color lipColor = isFemale ? const Color(0xFFC88276) : const Color(0xFFB59385);

    return [
      // Eyebrows
      Positioned(
        left: centerX - 12,
        top: eyesY - 5,
        child: Container(
          width: 8,
          height: 1.5,
          color: featureColor.withOpacity(0.8),
        ),
      ),
      Positioned(
        left: centerX + 4,
        top: eyesY - 5,
        child: Container(
          width: 8,
          height: 1.5,
          color: featureColor.withOpacity(0.8),
        ),
      ),
      // Eyes
      Positioned(
        left: centerX - 9,
        top: eyesY,
        child: Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: featureColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        left: centerX + 6,
        top: eyesY,
        child: Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: featureColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
      // Nose (Subtle vertical line)
      Positioned(
        left: centerX - 0.5,
        top: noseY,
        child: Container(
          width: 1.5,
          height: 6,
          color: featureColor.withOpacity(0.4),
        ),
      ),
      // Mouth
      Positioned(
        left: centerX - 5,
        top: mouthY,
        child: Container(
          width: 10,
          height: 2,
          decoration: BoxDecoration(
            color: lipColor,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    ];
  }
}
