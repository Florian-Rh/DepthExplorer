# DepthExplorer — Task List

## Phase 0: Architectural Groundwork

### Architecture

- [ ] **Split ContentViewModel into focused components**
  ContentViewModel currently handles diver control (position, tilt, smoothing), dive simulation (timer, depth history, saturation), UI state (gas mixture selection), and game constants — all in one class. Separate into distinct responsibilities:
  - `DiverController` — joystick input, position smoothing, tilt, movement
  - `DiveSession` — session lifecycle, survival factor tracking, timer, depth history
  - `GameState` / `PlayerProfile` — persistent state (XP, currency, inventory, unlocks)
  Decide on ownership model: single `@StateObject` that composes these, or independent objects passed through the environment.

- [ ] **Define a game configuration data model**
  Consolidate game parameters into structured, static definitions that a developer can easily adjust for balancing. Two categories:
  - **Level definitions** (static per level): hard depth limit, available gear, depth scaling (px/m). Depth scaling is the key difficulty lever — it determines how much ocean fits on screen and thus how fast the player *appears* to move.
  - **Gear/skill base values** (dynamic per player loadout): movement speed modifier, air consumption modifier, thermal resistance, risk thresholds. The actual movement speed in meters/second comes from gear and skills, not from the level.
  Currently these are scattered as hardcoded values in ContentViewModel (`scalingFactor`, `maximumDepth`, etc.).

- [ ] **Define the Knowledgeable Item data model**
  `Item` is currently a flat struct with `depth`, `name`, `image`, `description` and a static array of placeholder items. Replace with a dedicated `KnowledgeableItem` model:
  - Category (species, oceanography, human history, human impact)
  - Fixed depth placement based on real-world data
  - Name, image, description (educational content)
  - Discovery state (discovered vs. redacted in glossary)
  - Discovered by proximity — not "picked up," but unlocked when the diver reaches it
  The existing `Item` TODO ("rename more appropriately") confirms this is known tech debt.

- [ ] **Define the Trash data model**
  Separate model from Knowledgeable Items. Trash is:
  - Randomly placed (not at fixed depths)
  - Has a Sand Dollar value (may vary by type)
  - No image or description — simple pickup collectible
  - Physically picked up by the diver (proximity interaction)

- [ ] **Design the persistence layer**
  Persistent player data (inventory, XP, level, unlocked gear, discovered Knowledgeables, currency) must survive across sessions. Session data (current dive state) is ephemeral. Choose and set up the storage approach (SwiftData, or plain Codable + file storage for simplicity). Define the persistent model types.

- [ ] **Remove `UIScreen.main` dependencies**
  `ContentView`, `ContentViewModel`, `ItemView`, `DepthScale`, and `OceanView` all reference `UIScreen.main.bounds` directly. This breaks on iPad (split screen, Stage Manager) and makes previews unreliable. Pass screen/container dimensions through `GeometryReader` or environment values instead.

- [ ] **Extract JoystickScrollDriver from ContentView**
  `JoystickScrollDriver` is a `CADisplayLink`-based class defined as a private class inside `ContentView.swift`. It mixes input handling (joystick deadzone, auto-surfacing) with frame-driven updates (smoothing). Extract it into its own file and clarify its role as the frame-update coordinator.

### Testing

- [ ] **Add unit tests for dive physics models**
  `GasMixture`, `HaldaneTissueSaturation`, and the pressure calculations in the view model have no tests. These are pure logic and straightforward to test. This is especially important because survival factors will build on top of these calculations and incorrect physics will cascade.

---

## Phase 1: Core Game Loop

### Architecture

- [ ] **Build the session lifecycle manager**
  Implement the dive session state machine: Surface (idle) → Diving → Surfaced Safely (rewards credited) / Rescued (items lost) / Quit (items lost). This drives when items are committed to persistent storage.

- [ ] **Build the warning/alert system**
  When the player approaches a soft limit (low air, cold exposure, fast ascent), display a warning before failure. Design a generic system for triggering, displaying, and clearing warnings that can accommodate new survival factors later.

### Features

- [ ] **Implement air supply mechanic**
  Add a finite air supply that depletes over time based on depth (higher pressure = faster consumption), gear (tank size, rebreather), and skills (breathing techniques). Display remaining air in the HUD.

