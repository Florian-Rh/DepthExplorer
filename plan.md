# Phase 3: Visual Depth Zones — Implementation Plan

## Overview

Replace the single-gradient `Rectangle` in `OceanView` with a `VStack` of distinct zone views, each representing a real oceanic pelagic zone with its own gradient, ambient elements (corals, kelp, rocks), and particle effects (bubbles, plankton, marine snow). Transitions between zones are soft (gradient blending). Only zones near the viewport are rendered (lazy rendering for ambient elements and particles).

New `KnowledgeableItem` entries will be added for each zone.

## Depth Zones

Based on real oceanic pelagic zones, with a compressed darkness curve (reaching black at ~5000m instead of the real ~1000m):

| Zone | Real Depth | Game Depth | Visual Character |
|------|-----------|------------|-----------------|
| **Sunlight (Epipelagic)** | 0–200m | 0–200m | Bright turquoise/cyan, coral reefs, kelp forests, bubbles, light rays |
| **Twilight (Mesopelagic)** | 200–1000m | 200–1000m | Deep blue fading to indigo, sparse ambient life, dimming light, plankton particles |
| **Midnight (Bathypelagic)** | 1000–4000m | 1000–4000m | Dark indigo to near-black, bioluminescent specks (tiny glowing particles), no ambient structures |
| **Abyssal (Abyssopelagic)** | 4000–6000m | 4000–6000m | Near-black, extremely sparse faint particles, occasional hydrothermal vent glow |
| **Hadal (Hadalpelagic)** | 6000–11000m | 6000–11000m | Pure black, marine snow (very sparse white particles drifting down), trench rock silhouettes |

## Architecture

### New Files

1. **`DepthExplorer/Level/Ocean/DepthZone.swift`** — Data model defining each zone (depth range, colors, particle config, ambient element descriptors)
2. **`DepthExplorer/Level/Ocean/DepthZoneView.swift`** — SwiftUI view rendering a single zone (gradient background + ambient overlay + particle overlay)
3. **`DepthExplorer/Level/Ocean/AmbientElements.swift`** — Canvas-drawn ambient elements: coral formations, kelp strands, rock formations, hydrothermal vents. Drawn with `Canvas` for performance. Each zone type has its own drawing function.
4. **`DepthExplorer/Level/Ocean/OceanParticleView.swift`** — Particle system for per-zone effects (bubbles, plankton, marine snow, bioluminescent specks). Uses `TimelineView` + `Canvas` for performance, not individual SwiftUI views per particle.

### Modified Files

