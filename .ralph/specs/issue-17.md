# EncounterSystem: pure gauge fill + band-filtered monster pick

> GitHub issue #17 | Labels: ready-for-agent, P0 | https://github.com/taigamura/infinity-hunter/issues/17

## Parent

#16

## What to build

The pure encounter logic that drives the overworld, as a testable `RefCounted` in `src/systems` following the `NodeMap`/`DropSystem` precedent (static methods, no scene, no side effects). Two functions:

- `tick(tier_params, gauge, rng) -> {"gauge", "fired"}` — advances the encounter gauge by the tier's fill rate plus a small bounded jitter; when it crosses the threshold, reports `fired == true` and resets the gauge.
- `pick_monster(zone, tier_params, monster_defs, rng) -> monster_id` — returns a monster id chosen weighted-random from `zone.monster_ids` filtered to the tier's `[level_min, level_max]` band. Falls back gracefully (e.g. nearest-level monster) when the band matches nothing, mirroring how `NodeMap.generate` skips missing ids rather than failing.

`rng` is caller-supplied for deterministic tests, matching `RunState.resolve_fight`.

## Acceptance criteria

- [ ] Gauge accumulates by the tier's fill rate and does not fire below threshold
- [ ] A higher-rate tier fires in fewer ticks than a lower-rate tier
- [ ] Firing resets the gauge
- [ ] Jitter stays within its declared bound across seeds (fire step varies within a window)
- [ ] `pick_monster` only returns ids whose `MonsterDef.level` is inside the tier band; respects weights across many seeded rolls; graceful fallback when the band is empty
- [ ] `test_encounter_system.gd` extends `res://tests/test_case.gd` by path; `./scripts/test.sh` exits 0

## Blocked by

None - can start immediately

