extends Node

signal hp_changed(new_hp: int, max_hp: int)
signal gold_changed(new_gold: int)
signal energy_changed(new_energy: int, max_energy: int)
signal deck_changed()

var player_hp: int = 75
var player_max_hp: int = 75
var player_gold: int = 99
var player_energy: int = 3
var player_max_energy: int = 3

var deck: Array[CardData] = []
var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []
var exhaust_pile: Array[CardData] = []

var current_floor: int = 0
var max_floors: int = 15
var current_act: int = 1

var player_block: int = 0
var buffs: Dictionary = {}

func _ready():
	reset_run()

func reset_run():
	player_hp = 75
	player_max_hp = 75
	player_gold = 99
	player_energy = 3
	player_max_energy = 3
	player_block = 0
	buffs.clear()
	current_floor = 0
	current_act = 1

	deck.clear()
	draw_pile.clear()
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()

	_create_starter_deck()

func _create_starter_deck():
	for i in range(5):
		deck.append(_create_card("Strike", CardData.CardType.ATTACK, CardData.CardRarity.STARTER, 1, CardData.CardTarget.ENEMY, 6, 0, "Deal 6 damage.", Color.CRIMSON))
	for i in range(4):
		deck.append(_create_card("Defend", CardData.CardType.SKILL, CardData.CardRarity.STARTER, 1, CardData.CardTarget.SELF, 0, 5, "Gain 5 Block.", Color.STEEL_BLUE))
	deck.append(_create_card("Bash", CardData.CardType.ATTACK, CardData.CardRarity.STARTER, 2, CardData.CardTarget.ENEMY, 8, 0, "Deal 8 damage. Apply 2 Vulnerable.", Color.CRIMSON))
	deck_changed.emit()

func _create_card(name: String, type: int, rarity: int, cost: int, target: int, dmg: int, blk: int, desc: String, col: Color) -> CardData:
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
	return card

func take_damage(amount: int) -> int:
	var actual_damage = amount
	if player_block > 0:
		var blocked = min(player_block, amount)
		player_block -= blocked
		actual_damage -= blocked
	player_hp = max(0, player_hp - actual_damage)
	hp_changed.emit(player_hp, player_max_hp)
	return actual_damage

func heal(amount: int):
	player_hp = min(player_max_hp, player_hp + amount)
	hp_changed.emit(player_hp, player_max_hp)

func add_block(amount: int):
	player_block += amount

func add_gold(amount: int):
	player_gold += amount
	gold_changed.emit(player_gold)

func spend_gold(amount: int) -> bool:
	if player_gold >= amount:
		player_gold -= amount
		gold_changed.emit(player_gold)
		return true
	return false

func set_energy(energy: int, max_e: int):
	player_energy = energy
	player_max_energy = max_e
	energy_changed.emit(player_energy, player_max_energy)

func is_player_dead() -> bool:
	return player_hp <= 0

func shuffle_draw_pile():
	draw_pile = deck.duplicate()
	draw_pile.shuffle()

func draw_cards(count: int):
	for i in range(count):
		if draw_pile.is_empty():
			_reshuffle_discard()
		if not draw_pile.is_empty():
			var card = draw_pile.pop_front()
			hand.append(card)

func _reshuffle_discard():
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	draw_pile.shuffle()

func discard_hand():
	while not hand.is_empty():
		var card = hand.pop_front()
		discard_pile.append(card)

func play_card(card_index: int) -> CardData:
	if card_index < 0 or card_index >= hand.size():
		return null
	var card = hand.pop_at(card_index)
	discard_pile.append(card)
	deck_changed.emit()
	return card

func add_card_to_deck(card: CardData):
	deck.append(card)
	deck_changed.emit()

func remove_card_from_deck(index: int) -> CardData:
	if index < 0 or index >= deck.size():
		return null
	var card = deck.pop_at(index)
	deck_changed.emit()
	return card
