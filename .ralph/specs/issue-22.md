# Exit-tile travel: reach an exit in a hot region to unlock + travel deeper

> GitHub issue #22 | Labels: ready-for-agent, P1 | https://github.com/taigamura/infinity-hunter/issues/22

## Parent

#16

## What to build

Deeper-zone travel via an exit tile placed inside a hot (high-tier) region of the Verdant Fields map. Reaching the exit tile calls the existing `RunState.unlock_zone(target)` and travels to the connected zone (per `zone.connections`). Because the exit sits in high-tier terrain, reaching it means walking through fast-filling, tougher-spawn territory — travelling deeper is an earned gauntlet, not a free choice. For the slice, the exit is present and functional on Verdant Fields even if the target zone's tilemap is a minimal/stub map until it is painted later.

## Acceptance criteria

- [ ] An exit tile exists inside a high-tier region of Verdant Fields
- [ ] Reaching it unlocks (`RunState.unlock_zone`) and travels to the connected zone
- [ ] The route to the exit passes through hotter terrain (faster gauge, tougher band)
- [ ] Travelling deeper preserves run state (level, hunts, haul) correctly
- [ ] `./scripts/test.sh` exits 0

## Blocked by

- #21

