@tool
extends Node
## Pure logic test - no scene tree timers needed
## Tests the core game systems by calling methods directly

var tests_passed: int = 0
var tests_failed: int = 0
var failed_tests: Array[String] = []

func _ready():
	print("\n============================================")
	print("  CARD ROGUELIKE - PURE LOGIC COMBAT TEST")
	print("============================================\n")

	test_game_manager_core()
	test_deck_and_draw_cycle()
	test_card_data_and_database()
	test_enemy_instance_system()
	test_combat_start_and_turns()
	test_combat_play_all_cards()
	test_combat_kill_enemy()
	test_combat_player_death()
	test_block_damage_absorption()
	test_multi_enemy_combat()
	test_card_upgrade_system()
	test_15_floor_progression()

	print("\n============================================")
	print("  RESULTS: %d PASSED, %d FAILED" % [tests_passed, tests_failed])
	print("============================================")
	if failed_tests.size() > 0:
		for f in failed_tests:
			print("  FAIL: " + f)
		get_tree().quit(1)
	else:
		print("  ALL TESTS PASSED!")
	get_tree().quit()

func check(name: String, condition: bool, detail: String = ""):
	if condition:
		tests_passed += 1
		print("  [PASS] %s" % name)
	else:
		tests_failed += 1
		failed_tests.append(name)
		print("  [FAIL] %s -- %s" % [name, detail])

func make_enemy_data(name: String, hp: int, dmg: int) -> EnemyData:
	var e = EnemyData.new()
	e.enemy_name = name
	e.max_hp = hp
	e.min_hp = hp
	e.gold_drop = 10
	var m: Array[Dictionary] = []
	m.append({"name": "Attack", "damage": dmg, "block": 0, "effect": "", "value": 0})
	e.moves = m
	return e

# =============================================
func test_game_manager_core():
	print("--- GameManager Core ---")
	GameManager.reset_run()

	check("HP=75", GameManager.player_hp == 75)
	check("MaxHP=75", GameManager.player_max_hp == 75)
	check("Gold=99", GameManager.player_gold == 99)
	check("Alive", not GameManager.is_player_dead())
	check("Floor=0", GameManager.current_floor == 0)
	check("Deck=10", GameManager.deck.size() == 10)
	check("Energy=3/3", GameManager.player_energy == 3 and GameManager.player_max_energy == 3)

	# Damage
	GameManager.player_block = 0
	var d = GameManager.take_damage(10)
	check("Take 10 dmg", d == 10 and GameManager.player_hp == 65)

	# Block
	GameManager.add_block(8)
	d = GameManager.take_damage(12)
	check("Block 8 of 12", d == 4 and GameManager.player_hp == 61 and GameManager.player_block == 0)

	# Heal
	GameManager.heal(30)
	check("Heal caps at max", GameManager.player_hp == 75)

	# Gold
	GameManager.add_gold(50)
	check("Gold +50=149", GameManager.player_gold == 149)
	check("Spend 40 ok", GameManager.spend_gold(40))
	check("Gold=109", GameManager.player_gold == 109)
	check("Can't overspend", not GameManager.spend_gold(999))

	# Death
	GameManager.player_hp = 5
	GameManager.take_damage(10)
	check("Player dies", GameManager.is_player_dead())

# =============================================
func test_deck_and_draw_cycle():
	print("\n--- Deck & Draw Cycle ---")
	GameManager.reset_run()

	# 10 cards in deck
	check("Deck size 10", GameManager.deck.size() == 10)

	# Shuffle into draw pile
	GameManager.shuffle_draw_pile()
	check("Draw pile = 10", GameManager.draw_pile.size() == 10)
	check("Hand empty", GameManager.hand.size() == 0)
	check("Discard empty", GameManager.discard_pile.size() == 0)

	# Draw 5
	GameManager.draw_cards(5)
	check("Hand = 5", GameManager.hand.size() == 5)
	check("Draw = 5", GameManager.draw_pile.size() == 5)

	# Discard all
	GameManager.discard_hand()
	check("Hand = 0", GameManager.hand.size() == 0)
	check("Discard = 5", GameManager.discard_pile.size() == 5)

	# Draw remaining 5
	GameManager.draw_cards(5)
	check("Hand = 5 again", GameManager.hand.size() == 5)
	check("Draw = 0", GameManager.draw_pile.size() == 0)

	# Discard and reshuffle
	GameManager.discard_hand()
	check("Discard = 10", GameManager.discard_pile.size() == 10)

	GameManager.draw_cards(5)
	check("Reshuffle: Hand = 5", GameManager.hand.size() == 5)
	check("Draw = 5 after reshuffle", GameManager.draw_pile.size() == 5)
	check("Discard = 0 after reshuffle", GameManager.discard_pile.size() == 0)

	# Verify total card count consistency
	var total = GameManager.draw_pile.size() + GameManager.hand.size() + GameManager.discard_pile.size()
	check("Total cards consistent", total == 10, "total=%d" % total)

	# Stress test: 20 draws of 5
	GameManager.discard_hand()
	for i in range(20):
		GameManager.draw_cards(5)
		check("Cycle %d: hand=5" % i, GameManager.hand.size() == 5,
			"hand=%d draw=%d discard=%d" % [GameManager.hand.size(), GameManager.draw_pile.size(), GameManager.discard_pile.size()])
		GameManager.discard_hand()

