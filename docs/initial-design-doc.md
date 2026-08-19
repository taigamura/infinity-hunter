# Offline iOS Game — Implementation Handoff

## 1. Project Summary

Create an **offline iOS RPG** inspired by:

- **Inflation RPG** — limited encounters per run, huge level jumps, map routing, reincarnation/reset loop.
- **Tap Titans** — fast combat, escalating numbers, prestige-style progression.
- **Monster Hunter** — many weapon classes, armor sets, materials, crafting, monster part breaks, build variety.
- **Pokémon Black/White** — lively pixel/dot-style animated monster sprites.
- **Pokémon-style capture** — weakened monsters can be captured and brought as a companion for one run.

The game should **not** become a full monster-collection RPG. The focus remains:

> **Hunt → level explosively → gather materials → craft gear → capture a useful companion → push farther → reset → repeat.**

---

## 2. Core Design Pillars

1. **Short, replayable runs**
   - Each expedition has a limited number of hunts/encounters.
   - Target run length: roughly 5–15 minutes.

2. **Huge progression jumps**
   - Levels should rise rapidly.
   - Taking risks against stronger monsters should create dramatic XP gains.

3. **Buildcrafting**
   - Many weapon types.
   - Many armor pieces and sets.
   - Skills, elemental bonuses, crit builds, defense builds, farming builds, etc.

4. **Risk vs reward**
   - Players choose which monsters to challenge and which zones to enter.
   - Stronger monsters can accelerate a run but may end it.

5. **Permanent meta-progression**
   - Player level resets between runs.
   - Gear, materials, bestiary, captures, unlocks, and selected permanent bonuses persist.

6. **Pixel/dot aesthetic**
   - Retro pixel world.
   - Animated monster sprites inspired by Pokémon Black/White.

---

## 3. Main Game Loop

### Before Run

Player selects:

- Weapon
- Armor pieces / armor set
- One captured monster companion
- Optional consumables or loadout modifiers

### During Run

1. Start at **Lv.1** or a permanently upgraded starting level.
2. Enter the overworld.
3. Move between zones with visible difficulty ranges.
4. Choose monsters to fight.
5. Fight in short battles.
6. Gain large amounts of XP.
7. Collect monster materials.
8. Break monster parts for targeted drops.
9. Optionally capture sufficiently weakened monsters.
10. Push into progressively harder zones.
11. Continue until:
    - Hunt limit is exhausted,
    - player dies,
    - or player voluntarily ends the run.

### End of Run

- Player level resets.
- Gear remains.
- Materials remain.
- Captured monsters remain.
- Bestiary progress remains.
- Permanent progression currency/bonuses remain.
- Player begins another run with a stronger build.

---

## 4. Expedition / Hunt Limit

Each run should have a fixed number of encounters.

Initial target:

- **20–30 hunts per expedition**

Each normal encounter consumes one hunt.

This creates the core optimization puzzle:

> “What is the strongest monster I can safely kill right now?”

Example:

| Monster | Level | Reward | Risk |
|---|---:|---:|---|
| Mossfang | 80 | +40 levels | Low |
| Stoneback | 250 | +300 levels | Medium |
| Ember Drake | 1,500 | +3,000 levels | High |

The player should often be tempted to skip safe monsters and gamble on stronger ones.

---

## 5. Combat

Combat should be **simple, responsive, and short**, not a full Monster Hunter action simulation.

Target battle length:

- Normal monster: **5–15 seconds**
- Elite/boss: **15–45 seconds**

### Basic Inputs

Potential controls:

- **Tap** — basic attack / combo
- **Hold** — charge or heavy attack
- **Swipe** — dodge / special weapon interaction
- **Tap monster body parts** — target specific weak points or breakable parts

Exact controls can differ per weapon class.

---

## 6. Weapon System

Weapons are a major pillar.

Start with fewer classes for MVP, but architecture should support many.

Potential classes:

- Great Sword
- Long Sword
- Sword & Shield
- Dual Blades
- Hammer
- Hunting Horn
- Lance
- Gunlance
- Switch Axe
- Charge Blade
- Insect Glaive
- Bow
- Light Bowgun
- Heavy Bowgun

These do **not** need to reproduce Monster Hunter exactly.

Each class should instead have a clear lightweight identity.

Examples:

### Great Sword
- Hold to charge.
- Release for huge damage.
- Timing-focused.

### Dual Blades
- Rapid taps.
- Builds a frenzy/demon meter.
- High attack speed.

### Hammer
- Slower attacks.
- High stun and head-break damage.

### Lance
- Defensive.
- Counter mechanic.
- Good survivability.

### Bow
- Charge and release.
- Strong elemental scaling.
- Better targeting of weak points.

---

## 7. Armor and Buildcrafting

Armor should be inspired by Monster Hunter.

Slots:

- Head
- Chest
- Arms
- Waist
- Legs

Each armor piece may provide:

