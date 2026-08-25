# Off-path spike sections + apex stat-wall species pool

> GitHub issue #40 | Labels: ready-for-agent, P1 | https://github.com/taigamura/infinity-hunter/issues/40

## Parent

#36 — PRD: Concentric Sections overworld

## What to build

Off-path **spike sections** and the **apex species pool**. During fill (after the path is
carved), a small number of off-path sections (suggest 1-2 per map) roll a recommended level
far above the zone's band and are flagged `is_spike`. A spike section's encounter draws from
a pool of fixed high-level **apex stat-wall monsters** rather than normal zone species; the
existing `voidmaw_devourer` is the reference apex and may be reused as a placeholder, with a
couple more apex species authored under `data/monsters/` as available. Reuse
`EncounterSystem.pick_monster`'s `[level_min, level_max]` window: normal sections gate normal
species; spike sections' window selects the apex pool. No monster-stat scaling is introduced.
Because a run starts at Lv.1, a spike is a near-instant death normally, but a buff/gear win
pays out jackpot XP through the existing gap-scaled XP curve — verify that end-to-end.

## Acceptance criteria

- [ ] A bounded number of off-path sections are flagged as spikes with recommended levels
      well above the zone band.
- [ ] Spike sections select from an apex monster pool via the existing level-window filter;
      normal sections are unaffected.
- [ ] At least the `voidmaw`-style apex is reachable from a spike section (placeholder ok);
      any newly authored apex monsters pass data-load validation.
- [ ] Losing to a spike near-instantly and winning-with-buffs -> huge XP both work through
      the unchanged combat + XP systems (covered by/asserted in tests where feasible).
- [ ] `test_section_layout.gd` / `test_encounter_system.gd` cover spike flagging + apex pick.
- [ ] `./scripts/test.sh` passes.

## Blocked by

- #39