# =============================================
func test_card_data_and_database():
	print("\n--- Card Data & Database ---")
	var c = CardData.new()
	c.card_name = "Strike"
	c.cost = 1
	c.damage = 6
	c.block = 0
	c.upgrade_damage = 3
	c.card_type = CardData.CardType.ATTACK

	check("Base dmg=6", c.get_effective_damage() == 6)
	check("Base cost=1", c.get_effective_cost() == 1)

	var u = c.get_upgraded()
	check("Upgraded flag", u.upgraded)
	check("Upgraded dmg=9", u.get_effective_damage() == 9)
	check("Upgraded name+", u.card_name == "Strike+")

	# Database
	var db = CardDatabase.new()
	add_child(db)

	var strike = db.get_card("Strike")
	check("DB get Strike", strike != null)
	if strike:
		check("Strike dmg=6", strike.damage == 6)

	var reward = db.get_reward_cards(3)
	check("3 reward cards", reward.size() == 3)

	db.queue_free()

# =============================================
func test_enemy_instance_system():
	print("\n--- Enemy Instance ---")
	var e = make_enemy_data("TestMob", 40, 8)
	var inst = EnemyInstance.new(e)

	check("HP=40", inst.current_hp == 40)
	check("Not dead", not inst.is_dead)
	check("Has move", inst.current_move.size() > 0)

	# Take damage
	inst.take_damage(15)
	check("HP=25 after 15 dmg", inst.current_hp == 25)

	# Vulnerable
	inst.apply_vulnerable(2)
	check("Vuln=2", inst.vulnerable == 2)
	inst.take_damage(10) # 10 * 1.5 = 15
	check("Vuln: took 15 (10*1.5)", inst.current_hp == 10)

	# Weak
	inst.apply_weak(1)
	check("Weak=1", inst.weak == 1)

	# Block (still has vulnerable=1, so 3*1.5=4.5→4 damage)
	inst.add_block(5)
	inst.take_damage(3)
	# vulnerable still active: 3*1.5=4 damage, block absorbs 4 of 5
	check("Block absorbed damage with vuln", inst.current_hp == 10)
	check("Block reduced by 4", inst.block == 1)

	# Kill
	inst.take_damage(999)
	check("Dead", inst.is_dead)
	check("HP=0", inst.current_hp == 0)

	# Strength
	var e2 = make_enemy_data("Strong", 30, 5)
	var inst2 = EnemyInstance.new(e2)
	inst2.add_strength(3)
	inst2.choose_next_move()
	check("Intent dmg with str=3", inst2.get_intent_damage() == 8)

# =============================================
func test_combat_start_and_turns():
	print("\n--- Combat Start & Turns ---")
	GameManager.reset_run()

	var cm = Node2D.new()
	cm.set_script(load("res://scripts/CombatManager.gd"))
	add_child(cm)

	cm.start_combat([make_enemy_data("Mob", 50, 6)])

	check("Combat active", cm.combat_active)
	check("Enemies=1", cm.enemies.size() == 1)
	check("Is player turn", cm.is_player_turn)
	check("Turn=1", cm.turn_count == 1)
	check("Hand=5", GameManager.hand.size() == 5,
		"got %d" % GameManager.hand.size())
	check("Energy=3", GameManager.player_energy == 3)
	check("Block=0", GameManager.player_block == 0)

	cm.queue_free()

# =============================================
func test_combat_play_all_cards():
	print("\n--- Play All Cards ---")
	GameManager.reset_run()

	var cm = Node2D.new()
	cm.set_script(load("res://scripts/CombatManager.gd"))
	add_child(cm)

	cm.start_combat([make_enemy_data("Dummy", 9999, 0)])

	# Play all cards in hand
	var played_count = 0
	while GameManager.hand.size() > 0 and GameManager.player_energy > 0:
		var card = GameManager.hand[0]
		var cost = card.get_effective_cost()
		if cost < 0:
			cost = GameManager.player_energy
		if cost <= GameManager.player_energy:
			cm.play_card(0, 0)
			played_count += 1
		else:
			break

	check("Played >= 3 cards", played_count >= 3, "played %d" % played_count)
	check("Hand smaller now", GameManager.hand.size() < 5)
	check("Energy spent", GameManager.player_energy < 3)

	cm.queue_free()

