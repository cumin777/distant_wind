class_name EnemyDatabase
extends Node

var enemies: Dictionary = {}

func _ready():
	_register_enemies()

func _register_enemies():
	_register("Cultist", EnemyData.EnemyType.NORMAL, 50, 50, 15, Color.DARK_RED,
		[{"name": "Incantation", "damage": 0, "block": 0, "effect": "buff_strength", "value": 3},
		 {"name": "Dark Strike", "damage": 6, "block": 0, "effect": "", "value": 0}])
	_register("Jaw Worm", EnemyData.EnemyType.NORMAL, 40, 44, 20, Color.DARK_GREEN,
		[{"name": "Chomp", "damage": 11, "block": 0, "effect": "", "value": 0},
		 {"name": "Thrash", "damage": 7, "block": 0, "effect": "", "value": 0},
		 {"name": "Bellow", "damage": 0, "block": 6, "effect": "buff_strength", "value": 3}])
	_register("Fungi Beast", EnemyData.EnemyType.NORMAL, 28, 28, 15, Color.DARK_OLIVE_GREEN,
		[{"name": "Bite", "damage": 6, "block": 0, "effect": "", "value": 0},
		 {"name": "Grow", "damage": 0, "block": 0, "effect": "buff_strength", "value": 3}])
	_register("Slaver Blue", EnemyData.EnemyType.NORMAL, 46, 46, 25, Color.DARK_BLUE,
		[{"name": "Stab", "damage": 12, "block": 0, "effect": "", "value": 0},
		 {"name": "Rake", "damage": 7, "block": 0, "effect": "apply_weak", "value": 1}])
	_register("Slaver Red", EnemyData.EnemyType.NORMAL, 46, 46, 25, Color.DARK_RED,
		[{"name": "Stab", "damage": 13, "block": 0, "effect": "", "value": 0},
		 {"name": "Scrape", "damage": 8, "block": 5, "effect": "apply_vulnerable", "value": 1}])
	_register("Gremlin Nob", EnemyData.EnemyType.ELITE, 82, 82, 50, Color.DARK_MAGENTA,
		[{"name": "Bash", "damage": 14, "block": 0, "effect": "", "value": 0},
		 {"name": "Skull Bash", "damage": 6, "block": 0, "effect": "apply_vulnerable", "value": 2}])
	_register("Lagavulin", EnemyData.EnemyType.ELITE, 109, 109, 70, Color.DARK_SLATE_GRAY,
		[{"name": "Attack", "damage": 18, "block": 0, "effect": "", "value": 0},
		 {"name": "Siphon Soul", "damage": 0, "block": 0, "effect": "drain_strength", "value": 1}])
	_register("Sentry", EnemyData.EnemyType.ELITE, 38, 38, 60, Color.DARK_GRAY,
		[{"name": "Bolt", "damage": 9, "block": 0, "effect": "", "value": 0}])
	_register("Slime Boss", EnemyData.EnemyType.BOSS, 140, 140, 100, Color.DARK_GREEN,
		[{"name": "Goop Spray", "damage": 0, "block": 0, "effect": "spawn_slimes", "value": 0},
		 {"name": "Slam", "damage": 35, "block": 0, "effect": "", "value": 0}])
	_register("The Guardian", EnemyData.EnemyType.BOSS, 240, 240, 100, Color.DARK_RED,
		[{"name": "Charging Up", "damage": 0, "block": 9, "effect": "", "value": 0},
		 {"name": "Fierce Strike", "damage": 32, "block": 0, "effect": "", "value": 0},
		 {"name": "Whirlwind", "damage": 5, "block": 0, "effect": "multi_hit", "value": 4}])

func _register(name: String, type: int, min_hp: int, max_hp: int, gold: int, col: Color, moves: Array[Dictionary]):
	var enemy = EnemyData.new()
	enemy.enemy_name = name
	enemy.enemy_type = type
	enemy.min_hp = min_hp
	enemy.max_hp = max_hp
	enemy.gold_drop = gold
	enemy.color = col
	enemy.moves = moves
	enemies[name] = enemy

func get_enemy(name: String) -> EnemyData:
	if enemies.has(name):
		return enemies[name]
	return null

func get_random_normal_enemy() -> EnemyData:
	var normal: Array = []
	for e in enemies.values():
		if e.enemy_type == EnemyData.EnemyType.NORMAL:
			normal.append(e)
	if normal.is_empty():
		return null
	return normal[randi() % normal.size()]

func get_random_elite() -> EnemyData:
	var elites: Array = []
	for e in enemies.values():
		if e.enemy_type == EnemyData.EnemyType.ELITE:
			elites.append(e)
	if elites.is_empty():
		return null
	return elites[randi() % elites.size()]

func get_boss() -> EnemyData:
	var bosses: Array = []
	for e in enemies.values():
		if e.enemy_type == EnemyData.EnemyType.BOSS:
			bosses.append(e)
	if bosses.is_empty():
		return null
	return bosses[randi() % bosses.size()]
