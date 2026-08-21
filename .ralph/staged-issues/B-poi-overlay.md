# Overworld: points-of-interest overlay — dens, forage, cache, camp, landmark

> Staged (GitHub unreachable at authoring time). Labels: ready-for-agent, P1 | Implements ADR-0001

## Parent / decision

ADR-0001 — Overworld map: the Deepening Trail. **Blocked by #A** (depth-banded foundation).

## What to build

Give the ground meaning with a thin, **data-driven** points-of-interest layer rendered above
the tilemap. POIs are placed relative to the bands/trail from #A so they sit sensibly (dens in
hot bands, forage/cache along the trail, camp at the near edge, one landmark mid-field).

**POI model + placement (pure/testable).** A small system (mirror the `EncounterSystem` /
`OverworldTierLayout` precedent: static methods, no Node dependency) that, given map size +
tier layout + a seeded rng, returns a list of `{cell, type}` POIs. Types: `camp` (near-edge
spawn, exactly one), `portal` (deepest band, exactly one — may reuse `exit_cell`), `den`
(1–3, biased to mid/hot bands), `forage` (1–3, safe/mid bands near trail), `cache` (0–2,
mid/hot bands, off the trail so it's a detour), `landmark` (0–1, mid-field). Deterministic for
a given seed so it's headless-testable.

**Den → spawn bias.** When the player is on (or adjacent to) a `den` tile, the encounter gauge
fills faster and/or the band's spawn skews to the hotter end of its level range. Implement as a
multiplier applied to the existing tier params at tick time (do not fork `EncounterSystem.tick`;
pass boosted params in). Keep it modest — dens are a "hunt here for denser fights" hint, not a
trap.

**Rendering.** Draw POI markers above the tilemap in `overworld_screen.gd` (Sprite2D/Node2D
markers built in code, same "assemble in code" pattern as the tileset/player sprite — no new
art assets required for this slice; simple shaped/tinted markers are fine as placeholders).
Forage/cache are flavor + hooks for a future gathering pass — no gather interaction required
here beyond the visual + the den bias.

## Acceptance criteria

- [ ] A pure POI-placement system returns a deterministic `{cell, type}` list for a given seed;
      unit-tested (exactly one camp + one portal; dens biased hotter; nothing off-map)
- [ ] POIs render above the tilemap at their cells; camp sits at the spawn, portal at `exit_cell`
- [ ] Standing on/next to a `den` measurably boosts encounter density (via boosted tier params
      passed into the unchanged `EncounterSystem.tick`)
- [ ] `scripts/verify_visual.sh` still passes; add a smoke check that POI markers exist in-tree
      on the overworld (structural, like `test_scenes_smoke.gd`); SKIP if unrenderable
- [ ] No regression to exit-cell travel or combat; `./scripts/test.sh` exits 0

## Notes

- Placeholder markers only; bespoke POI sprites are a later art pass.
- Forage/cache gathering interaction is intentionally out of scope — this slice establishes the
  layer + den bias.