# =============================================
func test_combat_kill_enemy():
	print("\n--- Kill Enemy ---")
	GameManager.reset_run()

	var cm = Node2D.new()
	cm.set_script(load("res://scripts/CombatManager.gd"))
	add_child(cm)

	cm.start_combat([make_enemy_data("Weak", 20, 3)])

	# Keep playing attack cards until dead
	var rounds = 0
	for i in range(10):
		if not cm.combat_active:
			break
		# Play all cards
		while GameManager.hand.size() > 0:
			if cm.can_play_card(0):
				cm.play_card(0, 0)
			else:
				break
		rounds += 1
		if cm.combat_active:
			cm.end_player_turn()
			# Manually process enemy turn (no timer in test)
			GameManager.discard_hand()
			# Simulate what _process_enemies does synchronously
			if cm.combat_active and cm.enemies.size() > 0:
				var enemy = cm.enemies[0]
				if not enemy.is_dead:
					enemy.start_turn()
					var result = enemy.execute_move()
					if result.damage > 0:
						GameManager.take_damage(result.damage)
						if GameManager.is_player_dead():
							cm.combat_active = false
							break

			# New turn: draw cards
			cm.turn_count += 1
			cm.is_player_turn = true
			GameManager.set_energy(3, 3)
			GameManager.player_block = 0
			GameManager.draw_cards(5)

	check("Enemy dead", cm.enemies.size() == 0 or cm.enemies[0].is_dead)
	check("Combat ended or enemy HP<=0",
		not cm.combat_active or (cm.enemies.size() > 0 and cm.enemies[0].current_hp <= 0))

	cm.queue_free()

# =============================================
func test_combat_player_death():
	print("\n--- Player Death ---")
	GameManager.reset_run()

	var cm = Node2D.new()
	cm.set_script(load("res://scripts/CombatManager.gd"))
	add_child(cm)

	cm.start_combat([make_enemy_data("Killer", 9999, 25)])

	# Don't play cards, just let enemy hit us
	for i in range(10):
		if not cm.combat_active:
			break
		cm.end_player_turn()
		# Simulate enemy turn
		if cm.combat_active and cm.enemies.size() > 0:
			var enemy = cm.enemies[0]
			if not enemy.is_dead:
				enemy.start_turn()
				var result = enemy.execute_move()
				if result.damage > 0:
					GameManager.take_damage(result.damage)
					if GameManager.is_player_dead():
						cm.combat_active = false
						break

	check("Player is dead", GameManager.is_player_dead())
	check("HP <= 0", GameManager.player_hp <= 0)

	cm.queue_free()

# =============================================
func test_block_damage_absorption():
	print("\n--- Block & Damage ---")
	GameManager.reset_run()

	# Direct GameManager test
	GameManager.player_block = 10
	GameManager.player_hp = 50
	var dmg = GameManager.take_damage(15)

	check("Absorbed 10 block", dmg == 5)
	check("HP=45", GameManager.player_hp == 45)
	check("Block=0", GameManager.player_block == 0)

	# Full block
	GameManager.player_block = 20
	GameManager.player_hp = 50
	dmg = GameManager.take_damage(10)
	check("Full block, dmg=0", dmg == 0)
	check("HP still 50", GameManager.player_hp == 50)
	check("Block=10", GameManager.player_block == 10)

# =============================================
func test_multi_enemy_combat():
	print("\n--- Multi Enemy ---")
	GameManager.reset_run()

	var cm = Node2D.new()
	cm.set_script(load("res://scripts/CombatManager.gd"))
	add_child(cm)

	cm.start_combat([
		make_enemy_data("Mob1", 15, 4),
		make_enemy_data("Mob2", 15, 4)
	])

	check("2 enemies", cm.enemies.size() == 2)

	# Play all cards targeting enemy 0
	while GameManager.hand.size() > 0:
		if cm.can_play_card(0):
			cm.play_card(0, 0)
		else:
			break

	var any_dead = false
	for e in cm.enemies:
		if e.is_dead:
			any_dead = true
	check("At least one enemy took damage", cm.enemies[0].current_hp < 15 or cm.enemies[1].current_hp < 15)

	cm.queue_free()

# =============================================
func test_card_upgrade_system():
	print("\n--- Card Upgrade ---")
	GameManager.reset_run()

	var upgradable = 0
	for card in GameManager.deck:
		if not card.upgraded:
			upgradable += 1

	check("All 10 cards upgradeable", upgradable == 10)

	# Upgrade a Strike
	var first = GameManager.deck[0]
	var base_dmg = first.get_effective_damage()
	GameManager.deck[0] = first.get_upgraded()
	check("Card upgraded", GameManager.deck[0].upgraded)
	check("Dmg >= base", GameManager.deck[0].get_effective_damage() >= base_dmg)

