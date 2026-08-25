# SectionLayout foundation: center spawn + section-driven encounters end-to-end

> GitHub issue #37 | Labels: ready-for-agent, P0 | https://github.com/taigamura/infinity-hunter/issues/37

## Parent

#36 — PRD: Concentric Sections overworld

## What to build

The foundational tracer bullet: a new pure `SectionLayout` module and the overworld
switching to spawn at map center and drive encounters from a **section map** instead of
depth-banded tiers. For this first slice `SectionLayout` may generate the simplest valid
form — concentric rings by distance from center, each ring one section with a recommended
level that rises outward, a portal cell on the outer ring, and a cell->section lookup.
The overworld screen spawns the hunter at the center camp, each physics frame resolves the
section under the hunter, and feeds that section's params (same dict shape tiers used:
`gauge_rate`, `jitter`, `level_min`, `level_max`) into the unchanged `EncounterSystem.tick`.
Reaching the outer-ring portal still travels to the connected zone via the existing path.
The whole test gate stays green (including `verify_visual.sh` and the scene smoke test),
which means updating the overworld visual invariant from "red top / green bottom" to the
concentric model (mildest at center, hotter outward).

## Acceptance criteria

- [ ] `SectionLayout` is a pure `class_name` RefCounted with static methods and a
      caller-supplied `RandomNumberGenerator`, mirroring `OverworldTierLayout`/`PoiLayout`.
- [ ] It exposes generation returning sections (each with recommended level + encounter
      params), a center camp cell, an outer-ring portal cell, and a cell->section lookup.
- [ ] For a fixed seed the layout is deterministic; every cell resolves to exactly one section.
- [ ] The overworld spawns the hunter at map center and ticks encounters from the section
      under the hunter; encounters still fire and open combat as before.
- [ ] Reaching the portal cell travels to and unlocks the connected zone (unchanged flow).
- [ ] `tests/unit/test_section_layout.gd` covers the above (follows the `test_big.gd` pattern).
- [ ] `./scripts/test.sh` passes, including an updated overworld visual invariant.

## Blocked by

- None — can start immediately

