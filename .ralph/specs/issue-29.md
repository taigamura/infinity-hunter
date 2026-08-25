# Launch screen restructure: cards, essence pill, anchored START, 3-up nav

> GitHub issue #29 | Labels: ready-for-agent, P1 | https://github.com/taigamura/infinity-hunter/issues/29

## Parent

#27

## What to build

Restructure the launch screen from its current plain `VBoxContainer` into the visual-target composition, under the project theme from #28. Header row: pixel title with a gold text-shadow plus a styled essence pill showing the current essence (`Big.fmt`). A zone card (selectable) showing the zone's colour swatch, name, level band, and a "starting zone" tag, with an unlock-progression subline (Verdant Fields to Cinder Dunes to Frostpeak Ridge). A weapon card showing the equipped weapon with its icon, or "( none )" on a fresh save, with a crafting hint subline. A spacer, then a large bottom-anchored START EXPEDITION button with the "Begin at Level 1, ~10 hunts, die and forfeit the haul" subtitle. A 3-up icon nav row (Inventory, Bestiary, Meta) at the bottom.

`launch_screen.gd` keeps driving the same `GameState` calls (zone/weapon selection, `start_run`, navigation) — only node structure and wiring change. No rules logic here.

## Acceptance criteria

- [ ] Launch screen matches the visual-target composition: title + essence pill header, zone card, weapon card, bottom-anchored START + subtitle, 3-up icon nav
- [ ] Essence value and equipped-weapon (icon + name, "( none )" when empty) render from `GameState`
- [ ] Zone and weapon selection and `start_run` still work through the existing `GameState` seam
- [ ] `test_scenes_smoke.gd` asserts the launch screen instantiates and its expected nodes exist after the restructure
- [ ] `scripts/screenshot.sh` output for the launch screen is reviewed against the canvas
- [ ] No change to `src/systems/` rules
- [ ] `./scripts/test.sh` exits 0

## Blocked by

- #28

