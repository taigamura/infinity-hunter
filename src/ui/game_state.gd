# GameState — process-lifetime autoload that owns loaded content defs, the
# durable save, and (while a run is active) the current RunState + the
# monster picked off the node-map for combat. Scenes read/drive it via these
# public methods/fields instead of touching systems directly, so navigation
# between screens doesn't lose state.
extends Node

var monsters: Dictionary = {} # id -> MonsterDef
var weapons: Dictionary = {} # id -> WeaponDef
var armors: Dictionary = {} # id -> ArmorDef
var armor_sets: Dictionary = {} # id -> ArmorSetDef
var zones: Dictionary = {} # id -> ZoneDef
var companions: Dictionary = {} # id -> CompanionDef
var materials: Dictionary = {} # id -> MaterialDef
var tier_tables: Dictionary = {} # zone_id -> TierTableDef

var save_state: Dictionary = {}
var inventory: Inventory
var current_run: RunState = null
var pending_monster: MonsterDef = null

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_load_data()
	save_state = SaveManager.load_game()
	inventory = Inventory.from_state(save_state)

func _load_data() -> void:
	monsters = _load_dir("res://data/monsters", MonsterDef.from_dict)
	weapons = _load_dir("res://data/weapons", WeaponDef.from_dict)
	armors = _load_dir("res://data/armor", ArmorDef.from_dict)
	armor_sets = _load_dir("res://data/armor_sets", ArmorSetDef.from_dict)
	zones = _load_dir("res://data/zones", ZoneDef.from_dict)
	companions = _load_dir("res://data/companions", CompanionDef.from_dict)
	materials = _load_dir("res://data/materials", MaterialDef.from_dict)
	tier_tables = _load_dir("res://data/tiers", TierTableDef.from_dict)

func _load_dir(path: String, from_dict_fn: Callable) -> Dictionary:
	var result := DataLoader.load_directory(path, from_dict_fn)
	if not result["ok"]:
		push_error("GameState: failed loading %s: %s" % [path, result["error"]])
		return {}
	return result["defs"]

# Resolves `armor_ids` (slot -> ArmorDef id, e.g. RunState.equipped_armor_ids)
# into the equipped ArmorDef instances.
func equipped_armor_defs(armor_ids: Dictionary) -> Array:
	var defs: Array = []
	for slot in armor_ids:
		var armor_id: String = armor_ids[slot]
		if armors.has(armor_id):
			defs.append(armors[armor_id])
	return defs

# The SkillSystem effects profile (issue #9) for `armor_ids`'s equipped
# pieces + any set bonuses, ready to pass into CombatResolver.resolve /
# RunState.resolve_fight.
func skill_profile_for(armor_ids: Dictionary) -> Dictionary:
	return SkillSystem.build_profile(equipped_armor_defs(armor_ids), armor_sets)

func persist() -> void:
	inventory.to_state(save_state)
	SaveManager.save_game(save_state)

func mark_bestiary_seen(monster_id: String) -> void:
	var monster: MonsterDef = monsters.get(monster_id)
	if monster != null:
		Bestiary.record_encounter(save_state, monster)

# Records a kill plus any materials/parts learned from that fight.
func mark_bestiary_defeated(monster_id: String, dropped_materials: Array = [], broken_parts: Array = []) -> void:
	var monster: MonsterDef = monsters.get(monster_id)
	if monster == null:
		return
	Bestiary.record_kill(save_state, monster)
	if not dropped_materials.is_empty():
		Bestiary.record_drops(save_state, monster_id, dropped_materials)
	if not broken_parts.is_empty():
		Bestiary.record_broken_parts(save_state, monster_id, broken_parts)

func mark_bestiary_captured(monster_id: String) -> void:
	var monster: MonsterDef = monsters.get(monster_id)
	if monster != null:
		Bestiary.record_capture(save_state, monster)

# Merges a finished run's banked haul into the durable inventory/essence and
# saves. No-op for materials/essence if the run ended in death (RunState
# already zeroed its unbanked haul on death, and never banks a dead run).
func settle_run(run: RunState) -> void:
	for material_id in run.materials_banked:
		inventory.add_material(material_id, int(run.materials_banked[material_id]))
	MetaProgression.settle_run(save_state, run.level, run.status)
	persist()

func start_run(zone_id: String, weapon_id: String, armor_ids: Dictionary) -> void:
	var modifiers := MetaProgression.get_run_modifiers(save_state)
	var hunts_max: float = RunState.DEFAULT_HUNTS + modifiers.get("hunt_count_bonus", 0.0)
	var run := RunState.start(zone_id, weapon_id, armor_ids, hunts_max)
	run.level += modifiers.get("starting_level_bonus", 0.0)
	run.generate_node_map(zones[zone_id], monsters)
	current_run = run
