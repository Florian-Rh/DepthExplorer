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

- [x] **Build the session lifecycle manager**
  Created `DiveSession` with state machine (`surface` → `diving` → `surfacedSafely` / `rescued`). Tracks ephemeral session inventory (discovered items, sand dollars). `commitRewards(to:)` persists to `ProfileStore` on safe surfacing, `discard()` drops everything. `DiveSimulation` delegates lifecycle transitions to `DiveSession`.

- [x] **Build the warning/alert system**
  Created `DiveWarning.swift` with `DiveWarningKind` (per survival factor), `DiveWarningSeverity` (caution → critical → fatal), and `DiveWarningSystem` (set/clear/clearAll). Wired into `LevelViewModel`. Survival factors will call `warningSystem.set(...)` and `warningSystem.clear(...)` during their tick.

### Features

- [x] **Implement air supply mechanic**
  Created `AirSupply` model (200 bar default capacity, SAC rate × ambient pressure consumption). Integrated into `DiveSimulation` tick: consumes air while diving, evaluates warnings (caution at 50 bar, critical at 10 bar, fatal at 0 bar), triggers rescue on empty. Displayed in StatusPanel. Tank refills on each new dive.

- [x] **Implement thermal model**
  Water temperature decreases with depth. Track cumulative cold exposure. Gear (dry suit) and depth determine cooling rate. Warn and eventually rescue the player on hypothermia.

- [x] **Implement DCS risk from ascent speed**
  Track ascent speed (m/s real time) each simulation tick by comparing depth changes. Smoothed with exponential moving average (separate buildup/decay rates) so brief movements don't kill instantly. Evaluated against a game-tuned `safeAscentSpeed` constant with configurable thresholds (caution at 80%, critical at 100%, fatal/rescue at 150%). Time-scale independent — measures physical screen movement, not simulated time. Displayed in StatusPanel alongside safe speed.

- [ ] **Implement narcosis from nitrogen partial pressure**
  Already have partial pressure calculation and tissue saturation. Add threshold detection, warning, and failure state.

