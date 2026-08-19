# PRD — Infinity Hunter (MVP)

> Offline iOS pixel hunting RPG. Resolved design from the grilling session. This is the
> durable spec the Ralph loop and issue breakdown work from. Source vision:
> `docs/initial-design-doc.md`.

## Problem Statement

A player wants a short-session, offline mobile RPG that delivers the thrill of hunting
monsters, exploding from Level 1 into absurd power in a single run, crafting gear from monster
parts, and pushing a little farther each time — without the grind, live-service hooks, or
account/server requirements of typical mobile games. Existing games each hit one note (Inflation
RPG's level jumps, Tap Titans' escalation, Monster Hunter's crafting, Pokémon's capture) but none
combine them into a fast, replayable optimization puzzle that works fully offline.

## Solution

A run-based hunting RPG built in Godot 4 (GDScript), iOS-first but developed and verified on
desktop/headless Linux. Each expedition: pick an unlocked zone, start at Level 1 with your
persistent gear, and traverse a node-map choosing which monsters to fight. Combat is a
skill-based real-time dodge/HP-race. Killing monsters far above your level dumps huge XP (many
levels at once). You gather materials, break parts for targeted drops, optionally spend a Trap to
capture a weakened monster as a passive companion, and decide each step whether to push deeper or
cash out — because **dying forfeits the run's haul**. Between runs, your level resets but gear,
materials, captures, bestiary, unlocks, and a modest permanent-upgrade currency (essence) persist,
so every run starts a little stronger.

The unique identity to protect: **a fast offline pixel hunting RPG where each expedition is an
optimization puzzle — choose your fights, grow from Lv.1 into absurd power, craft monster gear,
bring one captured companion, push farther than last time, then reset and repeat.**

## User Stories

1. As a player, I want to launch an expedition into an unlocked zone, so that I can choose how much early-game to skip.
2. As a player, I want to start each run at Level 1 with my persistent gear, so that my crafted equipment makes the climb faster over time.
3. As a player, I want to see a node-map of upcoming monster choices with their level, reward, and risk, so that I can plan an optimal path.
4. As a player, I want each fight to spend one of my limited hunts, so that I must choose fights deliberately.
5. As a player, I want to pick between a safe monster and a much stronger one, so that I can gamble for explosive XP.
6. As a player, I want combat to be a short real-time dodge/attack HP-race, so that my reflexes matter.
7. As a player, I want to dodge most incoming damage but still take unavoidable chip proportional to the monster's power, so that vastly stronger monsters remain lethal no matter my skill.
8. As a player, I want each weapon class to play differently (Great Sword charge, Dual Blades rapid-tap meter, Hammer stun), so that my weapon choice changes how I fight.
9. As a player, I want killing a monster to grant XP that can cross many level thresholds at once, so that big gambles feel explosive.
10. As a player, I want my damage and survivability to scale with my level, so that leveling within a run visibly empowers me.
11. As a player, I want elemental matchups (Fire/Water/Earth/Thunder/Ice ring, Neutral, rare Dragon), so that I can build around a monster's weakness.
12. As a player, I want monsters to drop materials from weighted tables, so that rarer materials feel valuable.
13. As a player, I want to break specific monster parts (e.g. a head) to boost that part's material drop, so that I can farm targeted drops.
14. As a player, I want to craft weapons and armor from specific materials via fixed recipes, so that hunting specific monsters has a clear goal.
15. As a player, I want crafted gear to roll a rarity/quality tier, so that I can re-craft chasing better rolls.
16. As a player, I want armor pieces and set bonuses that grant skills (Crit, Attack Boost, resistances, XP Boost, Partbreaker, Capture Master, ...), so that I can build for power, survivability, farming, or capture.
17. As a player, I want to weaken a monster below an HP threshold and spend a Trap to capture it, so that I gain a companion at the cost of that kill's XP burst.
18. As a player, I want to choose one captured companion before a run for a passive buff, so that companions are another buildcrafting layer, not a party.
19. As a player, I want a bestiary that tracks what I've seen, killed, captured, and the drops/parts discovered, so that I get collection satisfaction without collecting being the main loop.
20. As a player, I want dying mid-run to forfeit the materials/essence I gathered that run (but keep already-crafted gear), so that "push or cash out" is a real decision.
21. As a player, I want to voluntarily retreat to bank my haul, so that I can lock in a good run.
22. As a player, I want to complete a run when my hunts are exhausted and bank everything, so that a full run is rewarding.
23. As a player, I want to earn essence proportional to the peak level I reached, banked on a successful run, so that progress compounds across runs.
24. As a player, I want to spend essence on modest permanent upgrades (starting level, XP multiplier, hunt count, crit, drop rate, capture chance, companion effectiveness), so that I smooth the early grind without trivializing gear.
25. As a player, I want to see zones far too dangerous for me (up to a near-spawn Lv.9,999,999,999 monster), so that I have long-term goals.
26. As a player, I want all progress stored locally with no account/server, so that the game works fully offline.
27. As a player, I want my save to survive crashes and app updates, so that I never lose my permanent progression.
28. As a player, I want large, readable damage/level numbers, so that the escalation feels satisfying.
29. As a player, I want animated monster sprites that feel alive even when idle, so that the world has character.
30. As a returning player, I want each run to feel a bit stronger than the last, so that I'm motivated to keep pushing farther.

