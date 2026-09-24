extends GdUnitTestSuite
## Equip e upgrade passano da StatApplier: si applicano alle copie di run, mai ai .tres base.


func test_additive_and_multiplier_modifiers() -> void:
	var stats := PlayerStats.new()
	var weapon := WeaponData.new()
	stats.move_speed = 200.0
	weapon.damage = 1
	weapon.fire_rate = 4.0

	StatApplier.apply(UpgradeData.Stat.DAMAGE, 2.0, false, stats, weapon)
	StatApplier.apply(UpgradeData.Stat.FIRE_RATE, 1.25, true, stats, weapon)
	StatApplier.apply(UpgradeData.Stat.MOVE_SPEED, 1.1, true, stats, weapon)

	assert_int(weapon.damage).is_equal(3)
	assert_float(weapon.fire_rate).is_equal_approx(5.0, 0.001)
	assert_float(stats.move_speed).is_equal_approx(220.0, 0.001)


func test_max_hp_never_below_one() -> void:
	var stats := PlayerStats.new()
	stats.max_hp = 2
	StatApplier.apply(UpgradeData.Stat.MAX_HP, -5.0, false, stats, WeaponData.new())
	assert_int(stats.max_hp).is_equal(1)


func test_equipment_applies_to_copies_and_leaves_base_resources_untouched() -> void:
	var base_stats: PlayerStats = load("res://data/player/player_default.tres")
	var base_weapon: WeaponData = load("res://data/weapons/starter_wand.tres")
	var base_hp := base_stats.max_hp
	var base_damage := base_weapon.damage
	var stats: PlayerStats = base_stats.duplicate()
	var weapon: WeaponData = base_weapon.duplicate()
	var modifiers: Array[StatModifier] = []
	for path in ["res://data/equipment/gel_wand.tres", "res://data/equipment/core_amulet.tres"]:
		modifiers.append_array(ItemInstance.new(load(path)).modifiers())

	StatApplier.apply_modifiers(modifiers, stats, weapon)

	assert_int(weapon.damage).is_equal(base_damage + 1)
	assert_int(stats.max_hp).is_equal(base_hp + 2)
	assert_int(base_weapon.damage).is_equal(base_damage)
	assert_int(base_stats.max_hp).is_equal(base_hp)
