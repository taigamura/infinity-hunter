# UI fidelity foundation: navy backgrounds, launch polish, gradient bar styles + pixel-invariant visual gate

> GitHub issue #32 | Labels: ready-for-agent, P0 | https://github.com/taigamura/infinity-hunter/issues/32

## Parent

#27

## What to build

Close the biggest fidelity gaps from the first theming pass so the screens read like the visual-target canvas, and add a **pixel-invariant visual gate** so the autonomous loop can actually verify the look, not just the structure. Post-#28 the panels are navy but the page background is still Godot default grey, titles lack their glow, and the theme is missing the gradient bar fills — this slice fixes the shared/launch pieces and lands the gate that #30-follow (combat) and #31-follow (overworld) depend on.

**Shared background.** Every screen must paint the mockup's dark-navy background behind its content (a full-rect background node per screen, since a `Theme` cannot set a root background). Launch/combat use gradients, overworld keeps its tile field. Exact values from the canvas artboards:
- Launch background: vertical gradient `#151822 -> #0f121a`, with the faint 48px grid overlay (`rgba(90,110,160,0.05)` lines).
- Combat background: radial gradient, centre-top, `#2a3550 -> #12151f` (~70%).

**Launch fidelity.** Title `INFINITY HUNTER` in gold `#f5c542` with a `3px 3px` drop-shadow in `#7a5a10`. Essence pill: bg `#1c2130`, border `#39415a`, with the small gold diamond glyph before the number. Cards: bg `#1b2030`, border `#39415a`, ~14px radius (already close — verify). START button: green gradient `#6ce27a -> #46b357` with a darker bottom edge `#2f7a3a`.

**Theme completeness (shared).** Add the gradient `ProgressBar` fill styles the other slices consume: a red monster-HP fill (`#ff5a3c -> #cc331a`) and a green player-HP fill (`#6ce27a -> #46b357`), each over a dark track (`#0c0f16`, border `#495168`). Expose them so combat can apply them per-bar.

**Visual gate (the important part).** Add `scripts/verify_visual.sh`: render each screen via `xvfb-run` (gl_compatibility) to an image and assert coarse, robust pixel invariants, then wire it into `scripts/test.sh` as a second stage (unit suite first, then visual gate; overall exit non-zero if either fails). It MUST be infra-safe: if rendering cannot produce a non-empty image at all (no display / driver), SKIP with a warning and exit 0 — never fail the gate on infrastructure. Fail (exit 1) only when a frame WAS rendered but violates an invariant. Invariants for this slice:
- Launch and combat: the background corner pixels are the navy family (blue-ish, dark), NOT the default grey (`~#3a3a3a`, r≈g≈b).

Keep invariants coarse (hue/brightness bands, not exact pixels) so they catch the grey-background class of miss without being brittle.

## Acceptance criteria

- [ ] Launch and combat render on the navy background (gradient), not Godot grey; launch shows the 48px faint grid
- [ ] Launch title has the gold drop-shadow; essence pill shows the gold diamond glyph; START uses the green gradient with a darker bottom edge
- [ ] The theme exposes red (`#ff5a3c->#cc331a`) and green (`#6ce27a->#46b357`) gradient `ProgressBar` fills over a dark track, ready for combat to apply
- [ ] `scripts/verify_visual.sh` exists, renders each screen via xvfb, and asserts the background-is-navy invariant for launch and combat; it SKIPS (exit 0) if no image can be rendered, and FAILS (exit 1) only on a rendered violation
- [ ] `scripts/test.sh` runs the unit suite AND the visual gate; a rendered navy-background violation makes it exit non-zero
- [ ] No change to `src/systems/` rules, tunables, or content JSON
- [ ] `./scripts/test.sh` exits 0 (unit suite green + visual gate satisfied/skipped)

## Blocked by

None - can start immediately