## Implementation Decisions

**Engine / language:** Godot 4.7, GDScript only (no C#). Developed and verified via desktop/Linux
and headless export; iOS export (Godot → Xcode → Mac build server → TestFlight) is a deferred
feature-complete milestone. Touch controls designed in from the start; desktop uses mouse/keyboard
equivalents.

**Numbers (`Big`):** All game quantities (HP, XP, damage, level, essence, thresholds) route through
a single `Big` type (`src/core/big.gd`), float-backed for the MVP (safe to ~9e15, above stated
ranges) and upgradeable to a mantissa/exponent bignum later without touching call sites.

**Data-driven content:** Monsters, weapons, armor, zones, companions, and materials are per-entity
JSON files under `data/`, loaded into typed def classes (`MonsterDef`, `WeaponDef`, `ArmorDef`,
`ZoneDef`, `CompanionDef`, `MaterialDef`) with load-time validation that fails loudly on bad data.
No hardcoded content in scripts.

**Modules (game logic, headless-testable — the single test seam):**
- `RunState` — the active expedition: current zone, node-map, hunt counter, level/XP, run HP,
  gathered (unbanked) materials + essence, chosen weapon/armor/companion. Owns push/retreat/death
  banking rules.
- `XpCurve` — exponential level thresholds; converts an XP award into a (levels-gained, carry)
  result that can cross many thresholds at once. Level → power scaling lives here or in a `Stats`
  helper.
- `NodeMap` — generates a run's branching node graph for a zone (monster choices per step, travel
  nodes to deeper connected zones), with visible level/reward/risk per option.
- `CombatResolver` — real-time dodge/HP-race model as pure logic: attacker/defender stats, dodge
  success reduces incoming damage, an unavoidable chip floor = f(monster power) always applies,
  weapon-class behavior modulates damage/speed, elemental multiplier applied. Produces
  tick/step outcomes the UI renders; the win/loss and numbers are deterministic given inputs +
  input timings, so they are unit-testable independent of rendering.
- `Elements` — 6-element model: Fire/Water/Earth/Thunder/Ice ring (weak ×1.5, resist ×0.66),
  Neutral (×1.0), rare Dragon (strong vs all, gated to high-tier). Pure matchup function.
- `DropSystem` — weighted drop tables; part-break sharply boosts/guarantees that part's material.
- `CraftingSystem` — fixed recipes consume materials to produce gear; crafted gear rolls a rarity
  tier (Common/Uncommon/Rare/Epic) applying stat multipliers. Produces instanced gear objects.
- `Inventory` — instanced gear (with rolled stats/affixes) + stackable material counts +
  consumables (Traps).
- `CaptureSystem` — capture available below an HP threshold; consumes a Trap; success grants a
  companion + materials (possibly capture-only) but forfeits the kill's XP burst.
- `Bestiary` — per-monster seen/kill/capture counts, discovered drops, broken parts.
- `MetaProgression` — essence = f(peak level reached), banked on successful run end; spend on a
  fixed set of modest global upgrades; enforces gear-primacy (upgrades never dominate).
- `SaveManager` — see below.

