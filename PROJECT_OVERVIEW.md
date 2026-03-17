# DepthExplorer (Working Title)

## Purpose

DepthExplorer is a casual learning game that teaches about the underwater world and the history of human ocean exploration, while raising awareness for pollution and humanity's impact on the ocean climate.

The core mechanics are simple: the player explores the underwater world by steering their character. The player can learn skills such as breathing techniques or purchase upgrades for their scuba gear, allowing them to dive deeper and longer. The ultimate goal is to reach the Challenger Deep in the Mariana Trench, the deepest point in the ocean.

## Game Mechanics

### Depth Limits

Each player level defines a **hard depth limit** that reflects the underwater environment scaling (e.g., Level X allows a maximum of 40m). The player physically cannot descend past this boundary.

Within the reachable range, **soft limits** create risk through survival factors. The player does not die immediately upon approaching a soft limit — they receive a warning first and have time to react. Failure only occurs if warnings are ignored.

To keep it child-friendly, the player does not actually die — instead they are "rescued." On rescue, all items collected during that dive are lost.

### Survival Factors

Limiting factors (soft limits):
- **Air supply** — Breathing gas is finite. The player suffocates if they run out.
- **Thermal profile** — Water gets colder the deeper the character goes. Spending too much time in cold water causes hypothermia.
- **Ascent speed** — Rising too fast induces decompression sickness (DCS).
- **Partial pressure of nitrogen** — Causes gas narcosis at depth.
- **Ambient pressure** — Causes barotrauma.

Not all factors are relevant at every depth. For example, at 40m the player cannot die of barotrauma, and air supply will deplete long before hypothermia sets in — but they can suffocate if they ignore their air gauge, or suffer DCS if they ascend too quickly.

### Dive Sessions

Each dive is a **fresh run**. Items and XP collected during a dive are only credited to the player's persistent inventory if the session ends by surfacing safely. A session can be paused via a settings screen, but quitting the game mid-session has the same effect as being rescued (items lost). Persistent data (inventory, XP, unlocks) is stored between sessions (e.g., SwiftData).

### Collectibles

There are two types of collectibles:

**Knowledgeable Items** are real-world facts about interesting species, oceanography, the history of human ocean exploration, or the impact of humans on the health of the sea. They appear at **fixed depths** corresponding to real-world data (e.g., "The deepest scuba dive ever performed" always appears at 332m). Knowledgeables are not picked up — they are **discovered** when the diver reaches them. All discovered Knowledgeables can be found in a glossary, alongside "redacted" entries for yet-undiscovered items.

Examples:
- The deepest dive ever performed by a human in scuba gear at 332m (human history)
- Brine pools (oceanography)
- Mantis shrimp (species)
- Coral bleaching (human impact)

**Trash** is randomly placed at varying depths each dive. Trash is picked up by the diver on proximity and awards Sand Dollars. It has no image or description — it is a simple collectible with a varying currency value.

### Currency and Progression

**Sand Dollars** (working title) are the in-game currency, earned by picking up trash underwater. Experience is earned by discovering Knowledgeable Items. Some gear requires a minimum experience level to purchase.

### Gear Upgrades

- **Dry diving suit** — Better thermal protection
- **Different gas mixtures** — Reduced narcosis and DCS risk
- **Tank upgrades** — More breathing gas
- **Scooter / DPV** — Higher movement speed
- **Rebreather** — High level; extends dive time, significantly reduces DCS and narcosis risk
- **Personal submarine** — High level; extends dive time significantly, eliminates DCS and narcosis risk
- **Bathysphere** — Highest level, most expensive. The only gear that allows reaching the bottom of the Mariana Trench, and thus required to "win" the game

Cosmetic upgrades such as suit colors can also be purchased.

### Skills

When leveling up, the player can acquire one skill per level. Some skills have prerequisites (e.g., Fin Kicking Level 2 requires Fin Kicking Level 1).

- **Buoyancy control** — Character is easier to control
- **Breathing techniques** — Lower air consumption
- **Fin kicking techniques** — Faster movement speed

## Target Audience

The game is child-friendly but not primarily targeted at children. It aims to provide entertainment and knowledge for anyone interested in the underwater world. Experienced scuba divers or marine biologists may already know most of the Knowledgeables, but can still enjoy the progression and exploration.

## Feature Roadmap

### Current Features
- Ocean environment with depth scale and items placed at real-world depths
- Joystick-controlled diver with smooth movement and rotation
- Basic dive simulation (depth tracking, nitrogen saturation model, gas mixtures)
- Canvas-rendered animated scuba diver with bubbles

