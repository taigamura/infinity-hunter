# Bestiary tracking and entries

> GitHub issue #12 | Labels: P2, ready-for-agent | https://github.com/taigamura/infinity-hunter/issues/12

## What to build
`Bestiary` (`src/systems/`): per-monster seen/kill/capture counts, discovered drops, broken parts, element/weakness. Updated by combat/drops/capture; persisted.

## Acceptance criteria
- [ ] Encounters/kills/captures increment the right counters
- [ ] Discovered drops and broken parts recorded as they occur
- [ ] Bestiary persists via #5
- [ ] Unit tests: counter increments, drop/part discovery recording, persistence

## Blocked by
- #7
- #10

## Definition of done
- All acceptance criteria met; `./scripts/test.sh` exits 0 (headless gate green); one commit; revert-and-report if you cannot finish cleanly. Follow `.ralph/AGENT.md` conventions (GDScript, `Big` type, data-driven JSON, single logic test seam).

