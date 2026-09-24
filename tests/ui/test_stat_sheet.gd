extends GdUnitTestSuite
## Righe delle statistiche (M9): valori letti da stats e arma, percentuali dei moltiplicatori.


func test_rows_reflect_stats_and_weapon() -> void:
	var stats := PlayerStats.new()
	stats.max_hp = 7
	stats.exp_multiplier = 1.25
	var weapon := WeaponData.new()
	weapon.damage = 3
	weapon.fire_rate = 5.5
	var rows := StatSheet.rows(stats, weapon)
	var by_label := {}
	for row in rows:
		by_label[row[0]] = row[1]
	assert_str(by_label["STAT_MAX_HP"]).is_equal("7")
	assert_str(by_label["STAT_DAMAGE"]).is_equal("3")
	assert_str(by_label["STAT_FIRE_RATE"]).is_equal("5.5/s")
	assert_str(by_label["STAT_EXP_BONUS"]).is_equal("+25%")
	assert_str(by_label["STAT_DROP_BONUS"]).is_equal("+0%")


func test_upgrade_changes_rows() -> void:
	var stats := PlayerStats.new()
	var weapon := WeaponData.new()
	var before := StatSheet.rows(stats, weapon)
	StatApplier.apply(UpgradeData.Stat.DAMAGE, 2.0, false, stats, weapon)
	var after := StatSheet.rows(stats, weapon)
	assert_str(after[2][1]).is_equal(str(int(before[2][1]) + 2))
