extends GdUnitTestSuite
## Ogni run riparte dalle stats base + equip: niente residui della run o dell'equip precedente.


func test_begin_run_rebuilds_stats_from_base_each_time() -> void:
	var player: Player = auto_free(load("res://scenes/run/Player/Player.tscn").instantiate())
	add_child(player)
	var base_hp := player.stats.max_hp
	var items: Array[StatModifier] = ItemInstance.new(load("res://data/equipment/core_amulet.tres")).modifiers()

	player.begin_run(items)
	assert_int(player.health.max_hp).is_equal(base_hp + 2)
	player.apply_upgrade(load("res://data/upgrades/max_hp_up.tres"))

	player.begin_run([])
	assert_int(player.stats.max_hp).is_equal(base_hp)
	assert_int(player.health.max_hp).is_equal(base_hp)
	assert_int(load("res://data/player/player_default.tres").max_hp).is_equal(base_hp)
