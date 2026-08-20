# Infinity Hunter

**An offline pixel hunting RPG.** Hunt monsters, explode from Level 1 into absurd
power in a single run, craft gear from the parts you break, capture a companion, push
a little farther than last time, then reset and repeat. No account, no server, no
grind: every expedition is a short, self-contained optimization puzzle.

Each **run** starts at Level 1 with your persistent gear. You pick an unlocked zone,
roam a walkable overworld, and fight monsters in a real-time dodge HP-race. Killing a
monster far above your level dumps enough XP to cross many level thresholds at once,
so power snowballs fast. But you get only about ten hunts, and dying forfeits
everything you gathered that run: the core decision is always **push deeper or cash
out.** Between runs your level resets, but gear, materials, captures, bestiary,
unlocks, and a permanent upgrade currency (essence) carry over, so you start a little
stronger each time.

## Design canvas (visual target)

Screen mockups (Launch, Overworld, Combat) and the full run-loop diagram — the
**visual target** the UI is being themed toward, not a screenshot of the current
build:

**https://claude.ai/code/artifact/b7dc6b5b-99de-4211-bb1a-f4ad5443e2fa**

The mockups match the real UI *structure* and use the game's actual tier colors and
monster sprites, but the running game is not yet skinned to them — that theming pass
is tracked in issue #27 (slices #28–#31). Until it lands, the live HUD uses default
Godot widgets; the canvas shows where it is headed.

## The loop

```
Launch (pick zone + gear, start Lv.1)
   -> Overworld (roam danger tiers; an encounter gauge fills)
   -> Combat (real-time dodge HP-race)
        -> Victory: XP burst, drops, part-breaks, optional capture -> push on (-1 hunt)
        -> Death: forfeit the run's unbanked haul (crafted gear is safe)
   -> Bank on retreat or when hunts run out -> earn essence -> spend on upgrades
   -> next run starts stronger
```

## Technology

- **Engine / language:** Godot 4 (4.7), GDScript only, no C#. Portrait, iOS-first,
  developed and verified headless on desktop Linux. iOS export is a deferred
  feature-complete milestone.
- **Layered architecture with one test seam:** a single `GameState` autoload owns
  loaded content, the save, and the live run. All game rules live in pure logic
  **systems** (`src/systems/`) with no scene or rendering dependency, so they are
  fully headless-testable. UI scenes (`src/ui/`) are thin shells over those systems.
- **Data-driven content:** monsters, weapons, armor, zones, companions, and materials
  are per-entity JSON files under `data/`, loaded into typed def classes with
  load-time validation that fails loudly on bad data. No content is hardcoded in
  scripts.
- **Big numbers:** every quantity (HP, XP, damage, level, essence) routes through a
  single `Big` type, float-backed today and swappable to a bignum later without
  touching call sites, so the game can reach Lv.9,999,999,999-scale monsters.
- **Robust local saves:** atomic JSON writes to `user://` (temp file, fsync, rename),
  a `.bak` rollback copy, a version stamp with a sequential migration path, and
  debounced autosave. Fully offline; no cloud required.
- **Art pipeline:** frame-by-frame animated sprites (idle / attack / hit) against a
  fixed sheet spec. The monster roster is AI-generated pixel art; world and HUD art is
  still placeholder while systems are built.

## Development

```bash
./scripts/test.sh    # headless test gate: exit 0 = all logic modules pass
```

The test suite (`tests/unit/`) drives the logic systems directly and is the
verification gate for every change. See `tests/unit/test_big.gd` for the reference
test pattern.

## Docs

- **`CONTEXT.md`**: central design doc covering architecture, module map, run loop,
  content, and current-state deltas. Start here.
- **`docs/PRD.md`**: the full resolved product design.
- **`docs/adr/`**: architecture decision records (added as decisions get resolved).
- **`CLAUDE.md`** and **`docs/agents/`**: how the agent tooling works with this repo.
