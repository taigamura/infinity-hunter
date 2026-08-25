# Overworld fidelity: tier green->red danger gradient, hot-region strip, styled gauge/retreat, joystick centering

> GitHub issue #34 | Labels: ready-for-agent, P1 | https://github.com/taigamura/infinity-hunter/issues/34

## Parent

#27

## What to build

Bring the overworld field + HUD to near-exact match with the canvas, on top of #32. In the first pass the tile field renders uniformly green with no visible danger gradient, so the "hot region" the design centres on is invisible.

**Tier danger gradient (the main miss).** The visible tile field must show the mockup's danger gradient rising toward the hot corner: tier 0 `rgb(64,140,64)` (safe green) -> tier 1 `rgb(134,96,45)` (olive-brown) -> tier 2 `rgb(204,51,26)` (danger red), interpolated by distance so the exit corner is clearly red while the centre is green. Keep the existing per-tile shade jitter + inset border. This is the real `OverworldTierLayout` mapping driving colour, not a uniform fill.

**Hot-region warning strip.** When the character is on a hot (tier 2) tile, show the strip from the mockup: bg `#2a1113`, border `#cc331a`, an alert glyph, and `Hot region - gauge fills fast` (VT323, `#ff9a86`). Absent on safe tiles.

**Encounter gauge + retreat.** Top bar gauge fill is the gradient `#57c964 -> #f5c542` reflecting the live gauge value; RETREAT button bg `#3a1f1f`, border `#a2432f`.

**Exit marker.** Toward the hot corner, the pulsing exit marker labelled with the connected zone (already present - verify it sits on/near the red tiles).

**Joystick.** Base bg `#0c0f16`, border `#495168`; knob `#c8cede`, border `#eef2ff`. Fix the knob resting position so it is CENTRED in the base at rest (currently offset), and returns to centre on release.

## Acceptance criteria

- [ ] The visible tile field shows the green -> olive -> red danger gradient toward the hot corner (not uniform green), driven by the real tier mapping, keeping the jitter + inset border
- [ ] The hot-region warning strip appears only when the character is on a tier-2 tile, styled per the mockup
- [ ] Encounter gauge uses the green->gold gradient and reflects the live gauge value; RETREAT is styled
- [ ] The joystick knob rests centred in the base and returns to centre on release
- [ ] `scripts/verify_visual.sh` gains an overworld invariant: the rendered overworld frame contains red-family pixels toward the top-right (hot corner); SKIP if unrenderable, FAIL only on a rendered violation
- [ ] No change to `src/systems/` rules; exit-cell travel behaviour unchanged
- [ ] `./scripts/test.sh` exits 0 (unit suite + visual gate)

## Blocked by

- #32

