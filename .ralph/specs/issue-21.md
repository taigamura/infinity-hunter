# Combat overlay: combat_screen emits combat_finished, fight renders over paused map

> GitHub issue #21 | Labels: ready-for-agent, P0 | https://github.com/taigamura/infinity-hunter/issues/21

## Parent

#16

## What to build

Turn a fired encounter into a real fight rendered as an overlay over the paused map. Refactor `combat_screen` so it no longer calls `change_scene_to_file` on completion; instead it emits a `combat_finished(result)` signal (or equivalent) and works as an instanced child overlay. The overworld pauses the map beneath it, hands the picked monster over via `GameState.pending_monster` (unchanged), and on completion: if the run is still `active`, free the overlay, reset the gauge, and resume; if the run ended (death or hunt exhaustion), settle and return to the launch screen. All authoritative outcome resolution stays in `RunState.resolve_fight` — no combat rules move. Each fight spends one hunt exactly as today.

## Acceptance criteria

- [ ] A fired encounter opens combat as an overlay on top of the paused overworld
- [ ] `combat_screen` signals completion instead of changing scenes
- [ ] Win: overlay frees, gauge resets, character resumes at the same position; one hunt spent
- [ ] Death: run ends, unbanked haul forfeit, returns to launch (existing behavior preserved)
- [ ] Hunt exhaustion auto-banks and returns to launch
- [ ] XP, drops, level, and bestiary progress accrue exactly as from node-map fights
- [ ] `./scripts/test.sh` exits 0

## Blocked by

- #20

