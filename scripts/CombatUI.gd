extends Control

const CardScene = preload("res://scenes/CardCard.tscn")
const EnemyScene = preload("res://scenes/EnemyDisplay.tscn")
const CardDatabase = preload("res://scripts/CardDatabase.gd")

@onready var enemy_area = $EnemyArea
@onready var hand_area = $HandArea
@onready var player_hp_label = $PlayerArea/PlayerHPLabel
@onready var player_block_label = $PlayerArea/PlayerBlockLabel
@onready var energy_label = $PlayerArea/EnergyLabel
@onready var gold_label = $PlayerArea/GoldLabel
@onready var end_turn_btn = $EndTurnBtn
@onready var draw_pile_label = $DrawPileLabel
@onready var discard_pile_label = $DiscardPileLabel
@onready var turn_label = $TurnLabel
@onready var info_label = $InfoLabel
@onready var deck_view_btn = $DeckViewBtn
@onready var combat_manager = $CombatManager
@onready var background = $Background

var card_db: Node
var card_displays: Array[Control] = []
var enemy_displays: Array[Control] = []
var is_animating: bool = false
var scene_transitioning: bool = false

func _ready():
	card_db = CardDatabase.new()
	add_child(card_db)

	end_turn_btn.pressed.connect(_on_end_turn)
	deck_view_btn.pressed.connect(_on_deck_view)
	GameManager.hp_changed.connect(_on_hp_changed)
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.energy_changed.connect(_on_energy_changed)

	combat_manager.player_turn_started.connect(_on_player_turn)
	combat_manager.enemy_turn_started.connect(_on_enemy_turn_start)
	combat_manager.enemy_turn_ended.connect(_on_enemy_turn_end)
	combat_manager.combat_ended.connect(_on_combat_ended)
	combat_manager.card_played.connect(_on_card_played)
	combat_manager.enemy_attacked.connect(_on_enemy_attacked)
	combat_manager.player_attacked.connect(_on_player_attacked)
	combat_manager.enemy_added.connect(_on_enemy_added)
	combat_manager.enemy_removed.connect(_on_enemy_removed)

	_apply_theme()
	_start_random_combat()

func _apply_theme():
	var theme = Theme.new()
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.2, 0.15, 0.1, 0.9)
	btn_normal.border_color = Color(0.5, 0.4, 0.2)
	btn_normal.set_border_width_all(2)
	btn_normal.set_corner_radius_all(6)
	theme.set_stylebox("normal", "Button", btn_normal)

	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.3, 0.25, 0.15, 0.95)
	btn_hover.border_color = Color(0.7, 0.6, 0.3)
	btn_hover.set_border_width_all(2)
	btn_hover.set_corner_radius_all(6)
	theme.set_stylebox("hover", "Button", btn_hover)

	var btn_disabled = StyleBoxFlat.new()
	btn_disabled.bg_color = Color(0.1, 0.1, 0.1, 0.5)
	btn_disabled.border_color = Color(0.3, 0.3, 0.3)
	btn_disabled.set_border_width_all(2)
	btn_disabled.set_corner_radius_all(6)
	theme.set_stylebox("disabled", "Button", btn_disabled)

	theme.set_font_size("font_size", "Button", 18)
	theme.set_color("font_color", "Button", Color(0.9, 0.85, 0.7))
	theme.set_color("font_color", "Label", Color(0.85, 0.85, 0.9))
	theme.set_font_size("font_size", "Label", 16)

	set_theme(theme)

