extends GdUnitTestSuite
## Ogni run riparte dalle stats base + equip: niente residui della run o dell'equip precedente.


func test_begin_run_rebuilds_stats_from_base_each_time() -> void:
	var player: Player = auto_free(load("res://scenes/run/Player/Player.tscn").instantiate())
	add_child(player)
	var base_hp := player.stats.max_hp
	var items: Array[StatModifier] = ItemInstance.new(load("res://data/equipment/core_amulet.tres")).modifiers()

	player.begin_run(items)
	# core_amulet: +20% HP (M12, #86: equip fisso in percentuale, non piu' flat).
	assert_int(player.health.max_hp).is_equal(roundi(base_hp * 1.2))
	player.apply_upgrade(load("res://data/upgrades/max_hp_up.tres"))

	player.begin_run([])
	assert_int(player.stats.max_hp).is_equal(base_hp)
	assert_int(player.health.max_hp).is_equal(base_hp)
	assert_int(load("res://data/player/player_default.tres").max_hp).is_equal(base_hp)


func test_pull_from_multiple_sources_does_not_stack_past_cap() -> void:
	# Piu' Sfere del vuoto vicine (M12, #86): la somma delle attrazioni non deve superare quella di
	# una singola sfera a distanza zero, altrimenti diventa impossibile scappare da un gruppo di slime viola.
	var player: Player = auto_free(load("res://scenes/run/Player/Player.tscn").instantiate())
	add_child(player)
	player.weapon_enabled = false
	for i in 5:
		player.add_pull(Vector2.RIGHT * 100.0)
	player._physics_process(0.0)
	assert_float(player.velocity.length()).is_less_equal(Player.MAX_PULL_FORCE + 0.01)


func test_single_pull_source_is_unaffected_by_cap() -> void:
	var player: Player = auto_free(load("res://scenes/run/Player/Player.tscn").instantiate())
	add_child(player)
	player.weapon_enabled = false
	player.add_pull(Vector2.RIGHT * 60.0)
	player._physics_process(0.0)
	assert_float(player.velocity.length()).is_equal_approx(60.0, 0.01)

func test_begin_run_resets_mana_and_wires_weapon() -> void:
	var player: Player = auto_free(load("res://scenes/run/Player/Player.tscn").instantiate())
	add_child(player)
	player.mana.spend(player.mana.max_value)
	player.begin_run([])
	assert_float(player.mana.current).is_equal_approx(player.stats.max_mana, 0.001)
	assert_float(player.mana.regen_per_second).is_equal_approx(player.stats.mana_regen, 0.001)


func test_max_mana_upgrade_grows_the_pool_without_a_full_refill() -> void:
	# Riserva (M13, #86): +10% mana massimo si applica sia a stats.max_mana sia al pool live,
	# accreditando solo la differenza guadagnata (come Vigore fa per la vita).
	var player: Player = auto_free(load("res://scenes/run/Player/Player.tscn").instantiate())
	add_child(player)
	player.begin_run([])
	var base_max := player.mana.max_value
	player.mana.spend(base_max * 0.5)
	var before_spend := player.mana.current

	player.apply_upgrade(load("res://data/upgrades/max_mana_up.tres"))

	assert_float(player.stats.max_mana).is_equal_approx(base_max * 1.1, 0.01)
	assert_float(player.mana.max_value).is_equal_approx(base_max * 1.1, 0.01)
	assert_float(player.mana.current).is_equal_approx(before_spend + base_max * 0.1, 0.01)
