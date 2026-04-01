class_name EnemyData
extends Resource

enum EnemyType { NORMAL, ELITE, BOSS }

@export var enemy_name: String = "Enemy"
@export var enemy_type: EnemyType = EnemyType.NORMAL
@export var max_hp: int = 30
@export var min_hp: int = 20
@export var gold_drop: int = 10
@export var moves: Array[Dictionary] = []
@export var color: Color = Color.RED

func get_random_hp() -> int:
	return randi_range(min_hp, max_hp)
