# ADR-0002 — Overworld map: Concentric Sections

- **Status:** Accepted (2026-08-21)
- **Supersedes:** ADR-0001 (Deepening Trail)
- **Area:** Overworld (`src/systems/section_layout.gd`, `src/systems/poi_layout.gd`,
  `src/ui/overworld/`, `data/zones/`)

## Context

ADR-0001 replaced the original radial danger heatmap with the Deepening Trail: danger
banded by depth along a single travel axis, camp on the near edge, portal on the far
edge, a winding trail spine threading between them. It shipped (foundation + POI +
per-zone band identity) and worked, but PRD issue #36 revisited the overworld shape
again and chose a different geometry: **Concentric Sections**, distinct named regions
arranged radially around a center camp rather than bands along a line.

Problems the Deepening Trail still had:

- A single travel axis makes the map feel like a corridor with width, not a place with
  regions to explore off the critical path.
- Depth-banding ties danger strictly to one coordinate (row), so every tile in a row is
  interchangeable; there is no way for a map to have an unexpectedly dangerous pocket
  near the safe end or a calmer pocket near the hot end.
- No natural seam for "explore off the beaten path and find something worth the risk" —
  the trail already tells you where to go.

## Decision

Adopt **Concentric Sections** (PRD #36), built across issues #37 (tracer bullet),
#39 (full path-first generator), #40 (spike sections + apex species), #41 (POI
carryover + generated section names):

- The hunter spawns at a **center camp**; a **portal** sits at an rng-angled point on
  the outer ring. `SectionLayout` carves a straight, always-connected camp→portal
  **path** (Bresenham) first, banding it into 3-4 concentric **ring sections** with a
  gently-rising recommended level (guaranteed monotonic outward by construction) —
  this is "the path," the visibly-safe route, rendered as a distinct tile blend.
- The rest of the map is scattered with ~5-10 more variable-size **fill sections**
  (rng seed cells resolved by nearest-neighbor Voronoi), each rolling a
  **recommended level** loosely correlated with how far out its seed sits, not a hard
  band — so a fill section can occasionally read hotter or calmer than its ring
  suggests. 8-14 sections total per map.
- Each section derives its own `gauge_rate` from its own recommended level (deadlier
  sections swarm harder); the overworld no longer reads danger off the zone's
  `TierTableDef`/`data/tiers/*.json` for its own geometry.
- **Apex/spike sections** (#40): 1-2 off-path fill sections per map roll a recommended
  level far above the zone's normal band and are flagged `is_spike`, which — via
  `EncounterSystem.pick_monster`'s unmodified level-window filter — surfaces
  apex/stat-wall species (e.g. `voidmaw_devourer`, `cinder_wyrm_matriarch`) instead of
  normal zone monsters. This gives the map an intentional "here be dragons" pocket
  without any special-casing in combat or encounter code.
- Each section carries a generated **evocative name** (zone band-name + rotating
  geographic suffix, e.g. "Bramble Hollow") surfaced by an on-enter banner and a
  persistent recommended-level badge, so sections read as distinct places rather than
  numbered tiers.
- `PoiLayout` re-homed onto `SectionLayout`: dens/forage/cache/landmark placement now
  derives from radial distance and path proximity, and camp/portal markers are sourced
  directly from `SectionLayout` so they always match where the hunter spawns/travels.

`OverworldTierLayout` (the Deepening Trail's depth-banding) is retired from the
overworld screen's own geometry and encounter feed. `data/tiers/*.json` and
`GameState.tier_tables` still load and validate but are otherwise unread.

## Consequences

- `SectionLayout` is the new single source of truth for overworld danger, spawn,
  portal, and gauge-rate geometry; `OverworldTierLayout` is unused outside its own
  loader/unit tests.
- Visual invariant: `scripts/verify_visual.sh`'s overworld check is radial (green
  near center, red toward edges/corners), not top/bottom banded.
- Retired vocabulary: "tier" (as a depth band), "trail" (as the sole safe route),
  "camp/near edge" and "portal/far edge" phrased as a linear axis. Replacement terms:
  **section**, **recommended level**, **apex / spike section**, **the path** — see
  `CONTEXT.md` glossary.
- `PoiLayout`'s core placement algorithm (banding by distance + trail/path proximity)
  survives, re-pointed at `SectionLayout`'s radial distance instead of
  `OverworldTierLayout`'s depth ratio.
- ADR-0001 is superseded by this ADR; its content is kept for history, not as current
  design.

## Work

Sliced into four issues: **#37** tracer bullet (radial ring bucketing), **#39** full
path-first generator (rings + fill sections), **#40** spike sections + apex species
pool, **#41** POI re-homing + generated section names. This ADR (**#42**) is the
documentation/decision-record cleanup closing out the pivot.
