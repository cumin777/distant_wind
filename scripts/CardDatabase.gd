class_name CardDatabase
extends Node

var all_cards: Dictionary = {}

func _ready():
	_register_cards()

func _register_cards():
	_register("Strike", CardData.CardType.ATTACK, CardData.CardRarity.STARTER, 1, CardData.CardTarget.ENEMY, 6, 0, "Deal 6 damage.", Color.CRIMSON, 3, 0, -1)
	_register("Defend", CardData.CardType.SKILL, CardData.CardRarity.STARTER, 1, CardData.CardTarget.SELF, 0, 5, "Gain 5 Block.", Color.STEEL_BLUE, 0, 3, -1)
	_register("Bash", CardData.CardType.ATTACK, CardData.CardRarity.STARTER, 2, CardData.CardTarget.ENEMY, 8, 0, "Deal 8 damage. Apply 2 Vulnerable.", Color.CRIMSON, 4, 0, -1)
	_register("Cleave", CardData.CardType.ATTACK, CardData.CardRarity.COMMON, 1, CardData.CardTarget.ALL_ENEMIES, 8, 0, "Deal 8 damage to ALL enemies.", Color.ORANGE_RED, 3, 0, -1)
	_register("Iron Wave", CardData.CardType.ATTACK, CardData.CardRarity.COMMON, 1, CardData.CardTarget.ENEMY, 5, 5, "Deal 5 damage. Gain 5 Block.", Color.SLATE_GRAY, 3, 3, -1)
	_register("Shrug It Off", CardData.CardType.SKILL, CardData.CardRarity.COMMON, 1, CardData.CardTarget.SELF, 0, 8, "Gain 8 Block. Draw 1 card.", Color.STEEL_BLUE, 0, 3, -1)
	_register("Sword Boomerang", CardData.CardType.ATTACK, CardData.CardRarity.COMMON, 1, CardData.CardTarget.ENEMY, 3, 0, "Deal 3x3 damage.", Color.CRIMSON, 1, 0, -1)
	_register("Pommel Strike", CardData.CardType.ATTACK, CardData.CardRarity.COMMON, 1, CardData.CardTarget.ENEMY, 9, 0, "Deal 9 damage. Draw 1 card.", Color.ORANGE_RED, 3, 0, -1)
	_register("Twin Strike", CardData.CardType.ATTACK, CardData.CardRarity.COMMON, 1, CardData.CardTarget.ENEMY, 5, 0, "Deal 5 damage twice.", Color.CRIMSON, 2, 0, -1)
	_register("Thunderclap", CardData.CardType.ATTACK, CardData.CardRarity.COMMON, 1, CardData.CardTarget.ALL_ENEMIES, 4, 0, "Deal 4 to ALL. Apply 1 Vulnerable.", Color.DARK_VIOLET, 3, 0, -1)
	_register("Inflame", CardData.CardType.POWER, CardData.CardRarity.UNCOMMON, 1, CardData.CardTarget.SELF, 0, 0, "Gain 2 Strength.", Color.DARK_ORANGE, 0, 0, -1)
	_register("Metallicize", CardData.CardType.POWER, CardData.CardRarity.UNCOMMON, 1, CardData.CardTarget.SELF, 0, 0, "End of turn: gain 3 Block.", Color.SLATE_GRAY, 0, 0, -1)
	_register("Body Slam", CardData.CardType.ATTACK, CardData.CardRarity.UNCOMMON, 1, CardData.CardTarget.ENEMY, 0, 0, "Deal damage equal to Block.", Color.DARK_BLUE, 0, 0, -1)
	_register("Blood Letting", CardData.CardType.SKILL, CardData.CardRarity.UNCOMMON, 0, CardData.CardTarget.SELF, 0, 0, "Lose 3 HP. Gain 2 Energy.", Color.DARK_RED, 0, 0, -1)
	_register("Uppercut", CardData.CardType.ATTACK, CardData.CardRarity.UNCOMMON, 2, CardData.CardTarget.ENEMY, 13, 0, "Deal 13 damage. Apply 1 Weak.", Color.DARK_MAGENTA, 3, 0, -1)
	_register("Entrench", CardData.CardType.SKILL, CardData.CardRarity.UNCOMMON, 2, CardData.CardTarget.SELF, 0, 0, "Double your Block.", Color.SLATE_GRAY, 0, 0, -1)
	_register("Whirlwind", CardData.CardType.ATTACK, CardData.CardRarity.RARE, -1, CardData.CardTarget.ALL_ENEMIES, 5, 0, "Deal 5 damage X times to ALL.", Color.DARK_RED, 3, 0, -1)
	_register("Limit Break", CardData.CardType.SKILL, CardData.CardRarity.RARE, 1, CardData.CardTarget.SELF, 0, 0, "Double your Strength.", Color.DARK_GOLDENROD, 0, 0, -1)
	_register("Feed", CardData.CardType.ATTACK, CardData.CardRarity.RARE, 1, CardData.CardTarget.ENEMY, 10, 0, "Deal 10 damage. Max HP +3.", Color.DARK_GREEN, 3, 0, -1)
	_register("Impervious", CardData.CardType.SKILL, CardData.CardRarity.RARE, 2, CardData.CardTarget.SELF, 0, 30, "Gain 30 Block.", Color.DARK_BLUE, 0, 10, -1)

func _register(name: String, type: int, rarity: int, cost: int, target: int, dmg: int, blk: int, desc: String, col: Color, up_dmg: int, up_blk: int, up_cost: int):
	var card = CardData.new()
	card.card_name = name
	card.card_type = type
	card.rarity = rarity
	card.cost = cost
	card.target = target
	card.damage = dmg
	card.block = blk
	card.description = desc
	card.color = col
	card.upgrade_damage = up_dmg
	card.upgrade_block = up_blk
	card.upgrade_cost = up_cost
	all_cards[name] = card

func get_card(name: String) -> CardData:
	if all_cards.has(name):
		return all_cards[name].duplicate()
	return null

func get_cards_by_rarity(rarity: int) -> Array[CardData]:
	var result: Array[CardData] = []
	for card in all_cards.values():
		if card.rarity == rarity:
			result.append(card.duplicate())
	return result

func get_random_card_by_rarity(rarity: int) -> CardData:
	var cards = get_cards_by_rarity(rarity)
	if cards.is_empty():
		# Fallback to common
		cards = get_cards_by_rarity(CardData.CardRarity.COMMON)
	if cards.is_empty():
		return null
	return cards[randi() % cards.size()].duplicate()

func get_reward_cards(count: int = 3) -> Array[CardData]:
	var rewards: Array[CardData] = []
	var rarities = [CardData.CardRarity.COMMON, CardData.CardRarity.COMMON, CardData.CardRarity.COMMON, CardData.CardRarity.UNCOMMON, CardData.CardRarity.RARE]
	for i in range(count):
		var roll = rarities[randi() % rarities.size()]
		var card = get_random_card_by_rarity(roll)
		if card:
			rewards.append(card)
	return rewards