- Defense
- Elemental resistance
- Skill points
- Set bonuses
- Special effects

Example skills:

- Critical Eye
- Attack Boost
- Fire Resistance
- Partbreaker
- Capture Master
- XP Boost
- Material Finder
- Weakness Exploit
- Last Stand
- Companion Bond

The player should make meaningful tradeoffs between:

- Raw power
- Survivability
- XP optimization
- Farming
- Capture builds
- Elemental builds

---

## 8. Crafting

Monsters drop materials.

Examples:

- Fang
- Hide
- Scale
- Horn
- Tail
- Core
- Gem
- Rare organ

Weapons and armor require specific monster materials.

This creates the persistent loop:

> Hunt monster → collect parts → craft equipment → hunt stronger monster.

Rare materials should make specific monsters worth farming.

---

## 9. Monster Part Breaking

Large monsters should have breakable areas such as:

- Head
- Horns
- Wings
- Tail
- Legs
- Shell

Targeting a part may:

- Reduce overall DPS efficiency
- Increase chance of a specific material
- Disable monster attacks
- Apply stagger/stun
- Unlock rare drops

Example:

**Ember Drake**

- Horn break → Ember Horn
- Tail sever → Drake Tail
- Wing break → Wing Membrane

This adds Monster Hunter flavor without requiring complicated combat.

---

## 10. Monster Capture System

Capture is reintroduced but remains a **support mechanic**, not the main game.

### Capture Flow

1. Fight monster.
2. Reduce it below a health threshold.
3. A **Capture** option becomes available.
4. Player attempts capture instead of killing it.

Capture may consume:

- Trap
- Capture item
- Hunt resource
- Or simply carry a success probability.

### Captured Monsters

Captured monsters are stored permanently.

Before each run, the player can choose **one companion**.

The companion provides buffs/passives rather than becoming a full Pokémon battle unit.

Examples:

### Ember Drake
- +15% fire damage
- +5% crit damage

### Mossfang
- +12% XP
- +5% movement speed

### Iron Turtle
- +20% defense
- Prevent lethal damage once per run

### Treasure Slime
- +20% material drop rate
- +2% rare material chance

### Thunderhawk
- +10% attack speed
- Chance to stun enemies

This turns monsters into another buildcrafting layer.

---

## 11. Companion Progression

Potential later features:

- Companion rarity
- Size/crown
- Traits
- Bond level
- Passive skill rolls
- Species-specific abilities

Avoid full party combat for the MVP.

The intended design is:

> **One monster = one meaningful passive companion choice per run.**

---

## 12. Bestiary

Every monster gets a bestiary entry.

Track:

- Seen count
- Kill count
- Capture count
- Largest size
- Smallest size
- Known drops
- Broken parts
- Habitats
- Element
- Weaknesses
- Rare variants

Possible completion goals:

- Gold crown largest
- Gold crown smallest
- Rare color variant
- All drops discovered
- Capture completed

The bestiary provides Pokémon-like collection satisfaction without making collecting the main loop.

---

## 13. Monster Variants

Use procedural/modular variants to increase content volume.

Possible modifiers:

- Giant
- Tiny
- Enraged
- Scarred
- Ancient
- Corrupted
- Albino
- Prismatic
- Elemental mutation

Example:

**Giant Enraged Emberfang**

Modifiers:

- +60% HP
- +40% damage
- +35% XP
- Higher rare-material chance

This lets base monsters stay relevant.

---

## 14. World Structure

Use a **2D pixel overworld**.

Example progression:

```text
Grasslands
Lv. 1–500
   |
   +---- Forest
   |     Lv. 300–5,000
   |
   +---- Swamp
         Lv. 800–12,000
             |
             +---- Ancient Ruins
             |     Lv. 8,000–100,000
             |
             +---- Volcano
                   Lv. 30,000–1,000,000
```

Players should see areas that are currently far too dangerous.

This creates long-term goals.

A huge monster may appear near the starting area at level:

**9,999,999,999**

The player gets destroyed early but eventually becomes capable of returning and killing it.

---

## 15. Progression / Reincarnation

At the end of a run:

### Resets

- Character level
- Temporary run buffs
- Temporary companion effects
- Expedition state

### Persists

- Weapons
- Armor
- Materials
- Captured monsters
- Bestiary
- Unlocked areas
- Crafting recipes
- Permanent upgrade currency

Potential permanent upgrades:

- Starting level
- XP multiplier
- Starting hunt count
- Crit chance
- Rare monster chance
- Material drop rate
- Capture chance
- Companion effectiveness

Avoid excessive permanent upgrades that trivialize gear/build decisions.

---

## 16. Visual Direction

Target aesthetic:

- Pixel/dot-style graphics
- Retro JRPG overworld
- Detailed animated monster sprites
- Large readable damage numbers
- Clean modern UI layered over pixel art

### Monster Sprite Animation

Reference feeling:

**Pokémon Black/White animated battle sprites**

