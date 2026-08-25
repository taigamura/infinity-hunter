# Combat restructure: auto-start, pinned HUD, telegraph + floating damage, result overlay

> GitHub issue #30 | Labels: ready-for-agent, P1 | https://github.com/taigamura/infinity-hunter/issues/30

## Parent

#27

## What to build

Restructure the combat screen into the visual-target in-fight HUD, under the project theme from #28. Combat begins automatically on `_ready` (the overworld already gated the encounter), so the explicit `StartButton` is removed. Absolutely-positioned HUD: monster name / level / weakness / element / targeted part with a styled HP bar pinned top; player HP bar + value pinned bottom; a large DODGE button anchored at the bottom with the "perfect timing avoids most damage, chip still lands" subtitle. Juice: monster sprite centred with an idle bob and a telegraph ring, an "INCOMING — TAP TO DODGE" banner flashing during the attack window, a floating damage number on hits, and a round-dot row tracking resolved / active / pending rounds. The fight outcome (victory XP, or death) renders as a themed panel over the arena carrying Push On / Bank actions, replacing the inline `ResultLabel` + `ContinueButton`.

The authoritative outcome still flows through `RunState.resolve_fight`; `combat_screen.gd` changes only round timing / animation bookkeeping and layout. The telegraph, damage number, and round dots are presentation over the existing round timing (`ROUND_DURATION`, `PERFECT_OFFSET`) — no combat-rule change. The screen remains an overlay that signals `combat_finished` and leaves teardown to its parent.

## Acceptance criteria

- [ ] Combat auto-starts on entry; the standalone Start button is gone
- [ ] In-fight HUD matches the canvas: monster info+HP pinned top, player HP pinned bottom, anchored DODGE + subtitle, telegraph banner+ring, floating damage number, round-dot row
- [ ] Victory/death shows a themed result overlay over the arena with Push On / Bank actions
- [ ] Outcome still resolves through `RunState.resolve_fight`; the screen still emits `combat_finished` with the result; no combat-rule change
- [ ] `test_scenes_smoke.gd` asserts the combat screen instantiates (with minimal `GameState`) and its expected nodes exist after the restructure
- [ ] `scripts/screenshot.sh` output for the combat screen is reviewed against the canvas
- [ ] No change to `src/systems/` rules or combat tunables
- [ ] `./scripts/test.sh` exits 0

## Blocked by

- #28

