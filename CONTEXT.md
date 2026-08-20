# CONTEXT.md — Infinity Hunter

> **Read this first every session.** It is the durable orientation doc: the game's
> identity, architecture, module map, run loop, content, and the current build's
> deltas from the PRD. Prefer it over re-scanning the codebase. When it drifts from
> the code, fix the code or fix this doc: it is meant to stay true.
>
> Deep specs live elsewhere: `docs/PRD.md` (full resolved design), `docs/adr/`
> (decisions, lazily added), and the visual design canvas linked in the README.

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
| `OverworldTierLayout` | Buckets a tile into a danger tier by distance from map center (center safe, edges hot). Defines the corner `exit_cell`. |
| `OverworldMovement` | Joystick + keyboard → clamped character step. |
| `DropSystem` | Weighted drop tables; part-break sharply boosts/guarantees that part's material. |
| `CraftingSystem` | Fixed recipes consume materials → instanced gear rolling a rarity tier (Common/Uncommon/Rare/Epic). |
| `Inventory` | Instanced gear (rolled stats) + stackable materials + consumables (Traps). |
| `CaptureSystem` | Below `capture_hp_threshold`, spend a Trap to capture: grants a companion + materials, forfeits the kill's XP. |
| `SkillSystem` | Builds the armor/set-bonus skill effect profile fed into combat. |
| `Bestiary` | Per-monster seen/kill/capture counts, discovered drops, broken parts. |
| `MetaProgression` | Essence = f(peak level), banked on a non-dead run; spend on capped global upgrades (see below). |
| `SaveManager` | Atomic JSON save to `user://` (temp→fsync→rename), `.bak` rollback, debounced autosave, versioned with sequential migration. `CURRENT_VERSION = 2`. |
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
  runs the reflex phase, then `RunState.resolve_fight` is the authoritative outcome
  (spends 1 hunt, awards XP/levels/drops, or kills the run). Combat never changes
  scenes: it emits `combat_finished` and the overworld tears down.
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
- **Tiers** (`data/tiers/`): only `verdant_fields.json` exists (tiers 0/1/2 with
  `gauge_rate` 6/10/16). Cinder Dunes / Frostpeak have no tier table yet.
- **Monsters** (`data/monsters/`, 11): slime, rock_lizard, mossback_turtle,
  thistle_sprite, **voidmaw_devourer** (Lv 9,999,999,999 dragon stat-wall in Verdant
  Fields), ember_wolf, sand_scorpion, magma_golem, frost_wyrm, thunder_stag,
  glacier_troll. Sprite sheets in `assets/sprites/` (256×192, 64×64 frames, real
  AI-generated art).
- Weapons, armor, armor_sets, companions, materials: `data/*` (loaded but inventory
  is empty on a fresh save until crafted).
- **Weapon icons** (9, one per weapon) in `assets/weapons/<id>.png` (32×32, real
  AI-generated art via img2img from tinted silhouette templates). `WeaponIcons.for_id`
  (`src/ui/weapon_icons.gd`) loads them by the same per-id convention as monster
  sheets; shown in the launch weapon dropdown and inventory gear/recipe rows. Armor
  has no icons yet (helper returns null, slot stays empty).

## Current state vs PRD (deltas that matter)

- **Node-map retired (#23).** The PRD's branching `NodeMap` was replaced by the
  walkable overworld (#20–22). `RunState.node_map` and `NodeMap` are gone. Traversal
  is now: roam tiles → encounter gauge fires → combat; travel deeper via the exit cell.
- **Art is placeholder** except monsters and weapons: overworld tiles are solid-color
  per-tier squares built at runtime (`OverworldTileset`, green→red), the player is a
  yellow square, HUD is default Godot widgets. Monster sprites and weapon icons are
  real AI-generated art.
- **Weapon-class feel not built.** Great Sword / Dual Blades / Hammer differentiation
  and part-break targeting from combat are specced but not implemented; combat is the
  generic dodge race.
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
  bucket within a zone's overworld (center safe, edges hot). **Exit cell** — the hot
  corner tile that travels to the connected zone.
- **Encounter gauge** — fills as you walk hot tiers; on full it spawns a fight.
- **Chip floor** — the unavoidable fraction of a monster hit that lands regardless of
  dodge skill; what makes far-stronger monsters a hard stat wall.
- **Big** — the universal big-number type. **Essence** — permanent currency = f(peak
  level), banked only on a non-dead run. **Companion** — one captured monster giving a
  passive buff (not a party). **Part-break** — breaking a monster part to boost that
  part's drop. **Bank / Forfeit** — retreat or hunt-exhaustion banks the haul; death
  forfeits it (crafted gear always survives).