func _start_random_combat():
	var enemy_db = load("res://scripts/EnemyDatabase.gd").new()
	add_child(enemy_db)

	var enemy_data_list: Array[EnemyData] = []
	var floor_mod = GameManager.current_floor % 15
	if floor_mod == 14:
		var boss = enemy_db.get_boss()
		if boss:
			enemy_data_list.append(boss)
	elif floor_mod == 5 or floor_mod == 10:
		var elite = enemy_db.get_random_elite()
		if elite:
			enemy_data_list.append(elite)
	else:
		var normal = enemy_db.get_random_normal_enemy()
		if normal:
			enemy_data_list.append(normal)
		if randf() < 0.3:
			var normal2 = enemy_db.get_random_normal_enemy()
			if normal2:
				enemy_data_list.append(normal2)

	enemy_db.queue_free()

	if enemy_data_list.is_empty():
		# Fallback: create a basic enemy if database failed
		var fallback = EnemyData.new()
		fallback.enemy_name = "Cultist"
		fallback.max_hp = 50
		fallback.min_hp = 50
		fallback.gold_drop = 15
		fallback.moves = [{"name": "Dark Strike", "damage": 6, "block": 0, "effect": "", "value": 0}]
		enemy_data_list.append(fallback)

	combat_manager.start_combat(enemy_data_list)

func _on_enemy_added(enemy: EnemyInstance, index: int):
	var display = EnemyScene.instantiate()
	enemy_area.add_child(display)
	display.setup(enemy, enemy_displays.size())
	display.enemy_selected.connect(_on_enemy_clicked)
	enemy_displays.append(display)

func _on_enemy_removed(index: int):
	# Remove corresponding display and rebuild indices
	if index >= 0 and index < enemy_displays.size():
		var display = enemy_displays.pop_at(index)
		if is_instance_valid(display):
			display.queue_free()
	# Re-index remaining displays
	for i in range(enemy_displays.size()):
		if is_instance_valid(enemy_displays[i]):
			enemy_displays[i].enemy_index = i

func _on_player_turn():
	if scene_transitioning:
		return
	end_turn_btn.disabled = false
	_update_hand_display()
	_update_hud()
	turn_label.text = "Turn: %d" % combat_manager.turn_count
	info_label.text = "[color=green]Your Turn[/color]"

func _on_enemy_turn_start():
	if scene_transitioning:
		return
	end_turn_btn.disabled = true
	_clear_hand()
	info_label.text = "[color=red]Enemy Turn[/color]"

func _on_enemy_turn_end():
	if scene_transitioning:
		return
	_update_hand_display()

func _update_hand_display():
	if scene_transitioning:
		return
	_clear_hand()
	for i in range(GameManager.hand.size()):
		var card = GameManager.hand[i]
		var display = CardScene.instantiate()
		hand_area.add_child(display)
		display.setup(card, i)
		display.in_hand = true
		display.card_clicked.connect(_on_card_clicked)

		var can_play = combat_manager.can_play_card(i)
		display.set_playable(can_play and combat_manager.is_player_turn)
		card_displays.append(display)
	_update_pile_labels()

func _clear_hand():
	for display in card_displays:
		if is_instance_valid(display):
			display.queue_free()
	card_displays.clear()

func _update_hud():
	if not is_instance_valid(player_hp_label):
		return
	player_hp_label.text = "HP: %d/%d" % [GameManager.player_hp, GameManager.player_max_hp]
	player_block_label.text = "Block: %d" % GameManager.player_block
	energy_label.text = "Energy: %d/%d" % [GameManager.player_energy, GameManager.player_max_energy]
	gold_label.text = "Gold: %d" % GameManager.player_gold

func _update_pile_labels():
	draw_pile_label.text = "Draw: %d" % GameManager.draw_pile.size()
	discard_pile_label.text = "Discard: %d" % GameManager.discard_pile.size()

func _on_card_clicked(index: int):
	if not combat_manager.is_player_turn or is_animating or scene_transitioning:
		return

	var card = GameManager.hand[index]
	if card == null:
		return

	var cost = card.get_effective_cost()
	if cost < 0:
		cost = GameManager.player_energy
	if cost > GameManager.player_energy:
		return

	# Auto-target for non-enemy cards
	if card.target == CardData.CardTarget.ENEMY:
		var alive_enemies = combat_manager.enemies.filter(func(e): return not e.is_dead)
		if alive_enemies.size() == 1:
			var idx = combat_manager.enemies.find(alive_enemies[0])
			_play_card(index, idx)
		elif alive_enemies.size() == 0:
			return
		else:
			_enter_target_mode(index)
	elif card.target == CardData.CardTarget.ALL_ENEMIES:
		_play_card(index, -1)
	else:
		_play_card(index, -1)

