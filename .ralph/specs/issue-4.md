# Core run loop: RunState + hunts + node-map + resolution

> GitHub issue #4 | Labels: ready-for-agent, P0 | https://github.com/taigamura/infinity-hunter/issues/4

## What to build
`RunState` (`src/systems/`) driving one expedition: start at Lv.1 in a chosen zone with equipped gear; a `NodeMap` of monster choices (level/reward/risk visible) + travel-deeper nodes; choosing a monster resolves a fight (stat-resolve stub is fine here; real combat is #2-dependent slice) -> awards XP via XpCurve -> may level up many times; each fight spends 1 hunt (~10/run, tunable). Run ends on hunt exhaustion (bank), voluntary retreat (bank), or death (**forfeit** unbanked materials + essence; crafted gear stays). Reaching a new zone unlocks it as a future launch option.

## Acceptance criteria
- [ ] Start a run: level=1, hunts=max, chosen zone recorded
- [ ] NodeMap generation yields the expected choice/travel structure with visible level/reward/risk
- [ ] Resolving a fight spends 1 hunt and awards XP (levels rise)
- [ ] Death forfeits unbanked haul; retreat and hunt-exhaustion bank it
- [ ] Reaching a deeper zone marks it unlocked
- [ ] Unit tests: banking on each of death/retreat/completion, hunt decrement, unlock, node-map invariants

## Blocked by
- #2
- #3

## Definition of done
- All acceptance criteria met; `./scripts/test.sh` exits 0 (headless gate green); one commit; revert-and-report if you cannot finish cleanly. Follow `.ralph/AGENT.md` conventions (GDScript, `Big` type, data-driven JSON, single logic test seam).

