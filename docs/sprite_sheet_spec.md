# Monster sprite sheet spec (fixed, MVP)

Frame-by-frame `AnimatedSprite2D` art, fed from a single PNG sheet per monster. This layout is
fixed for the life of the placeholder pipeline: a polished sheet with the same spec drops in over
a proxy sheet with **zero code change** (see `SpriteSheetSlicer`).

## Layout

- **Frame size:** 64x64 px, no padding/margin between frames.
- **Columns:** 4 (row-major: left to right, then down to the next row).
- **Rows:** 3, one per animation, in this fixed order:
  | Row | Anim name | Frames used | FPS |
  |-----|-----------|-------------|-----|
  | 0   | `idle`    | 4           | 4   |
  | 1   | `attack`  | 4           | 8   |
  | 2   | `hit`     | 2           | 6   |

- **Sheet size:** 256x192 px (4 cols x 3 rows x 64 px). Unused cells in the `hit` row (2 of 4) are
  left blank/transparent.
- `idle` loops continuously. `attack` and `hit` play once and are triggered by combat events, then
  the sprite returns to `idle`.

## File location & lookup

- Proxy/placeholder sheet (shared across all monsters for MVP): `assets/sprites/placeholder_monster.png`.
- Per-monster sheets, when authored, live at `assets/sprites/<monster_id>.png` and are picked up
  automatically by `MonsterSpriteSheet.path_for(monster_id)` (falls back to the shared placeholder
  if a per-monster file doesn't exist) — no `MonsterDef` schema change or code change needed to
  swap in real art.

## Slicing

`src/systems/sprite_sheet_slicer.gd` (`SpriteSheetSlicer`) computes the row-major `Rect2` region
for a given anim name + frame index from the constants above. It is pure math (no `Image`/`Texture`
work) so it is covered by the headless logic test suite. `src/ui/combat/monster_sprite_sheet.gd`
uses it to build a runtime `SpriteFrames` resource and is manual-verify only (rendering).
