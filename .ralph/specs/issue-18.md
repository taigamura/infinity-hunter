# Region/tier data model: danger tiers for Verdant Fields, loader + validation

> GitHub issue #18 | Labels: ready-for-agent, P0 | https://github.com/taigamura/infinity-hunter/issues/18

## Parent

#16

## What to build

The data-driven danger-tier model. Terrain paints a tier id (int) per tile; a tier table in data maps each tier id to `{level_min, level_max, gauge_rate, weight}` for a zone (Verdant Fields for the slice). Loaded and validated through the existing `DataLoader.validate(data, SCHEMA, path)` pattern used by every `*Def`, failing loudly on bad data. A reserved loot-boost field may exist in the schema but nothing reads it yet.

Whether the table is a new `*Def` file or an addition to `ZoneDef` is the implementer's call, but it MUST be JSON, validated at load time, and produce the `tier_params` dict shape that `EncounterSystem` consumes.

## Acceptance criteria

- [ ] A well-formed Verdant Fields tier table loads and exposes tier_params by tier id
- [ ] Tier params carry level_min, level_max, gauge_rate, weight
- [ ] A malformed tier table fails loudly at load (validation error), matching the `*Def` pattern
- [ ] Loaded tier_params are shape-compatible with `EncounterSystem.tick`/`pick_monster`
- [ ] Validation test extends `res://tests/test_case.gd` by path; `./scripts/test.sh` exits 0

## Blocked by

None - can start immediately

