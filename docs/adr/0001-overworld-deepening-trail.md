# ADR-0001 — Overworld map: the Deepening Trail

- **Status:** Superseded by ADR-0002 (Concentric Sections, 2026-08-21)
- **Area:** Overworld (`src/systems/overworld_tier_layout.gd`, `src/ui/overworld/`, `data/tiers/`, `data/zones/`)

## Context

The overworld field was a **radial danger heatmap**: `OverworldTierLayout.tier_for_cell`
buckets a tile by distance from map center, so danger rises in a ring from a safe center
to hot edges, with the `exit_cell` pinned to the top-right corner. It renders as flat
color squares (green → olive → red) with per-tile shade jitter and no other features.

Problems this creates:

- The map is a gradient, not a **place** — no landmarks, water, dens, camp, or paths.
- Danger is radial, but the game's core tension ("push deeper vs cash out") is a
  **journey**: it should read as *depth you travel*, not a ring you stand in the middle of.
- Routing is trivial (safe center → hot corner, straight line); the geography poses no
  risk/reward choice.
- Zero place identity: Verdant Fields, Cinder Dunes and Frostpeak all render as the same
  squares, differing only in hue.

Three concepts were mocked up (see the design pitch artifact linked from CONTEXT.md):
**01 The Deepening Trail** (depth-banded, near-edge camp → far-edge portal), **02 Forked
Valley** (river + safe long road vs deadly ridge shortcut), **03 Frontier Basin** (keep
radial, add a camp + rim gate + landmarks).

## Decision

Adopt **Concept 01 — The Deepening Trail**.

- **Danger is banded by depth along the travel axis**, not radial. The player spawns at a
  **camp** on the near edge (tier 0 / safest) and travels toward a **portal** in the
  deepest band (hottest) at the far edge. Every step toward the portal is a step deeper.
- **Bands are named terrain** per zone (e.g. Verdant Fields: Meadow → Thicket → Bramble →
  Thornwall), giving each zone its own identity through band names + palette.
- A **winding trail** threads through the bands as the safe spine; the portal sits on it.
- A thin **points-of-interest layer** (dens, forage nodes, cache, camp, landmark) gives the
  ground meaning. Dens bias their band's spawn hotter; forage/cache are flavor + hooks for
  future gathering.

Chosen over 02 (most layout-authoring cost, deferred as a possible later zone-shape variant)
and 03 (least code change, but keeps the ring-shaped tension we're trying to leave behind).

## Consequences

- `OverworldTierLayout`: `distance_ratio` (radial) is replaced by a **depth ratio** along
  the travel axis; the tier-bucketing call it feeds is unchanged, so `EncounterSystem` and
  the gauge math are untouched. `exit_cell` returns an on-trail tile in the deepest band
  instead of the corner. The exit-marker pointer already tracks whatever `exit_cell` returns.
- Spawn moves from map center to the near-edge camp tile.
- New **POI overlay** (data-driven) rendered above the tilemap in `overworld_screen.gd`.
- `data/tiers/`: author `cinder_dunes.json` and `frostpeak_ridge.json` (only
  `verdant_fields.json` exists today), plus per-zone band labels + palette.
- Visual invariant flips: the hot band is now the **far/deep edge**, not the top-right
  corner — `scripts/verify_visual.sh` overworld assertion updates accordingly.
- These mockups are diagrammatic; final tile art (grass tufts, trail texture, cliffs, water)
  is a later sprite pass, not part of the layout change.

## Work

Sliced into three issues (staged in `.ralph/specs/` when filed): **A** danger→depth + portal
+ camp + trail spine (foundation), **B** POI overlay, **C** per-zone tier tables + band
identity. B and C depend on A.
