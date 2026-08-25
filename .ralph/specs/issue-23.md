# Retire node-map: delete NodeMap/node_map_screen, drop RunState.node_map

> GitHub issue #23 | Labels: ready-for-agent, P1 | https://github.com/taigamura/infinity-hunter/issues/23

## Parent

#16

## What to build

Subtractive cleanup now that the overworld fully replaces the node-map. Delete `NodeMap`, `node_map_screen.gd/.tscn`, and `test_node_map.gd`; remove `RunState.node_map` and `generate_node_map`; stop `GameState.start_run` from generating a node map. No behavior change for the player — this removes dead code and its stale test.

## Acceptance criteria

- [ ] `NodeMap`, `node_map_screen`, and `test_node_map` are removed
- [ ] `RunState.node_map` and `generate_node_map` are gone; `resolve_fight`/`retreat`/`unlock_zone` unchanged
- [ ] `GameState.start_run` no longer references node-map generation
- [ ] No dangling references to the removed symbols remain
- [ ] `./scripts/test.sh` exits 0 (existing `test_run_state` still passes)

## Blocked by

- #22

