# CONTEXT.md — Infinity Hunter

> **Read this first every session.** It is the durable orientation doc: the game's
> identity, architecture, module map, run loop, content, and the current build's
> deltas from the PRD. Prefer it over re-scanning the codebase. When it drifts from
> the code, fix the code or fix this doc: it is meant to stay true.
>
> Deep specs live elsewhere: `docs/PRD.md` (full resolved design), `docs/adr/`
> (decisions, lazily added), and the visual-target design canvas linked in the
> README (a target mockup the UI is being themed toward, not the current build's look).

## What the game is

An offline, iOS-first **pixel hunting RPG** built in Godot 4 (GDScript only). Each
**run** (expedition): pick an unlocked **zone**, start at **Level 1** with your
persistent gear, roam a walkable **overworld**, and fight monsters in a real-time
dodge **HP-race**. Killing monsters far above your level dumps huge XP that crosses
many level thresholds at once, so you explode from Lv.1 into absurd power inside a
single run. You gather materials, craft gear, optionally capture a weakened monster
as a passive companion, and decide each step whether to **push deeper or cash out**:
dying forfeits the run's unbanked haul. Between runs, level resets but gear,
materials, captures, bestiary, unlocks, and **essence** (a modest permanent-upgrade
currency) persist. Fully offline, no account, no server.

**Identity to protect:** a fast offline pixel hunting RPG where each expedition is an
optimization puzzle: choose your fights, grow from Lv.1 into absurd power, craft
monster gear, bring one captured companion, push farther than last time, then reset
and repeat.

## Architecture

Four layers, one hard test seam.

1. **`GameState`** (`src/ui/game_state.gd`) — the single autoload. Owns loaded
   content defs, the durable save, the `Inventory`, and (while a run is live) the
   `current_run: RunState` plus the `pending_monster` picked for combat. Scenes read
   and drive it via its public methods; they never touch systems directly, so
   navigating between screens never loses state.
2. **Systems** (`src/systems/`, some `src/core/`) — pure game logic as `class_name`
   RefCounted/static classes. **This is the single test seam:** all rules are here,
   headless-testable, with no scene or rendering dependency. See the module map.
3. **Data** (`data/`) — per-entity JSON content loaded by `DataLoader` into typed
   def classes (`src/models/`) with load-time validation that fails loudly.
4. **UI scenes** (`src/ui/`) — thin shells over the systems. They render state and
   drive buttons; they reimplement no rules.

**Numbers:** every game quantity (HP, XP, damage, level, essence, thresholds) routes
through `Big` (`src/core/big.gd`), float-backed for now (safe to ~9e15), swappable
to a mantissa/exponent bignum later without touching call sites.

**Test gate:** `./scripts/test.sh` (exit 0 = pass). It rebuilds Godot's class cache,
then runs the headless suite (`tests/run_tests.gd`, 18 unit files under
`tests/unit/`). Reference test pattern: `tests/unit/test_big.gd`. This is the Ralph
loop's verification gate and the definition of "done".

### Module map (`src/systems/` unless noted)

| Module | Responsibility |
|---|---|
| `Big` (`src/core/big.gd`) | Float-backed big-number type + formatting (`Big.fmt`). |
| `RunState` | The live expedition: zone, hunts, level/XP, run HP, unbanked haul, equipped loadout. Owns push/retreat/death banking. |
| `XpCurve` | Exponential level thresholds; `award_xp` loops threshold-by-threshold so one award crosses many levels. Level→power scaling. |
| `CombatResolver` | Pure dodge/HP-race: dodge timing reduces incoming damage, an unavoidable **chip floor** (`CHIP_FLOOR_FRACTION = 0.35`) always lands, weapon class + element multiplier applied. |
| `Elements` | 6-element model: Fire/Water/Earth/Thunder/Ice ring (weak ×1.5, resist ×0.66), Neutral ×1.0, rare Dragon ×1.5 vs all. |
| `EncounterSystem` | Overworld gauge fill from tier params + band-filtered monster pick. `GAUGE_THRESHOLD = 100`. |
| `OverworldTierLayout` | Buckets a tile into a danger tier by **depth along the vertical travel axis** (near/bottom edge safe, far/top edge hot) per ADR-0001 (Deepening Trail, foundation slice built). Also places the near-edge `camp_cell` (spawn), the on-trail `exit_cell` (portal, deepest band), and `trail_x_for_row` (the winding trail spine's column per row). Per-zone tier tables/palettes (slice C) built. |
| `PoiLayout` | Pure/static points-of-interest placement (ADR-0001 slice B, built): `generate(map_cols, map_rows, sorted_tier_ids, rng)` returns a deterministic Array of `{cell, type}` (camp ×1, portal ×1, den 1–3, forage 1–3, cache 0–2, landmark 0–1), banded by depth thirds and trail proximity. Rendered as code-drawn tinted markers above the tilemap in `overworld_screen.gd`; standing on/adjacent to a den multiplies the tier's `gauge_rate` before it's passed into the unchanged `EncounterSystem.tick`. |
| `OverworldMovement` | Joystick + keyboard → clamped character step. |
| `DropSystem` | Weighted drop tables; part-break sharply boosts/guarantees that part's material. |
| `CraftingSystem` | Fixed recipes consume materials → instanced gear rolling a rarity tier (Common/Uncommon/Rare/Epic). |
| `Inventory` | Instanced gear (rolled stats) + stackable materials + consumables (Traps). |
| `CaptureSystem` | Below `capture_hp_threshold`, spend a Trap to capture: grants a companion + materials, forfeits the kill's XP. |
| `SkillSystem` | Builds the armor/set-bonus skill effect profile fed into combat. |
| `Bestiary` | Per-monster seen/kill/capture counts, discovered drops, broken parts. |
| `MetaProgression` | Essence = f(peak level), banked on a non-dead run; spend on capped global upgrades (see below). |
| `SaveManager` | Atomic JSON save to `user://` (temp→fsync→rename), `.bak` rollback, debounced autosave, versioned with sequential migration. `CURRENT_VERSION = 3`. A fresh (or empty-gear) save is seeded with a starter **Rusty Greatsword** + `unlocked_zones = [verdant_fields]`. |
| `SpriteSheetSlicer` | Slices a monster sheet into idle/attack/hit frames per the sheet spec. |

### UI scenes (`src/ui/`)

`launch/` (zone + loadout, starts the run) → `overworld/` (walkable field + encounter
gauge, opens combat as an overlay) → `combat/` (dodge HP-race, instanced overlay that
signals `combat_finished`). Plus `inventory/`, `bestiary/`, `meta/`. Portrait
720×1280, GL Compatibility renderer, `main_scene = launch_screen.tscn`.

## The run loop (current build)

```
LAUNCH ──▶ OVERWORLD ──▶ COMBAT ──┬─▶ VICTORY ──(push on, −1 hunt)──▶ OVERWORLD
  ▲            │                   │      └──(hunts=0 / retreat)──▶ BANK ─▶ essence ─▶ META ─▶ LAUNCH
  │            └─(reach exit cell)─┴─▶ travel deeper (unlock connected zone, reload)
  └──────────────── DEATH (forfeit unbanked haul; crafted gear safe) ◀── COMBAT
```

- **Launch:** pick zone + weapon, `GameState.start_run` builds a `RunState` at Lv.1
  (plus meta modifiers), change scene to the overworld.
- **Overworld:** walk a 30×40 tile field; each physics frame reads the tier under the
  character and ticks `EncounterSystem`. On gauge fire, band-pick a monster and open
  `CombatScreen` as an overlay (movement/ticking frozen). Reaching the corner
  **exit cell** unlocks the connected zone and reloads the scene for it.
- **Combat:** tap **Dodge** on the monster's telegraph each round; `CombatResolver`
  runs the reflex HP-race, and its result is now the **authoritative** win/loss:
  `CombatScreen` passes the reflex outcome into `RunState.resolve_fight` (via its
  `combat_outcome` arg), which spends 1 hunt, awards XP/levels/drops, or kills the
  run accordingly. You win by draining the monster's HP before yours; a round-cap
  timeout is broken by HP fraction. The old bare level-power compare survives only
  as the headless/test fallback when no `combat_outcome` is supplied. Combat never
  changes scenes: it emits `combat_finished` and the overworld tears down.
- **End of run:** hunts hit 0 or you retreat → `status = "banked"`, haul settled into
  the durable inventory + essence. Death → `status = "dead"`, unbanked haul zeroed.

### Key tunables (as built)

- Hunts per run: `RunState.DEFAULT_HUNTS = 10`. Essence: `ESSENCE_PER_XP = 0.5`.
- XP curve: `BASE_THRESHOLD = 100`, `GROWTH_RATE = 1.12`. Power: `POWER_BASE = 10`,
  `POWER_GROWTH = 1.08`.
- Combat: chip floor 0.35; dodge windows perfect 0.1s / good 0.3s (good removes 0.5).
- Meta upgrades (all `max_level = 5`, capped so gear stays primary): `starting_level`
  (+1/lvl, cap 5), `xp_multiplier` (+5%/lvl, cap 25%), `hunt_count` (+1/lvl, cap 5),
  `crit_chance` (cap 5%), `drop_rate` (cap 10%), `capture_chance` (cap 10%),
  `companion_effectiveness` (cap 10%).

## Content (as built)

- **Zones** (`data/zones/`): Verdant Fields (Lv 1–8) → Cinder Dunes (Lv 8–25) →
  Frostpeak Ridge (Lv 25–60). `connections` drive exit-tile travel.
- **Tiers** (`data/tiers/`): all three zones now have a tier table (tiers 0/1/2).
  `gauge_rate` escalates both within a zone and across zones toward Frostpeak
  (Verdant 6/10/16, Cinder Dunes 12/19/27, Frostpeak Ridge 20/30/42), reinforcing
  mounting pressure the deeper you push. Each zone's `data/zones/*.json` also carries
  a `palette` (3-stop hex: safe/mid/hot) and `band_names` (shallow→deep terrain
  labels), validated by `ZoneDef` — see ADR-0001 slice C below.
- **Monsters** (`data/monsters/`, 11): slime, rock_lizard, mossback_turtle,
  thistle_sprite, **voidmaw_devourer** (Lv 9,999,999,999 dragon stat-wall in Verdant
  Fields), ember_wolf, sand_scorpion, magma_golem, frost_wyrm, thunder_stag,
  glacier_troll. Sprite sheets in `assets/sprites/` (256×192, 64×64 frames, real
  AI-generated art).
- Weapons, armor, armor_sets, companions, materials: `data/*`. A fresh save is
  seeded with a starter **Rusty Greatsword** (auto-equipped at launch); everything
  else is crafted from looted materials. Launch gates the zone dropdown to the
  durable `unlocked_zones` list (starting at Verdant Fields), which `settle_run`
  extends whenever a run discovers a deeper zone (persists through death).
- **Weapon icons** (9, one per weapon) in `assets/weapons/<id>.png` (32×32, real
  AI-generated art via img2img from tinted silhouette templates). `WeaponIcons.for_id`
  (`src/ui/weapon_icons.gd`) loads them by the same per-id convention as monster
  sheets; shown in the launch weapon dropdown and inventory gear/recipe rows. Armor
  has no icons yet (helper returns null, slot stays empty).

## Current state vs PRD (deltas that matter)

- **Node-map retired (#23).** The PRD's branching `NodeMap` was replaced by the
  walkable overworld (#20–22). `RunState.node_map` and `NodeMap` are gone. Traversal
  is now: roam tiles → encounter gauge fires → combat; travel deeper via the exit cell.
- **HUD is themed to the visual-target canvas (#27, slices #28–#34).** A project-wide
  pixel `Theme` (`assets/theme/pixel_theme.tres`) with two vendored OFL fonts
  (`Press Start 2P` headers, `VT323` body) skins every screen; launch/overworld/combat
  are hand-composed to match the design canvas (navy backgrounds via
  `src/ui/common/screen_background.gd`, gradient HP/gauge bars, styled buttons, combat
  telegraph ring + floating damage juice). Inventory/bestiary/meta now also carry the
  navy `ScreenBackground` (release-polish pass) plus empty-state hint rows, dimmed
  disabled Craft buttons, and a bestiary discovered-count subtitle, so all screens
  share the look. Verified two ways: `tests/unit/test_scenes_smoke.gd` (structural, in the gate)
  and `scripts/verify_visual.sh` (pixel invariants, wired into `scripts/test.sh`);
  `scripts/screenshot.sh` renders PNGs for human review.
- **Overworld map redesign: Deepening Trail foundation built (ADR-0001, slice A).**
  The old radial danger heatmap (safe center, hot edges, corner exit) is gone.
  `OverworldTierLayout.tier_for_cell` now buckets by **depth** along the vertical
  travel axis (`depth_ratio`: near/bottom row = 0.0 safest, far/top row = 1.0 hottest;
  every column in a row shares the same depth, so danger reads as bands, not a ring).
  The player spawns at `camp_cell` (centered on the near/bottom edge) instead of map
  center; `exit_cell` now returns an on-trail tile in the deepest band (top row, at
  `trail_x_for_row(0, ...)`) instead of the top-right corner — the existing pulsing
  exit marker just tracks whatever `exit_cell` returns, unchanged. A winding **trail**
  spine (`trail_x_for_row`, a bounded sine anchored to the camp's x) is painted as a
  cosmetic dirt-tinted tile blend (`OverworldTileset` trail row) from camp to portal;
  it's visual only and does not change the tier under it. `EncounterSystem`/gauge math
  and the tier-bucketing call shape are untouched — only the cell→ratio meaning changed.
  `scripts/verify_visual.sh`'s overworld invariant now checks red toward the top and
  green toward the bottom. **Points-of-interest overlay built (slice B):** `PoiLayout`
  (pure, seeded, unit-tested) places camp/portal/den/forage/cache/landmark markers
  banded by depth thirds and trail proximity; `overworld_screen.gd` renders them as
  code-drawn tinted circles above the tilemap and multiplies the tier's `gauge_rate`
  when the player is on/adjacent to a den, feeding the boosted params into the
  unchanged `EncounterSystem.tick`. **Per-zone tier tables + band identity built
  (slice B and C both complete):** `data/tiers/cinder_dunes.json` and
  `frostpeak_ridge.json` now exist alongside Verdant Fields', each zone's
  `data/zones/*.json` carries a `palette` (3-stop hex safe/mid/hot) and `band_names`
  (shallow→deep terrain labels, e.g. Cinder Dunes: Dunes→Ashflats→Emberfield→Magma
  Rim; Frostpeak Ridge: Snowfield→Ice Shelf→Glacier→Summit), validated by `ZoneDef`.
  `OverworldTileset.build` paints from the active zone's palette
  (`OverworldTileset.gradient_color`) instead of hardcoded SAFE/MID/HOT constants,
  falling back to Verdant's original colours (`DEFAULT_PALETTE`) when none is
  supplied; the hot-region strip in `overworld_screen.gd` surfaces the current band
  name. Design pitch + mockups: the "Hunting Grounds" artifact.
- **Field tiles stay procedural placeholder:** overworld tiles are per-tier colour
  squares with shade jitter (`OverworldTileset`, green→olive→red toward the hot corner).
  The player is a Gen-4-style humanoid **walk sheet** (`assets/sprites/player_ethan.png`,
  a 4×4 grid of 64×64 frames: rows DOWN/UP/LEFT/RIGHT, cols a 4-frame walk cycle).
  `overworld_screen.gd` region-slices it, picks the facing row from the movement vector
  (dominant axis) and cycles the walk columns while moving (`WALK_FPS = 8`), holding the
  idle column when still; nearest-filtered, scaled `1.35×`, feet-anchored via a `-19` y
  offset. Combat also shows the hunter: `combat_screen.gd` drops his down-idle frame in as
  a small "YOU" avatar above the player HP bar (built in code from an `AtlasTexture`
  region, no scene edit). **This is a temporary placeholder (a repurposed reference sprite)
  to be swapped before any public release.** Monster sprites and weapon icons are real
  AI-generated art; tiles have no hand-authored sprites yet.
- **Weapon-class differentiation partially live.** Great Sword / Dual Blades / Hammer
  have distinct attack patterns in `CombatResolver` (charge / demon-meter / stagger-stun)
  and, now that the reflex outcome is authoritative, they affect who wins. Part-break
  *targeting* from combat is still specced-not-built.
- **iOS export deferred** (feature-complete milestone). Develop + verify headless on
  Linux/desktop.

## Conventions

- **Issue tracker:** GitHub Issues via `gh`. See `docs/agents/issue-tracker.md`.
  Triage labels in `docs/agents/triage-labels.md`.
- **Autonomous build:** the Ralph loop drives issues to green (`.ralph/`). Opus plans,
  Sonnet executes. The test gate above is the loop's verification.
- **Data-driven:** no hardcoded content in scripts; add JSON under `data/` and let
  validation catch bad data.
- **Domain vocabulary:** use the glossary terms below in issues, tests, and code.

## Glossary

- **Run / Expedition** — one Lv.1-to-reset cycle. **Hunt** — one fight; a run has ~10.
- **Zone** — a themed region with a level band and connections. **Tier** — a danger
  bucket within a zone's overworld, banded by depth along the travel axis (near edge
  safe, far edge hot). **Camp** — the near-edge spawn tile. **Portal / exit cell** —
  the on-trail tile in the deepest band that travels to the connected zone.
- **Encounter gauge** — fills as you walk hot tiers; on full it spawns a fight.
- **Chip floor** — the unavoidable fraction of a monster hit that lands regardless of
  dodge skill; what makes far-stronger monsters a hard stat wall.
- **Big** — the universal big-number type. **Essence** — permanent currency = f(peak
  level), banked only on a non-dead run. **Companion** — one captured monster giving a
  passive buff (not a party). **Part-break** — breaking a monster part to boost that
  part's drop. **Bank / Forfeit** — retreat or hunt-exhaustion banks the haul; death
  forfeits it (crafted gear always survives).
