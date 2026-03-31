# FrankensteinOSS

**FrankensteinOSS** is a mad scientist management simulator built with Flutter. Set in a rural Swiss manor in the 1860s, the game challenges players to balance traditional manor management with dark, experimental science. 

## 🦇 Game Overview

- **Manor Management:** Build and manage a 6-tier manor estate, ranging from subterranean laboratories to expansive upper-floor chambers. Assign tasks, manage NPC physiological needs, and oversee estate resources in an industrial-dark blueprint aesthetic.
- **Complex NPC AI:** A granular task scheduling and queueing system. NPCs have physiological needs (hunger, energy) and specific routines that react dynamically to the environment and the player's orders.
- **Science and Research:** A core progression loop simulating bizarre scientific experiments. Accelerate research by engaging with study materials, culminating in reanimation, cybernetics, and biological alterations.
- **Tactical Combat:** Skirmish simulation on a grid-based battlefield. Deploy customized units from a dynamic hand of cards, manage action points (AP), and engage enemy forces.

## 🛠️ Technology Stack

- **Engine:** [Flutter](https://flutter.dev/) (Dart 3.x)
- **State Management:** Provider
- **Key Architecture:**
  - *Temporal Engine:* A global clock that runs on 1-minute logic increments to support smooth visual locomotion and detailed daily routines.
  - *Task Queues:* Robust assignment logic handling concurrent NPC actions, locomotion, and schedule preemption.
  - *Custom UI:* "Parchment & Scroll" visual themes utilizing custom painting and stylized layouts, creating an immersive 19th-century atmospheric feel.

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.10.0 or higher)
- Android Studio / Xcode (for mobile deployment) or a configured desktop/web runner environment.

### Installation

1. Clone the project repository and navigate into the directory:
   ```bash
   git clone <repository-url>
   cd frankensteinoss
   ```

2. Fetch package dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

## 🗺️ Roadmap & Development

For details on the project's future expansions (including Sanity & Stress mechanics, Lineage Management, and Dynamic Events), please refer to the development documentation and roadmap files within the project.

## 🤝 Contributing

Contributions are welcome! Whether it's fixing NPC pathfinding bugs, adding new experimental technologies, or refining the UI, please feel free to submit a Pull Request. 

## 📜 License

This project is licensed under the **Apache License 2.0**. See the [LICENSE](LICENSE) file for more information.

The game is inspired by Mary Shelley's Frankenstein (1818) and includes Carl Spitzweg's "Der Maler im Garten" (1860).
