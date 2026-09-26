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


func test_upgrade_at_max_picks_is_excluded() -> void:
	# Ventaglio (M12, #86): oltre max_picks non deve piu' comparire tra le scelte.
	var table := _table(3)
	table.upgrades[0].max_picks = 2
	var picks: Dictionary[UpgradeData, int] = {table.upgrades[0]: 2}
	var rng := RandomNumberGenerator.new()
	for i in 100:
		assert_bool(table.pick(1, rng, picks)[0] == table.upgrades[0]).is_false()


func test_upgrade_below_max_picks_can_still_be_picked() -> void:
	var table := _table(1)
	table.upgrades[0].max_picks = 2
	var picks: Dictionary[UpgradeData, int] = {table.upgrades[0]: 1}
	var rng := RandomNumberGenerator.new()
	assert_int(table.pick(1, rng, picks).size()).is_equal(1)


## Guardia contro un indice numerico sbagliato nel .tres (gia' successo una volta con gli affix,
## M12 #86): l'enum e' salvato come intero, un refuso non darebbe errori di caricamento.
func test_mana_regen_upgrade_resource_has_correct_stat() -> void:
	var upgrade: UpgradeData = load("res://data/upgrades/mana_regen_up.tres")
	assert_int(upgrade.stat).is_equal(UpgradeData.Stat.MANA_REGEN)


## Danno e HP massimi non devono piu' avere upgrade flat (M12, #86): +1 raddoppiava/decuplicava
## rispetto alla base, un flat resta sempre sproporzionato mano a mano che la base cambia. Sempre
## percentuale, come Raffica.
func test_damage_and_max_hp_upgrades_are_percentage_not_flat() -> void:
	var damage_up: UpgradeData = load("res://data/upgrades/damage_up.tres")
	var max_hp_up: UpgradeData = load("res://data/upgrades/max_hp_up.tres")
	assert_bool(damage_up.is_multiplier).is_true()
	assert_bool(max_hp_up.is_multiplier).is_true()


func test_max_mana_upgrade_resource_has_correct_stat() -> void:
	var upgrade: UpgradeData = load("res://data/upgrades/max_mana_up.tres")
	assert_int(upgrade.stat).is_equal(UpgradeData.Stat.MAX_MANA)
	assert_bool(upgrade.is_multiplier).is_true()


func _table(size: int) -> UpgradeTable:
	var table := UpgradeTable.new()
	for i in size:
		var upgrade := UpgradeData.new()
		upgrade.display_name = "u%d" % i
		table.upgrades.append(upgrade)
	return table
