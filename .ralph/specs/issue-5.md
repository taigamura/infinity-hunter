# Save system: atomic, versioned, migratable

> GitHub issue #5 | Labels: ready-for-agent, P0 | https://github.com/taigamura/infinity-hunter/issues/5

## What to build
`SaveManager` (`src/systems/`): JSON to `user://` with atomic write (temp -> fsync -> rename), previous save kept as `.bak` rollback, a `version` integer + migration path, debounced autosave. Serializes persistent state (gear instances with rolled stats, material/consumable counts, captures, bestiary, unlocks, essence, upgrades). Blob shaped for optional future iCloud (never required).

## Acceptance criteria
- [ ] Save then load round-trips all persistent state exactly
- [ ] Write is atomic (interrupting mid-write cannot corrupt the live file; .bak retained)
- [ ] A v(n-1) blob migrates cleanly to v(n)
- [ ] Debounced autosave coalesces rapid changes
- [ ] Unit tests: round-trip, migration, corruption/rollback via .bak

## Blocked by
- #4

## Definition of done
- All acceptance criteria met; `./scripts/test.sh` exits 0 (headless gate green); one commit; revert-and-report if you cannot finish cleanly. Follow `.ralph/AGENT.md` conventions (GDScript, `Big` type, data-driven JSON, single logic test seam).

