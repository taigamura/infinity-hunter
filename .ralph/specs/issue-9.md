# Armor skills + set bonuses to build stats

> GitHub issue #9 | Labels: ready-for-agent, P1 | https://github.com/taigamura/infinity-hunter/issues/9

## What to build
Armor pieces grant skill points; set bonuses activate at thresholds; aggregate equipped skills into a computed player stat/skill profile that feeds CombatResolver and other systems (Crit, Attack Boost, resistances, XP Boost, Partbreaker, Capture Master, etc.).

## Acceptance criteria
- [ ] Equipping armor contributes skill points; set bonus activates at its piece-count threshold
- [ ] Aggregated skill profile is consumed by combat/XP/drop/capture where relevant
- [ ] Meaningful tradeoffs expressible (power vs survivability vs farming vs capture)
- [ ] Unit tests: skill aggregation, set-bonus activation threshold, effect application in combat

## Blocked by
- #6
- #8

## Definition of done
- All acceptance criteria met; `./scripts/test.sh` exits 0 (headless gate green); one commit; revert-and-report if you cannot finish cleanly. Follow `.ralph/AGENT.md` conventions (GDScript, `Big` type, data-driven JSON, single logic test seam).

