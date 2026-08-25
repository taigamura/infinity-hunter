# Overworld HUD + procedural polish: gauge, hot-strip, exit marker, joystick skin, tile/player treatment

> GitHub issue #31 | Labels: ready-for-agent, P1 | https://github.com/taigamura/infinity-hunter/issues/31

## Parent

#27

## What to build

Bring the overworld HUD and field render up to the visual-target, under the project theme from #28. Top bar: a styled ENCOUNTER gauge with a gradient fill (driven by the live `EncounterSystem` gauge) and a themed RETREAT button. A "hot region" warning strip that appears when the character is on a dangerous tier. An animated EXIT marker toward the hot corner, labelled with the connected zone. Skin the existing `virtual_joystick.gd` as the circular bottom-left control. Cheap procedural polish (no new art): `OverworldTileset` gains per-tile shade jitter + an inset border; the player square gains a border + drop-shadow.

Wiring stays on the existing seams — gauge value from `EncounterSystem`, tier from `OverworldTierLayout`, movement from `OverworldMovement`/the joystick, exit-cell travel unchanged. Only HUD styling, the marker/strip, and the procedural tile/player treatment change.

## Acceptance criteria

- [ ] Overworld top bar shows a styled encounter gauge reflecting the live gauge value and a themed RETREAT button
- [ ] A hot-region warning strip appears on dangerous tiers; an animated, zone-labelled EXIT marker sits toward the hot corner
- [ ] The virtual joystick is skinned to the circular control and still drives movement
- [ ] `OverworldTileset` shows per-tile shade jitter + inset border and the player square has a border + drop-shadow (no new sprite art)
- [ ] `test_scenes_smoke.gd` asserts the overworld screen instantiates (with minimal `GameState`) and its expected nodes exist after the restructure
- [ ] `scripts/screenshot.sh` output for the overworld is reviewed against the canvas
- [ ] No change to `src/systems/` rules; exit-cell travel behaviour unchanged
- [ ] `./scripts/test.sh` exits 0

## Blocked by

- #28

