extends Control

var enemy: EnemyInstance
var enemy_index: int = -1

signal enemy_selected(index: int)

@onready var border_rect = $BorderRect
@onready var body_rect = $BodyRect
@onready var face_rect = $FaceRect
@onready var hp_bar = $HPBar
@onready var hp_label = $HPLabel
@onready var intent_label = $IntentLabel
@onready var block_label = $BlockLabel
@onready var name_label = $NameLabel
@onready var select_btn = $SelectBtn

func _ready():
	select_btn.pressed.connect(_on_selected)
	select_btn.mouse_entered.connect(_on_hover)
	select_btn.mouse_exited.connect(_on_unhover)

func setup(enemy_inst: EnemyInstance, index: int):
	enemy = enemy_inst
	enemy_index = index
	enemy.enemy_hp_changed.connect(_on_enemy_hp_changed)
	enemy.enemy_intents_changed.connect(_on_enemy_intents_changed)
	_update_display()

func _on_enemy_hp_changed(_enemy: EnemyInstance):
	if is_instance_valid(self):
		_update_display()

func _on_enemy_intents_changed(_enemy: EnemyInstance):
	if is_instance_valid(self):
		_update_display()

func _update_display():
	if enemy == null or not is_instance_valid(self):
		return

	name_label.text = enemy.data.enemy_name
	hp_bar.max_value = enemy.max_hp
	hp_bar.value = enemy.current_hp
	hp_label.text = "%d/%d" % [enemy.current_hp, enemy.max_hp]
	block_label.text = "B:%d" % enemy.block

	# Intent display
	var intent_dmg = enemy.get_intent_damage()
	var intent_name = enemy.get_intent_name()
	if intent_dmg > 0:
		intent_label.text = "ATK %s (%d)" % [intent_name, intent_dmg]
		intent_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	elif enemy.get_intent_block() > 0:
		intent_label.text = "DEF %s" % intent_name
		intent_label.add_theme_color_override("font_color", Color(0.3, 0.5, 1))
	else:
		var effect = enemy.get_intent_effect()
		if effect != "" and effect != "sleep":
			intent_label.text = "* %s" % intent_name
			intent_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.3))
		else:
			intent_label.text = intent_name
			intent_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

	# Color based on enemy type
	var base_color = enemy.data.color
	border_rect.color = Color(base_color.r * 0.6, base_color.g * 0.6, base_color.b * 0.6)
	body_rect.color = base_color
	face_rect.color = Color(min(1, base_color.r * 1.3), min(1, base_color.g * 1.3), min(1, base_color.b * 1.3))

	# Status effects display
	var status_text = ""
	if enemy.vulnerable > 0:
		status_text += " [V:%d]" % enemy.vulnerable
	if enemy.weak > 0:
		status_text += " [W:%d]" % enemy.weak
	if enemy.strength > 0:
		status_text += " [S:+%d]" % enemy.strength
	name_label.text = enemy.data.enemy_name + status_text

	# Dead state
	if enemy.is_dead:
		modulate = Color(0.3, 0.3, 0.3, 0.5)
		select_btn.disabled = true
	else:
		modulate = Color.WHITE

func _on_selected():
	enemy_selected.emit(enemy_index)

func _on_hover():
	if enemy and not enemy.is_dead:
		border_rect.color = Color(0.8, 0.8, 0.3)
		scale = Vector2(1.05, 1.05)

func _on_unhover():
	if enemy and is_instance_valid(self):
		_update_display()
		scale = Vector2(1.0, 1.0)

func set_targetable(targetable: bool):
	if enemy == null or enemy.is_dead:
		return
	if targetable:
		modulate = Color.WHITE
		select_btn.disabled = false
		border_rect.color = Color(1, 0.8, 0.2)
		scale = Vector2(1.05, 1.05)
	else:
		modulate = Color.WHITE
		select_btn.disabled = true
		scale = Vector2(1.0, 1.0)
		_update_display()

func flash_damage():
	if not is_instance_valid(self):
		return
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func shake():
	if not is_instance_valid(self):
		return
	var tween = create_tween()
	var orig = position
	tween.tween_property(self, "position", orig + Vector2(8, 0), 0.05)
	tween.tween_property(self, "position", orig + Vector2(-8, 0), 0.05)
	tween.tween_property(self, "position", orig + Vector2(4, 0), 0.05)
	tween.tween_property(self, "position", orig, 0.05)

func cleanup():
	if enemy != null:
		if enemy.enemy_hp_changed.is_connected(_on_enemy_hp_changed):
			enemy.enemy_hp_changed.disconnect(_on_enemy_hp_changed)
		if enemy.enemy_intents_changed.is_connected(_on_enemy_intents_changed):
			enemy.enemy_intents_changed.disconnect(_on_enemy_intents_changed)
	enemy = null
