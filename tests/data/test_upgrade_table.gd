extends GdUnitTestSuite


func test_pick_returns_distinct_upgrades() -> void:
	var table := _table(5)
	var rng := RandomNumberGenerator.new()
	for i in 50:
		var picked := table.pick(3, rng)
		assert_int(picked.size()).is_equal(3)
		assert_bool(picked[0] != picked[1] and picked[1] != picked[2] and picked[0] != picked[2]).is_true()


func test_pick_is_capped_by_table_size() -> void:
	assert_int(_table(2).pick(3, RandomNumberGenerator.new()).size()).is_equal(2)


func test_zero_weight_upgrade_is_never_picked_while_others_exist() -> void:
	var table := _table(3)
	table.upgrades[0].weight = 0.0
	var rng := RandomNumberGenerator.new()
	for i in 100:
		assert_bool(table.pick(1, rng)[0] == table.upgrades[0]).is_false()


func _table(size: int) -> UpgradeTable:
	var table := UpgradeTable.new()
	for i in size:
		var upgrade := UpgradeData.new()
		upgrade.display_name = "u%d" % i
		table.upgrades.append(upgrade)
	return table
