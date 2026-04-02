class_name EnemyInstance
extends RefCounted

var data: EnemyData
var current_hp: int
var max_hp: int
var block: int = 0
var strength: int = 0
var vulnerable: int = 0
var weak: int = 0
var is_dead: bool = false
var move_index: int = 0
var current_move: Dictionary = {}

signal enemy_died(enemy: EnemyInstance)
signal enemy_hp_changed(enemy: EnemyInstance)
signal enemy_intents_changed(enemy: EnemyInstance)

func _init(enemy_data: EnemyData):
	data = enemy_data
	max_hp = data.get_random_hp()
	current_hp = max_hp
	choose_next_move()

func choose_next_move():
	if data.moves.is_empty():
		current_move = {"name": "Idle", "damage": 0, "block": 0, "effect": "", "value": 0}
		return
	move_index = randi() % data.moves.size()
	current_move = data.moves[move_index].duplicate()
	enemy_intents_changed.emit(self)

func get_intent_damage() -> int:
	var dmg = current_move.get("damage", 0)
	if dmg > 0:
		dmg += strength
		if weak > 0:
			dmg = max(1, int(dmg * 0.75))
	return dmg

func get_intent_block() -> int:
	return current_move.get("block", 0)

func get_intent_name() -> String:
	return current_move.get("name", "Unknown")

func get_intent_effect() -> String:
	return current_move.get("effect", "")

func take_damage(amount: int) -> int:
	var actual_damage = amount
	if vulnerable > 0:
		actual_damage = int(actual_damage * 1.5)
	if block > 0:
		var blocked_amount = min(block, actual_damage)
		block -= blocked_amount
		actual_damage -= blocked_amount
	current_hp = max(0, current_hp - actual_damage)
	enemy_hp_changed.emit(self)
	if current_hp <= 0 and not is_dead:
		is_dead = true
		enemy_died.emit(self)
	return actual_damage

func add_block(amount: int):
	block += amount

func apply_vulnerable(amount: int):
	vulnerable += amount

func apply_weak(amount: int):
	weak += amount

func add_strength(amount: int):
	strength += amount

func start_turn():
	block = 0
	if vulnerable > 0:
		vulnerable -= 1
	if weak > 0:
		weak -= 1

func execute_move() -> Dictionary:
	var result = {
		"damage": get_intent_damage(),
		"block": get_intent_block(),
		"effect": get_intent_effect(),
		"value": current_move.get("value", 0),
		"name": get_intent_name()
	}
	if result.block > 0:
		add_block(result.block)
	choose_next_move()
	return result
