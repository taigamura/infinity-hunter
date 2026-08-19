# Gauge wiring: tier-under-character drives EncounterSystem tick + gauge HUD

> GitHub issue #20 | Labels: ready-for-agent, P0 | https://github.com/taigamura/infinity-hunter/issues/20

## Parent

#16

## What to build

Wire the encounter gauge into the overworld. Each frame of movement, the scene reads the tier id of the terrain under the character (from the tilemap's tier data), looks up its tier_params, calls `EncounterSystem.tick`, and updates a gauge HUD element. The gauge visibly fills faster in higher-tier (hotter) terrain. When `tick` reports `fired`, the scene calls `EncounterSystem.pick_monster` to select the monster (band-filtered from the zone roster) and surfaces it (for this slice, a stub hand-off is acceptable — e.g. log/show the picked monster and reset the gauge); actual combat lands in the next slice.

## Acceptance criteria

- [ ] Gauge HUD fills as the character walks
- [ ] Walking through a higher-tier region fills the gauge faster than a low-tier region
- [ ] On fire, a monster is picked via `EncounterSystem.pick_monster` and the gauge resets
- [ ] Picked monster respects the tier's level band
- [ ] `./scripts/test.sh` exits 0

## Blocked by

- #17
- #18
- #19

