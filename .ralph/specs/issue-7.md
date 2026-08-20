# Drops, materials, and part-breaking

> GitHub issue #7 | Labels: ready-for-agent, P1 | https://github.com/taigamura/infinity-hunter/issues/7

## What to build
`DropSystem` (`src/systems/`): weighted drop tables per monster; breaking a specific part sharply boosts (or guarantees) that part's material. Wire material yields into RunState's unbanked haul; record discovery for the bestiary.

## Acceptance criteria
- [ ] Weighted table yields materials at configured probabilities (statistically verified over N rolls)
- [ ] Breaking a part boosts/guarantees that part's specific material
- [ ] Yielded materials enter the run haul (and are forfeited on death per #4)
- [ ] Unit tests: weighting distribution within tolerance, part-break drop boost, haul integration

## Blocked by
- #2
- #4

## Definition of done
- All acceptance criteria met; `./scripts/test.sh` exits 0 (headless gate green); one commit; revert-and-report if you cannot finish cleanly. Follow `.ralph/AGENT.md` conventions (GDScript, `Big` type, data-driven JSON, single logic test seam).

