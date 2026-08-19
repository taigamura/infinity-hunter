# Overworld scene + launch redirect: walk Verdant Fields with joystick + follow-camera

> GitHub issue #19 | Labels: ready-for-agent, P0 | https://github.com/taigamura/infinity-hunter/issues/19

## Parent

#16

## What to build

The walkable overworld scene for Verdant Fields, and the launch redirect that makes it the run screen. A new scene owns a `TileMap` for the zone, a `Camera2D` that follows the character, and a character body driven by an on-screen virtual joystick with keyboard input mapped to the same movement vector (so desktop/headless can drive it). A retreat button banks the run via the existing `RunState.retreat()` -> `GameState.settle_run` path and returns to launch. The launch screen's final navigation changes to route into this overworld instead of the node-map. The old node-map scene/code is left in place (unused, dead) and is removed in a later slice, so the game stays runnable throughout.

No encounters or combat yet — this slice delivers "launch -> walk Verdant Fields with a following camera -> retreat -> bank."

## Acceptance criteria

- [ ] Starting a run from launch loads the overworld scene for the chosen zone (Verdant Fields)
- [ ] Character moves in 8 directions via on-screen virtual joystick
- [ ] Keyboard input drives the same movement for desktop testing
- [ ] Camera follows the character across a map larger than the screen
- [ ] Retreat button banks the run and returns to launch (haul settled via existing path)
- [ ] node-map scene/code remains present but is no longer navigated to
- [ ] `./scripts/test.sh` exits 0 (existing gate stays green)

## Blocked by

None - can start immediately

