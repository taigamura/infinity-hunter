# MVP content: zones, monsters, weapons, armor

> GitHub issue #15 | Labels: ready-for-agent, P1 | https://github.com/taigamura/infinity-hunter/issues/15

## What to build
Author the MVP content as JSON per the #2 schemas once systems stabilize: 3 zones (with connectivity + level ranges), 8-12 monsters (levels, elements/weaknesses, drop tables, breakable parts, capture thresholds), 3 weapon classes (Great Sword/Dual Blades/Hammer with recipes), ~15 armor pieces (skills/sets/recipes). Include the aspirational near-spawn Lv.9,999,999,999 marker monster.

## Acceptance criteria
- [ ] 3 zones with connectivity + visible level ranges load and validate
- [ ] 8-12 monsters load, each consumable by combat/drops/capture/bestiary
- [ ] 3 weapons + ~15 armor with recipes load and are craftable
- [ ] All content passes #2 validation; a full run is playable end-to-end on desktop
- [ ] Unit tests: content loads + validates; representative recipe crafts

## Blocked by
- #2
- #7
- #8

## Definition of done
- All acceptance criteria met; `./scripts/test.sh` exits 0 (headless gate green); one commit; revert-and-report if you cannot finish cleanly. Follow `.ralph/AGENT.md` conventions (GDScript, `Big` type, data-driven JSON, single logic test seam).

