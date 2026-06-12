# Mobile Optimization Guidelines for Abomination

Everything we build related to Abomination needs to be optimized for mobile screens (small, super-wide screen aspect ratio).

## Core Principles

1. **Scrollable Panels**: Most dialog panels, detail cards, and content areas must be scrollable by wrapping columns or options list trees in `SingleChildScrollView` or utilizing scrollable widgets (`ListView`, `GridView`). This prevents vertical layout overflows on compact landscape devices.
2. **Minimal Header Heights**: Header sections, banners, and title texts must scale down or reduce their vertical footprint on small height screens to preserve maximum screen space for main interactive content.
3. **Minimal Padding & Spacing**: Margins, column spacings, and padding should shrink (e.g., using responsive checks like checking if `MediaQuery.of(context).size.height < 500`) to increase the layout budget.
4. **Adaptive Dialog Sizing**: Dialog boundaries must never use large hardcoded dimensions (like a fixed `height: 680`). Use relative bounds (e.g., `min(680.0, MediaQuery.of(context).size.height * 0.95)`) so elements resize dynamically to fit mobile displays.