func _enter_target_mode(card_index: int):
	combat_manager.card_target_mode = true
	combat_manager.pending_card_index = card_index
	info_label.text = "[color=yellow]Select a target[/color]"
	for i in range(enemy_displays.size()):
		var display = enemy_displays[i]
		if is_instance_valid(display) and display.enemy != null and not display.enemy.is_dead:
			display.set_targetable(true)

func _on_enemy_clicked(display_index: int):
	if not combat_manager.card_target_mode:
		return
	combat_manager.card_target_mode = false
	info_label.text = "[color=green]Your Turn[/color]"
	for display in enemy_displays:
		if is_instance_valid(display):
			display.set_targetable(false)

	# Convert display index to combat manager enemy index
	var actual_enemy_index = display_index
	if display_index >= 0 and display_index < combat_manager.enemies.size():
		actual_enemy_index = display_index
	_play_card(combat_manager.pending_card_index, actual_enemy_index)

func _play_card(card_index: int, target_index: int):
	if scene_transitioning:
		return
	is_animating = true
	combat_manager.play_card(card_index, target_index)
	await get_tree().create_timer(0.15).timeout
	is_animating = false
	if scene_transitioning or not is_instance_valid(self):
		return
	_update_hand_display()
	_update_hud()

func _on_card_played(card: CardData, target_index: int):
	if scene_transitioning:
		return
	var msg = "Played [color=cyan]%s[/color]" % card.card_name
	if card.get_effective_damage() > 0:
		msg += " (DMG: %d)" % (card.get_effective_damage() + combat_manager.player_strength)
	if card.get_effective_block() > 0:
		msg += " (BLK: %d)" % card.get_effective_block()
	info_label.text = msg

func _on_enemy_attacked(enemy: EnemyInstance, damage: int):
	if scene_transitioning:
		return
	for display in enemy_displays:
		if is_instance_valid(display) and display.enemy == enemy:
			display.flash_damage()
			display.shake()
	_update_hud()

func _on_player_attacked(damage: int):
	if scene_transitioning:
		return
	is_animating = true
	if is_instance_valid(background):
		var tween = create_tween()
		tween.tween_property(background, "color", Color(0.3, 0.05, 0.05), 0.1)
		tween.tween_property(background, "color", Color(0.05, 0.05, 0.1), 0.3)
		await tween.finished
	if not is_instance_valid(self) or scene_transitioning:
		return
	is_animating = false
	_update_hud()

func _on_end_turn():
	if combat_manager.is_player_turn and not is_animating and not scene_transitioning:
		combat_manager.end_player_turn()

func _on_combat_ended(victory: bool):
	if scene_transitioning:
		return
	scene_transitioning = true
	is_animating = false
	end_turn_btn.disabled = true

	if victory:
		info_label.text = "[color=green]Victory![/color]"
		var gold_reward = randi_range(20, 40)
		GameManager.add_gold(gold_reward)
		await get_tree().create_timer(1.5).timeout
		if is_instance_valid(self):
			get_tree().change_scene_to_file("res://scenes/RewardScreen.tscn")
	else:
		info_label.text = "[color=red]Defeated...[/color]"
		await get_tree().create_timer(2.0).timeout
		if is_instance_valid(self):
			get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

func _on_hp_changed(hp: int, max_hp: int):
	_update_hud()

func _on_gold_changed(gold: int):
	_update_hud()

func _on_energy_changed(energy: int, max_energy: int):
	_update_hud()

func _on_deck_view():
	var text = "[color=cyan]Deck:[/color] "
	for card in GameManager.deck:
		text += card.card_name + ", "
	info_label.text = text
