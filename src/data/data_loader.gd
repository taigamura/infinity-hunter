# Generic JSON content loader + schema validator.
#
# WHY THIS EXISTS: every content type (monster, weapon, armor, zone, companion,
# material) needs the exact same "read JSON, validate required fields, build a
# typed def, dedupe by id" pipeline. Def classes only supply a schema and a
# from_dict(data, source_path) -> Variant conversion; this class does the I/O,
# validation dispatch, and directory aggregation so that pipeline exists once.
class_name DataLoader
extends RefCounted

# Validates `data` against `schema` (field_name -> "string"|"number"|"bool"|
# "array"|"dictionary"). Returns "" if valid, else an error naming
# `source_path` and the offending field.
static func validate(data: Dictionary, schema: Dictionary, source_path: String) -> String:
	for field in schema.keys():
		var expected: String = schema[field]
		if not data.has(field):
			return "%s: missing required field '%s'" % [source_path, field]
		var value = data[field]
		if not _matches_type(value, expected):
			return "%s: field '%s' expected %s, got %s" % [
				source_path, field, expected, _type_name(value)
			]
	return ""

static func _matches_type(value, expected: String) -> bool:
	match expected:
		"string":
			return typeof(value) == TYPE_STRING
		"number":
			return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
		"bool":
			return typeof(value) == TYPE_BOOL
		"array":
			return typeof(value) == TYPE_ARRAY
		"dictionary":
			return typeof(value) == TYPE_DICTIONARY
	return false

static func _type_name(value) -> String:
	match typeof(value):
		TYPE_STRING:
			return "string"
		TYPE_BOOL:
			return "bool"
		TYPE_INT, TYPE_FLOAT:
			return "number"
		TYPE_ARRAY:
			return "array"
		TYPE_DICTIONARY:
			return "dictionary"
		TYPE_NIL:
			return "null"
	return "unknown"

# Loads a single JSON file and converts it via `from_dict_fn`, a
# Callable(Dictionary, String) -> Variant that returns either a def instance
# or a String error message. Returns {"ok": bool, "def": Variant, "error": String}.
static func load_file(path: String, from_dict_fn: Callable) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "def": null, "error": "file not found: %s" % path}
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "def": null, "error": "%s: invalid JSON" % path}
	var result = from_dict_fn.call(parsed, path)
	if result is String:
		return {"ok": false, "def": null, "error": result}
	return {"ok": true, "def": result, "error": ""}

# Loads every *.json file directly under `dir_path` via `from_dict_fn`.
# Rejects duplicate ids across files. Returns
# {"ok": bool, "defs": Dictionary[String, Variant], "error": String}.
static func load_directory(dir_path: String, from_dict_fn: Callable) -> Dictionary:
	var defs: Dictionary = {}
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return {"ok": false, "defs": {}, "error": "cannot open directory: %s" % dir_path}

	var files: Array[String] = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".json"):
			files.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	files.sort()

	for f in files:
		var path := "%s/%s" % [dir_path, f]
		var result := load_file(path, from_dict_fn)
		if not result["ok"]:
			return {"ok": false, "defs": {}, "error": result["error"]}
		var def = result["def"]
		if defs.has(def.id):
			return {"ok": false, "defs": {}, "error": "%s: duplicate id '%s'" % [path, def.id]}
		defs[def.id] = def

	return {"ok": true, "defs": defs, "error": ""}
