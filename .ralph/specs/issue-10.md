# Capture + companion passives

> GitHub issue #10 | Labels: ready-for-agent, P1 | https://github.com/taigamura/infinity-hunter/issues/10

## What to build
`CaptureSystem` (`src/systems/`): below an HP threshold a capture becomes available; it consumes a Trap and, on success, grants a companion + materials (possibly capture-only) but FORFEITS the kill's XP burst. Captured species stored permanently; one companion chosen pre-run grants a passive buff (not a party unit).

## Acceptance criteria
- [ ] Capture only available below the monster's HP threshold
- [ ] Capture consumes a Trap; success grants companion + mats and awards ZERO XP
- [ ] Captured species persist (#5); one companion selectable pre-run applies its passive for the run
- [ ] Unit tests: threshold gating, trap consumption, zero-XP-on-capture, companion passive application

## Blocked by
- #4
- #7

## Definition of done
- All acceptance criteria met; `./scripts/test.sh` exits 0 (headless gate green); one commit; revert-and-report if you cannot finish cleanly. Follow `.ralph/AGENT.md` conventions (GDScript, `Big` type, data-driven JSON, single logic test seam).

