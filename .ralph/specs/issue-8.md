# Crafting + inventory + rarity rolls

> GitHub issue #8 | Labels: ready-for-agent, P1 | https://github.com/taigamura/infinity-hunter/issues/8

## What to build
`CraftingSystem` + `Inventory` (`src/systems/`): fixed recipes consume materials to produce gear; crafted gear rolls a rarity tier (Common/Uncommon/Rare/Epic) applying stat multipliers -> instanced gear objects with rolled stats. Inventory holds instanced gear + stackable material/consumable counts.

## Acceptance criteria
- [ ] A recipe with sufficient mats crafts the item and consumes the mats; insufficient mats is rejected
- [ ] Crafted gear is an instance with a rolled rarity tier + corresponding stat multiplier
- [ ] Inventory stores instances (gear) and counts (materials/consumables) and persists via #5
- [ ] Unit tests: successful craft, insufficient-mats rejection, rarity roll distribution, inventory add/remove

## Blocked by
- #2
- #7

## Definition of done
- All acceptance criteria met; `./scripts/test.sh` exits 0 (headless gate green); one commit; revert-and-report if you cannot finish cleanly. Follow `.ralph/AGENT.md` conventions (GDScript, `Big` type, data-driven JSON, single logic test seam).

