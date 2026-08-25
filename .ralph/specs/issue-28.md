# Theme foundation: vendor OFL fonts, project-wide pixel theme, scene-smoke + screenshot harness

> GitHub issue #28 | Labels: ready-for-agent, P0 | https://github.com/taigamura/infinity-hunter/issues/28

## Parent

#27

## What to build

The theme foundation and the verification harness the whole milestone depends on. A single project-wide pixel-art `Theme` resource — two vendored OFL fonts (`Press Start 2P` for headers/labels/buttons, `VT323` for body/descriptive text), a dark-navy panel palette with a gold (`#f5c542`) primary accent, StyleBoxes for panels (navy fill, lighter border, rounded corners), beveled action buttons, and bordered `ProgressBar` fill/background — set as the project's default GUI theme so every `Control` inherits it. No screen is restructured here; this slice is verifiable because every existing screen (launch, overworld, combat, inventory, bestiary, meta) immediately renders under the pixel skin.

Also lands the two verification layers this milestone runs on: a new headless scene-smoke test that instantiates every screen scene and a `scripts/screenshot.sh` that renders each screen to a PNG via `xvfb-run` on the `gl_compatibility` renderer for out-of-band visual review. The smoke test sets up minimal `GameState` (start a run; set `pending_monster`) before instantiating the combat/overworld overlays, establishing the scene-loading test pattern (prior art for pure-logic tests: `tests/unit/test_big.gd`).

Fonts are vendored with their licence; the offline app must never fetch at runtime.

## Acceptance criteria

- [ ] `Press Start 2P` and `VT323` are vendored into the repo (with OFL licence) and load as valid `FontFile` resources
- [ ] A single `Theme` resource exists and is set as the project default GUI theme (`gui/theme/custom`), so screens inherit it with no per-scene theme overrides
- [ ] The theme defines the palette, panel StyleBoxes, button styles, and `ProgressBar` fill/background matching the visual-target canvas
- [ ] `tests/unit/test_scenes_smoke.gd` instantiates every screen scene, runs `_ready` without error (with minimal `GameState` set up for the combat/overworld overlays), and asserts the project theme is applied and the vendored fonts load
- [ ] `scripts/screenshot.sh` renders each screen to a PNG via `xvfb-run` (gl_compatibility) for visual review
- [ ] No change to `src/systems/` rules, tunables, or content JSON
- [ ] `./scripts/test.sh` exits 0

## Blocked by

None - can start immediately