Use a combination of:

- Small sprite sheets
- 3–8 key frames
- Body-part transforms
- Position offsets
- Rotation
- Squash/stretch
- Idle breathing
- Tail movement
- Wing movement
- Hit reaction
- Attack frames

Monsters should feel alive even when idle.

---

## 17. Asset Production Strategy

Do **not** depend on hundreds of fully hand-animated unique monsters initially.

Prefer modular generation.

Possible monster definition:

```json
{
  "id": "emberfang",
  "body": "wolf_03",
  "head": "reptile_02",
  "horns": "curved_01",
  "tail": "flame_02",
  "palette": "ember",
  "size": 1.25,
  "element": "fire"
}
```

Potential pipeline:

```text
AI generates monster concept/data
        ↓
Reusable sprite components
        ↓
Palette / trait variants
        ↓
Automated sprite assembly
        ↓
Manual polish for important monsters/bosses
```

Blender is **not required** for the initial implementation.

A 2D sprite pipeline is preferable.

---

## 18. Offline Requirement

The game should work **fully offline**.

Do not require:

- Accounts
- Servers
- Online inventory
- Live-service systems
- Cloud save for basic functionality

Store locally:

- Save data
- Inventory
- Bestiary
- Captured monsters
- Progression
- Settings

Cloud backup can be considered later but must not be necessary.

---

## 19. Recommended Technical Direction

Target:

- **iOS first**

Possible engines:

### Preferred: Godot

Reasons:

- Good 2D workflow
- Lightweight
- Sprite animation support
- Data-driven content works well
- Exports to iOS
- Easier for AI coding agents to reason about than a giant native project

### Alternative: Unity

Advantages:

- Strong ecosystem
- Mature tooling
- Lots of plugins

Disadvantages:

- Heavier project
- More overhead

### Native Swift / SpriteKit

Possible, especially for a pure 2D iOS game.

Advantages:

- Native
- Lightweight

Disadvantages:

- Smaller game-dev ecosystem
- More systems need to be built manually

Initial recommendation:

> **Godot unless there is a strong reason to stay native.**

---

## 20. Data-Driven Architecture

Avoid hardcoding monsters/items.

Use JSON/resources/tables for:

### Monster

```text
id
name
sprite
level
hp
attack
defense
element
weakness
xpReward
captureThreshold
captureRate
drops[]
breakableParts[]
traits[]
habitat
```

### Weapon

```text
id
name
weaponClass
attack
element
crit
skills[]
recipe[]
rarity
```

### Armor

```text
id
name
slot
defense
resistances
skills[]
setId
recipe[]
```

### Companion

```text
monsterId
passives[]
trait
size
rarity
```

This is important because large portions of future content can then be generated automatically.

---

## 21. MVP Scope

Do **not** build the full vision first.

### MVP should contain:

- 1 overworld
- 3 zones
- 8–12 monsters
- 3 weapon classes
- ~15 armor pieces
- Basic crafting
- XP / leveling
- 10 hunts per run
- Run reset
- Permanent progression
- Basic material drops
- 1 breakable monster part
- Capture system
- 1 companion slot
- Animated pixel monster sprites
- Local save

No multiplayer.

No online features.

No massive procedural world.

No hundreds of monsters.

---

## 22. First Prototype

The absolute first prototype should be ugly.

Use rectangles/placeholders.

Implement only:

```text
Start Lv.1
   ↓
Choose monster
   ↓
Fight
   ↓
Gain huge XP
   ↓
Choose harder monster
   ↓
10 total encounters
   ↓
Reset
   ↓
Receive permanent bonus
   ↓
Repeat
```

Test whether this is fun **before** investing heavily in art/content.

Once the progression loop works, add:

1. Weapon differences
2. Equipment
3. Materials
4. Crafting
5. Monster parts
6. Captures
7. Companions
8. World navigation
9. Pixel art and animation

---

## 23. Core Design Question to Protect

Throughout implementation, avoid drifting into:

- Full Monster Hunter combat
- Full Pokémon combat
- Idle-only Tap Titans gameplay
- Generic roguelike combat
- MMO/live-service design

The unique identity should remain:

> **A fast offline pixel hunting RPG where each expedition is an optimization puzzle: choose your fights, grow from Lv.1 into absurd power, craft monster gear, bring one captured monster companion, push farther than last time, then reset and do it again.**

---

## 24. Immediate Implementation Tasks

Another AI/dev agent should begin with:

1. Create the project skeleton.
2. Implement data models for monsters, weapons, armor, and runs.
3. Implement XP and rapid level scaling.
4. Implement the limited-hunt expedition system.
5. Create a placeholder battle screen.
6. Add 3 test monsters at dramatically different levels.
7. Implement death and run completion.
8. Implement reset + one permanent upgrade currency.
9. Implement local save.
10. Build a minimal overworld/monster selection screen.

Only after this loop is playable should work begin on crafting, captures, companions, and final art.
