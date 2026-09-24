extends GdUnitTestSuite
## Contatore (M10.1): +1 a ogni conteggio di proiettili, combo con i Ventagli presi dopo.


func _apply(stat: UpgradeData.Stat, stats: PlayerStats, weapon: WeaponData) -> void:
	StatApplier.apply(stat, 1.0, false, stats, weapon)


func test_counter_alone_adds_one_projectile() -> void:
	var stats := PlayerStats.new()
	var weapon := WeaponData.new()
	_apply(UpgradeData.Stat.COUNT_BONUS, stats, weapon)
	assert_int(weapon.projectile_count).is_equal(2)


func test_fan_counter_fan_gives_five() -> void:
	var stats := PlayerStats.new()
	var weapon := WeaponData.new()
	_apply(UpgradeData.Stat.PROJECTILE_COUNT, stats, weapon)
	assert_int(weapon.projectile_count).is_equal(2)
	_apply(UpgradeData.Stat.COUNT_BONUS, stats, weapon)
	assert_int(weapon.projectile_count).is_equal(3)
	_apply(UpgradeData.Stat.PROJECTILE_COUNT, stats, weapon)
	assert_int(weapon.projectile_count).is_equal(5)
	_apply(UpgradeData.Stat.COUNT_BONUS, stats, weapon)
	_apply(UpgradeData.Stat.PROJECTILE_COUNT, stats, weapon)
	assert_int(weapon.projectile_count).is_equal(9)


func test_counter_is_in_the_upgrade_table() -> void:
	var table: UpgradeTable = load("res://data/upgrades/upgrade_table.tres")
	assert_bool(table.upgrades.any(func(u: UpgradeData) -> bool: return u.stat == UpgradeData.Stat.COUNT_BONUS)).is_true()
