extends Node2D

signal turn_started()
signal player_turn_started()
signal enemy_turn_started()
signal enemy_turn_ended()
signal combat_ended(victory: bool)
signal card_played(card: CardData, target_index: int)
signal enemy_attacked(enemy: EnemyInstance, damage: int)
signal player_attacked(damage: int)
signal enemy_added(enemy: EnemyInstance)

var enemies: Array[EnemyInstance] = []
var turn_count: int = 0
var player_strength: int = 0
var metallicize_block: int = 0
var is_player_turn: bool = false
var card_target_mode: bool = false
var pending_card_index: int = -1
var combat_active: bool = false

func start_combat(enemy_data_list: Array[EnemyData]):
	combat_active = true
	turn_count = 0
	player_strength = 0
	metallicize_block = 0
	enemies.clear()
	GameManager.player_block = 0

	for ed in enemy_data_list:
		var instance = EnemyInstance.new(ed)
		instance.enemy_died.connect(_on_enemy_died)
		enemies.append(instance)
		enemy_added.emit(instance)

	GameManager.shuffle_draw_pile()
	GameManager.draw_cards(5)

	_start_player_turn()

func _start_player_turn():
	turn_count += 1
	is_player_turn = true
	card_target_mode = false
	GameManager.set_energy(3, 3)
	GameManager.player_block = 0
	if metallicize_block > 0:
		GameManager.add_block(metallicize_block)
	player_turn_started.emit()
	turn_started.emit()

func end_player_turn():
	if not is_player_turn:
		return
	is_player_turn = false
	GameManager.discard_hand()
	_start_enemy_turn()

func _start_enemy_turn():
	enemy_turn_started.emit()
	_process_enemies(0)

func _process_enemies(index: int):
	if index >= enemies.size() or not combat_active:
		enemy_turn_ended.emit()
		_start_player_turn()
		return

	var enemy = enemies[index]
	enemy.start_turn()
	var result = enemy.execute_move()

	if result.damage > 0:
		var actual = GameManager.take_damage(result.damage)
		player_attacked.emit(result.damage)
		await get_tree().create_timer(0.4).timeout
		if GameManager.is_player_dead():
			combat_active = false
			combat_ended.emit(false)
			return

	# Handle special effects
	var effect = result.get("effect", "")
	if effect == "buff_strength":
		enemy.add_strength(result.get("value", 0))
	elif effect == "apply_vulnerable":
		pass
	elif effect == "apply_weak":
		pass

	await get_tree().create_timer(0.2).timeout
	_process_enemies(index + 1)

func can_play_card(card_index: int) -> bool:
	if not is_player_turn or card_index < 0 or card_index >= GameManager.hand.size():
		return false
	var card = GameManager.hand[card_index]
	if card.cost < 0:
		return GameManager.player_energy > 0
	return card.cost <= GameManager.player_energy

func play_card(card_index: int, target_index: int = -1):
	if not can_play_card(card_index):
		return
	var card = GameManager.hand[card_index]

	var cost = card.get_effective_cost()
	if cost < 0:
		cost = GameManager.player_energy
	GameManager.set_energy(GameManager.player_energy - cost, GameManager.player_max_energy)

	var card_data = GameManager.play_card(card_index)
	if card_data == null:
		return

	# Apply card effects
	var total_damage = card_data.get_effective_damage() + player_strength
	if total_damage > 0:
		if card_data.target == CardData.CardTarget.ALL_ENEMIES:
			for i in range(enemies.size()):
				if not enemies[i].is_dead:
					var actual = enemies[i].take_damage(total_damage)
					enemy_attacked.emit(enemies[i], actual)
		elif card_data.target == CardData.CardTarget.ENEMY:
			if target_index >= 0 and target_index < enemies.size() and not enemies[target_index].is_dead:
				var actual = enemies[target_index].take_damage(total_damage)
				enemy_attacked.emit(enemies[target_index], actual)

	if card_data.get_effective_block() > 0:
		GameManager.add_block(card_data.get_effective_block())

	# Special card effects
	_handle_special_effects(card_data)

	card_played.emit(card_data, target_index)

	_check_combat_over()

func _handle_special_effects(card: CardData):
	var name = card.card_name.rstrip("+")
	match name:
		"Inflame":
			player_strength += 2
		"Metallicize":
			metallicize_block += 3
		"Blood Letting":
			GameManager.take_damage(3)
			GameManager.set_energy(GameManager.player_energy + 2, GameManager.player_max_energy)
		"Entrench":
			GameManager.player_block *= 2
		"Limit Break":
			player_strength *= 2
		"Feed":
			GameManager.player_max_hp += 3
		"Shrug It Off":
			GameManager.draw_cards(1)
		"Pommel Strike":
			GameManager.draw_cards(1)
		"Bash":
			if not enemies.is_empty():
				var target = enemies[0]
				target.apply_vulnerable(2)

func _on_enemy_died(enemy: EnemyInstance):
	GameManager.add_gold(enemy.data.gold_drop)
	var idx = enemies.find(enemy)
	if idx >= 0:
		enemies.remove_at(idx)
	_check_combat_over()

func _check_combat_over() -> bool:
	var all_dead = true
	for e in enemies:
		if not e.is_dead:
			all_dead = false
			break
	if all_dead and combat_active:
		combat_active = false
		combat_ended.emit(true)
		return true
	if GameManager.is_player_dead() and combat_active:
		combat_active = false
		combat_ended.emit(false)
		return true
	return false
