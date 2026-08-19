# Inventory — stackable material/consumable counts + instanced gear (crafted
# items with rolled stats, see CraftingSystem). Shaped to interop directly
# with SaveManager's state Dictionary (#5): `to_state`/`from_state` round-trip
# the same `materials` / `consumables` / `gear` fields SaveManager persists.
class_name Inventory
extends RefCounted

var materials: Dictionary = {} # material_id -> int count
var consumables: Dictionary = {} # consumable_id -> int count
var gear: Array = [] # [{id, def_id, rolled_stats: {...}}]

var _gear_counter: int = 0

# ---- materials --------------------------------------------------------------

func add_material(material_id: String, count: int = 1) -> void:
	materials[material_id] = int(materials.get(material_id, 0)) + count

# True if the inventory holds at least `recipe`'s required counts.
func has_materials(recipe: Dictionary) -> bool:
	for material_id in recipe:
		if int(materials.get(material_id, 0)) < int(recipe[material_id]):
			return false
	return true

# Atomically consumes `recipe`'s material counts. Returns false (no state
# change) if the inventory does not hold enough of every required material.
func consume_materials(recipe: Dictionary) -> bool:
	if not has_materials(recipe):
		return false
	for material_id in recipe:
		materials[material_id] = int(materials[material_id]) - int(recipe[material_id])
	return true

# ---- consumables --------------------------------------------------------------

func add_consumable(consumable_id: String, count: int = 1) -> void:
	consumables[consumable_id] = int(consumables.get(consumable_id, 0)) + count

func remove_consumable(consumable_id: String, count: int = 1) -> bool:
	if int(consumables.get(consumable_id, 0)) < count:
		return false
	consumables[consumable_id] = int(consumables[consumable_id]) - count
	return true

# ---- gear ---------------------------------------------------------------------

# Creates and stores a new gear instance from `def_id` + rolled stats.
# Instance ids are monotonically assigned so callers never collide.
func add_gear(def_id: String, rolled_stats: Dictionary) -> Dictionary:
	_gear_counter += 1
	var instance := {
		"id": "gear_%d" % _gear_counter,
		"def_id": def_id,
		"rolled_stats": rolled_stats,
	}
	gear.append(instance)
	return instance

func get_gear(instance_id: String) -> Variant:
	for instance in gear:
		if instance["id"] == instance_id:
			return instance
	return null

func remove_gear(instance_id: String) -> bool:
	for i in range(gear.size()):
		if gear[i]["id"] == instance_id:
			gear.remove_at(i)
			return true
	return false

# ---- save interop (#5) ---------------------------------------------------------

# Builds an Inventory from a SaveManager state Dictionary (or any Dictionary
# with the same `materials`/`consumables`/`gear` shape).
static func from_state(state: Dictionary) -> Inventory:
	var inv := Inventory.new()
	inv.materials = (state.get("materials", {}) as Dictionary).duplicate(true)
	inv.consumables = (state.get("consumables", {}) as Dictionary).duplicate(true)
	inv.gear = (state.get("gear", []) as Array).duplicate(true)
	var max_counter := 0
	for instance in inv.gear:
		var id_str: String = instance.get("id", "")
		if id_str.begins_with("gear_"):
			max_counter = maxi(max_counter, int(id_str.substr(5)))
	inv._gear_counter = max_counter
	return inv

# Writes this inventory's fields into `state` (mutates and returns it) so
# callers can merge it into a SaveManager state Dictionary before saving.
func to_state(state: Dictionary) -> Dictionary:
	state["materials"] = materials.duplicate(true)
	state["consumables"] = consumables.duplicate(true)
	state["gear"] = gear.duplicate(true)
	return state