**Combat model (decided):** skill-based real-time dodge/attack. The monster attacks back and the
player's HP bar drains; a fight is a race. Skilled dodging avoids most damage, but an unavoidable
chip floor proportional to the monster's power always lands — so a vastly stronger monster wins the
race regardless of skill, keeping the level spine intact (the near-spawn 1e10 monster is a hard
stat wall until stats catch up). Weapon classes: Great Sword (hold-charge-release burst, timed to
openings), Dual Blades (rapid taps build a demon meter → burst DPS), Hammer (slow heavy hits,
builds a stun/stagger bar feeding part-breaks). Monsters have telegraphed attacks with openings.

**Run lifecycle (decided):** start Lv.1 in a chosen unlocked zone with persistent gear → node-map
choices, each fight spends 1 hunt (MVP ~10 hunts/run, tunable) → travel deeper unlocks zones as
future launch options → run ends on hunt exhaustion (bank), voluntary retreat (bank), or death
(**forfeit** unbanked materials + essence; already-crafted gear is safe). Between runs: level and
run buffs reset; gear, materials, captures, bestiary, unlocks, recipes, and essence persist.

**Save format & robustness:** JSON written to `user://`. Atomic write (temp file → fsync →
rename over the real file), keep the previous save as `.bak` for rollback, stamp every save with a
`version` integer and provide a migration path, debounced autosave. Save blob shaped so optional
iCloud sync can be layered later; cloud is never required. Serializes instanced gear (rolled
stats), material/consumable counts, captures, bestiary, unlocks, essence, and permanent upgrades.

**UI/scenes:** thin shells over the logic modules — a zone/launch screen, the node-map, the combat
screen, inventory/crafting, bestiary, and a meta-upgrade screen. Portrait orientation. Large
readable numbers.

**Art pipeline:** frame-by-frame `AnimatedSprite2D` (anims: idle / attack / hit), fed
**placeholder/proxy frames** now against a fixed sheet spec (frame size, anim names, row-major
layout). Polished sheets drop in later with zero code change. MVP: 8–12 monsters, 3 zones.

## Testing Decisions

- **What makes a good test:** assert only external behavior of the logic modules (inputs →
  outputs / state transitions), never private implementation details or rendering. Example:
  "an XP award of N at level L yields the correct levels-gained and carry"; "a fight vs a monster
  3× the player's effective power is lost due to chip"; "capturing consumes a Trap, grants the
  companion, and awards zero XP"; "a save round-trips and a v(n-1) blob migrates to v(n)".
- **Single seam:** the headless test runner (`tests/run_tests.gd`) drives the logic classes
  directly. Run via `./scripts/test.sh` (exit 0 = pass). This is the loop's verification gate.
- **Modules tested:** `Big`, `XpCurve`, `CombatResolver`, `Elements`, `DropSystem`,
  `CraftingSystem`, `CaptureSystem`, `MetaProgression`, `SaveManager` (round-trip + migration),
  `RunState` (banking on retreat/death/completion), `NodeMap` (generation invariants).
- **Prior art:** `tests/unit/test_big.gd` is the reference pattern — `extends
  "res://tests/test_case.gd"`, `test_*` methods, `assert_*` helpers, no global `class_name`
  dependency.
- **Out of test scope (manual only):** dodge/reflex feel, sprite rendering, touch input, iOS
  export.

## Out of Scope (MVP)

- Multiplayer, servers, accounts, cloud saves as a requirement, any live-service systems.
- Full Monster Hunter action combat; full Pokémon party combat; idle-only Tap Titans gameplay;
  generic roguelike combat.
- Hundreds of monsters; massive procedural world; modular runtime sprite assembly.
- Companion depth beyond one passive per captured species (bond level, rarity rolls, size/crown,
  species abilities are deferred).
- Elemental content beyond the 6-element model; weapon classes beyond the 3 MVP archetypes.
- Polished final art; iOS build/signing pipeline (deferred milestone).

## Further Notes

- MVP content targets (section 21 of the design doc): 1 overworld, 3 zones, 8–12 monsters, 3
  weapon classes, ~15 armor pieces, basic crafting, XP/leveling, ~10 hunts/run, run reset,
  permanent progression, material drops, ≥1 breakable part, capture + 1 companion slot, animated
  (placeholder) sprites, local save.
- Balance constants (XP curve base, hunts/run, chip coefficient, rarity multipliers, essence
  formula) are playtest-tuned, not fixed here; expose them as data/constants for easy iteration.
- Rarity tiers default: Common / Uncommon / Rare / Epic with ascending stat multipliers.
- The near-spawn Lv.9,999,999,999 monster is a deliberate long-term goal marker, not MVP-critical
  combat content.
