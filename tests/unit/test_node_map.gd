# Tests for NodeMap (src/systems/node_map.gd): choice/travel structure and
# visible level/reward/risk invariants, built off the real MVP zone/monster data.
extends "res://tests/test_case.gd"

const NodeMap = preload("res://src/systems/node_map.gd")

var _monster_defs: Dictionary
var _verdant: ZoneDef
var _cinder: ZoneDef
var _frostpeak: ZoneDef

func before_each() -> void:
	var monster_result := DataLoader.load_directory("res://data/monsters", MonsterDef.from_dict)
	_monster_defs = monster_result["defs"]
	var zone_result := DataLoader.load_directory("res://data/zones", ZoneDef.from_dict)
	_verdant = zone_result["defs"]["verdant_fields"]
	_cinder = zone_result["defs"]["cinder_dunes"]
	_frostpeak = zone_result["defs"]["frostpeak_ridge"]

func test_generate_yields_one_monster_node_per_zone_monster() -> void:
	var nodes := NodeMap.generate(_verdant, _monster_defs)
	var monster_nodes := nodes.filter(func(n): return n["type"] == "monster")
	assert_eq(monster_nodes.size(), _verdant.monster_ids.size())
	var seen_ids: Array = []
	for n in monster_nodes:
		seen_ids.append(n["monster_id"])
	for mid in _verdant.monster_ids:
		assert_has(seen_ids, mid)

func test_generate_yields_one_travel_node_per_connection() -> void:
	var nodes := NodeMap.generate(_verdant, _monster_defs)
	var travel_nodes := nodes.filter(func(n): return n["type"] == "travel")
	assert_eq(travel_nodes.size(), _verdant.connections.size())
	assert_eq(travel_nodes[0]["target_zone_id"], "cinder_dunes")

func test_generate_zone_with_no_connections_has_no_travel_nodes() -> void:
	var nodes := NodeMap.generate(_frostpeak, _monster_defs)
	var travel_nodes := nodes.filter(func(n): return n["type"] == "travel")
	assert_true(travel_nodes.is_empty())

func test_monster_nodes_expose_level_reward_risk() -> void:
	var nodes := NodeMap.generate(_verdant, _monster_defs)
	var slime_node
	for n in nodes:
		if n["type"] == "monster" and n["monster_id"] == "slime":
			slime_node = n
	assert_not_null(slime_node, "expected a slime node in verdant_fields")
	var slime: MonsterDef = _monster_defs["slime"]
	assert_almost_eq(slime_node["level"], slime.level)
	assert_almost_eq(slime_node["xp_reward"], slime.xp_reward)
	assert_almost_eq(slime_node["risk"], slime.base_attack)

func test_generate_skips_monster_ids_missing_from_table() -> void:
	var nodes := NodeMap.generate(_verdant, {})
	var monster_nodes := nodes.filter(func(n): return n["type"] == "monster")
	assert_true(monster_nodes.is_empty(), "unknown monster ids must be skipped, not crash")
