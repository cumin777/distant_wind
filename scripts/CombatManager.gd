extends Node2D

signal turn_started()
signal player_turn_started()
signal enemy_turn_started()
signal enemy_turn_ended()
signal combat_ended(victory: bool)
signal card_played(card: CardData, target_index: int)
signal enemy_attacked(enemy: EnemyInstance, damage: int)
signal player_attacked(damage: int)
signal enemy_added(enemy: EnemyInstance, index: int)
signal enemy_removed(index: int)

var enemies: Array[EnemyInstance] = []
var turn_count: int = 0
var player_strength: int = 0
var metallicize_block: int = 0
var is_player_turn: bool = false
var card_target_mode: bool = false
var pending_card_index: int = -1
var combat_active: bool = false
var last_played_target_index: int = -1

func start_combat(enemy_data_list: Array[EnemyData]):
	combat_active = true
	turn_count = 0
	player_strength = 0
	metallicize_block = 0
	enemies.clear()
	GameManager.player_block = 0

	var idx = 0
	for ed in enemy_data_list:
		if ed == null:
			continue
		var instance = EnemyInstance.new(ed)
		instance.enemy_died.connect(_on_enemy_died)
		enemies.append(instance)
		enemy_added.emit(instance, idx)
		idx += 1

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
	if turn_count > 1:
		GameManager.draw_cards(5)
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
		if combat_active:
			enemy_turn_ended.emit()
			_start_player_turn()
		return

	var enemy = enemies[index]
	if enemy.is_dead:
		_process_enemies(index + 1)
		return

	enemy.start_turn()
	var result = enemy.execute_move()

	if result.damage > 0:
		GameManager.take_damage(result.damage)
		player_attacked.emit(result.damage)
		await get_tree().create_timer(0.3).timeout
		if not combat_active:
			return
		if GameManager.is_player_dead():
			combat_active = false
			combat_ended.emit(false)
			return

	# Handle special effects
	var effect = result.get("effect", "")
	var effect_val = result.get("value", 0)
	if effect == "buff_strength":
		enemy.add_strength(effect_val)
	elif effect == "apply_vulnerable":
		pass # TODO: apply to player
	elif effect == "apply_weak":
		pass # TODO: apply to player
	elif effect == "multi_hit":
		for i in range(effect_val - 1):
			if not combat_active:
				return
			var extra_dmg = enemy.get_intent_damage()
			if extra_dmg > 0:
				GameManager.take_damage(extra_dmg)
				player_attacked.emit(extra_dmg)
				await get_tree().create_timer(0.2).timeout
				if GameManager.is_player_dead():
					combat_active = false
					combat_ended.emit(false)
					return

	await get_tree().create_timer(0.2).timeout
	if not combat_active:
		return
	_process_enemies(index + 1)

func can_play_card(card_index: int) -> bool:
	if not is_player_turn or card_index < 0 or card_index >= GameManager.hand.size():
		return false
	var card = GameManager.hand[card_index]
	var cost = card.get_effective_cost()
	if cost < 0:
		return GameManager.player_energy > 0
	return cost <= GameManager.player_energy

func play_card(card_index: int, target_index: int = -1):
	if not can_play_card(card_index):
		return false
	var card = GameManager.hand[card_index]

	var cost = card.get_effective_cost()
	if cost < 0:
		cost = GameManager.player_energy
	GameManager.set_energy(GameManager.player_energy - cost, GameManager.player_max_energy)

	var card_data = GameManager.play_card(card_index)
	if card_data == null:
		return false

	last_played_target_index = target_index

	# Apply card effects
	var total_damage = card_data.get_effective_damage() + player_strength

	# Handle special damage cards first
	var card_name = card_data.card_name.rstrip("+")

	# Body Slam: damage equals block
	if card_name == "Body Slam":
		total_damage = GameManager.player_block + player_strength

	# Whirlwind: X-cost, hit all enemies X times
	if card_name == "Whirlwind":
		var hits = cost
		for h in range(hits):
			for i in range(enemies.size()):
				if not enemies[i].is_dead:
					var actual = enemies[i].take_damage(total_damage)
					enemy_attacked.emit(enemies[i], actual)
		_check_combat_over()
		card_played.emit(card_data, target_index)
		return true

	if total_damage > 0:
		if card_data.target == CardData.CardTarget.ALL_ENEMIES:
			for i in range(enemies.size()):
				if not enemies[i].is_dead:
					var actual = enemies[i].take_damage(total_damage)
					enemy_attacked.emit(enemies[i], actual)
					if not combat_active:
						card_played.emit(card_data, target_index)
						return true
		elif card_data.target == CardData.CardTarget.ENEMY:
			# Multi-hit cards
			var hits = 1
			if card_name == "Sword Boomerang":
				hits = 3
			elif card_name == "Twin Strike":
				hits = 2
			if target_index >= 0 and target_index < enemies.size() and not enemies[target_index].is_dead:
				for h in range(hits):
					if enemies[target_index].is_dead:
						break
					var actual = enemies[target_index].take_damage(total_damage)
					enemy_attacked.emit(enemies[target_index], actual)
					if not combat_active:
						card_played.emit(card_data, target_index)
						return true

	if card_data.get_effective_block() > 0:
		GameManager.add_block(card_data.get_effective_block())

	# Special card effects
	_handle_special_effects(card_data, target_index)

	card_played.emit(card_data, target_index)

	if not combat_active:
		return true

	_check_combat_over()
	return true

func _handle_special_effects(card: CardData, target_index: int):
	var card_name = card.card_name.rstrip("+")
	match card_name:
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
			if target_index >= 0 and target_index < enemies.size():
				enemies[target_index].apply_vulnerable(2)
			elif not enemies.is_empty():
				enemies[0].apply_vulnerable(2)
		"Thunderclap":
			for e in enemies:
				if not e.is_dead:
					e.apply_vulnerable(1)
		"Uppercut":
			if target_index >= 0 and target_index < enemies.size():
				enemies[target_index].apply_weak(1)
			elif not enemies.is_empty():
				enemies[0].apply_weak(1)

func _on_enemy_died(enemy: EnemyInstance):
	GameManager.add_gold(enemy.data.gold_drop)
	var idx = enemies.find(enemy)
	if idx >= 0:
		enemies.remove_at(idx)
		enemy_removed.emit(idx)
	_check_combat_over()

func _check_combat_over() -> bool:
	if not combat_active:
		return false
	var all_dead = true
	for e in enemies:
		if not e.is_dead:
			all_dead = false
			break
	if all_dead and enemies.size() == 0:
		combat_active = false
		combat_ended.emit(true)
		return true
	if GameManager.is_player_dead():
		combat_active = false
		combat_ended.emit(false)
		return true
	return false

func get_enemy_at_display_index(display_index: int) -> int:
	# Convert display index to actual enemy index by finding the nth alive enemy
	var count = -1
	for i in range(enemies.size()):
		if not enemies[i].is_dead:
			count += 1
			if count == display_index:
				return i
	return -1
