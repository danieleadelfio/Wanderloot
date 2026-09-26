extends GdUnitTestSuite
## Contatore (M10.1, #51; scope ridotto in M12 #86): +1 a ogni conteggio di proiettili delle abilita'
## (Anello arcano, Fulmine errante, ...), MAI allo sparo base ne' al Ventaglio.


func _apply(stat: UpgradeData.Stat, stats: PlayerStats, weapon: WeaponData) -> void:
	StatApplier.apply(stat, 1.0, false, stats, weapon)


func test_counter_alone_does_not_touch_base_weapon() -> void:
	var stats := PlayerStats.new()
	var weapon := WeaponData.new()
	_apply(UpgradeData.Stat.COUNT_BONUS, stats, weapon)
	assert_int(stats.count_bonus).is_equal(1)
	assert_int(weapon.projectile_count).is_equal(1)


func test_fan_and_counter_no_longer_combo_on_base_weapon() -> void:
	var stats := PlayerStats.new()
	var weapon := WeaponData.new()
	_apply(UpgradeData.Stat.PROJECTILE_COUNT, stats, weapon)
	assert_int(weapon.projectile_count).is_equal(2)
	_apply(UpgradeData.Stat.COUNT_BONUS, stats, weapon)
	assert_int(weapon.projectile_count).is_equal(2)
	_apply(UpgradeData.Stat.PROJECTILE_COUNT, stats, weapon)
	assert_int(weapon.projectile_count).is_equal(3)


func test_counter_is_in_the_upgrade_table() -> void:
	var table: UpgradeTable = load("res://data/upgrades/upgrade_table.tres")
	assert_bool(table.upgrades.any(func(u: UpgradeData) -> bool: return u.stat == UpgradeData.Stat.COUNT_BONUS)).is_true()
