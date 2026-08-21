# SaveManager — persists meta-progression (gear instances with rolled
# stats, material/consumable counts, captures, bestiary, unlocks, essence,
# upgrades) to `user://` as JSON. Never touches RunState (per-expedition,
# in-memory only, forfeited on death) — this is the durable save.
#
# Atomicity: writes go to a temp file, flushed, then the current live file
# (if any) is renamed to `.bak` before the temp file is renamed into place.
# A process kill mid-write leaves the live file (and `.bak`) untouched,
# since the live path is only ever replaced by a single rename.
#
# Shaped as a flat JSON Dictionary (not Godot-specific types) so a future
# iCloud/CloudKit sync path can ship the same blob without a save-format
# change; sync itself is out of scope here.
class_name SaveManager
extends RefCounted

const CURRENT_VERSION := 3
const DEFAULT_SAVE_PATH := "user://save.json"
const DEFAULT_BAK_SUFFIX := ".bak"
const DEFAULT_TMP_SUFFIX := ".tmp"

# Debounce window for autosave coalescing (ms).
const DEFAULT_DEBOUNCE_MS := 2000

var debounce_ms: int = DEFAULT_DEBOUNCE_MS
var _pending_state = null
var _last_request_ms: int = 0

# ---- persistent state shape ----------------------------------------------

static func default_state() -> Dictionary:
	return {
		"version": CURRENT_VERSION,
		"essence": 0.0, # Big
		"materials": {}, # material_id -> int count
		"consumables": {}, # consumable_id -> int count
		"gear": [{"id": "gear_1", "def_id": "rusty_greatsword", "rolled_stats": {"rarity": "Common"}}], # [{id, def_id, rolled_stats: {...}}]
		"captures": [], # [{monster_id, ...}]
		"bestiary": {}, # monster_id -> {seen: bool, defeated: bool, ...}
		"unlocks": [], # [unlock_id]
		"upgrades": {}, # upgrade_id -> int level
		"unlocked_zones": ["verdant_fields"], # [zone_id], durable zone unlocks
	}

# ---- migration -------------------------------------------------------------

# Each entry migrates FROM its key version TO key+1. Applied sequentially
# until data reaches CURRENT_VERSION.
static func _migrate_1_to_2(data: Dictionary) -> Dictionary:
	if not data.has("upgrades"):
		data["upgrades"] = {}
	data["version"] = 2
	return data

static func _migrate_2_to_3(data: Dictionary) -> Dictionary:
	if (data.get("gear", []) as Array).is_empty():
		data["gear"] = [{"id": "gear_1", "def_id": "rusty_greatsword", "rolled_stats": {"rarity": "Common"}}]
	if not data.has("unlocked_zones"):
		data["unlocked_zones"] = ["verdant_fields"]
	data["version"] = 3
	return data

static func migrate(data: Dictionary) -> Dictionary:
	var version := int(data.get("version", 1))
	while version < CURRENT_VERSION:
		match version:
			1:
				data = _migrate_1_to_2(data)
			2:
				data = _migrate_2_to_3(data)
			_:
				# No migration path defined; stop rather than loop forever.
				data["version"] = CURRENT_VERSION
				break
		version = int(data.get("version", CURRENT_VERSION))
	return data

# True if `data` is a plausible save blob (has the fields a fresh save has).
static func _is_valid(data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	return data.has("version")

# ---- atomic write / read ---------------------------------------------------

static func save_game(state: Dictionary, path: String = DEFAULT_SAVE_PATH) -> bool:
	var tmp_path := path + DEFAULT_TMP_SUFFIX
	var bak_path := path + DEFAULT_BAK_SUFFIX

	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: failed to open temp save file %s (err %d)" % [tmp_path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(state, "\t"))
	file.flush()
	file.close()

	if FileAccess.file_exists(path):
		# Overwrite any previous .bak with the outgoing live file before
		# replacing it, so .bak always holds the last-known-good save.
		if FileAccess.file_exists(bak_path):
			DirAccess.remove_absolute(bak_path)
		var rename_err := DirAccess.rename_absolute(path, bak_path)
		if rename_err != OK:
			push_error("SaveManager: failed to back up %s (err %d)" % [path, rename_err])
			return false

	var final_err := DirAccess.rename_absolute(tmp_path, path)
	if final_err != OK:
		push_error("SaveManager: failed to commit save to %s (err %d)" % [path, final_err])
		return false
	return true

# Parses+validates the JSON at `path`. Returns null on missing/corrupt file.
static func _read_blob(path: String):
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if not _is_valid(parsed):
		return null
	return parsed

# Loads the save at `path`, migrating it to CURRENT_VERSION. Falls back to
# `.bak` if the live file is missing or corrupt; falls back to a fresh
# default state if both are unusable.
static func load_game(path: String = DEFAULT_SAVE_PATH) -> Dictionary:
	var blob = _read_blob(path)
	if blob == null:
		blob = _read_blob(path + DEFAULT_BAK_SUFFIX)
	if blob == null:
		return default_state()
	return migrate(blob)

# ---- debounced autosave -----------------------------------------------------

# Marks `state` as dirty; the actual write is coalesced until `debounce_ms`
# has elapsed since the most recent call with no further calls in between.
# `now_ms` is injectable for deterministic tests; production callers omit it
# and get OS.get_ticks_msec().
func request_autosave(state: Dictionary, now_ms: int = -1) -> void:
	_pending_state = state
	_last_request_ms = now_ms if now_ms >= 0 else Time.get_ticks_msec()

func has_pending_autosave() -> bool:
	return _pending_state != null

# True once `debounce_ms` has passed since the last request_autosave call
# with no newer request superseding it.
func is_flush_due(now_ms: int = -1) -> bool:
	if _pending_state == null:
		return false
	var t := now_ms if now_ms >= 0 else Time.get_ticks_msec()
	return (t - _last_request_ms) >= debounce_ms

# Writes the pending state if due. Returns true if a write happened.
func flush(path: String = DEFAULT_SAVE_PATH, now_ms: int = -1) -> bool:
	if not is_flush_due(now_ms):
		return false
	var state: Dictionary = _pending_state
	_pending_state = null
	return save_game(state, path)
