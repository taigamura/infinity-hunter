# XP curve + level-to-power scaling

> GitHub issue #3 | Labels: ready-for-agent, P0 | https://github.com/taigamura/infinity-hunter/issues/3

## What to build
`XpCurve` (`src/systems/`): exponential level thresholds; converts an XP award into a (levels_gained, xp_carry) result that may cross MANY thresholds at once. Provide level->power scaling (damage/HP) usable by combat. All quantities via `Big`.

## Acceptance criteria
- [ ] `threshold(level)` grows exponentially (tunable base constant)
- [ ] Awarding a large XP lump crosses multiple levels in one call, returning levels gained + leftover carry
- [ ] level->power scaling function is monotonic and documented
- [ ] Unit tests: single-level gain, multi-level lump (e.g. +thousands), carry correctness, power scaling

## Blocked by
- None - can start immediately

## Definition of done
- All acceptance criteria met; `./scripts/test.sh` exits 0 (headless gate green); one commit; revert-and-report if you cannot finish cleanly. Follow `.ralph/AGENT.md` conventions (GDScript, `Big` type, data-driven JSON, single logic test seam).

