# How to Generate the Best AI Pokémon-style Sprites (research + findings)

Research pass (2026-08-20) into how others produce authentic Pokémon-style 32×32 sprites/icons,
plus what we can derive from the reference sprites. Conclusion at the bottom is now the recommended
pipeline for Infinity Hunter monster art.

## What others actually do (web research)

1. **Use a Pokémon-FINE-TUNED base model — this is the big one.** Nobody gets authentic results from
   a generic model + prompt. They fine-tune (or use a community fine-tune) on Pokémon:
   - `lambdalabs/sd-pokemon-diffusers` — full SD1.5 fine-tuned on Pokémon (BLIP-captioned dataset
     `lambdalabs/pokemon-blip-captions`). Text→Pokémon **creature**, 512px, loadable directly via
     diffusers. **We tested this — clear step change** (see below).
   - `justinpinkney/pokemon-stable-diffusion` — same lineage.
2. **Pokémon *sprite* LoRAs (pixel-native)** on Civitai — e.g. "Pokemon Sprite PixelArt 768" trained
   on the actual 96×96 game sprites; "Pokemon Sprites XL". Workflow they recommend: generate at
   768×768, **downscale ×8 (nearest) to 96×96**, or 768×384→192×96 for Gen-5 rows. Trained with type
   tags (`grasstype`, `firetype`…). These give a natively *pixel* look (less downscale artifact than
   the painterly lambdalabs model). Not one-click loadable via diffusers (Civitai `.safetensors` LoRA
   → `pipe.load_lora_weights`).
3. **IP-Adapter on top** — "for the absolute best results, use an IP-Adapter with a Pokémon sprite for
   style transfer on top of the pixelate effect." (This is the piece we already had — it was just
   sitting on the wrong base model.)
4. **Dedicated pixel tools** — Retro Diffusion, PixelLab, Astropulse pixel-detector: pixel-art-first
   diffusion + true-grid snapping. Good, but proprietary/hosted.
5. **32×32 post-process discipline** (consistent across every guide): generate big → **downscale with
   palette reduction** (build a palette, snap every pixel) → **12–32 colors, fewer = stronger retro**
   → **2 minutes of manual edge cleanup** ("the difference between 'converted photo' and 'drawn
   sprite'"). Defined outlines + clear silhouette + limited palette = SNES/GBA read.

## What we derived from the reference sprites (measured)

- **Palette is TIGHT: 12–15 opaque colors** on Gen-4 battle sprites, 12–18 on ORAS icons. Target
  ~15. Our `pixelate()` quantizes to 15 — matches.
- Icons are **40×40**, battle sprites **~80–86px**. Bounding-box fill varies by body plan (round mons
  ~0.45–0.5 of canvas each axis; long mons like Geodude 0.74 wide × 0.38 tall). Center + ground.
- Bold outlines, 3/4 front pose, cel shading, contrasting belly (see `POKEMON_AESTHETIC.md`).

## Tested result: lambdalabs Pokémon model + downscale/palette

Swapped the generic pixel model for `lambdalabs/sd-pokemon-diffusers`, text-prompted 6 creatures
(slime/dragon/golem/turtle/fox/bird), then `pixelate(32px, 15 colors)`. **Much more authentically
Pokémon** than pixel-model+IP-Adapter — the model natively renders Pokémon anatomy, outlines, and
shading (turtle & golem downscale cleanest; winged dragon/fox get busy at 32px because the source art
is complex). Boards: `/mnt/c/blender_work/gen_pokemodel/` (`board_all.png`, `raw_montage.png`).

## Recommended pipeline (updated)

1. **Base model:** `lambdalabs/sd-pokemon-diffusers` (Pokémon-native creatures). Optionally stack a
   **Civitai Pokémon *sprite* LoRA** for a pixel-native look (less downscale mush) — next thing to try.
2. **Control (optional):** IP-Adapter fed a tag-selected anchor (from `pokedex_tags.json`) to steer
   body plan/type; or type tags in the prompt.
3. **Post:** keyout bg → crop → hard downscale to **32px** → **quantize ~15 colors** → light despeckle.
   Generate at 512–768 for a cleaner downscale.
4. **Per-monster:** simple text prompt ("a cute mossy green turtle monster, shell, four legs") +
   optional anchor; generate 6–10, pick best.
5. Then animate in code (idle bob / attack / hit) → `assets/sprites/<id>.png`.

Open items: try a Civitai sprite LoRA for pixel-native output; tune per-monster prompts; colored-ring
backgrounds occasionally survive keyout (widen tolerance or center-flood).