### Phase 1: Core Game Loop
- Survival mechanics (air supply, thermal model, DCS/narcosis risk)
- Warning system for approaching soft limits
- Dive failure / rescue mechanic
- Collectible Knowledgeable Items (pickup, display, glossary)
- Trash collection and Sand Dollar currency
- Session lifecycle (fresh run, safe surfacing = rewards kept, rescue/quit = items lost)
- Persistent storage for inventory, XP, and unlocks
- Single continuous level with no hard depth limit (full depth range available for testing)

### Phase 2: Progression System
- Experience and leveling
- Hard depth limits and depth scaling per level
- Skill tree (buoyancy control, breathing techniques, fin kicking)
- Gear shop (suits, tanks, gas mixtures, DPV)
- Gear effects on gameplay (thermal protection, dive time, speed, risk reduction)

### Phase 3: Content and Polish
- Full set of Knowledgeable Items across all categories (species, oceanography, history, human impact)
- Higher-tier gear (rebreather, submarine, bathysphere)
- Cosmetic upgrades
- Glossary with redacted/undiscovered entries

### Phase 4: Balancing and Maintenance
- Tuning level definitions (depth scaling per level, hard depth limits, gear availability)
- Tuning gear/skill base values (movement speed modifiers, air consumption modifiers, thermal resistance, risk thresholds)
- Adding further Knowledgeable Items, gear, and skills
- Playtesting-driven adjustments for difficulty curve (not too easy, not too hard)
- Requires extensive human testing and feedback

> **Note:** Phases 1–3 must be designed with Phase 4 in mind. Both level definitions and gear/skill base values should be data-driven and easy to adjust without architectural changes.

### Ideas / Backlog
<!-- Features you'd like to explore eventually but haven't committed to -->

## Target Platforms

iPhone and iPad. Minimum version: iOS 26.0.

## Architecture Notes

### Data-Driven Design

There are two categories of game parameters:

**Static per level** (defined once, do not change at runtime):
- Hard depth limit
- Available gear for purchase
- Depth scaling (pixels per meter) — this is the key difficulty lever. Higher levels compress more ocean into less screen space, making the world feel larger and navigation harder.

**Dynamic per player** (derived from equipped gear and acquired skills):
- Movement speed (meters per second)
- Air consumption rate
- Thermal resistance
- Risk thresholds (DCS, narcosis)

Note that depth scaling affects *perceived* speed without changing actual speed. A player moving at 1 m/s with a scale of 100 px/m moves 100 px/s on screen. At 10 px/m (a higher level), the same 1 m/s is only 10 px/s on screen — but the player will likely have better gear and skills by then.

All parameters (both static level definitions and base values for gear/skill effects) should be defined as structured constants in code, making them straightforward for a developer to adjust for balancing.

### Item Placement

Knowledgeable Items and trash are placed at fixed, predefined depths. There is no procedural generation or randomized spawning.

### Visual Environment

The ocean is a single continuous environment rendered as a gradient that fades to black at depth. The architecture should allow for introducing distinct visual zones (e.g., coral reef, open water, abyss) in the future without restructuring the rendering pipeline.

### Persistence

Session-scoped state (current dive: air, depth, collected items) lives in memory and is discarded on rescue or quit. Persistent state (inventory, XP, unlocks, glossary) is stored across sessions using SwiftData or similar.

## Code Style

### Access Control

Always use the lowest possible access control level:
- A function used only within its own type is always `private`.
- A property that is read externally but only written internally is always `private(set)`.
- Properties that are never modified after initialization are always `let`, not `var`.

### Type Member Ordering

Members within a type are ordered as follows:

1. **Subtypes and typealiases**
2. **Stored properties** — wrapper properties (`@State`, `@Published`, etc.) are grouped together
3. **Computed properties**
4. **Functions** — initializers always come first
5. **Protocol conformances** — properties and functions belonging to a protocol conformance are grouped at the end of the type, preceded by a `// MARK: - ProtocolName` comment

Within each group, members are ordered by visibility (most visible first). `static` members are considered highest visibility, even if `private`.

**Exceptions:**
- In a SwiftUI `View`, the `body` property takes the position of an initializer: below other properties, but before other functions.
- Members with a strict logical connection may be grouped together regardless of category.

### Example

```swift
struct ExampleView: View {
    // Stored properties (wrappers grouped)
    @State private var isExpanded = false
    @State private var offset: CGFloat = 0

    let title: String
    private let spacing: CGFloat = 8

    // Computed properties
    var subtitle: String { "Details for \(title)" }
    private var isVisible: Bool { offset > 0 }

    // body (takes initializer position in Views)
    var body: some View { ... }

    // Functions
    func reset() { ... }
    private func calculateLayout() { ... }

    // MARK: - Hashable
    func hash(into hasher: inout Hasher) { ... }
}
```

## Dependencies

<!-- External packages (e.g., OpenSeasUI) and why they're used -->
