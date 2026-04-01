class_name CardData
extends Resource

enum CardType { ATTACK, SKILL, POWER }
enum CardRarity { STARTER, COMMON, UNCOMMON, RARE }
enum CardTarget { NONE, ENEMY, ALL_ENEMIES, SELF }

@export var card_name: String = "Unnamed"
@export var card_type: CardType = CardType.ATTACK
@export var rarity: CardRarity = CardRarity.STARTER
@export var cost: int = 1
@export var target: CardTarget = CardTarget.ENEMY
@export var damage: int = 0
@export var block: int = 0
@export var description: String = ""
@export var upgraded: bool = false
@export var upgrade_damage: int = 0
@export var upgrade_block: int = 0
@export var upgrade_cost: int = -1
@export var color: Color = Color.WHITE

func get_effective_damage() -> int:
	return damage + (upgrade_damage if upgraded else 0)

func get_effective_block() -> int:
	return block + (upgrade_block if upgraded else 0)

func get_effective_cost() -> int:
	if upgraded and upgrade_cost >= 0:
		return upgrade_cost
	return cost

func get_upgraded() -> CardData:
	var upgraded_card = duplicate()
	upgraded_card.upgraded = true
	upgraded_card.card_name = card_name.rstrip("+") + "+"
	return upgraded_card
