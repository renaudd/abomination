# Open TODOs and Future Feature Opportunities

This document tracks identified placeholders, inchoate features, and technical/design TODOs across the *Abomination* codebase, providing concrete pathways for future development and systems integration.

---

## 1. Research Level & Quest Integration

### Context
When removing the placeholder objectives `Zoological Curiosity` and `The Spark`, we identified that the objective verification pipeline (`_checkObjectives()` in `lib/state/game_state.dart`) was entirely missing support for checking the `research_level` requirement key:
```dart
requirements: {
  'research_level': {'Zoology': 1},
}
```
Because no checker existed, any objective using this requirement instantly marked itself as completed, leading to premature completion logs.

### Opportunities
* **Implement the `research_level` Checker**: Integrate checking logic into `_checkObjectives()` in [game_state.dart](file:///Users/rend/Development/Abomination/lib/state/game_state.dart):
  ```dart
  if (reqs.containsKey('research_level')) {
    final targetLevels = reqs['research_level'] as Map<String, dynamic>;
    for (var entry in targetLevels.entries) {
      final discipline = entry.key;
      final requiredLevel = (entry.value as num).toDouble();
      if (getKnowledgeLevel(discipline) < requiredLevel) {
        completed = false;
        break;
      }
    }
  }
  ```
* **Re-integrate Progressive Science Quests**: Use this checker to restore progressive questlines that require active research study, unlocking advanced laboratory operations or rare items upon completing academic milestones.

---

## 2. Parent's Death Cause & Quest Consequences

### Context
In [game_state.dart](file:///Users/rend/Development/Abomination/lib/state/game_state.dart#L3533), player biography generation displays a custom description based on the player character's parents' cause of death (`DeathCause`). It contains the following comment:
```dart
return "$baseBio $deathDesc\n\n// TODO: develop meaningful quests and game consequences tied to this death cause.";
```

### Opportunities
* **Narrative Branching**: Introduce distinct starting quests or flavor text sequences in Chapter 1 depending on whether the parents died from `disease`, a `trainCrash`, a `murderSuicide`, or a `misunderstanding`.
* **Gameplay Consequences**:
  * **Disease**: The player could start with a slight resistance to status effects, or start with higher baseline Medicine research.
  * **Train Crash**: Unlocks mechanical or structural repair-oriented bonuses early in the Manor.
  * **Murder-Suicide**: Modifies relationships or starting fear levels with certain Victoria secret societies.

---

## 3. Specialized Room-Specific Eating Tasks

### Context
In [room.dart](file:///Users/rend/Development/Abomination/lib/models/room.dart#L527), multiple rooms share a generic `TaskType.eat` task with a placeholder comment:
```dart
case RoomType.diningRoom:
case RoomType.pigPen:
case RoomType.cattlePasture:
  tasks.add(task_service.TaskType.eat); // Placeholder or specific tasks
  break;
```

### Opportunities
* **Task Differentiation**: 
  * **Humans (`diningRoom`)**: Modify the `eat` task in the Scullery / Dining Room to consume cooked food items (from the pantry/inventory) and trigger social events, character conversations, or happiness increases.
  * **Animals (`pigPen`, `cattlePasture`)**: Replace `eat` with animal-specific feeding tasks (e.g., `feedPigs`, `grazeCattle`) requiring feed resources and contributing to ranching yields/growth.

---

## 4. Physical Texts & Hybrid Scientific Knowledge Requirements [IMPLEMENTED]

### Context & Implementation
We have fully implemented a hybrid/dual-requirement verification system where advanced actions and room conversions require both **specific physical texts** (blueprints or books present in the manor) and a **minimum accumulated discipline knowledge level** (calculated dynamically from knowledge items).

* **Implemented Verifications**:
  * **Laboratory Construction**: Requires Zoology level $\ge$ 1 and possession of the `'lab_schematics'` blueprint.
  * **Operating Room Conversion**: Requires Surgery level $\ge$ 3, Medicine level $\ge$ 2, and possession of the `'surgical_theater_blueprint'`.
  * **Reanimation Procedure**: Requires Alchemy level $\ge$ 2 and possession of `'principles_of_galvanism'`.
  * **Transmutation**: Requires Alchemy level $\ge$ 5, Chemistry level $\ge$ 3, and possession of `'lemegeton_alchymia'`.
* **Behavior**: If either requirement is not met, task assignment or room conversion fails cleanly with an announcement.

---

## 5. Inventions and Tech Upgrades

### Context
In [discoveries_content.dart](file:///Users/rend/Development/Abomination/lib/ui/widgets/discoveries_content.dart#L57), there is a placeholder comment for a separate tab/category:
```dart
// Placeholder for Inventions
```

### Design Principles & Opportunities
* **The "Invent" Action (Modeled on Cooking Recipes)**:
  * Implement an `Invent` action in the Workshop/Laboratory where the player selects one or more components as inputs (e.g., copper wire, iron plates, gears, galvanic cells).
  * If the input combination matches a valid machine/device in the database, a check is run.
  * On success:
    * The physical invention is produced (e.g., an "Automated Harvester", "Alchemical Smoker", or "Lightning Rod").
    * The blueprint/recipe is learned and added to the Manor's library for future production without repeating the discovery process.
* **Patent Application & Faction Hostility**:
  * Any discovered invention can be patented by applying through the game state.
  * **Consequences**: Applying for a patent triggers competitor hostility, launching corporate espionage encounters, patent raiders, and litigation events (new tactical combat cards or events).
  * **Legal Defense**: Patent filings and lawsuits require "Legal Services" resources or action completions.
  * **In-House Law Firm**: Introduce a specialized Manor Room (e.g., the Law Firm / Office) that allows residents with high administrative/legal skills to perform Legal Services in-house to resolve these crises.
  * **Patent Rewards**: Successfully obtaining a patent increases both the market demand and the sell price/value of the patented item when trading with visiting merchants.

---

## 6. Dynamic Audio & Bleak Music

### Context
In [main.dart](file:///Users/rend/Development/Abomination/lib/main.dart#L60), the background audio system uses a hardcoded URL:
```dart
// Play placeholder bleak music (user can replace URL)
```

### Opportunities
* **Dynamic Playlist**: Build a playlist system that shifts the music track depending on the active game state (e.g. eerie/atmospheric for laboratory procedures, fast-paced orchestral for tactical combat, and somber acoustic for general manor maintenance).

---

## 7. Graduate School Progression & Canton Businesses [PARTIALLY IMPLEMENTED]

### Context & Implementation
The Canton Business room conversions and the required academic specialization verification are now fully implemented and integrated:
* **Clinic (Medicine Specialization)**: Requires graduation with a Medicine specialization.
* **Pharmacy (Pharmacy/Chemistry Specialization)**: Requires graduation with a Pharmacy or Chemistry specialization.
* **Law Firm (Law Specialization)**: Requires graduation with a Law specialization.
* **Operating Room upgrade (Hospital)**: Requires Surgery level $\ge$ 3, Medicine level $\ge$ 2, and the physical blueprint `'surgical_theater_blueprint'`.
* **Dentist Practice**: Exists as an upgrade option.

**Remaining Open Tasks**:
* **Graduate School Lifecycle Progression**: Complete the remote manor management events (Butler Flaubert Giles events), entrance exams, and Canton licensing board faction standing mechanics.
