# Overworld: Deepening Trail foundation — depth-banded danger, near-edge camp spawn, on-trail portal exit

> Staged (GitHub unreachable at authoring time). Labels: ready-for-agent, P0 | Implements ADR-0001

## Parent / decision

ADR-0001 — Overworld map: the Deepening Trail (`docs/adr/0001-overworld-deepening-trail.md`)

## What to build

Replace the radial danger heatmap with a **depth-banded** field so the overworld reads as a
journey inward. Danger rises with *depth along the travel axis* (near edge = safe, far edge =
hot) instead of distance from center. This is the foundation slice; the POI overlay (#B) and
per-zone tier tables (#C) build on it.

**Danger by depth (the core change).** In `OverworldTierLayout`, replace `distance_ratio`
(radial, distance from center) with a **depth ratio** along the travel axis: the near edge
(where the player spawns) is 0.0, the far edge (portal) is 1.0. Feed it into the existing
tier-bucketing so `EncounterSystem`, the gauge math, and the tier-param lookup are untouched —
only the mapping from cell → tier changes. Travel axis is the vertical map axis (near edge =
bottom row `y = MAP_ROWS-1`, deep edge = top row `y = 0`), matching the portrait field.

**Camp spawn at the near edge.** The player spawns at a **camp** tile centered on the near
(safe) edge rather than the map center. Update `overworld_screen.gd` spawn placement and the
camera reset so a single-frame render shows the camp at/near the bottom with safe green around it.

**Portal exit in the deepest band, on the trail.** `exit_cell` returns a tile inside the
deepest band on the trail line (top-edge, at the trail's x for `y = 0`) instead of the
top-right corner. The existing pulsing exit marker already tracks whatever `exit_cell` returns —
verify it points up-field toward the portal and lands on the portal tile when it scrolls in.

**Winding trail spine (cosmetic).** Carve a winding safe-ish **trail** corridor from the camp
up to the portal (a dirt-tinted tile blend over the banded gradient), so the depth read has a
visible spine. The trail x for a given row can be a smooth function (e.g. a bounded sine of the
row). Trail tiles are visual only — they do not change the tier under them. Keep the existing
per-tile shade jitter + inset border.

## Acceptance criteria

- [ ] `OverworldTierLayout` buckets tiles by **depth along the travel axis** (near edge safe,
      far edge hot), not radial distance; `EncounterSystem`/gauge math unchanged
- [ ] The player spawns at a **camp** on the near (safe) edge; camera framing shows it correctly
- [ ] `exit_cell` returns an on-trail tile in the deepest band; the exit marker points to it and
      lands on it in view; exit-cell travel still unlocks + reloads the connected zone
- [ ] A winding **trail** corridor is visible from camp to portal (cosmetic tint; tier unchanged)
- [ ] `scripts/verify_visual.sh` overworld invariant updated: rendered frame has red-family
      (hot) pixels toward the **deep/far edge** (top), safe green toward the near edge (bottom);
      SKIP if unrenderable, FAIL only on a rendered violation
- [ ] No change to `src/systems/` *rules* beyond the layout mapping; combat/encounter behaviour
      unchanged
- [ ] `OverworldTierLayout` tests updated for depth bucketing + new `exit_cell`; `./scripts/test.sh`
      exits 0

## Notes

- Keep the `distance_ratio`/`shade_index_for_distance` seam if convenient — the tileset can still
  read a 0..1 ratio; it's the *meaning* (depth, not radius) that changes.
- Final tile art (grass, trail texture) is a later sprite pass; this slice is layout + palette.
