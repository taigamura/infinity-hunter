# Pokémon Aesthetic Spec (Gen 4 DS backbone)

The design grammar every generated Infinity Hunter creature must obey. Derived from studying the
Gen 4 battle sprites in `docs/references/Gen 4 Pokemon/` (dex-numbered, ground truth) and the ORAS/SM
icons + HGSS overworld sheets. **Pokémon is the genuine backbone** — a generated creature that
violates these rules does not read as "of this world" and must be rejected.

> IP guardrail: these are STYLE rules distilled from observation. Build ORIGINAL creatures that obey
> the grammar. Never reproduce or ship a recognizable Pokémon, its name, or its exact sprite pixels.

## 1. Proportion (the cuteness engine)
- **Big head, small body.** Head is ~40–50% of sprite height on cute/small species (Pichu 172,
  Jigglypuff 39, Marill 183, Togepi 175, Munchlax 446). Larger/tougher species shrink the head ratio
  but never below ~30%.
- **Stubby limbs.** Arms/legs are short rounded nubs, not long. Hands/feet are simple mitts or pads,
  rarely fingered.
- **Round over angular.** Bodies are built from circles and ovals. Even rocky mons (Geodude 74,
  Onix 95, Sudowoodo 185) round their corners. Sharp shapes are reserved for horns, fins, spikes.
- **Low center of gravity.** Weight sits low; bottom-heavy silhouettes read stable and friendly.

## 2. Eyes & face
- **Large, high-contrast eyes.** Usually a dark oval/circle filling much of the eye, with **one bold
  white highlight dot** (upper area). Optional colored iris (Jigglypuff blue). This single shine is
  the biggest cuteness lever.
- **Eyes set wide and fairly low** on the face; gaze slightly toward the viewer (3/4).
- **Minimal mouth** — a small curve, a tiny open smile, or a simple line. Blush ovals on cheeks are
  common on cute species (Clefairy 35, Marill).

## 3. Outline (the Gen-4 signature)
- **Selective, COLORED outline — not uniform black.** The outline of each region is a *darker,
  slightly desaturated shade of that region's own fill* (green body → dark-green edge; red → maroon
  edge). Near-black is used only where forms overlap or at the very bottom for grounding.
- **1px, clean, closed.** No double lines, no anti-aliased fuzz. This crispness is why 32×32 +
  palette-quantize reads right and 80px LANCZOS reads "blurry."

## 4. Shading
- **2–3 tones per color region:** base, one shadow, optional one highlight. Discrete cel bands, not
  gradients.
- **Light from upper-left / top.** Highlight on the upper-left curve, shadow on the lower-right and
  underside. Consistent across all parts.
- **Shadow = darker + slightly desaturated** version of the base (same hue family), not gray.

## 5. Color
- **Saturated but not neon.** Tight palette per creature: 1 dominant hue + 1–2 accents + a
  light belly/underside + the outline shades. Typically 4–6 colors total at icon size.
- **Contrasting underside.** Belly/chest/feet are often a lighter cream or pale tint (Snorlax 143
  cream, Squirtle 7 cream, Bulbasaur 1 pale teal). Adds depth and reads cute.

## 6. Silhouette & pose
- **Readable silhouette.** Identifiable from the black shape alone; key appendages (ears, tail, fins,
  horns) break the outline so they register.
- **3/4 front pose, slight turn**, subtle asymmetry, grounded. Not flat-front, not full profile.

## 7. Body archetypes (drives anchor selection + the tag vocabulary)
| Archetype | Examples (dex) | Reads as |
|---|---|---|
| round / blob | 39, 35, 88, 316, 143 | sphere body, tiny nubs, no neck |
| quadruped | 1, 133, 231 | 4 legs, horizontal body, head forward |
| biped | 4, 25, 443, 185, 446 | stands, 2 arms + 2 legs, big head |
| serpent / noodle | 147, 95 | long body, no/again tiny limbs |
| fish / aquatic | 129, 349, 320, 131 | fins, fluke, side-on body |
| floating | 92, 200, 374, 436 | no ground contact, hovers |
| star / radial | 120, 121 | symmetric arms from a core |
| bug | 10, 13, 265 | segmented, antennae, many legs |
| bird / avian | 16, 21, 396 | wings, beak, talon feet |

## 8. Animation feel (overworld sheets)
- Overworld walk = **2–4 frames**, side/front chibi, a gentle vertical **bob** + slight squash. Low
  frame count, big motion per frame. Combat idle should borrow that bob amplitude; attack/hit stay
  code-driven (see the sprite pipeline). Overworld sprites are a *style* reference (side-facing walk),
  not liftable frames for a front-facing combat idle.

## 9. Generation checklist (apply every time)
1. Pick an anchor whose **body archetype + limb count matches the target** (tag DB → `pokedex_tags.json`).
2. Anchor from the **low-res icon** (chunky), not the high-res battle sprite (over-details).
3. **Mild hue nudge** the anchor toward target color (~0.6), leave greys.
4. Generate → keyout → **32×32 + quantize 16** (crisp, never LANCZOS-only).
5. Reject any result that fails §1–§6 (blurry, uniform-black outline, gradient shading, wrong
   proportion, unreadable silhouette).