- [ ] **Implement thermal model**
  Water temperature decreases with depth. Track cumulative cold exposure. Gear (dry suit) and depth determine cooling rate. Warn and eventually rescue the player on hypothermia.

- [ ] **Implement DCS risk from ascent speed**
  Track ascent rate (already partially modeled via `safeDesaturationSpeed`). Warn when ascending too fast. Trigger rescue on sustained unsafe ascent.

- [ ] **Implement narcosis from nitrogen partial pressure**
  Already have partial pressure calculation and tissue saturation. Add threshold detection, warning, and failure state.

- [ ] **Implement barotrauma from ambient pressure**
  Hard-gated by level depth limit (player can't reach barotrauma depths without appropriate gear). Add as a safety net for edge cases.

- [ ] **~~Implement hard depth limit per level~~** → moved to Phase 2

- [ ] **Implement Knowledgeable Item discovery**
  Detect proximity between diver and item. Trigger discovery animation/reveal. Mark as discovered in session state (committed to glossary on safe surfacing).

- [ ] **Implement trash pickup and Sand Dollar reward**
  Randomly place trash at varying depths each dive. Detect proximity, trigger pickup. Award Sand Dollars (committed on safe surfacing).

- [ ] **Build the glossary view**
  Display all Knowledgeable Items: discovered ones with full content, undiscovered ones as redacted entries. Accessible from a menu/settings screen.

- [ ] **Build the dive HUD**
  Replace the current StatusPanel with an in-game HUD showing: depth, air remaining, dive time, active warnings. The StatusPanel is currently commented out in ContentView.

- [ ] **Implement session end flow**
  On safe surfacing: animate return, credit collected items and XP to persistent store, show summary. On rescue: play rescue animation, show what was lost, return to surface.

---

## Phase 2: Progression System

### Features

- [ ] **Implement experience and leveling**
  XP earned from discovering Knowledgeables. Define XP thresholds per level. Level-ups unlock new hard depth limits, gear availability, and skill slots.

- [ ] **Enforce hard depth limit per level**
  Prevent the diver from descending past the current level's maximum depth. Visual/physical barrier. Apply depth scaling (px/m) from the level definition.

- [ ] **Implement the skill tree**
  Data model for skills with prerequisites (e.g., Fin Kicking L2 requires L1). One skill per level-up. Skills modify game parameters (air consumption rate, movement speed, control sensitivity).

- [ ] **Build the gear shop**
  UI for purchasing gear with Sand Dollars. Gear has level requirements. Purchased gear goes to inventory.

- [ ] **Implement gear effects on gameplay**
  Each equipped gear item modifies survival parameters: dry suit reduces thermal loss, larger tank increases air supply, different gas mixtures change narcosis/DCS risk, DPV increases movement speed.

- [ ] **Build the inventory and loadout screen**
  UI to view owned gear, equip/unequip items before a dive, view cosmetics.

---

## Phase 3: Content and Polish

### Features

- [ ] **Populate Knowledgeable Items**
  Research and write real-world content for all items across categories (species, oceanography, human history, human impact), placed at accurate depths.

- [ ] **Add higher-tier gear**
  Rebreather, personal submarine, bathysphere — each with unique mechanics (rebreather: extended time + reduced risk; submarine: eliminates most risks; bathysphere: required for Mariana Trench).

- [ ] **Add cosmetic upgrades**
  Suit colors and other visual customizations purchasable with Sand Dollars. Reflected in the Canvas-rendered diver.

- [ ] **Polish the glossary**
  Categories, search/filter, detail views with illustrations, progress indicators per category.

- [ ] **Add visual depth zones** (optional)
  Distinct visual environments at depth ranges (coral reef, open water, twilight zone, abyss). The architecture should already support this from the continuous OceanView design.

---

## Phase 4: Balancing and Maintenance

### Tasks

- [ ] **Playtest and tune survival parameters**
  Air consumption rate, thermal curves, DCS thresholds, narcosis onset — adjust based on human testing feedback.

- [ ] **Tune progression curve**
  XP per Knowledgeable, Sand Dollars per trash item, gear costs, level thresholds — ensure the game feels rewarding but not trivial.

- [ ] **Tune movement and controls**
  Smoothing factor, joystick sensitivity, auto-surface threshold, movement speed per gear tier.

- [ ] **Expand content**
  Add new Knowledgeable Items, trash types, gear, skills, and cosmetics as ongoing maintenance.