5. **`OceanView.swift`** — Replace the single gradient `Rectangle` with a `VStack` of `DepthZoneView`s. Keep the wave surface as-is. Pass `contentOffset` and `screenHeight` so zones can determine visibility.
6. **`LevelView.swift`** — Pass `contentOffset` to `OceanView` (it doesn't currently receive it) so zone views can do viewport culling.
7. **`KnowledgeableItem.swift`** — Add 5 new items, one per zone.
8. **`GameConfig.swift`** — Add zone-related constants (zone boundary depths, particle densities).

## Step-by-Step Implementation

### Step 1: Define the DepthZone data model

Create `DepthZone.swift`:
- `DepthZone` struct with: `name`, `depthRange` (ClosedRange<Double>), `gradientColors` ([Color]), `particleConfig` (type, density, color, speed), `ambientElementType` (enum: coral, kelp, rocks, vents, none)
- Static `allZones: [DepthZone]` array defining all 5 zones
- Zone height computed as `(range.upperBound - range.lowerBound) * scalingFactor`
- Helper: `zone(at depth: Double) -> DepthZone?`

Gradient colors per zone (soft transitions — each zone's last color matches the next zone's first color):
- Sunlight: `.oceanBlue` → bright cyan → `.deepSeaBlue`
- Twilight: `.deepSeaBlue` → indigo → `.abyssBlue`
- Midnight: `.abyssBlue` → dark navy → near-black
- Abyssal: near-black → black
- Hadal: black → black

### Step 2: Build the ambient element renderer

Create `AmbientElements.swift`:
- A SwiftUI `Canvas` view that draws static decorative elements based on zone type
- Elements are positioned deterministically using a seeded RNG (so they don't change between frames)
- **Sunlight zone**: Coral formations (colorful branching shapes), kelp strands (tall wavy green lines), sea fans
- **Twilight zone**: Sparse rocky outcrops, occasional lone kelp, dimmer colors
- **Midnight zone**: Bare rock formations, very sparse
- **Abyssal zone**: Hydrothermal vent silhouettes (rare), flat rocky floor
- **Hadal zone**: Trench wall silhouettes (angular rock shapes on sides)
- Lazy rendering: only draw elements within a vertical window around the viewport. Accept `visibleRange: Range<CGFloat>` and skip elements outside it.

### Step 3: Build the particle system

Create `OceanParticleView.swift`:
- Uses `TimelineView(.animation)` + `Canvas` for efficient rendering (no per-particle SwiftUI views)
- Particle types:
  - **Bubbles** (sunlight zone): white/translucent circles drifting upward
  - **Plankton** (twilight zone): tiny warm-tinted dots drifting slowly
  - **Bioluminescent specks** (midnight zone): tiny blue/green dots that pulse in opacity
  - **Marine snow** (abyssal/hadal): white specks drifting slowly downward
- Each particle type has: color, size range, speed, direction, opacity behavior, density
- Viewport-aware: only simulate/render particles in a window around the visible area. Particles are spawned relative to the viewport, not absolute positions.

### Step 4: Build DepthZoneView

Create `DepthZoneView.swift`:
- Takes a `DepthZone`, `scalingFactor`, `contentOffset`, `screenHeight`
- Computes its own height from the zone depth range × scaling factor
- Layers:
  1. `Rectangle` with zone-specific `LinearGradient`
  2. `AmbientElements` overlay (lazy, only if zone is near viewport)
  3. `OceanParticleView` overlay (lazy, only if zone is near viewport)
- Visibility check: compute whether any part of this zone's pixel range overlaps with `contentOffset ± screenHeight`. If not visible, render only the gradient (skip ambient + particles).

### Step 5: Integrate into OceanView

Modify `OceanView.swift`:
- Add `contentOffset: CGFloat` parameter
- Replace the single gradient `Rectangle` with a `VStack(spacing: 0)` of `DepthZoneView` instances
- Keep the `WaveView` / sky section unchanged
- Remove the old `adjustedMidnightAbyssGradient` static property

### Step 6: Update LevelView

Modify `LevelView.swift`:
- Pass `viewModel.contentOffset` to `OceanView`

### Step 7: Add zone KnowledgeableItems

Add 5 entries to `KnowledgeableItem.allItems`:
- **Sunlight Zone (Epipelagic)** at 5m — "The sunlight zone extends from the surface to 200m. It receives enough light for photosynthesis and contains over 90% of all marine life."
- **Twilight Zone (Mesopelagic)** at 200m — "The twilight zone receives only faint traces of sunlight. Many creatures here have bioluminescent abilities and migrate vertically each day."
- **Midnight Zone (Bathypelagic)** at 1000m — "No sunlight reaches the midnight zone. Life here relies on marine snow — organic debris falling from above — or chemosynthesis near hydrothermal vents."
- **Abyssal Zone (Abyssopelagic)** at 4000m — "The abyssal zone covers over 80% of the ocean floor. Water temperature hovers just above freezing at 1–4°C."
- **Hadal Zone (Hadalpelagic)** at 6000m — "The hadal zone exists only in ocean trenches. The Mariana Trench's Challenger Deep, at nearly 11,000m, is the deepest point on Earth."

### Step 8: Clean up GameConfig / TASKS

- Add zone boundary constants to `GameConfig.swift` if needed (or keep them in `DepthZone`)
- Remove the outdated scaling factor mechanic from TASKS.md as requested

## Performance Strategy

- **Gradient rectangles**: Always rendered (cheap, just fills)
- **Ambient elements (Canvas)**: Only rendered when zone overlaps viewport ± 1 screen height buffer. Static drawing, no animation cost.
- **Particles (TimelineView + Canvas)**: Only rendered when zone overlaps viewport ± 0.5 screen height buffer. Particle simulation only runs for visible particles. Particle count is capped per zone.
- The `VStack` itself contains only 5 children — no performance concern from the container.

## What This Plan Does NOT Include

- Fish or animated creatures (to be added later per your instruction)
- Changes to the scaling factor mechanic beyond removing it from TASKS.md
- Sound effects or haptics
- HUD zone indicator (could be added later — show current zone name on the HUD)
