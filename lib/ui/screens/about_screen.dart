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

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15100B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D1712),
        title: Text(
          'ABOUT ABOMINATION',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFE5D5B0),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFE5D5B0)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFC4B89B).withValues(alpha: 0.3), height: 1.0),
        ),
      ),
      body: Center(
        child: Container(
          width: 680,
          margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1510),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFC4B89B).withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF241D17),
                  border: Border(bottom: BorderSide(color: const Color(0xFFC4B89B).withValues(alpha: 0.3))),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BUILD VERSION 0.9.5 (ESOTERIC OVERHAUL)',
                          style: GoogleFonts.oswald(
                            color: const Color(0xFFD4AF37),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Advanced Agentic Coding Engineering Build',
                          style: GoogleFonts.oldStandardTt(
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E251F),
                            foregroundColor: const Color(0xFFE5D5B0),
                            side: BorderSide(color: const Color(0xFFC4B89B).withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          icon: const Icon(Icons.privacy_tip_outlined, size: 16, color: Color(0xFFD4AF37)),
                          label: const Text('Privacy Policy', style: TextStyle(fontSize: 12)),
                          onPressed: () => _showPrivacyPolicy(context),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E251F),
                            foregroundColor: const Color(0xFFE5D5B0),
                            side: BorderSide(color: const Color(0xFFC4B89B).withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          icon: const Icon(Icons.library_books_outlined, size: 16, color: Color(0xFFD4AF37)),
                          label: const Text('Third Party Notices', style: TextStyle(fontSize: 12)),
                          onPressed: () => _showThirdPartyNotices(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Scrollable Document Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeading('STATE OF DEVELOPMENT'),
                      const SizedBox(height: 8),
                      Text(
                        'The present build represents the near-final realization of Abomination, bridging subterranean Victorian estate management with multi-lane tabletop tactical warfare. Recent development milestones have focused on eradicating technical debt, standardizing UI symbols into fully articulated living soldiers, and integrating deep esoteric secret society mechanics.',
                        style: GoogleFonts.oldStandardTt(color: const Color(0xFFD7CCC8), fontSize: 15, height: 1.5),
                      ),
                      const SizedBox(height: 24),

                      _sectionHeading('NEW FEATURES IN THIS BUILD'),
                      const SizedBox(height: 12),
                      _bulletItem(
                        '19th-Century Esoteric Factions',
                        'Fully registered 9 distinct subterranean societies: Freemasons, Rosicrucians, Knights Templar, Gnomes of Zurich, Carbonari, Golden Dawn, Fenian Brotherhood, Chevaliers de la foi, and Ancient Order of Foresters.',
                      ),
                      _bulletItem(
                        '18 Faction-Exclusive Combat Cards',
                        'Introduced specialized squad types including Pyre Knights wielding flaming greatswords, stone-grey Masonic Sappers targeting towers exclusively, and 800-HP lumbering Behemoths.',
                      ),
                      _bulletItem(
                        'Living Articulated Battlefield Visuals',
                        'Routed all humanoid and mounted units into the high-fidelity articulated rendering engine with bobbing animation locomotion, custom Victorian uniforms, and period weapon overlays.',
                      ),
                      _bulletItem(
                        'Persistent Elemental Warfare',
                        'Implemented core engine logic for stacking Poison DOTs, unquenchable spreading Greek Fire, and hypnotic pendulum mind-control allegiance flipping.',
                      ),
                      _bulletItem(
                        'Intelligent Channel Pathfinding',
                        'Upgraded autonomous AI leader navigation to enforce strict vertical channel alignment before horizontal advancement, eliminating obstacles and wall collisions.',
                      ),
                      const SizedBox(height: 24),

                      _sectionHeading('KNOWN ISSUES & SANDBOX NOTES'),
                      const SizedBox(height: 12),
                      _bulletItem(
                        'Card Shop Faction Restrictions',
                        'Faction-locking availability rules in Skirmish and Tournament modes are temporarily unlocked to permit unencumbered sandbox deck testing.',
                      ),
                      _bulletItem(
                        'Hardware Stencil Buffer Clipping',
                        'High-density creature containers enforce strict Clip.hardEdge bounds on iOS to prevent sub-pixel layout overflow during dense multi-squad engagements.',
                      ),
                      _bulletItem(
                        'Minimap Viewport Aspect Ratio',
                        'Minimap projection boxes dynamically recalculate scale during ultra-wide custom battlefield simulations.',
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

  Widget _sectionHeading(String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFD4AF37), width: 1.5))),
      child: Text(
        title,
        style: GoogleFonts.playfairDisplay(
          color: const Color(0xFFE5D5B0),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _bulletItem(String label, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4, right: 10),
            child: Icon(Icons.diamond, size: 10, color: Color(0xFFD4AF37)),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.oldStandardTt(fontSize: 14, height: 1.4),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(color: Color(0xFFE5D5B0), fontWeight: FontWeight.bold)),
                  TextSpan(text: desc, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1712),
        shape: RoundedRectangleBorder(side: BorderSide(color: const Color(0xFFC4B89B).withValues(alpha: 0.4), width: 1.5), borderRadius: BorderRadius.circular(6)),
        title: Text(
          'PRIVACY POLICY',
          style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        content: SizedBox(
          width: 480,
          child: Text(
            'This application operates entirely locally on your device. It does not collect, transmit, store, or share any personal data, user accounts, telemetry, analytics, or network communications. All internal game progress, custom decks, and resident schedules are stored securely inside your local storage device.',
            style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 15, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('UNDERSTOOD', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showThirdPartyNotices(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1D1712),
        shape: RoundedRectangleBorder(side: BorderSide(color: const Color(0xFFC4B89B).withValues(alpha: 0.4), width: 1.5), borderRadius: BorderRadius.circular(6)),
        title: Text(
          'OPEN SOURCE COMPONENTS & TRANSITIVE LICENSES',
          style: GoogleFonts.playfairDisplay(color: const Color(0xFFE5D5B0), fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        content: SizedBox(
          width: 600,
          height: 440,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Abomination incorporates the following open-source software components, including all direct and transitive dependencies, under their unabridged license documentation:',
                  style: GoogleFonts.oldStandardTt(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                _licenseBlock(
                  'Flutter SDK, Dart Virtual Machine & Core Libraries',
                  'Direct Component: flutter, dart\nTransitive SDK Dependencies: collection, vector_math_64, characters, meta, path\n\n'
                  'Copyright 2014 The Flutter Authors. Copyright 2012 The Dart Project Authors. All rights reserved.\n\n'
                  'Redistribution and use in source and binary forms, with or or without modification, are permitted provided that the following conditions are met:\n'
                  '1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.\n'
                  '2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.\n'
                  '3. Neither the name of Google LLC nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.\n\n'
                  'THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.',
                ),
                _licenseBlock(
                  'Google Fonts (Playfair Display, Oswald, Old Standard TT, Inter, Roboto)',
                  'Direct Component: google_fonts\nTransitive Font Asset Dependencies: OFL.txt font definition bundles\n\n'
                  'SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007\n\n'
                  'PREAMBLE: The goals of the Open Font License (OFL) are to stimulate worldwide development of collaborative font projects, to support the font creation efforts of academic and linguistic communities, and to provide a free and open framework in which fonts may be shared and improved in partnership with others.\n\n'
                  'PERMISSION & CONDITIONS: Permission is hereby granted, free of charge, to any person obtaining a copy of the Font Software, to use, study, copy, merge, embed, modify, redistribute, and sell modified and unmodified copies of the Font Software, subject to the following conditions:\n'
                  '1) Neither the Font Software nor any of its individual components, in Original or Modified Versions, may be sold by itself.\n'
                  '2) Original or Modified Versions of the Font Software may be bundled, redistributed and/or sold with any software, provided that each copy contains the above copyright notice and this license.\n'
                  '3) No Modified Version of the Font Software may use the Reserved Font Name(s) unless explicit written permission is granted.\n'
                  '4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font Software shall not be used to promote, endorse or advertise any Modified Version.\n'
                  '5) The Font Software, modified or unmodified, in part or in whole, must be distributed entirely under this license, and must not be distributed under any other license. The requirement for fonts to remain under this license does not apply to any document created using the Font Software.\n\n'
                  'TERMINATION: This license becomes null and void if any of the above conditions are not met.\n\n'
                  'DISCLAIMER: THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM OTHER DEALINGS IN THE FONT SOFTWARE.',
                ),
                _licenseBlock(
                  'Provider (State Management Engine)',
                  'Direct Component: provider\nTransitive Dependencies: nested\n\n'
                  'Copyright 2019 Remi Rousselet\n\n'
                  'Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n\n'
                  'The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n\n'
                  'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.',
                ),
                _licenseBlock(
                  'Material Design Icons & Symbols',
                  'Direct Component: material_design_icons\n\n'
                  'Copyright Google LLC\n\n'
                  'Apache License\nVersion 2.0, January 2004\nhttp://www.apache.org/licenses/\n\n'
                  'TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION\n\n'
                  '1. Definitions.\n'
                  '"License" shall mean the terms and conditions for use, reproduction, and distribution as defined by Sections 1 through 9 of this document.\n'
                  '"Licensor" shall mean the copyright owner or entity authorized by the copyright owner that is granting the License.\n'
                  '"Legal Entity" shall mean the union of the acting entity and all other entities that control, are controlled by, or are under common control with that entity. For the purposes of this definition, "control" means (i) the power, direct or indirect, to cause the direction or management of such entity, whether by contract or otherwise, or (ii) ownership of fifty percent (50%) or more of the outstanding shares, or (iii) beneficial ownership of such entity.\n'
                  '"You" (or "Your") shall mean an individual or Legal Entity exercising permissions granted by this License.\n'
                  '"Source" form shall mean the preferred form for making modifications, including but not limited to software source code, documentation source, and configuration files.\n'
                  '"Object" form shall mean any form resulting from mechanical transformation or translation of a Source form, including but not limited to compiled object code, generated documentation, and conversions to other media types.\n'
                  '"Work" shall mean the work of authorship, whether in Source or Object form, made available under the License, as indicated by a copyright notice that is included in or attached to the work.\n'
                  '"Derivative Works" shall mean any work, whether in Source or Object form, that is based on (or derived from) the Work and for which the editorial revisions, annotations, elaborations, or other modifications represent, as a whole, an original work of authorship. For the purposes of this License, Derivative Works shall not include works that remain separable from, or merely link (or bind by name) to the interfaces of, the Work and Derivative Works thereof.\n'
                  '"Contribution" shall mean any work of authorship, including the original version of the Work and any modifications or additions to that Work or Derivative Works thereof, that is intentionally submitted to Licensor for inclusion in the Work by the copyright owner or by an individual or Legal Entity authorized to submit on behalf of the copyright owner.\n'
                  '"Contributor" shall mean Licensor and any individual or Legal Entity on behalf of whom a Contribution has been received by Licensor and subsequently incorporated within the Work.\n\n'
                  '2. Grant of Copyright License. Subject to the terms and conditions of this License, each Contributor hereby grants to You a perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable copyright license to reproduce, prepare Derivative Works of, publicly display, publicly perform, sublicense, and distribute the Work and such Derivative Works in Source or Object form.\n\n'
                  '3. Grant of Patent License. Subject to the terms and conditions of this License, each Contributor hereby grants to You a perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable (except as stated in this section) patent license to make, have made, use, offer to sell, sell, import, and otherwise transfer the Work, where such license applies only to those patent claims licensable by such Contributor that are necessarily infringed by their Contribution(s) alone or by combination of their Contribution(s) with the Work to which such Contribution(s) was submitted. If You institute patent litigation against any entity (including a cross-claim or counterclaim in a lawsuit) alleging that the Work or a Contribution incorporated within the Work constitutes direct or contributory patent infringement, then any patent licenses granted to You under this License for that Work shall terminate as of the date such litigation is filed.\n\n'
                  '4. Redistribution. You may reproduce and distribute copies of the Work or Derivative Works thereof in any medium, with or without modifications, and in Source or Object form, provided that You meet the following conditions:\n'
                  '(a) You must give any other recipients of the Work or Derivative Works a copy of this License; and\n'
                  '(b) You must cause any modified files to carry prominent notices stating that You changed the files; and\n'
                  '(c) You must retain, in the Source form of any Derivative Works that You distribute, all copyright, patent, trademark, and attribution notices from the Source form of the Work, excluding those notices that do not pertain to any part of the Derivative Works; and\n'
                  '(d) If the Work includes a "NOTICE" text file as part of its distribution, then any Derivative Works that You distribute must include a readable copy of the attribution notices contained within such NOTICE file, excluding those notices that do not pertain to any part of the Derivative Works, in at least one of the following places: within a NOTICE text file distributed as part of the Derivative Works; within the Source form or documentation, if provided along with the Derivative Works; or, within a display generated by the Derivative Works, if and wherever such third-party notices normally appear. The contents of the NOTICE file are for informational purposes only and do not modify the License. You may add Your own attribution notices within Derivative Works that You distribute, alongside or as an addendum to the NOTICE text from the Work, provided that such additional attribution notices cannot be construed as modifying the License.\n'
                  'You may add Your own copyright statement to Your modifications and may provide additional or different license terms and conditions for use, reproduction, or distribution of Your modifications, or for any such Derivative Works as a whole, provided Your use, reproduction, and distribution of the Work otherwise complies with the conditions stated in this License.\n\n'
                  '5. Submission of Contributions. Unless You explicitly state otherwise, any Contribution intentionally submitted for inclusion in the Work by You to the Licensor shall be under the terms and conditions of this License, without any additional terms or conditions. Notwithstanding the above, nothing herein shall supersede or modify the terms of any separate license agreement you may have executed with Licensor regarding such Contributions.\n\n'
                  '6. Trademarks. This License does not grant permission to use the trade names, trademarks, service marks, or product names of the Licensor, except as required for reasonable and customary use in describing the origin of the Work and reproducing the content of the NOTICE file.\n\n'
                  '7. Disclaimer of Warranty. Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its Contributions) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied, including, without limitation, any warranties or conditions of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A PARTICULAR PURPOSE. You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any risks associated with Your exercise of permissions under this License.\n\n'
                  '8. Limitation of Liability. In no event and under no legal theory, whether in tort (including negligence), contract, or otherwise, unless required by applicable law (such as deliberate and grossly negligent acts) or agreed to in writing, shall any Contributor be liable to You for damages, including any direct, indirect, special, incidental, or consequential damages of any character arising as a result of this License or out of the use or inability to use the Work, even if such Contributor has been advised of the possibility of such damages.\n\n'
                  '9. Accepting Warranty or Additional Liability. While redistributing the Work or Derivative Works thereof, You may choose to offer, and charge a fee for, acceptance of support, warranty, indemnity, or other liability obligations and/or rights consistent with this License. However, in accepting such obligations, You may act only on Your own behalf and on Your sole responsibility, not on behalf of any other Contributor, and only if You agree to indemnify, defend, and hold each Contributor harmless for any liability incurred by, or claims asserted against, such Contributor by reason of your accepting any such warranty or additional liability.\n\n'
                  'END OF TERMS AND CONDITIONS',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _licenseBlock(String name, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: GoogleFonts.oswald(color: const Color(0xFFD4AF37), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white10)),
            child: SelectableText(text, style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace', height: 1.4)),
          ),
        ],
      ),
    );
  }
}