- [ ] **Implement barotrauma from ambient pressure**
  Hard-gated by level depth limit (player can't reach barotrauma depths without appropriate gear). Add as a safety net for edge cases.

- [x] **Implement Knowledgeable Item discovery**
  Detect proximity between diver and item. Trigger discovery animation/reveal. Mark as discovered in session state (committed to glossary on safe surfacing).

- [x] **Implement trash pickup and Sand Dollar reward**
  Randomly place trash at varying depths each dive. Detect proximity, trigger pickup. Award Sand Dollars (committed on safe surfacing).

- [x] **Build the glossary view**
  Display all Knowledgeable Items: discovered ones with full content, undiscovered ones as redacted entries. Accessible from a menu/settings screen.

- [x] **Build the dive HUD**
  Replace the current StatusPanel with an in-game HUD showing: depth, air remaining, dive time, active warnings. The StatusPanel is currently commented out in LevelView.

- [x] **Implement session end flow**
  On safe surfacing: animate return, credit collected items and XP to persistent store, show summary. On rescue: play rescue animation, show what was lost, return to surface.

---

## Phase 2: Progression System

### Features

- [X] **Implement experience and leveling**
  XP earned from discovering Knowledgeables. Define XP thresholds per level. Level-ups unlock new hard depth limits, gear availability, and skill slots.

- [X] **Rank of diver should be displayed**
  From level 1 to 4: Free Diver
  From level 5 to 9: Scuba Diver
  From level 9 to 14: Tech Diver
  From level 15 to 19: Marine Specialist
  Level 20 and above: Oceanographer
  The title in the hub should display the current rank. Next to the rank is a "?" icon, that, when tapped, shows an explaination of the rank and what it means. you can use placeholder texts for now. 
  When a new rank is reached, it should be displayed on the completion screen rather visibly, with a bit an animation (confetti, firework or similar). From there, it should also be possible to show the explaination of the rank 

- [x] **Implement the skill tree**
  Data model for skills with prerequisites (e.g., Fin Kicking L2 requires L1). One skill per level-up. Skills modify game parameters (air consumption rate, movement speed). Two families: Breathing Techniques (SAC rate reduction) and Fin Kicking (speed boost), each with 3 levels. Skill points granted on level-up, spent in the Hub's Skills tab.

- [x] **Build the gear shop**
  UI for purchasing gear with Sand Dollars. Gear has level requirements. Purchased gear goes to inventory. Three categories: Fins (Advanced, Pro), Suits (5mm, 7mm, Drysuit), Tanks (Double). Accessible via the Hub.

- [x] **Implement gear effects on gameplay**
  `DiveParameters` struct computed from profile (equipped gear + acquired skills). Gear provides absolute replacements (fins set speed, suits set thermal protection, tanks set capacity). Skills provide multiplicative modifiers on top. Wired into `AirSupplyModel`, `ThermalModel`, `DiverController`, and `LevelViewModel`.

- [x] **Build the inventory and loadout screen**
  UI to view owned gear, equip/unequip items before a dive. One item per category slot with a "Default" option. Accessible via the Hub's Loadout tab.

---

## Phase 3: Content and Polish

### Features

- [ ] **Load Knowledgeable Items from a JSON file**
  Move item definitions out of the compiled `KnowledgeableItem.allItems` array and into a bundled JSON resource. Add `Codable` conformance to `KnowledgeableItem` and `KnowledgeableCategory`. Load and decode at startup.
  
- [ ] **Add animated graphics for Knowledgeable Items**
  Various types of fish for instance can move around (some in schools). In order to unlock the item,   

- [ ] **Populate Knowledgeable Items**
  Research and write real-world content for all items across categories (species, oceanography, human history, human impact), placed at accurate depths.

- [ ] **Add higher-tier gear**
  Rebreather, personal submarine, bathysphere — each with unique mechanics (rebreather: extended time + reduced risk; submarine: eliminates most risks. Is subsceptible to ambient pressure. Has a battery and CO2-Scrubber which can be upgraded individually; bathysphere: required for Mariana Trench).

- [ ] **Add cosmetic upgrades**
  Suit colors and other visual customizations purchasable with Sand Dollars. Reflected in the Canvas-rendered diver.

- [ ] **Polish the glossary**
  Categories, search/filter, detail views with illustrations, progress indicators per category.

- [ ] **Add warning and rescue animations**
  Visual feedback for warning escalation (screen tint, vignette, shake) and a rescue animation sequence (diver pulled to surface) instead of the current instant snap to surface.

- [ ] **Add visual depth zones**
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
  
- [ ] **Add legal disclaimer**
  Explain that the game, while trying to mimicing real diving physics, changed safety thresholds for a more enjoyable game pace. Make it clear that values from the game should under no circumstanbces be applied to real world diving, and that anyone who wishes to go scuba diving, should get licensed through a professional diving instructor.
   
- [ ] **Expand content**
  Add new Knowledgeable Items, trash types, gear, skills, and cosmetics as ongoing maintenance.


## Further Ideas

### Tasks

- [ ] **DCS risk speed should depend on depth**
  The closer the diver gets to the surface, the lower the safe ascent speed should be, meaning that a dive from 300 to 200 meters has little effect on ascent speed, but a dive from 100 to 0 meters has a high effect 
  
- [ ] **Skills can be limited to certain levels**
  For example, the player can acquire the skills "multi-gas diving", "Advanced multi-gas diving" and "hypoxic multi-gas diving", which reduces the risk for DCS, but is only available for level 15 and above.
  
- [ ] **Details for glossary entries**
  It should be possible to tap a glossary entry, nevigating to a detail page with more information on that entry.

- [ ] **Glossary section for hyperbaric medicine**
  Entry for each cause of rescue. These entries cannot be found under water, instead, when the player becomes rescued, the corresponding entry is unlocked. The rescue screen should include a "read more" button which takes the user directly to the glossary entry.
  
- [ ] **Glossary section for gear**
  Entries for various types of gear, explaining what they do and how they work. These entries cannot be found under water, instead, when the player buys them, the glossary entry is added. Note: Not all items have a glossary entry.
  
- [ ] **Highlight new glossary entries**
  When a new glossary entry is unlocked, a badge should be displayed, similar to the one when a skill point is available.
  
- [ ] **Graphics for trash**
  Instead of a trah icon with the value in dollars underneith, a graphic should be displayed. For variation, we should have at least 10 different types of trash, valued between 1 and 5 Sand dollars. More expensive trash is larger or more dangerous to the environment (i.E. a discarded battery is worth more than a soda bottle)
  
- [ ] **Limit for trash pickup**
  The amount of trash the player can pick up should be limited. In the shop, the player can purchase mash bags to increse the amount of trash he can collect

- [ ] **Add buoyancy to the DiveParameters**
  With a low buoyancy control value, the diver tends to move upwards in shallower water, and downwards in deeper water. Buoyancy control can become better through skills and through buying better BCDs.

- [ ] **Implement currents**
  Depending on direction, currents can push the diver to the left, right, top or bottom, or even swirl him around in a circle. Effect of currents can be mitigated through boucancy control

- [ ] **Night diving**
  description 

- [ ] **title**
  description 
