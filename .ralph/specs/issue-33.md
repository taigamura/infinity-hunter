# Combat fidelity: filled HP bars, detail line, telegraph/damage/banner juice, DODGE style, timer-in-tree fix

> GitHub issue #33 | Labels: ready-for-agent, P1 | https://github.com/taigamura/infinity-hunter/issues/33

## Parent

#27

## What to build

Bring the combat screen to near-exact match with the visual-target canvas, applying the shared background + gradient bar fills from #32. In the first pass the HP bars render as thin empty lines and the fight detail/juice is incomplete.

**HP bars (the main miss).** Apply the theme's red fill to the monster HP bar (`#ff5a3c -> #cc331a`) and the green fill to the player HP bar (`#6ce27a -> #46b357`), each ~30px tall over the dark track (`#0c0f16`, border `#495168`, ~9px radius). Both bars must be visibly FILLED to their current value, not empty lines.

**Detail line.** Under the monster name/level, show the full status line from the mockup: weakness (`WEAK`), element (with the coloured diamond, e.g. `Water`), and the targeted part (`part: body`) — VT323, muted where secondary.

**Sprite + juice.** Centre the monster sprite larger (mockup ~300px equivalent) with the idle bob. The transient states must exist and be verifiable in motion (they will not appear in a static first-frame): a dashed telegraph ring `#ffd24a` around the sprite and an `INCOMING - TAP TO DODGE` banner (bg `#2a1113`, border `#ffd24a`) during the attack window, and a floating damage number (`#ffe08a`, shadow `#915b00`) on a hit. Round dots: resolved `#46b357`, active `#ffd24a`, pending `#2a3145`.

**DODGE button.** Blue radial `#8fd7ff -> #4aa6e0` with a darker bottom edge `#2f7bad`, anchored bottom, with the `Perfect timing avoids most damage - chip still lands` subtitle.

**Fragility fix.** The auto-start currently calls `timer.start()` in `_ready`, which errors when the scene is not yet in the tree (seen in the smoke test). Guard it (e.g. defer the first round to after tree-entry / a frame, or `is_inside_tree()` check) so instantiation never throws, while the real overlay still auto-starts.

## Acceptance criteria

- [ ] Monster and player HP bars are visibly filled with the red/green gradients over the dark track (not empty lines)
- [ ] The monster detail line shows weakness + element (coloured diamond) + targeted part
- [ ] Monster sprite is centred and enlarged with the idle bob; DODGE uses the blue radial with darker bottom edge + subtitle
- [ ] Telegraph ring, INCOMING banner, floating damage number, and the 3-state round dots are implemented (verified in motion, not asserted statically)
- [ ] `_ready` auto-start no longer errors when the scene is instantiated outside the tree; the real overlay still auto-starts the fight
- [ ] `scripts/verify_visual.sh` gains a combat invariant: the rendered combat frame contains both red (monster-bar) and green (player-bar) pixels; SKIP if unrenderable, FAIL only on a rendered violation
- [ ] Outcome still resolves through `RunState.resolve_fight`; the screen still emits `combat_finished`; no combat-rule change
- [ ] `./scripts/test.sh` exits 0 (unit suite + visual gate)

## Blocked by

- #32

