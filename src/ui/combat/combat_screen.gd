# CombatScreen — renders a CombatResolver HP-race for the picked monster,
# driven by a tap-timed "Dodge" button (touch/mouse) each round. Once the
# reflex phase ends, the run's authoritative outcome (XP, drops, hunts,
# death) is resolved through RunState.resolve_fight — no rules logic is
# reimplemented here, only round timing/animation bookkeeping. Instanced as
# an overlay child (e.g. by the overworld) rather than a standalone scene:
# it never changes scenes itself, it signals completion via
# `combat_finished` and leaves scene/run teardown to its parent.
extends Control

signal combat_finished(result: Dictionary)

const MonsterSpriteSheet = preload("res://src/ui/combat/monster_sprite_sheet.gd")

const ROUND_DURATION := 1.2
const PERFECT_OFFSET := 0.7 # seconds into the round considered a "perfect" dodge
const MAX_ROUNDS := 12

@onready var timer: Timer = %RoundTimer
@onready var dodge_button: Button = %DodgeButton
@onready var start_button: Button = %StartButton
@onready var continue_button: Button = %ContinueButton
@onready var player_hp_bar: ProgressBar = %PlayerHpBar
@onready var monster_hp_bar: ProgressBar = %MonsterHpBar
@onready var info_label: Label = %InfoLabel
@onready var result_label: Label = %ResultLabel
@onready var monster_sprite: AnimatedSprite2D = %MonsterSprite

var monster: MonsterDef
var player_stats: Dictionary
var monster_stats: Dictionary
var weapon_stats: Dictionary
var skill_profile: Dictionary = {}
var beats: Array = []

var _round_start_ms: int = 0
var _dodge_tapped_this_round: bool = false
var _fight_over: bool = false
var _fight_result: Dictionary = {}

func _ready() -> void:
	monster = GameState.pending_monster
	var run: RunState = GameState.current_run

	player_stats = {"hp_max": XpCurve.power_scaling(run.level) * 5.0, "power": XpCurve.power_scaling(run.level)}
	monster_stats = {"hp_max": monster.base_hp, "power": monster.base_attack, "element": monster.element}
	weapon_stats = _weapon_stats(run.equipped_weapon_id)
	skill_profile = GameState.skill_profile_for(run.equipped_armor_ids)

	player_hp_bar.max_value = player_stats["hp_max"]
	player_hp_bar.value = player_stats["hp_max"]
	monster_hp_bar.max_value = monster_stats["hp_max"]
	monster_hp_bar.value = monster_stats["hp_max"]
	info_label.text = "%s (Lv %s)" % [monster.name, Big.fmt(monster.level)]

	monster_sprite.sprite_frames = MonsterSpriteSheet.build(monster.id)
	monster_sprite.animation_finished.connect(_on_monster_anim_finished)
	monster_sprite.play("idle")

	start_button.pressed.connect(_on_start_pressed)
	dodge_button.pressed.connect(_on_dodge_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	dodge_button.visible = false
	continue_button.visible = false
	result_label.text = ""

	timer.wait_time = ROUND_DURATION
	timer.one_shot = true
	timer.timeout.connect(_on_round_timeout)

func _weapon_stats(weapon_id: String) -> Dictionary:
	if weapon_id != "" and GameState.weapons.has(weapon_id):
		var def: WeaponDef = GameState.weapons[weapon_id]
		return {"weapon_class": def.weapon_class, "element": def.element, "base_damage": def.base_damage}
	return {"weapon_class": "", "element": "neutral", "base_damage": 5.0}

func _on_start_pressed() -> void:
	start_button.visible = false
	dodge_button.visible = true
	beats.clear()
	_fight_over = false
	_start_round()

func _start_round() -> void:
	_round_start_ms = Time.get_ticks_msec()
	_dodge_tapped_this_round = false
	timer.start()

func _on_dodge_pressed() -> void:
	if _fight_over or _dodge_tapped_this_round:
		return
	_dodge_tapped_this_round = true
	var elapsed := (Time.get_ticks_msec() - _round_start_ms) / 1000.0
	beats.append({"dodge_timing": absf(elapsed - PERFECT_OFFSET)})

func _on_round_timeout() -> void:
	if _fight_over:
		return
	if not _dodge_tapped_this_round:
		beats.append({"dodge_timing": INF})

	var monster_hp_before := monster_hp_bar.value
	var outcome := CombatResolver.resolve(player_stats, monster_stats, weapon_stats, beats, skill_profile)
	player_hp_bar.value = outcome["player_hp"]
	monster_hp_bar.value = outcome["monster_hp"]

	if outcome["monster_hp"] < monster_hp_before:
		monster_sprite.play("hit")
	else:
		monster_sprite.play("attack")

	if outcome["monster_hp"] <= 0.0 or outcome["player_hp"] <= 0.0 or beats.size() >= MAX_ROUNDS:
		_end_reflex_phase()
	else:
		_start_round()

func _on_monster_anim_finished() -> void:
	if monster_sprite.animation != "idle":
		monster_sprite.play("idle")

func _end_reflex_phase() -> void:
	_fight_over = true
	dodge_button.visible = false

	var run: RunState = GameState.current_run
	var result := run.resolve_fight(monster, [], null, skill_profile)
	_fight_result = result
	if result["died"]:
		GameState.mark_bestiary_seen(monster.id)
		result_label.text = "Defeated... the run's haul is forfeited."
	else:
		GameState.mark_bestiary_defeated(monster.id, result["materials_dropped"])
		result_label.text = "Victory! +%s XP, %d level(s) gained. Dropped: %s" % [
			Big.fmt(result["xp_awarded"]), result["levels_gained"], ", ".join(result["materials_dropped"])
		]
	continue_button.visible = true

func _on_continue_pressed() -> void:
	combat_finished.emit(_fight_result)
