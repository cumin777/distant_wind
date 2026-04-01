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

var card_db: Node
var card_displays: Array[Control] = []
var enemy_displays: Array[Control] = []
var is_animating: bool = false

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
	var enemy_data_list: Array[EnemyData] = []
	match GameManager.current_floor % 15:
		14:
			var db_script = load("res://scripts/EnemyDatabase.gd").new()
			add_child(db_script)
			enemy_data_list.append(db_script.get_boss())
			db_script.queue_free()
		5, 10:
			var db_script = load("res://scripts/EnemyDatabase.gd").new()
			add_child(db_script)
			enemy_data_list.append(db_script.get_random_elite())
			db_script.queue_free()
		_:
			var db_script = load("res://scripts/EnemyDatabase.gd").new()
			add_child(db_script)
			enemy_data_list.append(db_script.get_random_normal_enemy())
			# Sometimes two enemies
			if randf() < 0.3:
				enemy_data_list.append(db_script.get_random_normal_enemy())
			db_script.queue_free()

	combat_manager.start_combat(enemy_data_list)

func _on_enemy_added(enemy: EnemyInstance):
	var display = EnemyScene.instantiate()
	enemy_area.add_child(display)
	display.setup(enemy, enemy_displays.size())
	display.enemy_selected.connect(_on_enemy_clicked)
	enemy_displays.append(display)

func _on_player_turn():
	end_turn_btn.disabled = false
	_update_hand_display()
	_update_hud()
	turn_label.text = "Turn: %d" % combat_manager.turn_count
	info_label.text = "[color=green]Your Turn[/color]"

func _on_enemy_turn_start():
	end_turn_btn.disabled = true
	_clear_hand()
	info_label.text = "[color=red]Enemy Turn[/color]"

func _on_enemy_turn_end():
	_update_hand_display()

func _update_hand_display():
	_clear_hand()
	for i in range(GameManager.hand.size()):
		var card = GameManager.hand[i]
		var display = CardScene.instantiate()
		hand_area.add_child(display)
		display.setup(card, i)
		display.in_hand = true
		display.card_clicked.connect(_on_card_clicked)

		var can_play = combat_manager.can_play_card(i)
		# Check if card needs target
		if can_play and card.target == CardData.CardTarget.ENEMY:
			if not combat_manager.enemies.is_empty():
				can_play = true
		display.set_playable(can_play and combat_manager.is_player_turn)
		card_displays.append(display)
	_update_pile_labels()

func _clear_hand():
	for display in card_displays:
		if is_instance_valid(display):
			display.queue_free()
	card_displays.clear()

func _update_hud():
	player_hp_label.text = "HP: %d/%d" % [GameManager.player_hp, GameManager.player_max_hp]
	player_block_label.text = "Block: %d" % GameManager.player_block
	energy_label.text = "Energy: %d/%d" % [GameManager.player_energy, GameManager.player_max_energy]
	gold_label.text = "Gold: %d" % GameManager.player_gold

func _update_pile_labels():
	draw_pile_label.text = "Draw: %d" % GameManager.draw_pile.size()
	discard_pile_label.text = "Discard: %d" % GameManager.discard_pile.size()

func _on_card_clicked(index: int):
	if not combat_manager.is_player_turn or is_animating:
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
		if combat_manager.enemies.size() == 1:
			_play_card(index, 0)
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
	for display in enemy_displays:
		if is_instance_valid(display):
			display.set_targetable(true)

func _on_enemy_clicked(enemy_index: int):
	if combat_manager.card_target_mode:
		combat_manager.card_target_mode = false
		info_label.text = "[color=green]Your Turn[/color]"
		for display in enemy_displays:
			if is_instance_valid(display):
				display.set_targetable(false)
		_play_card(combat_manager.pending_card_index, enemy_index)

func _play_card(card_index: int, target_index: int):
	is_animating = true
	combat_manager.play_card(card_index, target_index)
	await get_tree().create_timer(0.15).timeout
	is_animating = false
	_update_hand_display()
	_update_hud()

func _on_card_played(card: CardData, target_index: int):
	var msg = "Played [color=cyan]%s[/color]" % card.card_name
	if card.get_effective_damage() > 0:
		msg += " (DMG: %d)" % (card.get_effective_damage() + combat_manager.player_strength)
	if card.get_effective_block() > 0:
		msg += " (BLK: %d)" % card.get_effective_block()
	info_label.text = msg

func _on_enemy_attacked(enemy: EnemyInstance, damage: int):
	for display in enemy_displays:
		if is_instance_valid(display) and display.enemy == enemy:
			display.flash_damage()
			display.shake()
	_update_hud()

func _on_player_attacked(damage: int):
	is_animating = true
	var tween = create_tween()
	tween.tween_property($Background, "color", Color(0.3, 0.05, 0.05), 0.1)
	tween.tween_property($Background, "color", Color(0.05, 0.05, 0.1), 0.3)
	await tween.finished
	is_animating = false
	_update_hud()

func _on_end_turn():
	if combat_manager.is_player_turn and not is_animating:
		combat_manager.end_player_turn()

func _on_combat_ended(victory: bool):
	if victory:
		info_label.text = "[color=green]Victory![/color]"
		# Add gold from combat
		var gold_reward = randi_range(20, 40)
		GameManager.add_gold(gold_reward)
		await get_tree().create_timer(1.5).timeout
		get_tree().change_scene_to_file("res://scenes/RewardScreen.tscn")
	else:
		info_label.text = "[color=red]Defeated...[/color]"
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

func _on_hp_changed(hp: int, max_hp: int):
	_update_hud()

func _on_gold_changed(gold: int):
	_update_hud()

func _on_energy_changed(energy: int, max_energy: int):
	_update_hud()

func _on_deck_view():
	# Simple deck view - show in info label
	var text = "[color=cyan]Deck:[/color] "
	for card in GameManager.deck:
		text += card.card_name + ", "
	info_label.text = text
