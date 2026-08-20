# UI shells over the logic modules

> GitHub issue #13 | Labels: ready-for-agent, P1 | https://github.com/taigamura/infinity-hunter/issues/13

## What to build
Thin Godot scenes (portrait) over the logic systems: zone/launch screen, node-map, combat screen (renders CombatResolver + touch dodge/attack), inventory/crafting, bestiary, meta-upgrade. Scenes are shells calling into the tested logic; no game rules in UI. Manual-verify (outside the headless test seam) but must load without SCRIPT ERROR.

## Acceptance criteria
- [ ] Each screen loads and drives its underlying system via public methods
- [ ] Launch -> node-map -> combat -> bank/upgrade -> relaunch flow is playable on desktop
- [ ] Touch controls (tap/hold/swipe) wired with mouse/keyboard equivalents on desktop
- [ ] Large readable numbers; no rules logic duplicated in UI
- [ ] `godot --headless --import` reports no SCRIPT ERROR

## Blocked by
- #4
- #6
- #8

## Definition of done
- All acceptance criteria met; `./scripts/test.sh` exits 0 (headless gate green); one commit; revert-and-report if you cannot finish cleanly. Follow `.ralph/AGENT.md` conventions (GDScript, `Big` type, data-driven JSON, single logic test seam).

