# NodeMap — builds the per-zone choice map for a run: one node per monster
# available in the zone (level/reward/risk visible so the player can judge
# the gamble before committing a hunt) plus one travel node per zone
# connection (deeper zones to unlock).
class_name NodeMap
extends RefCounted

# Builds the node list for `zone`. `monster_defs` maps monster id -> MonsterDef
# (typically the full loaded monster table; only ids in zone.monster_ids are
# used). Skips monster ids that aren't present in `monster_defs` rather than
# failing, since content gaps are a data-authoring concern, not a run-time one.
static func generate(zone: ZoneDef, monster_defs: Dictionary) -> Array:
	var nodes: Array = []
	for monster_id in zone.monster_ids:
		if not monster_defs.has(monster_id):
			continue
		var monster: MonsterDef = monster_defs[monster_id]
		nodes.append({
			"type": "monster",
			"monster_id": monster.id,
			"level": monster.level,
			"xp_reward": monster.xp_reward,
			"risk": monster.base_attack,
		})
	for target_zone_id in zone.connections:
		nodes.append({
			"type": "travel",
			"target_zone_id": target_zone_id,
		})
	return nodes
