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
import 'manor_screen.dart';

class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({super.key});

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  int _currentScene = 1;
  late final FocusNode _introFocusNode;

  // Selections
  DeathCause? _deathCause;
  int _age = 25;
  GilesTrait _gilesTrait = GilesTrait.sage;
  LifeObjective _objective = LifeObjective.science;

  final TextEditingController _firstNameController = TextEditingController(
    text: "Alphonse",
  );
  final TextEditingController _lastNameController = TextEditingController(
    text: "Frankenstein",
  );
  final TextEditingController _estateNameController = TextEditingController(
    text: "Ingolstadt",
  );

  @override
  void initState() {
    super.initState();
    _introFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _introFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _introFocusNode.dispose();
    super.dispose();
  }

  void _navigateToScene(int scene) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _currentScene = scene;
    });
    _introFocusNode.requestFocus();
  }

  void _triggerOptionByIndex(int index) {
    switch (_currentScene) {
      case 1:
        if (index >= 0 && index < DeathCause.values.length) {
          _selectDeath(DeathCause.values[index]);
        }
        break;
      case 3:
        final ages = [15, 25, 35, 45];
        if (index >= 0 && index < ages.length) {
          _selectAge(ages[index]);
        }
        break;
      case 4:
        if (index >= 0 && index < GilesTrait.values.length) {
          _selectGiles(GilesTrait.values[index]);
        }
        break;
      case 5:
        if (index >= 0 && index < LifeObjective.values.length) {
          _selectObjective(LifeObjective.values[index]);
        }
        break;
      case 6:
        if (index == 0) {
          _finish(context);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _introFocusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          // Skip hotkeys if typing in a text field
          final primaryFocus = FocusManager.instance.primaryFocus;
          if (primaryFocus != null && primaryFocus.context != null) {
            final hasTextFocus = primaryFocus.context!.findAncestorWidgetOfExactType<EditableText>() != null;
            if (hasTextFocus) return;
          }

          final key = event.physicalKey;
          if (key == PhysicalKeyboardKey.digit8 || key == PhysicalKeyboardKey.numpad8) {
            if (_currentScene > 1) {
              _navigateToScene(_currentScene - 1);
            }
          } else if (key == PhysicalKeyboardKey.digit9 || key == PhysicalKeyboardKey.numpad9) {
            if (_currentScene < 6 && _currentScene != 1) {
              _navigateToScene(_currentScene + 1);
            }
          } else if (key == PhysicalKeyboardKey.digit1 || key == PhysicalKeyboardKey.numpad1) {
            _triggerOptionByIndex(0);
          } else if (key == PhysicalKeyboardKey.digit2 || key == PhysicalKeyboardKey.numpad2) {
            _triggerOptionByIndex(1);
          } else if (key == PhysicalKeyboardKey.digit3 || key == PhysicalKeyboardKey.numpad3) {
            _triggerOptionByIndex(2);
          } else if (key == PhysicalKeyboardKey.digit4 || key == PhysicalKeyboardKey.numpad4) {
            _triggerOptionByIndex(3);
          } else if (key == PhysicalKeyboardKey.digit5 || key == PhysicalKeyboardKey.numpad5) {
            _triggerOptionByIndex(4);
          } else if (key == PhysicalKeyboardKey.digit6 || key == PhysicalKeyboardKey.numpad6) {
            _triggerOptionByIndex(5);
          } else if (key == PhysicalKeyboardKey.digit7 || key == PhysicalKeyboardKey.numpad7) {
            _triggerOptionByIndex(6);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1612),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            _introFocusNode.requestFocus();
          },
          child: Stack(
            children: [
              // Background Spitzweg Image
              Positioned.fill(
                child: Opacity(
                  opacity: 0.4,
                  child: Image.asset(
                    'assets/images/Carl_Spitzweg_-_Der_Maler_im_Garten.jpg',
                    fit: BoxFit.cover,
                    color: Colors.black,
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
              ),

              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(child: _buildSceneContent()),
                      ),
                      _buildFooter(),
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

  Widget _buildHeader() {
    return Text(
      'ANNO 1860',
      style: GoogleFonts.playfairDisplay(
        color: const Color(0xFFC4B89B),
        fontSize: 12,
        letterSpacing: 4,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSceneContent() {
    switch (_currentScene) {
      case 1:
        return _scene1();
      case 2:
        return _scene2();
      case 3:
        return _scene3();
      case 4:
        return _scene4();
      case 5:
        return _scene5();
      case 6:
        return _scene6();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _scene1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sceneText("Your parents have died. It was a..."),
        const SizedBox(height: 12),
        _optionButton(
          "TERRIBLE DISEASE.",
          () => _selectDeath(DeathCause.disease),
          index: 0,
        ),
        _optionButton(
          "TRAIN CRASH.",
          () => _selectDeath(DeathCause.trainCrash),
          index: 1,
        ),
        _optionButton(
          "MURDER-SUICIDE.",
          () => _selectDeath(DeathCause.murderSuicide),
          index: 2,
        ),
        _optionButton(
          "MISUNDERSTANDING.",
          () => _selectDeath(DeathCause.misunderstanding),
          index: 3,
        ),
      ],
    );
  }

  Widget _scene2() {
    String reaction = "";
    switch (_deathCause) {
      case DeathCause.disease:
        reaction =
            "The stench of ether still haunts the hallways of your memories.";
        break;
      case DeathCause.trainCrash:
        reaction = "The iron beast's failure was... explosive.";
        break;
      case DeathCause.murderSuicide:
        reaction = "A violent end for a violent lineage.";
        break;
      case DeathCause.misunderstanding:
        reaction = "A comedy of errors, ending in tragedy.";
        break;
      default:
        break;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sceneText(reaction),
        const SizedBox(height: 12),
        _sceneText("Leaving you, Master..."),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _inputField(
                "FIRST NAME",
                _firstNameController,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _inputField(
                "LAST NAME",
                _lastNameController,
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _sceneText("as Junker of..."),
        const SizedBox(height: 8),
        _inputField(
          "ESTATE NAME",
          _estateNameController,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _navigateToScene(3),
        ),
      ],
    );
  }

  Widget _scene3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sceneText("A terrible fate to befall a boy who is only..."),
        const SizedBox(height: 12),
        _optionButton(
          "15 YEARS OLD.",
          () => _selectAge(15),
          isSelected: _age == 15,
          index: 0,
        ),
        _optionButton(
          "25 YEARS OLD.",
          () => _selectAge(25),
          isSelected: _age == 25,
          index: 1,
        ),
        _optionButton(
          "35 YEARS OLD.",
          () => _selectAge(35),
          isSelected: _age == 35,
          index: 2,
        ),
        _optionButton(
          "45 YEARS OLD.",
          () => _selectAge(45),
          isSelected: _age == 45,
          index: 3,
        ),
      ],
    );
  }

  Widget _scene4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sceneText(
          "In this time of great mourning, take comfort in the continued servitude of your everloyal butler, Flaubert Giles.",
        ),
        const SizedBox(height: 10),
        _sceneText("Giles was always really good at..."),
        const SizedBox(height: 12),
        _optionButton(
          "GIVING SAGE ADVICE. (Tutorial Mode)",
          () => _selectGiles(GilesTrait.sage),
          isSelected: _gilesTrait == GilesTrait.sage,
          index: 0,
        ),
        _optionButton(
          "MAKING ENDS MEET.",
          () => _selectGiles(GilesTrait.endsMeet),
          isSelected: _gilesTrait == GilesTrait.endsMeet,
          index: 1,
        ),
        _optionButton(
          "KEEPING HIS MOUTH SHUT.",
          () => _selectGiles(GilesTrait.silent),
          isSelected: _gilesTrait == GilesTrait.silent,
          index: 2,
        ),
        _optionButton(
          "NOT SHUFFLING HIS FEET.",
          () => _selectGiles(GilesTrait.shuffle),
          isSelected: _gilesTrait == GilesTrait.shuffle,
          index: 3,
        ),
      ],
    );
  }

  Widget _scene5() {
    String intro = _gilesTrait == GilesTrait.silent
        ? "Silence fills the room as you reflect. This is an opportunity for you to finally pursue your interest in..."
        : "Giles adjust his spectacles. 'This is an opportunity for you to finally pursue your interest in...'";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sceneText(intro),
        const SizedBox(height: 12),
        _optionButton(
          "WOMEN.",
          () => _selectObjective(LifeObjective.women),
          isSelected: _objective == LifeObjective.women,
          index: 0,
        ),
        _optionButton(
          "MONEY.",
          () => _selectObjective(LifeObjective.money),
          isSelected: _objective == LifeObjective.money,
          index: 1,
        ),
        _optionButton(
          "FAME.",
          () => _selectObjective(LifeObjective.fame),
          isSelected: _objective == LifeObjective.fame,
          index: 2,
        ),
        _optionButton(
          "SCIENCE.",
          () => _selectObjective(LifeObjective.science),
          isSelected: _objective == LifeObjective.science,
          index: 3,
        ),
      ],
    );
  }

  Widget _scene6() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sceneText("The manor stands silent, awaiting your command."),
        const SizedBox(height: 10),
        _sceneText("'First, this house really needs to be cleaned up.'"),
        const SizedBox(height: 12),
        Center(
          child: _optionButton(
            "BEGIN THE WORK",
            () => _finish(context),
            isSelected: true,
            index: 0,
          ),
        ),
      ],
    );
  }

  Widget _sceneText(String text) {
    return Text(
      text,
      style: GoogleFonts.playfairDisplay(
        color: const Color(0xFFE5D5B0),
        fontSize: 12,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller, {
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: GoogleFonts.oldStandardTt(
        color: const Color(0xFFC4B89B),
        fontSize: 13,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.playfairDisplay(
          color: Colors.white24,
          fontSize: 11,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white10),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFC4B89B)),
        ),
      ),
    );
  }

  Widget _optionButton(
    String label,
    VoidCallback onTap, {
    bool isSelected = false,
    int? index,
  }) {
    final displayLabel = label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? const Color(0xFFC4B89B) : Colors.white10,
            ),
            color: isSelected
                ? const Color(0xFFC4B89B).withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Text(
            displayLabel,
            style: GoogleFonts.playfairDisplay(
              color: isSelected ? const Color(0xFFE5D5B0) : Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentScene > 1)
          TextButton(
            onPressed: () => _navigateToScene(_currentScene - 1),
            child: Text(
              "BACK",
              style: GoogleFonts.playfairDisplay(color: Colors.white24),
            ),
          )
        else
          const SizedBox.shrink(),
        if (_currentScene < 6 &&
            _currentScene != 1) // Scene 1 requires selection to advance
          TextButton(
            onPressed: () => _navigateToScene(_currentScene + 1),
            child: Text(
              "NEXT",
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFC4B89B),
              ),
            ),
          ),
      ],
    );
  }

  void _selectDeath(DeathCause cause) {
    _deathCause = cause;
    _navigateToScene(2);
  }

  void _selectAge(int age) {
    _age = age;
    _navigateToScene(4);
  }

  void _selectGiles(GilesTrait trait) {
    _gilesTrait = trait;
    _navigateToScene(5);
  }

  void _selectObjective(LifeObjective objective) {
    _objective = objective;
    _navigateToScene(6);
  }

  void _finish(BuildContext context) {
    final state = Provider.of<GameState>(context, listen: false);
    state.initializeNewGame(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      estateName: _estateNameController.text,
      deathCause: _deathCause!,
      age: _age,
      gilesTrait: _gilesTrait,
      objective: _objective,
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const ManorScreen()),
      (route) => false,
    );
  }
}
