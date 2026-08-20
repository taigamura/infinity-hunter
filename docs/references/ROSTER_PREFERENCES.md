# Roster Art Preferences (deterministic guide)

Running record of the user's stated preferences during the monster-sprite roster pass, so the look
stays consistent and reproducible. Generator: pixel base + pksp768 LoRA @1.0 → keyout → 32px →
quantize. Apply ALL general rules to every monster; per-monster rows lock the specific pick/prompt.

## General preferences (apply to every monster)
- **NOT monotone.** Avoid single-hue sprites. Use a **richer, multi-color, natural/earthy palette** —
  a dominant element hue PLUS complementary earthy tones (browns, tans, stone) and a contrasting
  belly/underside. (2026-08-20: rejected an all-green turtle batch as "too green"; #4 was closest
  because it mixed brown/tan/moss.)
- Element sets the DOMINANT hue, not the only hue.
- **FRONT-FACING.** The creature must face the viewer (front / 3-4 front), looking at the camera —
  never showing its back/rear/side-away. Quadrupeds especially default to profile/back; force front.
  Prompt: "facing forward, front view, looking at the viewer". Negative: "back view, rear view, from
  behind, backside, facing away". (2026-08-20: rock_lizard v1 came out showing its backside.)
  ENFORCEMENT: SD negatives are soft — quadrupeds still slip through backside ~half the time. So the
  operator must **visually cull backside tiles BEFORE presenting the pick-sheet** (over-generate to
  keep ~8-10 front-facing candidates). Also add positive "head up, face and eyes visible toward the
  camera" to every prompt. (2026-08-20: user flagged backside tiles still appearing on ember_wolf.)
- Keep the round/cute chibi proportions + bold outline + cel shading (see POKEMON_AESTHETIC.md).
- Palette: real sprites are 12–15 colors, but the user likes visible color variety → allow ~16–20
  colors when the monster benefits (earthy/weathered creatures).

## Per-monster decisions
| Monster | Element | Status | Pick | Notes |
|---|---|---|---|---|
| slime | water | ✅ DONE | #1 | cyan teardrop, little feet, face. Installed. |
| mossback_turtle | earth | ✅ DONE | #1 (v2) | earthy: brown shell + moss-green + tan belly @19 colors. v1 rejected too green. Installed. |
| rock_lizard | earth | ✅ DONE | #7 (v2) | earthy grey-brown stone, front-facing (v1 showed backside). Installed. |
| sand_scorpion | earth | ✅ DONE | #9 | claws-up front scorpion; came orange-ish (tan prompt). Installed. |
| thistle_sprite | neutral | ✅ DONE | #3 | green thistle in woody brown base, front. Installed. |
| ember_wolf | fire | ✅ DONE | #9 | orange fire fur + ash grey, front. Installed. |
| magma_golem | fire | ✅ DONE | #8 | grey stone + orange lava, front (culled backside). Installed. |
| thunder_stag | thunder | ✅ DONE | #11 | gold + brown stag, antlers, front. Installed. |
| frost_wyrm | ice | ✅ DONE | #5 | icy blue + white winged wyrm, front. Installed. |
| glacier_troll | ice | ✅ DONE | #10 | blue-white troll, arms spread, front. Installed. |
| voidmaw_devourer | dragon | ✅ DONE | v2#6→img2img var1 | bipedal, wings spread (Charizard stance), purple + gold flames. Iterated a lot. Installed. |

## Prompt recipe (per element, earthy variant)
- Lead with the creature + body plan, then dominant color, then 2–3 earthy accent tones + underside.
  e.g. turtle: "brown mossy shell, moss-green skin, tan underbelly, weathered earth tones".
