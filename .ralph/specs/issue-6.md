# Combat resolver: dodge/HP-race, weapon classes, elements

> GitHub issue #6 | Labels: ready-for-agent, P0 | https://github.com/taigamura/infinity-hunter/issues/6

## What to build
`CombatResolver` + `Elements` (`src/systems/`) as pure logic: real-time dodge/attack HP-race. Monster attacks back; player HP drains. Dodging avoids most damage but an unavoidable chip floor = f(monster power) always lands, so a vastly stronger monster wins regardless of skill. Weapon-class modifiers (Great Sword charge burst, Dual Blades rapid+demon meter, Hammer slow+stun bar). Elemental multiplier: Fire/Water/Earth/Thunder/Ice ring (weak x1.5, resist x0.66), Neutral x1.0, rare Dragon strong-vs-all. Outcomes deterministic given inputs+timings so unit-testable independent of rendering.

## Acceptance criteria
- [ ] HP-race resolves win/loss from stats + input timings deterministically
- [ ] Chip floor scales with monster power; a monster ~3x player power is unwinnable even with perfect dodging
- [ ] Each weapon class applies its distinct damage/speed/meter behavior
- [ ] Elemental ring + Neutral + Dragon multipliers correct
- [ ] Unit tests: chip lethality vs power gap, dodge reduction, each weapon modifier, every element matchup

## Blocked by
- #2
- #4

## Definition of done
- All acceptance criteria met; `./scripts/test.sh` exits 0 (headless gate green); one commit; revert-and-report if you cannot finish cleanly. Follow `.ralph/AGENT.md` conventions (GDScript, `Big` type, data-driven JSON, single logic test seam).