# =============================================
func test_15_floor_progression():
	print("\n--- 15-Floor Progression (Logic) ---")
	GameManager.reset_run()

	var db = CardDatabase.new()
	add_child(db)
	var edb = EnemyDatabase.new()
	add_child(edb)

	var floors_cleared = 0
	var combats_won = 0
	var player_died = false

	for floor in range(1, 16):
		if player_died:
			break
		GameManager.current_floor = floor

		# Decide encounter
		var is_combat = false
		var is_elite = false
		var is_boss = false

		if floor == 15:
			is_combat = true; is_boss = true
		elif floor % 5 == 0:
			is_combat = true; is_elite = true
		elif floor % 3 == 0:
			# Rest
			GameManager.heal(int(GameManager.player_max_hp * 0.3))
			floors_cleared += 1
			continue
		elif floor % 2 == 1:
			# Event (give gold)
			GameManager.add_gold(randi_range(10, 25))
			floors_cleared += 1
			continue
		else:
			is_combat = true

		if not is_combat:
			continue

		# Get enemies
		var enemies: Array[EnemyData] = []
		if is_boss:
			var b = edb.get_boss()
			if b: enemies.append(b)
		elif is_elite:
			var e = edb.get_random_elite()
			if e: enemies.append(e)
		else:
			var n = edb.get_random_normal_enemy()
			if n: enemies.append(n)

		if enemies.is_empty():
			floors_cleared += 1
			continue

		# === RUN COMBAT LOGIC ===
		# Reset combat state
		GameManager.shuffle_draw_pile()
		GameManager.draw_cards(5)
		GameManager.set_energy(3, 3)
		GameManager.player_block = 0

		var alive_enemies: Array = []
		for ed in enemies:
			alive_enemies.append(EnemyInstance.new(ed))

		var combat_rounds = 0
		var victory = false

		for round in range(50):
			combat_rounds += 1
			GameManager.set_energy(3, 3)
			GameManager.player_block = 0

			if round > 0:
				GameManager.draw_cards(5)

			# Player plays cards
			while GameManager.hand.size() > 0 and GameManager.player_energy > 0:
				var card = GameManager.hand[0]
				if card == null:
					break
				var cost = card.get_effective_cost()
				if cost < 0:
					cost = GameManager.player_energy
				if cost > GameManager.player_energy:
					break

				GameManager.set_energy(GameManager.player_energy - cost, GameManager.player_max_energy)
				GameManager.hand.pop_at(0)
				GameManager.discard_pile.append(card)

				# Apply card effects
				var total_dmg = card.get_effective_damage()
				if card.card_name.rstrip("+") == "Body Slam":
					total_dmg = GameManager.player_block

				if total_dmg > 0:
					if card.target == CardData.CardTarget.ALL_ENEMIES:
						for e in alive_enemies:
							if not e.is_dead:
								e.take_damage(total_dmg)
					elif card.target == CardData.CardTarget.ENEMY and alive_enemies.size() > 0:
						var target = alive_enemies[0]
						if not target.is_dead:
							target.take_damage(total_dmg)

				if card.get_effective_block() > 0:
					GameManager.add_block(card.get_effective_block())

			# Discard hand
			GameManager.discard_hand()

			# Remove dead enemies
			alive_enemies = alive_enemies.filter(func(e): return not e.is_dead)

			if alive_enemies.is_empty():
				victory = true
				break

			# Enemy turns
			for enemy in alive_enemies:
				enemy.start_turn()
				var result = enemy.execute_move()
				if result.damage > 0:
					GameManager.take_damage(result.damage)
					if GameManager.is_player_dead():
						player_died = true
						break

			if player_died:
				break

		if victory:
			combats_won += 1
			floors_cleared += 1
			GameManager.add_gold(randi_range(20, 40))
			var rewards = db.get_reward_cards(1)
			if rewards.size() > 0:
				GameManager.add_card_to_deck(rewards[0])
		elif player_died:
			break

	check("Cleared >= 5 floors", floors_cleared >= 5, "cleared %d" % floors_cleared)
	check("Won >= 2 combats", combats_won >= 2, "won %d" % combats_won)
	check("Deck grew > 10", GameManager.deck.size() > 10, "deck %d" % GameManager.deck.size())
	check("Gold earned", GameManager.player_gold >= 99, "gold %d" % GameManager.player_gold)

	print("  RESULT: Floors %d | Combats Won %d | HP %d/%d | Deck %d | Gold %d | %s" % [
		floors_cleared, combats_won,
		GameManager.player_hp, GameManager.player_max_hp,
		GameManager.deck.size(), GameManager.player_gold,
		"DEFEAT" if player_died else "SURVIVED"
	])

	db.queue_free()
	edb.queue_free()
