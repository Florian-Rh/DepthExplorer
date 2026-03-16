# DepthExplorer — Task List

## Phase 0: Architectural Groundwork

### Architecture

- [x] **Split ContentViewModel into focused components**
  Split into `DiverController` (joystick input, position smoothing, tilt), `DiveSimulation` (timer, depth history, saturation), and `LevelViewModel` (thin coordinator). Renamed `ContentView` → `LevelView`.

- [x] **Define a game configuration data model**
  Created `LevelDefinition` (depth limit, scaling factor, auto-surface) and `GameConstants` (movement, joystick, simulation tuning knobs) in `GameConfig.swift`. Wired into all consuming types.

- [x] **Define the Knowledgeable Item data model**
  Replaced `Item` with `KnowledgeableItem` (category, fixed depth, name, image, description). Renamed `ItemView` → `KnowledgeableItemView`, removed tap/expand logic. Removed old `Item.swift`.

- [x] **Define the Trash data model**
  Created `TrashItem` with random depth placement and Sand Dollar value. Separate model from `KnowledgeableItem`.

- [x] **Design the persistence layer**
  Codable + JSON file approach. Created `PlayerProfile` (sand dollars, XP, discovered items) and `ProfileStore` (load/save to documents directory, mutation methods). Session state remains ephemeral in memory.

- [x] **Remove `UIScreen.main` dependencies**
  Added `screenSize` to `LevelViewModel`, fed from `GeometryReader` in `LevelView`. Passed to `KnowledgeableItemView` and `OceanView` as parameters. `DepthScale` uses its own internal `GeometryReader`. `JoystickScrollDriver` reads from `vm.screenSize`.

- [x] **Extract JoystickScrollDriver from LevelView**
  Extracted to `FrameUpdateDriver.swift` (renamed to reflect its broader role: diver smoothing + scroll offset). `LevelView` now references `FrameUpdateDriver` as `@State private var frameDriver`.

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
  Replace the current StatusPanel with an in-game HUD showing: depth, air remaining, dive time, active warnings. The StatusPanel is currently commented out in LevelView.

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

- [ ] **Load Knowledgeable Items from a JSON file**
  Move item definitions out of the compiled `KnowledgeableItem.allItems` array and into a bundled JSON resource. Add `Codable` conformance to `KnowledgeableItem` and `KnowledgeableCategory`. Load and decode at startup.

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
